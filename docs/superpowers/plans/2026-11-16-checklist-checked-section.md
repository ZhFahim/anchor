# Checklist Checked Section Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move every checked checklist block to one checked section at the end of the list, wherever the block started.

**Architecture:** A pure planner computes a new line order and indents. A delta builder moves the lines and reindents them in one document change. `ChecklistSorter` uses the planner instead of the old sibling-only sort.

**Tech Stack:** Flutter 3.47.9, Dart, `flutter_quill`, `flutter_test`.

**Spec:** `docs/superpowers/specs/2026-11-16-checklist-checked-section-design.md`

## Global Constraints

- Do not change the checked-fold row UI.
- Keep the parent checkbox cascade from the previous change.
- The planner must include every line in the group exactly once.
- A checked root is indent 0; its descendants keep their relative indent.
- Unchecked lines keep their original order and indent.
- The result must be stable: planning the sorted group returns null.
- Run Flutter checks on box-03 with `./.superpowers/sdd/2026-11-14-notesx-polish/ft.sh`.
- `flutter analyze` must report no issues and the full `flutter test` suite must pass.
- Commit each task separately.

## Review Focus

- A checked parent at the top moves its whole subtree to the end. Covered in Task 1.
- A checked child under an unchecked parent moves out to the checked section. Covered in Task 1.
- Unchecked siblings keep their order. Covered in Task 1.
- Nested checked parent and child keep relative indent in the checked section. Covered in Task 1.
- The old nested sort tests change; Task 3 updates them.
- The checked fold count includes every checked line after the move. Covered in Task 3.

---

### Task 1: Plan the checked-section order

**Files:**
- Modify: `mobile/lib/features/notes/presentation/editor/checklist_lines.dart`
- Test: `mobile/test/checklist_lines_test.dart`

**Interfaces:**
- Produces:
  - `class CheckedSectionPlan { const CheckedSectionPlan({required this.order, required this.indents}); final List<int> order; final List<int> indents; }`
  - `CheckedSectionPlan? checklistCheckedSectionPlan(List<ParsedLine> lines, int groupStart, int groupEnd)`
- `order` holds original line indices in the new order. `indents` holds the new indent for each line in that order. Both lengths equal `groupEnd - groupStart + 1`.

- [ ] **Step 1: Write the failing planner tests**

Add to `mobile/test/checklist_lines_test.dart`:

```dart
CheckedSectionPlan? planOf(Document doc) {
  final lines = parseDocumentLines(doc);
  return checklistCheckedSectionPlan(lines, 0, lines.length - 1);
}

test('a checked flat item moves to the bottom', () {
  final plan = planOf(nestedDoc([
    ('a', 'unchecked', 0),
    ('b', 'unchecked', 0),
    ('c', 'unchecked', 0),
  ]));
  expect(plan, isNotNull);
  expect(plan!.order, [1, 2, 0]);
  expect(plan.indents, [0, 0, 0]);
});

test('a checked parent moves its whole block to the bottom', () {
  final plan = planOf(nestedDoc([
    ('a', 'checked', 0),
    ('a1', 'checked', 1),
    ('b', 'unchecked', 0),
    ('b1', 'unchecked', 1),
  ]));
  expect(plan!.order, [2, 3, 0, 1]);
  expect(plan.indents, [0, 1, 0, 1]);
});

test('a checked child leaves an unchecked parent', () {
  final plan = planOf(nestedDoc([
    ('p', 'unchecked', 0),
    ('c1', 'checked', 1),
    ('c2', 'unchecked', 1),
    ('q', 'unchecked', 0),
  ]));
  expect(plan!.order, [0, 2, 3, 1]);
  expect(plan.indents, [0, 1, 0, 0]);
});

test('an ordered group has no plan', () {
  final plan = planOf(nestedDoc([
    ('a', 'unchecked', 0),
    ('b', 'checked', 0),
    ('c', 'checked', 0),
  ]));
  expect(plan, isNull);
});
```

- [ ] **Step 2: Run the tests and verify they fail**

Run: `./.superpowers/sdd/2026-11-14-notesx-polish/ft.sh test/checklist_lines_test.dart`

Expected: FAIL with `checklistCheckedSectionPlan` not defined.

- [ ] **Step 3: Implement the planner**

Add `CheckedSectionPlan` and `checklistCheckedSectionPlan` to `checklist_lines.dart`.

Rules:
1. Build a block tree for `groupStart..groupEnd` using indent.
2. Walk the forest:
   - Checked block: append every line to the checked list, with root indent 0 and descendants relative to the block root.
   - Unchecked block: append its head to the unchecked list, then walk its children. A checked child is appended to the checked list; an unchecked child is walked in place.
3. `order` is the unchecked list followed by the checked list.
4. `indents` follows `order`.
5. Return null when `order` is already `groupStart..groupEnd` and every indent is unchanged.

- [ ] **Step 4: Run the tests and verify they pass**

Run: `./.superpowers/sdd/2026-11-14-notesx-polish/ft.sh test/checklist_lines_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add mobile/lib/features/notes/presentation/editor/checklist_lines.dart mobile/test/checklist_lines_test.dart
git commit -m "feat: plan a checklist checked section"
```

---

### Task 2: Build the checked-section delta

**Files:**
- Modify: `mobile/lib/features/notes/presentation/editor/checklist_lines.dart`
- Test: `mobile/test/checklist_lines_test.dart`

