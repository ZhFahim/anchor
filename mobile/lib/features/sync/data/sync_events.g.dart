// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_events.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(syncEvents)
final syncEventsProvider = SyncEventsProvider._();

final class SyncEventsProvider
    extends $FunctionalProvider<SyncEvents, SyncEvents, SyncEvents>
    with $Provider<SyncEvents> {
  SyncEventsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncEventsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncEventsHash();

  @$internal
  @override
  $ProviderElement<SyncEvents> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SyncEvents create(Ref ref) {
    return syncEvents(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SyncEvents value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SyncEvents>(value),
    );
  }
}

String _$syncEventsHash() => r'dc90809afa6412993689fa5a3e19a82992827431';
