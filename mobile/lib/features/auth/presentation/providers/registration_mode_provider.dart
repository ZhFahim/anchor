import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anchor/core/network/server_config_provider.dart';
import 'package:anchor/features/auth/data/remote/auth_service.dart';

/// Registration mode from server: 'disabled', 'enabled', or 'review'.
/// Defaults to 'enabled' when no server or on error.
final registrationModeProvider = FutureProvider.autoDispose<String>((
  ref,
) async {
  final serverUrl = ref.watch(serverUrlProvider);
  if (serverUrl == null || serverUrl.isEmpty) {
    return 'enabled';
  }
  final authService = ref.watch(authServiceProvider);
  return authService.getRegistrationMode();
});
