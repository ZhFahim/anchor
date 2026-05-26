import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/network/sync_requester.dart';
import '../../../../core/network/sync_upload_snapshot.dart';
import '../../../../core/providers/active_user_id_provider.dart';
import '../../../tags/data/repository/tags_repository.dart';
import '../../domain/note.dart' as domain;
import '../../domain/note_attachment.dart' as domain;
import 'note_attachments_repository.dart';

part 'notes_repository.g.dart';

@riverpod
NotesRepository notesRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  final dio = ref.watch(dioProvider);
  const storage = FlutterSecureStorage();
  final tagsRepo = ref.watch(tagsRepositoryProvider);
  final attachmentsRepo = ref.watch(noteAttachmentsRepositoryProvider);
  final userId = ref.watch(activeUserIdProvider)!;
  return NotesRepository(db, dio, storage, tagsRepo, attachmentsRepo, userId);
}

class NotesRepository {
  final AppDatabase _db;
  final Dio _dio;
  final FlutterSecureStorage _storage;
  final TagsRepository _tagsRepo;
  final NoteAttachmentsRepository _attachmentsRepo;
  final String _userId;

  NotesRepository(
    this._db,
    this._dio,
    this._storage,
    this._tagsRepo,
    this._attachmentsRepo,
    this._userId,
  );

  String get _lastSyncKey => 'last_synced_at_$_userId';
  String get _syncProtocolVersionKey => 'sync_protocol_version_$_userId';
  static const int _currentSyncProtocolVersion = 2;

  // Watch only active notes
  // Uses left outer joins to fetch notes, their tags, and image attachment paths
  Stream<List<domain.Note>> watchNotes({String? tagId}) {
    final query = _db.select(_db.notes).join([
      drift.leftOuterJoin(
        _db.noteTags,
        _db.noteTags.noteId.equalsExp(_db.notes.id),
      ),
      drift.leftOuterJoin(
        _db.noteAttachments,
        _db.noteAttachments.noteId.equalsExp(_db.notes.id) &
            _db.noteAttachments.type.equals('image') &
            _db.noteAttachments.syncStatus.isNotValue(
              domain.AttachmentSyncStatus.pendingDelete.dbValue,
            ),
      ),
    ]);

    // Apply filters - exclude archived notes from main list
    query.where(_db.notes.state.equals('active'));
    query.where(_db.notes.isArchived.equals(false));

    if (tagId != null) {
      query.where(
        _db.notes.id.isInQuery(
          _db.selectOnly(_db.noteTags)
            ..addColumns([_db.noteTags.noteId])
            ..where(_db.noteTags.tagId.equals(tagId)),
        ),
      );
    }

    query.orderBy([
      drift.OrderingTerm(
        expression: _db.notes.isPinned,
        mode: drift.OrderingMode.desc,
      ),
      drift.OrderingTerm(
        expression: _db.notes.updatedAt,
        mode: drift.OrderingMode.desc,
      ),
      drift.OrderingTerm(
        expression: _db.noteAttachments.position,
        mode: drift.OrderingMode.asc,
      ),
    ]);

    // Watch the query - emits when notes, noteTags, or noteAttachments change
    return query.watch().map((rows) {
      // Group rows by note ID to handle one-to-many relationships
      final noteMap = <String, domain.Note>{};
      // Track up to 4 image attachment previews per note
      final imagePreviewsMap = <String, List<domain.NoteImagePreview>>{};

      for (final row in rows) {
        final note = row.readTable(_db.notes);
        final tagRow = row.readTableOrNull(_db.noteTags);
        final attachmentRow = row.readTableOrNull(_db.noteAttachments);

        if (!noteMap.containsKey(note.id)) {
          noteMap[note.id] = _mapToDomain(note, []);
          imagePreviewsMap[note.id] = [];
        }

        if (tagRow?.tagId != null) {
          final currentNote = noteMap[note.id]!;
          if (!currentNote.tagIds.contains(tagRow!.tagId)) {
            noteMap[note.id] = currentNote.copyWith(
              tagIds: [...currentNote.tagIds, tagRow.tagId],
            );
          }
        }

        if (attachmentRow != null) {
          final previews = imagePreviewsMap[note.id]!;
          final attachmentId =
              attachmentRow.serverAttachmentId ?? attachmentRow.id;
          if (previews.length < 4 &&
              !previews.any((p) => p.attachmentId == attachmentId)) {
            previews.add(
              domain.NoteImagePreview(
                attachmentId: attachmentId,
                noteId: note.id,
                filename: attachmentRow.originalFilename,
                localPath: attachmentRow.localPath,
              ),
            );
          }
        }
      }

      return noteMap.entries.map((entry) {
        return entry.value.copyWith(
          imagePreviewData: imagePreviewsMap[entry.key] ?? [],
        );
      }).toList();
    });
  }

