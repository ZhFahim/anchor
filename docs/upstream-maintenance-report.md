# Upstream maintenance report

Date: 2026-11-14 17:40 WITA (UTC+8).
Repository: `/home/mimin/projects/anchorx`.
This report compares `fork/main` with `origin/main`. It records facts only.
It does not merge, stage, commit, or push.

## 1. Purpose

The fork carries 46 commits after the merge base. Upstream carries 2 commits.
This report names the 2 upstream commits, tests the merge tree, and judges the merge value.
It also compares 8 product areas and names the risks.

## 2. Commands and results

All commands ran in `/home/mimin/projects/anchorx`. The table lists each result.

| Command | Result |
| --- | --- |
| `git fetch origin --prune` | Exit 0. No output. |
| `git fetch fork --prune` | Exit 0. No output. |
| `git log --oneline fork/main..origin/main` | 2 commits: `dfa65c8`, `e56fd02`. |
| `git rev-list --count fork/main..origin/main` | 2. |
| `git rev-list --count origin/main..fork/main` | 46. |
| `git merge-base fork/main origin/main` | `81c27fab5ca56d2488cd131d1f6ed21b3706d77c`. |
| `git show --stat <sha>` | File counts and line counts in section 4. |
| `git show <sha> -- <paths>` | Key hunks read for both commits. |
| `git diff --name-only 81c27fa fork/main` | 122 fork paths. |
| `git diff --name-only 81c27fa origin/main` | 33 upstream paths. |
| `git merge-tree --write-tree fork/main origin/main` | `d42ac146e072de60d73d593acf69c399ed8408e6`. Exit 0. |
| `git merge-tree --write-tree --messages fork/main origin/main` | Same tree. 4 `Auto-merging` lines. 0 conflicts. |
| `git merge-tree --write-tree --name-only -z fork/main origin/main` | Only the tree OID. 0 conflicted paths. Exit 0. |
| `comm -12` on both changed-path lists | 4 overlapping paths. See section 5. |
| `node design/build/build.mjs --check` on merged tree | First attempt failed. Second attempt passed. See section 8. |
| `gh run list --repo muava12/anchor --limit 10` | Latest CI and Release succeeded at 2026-11-14 15:03 WITA. |
| `gh release list --repo muava12/anchor --limit 10` | 7 releases. `v0.23.0` published at 16:09 WITA. `v0.22.1` still shows Latest. |
| `gh pr list --repo muava12/anchor --state all --limit 10` | 3 merged PRs. |
| `git status --short` | ` M .superpowers/sdd/progress.md`. This change existed before the audit. The audit did not touch it. |

## 3. Repository state

The remotes, heads, and counts define the comparison.

| Item | Value |
| --- | --- |
| `origin` | `https://github.com/zhfahim/anchor.git` (upstream, read-only). |
| `fork` | `https://github.com/muava12/anchor.git` (fork, all pushes). |
| `origin/main` | `dfa65c80cc917642af2edb4be947dfb925049c44`. |
| `fork/main` | `5d555f89028a81c1503d98d7628cf1da8e482998`. |
| `main` | `5d555f89028a81c1503d98d7628cf1da8e482998`. |
| Merge base | `81c27fab5ca56d2488cd131d1f6ed21b3706d77c`. |
| Base commit subject | `Merge pull request #215 from GitGitro/add-custom-headers`. |
| Upstream-only commits | 2. |
| Fork-only commits | 46. |
| Upstream changed paths | 33. |
| Fork changed paths | 122. |
| Fork deletions or renames | 0. |
| Fork changes under `web/` | 0. |

## 4. Upstream commits by area

The 2 upstream commits split into one mobile group and one web group.

### 4.1 `dfa65c8` — mobile motion speed

`dfa65c8` has subject `feat(mobile): make open and close animations faster`.
Author: ZhFahim. Date: 2026-11-12 20:18 WITA. It closes issue `#163`.
It changes 25 files. It adds 990 lines and removes 82 lines.

