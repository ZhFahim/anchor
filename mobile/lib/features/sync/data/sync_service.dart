import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/database/app_database.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/network/dio_provider.dart';
import '../../notes/data/local/reminder_slots.dart';
import '../../notes/data/repository/note_attachments_repository.dart';
import '../../notes/data/repository/note_revisions_store.dart';
import '../../notes/domain/note.dart' as domain;
import '../../notes/domain/note_attachment.dart' as domain;
import '../../notes/domain/note_revision.dart';
import 'sync_api.dart';

part 'sync_service.g.dart';

const String _tag = 'Sync';

/// Stops the paging loop if the server never runs out.
const int _maxRequestsPerCycle = 500;

/// How often a rejected change is re-sent before it waits for the next sync.
const int _maxRebaseRounds = 3;

@Riverpod(keepAlive: true)
SyncService syncService(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  final dio = ref.watch(dioProvider);
  final attachments = ref.watch(noteAttachmentsRepositoryProvider);
  final revisions = ref.watch(noteRevisionsStoreProvider);
  return SyncService(db, SyncApi(dio), attachments, revisions);
}

/// Sends up everything that changed on this device, brings down everything that
/// changed elsewhere, and leaves the local database matching the server.
///
/// Nothing here compares timestamps: every change says which server version it
/// was written against, and the server takes it or rejects it.
class SyncService {
  SyncService(this._db, this._api, this._attachments, this._revisions);

  final AppDatabase _db;
  final SyncApi _api;
  final NoteAttachmentsRepository _attachments;
  final NoteRevisionsStore _revisions;

  Future<void> run() async {
    final start = DateTime.now();
    await _uploadAttachments();

    var pending = await _collectChanges();
    var rebaseRounds = 0;
    var didReset = false;
    var pushed = 0;
    var pulled = 0;

    AppLogger.instance.info(_tag, 'Sync start: queued=${pending.length}');

    for (var request = 0; request < _maxRequestsPerCycle; request++) {
      final cursor = await _prepareCursor();
      final batch = takeUnderBudget(
        pending.take(maxChangesPerRequest),
        (change) => change.approximateBytes,
      );
      final response = await _api.sync(cursor: cursor, changes: batch);

      final rebased = await _applyResponse(response, batch);
      pushed += batch.length;
      pulled += response.entries.length;

      pending = pending.sublist(batch.length);
      if (rebased.isNotEmpty) {
        if (rebaseRounds < _maxRebaseRounds) {
          rebaseRounds++;
          pending = [...pending, ...rebased];
        } else {
          AppLogger.instance.warn(
            _tag,
            '${rebased.length} change(s) still conflicting; retrying next cycle',
          );
        }
      }

      if (response.resetRequired) {
        if (didReset) {
          AppLogger.instance.warn(
            _tag,
            'Server asked to reset twice; stopping',
          );
          return;
        }
        didReset = true;
        AppLogger.instance.info(_tag, 'Cursor is too old, taking a snapshot');
        await _resetCursor();
        continue;
      }

      if (!response.hasMore && pending.isEmpty) {
        await _attachments.evictCache();
        AppLogger.instance.info(
          _tag,
          'Sync done in ${DateTime.now().difference(start).inMilliseconds}ms: '
          'pushed=$pushed pulled=$pulled',
        );
        return;
      }
    }

    AppLogger.instance.warn(
      _tag,
      'Sync stopped after $_maxRequestsPerCycle requests',
    );
  }

  Future<void> _uploadAttachments() async {
    try {
      await _attachments.sync();
    } catch (error, stack) {
      AppLogger.instance.error(
        _tag,
        'Attachment upload failed, retrying next cycle',
        error: error,
        stackTrace: stack,
      );
    }
  }

