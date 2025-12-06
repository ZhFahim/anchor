// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tags_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$noteTagsStreamHash() => r'56ba32fd63952655cd16a240b9f028b930cf816e';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [noteTagsStream].
@ProviderFor(noteTagsStream)
const noteTagsStreamProvider = NoteTagsStreamFamily();

/// See also [noteTagsStream].
class NoteTagsStreamFamily extends Family<AsyncValue<List<Tag>>> {
  /// See also [noteTagsStream].
  const NoteTagsStreamFamily();

  /// See also [noteTagsStream].
  NoteTagsStreamProvider call(String noteId) {
    return NoteTagsStreamProvider(noteId);
  }

  @override
  NoteTagsStreamProvider getProviderOverride(
    covariant NoteTagsStreamProvider provider,
  ) {
    return call(provider.noteId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'noteTagsStreamProvider';
}

/// See also [noteTagsStream].
class NoteTagsStreamProvider extends AutoDisposeStreamProvider<List<Tag>> {
  /// See also [noteTagsStream].
  NoteTagsStreamProvider(String noteId)
    : this._internal(
        (ref) => noteTagsStream(ref as NoteTagsStreamRef, noteId),
        from: noteTagsStreamProvider,
        name: r'noteTagsStreamProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$noteTagsStreamHash,
        dependencies: NoteTagsStreamFamily._dependencies,
        allTransitiveDependencies:
            NoteTagsStreamFamily._allTransitiveDependencies,
        noteId: noteId,
      );

  NoteTagsStreamProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.noteId,
  }) : super.internal();

  final String noteId;

  @override
  Override overrideWith(
    Stream<List<Tag>> Function(NoteTagsStreamRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: NoteTagsStreamProvider._internal(
        (ref) => create(ref as NoteTagsStreamRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        noteId: noteId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<Tag>> createElement() {
    return _NoteTagsStreamProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is NoteTagsStreamProvider && other.noteId == noteId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, noteId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin NoteTagsStreamRef on AutoDisposeStreamProviderRef<List<Tag>> {
  /// The parameter `noteId` of this provider.
  String get noteId;
}

class _NoteTagsStreamProviderElement
    extends AutoDisposeStreamProviderElement<List<Tag>>
    with NoteTagsStreamRef {
  _NoteTagsStreamProviderElement(super.provider);

  @override
  String get noteId => (origin as NoteTagsStreamProvider).noteId;
}

String _$availableTagsHash() => r'42399dbbe1aa46c35fcaade2a1aa49d57a4ee7c2';

/// See also [availableTags].
@ProviderFor(availableTags)
final availableTagsProvider = AutoDisposeFutureProvider<List<Tag>>.internal(
  availableTags,
  name: r'availableTagsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$availableTagsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AvailableTagsRef = AutoDisposeFutureProviderRef<List<Tag>>;
String _$tagsControllerHash() => r'300f71be67b03b3d441a9660d56aaf447b33ce2b';

/// See also [TagsController].
@ProviderFor(TagsController)
final tagsControllerProvider =
    AutoDisposeStreamNotifierProvider<TagsController, List<Tag>>.internal(
      TagsController.new,
      name: r'tagsControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$tagsControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$TagsController = AutoDisposeStreamNotifier<List<Tag>>;
String _$selectedTagFilterHash() => r'8aa84dad7b0d5e65e1c68e6db09019023720010e';

/// See also [SelectedTagFilter].
@ProviderFor(SelectedTagFilter)
final selectedTagFilterProvider =
    AutoDisposeNotifierProvider<SelectedTagFilter, String?>.internal(
      SelectedTagFilter.new,
      name: r'selectedTagFilterProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$selectedTagFilterHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SelectedTagFilter = AutoDisposeNotifier<String?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
