import 'dart:async';

import 'package:drift/drift.dart' as drift;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/logging/log_tags.dart';
import '../../../../core/network/sync_requester.dart';
import '../../../reminders/data/reminder_slots.dart';
import '../../domain/note.dart';
import '../../domain/note_attachment.dart';
import '../../domain/note_history.dart';
import '../../domain/note_revision.dart';
import '../../domain/user_summary.dart';
import '../local/note_rows.dart';
import 'note_attachments_repository.dart';
import 'note_revisions_store.dart';

part 'notes_repository.g.dart';

@Riverpod(keepAlive: true)
NotesRepository notesRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  final attachmentsRepo = ref.watch(noteAttachmentsRepositoryProvider);
  final revisions = ref.watch(noteRevisionsStoreProvider);
  return NotesRepository(db, attachmentsRepo, revisions);
}

const int maxImagePreviews = 4;

typedef _NoteFilter = drift.Expression<bool> Function($NotesTable tbl);

/// Nothing here talks to the server.
class NotesRepository {
  final AppDatabase _db;
  final NoteAttachmentsRepository _attachmentsRepo;
  final NoteRevisionsStore _revisions;

  NotesRepository(this._db, this._attachmentsRepo, this._revisions);

  /// Active, unarchived notes, pinned first. With [tagId], only the notes
  /// carrying that tag.
  Stream<List<Note>> watchNotes({String? tagId}) {
    return _watchNoteList((tbl) {
      final listed =
          tbl.state.equals(NoteState.active.name) &
          tbl.isArchived.equals(false);
      if (tagId == null) return listed;
      return listed &
          tbl.id.isInQuery(
            _db.selectOnly(_db.noteTags)
              ..addColumns([_db.noteTags.noteId])
              ..where(_db.noteTags.tagId.equals(tagId)),
          );
    }, isPinnedFirst: true);
  }

  /// Only notes this user owns.
  Stream<List<Note>> watchTrashedNotes() {
    return _watchNoteList(
      (tbl) =>
          tbl.state.equals(NoteState.trashed.name) &
          tbl.permission.equals(NotePermission.owner.name),
    );
  }

  Stream<List<Note>> watchArchivedNotes() {
    return _watchNoteList(
      (tbl) =>
          tbl.state.equals(NoteState.active.name) & tbl.isArchived.equals(true),
    );
  }

  Stream<List<Note>> _watchNoteList(
    _NoteFilter filter, {
    bool isPinnedFirst = false,
  }) {
    final changes = _db.tableUpdates(
      drift.TableUpdateQuery.onAllTables([
        _db.notes,
        _db.noteTags,
        _db.noteAttachments,
      ]),
    );
    return _readOnChange(
      changes,
      () => _readNoteList(filter, isPinnedFirst: isPinnedFirst),
    );
  }

