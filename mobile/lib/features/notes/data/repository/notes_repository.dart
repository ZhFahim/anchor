import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:drift/drift.dart' as drift;
import '../../../../core/database/app_database.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/providers/active_user_id_provider.dart';
import '../../domain/note.dart' as domain;
import '../../domain/note_attachment.dart' as domain;
import '../../../tags/data/repository/tags_repository.dart';
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
      updatedAt: DateTime.now(),
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

    // Trigger sync in background
    sync();
  }

  Future<void> updateNote(domain.Note note) async {
    final noteWithTimestamp = note.copyWith(updatedAt: DateTime.now());

    await _db
        .update(_db.notes)
        .replace(_mapToData(noteWithTimestamp, isSynced: false));
    await _tagsRepo.setTagsForNote(note.id, note.tagIds);

    // Trigger sync in background
    sync();
  }

  // Soft delete - moves note to trash
  Future<void> deleteNote(String id) async {
    final now = DateTime.now();

    await (_db.update(_db.notes)..where((tbl) => tbl.id.equals(id))).write(
      NotesCompanion(
        state: const drift.Value('trashed'),
        updatedAt: drift.Value(now),
        isSynced: const drift.Value(false),
      ),
    );

    sync();
  }

  // Restore from trash
  Future<void> restoreNote(String id) async {
    final now = DateTime.now();

    await (_db.update(_db.notes)..where((tbl) => tbl.id.equals(id))).write(
      NotesCompanion(
        state: const drift.Value('active'),
        updatedAt: drift.Value(now),
        isSynced: const drift.Value(false),
      ),
    );

    sync();
  }

  // Archive a note
  Future<void> archiveNote(String id) async {
    final now = DateTime.now();

    await (_db.update(_db.notes)..where((tbl) => tbl.id.equals(id))).write(
      NotesCompanion(
        isArchived: const drift.Value(true),
        updatedAt: drift.Value(now),
        isSynced: const drift.Value(false),
      ),
    );

    sync();
  }

  // Unarchive a note
  Future<void> unarchiveNote(String id) async {
    final now = DateTime.now();

    await (_db.update(_db.notes)..where((tbl) => tbl.id.equals(id))).write(
      NotesCompanion(
        isArchived: const drift.Value(false),
        updatedAt: drift.Value(now),
        isSynced: const drift.Value(false),
      ),
    );

    sync();
  }

  // Bulk delete notes
  Future<int> bulkDeleteNotes(List<String> ids) async {
    if (ids.isEmpty) return 0;
    final now = DateTime.now();

    await (_db.update(_db.notes)..where((tbl) => tbl.id.isIn(ids))).write(
      NotesCompanion(
        state: const drift.Value('trashed'),
        updatedAt: drift.Value(now),
        isSynced: const drift.Value(false),
      ),
    );

    sync();
    return ids.length;
  }

  // Bulk archive notes
  Future<int> bulkArchiveNotes(List<String> ids) async {
    if (ids.isEmpty) return 0;
    final now = DateTime.now();

    await (_db.update(_db.notes)..where((tbl) => tbl.id.isIn(ids))).write(
      NotesCompanion(
        isArchived: const drift.Value(true),
        updatedAt: drift.Value(now),
        isSynced: const drift.Value(false),
      ),
    );

    sync();
    return ids.length;
  }

  // Permanent delete - sets state to deleted (tombstone)
  // The note will be removed locally after sync confirms server received it
  Future<void> permanentDelete(String id) async {
    // Clean up local attachment files and DB records
    await _attachmentsRepo.deleteAllLocalForNote(id);

    final now = DateTime.now();
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

    sync();
  }

  // Bi-directional sync with server
  Future<void> sync() async {
    try {
      // 1. Get last sync timestamp
      final lastSyncedAt = await _storage.read(key: _lastSyncKey);

      // 2. Get all unsynced local notes (including tombstones)
      final unsyncedRows = await (_db.select(
        _db.notes,
      )..where((tbl) => tbl.isSynced.equals(false))).get();

      final localChanges = <Map<String, dynamic>>[];
      for (final row in unsyncedRows) {
        final tagIds = await _tagsRepo.getTagIdsForNote(row.id);
        final note = _mapToDomain(row, tagIds);
        localChanges.add({
          'id': note.id,
          'title': note.title,
          'content': note.content,
          'isPinned': note.isPinned,
          'isArchived': note.isArchived,
          'background': note.background,
          'state': note.state.name,
          'tagIds': note.tagIds,
          'updatedAt': note.updatedAt?.toIso8601String(),
        });
      }

      // 3. Send sync request to server
      final response = await _dio.post(
        '/api/notes/sync',
        data: {'lastSyncedAt': lastSyncedAt, 'changes': localChanges},
      );

      final data = response.data as Map<String, dynamic>;
      final serverChanges = (data['serverChanges'] as List)
          .map((e) => domain.Note.fromJson(e as Map<String, dynamic>))
          .toList();
      final revokedNoteIds =
          (data['revokedSharedNoteIds'] as List?)?.cast<String>() ?? [];
      final syncedAt = data['syncedAt'] as String;

      final processedIds =
          (data['processedIds'] as List?)?.cast<String>() ?? [];

      final noteIdsForFileCleanup = <String>[];

      // 4. Process server changes
      await _db.transaction(() async {
        // First handle revocations - delete these notes
        for (final revokedId in revokedNoteIds) {
          // Remove attachment rows so reactive streams update immediately
          await (_db.delete(
            _db.noteAttachments,
          )..where((tbl) => tbl.noteId.equals(revokedId))).go();
          await (_db.delete(
            _db.noteTags,
          )..where((tbl) => tbl.noteId.equals(revokedId))).go();
          await (_db.delete(
            _db.notes,
          )..where((tbl) => tbl.id.equals(revokedId))).go();
          noteIdsForFileCleanup.add(revokedId);
        }

        for (final serverNote in serverChanges) {
          // If server note is deleted (tombstone), remove it locally
          if (serverNote.isDeleted) {
            await (_db.delete(
              _db.noteAttachments,
            )..where((tbl) => tbl.noteId.equals(serverNote.id))).go();
            await (_db.delete(
              _db.noteTags,
            )..where((tbl) => tbl.noteId.equals(serverNote.id))).go();
            await (_db.delete(
              _db.notes,
            )..where((tbl) => tbl.id.equals(serverNote.id))).go();
            noteIdsForFileCleanup.add(serverNote.id);
            continue;
          }

          final localNote = await (_db.select(
            _db.notes,
          )..where((tbl) => tbl.id.equals(serverNote.id))).getSingleOrNull();

          if (localNote == null) {
            // Note doesn't exist locally - insert it
            await _db
                .into(_db.notes)
                .insert(
                  _mapToData(serverNote, isSynced: true),
                  mode: drift.InsertMode.insertOrReplace,
                );
            await _tagsRepo.setTagsForNote(serverNote.id, serverNote.tagIds);
          } else {
            // Note exists - compare timestamps
            final serverUpdatedAt = serverNote.updatedAt;
            final localUpdatedAt = localNote.updatedAt;

            // Server wins if it's newer or equal (server is source of truth)
            if (serverUpdatedAt != null &&
                (localUpdatedAt == null ||
                    serverUpdatedAt.isAfter(localUpdatedAt) ||
                    serverUpdatedAt.isAtSameMomentAs(localUpdatedAt))) {
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
                  sharedByProfileImage: drift.Value(
                    serverNote.sharedBy?.profileImage,
                  ),
                  isSynced: const drift.Value(true),
                ),
              );
              await _tagsRepo.setTagsForNote(serverNote.id, serverNote.tagIds);
            }
          }
        }
      });

      // Clean up local attachment files for revoked/deleted notes after the
      // transaction has committed
      for (final noteId in noteIdsForFileCleanup) {
        await _attachmentsRepo.deleteLocalFilesForNote(noteId);
      }

      // 5. Sync pending attachment uploads and deletes with server
      await _attachmentsRepo.sync();

      // 6. Fetch fresh attachment metadata for notes that changed this cycle
      await _attachmentsRepo.fetchAttachmentsForNotes(
        serverChanges.where((n) => !n.isDeleted).map((n) => n.id).toList(),
      );

      // 7. Mark notes as synced
      await _db.transaction(() async {
        for (final id in processedIds) {
          final note = await (_db.select(
            _db.notes,
          )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
          if (note != null && note.state == 'deleted') {
            await (_db.delete(
              _db.noteTags,
            )..where((tbl) => tbl.noteId.equals(id))).go();
            await (_db.delete(
              _db.notes,
            )..where((tbl) => tbl.id.equals(id))).go();
          } else {
            final hasPending = await _attachmentsRepo
                .hasPendingAttachmentsForNote(id);
            if (!hasPending) {
              await (_db.update(_db.notes)..where((tbl) => tbl.id.equals(id)))
                  .write(const NotesCompanion(isSynced: drift.Value(true)));
            }
          }
        }
      });

      // 8. Save new sync timestamp
      await _storage.write(key: _lastSyncKey, value: syncedAt);
    } catch (e) {
      // Sync failed, will retry later (handled by sync loop)
    }
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
