// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'missed_reminders.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(rungReminders)
final rungRemindersProvider = RungRemindersProvider._();

final class RungRemindersProvider
    extends $FunctionalProvider<RungReminders, RungReminders, RungReminders>
    with $Provider<RungReminders> {
  RungRemindersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'rungRemindersProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$rungRemindersHash();

  @$internal
  @override
  $ProviderElement<RungReminders> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RungReminders create(Ref ref) {
    return rungReminders(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RungReminders value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RungReminders>(value),
    );
  }
}

String _$rungRemindersHash() => r'8296e8d970e939e336891eb189e049d8df38ac13';
