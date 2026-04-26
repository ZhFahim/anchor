import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../database/app_database.dart';
import '../network/dio_provider.dart';
import '../providers/active_user_id_provider.dart';
import '../../features/notes/data/repository/note_attachments_repository.dart';
import 'sync_api_client.dart';
import 'sync_models.dart';
import 'sync_outbox_dao.dart';

part 'sync_worker.g.dart';

@riverpod
SyncWorker syncWorker(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  final dio = ref.watch(dioProvider);
  final userId = ref.watch(activeUserIdProvider)!;

  final worker = SyncWorker(
    db: db,
    dio: dio,
    userId: userId,
    // Resolve lazily — reading attachmentsRepo here would close a cycle with
    // its trigger callback, which itself reads syncWorker.
    attachmentsRepo: () => ref.read(noteAttachmentsRepositoryProvider),
  );
  worker.start();
  ref.onDispose(worker.stop);
  return worker;
}

// Single-flight sync orchestrator. One instance per active user.
class SyncWorker {
  final AppDatabase db;
  final String userId;
  final NoteAttachmentsRepository Function() _attachmentsRepo;
  final SyncApiClient _api;
  final SyncOutboxDao _outboxDao;
  final FlutterSecureStorage _storage;

  Completer<void>? _inflight;
  bool _dirtyAgain = false;
  Timer? _debounce;
  Timer? _periodic;
  bool _stopped = false;

  static const _debounceWindow = Duration(milliseconds: 500);
  static const _periodicInterval = Duration(seconds: 30);
  static const _batchSize = 100;

  SyncWorker({
    required this.db,
    required Dio dio,
    required this.userId,
    required NoteAttachmentsRepository Function() attachmentsRepo,
    SyncApiClient? api,
    FlutterSecureStorage? storage,
  }) : _attachmentsRepo = attachmentsRepo,
       _api = api ?? SyncApiClient(dio),
       _outboxDao = SyncOutboxDao(db),
       _storage = storage ?? const FlutterSecureStorage();

  String get _cursorKey => 'sync_cursor_$userId';

  void start() {
    if (_stopped) return;
    _periodic = Timer.periodic(_periodicInterval, (_) => requestSync());
    requestSync(immediate: true);
  }

  void stop() {
    _stopped = true;
    _debounce?.cancel();
    _periodic?.cancel();
  }

  Future<void> requestSync({bool immediate = false}) {
    if (_stopped) return Future.value();

    if (immediate) {
      _debounce?.cancel();
      return _runOrAttach();
    }

    _debounce?.cancel();
    final completer = Completer<void>();
    _debounce = Timer(_debounceWindow, () {
      _runOrAttach().then(completer.complete).catchError((Object e) {
        if (!completer.isCompleted) completer.complete();
      });
    });
    return completer.future;
  }

  Future<void> _runOrAttach() {
    if (_inflight != null) {
      _dirtyAgain = true;
      return _inflight!.future;
    }
    final completer = Completer<void>();
    _inflight = completer;

    () async {
      try {
        await _runOnce();
      } catch (e, st) {
        debugPrint('SyncWorker run failed: $e\n$st');
      } finally {
        _inflight = null;
        completer.complete();
        if (_dirtyAgain && !_stopped) {
          _dirtyAgain = false;
          Future.microtask(_runOrAttach);
        }
      }
    }();

    return completer.future;
  }

