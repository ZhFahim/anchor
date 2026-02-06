// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'editor_preferences_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(preferencesRepository)
const preferencesRepositoryProvider = PreferencesRepositoryProvider._();

final class PreferencesRepositoryProvider
    extends
        $FunctionalProvider<
          PreferencesRepository,
          PreferencesRepository,
          PreferencesRepository
        >
    with $Provider<PreferencesRepository> {
  const PreferencesRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'preferencesRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$preferencesRepositoryHash();

  @$internal
  @override
  $ProviderElement<PreferencesRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PreferencesRepository create(Ref ref) {
    return preferencesRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PreferencesRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PreferencesRepository>(value),
    );
  }
}

String _$preferencesRepositoryHash() =>
    r'a73cb8cd55a748279c39e0f4a35ab888fae1e30b';

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
    r'2b741bd5cb59aef4d836e033248b6a132b1df8dc';

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
