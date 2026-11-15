import 'package:anchor/features/notes/presentation/editor/checklist_sorter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';

void sortWith(
  QuillController controller, {
  bool sortEnabled = true,
  Duration delay = Duration.zero,
}) {
  final sorter = ChecklistSorter(
    controller,
    isEnabled: () => sortEnabled,
    delay: () => delay,
  );
  final changes = controller.changes.listen(sorter.handleChange);
  addTearDown(() {
    changes.cancel();
    sorter.dispose();
  });
}

QuillController makeController(List<(String, String?)> lines) {
  final ops = <Map<String, dynamic>>[];
  for (final (text, list) in lines) {
    if (text.isNotEmpty) ops.add({'insert': text});
    ops.add({
      'insert': '\n',
      if (list != null) 'attributes': {'list': list},
    });
  }
  return QuillController(
    document: Document.fromJson(ops),
    selection: const TextSelection.collapsed(offset: 0),
  );
}

QuillController makeNestedController(List<(String, String?, int)> lines) {
  final ops = <Map<String, dynamic>>[];
  for (final (text, list, indent) in lines) {
    if (text.isNotEmpty) ops.add({'insert': text});
    ops.add({
      'insert': '\n',
      if (list != null || indent > 0)
        'attributes': {'list': ?list, if (indent > 0) 'indent': indent},
    });
  }
  return QuillController(
    document: Document.fromJson(ops),
    selection: const TextSelection.collapsed(offset: 0),
  );
}

List<(String, String?, int)> nestedLinesOf(QuillController controller) {
  final out = <(String, String?, int)>[];
  final buffer = StringBuffer();
  for (final op in controller.document.toDelta().toList()) {
    final data = op.data;
    if (data is! String) continue;
    final parts = data.split('\n');
    for (var i = 0; i < parts.length; i++) {
      buffer.write(parts[i]);
      if (i < parts.length - 1) {
        final attrs = op.attributes;
        out.add((
          buffer.toString(),
          attrs?['list'] as String?,
          (attrs?['indent'] as int?) ?? 0,
        ));
        buffer.clear();
      }
    }
  }
  return out;
}

int lineStartOf(List<(String, String?, int)> lines, int index) {
  var offset = 0;
  for (var i = 0; i < index; i++) {
    offset += lines[i].$1.length + 1;
  }
  return offset;
}

List<(String, String?)> docLines(QuillController controller) {
  final lines = <(String, String?)>[];
  final buffer = StringBuffer();
  for (final op in controller.document.toDelta().toList()) {
    final data = op.data;
    if (data is! String) {
      buffer.write('[embed]');
      continue;
    }
    final parts = data.split('\n');
    for (var i = 0; i < parts.length; i++) {
      buffer.write(parts[i]);
      if (i < parts.length - 1) {
        lines.add((buffer.toString(), op.attributes?['list'] as String?));
        buffer.clear();
      }
    }
  }
  return lines;
}

int lineStart(List<(String, String?)> lines, int index) {
  var offset = 0;
  for (var i = 0; i < index; i++) {
    offset += lines[i].$1.length + 1;
  }
  return offset;
}