| Area | Paths | Change |
| --- | --- | --- |
| Token source | `design/tokens/base.tokens.json` | Smooth spring changes from 500 ms to 380 ms. Snappy description gains sheet and drawer text. |
| Generated tokens | `mobile/ios/ShareExtension/AnchorTokens.swift`, `mobile/lib/core/theme/tokens/anchor_tokens.dart` | Smooth duration changes from 0.5 s to 0.38 s, and from 500 ms to 380 ms. |
| Page transitions | `mobile/lib/core/motion/page_transitions.dart` | Reverse duration changes from 420 ms to `Spring.smooth.duration`. A `cancel` phase, `_Slide`, and `SnapshotWidget` are added. |
| Reorder and snapshot | `mobile/lib/core/motion/reorder_animation.dart`, `mobile/lib/core/motion/snapshot_scale.dart` | `Transform.scale` changes to `SnapshotScale`. The snapshot file is new. |
| Core widgets | `mobile/lib/core/widgets/anchor_dialog.dart`, `anchor_menu.dart`, `anchor_sheet.dart` | Scale transitions use `SnapshotScale`. The sheet gains `onGone`, a snappy reverse, and a `spring:` argument. |
| Note screens | `link_edit_sheet.dart`, `note_edit_screen.dart`, `note_morph_route.dart`, `notes_list_screen.dart` | Delayed focus and delayed navigation are removed. The morph route becomes touchable at 0.9 progress. |
| Drawer | `app_drawer.dart`, `drawer_host.dart` | Delays are removed. Close uses `Spring.snappy`. A `SnapshotController` and page-over status listener are added. |
| Share target | `mobile/lib/features/share_target/presentation/share_sheet_app.dart` | A `Completer` waits for `onGone` instead of a fixed 500 ms delay. |
| iOS share extension | `mobile/ios/ShareExtension/ShareSheetView.swift` | Close uses `Springs.snappy` and the 0.32 s snappy duration. |
| Tests | 8 files under `mobile/test/` | 4 new test files, 4 updated test files. New assertions cover snapshots, sheet `onGone`, focus timing, and drawer build count. |

### 4.2 `e56fd02` — web code-block indent

`e56fd02` has subject `feat(web): wrap long lines in code blocks with a hanging indent`.
Author: ZhFahim. Date: 2026-11-12 00:13 WITA.
It changes 8 files. It adds 211 lines and removes 18 lines.

| Area | Paths | Change |
| --- | --- | --- |
| Editor CSS | `web/app/styles/editor.css` | Code blocks change from `white-space: pre` and horizontal scroll to `pre-wrap`, `overflow-wrap: anywhere`, and `tab-size: 4`. |
| Note CSS | `web/app/styles/note-body.css` | `.doc pre.code .code-line` gains a hanging indent. Card previews keep `white-space: pre`. |
| New helpers | `web/features/notes/code-lines.ts`, `web/features/notes/code-lines.test.ts` | `codeIndentColumns` and `splitCodeLines` are added with 6 tests. |
| Editor hook | `use-code-indents.ts`, `rich-text-editor.tsx` | A `MutationObserver` sets `--code-indent` on each `.ql-code-block`. |
| Read-only blocks | `code-copy-buttons.tsx` | The `tabIndex`, `role="group"`, and `aria-label="Code"` writes are removed. |
| Version history | `history-view.tsx` | `CodeText` splits code lines into `<span className="code-line">` and keeps diff marks. |

## 5. Merge tree result

The merge tree is CLEAN. Git reports 0 conflicts and 0 conflicted paths.
Tree OID: `d42ac146e072de60d73d593acf69c399ed8408e6`.
Git auto-merges 4 paths. These 4 paths are also the full overlapping set.

| Overlapping path | Fork change | Upstream change |
| --- | --- | --- |
| `design/tokens/base.tokens.json` | `noteLineHeight` 1.55 and 1.15. | Smooth 380 ms and snappy description. |
| `mobile/ios/ShareExtension/AnchorTokens.swift` | `noteLineHeight` 1.55 and 1.15. | Smooth 0.38 s. |
| `mobile/lib/core/theme/tokens/anchor_tokens.dart` | `noteLineHeight`, `searchHighlight`, `searchHighlightActive`. | Smooth 380 ms. |
| `mobile/lib/features/notes/presentation/note_edit_screen.dart` | Note search, `moveTaskToBack`, `NoteSearchBar`. | Immediate title focus. |

