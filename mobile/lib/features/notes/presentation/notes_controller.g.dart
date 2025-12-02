// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notes_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$notesControllerHash() => r'f6422856b3956c1f3db9c19b4fca349f876b6c83';

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
