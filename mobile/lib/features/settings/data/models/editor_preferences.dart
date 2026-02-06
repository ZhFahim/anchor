/// Editor preferences model
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
