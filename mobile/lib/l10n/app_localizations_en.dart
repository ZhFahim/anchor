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
  String get serverWelcome => 'Welcome to Anchor';

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
  String get serverCustomHeaders => 'Custom headers';

  @override
  String get serverCustomHeadersHint =>
      'Extra headers sent with every request to your server.';

  @override
  String get serverAddHeader => 'Add header';

  @override
  String get serverRemoveHeader => 'Remove header';

  @override
  String get serverHeaderNameHint => 'Name';

  @override
  String get serverHeaderValueHint => 'Value';

  @override
  String serverHeaderCount(int count, int max) {
    return '$count/$max';
  }

  @override
  String serverHeaderLimit(int max) {
    return 'Up to $max headers.';
  }

  @override
  String get serverHeaderInvalidName =>
      'Enter a name with only letters, numbers, and dashes, like X-Anchor-User.';

  @override
  String serverHeaderReserved(String name) {
    return 'The app sets $name itself, so it can’t be changed here.';
  }

  @override
  String get serverHeaderDuplicate =>
      'A header with this name is already added.';

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
  String get settingsTextSize => 'Text size';

  @override
  String get settingsMoveChecked => 'Move checked items to the bottom';

  @override
  String get settingsMoveCheckedHelp =>
      'Checked items move below the unchecked ones.';

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
  String get settingsHelp => 'Help';

  @override
  String get settingsLogs => 'Logs';

  @override
  String get settingsLogsHelp => 'Activity details for troubleshooting';

  @override
  String get settingsSupport => 'Support Anchor';

  @override
  String get settingsSupportHelp => 'Buy the developer a coffee';

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
  String get settingsAppNameShort => 'Anchor';

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
  String get reminderNextWeek => 'Next week';

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
  String get actionShare => 'Share';

  @override
  String get actionHistory => 'Version history';

  @override
  String get actionUncheckAll => 'Uncheck all';

  @override
  String get actionDeleteChecked => 'Delete checked items';

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
  String get listViewOptions => 'View options';

  @override
  String searchTag(String tag) {
    return 'Search #$tag';
  }

  @override
  String searchNoResults(String query) {
    return 'No results for “$query”';
  }

  @override
  String get searchNoResultsHelp =>
      'Check the spelling or try different words.';

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
  String get attachmentAddLabel => 'Add picture or audio';

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
  String get toolRemoveHighlight => 'Remove highlight';

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
  String get addAudioFormats =>
      'Anchor supports MP3, WAV, M4A, OGG and AAC audio';

  @override
  String get addPhotoUnsupported =>
      'Couldn’t add this photo. Try a JPEG or PNG.';

  @override
  String get addMicDenied => 'Allow microphone access in Settings to record';

  @override
  String get addTakePhoto => 'Take photo';

  @override
  String get addChoosePhoto => 'Choose photo';

  @override
  String get addRecordAudio => 'Record audio';

  @override
  String get addAudioFile => 'Audio file';

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
  String get pictureAllowPhotos =>
      'Allow access to Photos in Settings to save pictures';

  @override
  String get pictureSaved => 'Saved to Photos';

  @override
  String get pictureSaveFailed => 'Couldn’t save the picture';

  @override
  String get pictureOffline => 'This picture will show when you’re back online';

  @override
  String get pictureLoadFailed => 'Couldn’t load this picture';

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
}
