import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../app_initializer.dart' as app_init;

part 'theme_mode_provider.g.dart';

const _themeModeKey = 'theme_mode';

@Riverpod(keepAlive: true)
class ThemeModeController extends _$ThemeModeController {
  final _storage = const FlutterSecureStorage();

  @override
  ThemeMode build() {
    // Use the theme loaded before app started (no flash)
    return app_init.initialThemeMode;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _storage.write(key: _themeModeKey, value: mode.name);
  }
}
