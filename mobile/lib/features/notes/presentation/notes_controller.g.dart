// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notes_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider to track syncing state globally

@ProviderFor(SyncingState)
const syncingStateProvider = SyncingStateProvider._();

/// Provider to track syncing state globally
final class SyncingStateProvider extends $NotifierProvider<SyncingState, bool> {
  /// Provider to track syncing state globally
  const SyncingStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncingStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncingStateHash();

  @$internal
  @override
  SyncingState create() => SyncingState();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$syncingStateHash() => r'a600405735f2359d21f235cc42ccfdfd0e9c2c38';

/// Provider to track syncing state globally

abstract class _$SyncingState extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(NotesController)
const notesControllerProvider = NotesControllerProvider._();

final class NotesControllerProvider
    extends $StreamNotifierProvider<NotesController, List<Note>> {
  const NotesControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notesControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notesControllerHash();

  @$internal
  @override
  NotesController create() => NotesController();
}

String _$notesControllerHash() => r'e0e017df3fbd90aeb7068da1bf2f59c0baf35df0';

abstract class _$NotesController extends $StreamNotifier<List<Note>> {
  Stream<List<Note>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<List<Note>>, List<Note>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Note>>, List<Note>>,
              AsyncValue<List<Note>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(SearchQuery)
const searchQueryProvider = SearchQueryProvider._();

final class SearchQueryProvider extends $NotifierProvider<SearchQuery, String> {
  const SearchQueryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchQueryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchQueryHash();

  @$internal
  @override
  SearchQuery create() => SearchQuery();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$searchQueryHash() => r'99ff8829a2de8a3351c2c5a931316b171cd121ee';

abstract class _$SearchQuery extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// Provider to track selection mode state

@ProviderFor(SelectionMode)
const selectionModeProvider = SelectionModeProvider._();

/// Provider to track selection mode state
final class SelectionModeProvider
    extends $NotifierProvider<SelectionMode, bool> {
  /// Provider to track selection mode state
  const SelectionModeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectionModeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectionModeHash();

  @$internal
  @override
  SelectionMode create() => SelectionMode();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$selectionModeHash() => r'7c4ef78c428243bcf513370860e626143a8c75b4';

/// Provider to track selection mode state

abstract class _$SelectionMode extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// Provider to track selected note IDs

@ProviderFor(SelectedNoteIds)
const selectedNoteIdsProvider = SelectedNoteIdsProvider._();

/// Provider to track selected note IDs
final class SelectedNoteIdsProvider
    extends $NotifierProvider<SelectedNoteIds, Set<String>> {
  /// Provider to track selected note IDs
  const SelectedNoteIdsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedNoteIdsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedNoteIdsHash();

  @$internal
  @override
  SelectedNoteIds create() => SelectedNoteIds();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<String>>(value),
    );
  }
}

String _$selectedNoteIdsHash() => r'72f5639a9e051b238b7dc97ff19588dec8897550';

/// Provider to track selected note IDs

abstract class _$SelectedNoteIds extends $Notifier<Set<String>> {
  Set<String> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<Set<String>, Set<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Set<String>, Set<String>>,
              Set<String>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(TrashController)
const trashControllerProvider = TrashControllerProvider._();

final class TrashControllerProvider
    extends $StreamNotifierProvider<TrashController, List<Note>> {
  const TrashControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'trashControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$trashControllerHash();

  @$internal
  @override
  TrashController create() => TrashController();
}

String _$trashControllerHash() => r'bab1244e95ae3358ac5aba5bfaa843258f6987a3';

abstract class _$TrashController extends $StreamNotifier<List<Note>> {
  Stream<List<Note>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<List<Note>>, List<Note>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Note>>, List<Note>>,
              AsyncValue<List<Note>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(ArchiveController)
const archiveControllerProvider = ArchiveControllerProvider._();

final class ArchiveControllerProvider
    extends $StreamNotifierProvider<ArchiveController, List<Note>> {
  const ArchiveControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'archiveControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$archiveControllerHash();

  @$internal
  @override
  ArchiveController create() => ArchiveController();
}

String _$archiveControllerHash() => r'4fa865310cc5d1a6653e6982f26b1bbf51dba7d5';

abstract class _$ArchiveController extends $StreamNotifier<List<Note>> {
  Stream<List<Note>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<List<Note>>, List<Note>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Note>>, List<Note>>,
              AsyncValue<List<Note>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
