---
status: accepted
date: 2026-11-14
---

# Keep a 22 px visual check size and raise compact line height

The fork keeps the 22 px visual check size for touch accessibility. Compact
density moves from line height 1.15 to 1.40. Standard density stays at 1.55.

At 16.5 px body text, 1.15 gives an 18.975 px line box. A 22 px square
crosses that line box by 3.025 px and touches neighbour rows. 1.40 gives a
23.1 px line box. The square then has 0.55 px of space above and below.

The earlier `NoteCheckBox.sizeFor` fix shrank the square to about 19 px in
compact density. We remove that method. `version_diff_view.dart` also uses
22 px. The 44 px touch target does not change.

## Considered Options

- Keep 1.15 and shrink the square. This preserves density but abandons the
  22 px visual check size.
- Keep 22 px and leave 1.15. This preserves the overlap with neighbour rows.
- Remove compact density. This gives up a user-visible density choice.

## Consequences

Compact density is now close to standard density. The fork accepts that loss
of contrast. The token source and the Dart, Swift, and CSS generated files
must change together. A 22 px square must stay inside the computed line box.