  Future<List<Note>> _readNoteList(
    _NoteFilter filter, {
    required bool isPinnedFirst,
  }) async {
    final rows =
        await (_db.select(_db.notes)
              ..where(filter)
              ..orderBy([
                if (isPinnedFirst)
                  (tbl) => drift.OrderingTerm(
                    expression: tbl.isPinned,
                    mode: drift.OrderingMode.desc,
                  ),
                (tbl) => drift.OrderingTerm(
                  expression: tbl.updatedAt,
                  mode: drift.OrderingMode.desc,
                ),
                (tbl) => drift.OrderingTerm(
                  expression: tbl.id,
                  mode: drift.OrderingMode.desc,
                ),
              ]))
            .get();
    if (rows.isEmpty) return const [];

    final listedIds = _db.selectOnly(_db.notes)
      ..addColumns([_db.notes.id])
      ..where(filter(_db.notes));

    final tagIdsOf = <String, List<String>>{};
    final links =
        await (_db.select(_db.noteTags)
              ..where((tbl) => tbl.noteId.isInQuery(listedIds))
              ..orderBy([
                (tbl) => drift.OrderingTerm(expression: tbl.noteId),
                (tbl) => drift.OrderingTerm(expression: tbl.tagId),
              ]))
            .get();
    for (final link in links) {
      (tagIdsOf[link.noteId] ??= []).add(link.tagId);
    }

    final previewsOf = <String, List<NoteImagePreview>>{};
    final fileIdsOf = <String, Set<String>>{};
    // The text read from each picture, by attachment.
    final pictureTextsOf = <String, Map<String, String>>{};
    final files =
        await (_db.select(_db.noteAttachments)
              ..where(
                (tbl) =>
                    tbl.noteId.isInQuery(listedIds) &
                    tbl.syncStatus.isNotValue(
                      AttachmentSyncStatus.pendingDelete.dbValue,
                    ),
              )
              ..orderBy([
                (tbl) => drift.OrderingTerm(expression: tbl.position),
                (tbl) => drift.OrderingTerm(expression: tbl.id),
              ]))
            .get();
    for (final file in files) {
      final attachmentId = file.serverAttachmentId ?? file.id;
      final isNew = (fileIdsOf[file.noteId] ??= {}).add(attachmentId);
      final pictureText = file.pictureText;
      if (pictureText != null && pictureText.isNotEmpty) {
        (pictureTextsOf[file.noteId] ??= {})[attachmentId] = pictureText;
      }
      if (!isNew || file.type != AttachmentType.image.name) continue;
      final previews = previewsOf[file.noteId] ??= [];
      if (previews.length < maxImagePreviews) {
        previews.add(
          NoteImagePreview(
            attachmentId: attachmentId,
            noteId: file.noteId,
            filename: file.originalFilename,
            localPath: file.localPath,
          ),
        );
      }
    }

    return [
      for (final row in rows)
        noteFromRow(
          row,
          tagIds: tagIdsOf[row.id] ?? const [],
          imagePreviews: previewsOf[row.id] ?? const [],
          attachmentCount: fileIdsOf[row.id]?.length ?? 0,
          pictureText: pictureTextsOf[row.id]?.values.join('\n\n') ?? '',
        ),
    ];
  }

  Future<Note?> getNote(String id) async {
    final row = await _db.noteRow(id);
    if (row == null) return null;
    return noteFromRow(row, tagIds: await _db.tagIdsOfNote(id));
  }

  Stream<Note?> watchNote(String id) {
    final query = _db.select(_db.notes).join([
      drift.leftOuterJoin(
        _db.noteTags,
        _db.noteTags.noteId.equalsExp(_db.notes.id),
      ),
    ])..where(_db.notes.id.equals(id));

    return query.watch().map((rows) {
      if (rows.isEmpty) return null;

      final tagIds = <String>[];
      for (final row in rows) {
        final tagId = row.readTableOrNull(_db.noteTags)?.tagId;
        if (tagId != null && !tagIds.contains(tagId)) {
          tagIds.add(tagId);
        }
      }

      return noteFromRow(rows.first.readTable(_db.notes), tagIds: tagIds);
    });
  }

  Future<void> createNote(Note note) async {
    await _db.transaction(() async {
      await _db
          .into(_db.notes)
          .insert(
            NotesCompanion.insert(
              id: note.id,
              title: note.title,
              content: drift.Value(note.content),
              isPinned: drift.Value(note.isPinned),
              isArchived: drift.Value(note.isArchived),
              isInvisible: drift.Value(note.isInvisible),
              background: drift.Value(note.background),
              state: drift.Value(NoteState.active.name),
              updatedAt: drift.Value(DateTime.now().toUtc()),
              createdAt: drift.Value(DateTime.now().toUtc()),
              isSynced: const drift.Value(false),
              localRev: const drift.Value(1),
              // The server creates notes unpinned.
              isPinSynced: drift.Value(!note.isPinned),
            ),
            mode: drift.InsertMode.insertOrReplace,
          );
      await _db.setNoteTags(note.id, note.tagIds);
    });

    AppLogger.instance.info(
      LogTags.notes,
      'createNote id=${note.id} title.len=${note.title.length} '
      'content.len=${note.content?.length ?? 0} tags=${note.tagIds.length}',
    );

    scheduleAppSync(trigger: 'NotesRepo.createNote');
  }