  Future<void> _runOnce() async {
    // Drain binary uploads first so the cursor pull picks up the resulting
    // server-side note version bumps inline.
    try {
      await _attachmentsRepo().syncBinaries();
    } catch (e) {
      debugPrint('Attachment binary sync failed (will retry): $e');
    }

    while (!_stopped) {
      final batch = await _outboxDao.nextBatch(limit: _batchSize);
      final cursor = await _readCursor();

      await _outboxDao.markInflight(batch.map((r) => r.id).toList());

      final ops = batch.map(_outboxRowToRequest).toList();
      final SyncResponse response;
      try {
        response = await _api.sync(SyncRequest(cursor: cursor, ops: ops));
      } catch (e) {
        for (final row in batch) {
          await _outboxDao.recordFailure(id: row.id, error: e.toString());
        }
        rethrow;
      }

      await db.transaction(() async {
        for (final result in response.results) {
          await _handleOpResult(result);
        }
        for (final change in response.serverChanges) {
          await _applyServerChange(change);
        }
        for (final id in response.revokedSharedNoteIds) {
          await _hardDeleteNoteLocal(id);
        }
      });

      await _cleanupRevokedAttachments(response);

      await _writeCursor(response.newCursor);

      final hasMoreLocal = batch.length == _batchSize ||
          await _outboxDao.hasReady();
      final hasMoreRemote = response.hasMore;
      if (!hasMoreLocal && !hasMoreRemote) break;
    }
  }

  Future<void> _handleOpResult(SyncOpResult result) async {
    final row = await (db.select(db.syncOutbox)
          ..where((tbl) => tbl.clientOpId.equals(result.clientOpId))
          ..limit(1))
        .getSingleOrNull();
    if (row == null) return;

    switch (result.status) {
      case SyncOpStatus.applied:
      case SyncOpStatus.noop:
        await _outboxDao.retire(result.clientOpId);
        if (result.serverRow != null) {
          await _applyServerRowIfSafe(
            entityType: row.entityType,
            entityId: row.entityId,
            serverRow: result.serverRow!,
            exceptClientOpId: result.clientOpId,
            isDeleted: false,
            syncVersion: result.syncVersion,
          );
        }
        break;
      case SyncOpStatus.rejected:
        debugPrint(
          'Sync op rejected: ${row.entityType} ${row.entityId} reason=${result.reason}',
        );
        await _outboxDao.recordFailure(
          id: row.id,
          error: 'rejected:${result.reason ?? 'unknown'}',
          poison: true,
        );
        break;
    }
  }

  // Lost-edit defense: skip the overwrite if a fresher local mutation is
  // pending; the next pass will push it.
  Future<void> _applyServerRowIfSafe({
    required String entityType,
    required String entityId,
    required Map<String, dynamic> serverRow,
    required String exceptClientOpId,
    required bool isDeleted,
    String? syncVersion,
  }) async {
    final hasOther = await _outboxDao.hasOtherPending(
      entityType: entityType,
      entityId: entityId,
      exceptClientOpId: exceptClientOpId,
    );
    if (hasOther) return;

    switch (entityType) {
      case 'note':
        await _writeNoteLocal(serverRow, syncVersion: syncVersion);
        break;
      case 'tag':
        await _writeTagLocal(serverRow, syncVersion: syncVersion);
        break;
      case 'note_attachment':
        // Reconciled inline when the parent note arrives in the cursor pull.
        break;
    }
  }

  Future<void> _applyServerChange(SyncServerChange change) async {
    switch (change.entityType) {
      case 'note':
        final state = change.data['state'] as String?;
        if (state == 'deleted') {
          await _hardDeleteNoteLocal(change.data['id'] as String);
          return;
        }
        await _applyServerRowIfSafe(
          entityType: 'note',
          entityId: change.data['id'] as String,
          serverRow: change.data,
          exceptClientOpId: '',
          isDeleted: false,
          syncVersion: change.syncVersion,
        );
        break;
      case 'tag':
        if (change.isDeleted || change.data['isDeleted'] == true) {
          await _hardDeleteTagLocal(change.data['id'] as String);
          return;
        }
        await _applyServerRowIfSafe(
          entityType: 'tag',
          entityId: change.data['id'] as String,
          serverRow: change.data,
          exceptClientOpId: '',
          isDeleted: false,
          syncVersion: change.syncVersion,
        );
        break;
    }
  }

