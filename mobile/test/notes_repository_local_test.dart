import 'package:anchor/core/database/app_database.dart';
import 'package:anchor/features/auth/domain/user.dart';
import 'package:anchor/features/notes/data/local/note_rows.dart';
import 'package:anchor/features/notes/data/repository/note_attachments_repository.dart';
import 'package:anchor/features/notes/data/repository/note_revisions_store.dart';
import 'package:anchor/features/notes/data/repository/notes_repository.dart';
import 'package:anchor/features/notes/domain/note.dart';
import 'package:anchor/features/notes/domain/note_revision.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAttachmentsRepo extends Mock implements NoteAttachmentsRepository {}

void main() {
  late AppDatabase db;
  late NoteRevisionsStore revisions;
  late MockAttachmentsRepo attachments;
  late NotesRepository repo;

  const author = User(id: 'user-1', email: 'me@example.com', name: 'Me');

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    revisions = NoteRevisionsStore(db, () async => author);
    attachments = MockAttachmentsRepo();
    repo = NotesRepository(db, attachments, revisions);

    when(
      () => attachments.deleteRowsForNote(any()),
    ).thenAnswer((_) async => <String>[]);
    when(() => attachments.deleteFiles(any())).thenAnswer((_) async {});
    when(
      () => attachments.deleteLocalFilesForNote(any()),
    ).thenAnswer((_) async {});
  });

  tearDown(() => db.close());

  test('checklist types survive creation, edits and local reloads', () async {
    const note = Note(
      id: 'checklist',
      title: 'Shopping',
      noteType: NoteType.checklist,
      isSynced: false,
    );
    await repo.createNote(note);
    expect((await repo.getNote(note.id))!.noteType, NoteType.checklist);
    await repo.updateNote(note.copyWith(title: 'Groceries'));
    expect((await repo.watchNote(note.id).first)!.noteType, NoteType.checklist);
    expect((await repo.watchNotes().first).single.noteType, NoteType.checklist);
  });

  Future<void> insertNote({
    required String id,
    String title = 'Note',
    String state = 'active',
    bool isArchived = false,
    bool isPinned = false,
    String permission = 'owner',
    DateTime? updatedAt,
  }) {
    return db
        .into(db.notes)
        .insert(
          NotesCompanion.insert(
            id: id,
            title: title,
            state: Value(state),
            isArchived: Value(isArchived),
            isPinned: Value(isPinned),
            permission: Value(permission),
            updatedAt: Value(updatedAt ?? DateTime.utc(2026, 7, 1)),
          ),
        );
  }

  Future<void> insertTag(String id, {String? name}) {
    return db
        .into(db.tags)
        .insert(TagsCompanion.insert(id: id, name: name ?? 'Tag $id'));
  }

  Future<void> linkTag(String noteId, String tagId) {
    return db
        .into(db.noteTags)
        .insert(NoteTagsCompanion(noteId: Value(noteId), tagId: Value(tagId)));
  }

  Future<void> insertImageAttachment(
    String id,
    String noteId, {
    String syncStatus = 'synced',
    int position = 0,
    String type = 'image',
    String? serverId,
  }) {
    return db
        .into(db.noteAttachments)
        .insert(
          NoteAttachmentsCompanion.insert(
            id: id,
            noteId: noteId,
            type: type,
            originalFilename: '$id.jpg',
            mimeType: 'image/jpeg',
            fileSize: 100,
            position: Value(position),
            syncStatus: Value(syncStatus),
            serverAttachmentId: Value(serverId),
          ),
        );
  }

  List<String> previewIds(Note note) =>
      note.imagePreviewData.map((p) => p.attachmentId).toList();

  group('watchNotes', () {
    test('shows only active, non-archived notes', () async {
      await insertNote(id: 'active');
      await insertNote(id: 'archived', isArchived: true);
      await insertNote(id: 'trashed', state: 'trashed');
      await insertNote(id: 'deleted', state: 'deleted');

      final notes = await repo.watchNotes().first;

      expect(notes.map((n) => n.id), ['active']);
    });

    test('sorts pinned notes first, then by most recently updated', () async {
      await insertNote(id: 'old', updatedAt: DateTime.utc(2026, 7, 1));
      await insertNote(id: 'newest', updatedAt: DateTime.utc(2026, 7, 3));
      await insertNote(
        id: 'pinned-old',
        isPinned: true,
        updatedAt: DateTime.utc(2026, 6, 1),
      );

      final notes = await repo.watchNotes().first;

      expect(notes.map((n) => n.id), ['pinned-old', 'newest', 'old']);
    });

    test('orders notes sharing a timestamp by id, descending', () async {
      final sameMoment = DateTime.utc(2026, 7, 2);
      for (final id in ['n-b', 'n-d', 'n-a', 'n-c']) {
        await insertNote(id: id, updatedAt: sameMoment);
      }

      final notes = await repo.watchNotes().first;

      expect(notes.map((n) => n.id), ['n-d', 'n-c', 'n-b', 'n-a']);
    });

    test('filters by tag and collects all tagIds per note', () async {
      await insertTag('t-work');
      await insertTag('t-home');
      await insertNote(id: 'both');
      await insertNote(id: 'home-only');
      await linkTag('both', 't-work');
      await linkTag('both', 't-home');
      await linkTag('home-only', 't-home');

      final workNotes = await repo.watchNotes(tagId: 't-work').first;

      expect(workNotes.map((n) => n.id), ['both']);
      expect(workNotes.single.tagIds.toSet(), {'t-work', 't-home'});
    });

    test('caps image previews at 4 and hides pending-delete ones', () async {
      await insertNote(id: 'n1');
      for (var i = 0; i < 6; i++) {
        await insertImageAttachment('img-$i', 'n1', position: i);
      }
      await insertImageAttachment(
        'img-deleting',
        'n1',
        syncStatus: 'pending_delete',
        position: 6,
      );

      final note = (await repo.watchNotes().first).single;

      expect(note.imagePreviewData, hasLength(4));
      expect(note.imagePreviewData.map((p) => p.attachmentId), [
        'img-0',
        'img-1',
        'img-2',
        'img-3',
      ]);
      expect(note.attachmentCount, 6);
    });
  });

  group('note lists with tags and pictures', () {
    Future<void> tagAndPicture(String noteId) async {
      // Linked out of order on purpose.
      for (final tagId in ['t-c', 't-a', 't-b']) {
        await linkTag(noteId, tagId);
      }
      await insertImageAttachment('$noteId-p2', noteId, position: 2);
      await insertImageAttachment('$noteId-p0', noteId, position: 0);
      await insertImageAttachment('$noteId-p1', noteId, position: 1);
      await insertImageAttachment(
        '$noteId-audio',
        noteId,
        type: 'audio',
        position: 3,
      );
    }

    setUp(() async {
      for (final tagId in ['t-a', 't-b', 't-c']) {
        await insertTag(tagId);
      }
    });

    test('lists each note once with every tag and its pictures', () async {
      await insertNote(id: 'n1', updatedAt: DateTime.utc(2026, 7, 2));
      await insertNote(id: 'n2', updatedAt: DateTime.utc(2026, 7, 1));
      await tagAndPicture('n1');
      await tagAndPicture('n2');

      final notes = await repo.watchNotes().first;

      expect(notes.map((n) => n.id), ['n1', 'n2']);
      for (final note in notes) {
        expect(note.tagIds, ['t-a', 't-b', 't-c']);
        expect(previewIds(note), [
          '${note.id}-p0',
          '${note.id}-p1',
          '${note.id}-p2',
        ]);
        expect(note.imagePreviewData.every((p) => p.noteId == note.id), isTrue);
        expect(note.attachmentCount, 4, reason: 'the voice note counts too');
      }
    });

    test('keeps the order when notes carry different numbers of tags and '
        'pictures', () async {
      await insertNote(id: 'plain', updatedAt: DateTime.utc(2026, 7, 3));
      await insertNote(id: 'busy', updatedAt: DateTime.utc(2026, 7, 2));
      await insertNote(
        id: 'pinned',
        isPinned: true,
        updatedAt: DateTime.utc(2026, 7, 1),
      );
      await tagAndPicture('busy');
      await linkTag('pinned', 't-b');

      final notes = await repo.watchNotes().first;

      expect(notes.map((n) => n.id), ['pinned', 'plain', 'busy']);
      expect(notes.first.tagIds, ['t-b']);
      expect(notes[1].tagIds, isEmpty);
      expect(notes[1].imagePreviewData, isEmpty);
    });

    test('a filtered list still carries every tag on its notes', () async {
      await insertNote(id: 'n1');
      await tagAndPicture('n1');

      final notes = await repo.watchNotes(tagId: 't-c').first;

      expect(notes.single.tagIds, ['t-a', 't-b', 't-c']);
      expect(previewIds(notes.single), ['n1-p0', 'n1-p1', 'n1-p2']);
    });

    test('shows an uploaded picture once, under its server id', () async {
      await insertNote(id: 'n1');
      await insertImageAttachment('local-1', 'n1', serverId: 'srv-1');
      await insertImageAttachment(
        'srv-1',
        'n1',
        serverId: 'srv-1',
        position: 1,
      );

      final note = (await repo.watchNotes().first).single;

      expect(previewIds(note), ['srv-1']);
    });

    test('the trash and the archive carry tags and pictures too', () async {
      await insertNote(id: 'trashed', state: 'trashed');
      await insertNote(id: 'archived', isArchived: true);
      await tagAndPicture('trashed');
      await tagAndPicture('archived');

      final trashed = (await repo.watchTrashedNotes().first).single;
      final archived = (await repo.watchArchivedNotes().first).single;

      expect(trashed.tagIds, ['t-a', 't-b', 't-c']);
      expect(previewIds(trashed), ['trashed-p0', 'trashed-p1', 'trashed-p2']);
      expect(archived.tagIds, ['t-a', 't-b', 't-c']);
      expect(previewIds(archived), [
        'archived-p0',
        'archived-p1',
        'archived-p2',
      ]);
    });

    test('updates when a tag or a picture is added', () async {
      await insertNote(id: 'n1');
      final emitted = repo.watchNotes().take(3).toList();
      await pumpEventQueue();

      await linkTag('n1', 't-a');
      await pumpEventQueue();
      await insertImageAttachment('p0', 'n1');

      final lists = await emitted;
      expect(lists.map((notes) => notes.single.tagIds), [
        isEmpty,
        ['t-a'],
        ['t-a'],
      ]);
      expect(previewIds(lists.last.single), ['p0']);
    });
  });

  group('watchNote', () {
    test('re-emits when the stored note changes', () async {
      await insertNote(id: 'n1', title: 'First');
      final emitted = repo.watchNote('n1').take(2).toList();

      await (db.update(db.notes)..where((tbl) => tbl.id.equals('n1'))).write(
        const NotesCompanion(title: Value('Second')),
      );

      expect((await emitted).map((n) => n?.title), ['First', 'Second']);
    });

    test('carries the note tags', () async {
      await insertNote(id: 'n1');
      await insertTag('t-work');
      await insertTag('t-home');
      await linkTag('n1', 't-work');
      await linkTag('n1', 't-home');

      final note = await repo.watchNote('n1').first;

      expect(note!.tagIds.toSet(), {'t-work', 't-home'});
    });

    test('emits null once the note is gone', () async {
      await insertNote(id: 'n1');
      final emitted = repo.watchNote('n1').take(2).toList();

      await (db.delete(db.notes)..where((tbl) => tbl.id.equals('n1'))).go();

      expect((await emitted).last, isNull);
    });
  });

  group('watchTrashedNotes', () {
    test('shows owned trashed notes but not shared ones', () async {
      await insertNote(id: 'mine', state: 'trashed');
      await insertNote(id: 'shared', state: 'trashed', permission: 'editor');
      await insertNote(id: 'still-active');

      final notes = await repo.watchTrashedNotes().first;

      expect(notes.map((n) => n.id), ['mine']);
    });

    test('orders notes trashed together by id, descending', () async {
      final sameMoment = DateTime.utc(2026, 7, 2);
      for (final id in ['n-b', 'n-d', 'n-a', 'n-c']) {
        await insertNote(id: id, state: 'trashed', updatedAt: sameMoment);
      }

      final notes = await repo.watchTrashedNotes().first;

      expect(notes.map((n) => n.id), ['n-d', 'n-c', 'n-b', 'n-a']);
    });
  });

  group('watchArchivedNotes', () {
    test('shows only archived active notes', () async {
      await insertNote(id: 'archived', isArchived: true);
      await insertNote(id: 'plain');
      await insertNote(
        id: 'archived-trashed',
        isArchived: true,
        state: 'trashed',
      );

      final notes = await repo.watchArchivedNotes().first;

      expect(notes.map((n) => n.id), ['archived']);
    });

    test('orders notes archived together by id, descending', () async {
      final sameMoment = DateTime.utc(2026, 7, 2);
      for (final id in ['n-b', 'n-d', 'n-a', 'n-c']) {
        await insertNote(id: id, isArchived: true, updatedAt: sameMoment);
      }

      final notes = await repo.watchArchivedNotes().first;

      expect(notes.map((n) => n.id), ['n-d', 'n-c', 'n-b', 'n-a']);
    });

    test('a shared note archives in place and queues to sync', () async {
      final edited = DateTime.utc(2026, 7, 1);
      await insertNote(id: 'n1', permission: 'viewer', updatedAt: edited);

      await repo.archive(['n1']);

      final note = (await repo.watchArchivedNotes().first).single;
      expect(note.id, 'n1');
      expect(note.updatedAt?.toUtc(), edited);
      expect(note.isSynced, isFalse);
    });
  });

  group('deleting', () {
    test('trashes your own notes and removes shared ones', () async {
      await insertNote(id: 'mine');
      await insertNote(id: 'theirs', permission: 'editor');

      await repo.trash(['mine', 'theirs']);

      final rows = await db.select(db.notes).get();
      expect(
        {for (final row in rows) row.id: row.state},
        {'mine': 'trashed', 'theirs': 'deleted'},
      );
      expect(rows.every((row) => !row.isSynced), isTrue);
      expect(await repo.watchTrashedNotes().first, hasLength(1));
    });
  });

  group('edit time', () {
    Future<Note> stored(String id) async => (await repo.getNote(id))!;
    final edited = DateTime.utc(2026, 7, 1);

    test('a pin or tag change leaves it alone', () async {
      await insertTag('t1');
      await insertNote(id: 'n1', updatedAt: edited);

      await repo.updateNote(
        (await stored('n1')).copyWith(isPinned: true, tagIds: ['t1']),
      );

      final note = await stored('n1');
      expect(note.updatedAt?.toUtc(), edited);
      expect(note.isSynced, isFalse);
    });

    test('a text change moves it', () async {
      await insertNote(id: 'n1', updatedAt: edited);

      await repo.updateNote((await stored('n1')).copyWith(content: 'milk'));

      expect((await stored('n1')).updatedAt?.toUtc(), isNot(edited));
    });
  });

  group('tags for note', () {
    test('setNoteTags queues the tags and leaves the note alone', () async {
      final edited = DateTime.utc(2026, 7, 1);
      await insertTag('t1');
      await insertNote(id: 'n1', permission: 'viewer', updatedAt: edited);

      await repo.setNoteTags('n1', ['t1']);

      final note = (await repo.getNote('n1'))!;
      expect(note.tagIds, ['t1']);
      expect(note.isSynced, isFalse);
      expect(note.updatedAt?.toUtc(), edited);
      expect(await revisions.watch('n1').first, isEmpty);
    });

    test('adding and removing a tag on several notes keeps the rest', () async {
      await insertTag('t1');
      await insertTag('t2');
      await insertNote(id: 'n1');
      await insertNote(id: 'n2');
      await db.setNoteTags('n1', ['t1']);

      await repo.addTags(['n1', 'n2'], ['t2']);
      expect(await db.tagIdsOfNote('n1'), unorderedEquals(['t1', 't2']));
      expect(await db.tagIdsOfNote('n2'), ['t2']);

      await repo.removeTags(['n1', 'n2'], ['t2']);
      expect(await db.tagIdsOfNote('n1'), ['t1']);
      expect(await db.tagIdsOfNote('n2'), isEmpty);
      expect((await repo.getNote('n2'))!.isSynced, isFalse);
    });

    test('setting a note\'s tags replaces the ones it had', () async {
      await insertTag('t1');
      await insertTag('t2');
      await insertTag('t3');
      await insertNote(id: 'n1');

      await db.setNoteTags('n1', ['t1', 't2']);
      await db.setNoteTags('n1', ['t3']);

      expect(await db.tagIdsOfNote('n1'), ['t3']);
    });
  });

  group('history', () {
    Future<Note> stored(String id) async => (await repo.getNote(id))!;

    test('an edit keeps what the note said before it', () async {
      await insertNote(id: 'n1', title: 'Groceries');
      await repo.updateNote((await stored('n1')).copyWith(content: 'milk'));

      final kept = await revisions.watch('n1').first;

      expect(kept, hasLength(1));
      expect(kept.single.title, 'Groceries');
      expect(kept.single.content, isNull);
      expect(kept.single.cause, RevisionCause.edit);
      expect(kept.single.author?.id, 'user-1');
    });

    test('a change that leaves the text alone keeps no version', () async {
      await insertNote(id: 'n1', title: 'Groceries');
      await repo.updateNote((await stored('n1')).copyWith(isArchived: true));

      expect(await revisions.watch('n1').first, isEmpty);
    });

    test('successive edits fold into the version already kept', () async {
      await insertNote(id: 'n1', title: 'Groceries');
      await repo.updateNote((await stored('n1')).copyWith(content: 'milk'));
      await repo.updateNote(
        (await stored('n1')).copyWith(content: 'milk, eggs'),
      );

      final kept = await revisions.watch('n1').first;

      expect(kept, hasLength(1));
      expect(kept.single.content, isNull);
    });

    test('restoring swaps the text and keeps what it replaced', () async {
      await insertNote(id: 'n1', title: 'Groceries');
      await repo.updateNote((await stored('n1')).copyWith(content: 'milk'));
      final earlier = (await revisions.watch('n1').first).single;

      await repo.restoreVersion('n1', earlier);

      final note = await stored('n1');
      expect(note.content, isNull);
      expect(note.isSynced, isFalse);

      final kept = await revisions.watch('n1').first;
      expect(kept.first.cause, RevisionCause.restore);
      expect(kept.first.content, 'milk');
    });

    test('undoing a restore keeps what was typed since as a version', () async {
      await insertNote(id: 'n1', title: 'Groceries');
      await repo.updateNote((await stored('n1')).copyWith(content: 'milk'));
      final earlier = (await revisions.watch('n1').first).single;
      await repo.restoreVersion('n1', earlier);
      await repo.updateNote(
        (await stored('n1')).copyWith(content: 'typed after'),
      );

      await repo.undoRestore('n1', (
        previousTitle: 'Groceries',
        previousContent: 'milk',
        revision: earlier,
      ));

      expect((await stored('n1')).content, 'milk');
      final kept = await revisions.watch('n1').first;
      expect(kept.map((revision) => revision.content), contains('typed after'));
    });

    test('undoing a restore at once adds no version', () async {
      await insertNote(id: 'n1', title: 'Groceries');
      await repo.updateNote((await stored('n1')).copyWith(content: 'milk'));
      final earlier = (await revisions.watch('n1').first).single;
      await repo.restoreVersion('n1', earlier);
      final versions = (await revisions.watch('n1').first).length;

      await repo.undoRestore('n1', (
        previousTitle: 'Groceries',
        previousContent: 'milk',
        revision: earlier,
      ));

      expect((await stored('n1')).content, 'milk');
      expect(await revisions.watch('n1').first, hasLength(versions));
    });

    test('a version waiting to go up is not pruned away', () async {
      await insertNote(id: 'n1', title: 'Groceries');
      await repo.updateNote((await stored('n1')).copyWith(content: 'milk'));
      await (db.update(db.noteRevisions)).write(
        NoteRevisionsCompanion(
          createdAt: Value(
            DateTime.now()
                .subtract(const Duration(days: 200))
                .millisecondsSinceEpoch,
          ),
        ),
      );

      await revisions.prune('n1');

      expect(await revisions.watch('n1').first, hasLength(1));
    });

    test('permanently deleting a note takes its history with it', () async {
      await insertNote(id: 'n1', title: 'Groceries');
      await repo.updateNote((await stored('n1')).copyWith(content: 'milk'));

      await repo.deleteForever(['n1']);

      expect(await revisions.watch('n1').first, isEmpty);
    });
  });
}
