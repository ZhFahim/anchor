# Play Protect scan prompt on the fork APK

Date: 2026-11-15. Repository: `/home/mimin/projects/anchorx`.
Local `main` = `8043f8d`, version `0.23.1+33`.
Read-only research. No code change, no build, no push.

## 1. Question

The app owner reports this: "Every time I install this fork, Android shows a system
prompt that Play Store wants to scan this app because it was not recognised before.
The upstream app never asks for this."

The owner wants the cause, and the way to remove the prompt.

## 2. Verdict

The prompt is the Play Protect "App scan recommended" dialog:
"Play Protect hasn't seen this app before. To protect your device and data, send some
info about the app to Google for scanning before you install."

The cause is the signing certificate, not the code. The fork ships an APK with the same
`applicationId` as upstream (`com.zhfahim.anchor`) but a different self-signed
certificate. Google Play Protect does not hold that certificate in its catalogue, so it
asks to scan the app.

Upstream does not trigger the prompt for the owner because the owner installed upstream
from Google Play. Play distributes the app signed by the Google app signing key, and
Play Protect knows that key. Upstream's own GitHub APK uses a different certificate
(`CN=Zahidul Hoque`, SHA-256 `BD:68:7E:...:2A:51`), so that APK triggers the same prompt.

One more fact made the prompt repeat on every build: until `v0.22.0` the release job made
a new throwaway key on every run. A new certificate per build means a new "unknown app"
per build. The key has been stable since `v0.22.0`.

## 3. Evidence per hypothesis

### H1. Play Protect scans unknown or newly-seen certificates. CONFIRMED

Primary source: <https://developers.google.com/android/play-protect/warning-dev-guidance>,
section "App scan recommended".

Prompt text: "Play Protect hasn't seen this app before. To protect your device and data,
send some info about the app to Google for scanning before you install."

Stated reason: "Google Play Protect conducts security checks at install time to help
protect users by scanning apps for malicious code and sensitive permissions from unknown
applications that are being installed on your device."

Second prompt on the same page, "Send App for Security Check": "This app is unknown to
Play Protect." Stated fix: "Ensure that Google Play Protect is aware of your application
to avoid this dialog appearing for users."

Measurement. The fork APKs and the upstream APK were parsed. The v2 signature block was
read and the signer certificate was hashed with `openssl x509 -fingerprint -sha256`.

| APK | Certificate subject | SHA-256 fingerprint |
| --- | --- | --- |
| fork `anchor-0.20.0` | `CN=Anchor fork` | `8A:0A:BF:9C:...:E0:52` |
| fork `anchor-0.21.0` | `CN=Anchor fork` | `53:EF:AA:AC:...:6D` |
| fork `anchor-0.22.1` | `CN=Anchor Fork` | `37:15:5C:C4:...:3B:99` |
| fork `anchor-0.23.1` | `CN=Anchor Fork` | `37:15:5C:C4:...:3B:99` |
| upstream `anchor-0.18.0` | `CN=Zahidul Hoque` | `BD:68:7E:69:...:2A:51` |

The fork certificate is self-signed and is not in any Google catalogue. Play Protect has
never seen it. The prompt follows from that.

### H2. Same `applicationId`, different certificate. CONFIRMED as a second, separate cause

`mobile/android/app/build.gradle.kts:17` sets `namespace = "com.zhfahim.anchor"`.
`mobile/android/app/build.gradle.kts:30` sets `applicationId = "com.zhfahim.anchor"`.
The decoded `AndroidManifest.xml` in `anchor-0.23.1-arm64-v8a.apk` contains the string
`com.zhfahim.anchor`. The upstream APK contains the same string.

Primary source: <https://developer.android.com/google/play/app-updates>.

- "Android devices can only have one app with a given application ID installed at a time."
- For an accepted update: "The signing certificate of the update must be the same as the
  signing certificate of the installed app, or it must contain a valid proof-of-rotation."
- "To install an app that doesn't meet the conditions above, a user must first uninstall
  the currently installed version, which erases all app data from the device."
- "Android treats apps without a matching application ID and signing key as incompatible."

