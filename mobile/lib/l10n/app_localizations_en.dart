// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Anchor Notes';

  @override
  String get commonBack => 'Back';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonClose => 'Close';

  @override
  String get commonDone => 'Done';

  @override
  String get commonMenu => 'Menu';

  @override
  String get commonCloseMenu => 'Close menu';

  @override
  String get commonShowPassword => 'Show password';

  @override
  String get commonHidePassword => 'Hide password';

  @override
  String get commonSelectedNotes => 'Selected notes';

  @override
  String get commonPlay => 'Play';

  @override
  String get commonPause => 'Pause';

  @override
  String commonPlayItem(String name) {
    return 'Play $name';
  }

  @override
  String commonPauseItem(String name) {
    return 'Pause $name';
  }

  @override
  String commonSwitchOn(String label) {
    return '$label, on';
  }

  @override
  String commonSwitchOff(String label) {
    return '$label, off';
  }

  @override
  String get formOffline =>
      'You’re offline. Connect to the internet to continue.';

  @override
  String get linkInvalid => 'Invalid link';

  @override
  String get linkCantOpen => 'Couldn’t open link';

  @override
  String get densityDefault => 'Default';

  @override
  String get densityCompact => 'Compact';

  @override
  String get noteFontSans => 'Sans';

  @override
  String get noteFontSerif => 'Serif';

  @override
  String get noteFontMono => 'Mono';

  @override
  String get textSizeSmall => 'Small';

  @override
  String get textSizeDefault => 'Default';

  @override
  String get textSizeLarge => 'Large';

  @override
  String get errorOffline => 'No internet connection.';

  @override
  String get errorTimeout => 'The server took too long to respond.';

  @override
  String get errorCertificate => 'The server’s certificate isn’t trusted.';

  @override
  String get errorCancelled => 'The request was canceled.';

  @override
  String get errorSignInAgain => 'Sign in again to continue.';

  @override
  String get errorForbidden => 'You don’t have permission to do that.';

  @override
  String get errorNotFound => 'The item couldn’t be found.';

  @override
  String get errorIncompatible =>
      'This app and your server aren’t compatible. Update them to continue.';

  @override
  String get errorCheckInput => 'Check the information you entered.';

  @override
  String get errorGeneric => 'Something went wrong. Try again.';

  @override
  String get errorServer => 'The server ran into a problem. Try again later.';

  @override
  String get commonSave => 'Save';

  @override
  String get commonSaving => 'Saving…';

  @override
  String get commonUndo => 'Undo';

  @override
  String get fieldName => 'Name';

  @override
  String get fieldNameHint => 'Your name';

  @override
  String get fieldEmail => 'Email';

  @override
  String get fieldEmailHint => 'you@example.com';

  @override
  String get fieldPassword => 'Password';

  @override
  String get fieldCurrentPassword => 'Current password';

  @override
  String get fieldNewPassword => 'New password';

  @override
  String passwordHelp(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'At least $count characters.',
      one: 'At least 1 character.',
    );
    return '$_temp0';
  }

  @override
  String get authEnterName => 'Enter your name.';

  @override
  String get authEnterEmail => 'Enter your email address.';

  @override
  String get authEnterValidEmail => 'Enter a valid email address.';

  @override
  String get authEnterPassword => 'Enter your password.';

  @override
  String get authEnterCurrentPassword => 'Enter your current password.';

  @override
  String authPasswordTooShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Use at least $count characters.',
      one: 'Use at least 1 character.',
    );
    return '$_temp0';
  }

  @override
  String get authIncorrectCredentials => 'Incorrect email or password.';

  @override
  String get authPasswordless =>
      'This account doesn’t use a password. Sign in with your provider instead.';

  @override
  String get authPendingApproval =>
      'Your account is waiting for admin approval.';

  @override
  String authPasswordSignInOff(String provider) {
    return 'Email and password sign-in is turned off. Sign in with $provider.';
  }

  @override
  String authPasswordSignUpOff(String provider) {
    return 'Email and password sign-up is turned off. Sign up with $provider.';
  }

  @override
  String get authPasswordSignInOffHere =>
      'Email and password sign-in is turned off on this server.';

  @override
  String get authPasswordSignUpOffHere =>
      'Email and password sign-up is turned off on this server.';

  @override
  String get authRegistrationClosed =>
      'This server isn’t accepting new accounts.';

  @override
  String get authEmailTaken => 'An account with this email already exists.';

  @override
  String get authWrongCurrentPassword => 'Your current password is incorrect.';

  @override
  String get authSamePassword =>
      'Your new password must be different from your current one.';

  @override
  String get authUnreachable =>
      'Couldn’t reach your server. Check your connection and try again.';

  @override
  String get authProviderNotSetUp =>
      'Signing in with a provider isn’t set up on this server.';

  @override
  String get authProviderFailed =>
      'Couldn’t sign in with your provider. Try again.';

  @override
  String authProviderFailedWith(String detail) {
    return 'Couldn’t sign in with your provider: $detail';
  }

  @override
  String get authSignIn => 'Sign in';

  @override
  String get authSigningIn => 'Signing in…';

  @override
  String authContinueWith(String provider) {
    return 'Continue with $provider';
  }

  @override
  String authOpeningProvider(String provider) {
    return 'Opening $provider…';
  }

  @override
  String get authWelcomeBack => 'Welcome back';

  @override
  String get authSignInToAnchor => 'Sign in to continue to Anchor.';

  @override
  String authSignInTo(String server) {
    return 'Sign in to $server';
  }

  @override
  String get authOfflineSignIn =>
      'You’re offline. Connect to the internet to sign in.';

  @override
  String get authNewToAnchor => 'New to Anchor?';

  @override
  String get authCreateAnAccount => 'Create an account';

  @override
  String get authOr => 'or';

  @override
  String get authCreateAccount => 'Create account';

  @override
  String get authCreatingAccount => 'Creating account…';

  @override
  String get authCreateYourAccount => 'Create your account';

  @override
  String get authApprovalNeeded =>
      'New accounts need admin approval before you can sign in.';

  @override
  String get authRegisterSubtitle => 'Start capturing your thoughts.';

  @override
  String get authAlreadyHaveAccount => 'Already have an account?';

  @override
  String authWelcomeName(String name) {
    return 'Welcome to Anchor, $name';
  }

  @override
  String get authWaitingTitle => 'Waiting for approval';

  @override
  String get authWaitingMessage =>
      'An admin needs to approve your account before you can sign in.';

  @override
  String get authBackToSignIn => 'Back to sign in';

  @override
  String get passwordTitle => 'Password';

  @override
  String get passwordChange => 'Change password';

  @override
  String get passwordChanging => 'Changing…';

  @override
  String get passwordChanged => 'Password changed';

  @override
  String get passwordOffline =>
      'You’re offline. Connect to the internet to change your password.';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileSaved => 'Profile saved';

  @override
  String get profileOffline =>
      'You’re offline. Connect to the internet to change your profile.';

  @override
  String get profilePhoto => 'Profile photo';

  @override
  String get profilePhotoVisible => 'People you share notes with can see it.';

  @override
  String get profileTakePhoto => 'Take photo';

  @override
  String get profileChoosePhoto => 'Choose photo';

  @override
  String get profileRemovePhoto => 'Remove photo';

  @override
  String get profilePhotoUpdated => 'Photo updated';

  @override
  String get profilePhotoUpdateFailed => 'Couldn’t update your photo';

  @override
  String get profilePhotoRemoved => 'Photo removed';

  @override
  String get profilePhotoRemoveFailed => 'Couldn’t remove your photo';

  @override
  String get profileEmailAdminOnly => 'Only an admin can change your email.';

  @override
  String get profileChangePhoto => 'Change profile photo';

  @override
  String get commonContinue => 'Continue';

  @override
  String commonExpandedItem(String label) {
    return '$label, expanded';
  }

  @override
  String commonCollapsedItem(String label) {
    return '$label, collapsed';
  }

  @override
  String get serverTitle => 'Server';

  @override
  String get serverWelcome => 'Welcome to Anchor+';

  @override
  String get serverSubtitle => 'Enter your server address to get started.';

  @override
  String get serverAddress => 'Server address';

  @override
  String get serverAddressHint => 'notes.example.com';

  @override
  String get serverConnecting => 'Connecting…';

  @override
  String get serverAdvanced => 'Advanced';

  @override
  String get serverSelfSigned => 'Allow self-signed certificates';

  @override
  String get serverSelfSignedWarning =>
      'Use only with a server you manage. Anchor can’t verify its identity.';

  @override
  String get serverSelfHosted => 'Anchor requires a self-hosted server.';

  @override
  String get serverEnterAddress => 'Enter a server address.';

  @override
  String get serverEnterValidAddress => 'Enter a valid server address.';

  @override
  String get serverConnectFailed =>
      'Couldn’t connect to the server. Try again.';

  @override
  String serverNotAnchor(String host) {
    return '$host isn’t an Anchor server. Check the address.';
  }

  @override
  String serverUntrusted(String host) {
    return 'Couldn’t verify the certificate for $host. If it’s self-signed, turn on Allow self-signed certificates in Advanced.';
  }

  @override
  String serverUnreachableNoScheme(String host) {
    return 'Couldn’t reach $host. Check the address, or add http:// if your server doesn’t use https.';
  }

  @override
  String serverUnreachable(String host) {
    return 'Couldn’t reach $host. Check the address and your connection.';
  }

  @override
  String get serverConnectAnyway => 'Connect anyway';

  @override
  String serverLinkLabel(String host) {
    return 'Server $host. Change server';
  }

  @override
  String get commonMore => 'More';

  @override
  String get commonCopy => 'Copy';

  @override
  String get commonSelect => 'Select';

  @override
  String get commonSelectAll => 'Select all';

  @override
  String get commonDeselectAll => 'Deselect all';

  @override
  String get commonStopSelecting => 'Stop selecting';

  @override
  String commonSelectedCount(int count) {
    return '$count selected';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String settingsProfileCard(String name, String email) {
    return '$name, $email. Profile';
  }

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsDensity => 'Density';

  @override
  String get settingsDensityHelp => 'Compact fits more notes on the screen.';

  @override
  String get settingsColorScheme => 'Color scheme';

  @override
  String get settingsColorSchemeLofi =>
      'Lo-fi draws in pencil grays, whatever the scheme.';

  @override
  String get colorSchemeAnchor => 'Anchor+';

  @override
  String get settingsCustomTheme => 'Custom theme';

  @override
  String get settingsCustomThemeOff => 'None';

  @override
  String get settingsCustomThemeOn => 'On';

  @override
  String get settingsCustomThemeLofi =>
      'Lo-fi keeps its pencil grays, so the custom theme waits for another style.';

  @override
  String get customThemeHelp =>
      'Paste a theme as JSON: colors for light, dark or both. Anything left out keeps the color scheme\'s color. Kept on this device; the same JSON works on the web.';

  @override
  String get customThemeJsonLabel => 'Theme JSON';

  @override
  String get customThemeApply => 'Apply';

  @override
  String get customThemeReset => 'Reset';

  @override
  String get customThemeCopy => 'Copy current theme as JSON';

  @override
  String get customThemeApplied => 'Custom theme applied';

  @override
  String customThemeAppliedNamed(String name) {
    return 'Custom theme “$name” applied';
  }

  @override
  String get customThemeRemoved => 'Custom theme removed';

  @override
  String get customThemeCopied => 'Current theme copied as JSON';

  @override
  String customThemeNotJson(String detail) {
    return 'Not valid JSON: $detail';
  }

  @override
  String get customThemeNotObject =>
      'The theme must be a JSON object with \"light\" or \"dark\" colors';

  @override
  String customThemeUnknownKey(String key, String expected) {
    return '$key: unknown key; expected one of $expected';
  }

  @override
  String customThemeUnknownKeyGuess(String key, String guess, String expected) {
    return '$key: unknown key (did you mean \"$guess\"?); expected one of $expected';
  }

  @override
  String get customThemeNameNotText => 'name: must be a string';

  @override
  String customThemeModeNotObject(String mode) {
    return '$mode: must be an object of colors';
  }

  @override
  String customThemeNotAColor(String key, String value) {
    return '$key: $value is not a color; use #rgb, #rrggbb or #rrggbbaa';
  }

  @override
  String get customThemeNoMode => 'Give at least one of \"light\" or \"dark\"';

  @override
  String get settingsStyle => 'Style';

  @override
  String get styleDefault => 'Default';

  @override
  String get styleDefaultHelp => 'Anchor as designed';

  @override
  String get styleSkeuomorphism => 'Skeuomorphism';

  @override
  String get styleSkeuomorphismHelp => 'Paper, linen and depth';

  @override
  String get styleNeoBrutalism => 'Neo-Brutalism';

  @override
  String get styleNeoBrutalismHelp => 'Thick outlines, hard shadows';

  @override
  String get styleLofi => 'Lo-fi';

  @override
  String get styleLofiHelp => 'A pencil-and-paper prototype';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeAutomatic => 'Automatic';

  @override
  String get settingsEditor => 'Editor';

  @override
  String get settingsFont => 'Font';

  @override
  String get settingsReminders => 'Reminders';

  @override
  String get settingsMorning => 'Morning';

  @override
  String get settingsAfternoon => 'Afternoon';

  @override
  String get settingsEvening => 'Evening';

  @override
  String get settingsNight => 'Night';

  @override
  String get settingsWeekStart => 'Week starts on';

  @override
  String get settingsTextSize => 'Text size';

  @override
  String get settingsMoveChecked => 'Move checked items to the bottom';

  @override
  String get settingsMoveCheckedHelp =>
      'Checked items move below the unchecked ones.';

  @override
  String get settingsBurnDeleted => 'Burn deleted notes';

  @override
  String get settingsBurnDeletedHelp =>
      'A deleted note burns away where it stood. Off, it just goes.';

  @override
  String get settingsPreviewTitle => 'Weekend in Lisbon';

  @override
  String get settingsPreviewText =>
      'Pack light. The hills are steep, and the trams fill up by nine.';

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsPassword => 'Password';

  @override
  String settingsPasswordManaged(String provider) {
    return 'Your password is managed by $provider.';
  }

  @override
  String get settingsPasswordManagedElsewhere =>
      'Your password is managed by your sign-in provider.';

  @override
  String get settingsSignOut => 'Sign out';

  @override
  String get settingsSigningOut => 'Signing out…';

  @override
  String get settingsSignOutTitle => 'Sign out?';

  @override
  String settingsSignOutMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count changes haven’t synced yet. They stay on this phone and sync when you sign in again.',
      one:
          '1 change hasn’t synced yet. It stays on this phone and syncs when you sign in again.',
      zero: 'Your notes stay on this phone and sync again when you sign in.',
    );
    return '$_temp0';
  }

  @override
  String get settingsUpdates => 'Updates';

  @override
  String get settingsCheckForUpdates => 'Check for updates';

  @override
  String get settingsUpdateChecking => 'Checking…';

  @override
  String settingsUpdateBuild(int build, String repository) {
    return 'This is build $build of $repository';
  }

  @override
  String get settingsCheckAutomatically => 'Check automatically';

  @override
  String get settingsCheckAutomaticallyHelp =>
      'Look for a new release when Anchor starts';

  @override
  String get settingsPreviewReleases => 'Receive preview releases';

  @override
  String get settingsPreviewReleasesHelp =>
      'Release candidates, when your server runs the :fork-preview image';

  @override
  String get settingsSearch => 'Search';

  @override
  String get settingsPictureSearch => 'Find pictures by what they show';

  @override
  String get settingsPictureSearchHelp =>
      'Search for “sunset by the sea” or “receipt” and find notes with such pictures, in most languages. Your server downloads a model once (about 380 MB) and looks at each picture; nothing leaves your server.';

  @override
  String pictureSearchDownloading(int percent) {
    return 'Downloading the picture model… $percent%';
  }

  @override
  String get pictureSearchFailed =>
      'The picture model couldn’t be downloaded. Turn it off and on to try again.';

  @override
  String pictureSearchIndexing(int indexed, int total) {
    return 'Looking at your pictures… $indexed of $total';
  }

  @override
  String pictureSearchReady(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'All $count pictures are ready to search.',
      one: 'Your picture is ready to search.',
      zero: 'Your pictures will be searchable as you add them.',
    );
    return '$_temp0';
  }

  @override
  String get pictureSearchChangeFailed => 'Couldn’t change picture search';

  @override
  String get updateAvailable => 'Update available';

  @override
  String get updateSeeWhatsNew => 'See what’s new';

  @override
  String get updateWhatsNew => 'What’s new';

  @override
  String updateMoreChanges(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'and $count more',
      one: 'and 1 more',
    );
    return '$_temp0';
  }

  @override
  String get updateInstall => 'Download and install';

  @override
  String updateInstallSize(int megabytes) {
    return 'Download and install ($megabytes MB)';
  }

  @override
  String updateDownloading(int percent) {
    return 'Downloading… $percent%';
  }

  @override
  String get updateViewRelease => 'View the release on GitHub';

  @override
  String get updateCheckFailed => 'Couldn’t check for updates';

  @override
  String get updateDownloadFailed => 'The update couldn’t be downloaded';

  @override
  String get updateUpToDate => 'Anchor is up to date';

  @override
  String get settingsHelp => 'Help';

  @override
  String get settingsLogs => 'Logs';

  @override
  String get settingsLogsHelp => 'Activity details for troubleshooting';

  @override
  String get settingsSupport => 'Donate to the original creator';

  @override
  String get settingsSupportHelp =>
      'Buy Anchor’s author a coffee; Anchor+ builds on their work';

  @override
  String get settingsOffline => 'Offline. Changes are saved on this phone.';

  @override
  String settingsSyncPaused(String reason) {
    return 'Sync is paused. $reason';
  }

  @override
  String settingsCantReach(String host) {
    return 'Can’t reach $host';
  }

  @override
  String settingsConnectedTo(String host) {
    return 'Connected to $host';
  }

  @override
  String settingsConnectedToVersion(String host, String version) {
    return 'Connected to $host · Server $version';
  }

  @override
  String settingsAppVersion(String version) {
    return 'Anchor $version';
  }

  @override
  String get settingsAppNameShort => 'Anchor+';

  @override
  String get settingsTagline => 'Your thoughts, secured.';

  @override
  String get logsTitle => 'Logs';

  @override
  String get logsMenuHelp => 'Copy and Save include earlier sessions too.';

  @override
  String get logsCopyAll => 'Copy all';

  @override
  String get logsSaveToFile => 'Save to a file';

  @override
  String get logsClear => 'Clear logs';

  @override
  String get logsCopiedAll => 'Logs copied, including earlier sessions';

  @override
  String get logsCopiedNewest =>
      'Newest logs copied. Save to a file to get them all.';

  @override
  String get logsClearTitle => 'Clear logs?';

  @override
  String get logsClearMessage =>
      'All logs on this phone will be deleted. This can’t be undone.';

  @override
  String get logsCleared => 'Logs cleared';

  @override
  String get logsSaveDialog => 'Save logs';

  @override
  String logsSaved(String name) {
    return 'Saved $name';
  }

  @override
  String get logsSaveFailed => 'Couldn’t save the logs';

  @override
  String logsCopied(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count logs copied',
      one: '1 log copied',
    );
    return '$_temp0';
  }

  @override
  String get logsSelectTitle => 'Select logs';

  @override
  String get logsSearch => 'Search logs';

  @override
  String get logsSelected => 'Selected logs';

  @override
  String get logsLevel => 'Log level';

  @override
  String get logsAll => 'All';

  @override
  String get logsErrors => 'Errors';

  @override
  String get logsWarnings => 'Warnings';

  @override
  String get logsInfo => 'Info';

  @override
  String get logsDebug => 'Debug';

  @override
  String get logsSessionNote =>
      'Showing this session only. Copy and Save include earlier sessions too.';

  @override
  String get logsNoMatches => 'No matching logs';

  @override
  String get logsNoMatchesHelp => 'Try another word or show all levels.';

  @override
  String get logsEmpty => 'No logs yet';

  @override
  String get logsEmptyHelp => 'Activity from this session appears here.';

  @override
  String get logLevelError => 'Error';

  @override
  String get logLevelWarning => 'Warning';

  @override
  String get logLevelInfo => 'Info';

  @override
  String get logLevelDebug => 'Debug';

  @override
  String get commonToday => 'Today';

  @override
  String get commonTomorrow => 'Tomorrow';

  @override
  String get commonNotNow => 'Not now';

  @override
  String get commonLater => 'Later';

  @override
  String get commonOk => 'OK';

  @override
  String get commonOpenSettings => 'Open settings';

  @override
  String get reminderTitle => 'Reminder';

  @override
  String get reminderSheetSubtitle =>
      'You’ll get a notification on this phone.';

  @override
  String reminderDayTime(String day, String time) {
    return '$day, $time';
  }

  @override
  String reminderWithRepeat(String when, String repeat) {
    return '$when · $repeat';
  }

  @override
  String reminderSpoken(String when) {
    return 'Reminder: $when';
  }

  @override
  String reminderSpokenLate(String when) {
    return 'Overdue reminder: $when';
  }

  @override
  String get reminderLaterToday => 'Later today';

  @override
  String get reminderThisAfternoon => 'This afternoon';

  @override
  String get reminderTonight => 'Tonight';

  @override
  String get reminderTomorrowNight => 'Tomorrow night';

  @override
  String get reminderTomorrowMorning => 'Tomorrow morning';

  @override
  String get reminderTomorrowAfternoon => 'Tomorrow afternoon';

  @override
  String get reminderTomorrowEvening => 'Tomorrow evening';

  @override
  String get reminderThisEvening => 'This evening';

  @override
  String get reminderNextWeek => 'Next week';

  @override
  String get reminderWeekend => 'On the weekend';

  @override
  String get reminderNextMonth => 'Next month';

  @override
  String get reminderNone => 'No reminder';

  @override
  String get reminderPickTime => 'Pick a date and time';

  @override
  String get reminderTimePassed => 'This time has already passed';

  @override
  String reminderInMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'In $count minutes',
      one: 'In 1 minute',
    );
    return '$_temp0';
  }

  @override
  String reminderInHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'In $count hours',
      one: 'In 1 hour',
    );
    return '$_temp0';
  }

  @override
  String reminderInDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'In $count days',
      one: 'In 1 day',
    );
    return '$_temp0';
  }

  @override
  String get reminderRepeatsDaily => 'Repeats every day';

  @override
  String reminderRepeatsWeekly(String weekday) {
    return 'Repeats every $weekday';
  }

  @override
  String reminderRepeatsMonthly(int day) {
    return 'Repeats monthly on day $day';
  }

  @override
  String reminderRepeatsMonthlyEnd(int day) {
    return 'Repeats monthly on day $day or the last day';
  }

  @override
  String reminderRepeatsYearly(String date) {
    return 'Repeats every year on $date';
  }

  @override
  String get repeatOnce => 'Once';

  @override
  String get repeatDaily => 'Daily';

  @override
  String get repeatWeekly => 'Weekly';

  @override
  String get repeatMonthly => 'Monthly';

  @override
  String get repeatYearly => 'Yearly';

  @override
  String get reminderWhen => 'When';

  @override
  String get reminderPickDate => 'Pick a date';

  @override
  String get reminderDate => 'Date';

  @override
  String get reminderTime => 'Time';

  @override
  String get reminderRepeat => 'Repeat';

  @override
  String get reminderRemove => 'Remove';

  @override
  String get reminderSetFailed => 'Couldn’t set the reminder';

  @override
  String get reminderNotifyTitle => 'Allow notifications?';

  @override
  String get reminderNotifyMessage =>
      'Anchor needs permission to send notifications so your reminders can ring on this phone.';

  @override
  String get reminderExactTitle => 'Allow exact alarms?';

  @override
  String get reminderExactMessage =>
      'Android may delay reminders to save battery. Allow exact alarms so they ring on time.';

  @override
  String get reminderNotificationsOff =>
      'Notifications are off. Turn them on in your phone’s settings.';

  @override
  String get monthPrevious => 'Previous month';

  @override
  String get monthNext => 'Next month';

  @override
  String get reminderChannelName => 'Reminders';

  @override
  String get reminderChannelDescription => 'Reminders you set on your notes';

  @override
  String get reminderDone => 'Done';

  @override
  String notesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes',
      one: '1 note',
    );
    return '$_temp0';
  }

  @override
  String get tagsTitle => 'Tags';

  @override
  String get tagNotesTitle => 'Tag notes';

  @override
  String get tagSaveFailed => 'Couldn’t save the tag';

  @override
  String get tagUpdateFailed => 'Couldn’t update the tags';

  @override
  String tagNameTaken(String name) {
    return 'A tag named “$name” already exists.';
  }

  @override
  String tagCreateNamed(String name) {
    return 'Create “$name”';
  }

  @override
  String tagAdded(String tag) {
    return '$tag, added';
  }

  @override
  String tagNotAdded(String tag) {
    return '$tag, not added';
  }

  @override
  String tagAddedToSome(String tag) {
    return '$tag, added to some notes';
  }

  @override
  String get tagSearchOrCreate => 'Search or create a tag';

  @override
  String get tagsEmpty => 'No tags yet. Type a name to create one.';

  @override
  String tagSheetLabel(String name) {
    return 'Tag $name';
  }

  @override
  String get tagColor => 'Color';

  @override
  String get tagRename => 'Rename tag';

  @override
  String get tagDelete => 'Delete tag';

  @override
  String tagDeleteTitle(String name) {
    return 'Delete tag “$name”?';
  }

  @override
  String tagDeleteMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'The tag will be removed from $count notes. Your notes won’t be deleted.',
      one: 'The tag will be removed from 1 note. Your notes won’t be deleted.',
    );
    return '$_temp0';
  }

  @override
  String get tagDeleteUnused => 'This tag isn’t on any notes.';

  @override
  String tagDeleted(String name) {
    return 'Tag “$name” deleted';
  }

  @override
  String get tagNew => 'New tag';

  @override
  String tagMove(String name) {
    return 'Move $name';
  }

  @override
  String get tagNamePreview => 'tag name';

  @override
  String get tagNameHint => 'Tag name';

  @override
  String get tagCreate => 'Create tag';

  @override
  String get tagRenameAction => 'Rename';

  @override
  String get colorRed => 'Red';

  @override
  String get colorPink => 'Pink';

  @override
  String get colorPurple => 'Purple';

  @override
  String get colorDeepPurple => 'Deep purple';

  @override
  String get colorIndigo => 'Indigo';

  @override
  String get colorBlue => 'Blue';

  @override
  String get colorLightBlue => 'Light blue';

  @override
  String get colorCyan => 'Cyan';

  @override
  String get colorTeal => 'Teal';

  @override
  String get colorGreen => 'Green';

  @override
  String get colorLightGreen => 'Light green';

  @override
  String get colorLime => 'Lime';

  @override
  String get colorAmber => 'Amber';

  @override
  String get colorOrange => 'Orange';

  @override
  String get colorDeepOrange => 'Deep orange';

  @override
  String get colorBrown => 'Brown';

  @override
  String get colorBlueGrey => 'Blue gray';

  @override
  String get colorYellow => 'Yellow';

  @override
  String get syncSignedOutLead => 'Signed out.';

  @override
  String get syncSignedOutText => 'Sign in again to sync your notes.';

  @override
  String get syncSignInAgainTitle => 'Sign in again';

  @override
  String get syncSignInAgainMessage =>
      'Your notes stay on this phone and sync once you sign in.';

  @override
  String get syncServerOutdatedLead => 'Update your server.';

  @override
  String get syncServerOutdatedText => 'It’s too old to sync with this app.';

  @override
  String get syncServerOutdatedTitle => 'Update your server';

  @override
  String get syncServerOutdatedMessage =>
      'Your Anchor server is too old to sync with this app. Update the server to continue.';

  @override
  String get syncAppOutdatedLead => 'Update Anchor.';

  @override
  String get syncAppOutdatedText =>
      'This app is too old to sync with your server.';

  @override
  String get syncAppOutdatedTitle => 'Update Anchor';

  @override
  String get syncAppOutdatedMessage =>
      'This app is too old to sync with your Anchor server. Update the app to continue.';

  @override
  String syncPausedMessage(String reason) {
    return '$reason Your notes stay on this phone in the meantime.';
  }

  @override
  String get reminderAdd => 'Add a reminder';

  @override
  String get commonYesterday => 'Yesterday';

  @override
  String peopleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people',
      one: '1 person',
    );
    return '$_temp0';
  }

  @override
  String wordsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count words',
      one: '1 word',
    );
    return '$_temp0';
  }

  @override
  String get notesBackToTop => 'Back to top';

  @override
  String get notesSelectTitle => 'Select notes';

  @override
  String get noteUntitled => 'Untitled';

  @override
  String namesTwo(String first, String second) {
    return '$first and $second';
  }

  @override
  String namesMore(String first, String second, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$first, $second and $count more',
    );
    return '$_temp0';
  }

  @override
  String get shareOnlyYou => 'Only you can see this note.';

  @override
  String get shareLoadFailed => 'Couldn’t load the people with access.';

  @override
  String shareSharedWith(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Shared with $count people.',
      one: 'Shared with 1 person.',
    );
    return '$_temp0';
  }

  @override
  String shareSharedWithOffline(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Shared with $count people. Connect to see who has access.',
      one: 'Shared with 1 person. Connect to see who has access.',
    );
    return '$_temp0';
  }

  @override
  String shareSharedWithNames(String names) {
    return 'Shared with $names';
  }

  @override
  String shareSharedWithCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Shared with $count people',
      one: 'Shared with 1 person',
    );
    return '$_temp0';
  }

  @override
  String get shareCanView => 'Can view';

  @override
  String get shareCanEdit => 'Can edit';

  @override
  String get shareLink => 'Link';

  @override
  String get shareLinkAnyone => 'Anyone with the link';

  @override
  String get shareLinkOff => 'Off';

  @override
  String get shareLinkOffHint => 'Only people you add can open it';

  @override
  String get shareLinkViewHint =>
      'Anyone with the link can read it, without an account';

  @override
  String get shareLinkEditHint =>
      'Anyone with the link can change the title and text';

  @override
  String get shareLinkAccess => 'Access with the link';

  @override
  String shareLinkChangeAccess(String access) {
    return '$access. Change access with the link';
  }

  @override
  String get shareLinkCopy => 'Copy link';

  @override
  String get shareLinkShareIt => 'Send link';

  @override
  String get shareLinkCopied => 'Link copied';

  @override
  String get shareLinkMade => 'Link made and copied';

  @override
  String get shareLinkTurnedOff =>
      'Link turned off; it no longer opens the note';

  @override
  String get shareLinkNowCanView => 'Anyone with the link can now view';

  @override
  String get shareLinkNowCanEdit => 'Anyone with the link can now edit';

  @override
  String get shareLinkFailed => 'Couldn’t change the link';

  @override
  String get shareLinkLoadFailed => 'Couldn’t load the note’s link.';

  @override
  String get shareLinkOpens => 'Anyone with the link can open it.';

  @override
  String dayTodayAt(String time) {
    return 'Today at $time';
  }

  @override
  String dayYesterdayAt(String time) {
    return 'Yesterday at $time';
  }

  @override
  String dayOnAt(String date, String time) {
    return '$date at $time';
  }

  @override
  String get editedToday => 'Edited today';

  @override
  String get editedYesterday => 'Edited yesterday';

  @override
  String editedOn(String date) {
    return 'Edited $date';
  }

  @override
  String get editedJustNow => 'Edited just now';

  @override
  String editedMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Edited $count min ago',
      one: 'Edited 1 min ago',
    );
    return '$_temp0';
  }

  @override
  String editedTodayAt(String time) {
    return 'Edited today at $time';
  }

  @override
  String editedYesterdayAt(String time) {
    return 'Edited yesterday at $time';
  }

  @override
  String editedOnAt(String date, String time) {
    return 'Edited $date at $time';
  }

  @override
  String trashRule(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Notes here are deleted after $count days.',
      one: 'Notes here are deleted after 1 day.',
    );
    return '$_temp0';
  }

  @override
  String trashEmpty(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Notes you delete stay here for $count days.',
      one: 'Notes you delete stay here for 1 day.',
    );
    return '$_temp0';
  }

  @override
  String trashDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days left',
      one: '1 day left',
    );
    return '$_temp0';
  }

  @override
  String trashDeletesOn(String date) {
    return 'Will be deleted on $date.';
  }

  @override
  String trashDeletesAfter(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Will be deleted after $count days.',
      one: 'Will be deleted after 1 day.',
    );
    return '$_temp0';
  }

  @override
  String historyKept(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'A version is saved each time the note changes and kept for $count days.',
      one: 'A version is saved each time the note changes and kept for 1 day.',
    );
    return '$_temp0';
  }

  @override
  String historyLimit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Edits older than $count days are removed.',
      one: 'Edits older than 1 day are removed.',
    );
    return '$_temp0';
  }

  @override
  String get historyEarlier => 'Earlier version';

  @override
  String get historyNotSaved => 'Not saved';

  @override
  String get historyBeforeRestore => 'Before a restore';

  @override
  String get historySomeone => 'Someone';

  @override
  String get historyYou => 'You';

  @override
  String get navNotes => 'Notes';

  @override
  String get navArchive => 'Archive';

  @override
  String get navTrash => 'Trash';

  @override
  String drawerAccount(String name) {
    return '$name, Settings';
  }

  @override
  String shareNowCanView(String person) {
    return '$person can now view';
  }

  @override
  String shareNowCanEdit(String person) {
    return '$person can now edit';
  }

  @override
  String get revisionComparedCurrent => 'Compared with the current version';

  @override
  String revisionComparedTodayAt(String time) {
    return 'Compared with today at $time';
  }

  @override
  String revisionComparedYesterdayAt(String time) {
    return 'Compared with yesterday at $time';
  }

  @override
  String revisionComparedOnAt(String date, String time) {
    return 'Compared with $date at $time';
  }

  @override
  String get listArchiveLine => 'Hidden from Notes';

  @override
  String listTrashLine(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Deleted after $count days',
      one: 'Deleted after 1 day',
    );
    return '$_temp0';
  }

  @override
  String get listOfflineSaved => 'Offline · changes are saved on this phone';

  @override
  String listOfflineChanges(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Offline · $count changes to sync',
      one: 'Offline · 1 change to sync',
    );
    return '$_temp0';
  }

  @override
  String get listSyncFailed => 'Couldn’t sync';

  @override
  String listTitleMenu(String title) {
    return '$title, open menu';
  }

  @override
  String get searchNotes => 'Search notes';

  @override
  String get searchArchive => 'Search archive';

  @override
  String get searchTrash => 'Search trash';

  @override
  String get actionTag => 'Tag';

  @override
  String get actionPin => 'Pin';

  @override
  String get actionUnpin => 'Unpin';

  @override
  String get actionColor => 'Color';

  @override
  String get actionSend => 'Send';

  @override
  String get actionMakeCopy => 'Make a copy';

  @override
  String get noteSendEmpty => 'There’s nothing to send yet';

  @override
  String get noteCopyMade => 'This is your copy';

  @override
  String get noteCopyFailed =>
      'Couldn’t make a copy. It needs a connection to the server.';

  @override
  String notesColorChanged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Color changed on $count notes',
      one: 'Color changed on 1 note',
    );
    return '$_temp0';
  }

  @override
  String notesColorChangedExcept(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Color changed. $count notes shared with you to view stay as they were',
      one: 'Color changed. 1 note shared with you to view stays as it was',
    );
    return '$_temp0';
  }

  @override
  String notesColorUnchanged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'These notes are shared with you to view, so their color can’t change',
      one: 'This note is shared with you to view, so its color can’t change',
    );
    return '$_temp0';
  }

  @override
  String get actionShare => 'Share';

  @override
  String get actionHistory => 'Version history';

  @override
  String get actionUncheckAll => 'Uncheck all';

  @override
  String get actionSortByName => 'Sort A to Z';

  @override
  String get actionDeleteChecked => 'Delete checked items';

  @override
  String get actionShowCheckboxes => 'Show checkboxes';

  @override
  String get actionHideCheckboxes => 'Hide checkboxes';

  @override
  String get actionArchive => 'Archive';

  @override
  String get actionUnarchive => 'Unarchive';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionRemove => 'Remove';

  @override
  String get actionRestore => 'Restore';

  @override
  String get actionDeletePermanently => 'Delete permanently';

  @override
  String notesPinned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes pinned',
      one: 'Note pinned',
    );
    return '$_temp0';
  }

  @override
  String notesUnpinned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes unpinned',
      one: 'Note unpinned',
    );
    return '$_temp0';
  }

  @override
  String notesArchived(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes archived',
      one: 'Note archived',
    );
    return '$_temp0';
  }

  @override
  String notesUnarchived(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes unarchived',
      one: 'Note unarchived',
    );
    return '$_temp0';
  }

  @override
  String itemsUnchecked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items unchecked',
      one: 'Item unchecked',
    );
    return '$_temp0';
  }

  @override
  String checkboxesShown(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count checkboxes added',
      one: 'Checkbox added',
    );
    return '$_temp0';
  }

  @override
  String checkboxesHidden(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count checkboxes removed',
      one: 'Checkbox removed',
    );
    return '$_temp0';
  }

  @override
  String itemsSortedByName(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items sorted A to Z',
      one: 'Item sorted A to Z',
    );
    return '$_temp0';
  }

  @override
  String get itemsAlreadySorted => 'Already in A to Z order';

  @override
  String checkedItemsDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count checked items deleted',
      one: 'Checked item deleted',
    );
    return '$_temp0';
  }

  @override
  String notesRestored(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes restored',
      one: 'Note restored',
    );
    return '$_temp0';
  }

  @override
  String get noteRestoredFollow => 'Follow it';

  @override
  String notesDeletedForever(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes permanently deleted',
      one: 'Note permanently deleted',
    );
    return '$_temp0';
  }

  @override
  String notesMovedToTrash(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes moved to trash',
      one: 'Note moved to trash',
    );
    return '$_temp0';
  }

  @override
  String notesRemovedFromYours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes removed from your notes',
      one: 'Note removed from your notes',
    );
    return '$_temp0';
  }

  @override
  String notesTrashedMixed(String moved, String removed) {
    return '$moved $removed';
  }

  @override
  String notesMovedToTrashPart(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes moved to trash.',
      one: '1 note moved to trash.',
    );
    return '$_temp0';
  }

  @override
  String notesRemovedPart(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count removed from your notes.',
      one: '1 removed from your notes.',
    );
    return '$_temp0';
  }

  @override
  String get notesRemoveSharedTitle => 'Remove this note from your notes?';

  @override
  String get notesRemoveSharedMessage =>
      'To see it again, its owner has to share it with you again.';

  @override
  String notesDeleteTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Delete $count notes?',
      one: 'Delete 1 note?',
    );
    return '$_temp0';
  }

  @override
  String notesDeleteSharedMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count notes shared with you will be removed from your notes. To see them again, their owners have to share them with you again.',
      one:
          'A note shared with you will be removed from your notes. To see it again, its owner has to share it with you again.',
    );
    return '$_temp0';
  }

  @override
  String get notesDeleteForeverOneTitle => 'Permanently delete this note?';

  @override
  String notesDeleteFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Couldn’t delete the notes',
      one: 'Couldn’t delete the note',
    );
    return '$_temp0';
  }

  @override
  String notesDeleteForeverTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Permanently delete $count notes?',
      one: 'Permanently delete 1 note?',
    );
    return '$_temp0';
  }

  @override
  String notesDeleteForeverMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'This can’t be undone. People you shared them with will lose access too.',
      one:
          'This can’t be undone. People you shared it with will lose access too.',
    );
    return '$_temp0';
  }

  @override
  String get trashEmptyAction => 'Empty trash';

  @override
  String get trashNothing => 'Nothing to delete';

  @override
  String get trashEmptyTitle => 'Empty trash?';

  @override
  String trashEmptyMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes will be permanently deleted. This can’t be undone.',
      one: '1 note will be permanently deleted. This can’t be undone.',
    );
    return '$_temp0';
  }

  @override
  String get trashEmptied => 'Trash emptied';

  @override
  String get listSelectNotes => 'Select notes';

  @override
  String get listViewOptions => 'View options';

  @override
  String get listPressBackAgainToExit => 'Press back again to exit';

  @override
  String searchTag(String tag) {
    return 'Search #$tag';
  }

  @override
  String get syncOverwroteLead => 'Changed in two places';

  @override
  String syncOverwroteText(String title) {
    return 'Your changes to “$title” replaced ones made elsewhere. Tap to see them in its history.';
  }

  @override
  String syncOverwroteManyText(int count) {
    return 'Your changes to $count notes replaced ones made elsewhere. Tap to see the first one\'s history.';
  }

  @override
  String searchNoResults(String query) {
    return 'No results for “$query”';
  }

  @override
  String get searchNoResultsHelp =>
      'Check the spelling or try different words.';

  @override
  String get searchRegexInvalidHelp =>
      'This isn\'t a valid regular expression, so it was looked for as typed. Check the pattern, or turn off Regular expression.';

  @override
  String get archiveEmptyTitle => 'No archived notes';

  @override
  String get archiveEmptyHelp =>
      'Archive notes you want to keep but don’t need to see every day.';

  @override
  String get trashEmptyStateTitle => 'Trash is empty';

  @override
  String tagEmptyTitle(String tag) {
    return 'No notes tagged #$tag';
  }

  @override
  String get tagEmptyHelp => 'New notes you create here get this tag.';

  @override
  String get notesLoading => 'Loading notes';

  @override
  String get notesEmptyTitle => 'No notes yet';

  @override
  String get notesEmptyHelp => 'Tap New note to write your first one.';

  @override
  String get notesLoadFailedTitle => 'Couldn’t load your notes';

  @override
  String get notesLoadFailedHelp => 'Check your connection, then try again.';

  @override
  String get notesLoadPausedHelp =>
      'Your notes will appear here once they sync.';

  @override
  String get noteNewList => 'New list';

  @override
  String get noteNew => 'New note';

  @override
  String get cardNotSynced => 'Not synced yet';

  @override
  String cardPictures(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pictures',
      one: '1 picture',
    );
    return '$_temp0';
  }

  @override
  String shareSharedBy(String name) {
    return 'Shared by $name';
  }

  @override
  String get actionSharing => 'Sharing';

  @override
  String get actionMoveToTrash => 'Move to trash';

  @override
  String get actionRemoveFromMine => 'Remove from my notes';

  @override
  String get readOnlyInTrash => 'In trash.';

  @override
  String get readOnlyViewOnly => 'View only.';

  @override
  String get readOnlyOwnerEdits => 'Only the owner can edit it.';

  @override
  String readOnlySharedBy(String name) {
    return 'Shared by $name.';
  }

  @override
  String get noteArchived => 'Archived';

  @override
  String get tagAdd => 'Add tag';

  @override
  String tagRemoveNamed(String tag) {
    return 'Remove $tag';
  }

  @override
  String get starterList => 'List';

  @override
  String get starterAttachment => 'Picture or audio';

  @override
  String get attachmentPictureDeleted => 'Picture deleted';

  @override
  String get attachmentVoiceDeleted => 'Voice note deleted';

  @override
  String get attachmentAddLabel => 'Add a picture, recording or file';

  @override
  String get attachmentAdd => 'Add';

  @override
  String get pullOffline =>
      'You’re offline. Your changes are saved on this phone.';

  @override
  String get pullSyncing => 'Syncing…';

  @override
  String get pullUpToDate => 'Up to date';

  @override
  String get pullFailed =>
      'Couldn’t sync. Your changes are saved on this phone.';

  @override
  String get searchClear => 'Clear search';

  @override
  String get searchFilter => 'Filter notes';

  @override
  String searchFiltersOn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Filter notes, $count filters on',
      one: 'Filter notes, 1 filter on',
    );
    return '$_temp0';
  }

  @override
  String get searchNoMatches => 'No notes match';

  @override
  String get searchNoMatchesHelp => 'Turn off a filter to see more notes.';

  @override
  String get filterTitle => 'Filter notes';

  @override
  String get filterHelp => 'Show only notes that match';

  @override
  String filterCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count filters on',
      one: '1 filter on',
    );
    return '$_temp0';
  }

  @override
  String get debugRecordingTitle => 'Debug recording';

  @override
  String get debugStopRecording => 'Stop debug recording';

  @override
  String get debugDiscard => 'Discard';

  @override
  String get debugDiscardTitle => 'Discard recording?';

  @override
  String get debugDiscardMessage =>
      'The recording and the problems you marked will be lost.';

  @override
  String get debugShareFile => 'Share file';

  @override
  String get debugPlay => 'Play';

  @override
  String get debugPause => 'Pause';

  @override
  String debugProblemHere(String time) {
    return 'Problem here ($time)';
  }

  @override
  String debugProblemAt(String time) {
    return 'Problem at $time';
  }

  @override
  String get debugExpectation => 'Expectation';

  @override
  String get debugExpectationHint => 'What should have happened?';

  @override
  String get debugAdd => 'Add';

  @override
  String get debugNoExpectation => '(no expectation)';

  @override
  String get debugProblemsHint =>
      'Move to where it went wrong and tap Problem here.\nThe video greys out text and pictures; the report leaves out what you wrote.';

  @override
  String get debugCreateIssue => 'Create issue';

  @override
  String get debugSaveReport => 'Save debug report';

  @override
  String get debugBuilding => 'Building the report…';

  @override
  String get debugShareFailed => 'Couldn’t share the report';

  @override
  String get debugGithubFailed => 'Couldn’t open GitHub';

  @override
  String get debugBuildFailed => 'Couldn’t build the report';

  @override
  String get actionMerge => 'Merge';

  @override
  String notesMerged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Merged $count notes',
      one: 'Merged 1 note',
    );
    return '$_temp0';
  }

  @override
  String notesMergedKeptPictures(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Merged $count notes; pictures stay with their notes in the trash',
      one: 'Merged 1 note; pictures stay with their notes in the trash',
    );
    return '$_temp0';
  }

  @override
  String get notesMergePickTwo => 'Pick two notes or more to merge';

  @override
  String get notesMergeOwnOnly => 'Only your own notes can be merged';

  @override
  String get notesMergeFrozen =>
      'Unfreeze the frozen notes first, then merge them';

  @override
  String get notesMergeLocked => 'Open the locked notes first, then merge them';

  @override
  String get notesMergeFailed => 'Couldn’t merge the notes';

  @override
  String get filterSecrets => 'Secrets';

  @override
  String get filterSecretsHelp => 'Keys, tokens, ids and passwords';

  @override
  String get filterSearch => 'Search';

  @override
  String get filterRegex => 'Regular expression';

  @override
  String get filterMatchCase => 'Match case';

  @override
  String get searchHintRegex => 'Search with a regex';

  @override
  String get searchHintMatchCase => 'Search, matching case';

  @override
  String get searchHintRegexMatchCase => 'Regex, matching case';

  @override
  String get searchRegexIncomplete =>
      'Not a complete regular expression yet: looking for the text as typed';

  @override
  String get filterHas => 'Has';

  @override
  String get filterPictures => 'Pictures';

  @override
  String get filterChecklists => 'Checklists';

  @override
  String get filterReminders => 'Reminders';

  @override
  String get filterTag => 'Tag';

  @override
  String get filterClear => 'Clear filters';

  @override
  String get lineText => 'Text';

  @override
  String get lineH1 => 'Heading 1';

  @override
  String get lineH2 => 'Heading 2';

  @override
  String get lineH3 => 'Heading 3';

  @override
  String get lineChecklist => 'Checklist';

  @override
  String get lineBullet => 'Bullet list';

  @override
  String get lineNumbered => 'Numbered list';

  @override
  String get lineQuote => 'Quote';

  @override
  String get lineCode => 'Code block';

  @override
  String get editorLink => 'Link';

  @override
  String get slashWordsChecklist => 'todo to-do task checkbox list';

  @override
  String get slashWordsH1 => 'h1 title';

  @override
  String get slashWordsH2 => 'h2 subtitle subheading';

  @override
  String get slashWordsH3 => 'h3 subheading';

  @override
  String get slashWordsBullet => 'unordered ul dashes';

  @override
  String get slashWordsNumbered => 'ordered ol';

  @override
  String get slashWordsQuote => 'blockquote citation';

  @override
  String get slashWordsCode => 'pre snippet';

  @override
  String get slashWordsText => 'paragraph plain normal body';

  @override
  String get slashDate => 'Today’s date';

  @override
  String get slashWordsDate => 'date today now day';

  @override
  String get slashWordsLink => 'url web address';

  @override
  String get slashWordsAttachment =>
      'image img photo file voice recording attachment';

  @override
  String get barFormatting => 'Formatting';

  @override
  String get barList => 'List';

  @override
  String get barSelected => 'Selected text';

  @override
  String get barStyles => 'Text styles';

  @override
  String get barColors => 'Highlight colors';

  @override
  String get barLineStyles => 'Line styles';

  @override
  String get toolOutdent => 'Outdent';

  @override
  String get toolIndent => 'Indent';

  @override
  String get toolBold => 'Bold';

  @override
  String get toolItalic => 'Italic';

  @override
  String get toolUnderline => 'Underline';

  @override
  String get toolStrikethrough => 'Strikethrough';

  @override
  String get toolHighlight => 'Highlight';

  @override
  String get toolTextStyle => 'Color and font';

  @override
  String get textStyleNone => 'None';

  @override
  String get textStyleDefault => 'Default';

  @override
  String get textStyleColor => 'Text color';

  @override
  String get textStyleFont => 'Font';

  @override
  String get textFontComic => 'Comic Sans';

  @override
  String get textFontHandwriting => 'Handwriting';

  @override
  String get textFontTypewriter => 'Typewriter';

  @override
  String get textFontRounded => 'Rounded';

  @override
  String get textFontSlab => 'Slab';

  @override
  String get textFontMarker => 'Marker';

  @override
  String get textStyleCustomHighlight => 'Custom highlight';

  @override
  String get textStyleCustomColor => 'Custom text color';

  @override
  String get colorGray => 'Gray';

  @override
  String get colorPickerHue => 'Hue';

  @override
  String get colorPickerSaturation => 'Saturation';

  @override
  String get colorPickerLightness => 'Lightness';

  @override
  String get colorPickerBadHex => 'Use #rgb or #rrggbb';

  @override
  String get colorPickerApply => 'Apply';

  @override
  String get toolRemoveHighlight => 'Remove highlight';

  @override
  String get toolClearFormatting => 'Clear formatting';

  @override
  String get toolRedo => 'Redo';

  @override
  String get toolHideKeyboard => 'Hide keyboard';

  @override
  String get editorEmptyItem => 'Empty item';

  @override
  String get editorLinkCopied => 'Link copied';

  @override
  String editorCheckedItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count checked items',
      one: '1 checked item',
    );
    return '$_temp0';
  }

  @override
  String get linkAdd => 'Add link';

  @override
  String get linkEdit => 'Edit link';

  @override
  String get linkTextHint => 'Text';

  @override
  String get commonOpen => 'Open';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonRemove => 'Remove';

  @override
  String get editorSlashHint => 'Type / for more';

  @override
  String get editorPastePicture => 'Paste picture';

  @override
  String get editorPlaceholder => 'Start writing';

  @override
  String get commonTryAgain => 'Try again';

  @override
  String get historyCurrent => 'Current version';

  @override
  String get historySavedOnPhone => 'Saved on this phone';

  @override
  String get historyNoChanges => 'No changes';

  @override
  String get historyEmptyTitle => 'No earlier versions yet';

  @override
  String get historyFetchFailed =>
      'Couldn’t check for versions from your other devices.';

  @override
  String get historyOffline =>
      'Connect to the internet to see versions from your other devices.';

  @override
  String diffAdded(int count) {
    return '$count added';
  }

  @override
  String diffRemoved(int count) {
    return '$count removed';
  }

  @override
  String diffChanged(int count) {
    return '$count changed';
  }

  @override
  String diffLinesAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lines added',
      one: '1 line added',
    );
    return '$_temp0';
  }

  @override
  String diffLinesRemoved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lines removed',
      one: '1 line removed',
    );
    return '$_temp0';
  }

  @override
  String diffLinesChanged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lines changed',
      one: '1 line changed',
    );
    return '$_temp0';
  }

  @override
  String diffShowUnchanged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Show $count unchanged lines',
      one: 'Show 1 unchanged line',
    );
    return '$_temp0';
  }

  @override
  String diffUnchanged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unchanged lines',
      one: '1 unchanged line',
    );
    return '$_temp0';
  }

  @override
  String get diffAddedMark => 'Added:';

  @override
  String get diffRemovedMark => 'Removed:';

  @override
  String get diffChangedMark => 'Changed:';

  @override
  String get diffCheckedMark => 'Checked:';

  @override
  String get diffUncheckedMark => 'Not checked:';

  @override
  String get diffRemovedTitle => 'Removed title:';

  @override
  String get diffAddedTitle => 'Added title:';

  @override
  String get revisionNotSavedLead => 'Not saved.';

  @override
  String get revisionNotSavedText =>
      'This edit wasn’t saved because the note changed on another device first. Restore it, or copy what you need.';

  @override
  String get revisionAlreadyMatches => 'The note already matches this version';

  @override
  String get revisionRestoreFailed => 'Couldn’t restore this version';

  @override
  String get revisionRestoring => 'Restoring…';

  @override
  String get revisionBackToList => 'Back to the version list';

  @override
  String get revisionNewer => 'Newer version';

  @override
  String get revisionOlder => 'Older version';

  @override
  String revisionPosition(int index, int count) {
    return '$index of $count';
  }

  @override
  String get revisionGone => 'This version is no longer available.';

  @override
  String get revisionSameAsNext => 'Same text as the version after this one.';

  @override
  String get revisionSameAsCurrent => 'Same text as the current version.';

  @override
  String get revisionEmpty => 'This version is empty.';

  @override
  String shareFailed(String name) {
    return 'Couldn’t share with $name';
  }

  @override
  String shareAccessFor(String name) {
    return 'Access for $name';
  }

  @override
  String shareRevoked(String name) {
    return '$name no longer has access';
  }

  @override
  String shareRevokeFailed(String name) {
    return 'Couldn’t remove access for $name';
  }

  @override
  String shareChangeFailed(String name) {
    return 'Couldn’t change access for $name';
  }

  @override
  String get shareSubtitle =>
      'People you add will see this note in their list.';

  @override
  String get shareOffline => 'Connect to the internet to share this note.';

  @override
  String get shareSearchHint => 'Add people by name or email';

  @override
  String get shareNoMatches =>
      'No one found. Only people with an account on this server can be added.';

  @override
  String get shareRecent => 'Recently shared with';

  @override
  String get sharePeople => 'People';

  @override
  String shareAddPerson(String name) {
    return 'Add $name';
  }

  @override
  String get shareWithAccess => 'People with access';

  @override
  String shareYou(String name) {
    return '$name (you)';
  }

  @override
  String get shareOwner => 'Owner';

  @override
  String shareChangeAccess(String permission, String name) {
    return '$permission. Change access for $name';
  }

  @override
  String get commonOffline => 'Offline';

  @override
  String commonDeleteItem(String name) {
    return 'Delete $name';
  }

  @override
  String commonPosition(int index, int count) {
    return '$index of $count';
  }

  @override
  String get addToNote => 'Add to note';

  @override
  String get addPhotoUnsupported =>
      'Couldn’t add this photo. Try a JPEG or PNG.';

  @override
  String get addMicDenied => 'Allow microphone access in Settings to record';

  @override
  String get addTakePhoto => 'Take photo';

  @override
  String get addChoosePhoto => 'Choose photos';

  @override
  String get addRecordAudio => 'Record audio';

  @override
  String get recordingTitle => 'Recording';

  @override
  String get recordingHelp =>
      'Speak normally. The recording stays on this phone until it uploads.';

  @override
  String get recordingReviewTitle => 'Your recording';

  @override
  String recordingReviewHelp(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seconds. Listen, then keep it or record again.',
      one: '1 second. Listen, then keep it or record again.',
    );
    return '$_temp0';
  }

  @override
  String get recordingStoppedAtLimit =>
      'Stopped at the maximum length. Listen, then keep it or record again.';

  @override
  String recordingElapsed(String time) {
    return 'Recording, $time';
  }

  @override
  String get recordingStop => 'Stop';

  @override
  String get recordingDiscard => 'Discard';

  @override
  String get recordingAgain => 'Again';

  @override
  String get voiceOffline =>
      'This voice note will play when you’re back online';

  @override
  String get voiceNote => 'Voice note';

  @override
  String get voiceLoadFailed => 'Couldn’t load';

  @override
  String get attachmentUploading => 'Uploading…';

  @override
  String get attachmentUploadFailed => 'Couldn’t upload';

  @override
  String voicePosition(String name) {
    return 'Position in $name';
  }

  @override
  String audioSave(String name) {
    return 'Save $name';
  }

  @override
  String get audioSaveDialog => 'Save audio';

  @override
  String audioSaved(String name) {
    return 'Saved $name';
  }

  @override
  String get audioSaveFailed => 'Couldn’t save the audio';

  @override
  String get pictureAllowPhotos =>
      'Allow access to Photos in Settings to save pictures';

  @override
  String get pictureCopy => 'Copy picture';

  @override
  String get pictureCopied => 'Picture copied';

  @override
  String get pictureCopyFailed => 'Couldn’t copy the picture';

  @override
  String get pictureSaved => 'Saved to Photos';

  @override
  String get pictureSaveFailed => 'Couldn’t save the picture';

  @override
  String get pictureOffline => 'This picture will show when you’re back online';

  @override
  String get pictureLoadFailed => 'Couldn’t load this picture';

  @override
  String get pictureShowTags => 'Show detected tags';

  @override
  String get pictureHideTags => 'Hide detected tags';

  @override
  String get pictureFindingTags => 'Finding tags';

  @override
  String get pictureTagsFailed => 'Couldn’t get the tags';

  @override
  String get pictureTagsNotYet =>
      'This picture hasn’t been looked at yet. Try again soon.';

  @override
  String pictureSearchTag(String tag) {
    return 'Search your notes for $tag';
  }

  @override
  String get pictureGrabText => 'Grab image text';

  @override
  String get pictureReadingText => 'Reading the picture’s text';

  @override
  String get pictureTextAdded => 'Text added to the note';

  @override
  String get pictureNoText => 'No text found in this picture';

  @override
  String get pictureTextFailed => 'Couldn’t read this picture';

  @override
  String get pictureSelectText => 'Select text';

  @override
  String pictureWordsSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count words selected',
      one: '1 word selected',
    );
    return '$_temp0';
  }

  @override
  String get pictureSelectHint =>
      'Hold a word and drag to select text, or hold beside it and drag a box';

  @override
  String get pictureInsertText => 'Insert in note';

  @override
  String get pictureTextCopied => 'Text copied';

  @override
  String get pictureSaveToPhotos => 'Save to Photos';

  @override
  String attachmentRetry(String name) {
    return 'Try again, $name';
  }

  @override
  String pictureOpen(String name) {
    return '$name, open';
  }

  @override
  String get groupPinned => 'Pinned';

  @override
  String get groupOthers => 'Others';

  @override
  String get groupArchived => 'Archived';

  @override
  String get groupPictureMatches => 'Pictures that may match';

  @override
  String get noteBackground => 'Background';

  @override
  String get notePattern => 'Pattern';

  @override
  String get noteColorDefault => 'Default';

  @override
  String get patternDots => 'Dots';

  @override
  String get patternGrid => 'Grid';

  @override
  String get patternLines => 'Lines';

  @override
  String get patternWaves => 'Waves';

  @override
  String get patternGroceries => 'Groceries';

  @override
  String get patternMusic => 'Music';

  @override
  String get patternTravel => 'Travel';

  @override
  String get patternCode => 'Code';

  @override
  String get viewLayout => 'Layout';

  @override
  String get viewMasonry => 'Masonry';

  @override
  String get viewGrid => 'Grid';

  @override
  String get viewList => 'List';

  @override
  String get viewSortBy => 'Sort by';

  @override
  String get viewDateEdited => 'Date edited';

  @override
  String get viewTitle => 'Title';

  @override
  String get viewAtoZ => 'A to Z';

  @override
  String get viewZtoA => 'Z to A';

  @override
  String get viewNewestFirst => 'Newest first';

  @override
  String get viewOldestFirst => 'Oldest first';

  @override
  String get noteUnsynced => 'Changes not synced yet';

  @override
  String get noteOnThisPhone => 'On this phone';

  @override
  String get noteGone => 'This note is no longer available';

  @override
  String get reminderRemoved => 'Reminder removed';

  @override
  String get versionRestored => 'Version restored';

  @override
  String get attachmentPictureAdded => 'Picture added';

  @override
  String get attachmentVoiceAdded => 'Voice note added';

  @override
  String get attachmentPictureAddedOffline =>
      'Picture added. It will upload when you’re back online.';

  @override
  String get attachmentVoiceAddedOffline =>
      'Voice note added. It will upload when you’re back online.';

  @override
  String get attachmentPictureAddFailed => 'Couldn’t add the picture';

  @override
  String get attachmentVoiceAddFailed => 'Couldn’t add the voice note';

  @override
  String get attachmentAudioAdded => 'Audio file added';

  @override
  String get attachmentAudioAddedOffline =>
      'Audio file added. It will upload when you’re back online.';

  @override
  String get attachmentAudioAddFailed => 'Couldn’t add the audio file';

  @override
  String get attachmentTooBig => 'Can’t add files over 50 MB.';

  @override
  String get attachmentAudioDeleted => 'Audio file deleted';

  @override
  String get audioFileOffline =>
      'This audio file will play when you’re back online';

  @override
  String get noteTitleHint => 'Title';

  @override
  String get viewOrder => 'Order';

  @override
  String get viewCards => 'Cards';

  @override
  String get viewCardPictures => 'Pictures on cards';

  @override
  String get viewCardPicturesHelp => 'Show a note’s pictures on its card';

  @override
  String get editorDragHint => 'Drag to reorder';

  @override
  String get slashMenuLabel => 'Insert';

  @override
  String get slashNoResults => 'No results';

  @override
  String get noteColor => 'Color';

  @override
  String cardChecked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count done',
      one: '1 done',
    );
    return '$_temp0';
  }

  @override
  String cardAllChecked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'All $count done',
      one: 'All 1 done',
    );
    return '$_temp0';
  }

  @override
  String get shareSheetTitle => 'New note';

  @override
  String shareTag(String name) {
    return 'Tag $name';
  }

  @override
  String get shareSignIn => 'Sign in to Anchor to save what you share.';

  @override
  String get shareOpenApp => 'Open Anchor';

  @override
  String get shareNothing => 'There’s nothing here that Anchor can save.';

  @override
  String shareNotAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files couldn’t be added.',
      one: '1 file couldn’t be added.',
    );
    return '$_temp0';
  }

  @override
  String shareUnsupported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files can’t be added. Anchor adds pictures and audio.',
      one: '1 file can’t be added. Anchor adds pictures and audio.',
    );
    return '$_temp0';
  }

  @override
  String shareTooBig(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files are over 50 MB, so they can’t be added.',
      one: '1 file is over 50 MB, so it can’t be added.',
    );
    return '$_temp0';
  }

  @override
  String get shareOverLimit => 'Only the first 20 files are added.';

  @override
  String shareRemoveItem(String name) {
    return 'Remove $name';
  }

  @override
  String get actionLock => 'Lock';

  @override
  String get actionChangeLock => 'Change lock';

  @override
  String get actionRemoveLock => 'Remove lock';

  @override
  String get lockSheetTitle => 'Lock';

  @override
  String get lockSheetChangeTitle => 'Change lock';

  @override
  String get lockSheetSubtitle => 'What opens the note';

  @override
  String get lockKindBiometric => 'Fingerprint or face';

  @override
  String get lockKindBiometricHelp => 'Or your phone’s own screen lock';

  @override
  String get lockKindPin => 'PIN';

  @override
  String get lockKindPinHelp => 'One PIN for all your locked notes';

  @override
  String get lockKindPattern => 'Pattern';

  @override
  String get lockKindPatternHelp => 'One pattern for all your locked notes';

  @override
  String get lockKindTap => 'Just a tap';

  @override
  String get lockKindTapHelp => 'Hides the note until you tap';

  @override
  String noteLockedWith(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'biometric': 'Locked with your fingerprint or face',
      'pin': 'Locked with your PIN',
      'pattern': 'Locked with your pattern',
      'other': 'Locked with a tap',
    });
    return '$_temp0';
  }

  @override
  String noteLockChanged(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'biometric': 'Now locked with your fingerprint or face',
      'pin': 'Now locked with your PIN',
      'pattern': 'Now locked with your pattern',
      'other': 'Now locked with a tap',
    });
    return '$_temp0';
  }

  @override
  String get noteLockRemoved => 'Lock removed';

  @override
  String notesLocked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes locked',
      one: 'Note locked',
    );
    return '$_temp0';
  }

  @override
  String notesLockedSome(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Locked $count notes. Locked notes you haven’t opened keep their lock.',
      one: 'Locked 1 note. Locked notes you haven’t opened keep their lock.',
    );
    return '$_temp0';
  }

  @override
  String notesLockOpenFirst(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Open these notes to change their locks',
      one: 'Open this note to change its lock',
    );
    return '$_temp0';
  }

  @override
  String lockNeedsServer(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'pin': 'Setting a PIN needs a connection to the server',
      'other': 'Setting a pattern needs a connection to the server',
    });
    return '$_temp0';
  }

  @override
  String lockChangeNeedsServer(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'pin': 'Changing the PIN needs a connection to the server',
      'other': 'Changing the pattern needs a connection to the server',
    });
    return '$_temp0';
  }

  @override
  String get lockUntitled => 'Locked note';

  @override
  String get lockTapToUnlock => 'Tap to unlock';

  @override
  String get lockUnlock => 'Unlock';

  @override
  String get lockEnterPin => 'Enter your PIN';

  @override
  String get lockDrawPattern => 'Draw your pattern';

  @override
  String get lockUseBiometric => 'Use your fingerprint, face or screen lock';

  @override
  String lockBiometricReason(String title) {
    return 'Unlock “$title”';
  }

  @override
  String get lockTooManyTries =>
      'Too many tries. Unlock your phone, then try again.';

  @override
  String get lockCantCheck =>
      'Can’t check it on this phone yet. Connect to the internet and try again.';

  @override
  String lockWrong(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'pin': 'Wrong PIN',
      'other': 'Wrong pattern',
    });
    return '$_temp0';
  }

  @override
  String get lockPatternGrid => 'Pattern grid. Drag across at least 4 dots.';

  @override
  String get lockPinErase => 'Delete digit';

  @override
  String lockPinDigits(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count digits',
      one: '1 digit',
      zero: 'No digits',
    );
    return '$_temp0';
  }

  @override
  String lockSetupTitle(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'pin': 'PIN',
      'other': 'Pattern',
    });
    return '$_temp0';
  }

  @override
  String lockSetupChoose(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'pin': 'Choose a PIN',
      'other': 'Draw a pattern',
    });
    return '$_temp0';
  }

  @override
  String lockSetupChooseNew(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'pin': 'Choose a new PIN',
      'other': 'Draw a new pattern',
    });
    return '$_temp0';
  }

  @override
  String lockSetupConfirm(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'pin': 'Enter the PIN again',
      'other': 'Draw the pattern again',
    });
    return '$_temp0';
  }

  @override
  String get lockSetupCurrentHelp => 'The one you use now';

  @override
  String lockSetupChooseHelp(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'pin': '4 to 12 digits. It opens every note you lock with a PIN.',
      'other':
          'Join at least 4 dots. It opens every note you lock with a pattern.',
    });
    return '$_temp0';
  }

  @override
  String get lockSetupConfirmHelp => 'To be sure';

  @override
  String lockSetupNotYours(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'pin': 'That’s not your PIN',
      'other': 'That’s not your pattern',
    });
    return '$_temp0';
  }

  @override
  String lockSetupBadShape(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'pin': 'Use 4 to 12 digits',
      'other': 'Join at least 4 dots, each once',
    });
    return '$_temp0';
  }

  @override
  String lockSetupMismatch(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'pin': 'The PINs didn’t match. Try again.',
      'other': 'The patterns didn’t match. Try again.',
    });
    return '$_temp0';
  }

  @override
  String get lockSetupForgot => 'Forgot? Use your password';

  @override
  String get lockSetupPasswordTitle => 'Your account password';

  @override
  String lockErrorWrongProof(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'pin': 'Wrong PIN or password',
      'other': 'Wrong pattern or password',
    });
    return '$_temp0';
  }

  @override
  String lockErrorInvalid(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'pin': 'A PIN is 4 to 12 digits',
      'other': 'A pattern joins at least 4 dots',
    });
    return '$_temp0';
  }

  @override
  String get lockErrorUnsupported =>
      'Your server doesn’t support note locks yet';

  @override
  String lockErrorOffline(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'pin': 'Couldn’t save the PIN. It needs a connection to the server.',
      'other':
          'Couldn’t save the pattern. It needs a connection to the server.',
    });
    return '$_temp0';
  }

  @override
  String lockSaved(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'pin': 'PIN saved',
      'other': 'Pattern saved',
    });
    return '$_temp0';
  }

  @override
  String get settingsNoteLocks => 'Note locks';

  @override
  String settingsLockSet(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'pin': 'Set PIN',
      'other': 'Set pattern',
    });
    return '$_temp0';
  }

  @override
  String settingsLockChange(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'pin': 'Change PIN',
      'other': 'Change pattern',
    });
    return '$_temp0';
  }

  @override
  String settingsLockHelp(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'pin': 'Opens the notes you lock with a PIN',
      'other': 'Opens the notes you lock with a pattern',
    });
    return '$_temp0';
  }

  @override
  String get cardLocked => 'Locked';

  @override
  String get cardUnlocked => 'Locked, open until the screen turns off';

  @override
  String get settingsBackup => 'Backup';

  @override
  String get backupExport => 'Export backup';

  @override
  String get backupExportHelp =>
      'Save every note, tag, picture and recording to a file';

  @override
  String get backupExporting => 'Making the backup…';

  @override
  String get backupSaveTitle => 'Save the backup';

  @override
  String backupSaved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Saved $count notes to the backup',
      one: 'Saved 1 note to the backup',
    );
    return '$_temp0';
  }

  @override
  String backupMissingFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count attachments weren’t on this phone and couldn’t be fetched.',
      one: '1 attachment wasn’t on this phone and couldn’t be fetched.',
    );
    return '$_temp0';
  }

  @override
  String get backupExportFailed => 'Couldn’t make the backup';

  @override
  String get backupRestore => 'Restore backup';

  @override
  String get backupRestoreHelp =>
      'Bring back the notes from a backup file. Notes already here stay as they are';

  @override
  String get backupRestoring => 'Restoring…';

  @override
  String get backupPickTitle => 'Pick an Anchor backup';

  @override
  String get backupOpenFailed => 'Couldn’t open the file';

  @override
  String backupRestored(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Restored $count notes',
      one: 'Restored 1 note',
    );
    return '$_temp0';
  }

  @override
  String backupAlreadyHere(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count were already here.',
      one: '1 was already here.',
    );
    return '$_temp0';
  }

  @override
  String get backupNothingToRestore =>
      'Nothing to restore: every note is already here';

  @override
  String get backupRestoreFailed => 'Couldn’t restore the backup';

  @override
  String get backupNotABackup => 'This file isn’t an Anchor backup';

  @override
  String get backupDamaged => 'This backup is damaged';

  @override
  String get backupTooNew =>
      'This backup is from a newer Anchor. Update the app to restore it.';

  @override
  String get attachmentFileAdded => 'File added';

  @override
  String get attachmentFileAddedOffline =>
      'File added. It will upload when you’re back online.';

  @override
  String get attachmentFileAddFailed => 'Couldn’t add the file';

  @override
  String get attachmentFileDeleted => 'File deleted';

  @override
  String attachmentsAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count attachments added',
      one: '1 attachment added',
    );
    return '$_temp0';
  }

  @override
  String attachmentsAddedOffline(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count attachments added. They will upload when you’re back online.',
      one: '1 attachment added. It will upload when you’re back online.',
    );
    return '$_temp0';
  }

  @override
  String get toolPictureInText => 'Picture in the text';

  @override
  String get pictureInTextCamera => 'Take a picture';

  @override
  String get pictureInTextChoose => 'Choose pictures';

  @override
  String get pictureCrop => 'Crop';

  @override
  String get pictureCropReset => 'Reset';

  @override
  String get cameraFlashOff => 'Flash off';

  @override
  String get cameraFlashOn => 'Flash on';

  @override
  String get cameraNone => 'No camera found';

  @override
  String get cameraNoPermission =>
      'Anchor needs the camera permission to take pictures';

  @override
  String get cameraFailed => 'Couldn’t start the camera';

  @override
  String get cameraSwitch => 'Switch camera';

  @override
  String get cameraShutter => 'Take a picture';

  @override
  String cameraTaken(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pictures taken',
      one: '1 picture taken',
    );
    return '$_temp0';
  }

  @override
  String cameraPicturesAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pictures added',
      one: '1 picture added',
    );
    return '$_temp0';
  }

  @override
  String get inlinePicture => 'Picture';

  @override
  String get inlinePictureRetake => 'Retake';

  @override
  String get inlinePictureMirrorHorizontally => 'Mirror horizontally';

  @override
  String get inlinePictureMirrorVertically => 'Mirror vertically';

  @override
  String get inlinePictureAddCaption => 'Add caption';

  @override
  String get inlinePictureEditCaption => 'Edit caption';

  @override
  String get inlinePictureCaptionHint => 'Caption';

  @override
  String get inlinePictureChangeFailed => 'Couldn’t change the picture';

  @override
  String get inlinePictureResize => 'Resize picture';

  @override
  String get fileOffline => 'This file will open when you’re back online';

  @override
  String get fileLoadFailed => 'Couldn’t load the file';

  @override
  String get fileNoApp => 'No app on this phone opens it. Save it instead.';

  @override
  String get fileSaveDialog => 'Save file';

  @override
  String fileSaved(String name) {
    return 'Saved $name';
  }

  @override
  String get fileSaveFailed => 'Couldn’t save the file';

  @override
  String fileOpen(String name) {
    return 'Open $name';
  }

  @override
  String fileSave(String name) {
    return 'Save $name';
  }

  @override
  String get addTakeSeveral => 'Take several';

  @override
  String get addFiles => 'Files';

  @override
  String get addFolder => 'Folder';

  @override
  String get addFolderFailed => 'Couldn’t read that folder';

  @override
  String get addFolderEmpty => 'That folder is empty';

  @override
  String get actionAddImage => 'Add image';

  @override
  String get actionTakePicture => 'Take picture';

  @override
  String get actionTakeSeveral => 'Take several';

  @override
  String get actionFreeze => 'Freeze';

  @override
  String get actionUnfreeze => 'Unfreeze';

  @override
  String get noteFreezeHelp =>
      'Nobody can change or delete it until you unfreeze it';

  @override
  String get noteFreezeFailed =>
      'Couldn’t freeze. It needs a connection to the server.';

  @override
  String get noteUnfreezeFailed =>
      'Couldn’t unfreeze. It needs a connection to the server.';

  @override
  String notesFrozen(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes frozen',
      one: 'Note frozen',
    );
    return '$_temp0';
  }

  @override
  String notesUnfrozen(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes unfrozen',
      one: 'Note unfrozen',
    );
    return '$_temp0';
  }

  @override
  String notesFrozenStay(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Frozen notes can’t be deleted. Unfreeze them first.',
      one: 'A frozen note can’t be deleted. Unfreeze it first.',
    );
    return '$_temp0';
  }

  @override
  String get notesLockOrFreeze => 'Lock or freeze';

  @override
  String get readOnlyFrozenByOwner =>
      'Its owner froze it, so it can’t be changed.';

  @override
  String get cardFrozen => 'Frozen';

  @override
  String get noteNewCamera => 'Camera note';

  @override
  String get actionMakeInvisible => 'Make invisible';

  @override
  String get actionMakeVisible => 'Make visible';

  @override
  String get noteInvisibleHelp => 'Only a search finds it';

  @override
  String notesMadeInvisible(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes made invisible. Search finds them.',
      one: 'Note made invisible. Search finds it.',
    );
    return '$_temp0';
  }

  @override
  String notesMadeVisible(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes made visible',
      one: 'Note made visible',
    );
    return '$_temp0';
  }

  @override
  String get notesLockFreezeOrHide => 'Lock, freeze or make invisible';

  @override
  String get notesLockOrHide => 'Lock or make invisible';

  @override
  String get cardInvisible => 'Invisible';

  @override
  String get filterIs => 'Is';

  @override
  String get filterInvisible => 'Invisible';

  @override
  String get actionReminder => 'Reminder';

  @override
  String get actionCheckboxes => 'Checkboxes';

  @override
  String get actionModifyQuickActions => 'Modify quick actions';

  @override
  String get settingsQuickActions => 'Quick actions';

  @override
  String get settingsQuickActionsHelp =>
      'In a note\'s top bar, in this order. Up to 5 fit. Drag to reorder.';

  @override
  String get settingsQuickActionsEmpty => 'None. Everything is in More.';

  @override
  String get settingsMoreActions => 'In More';

  @override
  String get settingsMoreActionsHelp =>
      'Turn one off to offer it nowhere. Tap + to put it in the top bar.';

  @override
  String get settingsQuickActionsReset => 'Reset quick actions';

  @override
  String settingsAddToBar(String action) {
    return 'Put $action in the top bar';
  }

  @override
  String settingsRemoveFromBar(String action) {
    return 'Take $action out of the top bar';
  }

  @override
  String get settingsCopySetup => 'Copy setup';

  @override
  String get settingsPasteSetup => 'Paste setup';

  @override
  String get settingsSetupCopied => 'Quick actions copied';

  @override
  String get settingsSetupPasted => 'Quick actions pasted';

  @override
  String get settingsSetupPasteFailed =>
      'The clipboard holds no copied quick actions';

  @override
  String get authMagicCodeUsed =>
      'This QR code or magic link has run out. Make a new one in Settings on the web.';

  @override
  String get magicLoginScan => 'Scan QR code';

  @override
  String get magicLoginScanTitle => 'Scan the magic login QR code';

  @override
  String get magicLoginScanHint =>
      'On the web, open Settings and tap Show QR code under Sign in on your phone. Then point the camera at it.';

  @override
  String get magicLoginNotOurs =>
      'That QR code isn’t a magic login. Use the one from Settings on the web.';

  @override
  String get magicLoginNoPermission =>
      'Anchor needs the camera permission to scan the QR code';

  @override
  String get magicLoginSigningIn => 'Signing in…';

  @override
  String get magicLoginAlreadySignedIn =>
      'You’re already signed in. Sign out first to use a magic link.';
}
