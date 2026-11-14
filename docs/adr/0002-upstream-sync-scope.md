---
status: accepted
date: 2026-11-14
---

# Adopt upstream changes that reduce animation latency or repaint cost

The fork merges upstream commit `dfa65c8` in full. That commit reduces
animation latency from 500 ms to 380 ms and adds `SnapshotScale` to reduce
repaint cost. It closes upstream issue #163 about slow note open and close.

The fork also merges upstream commit `e56fd02`. That commit fixes long code
lines in web code blocks. The fork restores `tabIndex`, `role="group"`, and
`aria-label="Code"` after the merge, because the upstream commit removes
them without a stated reason.

The fork keeps its own CI, Android signing guard, note search, backup, and
version. Both upstream commits are adopted in one upstream sync. The fork
does not adopt the upstream 1.7 or 1.55 note line heights.

## Considered Options

- Merge only `snapshot_scale.dart`. This leaves the new animation timings
  untested and drops the #163 fix.
- Skip `e56fd02`. This keeps the code-block overflow bug in the web app.
- Accept the accessibility attribute removal. This leaves read-only code
  blocks without a named group.

## Consequences

Upstream tests arrive with the merge. The fork must extend
`_MockPreferences` and any provider overrides that those tests need.
MotionSpeed still scales the new 380 ms duration. iOS share extension
changes need a Mac with Xcode, because fork CI does not build iOS.
