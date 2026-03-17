import 'dart:io';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/network/connectivity_provider.dart';
import '../../../../core/network/dio_provider.dart';
import '../../domain/note_attachment.dart' as domain;

part 'note_attachments_repository.g.dart';

@riverpod
NoteAttachmentsRepository noteAttachmentsRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  final dio = ref.watch(dioProvider);

  void triggerSync() {
    ref.read(syncManagerProvider.notifier).manualSync();
  }

  return NoteAttachmentsRepository(db, dio, triggerSync);
}

class NoteAttachmentsRepository {
  final AppDatabase _db;
  final Dio _dio;
  final void Function() _triggerSync;

  /// In-flight downloads keyed by attachmentId to deduplicate concurrent
  /// requests for the same file.
  final Map<String, Future<String>> _activeDownloads = {};

  NoteAttachmentsRepository(this._db, this._dio, this._triggerSync);

  /// Watch attachments for a note reactively (excludes pending-delete)
  Stream<List<domain.NoteAttachment>> watchAttachments(String noteId) {
    return (_db.select(_db.noteAttachments)
          ..where(
            (tbl) =>
                tbl.noteId.equals(noteId) &
                tbl.syncStatus
                    .equals(domain.AttachmentSyncStatus.pendingDelete.dbValue)
                    .not(),
          )
          ..orderBy([(tbl) => drift.OrderingTerm(expression: tbl.position)]))
        .watch()
        .map((rows) => rows.map(_mapToDomain).toList());
  }

  /// Fetch attachments for a batch of notes from the server and update local DB.
  Future<void> fetchAttachmentsForNotes(List<String> noteIds) async {
    for (final noteId in noteIds) {
      try {
        await fetchAttachments(noteId);
      } catch (e) {
        debugPrint('Failed to fetch attachments for $noteId: $e');
      }
    }
  }

  /// Fetch attachments from server and update local DB
  Future<List<domain.NoteAttachment>> fetchAttachments(String noteId) async {
    final response = await _dio.get('/api/notes/$noteId/attachments');
    final items = (response.data as List)
        .map((e) => domain.NoteAttachment.fromJson(e as Map<String, dynamic>))
        .toList();

    // Find orphaned files (attachments that are no longer in the server list)
    final orphanedPaths = <String>[];

    await _db.transaction(() async {
      // Remove attachments not in server list
      final serverIds = items.map((a) => a.id).toSet();
      final localRows = await (_db.select(
        _db.noteAttachments,
      )..where((tbl) => tbl.noteId.equals(noteId))).get();

      for (final row in localRows) {
        if (row.syncStatus ==
            domain.AttachmentSyncStatus.pendingUpload.dbValue) {
          continue;
        }
        if (row.syncStatus ==
            domain.AttachmentSyncStatus.pendingDelete.dbValue) {
          continue;
        }
        if (!serverIds.contains(row.serverAttachmentId ?? row.id)) {
          if (row.localPath != null) {
            orphanedPaths.add(row.localPath!);
          }
          await (_db.delete(
            _db.noteAttachments,
          )..where((tbl) => tbl.id.equals(row.id))).go();
        }
      }

      // Upsert server attachments
      for (final attachment in items) {
        final existing =
            await (_db.select(_db.noteAttachments)
                  ..where(
                    (tbl) =>
                        tbl.id.equals(attachment.id) |
                        tbl.serverAttachmentId.equals(attachment.id),
                  )
                  ..limit(1))
                .getSingleOrNull();

        await _db
            .into(_db.noteAttachments)
            .insertOnConflictUpdate(
              NoteAttachmentsCompanion.insert(
                id: attachment.id,
                noteId: attachment.noteId,
                type: attachment.type.name,
                originalFilename: attachment.originalFilename,
                mimeType: attachment.mimeType,
                fileSize: attachment.fileSize,
                position: drift.Value(attachment.position),
                localPath: drift.Value(existing?.localPath),
                syncStatus: drift.Value(
                  domain.AttachmentSyncStatus.synced.dbValue,
                ),
                serverAttachmentId: drift.Value(attachment.id),
                uploadedByUserId: drift.Value(attachment.uploadedByUserId),
              ),
            );
      }
    });

    // Delete orphaned files after the transaction has committed
    for (final p in orphanedPaths) {
      try {
        await File(p).delete();
      } catch (e) {
        debugPrint('Failed to delete orphaned file $p: $e');
      }
    }

    return items;
  }

  /// Returns true if the note has any attachments with unsynced status
  Future<bool> hasPendingAttachmentsForNote(String noteId) async {
    final rows =
        await (_db.select(_db.noteAttachments)..where(
              (tbl) =>
                  tbl.noteId.equals(noteId) &
                  tbl.syncStatus
                      .equals(domain.AttachmentSyncStatus.synced.dbValue)
                      .not(),
            ))
            .get();
    return rows.isNotEmpty;
  }