  Future<void> updateNote(Note note) async {
    await _db.transaction(() async {
      final prior = await _db.noteRow(note.id);
      if (prior == null) return;
      if (prior.isFrozen) {
        // Only what is this person's own changes on a frozen note.
        note = note.copyWith(
          title: prior.title,
          content: prior.content,
          background: prior.background,
          state: NoteState.fromString(prior.state),
        );
      }

      if (prior.title != note.title || prior.content != note.content) {
        await _revisions.record(prior);
      }
      final noteChanged =
          prior.title != note.title ||
          prior.content != note.content ||
          prior.background != note.background ||
          prior.state != note.state.name;

      await _db.writeNote(
        note.id,
        NotesCompanion(
          title: drift.Value(note.title),
          content: drift.Value(note.content),
          isPinned: drift.Value(note.isPinned),
          isArchived: drift.Value(note.isArchived),
          background: drift.Value(note.background),
          state: drift.Value(note.state.name),
          updatedAt: noteChanged
              ? drift.Value(DateTime.now().toUtc())
              : const drift.Value.absent(),
          isSynced: const drift.Value(false),
          localRev: drift.Value(prior.localRev + 1),
          isPinSynced: prior.isPinned == note.isPinned
              ? const drift.Value.absent()
              : const drift.Value(false),
        ),
      );
      await _db.setNoteTags(note.id, note.tagIds);
    });

    AppLogger.instance.info(
      LogTags.notes,
      'updateNote id=${note.id} title.len=${note.title.length} '
      'content.len=${note.content?.length ?? 0} tags=${note.tagIds.length}',
    );

    scheduleAppSync(trigger: 'NotesRepo.updateNote');
  }

  /// Rewrites the note's stored content with [change], as an edit; nothing
  /// happens when [change] gives null.
  Future<void> changeContent(
    String noteId,
    String? Function(String? content) change, {
    double? keepAt,
  }) async {
    final note = await getNote(noteId);
    if (note == null) return;
    final content = change(note.content);
    if (content == null || content == note.content) return;
    // One write, so the list doesn't first move the edited note up and then
    // back to its place (placed there after the change, as a dragged note
    // is): that showed as a jerk of the cards.
    await _db.transaction(() async {
      await updateNote(note.copyWith(content: content));
      if (keepAt != null) await setPosition(noteId, keepAt);
    });
  }

  /// What the note says now is kept as a version of its own.
  Future<void> restoreVersion(String noteId, NoteRevision revision) async {
    await _db.transaction(() async {
      final prior = await _db.noteRow(noteId);
      if (prior == null || prior.isFrozen) return;
      if (prior.title == revision.title && prior.content == revision.content) {
        return;
      }

      await _revisions.record(prior, cause: RevisionCause.restore);
      await _db.writeNote(
        noteId,
        NotesCompanion(
          title: drift.Value(revision.title),
          content: drift.Value(revision.content),
          updatedAt: drift.Value(DateTime.now().toUtc()),
          isSynced: const drift.Value(false),
          localRev: drift.Value(prior.localRev + 1),
        ),
      );
    });

    AppLogger.instance.info(
      LogTags.notes,
      'restoreVersion id=$noteId revision=${revision.id}',
    );

    scheduleAppSync(trigger: 'NotesRepo.restoreVersion');
  }

  /// What changed since the restore is kept as a version of its own.
  Future<void> undoRestore(String noteId, RestoredVersion restored) async {
    await _db.transaction(() async {
      final prior = await _db.noteRow(noteId);
      if (prior == null) return;
      final revision = restored.revision;
      if (prior.title != revision.title || prior.content != revision.content) {
        await _revisions.record(prior, cause: RevisionCause.restore);
      }
      await _db.writeNote(
        noteId,
        NotesCompanion(
          title: drift.Value(restored.previousTitle),
          content: drift.Value(restored.previousContent),
          updatedAt: drift.Value(DateTime.now().toUtc()),
          isSynced: const drift.Value(false),
          localRev: drift.Value(prior.localRev + 1),
        ),
      );
    });
    AppLogger.instance.info(LogTags.notes, 'undoRestore id=$noteId');
    scheduleAppSync(trigger: 'NotesRepo.undoRestore');
  }

