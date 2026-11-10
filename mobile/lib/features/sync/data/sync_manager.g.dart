// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_manager.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Runs syncs one at a time.

@ProviderFor(SyncManager)
final syncManagerProvider = SyncManagerProvider._();

/// Runs syncs one at a time.
final class SyncManagerProvider extends $NotifierProvider<SyncManager, bool> {
  /// Runs syncs one at a time.
  SyncManagerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncManagerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncManagerHash();

  @$internal
  @override
  SyncManager create() => SyncManager();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$syncManagerHash() => r'cc6c9b01018be4f967dab979597aad8923db10f8';

/// Runs syncs one at a time.

abstract class _$SyncManager extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Whether the last sync failed or was paused; the next one that works clears it.

@ProviderFor(SyncFailed)
final syncFailedProvider = SyncFailedProvider._();

/// Whether the last sync failed or was paused; the next one that works clears it.
final class SyncFailedProvider extends $NotifierProvider<SyncFailed, bool> {
  /// Whether the last sync failed or was paused; the next one that works clears it.
  SyncFailedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncFailedProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncFailedHash();

  @$internal
  @override
  SyncFailed create() => SyncFailed();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$syncFailedHash() => r'9a60f8617f144eed51a2d0e02ec83c69e642b78b';

/// Whether the last sync failed or was paused; the next one that works clears it.

abstract class _$SyncFailed extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(hasDownloaded)
final hasDownloadedProvider = HasDownloadedProvider._();

final class HasDownloadedProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, Stream<bool>>
    with $FutureModifier<bool>, $StreamProvider<bool> {
  HasDownloadedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'hasDownloadedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$hasDownloadedHash();

  @$internal
  @override
  $StreamProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<bool> create(Ref ref) {
    return hasDownloaded(ref);
  }
}

String _$hasDownloadedHash() => r'ba18c89420da243f47e7b1c2062386ba58a894fd';

@ProviderFor(firstDownload)
final firstDownloadProvider = FirstDownloadProvider._();

final class FirstDownloadProvider
    extends $FunctionalProvider<FirstDownload, FirstDownload, FirstDownload>
    with $Provider<FirstDownload> {
  FirstDownloadProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'firstDownloadProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$firstDownloadHash();

  @$internal
  @override
  $ProviderElement<FirstDownload> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FirstDownload create(Ref ref) {
    return firstDownload(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FirstDownload value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FirstDownload>(value),
    );
  }
}

String _$firstDownloadHash() => r'fbe4a2ce04b04605663f5e53b8a51592033873a9';
