import 'dart:convert';

import 'package:anchor/core/widgets/quill_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _nestedContent = [
  {'insert': 'a'},
  {
    'insert': '\n',
    'attributes': {'list': 'unchecked'},
  },
  {'insert': 'a1'},
  {
    'insert': '\n',
    'attributes': {'list': 'checked', 'indent': 1},
  },
  {'insert': 'g1'},
  {
    'insert': '\n',
    'attributes': {'list': 'unchecked', 'indent': 2},
  },
];

void main() {
  testWidgets('preview rows are indented per nesting level', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuillPreview(content: jsonEncode({'ops': _nestedContent})),
        ),
      ),
    );

    final aLeft = tester.getTopLeft(find.text('a')).dx;
    final a1Left = tester.getTopLeft(find.text('a1')).dx;
    final g1Left = tester.getTopLeft(find.text('g1')).dx;
    expect(a1Left - aLeft, 12);
    expect(g1Left - a1Left, 12);
  });

  testWidgets('nested ordered lists number per level like the editor', (
    tester,
  ) async {
    const ops = [
      {'insert': 'one'},
      {
        'insert': '\n',
        'attributes': {'list': 'ordered'},
      },
      {'insert': 'two'},
      {
        'insert': '\n',
        'attributes': {'list': 'ordered'},
      },
      {'insert': 'child'},
      {
        'insert': '\n',
        'attributes': {'list': 'ordered', 'indent': 1},
      },
      {'insert': 'grand'},
      {
        'insert': '\n',
        'attributes': {'list': 'ordered', 'indent': 2},
      },
      {'insert': 'three'},
      {
        'insert': '\n',
        'attributes': {'list': 'ordered'},
      },
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: QuillPreview(content: jsonEncode({'ops': ops}))),
      ),
    );

    expect(find.text('2.'), findsOneWidget);
    expect(find.text('a.'), findsOneWidget);
    expect(find.text('i.'), findsOneWidget);
    // The top-level count continues past the nested run.
    expect(find.text('3.'), findsOneWidget);
  });
}
