# Notesx Polish Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the six approved user-visible fixes: the `Notesx` label, a lock grace period, search focus in and out, consistent next/previous, and a backup section that names the chosen folder.

**Architecture:** Small, local changes on top of the existing Riverpod and Provider patterns. The lock grace keeps its duration in `PreferencesRepository` and its last-unlock time in memory on `AppLockController`. Search focus moves between the bar's own `FocusNode` and the note screen's title and editor nodes. `revealRange` gains a visibility check before it animates. The backup folder name comes from Kotlin's `DocumentFile.name` and travels with the URI.

**Tech Stack:** Flutter, Riverpod (code-generated), Kotlin, Android document tree.

**Spec:** `docs/superpowers/specs/2026-11-14-notesx-polish-design.md`

## Global Constraints

- App label is exactly `Notesx`. The home widget keeps `widget_app_name` = `Anchor`.
- `applicationId` stays `com.zhfahim.anchor`. `namespace` stays `com.zhfahim.anchor`. The OAuth redirect stays `anchor://oidc/callback`. No iOS change.
- Lock grace default is 5 minutes. Choices are `Off`, `1`, `5`, `15`.
- The cover still appears on `paused`. Only the biometric prompt is deferred.
- `node design/build/build.mjs --check` must pass from the repo root. This plan changes no design token.
- `flutter analyze` and `flutter test` in `mobile/` must pass before any commit is called done.
- Every new string goes in `mobile/lib/l10n/app_en.arb`. Run `flutter gen-l10n` after editing it. Never hardcode copy in a widget.

## Review Focus

1. **Grace of `Off`.** With the setting off, a return from another app asks for biometrics every time. Pin it in Task 3's test.
2. **Grace across a cold start.** The last unlock time is in memory, so a killed app asks even inside the window. Pin it in Task 2's test.
3. **Search closed with no match.** Closing a search that found nothing must not crash and must return focus to the editor. Pin it in Task 4's test.
4. **A match already on screen.** Next must not move the view when the active match is fully visible. Pin it in Task 5's test.
5. **A folder URI with no display name.** Some providers give a URI whose `DocumentFile.name` is null. The row must fall back to `Choose a folder`. Pin it in Task 6's test.

---

### Task 1: The `Notesx` label

