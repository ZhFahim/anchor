import 'package:anchor/core/database/app_database.dart';
import 'package:anchor/features/notes/data/repository/note_attachments_repository.dart';
import 'package:anchor/features/notes/data/repository/notes_repository.dart';
import 'package:anchor/features/tags/data/repository/tags_repository.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

class MockAttachmentsRepo extends Mock implements NoteAttachmentsRepository {}

/// Local query behavior of NotesRepository/TagsRepository against an
/// in-memory Drift DB. No network involved.
void main() {
  const userId = 'user-1';

  late AppDatabase db;
  late TagsRepository tagsRepo;
  late NotesRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    tagsRepo = TagsRepository(db, MockDio(), MockSecureStorage(), userId);
    repo = NotesRepository(
      db,
      MockDio(),
      MockSecureStorage(),
      tagsRepo,
      MockAttachmentsRepo(),
      userId,
    );
  });

  tearDown(() => db.close());

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
        .insert(
          NoteTagsCompanion(noteId: Value(noteId), tagId: Value(tagId)),
        );
  }

  Future<void> insertImageAttachment(
    String id,
    String noteId, {
    String syncStatus = 'synced',
    int position = 0,
  }) {
    return db
        .into(db.noteAttachments)
        .insert(
          NoteAttachmentsCompanion.insert(
            id: id,
            noteId: noteId,
            type: 'image',
            originalFilename: '$id.jpg',
            mimeType: 'image/jpeg',
            fileSize: 100,
            position: Value(position),
            syncStatus: Value(syncStatus),
          ),
        );
  }

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
      expect(
        note.imagePreviewData.map((p) => p.attachmentId),
        ['img-0', 'img-1', 'img-2', 'img-3'],
      );
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
  });

  group('watchArchivedNotes', () {
    test('shows only archived active notes', () async {
      await insertNote(id: 'archived', isArchived: true);
      await insertNote(id: 'plain');
      await insertNote(id: 'archived-trashed', isArchived: true, state: 'trashed');

      final notes = await repo.watchArchivedNotes().first;

      expect(notes.map((n) => n.id), ['archived']);
    });
  });

  group('tags for note', () {
    test('setTagsForNote replaces the existing associations', () async {
      await insertTag('t1');
      await insertTag('t2');
      await insertTag('t3');
      await insertNote(id: 'n1');

      await tagsRepo.setTagsForNote('n1', ['t1', 't2']);
      await tagsRepo.setTagsForNote('n1', ['t3']);

      expect(await tagsRepo.getTagIdsForNote('n1'), ['t3']);
    });

    test('watchTagsForNote hides deleted tags', () async {
      await insertTag('t1');
      await insertNote(id: 'n1');
      await tagsRepo.setTagsForNote('n1', ['t1']);
      await (db.update(db.tags)..where((tbl) => tbl.id.equals('t1'))).write(
        const TagsCompanion(isDeleted: Value(true)),
      );

      expect(await tagsRepo.watchTagsForNote('n1').first, isEmpty);
    });
  });
}
