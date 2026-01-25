import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/repository/note_shares_repository.dart';
import '../data/repository/users_repository.dart';
import '../domain/note_share.dart';
import '../domain/note_share_permission.dart';
import '../domain/user_search_result.dart';

part 'share_note_controller.g.dart';

/// Controller for managing note shares for a specific note
@riverpod
class ShareNoteController extends _$ShareNoteController {
  @override
  Future<List<NoteShare>> build(String noteId) async {
    return _fetchShares();
  }

  Future<List<NoteShare>> _fetchShares() async {
    final repository = ref.read(noteSharesRepositoryProvider);
    return repository.getNoteShares(noteId);
  }

  /// Share the note with a user
  Future<void> shareNote(
    String sharedWithUserId,
    NoteSharePermission permission,
  ) async {
    final repository = ref.read(noteSharesRepositoryProvider);
    try {
      await repository.shareNote(noteId, sharedWithUserId, permission);
      ref.invalidateSelf();
    } catch (e) {
      debugPrint('Share note failed: $e');
      rethrow;
    }
  }

  /// Update an existing share's permission
  Future<void> updateNoteSharePermission(
    String shareId,
    NoteSharePermission permission,
  ) async {
    final repository = ref.read(noteSharesRepositoryProvider);
    try {
      await repository.updateNoteSharePermission(noteId, shareId, permission);
      ref.invalidateSelf();
    } catch (e) {
      debugPrint('Update share permission failed: $e');
      rethrow;
    }
  }

  /// Revoke a share
  Future<void> revokeShare(String shareId) async {
    final repository = ref.read(noteSharesRepositoryProvider);
    try {
      await repository.revokeShare(noteId, shareId);
      ref.invalidateSelf();
    } catch (e) {
      debugPrint('Revoke share failed: $e');
      rethrow;
    }
  }
}

/// Provider for searching users
@riverpod
class UserSearch extends _$UserSearch {
  @override
  Future<List<UserSearchResult>> build(String query) async {
    if (query.trim().length < 2) {
      return [];
    }
    final repository = ref.read(usersRepositoryProvider);
    return repository.searchUsers(query);
  }
}
