import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

part 'editor_preferences_provider.g.dart';

const _sortChecklistItemsKey = 'editor_sort_checklist_items';

/// Editor preferences state
class EditorPreferences {
  /// Whether to sort checklist items (checked to bottom, unchecked to top)
  final bool sortChecklistItems;

  const EditorPreferences({this.sortChecklistItems = true});

  EditorPreferences copyWith({bool? sortChecklistItems}) {
    return EditorPreferences(
      sortChecklistItems: sortChecklistItems ?? this.sortChecklistItems,
    );
  }
}

@Riverpod(keepAlive: true)
class EditorPreferencesController extends _$EditorPreferencesController {
  final _storage = const FlutterSecureStorage();

  @override
  EditorPreferences build() {
    // Start with defaults, then load from storage
    _loadFromStorage();
    return const EditorPreferences();
  }

  Future<void> _loadFromStorage() async {
    final value = await _storage.read(key: _sortChecklistItemsKey);
    if (value != null) {
      state = state.copyWith(sortChecklistItems: value != 'false');
    }
  }

  Future<void> setSortChecklistItems(bool value) async {
    state = state.copyWith(sortChecklistItems: value);
    await _storage.write(key: _sortChecklistItemsKey, value: value.toString());
  }
}
