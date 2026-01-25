import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' as drift;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/network/dio_provider.dart';
import '../../domain/note_share.dart';
import '../../domain/note_share_permission.dart';

part 'note_shares_repository.g.dart';

@riverpod
NoteSharesRepository noteSharesRepository(Ref ref) {
  final dio = ref.watch(dioProvider);
  final db = ref.watch(appDatabaseProvider);
  return NoteSharesRepository(dio, db);
}

class NoteSharesRepository {
  final Dio _dio;
  final AppDatabase _db;

  NoteSharesRepository(this._dio, this._db);

  /// Share a note with another user.
  Future<NoteShare> shareNote(
    String noteId,
    String sharedWithUserId,
    NoteSharePermission permission,
  ) async {
    final response = await _dio.post(
      '/api/notes/$noteId/shares',
      data: {
        'sharedWithUserId': sharedWithUserId,
        'permission': permission.name,
      },
    );

    final share = NoteShare.fromJson(response.data as Map<String, dynamic>);

    // Update local database with new shareIds
    await _updateLocalShareIds(noteId);

    return share;
  }

  /// Get all shares for a note.
  Future<List<NoteShare>> getNoteShares(String noteId) async {
    final response = await _dio.get('/api/notes/$noteId/shares');

    final List<dynamic> data = response.data as List<dynamic>;
    return data
        .map((e) => NoteShare.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Update the permission level of an existing share.
  Future<NoteShare> updateNoteSharePermission(
    String noteId,
    String shareId,
    NoteSharePermission permission,
  ) async {
    final response = await _dio.patch(
      '/api/notes/$noteId/shares/$shareId',
      data: {'permission': permission.name},
    );

    return NoteShare.fromJson(response.data as Map<String, dynamic>);
  }

  /// Revoke a share (remove user's access to the note).
  Future<void> revokeShare(String noteId, String shareId) async {
    await _dio.delete('/api/notes/$noteId/shares/$shareId');

    // Update local database after revoking share
    await _updateLocalShareIds(noteId);
  }

  /// Update the local note's shareIds by fetching current shares from server.
  Future<void> _updateLocalShareIds(String noteId) async {
    try {
      // Fetch current shares from server
      final shares = await getNoteShares(noteId);

      // Extract user IDs from shares
      final shareUserIds = shares.map((s) => s.sharedWithUser.id).toList();

      // Update local database
      await (_db.update(_db.notes)..where((tbl) => tbl.id.equals(noteId)))
          .write(NotesCompanion(shareIds: drift.Value(jsonEncode(shareUserIds))));
    } catch (e) {
      // Silently fail - sync will eventually fix it
    }
  }
}
