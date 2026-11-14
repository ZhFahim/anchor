import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/database/app_database.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/logging/log_tags.dart';
import '../../notes/data/repository/note_attachments_repository.dart';
import '../../share_target/data/share_inbox.dart';

class LocalAccountData {
  const LocalAccountData._(
    this._userId,
    this._db,
    this._attachments,
    this._noteIds,
  );

  final String _userId;
  final AppDatabase _db;
  final NoteAttachmentsRepository _attachments;

  final List<String>? _noteIds;

  /// Call before the database closes.
  static Future<LocalAccountData> read(
    String userId, {
    required AppDatabase db,
    required NoteAttachmentsRepository attachments,
  }) async {
    List<String>? noteIds;
    try {
      noteIds = await (db.selectOnly(
        db.notes,
      )..addColumns([db.notes.id])).map((row) => row.read(db.notes.id)!).get();
    } catch (error) {
      _warn('note list', error);
    }
    return LocalAccountData._(userId, db, attachments, noteIds);
  }

  /// Never throws.
  Future<void> remove() async {
    final noteIds = _noteIds;
    final steps = [
      noteIds != null,
      await _attempt('attachments', () async {
        for (final noteId in noteIds ?? const <String>[]) {
          await _attachments.deleteLocalFilesForNote(noteId);
        }
      }),
      await _attempt('database', () async {
        await _db.close();
        await deleteUserDatabaseFiles(_userId);
      }),
      await _attempt('pending shares', () async {
        await (await ShareInbox.find())?.removeEntriesOf(_userId);
      }),
      await _attempt(
        'profile photos',
        CachedNetworkImageProvider.defaultCacheManager.emptyCache,
      ),
    ];
    if (steps.every((isDone) => isDone)) await AppLogger.instance.clear();
  }

  Future<bool> _attempt(String what, Future<void> Function() remove) async {
    try {
      await remove();
      return true;
    } catch (error) {
      _warn(what, error);
      return false;
    }
  }

  static void _warn(String what, Object error) {
    AppLogger.instance.warn(
      LogTags.auth,
      'Removing the deleted account’s $what failed',
      error: error,
    );
  }
}