  /// Download attachment file and cache locally.
  /// Deduplicates concurrent requests for the same attachment and uses
  /// atomic temp-file writes to prevent partial files from being served.
  Future<String> downloadAttachment(
    String noteId,
    String attachmentId,
    String filename,
  ) async {
    final cacheDir = await getApplicationCacheDirectory();
    final attachmentDir = Directory(
      path.join(cacheDir.path, 'attachments', noteId),
    );
    if (!attachmentDir.existsSync()) {
      attachmentDir.createSync(recursive: true);
    }

    final filePath = path.join(attachmentDir.path, '$attachmentId-$filename');
    final file = File(filePath);

    // Return cached file if it exists and is non-empty
    if (file.existsSync() && file.lengthSync() > 0) {
      return filePath;
    }
    // Clean up zero-byte remnant from a previous interrupted download
    if (file.existsSync()) {
      file.deleteSync();
    }

    // Deduplicate
    if (_activeDownloads.containsKey(attachmentId)) {
      return _activeDownloads[attachmentId]!;
    }

    final future = _doDownload(noteId, attachmentId, filePath);
    _activeDownloads[attachmentId] = future;
    try {
      return await future;
    } finally {
      _activeDownloads.remove(attachmentId);
    }
  }

  /// Performs the actual download to a temp file, then atomically renames.
  Future<String> _doDownload(
    String noteId,
    String attachmentId,
    String filePath,
  ) async {
    final tmpPath = '$filePath.tmp';
    try {
      await _dio.download(
        '/api/notes/$noteId/attachments/$attachmentId',
        tmpPath,
        options: Options(receiveTimeout: const Duration(seconds: 120)),
      );

      final tmpFile = File(tmpPath);
      if (!tmpFile.existsSync() || tmpFile.lengthSync() == 0) {
        throw Exception('Download produced empty file');
      }

      // Atomic rename — on the same filesystem this is instant
      await tmpFile.rename(filePath);
    } catch (e) {
      // Clean up partial temp file
      try {
        File(tmpPath).deleteSync();
      } catch (_) {}
      rethrow;
    }

    // Update local path in DB so stream watchers pick up the change
    await (_db.update(_db.noteAttachments)..where(
          (tbl) =>
              tbl.noteId.equals(noteId) &
              (tbl.id.equals(attachmentId) |
                  tbl.serverAttachmentId.equals(attachmentId)),
        ))
        .write(NoteAttachmentsCompanion(localPath: drift.Value(filePath)));

    return filePath;
  }

  /// Delete attachment
  Future<void> deleteAttachment(String noteId, String attachmentId) async {
    final rows =
        await (_db.select(_db.noteAttachments)..where(
              (tbl) =>
                  tbl.noteId.equals(noteId) &
                  tbl.syncStatus
                      .equals(domain.AttachmentSyncStatus.pendingDelete.dbValue)
                      .not() &
                  (tbl.id.equals(attachmentId) |
                      tbl.serverAttachmentId.equals(attachmentId)),
            ))
            .get();

    if (rows.isEmpty) return;

    final row = rows.first;
    if (row.syncStatus == domain.AttachmentSyncStatus.pendingUpload.dbValue) {
      if (row.localPath != null) {
        try {
          await File(row.localPath!).delete();
        } catch (e) {
          debugPrint('Failed to delete local file ${row.localPath}: $e');
        }
      }
      await (_db.delete(
        _db.noteAttachments,
      )..where((tbl) => tbl.id.equals(row.id))).go();
    } else {
      await (_db.update(
        _db.noteAttachments,
      )..where((tbl) => tbl.id.equals(row.id))).write(
        NoteAttachmentsCompanion(
          syncStatus: drift.Value(
            domain.AttachmentSyncStatus.pendingDelete.dbValue,
          ),
        ),
      );
    }

    await _markNoteUnsynced(noteId);
    _triggerSync();
  }

  /// Add attachment: copy to persistent storage, insert into DB
  Future<String> addAttachment(
    String noteId,
    String sourceFilePath,
    String mimeType,
    String originalFilename,
  ) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final localId = const Uuid().v4();
    final safeName = path.basename(originalFilename);
    final persistentPath = path.join(
      docsDir.path,
      'attachments',
      noteId,
      '$localId-$safeName',
    );

    final attachmentDir = Directory(path.dirname(persistentPath));
    if (!attachmentDir.existsSync()) {
      attachmentDir.createSync(recursive: true);
    }
    await File(sourceFilePath).copy(persistentPath);

