// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reminder_scheduler.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Keeps the OS's pending notifications in step with the reminders in Drift.
///
/// Diffs what the device should hold against what it does hold, cancelling
/// the difference rather than rescheduling everything.

@ProviderFor(ReminderScheduler)
final reminderSchedulerProvider = ReminderSchedulerProvider._();

/// Keeps the OS's pending notifications in step with the reminders in Drift.
///
/// Diffs what the device should hold against what it does hold, cancelling
/// the difference rather than rescheduling everything.
final class ReminderSchedulerProvider
    extends $NotifierProvider<ReminderScheduler, void> {
  /// Keeps the OS's pending notifications in step with the reminders in Drift.
  ///
  /// Diffs what the device should hold against what it does hold, cancelling
  /// the difference rather than rescheduling everything.
  ReminderSchedulerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reminderSchedulerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reminderSchedulerHash();

  @$internal
  @override
  ReminderScheduler create() => ReminderScheduler();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$reminderSchedulerHash() => r'0ab0660c45c335733e27c63239ebdd723ee17eee';

/// Keeps the OS's pending notifications in step with the reminders in Drift.
///
/// Diffs what the device should hold against what it does hold, cancelling
/// the difference rather than rescheduling everything.

abstract class _$ReminderScheduler extends $Notifier<void> {
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
