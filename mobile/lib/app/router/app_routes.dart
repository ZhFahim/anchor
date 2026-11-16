/// Must match the path patterns in app_router.dart.
class AppRoutes {
  AppRoutes._();

  static const home = '/';
  static const serverConfig = '/server-config';
  static const login = '/login';
  static const register = '/register';

  // Steps of signing in. The code step needs the challenge as `extra`.
  static const twoFactor = '/login/two-factor';
  static const twoFactorSetup = '/login/two-factor-setup';

  /// [twoFactorSetup] for an account that has only passkeys.
  static const passkeyOnWeb = '/login/passkey-on-web';

  /// Pages for someone who isn't signed in.
  static const signedOutPages = {
    login,
    register,
    twoFactor,
    twoFactorSetup,
    passkeyOnWeb,
    serverConfig,
  };
  static const trash = '/trash';
  static const archive = '/archive';

  static const newNote = '/note/new';
  static String note(String id) => '/note/$id';
  static String history(String noteId) => '${note(noteId)}/history';
  static String revision(String noteId, String revisionId) =>
      '${history(noteId)}/$revisionId';

  static const settings = '/settings';
  static const changePassword = '$settings/change-password';
  static const editProfile = '$settings/edit-profile';
  static const logs = '$settings/logs';

  // For home-widget and reminder taps: the editor opens as the only page.
  static const widgetNewNote = '/widget/note/new';
  static String widgetNote(String id) => '/widget/note/$id';
}
