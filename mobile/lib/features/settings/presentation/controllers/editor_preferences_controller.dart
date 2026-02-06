import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../data/models/editor_preferences.dart';
import '../../data/repository/preferences_repository.dart';

part 'editor_preferences_controller.g.dart';

@Riverpod(keepAlive: true)
PreferencesRepository preferencesRepository(Ref ref) {
  return const PreferencesRepository(FlutterSecureStorage());
}

@Riverpod(keepAlive: true)
class EditorPreferencesController extends _$EditorPreferencesController {
  @override
  EditorPreferences build() {
    // Start with defaults, then load from storage
    _loadFromStorage();
    return const EditorPreferences();
  }

  Future<void> _loadFromStorage() async {
    final repository = ref.read(preferencesRepositoryProvider);
    final sortChecklistItems = await repository.getSortChecklistItems();
    state = state.copyWith(sortChecklistItems: sortChecklistItems);
  }

  Future<void> setSortChecklistItems(bool value) async {
    state = state.copyWith(sortChecklistItems: value);
    final repository = ref.read(preferencesRepositoryProvider);
    await repository.setSortChecklistItems(value);
  }
}