  Future<List<SyncChange>> _collectChanges() async {
    final changes = <SyncChange>[];

    // Tags go first, so a note never arrives before a tag it uses.
    final tags = await (_db.select(
      _db.tags,
    )..where((tbl) => tbl.isSynced.equals(false))).get();
    changes.addAll(tags.map(_tagChangeOf));

    final notes = await (_db.select(
      _db.notes,
    )..where((tbl) => tbl.isSynced.equals(false))).get();
    for (final note in notes) {
      changes.add(await _noteChangeOf(note));
    }

    // A clean note can still hold recorded versions the server has not seen.
    final dirtyNoteIds = {for (final note in notes) note.id};
    for (final noteId in await _revisions.noteIdsWithPending()) {
      if (dirtyNoteIds.contains(noteId)) continue;
      final row = await _noteRow(noteId);
      if (row == null || !row.isSynced) continue;
      changes.add(await _noteChangeOf(row, isRevisionsOnly: true));
    }

    final pins = await (_db.select(
      _db.notes,
    )..where((tbl) => tbl.isPinSynced.equals(false))).get();
    changes.addAll(
      pins.map((note) => SyncPinChange(id: note.id, isPinned: note.isPinned)),
    );

    final reminders = await (_db.select(
      _db.notes,
    )..where((tbl) => tbl.isReminderSynced.equals(false))).get();
    changes.addAll(reminders.map(_reminderChangeOf));

    return changes;
  }

  Future<SyncNoteChange> _noteChangeOf(
    Note note, {
    bool isRevisionsOnly = false,
  }) async {
    final tagIds =
        await (_db.select(_db.noteTags)
              ..where((tbl) => tbl.noteId.equals(note.id)))
            .map((row) => row.tagId)
            .get();
    final recorded = await _revisions.pending(
      note.id,
      limit: maxRevisionsPerNote,
    );

    final revisions = takeUnderBudget(
      [
        for (final revision in recorded)
          SyncNoteRevision(
            id: revision.id,
            version: revision.version,
            title: revision.title,
            content: revision.content,
            cause: revision.cause.name,
            createdAt: revision.createdAt,
          ),
      ],
      (revision) => revision.approximateBytes,
      used: note.title.length + (note.content?.length ?? 0),
    );

    return SyncNoteChange(
      id: note.id,
      localRev: note.localRev,
      baseVersion: note.version,
      title: note.title,
      content: note.content,
      isArchived: note.isArchived,
      background: note.background,
      state: note.state,
      tagIds: tagIds,
      revisions: revisions,
      isRevisionsOnly: isRevisionsOnly,
    );
  }

  SyncReminderChange _reminderChangeOf(Note note) => SyncReminderChange(
    id: note.id,
    remindAt: note.reminderAt,
    recurrence: domain.ReminderRecurrence.fromString(note.reminderRecurrence),
    baseVersion: note.reminderVersion,
  );

  SyncTagChange _tagChangeOf(Tag tag) => SyncTagChange(
    id: tag.id,
    localRev: tag.localRev,
    baseVersion: tag.version,
    name: tag.name,
    color: tag.color,
    isDeleted: tag.isDeleted,
  );

  Future<List<SyncChange>> _applyResponse(
    SyncResponse response,
    List<SyncChange> batch,
  ) async {
    final sent = {
      for (final change in batch) '${change.type}:${change.id}': change,
    };
    final rebased = <SyncChange>[];
    final filesToClean = <String>{};
    final orphanedFiles = <String>[];

    await _db.transaction(() async {
      for (final result in response.results) {
        final change = sent['${result.type}:${result.id}'];
        switch (change) {
          case SyncNoteChange():
            await _applyNoteResult(result, change, rebased, filesToClean);
          case SyncTagChange():
            await _applyTagResult(result, change, rebased);
          case SyncPinChange():
            await _applyPinResult(result, change);
          case SyncReminderChange():
            await _applyReminderResult(result, change);
          case null:
            break;
        }
      }

      // An expired cursor makes the entries meaningless; the upload results
      // are still good.
      if (response.resetRequired) return;

      for (final entry in response.entries) {
        await _applyEntry(entry, filesToClean, orphanedFiles);
      }

      await _db
          .update(_db.syncState)
          .write(SyncStateCompanion(cursor: Value(response.nextCursor)));

      if (!response.hasMore) {
        await _finishSweep(filesToClean, orphanedFiles);
      }
    });

    for (final noteId in filesToClean) {
      await _attachments.deleteLocalFilesForNote(noteId);
    }
    await _attachments.deleteFiles(orphanedFiles);

    return rebased;
  }

