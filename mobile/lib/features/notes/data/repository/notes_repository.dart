import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:drift/drift.dart' as drift;
import '../../../../core/database/app_database.dart';
import '../../../../core/sync/sync_outbox_dao.dart';
import '../../../../core/sync/sync_worker.dart';
import '../../domain/note.dart' as domain;
import '../../domain/note_attachment.dart' as domain;
import '../../../tags/data/repository/tags_repository.dart';
import 'note_attachments_repository.dart';

part 'notes_repository.g.dart';

@riverpod
NotesRepository notesRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  final tagsRepo = ref.watch(tagsRepositoryProvider);
  final attachmentsRepo = ref.watch(noteAttachmentsRepositoryProvider);

  // Read lazily to avoid a provider-graph cycle.
  void triggerSync() {
    try {
      ref.read(syncWorkerProvider).requestSync();
    } catch (e) {
      debugPrint('Sync trigger failed: $e');
    }
  }

  return NotesRepository(db, tagsRepo, attachmentsRepo, triggerSync);
}

class NotesRepository {
  final AppDatabase _db;
  final TagsRepository _tagsRepo;
  final NoteAttachmentsRepository _attachmentsRepo;
  final void Function() _triggerSync;
  late final SyncOutboxDao _outbox = SyncOutboxDao(_db);

  NotesRepository(
    this._db,
    this._tagsRepo,
    this._attachmentsRepo,
    this._triggerSync,
  );

