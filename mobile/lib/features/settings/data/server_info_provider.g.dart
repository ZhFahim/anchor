// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'server_info_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(serverInfo)
const serverInfoProvider = ServerInfoProvider._();

final class ServerInfoProvider
    extends
        $FunctionalProvider<
          AsyncValue<ServerInfo?>,
          ServerInfo?,
          FutureOr<ServerInfo?>
        >
    with $FutureModifier<ServerInfo?>, $FutureProvider<ServerInfo?> {
  const ServerInfoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'serverInfoProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$serverInfoHash();

  @$internal
  @override
  $FutureProviderElement<ServerInfo?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ServerInfo?> create(Ref ref) {
    return serverInfo(ref);
  }
}

String _$serverInfoHash() => r'ea826fed49ce54936d13dc3a78be71b5f015cbf6';
