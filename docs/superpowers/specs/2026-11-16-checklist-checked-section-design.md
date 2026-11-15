# Checklist checked section — design

## Intent

A checked checklist block moves to the checked-items section at the end of the list, wherever the block started. A checked parent with sub-items can then be hidden like any other checked item.

## Goals

- Check a parent with sub-items: the whole block moves to the checked section.
- Check a child under an unchecked parent: that child block moves to the checked section.
- All checked blocks stay together at the end of the checklist run.
- The existing checked-items fold hides the whole section.
- Unchecked blocks keep their order.

## Non-goals

- No per-parent chevron or collapse control.
- No change to the checked-fold row UI.
- No drag-and-drop change.
- No search auto-expand.

## Behavior

Example before:

```text
A          unchecked
  A1       unchecked
B          unchecked
  B1       checked
```

Check A. Because the parent toggle cascades, A and A1 become checked. The result is:

```text
B
--- checked items ---
A
  A1
B1
```

B1 moved out of B because it is checked. The checked section is one trailing run, so the fold hides A, A1, and B1.

## Ordering rules

1. Parse the checklist run into blocks by indent.
2. A block is checked when its head line is checked. The parent toggle cascades, so a checked parent block is fully checked.
3. Walk the forest:
   - Checked block: move the whole block to the checked section.
   - Unchecked block: keep it in the unchecked section, then process its children. A checked child moves out to the checked section.
4. Checked blocks keep their original order.
5. Reindent moved blocks so each checked root is indent 0 and its descendants keep their relative indent.
6. Unchecked blocks keep their original order and indent.

The result is stable: sorting again changes nothing.

## Fold

The checked section is the trailing checked run. The current fold counts and hides it as one group. No new per-parent state is needed.

## Drag and drop

The sorter runs on a checkbox toggle, as today. Drag and drop is unchanged.

## Tests

- A checked parent at the top moves its whole block to the bottom.
- A checked child under an unchecked parent moves out to the checked section.
- Unchecked blocks keep their order.
- A nested checked parent moves its subtree.
- The fold count includes every checked line.
- Sorting twice is stable.
- Flat item behavior still passes.

## Risks

- The sort order of nested checklists changes. Existing nested sort tests must be rewritten to the new rule.
- A checked child leaves its unchecked parent, so the parent may have no children left.
- Drag and drop can still place an unchecked item after the checked section until the next toggle.