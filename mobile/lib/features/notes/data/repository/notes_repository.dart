import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:drift/drift.dart' as drift;
import '../../../../core/database/app_database.dart';
import '../../../../core/network/dio_provider.dart';
import '../../domain/note.dart' as domain;
import '../../../tags/data/repository/tags_repository.dart';

part 'notes_repository.g.dart';

const _lastSyncKey = 'last_synced_at';

@riverpod
NotesRepository notesRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  final dio = ref.watch(dioProvider);
  const storage = FlutterSecureStorage();
  final tagsRepo = ref.watch(tagsRepositoryProvider);
  return NotesRepository(db, dio, storage, tagsRepo);
}

class NotesRepository {
  final AppDatabase _db;
  final Dio _dio;
  final FlutterSecureStorage _storage;
  final TagsRepository _tagsRepo;

  NotesRepository(this._db, this._dio, this._storage, this._tagsRepo);

  // Watch only active notes
  // Uses a left outer join to fetch notes and their tags in a single query
  Stream<List<domain.Note>> watchNotes({String? tagId}) {
    final query = _db.select(_db.notes).join([
      drift.leftOuterJoin(
        _db.noteTags,
        _db.noteTags.noteId.equalsExp(_db.notes.id),
      ),
    ]);

    // Apply filters - exclude archived notes from main list
    query.where(_db.notes.state.equals('active'));
    query.where(_db.notes.isArchived.equals(false));

    if (tagId != null) {
      // If filtering by tag, we first need to find note IDs that have this tag
      // Then fetch those notes with ALL their tags
      // This is slightly complex to do in one pure join if we want ALL tags for the filtered notes
      // Simpler approach: Filter the join, but this limits the tags we get back to just the filtered one
      // Correct approach with Drift: Use subquery or separate filter logic

      // For now, to keep it simple and fast:
      // 1. Join is already set up
      // 2. Add where clause on the joined table
      // 3. BUT this will filter out other tags for the same note in the result set if we are not careful
      // The standard pattern for "Filter by Tag but get all Tags" is:
      // Filter on Note ID where Note ID in (SELECT noteId FROM noteTags WHERE tagId = ?)

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
    ]);

    // Watch the query - emits when notes or noteTags change
    return query.watch().map((rows) {
      // Group rows by note ID to handle one-to-many relationship
      final noteMap = <String, domain.Note>{};

      for (final row in rows) {
        final note = row.readTable(_db.notes);
        final tagId = row.readTableOrNull(_db.noteTags)?.tagId;

        if (!noteMap.containsKey(note.id)) {
          noteMap[note.id] = _mapToDomain(note, []);
        }

        if (tagId != null) {
          final currentNote = noteMap[note.id]!;
          if (!currentNote.tagIds.contains(tagId)) {
            noteMap[note.id] = currentNote.copyWith(
              tagIds: [...currentNote.tagIds, tagId],
            );
          }
        }
      }

      return noteMap.values.toList();
    });
  }

  // Watch trashed notes for Trash screen
  Stream<List<domain.Note>> watchTrashedNotes() {
    final query =
        _db.select(_db.notes).join([
            drift.leftOuterJoin(
              _db.noteTags,
              _db.noteTags.noteId.equalsExp(_db.notes.id),
            ),
          ])
          ..where(_db.notes.state.equals('trashed'))
          ..orderBy([
            drift.OrderingTerm(
              expression: _db.notes.updatedAt,
              mode: drift.OrderingMode.desc,
            ),
          ]);

    return query.watch().map((rows) {
      final noteMap = <String, domain.Note>{};

      for (final row in rows) {
        final note = row.readTable(_db.notes);
        final tagId = row.readTableOrNull(_db.noteTags)?.tagId;

        if (!noteMap.containsKey(note.id)) {
          noteMap[note.id] = _mapToDomain(note, []);
        }

        if (tagId != null) {
          final currentNote = noteMap[note.id]!;
          if (!currentNote.tagIds.contains(tagId)) {
            noteMap[note.id] = currentNote.copyWith(
              tagIds: [...currentNote.tagIds, tagId],
            );
          }
        }
      }

      return noteMap.values.toList();
    });
  }

  // Watch archived notes for Archive screen
  Stream<List<domain.Note>> watchArchivedNotes() {
    final query =
        _db.select(_db.notes).join([
            drift.leftOuterJoin(
              _db.noteTags,
              _db.noteTags.noteId.equalsExp(_db.notes.id),
            ),
          ])
          ..where(_db.notes.state.equals('active'))
          ..where(_db.notes.isArchived.equals(true))
          ..orderBy([
            drift.OrderingTerm(
              expression: _db.notes.updatedAt,
              mode: drift.OrderingMode.desc,
            ),
          ]);

    return query.watch().map((rows) {
      final noteMap = <String, domain.Note>{};

      for (final row in rows) {
        final note = row.readTable(_db.notes);
        final tagId = row.readTableOrNull(_db.noteTags)?.tagId;

        if (!noteMap.containsKey(note.id)) {
          noteMap[note.id] = _mapToDomain(note, []);
        }

        if (tagId != null) {
          final currentNote = noteMap[note.id]!;
          if (!currentNote.tagIds.contains(tagId)) {
            noteMap[note.id] = currentNote.copyWith(
              tagIds: [...currentNote.tagIds, tagId],
            );
          }
        }
      }

      return noteMap.values.toList();
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
      final syncedAt = data['syncedAt'] as String;

      // 4. Process server changes with conflict resolution
      await _db.transaction(() async {
        for (final serverNote in serverChanges) {
          // If server note is deleted (tombstone), remove it locally
          if (serverNote.isDeleted) {
            await (_db.delete(
              _db.noteTags,
            )..where((tbl) => tbl.noteId.equals(serverNote.id))).go();
            await (_db.delete(
              _db.notes,
            )..where((tbl) => tbl.id.equals(serverNote.id))).go();
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
                  isSynced: const drift.Value(true),
                ),
              );
              await _tagsRepo.setTagsForNote(serverNote.id, serverNote.tagIds);
            }
          }
        }

        // Mark all successfully pushed notes as synced
        final processedIds =
            (data['processedIds'] as List?)?.cast<String>() ?? [];
        for (final id in processedIds) {
          // Check if the note was a tombstone - if so, delete it locally
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
            await (_db.update(_db.notes)..where((tbl) => tbl.id.equals(id)))
                .write(const NotesCompanion(isSynced: drift.Value(true)));
          }
        }
      });

      // 5. Save new sync timestamp
      await _storage.write(key: _lastSyncKey, value: syncedAt);
    } catch (e) {
      // Sync failed, will retry later
    }
  }

  // Clear all local data
  Future<void> clearAll() async {
    // Clear all notes from DB
    await _db.delete(_db.notes).go();
    await _db.delete(_db.noteTags).go();
    // Clear sync timestamp
    await _storage.delete(key: _lastSyncKey);
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
      isSynced: isSynced,
    );
  }
}
