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
final homeWidgetSyncProvider = HomeWidgetSyncProvider._();

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
  HomeWidgetSyncProvider._()
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

String _$homeWidgetSyncHash() => r'fd8f2d7b3e744fabe7a58dae7d51eb7cba40b1d8';

/// Mirrors the active notes list into the Android home-screen widget.
///
/// Watched from [AnchorApp] so it lives for the whole app session. Reacts to
/// every local notes change (edits, sync results) via the drift stream and to
/// login/logout via the active user id.

abstract class _$HomeWidgetSync extends $Notifier<void> {
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

/// Routes home-screen widget taps into the app while it is running:
/// `anchorwidget://note/new`, `anchorwidget://note/<id>`, `anchorwidget://open`.
///
/// Cold-start taps never reach this handler; [initializeApp] turns them into
/// the app's initial route before the first frame.

@ProviderFor(HomeWidgetLaunchHandler)
final homeWidgetLaunchHandlerProvider = HomeWidgetLaunchHandlerProvider._();

/// Routes home-screen widget taps into the app while it is running:
/// `anchorwidget://note/new`, `anchorwidget://note/<id>`, `anchorwidget://open`.
///
/// Cold-start taps never reach this handler; [initializeApp] turns them into
/// the app's initial route before the first frame.
final class HomeWidgetLaunchHandlerProvider
    extends $NotifierProvider<HomeWidgetLaunchHandler, void> {
  /// Routes home-screen widget taps into the app while it is running:
  /// `anchorwidget://note/new`, `anchorwidget://note/<id>`, `anchorwidget://open`.
  ///
  /// Cold-start taps never reach this handler; [initializeApp] turns them into
  /// the app's initial route before the first frame.
  HomeWidgetLaunchHandlerProvider._()
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
    r'3a604ab1a7e6034da87fcda23bca98cd74ca6fb3';

/// Routes home-screen widget taps into the app while it is running:
/// `anchorwidget://note/new`, `anchorwidget://note/<id>`, `anchorwidget://open`.
///
/// Cold-start taps never reach this handler; [initializeApp] turns them into
/// the app's initial route before the first frame.

abstract class _$HomeWidgetLaunchHandler extends $Notifier<void> {
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