  Future<void> _applyNoteResult(
    SyncResult result,
    SyncNoteChange change,
    List<SyncChange> rebased,
    Set<String> filesToClean,
  ) async {
    switch (result.status) {
      case SyncStatus.applied:
        if (change.state == 'deleted') {
          await _dropNote(result.id, filesToClean);
          return;
        }
        await _revisions.markSynced(
          change.revisions.map((revision) => revision.id),
        );
        final row = await _noteRow(result.id);
        if (row == null) return;
        // A revisions-only ack names a version this row's text may not hold
        // yet; only the feed moves the note.
        if (!change.isRevisionsOnly) {
          await _writeNote(
            result.id,
            NotesCompanion(
              version: Value(result.version),
              isSynced: Value(row.localRev == change.localRev),
            ),
          );
        }
        // Versions that did not fit this push go again.
        if (row.localRev == change.localRev &&
            (await _revisions.pending(result.id, limit: 1)).isNotEmpty) {
          final fresh = await _noteRow(result.id);
          if (fresh != null) {
            rebased.add(await _noteChangeOf(fresh, isRevisionsOnly: true));
          }
        }

      case SyncStatus.conflict:
        final server = result.serverNote;
        if (server == null) return;
        if (server.isDeleted) {
          await _dropNote(result.id, filesToClean);
          return;
        }
        await _revisions.markStale(result.id);
        if (!server.canEdit) {
          final prior = await _noteRow(result.id);
          if (prior != null &&
              !prior.isSynced &&
              (prior.title != server.title ||
                  prior.content != server.content)) {
            // Local-only: the server refuses history from a viewer.
            await _revisions.record(
              prior,
              cause: RevisionCause.conflict,
              synced: true,
            );
          }
          await _upsertServerNote(server, force: true);
          return;
        }
        // Re-send the local text on top of the server's version.
        await _writeNote(
          result.id,
          _sharingOf(server).copyWith(
            version: Value(server.version),
            isSynced: const Value(false),
          ),
        );
        final row = await _noteRow(result.id);
        if (row != null) rebased.add(await _noteChangeOf(row));

      case SyncStatus.denied:
        await _dropNote(result.id, filesToClean);

      case SyncStatus.failed:
        break;
    }
  }

  Future<void> _applyTagResult(
    SyncResult result,
    SyncTagChange change,
    List<SyncChange> rebased,
  ) async {
    switch (result.status) {
      case SyncStatus.applied:
        if (change.isDeleted) {
          await _dropTag(result.id);
          return;
        }
        final row = await _tagRow(result.id);
        if (row == null) return;
        await _writeTag(
          result.id,
          TagsCompanion(
            version: Value(result.version),
            isSynced: Value(row.localRev == change.localRev),
          ),
        );

      case SyncStatus.conflict:
        final server = result.serverTag;
        if (server == null) return;
        if (server.id != result.id) {
          await _mergeTagInto(result.id, server);
          return;
        }
        await _writeTag(
          result.id,
          TagsCompanion(
            version: Value(server.version),
            isSynced: const Value(false),
          ),
        );
        final row = await _tagRow(result.id);
        if (row != null) rebased.add(_tagChangeOf(row));

      case SyncStatus.denied:
        await _dropTag(result.id);

      case SyncStatus.failed:
        break;
    }
  }

  Future<void> _applyPinResult(SyncResult result, SyncPinChange change) async {
    switch (result.status) {
      case SyncStatus.applied:
        final row = await _noteRow(result.id);
        if (row == null || row.isPinned != change.isPinned) return;
        await _writeNote(
          result.id,
          const NotesCompanion(isPinSynced: Value(true)),
        );

      case SyncStatus.denied:
        // The note is gone or unshared, so there is nothing left to pin.
        await _writeNote(
          result.id,
          const NotesCompanion(isPinSynced: Value(true)),
        );

      case SyncStatus.conflict:
      case SyncStatus.failed:
        break;
    }
  }

  Future<void> _applyReminderResult(
    SyncResult result,
    SyncReminderChange change,
  ) async {
    switch (result.status) {
      case SyncStatus.applied:
        final row = await _noteRow(result.id);
        // An edit made during the round trip must stay queued.
        if (row == null ||
            row.reminderAt != change.remindAt ||
            row.reminderRecurrence != change.recurrence.name) {
          return;
        }
        await _writeNote(
          result.id,
          NotesCompanion(
            isReminderSynced: const Value(true),
            reminderVersion: Value(result.version),
          ),
        );

      case SyncStatus.conflict:
        // No conflict dialog for a reminder: adopt the server's copy.
        await _writeNote(
          result.id,
          await _reminderOf(result.id, result.serverReminder),
        );

      case SyncStatus.denied:
        // The note is gone or unshared, so the reminder has nothing to ring for.
        await _writeNote(result.id, await _reminderOf(result.id, null));

      case SyncStatus.failed:
        break;
    }
  }