    final type = mimeType.startsWith('image/') ? 'image' : 'audio';

    try {
      await _db.transaction(() async {
        // Shift all existing attachments down to make room at position 0
        final tbl = _db.noteAttachments;
        await (_db.update(tbl)..where((t) => t.noteId.equals(noteId))).write(
          NoteAttachmentsCompanion.custom(
            position: tbl.position + const drift.Constant(1),
          ),
        );

        await _db
            .into(_db.noteAttachments)
            .insert(
              NoteAttachmentsCompanion.insert(
                id: localId,
                noteId: noteId,
                type: type,
                originalFilename: originalFilename,
                mimeType: mimeType,
                fileSize: File(persistentPath).lengthSync(),
                position: const drift.Value(0),
                localPath: drift.Value(persistentPath),
                syncStatus: drift.Value(
                  domain.AttachmentSyncStatus.pendingUpload.dbValue,
                ),
              ),
            );
      });
    } catch (e) {
      try {
        await File(persistentPath).delete();
      } catch (deleteErr) {
        debugPrint('Failed to clean up file $persistentPath: $deleteErr');
      }
      rethrow;
    }

    await _markNoteUnsynced(noteId);
    _triggerSync();
    return localId;
  }

  /// Mark the note as having pending local work so the sync loop picks it up
  Future<void> _markNoteUnsynced(String noteId) async {
    await (_db.update(_db.notes)..where((tbl) => tbl.id.equals(noteId))).write(
      const NotesCompanion(isSynced: drift.Value(false)),
    );
  }

  /// Sync pending uploads and deletes with server
  Future<void> sync() async {
    // 1. Process pending uploads
    final pendingUpload =
        await (_db.select(_db.noteAttachments)..where(
              (tbl) => tbl.syncStatus.equals(
                domain.AttachmentSyncStatus.pendingUpload.dbValue,
              ),
            ))
            .get();

    for (final row in pendingUpload) {
      if (row.localPath == null) continue;
      try {
        final attachment = await _uploadToServer(
          row.noteId,
          row.localPath!,
          row.mimeType,
          row.originalFilename,
        );

        // Move the local file from persistent (docs) to cache so the synced
        // record can reference it directly — avoids a redundant re-download.
        String? cachedPath;
        try {
          final cacheDir = await getApplicationCacheDirectory();
          final cacheAttachDir = Directory(
            path.join(cacheDir.path, 'attachments', attachment.noteId),
          );
          if (!cacheAttachDir.existsSync()) {
            cacheAttachDir.createSync(recursive: true);
          }
          cachedPath = path.join(
            cacheAttachDir.path,
            '${attachment.id}-${attachment.originalFilename}',
          );
          await File(row.localPath!).rename(cachedPath);
        } catch (e) {
          // Rename may fail across filesystems — fall back to delete.
          // The image will be re-downloaded on next view.
          debugPrint('Failed to move upload to cache: $e');
          cachedPath = null;
          try {
            await File(row.localPath!).delete();
          } catch (_) {}
        }

        // Atomically insert the synced record (with cached localPath) and
        // delete the pending row to prevent duplicates.
        await _db.transaction(() async {
          await _db
              .into(_db.noteAttachments)
              .insertOnConflictUpdate(
                NoteAttachmentsCompanion.insert(
                  id: attachment.id,
                  noteId: attachment.noteId,
                  type: attachment.type.name,
                  originalFilename: attachment.originalFilename,
                  mimeType: attachment.mimeType,
                  fileSize: attachment.fileSize,
                  position: drift.Value(attachment.position),
                  localPath: drift.Value(cachedPath),
                  syncStatus: drift.Value(
                    domain.AttachmentSyncStatus.synced.dbValue,
                  ),
                  serverAttachmentId: drift.Value(attachment.id),
                  uploadedByUserId: drift.Value(attachment.uploadedByUserId),
                ),
              );

          await (_db.delete(
            _db.noteAttachments,
          )..where((tbl) => tbl.id.equals(row.id))).go();
        });
      } catch (e) {
        debugPrint('Attachment upload failed for ${row.id}: $e');
        // Will retry next sync
      }
    }

    // 2. Process pending deletes
    final pendingDelete =
        await (_db.select(_db.noteAttachments)..where(
              (tbl) => tbl.syncStatus.equals(
                domain.AttachmentSyncStatus.pendingDelete.dbValue,
              ),
            ))
            .get();

    for (final row in pendingDelete) {
      final serverId = row.serverAttachmentId ?? row.id;
      try {
        await _dio.delete('/api/notes/${row.noteId}/attachments/$serverId');
        if (row.localPath != null) {
          try {
            await File(row.localPath!).delete();
          } catch (e) {
            debugPrint(
              'Failed to delete local file for attachment ${row.id}: $e',
            );
          }
        }
        await (_db.delete(
          _db.noteAttachments,
        )..where((tbl) => tbl.id.equals(row.id))).go();
      } catch (e) {
        debugPrint('Attachment delete failed for ${row.id}: $e');
        // Will retry next sync
      }
    }
  }

  /// Upload file to server and return the server attachment metadata
  Future<domain.NoteAttachment> _uploadToServer(
    String noteId,
    String localFilePath,
    String mimeType,
    String originalFilename,
  ) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        localFilePath,
        filename: originalFilename,
        contentType: DioMediaType.parse(mimeType),
      ),
    });

    final response = await _dio.post(
      '/api/notes/$noteId/attachments',
      data: formData,
    );

    return domain.NoteAttachment.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// Delete local attachment directories for a note without touching the DB
  Future<void> deleteLocalFilesForNote(String noteId) async {
    for (final dir in [
      await getApplicationDocumentsDirectory(),
      await getApplicationCacheDirectory(),
    ]) {
      final noteDir = Directory(path.join(dir.path, 'attachments', noteId));
      if (noteDir.existsSync()) {
        try {
          await noteDir.delete(recursive: true);
        } catch (e) {
          debugPrint('Failed to delete attachment dir ${noteDir.path}: $e');
        }
      }
    }
  }

  /// Delete all local attachment files and DB records for a note
  Future<void> deleteAllLocalForNote(String noteId) async {
    final rows = await (_db.select(
      _db.noteAttachments,
    )..where((tbl) => tbl.noteId.equals(noteId))).get();

    // Delete local files
    for (final row in rows) {
      if (row.localPath != null) {
        try {
          await File(row.localPath!).delete();
        } catch (e) {
          debugPrint('Failed to delete local file ${row.localPath}: $e');
        }
      }
    }

    // Delete all DB records for this note
    await (_db.delete(
      _db.noteAttachments,
    )..where((tbl) => tbl.noteId.equals(noteId))).go();

    // Remove attachment directories
    for (final dir in [
      await getApplicationDocumentsDirectory(),
      await getApplicationCacheDirectory(),
    ]) {
      final noteDir = Directory(path.join(dir.path, 'attachments', noteId));
      if (noteDir.existsSync()) {
        try {
          await noteDir.delete(recursive: true);
        } catch (e) {
          debugPrint('Failed to delete attachment dir ${noteDir.path}: $e');
        }
      }
    }
  }

  /// Evict cached attachment files that exceed the size threshold
  Future<void> evictCache({int maxCacheBytes = 500 * 1024 * 1024}) async {
    final cacheDir = await getApplicationCacheDirectory();
    final attachmentsDir = Directory(path.join(cacheDir.path, 'attachments'));
    if (!attachmentsDir.existsSync()) return;

    final files = <File>[];
    int totalSize = 0;

    await for (final entity in attachmentsDir.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is File && !entity.path.endsWith('.tmp')) {
        files.add(entity);
        totalSize += await entity.length();
      }
    }

    if (totalSize <= maxCacheBytes) return;

    // Sort by last accessed (oldest first)
    files.sort((a, b) {
      final aStat = a.statSync();
      final bStat = b.statSync();
      return aStat.accessed.compareTo(bStat.accessed);
    });

    for (final file in files) {
      if (totalSize <= maxCacheBytes) break;
      final size = await file.length();
      try {
        await file.delete();
        totalSize -= size;

        // Clear localPath in DB for evicted files
        await (_db.update(
          _db.noteAttachments,
        )..where((tbl) => tbl.localPath.equals(file.path))).write(
          const NoteAttachmentsCompanion(localPath: drift.Value(null)),
        );

        debugPrint(
          'Evicted cached attachment: ${path.basename(file.path)} ($size bytes)',
        );
      } catch (e) {
        debugPrint('Failed to evict cached file ${file.path}: $e');
      }
    }
  }

  domain.NoteAttachment _mapToDomain(NoteAttachment row) {
    return domain.NoteAttachment(
      id: row.serverAttachmentId ?? row.id,
      noteId: row.noteId,
      type: domain.AttachmentType.fromString(row.type),
      originalFilename: row.originalFilename,
      mimeType: row.mimeType,
      fileSize: row.fileSize,
      position: row.position,
      uploadedByUserId: row.uploadedByUserId,
      localPath: row.localPath,
      isPendingUpload:
          domain.AttachmentSyncStatus.fromString(row.syncStatus) ==
          domain.AttachmentSyncStatus.pendingUpload,
    );
  }
}
