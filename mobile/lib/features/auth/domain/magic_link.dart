import '../../../core/network/server_address.dart';

/// A one-time sign-in made on the web, in Settings › Sign in on your phone:
/// its QR code, or its magic link opened on this phone.
class MagicLink {
  const MagicLink({required this.serverUrl, required this.code});

  /// The scheme and host the web app opens (web/features/auth/utils/magic-link.ts).
  static const appScheme = 'anchorplus';
  static const appHost = 'magic-login';

  /// A normalized server address.
  final String serverUrl;
  final String code;

  /// Reads either form of the link: the web page every browser opens,
  /// https://notes.example.com/magic-login?code=…, whose server is the one
  /// it's on, or anchorplus://magic-login?server=…&code=…, which that page
  /// hands the app. Null for anything else.
  static MagicLink? parse(String text) {
    final uri = Uri.tryParse(text.trim());
    if (uri == null) return null;
    final code = uri.queryParameters['code'];
    if (code == null || code.isEmpty) return null;
    final String? server;
    if (uri.scheme == appScheme) {
      if (uri.host != appHost) return null;
      server = uri.queryParameters['server'];
    } else if ((uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.path == '/$appHost') {
      server = uri.origin;
    } else {
      return null;
    }
    if (server == null) return null;
    final serverUri = Uri.tryParse(server);
    if (serverUri == null ||
        (serverUri.scheme != 'https' && serverUri.scheme != 'http')) {
      return null;
    }
    final serverUrl = normalizeServerUrl(server);
    if (serverUrl == null) return null;
    return MagicLink(serverUrl: serverUrl, code: code);
  }

  @override
  bool operator ==(Object other) =>
      other is MagicLink && other.serverUrl == serverUrl && other.code == code;

  @override
  int get hashCode => Object.hash(serverUrl, code);
}
