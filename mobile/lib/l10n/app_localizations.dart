import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// The app's name in Android's recent apps, the same as its launcher name.
  ///
  /// In en, this message translates to:
  /// **'Anchor Notes'**
  String get appName;

  /// Screen reader label of the back arrow in the top bar and the editor toolbar.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// Button that closes a dialog, sheet, search or selection without making changes.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// Spoken label of the picture viewer’s close button and of the area outside a dialog, and the button that closes the share sheet when nothing in a share can be saved.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// Small button at the top of a sheet that closes it.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// Screen reader name of a pop-up menu and of the side menu with the lists and tags.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get commonMenu;

  /// Screen reader label for the area outside an open menu, which closes it.
  ///
  /// In en, this message translates to:
  /// **'Close menu'**
  String get commonCloseMenu;

  /// Screen reader label of the eye button that shows a hidden password.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get commonShowPassword;

  /// Screen reader label of the eye button that hides a shown password.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get commonHidePassword;

  /// Screen reader name of the bar shown while notes are selected.
  ///
  /// In en, this message translates to:
  /// **'Selected notes'**
  String get commonSelectedNotes;

  /// Screen reader label of a play button for an audio file without a name.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get commonPlay;

  /// Screen reader label of a pause button for an audio file without a name.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get commonPause;

  /// Screen reader label of a play button for an audio or video file.
  ///
  /// In en, this message translates to:
  /// **'Play {name}'**
  String commonPlayItem(String name);

  /// Screen reader label of a pause button for an audio or video file.
  ///
  /// In en, this message translates to:
  /// **'Pause {name}'**
  String commonPauseItem(String name);

  /// Screen reader text for a settings switch that is on.
  ///
  /// In en, this message translates to:
  /// **'{label}, on'**
  String commonSwitchOn(String label);

  /// Screen reader text for a settings switch that is off.
  ///
  /// In en, this message translates to:
  /// **'{label}, off'**
  String commonSwitchOff(String label);

  /// Notice at the top of a form that needs the server.
  ///
  /// In en, this message translates to:
  /// **'You’re offline. Connect to the internet to continue.'**
  String get formOffline;

  /// Message when a tapped link isn’t a valid web address.
  ///
  /// In en, this message translates to:
  /// **'Invalid link'**
  String get linkInvalid;

  /// Message when no app on the phone can open a tapped link.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t open link'**
  String get linkCantOpen;

  /// Display density with regular spacing.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get densityDefault;

  /// Display density with tighter spacing that fits more notes.
  ///
  /// In en, this message translates to:
  /// **'Compact'**
  String get densityCompact;

  /// Note font choice: a sans-serif font.
  ///
  /// In en, this message translates to:
  /// **'Sans'**
  String get noteFontSans;

  /// Note font choice: a serif font.
  ///
  /// In en, this message translates to:
  /// **'Serif'**
  String get noteFontSerif;

  /// Note font choice: a monospaced font.
  ///
  /// In en, this message translates to:
  /// **'Mono'**
  String get noteFontMono;

  /// Note text size.
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get textSizeSmall;

  /// Note text size.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get textSizeDefault;

  /// Note text size.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get textSizeLarge;

  /// Error when a request fails because the phone has no internet.
  ///
  /// In en, this message translates to:
  /// **'No internet connection.'**
  String get errorOffline;

  /// Error when the server doesn’t answer in time.
  ///
  /// In en, this message translates to:
  /// **'The server took too long to respond.'**
  String get errorTimeout;

  /// Error when the server’s security certificate can’t be verified.
  ///
  /// In en, this message translates to:
  /// **'The server’s certificate isn’t trusted.'**
  String get errorCertificate;

  /// Error when a request to the server stopped before it finished.
  ///
  /// In en, this message translates to:
  /// **'The request was canceled.'**
  String get errorCancelled;

  /// Error when the person’s sign-in has expired and the server refuses the request.
  ///
  /// In en, this message translates to:
  /// **'Sign in again to continue.'**
  String get errorSignInAgain;

  /// Error when the server refuses an action this account isn’t allowed to do.
  ///
  /// In en, this message translates to:
  /// **'You don’t have permission to do that.'**
  String get errorForbidden;

  /// Error when the server can’t find what the app asked for.
  ///
  /// In en, this message translates to:
  /// **'The item couldn’t be found.'**
  String get errorNotFound;

  /// Error when the app and server versions can’t work together.
  ///
  /// In en, this message translates to:
  /// **'This app and your server aren’t compatible. Update them to continue.'**
  String get errorIncompatible;

  /// Error at the top of a form when the server rejects what was entered.
  ///
  /// In en, this message translates to:
  /// **'Check the information you entered.'**
  String get errorCheckInput;

  /// Error for any unexpected failure.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Try again.'**
  String get errorGeneric;

  /// Error when the server fails while handling a request.
  ///
  /// In en, this message translates to:
  /// **'The server ran into a problem. Try again later.'**
  String get errorServer;

  /// Button that saves a form or the choice made in a sheet.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// Text on the Save button while the profile is being saved.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get commonSaving;

  /// Button that reverses the last change, in toasts and in the editor toolbar.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get commonUndo;

  /// Label of the person’s name field when signing up or editing the profile.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get fieldName;

  /// Hint inside the empty name field when creating an account.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get fieldNameHint;

  /// Label of the email address field.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get fieldEmail;

  /// An example email address shown in an empty email field.
  ///
  /// In en, this message translates to:
  /// **'you@example.com'**
  String get fieldEmailHint;

  /// Label of the password field on the sign-in and sign-up pages.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get fieldPassword;

  /// Label of the field for the old password on the change password page.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get fieldCurrentPassword;

  /// Label of the field for the new password on the change password page.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get fieldNewPassword;

  /// Shown under a new password field.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{At least 1 character.} other{At least {count} characters.}}'**
  String passwordHelp(int count);

  /// Error under the name field when it’s left empty.
  ///
  /// In en, this message translates to:
  /// **'Enter your name.'**
  String get authEnterName;

  /// Error under the email field when it’s left empty.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address.'**
  String get authEnterEmail;

  /// Error under the email field when the address isn’t valid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get authEnterValidEmail;

  /// Error under the password field on the sign-in page when it’s left empty.
  ///
  /// In en, this message translates to:
  /// **'Enter your password.'**
  String get authEnterPassword;

  /// Error under the current password field when the server says it’s missing.
  ///
  /// In en, this message translates to:
  /// **'Enter your current password.'**
  String get authEnterCurrentPassword;

  /// Error under a new password that is too short.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Use at least 1 character.} other{Use at least {count} characters.}}'**
  String authPasswordTooShort(int count);

  /// Error at the top of the sign-in form when the email or password is wrong.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password.'**
  String get authIncorrectCredentials;

  /// The account was created through a sign-in provider such as an identity service.
  ///
  /// In en, this message translates to:
  /// **'This account doesn’t use a password. Sign in with your provider instead.'**
  String get authPasswordless;

  /// Error at the top of the sign-in form when an admin hasn’t approved the account yet.
  ///
  /// In en, this message translates to:
  /// **'Your account is waiting for admin approval.'**
  String get authPendingApproval;

  /// Error on the sign-in page when the server only allows signing in through a sign-in provider.
  ///
  /// In en, this message translates to:
  /// **'Email and password sign-in is turned off. Sign in with {provider}.'**
  String authPasswordSignInOff(String provider);

  /// Error on the sign-up page when the server only allows new accounts through a sign-in provider.
  ///
  /// In en, this message translates to:
  /// **'Email and password sign-up is turned off. Sign up with {provider}.'**
  String authPasswordSignUpOff(String provider);

  /// Error on the sign-in page when the server allows no email and password sign-in.
  ///
  /// In en, this message translates to:
  /// **'Email and password sign-in is turned off on this server.'**
  String get authPasswordSignInOffHere;

  /// Error on the sign-up page when the server allows no email and password sign-up.
  ///
  /// In en, this message translates to:
  /// **'Email and password sign-up is turned off on this server.'**
  String get authPasswordSignUpOffHere;

  /// Error at the top of the sign-up form when the server takes no new accounts.
  ///
  /// In en, this message translates to:
  /// **'This server isn’t accepting new accounts.'**
  String get authRegistrationClosed;

  /// Error under the email field when signing up with an email already in use.
  ///
  /// In en, this message translates to:
  /// **'An account with this email already exists.'**
  String get authEmailTaken;

  /// Error under the current password field when it’s wrong.
  ///
  /// In en, this message translates to:
  /// **'Your current password is incorrect.'**
  String get authWrongCurrentPassword;

  /// Error under the new password field when it matches the old one.
  ///
  /// In en, this message translates to:
  /// **'Your new password must be different from your current one.'**
  String get authSamePassword;

  /// Error at the top of an account form when the server can’t be reached.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t reach your server. Check your connection and try again.'**
  String get authUnreachable;

  /// Error on the sign-in page when the server has no sign-in provider set up.
  ///
  /// In en, this message translates to:
  /// **'Signing in with a provider isn’t set up on this server.'**
  String get authProviderNotSetUp;

  /// Error on the sign-in page when signing in through a sign-in provider fails.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t sign in with your provider. Try again.'**
  String get authProviderFailed;

  /// {detail} is the provider’s own error text, often in English.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t sign in with your provider: {detail}'**
  String authProviderFailedWith(String detail);

  /// Button that signs in, a link to the sign-in page, and that page’s spoken name.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSignIn;

  /// Text on the Sign in button while signing in.
  ///
  /// In en, this message translates to:
  /// **'Signing in…'**
  String get authSigningIn;

  /// Button that signs in through a sign-in provider.
  ///
  /// In en, this message translates to:
  /// **'Continue with {provider}'**
  String authContinueWith(String provider);

  /// Text on the sign-in provider button while the provider’s page opens.
  ///
  /// In en, this message translates to:
  /// **'Opening {provider}…'**
  String authOpeningProvider(String provider);

  /// Title of the sign-in page.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get authWelcomeBack;

  /// Under the sign-in page title when no server address is shown.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue to Anchor.'**
  String get authSignInToAnchor;

  /// Under the sign-in title. {server} is the server’s address, shown as a link that opens the server page.
  ///
  /// In en, this message translates to:
  /// **'Sign in to {server}'**
  String authSignInTo(String server);

  /// Notice at the top of the sign-in form while the phone is offline.
  ///
  /// In en, this message translates to:
  /// **'You’re offline. Connect to the internet to sign in.'**
  String get authOfflineSignIn;

  /// Followed by the link “Create an account”.
  ///
  /// In en, this message translates to:
  /// **'New to Anchor?'**
  String get authNewToAnchor;

  /// Link after “New to Anchor?” on the sign-in page that opens the sign-up page.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get authCreateAnAccount;

  /// Between the sign-in provider button and the email and password fields.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get authOr;

  /// Button that submits the sign-up form; also the sign-up page’s spoken name.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authCreateAccount;

  /// Text on the Create account button while the account is being created.
  ///
  /// In en, this message translates to:
  /// **'Creating account…'**
  String get authCreatingAccount;

  /// Title of the sign-up page.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get authCreateYourAccount;

  /// Under the sign-up page title when an admin must approve new accounts.
  ///
  /// In en, this message translates to:
  /// **'New accounts need admin approval before you can sign in.'**
  String get authApprovalNeeded;

  /// Under the sign-up page title, a short welcoming line.
  ///
  /// In en, this message translates to:
  /// **'Start capturing your thoughts.'**
  String get authRegisterSubtitle;

  /// Followed by the link “Sign in”.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get authAlreadyHaveAccount;

  /// Message after creating an account. {name} is the person’s first name.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Anchor, {name}'**
  String authWelcomeName(String name);

  /// Title of the page shown after signing up, until an admin approves the account.
  ///
  /// In en, this message translates to:
  /// **'Waiting for approval'**
  String get authWaitingTitle;

  /// Under the title of the page that waits for an admin to approve the account.
  ///
  /// In en, this message translates to:
  /// **'An admin needs to approve your account before you can sign in.'**
  String get authWaitingMessage;

  /// Button on the waiting for approval page that returns to the sign-in page.
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get authBackToSignIn;

  /// Title of the change password page.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordTitle;

  /// Button that saves the new password on the change password page.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get passwordChange;

  /// Text on the Change password button while the new password is saved.
  ///
  /// In en, this message translates to:
  /// **'Changing…'**
  String get passwordChanging;

  /// Toast after the password was changed.
  ///
  /// In en, this message translates to:
  /// **'Password changed'**
  String get passwordChanged;

  /// Notice at the top of the change password page while the phone is offline.
  ///
  /// In en, this message translates to:
  /// **'You’re offline. Connect to the internet to change your password.'**
  String get passwordOffline;

  /// Title of the page where the person edits their name and photo.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// Toast after the profile changes were saved.
  ///
  /// In en, this message translates to:
  /// **'Profile saved'**
  String get profileSaved;

  /// Notice at the top of the profile page while the phone is offline.
  ///
  /// In en, this message translates to:
  /// **'You’re offline. Connect to the internet to change your profile.'**
  String get profileOffline;

  /// Title of the sheet with options for the person’s profile picture.
  ///
  /// In en, this message translates to:
  /// **'Profile photo'**
  String get profilePhoto;

  /// Under the profile photo sheet title: who sees the person’s picture.
  ///
  /// In en, this message translates to:
  /// **'People you share notes with can see it.'**
  String get profilePhotoVisible;

  /// Option that opens the camera to take a new profile picture.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get profileTakePhoto;

  /// Option that picks a profile picture from the phone’s photos.
  ///
  /// In en, this message translates to:
  /// **'Choose photo'**
  String get profileChoosePhoto;

  /// Option that removes the current profile picture.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get profileRemovePhoto;

  /// Toast after a new profile picture was saved.
  ///
  /// In en, this message translates to:
  /// **'Photo updated'**
  String get profilePhotoUpdated;

  /// Toast when a new profile picture couldn’t be saved.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t update your photo'**
  String get profilePhotoUpdateFailed;

  /// Toast after the profile picture was removed, with an Undo button.
  ///
  /// In en, this message translates to:
  /// **'Photo removed'**
  String get profilePhotoRemoved;

  /// Toast when the profile picture couldn’t be removed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t remove your photo'**
  String get profilePhotoRemoveFailed;

  /// Help under the read-only email field on the profile page.
  ///
  /// In en, this message translates to:
  /// **'Only an admin can change your email.'**
  String get profileEmailAdminOnly;

  /// Screen reader label of the profile picture button.
  ///
  /// In en, this message translates to:
  /// **'Change profile photo'**
  String get profileChangePhoto;

  /// Button that goes to the next step on the server page or in a permission dialog.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get commonContinue;

  /// Screen reader text for a section heading that is open.
  ///
  /// In en, this message translates to:
  /// **'{label}, expanded'**
  String commonExpandedItem(String label);

  /// Screen reader text for a section heading that is closed.
  ///
  /// In en, this message translates to:
  /// **'{label}, collapsed'**
  String commonCollapsedItem(String label);

  /// Name of the server page, read by screen readers.
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get serverTitle;

  /// Title of the first page, where the person enters their server address.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Anchor'**
  String get serverWelcome;

  /// Under the title of the first page, where the server address is entered.
  ///
  /// In en, this message translates to:
  /// **'Enter your server address to get started.'**
  String get serverSubtitle;

  /// Label of the field for the web address of the person’s Anchor server.
  ///
  /// In en, this message translates to:
  /// **'Server address'**
  String get serverAddress;

  /// An example server address shown in the empty field.
  ///
  /// In en, this message translates to:
  /// **'notes.example.com'**
  String get serverAddressHint;

  /// Text on the Continue button while the app checks the server.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get serverConnecting;

  /// Heading of a section of extra connection settings that opens and closes.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get serverAdvanced;

  /// Switch that lets the app trust a server certificate it can’t verify.
  ///
  /// In en, this message translates to:
  /// **'Allow self-signed certificates'**
  String get serverSelfSigned;

  /// Warning under the self-signed certificates switch while it’s on.
  ///
  /// In en, this message translates to:
  /// **'Use only with a server you manage. Anchor can’t verify its identity.'**
  String get serverSelfSignedWarning;

  /// Heading of the list of extra headers sent to the server, under the self-signed certificates switch.
  ///
  /// In en, this message translates to:
  /// **'Custom headers'**
  String get serverCustomHeaders;

  /// Under the custom headers heading.
  ///
  /// In en, this message translates to:
  /// **'Extra headers sent with every request to your server.'**
  String get serverCustomHeadersHint;

  /// Button that adds another empty name and value pair to the custom headers.
  ///
  /// In en, this message translates to:
  /// **'Add header'**
  String get serverAddHeader;

  /// Screen reader label of the button that removes a custom header row.
  ///
  /// In en, this message translates to:
  /// **'Remove header'**
  String get serverRemoveHeader;

  /// Placeholder in the field for a custom header’s name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get serverHeaderNameHint;

  /// Placeholder in the field for a custom header’s value.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get serverHeaderValueHint;

  /// How many custom headers are added, of the most that fit.
  ///
  /// In en, this message translates to:
  /// **'{count}/{max}'**
  String serverHeaderCount(int count, int max);

  /// Note when the most custom headers are added and no more fit.
  ///
  /// In en, this message translates to:
  /// **'Up to {max} headers.'**
  String serverHeaderLimit(int max);

  /// Error under a custom header row whose name isn’t valid.
  ///
  /// In en, this message translates to:
  /// **'Enter a name with only letters, numbers, and dashes, like X-Anchor-User.'**
  String get serverHeaderInvalidName;

  /// Error under a custom header row whose name the app manages.
  ///
  /// In en, this message translates to:
  /// **'The app sets {name} itself, so it can’t be changed here.'**
  String serverHeaderReserved(String name);

  /// Error under a custom header row whose name repeats an earlier one.
  ///
  /// In en, this message translates to:
  /// **'A header with this name is already added.'**
  String get serverHeaderDuplicate;

  /// Note at the bottom of the server page: Anchor has no shared public server.
  ///
  /// In en, this message translates to:
  /// **'Anchor requires a self-hosted server.'**
  String get serverSelfHosted;

  /// Error under the server address field when it’s left empty.
  ///
  /// In en, this message translates to:
  /// **'Enter a server address.'**
  String get serverEnterAddress;

  /// Error under the server address field when the address isn’t valid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid server address.'**
  String get serverEnterValidAddress;

  /// Error at the top of the server page when connecting fails for an unknown reason.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t connect to the server. Try again.'**
  String get serverConnectFailed;

  /// Error when the address answers but isn’t an Anchor server.
  ///
  /// In en, this message translates to:
  /// **'{host} isn’t an Anchor server. Check the address.'**
  String serverNotAnchor(String host);

  /// “Allow self-signed certificates” and “Advanced” are names of controls on the same page.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t verify the certificate for {host}. If it’s self-signed, turn on Allow self-signed certificates in Advanced.'**
  String serverUntrusted(String host);

  /// Shown when the address was typed without http:// or https://. Keep http:// and https:// as they are.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t reach {host}. Check the address, or add http:// if your server doesn’t use https.'**
  String serverUnreachableNoScheme(String host);

  /// Error when nothing answers at the server address.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t reach {host}. Check the address and your connection.'**
  String serverUnreachable(String host);

  /// Button in a dialog warning that the app and server versions don’t match.
  ///
  /// In en, this message translates to:
  /// **'Connect anyway'**
  String get serverConnectAnyway;

  /// Screen reader label of the server address link on the sign-in page.
  ///
  /// In en, this message translates to:
  /// **'Server {host}. Change server'**
  String serverLinkLabel(String host);

  /// Screen reader label of the three dots button that opens more actions.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get commonMore;

  /// Button that copies a link or the selected logs. Short: fits a small bubble.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get commonCopy;

  /// Menu item on the logs page that starts selecting logs.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get commonSelect;

  /// Button that selects every item shown while selecting.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get commonSelectAll;

  /// Button that clears the selection when every item is selected.
  ///
  /// In en, this message translates to:
  /// **'Deselect all'**
  String get commonDeselectAll;

  /// Screen reader label of the button that leaves selection mode.
  ///
  /// In en, this message translates to:
  /// **'Stop selecting'**
  String get commonStopSelecting;

  /// Page title while selecting items.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String commonSelectedCount(int count);

  /// Title of the Settings page, also the name of the button that opens it.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Screen reader label of the card that opens the profile.
  ///
  /// In en, this message translates to:
  /// **'{name}, {email}. Profile'**
  String settingsProfileCard(String name, String email);

  /// Section label in Settings for theme and density.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// Setting for how tightly the app spaces notes and other items.
  ///
  /// In en, this message translates to:
  /// **'Density'**
  String get settingsDensity;

  /// Under the Density setting; Compact is the name of one of its options.
  ///
  /// In en, this message translates to:
  /// **'Compact fits more notes on the screen.'**
  String get settingsDensityHelp;

  /// Screen reader name of the group of light, dark and automatic theme choices.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// Theme choice with a light background. Short: one of three tiles in a row.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// Theme choice with a dark background. Short: one of three tiles in a row.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// Theme that follows the phone’s light or dark setting.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get themeAutomatic;

  /// Section label in Settings for how notes look and behave while writing.
  ///
  /// In en, this message translates to:
  /// **'Editor'**
  String get settingsEditor;

  /// Setting that picks the typeface used in notes.
  ///
  /// In en, this message translates to:
  /// **'Font'**
  String get settingsFont;

  /// Setting that picks how big the text in notes is.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get settingsTextSize;

  /// Switch in Settings for checklists in notes.
  ///
  /// In en, this message translates to:
  /// **'Move checked items to the bottom'**
  String get settingsMoveChecked;

  /// Under the switch that moves checked checklist items to the bottom.
  ///
  /// In en, this message translates to:
  /// **'Checked items move below the unchecked ones.'**
  String get settingsMoveCheckedHelp;

  /// Title of a sample note that previews the font and text size.
  ///
  /// In en, this message translates to:
  /// **'Weekend in Lisbon'**
  String get settingsPreviewTitle;

  /// Text of a sample note that previews the font and text size.
  ///
  /// In en, this message translates to:
  /// **'Pack light. The hills are steep, and the trams fill up by nine.'**
  String get settingsPreviewText;

  /// Section label in Settings for password and sign out.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccount;

  /// Row in Settings that opens the change password page, or shows who manages it.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get settingsPassword;

  /// Under the Password row when the account signs in through a sign-in provider.
  ///
  /// In en, this message translates to:
  /// **'Your password is managed by {provider}.'**
  String settingsPasswordManaged(String provider);

  /// Under the Password row when the account uses a sign-in provider with no known name.
  ///
  /// In en, this message translates to:
  /// **'Your password is managed by your sign-in provider.'**
  String get settingsPasswordManagedElsewhere;

  /// Row in Settings and the confirm button of its dialog: signs out of the account.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get settingsSignOut;

  /// The Sign out button of the sign-out dialog while signing out runs.
  ///
  /// In en, this message translates to:
  /// **'Signing out…'**
  String get settingsSigningOut;

  /// Title of the dialog that confirms signing out.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get settingsSignOutTitle;

  /// {count} is the number of changes not yet sent to the server.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Your notes stay on this phone and sync again when you sign in.} =1{1 change hasn’t synced yet. It stays on this phone and syncs when you sign in again.} other{{count} changes haven’t synced yet. They stay on this phone and sync when you sign in again.}}'**
  String settingsSignOutMessage(int count);

  /// Section label in Settings for logs and supporting the developer.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get settingsHelp;

  /// Row in Settings that opens the app’s technical activity records.
  ///
  /// In en, this message translates to:
  /// **'Logs'**
  String get settingsLogs;

  /// Under the Logs row in Settings.
  ///
  /// In en, this message translates to:
  /// **'Activity details for troubleshooting'**
  String get settingsLogsHelp;

  /// Row in Settings that opens a web page to donate to the developer.
  ///
  /// In en, this message translates to:
  /// **'Support Anchor'**
  String get settingsSupport;

  /// Under the Support Anchor row: a small donation to the developer.
  ///
  /// In en, this message translates to:
  /// **'Buy the developer a coffee'**
  String get settingsSupportHelp;

  /// Small line at the bottom of Settings while the phone is offline.
  ///
  /// In en, this message translates to:
  /// **'Offline. Changes are saved on this phone.'**
  String get settingsOffline;

  /// {reason} is a short instruction, such as “Update your server.”
  ///
  /// In en, this message translates to:
  /// **'Sync is paused. {reason}'**
  String settingsSyncPaused(String reason);

  /// Small line at the bottom of Settings when the server doesn’t answer.
  ///
  /// In en, this message translates to:
  /// **'Can’t reach {host}'**
  String settingsCantReach(String host);

  /// Small line at the bottom of Settings showing the server in use.
  ///
  /// In en, this message translates to:
  /// **'Connected to {host}'**
  String settingsConnectedTo(String host);

  /// Small line at the bottom of Settings showing the server and its version.
  ///
  /// In en, this message translates to:
  /// **'Connected to {host} · Server {version}'**
  String settingsConnectedToVersion(String host, String version);

  /// The app’s name and version at the bottom of Settings.
  ///
  /// In en, this message translates to:
  /// **'Anchor {version}'**
  String settingsAppVersion(String version);

  /// The app’s short name, at the top of the menu and the bottom of Settings.
  ///
  /// In en, this message translates to:
  /// **'Anchor'**
  String get settingsAppNameShort;

  /// The app’s tagline under its version.
  ///
  /// In en, this message translates to:
  /// **'Your thoughts, secured.'**
  String get settingsTagline;

  /// Title of the logs page and of its menu of actions.
  ///
  /// In en, this message translates to:
  /// **'Logs'**
  String get logsTitle;

  /// Under the title of the logs menu; Copy and Save are names of its options.
  ///
  /// In en, this message translates to:
  /// **'Copy and Save include earlier sessions too.'**
  String get logsMenuHelp;

  /// Menu item that copies every log, including earlier sessions.
  ///
  /// In en, this message translates to:
  /// **'Copy all'**
  String get logsCopyAll;

  /// Menu item that saves every log to a file on the phone.
  ///
  /// In en, this message translates to:
  /// **'Save to a file'**
  String get logsSaveToFile;

  /// Menu item and dialog button that delete all logs.
  ///
  /// In en, this message translates to:
  /// **'Clear logs'**
  String get logsClear;

  /// Toast after all logs were copied.
  ///
  /// In en, this message translates to:
  /// **'Logs copied, including earlier sessions'**
  String get logsCopiedAll;

  /// Toast after Copy all copied only the newest logs, because all of them are too long for the clipboard. "Save to a file" is the menu item next to Copy all.
  ///
  /// In en, this message translates to:
  /// **'Newest logs copied. Save to a file to get them all.'**
  String get logsCopiedNewest;

  /// Title of the dialog that confirms deleting all logs.
  ///
  /// In en, this message translates to:
  /// **'Clear logs?'**
  String get logsClearTitle;

  /// Message of the dialog that confirms deleting all logs.
  ///
  /// In en, this message translates to:
  /// **'All logs on this phone will be deleted. This can’t be undone.'**
  String get logsClearMessage;

  /// Toast after all logs were deleted.
  ///
  /// In en, this message translates to:
  /// **'Logs cleared'**
  String get logsCleared;

  /// Title of the system dialog for saving the logs file.
  ///
  /// In en, this message translates to:
  /// **'Save logs'**
  String get logsSaveDialog;

  /// Toast after the logs were saved to a file.
  ///
  /// In en, this message translates to:
  /// **'Saved {name}'**
  String logsSaved(String name);

  /// Toast when the logs file couldn’t be saved.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t save the logs'**
  String get logsSaveFailed;

  /// Toast after the selected logs were copied.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 log copied} other{{count} logs copied}}'**
  String logsCopied(int count);

  /// Page title while selecting logs and none is selected yet.
  ///
  /// In en, this message translates to:
  /// **'Select logs'**
  String get logsSelectTitle;

  /// Hint inside the empty search field on the logs page.
  ///
  /// In en, this message translates to:
  /// **'Search logs'**
  String get logsSearch;

  /// Screen reader name of the bar shown while logs are selected.
  ///
  /// In en, this message translates to:
  /// **'Selected logs'**
  String get logsSelected;

  /// Screen reader name of the filter for log levels.
  ///
  /// In en, this message translates to:
  /// **'Log level'**
  String get logsLevel;

  /// Filter that shows logs of every level. Short: one of five tabs in a row.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get logsAll;

  /// Filter that shows only error logs. Short: one of five tabs in a row.
  ///
  /// In en, this message translates to:
  /// **'Errors'**
  String get logsErrors;

  /// Filter that shows only warning logs. Short: one of five tabs in a row.
  ///
  /// In en, this message translates to:
  /// **'Warnings'**
  String get logsWarnings;

  /// Filter that shows only general information logs. Short: one of five tabs in a row.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get logsInfo;

  /// Filter that shows only detailed technical logs. Short: one of five tabs in a row.
  ///
  /// In en, this message translates to:
  /// **'Debug'**
  String get logsDebug;

  /// Note under the log filters; Copy and Save are names of menu options.
  ///
  /// In en, this message translates to:
  /// **'Showing this session only. Copy and Save include earlier sessions too.'**
  String get logsSessionNote;

  /// Empty-screen title on the logs page when the search or filter matches nothing.
  ///
  /// In en, this message translates to:
  /// **'No matching logs'**
  String get logsNoMatches;

  /// Empty-screen help on the logs page when the search or filter matches nothing.
  ///
  /// In en, this message translates to:
  /// **'Try another word or show all levels.'**
  String get logsNoMatchesHelp;

  /// Empty-screen title on the logs page when nothing has been recorded.
  ///
  /// In en, this message translates to:
  /// **'No logs yet'**
  String get logsEmpty;

  /// Empty-screen help on the logs page when nothing has been recorded.
  ///
  /// In en, this message translates to:
  /// **'Activity from this session appears here.'**
  String get logsEmptyHelp;

  /// Level tag on a single log line that records an error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get logLevelError;

  /// Level tag on a single log line that records a warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get logLevelWarning;

  /// Level tag on a single log line with general information.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get logLevelInfo;

  /// Level tag on a single log line with detailed technical information.
  ///
  /// In en, this message translates to:
  /// **'Debug'**
  String get logLevelDebug;

  /// The current day, as a date heading, on a note card or in a reminder time.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get commonToday;

  /// The next day, in a reminder time or as a quick reminder choice.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get commonTomorrow;

  /// Button that closes a permission dialog without asking for the permission.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get commonNotNow;

  /// Button that closes the sign in again dialog without signing in.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get commonLater;

  /// Button that closes a warning dialog.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// Opens the phone’s settings for the app.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get commonOpenSettings;

  /// Title of the reminder sheet, and of a reminder notification when the note has no title.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get reminderTitle;

  /// Under the title of the sheet that sets a reminder.
  ///
  /// In en, this message translates to:
  /// **'You’ll get a notification on this phone.'**
  String get reminderSheetSubtitle;

  /// A reminder’s day and time, such as “Today, 6:05 PM” or “Fri, Aug 21, 9:00 AM”.
  ///
  /// In en, this message translates to:
  /// **'{day}, {time}'**
  String reminderDayTime(String day, String time);

  /// A repeating reminder, such as “Mon, Aug 24, 5:00 PM · Weekly”.
  ///
  /// In en, this message translates to:
  /// **'{when} · {repeat}'**
  String reminderWithRepeat(String when, String repeat);

  /// Screen reader text of a reminder.
  ///
  /// In en, this message translates to:
  /// **'Reminder: {when}'**
  String reminderSpoken(String when);

  /// Screen reader text of a reminder whose time has passed.
  ///
  /// In en, this message translates to:
  /// **'Overdue reminder: {when}'**
  String reminderSpokenLate(String when);

  /// Quick reminder choice for a time later on the same day.
  ///
  /// In en, this message translates to:
  /// **'Later today'**
  String get reminderLaterToday;

  /// Quick reminder choice for a day in the coming week.
  ///
  /// In en, this message translates to:
  /// **'Next week'**
  String get reminderNextWeek;

  /// Big summary line at the top of the reminder sheet before a time is picked.
  ///
  /// In en, this message translates to:
  /// **'No reminder'**
  String get reminderNone;

  /// Under the summary at the top of the reminder sheet before a time is picked.
  ///
  /// In en, this message translates to:
  /// **'Pick a date and time'**
  String get reminderPickTime;

  /// Summary at the top of the reminder sheet when the picked time is in the past.
  ///
  /// In en, this message translates to:
  /// **'This time has already passed'**
  String get reminderTimePassed;

  /// How soon a reminder rings, under the summary in the reminder sheet.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{In 1 minute} other{In {count} minutes}}'**
  String reminderInMinutes(int count);

  /// How soon a reminder rings, under the summary in the reminder sheet.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{In 1 hour} other{In {count} hours}}'**
  String reminderInHours(int count);

  /// How soon a reminder rings, under the summary in the reminder sheet.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{In 1 day} other{In {count} days}}'**
  String reminderInDays(int count);

  /// Under the summary in the reminder sheet for a reminder that rings every day.
  ///
  /// In en, this message translates to:
  /// **'Repeats every day'**
  String get reminderRepeatsDaily;

  /// Under the summary in the reminder sheet for a reminder that rings weekly.
  ///
  /// In en, this message translates to:
  /// **'Repeats every {weekday}'**
  String reminderRepeatsWeekly(String weekday);

  /// Under the summary in the reminder sheet for a reminder that rings monthly.
  ///
  /// In en, this message translates to:
  /// **'Repeats monthly on day {day}'**
  String reminderRepeatsMonthly(int day);

  /// For days 29 to 31: in shorter months it rings on the last day. Keep it short, it shows on one line.
  ///
  /// In en, this message translates to:
  /// **'Repeats monthly on day {day} or the last day'**
  String reminderRepeatsMonthlyEnd(int day);

  /// Under the summary in the reminder sheet for a reminder that rings once a year.
  ///
  /// In en, this message translates to:
  /// **'Repeats every year on {date}'**
  String reminderRepeatsYearly(String date);

  /// How often a reminder rings: one time only, without repeating.
  ///
  /// In en, this message translates to:
  /// **'Once'**
  String get repeatOnce;

  /// How often a reminder rings. Short: one of four tabs in a row.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get repeatDaily;

  /// How often a reminder rings. Short: one of four tabs in a row.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get repeatWeekly;

  /// How often a reminder rings. Short: one of four tabs in a row.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get repeatMonthly;

  /// How often a reminder rings. Short: one of four tabs in a row.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get repeatYearly;

  /// Screen reader name of the list of reminder times.
  ///
  /// In en, this message translates to:
  /// **'When'**
  String get reminderWhen;

  /// Row in the reminder sheet that opens a calendar and clock to choose any time.
  ///
  /// In en, this message translates to:
  /// **'Pick a date'**
  String get reminderPickDate;

  /// Button that opens the calendar in the reminder sheet before a day is chosen.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get reminderDate;

  /// Button that opens the clock in the reminder sheet before a time is chosen.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get reminderTime;

  /// Switch in the reminder sheet that makes the reminder ring again and again.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get reminderRepeat;

  /// Button in the reminder sheet that deletes the note’s reminder.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get reminderRemove;

  /// Error shown when a reminder picked in the reminder sheet couldn’t be saved.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t set the reminder'**
  String get reminderSetFailed;

  /// Title of the dialog shown before the phone asks for notification permission.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications?'**
  String get reminderNotifyTitle;

  /// Message of the dialog shown before the phone asks for notification permission.
  ///
  /// In en, this message translates to:
  /// **'Anchor needs permission to send notifications so your reminders can ring on this phone.'**
  String get reminderNotifyMessage;

  /// Android’s “Alarms & reminders” permission.
  ///
  /// In en, this message translates to:
  /// **'Allow exact alarms?'**
  String get reminderExactTitle;

  /// Message of the dialog that asks for Android’s Alarms & reminders permission.
  ///
  /// In en, this message translates to:
  /// **'Android may delay reminders to save battery. Allow exact alarms so they ring on time.'**
  String get reminderExactMessage;

  /// Toast when a reminder is set but notifications for the app are blocked.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off. Turn them on in your phone’s settings.'**
  String get reminderNotificationsOff;

  /// Screen reader label of the arrow that shows the previous month in a calendar.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get monthPrevious;

  /// Screen reader label of the arrow that shows the next month in a calendar.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get monthNext;

  /// Name of the app’s notification category in Android’s settings.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get reminderChannelName;

  /// Description of the app’s notification category in Android’s settings.
  ///
  /// In en, this message translates to:
  /// **'Reminders you set on your notes'**
  String get reminderChannelDescription;

  /// Number of notes, under the list title, in the tag sheet and the Empty trash menu.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 note} other{{count} notes}}'**
  String notesCount(int count);

  /// Title of the sheet that tags a note, and the tags heading in the side menu.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tagsTitle;

  /// Title of the sheet that tags several selected notes at once.
  ///
  /// In en, this message translates to:
  /// **'Tag notes'**
  String get tagNotesTitle;

  /// Error when a new or renamed tag couldn’t be saved.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t save the tag'**
  String get tagSaveFailed;

  /// Toast when adding or removing tags on notes failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t update the tags'**
  String get tagUpdateFailed;

  /// Error when creating or renaming a tag to a name that’s already used.
  ///
  /// In en, this message translates to:
  /// **'A tag named “{name}” already exists.'**
  String tagNameTaken(String name);

  /// Row in the tag sheet that makes a new tag from the typed text.
  ///
  /// In en, this message translates to:
  /// **'Create “{name}”'**
  String tagCreateNamed(String name);

  /// Screen reader text of a tag that is on the note.
  ///
  /// In en, this message translates to:
  /// **'{tag}, added'**
  String tagAdded(String tag);

  /// Screen reader text of a tag that isn’t on the note.
  ///
  /// In en, this message translates to:
  /// **'{tag}, not added'**
  String tagNotAdded(String tag);

  /// Screen reader text of a tag on some of the selected notes.
  ///
  /// In en, this message translates to:
  /// **'{tag}, added to some notes'**
  String tagAddedToSome(String tag);

  /// Hint inside the empty search field of the tag sheet.
  ///
  /// In en, this message translates to:
  /// **'Search or create a tag'**
  String get tagSearchOrCreate;

  /// Shown in the tag sheet when the person has no tags yet.
  ///
  /// In en, this message translates to:
  /// **'No tags yet. Type a name to create one.'**
  String get tagsEmpty;

  /// Screen reader name of the sheet for one tag.
  ///
  /// In en, this message translates to:
  /// **'Tag {name}'**
  String tagSheetLabel(String name);

  /// Section label for the color choices of a tag.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get tagColor;

  /// Row in a tag’s sheet that renames it, and title of the rename sheet.
  ///
  /// In en, this message translates to:
  /// **'Rename tag'**
  String get tagRename;

  /// Row in a tag’s sheet and the confirm button of its dialog: deletes the tag.
  ///
  /// In en, this message translates to:
  /// **'Delete tag'**
  String get tagDelete;

  /// Title of the dialog that confirms deleting a tag.
  ///
  /// In en, this message translates to:
  /// **'Delete tag “{name}”?'**
  String tagDeleteTitle(String name);

  /// Message of the dialog that confirms deleting a tag that is on notes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{The tag will be removed from 1 note. Your notes won’t be deleted.} other{The tag will be removed from {count} notes. Your notes won’t be deleted.}}'**
  String tagDeleteMessage(int count);

  /// Message of the dialog that confirms deleting a tag no note uses.
  ///
  /// In en, this message translates to:
  /// **'This tag isn’t on any notes.'**
  String get tagDeleteUnused;

  /// Toast after a tag was deleted.
  ///
  /// In en, this message translates to:
  /// **'Tag “{name}” deleted'**
  String tagDeleted(String name);

  /// Title of the new tag sheet, and spoken name of the plus button that opens it.
  ///
  /// In en, this message translates to:
  /// **'New tag'**
  String get tagNew;

  /// Placeholder in the tag preview while the name field is empty. Lowercase, like a tag.
  ///
  /// In en, this message translates to:
  /// **'tag name'**
  String get tagNamePreview;

  /// Hint inside the empty tag name field.
  ///
  /// In en, this message translates to:
  /// **'Tag name'**
  String get tagNameHint;

  /// Button that saves a new tag.
  ///
  /// In en, this message translates to:
  /// **'Create tag'**
  String get tagCreate;

  /// Verb: button that saves a tag’s new name.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get tagRenameAction;

  /// Screen reader name of a tag or note background color swatch.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get colorRed;

  /// Screen reader name of a tag, note background or highlight color swatch.
  ///
  /// In en, this message translates to:
  /// **'Pink'**
  String get colorPink;

  /// Screen reader name of a tag, note background or highlight color swatch.
  ///
  /// In en, this message translates to:
  /// **'Purple'**
  String get colorPurple;

  /// Screen reader name of a tag color swatch, darker than purple.
  ///
  /// In en, this message translates to:
  /// **'Deep purple'**
  String get colorDeepPurple;

  /// Screen reader name of a dark blue tag or note background color swatch.
  ///
  /// In en, this message translates to:
  /// **'Indigo'**
  String get colorIndigo;

  /// Screen reader name of a tag, note background or highlight color swatch.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get colorBlue;

  /// Screen reader name of a tag color swatch, paler than blue.
  ///
  /// In en, this message translates to:
  /// **'Light blue'**
  String get colorLightBlue;

  /// Screen reader name of a bright blue-green tag color swatch.
  ///
  /// In en, this message translates to:
  /// **'Cyan'**
  String get colorCyan;

  /// Screen reader name of a dark blue-green tag or note background color swatch.
  ///
  /// In en, this message translates to:
  /// **'Teal'**
  String get colorTeal;

  /// Screen reader name of a tag, note background or highlight color swatch.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get colorGreen;

  /// Screen reader name of a tag color swatch, paler than green.
  ///
  /// In en, this message translates to:
  /// **'Light green'**
  String get colorLightGreen;

  /// Screen reader name of a yellow-green tag color swatch.
  ///
  /// In en, this message translates to:
  /// **'Lime'**
  String get colorLime;

  /// Screen reader name of a golden orange-yellow tag color swatch.
  ///
  /// In en, this message translates to:
  /// **'Amber'**
  String get colorAmber;

  /// Screen reader name of a tag or note background color swatch.
  ///
  /// In en, this message translates to:
  /// **'Orange'**
  String get colorOrange;

  /// Screen reader name of a tag color swatch, redder than orange.
  ///
  /// In en, this message translates to:
  /// **'Deep orange'**
  String get colorDeepOrange;

  /// Screen reader name of a tag or note background color swatch.
  ///
  /// In en, this message translates to:
  /// **'Brown'**
  String get colorBrown;

  /// Screen reader name of a grayish blue tag color swatch.
  ///
  /// In en, this message translates to:
  /// **'Blue gray'**
  String get colorBlueGrey;

  /// Screen reader name of a tag, note background or highlight color swatch.
  ///
  /// In en, this message translates to:
  /// **'Yellow'**
  String get colorYellow;

  /// Bold lead of a warning above the notes list after the sign-in expired.
  ///
  /// In en, this message translates to:
  /// **'Signed out.'**
  String get syncSignedOutLead;

  /// Follows the bold “Signed out.” in a warning at the top of the notes list.
  ///
  /// In en, this message translates to:
  /// **'Sign in again to sync your notes.'**
  String get syncSignedOutText;

  /// Title of the dialog that asks the person to sign in again after the sign-in expired.
  ///
  /// In en, this message translates to:
  /// **'Sign in again'**
  String get syncSignInAgainTitle;

  /// Message of the dialog that asks the person to sign in again.
  ///
  /// In en, this message translates to:
  /// **'Your notes stay on this phone and sync once you sign in.'**
  String get syncSignInAgainMessage;

  /// Bold lead of a warning when the server is too old, also used after “Sync is paused.” in Settings.
  ///
  /// In en, this message translates to:
  /// **'Update your server.'**
  String get syncServerOutdatedLead;

  /// Follows the bold “Update your server.” in a warning; “It” is the server.
  ///
  /// In en, this message translates to:
  /// **'It’s too old to sync with this app.'**
  String get syncServerOutdatedText;

  /// Title of the dialog explaining that the server is too old for this app.
  ///
  /// In en, this message translates to:
  /// **'Update your server'**
  String get syncServerOutdatedTitle;

  /// Message of the dialog explaining that the server is too old for this app.
  ///
  /// In en, this message translates to:
  /// **'Your Anchor server is too old to sync with this app. Update the server to continue.'**
  String get syncServerOutdatedMessage;

  /// Bold lead of a warning when the app is too old, also used after “Sync is paused.” in Settings.
  ///
  /// In en, this message translates to:
  /// **'Update Anchor.'**
  String get syncAppOutdatedLead;

  /// Follows the bold “Update Anchor.” in a warning at the top of the notes list.
  ///
  /// In en, this message translates to:
  /// **'This app is too old to sync with your server.'**
  String get syncAppOutdatedText;

  /// Title of the dialog explaining that the app is too old for the server.
  ///
  /// In en, this message translates to:
  /// **'Update Anchor'**
  String get syncAppOutdatedTitle;

  /// Message of the dialog explaining that the app is too old for the server.
  ///
  /// In en, this message translates to:
  /// **'This app is too old to sync with your Anchor server. Update the app to continue.'**
  String get syncAppOutdatedMessage;

  /// {reason} says which side needs an update.
  ///
  /// In en, this message translates to:
  /// **'{reason} Your notes stay on this phone in the meantime.'**
  String syncPausedMessage(String reason);

  /// Screen reader label of the bell button on a note without a reminder.
  ///
  /// In en, this message translates to:
  /// **'Add a reminder'**
  String get reminderAdd;

  /// The day before today, as a date heading or on a note card.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get commonYesterday;

  /// How many people a note is shared with, beside Sharing in the note’s menu.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 person} other{{count} people}}'**
  String peopleCount(int count);

  /// Number of words in the note, in the small line under its title.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 word} other{{count} words}}'**
  String wordsCount(int count);

  /// Page title while selecting notes and none is selected yet.
  ///
  /// In en, this message translates to:
  /// **'Select notes'**
  String get notesSelectTitle;

  /// Shown for a note without a title.
  ///
  /// In en, this message translates to:
  /// **'Untitled'**
  String get noteUntitled;

  /// Two people’s first names joined, as in “Shared with Ada and Ben”.
  ///
  /// In en, this message translates to:
  /// **'{first} and {second}'**
  String namesTwo(String first, String second);

  /// Two names and how many other people.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{first}, {second} and {count} more}}'**
  String namesMore(String first, String second, int count);

  /// Small line in the share sheet when the note isn’t shared with anyone.
  ///
  /// In en, this message translates to:
  /// **'Only you can see this note.'**
  String get shareOnlyYou;

  /// Notice in the share sheet when the list of people the note is shared with didn’t load, next to a Try again button.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load the people with access.'**
  String get shareLoadFailed;

  /// Small line in the share sheet giving how many people can see the note.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Shared with 1 person.} other{Shared with {count} people.}}'**
  String shareSharedWith(int count);

  /// Small line in the share sheet while offline, when the list of people can’t load.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Shared with 1 person. Connect to see who has access.} other{Shared with {count} people. Connect to see who has access.}}'**
  String shareSharedWithOffline(int count);

  /// Under a note’s title, or in a toast after sharing; {names} holds first names.
  ///
  /// In en, this message translates to:
  /// **'Shared with {names}'**
  String shareSharedWithNames(String names);

  /// A short line on a note, without a period.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Shared with 1 person} other{Shared with {count} people}}'**
  String shareSharedWithCount(int count);

  /// Access level: the person can read the note but not change it.
  ///
  /// In en, this message translates to:
  /// **'Can view'**
  String get shareCanView;

  /// Access level: the person can read and change the note.
  ///
  /// In en, this message translates to:
  /// **'Can edit'**
  String get shareCanEdit;

  /// When a version of a note was saved, in version history.
  ///
  /// In en, this message translates to:
  /// **'Today at {time}'**
  String dayTodayAt(String time);

  /// When a version of a note was saved, in version history.
  ///
  /// In en, this message translates to:
  /// **'Yesterday at {time}'**
  String dayYesterdayAt(String time);

  /// When a version of a note was saved, in version history.
  ///
  /// In en, this message translates to:
  /// **'{date} at {time}'**
  String dayOnAt(String date, String time);

  /// When the note last changed, in the small line under its title.
  ///
  /// In en, this message translates to:
  /// **'Edited today'**
  String get editedToday;

  /// When the note last changed, in the small line under its title.
  ///
  /// In en, this message translates to:
  /// **'Edited yesterday'**
  String get editedYesterday;

  /// When the note last changed, in the small line under its title.
  ///
  /// In en, this message translates to:
  /// **'Edited {date}'**
  String editedOn(String date);

  /// When the current version last changed, in version history.
  ///
  /// In en, this message translates to:
  /// **'Edited just now'**
  String get editedJustNow;

  /// When the current version last changed, in version history.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Edited 1 min ago} other{Edited {count} min ago}}'**
  String editedMinutesAgo(int count);

  /// When the current version last changed, in version history.
  ///
  /// In en, this message translates to:
  /// **'Edited today at {time}'**
  String editedTodayAt(String time);

  /// When the current version last changed, in version history.
  ///
  /// In en, this message translates to:
  /// **'Edited yesterday at {time}'**
  String editedYesterdayAt(String time);

  /// When the current version last changed, in version history.
  ///
  /// In en, this message translates to:
  /// **'Edited {date} at {time}'**
  String editedOnAt(String date, String time);

  /// Under the Trash title in the trash menu, which has the Empty trash option.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Notes here are deleted after 1 day.} other{Notes here are deleted after {count} days.}}'**
  String trashRule(int count);

  /// Empty-screen help when the trash has no notes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Notes you delete stay here for 1 day.} other{Notes you delete stay here for {count} days.}}'**
  String trashEmpty(int count);

  /// Small label on a note card in the trash: days until it’s permanently deleted.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day left} other{{count} days left}}'**
  String trashDaysLeft(int count);

  /// Follows the bold “In trash.” at the bottom of a note opened from the trash.
  ///
  /// In en, this message translates to:
  /// **'Will be deleted on {date}.'**
  String trashDeletesOn(String date);

  /// Follows the bold “In trash.” when the date the note was deleted isn’t known.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Will be deleted after 1 day.} other{Will be deleted after {count} days.}}'**
  String trashDeletesAfter(int count);

  /// Empty-screen help in version history when the note has no earlier versions.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{A version is saved each time the note changes and kept for 1 day.} other{A version is saved each time the note changes and kept for {count} days.}}'**
  String historyKept(int count);

  /// Small note at the end of the version history list.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Edits older than 1 day are removed.} other{Edits older than {count} days are removed.}}'**
  String historyLimit(int count);

  /// Label of a version saved by an ordinary edit of the note.
  ///
  /// In en, this message translates to:
  /// **'Earlier version'**
  String get historyEarlier;

  /// A version that couldn’t be saved because the note had already changed elsewhere.
  ///
  /// In en, this message translates to:
  /// **'Not saved'**
  String get historyNotSaved;

  /// A version saved just before an older version was restored.
  ///
  /// In en, this message translates to:
  /// **'Before a restore'**
  String get historyBeforeRestore;

  /// The author of a version when it isn’t known.
  ///
  /// In en, this message translates to:
  /// **'Someone'**
  String get historySomeone;

  /// The author of a version when it’s the person using the app.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get historyYou;

  /// Item in the side menu and title of the main list of notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get navNotes;

  /// Noun: the side menu item and list title for archived notes.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get navArchive;

  /// Noun: the side menu item and list title for deleted notes.
  ///
  /// In en, this message translates to:
  /// **'Trash'**
  String get navTrash;

  /// Screen reader label of the account row at the bottom of the menu.
  ///
  /// In en, this message translates to:
  /// **'{name}, Settings'**
  String drawerAccount(String name);

  /// Message after changing someone’s access.
  ///
  /// In en, this message translates to:
  /// **'{person} can now view'**
  String shareNowCanView(String person);

  /// Message after changing someone’s access.
  ///
  /// In en, this message translates to:
  /// **'{person} can now edit'**
  String shareNowCanEdit(String person);

  /// Shown above a version’s changes when they’re compared with the latest text.
  ///
  /// In en, this message translates to:
  /// **'Compared with the current version'**
  String get revisionComparedCurrent;

  /// Shown above a version’s changes: the later version they’re compared with.
  ///
  /// In en, this message translates to:
  /// **'Compared with today at {time}'**
  String revisionComparedTodayAt(String time);

  /// Shown above a version’s changes: the later version they’re compared with.
  ///
  /// In en, this message translates to:
  /// **'Compared with yesterday at {time}'**
  String revisionComparedYesterdayAt(String time);

  /// Shown above a version’s changes: the later version they’re compared with.
  ///
  /// In en, this message translates to:
  /// **'Compared with {date} at {time}'**
  String revisionComparedOnAt(String date, String time);

  /// The line under the Archive title: archived notes don’t show in the Notes list.
  ///
  /// In en, this message translates to:
  /// **'Hidden from Notes'**
  String get listArchiveLine;

  /// The line under the Trash title: how long notes stay in the trash.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Deleted after 1 day} other{Deleted after {count} days}}'**
  String listTrashLine(int count);

  /// The line under the list title while offline with nothing waiting to sync.
  ///
  /// In en, this message translates to:
  /// **'Offline · changes are saved on this phone'**
  String get listOfflineSaved;

  /// The line under the list title while offline, with changes that haven’t been sent yet.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Offline · 1 change to sync} other{Offline · {count} changes to sync}}'**
  String listOfflineChanges(int count);

  /// The line under the list title after the last sync failed, until one works.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t sync'**
  String get listSyncFailed;

  /// Screen reader label of the list title, which opens the menu.
  ///
  /// In en, this message translates to:
  /// **'{title}, open menu'**
  String listTitleMenu(String title);

  /// Hint inside the empty search field on the Notes list.
  ///
  /// In en, this message translates to:
  /// **'Search notes'**
  String get searchNotes;

  /// Hint inside the empty search field on the Archive list.
  ///
  /// In en, this message translates to:
  /// **'Search archive'**
  String get searchArchive;

  /// Hint inside the empty search field on the Trash list.
  ///
  /// In en, this message translates to:
  /// **'Search trash'**
  String get searchTrash;

  /// Action that opens the tag picker for notes.
  ///
  /// In en, this message translates to:
  /// **'Tag'**
  String get actionTag;

  /// Verb, in the note menu and selection bar: keeps notes at the top of the list.
  ///
  /// In en, this message translates to:
  /// **'Pin'**
  String get actionPin;

  /// Verb, in the note menu and selection bar: stops keeping notes at the top.
  ///
  /// In en, this message translates to:
  /// **'Unpin'**
  String get actionUnpin;

  /// Verb: opens sharing for a note or a picture; also the title of the share sheet.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get actionShare;

  /// Menu item and button that open a note’s earlier versions; also that page’s title.
  ///
  /// In en, this message translates to:
  /// **'Version history'**
  String get actionHistory;

  /// Item in a note's More menu that unchecks every checked item in the note's checklists. Shown for notes with a checklist, dimmed while no item is checked.
  ///
  /// In en, this message translates to:
  /// **'Uncheck all'**
  String get actionUncheckAll;

  /// Item in a note's More menu that deletes every checked item from the note's checklists, with Undo. Shown for notes with a checklist, dimmed while no item is checked.
  ///
  /// In en, this message translates to:
  /// **'Delete checked items'**
  String get actionDeleteChecked;

  /// Verb: moves notes to the archive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get actionArchive;

  /// Verb, in menus and the selection bar: moves notes from the archive back to Notes.
  ///
  /// In en, this message translates to:
  /// **'Unarchive'**
  String get actionUnarchive;

  /// Verb: moves notes to the trash or deletes a picture. Short: fits the selection bar.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// Removes a note shared with you from your notes.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get actionRemove;

  /// Verb: brings notes back from the trash, or brings back an earlier version.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get actionRestore;

  /// Button that permanently deletes notes in the trash.
  ///
  /// In en, this message translates to:
  /// **'Delete permanently'**
  String get actionDeletePermanently;

  /// Toast after notes were pinned to the top of the list, with an Undo button.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Note pinned} other{{count} notes pinned}}'**
  String notesPinned(int count);

  /// Toast after notes were unpinned, with an Undo button.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Note unpinned} other{{count} notes unpinned}}'**
  String notesUnpinned(int count);

  /// Toast after notes were moved to the archive, with an Undo button.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Note archived} other{{count} notes archived}}'**
  String notesArchived(int count);

  /// Toast after notes were moved out of the archive, with an Undo button.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Note unarchived} other{{count} notes unarchived}}'**
  String notesUnarchived(int count);

  /// Toast after Uncheck all in a note's More menu, with an Undo button. The items are checklist items in the note.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Item unchecked} other{{count} items unchecked}}'**
  String itemsUnchecked(int count);

  /// Toast after Delete checked items in a note's More menu, with an Undo button. The items are checklist items in the note.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Checked item deleted} other{{count} checked items deleted}}'**
  String checkedItemsDeleted(int count);

  /// Toast after notes were brought back from the trash, with an Undo button.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Note restored} other{{count} notes restored}}'**
  String notesRestored(int count);

  /// Toast after notes were permanently deleted.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Note permanently deleted} other{{count} notes permanently deleted}}'**
  String notesDeletedForever(int count);

  /// Toast after the person’s own notes were moved to the trash.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Note moved to trash} other{{count} notes moved to trash}}'**
  String notesMovedToTrash(int count);

  /// Notes shared with the person, taken off their list.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Note removed from your notes} other{{count} notes removed from your notes}}'**
  String notesRemovedFromYours(int count);

  /// Two sentences: notes moved to trash, and shared notes removed.
  ///
  /// In en, this message translates to:
  /// **'{moved} {removed}'**
  String notesTrashedMixed(String moved, String removed);

  /// First sentence of a toast that also mentions removed shared notes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 note moved to trash.} other{{count} notes moved to trash.}}'**
  String notesMovedToTrashPart(int count);

  /// About notes shared with the person.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 removed from your notes.} other{{count} removed from your notes.}}'**
  String notesRemovedPart(int count);

  /// For a note someone else shared with the person.
  ///
  /// In en, this message translates to:
  /// **'Remove this note from your notes?'**
  String get notesRemoveSharedTitle;

  /// Message of the dialog that removes one note someone else shared with the person.
  ///
  /// In en, this message translates to:
  /// **'To see it again, its owner has to share it with you again.'**
  String get notesRemoveSharedMessage;

  /// Title of the dialog that confirms deleting notes, some of them shared with the person.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Delete 1 note?} other{Delete {count} notes?}}'**
  String notesDeleteTitle(int count);

  /// Message of the dialog that confirms deleting notes that others shared with the person.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{A note shared with you will be removed from your notes. To see it again, its owner has to share it with you again.} other{{count} notes shared with you will be removed from your notes. To see them again, their owners have to share them with you again.}}'**
  String notesDeleteSharedMessage(int count);

  /// Title of the dialog that confirms permanently deleting the open note.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete this note?'**
  String get notesDeleteForeverOneTitle;

  /// Title of the dialog that confirms permanently deleting the selected notes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Permanently delete 1 note?} other{Permanently delete {count} notes?}}'**
  String notesDeleteForeverTitle(int count);

  /// Message of the dialog that confirms permanently deleting notes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{This can’t be undone. People you shared it with will lose access too.} other{This can’t be undone. People you shared them with will lose access too.}}'**
  String notesDeleteForeverMessage(int count);

  /// Menu item and dialog button that permanently delete every note in the trash.
  ///
  /// In en, this message translates to:
  /// **'Empty trash'**
  String get trashEmptyAction;

  /// Under the Empty trash menu item when the trash has no notes.
  ///
  /// In en, this message translates to:
  /// **'Nothing to delete'**
  String get trashNothing;

  /// Title of the dialog that confirms emptying the trash.
  ///
  /// In en, this message translates to:
  /// **'Empty trash?'**
  String get trashEmptyTitle;

  /// Message of the dialog that confirms emptying the trash.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 note will be permanently deleted. This can’t be undone.} other{{count} notes will be permanently deleted. This can’t be undone.}}'**
  String trashEmptyMessage(int count);

  /// Toast after every note in the trash was permanently deleted.
  ///
  /// In en, this message translates to:
  /// **'Trash emptied'**
  String get trashEmptied;

  /// Title of the sheet for layout and sort order, and the button that opens it.
  ///
  /// In en, this message translates to:
  /// **'View options'**
  String get listViewOptions;

  /// Hint inside the empty search field while the list shows only one tag.
  ///
  /// In en, this message translates to:
  /// **'Search #{tag}'**
  String searchTag(String tag);

  /// Empty-screen title when a search finds no notes.
  ///
  /// In en, this message translates to:
  /// **'No results for “{query}”'**
  String searchNoResults(String query);

  /// Empty-screen help when a search finds no notes.
  ///
  /// In en, this message translates to:
  /// **'Check the spelling or try different words.'**
  String get searchNoResultsHelp;

  /// Empty-screen title when the archive has no notes.
  ///
  /// In en, this message translates to:
  /// **'No archived notes'**
  String get archiveEmptyTitle;

  /// Empty-screen help in the archive, where “Archive” is a verb.
  ///
  /// In en, this message translates to:
  /// **'Archive notes you want to keep but don’t need to see every day.'**
  String get archiveEmptyHelp;

  /// Empty-screen title when the trash has no notes.
  ///
  /// In en, this message translates to:
  /// **'Trash is empty'**
  String get trashEmptyStateTitle;

  /// Empty-screen title when no note has the tag the list is showing.
  ///
  /// In en, this message translates to:
  /// **'No notes tagged #{tag}'**
  String tagEmptyTitle(String tag);

  /// Empty-screen help when the list shows a tag that no note has yet.
  ///
  /// In en, this message translates to:
  /// **'New notes you create here get this tag.'**
  String get tagEmptyHelp;

  /// Read by screen readers while gray card shapes stand in for notes still coming from the server.
  ///
  /// In en, this message translates to:
  /// **'Loading notes'**
  String get notesLoading;

  /// Empty-screen title when the person has no notes.
  ///
  /// In en, this message translates to:
  /// **'No notes yet'**
  String get notesEmptyTitle;

  /// “New note” is the name of the button.
  ///
  /// In en, this message translates to:
  /// **'Tap New note to write your first one.'**
  String get notesEmptyHelp;

  /// Title in the middle of the notes list when the person's notes haven't come to this phone yet because it is offline, the server can't be reached or syncing is paused.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load your notes'**
  String get notesLoadFailedTitle;

  /// Under “Couldn’t load your notes”, above a Try again button.
  ///
  /// In en, this message translates to:
  /// **'Check your connection, then try again.'**
  String get notesLoadFailedHelp;

  /// Under “Couldn’t load your notes” while syncing is paused (signed out, or the app or the server needs an update). A warning above the list says what to do.
  ///
  /// In en, this message translates to:
  /// **'Your notes will appear here once they sync.'**
  String get notesLoadPausedHelp;

  /// Button that starts a new note, on the empty list and the plus button.
  ///
  /// In en, this message translates to:
  /// **'New note'**
  String get noteNew;

  /// Tooltip of the cloud icon on a note card with changes not yet sent. Screen readers also read it with the card.
  ///
  /// In en, this message translates to:
  /// **'Not synced yet'**
  String get cardNotSynced;

  /// Read out by screen readers with a note card: how many pictures the note has.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 picture} other{{count} pictures}}'**
  String cardPictures(int count);

  /// Under a note’s title, or spoken on a card: who shared the note with the person.
  ///
  /// In en, this message translates to:
  /// **'Shared by {name}'**
  String shareSharedBy(String name);

  /// The Share action when the note is already shared.
  ///
  /// In en, this message translates to:
  /// **'Sharing'**
  String get actionSharing;

  /// Menu item that moves the open note to the trash.
  ///
  /// In en, this message translates to:
  /// **'Move to trash'**
  String get actionMoveToTrash;

  /// For a note someone else shared with the person.
  ///
  /// In en, this message translates to:
  /// **'Remove from my notes'**
  String get actionRemoveFromMine;

  /// Bold lead before a sentence about when the note will be deleted.
  ///
  /// In en, this message translates to:
  /// **'In trash.'**
  String get readOnlyInTrash;

  /// Bold lead before a sentence about who can edit the note.
  ///
  /// In en, this message translates to:
  /// **'View only.'**
  String get readOnlyViewOnly;

  /// Follows the bold “View only.” at the bottom of a note the person can’t edit.
  ///
  /// In en, this message translates to:
  /// **'Only the owner can edit it.'**
  String get readOnlyOwnerEdits;

  /// Follows the bold “View only.” at the bottom of a note someone shared with the person.
  ///
  /// In en, this message translates to:
  /// **'Shared by {name}.'**
  String readOnlySharedBy(String name);

  /// Shown on a note that is in the archive.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get noteArchived;

  /// Small button under the note’s title that opens the tag picker.
  ///
  /// In en, this message translates to:
  /// **'Add tag'**
  String get tagAdd;

  /// Screen reader label of the remove button on a tag chip.
  ///
  /// In en, this message translates to:
  /// **'Remove {tag}'**
  String tagRemoveNamed(String tag);

  /// Starts a bulleted list in an empty note.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get starterList;

  /// Adds a picture or an audio file to an empty note.
  ///
  /// In en, this message translates to:
  /// **'Picture or audio'**
  String get starterAttachment;

  /// Toast after a picture was removed from a note, with an Undo button.
  ///
  /// In en, this message translates to:
  /// **'Picture deleted'**
  String get attachmentPictureDeleted;

  /// Toast after a voice note recorded in the app was removed from a note, with an Undo button.
  ///
  /// In en, this message translates to:
  /// **'Voice note deleted'**
  String get attachmentVoiceDeleted;

  /// Screen reader label of the button that adds a picture or audio file to a note.
  ///
  /// In en, this message translates to:
  /// **'Add picture or audio'**
  String get attachmentAddLabel;

  /// Short label on a small square tile that adds a picture or audio.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get attachmentAdd;

  /// Shown when the person pulls down the list to sync while offline.
  ///
  /// In en, this message translates to:
  /// **'You’re offline. Your changes are saved on this phone.'**
  String get pullOffline;

  /// Shown above the list while a pull-down sync runs.
  ///
  /// In en, this message translates to:
  /// **'Syncing…'**
  String get pullSyncing;

  /// Shown above the list after a pull-down sync finished.
  ///
  /// In en, this message translates to:
  /// **'Up to date'**
  String get pullUpToDate;

  /// Shown above the list when a pull-down sync failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t sync. Your changes are saved on this phone.'**
  String get pullFailed;

  /// Screen reader label of the button that empties the search field.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get searchClear;

  /// Line style: plain text.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get lineText;

  /// Line style for the biggest heading, in the slash menu and the line styles toolbar.
  ///
  /// In en, this message translates to:
  /// **'Heading 1'**
  String get lineH1;

  /// Line style for a medium heading, in the slash menu and the line styles toolbar.
  ///
  /// In en, this message translates to:
  /// **'Heading 2'**
  String get lineH2;

  /// Line style for the smallest heading, in the slash menu and the line styles toolbar.
  ///
  /// In en, this message translates to:
  /// **'Heading 3'**
  String get lineH3;

  /// Line style with checkboxes; also a starter button in an empty note.
  ///
  /// In en, this message translates to:
  /// **'Checklist'**
  String get lineChecklist;

  /// Line style for a list with dots, in the slash menu and the toolbars.
  ///
  /// In en, this message translates to:
  /// **'Bullet list'**
  String get lineBullet;

  /// Line style for a list with numbers, in the slash menu and the line styles toolbar.
  ///
  /// In en, this message translates to:
  /// **'Numbered list'**
  String get lineNumbered;

  /// Noun: line style for quoted text, in the slash menu and toolbar.
  ///
  /// In en, this message translates to:
  /// **'Quote'**
  String get lineQuote;

  /// Line style for computer code in a fixed-width font.
  ///
  /// In en, this message translates to:
  /// **'Code block'**
  String get lineCode;

  /// Noun: slash menu item and spoken toolbar button that add a web link.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get editorLink;

  /// Search words for the slash menu, separated by spaces. Keep the English words and add your own.
  ///
  /// In en, this message translates to:
  /// **'todo to-do task checkbox list'**
  String get slashWordsChecklist;

  /// Search words for the slash menu, separated by spaces. Keep the English words and add your own.
  ///
  /// In en, this message translates to:
  /// **'h1 title'**
  String get slashWordsH1;

  /// Search words for the slash menu, separated by spaces. Keep the English words and add your own.
  ///
  /// In en, this message translates to:
  /// **'h2 subtitle subheading'**
  String get slashWordsH2;

  /// Search words for the slash menu, separated by spaces. Keep the English words and add your own.
  ///
  /// In en, this message translates to:
  /// **'h3 subheading'**
  String get slashWordsH3;

  /// Search words for the slash menu, separated by spaces. Keep the English words and add your own.
  ///
  /// In en, this message translates to:
  /// **'unordered ul dashes'**
  String get slashWordsBullet;

  /// Search words for the slash menu, separated by spaces. Keep the English words and add your own.
  ///
  /// In en, this message translates to:
  /// **'ordered ol'**
  String get slashWordsNumbered;

  /// Search words for the slash menu, separated by spaces. Keep the English words and add your own.
  ///
  /// In en, this message translates to:
  /// **'blockquote citation'**
  String get slashWordsQuote;

  /// Search words for the slash menu, separated by spaces. Keep the English words and add your own.
  ///
  /// In en, this message translates to:
  /// **'pre snippet'**
  String get slashWordsCode;

  /// Search words for the slash menu, separated by spaces. Keep the English words and add your own.
  ///
  /// In en, this message translates to:
  /// **'paragraph plain normal body'**
  String get slashWordsText;

  /// Search words for the slash menu, separated by spaces. Keep the English words and add your own.
  ///
  /// In en, this message translates to:
  /// **'url web address'**
  String get slashWordsLink;

  /// Search words for the slash menu, separated by spaces. Keep the English words and add your own.
  ///
  /// In en, this message translates to:
  /// **'image img photo file voice recording attachment'**
  String get slashWordsAttachment;

  /// Screen reader name of the editor toolbar while typing.
  ///
  /// In en, this message translates to:
  /// **'Formatting'**
  String get barFormatting;

  /// Screen reader name of the editor toolbar on a list line.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get barList;

  /// Screen reader name of the editor toolbar while text is selected.
  ///
  /// In en, this message translates to:
  /// **'Selected text'**
  String get barSelected;

  /// Screen reader name of the toolbar with text and line styles, and of its button.
  ///
  /// In en, this message translates to:
  /// **'Text styles'**
  String get barStyles;

  /// Screen reader name of the editor toolbar with highlight colors.
  ///
  /// In en, this message translates to:
  /// **'Highlight colors'**
  String get barColors;

  /// Screen reader name of the row of line style buttons in the editor toolbar.
  ///
  /// In en, this message translates to:
  /// **'Line styles'**
  String get barLineStyles;

  /// Screen reader label of the toolbar button that moves a list item one level left.
  ///
  /// In en, this message translates to:
  /// **'Outdent'**
  String get toolOutdent;

  /// Screen reader label of the toolbar button that moves a list item one level right.
  ///
  /// In en, this message translates to:
  /// **'Indent'**
  String get toolIndent;

  /// Screen reader label of the toolbar button that makes text bold.
  ///
  /// In en, this message translates to:
  /// **'Bold'**
  String get toolBold;

  /// Screen reader label of the toolbar button that makes text italic.
  ///
  /// In en, this message translates to:
  /// **'Italic'**
  String get toolItalic;

  /// Screen reader label of the toolbar button that underlines text.
  ///
  /// In en, this message translates to:
  /// **'Underline'**
  String get toolUnderline;

  /// Screen reader label of the toolbar button that crosses text out.
  ///
  /// In en, this message translates to:
  /// **'Strikethrough'**
  String get toolStrikethrough;

  /// Screen reader label of the toolbar button that marks text with a color.
  ///
  /// In en, this message translates to:
  /// **'Highlight'**
  String get toolHighlight;

  /// Screen reader label of the toolbar button that removes the color mark from text.
  ///
  /// In en, this message translates to:
  /// **'Remove highlight'**
  String get toolRemoveHighlight;

  /// Screen reader label of the toolbar button that repeats an undone change.
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get toolRedo;

  /// Screen reader label of the toolbar button that closes the on-screen keyboard.
  ///
  /// In en, this message translates to:
  /// **'Hide keyboard'**
  String get toolHideKeyboard;

  /// Screen reader name of an empty checklist or list item.
  ///
  /// In en, this message translates to:
  /// **'Empty item'**
  String get editorEmptyItem;

  /// Toast after a link’s web address was copied.
  ///
  /// In en, this message translates to:
  /// **'Link copied'**
  String get editorLinkCopied;

  /// Folded checked items at the end of a checklist.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 checked item} other{{count} checked items}}'**
  String editorCheckedItems(int count);

  /// Title of the sheet that adds a link to text, and its confirm button.
  ///
  /// In en, this message translates to:
  /// **'Add link'**
  String get linkAdd;

  /// Title of the sheet that changes an existing link.
  ///
  /// In en, this message translates to:
  /// **'Edit link'**
  String get linkEdit;

  /// Hint in the field for the words a link shows.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get linkTextHint;

  /// Opens a link in the browser. Short: one of four buttons in a small bubble.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get commonOpen;

  /// Changes a link. Short: one of four buttons in a small bubble over the link.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// Verb: removes a link from text, or a person from a shared note.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get commonRemove;

  /// Hint in an empty line: typing a slash opens a menu of line styles.
  ///
  /// In en, this message translates to:
  /// **'Type / for more'**
  String get editorSlashHint;

  /// Placeholder in an empty note.
  ///
  /// In en, this message translates to:
  /// **'Start writing'**
  String get editorPlaceholder;

  /// Button that retries something that failed, such as a picture upload.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get commonTryAgain;

  /// The note’s latest text, at the top of version history and as a page title.
  ///
  /// In en, this message translates to:
  /// **'Current version'**
  String get historyCurrent;

  /// A note that hasn’t synced yet, so it has no edit time from the server.
  ///
  /// In en, this message translates to:
  /// **'Saved on this phone'**
  String get historySavedOnPhone;

  /// A version that changed no lines, under its time in version history and in its title bar.
  ///
  /// In en, this message translates to:
  /// **'No changes'**
  String get historyNoChanges;

  /// Empty-screen title in version history when the note has no earlier versions.
  ///
  /// In en, this message translates to:
  /// **'No earlier versions yet'**
  String get historyEmptyTitle;

  /// Warning in version history when loading versions from the server failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t check for versions from your other devices.'**
  String get historyFetchFailed;

  /// Notice in version history while the phone is offline.
  ///
  /// In en, this message translates to:
  /// **'Connect to the internet to see versions from your other devices.'**
  String get historyOffline;

  /// Lines added in a version.
  ///
  /// In en, this message translates to:
  /// **'{count} added'**
  String diffAdded(int count);

  /// Lines removed in a version.
  ///
  /// In en, this message translates to:
  /// **'{count} removed'**
  String diffRemoved(int count);

  /// Lines changed in a version.
  ///
  /// In en, this message translates to:
  /// **'{count} changed'**
  String diffChanged(int count);

  /// What a version did, under its time in version history and in its title bar. When it did more, the other kinds follow in the short form, as in “2 lines added, 1 removed”.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 line added} other{{count} lines added}}'**
  String diffLinesAdded(int count);

  /// What a version did, under its time in version history and in its title bar. When it did more, the other kinds follow in the short form, as in “2 lines removed, 1 removed”.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 line removed} other{{count} lines removed}}'**
  String diffLinesRemoved(int count);

  /// What a version did, under its time in version history and in its title bar. When it did more, the other kinds follow in the short form, as in “2 lines changed, 1 removed”.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 line changed} other{{count} lines changed}}'**
  String diffLinesChanged(int count);

  /// Screen reader label of the button that shows hidden lines that didn’t change.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Show 1 unchanged line} other{Show {count} unchanged lines}}'**
  String diffShowUnchanged(int count);

  /// Small label standing in for lines that didn’t change between versions.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 unchanged line} other{{count} unchanged lines}}'**
  String diffUnchanged(int count);

  /// Screen reader prefix before a line added in a version.
  ///
  /// In en, this message translates to:
  /// **'Added:'**
  String get diffAddedMark;

  /// Screen reader prefix before a line removed in a version.
  ///
  /// In en, this message translates to:
  /// **'Removed:'**
  String get diffRemovedMark;

  /// Screen reader prefix before a line changed in a version.
  ///
  /// In en, this message translates to:
  /// **'Changed:'**
  String get diffChangedMark;

  /// Screen reader prefix before a checked checklist item.
  ///
  /// In en, this message translates to:
  /// **'Checked:'**
  String get diffCheckedMark;

  /// Screen reader prefix before an unchecked checklist item.
  ///
  /// In en, this message translates to:
  /// **'Not checked:'**
  String get diffUncheckedMark;

  /// Screen reader prefix before a title removed in a version.
  ///
  /// In en, this message translates to:
  /// **'Removed title:'**
  String get diffRemovedTitle;

  /// Screen reader prefix before a title added in a version.
  ///
  /// In en, this message translates to:
  /// **'Added title:'**
  String get diffAddedTitle;

  /// Bold lead of a warning on a version that couldn’t be saved.
  ///
  /// In en, this message translates to:
  /// **'Not saved.'**
  String get revisionNotSavedLead;

  /// Follows the bold “Not saved.” on a version that couldn’t be saved.
  ///
  /// In en, this message translates to:
  /// **'This edit wasn’t saved because the note changed on another device first. Restore it, or copy what you need.'**
  String get revisionNotSavedText;

  /// Toast when restoring a version whose text is the same as the note.
  ///
  /// In en, this message translates to:
  /// **'The note already matches this version'**
  String get revisionAlreadyMatches;

  /// Toast when an earlier version couldn’t be restored.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t restore this version'**
  String get revisionRestoreFailed;

  /// Text on the Restore button while an earlier version is restored.
  ///
  /// In en, this message translates to:
  /// **'Restoring…'**
  String get revisionRestoring;

  /// Screen reader label of the back button on a version page.
  ///
  /// In en, this message translates to:
  /// **'Back to the version list'**
  String get revisionBackToList;

  /// Screen reader label of the up arrow that shows the next newer version.
  ///
  /// In en, this message translates to:
  /// **'Newer version'**
  String get revisionNewer;

  /// Screen reader label of the down arrow that shows the next older version.
  ///
  /// In en, this message translates to:
  /// **'Older version'**
  String get revisionOlder;

  /// Which version is shown, such as “2 of 5”.
  ///
  /// In en, this message translates to:
  /// **'{index} of {count}'**
  String revisionPosition(int index, int count);

  /// Shown on a version page when that version was deleted.
  ///
  /// In en, this message translates to:
  /// **'This version is no longer available.'**
  String get revisionGone;

  /// Shown above a version whose text matches the next newer version.
  ///
  /// In en, this message translates to:
  /// **'Same text as the version after this one.'**
  String get revisionSameAsNext;

  /// Shown above a version whose text matches the note’s latest text.
  ///
  /// In en, this message translates to:
  /// **'Same text as the current version.'**
  String get revisionSameAsCurrent;

  /// Shown on a version page when that version has no text.
  ///
  /// In en, this message translates to:
  /// **'This version is empty.'**
  String get revisionEmpty;

  /// Toast when sharing a note with a person failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t share with {name}'**
  String shareFailed(String name);

  /// Screen reader name of the menu that changes someone’s access.
  ///
  /// In en, this message translates to:
  /// **'Access for {name}'**
  String shareAccessFor(String name);

  /// Toast after a person was removed from a shared note, with an Undo button.
  ///
  /// In en, this message translates to:
  /// **'{name} no longer has access'**
  String shareRevoked(String name);

  /// Toast when removing a person from a shared note failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t remove access for {name}'**
  String shareRevokeFailed(String name);

  /// Toast when changing a person’s access to a shared note failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t change access for {name}'**
  String shareChangeFailed(String name);

  /// Under the share sheet title.
  ///
  /// In en, this message translates to:
  /// **'People you add will see this note in their list.'**
  String get shareSubtitle;

  /// Under the share sheet title while the phone is offline.
  ///
  /// In en, this message translates to:
  /// **'Connect to the internet to share this note.'**
  String get shareOffline;

  /// Hint inside the empty field of the share sheet that finds people.
  ///
  /// In en, this message translates to:
  /// **'Add people by name or email'**
  String get shareSearchHint;

  /// Shown in the share sheet when the search finds no one.
  ///
  /// In en, this message translates to:
  /// **'No one found. Only people with an account on this server can be added.'**
  String get shareNoMatches;

  /// Section label in the share sheet for people the person shared with before.
  ///
  /// In en, this message translates to:
  /// **'Recently shared with'**
  String get shareRecent;

  /// Section label in the share sheet for people found by the search.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get sharePeople;

  /// Screen reader label of a person in the share search results.
  ///
  /// In en, this message translates to:
  /// **'Add {name}'**
  String shareAddPerson(String name);

  /// Section label in the share sheet for everyone who can see the note.
  ///
  /// In en, this message translates to:
  /// **'People with access'**
  String get shareWithAccess;

  /// The person’s own name in the share sheet’s list of people.
  ///
  /// In en, this message translates to:
  /// **'{name} (you)'**
  String shareYou(String name);

  /// Noun beside the person’s own name in the share sheet: they own the note.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get shareOwner;

  /// Screen reader label of the access button, such as “Can edit. Change access for Ada Lovelace”.
  ///
  /// In en, this message translates to:
  /// **'{permission}. Change access for {name}'**
  String shareChangeAccess(String permission, String name);

  /// Small label on a picture that can’t load while the phone is offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get commonOffline;

  /// Screen reader label of the delete button on an attachment.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}'**
  String commonDeleteItem(String name);

  /// Which picture is shown, such as “2 of 5”.
  ///
  /// In en, this message translates to:
  /// **'{index} of {count}'**
  String commonPosition(int index, int count);

  /// Title of the sheet with options to add a picture or audio to a note.
  ///
  /// In en, this message translates to:
  /// **'Add to note'**
  String get addToNote;

  /// Toast when the picked audio file is a type the app can’t play.
  ///
  /// In en, this message translates to:
  /// **'Anchor supports MP3, WAV, M4A, OGG and AAC audio'**
  String get addAudioFormats;

  /// Toast when the picked photo is in a format the phone couldn’t read or convert.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t add this photo. Try a JPEG or PNG.'**
  String get addPhotoUnsupported;

  /// Toast when recording is blocked because the app has no microphone permission.
  ///
  /// In en, this message translates to:
  /// **'Allow microphone access in Settings to record'**
  String get addMicDenied;

  /// Option that opens the camera to take a photo for the note.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get addTakePhoto;

  /// Option that picks a photo from the phone’s photo library to add to the note.
  ///
  /// In en, this message translates to:
  /// **'Choose photo'**
  String get addChoosePhoto;

  /// Option that starts recording a voice note.
  ///
  /// In en, this message translates to:
  /// **'Record audio'**
  String get addRecordAudio;

  /// Noun: option that picks an audio file stored on the phone.
  ///
  /// In en, this message translates to:
  /// **'Audio file'**
  String get addAudioFile;

  /// Noun: title of the sheet while a voice note is being recorded.
  ///
  /// In en, this message translates to:
  /// **'Recording'**
  String get recordingTitle;

  /// Under the title while a voice note is being recorded.
  ///
  /// In en, this message translates to:
  /// **'Speak normally. The recording stays on this phone until it uploads.'**
  String get recordingHelp;

  /// Title of the sheet after recording, where the person listens before keeping it.
  ///
  /// In en, this message translates to:
  /// **'Your recording'**
  String get recordingReviewTitle;

  /// Under the title after recording; {count} is the length in seconds.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 second. Listen, then keep it or record again.} other{{count} seconds. Listen, then keep it or record again.}}'**
  String recordingReviewHelp(int count);

  /// Under the title after a recording stopped by itself at the longest length a note can hold, about 70 minutes.
  ///
  /// In en, this message translates to:
  /// **'Stopped at the maximum length. Listen, then keep it or record again.'**
  String get recordingStoppedAtLimit;

  /// Screen reader text while recording. {time} is minutes and seconds, such as 0:12.
  ///
  /// In en, this message translates to:
  /// **'Recording, {time}'**
  String recordingElapsed(String time);

  /// Verb: button that ends the recording.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get recordingStop;

  /// Button that throws away the recording without adding it to the note.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get recordingDiscard;

  /// Records the audio again. Keep it short, it shares a row with two other buttons.
  ///
  /// In en, this message translates to:
  /// **'Again'**
  String get recordingAgain;

  /// Toast when the person plays a voice note that hasn’t downloaded while offline.
  ///
  /// In en, this message translates to:
  /// **'This voice note will play when you’re back online'**
  String get voiceOffline;

  /// Name of an audio recording made in the app.
  ///
  /// In en, this message translates to:
  /// **'Voice note'**
  String get voiceNote;

  /// Short line on a voice note card when its audio couldn’t load.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load'**
  String get voiceLoadFailed;

  /// Short line on a voice note or audio file card while it uploads.
  ///
  /// In en, this message translates to:
  /// **'Uploading…'**
  String get attachmentUploading;

  /// Short line on a voice note or audio file card when the server didn’t take it. A Try again button sits under it.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t upload'**
  String get attachmentUploadFailed;

  /// Screen reader name of the playback slider.
  ///
  /// In en, this message translates to:
  /// **'Position in {name}'**
  String voicePosition(String name);

  /// Toast when saving a picture is blocked because the app has no Photos permission.
  ///
  /// In en, this message translates to:
  /// **'Allow access to Photos in Settings to save pictures'**
  String get pictureAllowPhotos;

  /// Toast after a picture was saved to the phone’s photo library.
  ///
  /// In en, this message translates to:
  /// **'Saved to Photos'**
  String get pictureSaved;

  /// Toast when saving a picture to the phone’s photo library failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t save the picture'**
  String get pictureSaveFailed;

  /// Shown in the picture viewer when a picture can’t load while offline.
  ///
  /// In en, this message translates to:
  /// **'This picture will show when you’re back online'**
  String get pictureOffline;

  /// Shown in the picture viewer when a picture didn’t download while online, above a Try again button.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load this picture'**
  String get pictureLoadFailed;

  /// Screen reader label of the download button in the picture viewer.
  ///
  /// In en, this message translates to:
  /// **'Save to Photos'**
  String get pictureSaveToPhotos;

  /// Screen reader label of the retry button on a picture, voice note or audio file that didn’t upload or download.
  ///
  /// In en, this message translates to:
  /// **'Try again, {name}'**
  String attachmentRetry(String name);

  /// Screen reader label of a picture in a note.
  ///
  /// In en, this message translates to:
  /// **'{name}, open'**
  String pictureOpen(String name);

  /// Heading of the pinned notes.
  ///
  /// In en, this message translates to:
  /// **'Pinned'**
  String get groupPinned;

  /// Heading of the notes that aren’t pinned.
  ///
  /// In en, this message translates to:
  /// **'Others'**
  String get groupOthers;

  /// Heading of the archived notes listed below the others in search results and on a tag's page, with their count. On a tag's page it can be tapped to show or hide them.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get groupArchived;

  /// The note’s color or pattern.
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get noteBackground;

  /// Section label for note backgrounds with a repeating pattern.
  ///
  /// In en, this message translates to:
  /// **'Pattern'**
  String get notePattern;

  /// The note background with no color.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get noteColorDefault;

  /// Note background pattern made of small dots.
  ///
  /// In en, this message translates to:
  /// **'Dots'**
  String get patternDots;

  /// Note background pattern of squares, like graph paper.
  ///
  /// In en, this message translates to:
  /// **'Grid'**
  String get patternGrid;

  /// Note background pattern of lines, like ruled paper.
  ///
  /// In en, this message translates to:
  /// **'Lines'**
  String get patternLines;

  /// Note background pattern of wavy lines.
  ///
  /// In en, this message translates to:
  /// **'Waves'**
  String get patternWaves;

  /// Note background pattern of small shopping bag drawings.
  ///
  /// In en, this message translates to:
  /// **'Groceries'**
  String get patternGroceries;

  /// Note background pattern of small music note drawings.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get patternMusic;

  /// Note background pattern of small airplane drawings.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get patternTravel;

  /// Note background pattern of small computer code symbols.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get patternCode;

  /// Section label in the view options sheet for how notes are arranged.
  ///
  /// In en, this message translates to:
  /// **'Layout'**
  String get viewLayout;

  /// A layout where cards of different heights stack in columns.
  ///
  /// In en, this message translates to:
  /// **'Masonry'**
  String get viewMasonry;

  /// Layout with cards of equal size in columns. Short: one of three tabs in a row.
  ///
  /// In en, this message translates to:
  /// **'Grid'**
  String get viewGrid;

  /// Layout with one note per row. Short: one of three tabs in a row.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get viewList;

  /// Section label in the view options sheet for what decides the note order.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get viewSortBy;

  /// Sort option: orders notes by when they last changed.
  ///
  /// In en, this message translates to:
  /// **'Date edited'**
  String get viewDateEdited;

  /// Sort option: orders notes alphabetically by their title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get viewTitle;

  /// Sort direction for titles, alphabetical. Short: one of two tabs in a row.
  ///
  /// In en, this message translates to:
  /// **'A to Z'**
  String get viewAtoZ;

  /// Sort direction for titles, reverse alphabetical. Short: one of two tabs in a row.
  ///
  /// In en, this message translates to:
  /// **'Z to A'**
  String get viewZtoA;

  /// Sort direction for dates, latest first. Short: one of two tabs in a row.
  ///
  /// In en, this message translates to:
  /// **'Newest first'**
  String get viewNewestFirst;

  /// Sort direction for dates, earliest first. Short: one of two tabs in a row.
  ///
  /// In en, this message translates to:
  /// **'Oldest first'**
  String get viewOldestFirst;

  /// Screen reader label of the mark on a note that has changes only on this phone.
  ///
  /// In en, this message translates to:
  /// **'Changes not synced yet'**
  String get noteUnsynced;

  /// Short label in the note’s top bar while its changes haven’t synced yet.
  ///
  /// In en, this message translates to:
  /// **'On this phone'**
  String get noteOnThisPhone;

  /// Toast when the open note was deleted or unshared elsewhere.
  ///
  /// In en, this message translates to:
  /// **'This note is no longer available'**
  String get noteGone;

  /// Toast after a note’s reminder was removed, with an Undo button.
  ///
  /// In en, this message translates to:
  /// **'Reminder removed'**
  String get reminderRemoved;

  /// Toast after an earlier version of the note was restored, with an Undo button.
  ///
  /// In en, this message translates to:
  /// **'Version restored'**
  String get versionRestored;

  /// Toast after a picture was added to a note.
  ///
  /// In en, this message translates to:
  /// **'Picture added'**
  String get attachmentPictureAdded;

  /// Toast after a voice note recorded in the app was added to a note.
  ///
  /// In en, this message translates to:
  /// **'Voice note added'**
  String get attachmentVoiceAdded;

  /// Toast after a picture was added to a note while offline.
  ///
  /// In en, this message translates to:
  /// **'Picture added. It will upload when you’re back online.'**
  String get attachmentPictureAddedOffline;

  /// Toast after a voice note recorded in the app was added to a note while offline.
  ///
  /// In en, this message translates to:
  /// **'Voice note added. It will upload when you’re back online.'**
  String get attachmentVoiceAddedOffline;

  /// Toast when a picture couldn’t be added to a note.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t add the picture'**
  String get attachmentPictureAddFailed;

  /// Toast when a voice note recorded in the app couldn’t be added to a note.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t add the voice note'**
  String get attachmentVoiceAddFailed;

  /// Toast after an audio file from the phone was added to a note.
  ///
  /// In en, this message translates to:
  /// **'Audio file added'**
  String get attachmentAudioAdded;

  /// Toast after an audio file from the phone was added to a note while offline.
  ///
  /// In en, this message translates to:
  /// **'Audio file added. It will upload when you’re back online.'**
  String get attachmentAudioAddedOffline;

  /// Toast when an audio file from the phone couldn’t be added to a note.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t add the audio file'**
  String get attachmentAudioAddFailed;

  /// Error toast when a picture, voice note or audio file is bigger than the server takes, so it isn’t added to the note.
  ///
  /// In en, this message translates to:
  /// **'Can’t add files over 50 MB.'**
  String get attachmentTooBig;

  /// Toast after an audio file was removed from a note, with an Undo button.
  ///
  /// In en, this message translates to:
  /// **'Audio file deleted'**
  String get attachmentAudioDeleted;

  /// Toast when the person plays an audio file that hasn’t downloaded while offline.
  ///
  /// In en, this message translates to:
  /// **'This audio file will play when you’re back online'**
  String get audioFileOffline;

  /// Placeholder of the note title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get noteTitleHint;

  /// Section label in the view options sheet for the sort direction.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get viewOrder;

  /// Spoken hint on a checklist item that can be dragged.
  ///
  /// In en, this message translates to:
  /// **'Drag to reorder'**
  String get editorDragHint;

  /// Spoken name of the slash menu.
  ///
  /// In en, this message translates to:
  /// **'Insert'**
  String get slashMenuLabel;

  /// Shown in the slash menu when nothing matches.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get slashNoResults;

  /// Section label for note background colors.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get noteColor;

  /// Line on a note card that stands in for the checked items of a checklist.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 done} other{{count} done}}'**
  String cardChecked(int count);

  /// Line on a note card when every item of a checklist is checked.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{All 1 done} other{All {count} done}}'**
  String cardAllChecked(int count);

  /// Title of the sheet that opens over another app when something is shared to Anchor; it names the note the sheet makes.
  ///
  /// In en, this message translates to:
  /// **'New note'**
  String get shareSheetTitle;

  /// Spoken label of a tag in the share sheet; tapping it adds the tag to the new note or takes it off.
  ///
  /// In en, this message translates to:
  /// **'Tag {name}'**
  String shareTag(String name);

  /// Shown in the sheet that opens when something is shared to Anchor from another app while no one is signed in.
  ///
  /// In en, this message translates to:
  /// **'Sign in to Anchor to save what you share.'**
  String get shareSignIn;

  /// Button in that sheet, beside Cancel, that opens the app to sign in.
  ///
  /// In en, this message translates to:
  /// **'Open Anchor'**
  String get shareOpenApp;

  /// Shown in the share sheet when what another app shared has nothing Anchor can keep.
  ///
  /// In en, this message translates to:
  /// **'There’s nothing here that Anchor can save.'**
  String get shareNothing;

  /// Shown below the new note in the share sheet when some shared files can’t come in, for mixed or unknown reasons.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file couldn’t be added.} other{{count} files couldn’t be added.}}'**
  String shareNotAdded(int count);

  /// Shown below the new note in the share sheet when shared files are of a kind Anchor doesn’t keep, such as a video or a PDF.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file can’t be added. Anchor adds pictures and audio.} other{{count} files can’t be added. Anchor adds pictures and audio.}}'**
  String shareUnsupported(int count);

  /// Shown below the new note in the share sheet when shared files are larger than a note’s file limit.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file is over 50 MB, so it can’t be added.} other{{count} files are over 50 MB, so they can’t be added.}}'**
  String shareTooBig(int count);

  /// Shown below the new note in the share sheet when more than 20 files were shared at once.
  ///
  /// In en, this message translates to:
  /// **'Only the first 20 files are added.'**
  String get shareOverLimit;

  /// Spoken label of the small x on a picture or audio file in the share sheet; it leaves that file out of the new note.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}'**
  String shareRemoveItem(String name);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
