// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'share_note_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Controller for managing note shares for a specific note

@ProviderFor(ShareNoteController)
const shareNoteControllerProvider = ShareNoteControllerFamily._();

/// Controller for managing note shares for a specific note
final class ShareNoteControllerProvider
    extends $AsyncNotifierProvider<ShareNoteController, List<NoteShare>> {
  /// Controller for managing note shares for a specific note
  const ShareNoteControllerProvider._({
    required ShareNoteControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'shareNoteControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$shareNoteControllerHash();

  @override
  String toString() {
    return r'shareNoteControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ShareNoteController create() => ShareNoteController();

  @override
  bool operator ==(Object other) {
    return other is ShareNoteControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$shareNoteControllerHash() =>
    r'b08043bdc50b1c4ee25be89ff07b281d4dacb906';

/// Controller for managing note shares for a specific note

final class ShareNoteControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          ShareNoteController,
          AsyncValue<List<NoteShare>>,
          List<NoteShare>,
          FutureOr<List<NoteShare>>,
          String
        > {
  const ShareNoteControllerFamily._()
    : super(
        retry: null,
        name: r'shareNoteControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Controller for managing note shares for a specific note

  ShareNoteControllerProvider call(String noteId) =>
      ShareNoteControllerProvider._(argument: noteId, from: this);

  @override
  String toString() => r'shareNoteControllerProvider';
}

/// Controller for managing note shares for a specific note

abstract class _$ShareNoteController extends $AsyncNotifier<List<NoteShare>> {
  late final _$args = ref.$arg as String;
  String get noteId => _$args;

  FutureOr<List<NoteShare>> build(String noteId);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref = this.ref as $Ref<AsyncValue<List<NoteShare>>, List<NoteShare>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<NoteShare>>, List<NoteShare>>,
              AsyncValue<List<NoteShare>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// Provider for searching users

@ProviderFor(UserSearch)
const userSearchProvider = UserSearchFamily._();

/// Provider for searching users
final class UserSearchProvider
    extends $AsyncNotifierProvider<UserSearch, List<UserSearchResult>> {
  /// Provider for searching users
  const UserSearchProvider._({
    required UserSearchFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'userSearchProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$userSearchHash();

  @override
  String toString() {
    return r'userSearchProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  UserSearch create() => UserSearch();

  @override
  bool operator ==(Object other) {
    return other is UserSearchProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$userSearchHash() => r'a22cd927bc6df21caaa720023d1e580f1996ec22';

/// Provider for searching users

final class UserSearchFamily extends $Family
    with
        $ClassFamilyOverride<
          UserSearch,
          AsyncValue<List<UserSearchResult>>,
          List<UserSearchResult>,
          FutureOr<List<UserSearchResult>>,
          String
        > {
  const UserSearchFamily._()
    : super(
        retry: null,
        name: r'userSearchProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider for searching users

  UserSearchProvider call(String query) =>
      UserSearchProvider._(argument: query, from: this);

  @override
  String toString() => r'userSearchProvider';
}

/// Provider for searching users

abstract class _$UserSearch extends $AsyncNotifier<List<UserSearchResult>> {
  late final _$args = ref.$arg as String;
  String get query => _$args;

  FutureOr<List<UserSearchResult>> build(String query);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref =
        this.ref
            as $Ref<AsyncValue<List<UserSearchResult>>, List<UserSearchResult>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<UserSearchResult>>,
                List<UserSearchResult>
              >,
              AsyncValue<List<UserSearchResult>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
