# Local backup — progress ledger

Plan: docs/superpowers/plans/2026-11-14-local-backup.md
Branch: feat/local-backup
Base: 5414c19

Note: this host has no Flutter. Tests are run on box-03 over SSH:
  tar czf /tmp/sync.tgz -C mobile lib test pubspec.yaml
  scp to box-03:/data/workspace/anchor-dev/
  flutter analyze && flutter test

Task 1: complete (commits 5414c19..9b86a2e, tests pass on box-03)
  - archive 4.5.2 addFile drops the entry; writer uses addArchiveFile with bytes.
Task 2: complete (tests pass on box-03)
  - Formatting: run `dart format` on box-03 once at the end for all backup files.
Task 3: complete (5 tests pass on box-03)
  - cryptography resolves to 2.9.0; pubspec.lock updated from box-03.
  - decrypt now refuses a truncated file with BackupFormatException.
Task 4: complete (14 backup tests pass, analyze clean on box-03)
  - _attachmentsRoot now resolves a relative localPath, so the field is used.
Task 5: complete (20 backup tests pass on box-03)
  - BackupTag gained version; keepIds keeps tag versions, newIds clears them.
  - Restore deletes replaced attachment files after commit, and written files on rollback.
  - Duplicate tag ids per note are de-duplicated.
Task 6: complete (4 tests pass on box-03)
  - Added androidx.documentfile:1.0.1 to android/app/build.gradle.kts.
  - Dart wrapper sends Uint8List so Kotlin receives a byte array.
  - Kotlin compile NOT verified: box-03 has no Android SDK. CI will verify.
Task 7: complete (3 tests pass on box-03; riverpod .g.dart generated on box-03 and copied back)
  - copyWith gained clearFolder, so setFolder(null) clears the in-memory state too.
Task 8: complete (4 tests pass on box-03; backup_controller.g.dart generated and copied back)
  - Test mocks path_provider and PackageInfo; added a retention test.
  - bytes is List<int> so the encrypted path compiles.
Task 9: complete (5 tests pass on box-03)
Task 10: complete (1171 tests pass on box-03, analyze clean, format clean)
  - FilePicker.pickFile replaces the removed FilePicker.platform API.
  - l10n descriptions added for 6 messages; share extension strings regenerated.

## Kotlin / Android build verification (post-plan)
- box-03 Android build verified after disk optimization: `flutter build apk --debug --target-platform=android-arm64` succeeded.
- BackupFolderPlugin compiled into the APK (classes18/20.dex contain zhfahim/anchor/backup/BackupFolderPlugin).
- The gradle signingConfig fix (key.properties guard) works on a machine without the keystore.
- box-03 gotcha: universal build hit transient TLS rate-limiting to storage.googleapis.com; single-ABI succeeded. GitHub mobile-android job (ubuntu-latest) is the universal gate.

## 2026-11-14 15:06 WITA — release v0.23.0 shipped
- Checkbox compact fix visual-verified: golden PNGs rendered on box-03 (compact 15px box, standard 22px box, no bleed onto title or neighbour rows); temp test + PNGs deleted.
- GitHub Actions was wedged on the fork (runs queued 6h with no jobs, dispatch 422 "disabled" while API said enabled). Unblock: added `workflow_dispatch` to ci.yml; new push triggered run 43568523842 → ALL SUCCESS in 8m43s (incl. mobile-android on GitHub runner).
- Merged PR #2 into fork main (c1c7b17); closed PR #3 (superseded).
- Bumped mobile/pubspec.yaml → 0.23.0+32, tagged v0.23.0, pushed. Release workflow 43569305339 → success: docker amd64/arm64 + universal/split APKs published to the v0.23.0 GitHub release (4 assets).
- box-03: universal build fails on parallel engine-JAR download + /data fills 20G; arm64 build kept working after clearing stale gradle transforms cache. Universal builds stay on GitHub.
- DONE: spec, plan, 10 tasks, PR, release. No open items.

## 2026-11-14 19:50 WITA — upstream sync and v0.23.1
- Grilling and domain modeling resolved. Glossary and ADR-0001/0002 written. Research report corrected.
- Merged origin/main (dfa65c8 + e56fd02) into a worktree. Merge tree CLEAN.
- Kept the 22 px visual check size. Raised compact note line height to 1.40. Removed NoteCheckBox.sizeFor.
- Restored read-only code-block accessibility attributes. Extended upstream drawer test mocks.
- Gates on box-03: token check OK, web check OK, web 444 tests, server check OK, server 348 tests, flutter analyze OK, flutter 1191 tests, Dart format OK.
- Scheduled a daily 08:00 WITA read-only upstream check (id de5059).
