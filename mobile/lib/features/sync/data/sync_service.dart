import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/database/app_database.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/logging/log_tags.dart';
import '../../../core/network/dio_provider.dart';
import '../../notes/data/local/note_rows.dart';
import '../../notes/data/repository/note_attachments_repository.dart';
import '../../notes/data/repository/note_revisions_store.dart';
import '../../notes/domain/note.dart';
import '../../notes/domain/note_attachment.dart';
import '../../notes/domain/note_revision.dart';
import '../../reminders/data/reminder_slots.dart';
import '../../tags/data/local/tag_rows.dart';
import 'sync_api.dart';
import 'sync_cursor.dart';

part 'sync_service.g.dart';

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

/// Never compares timestamps: each change names the server version it was
/// written against.
class SyncService {
  SyncService(this._db, this._api, this._attachments, this._revisions)
    : _cursor = SyncCursor(_db);

  final AppDatabase _db;
  final SyncApi _api;
  final NoteAttachmentsRepository _attachments;
  final NoteRevisionsStore _revisions;
  final SyncCursor _cursor;

  Future<void> run() async {
    final start = DateTime.now();
    final counts = await _exchange();
    await _uploadAttachments();
    if (counts == null) return;
    await _attachments.evictCache();
    AppLogger.instance.info(
      LogTags.sync,
      'Sync done in ${DateTime.now().difference(start).inMilliseconds}ms: '
      'pushed=${counts.pushed} pulled=${counts.pulled}',
    );
  }

