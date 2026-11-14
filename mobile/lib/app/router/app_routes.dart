/// Must match the path patterns in app_router.dart.
class AppRoutes {
  AppRoutes._();

  static const home = '/';
  static const serverConfig = '/server-config';
  static const login = '/login';
  static const register = '/register';
  static const trash = '/trash';
  static const archive = '/archive';

  static const newNote = '/note/new';
  static String note(String id) => '/note/$id';
  static String history(String noteId) => '${note(noteId)}/history';
  static String revision(String noteId, String revisionId) =>
      '${history(noteId)}/$revisionId';

  static const settings = '/settings';
  static const changePassword = '$settings/change-password';
  static const deleteAccount = '$settings/delete-account';
  static const editProfile = '$settings/edit-profile';
  static const logs = '$settings/logs';

  // For home-widget and reminder taps: the editor opens as the only page.
  static const widgetNewNote = '/widget/note/new';
  static String widgetNote(String id) => '/widget/note/$id';
}