  // Watch trashed notes for Trash screen
  // Only show notes owned by the current user (not shared notes that were trashed by others)
  Stream<List<domain.Note>> watchTrashedNotes() async* {
    final query =
        _db.select(_db.notes).join([
            drift.leftOuterJoin(
              _db.noteTags,
              _db.noteTags.noteId.equalsExp(_db.notes.id),
            ),
            drift.leftOuterJoin(
              _db.noteAttachments,
              _db.noteAttachments.noteId.equalsExp(_db.notes.id) &
                  _db.noteAttachments.type.equals('image') &
                  _db.noteAttachments.syncStatus.isNotValue(
                    domain.AttachmentSyncStatus.pendingDelete.dbValue,
                  ),
            ),
          ])
          ..where(_db.notes.state.equals('trashed'))
          ..orderBy([
            drift.OrderingTerm(
              expression: _db.notes.updatedAt,
              mode: drift.OrderingMode.desc,
            ),
            drift.OrderingTerm(
              expression: _db.noteAttachments.position,
              mode: drift.OrderingMode.asc,
            ),
          ]);

    await for (final rows in query.watch()) {
      final noteMap = <String, domain.Note>{};
      final imagePreviewsMap = <String, List<domain.NoteImagePreview>>{};

      for (final row in rows) {
        final note = row.readTable(_db.notes);
        final tagId = row.readTableOrNull(_db.noteTags)?.tagId;
        final attachmentRow = row.readTableOrNull(_db.noteAttachments);

        // Skip shared notes that are trashed (only show owned notes)
        if (note.permission != 'owner') {
          continue;
        }

        if (!noteMap.containsKey(note.id)) {
          noteMap[note.id] = _mapToDomain(note, []);
          imagePreviewsMap[note.id] = [];
        }

        if (tagId != null) {
          final currentNote = noteMap[note.id]!;
          if (!currentNote.tagIds.contains(tagId)) {
            noteMap[note.id] = currentNote.copyWith(
              tagIds: [...currentNote.tagIds, tagId],
            );
          }
        }

        if (attachmentRow != null) {
          final previews = imagePreviewsMap[note.id]!;
          final attachmentId =
              attachmentRow.serverAttachmentId ?? attachmentRow.id;
          if (previews.length < 4 &&
              !previews.any((p) => p.attachmentId == attachmentId)) {
            previews.add(
              domain.NoteImagePreview(
                attachmentId: attachmentId,
                noteId: note.id,
                filename: attachmentRow.originalFilename,
                localPath: attachmentRow.localPath,
              ),
            );
          }
        }
      }

      yield noteMap.entries
          .map(
            (e) => e.value.copyWith(
              imagePreviewData: imagePreviewsMap[e.key] ?? [],
            ),
          )
          .toList();
    }
  }