**Files:**
- Modify: `mobile/android/app/src/main/res/values/strings.xml:3`
- Modify: `mobile/lib/l10n/app_en.arb:3`
- Regenerate: `mobile/lib/l10n/app_localizations.dart`, `mobile/lib/l10n/app_localizations_en.dart`
- Test: `mobile/test/l10n_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces: `AppLocalizations.of(context).appName` returns `Notesx`. The Android label resolves to `Notesx`.

- [ ] **Step 1: Write the failing test**

```dart
test('the app name is Notesx', () {
  expect(AppLocalizationsEn().appName, 'Notesx');
});
```

- [ ] **Step 2: Run it and watch it fail**

Run: `cd mobile && flutter test test/l10n_test.dart`
Expected: FAIL, `Expected: 'Notesx' Actual: 'Anchor Notes'`

- [ ] **Step 3: Change both sources**

Set `app_name` in `strings.xml` to `Notesx`. Set `appName` in `app_en.arb` to `Notesx`. Leave `widget_app_name` as `Anchor`.

- [ ] **Step 4: Regenerate the localizations**

Run: `cd mobile && flutter gen-l10n && flutter test test/l10n_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add mobile/android/app/src/main/res/values/strings.xml mobile/lib/l10n/app_en.arb mobile/lib/l10n/app_localizations.dart mobile/lib/l10n/app_localizations_en.dart mobile/test/l10n_test.dart
git commit -m "feat: name the app Notesx"
```

---

### Task 2: Lock grace duration and the in-memory unlock time

**Files:**
- Modify: `mobile/lib/core/storage/storage_keys.dart`
- Modify: `mobile/lib/core/storage/preferences_repository.dart`
- Modify: `mobile/lib/app/app_bootstrap.dart`
- Modify: `mobile/lib/app/bootstrap.dart`
- Modify: `mobile/lib/features/settings/presentation/app_lock_controller.dart`
- Modify: `mobile/lib/features/settings/presentation/app_lock_gate.dart`
- Test: `mobile/test/widgets/app_lock_test.dart`

**Interfaces:**
- Consumes: `AppBootstrap.appLockEnabled`, `AppLockEnabled`.
- Produces:
  - `StorageKeys.lockGraceMinutes` = `'security_lock_grace_minutes'`
  - `PreferencesRepository.getLockGraceMinutes() -> Future<int>`, default `5`
  - `PreferencesRepository.setLockGraceMinutes(int value) -> Future<void>`
  - `AppBootstrap.lockGraceMinutes` (int, default 5)
  - `AppLockController.lastUnlockedAt` (DateTime?), set by `unlock()` on success
  - `AppLockController.isWithinGrace(DateTime now) -> bool`
  - `AppLockEnabled.graceMinutes` state and `setGraceMinutes(int)` on the notifier
  - `@visibleForTesting void debugMarkUnlocked(DateTime at)` on `AppLockController`

- [ ] **Step 1: Write the failing test**

Add to `app_lock_test.dart`. The existing `_container` helper must also stub the new preference read. Drive the controller through a `ProviderContainer` read by the gate, not through a private state class.

```dart
testWidgets('a return inside the grace window does not ask again', (tester) async {
  final auth = await _pump(tester, isLocked: true);
  auth.answer(true);
  await tester.pumpAndSettle();
  expect(auth.calls, 1);

  // The person unlocked, then left and came back inside the window.
  final container = ProviderScope.containerOf(
    tester.element(find.byType(AppLockGate)),
  );
  container.read(appLockControllerProvider.notifier).debugMarkUnlocked(
    DateTime.now(),
  );
  await tester.pumpAppLifecycle(AppLifecycleState.resumed);
  await tester.pumpAndSettle();

  expect(auth.calls, 1, reason: 'the second entry must not prompt');
});
```

`_pump` must return the container as well as the authenticator. Change its return type to a small record `(_FakeAuthenticator auth, ProviderContainer container)`.

- [ ] **Step 2: Run it and watch it fail**

Run: `cd mobile && flutter test test/widgets/app_lock_test.dart`
Expected: FAIL, compile error on the missing members.

- [ ] **Step 3: Add the key and the preference**

Add `lockGraceMinutes` to `StorageKeys`. Add the getter and setter to `PreferencesRepository`. The getter parses the stored int and returns `5` when the value is missing or not a number.

- [ ] **Step 4: Carry the value through bootstrap**

Add `this.lockGraceMinutes = 5` to `AppBootstrap`, and `final int lockGraceMinutes;`. In `bootstrap.dart`, read `await preferences.getLockGraceMinutes()` and pass it.

- [ ] **Step 5: Add the controller state and the grace check**

On `AppLockController` add `DateTime? lastUnlockedAt`. In `unlock()`, set it after a successful authenticate. Add `bool isWithinGrace(DateTime now)` that is true when `lastUnlockedAt` is set, the grace minutes are above 0, and `now.difference(lastUnlockedAt) < Duration(minutes: graceMinutes)`.

Add `@visibleForTesting void debugMarkUnlocked(DateTime at)` that sets `lastUnlockedAt` and is the only setter the test uses.

Add `graceMinutes` to `AppLockEnabled` state, initialised from `AppBootstrap.lockGraceMinutes`, and a `setGraceMinutes(int)` that writes the preference.

- [ ] **Step 6: Use it on the way back**

In `AppLockGate.didChangeAppLifecycleState`, handle `AppLifecycleState.resumed`: when the lock is on and `isWithinGrace(DateTime.now())` is true, clear the covered state without calling the authenticator. The `paused` and `hidden` branches keep calling `lock()`.

- [ ] **Step 7: Run the tests**

Run: `cd mobile && flutter test test/widgets/app_lock_test.dart`
Expected: PASS, including the existing six tests.

- [ ] **Step 8: Commit**

```bash
git add mobile/lib/core/storage/storage_keys.dart mobile/lib/core/storage/preferences_repository.dart mobile/lib/app/app_bootstrap.dart mobile/lib/app/bootstrap.dart mobile/lib/features/settings/presentation/app_lock_controller.dart mobile/lib/features/settings/presentation/app_lock_gate.dart mobile/test/widgets/app_lock_test.dart
git commit -m "feat: let a quick return skip the biometric prompt"
```

---

### Task 3: The grace setting in Security

**Files:**
- Modify: `mobile/lib/l10n/app_en.arb`
- Modify: `mobile/lib/features/settings/presentation/settings_screen.dart`
- Test: `mobile/test/widgets/settings_security_test.dart`

**Interfaces:**
- Consumes: `AppLockEnabled.graceMinutes`, `setGraceMinutes(int)`, `SegmentedControl<int>`, `Segment<int>`.
- Produces: nothing later tasks use.

- [ ] **Step 1: Write the failing tests**

Build the test on the pump pattern in `mobile/test/widgets/settings_motion_test.dart`. It already stubs `PreferencesRepository` and overrides `appBootstrapProvider`. Add `when(() => preferences.getLockGraceMinutes()).thenAnswer((_) async => 5)` to the setup.

```dart
testWidgets('the grace row offers Off, 1, 5 and 15', (tester) async {
  await pump(tester, isLocked: true);
  expect(find.text('Off'), findsOneWidget);
  expect(find.text('1'), findsOneWidget);
  expect(find.text('5'), findsOneWidget);
  expect(find.text('15'), findsOneWidget);
});

