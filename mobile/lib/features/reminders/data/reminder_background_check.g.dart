// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reminder_background_check.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Keeps the background check registered while someone is signed in, so a
/// reminder set on another device rings here with the app closed.

@ProviderFor(reminderBackgroundCheck)
final reminderBackgroundCheckProvider = ReminderBackgroundCheckProvider._();

/// Keeps the background check registered while someone is signed in, so a
/// reminder set on another device rings here with the app closed.

final class ReminderBackgroundCheckProvider
    extends $FunctionalProvider<void, void, void>
    with $Provider<void> {
  /// Keeps the background check registered while someone is signed in, so a
  /// reminder set on another device rings here with the app closed.
  ReminderBackgroundCheckProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reminderBackgroundCheckProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reminderBackgroundCheckHash();

  @$internal
  @override
  $ProviderElement<void> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  void create(Ref ref) {
    return reminderBackgroundCheck(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$reminderBackgroundCheckHash() =>
    r'5e8fe5fd5df3f42f435e5ee22de7178862a1efba';
