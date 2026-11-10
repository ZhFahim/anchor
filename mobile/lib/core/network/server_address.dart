String hostOf(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null || uri.host.isEmpty) return url;
  return uri.hasPort && uri.port != 80 && uri.port != 443
      ? '${uri.host}:${uri.port}'
      : uri.host;
}

bool isOnServer(String url, String serverUrl) {
  final uri = Uri.tryParse(url);
  final server = Uri.tryParse(serverUrl);
  if (uri == null || server == null || !uri.hasAuthority) return false;
  return uri.scheme == server.scheme &&
      uri.host == server.host &&
      uri.port == server.port;
}

/// Null when [address] isn't a web address.
String? normalizeServerUrl(String address) {
  var url = address.trim();
  while (url.endsWith('/')) {
    url = url.substring(0, url.length - 1);
  }
  if (url.isEmpty) return null;
  if (!url.startsWith('http://') && !url.startsWith('https://')) {
    url = 'https://$url';
  }
  final uri = Uri.tryParse(url);
  if (uri == null || !_hostPattern.hasMatch(uri.host)) return null;
  return url;
}

final _hostPattern = RegExp(r'^[\w.-]+$');
