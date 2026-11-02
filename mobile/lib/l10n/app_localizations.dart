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

  /// Title of the first page, where the person enters their server address. Ends with the app's name, Anchor+; the trailing + is drawn as an animated plus.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Anchor+'**
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

  /// Label of the Appearance setting that picks the app's colors (Anchor, Nord, Dracula and so on).
  ///
  /// In en, this message translates to:
  /// **'Color scheme'**
  String get settingsColorScheme;

  /// Under the Color scheme setting while the Lo-fi style is on, which ignores the scheme. Lo-fi is the style's name.
  ///
  /// In en, this message translates to:
  /// **'Lo-fi draws in pencil grays, whatever the scheme.'**
  String get settingsColorSchemeLofi;

  /// Name of the app's own color scheme, listed with Nord, Dracula and others. The app's name.
  ///
  /// In en, this message translates to:
  /// **'Anchor+'**
  String get colorSchemeAnchor;

  /// Label of the Appearance setting where colors pasted as JSON override the color scheme's.
  ///
  /// In en, this message translates to:
  /// **'Custom theme'**
  String get settingsCustomTheme;

  /// Value of the Custom theme setting while no custom theme is applied.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get settingsCustomThemeOff;

  /// Value of the Custom theme setting while an unnamed custom theme is applied.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get settingsCustomThemeOn;

  /// Under the Custom theme setting while the Lo-fi style is on, which ignores custom colors. Lo-fi is the style's name.
  ///
  /// In en, this message translates to:
  /// **'Lo-fi keeps its pencil grays, so the custom theme waits for another style.'**
  String get settingsCustomThemeLofi;

  /// Explains the Custom theme sheet. JSON is a text format; light and dark are the app's two modes.
  ///
  /// In en, this message translates to:
  /// **'Paste a theme as JSON: colors for light, dark or both. Anything left out keeps the color scheme\'s color. Kept on this device; the same JSON works on the web.'**
  String get customThemeHelp;

  /// Accessibility label of the text box where a custom theme is pasted as JSON.
  ///
  /// In en, this message translates to:
  /// **'Theme JSON'**
  String get customThemeJsonLabel;

  /// Button that applies the pasted custom theme.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get customThemeApply;

  /// Button that removes the custom theme and goes back to the color scheme's colors.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get customThemeReset;

  /// Button that puts the colors in use now, as JSON, in the text box and on the clipboard, to start a custom theme from.
  ///
  /// In en, this message translates to:
  /// **'Copy current theme as JSON'**
  String get customThemeCopy;

  /// Message after a custom theme is applied.
  ///
  /// In en, this message translates to:
  /// **'Custom theme applied'**
  String get customThemeApplied;

  /// Message after a custom theme with a name is applied.
  ///
  /// In en, this message translates to:
  /// **'Custom theme “{name}” applied'**
  String customThemeAppliedNamed(String name);

  /// Message after the custom theme is reset.
  ///
  /// In en, this message translates to:
  /// **'Custom theme removed'**
  String get customThemeRemoved;

  /// The Copy current theme as JSON button once it has put the colors in use on the clipboard.
  ///
  /// In en, this message translates to:
  /// **'Current theme copied as JSON'**
  String get customThemeCopied;

  /// A pasted custom theme isn't JSON. detail is the parser's own (English) explanation.
  ///
  /// In en, this message translates to:
  /// **'Not valid JSON: {detail}'**
  String customThemeNotJson(String detail);

  /// A pasted custom theme is JSON but not an object. Keep "light" and "dark" as they are: they are JSON keys.
  ///
  /// In en, this message translates to:
  /// **'The theme must be a JSON object with \"light\" or \"dark\" colors'**
  String get customThemeNotObject;

  /// A key in a pasted custom theme isn't one the app knows. key and expected are JSON keys, keep them as they are.
  ///
  /// In en, this message translates to:
  /// **'{key}: unknown key; expected one of {expected}'**
  String customThemeUnknownKey(String key, String expected);

  /// Like customThemeUnknownKey, with the key that was likely meant.
  ///
  /// In en, this message translates to:
  /// **'{key}: unknown key (did you mean \"{guess}\"?); expected one of {expected}'**
  String customThemeUnknownKeyGuess(String key, String guess, String expected);

  /// The "name" of a pasted custom theme isn't text. Keep "name" as it is: it's a JSON key.
  ///
  /// In en, this message translates to:
  /// **'name: must be a string'**
  String get customThemeNameNotText;

  /// A pasted custom theme's light or dark part isn't a JSON object. mode is the JSON key, light or dark.
  ///
  /// In en, this message translates to:
  /// **'{mode}: must be an object of colors'**
  String customThemeModeNotObject(String mode);

  /// A color in a pasted custom theme can't be read. key is the JSON key; value is what was given. Keep #rgb, #rrggbb and #rrggbbaa as they are.
  ///
  /// In en, this message translates to:
  /// **'{key}: {value} is not a color; use #rgb, #rrggbb or #rrggbbaa'**
  String customThemeNotAColor(String key, String value);

  /// A pasted custom theme has neither light nor dark colors. Keep "light" and "dark" as they are: they are JSON keys.
  ///
  /// In en, this message translates to:
  /// **'Give at least one of \"light\" or \"dark\"'**
  String get customThemeNoMode;

  /// Label of the Appearance setting that changes the app's look: corners, outlines, shadows and font.
  ///
  /// In en, this message translates to:
  /// **'Style'**
  String get settingsStyle;

  /// The style that keeps the app as designed.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get styleDefault;

  /// Under the Default style. Anchor is the app's name.
  ///
  /// In en, this message translates to:
  /// **'Anchor as designed'**
  String get styleDefaultHelp;

  /// A style imitating real materials: paper, linen and soft shadows.
  ///
  /// In en, this message translates to:
  /// **'Skeuomorphism'**
  String get styleSkeuomorphism;

  /// Under the Skeuomorphism style.
  ///
  /// In en, this message translates to:
  /// **'Paper, linen and depth'**
  String get styleSkeuomorphismHelp;

  /// A style with thick ink outlines, hard shadows and square corners.
  ///
  /// In en, this message translates to:
  /// **'Neo-Brutalism'**
  String get styleNeoBrutalism;

  /// Under the Neo-Brutalism style.
  ///
  /// In en, this message translates to:
  /// **'Thick outlines, hard shadows'**
  String get styleNeoBrutalismHelp;

  /// A style that draws the app like a pencil sketch, in grays and handwriting.
  ///
  /// In en, this message translates to:
  /// **'Lo-fi'**
  String get styleLofi;

  /// Under the Lo-fi style.
  ///
  /// In en, this message translates to:
  /// **'A pencil-and-paper prototype'**
  String get styleLofiHelp;

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

  /// Settings section heading for the reminder times of day and the first day of the week.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get settingsReminders;

  /// Settings row: the time of day used by the Tomorrow, weekend, next week and next month reminder choices.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get settingsMorning;

  /// Settings row: the time of day the This afternoon reminder choice uses.
  ///
  /// In en, this message translates to:
  /// **'Afternoon'**
  String get settingsAfternoon;

  /// Settings row: the time of day the This evening reminder choice uses.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get settingsEvening;

  /// Settings row: the time of day the Tonight reminder choice uses.
  ///
  /// In en, this message translates to:
  /// **'Night'**
  String get settingsNight;

  /// Settings label above the choice of weekday the Next week reminder choice lands on.
  ///
  /// In en, this message translates to:
  /// **'Week starts on'**
  String get settingsWeekStart;

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

  /// Switch in Settings › Editor: a deleted note's card burns away (a short fiery dissolve) where it stood. A setting on this device.
  ///
  /// In en, this message translates to:
  /// **'Burn deleted notes'**
  String get settingsBurnDeleted;

  /// Help under the Burn deleted notes switch.
  ///
  /// In en, this message translates to:
  /// **'A deleted note burns away where it stood. Off, it just goes.'**
  String get settingsBurnDeletedHelp;

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

  /// Section label in Settings for this fork's updates from its GitHub releases (Android release builds only).
  ///
  /// In en, this message translates to:
  /// **'Updates'**
  String get settingsUpdates;

  /// Row in Settings › Updates that looks for a newer release now.
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get settingsCheckForUpdates;

  /// Subtitle of Check for updates while it looks for a newer release.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get settingsUpdateChecking;

  /// Subtitle of Check for updates: the installed build number and the GitHub repository it updates from.
  ///
  /// In en, this message translates to:
  /// **'This is build {build} of {repository}'**
  String settingsUpdateBuild(int build, String repository);

  /// Switch in Settings › Updates.
  ///
  /// In en, this message translates to:
  /// **'Check automatically'**
  String get settingsCheckAutomatically;

  /// Help under the Check automatically switch.
  ///
  /// In en, this message translates to:
  /// **'Look for a new release when Anchor starts'**
  String get settingsCheckAutomaticallyHelp;

  /// Switch in Settings › Updates: also offer release candidates, before they are released to everyone.
  ///
  /// In en, this message translates to:
  /// **'Receive preview releases'**
  String get settingsPreviewReleases;

  /// Help under the Receive preview releases switch: candidates are only offered when the server runs the fork's preview Docker image (ghcr.io/…/anchor:fork-preview).
  ///
  /// In en, this message translates to:
  /// **'Release candidates, when your server runs the :fork-preview image'**
  String get settingsPreviewReleasesHelp;

  /// Section label in Settings for search options. Shown only when the server offers picture search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get settingsSearch;

  /// Switch in Settings › Search: searches then also find notes whose pictures look like what was typed (an AI model on the user's own server).
  ///
  /// In en, this message translates to:
  /// **'Find pictures by what they show'**
  String get settingsPictureSearch;

  /// Help under the Find pictures by what they show switch. The examples may be translated.
  ///
  /// In en, this message translates to:
  /// **'Search for “sunset by the sea” or “receipt” and find notes with such pictures, in most languages. Your server downloads a model once (about 380 MB) and looks at each picture; nothing leaves your server.'**
  String get settingsPictureSearchHelp;

  /// Picture search status in Settings while the server downloads its model.
  ///
  /// In en, this message translates to:
  /// **'Downloading the picture model… {percent}%'**
  String pictureSearchDownloading(int percent);

  /// Picture search status in Settings when the server could not download its model.
  ///
  /// In en, this message translates to:
  /// **'The picture model couldn’t be downloaded. Turn it off and on to try again.'**
  String get pictureSearchFailed;

  /// Picture search status in Settings while the server goes through the user's pictures.
  ///
  /// In en, this message translates to:
  /// **'Looking at your pictures… {indexed} of {total}'**
  String pictureSearchIndexing(int indexed, int total);

  /// Picture search status in Settings once every picture of the user's notes has been looked at.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Your pictures will be searchable as you add them.} =1{Your picture is ready to search.} other{All {count} pictures are ready to search.}}'**
  String pictureSearchReady(int count);

  /// Error snackbar when turning picture search on or off in Settings fails (e.g. offline).
  ///
  /// In en, this message translates to:
  /// **'Couldn’t change picture search'**
  String get pictureSearchChangeFailed;

  /// Title of the banner above the notes and of the sheet, when a newer release of the app is out.
  ///
  /// In en, this message translates to:
  /// **'Update available'**
  String get updateAvailable;

  /// Button in the Update available banner above the notes that opens the update sheet.
  ///
  /// In en, this message translates to:
  /// **'See what’s new'**
  String get updateSeeWhatsNew;

  /// Heading over the list of changes in the update sheet.
  ///
  /// In en, this message translates to:
  /// **'What’s new'**
  String get updateWhatsNew;

  /// Under the update's list of changes, when not all are shown.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{and 1 more} other{and {count} more}}'**
  String updateMoreChanges(int count);

  /// Button in the update sheet, when the download's size is unknown.
  ///
  /// In en, this message translates to:
  /// **'Download and install'**
  String get updateInstall;

  /// Button in the update sheet, with the size of the download.
  ///
  /// In en, this message translates to:
  /// **'Download and install ({megabytes} MB)'**
  String updateInstallSize(int megabytes);

  /// The update sheet's button while the update downloads.
  ///
  /// In en, this message translates to:
  /// **'Downloading… {percent}%'**
  String updateDownloading(int percent);

  /// Button in the update sheet that opens the release's page.
  ///
  /// In en, this message translates to:
  /// **'View the release on GitHub'**
  String get updateViewRelease;

  /// Error when looking for a newer release failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t check for updates'**
  String get updateCheckFailed;

  /// Error in the update sheet when the download failed.
  ///
  /// In en, this message translates to:
  /// **'The update couldn’t be downloaded'**
  String get updateDownloadFailed;

  /// Toast after Check for updates found no newer release.
  ///
  /// In en, this message translates to:
  /// **'Anchor is up to date'**
  String get updateUpToDate;

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

  /// Row in Settings that opens a web page to donate to the original author of Anchor (this app, Anchor+, is a fork of it).
  ///
  /// In en, this message translates to:
  /// **'Donate to the original creator'**
  String get settingsSupport;

  /// Under the Donate to the original creator row: a small donation to the author of Anchor, which Anchor+ builds on.
  ///
  /// In en, this message translates to:
  /// **'Buy Anchor’s author a coffee; Anchor+ builds on their work'**
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
  /// **'Anchor+'**
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

  /// Quick reminder choice for the morning time on the same day, once the day has begun.
  ///
  /// In en, this message translates to:
  /// **'Later today'**
  String get reminderLaterToday;

  /// Quick reminder choice for the afternoon time on the same day.
  ///
  /// In en, this message translates to:
  /// **'This afternoon'**
  String get reminderThisAfternoon;

  /// Quick reminder choice for the night time on the same day.
  ///
  /// In en, this message translates to:
  /// **'Tonight'**
  String get reminderTonight;

  /// Quick reminder choice for tomorrow's night time; in the small hours, before the day begins, the coming night.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow night'**
  String get reminderTomorrowNight;

  /// Quick reminder choice for tomorrow's morning time; in the small hours, before the day begins, the coming morning.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow morning'**
  String get reminderTomorrowMorning;

  /// Quick reminder choice for tomorrow's afternoon time; in the small hours, before the day begins, the coming afternoon.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow afternoon'**
  String get reminderTomorrowAfternoon;

  /// Quick reminder choice for tomorrow's evening time; in the small hours, before the day begins, the coming evening.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow evening'**
  String get reminderTomorrowEvening;

  /// Quick reminder choice for the evening time on the same day.
  ///
  /// In en, this message translates to:
  /// **'This evening'**
  String get reminderThisEvening;

  /// Quick reminder choice for the first day of next week, in the morning.
  ///
  /// In en, this message translates to:
  /// **'Next week'**
  String get reminderNextWeek;

  /// Quick reminder choice for the coming Saturday, or Sunday when it is Saturday.
  ///
  /// In en, this message translates to:
  /// **'On the weekend'**
  String get reminderWeekend;

  /// Quick reminder choice for the first day of next month, in the morning.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get reminderNextMonth;

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

  /// Button on a reminder notification: clears a one-time reminder without opening the app.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get reminderDone;

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

  /// Screen reader label of the grip beside a tag in the drawer, dragged to put the tag elsewhere in the list.
  ///
  /// In en, this message translates to:
  /// **'Move {name}'**
  String tagMove(String name);

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

  /// Round button that shows two screens down the notes list; it scrolls back to the top.
  ///
  /// In en, this message translates to:
  /// **'Back to top'**
  String get notesBackToTop;

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

  /// Heading of the share sheet’s section for the note’s share link.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get shareLink;

  /// Row in the share sheet for the note’s share link.
  ///
  /// In en, this message translates to:
  /// **'Anyone with the link'**
  String get shareLinkAnyone;

  /// Access level of a share link that is turned off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get shareLinkOff;

  /// Under “Anyone with the link” while the note has no link.
  ///
  /// In en, this message translates to:
  /// **'Only people you add can open it'**
  String get shareLinkOffHint;

  /// Under “Anyone with the link” while the link can only view.
  ///
  /// In en, this message translates to:
  /// **'Anyone with the link can read it, without an account'**
  String get shareLinkViewHint;

  /// Under “Anyone with the link” while the link can edit.
  ///
  /// In en, this message translates to:
  /// **'Anyone with the link can change the title and text'**
  String get shareLinkEditHint;

  /// Accessibility label of the menu that picks what the share link allows.
  ///
  /// In en, this message translates to:
  /// **'Access with the link'**
  String get shareLinkAccess;

  /// Accessibility label of the button that opens the share link’s access menu.
  ///
  /// In en, this message translates to:
  /// **'{access}. Change access with the link'**
  String shareLinkChangeAccess(String access);

  /// Button that copies the note’s share link.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get shareLinkCopy;

  /// Button that sends the note’s share link with another app.
  ///
  /// In en, this message translates to:
  /// **'Send link'**
  String get shareLinkShareIt;

  /// Toast after copying the note’s share link.
  ///
  /// In en, this message translates to:
  /// **'Link copied'**
  String get shareLinkCopied;

  /// Toast after turning on the note’s share link, which also copies it.
  ///
  /// In en, this message translates to:
  /// **'Link made and copied'**
  String get shareLinkMade;

  /// Toast after turning off the note’s share link.
  ///
  /// In en, this message translates to:
  /// **'Link turned off; it no longer opens the note'**
  String get shareLinkTurnedOff;

  /// Toast after making the share link view only.
  ///
  /// In en, this message translates to:
  /// **'Anyone with the link can now view'**
  String get shareLinkNowCanView;

  /// Toast after letting the share link edit.
  ///
  /// In en, this message translates to:
  /// **'Anyone with the link can now edit'**
  String get shareLinkNowCanEdit;

  /// Toast when turning the share link on or off, or changing it, failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t change the link'**
  String get shareLinkFailed;

  /// Notice in the share sheet when the note’s share link didn’t load.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load the note’s link.'**
  String get shareLinkLoadFailed;

  /// Small line in the share sheet while the note has a share link and no people.
  ///
  /// In en, this message translates to:
  /// **'Anyone with the link can open it.'**
  String get shareLinkOpens;

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

  /// Selection bar action: gives every selected note one color or pattern. Short: one of five actions in a row.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get actionColor;

  /// Note menu action: hands the note to another app as text, through the system share sheet.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get actionSend;

  /// Note menu action: makes a new note of your own with the same title, text, color, tags and attachments, then opens it.
  ///
  /// In en, this message translates to:
  /// **'Make a copy'**
  String get actionMakeCopy;

  /// Toast when Send is chosen on a note with no title and no text.
  ///
  /// In en, this message translates to:
  /// **'There’s nothing to send yet'**
  String get noteSendEmpty;

  /// Toast shown when the copy made with Make a copy opens.
  ///
  /// In en, this message translates to:
  /// **'This is your copy'**
  String get noteCopyMade;

  /// Error toast when Make a copy fails, usually because the app is offline.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t make a copy. It needs a connection to the server.'**
  String get noteCopyFailed;

  /// Toast after giving the selected notes a color or pattern; it has an Undo button.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Color changed on 1 note} other{Color changed on {count} notes}}'**
  String notesColorChanged(int count);

  /// Toast after giving the selected notes a color, when some are shared with you only to view and could not change.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Color changed. 1 note shared with you to view stays as it was} other{Color changed. {count} notes shared with you to view stay as they were}}'**
  String notesColorChangedExcept(int count);

  /// Toast when none of the selected notes could get the color, because all are shared with you only to view.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{This note is shared with you to view, so its color can’t change} other{These notes are shared with you to view, so their color can’t change}}'**
  String notesColorUnchanged(int count);

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

  /// Item in a note's More menu that sorts the items of each of the note's checklists alphabetically, sub-items moving with their item, with Undo. Checked items stay at the bottom when Move checked items to bottom is on. Shown for notes with a checklist, dimmed while it has fewer than two items.
  ///
  /// In en, this message translates to:
  /// **'Sort A to Z'**
  String get actionSortByName;

  /// Item in a note's More menu that deletes every checked item from the note's checklists, with Undo. Shown for notes with a checklist, dimmed while no item is checked.
  ///
  /// In en, this message translates to:
  /// **'Delete checked items'**
  String get actionDeleteChecked;

  /// Item in a note's More menu that turns every written line of the note into an unchecked checklist item, like Google Keep. Shown while some line is not a checklist item.
  ///
  /// In en, this message translates to:
  /// **'Show checkboxes'**
  String get actionShowCheckboxes;

  /// Item in a note's More menu that turns every checklist item of the note back into a plain line, like Google Keep. Shown in place of Show checkboxes when every line is a checklist item.
  ///
  /// In en, this message translates to:
  /// **'Hide checkboxes'**
  String get actionHideCheckboxes;

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

  /// Toast after Show checkboxes in a note's More menu, with an Undo button. count is how many lines became checklist items.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Checkbox added} other{{count} checkboxes added}}'**
  String checkboxesShown(int count);

  /// Toast after Hide checkboxes in a note's More menu, with an Undo button. count is how many checklist items became plain lines.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Checkbox removed} other{{count} checkboxes removed}}'**
  String checkboxesHidden(int count);

  /// Toast after Sort A to Z in a note's More menu, with an Undo button. The items are checklist items in the note.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Item sorted A to Z} other{{count} items sorted A to Z}}'**
  String itemsSortedByName(int count);

  /// Toast after Sort A to Z in a note's More menu when every checklist in the note was in alphabetical order already, so nothing changed.
  ///
  /// In en, this message translates to:
  /// **'Already in A to Z order'**
  String get itemsAlreadySorted;

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

  /// Button on the toast after a note opened from the trash was restored; it goes to the list the note is kept in and shows its card there.
  ///
  /// In en, this message translates to:
  /// **'Follow it'**
  String get noteRestoredFollow;

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

  /// Error message when moving notes to the trash or deleting them failed; their cards come back on the list.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Couldn’t delete the note} other{Couldn’t delete the notes}}'**
  String notesDeleteFailed(int count);

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

  /// Button in the notes list's top bar that starts choosing several notes, since holding a card drags it.
  ///
  /// In en, this message translates to:
  /// **'Select notes'**
  String get listSelectNotes;

  /// Title of the sheet for layout and sort order, and the button that opens it.
  ///
  /// In en, this message translates to:
  /// **'View options'**
  String get listViewOptions;

  /// Toast after Android's Back on the notes list: a second Back while it shows closes the app.
  ///
  /// In en, this message translates to:
  /// **'Press back again to exit'**
  String get listPressBackAgainToExit;

  /// Hint inside the empty search field while the list shows only one tag.
  ///
  /// In en, this message translates to:
  /// **'Search #{tag}'**
  String searchTag(String tag);

  /// Card title on the notes list when this device's edits replaced edits made to the same note elsewhere while offline.
  ///
  /// In en, this message translates to:
  /// **'Changed in two places'**
  String get syncOverwroteLead;

  /// Card text when this device's edits replaced edits made elsewhere to one note; tapping opens its version history.
  ///
  /// In en, this message translates to:
  /// **'Your changes to “{title}” replaced ones made elsewhere. Tap to see them in its history.'**
  String syncOverwroteText(String title);

  /// Card text when this device's edits replaced edits made elsewhere to several notes; tapping opens the first one's version history.
  ///
  /// In en, this message translates to:
  /// **'Your changes to {count} notes replaced ones made elsewhere. Tap to see the first one\'s history.'**
  String syncOverwroteManyText(int count);

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

  /// Empty-screen help when a regex search can't be read as a regular expression and the text as typed finds no notes.
  ///
  /// In en, this message translates to:
  /// **'This isn\'t a valid regular expression, so it was looked for as typed. Check the pattern, or turn off Regular expression.'**
  String get searchRegexInvalidHelp;

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

  /// Menu item, shown by holding the New note button, that starts a new note as a checklist.
  ///
  /// In en, this message translates to:
  /// **'New list'**
  String get noteNewList;

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

  /// Screen reader label of the button that adds a picture, recording or other file to a note.
  ///
  /// In en, this message translates to:
  /// **'Add a picture, recording or file'**
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

  /// Screen reader label of the filter button in the search field, while no filter is on.
  ///
  /// In en, this message translates to:
  /// **'Filter notes'**
  String get searchFilter;

  /// Screen reader label of the filter button in the search field, while filters are on.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Filter notes, 1 filter on} other{Filter notes, {count} filters on}}'**
  String searchFiltersOn(int count);

  /// Empty-screen title when the search filters (with no words typed) leave no notes.
  ///
  /// In en, this message translates to:
  /// **'No notes match'**
  String get searchNoMatches;

  /// Empty-screen help when the search filters leave no notes.
  ///
  /// In en, this message translates to:
  /// **'Turn off a filter to see more notes.'**
  String get searchNoMatchesHelp;

  /// Title of the sheet that narrows the list to notes with pictures, a checklist, a reminder, a color or pattern, or a tag.
  ///
  /// In en, this message translates to:
  /// **'Filter notes'**
  String get filterTitle;

  /// Subtitle of the filter sheet while no filter is on.
  ///
  /// In en, this message translates to:
  /// **'Show only notes that match'**
  String get filterHelp;

  /// Subtitle of the filter sheet: how many filters are on.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 filter on} other{{count} filters on}}'**
  String filterCount(int count);

  /// Title of the page that plays back a debug recording (debug mode: two fingers held still for 3 s film the app for a bug report).
  ///
  /// In en, this message translates to:
  /// **'Debug recording'**
  String get debugRecordingTitle;

  /// The camera button in the top left corner while debug mode films the app; it stops filming.
  ///
  /// In en, this message translates to:
  /// **'Stop debug recording'**
  String get debugStopRecording;

  /// Throws the debug recording away and closes the player.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get debugDiscard;

  /// Dialog title when leaving the debug player with problems marked.
  ///
  /// In en, this message translates to:
  /// **'Discard recording?'**
  String get debugDiscardTitle;

  /// Dialog message when discarding a debug recording.
  ///
  /// In en, this message translates to:
  /// **'The recording and the problems you marked will be lost.'**
  String get debugDiscardMessage;

  /// Bar button in the debug player that shares the report file (an MP4) with another app.
  ///
  /// In en, this message translates to:
  /// **'Share file'**
  String get debugShareFile;

  /// Plays the debug recording.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get debugPlay;

  /// Pauses the debug recording.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get debugPause;

  /// Button in the debug player that marks a problem at the current moment of the recording.
  ///
  /// In en, this message translates to:
  /// **'Problem here ({time})'**
  String debugProblemHere(String time);

  /// Title of the sheet that asks what was expected at a moment of the debug recording.
  ///
  /// In en, this message translates to:
  /// **'Problem at {time}'**
  String debugProblemAt(String time);

  /// Label of the field for what should have happened at a marked problem.
  ///
  /// In en, this message translates to:
  /// **'Expectation'**
  String get debugExpectation;

  /// Hint in the Expectation field.
  ///
  /// In en, this message translates to:
  /// **'What should have happened?'**
  String get debugExpectationHint;

  /// Adds the marked problem to the debug report.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get debugAdd;

  /// Shown for a marked problem whose expectation was left empty.
  ///
  /// In en, this message translates to:
  /// **'(no expectation)'**
  String get debugNoExpectation;

  /// Shown in the debug player before any problem is marked.
  ///
  /// In en, this message translates to:
  /// **'Move to where it went wrong and tap Problem here.\nThe video greys out text and pictures; the report leaves out what you wrote.'**
  String get debugProblemsHint;

  /// Saves the debug report and opens a new GitHub issue to attach it to.
  ///
  /// In en, this message translates to:
  /// **'Create issue'**
  String get debugCreateIssue;

  /// Title of the save dialog for the debug report file.
  ///
  /// In en, this message translates to:
  /// **'Save debug report'**
  String get debugSaveReport;

  /// Read out while the debug report file is being built.
  ///
  /// In en, this message translates to:
  /// **'Building the report…'**
  String get debugBuilding;

  /// Toast when sharing the debug report failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t share the report'**
  String get debugShareFailed;

  /// Toast when the browser could not open GitHub’s new-issue page.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t open GitHub'**
  String get debugGithubFailed;

  /// Toast when the debug report file could not be built or saved.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t build the report'**
  String get debugBuildFailed;

  /// Selection bar action: merges the picked notes into the first one picked.
  ///
  /// In en, this message translates to:
  /// **'Merge'**
  String get actionMerge;

  /// Toast after merging notes, with Undo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Merged 1 note} other{Merged {count} notes}}'**
  String notesMerged(int count);

  /// Toast after merging notes when some of the merged-in notes had pictures, which stay with them in the trash.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Merged 1 note; pictures stay with their notes in the trash} other{Merged {count} notes; pictures stay with their notes in the trash}}'**
  String notesMergedKeptPictures(int count);

  /// Toast when Merge is tapped with only one note picked.
  ///
  /// In en, this message translates to:
  /// **'Pick two notes or more to merge'**
  String get notesMergePickTwo;

  /// Toast when a picked note is shared with the person rather than theirs.
  ///
  /// In en, this message translates to:
  /// **'Only your own notes can be merged'**
  String get notesMergeOwnOnly;

  /// Toast when a picked note is frozen (it can’t be changed or deleted).
  ///
  /// In en, this message translates to:
  /// **'Unfreeze the frozen notes first, then merge them'**
  String get notesMergeFrozen;

  /// Toast when a picked note is locked and hasn’t been opened since the phone was locked.
  ///
  /// In en, this message translates to:
  /// **'Open the locked notes first, then merge them'**
  String get notesMergeLocked;

  /// Toast when merging failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t merge the notes'**
  String get notesMergeFailed;

  /// Filter choice in the filter sheet's Has section: only notes holding something that looks like a secret (a key, token, id or password).
  ///
  /// In en, this message translates to:
  /// **'Secrets'**
  String get filterSecrets;

  /// Under the Secrets filter: what it looks for in a note's title, text and pictures' text.
  ///
  /// In en, this message translates to:
  /// **'Keys, tokens, ids and passwords'**
  String get filterSecretsHelp;

  /// Section label in the filter sheet, above Regular expression and Match case: how the search reads what is typed. Not filters; they stay on after the search ends.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get filterSearch;

  /// Search option: what is typed in the search box is read as a regular expression.
  ///
  /// In en, this message translates to:
  /// **'Regular expression'**
  String get filterRegex;

  /// Search option: upper and lower case letters must match exactly.
  ///
  /// In en, this message translates to:
  /// **'Match case'**
  String get filterMatchCase;

  /// Search box hint while the search reads what is typed as a regular expression (set in the filter sheet).
  ///
  /// In en, this message translates to:
  /// **'Search with a regex'**
  String get searchHintRegex;

  /// Search box hint while the search matches upper and lower case exactly (set in the filter sheet).
  ///
  /// In en, this message translates to:
  /// **'Search, matching case'**
  String get searchHintMatchCase;

  /// Search box hint while the search reads a regular expression and matches case (both set in the filter sheet).
  ///
  /// In en, this message translates to:
  /// **'Regex, matching case'**
  String get searchHintRegexMatchCase;

  /// Read out (and shown as a hint) on the search box's red regex icon while what is typed can't be read as a regular expression yet.
  ///
  /// In en, this message translates to:
  /// **'Not a complete regular expression yet: looking for the text as typed'**
  String get searchRegexIncomplete;

  /// Section label in the filter sheet, above Pictures, Checklists and Reminders: notes that have them.
  ///
  /// In en, this message translates to:
  /// **'Has'**
  String get filterHas;

  /// Filter choice: only notes with pictures.
  ///
  /// In en, this message translates to:
  /// **'Pictures'**
  String get filterPictures;

  /// Filter choice: only notes with checklist items.
  ///
  /// In en, this message translates to:
  /// **'Checklists'**
  String get filterChecklists;

  /// Filter choice: only notes with a reminder.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get filterReminders;

  /// Section label in the filter sheet above the tags; picking one shows only notes with it.
  ///
  /// In en, this message translates to:
  /// **'Tag'**
  String get filterTag;

  /// Button in the filter sheet that turns every filter off.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get filterClear;

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

  /// Slash menu item that types today’s date at the caret, like “Oct 28th 2026”. Typing /date and a space does the same.
  ///
  /// In en, this message translates to:
  /// **'Today’s date'**
  String get slashDate;

  /// Search words for the slash menu, separated by spaces. Keep the English words and add your own.
  ///
  /// In en, this message translates to:
  /// **'date today now day'**
  String get slashWordsDate;

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

  /// Editor toolbar button (in Aa, with words picked) and the sheet it opens: the words' highlight, text color and font.
  ///
  /// In en, this message translates to:
  /// **'Color and font'**
  String get toolTextStyle;

  /// In the Color and font sheet: no highlight.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get textStyleNone;

  /// In the Color and font sheet: the note's own text color, or its own font.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get textStyleDefault;

  /// Section of the Color and font sheet with colors for the words themselves.
  ///
  /// In en, this message translates to:
  /// **'Text color'**
  String get textStyleColor;

  /// Section of the Color and font sheet that sets the words' font.
  ///
  /// In en, this message translates to:
  /// **'Font'**
  String get textStyleFont;

  /// Font choice for some words in a note (Aa › Color and font): a casual, comic-book handwriting font (Comic Neue, drawn like Comic Sans). Shown written in that font.
  ///
  /// In en, this message translates to:
  /// **'Comic Sans'**
  String get textFontComic;

  /// Font choice for some words in a note (Aa › Color and font): a font that looks handwritten. Shown written in that font.
  ///
  /// In en, this message translates to:
  /// **'Handwriting'**
  String get textFontHandwriting;

  /// Font choice for some words in a note (Aa › Color and font): a font that looks typed on a typewriter. Shown written in that font.
  ///
  /// In en, this message translates to:
  /// **'Typewriter'**
  String get textFontTypewriter;

  /// Font choice for some words in a note (Aa › Color and font): a sans-serif font with rounded ends. Shown written in that font.
  ///
  /// In en, this message translates to:
  /// **'Rounded'**
  String get textFontRounded;

  /// Font choice for some words in a note (Aa › Color and font): a slab-serif font (thick, block-like serifs). Shown written in that font.
  ///
  /// In en, this message translates to:
  /// **'Slab'**
  String get textFontSlab;

  /// Font choice for some words in a note (Aa › Color and font): a font that looks drawn with a felt marker. Shown written in that font.
  ///
  /// In en, this message translates to:
  /// **'Marker'**
  String get textFontMarker;

  /// Swatch in the Color and font sheet that opens a color picker for the highlight, and that picker's title.
  ///
  /// In en, this message translates to:
  /// **'Custom highlight'**
  String get textStyleCustomHighlight;

  /// Swatch in the Color and font sheet that opens a color picker for the text, and that picker's title.
  ///
  /// In en, this message translates to:
  /// **'Custom text color'**
  String get textStyleCustomColor;

  /// Color name, for text.
  ///
  /// In en, this message translates to:
  /// **'Gray'**
  String get colorGray;

  /// Slider in the color picker: which color it is.
  ///
  /// In en, this message translates to:
  /// **'Hue'**
  String get colorPickerHue;

  /// Slider in the color picker: how vivid the color is.
  ///
  /// In en, this message translates to:
  /// **'Saturation'**
  String get colorPickerSaturation;

  /// Slider in the color picker: how light the color is.
  ///
  /// In en, this message translates to:
  /// **'Lightness'**
  String get colorPickerLightness;

  /// Under the hex field of the color picker when what's typed isn't a color. Keep #rgb and #rrggbb as they are.
  ///
  /// In en, this message translates to:
  /// **'Use #rgb or #rrggbb'**
  String get colorPickerBadHex;

  /// Button of the color picker that uses the color.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get colorPickerApply;

  /// Screen reader label of the toolbar button that removes the color mark from text.
  ///
  /// In en, this message translates to:
  /// **'Remove highlight'**
  String get toolRemoveHighlight;

  /// Screen reader label of the toolbar button that takes bold, italic, underline, strikethrough, highlight, color and font off the selected words.
  ///
  /// In en, this message translates to:
  /// **'Clear formatting'**
  String get toolClearFormatting;

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

  /// Entry in the text selection menu (next to Cut, Copy, Paste) when the clipboard holds a picture: places it in the note's text at the caret.
  ///
  /// In en, this message translates to:
  /// **'Paste picture'**
  String get editorPastePicture;

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

  /// Option that picks one or more photos from the phone’s photo library to add to the note.
  ///
  /// In en, this message translates to:
  /// **'Choose photos'**
  String get addChoosePhoto;

  /// Option that starts recording a voice note.
  ///
  /// In en, this message translates to:
  /// **'Record audio'**
  String get addRecordAudio;

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

  /// Screen reader name of the download button on a voice note or audio file in a note.
  ///
  /// In en, this message translates to:
  /// **'Save {name}'**
  String audioSave(String name);

  /// Title of the system dialog for saving a voice note or audio file to the phone.
  ///
  /// In en, this message translates to:
  /// **'Save audio'**
  String get audioSaveDialog;

  /// Toast after a voice note or audio file was saved to a file on the phone.
  ///
  /// In en, this message translates to:
  /// **'Saved {name}'**
  String audioSaved(String name);

  /// Toast when a voice note or audio file couldn’t be saved to the phone.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t save the audio'**
  String get audioSaveFailed;

  /// Toast when saving a picture is blocked because the app has no Photos permission.
  ///
  /// In en, this message translates to:
  /// **'Allow access to Photos in Settings to save pictures'**
  String get pictureAllowPhotos;

  /// Button in the picture viewer that puts the picture on the clipboard, to paste into other apps.
  ///
  /// In en, this message translates to:
  /// **'Copy picture'**
  String get pictureCopy;

  /// Toast after Copy picture put the picture on the clipboard.
  ///
  /// In en, this message translates to:
  /// **'Picture copied'**
  String get pictureCopied;

  /// Toast when the picture could not be put on the clipboard.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t copy the picture'**
  String get pictureCopyFailed;

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

  /// Picture viewer button (with picture search on) that shows words for what the picture depicts, each one a search.
  ///
  /// In en, this message translates to:
  /// **'Show detected tags'**
  String get pictureShowTags;

  /// The same button while the detected tags are shown.
  ///
  /// In en, this message translates to:
  /// **'Hide detected tags'**
  String get pictureHideTags;

  /// Accessibility label of the spinner while the server works out what a picture shows.
  ///
  /// In en, this message translates to:
  /// **'Finding tags'**
  String get pictureFindingTags;

  /// Message when the server couldn't say what a picture shows.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t get the tags'**
  String get pictureTagsFailed;

  /// Message when picture search hasn't processed this picture yet, so it has no detected tags.
  ///
  /// In en, this message translates to:
  /// **'This picture hasn’t been looked at yet. Try again soon.'**
  String get pictureTagsNotYet;

  /// Accessibility label of a detected tag in the picture viewer; tapping it searches the notes for the word.
  ///
  /// In en, this message translates to:
  /// **'Search your notes for {tag}'**
  String pictureSearchTag(String tag);

  /// Button in the picture viewer: reads the text in the picture and adds it at the end of the note.
  ///
  /// In en, this message translates to:
  /// **'Grab image text'**
  String get pictureGrabText;

  /// Screen reader label while Grab image text reads the picture.
  ///
  /// In en, this message translates to:
  /// **'Reading the picture’s text'**
  String get pictureReadingText;

  /// Toast after Grab image text put the picture's selected text at the end of the note.
  ///
  /// In en, this message translates to:
  /// **'Text added to the note'**
  String get pictureTextAdded;

  /// Toast when Grab image text finds no text in the picture.
  ///
  /// In en, this message translates to:
  /// **'No text found in this picture'**
  String get pictureNoText;

  /// Error toast when Grab image text fails.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t read this picture'**
  String get pictureTextFailed;

  /// Title of the Grab image text page while no words are selected.
  ///
  /// In en, this message translates to:
  /// **'Select text'**
  String get pictureSelectText;

  /// Title of the Grab image text page: how many of the picture's words are selected.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 word selected} other{{count} words selected}}'**
  String pictureWordsSelected(int count);

  /// Hint under the picture on the Grab image text page, until a word is selected.
  ///
  /// In en, this message translates to:
  /// **'Hold a word and drag to select text, or hold beside it and drag a box'**
  String get pictureSelectHint;

  /// Button on the Grab image text page that puts the selected words at the end of the note.
  ///
  /// In en, this message translates to:
  /// **'Insert in note'**
  String get pictureInsertText;

  /// Toast after Copy on the Grab image text page copied the selected words.
  ///
  /// In en, this message translates to:
  /// **'Text copied'**
  String get pictureTextCopied;

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

  /// Heading, in a search, of the notes the server found by what their pictures show (not by their words), listed after the others with their count. Only for users who turned on picture search in Settings.
  ///
  /// In en, this message translates to:
  /// **'Pictures that may match'**
  String get groupPictureMatches;

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

  /// Section label in the view options sheet for what note cards show.
  ///
  /// In en, this message translates to:
  /// **'Cards'**
  String get viewCards;

  /// Switch in the view options sheet: shows a note's pictures on its card in the notes list.
  ///
  /// In en, this message translates to:
  /// **'Pictures on cards'**
  String get viewCardPictures;

  /// Under the Pictures on cards switch in the view options sheet.
  ///
  /// In en, this message translates to:
  /// **'Show a note’s pictures on its card'**
  String get viewCardPicturesHelp;

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

  /// Note menu and selection bar action: locks the note so it opens only with a fingerprint, PIN, pattern or a tap. Opens a sheet to choose how.
  ///
  /// In en, this message translates to:
  /// **'Lock'**
  String get actionLock;

  /// Note menu action on a locked note: chooses another way to open it (fingerprint, PIN, pattern or a tap).
  ///
  /// In en, this message translates to:
  /// **'Change lock'**
  String get actionChangeLock;

  /// Note menu action on a locked note: the note no longer needs unlocking.
  ///
  /// In en, this message translates to:
  /// **'Remove lock'**
  String get actionRemoveLock;

  /// Title of the sheet that asks how a note opens once locked.
  ///
  /// In en, this message translates to:
  /// **'Lock'**
  String get lockSheetTitle;

  /// Title of the same sheet on a note that is locked already.
  ///
  /// In en, this message translates to:
  /// **'Change lock'**
  String get lockSheetChangeTitle;

  /// Under the title of the lock sheet.
  ///
  /// In en, this message translates to:
  /// **'What opens the note'**
  String get lockSheetSubtitle;

  /// Lock choice: the note opens with the phone's fingerprint or face unlock.
  ///
  /// In en, this message translates to:
  /// **'Fingerprint or face'**
  String get lockKindBiometric;

  /// Under the Fingerprint or face lock choice: the phone's PIN, pattern or password also works.
  ///
  /// In en, this message translates to:
  /// **'Or your phone’s own screen lock'**
  String get lockKindBiometricHelp;

  /// Lock choice: the note opens with the account's note PIN (the same for every note, and on the web).
  ///
  /// In en, this message translates to:
  /// **'PIN'**
  String get lockKindPin;

  /// Under the PIN lock choice.
  ///
  /// In en, this message translates to:
  /// **'One PIN for all your locked notes'**
  String get lockKindPinHelp;

  /// Lock choice: the note opens with the account's note pattern, drawn across 9 dots.
  ///
  /// In en, this message translates to:
  /// **'Pattern'**
  String get lockKindPattern;

  /// Under the Pattern lock choice.
  ///
  /// In en, this message translates to:
  /// **'One pattern for all your locked notes'**
  String get lockKindPatternHelp;

  /// Lock choice: the note's text stays hidden until a tap on Tap to unlock.
  ///
  /// In en, this message translates to:
  /// **'Just a tap'**
  String get lockKindTap;

  /// Under the Just a tap lock choice.
  ///
  /// In en, this message translates to:
  /// **'Hides the note until you tap'**
  String get lockKindTapHelp;

  /// Toast after a note was locked; kind is biometric, pin, pattern or tap.
  ///
  /// In en, this message translates to:
  /// **'{kind, select, biometric{Locked with your fingerprint or face} pin{Locked with your PIN} pattern{Locked with your pattern} other{Locked with a tap}}'**
  String noteLockedWith(String kind);

  /// Toast after a locked note was given another lock; kind is biometric, pin, pattern or tap.
  ///
  /// In en, this message translates to:
  /// **'{kind, select, biometric{Now locked with your fingerprint or face} pin{Now locked with your PIN} pattern{Now locked with your pattern} other{Now locked with a tap}}'**
  String noteLockChanged(String kind);

  /// Toast after Remove lock on a note.
  ///
  /// In en, this message translates to:
  /// **'Lock removed'**
  String get noteLockRemoved;

  /// Toast after selected notes were locked.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Note locked} other{{count} notes locked}}'**
  String notesLocked(int count);

  /// Toast after selected notes were locked, when some of them were locked already and not opened since the phone was last locked: their lock wasn't changed.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Locked 1 note. Locked notes you haven’t opened keep their lock.} other{Locked {count} notes. Locked notes you haven’t opened keep their lock.}}'**
  String notesLockedSome(int count);

  /// Toast when Lock is chosen for selected notes that are all locked and not opened since the phone was last locked.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Open this note to change its lock} other{Open these notes to change their locks}}'**
  String notesLockOpenFirst(int count);

  /// Toast when the first PIN or pattern can't be set without the server; kind is pin or pattern.
  ///
  /// In en, this message translates to:
  /// **'{kind, select, pin{Setting a PIN needs a connection to the server} other{Setting a pattern needs a connection to the server}}'**
  String lockNeedsServer(String kind);

  /// Toast in Settings when the PIN or pattern can't be changed without the server; kind is pin or pattern.
  ///
  /// In en, this message translates to:
  /// **'{kind, select, pin{Changing the PIN needs a connection to the server} other{Changing the pattern needs a connection to the server}}'**
  String lockChangeNeedsServer(String kind);

  /// Heading of a locked note's unlock page when the note has no title.
  ///
  /// In en, this message translates to:
  /// **'Locked note'**
  String get lockUntitled;

  /// Button on a note locked with a tap: shows the note.
  ///
  /// In en, this message translates to:
  /// **'Tap to unlock'**
  String get lockTapToUnlock;

  /// Button on a note locked with a fingerprint or face: asks for it again.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get lockUnlock;

  /// Hint on a note locked with the PIN, and the first step when changing the PIN.
  ///
  /// In en, this message translates to:
  /// **'Enter your PIN'**
  String get lockEnterPin;

  /// Hint on a note locked with the pattern, and the first step when changing the pattern.
  ///
  /// In en, this message translates to:
  /// **'Draw your pattern'**
  String get lockDrawPattern;

  /// Hint on a note locked with a fingerprint or face.
  ///
  /// In en, this message translates to:
  /// **'Use your fingerprint, face or screen lock'**
  String get lockUseBiometric;

  /// Shown in the system's fingerprint or face prompt.
  ///
  /// In en, this message translates to:
  /// **'Unlock “{title}”'**
  String lockBiometricReason(String title);

  /// Shown on a locked note after too many failed fingerprint or face tries.
  ///
  /// In en, this message translates to:
  /// **'Too many tries. Unlock your phone, then try again.'**
  String get lockTooManyTries;

  /// Shown under the PIN pad or pattern when this phone has no copy of the PIN or pattern yet and the server can't be reached.
  ///
  /// In en, this message translates to:
  /// **'Can’t check it on this phone yet. Connect to the internet and try again.'**
  String get lockCantCheck;

  /// Shown under the PIN pad or pattern after a wrong PIN or pattern; kind is pin or pattern.
  ///
  /// In en, this message translates to:
  /// **'{kind, select, pin{Wrong PIN} other{Wrong pattern}}'**
  String lockWrong(String kind);

  /// Read by screen readers on the 3 by 3 grid of dots to draw a pattern on.
  ///
  /// In en, this message translates to:
  /// **'Pattern grid. Drag across at least 4 dots.'**
  String get lockPatternGrid;

  /// Read by screen readers on the PIN pad's backspace key.
  ///
  /// In en, this message translates to:
  /// **'Delete digit'**
  String get lockPinErase;

  /// Read by screen readers on the dots above the PIN pad: how many digits are typed.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No digits} =1{1 digit} other{{count} digits}}'**
  String lockPinDigits(int count);

  /// Title of the page that sets or changes the PIN or the pattern; kind is pin or pattern.
  ///
  /// In en, this message translates to:
  /// **'{kind, select, pin{PIN} other{Pattern}}'**
  String lockSetupTitle(String kind);

  /// Step when setting the first PIN or pattern; kind is pin or pattern.
  ///
  /// In en, this message translates to:
  /// **'{kind, select, pin{Choose a PIN} other{Draw a pattern}}'**
  String lockSetupChoose(String kind);

  /// Step when changing the PIN or pattern; kind is pin or pattern.
  ///
  /// In en, this message translates to:
  /// **'{kind, select, pin{Choose a new PIN} other{Draw a new pattern}}'**
  String lockSetupChooseNew(String kind);

  /// Last step when setting the PIN or pattern; kind is pin or pattern.
  ///
  /// In en, this message translates to:
  /// **'{kind, select, pin{Enter the PIN again} other{Draw the pattern again}}'**
  String lockSetupConfirm(String kind);

  /// Under Enter your PIN or Draw your pattern, when changing it.
  ///
  /// In en, this message translates to:
  /// **'The one you use now'**
  String get lockSetupCurrentHelp;

  /// Under Choose a PIN or Draw a pattern; kind is pin or pattern.
  ///
  /// In en, this message translates to:
  /// **'{kind, select, pin{4 to 12 digits. It opens every note you lock with a PIN.} other{Join at least 4 dots. It opens every note you lock with a pattern.}}'**
  String lockSetupChooseHelp(String kind);

  /// Under Enter the PIN again or Draw the pattern again.
  ///
  /// In en, this message translates to:
  /// **'To be sure'**
  String get lockSetupConfirmHelp;

  /// Shown when the current PIN or pattern given before changing it is wrong; kind is pin or pattern.
  ///
  /// In en, this message translates to:
  /// **'{kind, select, pin{That’s not your PIN} other{That’s not your pattern}}'**
  String lockSetupNotYours(String kind);

  /// Shown when a new PIN or pattern is too short or too long; kind is pin or pattern.
  ///
  /// In en, this message translates to:
  /// **'{kind, select, pin{Use 4 to 12 digits} other{Join at least 4 dots, each once}}'**
  String lockSetupBadShape(String kind);

  /// Shown when the PIN or pattern given twice differs; kind is pin or pattern.
  ///
  /// In en, this message translates to:
  /// **'{kind, select, pin{The PINs didn’t match. Try again.} other{The patterns didn’t match. Try again.}}'**
  String lockSetupMismatch(String kind);

  /// Button when changing the PIN or pattern: the account password stands in for the forgotten one.
  ///
  /// In en, this message translates to:
  /// **'Forgot? Use your password'**
  String get lockSetupForgot;

  /// Title of the sheet asking for the account password in place of a forgotten PIN or pattern.
  ///
  /// In en, this message translates to:
  /// **'Your account password'**
  String get lockSetupPasswordTitle;

  /// Shown when the server refuses the old PIN, pattern or password while changing it; kind is pin or pattern.
  ///
  /// In en, this message translates to:
  /// **'{kind, select, pin{Wrong PIN or password} other{Wrong pattern or password}}'**
  String lockErrorWrongProof(String kind);

  /// Shown when the server refuses a new PIN or pattern's shape; kind is pin or pattern.
  ///
  /// In en, this message translates to:
  /// **'{kind, select, pin{A PIN is 4 to 12 digits} other{A pattern joins at least 4 dots}}'**
  String lockErrorInvalid(String kind);

  /// Shown when the server is too old for note locks.
  ///
  /// In en, this message translates to:
  /// **'Your server doesn’t support note locks yet'**
  String get lockErrorUnsupported;

  /// Shown when saving a PIN or pattern failed; kind is pin or pattern.
  ///
  /// In en, this message translates to:
  /// **'{kind, select, pin{Couldn’t save the PIN. It needs a connection to the server.} other{Couldn’t save the pattern. It needs a connection to the server.}}'**
  String lockErrorOffline(String kind);

  /// Toast after the PIN or pattern was set or changed in Settings; kind is pin or pattern.
  ///
  /// In en, this message translates to:
  /// **'{kind, select, pin{PIN saved} other{Pattern saved}}'**
  String lockSaved(String kind);

  /// Settings section with the PIN and the pattern that open locked notes.
  ///
  /// In en, this message translates to:
  /// **'Note locks'**
  String get settingsNoteLocks;

  /// Settings row when no PIN or pattern is set yet; kind is pin or pattern.
  ///
  /// In en, this message translates to:
  /// **'{kind, select, pin{Set PIN} other{Set pattern}}'**
  String settingsLockSet(String kind);

  /// Settings row when the PIN or pattern is set; kind is pin or pattern.
  ///
  /// In en, this message translates to:
  /// **'{kind, select, pin{Change PIN} other{Change pattern}}'**
  String settingsLockChange(String kind);

  /// Under the Set or Change PIN or pattern row in Settings; kind is pin or pattern.
  ///
  /// In en, this message translates to:
  /// **'{kind, select, pin{Opens the notes you lock with a PIN} other{Opens the notes you lock with a pattern}}'**
  String settingsLockHelp(String kind);

  /// On a locked note's card (and the home screen widget) in place of its text, until it's opened.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get cardLocked;

  /// Tooltip of the open lock on a locked note's card after it was opened; screen readers read it with the card.
  ///
  /// In en, this message translates to:
  /// **'Locked, open until the screen turns off'**
  String get cardUnlocked;

  /// Settings section to save every note to a file and restore one.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get settingsBackup;

  /// Settings row: saves every note, tag, picture and recording to one .zip file.
  ///
  /// In en, this message translates to:
  /// **'Export backup'**
  String get backupExport;

  /// Under Export backup in Settings.
  ///
  /// In en, this message translates to:
  /// **'Save every note, tag, picture and recording to a file'**
  String get backupExportHelp;

  /// Under Export backup while the file is being made.
  ///
  /// In en, this message translates to:
  /// **'Making the backup…'**
  String get backupExporting;

  /// Title of the phone's save screen for the backup file.
  ///
  /// In en, this message translates to:
  /// **'Save the backup'**
  String get backupSaveTitle;

  /// Toast after the backup file was saved.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Saved 1 note to the backup} other{Saved {count} notes to the backup}}'**
  String backupSaved(int count);

  /// Added after the saved-backup toast when some attachments couldn't be put in (not downloaded, no connection).
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 attachment wasn’t on this phone and couldn’t be fetched.} other{{count} attachments weren’t on this phone and couldn’t be fetched.}}'**
  String backupMissingFiles(int count);

  /// Toast when making or saving the backup failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t make the backup'**
  String get backupExportFailed;

  /// Settings row: brings back the notes from a backup file.
  ///
  /// In en, this message translates to:
  /// **'Restore backup'**
  String get backupRestore;

  /// Under Restore backup in Settings.
  ///
  /// In en, this message translates to:
  /// **'Bring back the notes from a backup file. Notes already here stay as they are'**
  String get backupRestoreHelp;

  /// Under Restore backup while a backup is being restored.
  ///
  /// In en, this message translates to:
  /// **'Restoring…'**
  String get backupRestoring;

  /// Title of the phone's file picker when restoring a backup.
  ///
  /// In en, this message translates to:
  /// **'Pick an Anchor backup'**
  String get backupPickTitle;

  /// Toast when the picked backup file can't be read.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t open the file'**
  String get backupOpenFailed;

  /// Toast after a backup was restored.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Restored 1 note} other{Restored {count} notes}}'**
  String backupRestored(int count);

  /// Added after the restored toast: notes of the backup that were already on the phone and were left alone.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 was already here.} other{{count} were already here.}}'**
  String backupAlreadyHere(int count);

  /// Toast when a restored backup held no note missing from the phone.
  ///
  /// In en, this message translates to:
  /// **'Nothing to restore: every note is already here'**
  String get backupNothingToRestore;

  /// Toast when restoring a backup failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t restore the backup'**
  String get backupRestoreFailed;

  /// Toast when the file picked to restore isn't an Anchor backup.
  ///
  /// In en, this message translates to:
  /// **'This file isn’t an Anchor backup'**
  String get backupNotABackup;

  /// Toast when the backup's list of notes can't be read.
  ///
  /// In en, this message translates to:
  /// **'This backup is damaged'**
  String get backupDamaged;

  /// Toast when the backup was made by a newer version of the app.
  ///
  /// In en, this message translates to:
  /// **'This backup is from a newer Anchor. Update the app to restore it.'**
  String get backupTooNew;

  /// Toast after a file that isn’t a picture or a recording was added to a note.
  ///
  /// In en, this message translates to:
  /// **'File added'**
  String get attachmentFileAdded;

  /// Toast after a file that isn’t a picture or a recording was added to a note while offline.
  ///
  /// In en, this message translates to:
  /// **'File added. It will upload when you’re back online.'**
  String get attachmentFileAddedOffline;

  /// Toast when a file couldn’t be added to a note.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t add the file'**
  String get attachmentFileAddFailed;

  /// Toast after a file was deleted from a note, with an Undo button.
  ///
  /// In en, this message translates to:
  /// **'File deleted'**
  String get attachmentFileDeleted;

  /// Toast after several files were added to a note at once.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 attachment added} other{{count} attachments added}}'**
  String attachmentsAdded(int count);

  /// Toast after several files were added to a note at once while offline.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 attachment added. It will upload when you’re back online.} other{{count} attachments added. They will upload when you’re back online.}}'**
  String attachmentsAddedOffline(int count);

  /// Toolbar button over the keyboard, and the title of the menu it opens: puts a picture taken with the camera, or pictures from the phone, in the note’s text where the cursor is.
  ///
  /// In en, this message translates to:
  /// **'Picture in the text'**
  String get toolPictureInText;

  /// Option of the Picture in the text menu: takes a picture with the camera.
  ///
  /// In en, this message translates to:
  /// **'Take a picture'**
  String get pictureInTextCamera;

  /// Option of the Picture in the text menu: picks pictures from the phone’s photo library.
  ///
  /// In en, this message translates to:
  /// **'Choose pictures'**
  String get pictureInTextChoose;

  /// Verb: title of the page that crops a picture placed in a note’s text, its button that applies the crop, and the menu option that opens it.
  ///
  /// In en, this message translates to:
  /// **'Crop'**
  String get pictureCrop;

  /// Button on the crop page that puts the frame back around the whole picture.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get pictureCropReset;

  /// Button on the camera page while the flash is off; tapping it turns the flash on.
  ///
  /// In en, this message translates to:
  /// **'Flash off'**
  String get cameraFlashOff;

  /// Button on the camera page while the flash is on; tapping it turns the flash off.
  ///
  /// In en, this message translates to:
  /// **'Flash on'**
  String get cameraFlashOn;

  /// Message on the camera page when the phone has no camera the app can use.
  ///
  /// In en, this message translates to:
  /// **'No camera found'**
  String get cameraNone;

  /// Message on the camera page when the person hasn’t let the app use the camera.
  ///
  /// In en, this message translates to:
  /// **'Anchor needs the camera permission to take pictures'**
  String get cameraNoPermission;

  /// Message on the camera page when the camera couldn’t be started.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t start the camera'**
  String get cameraFailed;

  /// Button on the camera page that switches between the front and back cameras.
  ///
  /// In en, this message translates to:
  /// **'Switch camera'**
  String get cameraSwitch;

  /// Screen reader name of the round shutter button on the camera page.
  ///
  /// In en, this message translates to:
  /// **'Take a picture'**
  String get cameraShutter;

  /// Screen reader label of the pile of pictures taken so far on the camera page.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 picture taken} other{{count} pictures taken}}'**
  String cameraTaken(int count);

  /// Toast after the camera page closed, saying how many pictures were added to the note.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 picture added} other{{count} pictures added}}'**
  String cameraPicturesAdded(int count);

  /// Title of the menu shown when holding a picture placed in a note’s text, and its screen reader name when it has no caption.
  ///
  /// In en, this message translates to:
  /// **'Picture'**
  String get inlinePicture;

  /// Option in a picture’s menu: takes a new picture in its place.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get inlinePictureRetake;

  /// Option in a picture’s menu: swaps its left and right.
  ///
  /// In en, this message translates to:
  /// **'Mirror horizontally'**
  String get inlinePictureMirrorHorizontally;

  /// Option in a picture’s menu: swaps its top and bottom.
  ///
  /// In en, this message translates to:
  /// **'Mirror vertically'**
  String get inlinePictureMirrorVertically;

  /// Option in a picture’s menu, and the title of the sheet that writes a caption shown under the picture.
  ///
  /// In en, this message translates to:
  /// **'Add caption'**
  String get inlinePictureAddCaption;

  /// Option in a picture’s menu when it has a caption, and the title of the sheet that changes it.
  ///
  /// In en, this message translates to:
  /// **'Edit caption'**
  String get inlinePictureEditCaption;

  /// Placeholder of the field for a picture’s caption.
  ///
  /// In en, this message translates to:
  /// **'Caption'**
  String get inlinePictureCaptionHint;

  /// Toast when retaking, cropping or mirroring a picture in a note’s text failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t change the picture'**
  String get inlinePictureChangeFailed;

  /// Screen reader name of the round handle in a picture’s corner that changes its width.
  ///
  /// In en, this message translates to:
  /// **'Resize picture'**
  String get inlinePictureResize;

  /// Toast when the person opens or saves a file that hasn’t downloaded while offline.
  ///
  /// In en, this message translates to:
  /// **'This file will open when you’re back online'**
  String get fileOffline;

  /// Toast when an attached file couldn’t be downloaded.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load the file'**
  String get fileLoadFailed;

  /// Toast when no app on the phone can open an attached file.
  ///
  /// In en, this message translates to:
  /// **'No app on this phone opens it. Save it instead.'**
  String get fileNoApp;

  /// Title of the system dialog for saving an attached file to the phone.
  ///
  /// In en, this message translates to:
  /// **'Save file'**
  String get fileSaveDialog;

  /// Toast after an attached file was saved to the phone.
  ///
  /// In en, this message translates to:
  /// **'Saved {name}'**
  String fileSaved(String name);

  /// Toast when an attached file couldn’t be saved to the phone.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t save the file'**
  String get fileSaveFailed;

  /// Screen reader name of an attached file’s tile; tapping it opens the file in another app.
  ///
  /// In en, this message translates to:
  /// **'Open {name}'**
  String fileOpen(String name);

  /// Screen reader name of the download button on an attached file.
  ///
  /// In en, this message translates to:
  /// **'Save {name}'**
  String fileSave(String name);

  /// Option that opens the camera to take several pictures in a row, each added to the note as it’s taken.
  ///
  /// In en, this message translates to:
  /// **'Take several'**
  String get addTakeSeveral;

  /// Noun: option that picks one or more files of any kind stored on the phone.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get addFiles;

  /// Noun: option that picks a folder on the phone and adds it, zipped with its subfolders.
  ///
  /// In en, this message translates to:
  /// **'Folder'**
  String get addFolder;

  /// Toast when the picked folder couldn’t be zipped.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t read that folder'**
  String get addFolderFailed;

  /// Toast when the picked folder holds no files.
  ///
  /// In en, this message translates to:
  /// **'That folder is empty'**
  String get addFolderEmpty;

  /// Option in an open note’s More menu: adds pictures from the phone as attachments.
  ///
  /// In en, this message translates to:
  /// **'Add image'**
  String get actionAddImage;

  /// Option in an open note’s More menu: takes a picture with the camera app and adds it as an attachment.
  ///
  /// In en, this message translates to:
  /// **'Take picture'**
  String get actionTakePicture;

  /// Option in an open note’s More menu: opens the camera to take several pictures in a row.
  ///
  /// In en, this message translates to:
  /// **'Take several'**
  String get actionTakeSeveral;

  /// Verb: option for a note this person owns: nobody can change, trash or delete it until it’s unfrozen.
  ///
  /// In en, this message translates to:
  /// **'Freeze'**
  String get actionFreeze;

  /// Verb: option, and the snowflake on a frozen note’s bar, that lets the note be changed and deleted again.
  ///
  /// In en, this message translates to:
  /// **'Unfreeze'**
  String get actionUnfreeze;

  /// Subtitle of the Freeze option.
  ///
  /// In en, this message translates to:
  /// **'Nobody can change or delete it until you unfreeze it'**
  String get noteFreezeHelp;

  /// Toast when freezing failed, usually offline.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t freeze. It needs a connection to the server.'**
  String get noteFreezeFailed;

  /// Toast when unfreezing failed, usually offline.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t unfreeze. It needs a connection to the server.'**
  String get noteUnfreezeFailed;

  /// Toast after notes were frozen, with an Undo button.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Note frozen} other{{count} notes frozen}}'**
  String notesFrozen(int count);

  /// Toast after notes were unfrozen, with an Undo button.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Note unfrozen} other{{count} notes unfrozen}}'**
  String notesUnfrozen(int count);

  /// Toast when the notes picked for deleting are all frozen.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{A frozen note can’t be deleted. Unfreeze it first.} other{Frozen notes can’t be deleted. Unfreeze them first.}}'**
  String notesFrozenStay(int count);

  /// Title of the menu behind the Lock button of the selection bar.
  ///
  /// In en, this message translates to:
  /// **'Lock or freeze'**
  String get notesLockOrFreeze;

  /// Toast when the snowflake of a note shared with this person, that its owner froze, is tapped.
  ///
  /// In en, this message translates to:
  /// **'Its owner froze it, so it can’t be changed.'**
  String get readOnlyFrozenByOwner;

  /// Tooltip of the snowflake on a frozen note’s card, read out with the card, and the label of the snowflake on the bar of a note its owner froze.
  ///
  /// In en, this message translates to:
  /// **'Frozen'**
  String get cardFrozen;

  /// Option in the menu shown when holding the New note button: opens a new note and takes a picture straight into its text.
  ///
  /// In en, this message translates to:
  /// **'Camera note'**
  String get noteNewCamera;

  /// Option for a note (or picked notes): keep it out of this person’s lists; only a search or the Invisible filter finds it. Only for this person, like a lock.
  ///
  /// In en, this message translates to:
  /// **'Make invisible'**
  String get actionMakeInvisible;

  /// Option for an invisible note (or picked notes that all are): list it again.
  ///
  /// In en, this message translates to:
  /// **'Make visible'**
  String get actionMakeVisible;

  /// Under Make invisible in a note’s menu: an invisible note stays out of the lists, only a search or a filter brings it up.
  ///
  /// In en, this message translates to:
  /// **'Only a search finds it'**
  String get noteInvisibleHelp;

  /// Toast after notes were made invisible, with an Undo button.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Note made invisible. Search finds it.} other{{count} notes made invisible. Search finds them.}}'**
  String notesMadeInvisible(int count);

  /// Toast after invisible notes were made visible again, with an Undo button.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Note made visible} other{{count} notes made visible}}'**
  String notesMadeVisible(int count);

  /// Title of the menu behind the Lock button of the selection bar, when it offers Lock, Freeze and Make invisible.
  ///
  /// In en, this message translates to:
  /// **'Lock, freeze or make invisible'**
  String get notesLockFreezeOrHide;

  /// Title of the menu behind the Lock button of the selection bar, when it offers Lock and Make invisible (none of the picked notes can be frozen).
  ///
  /// In en, this message translates to:
  /// **'Lock or make invisible'**
  String get notesLockOrHide;

  /// Tooltip of the crossed-out eye on an invisible note’s card (found by a search or a filter), and read out with the card.
  ///
  /// In en, this message translates to:
  /// **'Invisible'**
  String get cardInvisible;

  /// Section label in the filter sheet, above Invisible: notes that are so.
  ///
  /// In en, this message translates to:
  /// **'Is'**
  String get filterIs;

  /// Filter choice: only the notes this person made invisible (kept out of the lists).
  ///
  /// In en, this message translates to:
  /// **'Invisible'**
  String get filterInvisible;

  /// Menu item and quick action: sets or changes the note's reminder.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get actionReminder;

  /// Quick action in a note's top bar: shows the note's lines as a checklist, or hides the checkboxes again.
  ///
  /// In en, this message translates to:
  /// **'Checkboxes'**
  String get actionCheckboxes;

  /// Last item in a note's More menu: opens Settings at the note's quick actions.
  ///
  /// In en, this message translates to:
  /// **'Modify quick actions'**
  String get actionModifyQuickActions;

  /// Section in Settings: the buttons in a note's top bar, beside More.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get settingsQuickActions;

  /// Footer under Settings › Quick actions.
  ///
  /// In en, this message translates to:
  /// **'In a note\'s top bar, in this order. Up to 5 fit. Drag to reorder.'**
  String get settingsQuickActionsHelp;

  /// Row in Settings › Quick actions when the bar holds no quick actions.
  ///
  /// In en, this message translates to:
  /// **'None. Everything is in More.'**
  String get settingsQuickActionsEmpty;

  /// Section in Settings under Quick actions: the actions in a note's More menu, each with a switch.
  ///
  /// In en, this message translates to:
  /// **'In More'**
  String get settingsMoreActions;

  /// Footer under Settings › In More.
  ///
  /// In en, this message translates to:
  /// **'Turn one off to offer it nowhere. Tap + to put it in the top bar.'**
  String get settingsMoreActionsHelp;

  /// Row in Settings: puts the note's top bar and More back as they first were.
  ///
  /// In en, this message translates to:
  /// **'Reset quick actions'**
  String get settingsQuickActionsReset;

  /// Screen reader label of the + button by an action in Settings › In More.
  ///
  /// In en, this message translates to:
  /// **'Put {action} in the top bar'**
  String settingsAddToBar(String action);

  /// Screen reader label of the minus button by a quick action in Settings; it goes back to More.
  ///
  /// In en, this message translates to:
  /// **'Take {action} out of the top bar'**
  String settingsRemoveFromBar(String action);

  /// Row in Settings under the quick actions: copies the top bar and the actions turned off, to paste on another phone.
  ///
  /// In en, this message translates to:
  /// **'Copy setup'**
  String get settingsCopySetup;

  /// Row in Settings under the quick actions: takes a copied setup from the clipboard.
  ///
  /// In en, this message translates to:
  /// **'Paste setup'**
  String get settingsPasteSetup;

  /// Message after Copy setup in Settings.
  ///
  /// In en, this message translates to:
  /// **'Quick actions copied'**
  String get settingsSetupCopied;

  /// Message after Paste setup in Settings.
  ///
  /// In en, this message translates to:
  /// **'Quick actions pasted'**
  String get settingsSetupPasted;

  /// Error after Paste setup when the clipboard holds something else.
  ///
  /// In en, this message translates to:
  /// **'The clipboard holds no copied quick actions'**
  String get settingsSetupPasteFailed;

  /// Error when a magic login QR code or link was already used or is older than 10 minutes. “Settings” is the web app’s Settings page.
  ///
  /// In en, this message translates to:
  /// **'This QR code or magic link has run out. Make a new one in Settings on the web.'**
  String get authMagicCodeUsed;

  /// Button on the first screen (server address) that opens the camera to scan the magic login QR code shown in the web app’s Settings.
  ///
  /// In en, this message translates to:
  /// **'Scan QR code'**
  String get magicLoginScan;

  /// Title of the camera screen that scans the magic login QR code.
  ///
  /// In en, this message translates to:
  /// **'Scan the magic login QR code'**
  String get magicLoginScanTitle;

  /// Instructions under the camera on the QR code scanner. “Settings”, “Show QR code” and “Sign in on your phone” are names in the web app.
  ///
  /// In en, this message translates to:
  /// **'On the web, open Settings and tap Show QR code under Sign in on your phone. Then point the camera at it.'**
  String get magicLoginScanHint;

  /// Shown on the scanner when it reads some other QR code.
  ///
  /// In en, this message translates to:
  /// **'That QR code isn’t a magic login. Use the one from Settings on the web.'**
  String get magicLoginNotOurs;

  /// Shown on the scanner when the camera permission was denied.
  ///
  /// In en, this message translates to:
  /// **'Anchor needs the camera permission to scan the QR code'**
  String get magicLoginNoPermission;

  /// Shown on the first screen while a magic login QR code or link signs in.
  ///
  /// In en, this message translates to:
  /// **'Signing in…'**
  String get magicLoginSigningIn;

  /// Shown when a magic link is opened while someone is signed in to the app.
  ///
  /// In en, this message translates to:
  /// **'You’re already signed in. Sign out first to use a magic link.'**
  String get magicLoginAlreadySignedIn;
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
