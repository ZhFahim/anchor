// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note_shares_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(noteSharesRepository)
const noteSharesRepositoryProvider = NoteSharesRepositoryProvider._();

final class NoteSharesRepositoryProvider
    extends
        $FunctionalProvider<
          NoteSharesRepository,
          NoteSharesRepository,
          NoteSharesRepository
        >
    with $Provider<NoteSharesRepository> {
  const NoteSharesRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'noteSharesRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$noteSharesRepositoryHash();

  @$internal
  @override
  $ProviderElement<NoteSharesRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  NoteSharesRepository create(Ref ref) {
    return noteSharesRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NoteSharesRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NoteSharesRepository>(value),
    );
  }
}

String _$noteSharesRepositoryHash() =>
    r'3a4b7c7c312f0994d7fb9fecd97bb252f39ea62b';
