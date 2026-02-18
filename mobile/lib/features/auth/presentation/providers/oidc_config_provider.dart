import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anchor/core/network/server_config_provider.dart';
import 'package:anchor/features/auth/data/remote/auth_service.dart';
import 'package:anchor/features/auth/domain/oidc_config.dart';

/// Fetches OIDC mobile config from the server when a server URL is set.
/// Returns a disabled config when no server is configured.
final oidcConfigProvider = FutureProvider.autoDispose<OidcConfig>((ref) async {
  final serverUrl = ref.watch(serverUrlProvider);
  if (serverUrl == null || serverUrl.isEmpty) {
    return const OidcConfig();
  }
  final authService = ref.watch(authServiceProvider);
  return authService.getOidcConfig();
});
