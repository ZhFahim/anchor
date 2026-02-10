import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _themeModeKey = 'theme_mode';
const _storage = FlutterSecureStorage();

/// Holds the initial theme mode loaded before the app starts
/// This is set by [initializeApp] and read by the theme provider
ThemeMode initialThemeMode = ThemeMode.system;

/// Holds the initial user ID loaded before the app starts
/// This is set by [initializeApp] and read by [ActiveUserId] provider
String? initialUserId;

/// Load app initialization data before the app starts
/// This prevents theme flash and other initialization issues
Future<void> initializeApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load saved theme preference
  final savedTheme = await _storage.read(key: _themeModeKey);
  if (savedTheme != null) {
    initialThemeMode = ThemeMode.values.firstWhere(
      (mode) => mode.name == savedTheme,
      orElse: () => ThemeMode.system,
    );
  }

  // Load saved user ID for per-user database selection
  initialUserId = await _storage.read(key: 'user_id');
}
