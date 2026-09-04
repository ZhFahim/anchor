// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reminder_permissions.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Reads and asks for the grants a reminder needs.
///
/// The exact-alarm answer only arrives once the user is back from Android's
/// settings screen, so the grants are re-read on every resume.

@ProviderFor(ReminderPermissionsController)
final reminderPermissionsControllerProvider =
    ReminderPermissionsControllerProvider._();

/// Reads and asks for the grants a reminder needs.
///
/// The exact-alarm answer only arrives once the user is back from Android's
/// settings screen, so the grants are re-read on every resume.
final class ReminderPermissionsControllerProvider
    extends
        $AsyncNotifierProvider<
          ReminderPermissionsController,
          ReminderPermissions
        > {
  /// Reads and asks for the grants a reminder needs.
  ///
  /// The exact-alarm answer only arrives once the user is back from Android's
  /// settings screen, so the grants are re-read on every resume.
  ReminderPermissionsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reminderPermissionsControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reminderPermissionsControllerHash();

  @$internal
  @override
  ReminderPermissionsController create() => ReminderPermissionsController();
}

String _$reminderPermissionsControllerHash() =>
    r'a505ef4dd4d847a135a8cb575b4ecd1f6026dcce';

/// Reads and asks for the grants a reminder needs.
///
/// The exact-alarm answer only arrives once the user is back from Android's
/// settings screen, so the grants are re-read on every resume.

abstract class _$ReminderPermissionsController
    extends $AsyncNotifier<ReminderPermissions> {
  FutureOr<ReminderPermissions> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<ReminderPermissions>, ReminderPermissions>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ReminderPermissions>, ReminderPermissions>,
              AsyncValue<ReminderPermissions>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
