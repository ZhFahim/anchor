# Anchor

Anchor is an offline-first note app. This glossary names the terms that the
fork uses for note density, motion, and fork maintenance.

## Note density

**Visual check size**:
The drawn square of a note checkbox. It is 22 px in every density.
_Avoid_: checkbox size, box size

**Touch target**:
The invisible 44 px area that accepts a tap on a note checkbox.
_Avoid_: hit area, tap target, checkbox size

**Touch accessibility**:
The rule that keeps the touch target at 44 px when the visual check size changes.
_Avoid_: accessibility size, a11y checkbox

**Compact density**:
The note density with line height 1.40. It keeps a 22 px visual check size
inside a 23.1 px line box.
_Avoid_: tight mode, small mode

**Standard density**:
The note density with line height 1.55.
_Avoid_: normal mode, default mode

## Motion

**Animation latency**:
The elapsed time from a user action to the end of its transition.
_Avoid_: animation speed, motion speed

**Repaint cost**:
The work that Flutter does to redraw a widget during a transition.
_Avoid_: jank, frame cost

## Checklists

**Checked section**:
The run of checked checklist blocks at the bottom of a checklist group.
_Avoid_: done section, completed list

**Frozen block**:
A checked checklist block with at least one unchecked descendant. It stays in
place, and its children do not move, until every descendant is checked.
_Avoid_: locked block, pending parent

## Fork maintenance

**Upstream**:
The `zhfahim/anchor` repository. The fork reads it and never pushes to it.
_Avoid_: origin repository, main repository

**Fork**:
The `muava12/anchor` repository. All release work is pushed here.
_Avoid_: our repo, local anchor

**Upstream sync**:
A merge of upstream commits into the fork, followed by the four gates.
_Avoid_: rebase, update, pull
