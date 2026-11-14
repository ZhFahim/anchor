import 'package:anchor/core/theme/app_theme.dart';
import 'package:anchor/core/widgets/app_buttons.dart';
import 'package:anchor/features/notes/presentation/editor/link_edit_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<(String, String)> submitted;
  late int removed;

  Future<void> openSheet(
    WidgetTester tester, {
    String initialText = '',
    String initialUrl = '',
    bool canRemove = false,
  }) async {
    submitted = [];
    removed = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () => LinkEditSheet.show(
                  context,
                  initialText: initialText,
                  initialUrl: initialUrl,
                  onSubmit: (text, url) => submitted.add((text, url)),
                  onRemove: canRemove ? () => removed++ : null,
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  Finder field(String hint) => find.byWidgetPredicate(
    (w) => w is TextField && w.decoration?.hintText == hint,
  );

  AppButton button(WidgetTester tester, String label) => tester.widget(
    find.byWidgetPredicate((w) => w is AppButton && w.label == label),
  );

  testWidgets('the words field takes focus as the sheet starts to rise', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () => LinkEditSheet.show(
                  context,
                  initialText: '',
                  initialUrl: '',
                  onSubmit: (_, _) {},
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump();

    expect(tester.widget<TextField>(field('Text')).focusNode!.hasFocus, isTrue);
    await tester.pumpAndSettle();
  });

  testWidgets('Add link stays off until the address looks like one', (
    tester,
  ) async {
    await openSheet(tester);
    expect(button(tester, 'Add link').onPressed, isNull);

    for (final (url, canSave) in [
      ('hello', false),
      ('example.com', true),
      ('https://example.com/a?b=1', true),
      ('tel:5551234', true),
      ('localhost:3000', true),
      ('two words.com', false),
      ('', false),
    ]) {
      await tester.enterText(field('https://'), url);
      await tester.pump();
      expect(
        button(tester, 'Add link').onPressed != null,
        canSave,
        reason: url,
      );
    }
  });

  testWidgets('saving uses the address as the words when there are none', (
    tester,
  ) async {
    await openSheet(tester);

    await tester.enterText(field('https://'), 'example.com');
    await tester.pump();
    await tester.tap(find.text('Add link').last);
    await tester.pumpAndSettle();

    expect(submitted, [('example.com', 'https://example.com')]);
    expect(find.byType(LinkEditSheet), findsNothing);
  });

  testWidgets('saving keeps the words typed for the link', (tester) async {
    await openSheet(tester);

    await tester.enterText(field('Text'), 'Our site');
    await tester.enterText(field('https://'), 'https://example.com');
    await tester.pump();
    await tester.tap(find.text('Add link').last);
    await tester.pumpAndSettle();

    expect(submitted, [('Our site', 'https://example.com')]);
  });

  testWidgets('editing a link offers Save and Remove', (tester) async {
    await openSheet(
      tester,
      initialText: 'site',
      initialUrl: 'https://example.com',
      canRemove: true,
    );

    expect(find.text('Edit link'), findsOneWidget);
    expect(button(tester, 'Save').onPressed, isNotNull);

    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();

    expect(removed, 1);
    expect(submitted, isEmpty);
    expect(find.byType(LinkEditSheet), findsNothing);
  });
}
