// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tags_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TagsController)
const tagsControllerProvider = TagsControllerProvider._();

final class TagsControllerProvider
    extends $StreamNotifierProvider<TagsController, List<Tag>> {
  const TagsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tagsControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tagsControllerHash();

  @$internal
  @override
  TagsController create() => TagsController();
}

String _$tagsControllerHash() => r'b5cc211ab68f9bb303f56b59d5b5bc6a22871053';

abstract class _$TagsController extends $StreamNotifier<List<Tag>> {
  Stream<List<Tag>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<List<Tag>>, List<Tag>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Tag>>, List<Tag>>,
              AsyncValue<List<Tag>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(noteTagsStream)
const noteTagsStreamProvider = NoteTagsStreamFamily._();

final class NoteTagsStreamProvider
    extends
        $FunctionalProvider<AsyncValue<List<Tag>>, List<Tag>, Stream<List<Tag>>>
    with $FutureModifier<List<Tag>>, $StreamProvider<List<Tag>> {
  const NoteTagsStreamProvider._({
    required NoteTagsStreamFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'noteTagsStreamProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$noteTagsStreamHash();

  @override
  String toString() {
    return r'noteTagsStreamProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<Tag>> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<Tag>> create(Ref ref) {
    final argument = this.argument as String;
    return noteTagsStream(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is NoteTagsStreamProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$noteTagsStreamHash() => r'56ba32fd63952655cd16a240b9f028b930cf816e';

final class NoteTagsStreamFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<Tag>>, String> {
  const NoteTagsStreamFamily._()
    : super(
        retry: null,
        name: r'noteTagsStreamProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  NoteTagsStreamProvider call(String noteId) =>
      NoteTagsStreamProvider._(argument: noteId, from: this);

  @override
  String toString() => r'noteTagsStreamProvider';
}

@ProviderFor(availableTags)
const availableTagsProvider = AvailableTagsProvider._();

final class AvailableTagsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Tag>>,
          List<Tag>,
          FutureOr<List<Tag>>
        >
    with $FutureModifier<List<Tag>>, $FutureProvider<List<Tag>> {
  const AvailableTagsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'availableTagsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$availableTagsHash();

  @$internal
  @override
  $FutureProviderElement<List<Tag>> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<Tag>> create(Ref ref) {
    return availableTags(ref);
  }
}

String _$availableTagsHash() => r'42399dbbe1aa46c35fcaade2a1aa49d57a4ee7c2';

@ProviderFor(SelectedTagFilter)
const selectedTagFilterProvider = SelectedTagFilterProvider._();

final class SelectedTagFilterProvider
    extends $NotifierProvider<SelectedTagFilter, String?> {
  const SelectedTagFilterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedTagFilterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedTagFilterHash();

  @$internal
  @override
  SelectedTagFilter create() => SelectedTagFilter();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$selectedTagFilterHash() => r'8aa84dad7b0d5e65e1c68e6db09019023720010e';

abstract class _$SelectedTagFilter extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