  Future<void> _writeNoteLocal(
    Map<String, dynamic> note, {
    String? syncVersion,
  }) async {
    final id = note['id'] as String;
    final tagIds =
        ((note['tagIds'] as List?) ?? const []).cast<String>();
    final shareIds = note['shareIds'] as List?;
    final sharedBy = note['sharedBy'] as Map<String, dynamic>?;
    final resolvedSyncVersion =
        (syncVersion ?? note['syncVersion']) as String?;

    await db
        .into(db.notes)
        .insertOnConflictUpdate(
          NotesCompanion(
            id: drift.Value(id),
            title: drift.Value(note['title'] as String? ?? ''),
            content: drift.Value(note['content'] as String?),
            isPinned: drift.Value((note['isPinned'] as bool?) ?? false),
            isArchived: drift.Value((note['isArchived'] as bool?) ?? false),
            background: drift.Value(note['background'] as String?),
            state: drift.Value(note['state'] as String? ?? 'active'),
            updatedAt: drift.Value(_parseDate(note['updatedAt'] as String?)),
            isSynced: const drift.Value(true),
            permission: drift.Value(
              note['permission'] as String? ?? 'owner',
            ),
            shareIds: drift.Value(
              shareIds != null ? jsonEncode(shareIds) : null,
            ),
            sharedById: drift.Value(sharedBy?['id'] as String?),
            sharedByName: drift.Value(sharedBy?['name'] as String?),
            sharedByEmail: drift.Value(sharedBy?['email'] as String?),
            sharedByProfileImage: drift.Value(
              sharedBy?['profileImage'] as String?,
            ),
            syncVersion: drift.Value(resolvedSyncVersion),
          ),
        );

    await _setTagsForNote(id, tagIds);

    final attachments =
        (note['attachments'] as List?)?.cast<Map<String, dynamic>>() ??
        const [];
    await _reconcileAttachments(id, attachments);
  }

  Future<void> _writeTagLocal(
    Map<String, dynamic> tag, {
    String? syncVersion,
  }) async {
    final id = tag['id'] as String;
    final resolvedSyncVersion =
        (syncVersion ?? tag['syncVersion']) as String?;

    await db
        .into(db.tags)
        .insertOnConflictUpdate(
          TagsCompanion(
            id: drift.Value(id),
            name: drift.Value(tag['name'] as String? ?? ''),
            color: drift.Value(tag['color'] as String?),
            updatedAt: drift.Value(_parseDate(tag['updatedAt'] as String?)),
            isSynced: const drift.Value(true),
            isDeleted: drift.Value((tag['isDeleted'] as bool?) ?? false),
            syncVersion: drift.Value(resolvedSyncVersion),
          ),
        );
  }

  Future<void> _setTagsForNote(String noteId, List<String> tagIds) async {
    await (db.delete(
      db.noteTags,
    )..where((tbl) => tbl.noteId.equals(noteId))).go();
    if (tagIds.isEmpty) return;
    await db.batch((batch) {
      batch.insertAll(
        db.noteTags,
        tagIds
            .map(
              (tagId) => NoteTagsCompanion(
                noteId: drift.Value(noteId),
                tagId: drift.Value(tagId),
              ),
            )
            .toList(),
        mode: drift.InsertMode.insertOrReplace,
      );
    });
  }