**Interfaces:**
- Consumes: `CheckedSectionPlan`, `buildGroupReorderDelta`.
- Produces:
  - `Delta buildIndentsDelta(List<ParsedLine> lines, int groupStart, List<int> indents)`
  - `Delta buildCheckedSectionDelta(Document document, List<ParsedLine> lines, int groupStart, CheckedSectionPlan plan)`

- [ ] **Step 1: Write the failing delta tests**

Add to `mobile/test/checklist_lines_test.dart`:

```dart
Document appliedPlan(Document doc, CheckedSectionPlan plan) {
  final lines = parseDocumentLines(doc);
  final delta = buildCheckedSectionDelta(doc, lines, 0, plan);
  doc.compose(delta, ChangeSource.local);
  return doc;
}

test('the delta writes the checked section order and indents', () {
  final doc = nestedDoc([
    ('p', 'unchecked', 0),
    ('c1', 'checked', 1),
    ('c2', 'unchecked', 1),
    ('q', 'unchecked', 0),
  ]);
  final plan = planOf(doc)!;
  expect(nestedLinesOf(appliedPlan(doc, plan)), [
    ('p', 'unchecked', 0),
    ('c2', 'unchecked', 1),
    ('q', 'unchecked', 0),
    ('c1', 'checked', 0),
  ]);
});

test('the delta undoes in one step', () {
  final doc = nestedDoc([
    ('a', 'checked', 0),
    ('a1', 'checked', 1),
    ('b', 'unchecked', 0),
  ]);
  final before = doc.toDelta();
  final plan = planOf(doc)!;
  final delta = buildCheckedSectionDelta(doc, parseDocumentLines(doc), 0, plan);
  doc.compose(delta, ChangeSource.local);
  doc.compose(delta.invert(before), ChangeSource.local);
  expect(doc.toDelta(), before);
});
```

- [ ] **Step 2: Run the tests and verify they fail**

Run: `./.superpowers/sdd/2026-11-14-notesx-polish/ft.sh test/checklist_lines_test.dart`

Expected: FAIL with `buildCheckedSectionDelta` not defined.

- [ ] **Step 3: Implement the delta builder**

- `buildIndentsDelta` retains to each line's newline and applies `indentAttributes(indents[i])` when the indent changes.
- `buildCheckedSectionDelta`:
  1. `move = buildGroupReorderDelta(document, lines, groupStart, plan.order)`.
  2. Simulate the move on a copy: `Document.fromDelta(document.toDelta())..compose(move, ChangeSource.local)`.
  3. Parse the moved copy and build `reindent = buildIndentsDelta(movedLines, groupStart, plan.indents)`.
  4. Return `move.compose(reindent)`.

- [ ] **Step 4: Run the tests and verify they pass**

Run: `./.superpowers/sdd/2026-11-14-notesx-polish/ft.sh test/checklist_lines_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add mobile/lib/features/notes/presentation/editor/checklist_lines.dart mobile/test/checklist_lines_test.dart
git commit -m "feat: build a checklist checked-section delta"
```

---

### Task 3: Use the checked section in the editor

**Files:**
- Modify: `mobile/lib/features/notes/presentation/editor/checklist_sorter.dart`
- Test: `mobile/test/checklist_reorder_test.dart`, `mobile/test/checklist_lines_test.dart`, `mobile/test/checklist_fold_test.dart`

**Interfaces:**
- Consumes: `checklistCheckedSectionPlan`, `buildCheckedSectionDelta`.

- [ ] **Step 1: Update the sorter test for a nested checked child**

In `mobile/test/checklist_reorder_test.dart`, add a nested controller helper:

```dart
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
```

Then add the test:

```dart
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
```

- [ ] **Step 2: Run the test and verify it fails**

Run: `./.superpowers/sdd/2026-11-14-notesx-polish/ft.sh test/checklist_reorder_test.dart`

Expected: FAIL because the old sorter keeps the child under its parent.

- [ ] **Step 3: Replace the sorter path**

In `checklist_sorter.dart`, replace `_sortToggledLine`'s order/delta block with:

```dart
final plan = checklistCheckedSectionPlan(lines, groupStart, groupEnd);
if (plan == null) return;
final move = buildCheckedSectionDelta(
  _controller.document,
  lines,
  groupStart,
  plan,
);
```

Keep the existing selection `follow` logic, but use `plan.order` instead of `order`.

- [ ] **Step 4: Update the old nested sort tests**

In `checklist_lines_test.dart`, update the nested `checklistSortOrder` tests to the new planner. Remove tests for the old sibling-only order. Keep the block-move tests.

- [ ] **Step 5: Run the tests and verify they pass**

Run: `./.superpowers/sdd/2026-11-14-notesx-polish/ft.sh test/checklist_reorder_test.dart test/checklist_lines_test.dart test/checklist_fold_test.dart`

Expected: PASS.

- [ ] **Step 6: Run the full gate**

Run:

```bash
./.superpowers/sdd/2026-11-14-notesx-polish/ft.sh
./.superpowers/sdd/2026-11-14-notesx-polish/sync.sh
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null box-03 \
  'cd /data/tmp/notesx-test && export PATH=/data/workspace/toolchain/flutter/bin:$PATH && export PUB_CACHE=/data/home/.pub-cache && flutter analyze'
```

Expected: all tests pass; `No issues found!`.

- [ ] **Step 7: Commit**

```bash
git add mobile/lib/features/notes/presentation/editor/checklist_sorter.dart mobile/test/checklist_reorder_test.dart mobile/test/checklist_lines_test.dart mobile/test/checklist_fold_test.dart
git commit -m "feat: sort checked checklist blocks into one section"
```