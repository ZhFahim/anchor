import 'dart:async';

import 'package:anchor/features/notes/data/repository/notes_repository.dart';
import 'package:anchor/features/notes/domain/note.dart';
import 'package:anchor/features/notes/presentation/note_editor_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockNotesRepository extends Mock implements NotesRepository {}

class FakeEditor implements NoteEditorContent {
  FakeEditor(this.text);

  String text;

  @override
  String? get content => '{"ops":[{"insert":"$text\\n"}]}';

  @override
  String? get plainText => text;

  @override
  bool? matches(String? content) => content == this.content;
}

void main() {
  late MockNotesRepository repo;
  late StreamController<Note?> stored;

  setUpAll(() => registerFallbackValue(const Note(id: 'fallback', title: '')));

  setUp(() {
    repo = MockNotesRepository();
    stored = StreamController<Note?>.broadcast();
    when(() => repo.watchNote(any())).thenAnswer((_) => stored.stream);
    when(() => repo.createNote(any())).thenAnswer((_) async {});
    when(() => repo.updateNote(any())).thenAnswer((_) async {});
  });

  tearDown(() => stored.close());

  NoteEditorController open(
    FakeEditor editor, {
    Note? note,
    String? tagId,
    VoidCallback? onNoteDeleted,
  }) => NoteEditorController(
    notes: repo,
    sharesOf: (_) async => const [],
    editor: editor,
    newNoteTagIds: [?tagId],
    onNoteDeleted: onNoteDeleted ?? () {},
    note: note,
  );

  const note = Note(
    id: 'n1',
    title: 'Groceries',
    content: '{"ops":[{"insert":"milk\\n"}]}',
  );

  testWidgets('saves two seconds after the last change', (tester) async {
    final editor = FakeEditor('milk');
    final draft = open(editor, note: note);

    editor.text = 'milk and eggs';
    draft.contentChanged();
    await tester.pump(const Duration(seconds: 1));
    verifyNever(() => repo.updateNote(any()));

    await tester.pump(const Duration(seconds: 2));
    final saved =
        verify(() => repo.updateNote(captureAny())).captured.single as Note;
    expect(saved.content, contains('milk and eggs'));
    expect(saved.title, 'Groceries');
    draft.dispose();
  });

  testWidgets('a new note is kept once it holds something, with its tag', (
    tester,
  ) async {
    final editor = FakeEditor('');
    final empty = open(editor, tagId: 't1');

    empty.flushOnLeave();
    await tester.pump();
    verifyNever(() => repo.createNote(any()));

    final titled = open(editor, tagId: 't1');
    titled.title.text = 'Ideas';
    titled.flushOnLeave();
    await tester.pump();
    final created =
        verify(() => repo.createNote(captureAny())).captured.single as Note;
    expect(created.title, 'Ideas');
    expect(created.tagIds, ['t1']);
    expect(titled.isNew, isFalse);
    empty.dispose();
    titled.dispose();
  });

  testWidgets('a new note shows its tag before it is saved, and can drop it', (
    tester,
  ) async {
    final draft = open(FakeEditor(''), tagId: 't1');
    expect(draft.tagIds, ['t1']);

    draft.removeNewNoteTag('t1');
    expect(draft.tagIds, isEmpty);
    draft.title.text = 'Ideas';
    draft.flushOnLeave();
    await tester.pump();

    final created =
        verify(() => repo.createNote(captureAny())).captured.single as Note;
    expect(created.tagIds, isEmpty);
    draft.dispose();
  });

  testWidgets('a note opened by id shows no new-note tag while it loads', (
    tester,
  ) async {
    when(() => repo.getNote(any())).thenAnswer((_) async => null);
    final draft = NoteEditorController(
      notes: repo,
      sharesOf: (_) async => const [],
      editor: FakeEditor(''),
      newNoteTagIds: const ['t1'],
      onNoteDeleted: () {},
      noteId: 'n1',
    );
    expect(draft.tagIds, isEmpty);
    await tester.pump();
    draft.dispose();
  });

  group('a blank new note after the tag picker', () {
    Future<NoteEditorController> pick(List<String> picked) async {
      when(() => repo.deleteForever(any())).thenAnswer((_) async {});
      final draft = open(FakeEditor(''), tagId: 't1');
      final id = await draft.createNote();
      when(
        () => repo.getNote(id),
      ).thenAnswer((_) async => Note(id: id, title: '', tagIds: picked));
      await draft.discardIfBlank();
      return draft;
    }

    test('is let go with only the tag it opened with', () async {
      final draft = await pick(['t1']);
      verify(() => repo.deleteForever(any())).called(1);
      expect(draft.isNew, isTrue);
      expect(draft.tagIds, ['t1']);
      draft.dispose();
    });

    test('is let go with that tag taken off, and shows none', () async {
      final draft = await pick([]);
      verify(() => repo.deleteForever(any())).called(1);
      expect(draft.tagIds, isEmpty);
      draft.dispose();
    });

    test('is kept once a tag was added', () async {
      final draft = await pick(['t1', 't2']);
      verifyNever(() => repo.deleteForever(any()));
      expect(draft.isNew, isFalse);
      draft.dispose();
    });
  });

  testWidgets('a change from elsewhere replaces the draft unless edited', (
    tester,
  ) async {
    final draft = open(FakeEditor('milk'), note: note);

    stored.add(note.copyWith(title: 'Shopping'));
    await tester.pump();
    expect(draft.title.text, 'Shopping');

    draft.title.text = 'Mine';
    stored.add(note.copyWith(title: 'Theirs'));
    await tester.pump();
    expect(draft.title.text, 'Mine');
    draft.dispose();
  });

  testWidgets('restoring the text the note opened with shows it again', (
    tester,
  ) async {
    final editor = FakeEditor('milk');
    final draft = open(editor, note: note);
    final opened = draft.contentVersion;

    editor.text = 'milk and eggs';
    draft.contentChanged();
    await tester.pump(const Duration(seconds: 3));
    stored.add(note.copyWith(content: editor.content));
    await tester.pump();
    expect(draft.contentVersion, opened, reason: 'its own save keeps the text');

    stored.add(note);
    await tester.pump();
    expect(draft.initialContent, note.content);
    expect(draft.contentVersion, greaterThan(opened));
    draft.dispose();
  });

  testWidgets('a rename and color from elsewhere survive typing', (
    tester,
  ) async {
    final editor = FakeEditor('milk');
    final draft = open(editor, note: note);

    editor.text = 'milk and eggs';
    draft.contentChanged();
    stored.add(note.copyWith(title: 'Shopping', background: 'color_blue'));
    await tester.pump();
    expect(draft.title.text, 'Shopping');
    expect(draft.background, 'color_blue');

    await tester.pump(const Duration(seconds: 3));
    final saved =
        verify(() => repo.updateNote(captureAny())).captured.single as Note;
    expect(saved.title, 'Shopping');
    expect(saved.background, 'color_blue');
    expect(saved.content, contains('milk and eggs'));
    draft.dispose();
  });

  testWidgets('a title changed here is saved over one from elsewhere', (
    tester,
  ) async {
    final draft = open(FakeEditor('milk'), note: note);

    draft.title.text = 'Mine';
    stored.add(note.copyWith(title: 'Theirs', background: 'color_blue'));
    await tester.pump(const Duration(seconds: 3));
    final saved =
        verify(() => repo.updateNote(captureAny())).captured.single as Note;
    expect(saved.title, 'Mine');
    expect(saved.background, 'color_blue');
    draft.dispose();
  });

  testWidgets('text changed elsewhere survives a title typed here', (
    tester,
  ) async {
    final editor = FakeEditor('milk');
    final draft = open(editor, note: note);
    final opened = draft.contentVersion;
    const theirs = '{"ops":[{"insert":"bread\\n"}]}';

    draft.title.text = 'Mine';
    stored.add(note.copyWith(content: theirs));
    await tester.pump();
    expect(draft.initialContent, theirs);
    expect(draft.contentVersion, greaterThan(opened));

    await tester.pump(const Duration(seconds: 3));
    final saved =
        verify(() => repo.updateNote(captureAny())).captured.single as Note;
    expect(saved.title, 'Mine');
    expect(saved.content, theirs, reason: 'saved before the editor reloads');
    draft.dispose();
  });

  testWidgets('text typed here is saved over text from elsewhere', (
    tester,
  ) async {
    final editor = FakeEditor('milk');
    final draft = open(editor, note: note);
    final opened = draft.contentVersion;

    editor.text = 'milk and eggs';
    draft.contentChanged();
    stored.add(note.copyWith(content: '{"ops":[{"insert":"bread\\n"}]}'));
    await tester.pump();
    expect(draft.contentVersion, opened);

    await tester.pump(const Duration(seconds: 3));
    final saved =
        verify(() => repo.updateNote(captureAny())).captured.single as Note;
    expect(saved.content, contains('milk and eggs'));
    draft.dispose();
  });

  testWidgets('a note gone from the phone closes once', (tester) async {
    var closed = 0;
    final draft = open(
      FakeEditor('milk'),
      note: note,
      onNoteDeleted: () => closed++,
    );

    stored.add(null);
    stored.add(null);
    await tester.pump();
    expect(closed, 1);
    draft.dispose();
  });
}
