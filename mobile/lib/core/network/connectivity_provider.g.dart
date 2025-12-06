// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connectivity_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$connectivityStreamHash() =>
    r'dbd2c4ce5970f1f97dad2730821bb5ca0b99c327';

/// See also [connectivityStream].
@ProviderFor(connectivityStream)
final connectivityStreamProvider =
    AutoDisposeStreamProvider<List<ConnectivityResult>>.internal(
      connectivityStream,
      name: r'connectivityStreamProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$connectivityStreamHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ConnectivityStreamRef =
    AutoDisposeStreamProviderRef<List<ConnectivityResult>>;
String _$isOnlineHash() => r'e62aa0103f472e2bbcdbc3698127b57f571f7234';

/// See also [isOnline].
@ProviderFor(isOnline)
final isOnlineProvider = AutoDisposeFutureProvider<bool>.internal(
  isOnline,
  name: r'isOnlineProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$isOnlineHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IsOnlineRef = AutoDisposeFutureProviderRef<bool>;
String _$syncManagerHash() => r'c5b5b44c4a3d7acc00506ff14067edb34f040ba4';

/// See also [SyncManager].
@ProviderFor(SyncManager)
final syncManagerProvider =
    AutoDisposeNotifierProvider<SyncManager, bool>.internal(
      SyncManager.new,
      name: r'syncManagerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$syncManagerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SyncManager = AutoDisposeNotifier<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