  // Skips rows mid-binary-upload or pending-delete so their state machine
  // stays intact. Orphaned local files are queued for cleanup post-commit.
  Future<void> _reconcileAttachments(
    String noteId,
    List<Map<String, dynamic>> serverAttachments,
  ) async {
    final localRows = await (db.select(
      db.noteAttachments,
    )..where((tbl) => tbl.noteId.equals(noteId))).get();

    final serverIds = serverAttachments.map((a) => a['id'] as String).toSet();

    for (final row in localRows) {
      final isPendingUpload = row.syncStatus == 'pending_upload';
      final isPendingDelete = row.syncStatus == 'pending_delete';
      if (isPendingUpload || isPendingDelete) continue;

      final knownServerId = row.serverAttachmentId ?? row.id;
      if (!serverIds.contains(knownServerId)) {
        _orphanedAttachmentPaths.add(row.localPath);
        await (db.delete(
          db.noteAttachments,
        )..where((tbl) => tbl.id.equals(row.id))).go();
      }
    }

    for (final att in serverAttachments) {
      final id = att['id'] as String;
      final existing = await (db.select(db.noteAttachments)
            ..where(
              (tbl) =>
                  tbl.id.equals(id) | tbl.serverAttachmentId.equals(id),
            )
            ..limit(1))
          .getSingleOrNull();

      await db
          .into(db.noteAttachments)
          .insertOnConflictUpdate(
            NoteAttachmentsCompanion(
              id: drift.Value(id),
              noteId: drift.Value(att['noteId'] as String),
              type: drift.Value(att['type'] as String),
              originalFilename: drift.Value(
                att['originalFilename'] as String,
              ),
              mimeType: drift.Value(att['mimeType'] as String),
              fileSize: drift.Value(att['fileSize'] as int),
              position: drift.Value((att['position'] as int?) ?? 0),
              localPath: drift.Value(existing?.localPath),
              syncStatus: const drift.Value('synced'),
              serverAttachmentId: drift.Value(id),
              uploadedByUserId: drift.Value(
                att['uploadedByUserId'] as String?,
              ),
              syncVersion: drift.Value(att['syncVersion'] as String?),
            ),
          );
    }
  }

  final List<String?> _orphanedAttachmentPaths = [];

  Future<void> _cleanupRevokedAttachments(SyncResponse _) async {
    if (_orphanedAttachmentPaths.isEmpty) return;
    final paths = List<String?>.from(_orphanedAttachmentPaths);
    _orphanedAttachmentPaths.clear();
    for (final p in paths) {
      if (p == null) continue;
      try {
        await _attachmentsRepo().deleteFileAtPath(p);
      } catch (e) {
        debugPrint('Failed to delete orphaned attachment file: $e');
      }
    }
  }

  Future<void> _hardDeleteNoteLocal(String noteId) async {
    await (db.delete(
      db.noteTags,
    )..where((tbl) => tbl.noteId.equals(noteId))).go();

    final attachmentRows = await (db.select(
      db.noteAttachments,
    )..where((tbl) => tbl.noteId.equals(noteId))).get();
    for (final a in attachmentRows) {
      _orphanedAttachmentPaths.add(a.localPath);
    }

    await (db.delete(
      db.noteAttachments,
    )..where((tbl) => tbl.noteId.equals(noteId))).go();

    await (db.delete(
      db.notes,
    )..where((tbl) => tbl.id.equals(noteId))).go();

    await (db.delete(db.syncOutbox)..where(
          (tbl) =>
              tbl.entityType.equals('note') & tbl.entityId.equals(noteId),
        ))
        .go();
  }

  Future<void> _hardDeleteTagLocal(String tagId) async {
    await (db.delete(
      db.noteTags,
    )..where((tbl) => tbl.tagId.equals(tagId))).go();
    await (db.delete(db.tags)..where((tbl) => tbl.id.equals(tagId))).go();
    await (db.delete(db.syncOutbox)..where(
          (tbl) => tbl.entityType.equals('tag') & tbl.entityId.equals(tagId),
        ))
        .go();
  }

  Future<String?> _readCursor() async {
    return _storage.read(key: _cursorKey);
  }

  Future<void> _writeCursor(String cursor) async {
    await _storage.write(key: _cursorKey, value: cursor);
  }

  SyncOpRequest _outboxRowToRequest(SyncOutboxData row) {
    final payload = row.op == 'delete'
        ? null
        : (jsonDecode(row.payloadJson) as Map<String, dynamic>);
    return SyncOpRequest(
      clientOpId: row.clientOpId,
      entityType: row.entityType,
      entityId: row.entityId,
      op: row.op,
      baseSyncVersion: row.baseSyncVersion,
      payload: payload,
    );
  }

  static DateTime? _parseDate(String? iso) =>
      iso == null ? null : DateTime.tryParse(iso);
}
