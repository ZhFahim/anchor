// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'server_config_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ServerConfig)
final serverConfigProvider = ServerConfigProvider._();

final class ServerConfigProvider
    extends $AsyncNotifierProvider<ServerConfig, String?> {
  ServerConfigProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'serverConfigProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$serverConfigHash();

  @$internal
  @override
  ServerConfig create() => ServerConfig();
}

String _$serverConfigHash() => r'3105fddd460f89532136f1e6bc5bb65cb752e6df';

abstract class _$ServerConfig extends $AsyncNotifier<String?> {
  FutureOr<String?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<String?>, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<String?>, String?>,
              AsyncValue<String?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(serverUrl)
final serverUrlProvider = ServerUrlProvider._();

final class ServerUrlProvider
    extends $FunctionalProvider<String?, String?, String?>
    with $Provider<String?> {
  ServerUrlProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'serverUrlProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$serverUrlHash();

  @$internal
  @override
  $ProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String? create(Ref ref) {
    return serverUrl(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$serverUrlHash() => r'd4257305921fa0bbecbe8621dc4adc024d756f1c';

@ProviderFor(AllowSelfSignedCert)
final allowSelfSignedCertProvider = AllowSelfSignedCertProvider._();

final class AllowSelfSignedCertProvider
    extends $AsyncNotifierProvider<AllowSelfSignedCert, bool> {
  AllowSelfSignedCertProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'allowSelfSignedCertProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$allowSelfSignedCertHash();

  @$internal
  @override
  AllowSelfSignedCert create() => AllowSelfSignedCert();
}

String _$allowSelfSignedCertHash() =>
    r'e4e50e0b0f52511fec19be9a829aa94249abce7d';

abstract class _$AllowSelfSignedCert extends $AsyncNotifier<bool> {
  FutureOr<bool> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<bool>, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<bool>, bool>,
              AsyncValue<bool>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(CustomHeaders)
final customHeadersProvider = CustomHeadersProvider._();

final class CustomHeadersProvider
    extends $AsyncNotifierProvider<CustomHeaders, List<CustomHeader>> {
  CustomHeadersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'customHeadersProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$customHeadersHash();

  @$internal
  @override
  CustomHeaders create() => CustomHeaders();
}

String _$customHeadersHash() => r'8393a38b86d6fb1f9e104dc2676815e6a544fbea';

abstract class _$CustomHeaders extends $AsyncNotifier<List<CustomHeader>> {
  FutureOr<List<CustomHeader>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<CustomHeader>>, List<CustomHeader>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<CustomHeader>>, List<CustomHeader>>,
              AsyncValue<List<CustomHeader>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
