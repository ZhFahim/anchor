// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note_attachments_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(noteAttachmentsRepository)
const noteAttachmentsRepositoryProvider = NoteAttachmentsRepositoryProvider._();

final class NoteAttachmentsRepositoryProvider
    extends
        $FunctionalProvider<
          NoteAttachmentsRepository,
          NoteAttachmentsRepository,
          NoteAttachmentsRepository
        >
    with $Provider<NoteAttachmentsRepository> {
  const NoteAttachmentsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'noteAttachmentsRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$noteAttachmentsRepositoryHash();

  @$internal
  @override
  $ProviderElement<NoteAttachmentsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  NoteAttachmentsRepository create(Ref ref) {
    return noteAttachmentsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NoteAttachmentsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NoteAttachmentsRepository>(value),
    );
  }
}

String _$noteAttachmentsRepositoryHash() =>
    r'cc5fadc96e79ea721fe195f427b6559948413c5e';
