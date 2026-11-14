# Notesx polish: label, lock grace, search focus, backup folder

Date: 2026-11-14
Status: approved in brainstorming, not implemented

## Goal

Six user-visible fixes in the Anchor fork, plus the app label change to
`Notesx`. The fork keeps the upstream `applicationId`, `namespace`, OAuth
scheme, and iOS bundle id. No package change happens in this spec.

## Scope

In scope:

1. App label `Anchor Notes` becomes `Notesx`.
2. A grace period before the app lock asks for biometrics again.
3. The search field takes focus when the search icon is tapped.
4. Closing a search returns focus to where it was.
5. Next and previous in a search stop shifting the view.
6. The backup section shows the chosen folder name and matches the other
   settings sections.

Out of scope, and named so nobody adds them later:

- Changing `applicationId`, `namespace`, or the iOS bundle id.
- Registering a signing certificate with Google Play.
- Changing the OAuth redirect scheme.
- Any new deep link. The fork has no exported deep link today. `anchor://` is
  only the OAuth redirect. `anchorwidget://` is internal to the home widget.

## Decisions

### 1. Label

`app_name` is `Anchor Notes` at `mobile/android/app/src/main/res/values/strings.xml:3`.
The in-app name is `appName` at `mobile/lib/l10n/app_en.arb:3`, generated into
`mobile/lib/l10n/app_localizations_en.dart:12`.

The fork shows `Notesx` in both places. The home widget keeps `widget_app_name`
= `Anchor`, because that is text inside the widget, not the app name.

### 2. Lock grace period

`AppLockGate.didChangeAppLifecycleState` locks on `paused` and `hidden`
(`mobile/lib/features/settings/presentation/app_lock_gate.dart:47`).
`AppLockController.lock()` sets the covered state. `unlock()` calls the device
authenticator every time.

New behaviour:

- The cover still appears when the app leaves the screen. The Android
  thumbnail must not show a note.
- On resume, the cover is removed without a biometric prompt when the time since
  the last successful unlock is below the grace period.
- The grace period is stored on the device. The default is 5 minutes.
- The setting offers `Off`, `1`, `5`, and `15` minutes.

`AppLockController` gains `lastUnlockedAt` in memory. `AppLockGate` reads it on
resume. The value is not persisted, so a cold start always asks.

`PreferencesRepository` gains `getLockGraceMinutes` and
`setLockGraceMinutes`. `StorageKeys` gains the key. The key is read in
`bootstrap.dart` and carried into `AppBootstrap` next to `appLockEnabled`.

`_SecuritySection` gains a `SegmentedControl` under the existing `SwitchRow`.
The control is disabled while the app lock is off.

### 3. Focus the search field

`NoteSearchBar` already sets `autofocus: true` on its `TextField`
(`mobile/lib/features/notes/presentation/widgets/note_search_bar.dart:69`).
Focus still does not land there, because the editor keeps its focus node and the
bar is built in the same frame.

New behaviour:

- `NoteSearchBar` owns a `FocusNode` and requests focus in
  `didChangeDependencies`.
- `_openSearch` unfocuses the title and editor nodes before it sets
  `_isSearching`.

### 4. Return focus when a search closes

`_closeSearch` clears the query and sets `_isSearching` to false
(`mobile/lib/features/notes/presentation/note_edit_screen.dart:189`). Focus is
lost to the page body.

New behaviour:

- `_openSearch` records which of `_titleFocus` or `_editorFocus` had focus.
- `_closeSearch` requests focus on that node again.
- When neither had focus, `_closeSearch` focuses the editor.

### 5. Next and previous

`RichTextEditor.revealRange` always animates to
`offset + top - 120` (`mobile/lib/features/notes/presentation/editor/rich_text_editor.dart:158`).
It does not look at the current scroll position.

That is the bug. With one match, every tap runs the same animation and the view
shifts. With two matches, the animation after the last match is wrong.

New behaviour:

- `revealRange` reads the current viewport.
- When the match is already fully visible, it does nothing.
- When it is not visible, it scrolls the smallest distance that makes it
  visible, then applies the 120 px headroom only when the match is above the
  viewport.
- `NoteSearchController._step` already wraps with `% count`
  (`mobile/lib/features/notes/presentation/editor/note_search_controller.dart:52`).
  It does not change.

### 6. Backup folder and section layout

`BackupSection` shows `value: settings.hasFolder ? l10n.backupFolder : l10n.backupChooseFolder`
(`mobile/lib/features/backup/presentation/backup_section.dart:39`). The chosen
value is the static word `Folder`, never the folder.

New behaviour:

- `BackupSettings` gains `folderName`.
- `BackupFolder.pick()` returns both the URI and the display name. The Kotlin
  plugin reads `DocumentFile.name` after `ACTION_OPEN_DOCUMENT_TREE`.
- The row shows the folder name. It shows `Choose a folder` when nothing is
  chosen.
- `BackupSection` uses `GroupedListTile` instead of its own `_Row`. Each row
  gets an icon. `Back up now` and `Restore` get a chevron when they can be
  tapped. The section keeps the shared `Section` header that the other settings
  sections use.

## Testing

- `flutter analyze` and `flutter test` in `mobile/`.
- A widget test for the lock grace: cover shows on pause, no prompt inside the
  window, prompt after the window.
- A widget test for search focus in and out.
- A widget test for `revealRange` with one match, two matches, and a match that
  is already visible.
- A unit test for `folderName` and the chosen-folder row.
- A golden check for the backup section against another settings section.
- `node design/build/build.mjs --check` from the repo root, because the design
  tokens are not changed here but CI runs the gate anyway.

## Risks

- The grace period weakens the lock. The owner chose 5 minutes as the default.
- `folderName` needs a Kotlin change. The plugin must return the name with the
  URI, or the Dart side must decode the URI. The Kotlin route is chosen.
- `revealRange` runs on every keystroke through `_searchChanged`. The new
  visibility check must be cheap.

## Open items

None.