  /// Reminders sync on their own.
  Future<void> setReminder(String noteId, NoteReminder? reminder) async {
    await _db.transaction(() async {
      final prior = await _db.noteRow(noteId);
      if (prior == null) return;

      final slot = reminder == null
          ? null
          : await ensureReminderSlot(_db, noteId);

      await _db.writeNote(
        noteId,
        NotesCompanion(
          reminderAt: drift.Value(reminder?.remindAt),
          reminderRecurrence: drift.Value(reminder?.recurrence.name),
          isReminderSynced: const drift.Value(false),
          reminderSlot: slot == null
              ? const drift.Value.absent()
              : drift.Value(slot),
        ),
      );
    });

    AppLogger.instance.info(
      LogTags.notes,
      'setReminder id=$noteId at=${reminder?.remindAt ?? 'none'} '
      'repeat=${reminder?.recurrence.name ?? 'none'}',
    );
    scheduleAppSync(trigger: 'NotesRepo.setReminder');
  }

  Future<void> archive(List<String> ids) async {
    if (ids.isEmpty) return;
    await _writeArchived(ids, isArchived: true);
    scheduleAppSync(trigger: 'NotesRepo.archive');
  }

  Future<void> unarchive(List<String> ids) async {
    if (ids.isEmpty) return;
    await _writeArchived(ids, isArchived: false);
    scheduleAppSync(trigger: 'NotesRepo.unarchive');
  }

  /// Marking a shared note deleted leaves the share. This person's own
  /// frozen notes stay; returns how many went.
  Future<int> trash(List<String> ids) async {
    if (ids.isEmpty) return 0;
    final count = await _db.transaction(() async {
      final shared =
          await (_db.select(_db.notes)..where(
                (tbl) =>
                    tbl.id.isIn(ids) &
                    tbl.permission.equals(NotePermission.owner.name).not(),
              ))
              .map((row) => row.id)
              .get();
      final frozen =
          await (_db.select(_db.notes)..where(
                (tbl) =>
                    tbl.id.isIn(ids) &
                    tbl.permission.equals(NotePermission.owner.name) &
                    tbl.isFrozen.equals(true),
              ))
              .map((row) => row.id)
              .get();
      final owned = ids
          .where((id) => !shared.contains(id) && !frozen.contains(id))
          .toList();
      if (owned.isNotEmpty) await _writeState(owned, NoteState.trashed);
      if (shared.isNotEmpty) await _writeState(shared, NoteState.deleted);
      return owned.length + shared.length;
    });
    scheduleAppSync(trigger: 'NotesRepo.trash');
    return count;
  }

  Future<void> restore(List<String> ids) async {
    if (ids.isEmpty) return;
    await _writeState(ids, NoteState.active);
    scheduleAppSync(trigger: 'NotesRepo.restore');
  }

  /// Marked deleted here; the rows go once the server has been told. Files
  /// are deleted only after the transaction commits.
  Future<void> deleteForever(List<String> ids) async {
    if (ids.isEmpty) return;
    final files = <String>[];
    await _db.transaction(() async {
      for (final id in ids) {
        files.addAll(await _attachmentsRepo.deleteRowsForNote(id));
        await _revisions.deleteForNote(id);
      }
      await _writeState(ids, NoteState.deleted);
      await (_db.delete(
        _db.noteTags,
      )..where((tbl) => tbl.noteId.isIn(ids))).go();
    });

    await _attachmentsRepo.deleteFiles(files);
    for (final id in ids) {
      await _attachmentsRepo.deleteLocalFilesForNote(id);
    }
    scheduleAppSync(trigger: 'NotesRepo.deleteForever');
  }

  /// Pins sync on their own.
  Future<void> setPinned(List<String> ids, bool isPinned) async {
    if (ids.isEmpty) return;

    await (_db.update(_db.notes)..where((tbl) => tbl.id.isIn(ids))).write(
      NotesCompanion(
        isPinned: drift.Value(isPinned),
        isPinSynced: const drift.Value(false),
      ),
    );

    scheduleAppSync(trigger: 'NotesRepo.setPinned');
  }

  /// Shows the notes frozen (or not) at once, once the server has taken
  /// it; the feed brings the rest. Nothing goes up for it.
  Future<void> markFrozen(List<String> ids, {required bool isFrozen}) async {
    if (ids.isEmpty) return;
    await (_db.update(_db.notes)..where((tbl) => tbl.id.isIn(ids))).write(
      NotesCompanion(isFrozen: drift.Value(isFrozen)),
    );
  }