  /// The columns for a server reminder, or for having none.
  Future<NotesCompanion> _reminderOf(
    String noteId,
    SyncServerReminder? reminder,
  ) async => NotesCompanion(
    reminderAt: Value(reminder?.remindAt),
    reminderRecurrence: Value(reminder?.recurrence.name),
    reminderVersion: Value(reminder?.version),
    isReminderSynced: const Value(true),
    reminderSlot: reminder == null
        ? const Value.absent()
        : Value(await ensureReminderSlot(_db, noteId)),
  );

  Future<void> _applyEntry(
    SyncEntry entry,
    Set<String> filesToClean,
    List<String> orphanedFiles,
  ) async {
    switch (entry.entityType) {
      case SyncEntityType.note:
        if (entry.isRemove) {
          await _dropNote(entry.entityId, filesToClean);
          return;
        }
        await _clearSweep(SyncEntityType.note, entry.entityId);
        final note = entry.note;
        if (note == null) return;
        await _upsertServerNote(note);
        await _revisions.markStale(entry.entityId);

      case SyncEntityType.tag:
        if (entry.isRemove) {
          await _dropTag(entry.entityId);
          return;
        }
        await _clearSweep(SyncEntityType.tag, entry.entityId);
        final tag = entry.tag;
        if (tag != null) await _upsertServerTag(tag);

      case SyncEntityType.pin:
        final row = await _noteRow(entry.entityId);
        if (row == null || !row.isPinSynced) return;
        await _writeNote(
          entry.entityId,
          NotesCompanion(isPinned: Value(!entry.isRemove)),
        );

      case SyncEntityType.reminder:
        final row = await _noteRow(entry.entityId);
        // An unsent local reminder wins; it rides up on the next push.
        if (row == null || !row.isReminderSynced) return;
        await _writeNote(
          entry.entityId,
          await _reminderOf(
            entry.entityId,
            entry.isRemove ? null : entry.reminder,
          ),
        );

      case SyncEntityType.attachments:
        if (entry.isRemove) {
          filesToClean.add(entry.entityId);
          await _dropAttachments(entry.entityId);
          return;
        }
        await _clearSweep(SyncEntityType.attachments, entry.entityId);
        orphanedFiles.addAll(
          await _attachments.applyServerAttachments(
            entry.entityId,
            entry.attachments,
          ),
        );
    }
  }

  /// Unsent local edits win: overwriting them would lose work the server never
  /// saw. Sharing isn't part of an edit, so it lands either way.
  Future<void> _upsertServerNote(
    SyncServerNote note, {
    bool force = false,
  }) async {
    final row = await _noteRow(note.id);
    final keepLocalReminder = row != null && !row.isReminderSynced;
    final serverReminder = !note.hasReminderField || keepLocalReminder
        ? const NotesCompanion()
        : await _reminderOf(note.id, note.reminder);

    if (!force && row != null && !row.isSynced) {
      await _writeNote(
        note.id,
        _sharingOf(note).copyWith(
          reminderAt: serverReminder.reminderAt,
          reminderRecurrence: serverReminder.reminderRecurrence,
          reminderVersion: serverReminder.reminderVersion,
          isReminderSynced: serverReminder.isReminderSynced,
          reminderSlot: serverReminder.reminderSlot,
        ),
      );
      return;
    }

    final keepLocalPin = row != null && !row.isPinSynced;
    await _db
        .into(_db.notes)
        .insertOnConflictUpdate(
          _sharingOf(note).copyWith(
            id: Value(note.id),
            title: Value(note.title),
            content: Value(note.content),
            isPinned: keepLocalPin
                ? const Value.absent()
                : Value(note.isPinned),
            isArchived: Value(note.isArchived),
            background: Value(note.background),
            state: Value(note.state),
            updatedAt: Value(note.updatedAt),
            version: Value(note.version),
            isSynced: const Value(true),
            reminderAt: serverReminder.reminderAt,
            reminderRecurrence: serverReminder.reminderRecurrence,
            reminderVersion: serverReminder.reminderVersion,
            isReminderSynced: serverReminder.isReminderSynced,
            reminderSlot: serverReminder.reminderSlot,
          ),
        );
    await _setNoteTags(note.id, note.tagIds);
  }

