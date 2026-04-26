// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_worker.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(syncWorker)
const syncWorkerProvider = SyncWorkerProvider._();

final class SyncWorkerProvider
    extends $FunctionalProvider<SyncWorker, SyncWorker, SyncWorker>
    with $Provider<SyncWorker> {
  const SyncWorkerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncWorkerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncWorkerHash();

  @$internal
  @override
  $ProviderElement<SyncWorker> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SyncWorker create(Ref ref) {
    return syncWorker(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SyncWorker value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SyncWorker>(value),
    );
  }
}

String _$syncWorkerHash() => r'a47b58ff53049f5933b01f5955532937ab8bccaf';