So the fork cannot update an upstream install, and upstream cannot update a fork install.
Each side must be uninstalled first. This also matches the tamper signal that Play Protect
raises when a catalogued package appears with an unknown certificate.

### H3. The prompt comes from sideloading, not from the code. PARTLY CONFIRMED

Primary source: <https://developers.google.com/android/play-protect/client-protections>,
"Real-time protections for non-Play installs".

"Google Play Protect offers protection for apps that are installed from sources outside of
Google Play. When a user tries to install an app, Play Protect conducts a real-time check
of the app against known harmful or malicious samples that Google Play Protect has
cataloged."

So the install path matters. But the path alone does not explain the difference between
the fork and upstream. The owner installed upstream from Play, where the app is catalogued
and signed by Google. The prompt text names the missing catalogue entry, not the install
path.

The APK files also show the prompt is not code-driven. No code path can trigger it, and no
manifest attribute below turns it on or off.

### H4. Debug signing config leaks into release, or the guard changes the identity between builds. CONFIRMED for the period before `v0.22.0`

`mobile/android/app/build.gradle.kts` has these signing blocks:

- Lines 10-14: load `android/key.properties` when the file exists.
- Lines 43-52: create the `release` signing config only when `key.properties` exists.
  The config reads `keyAlias`, `keyPassword`, `storeFile`, and `storePassword`.
- Lines 55-57: `debug` build type sets `applicationIdSuffix = ".debug"`. The debug build
  type has no `signingConfig`, so it uses the debug keystore. It cannot leak into release.
- Lines 58-62: `release` sets `signingConfig = signingConfigs.getByName("release")` only
  when `key.properties` exists.

`.github/workflows/release.yml`:

- Line 56: `KEYSTORE_BASE64: ${{ secrets.ANDROID_KEYSTORE_BASE64 }}`.
- Lines 58-59: when the secret exists, decode it to `android/app/upload-keystore.jks`.
- Lines 60-66: when the secret is absent, print a warning (line 61), then run
  `keytool -genkeypair` with alias `anchor`, password `anchorfork`, and validity 10000.
  `keytool` makes a new random key pair on every run. The identity therefore changes
  between builds.
- Lines 68-84: write `android/key.properties`. The alias is `anchor` when the secret is
  absent. The alias comes from `secrets.ANDROID_KEY_ALIAS` when the secret is present.

`gh secret list -R muava12/anchor` shows four secrets set at `2026-11-13T14:47`:
`ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`,
`ANDROID_KEY_PASSWORD`. The alias value is write-only and is not visible.

The measured fingerprints confirm the rotation. `v0.20.0` and `v0.21.0` have different
certificates, and both differ from `v0.22.1` and `v0.23.1`. Since `v0.22.0` the
certificate is stable, because the keystore secret exists.

So H4 does not cause the prompt today. It caused a fresh prompt on every build before
`v0.22.0`, and it also caused install failures by signature mismatch.

### H5. The prompt is the normal unknown-source install prompt. RULED OUT as the whole story

The unknown-source prompt is the system dialog that asks to allow installs from this
source. It is a per-source permission and it appears before the download or install step.
The owner's wording — "Play Store wants to scan this app" — matches the Play Protect
"App scan recommended" dialog text on the warning guidance page. The manifest cannot
change that dialog either way.

The manifest carries no `android:debuggable` attribute, so the release APK is not debuggable.
`android:allowBackup="false"` is set. Neither attribute affects Play Protect scanning.

## 4. Repository facts about identity and naming

`rg -n 'applicationId|namespace|android:label|PRODUCT_BUNDLE_IDENTIFIER|CFBundleIdentifier|app_name' mobile/`
returns these identity lines:

- `mobile/android/app/build.gradle.kts:17` — `namespace = "com.zhfahim.anchor"`.
- `mobile/android/app/build.gradle.kts:30` — `applicationId = "com.zhfahim.anchor"`.
- `mobile/android/app/build.gradle.kts:56` — `applicationIdSuffix = ".debug"`.
- `mobile/android/app/src/main/AndroidManifest.xml:18` — `android:label="@string/app_name"`.
- `mobile/android/app/src/main/res/values/strings.xml:3` — `<string name="app_name">Anchor Notes</string>`.
- `mobile/ios/Runner.xcodeproj/project.pbxproj:563` — `PRODUCT_BUNDLE_IDENTIFIER = com.zhfahim.anchor`.
- `mobile/macos/Runner/Configs/AppInfo.xcconfig:11` — `PRODUCT_BUNDLE_IDENTIFIER = com.zhfahim.anchor`.