The merged tree keeps both sets of values. Verification reads the tree directly.

| Merged file | Verified value |
| --- | --- |
| `design/tokens/base.tokens.json` | Smooth 380 ms, snappy 320 ms, `noteLineHeight` 1.55 and 1.15. |
| `mobile/ios/ShareExtension/AnchorTokens.swift` | Smooth 0.38 s, snappy 0.32 s, line heights 1.55 and 1.15. |
| `mobile/lib/core/theme/tokens/anchor_tokens.dart` | Smooth 380 ms, snappy 320 ms, line heights 1.55 and 1.15, `searchHighlight` retained. |
| `mobile/lib/features/notes/presentation/note_edit_screen.dart` | Upstream immediate focus and fork note search both present. |
| `mobile/pubspec.yaml` | `0.23.0+32`. |
| `web/app/styles/editor.css` | `pre-wrap` and hanging indent. |
| `web/app/styles/note-body.css` | `pre-wrap`, `.code-line` indent, card preview `pre`. |

## 6. Verdicts

Each group gets one verdict. The reason states the merge value in one sentence.

| Group | Verdict | Reason |
| --- | --- | --- |
| Motion token duration and 3 generated files | MERGE WITH CARE | The fork needs the faster 380 ms motion, but the generated files require the token check. |
| 12 unchanged mobile motion source files | MERGE | The fork did not rewrite these files, and the commit fixes predictive back, sheet closing, and drawer timing. |
| `note_edit_screen.dart` | MERGE WITH CARE | Git auto-merged the focus change, but the fork rewrote this file for note search and `moveTaskToBack`. |
| 8 new or updated mobile tests | MERGE WITH CARE | The tests assert upstream timing and use mocks that the fork added providers may not satisfy. |
| iOS share extension | MERGE | The fork left `ShareSheetView.swift` unchanged, so the snappy close animation applies cleanly. |
| 8 web code-block files | MERGE | The fork changed no file under `web/`, so all 8 files apply cleanly. |
| Upstream change to a deleted or replaced fork file | SKIP | The fork deleted no file and replaced no upstream file, so this case does not occur. |

Overall verdict: MERGE WITH CARE. Both upstream commits carry user-visible fixes.
No upstream commit targets a file that the fork deleted or replaced.

## 7. Comparison table

The table compares the fork state, the upstream state, and the effect of a merge.

| Area | Fork state | Upstream state | Effect if merged |
| --- | --- | --- | --- |
| App version and build | `0.23.0+32` in `mobile/pubspec.yaml`. 7 releases up to `v0.23.0`. | `0.18.0+25` in `mobile/pubspec.yaml`. | Merge keeps `0.23.0+32`. Upstream commits do not edit `pubspec.yaml`. |
| Backup and restore | 17 library files under `mobile/lib/features/backup/**`, 10 tests, `BackupFolderPlugin.kt`, NotallyX tools, Settings section. | No backup feature at the merge base. | Merge keeps every fork backup file. No upstream file overlaps. |
| Note checkbox sizing in compact mode | `NoteCheckBox.sizeFor(lineHeight)` with `minSize 14` and `maxSize 22`. `version_diff_view.dart` passes the size. | Fixed `_checkboxSize = 22`. | Merge keeps fork adaptive sizing. Upstream does not touch `list_markers.dart`. |
| Line-height tokens | 1.55 default and 1.15 compact in 3 token files. | 1.7 default and 1.55 compact. Only motion duration changes nearby. | Merge keeps 1.55 and 1.15, and takes 380 ms. The token check on the merged tree passed. |
| Motion durations | Smooth 500 ms, snappy 320 ms. `MotionSpeed` scale 1, 0.3, or 0. | Smooth 380 ms, snappy 320 ms. No app motion setting. | Merge sets smooth to 380 ms. `MotionSpeed` still scales it to 380, 114, or 0 ms. |
| Code-block rendering in web | `white-space: pre`, `overflow-x: auto`, horizontal scroll. `history-view.tsx` renders one `<pre>`. | `pre-wrap`, `overflow-wrap: anywhere`, hanging indent. `code-lines.ts`, `use-code-indents.ts`, `CodeText`. | Merge replaces scroll with wrap and indent. Card preview keeps `pre`. |
| CI workflows | `workflow_dispatch`, self-hosted `mobile-lint`, `mobile-android` debug APK, Flutter `3.47.9`. | One `mobile-lint` job on `ubuntu-latest` with `flutter analyze` and `flutter test`. | Merge keeps fork CI. Upstream commits do not touch `.github/`. |
| Android signing | `build.gradle.kts` creates the `release` signing config only when `key.properties` exists. `release.yml` generates a fallback key. | Unconditional `signingConfigs.create("release")` reads `key.properties` and throws when the file is absent. | Merge keeps the fork guard. Debug builds still work without a keystore. |

