import 'package:anchor/core/network/connectivity_provider.dart';
import 'package:anchor/core/network/server_config_provider.dart';
import 'package:anchor/core/providers/active_user_id_provider.dart';
import 'package:anchor/core/widgets/rich_text_editor.dart';
import 'package:anchor/features/notes/data/repository/note_attachments_repository.dart';
import 'package:anchor/features/notes/data/repository/notes_repository.dart';
import 'package:anchor/features/notes/domain/note.dart';
import 'package:anchor/features/notes/presentation/note_edit_screen.dart';
import 'package:anchor/features/settings/presentation/controllers/editor_preferences_controller.dart';
import 'package:anchor/features/settings/data/repository/preferences_repository.dart';
import 'package:anchor/features/tags/data/repository/tags_repository.dart';
import 'package:anchor/features/tags/domain/tag.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockNotesRepository extends Mock implements NotesRepository {}

class MockTagsRepository extends Mock implements TagsRepository {}

class MockAttachmentsRepository extends Mock
    implements NoteAttachmentsRepository {}

class MockPreferencesRepository extends Mock implements PreferencesRepository {}

class FakeActiveUserId extends ActiveUserId {
  @override
  String? build() => 'user-1';
}

/// Dirty-tracking and auto-save flow of NoteEditScreen against mocked
/// repositories. The 2s auto-save timer is driven with tester.pump.
void main() {
  late MockNotesRepository notesRepo;
  late MockTagsRepository tagsRepo;
  late MockAttachmentsRepository attachmentsRepo;
  late MockPreferencesRepository prefsRepo;

  setUpAll(() {
    registerFallbackValue(const Note(id: 'fallback', title: ''));
  });

  setUp(() {
    notesRepo = MockNotesRepository();
    tagsRepo = MockTagsRepository();
    attachmentsRepo = MockAttachmentsRepository();
    prefsRepo = MockPreferencesRepository();

    when(() => notesRepo.createNote(any())).thenAnswer((_) async {});
    when(() => notesRepo.updateNote(any())).thenAnswer((_) async {});
    when(
      () => tagsRepo.watchTags(),
    ).thenAnswer((_) => Stream.value(const <Tag>[]));
    when(
      () => attachmentsRepo.watchAttachments(any()),
    ).thenAnswer((_) => Stream.value(const []));
    when(() => prefsRepo.getSortChecklistItems()).thenAnswer((_) async => true);
  });

  Future<void> pumpScreen(WidgetTester tester, {Note? note}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notesRepositoryProvider.overrideWithValue(notesRepo),
          tagsRepositoryProvider.overrideWithValue(tagsRepo),
          noteAttachmentsRepositoryProvider.overrideWithValue(attachmentsRepo),
          preferencesRepositoryProvider.overrideWithValue(prefsRepo),
          serverUrlProvider.overrideWith((ref) => null),
          connectivityStreamProvider.overrideWith(
            (ref) => const Stream<List<ConnectivityResult>>.empty(),
          ),
          activeUserIdProvider.overrideWith(FakeActiveUserId.new),
        ],
        child: MaterialApp.router(
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            FlutterQuillLocalizations.delegate,
          ],
          // ConfirmDialog pops through GoRouter.
          routerConfig: GoRouter(
            routes: [
              GoRoute(
                path: '/',
                builder: (_, _) => NoteEditScreen(note: note, noteId: note?.id),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
  }

  QuillController editorController(WidgetTester tester) =>
      tester.state<RichTextEditorState>(find.byType(RichTextEditor)).controller;

  testWidgets('typing in a new note autosaves it after the idle window', (
    tester,
  ) async {
    await pumpScreen(tester);

    editorController(tester).replaceText(0, 0, 'hello', null);
    await tester.pump();
    verifyNever(() => notesRepo.createNote(any()));

    await tester.pump(const Duration(seconds: 3));

    final captured = verify(() => notesRepo.createNote(captureAny())).captured;
    expect(captured, hasLength(1));
    final note = captured.single as Note;
    expect(note.content, contains('hello'));
    expect(note.title, isEmpty);
  });

  testWidgets('an untouched new note is never saved', (tester) async {
    await pumpScreen(tester);

    await tester.pump(const Duration(seconds: 3));

    verifyNever(() => notesRepo.createNote(any()));
    verifyNever(() => notesRepo.updateNote(any()));
  });

  testWidgets('typing a title autosaves a new note with that title', (
    tester,
  ) async {
    await pumpScreen(tester);

    final titleField = find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.hintText == 'Title',
    );
    await tester.enterText(titleField, 'My title');
    await tester.pump(const Duration(seconds: 3));

    final captured = verify(() => notesRepo.createNote(captureAny())).captured;
    expect(captured, hasLength(1));
    expect((captured.single as Note).title, 'My title');
  });

  testWidgets('cursor movement alone never saves an existing note', (
    tester,
  ) async {
    const note = Note(
      id: 'n1',
      title: 'T',
      content: '{"ops":[{"insert":"hi\\n"}]}',
    );
    await pumpScreen(tester, note: note);

    editorController(tester).updateSelection(
      const TextSelection.collapsed(offset: 1),
      ChangeSource.local,
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));

    verifyNever(() => notesRepo.updateNote(any()));
    verifyNever(() => notesRepo.createNote(any()));
  });

  testWidgets('restoring a trashed note reloads its content into the editor', (
    tester,
  ) async {
    const trashed = Note(
      id: 'n1',
      title: 'T',
      content: '{"ops":[{"insert":"old content\\n"}]}',
      state: NoteState.trashed,
    );
    const restored = Note(
      id: 'n1',
      title: 'T',
      content: '{"ops":[{"insert":"fresh content\\n"}]}',
    );
    when(() => notesRepo.restoreNote('n1')).thenAnswer((_) async {});
    when(() => notesRepo.getNote('n1')).thenAnswer((_) async => restored);

    await pumpScreen(tester, note: trashed);
    expect(find.text('old content', findRichText: true), findsOneWidget);

    await tester.tap(find.byTooltip('Restore Note'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Restore'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('fresh content', findRichText: true), findsOneWidget);
    expect(find.text('old content', findRichText: true), findsNothing);
    verify(() => notesRepo.restoreNote('n1')).called(1);

    // Drain the success snackbar's display timer.
    await tester.pump(const Duration(seconds: 10));
  });

  testWidgets('editing an existing note autosaves an update', (tester) async {
    const note = Note(
      id: 'n1',
      title: 'T',
      content: '{"ops":[{"insert":"hi\\n"}]}',
    );
    await pumpScreen(tester, note: note);

    editorController(tester).replaceText(0, 0, 'x', null);
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));

    final captured = verify(() => notesRepo.updateNote(captureAny())).captured;
    expect(captured, hasLength(1));
    final saved = captured.single as Note;
    expect(saved.id, 'n1');
    expect(saved.content, contains('xhi'));
  });
}
