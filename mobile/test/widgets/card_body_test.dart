import 'dart:io';

import 'package:anchor/core/theme/app_theme.dart';
import 'package:anchor/core/theme/app_typography.dart';
import 'package:anchor/features/notes/domain/checklist_task.dart';
import 'package:anchor/features/notes/presentation/widgets/card_body.dart';
import 'package:anchor/features/notes/presentation/widgets/note_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() async {
    await (FontLoader(AppTypography.sans)..addFont(
          Future.value(
            ByteData.sublistView(
              File('assets/fonts/DMSans-Variable.ttf').readAsBytesSync(),
            ),
          ),
        ))
        .load();
  });

  testWidgets('a card number ends 3 inside its 15 wide box', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 160,
              child: Builder(
                builder: (context) => CardBody(
                  content:
                      r'{"ops":[{"insert":"Ship it"},'
                      r'{"insert":"\n","attributes":{"list":"ordered"}}]}',
                  appearance: NoteAppearance.of(context, null),
                  layout: CardLayout.masonry,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final number = tester.getRect(find.text('1.'));
    expect(number.width, lessThan(12));
    expect(number.right - tester.getRect(find.byType(CardBody)).left, 12);
  });

  testWidgets('checklist cards preview only unfinished tasks', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Builder(
            builder: (context) => CardBody(
              content: writeChecklist([
                const ChecklistTask(text: 'Milk'),
                const ChecklistTask(text: 'Bread', done: true),
              ]),
              hideCompleted: true,
              appearance: NoteAppearance.of(context, null),
              layout: CardLayout.masonry,
            ),
          ),
        ),
      ),
    );
    expect(find.text('Milk', findRichText: true), findsOneWidget);
    expect(find.text('Bread', findRichText: true), findsNothing);
  });
}
