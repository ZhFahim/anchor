// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tags_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(tagsRepository)
const tagsRepositoryProvider = TagsRepositoryProvider._();

final class TagsRepositoryProvider
    extends $FunctionalProvider<TagsRepository, TagsRepository, TagsRepository>
    with $Provider<TagsRepository> {
  const TagsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tagsRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tagsRepositoryHash();

  @$internal
  @override
  $ProviderElement<TagsRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TagsRepository create(Ref ref) {
    return tagsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TagsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TagsRepository>(value),
    );
  }
}

String _$tagsRepositoryHash() => r'f6fde887bfe145d3a24317bc929f2ee38206e13f';