  // Watch only active notes
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
            _db.noteAttachments.syncStatus
                .equals(domain.AttachmentSyncStatus.pendingDelete.dbValue)
                .not(),
      ),
    ]);

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

    return query.watch().map(_groupNoteRows);
  }

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
                  _db.noteAttachments.syncStatus
                      .equals(domain.AttachmentSyncStatus.pendingDelete.dbValue)
                      .not(),
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
      // Trash screen only shows owned notes (not shared notes that someone
      // else trashed).
      yield _groupNoteRows(rows).where((n) => n.isOwner).toList();
    }
  }

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
                  _db.noteAttachments.syncStatus
                      .equals(domain.AttachmentSyncStatus.pendingDelete.dbValue)
                      .not(),
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

    return query.watch().map(_groupNoteRows);
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
    final stamped = note.copyWith(
      updatedAt: DateTime.now(),
      state: domain.NoteState.active,
    );

    await _db.transaction(() async {
      await _db
          .into(_db.notes)
          .insert(
            _mapToData(stamped),
            mode: drift.InsertMode.insertOrReplace,
          );
      await _tagsRepo.setTagsForNote(note.id, note.tagIds);
      await _enqueueUpsert(stamped);
    });

    _triggerSync();
  }

  Future<void> updateNote(domain.Note note) async {
    final stamped = note.copyWith(updatedAt: DateTime.now());

    await _db.transaction(() async {
      await _db.update(_db.notes).replace(_mapToData(stamped));
      await _tagsRepo.setTagsForNote(note.id, note.tagIds);
      await _enqueueUpsert(stamped);
    });

    _triggerSync();
  }

  Future<void> deleteNote(String id) async {
    await _stateTransition(id, domain.NoteState.trashed);
  }

  Future<void> restoreNote(String id) async {
    await _stateTransition(id, domain.NoteState.active);
  }

  Future<void> archiveNote(String id) => _toggleArchive(id, true);
  Future<void> unarchiveNote(String id) => _toggleArchive(id, false);

  Future<void> _toggleArchive(String id, bool archived) async {
    final now = DateTime.now();
    await _db.transaction(() async {
      await (_db.update(_db.notes)..where((tbl) => tbl.id.equals(id))).write(
        NotesCompanion(
          isArchived: drift.Value(archived),
          updatedAt: drift.Value(now),
          isSynced: const drift.Value(false),
        ),
      );
      final note = await getNote(id);
      if (note != null) await _enqueueUpsert(note.copyWith(updatedAt: now));
    });
    _triggerSync();
  }

  Future<void> _stateTransition(String id, domain.NoteState newState) async {
    final now = DateTime.now();
    await _db.transaction(() async {
      await (_db.update(_db.notes)..where((tbl) => tbl.id.equals(id))).write(
        NotesCompanion(
          state: drift.Value(newState.name),
          updatedAt: drift.Value(now),
          isSynced: const drift.Value(false),
        ),
      );
      final note = await getNote(id);
      if (note != null) await _enqueueUpsert(note.copyWith(updatedAt: now));
    });
    _triggerSync();
  }

  Future<int> bulkDeleteNotes(List<String> ids) async {
    if (ids.isEmpty) return 0;
    final now = DateTime.now();

    await _db.transaction(() async {
      await (_db.update(_db.notes)..where((tbl) => tbl.id.isIn(ids))).write(
        NotesCompanion(
          state: const drift.Value('trashed'),
          updatedAt: drift.Value(now),
          isSynced: const drift.Value(false),
        ),
      );
      for (final id in ids) {
        final note = await getNote(id);
        if (note != null) {
          await _enqueueUpsert(note.copyWith(updatedAt: now));
        }
      }
    });

    _triggerSync();
    return ids.length;
  }

  Future<int> bulkArchiveNotes(List<String> ids) async {
    if (ids.isEmpty) return 0;
    final now = DateTime.now();

    await _db.transaction(() async {
      await (_db.update(_db.notes)..where((tbl) => tbl.id.isIn(ids))).write(
        NotesCompanion(
          isArchived: const drift.Value(true),
          updatedAt: drift.Value(now),
          isSynced: const drift.Value(false),
        ),
      );
      for (final id in ids) {
        final note = await getNote(id);
        if (note != null) {
          await _enqueueUpsert(note.copyWith(updatedAt: now));
        }
      }
    });

    _triggerSync();
    return ids.length;
  }

  Future<void> permanentDelete(String id) async {
    await _attachmentsRepo.deleteAllLocalForNote(id);

    final now = DateTime.now();
    await _db.transaction(() async {
      await (_db.update(_db.notes)..where((tbl) => tbl.id.equals(id))).write(
        NotesCompanion(
          state: const drift.Value('deleted'),
          updatedAt: drift.Value(now),
          isSynced: const drift.Value(false),
        ),
      );
      await (_db.delete(
        _db.noteTags,
      )..where((tbl) => tbl.noteId.equals(id))).go();

      final row = await (_db.select(
        _db.notes,
      )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
      await _outbox.enqueue(
        entityType: 'note',
        entityId: id,
        op: 'delete',
        payloadJson: jsonEncode(<String, dynamic>{}),
        baseSyncVersion: row?.syncVersion,
        clientUpdatedAt: now,
      );
    });

    _triggerSync();
  }

  Future<void> _enqueueUpsert(domain.Note note) async {
    final row = await (_db.select(
      _db.notes,
    )..where((tbl) => tbl.id.equals(note.id))).getSingleOrNull();
    final payload = <String, dynamic>{
      'title': note.title,
      'content': note.content,
      'isPinned': note.isPinned,
      'isArchived': note.isArchived,
      'background': note.background,
      'state': note.state.name,
      'tagIds': note.tagIds,
    };
    await _outbox.enqueue(
      entityType: 'note',
      entityId: note.id,
      op: 'upsert',
      payloadJson: jsonEncode(payload),
      baseSyncVersion: row?.syncVersion,
      clientUpdatedAt: note.updatedAt,
    );
  }

  List<domain.Note> _groupNoteRows(
    List<drift.TypedResult> rows,
  ) {
    final noteMap = <String, domain.Note>{};
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

    return noteMap.entries
        .map(
          (e) => e.value.copyWith(
            imagePreviewData: imagePreviewsMap[e.key] ?? [],
          ),
        )
        .toList();
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

  Note _mapToData(domain.Note note) {
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
      isSynced: false,
      syncVersion: null,
    );
  }
}