testWidgets('picking 1 stores it', (tester) async {
  final container = await pump(tester, isLocked: true);
  await tester.tap(find.text('1'));
  await tester.pumpAndSettle();
  expect(container.read(appLockEnabledProvider.notifier).graceMinutes, 1);
});
```

- [ ] **Step 2: Run them and watch them fail**

Run: `cd mobile && flutter test test/widgets/settings_security_test.dart`
Expected: FAIL, the labels are not found.

- [ ] **Step 3: Add the strings**

Add to `app_en.arb`: `settingsLockGrace` = `Re-lock after`, `settingsLockGraceHelp` = `How long the app stays open after you leave it`, `settingsLockGraceOff` = `Off`, `settingsLockGraceMinutes` = `{minutes} min`. Run `flutter gen-l10n`.

- [ ] **Step 4: Add the row**

In `_SecuritySection`, add a `StackedListTile` after the existing `SwitchRow`: label `settingsLockGrace`, child `SegmentedControl<int>` with segments for `0`, `1`, `5`, `15`. The label for `0` is `settingsLockGraceOff`, the others are `settingsLockGraceMinutes`. Pass `onChanged: isEnabled ? controller.setGraceMinutes : null`.

The row reads `ref.watch(appLockEnabledProvider.notifier).graceMinutes` for its value. `StackedListTile` is already imported in `settings_screen.dart` through `grouped_list.dart`.

- [ ] **Step 5: Run the test**

Run: `cd mobile && flutter test test/widgets/settings_security_test.dart`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add mobile/lib/l10n/app_en.arb mobile/lib/l10n/app_localizations.dart mobile/lib/l10n/app_localizations_en.dart mobile/lib/features/settings/presentation/settings_screen.dart mobile/test/widgets/settings_security_test.dart
git commit -m "feat: add the re-lock grace setting"
```

---

### Task 4: Focus the search field, and return focus on close

**Files:**
- Modify: `mobile/lib/features/notes/presentation/widgets/note_search_bar.dart`
- Modify: `mobile/lib/features/notes/presentation/note_edit_screen.dart`
- Test: `mobile/test/note_edit_screen_test.dart`

**Interfaces:**
- Consumes: `_titleFocus`, `_editorFocus`, `_isSearching` in `note_edit_screen.dart`.
- Produces: `NoteSearchBar` takes focus on mount. `note_edit_screen` remembers `_focusBeforeSearch` (`FocusNode?`).

- [ ] **Step 1: Write the failing tests**

Add to `note_edit_screen_test.dart`. Use the existing `pumpScreen` helper. The screen opens with a saved note so the search icon is on the bar.

```dart
testWidgets('tapping search moves the caret into the field', (tester) async {
  await pumpScreen(tester, note: aSavedNote());
  await tester.tap(find.bySemanticsLabel('Search in this note'));
  await tester.pumpAndSettle();
  final field = tester.widget<TextField>(find.byType(TextField));
  expect(field.focusNode?.hasFocus, isTrue);
});

testWidgets('closing the search returns the caret to the editor', (tester) async {
  await pumpScreen(tester, note: aSavedNote());
  await tester.tap(find.bySemanticsLabel('Search in this note'));
  await tester.pumpAndSettle();
  await tester.tap(find.bySemanticsLabel('Close search'));
  await tester.pumpAndSettle();
  final editor = tester.widget<RichTextEditor>(find.byType(RichTextEditor));
  expect(editor.focusNode.hasFocus, isTrue);
});
```

`aSavedNote()` is a small helper in the test file that returns a `Note` with a title and a body, and stubs `watchNote` to emit it. If `RichTextEditor` does not expose `focusNode`, add a `@visibleForTesting FocusNode get debugFocusNode => _focus;` to it.

- [ ] **Step 2: Run them and watch them fail**