## 8. Risks

Seven risks need a check after a real merge. Each item names the files and the check.

1. **Rewritten `note_edit_screen.dart`.** The fork added `NoteSearchController`, `NoteSearchBar`, `moveTaskToBack`, and `searchHighlight`. Upstream removed a 280 ms focus delay. Git merged the file cleanly. Run `flutter test mobile/test/note_edit_screen_test.dart` after the merge.
2. **Regenerated token files.** The 3 overlapping generated files are `design/tokens/base.tokens.json`, `AnchorTokens.swift`, and `anchor_tokens.dart`. `design/build/build.mjs` regenerates CSS, Dart, and Swift. The first merged-tree check failed with `ERR_MODULE_NOT_FOUND` for `web/node_modules/lucide-react`. A second check with a symlink to `web/node_modules` printed `Generated files are up to date.` and returned exit 0. Run `node design/build/build.mjs --check` in the real worktree after the merge. CI enforces this gate.
3. **New upstream tests.** The commit adds 8 test files under `mobile/test/`. `notes_list_drawer_test.dart` stubs only `getCustomHeaders` on `_MockPreferences`. The fork added `getNotesViewType`, `getNotesSortOption`, `getNotesSortAscending`, `getMotionSpeedName`, `getAppLockEnabled`, and backup getters. The fork also added providers that the upstream test does not override. Run `flutter test` after the merge.
4. **`MotionSpeed` interaction.** Upstream uses `Spring.smooth.duration` and `Spring.snappy` in `anchor_sheet.dart`, `page_transitions.dart`, `drawer_host.dart`, and `share_sheet_app.dart`. The fork scales these durations. Compilation works because `springBackTo` keeps the `spring` named parameter. Check fast and off modes on a device.
5. **Accessibility removal.** `code-copy-buttons.tsx` removes `tabIndex`, `role="group"`, and `aria-label="Code"` for read-only code blocks. Check keyboard access and screen reader labels after the merge.
6. **iOS share extension.** `ShareSheetView.swift` now closes with `Springs.snappy` after 0.32 s. Fork CI does not build the iOS share extension. Check on a Mac with Xcode.
7. **Snapshot widgets.** `SnapshotWidget` and `SnapshotScale` appear in 6 files. Check repaint behaviour under `MotionSpeed.off` and after `didChangeMetrics`.

## 9. Checks not run

The task brief forbids build commands. This audit ran no `flutter build`, `flutter test`, `pnpm`, or other build command.
It ran only read-only `gh` commands. It staged, committed, and pushed nothing.
It created only this report file.

## 10. Next steps

A real merge must happen in a separate worktree. The steps below are a recommendation, not an action of this audit.

1. Merge `origin/main` into `fork/main` in a separate worktree.
2. Run `node design/build/build.mjs --check` from the repository root.
3. Run `cd mobile && flutter analyze && flutter test`.
4. Run `cd web && pnpm check && pnpm test`.
5. Check code-block keyboard access and the iOS share extension on a device.
6. Push only after all gates pass.