  // Watch archived notes for Archive screen
  Stream<List<domain.Note>> watchArchivedNotes() {
    final query =
        _db.select(_db.notes).join([
            drift.leftOuterJoin(
              _db.noteTags,
              _db.noteTags.noteId.equalsExp(_db.notes.id),
            ),
            drift.leftOuterJoin(
              _db.noteAttachments,
              _db.noteAttachments.noteId.equalsExp(_db.notes.id) &
                  _db.noteAttachments.type.equals('image') &
                  _db.noteAttachments.syncStatus.isNotValue(
                    domain.AttachmentSyncStatus.pendingDelete.dbValue,
                  ),
            ),
          ])
          ..where(_db.notes.state.equals('active'))
          ..where(_db.notes.isArchived.equals(true))
          ..orderBy([
            drift.OrderingTerm(
              expression: _db.notes.updatedAt,
              mode: drift.OrderingMode.desc,
            ),
            drift.OrderingTerm(
              expression: _db.noteAttachments.position,
              mode: drift.OrderingMode.asc,
            ),
          ]);

    return query.watch().map((rows) {
      final noteMap = <String, domain.Note>{};
      final imagePreviewsMap = <String, List<domain.NoteImagePreview>>{};

      for (final row in rows) {
        final note = row.readTable(_db.notes);
        final tagId = row.readTableOrNull(_db.noteTags)?.tagId;
        final attachmentRow = row.readTableOrNull(_db.noteAttachments);

        if (!noteMap.containsKey(note.id)) {
          noteMap[note.id] = _mapToDomain(note, []);
          imagePreviewsMap[note.id] = [];
        }

        if (tagId != null) {
          final currentNote = noteMap[note.id]!;
          if (!currentNote.tagIds.contains(tagId)) {
            noteMap[note.id] = currentNote.copyWith(
              tagIds: [...currentNote.tagIds, tagId],
            );
          }
        }

        if (attachmentRow != null) {
          final previews = imagePreviewsMap[note.id]!;
          final attachmentId =
              attachmentRow.serverAttachmentId ?? attachmentRow.id;
          if (previews.length < 4 &&
              !previews.any((p) => p.attachmentId == attachmentId)) {
            previews.add(
              domain.NoteImagePreview(
                attachmentId: attachmentId,
                noteId: note.id,
                filename: attachmentRow.originalFilename,
                localPath: attachmentRow.localPath,
              ),
            );
          }
        }
      }

      return noteMap.entries
          .map(
            (e) => e.value.copyWith(
              imagePreviewData: imagePreviewsMap[e.key] ?? [],
            ),
          )
          .toList();
    });
  }