Correction to the task brief. The brief said `strings.xml` uses the key `n`.
The file uses `app_name` with the value `Anchor Notes`. Only one `strings*.xml` file
exists: `mobile/android/app/src/main/res/values/strings.xml`. It holds seven strings:

| Key | Value |
| --- | --- |
| `app_name` | `Anchor Notes` |
| `widget_label` | `Notes` |
| `widget_description` | `See your notes and start a new one from the home screen.` |
| `widget_app_name` | `Anchor` |
| `widget_new_note` | `New note` |
| `widget_empty` | `No notes yet.\nTap + to write your first one.` |
| `widget_logged_out` | `Sign in to Anchor\nto see your notes here.` |

Android displays `Anchor Notes` as the launcher label. The package name stays
`com.zhfahim.anchor`. The label is not part of the identity, so it cannot cause the prompt.

Upstream distribution. Upstream publishes to Google Play and to GitHub releases.
`README.md` links `https://play.google.com/store/apps/details?id=com.zhfahim.anchor`.
That URL returns HTTP 200, and the listing names the developer "Zahidul Hoque".
There is no F-Droid listing. Upstream issue `#65` "F-Droid Release" is still open.
So upstream does distribute a Play-signed APK, signed by the Google app signing key.

Keystore documentation. The repository does not record the keystore fingerprint or alias
for a release. The only alias value in the repository is the fallback `anchor` in
`.github/workflows/release.yml:63`. The real alias lives in the repository secret
`ANDROID_KEY_ALIAS`, and its value is not readable.

## 5. What removes the prompt

1. **Stable keystore across all releases.** The keystore secret now exists, so the
   certificate is stable. Keep it that way. A rotating key means a new unknown certificate
   on every release, and the prompt returns on every install. Make the release job fail
   when the secret is missing, instead of falling back to a generated key.
2. **Own `applicationId` for the fork.** Change `applicationId` in
   `mobile/android/app/build.gradle.kts:30` to a value the fork owns, for example
   `com.muava.anchor`. Change `namespace` on line 17 to match. This ends the collision with
   the Play install of `com.zhfahim.anchor`, and it ends the "same package, different
   certificate" tamper signal. It also lets the fork and upstream sit side by side.
3. **Register the package with Google.** Play Protect stops the prompt when it knows the
   app. The warning guidance says: "Ensure that Google Play Protect is aware of your
   application to avoid this dialog appearing for users." The routes are a Google Play
   Console listing, or an Android Developer Console account with package name
   registration. See <https://developer.android.com/developer-verification/guides>.
4. **One-time "send for scan".** If the person allows the scan once with "always", the
   device stops asking for that certificate. This works only while the certificate is stable.

## 6. What does not remove the prompt

- Editing `strings.xml`, the app label, or the icon.
- Removing `android:allowBackup` or `android:debuggable`.
- Adding a `signingConfig` guard to `build.gradle.kts`. The guard only stops a build error.
- A debug build with `applicationIdSuffix = ".debug"`. That creates a second package. It
  does not make the release package known to Google.
- Turning off Play Protect. This is not a fix, and this report does not propose it.
- Changing the version name or version code.

## 7. Recommendation

1. Make the release job fail when `ANDROID_KEYSTORE_BASE64` is absent. Never generate a
   throwaway key in a release path. A released certificate must never change.
2. Move the fork to its own `applicationId` (`com.muava.anchor`) in Android, and align
   `namespace`. Consider the same change on iOS and macOS for a matching identity. Keep the
   deep link scheme distinct from upstream's `anchor` scheme.
3. Publish the fork under a Google Play Console or Android Developer Console account with
   its own package name, so Play Protect knows the certificate. Accept one "send for scan"
   per device in the meantime.

Follow-up work outside this task: record the release certificate SHA-256 fingerprint in the
repository, so a future build can be checked against it.