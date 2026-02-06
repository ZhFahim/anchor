import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Repository for managing user preferences in secure storage
class PreferencesRepository {
  final FlutterSecureStorage _storage;

  const PreferencesRepository(this._storage);

  // Editor preferences keys
  static const _sortChecklistItemsKey = 'editor_sort_checklist_items';

  // Theme preferences keys
  static const _themeModeKey = 'theme_mode';

  // Editor preferences methods
  Future<bool> getSortChecklistItems() async {
    final value = await _storage.read(key: _sortChecklistItemsKey);
    return value != 'false'; // Default to true
  }

  Future<void> setSortChecklistItems(bool value) async {
    await _storage.write(key: _sortChecklistItemsKey, value: value.toString());
  }

  // Theme preferences methods
  Future<String?> getThemeMode() async {
    return await _storage.read(key: _themeModeKey);
  }

  Future<void> setThemeMode(String mode) async {
    await _storage.write(key: _themeModeKey, value: mode);
  }
}
