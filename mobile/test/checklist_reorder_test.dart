import 'package:anchor/core/widgets/editor/checklist_reorder_mixin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';

/// Minimal host so the mixin can be exercised without rendering QuillEditor.
class _SortHost extends StatefulWidget {
  const _SortHost({required this.controller, this.sortEnabled = true});

  final QuillController controller;
  final bool sortEnabled;

  @override
  State<_SortHost> createState() => _SortHostState();
}

class _SortHostState extends State<_SortHost> with ChecklistReorderMixin {
  @override
  QuillController get controller => widget.controller;

  @override
  bool get sortChecklistItems => widget.sortEnabled;

  @override
  void initState() {
    super.initState();
    attachChecklistSorting();
  }

  @override
  void dispose() {
    detachChecklistSorting();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// Builds a controller from (text, listType) lines; listType null = paragraph.
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

/// Reads the document back as (text, listType) lines.
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

/// Document offset of the first character of line [index] in [lines].
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
  }) async {
    final controller = makeController(lines);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _SortHost(controller: controller, sortEnabled: sortEnabled),
    );
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
    // The sorter must not re-sort what undo just restored.
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
    await tester.pumpWidget(_SortHost(controller: controller));

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

    // Convert all three lines to unchecked in one format call, like the
    // toolbar does for a multi-line selection.
    controller.formatText(0, 5, Attribute.unchecked);
    await tester.pump();

    expect(docLines(controller), [
      ('a', 'unchecked'),
      ('b', 'unchecked'),
      ('c', 'unchecked'),
    ]);
  });
}
