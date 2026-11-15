# Checklist Parent Toggle Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Toggling a parent checklist item toggles its whole checklist subtree, and a checked item hidden by the fold stays hidden.

**Architecture:** Add one pure delta builder for a checklist block. `_toggleCheckbox` composes that delta in one edit. A multi-line change is ignored by `ChecklistSorter`, so a parent with sub-items does not reorder.

**Tech Stack:** Flutter 3.47.9, Dart, `flutter_quill`, `flutter_test`.

**Spec:** `docs/superpowers/specs/2026-11-14-checklist-parent-toggle-design.md`

## Global Constraints

- Do not change `ChecklistSorter`.
- Use `Attribute.checked.value` and `Attribute.unchecked.value` for list values.
- Keep the delta shape valid for `Document.compose`: never delete the final newline.
- Run Flutter checks on box-03 with `./.superpowers/sdd/2026-11-14-notesx-polish/ft.sh`.
- `flutter analyze` must report no issues and the full `flutter test` suite must pass.
- Commit each task separately.

## Review Focus

- A parent with deeper nested sub-items: every checklist descendant changes, not only direct children. Covered in Task 1.
- A non-checklist line indented under a parent: its list state does not change. Covered in Task 1.
- Unchecking a parent with checked descendants: every checklist descendant becomes unchecked. Covered in Task 1.
- A checked item hidden at the end of another branch: it stays hidden after the parent toggle. Covered in Task 2.
- A flat checklist item: checking it still moves it to the bottom. Covered by the flat-item widget test in Task 2.

---

### Task 1: Add the checklist block toggle delta

**Files:**
- Modify: `mobile/lib/features/notes/presentation/editor/checklist_lines.dart`
- Test: `mobile/test/checklist_lines_test.dart`

**Interfaces:**
- Produces: `Delta buildChecklistToggleDelta(List<ParsedLine> lines, int index, bool checked)`
- Consumes: `ParsedLine`, `checklistBlockEnd`, `parseDocumentLines`, `nestedDoc`, `nestedLinesOf` from the test file.

- [ ] **Step 1: Write the failing tests**

Add to `mobile/test/checklist_lines_test.dart`:

```dart
test('checking a parent block checks every checklist descendant', () {
  final doc = nestedDoc([
    ('a', 'unchecked', 0),
    ('a1', 'unchecked', 1),
    ('a2', 'unchecked', 2),
    ('b', 'unchecked', 0),
  ]);
  final lines = parseDocumentLines(doc);
  doc.compose(
    buildChecklistToggleDelta(lines, 0, true),
    ChangeSource.local,
  );
  expect(nestedLinesOf(doc), [
    ('a', 'checked', 0),
    ('a1', 'checked', 1),
    ('a2', 'checked', 2),
    ('b', 'unchecked', 0),
  ]);
});

test('unchecking a parent block unchecks every checklist descendant', () {
  final doc = nestedDoc([
    ('a', 'checked', 0),
    ('a1', 'checked', 1),
    ('b', 'unchecked', 0),
  ]);
  final lines = parseDocumentLines(doc);
  doc.compose(
    buildChecklistToggleDelta(lines, 0, false),
    ChangeSource.local,
  );
  expect(nestedLinesOf(doc), [
    ('a', 'unchecked', 0),
    ('a1', 'unchecked', 1),
    ('b', 'unchecked', 0),
  ]);
});

test('a non-checklist child under a parent keeps its list state', () {
  final doc = nestedDoc([
    ('a', 'unchecked', 0),
    ('note', null, 1),
    ('a1', 'unchecked', 1),
  ]);
  final lines = parseDocumentLines(doc);
  doc.compose(
    buildChecklistToggleDelta(lines, 0, true),
    ChangeSource.local,
  );
  expect(nestedLinesOf(doc), [
    ('a', 'checked', 0),
    ('note', null, 1),
    ('a1', 'checked', 1),
  ]);
});
```

- [ ] **Step 2: Run the tests and verify they fail**

Run: `./.superpowers/sdd/2026-11-14-notesx-polish/ft.sh test/checklist_lines_test.dart`

Expected: FAIL with `buildChecklistToggleDelta` not defined.

- [ ] **Step 3: Implement `buildChecklistToggleDelta`**

In `mobile/lib/features/notes/presentation/editor/checklist_lines.dart`, add:

```dart
/// Toggles [index] and every checklist line in its block.
Delta buildChecklistToggleDelta(
  List<ParsedLine> lines,
  int index,
  bool checked,
) {
  final end = checklistBlockEnd(lines, index, lines.length - 1);
  final value = checked
      ? Attribute.checked.value
      : Attribute.unchecked.value;
  final delta = Delta();
  var cursor = 0;
  for (var i = index; i <= end; i++) {
    final line = lines[i];
    if (!line.isChecklist) continue;
    final newlineOffset = line.startOffset + line.length - 1;
    if (newlineOffset > cursor) delta.retain(newlineOffset - cursor);
    delta.retain(1, {Attribute.list.key: value});
    cursor = newlineOffset + 1;
  }
  return delta;
}
```