  /// Locks the notes with [lock], or unlocks them (null). The lock is this
  /// person's own and goes up with each note.
  Future<void> setLock(List<String> ids, NoteLock? lock) async {
    if (ids.isEmpty) return;
    await (_db.update(_db.notes)..where((tbl) => tbl.id.isIn(ids))).write(
      NotesCompanion.custom(
        lock: drift.Constant(lock?.name),
        isSynced: const drift.Constant(false),
        localRev: _db.nextLocalRev,
      ),
    );
    AppLogger.instance.info(
      LogTags.notes,
      'setLock count=${ids.length} lock=${lock?.name ?? 'none'}',
    );
    scheduleAppSync(trigger: 'NotesRepo.setLock');
  }

  /// Makes the notes invisible for this person (left out of the lists,
  /// found by search), or shows them again. Their own, like a lock, and
  /// goes up with each note.
  Future<void> setInvisible(
    List<String> ids, {
    required bool isInvisible,
  }) async {
    if (ids.isEmpty) return;
    await (_db.update(_db.notes)..where((tbl) => tbl.id.isIn(ids))).write(
      NotesCompanion.custom(
        isInvisible: drift.Constant(isInvisible),
        isSynced: const drift.Constant(false),
        localRev: _db.nextLocalRev,
      ),
    );
    AppLogger.instance.info(
      LogTags.notes,
      'setInvisible count=${ids.length} invisible=$isInvisible',
    );
    scheduleAppSync(trigger: 'NotesRepo.setInvisible');
  }

  /// Puts a note where it was dragged among the notes; it stays there until it
  /// is next edited, and goes up with the note.
  Future<void> setPosition(String noteId, double position) async {
    await (_db.update(_db.notes)..where((tbl) => tbl.id.equals(noteId))).write(
      NotesCompanion.custom(
        position: drift.Constant(position),
        positionedAt: drift.Constant(DateTime.now().toUtc()),
        isSynced: const drift.Constant(false),
        localRev: _db.nextLocalRev,
      ),
    );
    scheduleAppSync(trigger: 'NotesRepo.setPosition');
  }

  /// Gives the notes one colour or pattern (null for none). Only notes this
  /// person can edit change; returns the ids that did.
  Future<List<String>> setBackground(
    List<String> ids,
    String? background,
  ) async {
    if (ids.isEmpty) return const [];
    final changed = await _db.transaction(() async {
      final editable =
          await (_db.select(_db.notes)..where(
                (tbl) =>
                    tbl.id.isIn(ids) &
                    tbl.permission.isIn([
                      NotePermission.owner.name,
                      NotePermission.editor.name,
                    ]) &
                    tbl.isFrozen.equals(false),
              ))
              .map((row) => row.id)
              .get();
      if (editable.isEmpty) return const <String>[];
      await (_db.update(
        _db.notes,
      )..where((tbl) => tbl.id.isIn(editable))).write(
        NotesCompanion.custom(
          background: drift.Constant(background),
          updatedAt: drift.Constant(DateTime.now().toUtc()),
          isSynced: const drift.Constant(false),
          localRev: _db.nextLocalRev,
        ),
      );
      return editable;
    });

    if (changed.isNotEmpty) {
      AppLogger.instance.info(
        LogTags.notes,
        'setBackground count=${changed.length} background=$background',
      );
      scheduleAppSync(trigger: 'NotesRepo.setBackground');
    }
    return changed;
  }

  Future<void> addTags(List<String> ids, List<String> tagIds) async {
    if (ids.isEmpty || tagIds.isEmpty) return;

    await _db.transaction(() async {
      await _db.batch((batch) {
        batch.insertAll(_db.noteTags, [
          for (final noteId in ids)
            for (final tagId in tagIds)
              NoteTagsCompanion.insert(noteId: noteId, tagId: tagId),
        ], mode: drift.InsertMode.insertOrReplace);
      });

      await _db.markNotesUnsynced(ids);
    });

    scheduleAppSync(trigger: 'NotesRepo.addTags');
  }

