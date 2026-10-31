import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:anchor/core/network/server_config_provider.dart';
import 'package:anchor/core/theme/app_theme.dart';
import 'package:anchor/core/widgets/check_circle.dart';
import 'package:anchor/core/widgets/shimmer.dart';
import 'package:anchor/features/notes/data/repository/attachment_file_provider.dart';
import 'package:anchor/features/notes/domain/checklist_task.dart';
import 'package:anchor/features/notes/domain/note.dart';
import 'package:anchor/features/notes/presentation/widgets/card_body.dart';
import 'package:anchor/features/notes/presentation/widgets/note_card.dart';
import 'package:anchor/features/notes/presentation/widgets/note_card_content.dart';
import 'package:anchor/features/tags/domain/tag.dart';
import 'package:anchor/features/tags/presentation/tags_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

void main() {
  Note noteWith(NoteReminder? reminder) => Note(
    id: 'n1',
    title: 'Hi',
    content: null,
    updatedAt: DateTime(2026, 9, 23, 19, 22),
    reminder: reminder,
  );

  Future<void> pumpCard(
    WidgetTester tester,
    Note note,
    double width, {
    bool isSelecting = false,
    List<Tag> tags = const [],
    FutureOr<String?> Function()? picture,
    CardLayout layout = CardLayout.masonry,
    TextScaler textScaler = TextScaler.noScaling,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tagsControllerProvider.overrideWith(TagsController.new),
          serverUrlProvider.overrideWithValue('https://example.test'),
          if (picture != null)
            attachmentFileProvider.overrideWith((ref, key) => picture()),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: textScaler),
            child: child!,
          ),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: width,
                child: NoteCard(
                  note: note,
                  layout: layout,
                  tags: tags,
                  isSelecting: isSelecting,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  final checklist = Note(
    id: 'tasks',
    title: 'Shopping',
    noteType: NoteType.checklist,
    content: writeChecklist([
      const ChecklistTask(text: 'Milk'),
      const ChecklistTask(text: 'Bread', done: true),
      const ChecklistTask(),
    ]),
  );

  for (final layout in CardLayout.values) {
    testWidgets('checklist icon and progress appear in ${layout.name} cards', (
      tester,
    ) async {
      await pumpCard(tester, checklist, 160, layout: layout);
      expect(find.byIcon(LucideIcons.listChecks), findsOneWidget);
      expect(find.text('1 of 2 done', findRichText: true), findsOneWidget);
      expect(find.text('Bread', findRichText: true), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('completed checklists show a checkmark and All done', (
    tester,
  ) async {
    await pumpCard(
      tester,
      checklist.copyWith(
        content: writeChecklist([
          const ChecklistTask(text: 'Milk', done: true),
          const ChecklistTask(),
        ]),
      ),
      160,
    );
    expect(find.byIcon(LucideIcons.circleCheck), findsOneWidget);
    expect(find.textContaining('All done', findRichText: true), findsOneWidget);
    expect(find.text('1 of 2 done', findRichText: true), findsNothing);
  });

  testWidgets(
    'an empty untitled checklist stays recognizable without All done',
    (tester) async {
      await pumpCard(tester, checklist.copyWith(title: '', content: ''), 160);
      expect(find.text('Checklist'), findsOneWidget);
      expect(find.byIcon(LucideIcons.listChecks), findsOneWidget);
      expect(find.text('No tasks', findRichText: true), findsOneWidget);
      expect(find.textContaining('All done', findRichText: true), findsNothing);
    },
  );

  testWidgets('ordinary checkbox notes have no type indicator or progress', (
    tester,
  ) async {
    await pumpCard(tester, checklist.copyWith(noteType: NoteType.note), 160);
    expect(find.byIcon(LucideIcons.listChecks), findsNothing);
    expect(find.text('1 of 2 done', findRichText: true), findsNothing);
  });

  testWidgets(
    'checklist cards announce type and progress but not hidden task text',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await pumpCard(tester, checklist, 160);
        final label = tester.getSemantics(find.byType(NoteCard)).label;
        expect(label, contains('Checklist note'));
        expect(label, contains('1 of 2 tasks completed'));
        expect(label, isNot(contains('Bread')));
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets(
    'progress fits narrow cards with tags, reminders and large text',
    (tester) async {
      await pumpCard(
        tester,
        checklist.copyWith(
          reminder: const NoteReminder(
            remindAt: '2026-12-23T19:22',
            recurrence: ReminderRecurrence.yearly,
          ),
        ),
        160,
        layout: CardLayout.list,
        tags: const [Tag(id: 'work', name: 'work')],
        textScaler: TextScaler.linear(2),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('a long reminder label does not overflow the footer', (
    tester,
  ) async {
    // Half a 360pt screen minus gutters: the two-column grid's worst case.
    await pumpCard(
      tester,
      noteWith(
        const NoteReminder(
          remindAt: '2026-09-23T19:22',
          recurrence: ReminderRecurrence.yearly,
        ),
      ),
      160,
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('the reminder chip names the repeat in title case', (
    tester,
  ) async {
    await pumpCard(
      tester,
      noteWith(
        const NoteReminder(
          remindAt: '2026-09-23T19:22',
          recurrence: ReminderRecurrence.yearly,
        ),
      ),
      360,
    );

    expect(find.textContaining('· Yearly'), findsOneWidget);
  });

  testWidgets('a note with no title leads with its text', (tester) async {
    await pumpCard(
      tester,
      const Note(
        id: 'n1',
        title: '  ',
        content: '{"ops":[{"insert":"Buy milk\\n"}]}',
      ),
      160,
    );

    expect(find.text('Buy milk', findRichText: true), findsOneWidget);
    expect(find.text('Untitled'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a screen reader hears the tags and reminder on a card', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpCard(
      tester,
      noteWith(const NoteReminder(remindAt: '2026-09-23T19:22')),
      160,
      tags: const [Tag(id: 't1', name: 'work')],
    );

    final label = tester.getSemantics(find.byType(NoteCard)).label;
    expect(label, contains('Tag work'));
    expect(label, contains('reminder: Sep 23, 7:22'));
    semantics.dispose();
  });

  Note withPicture() => const Note(
    id: 'n1',
    title: 'Trip',
    content: null,
    imagePreviewData: [
      NoteImagePreview(attachmentId: 'a1', noteId: 'n1', filename: 'a.jpg'),
    ],
  );

  testWidgets('the last picture counts the files after it, voice notes '
      'too', (tester) async {
    await pumpCard(
      tester,
      const Note(
        id: 'n1',
        title: 'Trip',
        content: null,
        imagePreviewData: [
          NoteImagePreview(attachmentId: 'a1', noteId: 'n1', filename: 'a.jpg'),
          NoteImagePreview(attachmentId: 'a2', noteId: 'n1', filename: 'b.jpg'),
          NoteImagePreview(attachmentId: 'a3', noteId: 'n1', filename: 'c.jpg'),
        ],
        attachmentCount: 4,
      ),
      160,
      picture: () => null,
    );

    expect(find.text('+1'), findsOneWidget);
  });

  testWidgets('a card picture shimmers while it loads', (tester) async {
    final never = Completer<String?>();
    await pumpCard(tester, withPicture(), 160, picture: () => never.future);

    expect(find.byType(Shimmer), findsOneWidget);
  });

  testWidgets('a card picture that does not load shows an icon', (
    tester,
  ) async {
    await pumpCard(
      tester,
      withPicture(),
      160,
      picture: () => throw const SocketException('offline'),
    );
    await tester.pump();

    expect(find.byType(Shimmer), findsNothing);
    expect(find.byIcon(LucideIcons.imageOff), findsOneWidget);
  });

  testWidgets('no reminder still lays out', (tester) async {
    await pumpCard(tester, noteWith(null), 160);
    expect(tester.takeException(), isNull);
  });

  testWidgets('while selecting, the first line keeps clear of the check', (
    tester,
  ) async {
    const words = 'Birthday ideas for the whole family this year';
    for (final note in const [
      Note(id: 't', title: words),
      Note(id: 'b', title: '', content: '{"ops":[{"insert":"$words\\n"}]}'),
    ]) {
      await pumpCard(tester, note, 160, isSelecting: true);
      await tester.pumpAndSettle();
      final line = tester.getRect(find.textContaining('Birthday').first);
      final check = tester.getRect(find.byType(CheckCircle));
      expect(line.right, lessThanOrEqualTo(check.left), reason: note.id);
    }
  });

  testWidgets('a card pressed and then scrolled springs back to full size', (
    tester,
  ) async {
    tester.view.gestureSettings = const ui.GestureSettings(
      physicalTouchSlop: 8 * 3,
    );
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tagsControllerProvider.overrideWith(TagsController.new),
          serverUrlProvider.overrideWithValue('https://example.test'),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (var i = 0; i < 12; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: NoteCard(
                      note: Note(id: 'n$i', title: 'Note $i', content: null),
                      tags: const [],
                      layout: CardLayout.list,
                      onTap: () {},
                      onLongPress: () {},
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final card = find.byType(NoteCardContent).at(2);
    final width = tester.getRect(card).width;

    for (final hold in const [
      Duration(milliseconds: 16),
      Duration(milliseconds: 150),
    ]) {
      final finger = await tester.startGesture(tester.getCenter(card));
      await tester.pump(hold);
      for (var i = 0; i < 6; i++) {
        await finger.moveBy(const Offset(0, -12));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await tester.pumpAndSettle();
      expect(tester.getRect(card).width, closeTo(width, 0.5), reason: '$hold');

      await finger.up();
      await tester.pumpAndSettle();
      expect(tester.getRect(card).width, closeTo(width, 0.5), reason: '$hold');
    }
  });
}