- [ ] **Step 4: Run the tests and verify they pass**

Run: `./.superpowers/sdd/2026-11-14-notesx-polish/ft.sh test/checklist_lines_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add mobile/lib/features/notes/presentation/editor/checklist_lines.dart mobile/test/checklist_lines_test.dart
git commit -m "feat: add a checklist block toggle delta"
```

---

### Task 2: Toggle the whole block from the editor

**Files:**
- Modify: `mobile/lib/features/notes/presentation/editor/rich_text_editor.dart:841-858`
- Test: `mobile/test/checklist_fold_test.dart`

**Interfaces:**
- Consumes: `buildChecklistToggleDelta` from Task 1.
- Produces: no new public API.

- [ ] **Step 1: Write the failing widget tests**

Add to `mobile/test/checklist_fold_test.dart`:

```dart
testWidgets('checking a parent checks its sub-items', (tester) async {
  final state = await pumpNote(tester, const [
    ('A', 'unchecked', 0),
    ('A1', 'unchecked', 1),
    ('B', 'unchecked', 0),
  ]);

  await tester.tap(checkboxOf('A'));
  await tester.pump(AnchorTokens.motionDurationSinkDelay);

  final lines = parseDocumentLines(state.controller.document);
  expect(lines[0].isChecked, isTrue);
  expect(lines[1].isChecked, isTrue);
  expect(lines[2].isChecked, isFalse);
});

testWidgets('unchecking a parent unchecks its sub-items', (tester) async {
  final state = await pumpNote(tester, const [
    ('A', 'checked', 0),
    ('A1', 'checked', 1),
    ('B', 'unchecked', 0),
  ]);

  await tester.tap(checkboxOf('A'));
  await tester.pump(AnchorTokens.motionDurationSinkDelay);

  final lines = parseDocumentLines(state.controller.document);
  expect(lines[0].isChecked, isFalse);
  expect(lines[1].isChecked, isFalse);
  expect(lines[2].isChecked, isFalse);
});

testWidgets('checking a parent keeps a hidden checked item hidden', (
  tester,
) async {
  final state = await pumpNote(tester, const [
    ('A', 'unchecked', 0),
    ('A1', 'unchecked', 1),
    ('B', 'unchecked', 0),
    ('B1', 'checked', 1),
  ], folded: true);

  await tester.tap(checkboxOf('A'));
  await tester.pump(AnchorTokens.motionDurationSinkDelay);

  expect(checkboxOf('B1'), findsNothing);
  expect(checkboxOf('A'), findsOneWidget);
  expect(checkboxOf('A1'), findsOneWidget);
  expect(state.getPlainText(), startsWith('A\nA1\nB\nB1'));
});
```

Add the missing import if needed:

```dart
import 'package:anchor/features/notes/presentation/editor/document_lines.dart';
```

- [ ] **Step 2: Run the tests and verify they fail**

Run: `./.superpowers/sdd/2026-11-14-notesx-polish/ft.sh test/checklist_fold_test.dart`

Expected: FAIL because the parent toggle changes only the parent line.

- [ ] **Step 3: Use the block delta in `_toggleCheckbox`**

In `mobile/lib/features/notes/presentation/editor/rich_text_editor.dart`, replace the body of `_toggleCheckbox` after the timer block with:

```dart
_consumeNextEditorTap();
final lines = parseDocumentLines(_controller.document);
final index = lineIndexAt(lines, line.documentOffset);
if (index == -1) return;
final delta = buildChecklistToggleDelta(lines, index, checked);
_editWithoutFocus(
  () => _controller.compose(
    delta,
    _controller.selection,
    ChangeSource.local,
  ),
);
```

- [ ] **Step 4: Run the tests and verify they pass**

Run: `./.superpowers/sdd/2026-11-14-notesx-polish/ft.sh test/checklist_fold_test.dart`

Expected: PASS.

- [ ] **Step 5: Run the full gate**

Run:

```bash
./.superpowers/sdd/2026-11-14-notesx-polish/ft.sh
./.superpowers/sdd/2026-11-14-notesx-polish/sync.sh
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null box-03 \
  'cd /data/tmp/notesx-test && export PATH=/data/workspace/toolchain/flutter/bin:$PATH && export PUB_CACHE=/data/home/.pub-cache && flutter analyze'
```

Expected: all tests pass; `No issues found!`.

- [ ] **Step 6: Commit**

```bash
git add mobile/lib/features/notes/presentation/editor/rich_text_editor.dart mobile/test/checklist_fold_test.dart
git commit -m "feat: toggle a checklist parent and its sub-items"
```