  Future<void> removeTags(List<String> ids, List<String> tagIds) async {
    if (ids.isEmpty || tagIds.isEmpty) return;

    await _db.transaction(() async {
      await (_db.delete(
        _db.noteTags,
      )..where((tbl) => tbl.noteId.isIn(ids) & tbl.tagId.isIn(tagIds))).go();
      await _db.markNotesUnsynced(ids);
    });

    scheduleAppSync(trigger: 'NotesRepo.removeTags');
  }

  Future<void> setNoteTags(String noteId, List<String> tagIds) async {
    await _db.transaction(() async {
      await _db.setNoteTags(noteId, tagIds);
      await _db.markNotesUnsynced([noteId]);
    });
    scheduleAppSync(trigger: 'NotesRepo.setNoteTags');
  }

  Future<void> _writeState(List<String> ids, NoteState state) async {
    await (_db.update(_db.notes)..where((tbl) => tbl.id.isIn(ids))).write(
      NotesCompanion.custom(
        state: drift.Constant(state.name),
        updatedAt: drift.Variable(DateTime.now().toUtc()),
        isSynced: const drift.Constant(false),
        localRev: _db.nextLocalRev,
      ),
    );
  }

  Future<void> _writeArchived(
    List<String> ids, {
    required bool isArchived,
  }) async {
    await (_db.update(_db.notes)..where((tbl) => tbl.id.isIn(ids))).write(
      NotesCompanion.custom(
        isArchived: drift.Constant(isArchived),
        isSynced: const drift.Constant(false),
        localRev: _db.nextLocalRev,
      ),
    );
  }
}

/// The note a stored row holds.
Note noteFromRow(
  NoteRow row, {
  List<String> tagIds = const [],
  List<NoteImagePreview> imagePreviews = const [],
  int attachmentCount = 0,
  String pictureText = '',
}) {
  return Note(
    id: row.id,
    title: row.title,
    content: row.content,
    isPinned: row.isPinned,
    isArchived: row.isArchived,
    background: row.background,
    state: NoteState.fromString(row.state),
    updatedAt: row.updatedAt,
    createdAt: row.createdAt,
    position: row.position,
    positionedAt: row.positionedAt,
    tagIds: tagIds,
    permission: NotePermission.fromString(row.permission),
    shareIds: decodeShareIds(row.shareIds),
    sharedBy: row.sharedById != null
        ? UserSummary(
            id: row.sharedById!,
            name: row.sharedByName ?? '',
            email: row.sharedByEmail ?? '',
            profileImage: row.sharedByProfileImage,
          )
        : null,
    lock: NoteLock.fromString(row.lock),
    isFrozen: row.isFrozen,
    isInvisible: row.isInvisible ?? false,
    isSynced: row.isSynced,
    reminderSlot: row.reminderSlot,
    imagePreviewData: imagePreviews,
    attachmentCount: attachmentCount,
    pictureText: pictureText,
    reminder: row.reminderAt == null
        ? null
        : NoteReminder(
            remindAt: row.reminderAt!,
            recurrence: ReminderRecurrence.fromString(row.reminderRecurrence),
            version: row.reminderVersion ?? 0,
          ),
  );
}

/// Emits [read] now and after every [changes] event. Reads never overlap,
/// and a read overtaken by changes is dropped for a fresh one.
Stream<T> _readOnChange<T>(Stream<Object?> changes, Future<T> Function() read) {
  final controller = StreamController<T>();
  StreamSubscription<Object?>? subscription;
  var isReading = false;
  var isStale = false;
  var isCancelled = false;
  bool isDone() => isCancelled || controller.isClosed;

  Future<void> readLatest() async {
    if (isReading) {
      isStale = true;
      return;
    }
    isReading = true;
    do {
      isStale = false;
      try {
        final value = await read();
        if (!isStale && !isDone()) controller.add(value);
      } catch (error, stack) {
        if (!isStale && !isDone()) controller.addError(error, stack);
      }
    } while (isStale && !isDone());
    isReading = false;
  }

  controller
    ..onListen = () {
      subscription = changes.listen(
        (_) => readLatest(),
        onError: controller.addError,
        onDone: controller.close,
      );
      readLatest();
    }
    ..onCancel = () {
      isCancelled = true;
      return subscription?.cancel();
    };
  return controller.stream;
}