void main() {
  Future<QuillController> pumpHost(
    WidgetTester tester,
    List<(String, String?)> lines, {
    bool sortEnabled = true,
    Duration delay = Duration.zero,
  }) async {
    final controller = makeController(lines);
    addTearDown(controller.dispose);
    sortWith(controller, sortEnabled: sortEnabled, delay: delay);
    return controller;
  }

  testWidgets('checking an item moves it to the bottom of its group', (
    tester,
  ) async {
    final initial = <(String, String?)>[
      ('a', 'unchecked'),
      ('b', 'unchecked'),
      ('c', 'unchecked'),
    ];
    final controller = await pumpHost(tester, initial);

    controller.formatText(lineStart(initial, 0), 0, Attribute.checked);
    await tester.pump();

    expect(docLines(controller), [
      ('b', 'unchecked'),
      ('c', 'unchecked'),
      ('a', 'checked'),
    ]);
  });

  testWidgets('toggling in a mixed group heals the whole group', (
    tester,
  ) async {
    // A group that was never sorted.
    final initial = <(String, String?)>[
      ('observing', 'unchecked'),
      ('jsjshs', 'checked'),
      ('test', 'checked'),
      ('pretty', 'unchecked'),
      ('leggy', 'unchecked'),
      ('patio', 'unchecked'),
    ];
    final controller = await pumpHost(tester, initial);

    controller.formatText(lineStart(initial, 4), 0, Attribute.checked);
    await tester.pump();

    expect(docLines(controller), [
      ('observing', 'unchecked'),
      ('pretty', 'unchecked'),
      ('patio', 'unchecked'),
      ('jsjshs', 'checked'),
      ('test', 'checked'),
      ('leggy', 'checked'),
    ]);
  });

  testWidgets('unchecking an item moves it above the first checked item', (
    tester,
  ) async {
    final initial = <(String, String?)>[
      ('a', 'unchecked'),
      ('b', 'checked'),
      ('c', 'checked'),
    ];
    final controller = await pumpHost(tester, initial);

    controller.formatText(lineStart(initial, 2), 0, Attribute.unchecked);
    await tester.pump();

    expect(docLines(controller), [
      ('a', 'unchecked'),
      ('c', 'unchecked'),
      ('b', 'checked'),
    ]);
  });

  testWidgets('a checked child moves to the checked section', (tester) async {
    final lines = <(String, String?, int)>[
      ('p', 'unchecked', 0),
      ('c1', 'unchecked', 1),
      ('c2', 'unchecked', 1),
      ('q', 'unchecked', 0),
    ];
    final controller = makeNestedController(lines);
    addTearDown(controller.dispose);
    sortWith(controller);

    controller.formatText(lineStartOf(lines, 1), 0, Attribute.checked);
    await tester.pump();

    expect(nestedLinesOf(controller), [
      ('p', 'unchecked', 0),
      ('c2', 'unchecked', 1),
      ('q', 'unchecked', 0),
      ('c1', 'checked', 0),
    ]);
  });

  testWidgets('toggling a child moves its whole subtree', (tester) async {
    final lines = <(String, String?, int)>[
      ('p', 'unchecked', 0),
      ('c1', 'unchecked', 1),
      ('g1', 'unchecked', 2),
      ('q', 'unchecked', 0),
    ];
    final controller = makeNestedController(lines);
    addTearDown(controller.dispose);
    sortWith(controller);

    controller.formatText(lineStartOf(lines, 1), 0, Attribute.checked);
    await tester.pump();

    // c1 leaves its parent with g1, which stays one level below it.
    expect(nestedLinesOf(controller), [
      ('p', 'unchecked', 0),
      ('q', 'unchecked', 0),
      ('c1', 'checked', 0),
      ('g1', 'unchecked', 1),
    ]);
  });

  testWidgets('checking the last unchecked item leaves it in place', (
    tester,
  ) async {
    final initial = <(String, String?)>[('a', 'unchecked'), ('b', 'unchecked')];
    final controller = await pumpHost(tester, initial);

    controller.formatText(lineStart(initial, 1), 0, Attribute.checked);
    await tester.pump();

    expect(docLines(controller), [('a', 'unchecked'), ('b', 'checked')]);
  });

  testWidgets('sorting stays within the toggled checklist group', (
    tester,
  ) async {
    final initial = <(String, String?)>[
      ('a', 'unchecked'),
      ('b', 'unchecked'),
      ('note', null),
      ('c', 'unchecked'),
      ('d', 'unchecked'),
    ];
    final controller = await pumpHost(tester, initial);

    controller.formatText(lineStart(initial, 0), 0, Attribute.checked);
    await tester.pump();

    expect(docLines(controller), [
      ('b', 'unchecked'),
      ('a', 'checked'),
      ('note', null),
      ('c', 'unchecked'),
      ('d', 'unchecked'),
    ]);
  });

  testWidgets('selection outside the moved region is preserved', (
    tester,
  ) async {
    final initial = <(String, String?)>[
      ('hello', null),
      ('a', 'unchecked'),
      ('b', 'unchecked'),
    ];
    final controller = await pumpHost(tester, initial);
    controller.updateSelection(
      const TextSelection.collapsed(offset: 2),
      ChangeSource.local,
    );

    controller.formatText(lineStart(initial, 1), 0, Attribute.checked);
    await tester.pump();

    expect(docLines(controller), [
      ('hello', null),
      ('b', 'unchecked'),
      ('a', 'checked'),
    ]);
    expect(controller.selection, const TextSelection.collapsed(offset: 2));
  });

  testWidgets('the caret stays with its line when a tick moves lines', (
    tester,
  ) async {
    final initial = <(String, String?)>[
      ('Milk', 'unchecked'),
      ('Bread', 'unchecked'),
      ('After the list', null),
    ];
    final controller = await pumpHost(tester, initial);
    final breadEnd = lineStart(initial, 1) + 'Bread'.length;
    controller.updateSelection(
      TextSelection.collapsed(offset: breadEnd),
      ChangeSource.local,
    );

    controller.formatText(lineStart(initial, 0), 0, Attribute.checked);
    await tester.pump();

    expect(docLines(controller).take(2), [
      ('Bread', 'unchecked'),
      ('Milk', 'checked'),
    ]);
    expect(
      controller.selection,
      const TextSelection.collapsed(offset: 'Bread'.length),
    );
  });

  testWidgets('a line just made a checklist item stays where it is', (
    tester,
  ) async {
    final initial = <(String, String?)>[
      ('Butter', null),
      ('Milk', 'unchecked'),
      ('Eggs', 'unchecked'),
    ];
    final controller = await pumpHost(tester, initial);

    controller.formatText(lineStart(initial, 0), 0, Attribute.unchecked);
    await tester.pump();

    expect(docLines(controller), [
      ('Butter', 'unchecked'),
      ('Milk', 'unchecked'),
      ('Eggs', 'unchecked'),
    ]);
  });

  testWidgets('undoing an item made text puts it back where it was', (
    tester,
  ) async {
    final initial = <(String, String?)>[
      ('A', 'unchecked'),
      ('B', 'unchecked'),
      ('C', 'unchecked'),
    ];
    final controller = await pumpHost(tester, initial);

    controller.formatText(
      lineStart(initial, 1),
      0,
      Attribute.clone(Attribute.list, null),
    );
    await tester.pump();
    controller.undo();
    await tester.pump();

    expect(docLines(controller), initial);
  });

  testWidgets('a single undo reverts both the toggle and the move', (
    tester,
  ) async {
    final initial = <(String, String?)>[
      ('a', 'unchecked'),
      ('b', 'unchecked'),
      ('c', 'unchecked'),
    ];
    final controller = await pumpHost(tester, initial);

    controller.formatText(lineStart(initial, 0), 0, Attribute.checked);
    await tester.pump();
    expect(docLines(controller).first, ('b', 'unchecked'));
    expect(controller.hasUndo, isTrue);

    controller.undo();
    await tester.pump();

    expect(docLines(controller), initial);
    await tester.pump();
    expect(docLines(controller), initial);
  });

  testWidgets('unchecking the last line of the document undoes cleanly', (
    tester,
  ) async {
    final initial = <(String, String?)>[
      ('a', 'unchecked'),
      ('b', 'checked'),
      ('c', 'checked'),
    ];
    final controller = await pumpHost(tester, initial);

    controller.formatText(lineStart(initial, 2), 0, Attribute.unchecked);
    await tester.pump();
    expect(docLines(controller), [
      ('a', 'unchecked'),
      ('c', 'unchecked'),
      ('b', 'checked'),
    ]);

    controller.undo();
    await tester.pump();
    expect(docLines(controller), initial);
    await tester.pump();
    expect(docLines(controller), initial);
  });

  testWidgets('unchecking mid-group with content below the group', (
    tester,
  ) async {
    final initial = <(String, String?)>[
      ('a', 'unchecked'),
      ('b', 'checked'),
      ('c', 'checked'),
      ('note', null),
    ];
    final controller = await pumpHost(tester, initial);

    controller.formatText(lineStart(initial, 2), 0, Attribute.unchecked);
    await tester.pump();

    expect(docLines(controller), [
      ('a', 'unchecked'),
      ('c', 'unchecked'),
      ('b', 'checked'),
      ('note', null),
    ]);
  });

  testWidgets('inline formatting survives an end-of-document move', (
    tester,
  ) async {
    final controller = QuillController(
      document: Document.fromJson([
        {
          'insert': 'bold',
          'attributes': {'bold': true},
        },
        {'insert': ' item'},
        {
          'insert': '\n',
          'attributes': {'list': 'unchecked'},
        },
        {'insert': 'b'},
        {
          'insert': '\n',
          'attributes': {'list': 'unchecked'},
        },
      ]),
      selection: const TextSelection.collapsed(offset: 0),
    );
    addTearDown(controller.dispose);
    sortWith(controller);

    controller.formatText(0, 0, Attribute.checked);
    await tester.pump();

    expect(docLines(controller), [
      ('b', 'unchecked'),
      ('bold item', 'checked'),
    ]);
    final ops = controller.document.toDelta().toJson();
    expect(
      ops.any(
        (op) =>
            op['insert'] == 'bold' &&
            (op['attributes'] as Map?)?['bold'] == true,
      ),
      isTrue,
      reason: 'bold run should survive the move',
    );
  });

  testWidgets('typing does not trigger sorting', (tester) async {
    // Checked item above an unchecked one: only a toggle may reorder.
    final initial = <(String, String?)>[('a', 'checked'), ('b', 'unchecked')];
    final controller = await pumpHost(tester, initial);

    controller.replaceText(1, 0, 'x', null);
    await tester.pump();

    expect(docLines(controller), [('ax', 'checked'), ('b', 'unchecked')]);
  });

  testWidgets('sorting disabled leaves toggled items in place', (tester) async {
    final initial = <(String, String?)>[('a', 'unchecked'), ('b', 'unchecked')];
    final controller = await pumpHost(tester, initial, sortEnabled: false);

    controller.formatText(lineStart(initial, 0), 0, Attribute.checked);
    await tester.pump();

    expect(docLines(controller), [('a', 'checked'), ('b', 'unchecked')]);
  });

  testWidgets('bulk multi-line formatting is not sorted', (tester) async {
    final initial = <(String, String?)>[
      ('a', 'checked'),
      ('b', 'checked'),
      ('c', 'unchecked'),
    ];
    final controller = await pumpHost(tester, initial);

    controller.formatText(0, 5, Attribute.unchecked);
    await tester.pump();

    expect(docLines(controller), [
      ('a', 'unchecked'),
      ('b', 'unchecked'),
      ('c', 'unchecked'),
    ]);
  });

  group('with a pause before the move', () {
    const pause = Duration(milliseconds: 320);
    final initial = <(String, String?)>[
      ('a', 'unchecked'),
      ('b', 'unchecked'),
      ('c', 'checked'),
    ];

    testWidgets('a ticked item stays in place until the pause ends', (
      tester,
    ) async {
      final controller = await pumpHost(tester, initial, delay: pause);

      controller.formatText(lineStart(initial, 0), 0, Attribute.checked);
      await tester.pump(pause - const Duration(milliseconds: 20));
      expect(docLines(controller).first, ('a', 'checked'));

      await tester.pump(const Duration(milliseconds: 40));
      expect(docLines(controller), [
        ('b', 'unchecked'),
        ('c', 'checked'),
        ('a', 'checked'),
      ]);
    });

    testWidgets('unticking it in the pause keeps it where it was', (
      tester,
    ) async {
      final controller = await pumpHost(tester, initial, delay: pause);

      controller.formatText(lineStart(initial, 0), 0, Attribute.checked);
      await tester.pump(const Duration(milliseconds: 100));
      controller.formatText(lineStart(initial, 0), 0, Attribute.unchecked);
      await tester.pump(pause * 2);

      expect(docLines(controller), initial);
    });

    testWidgets('an unticked item waits too, then moves up', (tester) async {
      final controller = await pumpHost(tester, initial, delay: pause);

      controller.formatText(lineStart(initial, 2), 0, Attribute.unchecked);
      await tester.pump(const Duration(milliseconds: 100));
      expect(docLines(controller).last, ('c', 'unchecked'));
      await tester.pump(pause);

      expect(docLines(controller).map((l) => l.$2), everyElement('unchecked'));
    });

    testWidgets('typing elsewhere in the pause still moves the right item', (
      tester,
    ) async {
      final controller = await pumpHost(tester, initial, delay: pause);

      controller.formatText(lineStart(initial, 1), 0, Attribute.checked);
      await tester.pump(const Duration(milliseconds: 100));
      controller.replaceText(
        0,
        0,
        'xyz',
        const TextSelection.collapsed(offset: 3),
      );
      await tester.pump(pause);

      expect(docLines(controller), [
        ('xyza', 'unchecked'),
        ('c', 'checked'),
        ('b', 'checked'),
      ]);
    });

    testWidgets('one Undo takes back the tick and the move', (tester) async {
      final controller = await pumpHost(tester, initial, delay: pause);

      controller.formatText(lineStart(initial, 0), 0, Attribute.checked);
      await tester.pump(pause * 2);
      expect(docLines(controller).first, ('b', 'unchecked'));

      controller.undo();
      await tester.pump(pause * 2);

      expect(docLines(controller), initial);
    });
  });
}
