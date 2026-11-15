# Checklist parent toggle — design

## Intent

A parent checklist item with sub-items must toggle its whole subtree. A checked item hidden by the fold must not reappear when another item is toggled.

## Goals

- Tapping a parent checkbox checks or unchecks every checklist descendant.
- A parent with sub-items keeps its current position when toggled.
- Hidden checked items stay hidden.
- Flat checklist behavior stays the same.

## Non-goals

- No change to drag and drop.
- No change to indent or outdent.
- No change to the fold row UI.

## Approach

Chosen: **cascade the toggle to the subtree, and do not reorder a block that has sub-items.**

Alternatives considered:

1. Sort a block by its last line. This keeps a trailing checked child hidden, but a parent with an open sub-item no longer sinks. It also does not cover every mixed case.
2. Cascade only. This makes parent and child states agree, but the parent block still moves. The move can expose a checked child in another block, so the reported bug remains.
3. Skip sorting for every list with sub-items. This hides the jump but also stops child-level sorting.

The chosen approach uses one document change for the whole subtree. `ChecklistSorter` ignores a change that touches more than one checklist line. A block with sub-items therefore does not move. A flat item still produces a one-line change and still sorts.

## Behavior

- Tap a parent checkbox: every checklist line in its block gets the new state.
- Tap a child checkbox: only that child block changes, as today.
- The parent block stays where it is. Its children keep their order.
- A checked item hidden at the end of the list stays hidden after the toggle.

## Implementation

- Add `buildChecklistToggleDelta(lines, index, checked)` in `checklist_lines.dart`.
- It walks `checklistBlockEnd(lines, index, lines.length - 1)` and changes each checklist line.
- `_toggleCheckbox` composes that delta in one edit.
- `ChecklistSorter` needs no change. A multi-line toggle is not a single-line toggle, so it does not reorder.

## Tests

- Checking a parent checks every checklist descendant.
- Unchecking a parent unchecks every checklist descendant.
- A checked item hidden at the end stays hidden after a parent toggle.
- A flat item still moves to the bottom when checked.
- The existing checklist suite stays green.

## Risks

- A parent with sub-items no longer moves when toggled. This is the trade-off for keeping hidden items hidden.