// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reminder_tap_handler.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Opens the note behind a reminder the user tapped while the app was running.
///
/// Cold-start taps are handled by [initializeApp] instead.

@ProviderFor(ReminderTapHandler)
final reminderTapHandlerProvider = ReminderTapHandlerProvider._();

/// Opens the note behind a reminder the user tapped while the app was running.
///
/// Cold-start taps are handled by [initializeApp] instead.
final class ReminderTapHandlerProvider
    extends $NotifierProvider<ReminderTapHandler, void> {
  /// Opens the note behind a reminder the user tapped while the app was running.
  ///
  /// Cold-start taps are handled by [initializeApp] instead.
  ReminderTapHandlerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reminderTapHandlerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reminderTapHandlerHash();

  @$internal
  @override
  ReminderTapHandler create() => ReminderTapHandler();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$reminderTapHandlerHash() =>
    r'7135eadc4497b4db82b6304f29c8a34c32bd2c20';

/// Opens the note behind a reminder the user tapped while the app was running.
///
/// Cold-start taps are handled by [initializeApp] instead.

abstract class _$ReminderTapHandler extends $Notifier<void> {
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
