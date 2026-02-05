// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'editor_preferences_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(EditorPreferencesController)
const editorPreferencesControllerProvider =
    EditorPreferencesControllerProvider._();

final class EditorPreferencesControllerProvider
    extends $NotifierProvider<EditorPreferencesController, EditorPreferences> {
  const EditorPreferencesControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'editorPreferencesControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$editorPreferencesControllerHash();

  @$internal
  @override
  EditorPreferencesController create() => EditorPreferencesController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EditorPreferences value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EditorPreferences>(value),
    );
  }
}

String _$editorPreferencesControllerHash() =>
    r'2338330babe264fc9992e4ee0467314a11cf849c';

abstract class _$EditorPreferencesController
    extends $Notifier<EditorPreferences> {
  EditorPreferences build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<EditorPreferences, EditorPreferences>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<EditorPreferences, EditorPreferences>,
              EditorPreferences,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
