// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note_revisions_store.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(noteRevisionsStore)
final noteRevisionsStoreProvider = NoteRevisionsStoreProvider._();

final class NoteRevisionsStoreProvider
    extends
        $FunctionalProvider<
          NoteRevisionsStore,
          NoteRevisionsStore,
          NoteRevisionsStore
        >
    with $Provider<NoteRevisionsStore> {
  NoteRevisionsStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'noteRevisionsStoreProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$noteRevisionsStoreHash();

  @$internal
  @override
  $ProviderElement<NoteRevisionsStore> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  NoteRevisionsStore create(Ref ref) {
    return noteRevisionsStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NoteRevisionsStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NoteRevisionsStore>(value),
    );
  }
}

String _$noteRevisionsStoreHash() =>
    r'1fdbb95544de27fa3c3f2f9cb879766bc90e4697';
