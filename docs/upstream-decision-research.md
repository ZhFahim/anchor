# Upstream Decision Research: Anchor Notes

Date: 2026-11-14 18:47 WITA (UTC+8).

## Sources

| Decision | Source |
| --- | --- |
| A. Motion duration 500ms → 380ms | Issue #163, commit dfa65c8 |
| B. SnapshotWidget/SnapshotScale | Commit dfa65c8 |
| C. Web code-block hanging indent | Commit e56fd02 |
| D. Accessibility attributes removal | Commit e56fd02 diff |
| E. Note line height 1.7/1.55 and checkbox 22px | Commits 4d69ef9, 328a516, c32711d |

## A. Why did upstream shorten motion from 500 ms to 380 ms?

User complaint (issue #163): When selecting and opening or closing an individual note, the animation is noticeably slower than on Keep. When going back and forth between notes, the animation can be annoying. The user asked for an option for quicker animations, similar to the speed in Keep.

Maintainer response: Closes #163. The commit message says "make open and close animations faster".

Evidence: Issue #163 is closed. The commit message says "feat(mobile): make open and close animations faster" and "Closes #163". No PR is linked in the issue. The change targets mobile page transitions, note morph, sheets, and list reordering.

## B. Why did upstream add `SnapshotWidget` / `SnapshotScale` in `dfa65c8`?

The commit message does not explicitly name a stutter, repaint, or jank problem. The commit adds `mobile/lib/core/motion/snapshot_scale.dart` with `SnapshotScale` and `SnapshotWidget`. The code comment says `SnapshotScale` "draws [child] as a picture taken when the scaling starts. Use it only for what doesn't change while it scales."

The commit message says "make open and close animations faster". The doc comment says the widget draws a picture of the child and must be used only for static children. No issue names stutter, jank, or repaint. The maintainer reason for the snapshot is not stated.

Evidence: Commit dfa65c80cc917642af2edb4be947dfb925049c44, file `mobile/lib/core/motion/snapshot_scale.dart`. No specific issue or PR is linked.

## C. Why did upstream add the web code-block hanging indent in `e56fd02`?

Commit title: "feat(web): wrap long lines in code blocks with a hanging indent". The commit message says the same. The diff shows the change in `web/features/notes/components/editor/code-copy-buttons.tsx`, but the hanging indent logic is not in that file. The commit also changes `web/features/notes/components/editor/code-copy-buttons.tsx` by removing accessibility attributes.

Search for "code block", "wrap", "long line", "indent", "horizontal scroll" in issues and PRs found no linked issue. Release notes for v0.18.0 (2026-11-05) do not mention code-block wrapping. The commit message is the only source.

User problem: Long lines in code blocks do not wrap. The commit changes `editor.css` to `pre-wrap` and `overflow-wrap: anywhere`. `history-view.tsx` now splits code into `.code-line` spans. No issue states the user problem. The commit title is the only stated reason.

Evidence: Commit e56fd024ef454f07d20605039e659fbbf3cc70a7, files `web/app/styles/editor.css` and `web/features/notes/components/history-view.tsx`.

## D. Why did upstream delete `tabIndex`, `role="group"`, and `aria-label="Code"` from `code-copy-buttons.tsx`?

The commit removes a loop that set `tabIndex`, `role="group"`, and `aria-label="Code"` on read-only code blocks. The commit message does not mention accessibility. No other file restores those three attributes for code blocks. `rich-text-editor.tsx` sets `root.tabIndex = 0` on the editor root, not on each code block.

The evidence does not prove that the removal is safe. Read-only code blocks lose a named group and a keyboard stop. The fork treats this as an accessibility regression and restores the attributes.

Evidence: Commit e56fd024ef454f07d20605039e659fbbf3cc70a7, diff of `code-copy-buttons.tsx` lines 29-35. `git grep` on merged tree `d42ac146` finds no replacement.

## E. Why does upstream use note line height 1.7 default / 1.55 compact, and a fixed 22 px checkbox?

### Note line height

Upstream at merge base `81c27fa` uses 1.7 standard and 1.55 compact in `design/tokens/base.tokens.json`. The fork uses 1.55 standard and 1.15 compact at `5d555f8`.

Commit `4d69ef9` belongs to the fork, not upstream. Its author is muava12. It set 1.55 standard and 1.0 compact. Commit `9c8e099`, also from the fork, raised compact to 1.15 because 1.0 cut the tails of g, y, p, and j. No upstream issue or design doc states a reason for 1.7 or 1.55.

Evidence: `git show 81c27fa:design/tokens/base.tokens.json`, `git show fork/main:design/tokens/base.tokens.json`, `git show -s 4d69ef9`, and `git show -s 9c8e099`.

### Fixed 22 px checkbox

The checkbox size was introduced in commit c32711d "feat(mobile): rebuild the note editor". The file `mobile/lib/features/notes/presentation/editor/list_markers.dart` defines `const double _checkboxSize = 22;` as a constant.

Commit `328a516` belongs to the fork, not upstream. It added `sizeFor(lineHeight)` with `maxSize = 22` and `minSize = 14`. Its comment says a fixed size would draw the box over the line above and the one below. That fork decision is now reversed by ADR-0001.

The initial 22 px size came from upstream commit `c32711d`. No upstream issue or design doc states an accessibility reason for 22 px.

Evidence: `git show -s c32711d`, `git show -s 328a516`, and `mobile/lib/features/notes/presentation/editor/list_markers.dart` lines 341-356. No stated design doc or issue about readability and compact density was found.

## Effect on our fork decision

- The motion duration change (500ms → 380ms) is a user-facing performance improvement. We can adopt it to match user expectations.
- `SnapshotWidget` / `SnapshotScale` is an implementation detail for smoother animations. We can keep it if we adopt the motion change.
- The web code-block hanging indent is a layout fix for long lines. We can adopt it to prevent overflow in the editor.
- Restore the removed accessibility attributes after merging `e56fd02`.
- Keep fork line height 1.55 standard. Raise compact to 1.40 and keep the 22 px visual check size. Do not adopt upstream 1.7 or 1.55.
- Record the decisions in `docs/adr/0001-visual-check-size-and-compact-density.md` and `docs/adr/0002-upstream-sync-scope.md`.
