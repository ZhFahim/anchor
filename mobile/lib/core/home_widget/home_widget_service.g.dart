// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_widget_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Mirrors the active notes list into the Android home-screen widget.
///
/// Watched from [AnchorApp] so it lives for the whole app session. Reacts to
/// every local notes change (edits, sync results) via the drift stream and to
/// login/logout via the active user id.

@ProviderFor(HomeWidgetSync)
const homeWidgetSyncProvider = HomeWidgetSyncProvider._();

/// Mirrors the active notes list into the Android home-screen widget.
///
/// Watched from [AnchorApp] so it lives for the whole app session. Reacts to
/// every local notes change (edits, sync results) via the drift stream and to
/// login/logout via the active user id.
final class HomeWidgetSyncProvider
    extends $NotifierProvider<HomeWidgetSync, void> {
  /// Mirrors the active notes list into the Android home-screen widget.
  ///
  /// Watched from [AnchorApp] so it lives for the whole app session. Reacts to
  /// every local notes change (edits, sync results) via the drift stream and to
  /// login/logout via the active user id.
  const HomeWidgetSyncProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeWidgetSyncProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeWidgetSyncHash();

  @$internal
  @override
  HomeWidgetSync create() => HomeWidgetSync();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$homeWidgetSyncHash() => r'a0392e16c23cbe3b3e5dec2dd66b7603dd89e2f4';

/// Mirrors the active notes list into the Android home-screen widget.
///
/// Watched from [AnchorApp] so it lives for the whole app session. Reacts to
/// every local notes change (edits, sync results) via the drift stream and to
/// login/logout via the active user id.

abstract class _$HomeWidgetSync extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  void runBuild() {
    build();
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    element.handleValue(ref, null);
  }
}

/// Routes home-screen widget taps into the app:
/// `anchorwidget://note/new`, `anchorwidget://note/<id>`, `anchorwidget://open`.

@ProviderFor(HomeWidgetLaunchHandler)
const homeWidgetLaunchHandlerProvider = HomeWidgetLaunchHandlerProvider._();

/// Routes home-screen widget taps into the app:
/// `anchorwidget://note/new`, `anchorwidget://note/<id>`, `anchorwidget://open`.
final class HomeWidgetLaunchHandlerProvider
    extends $NotifierProvider<HomeWidgetLaunchHandler, void> {
  /// Routes home-screen widget taps into the app:
  /// `anchorwidget://note/new`, `anchorwidget://note/<id>`, `anchorwidget://open`.
  const HomeWidgetLaunchHandlerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeWidgetLaunchHandlerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeWidgetLaunchHandlerHash();

  @$internal
  @override
  HomeWidgetLaunchHandler create() => HomeWidgetLaunchHandler();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$homeWidgetLaunchHandlerHash() =>
    r'94cdd7af3d258eef3c9900608810d22b1ac0ede3';

/// Routes home-screen widget taps into the app:
/// `anchorwidget://note/new`, `anchorwidget://note/<id>`, `anchorwidget://open`.

abstract class _$HomeWidgetLaunchHandler extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  void runBuild() {
    build();
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    element.handleValue(ref, null);
  }
}