  Future<domain.Note?> getNote(String id) async {
    final row = await (_db.select(
      _db.notes,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    final tagIds = await _tagsRepo.getTagIdsForNote(id);
    return _mapToDomain(row, tagIds);
  }

  Future<void> createNote(domain.Note note) async {
    final noteWithTimestamp = note.copyWith(
      updatedAt: DateTime.now().toUtc(),
      state: domain.NoteState.active,
    );

    // Save locally with generated ID
    await _db
        .into(_db.notes)
        .insert(
          _mapToData(noteWithTimestamp, isSynced: false),
          mode: drift.InsertMode.insertOrReplace,
        );
    await _tagsRepo.setTagsForNote(note.id, note.tagIds);

    AppLogger.instance.info(
      'Notes',
      'createNote id=${note.id} title.len=${noteWithTimestamp.title.length} '
          'content.len=${noteWithTimestamp.content?.length ?? 0} '
          'tags=${note.tagIds.length} updatedAt=${noteWithTimestamp.updatedAt?.toIso8601String()} '
          '→ isSynced=false',
    );

    // Trigger coordinated sync in background
    scheduleAppSync(trigger: 'NotesRepo.createNote');
  }

  Future<void> updateNote(domain.Note note) async {
    final noteWithTimestamp = note.copyWith(updatedAt: DateTime.now().toUtc());

    await _db
        .update(_db.notes)
        .replace(_mapToData(noteWithTimestamp, isSynced: false));
    await _tagsRepo.setTagsForNote(note.id, note.tagIds);

    AppLogger.instance.info(
      'Notes',
      'updateNote id=${note.id} title.len=${noteWithTimestamp.title.length} '
          'content.len=${noteWithTimestamp.content?.length ?? 0} '
          'tags=${note.tagIds.length} updatedAt=${noteWithTimestamp.updatedAt?.toIso8601String()} '
          '→ isSynced=false',
    );

    // Trigger coordinated sync in background
    scheduleAppSync(trigger: 'NotesRepo.updateNote');
  }

  // Soft delete - moves note to trash
  Future<void> deleteNote(String id) async {
    final now = DateTime.now().toUtc();

    await (_db.update(_db.notes)..where((tbl) => tbl.id.equals(id))).write(
      NotesCompanion(
        state: const drift.Value('trashed'),
        updatedAt: drift.Value(now),
        isSynced: const drift.Value(false),
      ),
    );

    scheduleAppSync(trigger: 'NotesRepo.deleteNote');
  }

  // Restore from trash
  Future<void> restoreNote(String id) async {
    final now = DateTime.now().toUtc();

    await (_db.update(_db.notes)..where((tbl) => tbl.id.equals(id))).write(
      NotesCompanion(
        state: const drift.Value('active'),
        updatedAt: drift.Value(now),
        isSynced: const drift.Value(false),
      ),
    );

    scheduleAppSync(trigger: 'NotesRepo.restoreNote');
  }

  // Archive a note
  Future<void> archiveNote(String id) async {
    final now = DateTime.now().toUtc();

    await (_db.update(_db.notes)..where((tbl) => tbl.id.equals(id))).write(
      NotesCompanion(
        isArchived: const drift.Value(true),
        updatedAt: drift.Value(now),
        isSynced: const drift.Value(false),
      ),
    );

    scheduleAppSync(trigger: 'NotesRepo.archiveNote');
  }

  // Unarchive a note
  Future<void> unarchiveNote(String id) async {
    final now = DateTime.now().toUtc();

    await (_db.update(_db.notes)..where((tbl) => tbl.id.equals(id))).write(
      NotesCompanion(
        isArchived: const drift.Value(false),
        updatedAt: drift.Value(now),
        isSynced: const drift.Value(false),
      ),
    );

    scheduleAppSync(trigger: 'NotesRepo.unarchiveNote');
  }

  // Bulk delete notes
  Future<int> bulkDeleteNotes(List<String> ids) async {
    if (ids.isEmpty) return 0;
    final now = DateTime.now().toUtc();

    await (_db.update(_db.notes)..where((tbl) => tbl.id.isIn(ids))).write(
      NotesCompanion(
        state: const drift.Value('trashed'),
        updatedAt: drift.Value(now),
        isSynced: const drift.Value(false),
      ),
    );

    scheduleAppSync(trigger: 'NotesRepo.bulkDeleteNotes');
    return ids.length;
  }

  // Bulk archive notes
  Future<int> bulkArchiveNotes(List<String> ids) async {
    if (ids.isEmpty) return 0;
    final now = DateTime.now().toUtc();

    await (_db.update(_db.notes)..where((tbl) => tbl.id.isIn(ids))).write(
      NotesCompanion(
        isArchived: const drift.Value(true),
        updatedAt: drift.Value(now),
        isSynced: const drift.Value(false),
      ),
    );

    scheduleAppSync(trigger: 'NotesRepo.bulkArchiveNotes');
    return ids.length;
  }

  // Permanent delete - sets state to deleted (tombstone)
  // The note will be removed locally after sync confirms server received it
  Future<void> permanentDelete(String id) async {
    // Clean up local attachment files and DB records
    await _attachmentsRepo.deleteAllLocalForNote(id);

    final now = DateTime.now().toUtc();
    await (_db.update(_db.notes)..where((tbl) => tbl.id.equals(id))).write(
      NotesCompanion(
        state: const drift.Value('deleted'),
        updatedAt: drift.Value(now),
        isSynced: const drift.Value(false),
      ),
    );

    // Remove tag associations immediately for local UI
    await (_db.delete(
      _db.noteTags,
    )..where((tbl) => tbl.noteId.equals(id))).go();

    scheduleAppSync(trigger: 'NotesRepo.permanentDelete');
  }

  // One time migrations when sync protocol version changes (e.g. new feature
  // added server-side that older clients didn't know about).
  Future<void> _runProtocolMigrations() async {
    final raw = await _storage.read(key: _syncProtocolVersionKey);
    final storedVersion = raw != null ? int.tryParse(raw) ?? 1 : 1;

    if (storedVersion < 2) {
      // Backfill attachment metadata for all existing local notes.
      // Needed when upgrading from a pre attachments app version that synced
      // notes without fetching their attachments.
      final localNoteIds =
          await (_db.select(_db.notes)
                ..where((tbl) => tbl.state.isNotValue('deleted')))
              .map((row) => row.id)
              .get();

      if (localNoteIds.isNotEmpty) {
        await _attachmentsRepo.fetchAttachmentsForNotes(localNoteIds);
      }
    }

    // Only persist after all migrations succeed so failures retry next sync.
    if (storedVersion < _currentSyncProtocolVersion) {
      await _storage.write(
        key: _syncProtocolVersionKey,
        value: _currentSyncProtocolVersion.toString(),
      );
    }
  }

  // Bi-directional sync with server
  Future<void> sync() async {
    final cycleStart = DateTime.now();
    try {
      final payload = await _collectLocalChanges();
      AppLogger.instance.info(
        'Notes',
        'Notes sync start: uploading=${payload.localChanges.length} '
            'lastSyncedAt=${payload.lastSyncedAt}',
      );
      final response = await _postSync(payload);
      _logClockSkewIfDrifted(response.syncedAt);
      final applyResult = await _applyServerChanges(
        response,
        payload.uploadSnapshots,
      );

      await _cleanupLocalFiles(applyResult.fileCleanupIds);
      await _attachmentsRepo.sync();
      await _fetchAttachmentMetadata(response.serverChanges);
      await _markProcessedNotesSynced(
        response.processedIds,
        applyResult.postApplySnapshot,
      );
      await _storage.write(key: _lastSyncKey, value: response.syncedAt);
      await _runProtocolMigrations();
      AppLogger.instance.info(
        'Notes',
        'Notes sync done in '
            '${DateTime.now().difference(cycleStart).inMilliseconds}ms: '
            'serverChanges=${response.serverChanges.length} '
            'processed=${response.processedIds.length} '
            'revoked=${response.revokedNoteIds.length} '
            'syncedAt=${response.syncedAt}',
      );
    } catch (e, stack) {
      AppLogger.instance.error(
        'Notes',
        'Notes sync failed after '
            '${DateTime.now().difference(cycleStart).inMilliseconds}ms',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  static const Duration _clockSkewWarnThreshold = Duration(seconds: 30);

  void _logClockSkewIfDrifted(String serverSyncedAt) {
    final serverNow = DateTime.tryParse(serverSyncedAt);
    if (serverNow == null) return;
    final skew = DateTime.now().toUtc().difference(serverNow.toUtc());
    if (skew.abs() < _clockSkewWarnThreshold) return;
    AppLogger.instance.warn(
      'Sync',
      'Clock skew detected: device is ${skew.inMilliseconds}ms '
          '${skew.isNegative ? "behind" : "ahead of"} server '
          '(serverSyncedAt=$serverSyncedAt) — may affect conflict resolution',
    );
  }

  Future<_NoteSyncPayload> _collectLocalChanges() async {
    final lastSyncedAt = await _storage.read(key: _lastSyncKey);
    final unsyncedRows = await (_db.select(
      _db.notes,
    )..where((tbl) => tbl.isSynced.equals(false))).get();

    final snapshots = <String, DateTime?>{};
    final localChanges = <Map<String, dynamic>>[];

    for (final row in unsyncedRows) {
      snapshots[row.id] = row.updatedAt;
      final tagIds = await _tagsRepo.getTagIdsForNote(row.id);
      final note = _mapToDomain(row, tagIds);
      localChanges.add(_noteToSyncChange(note));
      AppLogger.instance.debug(
        'Notes',
        'Local change: id=${row.id} state=${row.state} '
            'content.len=${row.content?.length ?? 0} '
            'updatedAt=${row.updatedAt?.toIso8601String()}',
      );
    }

    return _NoteSyncPayload(
      lastSyncedAt: lastSyncedAt,
      localChanges: localChanges,
      uploadSnapshots: SyncUploadSnapshot(snapshots),
    );
  }

  Map<String, dynamic> _noteToSyncChange(domain.Note note) {
    return {
      'id': note.id,
      'title': note.title,
      'content': note.content,
      'isPinned': note.isPinned,
      'isArchived': note.isArchived,
      'background': note.background,
      'state': note.state.name,
      'tagIds': note.tagIds,
      'updatedAt': note.updatedAt?.toUtc().toIso8601String(),
    };
  }

  Future<_NotesSyncResponse> _postSync(_NoteSyncPayload payload) async {
    final response = await _dio.post(
      '/api/notes/sync',
      data: {
        'lastSyncedAt': payload.lastSyncedAt,
        'changes': payload.localChanges,
      },
    );

    final data = response.data as Map<String, dynamic>;
    final rawConflicts = (data['conflicts'] as List?) ?? const [];
    final serverWonIds = <String>{
      for (final c in rawConflicts)
        if (c is Map && c['resolution'] == 'server' && c['noteId'] is String)
          c['noteId'] as String,
    };
    return _NotesSyncResponse(
      serverChanges: (data['serverChanges'] as List)
          .map((e) => domain.Note.fromJson(e as Map<String, dynamic>))
          .toList(),
      revokedNoteIds:
          (data['revokedSharedNoteIds'] as List?)?.cast<String>() ?? [],
      processedIds: (data['processedIds'] as List?)?.cast<String>() ?? [],
      serverWonIds: serverWonIds,
      syncedAt: data['syncedAt'] as String,
    );
  }

  Future<_NotesApplyResult> _applyServerChanges(
    _NotesSyncResponse response,
    SyncUploadSnapshot uploadSnapshots,
  ) async {
    final fileCleanupIds = <String>{};

    // Defaults to pre-upload snapshot; overwritten below for ids we actually write.
    final postApply = <String, DateTime?>{
      for (final id in response.processedIds)
        if (uploadSnapshots.contains(id)) id: uploadSnapshots[id],
    };

    await _db.transaction(() async {
      for (final revokedId in response.revokedNoteIds) {
        AppLogger.instance.info(
          'Notes',
          'Server revoked share: id=$revokedId → removing local',
        );
        await _removeLocalNote(revokedId);
        fileCleanupIds.add(revokedId);
      }

      for (final serverNote in response.serverChanges) {
        final localNote = await _getLocalNoteRow(serverNote.id);
        final uploadedThisCycle = uploadSnapshots.contains(serverNote.id);

        if (localNote != null &&
            uploadSnapshots.hasChanged(serverNote.id, localNote.updatedAt)) {
          AppLogger.instance.debug(
            'Notes',
            'Skip server change for ${serverNote.id}: local was edited '
                'during sync (local.updatedAt=${localNote.updatedAt?.toIso8601String()})',
          );
          continue;
        }

        if (serverNote.isDeleted) {
          AppLogger.instance.info(
            'Notes',
            'Server deleted: id=${serverNote.id} → removing local',
          );
          await _removeLocalNote(serverNote.id);
          fileCleanupIds.add(serverNote.id);
          if (uploadedThisCycle) {
            postApply[serverNote.id] = null;
          }
          continue;
        }

        if (uploadedThisCycle &&
            response.serverWonIds.contains(serverNote.id)) {
          AppLogger.instance.warn(
            'Notes',
            'Server overrode local edit for ${serverNote.id}: '
                'server.updatedAt=${serverNote.updatedAt?.toIso8601String()} '
                'local.updatedAt=${localNote?.updatedAt?.toIso8601String()} ',
          );
        }

        await _upsertServerNote(
          serverNote,
          localNote,
          forceApply: uploadedThisCycle,
        );

        if (uploadedThisCycle) {
          // Re-read after write: Drift truncates ms so we need the stored value, not serverNote.updatedAt.
          final applied = await _getLocalNoteRow(serverNote.id);
          postApply[serverNote.id] = applied?.updatedAt;
        }
      }
    });

    return _NotesApplyResult(
      fileCleanupIds: fileCleanupIds,
      postApplySnapshot: SyncUploadSnapshot(postApply),
    );
  }

  Future<Note?> _getLocalNoteRow(String id) {
    return (_db.select(
      _db.notes,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  Future<void> _removeLocalNote(String id) async {
    await (_db.delete(
      _db.noteAttachments,
    )..where((tbl) => tbl.noteId.equals(id))).go();
    await (_db.delete(
      _db.noteTags,
    )..where((tbl) => tbl.noteId.equals(id))).go();
    await (_db.delete(_db.notes)..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<void> _upsertServerNote(
    domain.Note serverNote,
    Note? localNote, {
    required bool forceApply,
  }) async {
    if (localNote == null) {
      AppLogger.instance.debug(
        'Notes',
        'Insert server note: id=${serverNote.id} '
            'updatedAt=${serverNote.updatedAt?.toIso8601String()} → isSynced=true',
      );
      await _db
          .into(_db.notes)
          .insert(
            _mapToData(serverNote, isSynced: true),
            mode: drift.InsertMode.insertOrReplace,
          );
      await _tagsRepo.setTagsForNote(serverNote.id, serverNote.tagIds);
      return;
    }

    if (!forceApply && !_serverShouldReplaceLocal(serverNote, localNote)) {
      AppLogger.instance.debug(
        'Notes',
        'Keep local for ${serverNote.id}: local.updatedAt='
            '${localNote.updatedAt?.toIso8601String()} >= '
            'server.updatedAt=${serverNote.updatedAt?.toIso8601String()}',
      );
      return;
    }
    AppLogger.instance.debug(
      'Notes',
      'Apply server change to ${serverNote.id}: '
          'server.updatedAt=${serverNote.updatedAt?.toIso8601String()} '
          'local.updatedAt=${localNote.updatedAt?.toIso8601String()} '
          'forceApply=$forceApply',
    );

    // mark-synced owns isSynced; don't flip here in case attachments are still pending.
    await (_db.update(
      _db.notes,
    )..where((tbl) => tbl.id.equals(serverNote.id))).write(
      NotesCompanion(
        title: drift.Value(serverNote.title),
        content: drift.Value(serverNote.content),
        isPinned: drift.Value(serverNote.isPinned),
        isArchived: drift.Value(serverNote.isArchived),
        background: drift.Value(serverNote.background),
        state: drift.Value(serverNote.state.name),
        updatedAt: drift.Value(serverNote.updatedAt),
        permission: drift.Value(serverNote.permission.name),
        shareIds: drift.Value(jsonEncode(serverNote.shareIds ?? [])),
        sharedById: drift.Value(serverNote.sharedBy?.id),
        sharedByName: drift.Value(serverNote.sharedBy?.name),
        sharedByEmail: drift.Value(serverNote.sharedBy?.email),
        sharedByProfileImage: drift.Value(serverNote.sharedBy?.profileImage),
      ),
    );
    await _tagsRepo.setTagsForNote(serverNote.id, serverNote.tagIds);
  }

  bool _serverShouldReplaceLocal(domain.Note serverNote, Note localNote) {
    final serverUpdatedAt = serverNote.updatedAt;
    final localUpdatedAt = localNote.updatedAt;

    return serverUpdatedAt != null &&
        (localUpdatedAt == null ||
            serverUpdatedAt.isAfter(localUpdatedAt) ||
            serverUpdatedAt.isAtSameMomentAs(localUpdatedAt));
  }

  Future<void> _cleanupLocalFiles(Set<String> noteIds) async {
    for (final noteId in noteIds) {
      await _attachmentsRepo.deleteLocalFilesForNote(noteId);
    }
  }

  Future<void> _fetchAttachmentMetadata(List<domain.Note> serverChanges) {
    return _attachmentsRepo.fetchAttachmentsForNotes(
      serverChanges.where((n) => !n.isDeleted).map((n) => n.id).toList(),
    );
  }

  Future<void> _markProcessedNotesSynced(
    List<String> processedIds,
    SyncUploadSnapshot postApplySnapshot,
  ) async {
    await _db.transaction(() async {
      for (final id in processedIds) {
        final note = await _getLocalNoteRow(id);
        // Mismatch = user re-edited after apply; leave isSynced=false for next cycle.
        if (!postApplySnapshot.isCurrent(id, note?.updatedAt)) {
          AppLogger.instance.info(
            'Notes',
            'Skip mark-synced for $id: local re-edited after apply '
                '(now updatedAt=${note?.updatedAt?.toIso8601String()})',
          );
          continue;
        }

        if (note != null && note.state == 'deleted') {
          AppLogger.instance.info(
            'Notes',
            'Server acked delete $id → removing local row',
          );
          await (_db.delete(
            _db.noteTags,
          )..where((tbl) => tbl.noteId.equals(id))).go();
          await (_db.delete(_db.notes)..where((tbl) => tbl.id.equals(id))).go();
          continue;
        }

        if (note == null) {
          if (postApplySnapshot[id] != null) {
            AppLogger.instance.warn(
              'Notes',
              'Server acked $id but no local row present',
            );
          }
          continue;
        }
        final hasPending = await _attachmentsRepo.hasPendingAttachmentsForNote(
          id,
        );
        if (!hasPending) {
          await (_db.update(_db.notes)..where((tbl) => tbl.id.equals(id)))
              .write(const NotesCompanion(isSynced: drift.Value(true)));
          AppLogger.instance.info('Notes', 'Marked synced: id=$id');
        } else {
          AppLogger.instance.info(
            'Notes',
            'Keep $id unsynced: pending attachment uploads',
          );
        }
      }
    });
  }

  domain.Note _mapToDomain(Note row, List<String> tagIds) {
    return domain.Note(
      id: row.id,
      title: row.title,
      content: row.content,
      isPinned: row.isPinned,
      isArchived: row.isArchived,
      background: row.background,
      state: domain.NoteState.fromString(row.state),
      updatedAt: row.updatedAt,
      tagIds: tagIds,
      permission: domain.NotePermission.fromString(row.permission),
      shareIds: row.shareIds?.isNotEmpty == true
          ? List<String>.from(jsonDecode(row.shareIds!))
          : [],
      sharedBy: row.sharedById != null
          ? domain.SharedByUser(
              id: row.sharedById!,
              name: row.sharedByName ?? '',
              email: row.sharedByEmail ?? '',
              profileImage: row.sharedByProfileImage,
            )
          : null,
      isSynced: row.isSynced,
    );
  }

  Note _mapToData(domain.Note note, {required bool isSynced}) {
    return Note(
      id: note.id,
      title: note.title,
      content: note.content,
      isPinned: note.isPinned,
      isArchived: note.isArchived,
      background: note.background,
      state: note.state.name,
      updatedAt: note.updatedAt,
      permission: note.permission.name,
      shareIds: jsonEncode(note.shareIds ?? []),
      sharedById: note.sharedBy?.id,
      sharedByName: note.sharedBy?.name,
      sharedByEmail: note.sharedBy?.email,
      sharedByProfileImage: note.sharedBy?.profileImage,
      isSynced: isSynced,
    );
  }
}

class _NoteSyncPayload {
  final String? lastSyncedAt;
  final List<Map<String, dynamic>> localChanges;
  final SyncUploadSnapshot uploadSnapshots;

  _NoteSyncPayload({
    required this.lastSyncedAt,
    required this.localChanges,
    required this.uploadSnapshots,
  });
}

class _NotesApplyResult {
  final Set<String> fileCleanupIds;
  final SyncUploadSnapshot postApplySnapshot;

  _NotesApplyResult({
    required this.fileCleanupIds,
    required this.postApplySnapshot,
  });
}

class _NotesSyncResponse {
  final List<domain.Note> serverChanges;
  final List<String> revokedNoteIds;
  final List<String> processedIds;
  // Ids where the server discarded our upload; logged at warn for triage.
  final Set<String> serverWonIds;
  final String syncedAt;

  _NotesSyncResponse({
    required this.serverChanges,
    required this.revokedNoteIds,
    required this.processedIds,
    required this.serverWonIds,
    required this.syncedAt,
  });
}
