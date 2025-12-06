// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notes_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$syncingStateHash() => r'a600405735f2359d21f235cc42ccfdfd0e9c2c38';

/// Provider to track syncing state globally
///
/// Copied from [SyncingState].
@ProviderFor(SyncingState)
final syncingStateProvider =
    AutoDisposeNotifierProvider<SyncingState, bool>.internal(
      SyncingState.new,
      name: r'syncingStateProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$syncingStateHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SyncingState = AutoDisposeNotifier<bool>;
String _$notesControllerHash() => r'82c997dc332d506727ee6f10965053734816412e';

/// See also [NotesController].
@ProviderFor(NotesController)
final notesControllerProvider =
    AutoDisposeStreamNotifierProvider<NotesController, List<Note>>.internal(
      NotesController.new,
      name: r'notesControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$notesControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$NotesController = AutoDisposeStreamNotifier<List<Note>>;
String _$searchQueryHash() => r'99ff8829a2de8a3351c2c5a931316b171cd121ee';

/// See also [SearchQuery].
@ProviderFor(SearchQuery)
final searchQueryProvider =
    AutoDisposeNotifierProvider<SearchQuery, String>.internal(
      SearchQuery.new,
      name: r'searchQueryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$searchQueryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SearchQuery = AutoDisposeNotifier<String>;
String _$trashControllerHash() => r'bab1244e95ae3358ac5aba5bfaa843258f6987a3';

/// See also [TrashController].
@ProviderFor(TrashController)
final trashControllerProvider =
    AutoDisposeStreamNotifierProvider<TrashController, List<Note>>.internal(
      TrashController.new,
      name: r'trashControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$trashControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$TrashController = AutoDisposeStreamNotifier<List<Note>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