  NotesCompanion _sharingOf(SyncServerNote note) => NotesCompanion(
    permission: Value(note.permission),
    shareIds: Value(jsonEncode(note.shareIds)),
    sharedById: Value(note.sharedBy?.id),
    sharedByName: Value(note.sharedBy?.name),
    sharedByEmail: Value(note.sharedBy?.email),
    sharedByProfileImage: Value(note.sharedBy?.profileImage),
  );

  Future<void> _upsertServerTag(SyncServerTag tag) async {
    final row = await _tagRow(tag.id);
    if (row != null && !row.isSynced) return;

    await _db
        .into(_db.tags)
        .insertOnConflictUpdate(
          TagsCompanion(
            id: Value(tag.id),
            name: Value(tag.name),
            color: Value(tag.color),
            updatedAt: Value(tag.updatedAt),
            version: Value(tag.version),
            isSynced: const Value(true),
            isDeleted: const Value(false),
          ),
        );
  }

  Future<void> _mergeTagInto(String localId, SyncServerTag server) async {
    final noteIds =
        await (_db.select(_db.noteTags)
              ..where((tbl) => tbl.tagId.equals(localId)))
            .map((row) => row.noteId)
            .get();

    await _dropTag(localId);
    await _upsertServerTag(server);

    if (noteIds.isEmpty) return;
    await _db.batch((batch) {
      batch.insertAll(_db.noteTags, [
        for (final noteId in noteIds)
          NoteTagsCompanion.insert(noteId: noteId, tagId: server.id),
      ], mode: InsertMode.insertOrReplace);
    });
    await (_db.update(_db.notes)..where((tbl) => tbl.id.isIn(noteIds))).write(
      NotesCompanion.custom(
        isSynced: const Constant(false),
        localRev: _db.notes.localRev + const Constant(1),
      ),
    );
  }

  Future<void> _setNoteTags(String noteId, List<String> tagIds) async {
    await (_db.delete(
      _db.noteTags,
    )..where((tbl) => tbl.noteId.equals(noteId))).go();
    if (tagIds.isEmpty) return;

    await _db.batch((batch) {
      batch.insertAll(_db.noteTags, [
        for (final tagId in tagIds)
          NoteTagsCompanion.insert(noteId: noteId, tagId: tagId),
      ], mode: InsertMode.insertOrReplace);
    });
  }

  Future<void> _dropNote(String id, Set<String> filesToClean) async {
    await _dropAttachments(id);
    await _revisions.deleteForNote(id);
    await (_db.delete(
      _db.noteTags,
    )..where((tbl) => tbl.noteId.equals(id))).go();
    await (_db.delete(_db.notes)..where((tbl) => tbl.id.equals(id))).go();
    await _clearSweep(SyncEntityType.note, id);
    await _clearSweep(SyncEntityType.attachments, id);
    filesToClean.add(id);
  }

  Future<void> _dropTag(String id) async {
    await (_db.delete(_db.noteTags)..where((tbl) => tbl.tagId.equals(id))).go();
    await (_db.delete(_db.tags)..where((tbl) => tbl.id.equals(id))).go();
    await _clearSweep(SyncEntityType.tag, id);
  }

  Future<void> _dropAttachments(String noteId) async {
    await (_db.delete(
      _db.noteAttachments,
    )..where((tbl) => tbl.noteId.equals(noteId))).go();
  }

  Future<void> _dropSyncedAttachments(
    String noteId,
    List<String> orphanedFiles,
  ) async {
    final synced = _db.noteAttachments.syncStatus.equals(
      domain.AttachmentSyncStatus.synced.dbValue,
    );
    final rows = await (_db.select(
      _db.noteAttachments,
    )..where((tbl) => tbl.noteId.equals(noteId) & synced)).get();

    for (final row in rows) {
      if (row.localPath != null) orphanedFiles.add(row.localPath!);
    }
    await (_db.delete(
      _db.noteAttachments,
    )..where((tbl) => tbl.noteId.equals(noteId) & synced)).go();
  }