Run: `cd mobile && flutter test test/note_edit_screen_test.dart --plain-name search`
Expected: FAIL, focus stays on the editor.

- [ ] **Step 3: Give the bar its own focus**

In `NoteSearchBar`, convert to a `FocusNode` field, attach it to the `TextField`, and call `requestFocus()` in `didChangeDependencies`. Keep `autofocus: true` as a fallback for the first frame.

- [ ] **Step 4: Record and restore focus in the screen**

Add `FocusNode? _focusBeforeSearch`. In `_openSearch`, store whichever of `_titleFocus` or `_editorFocus` has focus, then unfocus both. In `_closeSearch`, request focus on the stored node, or on `_editorFocus` when the stored node is null.

- [ ] **Step 5: Run the tests**

Run: `cd mobile && flutter test test/note_edit_screen_test.dart`
Expected: PASS, including the existing 20 tests.

- [ ] **Step 6: Commit**

```bash
git add mobile/lib/features/notes/presentation/widgets/note_search_bar.dart mobile/lib/features/notes/presentation/note_edit_screen.dart mobile/lib/features/notes/presentation/editor/rich_text_editor.dart mobile/test/note_edit_screen_test.dart
git commit -m "fix: put the caret in the search field and hand it back on close"
```

---

### Task 5: Next and previous stop shifting the view

**Files:**
- Modify: `mobile/lib/features/notes/presentation/editor/rich_text_editor.dart`
- Test: `mobile/test/rich_text_editor_test.dart`

**Interfaces:**
- Consumes: `render.getLocalRectForCaret`, `widget.scrollController`, `context.findRenderObject()`.
- Produces: `revealRange(TextRange)` unchanged in signature.

- [ ] **Step 1: Write the failing test**

Add to `rich_text_editor_test.dart`. Build a note with several paragraphs so the first match is below the fold.

```dart
testWidgets('next on a visible match leaves the scroll alone', (tester) async {
  await pumpEditor(tester, content: longNote());
  final controller = tester
      .widget<Scrollable>(find.byType(Scrollable))
      .controller!;
  final before = controller.offset;
  for (var i = 0; i < 3; i++) {
    await tester.tap(find.bySemanticsLabel('Next match'));
    await tester.pumpAndSettle();
  }
  expect(controller.offset, before);
});
```

`longNote()` is a helper that returns a note body with three paragraphs, where the searched word sits in the first paragraph that is already on screen.

- [ ] **Step 2: Run it and watch it fail**

Run: `cd mobile && flutter test test/rich_text_editor_test.dart --plain-name next`
Expected: FAIL, the offset keeps moving.

- [ ] **Step 3: Only move when the match is off screen**

In `revealRange`, after computing `rect` and `offset`, read the viewport from the render box: its `size.height` is the visible height. If the rect is fully inside `[0, size.height]`, return. Otherwise scroll by the smallest amount: when the rect is below the viewport, put its top 120 px from the top; when it is above, put its bottom 120 px from the bottom. Clamp to `maxScrollExtent`.

`offset` is already relative to the box because `localToGlobal` uses `ancestor: box`.

- [ ] **Step 4: Run the tests**

Run: `cd mobile && flutter test test/rich_text_editor_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add mobile/lib/features/notes/presentation/editor/rich_text_editor.dart mobile/test/rich_text_editor_test.dart
git commit -m "fix: stop the search arrows from moving a view that is already right"
```

---

### Task 6: The backup folder name

**Files:**
- Modify: `mobile/android/app/src/main/kotlin/com/zhfahim/anchor/backup/BackupFolderPlugin.kt`
- Modify: `mobile/lib/features/backup/data/backup_folder.dart`
- Modify: `mobile/lib/features/backup/domain/backup_settings.dart`
- Modify: `mobile/lib/features/backup/presentation/backup_settings_controller.dart`
- Test: `mobile/test/backup/backup_folder_test.dart`, `mobile/test/backup/backup_settings_controller_test.dart`

**Interfaces:**
- Consumes: `DocumentFile.fromTreeUri(...).name` from Kotlin.
- Produces:
  - `class BackupFolderChoice { const BackupFolderChoice(this.uri, this.name); final String uri; final String? name; }`
  - `BackupFolder.pick() -> Future<BackupFolderChoice?>`
  - `BackupSettings.folderName` (String?), `hasFolder` unchanged
  - `BackupSettingsController.setFolder(String? uri, {String? name})`

- [ ] **Step 1: Write the failing test**

In `backup_folder_test.dart`, change the `pickFolder` mock to return a map, and assert the choice:

```dart
test('pick returns the folder and its name', () async {
  final choice = await BackupFolder().pick();
  expect(choice?.uri, 'content://tree/backups');
  expect(choice?.name, 'Backups');
});
```

Change the existing `'pickFolder' => 'content://tree/backups'` mock line to `'pickFolder' => {'uri': 'content://tree/backups', 'name': 'Backups'}`.

- [ ] **Step 2: Run it and watch it fail**

Run: `cd mobile && flutter test test/backup/backup_folder_test.dart`
Expected: FAIL, the type does not exist.

- [ ] **Step 3: Return a name from Kotlin**

In `pickFolder`, after `takePersistableUriPermission`, read `DocumentFile.fromTreeUri(current, uri)?.name`. Send `mapOf("uri" to uri.toString(), "name" to name)` back through `result.success`.

- [ ] **Step 4: Model the choice in Dart**

Add `BackupFolderChoice` to `backup_folder.dart`. Change `pick()` to decode the map, and treat a missing name as null.

- [ ] **Step 5: Carry the name into the settings**

Add `folderName` to `BackupSettings` and to `copyWith`. Change `BackupSettingsController.setFolder` to `Future<void> setFolder(String? uri, {String? name})` and store the name. Keep the URI write to the repository unchanged. The `folderName` is not persisted, so a cold start shows the last path segment of `folderUri` as a fallback.

In `backup_section.dart:84`, the call site becomes `setFolder(uri, name: choice?.name)` and receives the choice from `BackupFolder.pick()`.

- [ ] **Step 6: Update the existing controller test**

In `backup_settings_controller_test.dart`, no `setFolder` call exists today, so add one: `setFolder('content://tree/backups', name: 'Backups')` then expect `state.value?.folderName` is `'Backups'`.

- [ ] **Step 7: Run the tests**

Run: `cd mobile && flutter test test/backup/`
Expected: PASS

- [ ] **Step 8: Commit**

```bash
git add mobile/android/app/src/main/kotlin/com/zhfahim/anchor/backup/BackupFolderPlugin.kt mobile/lib/features/backup/data/backup_folder.dart mobile/lib/features/backup/domain/backup_settings.dart mobile/lib/features/backup/presentation/backup_settings_controller.dart mobile/test/backup/
git commit -m "feat: show the chosen backup folder by name"
```

---

### Task 7: The backup section matches the other sections

**Files:**
- Modify: `mobile/lib/features/backup/presentation/backup_section.dart`
- Test: `mobile/test/backup/backup_section_test.dart`

**Interfaces:**
- Consumes: `BackupSettings.folderName`, `GroupedListTile`, `Section`, `LucideIcons`.
- Produces: nothing later tasks use.

- [ ] **Step 1: Write the failing tests**

```dart
testWidgets('a chosen folder shows its name', (tester) async {
  await pump(tester, const BackupSettings(
    folderUri: 'content://tree/backups',
    folderName: 'Backups',
  ));
  expect(find.text('Backups'), findsOneWidget);
  expect(find.text('Choose a folder'), findsNothing);
});

testWidgets('a folder with no name falls back to the prompt', (tester) async {
  await pump(tester, const BackupSettings(folderUri: 'content://tree/backups'));
  expect(find.text('Choose a folder'), findsOneWidget);
});
```

- [ ] **Step 2: Run them and watch them fail**

Run: `cd mobile && flutter test test/backup/backup_section_test.dart`
Expected: FAIL, the name is not rendered.

- [ ] **Step 3: Replace `_Row` with `GroupedListTile`**

Delete the private `_Row` class. Build each row with `GroupedListTile`: an icon, a label, and a `value` where one exists. Give `Back up now` and `Restore` `showChevron: true` when they are tappable. The folder row shows `settings.folderName` when set and `backupChooseFolder` when not.

- [ ] **Step 4: Run the tests**

Run: `cd mobile && flutter test test/backup/backup_section_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add mobile/lib/features/backup/presentation/backup_section.dart mobile/test/backup/backup_section_test.dart
git commit -m "feat: lay the backup rows out like the rest of settings"
```

---

## Final Gate

- [ ] **Run the whole suite**

Run: `cd mobile && flutter analyze && flutter test`
Expected: no issues, all tests pass.

- [ ] **Run the token check**

Run: `node design/build/build.mjs --check`
Expected: `Generated files are up to date.`

- [ ] **Commit the gate result**

Only if a gate changed a file. Otherwise the gate is its own proof and needs no commit.