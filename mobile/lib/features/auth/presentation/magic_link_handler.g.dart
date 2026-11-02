// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'magic_link_handler.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// A magic link opened on this phone (from the web's Settings, through its
/// /magic-login page) signs in on the server screen, which shows how it
/// goes. Someone already signed in is told so instead.

@ProviderFor(MagicLinkHandler)
final magicLinkHandlerProvider = MagicLinkHandlerProvider._();

/// A magic link opened on this phone (from the web's Settings, through its
/// /magic-login page) signs in on the server screen, which shows how it
/// goes. Someone already signed in is told so instead.
final class MagicLinkHandlerProvider
    extends $NotifierProvider<MagicLinkHandler, void> {
  /// A magic link opened on this phone (from the web's Settings, through its
  /// /magic-login page) signs in on the server screen, which shows how it
  /// goes. Someone already signed in is told so instead.
  MagicLinkHandlerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'magicLinkHandlerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$magicLinkHandlerHash();

  @$internal
  @override
  MagicLinkHandler create() => MagicLinkHandler();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$magicLinkHandlerHash() => r'2f60e416317bf191a4ec724476e4f57edcf011fb';

/// A magic link opened on this phone (from the web's Settings, through its
/// /magic-login page) signs in on the server screen, which shows how it
/// goes. Someone already signed in is told so instead.

abstract class _$MagicLinkHandler extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