  Future<Note?> _noteRow(String id) => (_db.select(
    _db.notes,
  )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();

  Future<Tag?> _tagRow(String id) => (_db.select(
    _db.tags,
  )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();

  Future<void> _writeNote(String id, NotesCompanion values) async {
    await (_db.update(
      _db.notes,
    )..where((tbl) => tbl.id.equals(id))).write(values);
  }

  Future<void> _writeTag(String id, TagsCompanion values) async {
    await (_db.update(
      _db.tags,
    )..where((tbl) => tbl.id.equals(id))).write(values);
  }

  Future<SyncStateData> _state() async {
    final row = await _db.select(_db.syncState).getSingleOrNull();
    if (row != null) return row;
    await _db.into(_db.syncState).insert(SyncStateCompanion.insert());
    return _db.select(_db.syncState).getSingle();
  }

  Future<String?> _prepareCursor() async {
    final state = await _state();
    if (state.cursor == null && !state.isSweeping) {
      await _beginSweep();
    }
    return state.cursor;
  }

  Future<void> _resetCursor() async {
    await _db.transaction(() async {
      await _db.delete(_db.syncSweep).go();
      await _db
          .update(_db.syncState)
          .write(
            const SyncStateCompanion(
              cursor: Value(null),
              isSweeping: Value(false),
            ),
          );
    });
  }

  /// Lists what we hold before a full download, so anything the server never
  /// sends back can be deleted once it finishes.
  Future<void> _beginSweep() async {
    await _db.transaction(() async {
      await _db.delete(_db.syncSweep).go();

      final noteIds =
          await (_db.selectOnly(_db.notes)
                ..addColumns([_db.notes.id])
                ..where(_db.notes.isSynced.equals(true)))
              .map((row) => row.read(_db.notes.id)!)
              .get();
      final tagIds =
          await (_db.selectOnly(_db.tags)
                ..addColumns([_db.tags.id])
                ..where(_db.tags.isSynced.equals(true)))
              .map((row) => row.read(_db.tags.id)!)
              .get();
      final attachedNoteIds =
          await (_db.selectOnly(_db.noteAttachments, distinct: true)
                ..addColumns([_db.noteAttachments.noteId])
                ..where(
                  _db.noteAttachments.syncStatus.equals(
                    domain.AttachmentSyncStatus.synced.dbValue,
                  ),
                ))
              .map((row) => row.read(_db.noteAttachments.noteId)!)
              .get();

      await _db.batch((batch) {
        batch.insertAll(_db.syncSweep, [
          for (final id in noteIds) _sweepRow(SyncEntityType.note, id),
          for (final id in tagIds) _sweepRow(SyncEntityType.tag, id),
          for (final id in attachedNoteIds)
            _sweepRow(SyncEntityType.attachments, id),
        ], mode: InsertMode.insertOrReplace);
      });

      await _db
          .update(_db.syncState)
          .write(const SyncStateCompanion(isSweeping: Value(true)));
    });
  }

  SyncSweepCompanion _sweepRow(SyncEntityType entityType, String entityId) =>
      SyncSweepCompanion.insert(
        entityType: entityType.name,
        entityId: entityId,
      );

  Future<void> _clearSweep(SyncEntityType entityType, String entityId) async {
    await (_db.delete(_db.syncSweep)..where(
          (tbl) =>
              tbl.entityType.equals(entityType.name) &
              tbl.entityId.equals(entityId),
        ))
        .go();
  }

  Future<void> _finishSweep(
    Set<String> filesToClean,
    List<String> orphanedFiles,
  ) async {
    final state = await _state();
    if (!state.isSweeping) return;

    final leftovers = await _db.select(_db.syncSweep).get();
    for (final row in leftovers) {
      switch (SyncEntityType.fromString(row.entityType)) {
        case SyncEntityType.note:
          await _dropNote(row.entityId, filesToClean);
        case SyncEntityType.tag:
          await _dropTag(row.entityId);
        case SyncEntityType.attachments:
          await _dropSyncedAttachments(row.entityId, orphanedFiles);
        // Both ride on the note payload and reconcile in the notes phase.
        case SyncEntityType.pin:
        case SyncEntityType.reminder:
        case null:
          break;
      }
    }

    await _db.delete(_db.syncSweep).go();
    await _db
        .update(_db.syncState)
        .write(const SyncStateCompanion(isSweeping: Value(false)));

    if (leftovers.isNotEmpty) {
      AppLogger.instance.info(
        _tag,
        'Snapshot complete: dropped ${leftovers.length} stale row(s)',
      );
    }
  }
}