  /// Pushes and pulls until the feed runs out; null when it stops early.
  Future<({int pushed, int pulled})?> _exchange() async {
    var pending = await _collectChanges();
    var rebaseRounds = 0;
    var didReset = false;
    var pushed = 0;
    var pulled = 0;

    AppLogger.instance.info(
      LogTags.sync,
      'Sync start: queued=${pending.length}',
    );

    for (var request = 0; request < _maxRequestsPerCycle; request++) {
      final cursor = await _cursor.prepare();
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
            LogTags.sync,
            '${rebased.length} change(s) still conflicting; retrying next cycle',
          );
        }
      }

      if (response.resetRequired) {
        if (didReset) {
          AppLogger.instance.warn(
            LogTags.sync,
            'Server asked to reset twice; stopping',
          );
          return null;
        }
        didReset = true;
        AppLogger.instance.info(
          LogTags.sync,
          'Cursor is too old, taking a snapshot',
        );
        await _cursor.reset();
        continue;
      }

      if (!response.hasMore && pending.isEmpty) {
        return (pushed: pushed, pulled: pulled);
      }
    }

    AppLogger.instance.warn(
      LogTags.sync,
      'Sync stopped after $_maxRequestsPerCycle requests',
    );
    return null;
  }

  Future<void> _uploadAttachments() async {
    try {
      await _attachments.sync();
    } catch (error, stack) {
      AppLogger.instance.error(
        LogTags.sync,
        'Attachment upload failed, retrying next cycle',
        error: error,
        stackTrace: stack,
      );
    }
  }

  Future<List<SyncChange>> _collectChanges() async {
    final changes = <SyncChange>[];

    // Tags must go before the notes that use them.
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
      final row = await _db.noteRow(noteId);
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
    NoteRow note, {
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
      noteType: NoteType.fromString(note.noteType),
      localRev: note.localRev,
      baseVersion: note.version,
      title: note.title,
      content: note.content,
      isArchived: note.isArchived,
      background: note.background,
      state:
          note.permission == NotePermission.owner.name ||
              note.state == NoteState.deleted.name
          ? note.state
          : null,
      tagIds: tagIds,
      revisions: revisions,
      isRevisionsOnly: isRevisionsOnly,
    );
  }

  SyncReminderChange _reminderChangeOf(NoteRow note) => SyncReminderChange(
    id: note.id,
    remindAt: note.reminderAt,
    recurrence: ReminderRecurrence.fromString(note.reminderRecurrence),
    baseVersion: note.reminderVersion,
  );

  SyncTagChange _tagChangeOf(TagRow tag) => SyncTagChange(
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

      // On reset the entries are void; the upload results still apply.
      if (response.resetRequired) return;

      for (final entry in response.entries) {
        await _applyEntry(entry, filesToClean, orphanedFiles);
      }

      await _cursor.save(response.nextCursor);

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
        if (change.state == NoteState.deleted.name) {
          await _dropNote(result.id, filesToClean);
          return;
        }
        await _revisions.markSynced(
          change.revisions.map((revision) => revision.id),
        );
        final row = await _db.noteRow(result.id);
        if (row == null) return;
        // A reply that only confirms versions must not move the note's
        // version; only the feed does.
        if (!change.isRevisionsOnly) {
          await _db.writeNote(
            result.id,
            NotesCompanion(
              version: Value(result.version),
              isSynced: Value(row.localRev == change.localRev),
              syncedTitle: Value(change.title),
              syncedContent: Value(change.content),
              syncedBackground: Value(change.background),
              syncedState: Value.absentIfNull(change.state),
            ),
          );
        }
        // Versions that did not fit this push go again.
        if (row.localRev == change.localRev &&
            (await _revisions.pending(result.id, limit: 1)).isNotEmpty) {
          final fresh = await _db.noteRow(result.id);
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
          final prior = await _db.noteRow(result.id);
          if (prior != null &&
              !prior.isSynced &&
              _hasLocalTextChange(prior) &&
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
        final prior = await _db.noteRow(result.id);
        if (prior == null) return;
        await _db.writeNote(result.id, _rebasedOnto(prior, server));
        final row = await _db.noteRow(result.id);
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
        final row = await _db.tagRow(result.id);
        if (row == null) return;
        await _db.writeTag(
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
        await _db.writeTag(
          result.id,
          TagsCompanion(
            version: Value(server.version),
            isSynced: const Value(false),
          ),
        );
        final row = await _db.tagRow(result.id);
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
        final row = await _db.noteRow(result.id);
        if (row == null || row.isPinned != change.isPinned) return;
        await _db.writeNote(
          result.id,
          const NotesCompanion(isPinSynced: Value(true)),
        );

      case SyncStatus.denied:
        // Denied means the note is gone or unshared.
        await _db.writeNote(
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
        final row = await _db.noteRow(result.id);
        if (row == null) return;
        // An edit made during the round trip stays queued, on the new version.
        final pending = _reminderChangeOf(row);
        final settled =
            pending.remindAt == change.remindAt &&
            pending.recurrence == change.recurrence;
        await _db.writeNote(
          result.id,
          NotesCompanion(
            isReminderSynced: Value(settled),
            reminderVersion: Value(result.version),
          ),
        );

      case SyncStatus.conflict:
        // No server copy: the change stays queued.
        if (!result.hasServerCopy) return;
        // Reminder conflicts take the server's copy.
        await _db.writeNote(
          result.id,
          await _reminderOf(result.id, result.serverReminder),
        );

      case SyncStatus.denied:
        // A note the server has never seen keeps its reminder; one it has seen
        // is gone or unshared.
        final denied = await _db.noteRow(result.id);
        if (denied == null || denied.version == null) return;
        await _db.writeNote(result.id, await _reminderOf(result.id, null));

      case SyncStatus.failed:
        break;
    }
  }

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
        await _cursor.removeFromSweep(SyncEntityType.note, entry.entityId);
        final note = entry.note;
        if (note == null) return;
        await _upsertServerNote(note);
        await _revisions.markStale(entry.entityId);

      case SyncEntityType.tag:
        if (entry.isRemove) {
          await _dropTag(entry.entityId);
          return;
        }
        await _cursor.removeFromSweep(SyncEntityType.tag, entry.entityId);
        final tag = entry.tag;
        if (tag != null) await _upsertServerTag(tag);

      case SyncEntityType.pin:
        final row = await _db.noteRow(entry.entityId);
        if (row == null || !row.isPinSynced) return;
        await _db.writeNote(
          entry.entityId,
          NotesCompanion(isPinned: Value(!entry.isRemove)),
        );

      case SyncEntityType.reminder:
        final row = await _db.noteRow(entry.entityId);
        // An unsent local reminder wins.
        if (row == null || !row.isReminderSynced) return;
        await _db.writeNote(
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
        await _cursor.removeFromSweep(
          SyncEntityType.attachments,
          entry.entityId,
        );
        orphanedFiles.addAll(
          await _attachments.applyServerAttachments(
            entry.entityId,
            entry.attachments,
          ),
        );
    }
  }

  /// Unsent local edits win unless [force]; sharing lands either way.
  Future<void> _upsertServerNote(
    SyncServerNote note, {
    bool force = false,
  }) async {
    final row = await _db.noteRow(note.id);
    final keepLocalReminder = row != null && !row.isReminderSynced;
    final serverReminder = !note.hasReminderField || keepLocalReminder
        ? const NotesCompanion()
        : await _reminderOf(note.id, note.reminder);

    if (!force && row != null && !row.isSynced) {
      await _db.writeNote(
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
            syncedTitle: Value(note.title),
            syncedContent: Value(note.content),
            syncedBackground: Value(note.background),
            syncedState: Value(note.state),
            reminderAt: serverReminder.reminderAt,
            reminderRecurrence: serverReminder.reminderRecurrence,
            reminderVersion: serverReminder.reminderVersion,
            isReminderSynced: serverReminder.isReminderSynced,
            reminderSlot: serverReminder.reminderSlot,
          ),
        );
    await _db.setNoteTags(note.id, note.tagIds);
  }

  /// Moves [row] onto the server's newer copy, keeping only the fields
  /// changed on this device.
  NotesCompanion _rebasedOnto(NoteRow row, SyncServerNote server) {
    bool isChangedLocally(Object? local, Object? synced) =>
        !_hasSyncedCopy(row) || local != synced;

    final keepTitle = isChangedLocally(row.title, row.syncedTitle);
    final keepContent = isChangedLocally(row.content, row.syncedContent);
    final keepBackground = isChangedLocally(
      row.background,
      row.syncedBackground,
    );
    final keepState = isChangedLocally(row.state, row.syncedState);
    final keepsAny = keepTitle || keepContent || keepBackground || keepState;

    return _sharingOf(server).copyWith(
      title: keepTitle ? const Value.absent() : Value(server.title),
      content: keepContent ? const Value.absent() : Value(server.content),
      background: keepBackground
          ? const Value.absent()
          : Value(server.background),
      state: keepState ? const Value.absent() : Value(server.state),
      updatedAt: keepsAny
          ? const Value.absent()
          : Value.absentIfNull(server.updatedAt),
      version: Value(server.version),
      isSynced: const Value(false),
      syncedTitle: Value(server.title),
      syncedContent: Value(server.content),
      syncedBackground: Value(server.background),
      syncedState: Value(server.state),
    );
  }

  NotesCompanion _sharingOf(SyncServerNote note) => NotesCompanion(
    noteType: Value(note.noteType),
    permission: Value(note.permission),
    shareIds: Value(encodeShareIds(note.shareIds)),
    sharedById: Value(note.sharedBy?.id),
    sharedByName: Value(note.sharedBy?.name),
    sharedByEmail: Value(note.sharedBy?.email),
    sharedByProfileImage: Value(note.sharedBy?.profileImage),
  );

  Future<void> _upsertServerTag(SyncServerTag tag) async {
    final row = await _db.tagRow(tag.id);
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
    await _db.markNotesUnsynced(noteIds);
  }

  Future<void> _dropNote(String id, Set<String> filesToClean) async {
    await _dropAttachments(id);
    await _revisions.deleteForNote(id);
    await (_db.delete(
      _db.noteTags,
    )..where((tbl) => tbl.noteId.equals(id))).go();
    await (_db.delete(_db.notes)..where((tbl) => tbl.id.equals(id))).go();
    await _cursor.removeFromSweep(SyncEntityType.note, id);
    await _cursor.removeFromSweep(SyncEntityType.attachments, id);
    filesToClean.add(id);
  }

  Future<void> _dropTag(String id) async {
    await (_db.delete(_db.noteTags)..where((tbl) => tbl.tagId.equals(id))).go();
    await (_db.delete(_db.tags)..where((tbl) => tbl.id.equals(id))).go();
    await _cursor.removeFromSweep(SyncEntityType.tag, id);
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
      AttachmentSyncStatus.synced.dbValue,
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

  Future<void> _finishSweep(
    Set<String> filesToClean,
    List<String> orphanedFiles,
  ) async {
    if (!await _cursor.isSweeping()) return;

    final leftovers = await _cursor.leftovers();
    for (final row in leftovers) {
      switch (SyncEntityType.fromString(row.entityType)) {
        case SyncEntityType.note:
          await _dropNote(row.entityId, filesToClean);
        case SyncEntityType.tag:
          await _dropTag(row.entityId);
        case SyncEntityType.attachments:
          await _dropSyncedAttachments(row.entityId, orphanedFiles);
        // Pins and reminders ride on the note payload.
        case SyncEntityType.pin:
        case SyncEntityType.reminder:
        case null:
          break;
      }
    }

    await _cursor.endSweep();

    if (leftovers.isNotEmpty) {
      AppLogger.instance.info(
        LogTags.sync,
        'Snapshot complete: dropped ${leftovers.length} stale row(s)',
      );
    }
  }
}

bool _hasSyncedCopy(NoteRow row) => row.syncedTitle != null;

bool _hasLocalTextChange(NoteRow row) =>
    !_hasSyncedCopy(row) ||
    row.title != row.syncedTitle ||
    row.content != row.syncedContent;
