import 'dart:async';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/network/sync_requester.dart';
import '../../../../core/network/sync_upload_snapshot.dart';
import '../../../../core/providers/active_user_id_provider.dart';
import '../../domain/tag.dart' as domain;

part 'tags_repository.g.dart';

@riverpod
TagsRepository tagsRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  final dio = ref.watch(dioProvider);
  const storage = FlutterSecureStorage();
  final userId = ref.watch(activeUserIdProvider)!;
  return TagsRepository(db, dio, storage, userId);
}

class TagsRepository {
  final AppDatabase _db;
  final Dio _dio;
  final FlutterSecureStorage _storage;
  final String _userId;

  TagsRepository(this._db, this._dio, this._storage, this._userId);

  String get _lastTagSyncKey => 'last_tags_synced_at_$_userId';

  // Watch all tags (excluding deleted) with note counts
  // This watches both tags and noteTags tables so counts update in realtime
  Stream<List<domain.Tag>> watchTags() {
    // Use a custom query or a join to count notes per tag
    // Drift doesn't support aggregation in simple joins easily in dart objects
    // But we can use a join and count in memory since tag list is usually small

    final query =
        _db.select(_db.tags).join([
            drift.leftOuterJoin(
              _db.noteTags,
              _db.noteTags.tagId.equalsExp(_db.tags.id),
            ),
            drift.leftOuterJoin(
              _db.notes,
              _db.notes.id.equalsExp(_db.noteTags.noteId),
            ),
          ])
          ..where(_db.tags.isDeleted.equals(false))
          ..orderBy([
            drift.OrderingTerm(
              expression: _db.tags.name,
              mode: drift.OrderingMode.asc,
            ),
          ]);

    return query.watch().map((rows) {
      final tagMap = <String, domain.Tag>{};
      final tagCounts = <String, int>{};

      for (final row in rows) {
        final tag = row.readTable(_db.tags);
        final noteTag = row.readTableOrNull(_db.noteTags);
        final note = row.readTableOrNull(_db.notes);

        if (!tagMap.containsKey(tag.id)) {
          tagMap[tag.id] = _mapToDomain(tag);
        }

        // Only count active, non-archived notes
        if (noteTag != null && note != null) {
          final isActive = note.state == 'active' && !note.isArchived;
          if (isActive) {
            tagCounts[tag.id] = (tagCounts[tag.id] ?? 0) + 1;
          }
        }
      }

      // Update counts
      return tagMap.values.map((tag) {
        return tag.copyWith(
          count: domain.TagCount(notes: tagCounts[tag.id] ?? 0),
        );
      }).toList();
    });
  }

  // Get all tags (for dropdowns, etc)
  Future<List<domain.Tag>> getTags() async {
    final query = _db.select(_db.tags)
      ..where((tbl) => tbl.isDeleted.equals(false))
      ..orderBy([
        (t) => drift.OrderingTerm(
          expression: t.name,
          mode: drift.OrderingMode.asc,
        ),
      ]);
    final rows = await query.get();
    return rows.map((row) => _mapToDomain(row)).toList();
  }

  // Get tag by id
  Future<domain.Tag?> getTag(String id) async {
    final row = await (_db.select(
      _db.tags,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    return row != null ? _mapToDomain(row) : null;
  }

  // Create tag - strictly local first
  Future<domain.Tag> createTag(domain.Tag tag) async {
    final tagWithTimestamp = tag.copyWith(updatedAt: DateTime.now().toUtc());

    // Save locally
    await _db
        .into(_db.tags)
        .insert(
          _mapToData(tagWithTimestamp, isSynced: false),
          mode: drift.InsertMode.insertOrReplace,
        );

    // Trigger coordinated sync in background
    scheduleAppSync(trigger: 'TagsRepo.createTag');

    return tagWithTimestamp;
  }

  // Update tag
  Future<void> updateTag(domain.Tag tag) async {
    final tagWithTimestamp = tag.copyWith(updatedAt: DateTime.now().toUtc());

    await _db
        .update(_db.tags)
        .replace(_mapToData(tagWithTimestamp, isSynced: false));

    scheduleAppSync(trigger: 'TagsRepo.updateTag');
  }

  // Delete tag
  Future<void> deleteTag(String id) async {
    final now = DateTime.now().toUtc();
    // Mark as deleted locally (tombstone)
    await (_db.update(_db.tags)..where((tbl) => tbl.id.equals(id))).write(
      TagsCompanion(
        isDeleted: const drift.Value(true),
        updatedAt: drift.Value(now),
        isSynced: const drift.Value(false),
      ),
    );
    // Remove tag associations locally
    await (_db.delete(_db.noteTags)..where((tbl) => tbl.tagId.equals(id))).go();

    scheduleAppSync(trigger: 'TagsRepo.deleteTag');
  }

  // Get tags for a note
  Future<List<String>> getTagIdsForNote(String noteId) async {
    final rows = await (_db.select(
      _db.noteTags,
    )..where((tbl) => tbl.noteId.equals(noteId))).get();
    return rows.map((row) => row.tagId).toList();
  }

  // Watch tags for a note
  Stream<List<domain.Tag>> watchTagsForNote(String noteId) {
    final query =
        _db.select(_db.noteTags).join([
            drift.innerJoin(
              _db.tags,
              _db.tags.id.equalsExp(_db.noteTags.tagId),
            ),
          ])
          ..where(_db.noteTags.noteId.equals(noteId))
          ..where(_db.tags.isDeleted.equals(false));

    return query.watch().map((rows) {
      return rows.map((row) => _mapToDomain(row.readTable(_db.tags))).toList();
    });
  }

  // Set tags for a note
  Future<void> setTagsForNote(String noteId, List<String> tagIds) async {
    await _db.transaction(() async {
      // Delete existing associations
      await (_db.delete(
        _db.noteTags,
      )..where((tbl) => tbl.noteId.equals(noteId))).go();

      if (tagIds.isEmpty) return;

      // Use batch insert for better performance
      await _db.batch((batch) {
        batch.insertAll(
          _db.noteTags,
          tagIds
              .map(
                (tagId) => NoteTagsCompanion(
                  noteId: drift.Value(noteId),
                  tagId: drift.Value(tagId),
                ),
              )
              .toList(),
          mode: drift.InsertMode.insertOrReplace,
        );
      });
    });
  }

  // Sync tags with server
  Future<void> sync() async {
    final cycleStart = DateTime.now();
    try {
      final payload = await _collectLocalChanges();
      AppLogger.instance.info(
        'Tags',
        'Tags sync start: uploading=${payload.localChanges.length} '
            'lastSyncedAt=${payload.lastSyncedAt}',
      );
      final response = await _postSync(payload);

      await _db.transaction(() async {
        final postApplySnapshot = await _applyServerChanges(
          response.serverChanges,
          response.processedIds,
          payload.uploadSnapshots,
        );
        await _markProcessedTagsSynced(
          response.processedIds,
          postApplySnapshot,
        );
      });

      await _storage.write(key: _lastTagSyncKey, value: response.syncedAt);
      AppLogger.instance.info(
        'Tags',
        'Tags sync done in '
            '${DateTime.now().difference(cycleStart).inMilliseconds}ms: '
            'serverChanges=${response.serverChanges.length} '
            'processed=${response.processedIds.length} '
            'syncedAt=${response.syncedAt}',
      );
    } catch (e, stack) {
      AppLogger.instance.error(
        'Tags',
        'Tags sync failed after '
            '${DateTime.now().difference(cycleStart).inMilliseconds}ms',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  Future<_TagSyncPayload> _collectLocalChanges() async {
    final lastSyncedAt = await _storage.read(key: _lastTagSyncKey);
    final unsyncedRows = await (_db.select(
      _db.tags,
    )..where((tbl) => tbl.isSynced.equals(false))).get();

    return _TagSyncPayload(
      lastSyncedAt: lastSyncedAt,
      localChanges: unsyncedRows.map(_tagToSyncChange).toList(),
      uploadSnapshots: SyncUploadSnapshot({
        for (final row in unsyncedRows) row.id: row.updatedAt,
      }),
    );
  }

  Map<String, dynamic> _tagToSyncChange(Tag row) {
    final tag = _mapToDomain(row);
    return {
      'id': tag.id,
      'name': tag.name,
      'color': tag.color,
      'updatedAt': tag.updatedAt?.toUtc().toIso8601String(),
      'isDeleted': tag.isDeleted,
    };
  }

  Future<_TagsSyncResponse> _postSync(_TagSyncPayload payload) async {
    final response = await _dio.post(
      '/api/tags/sync',
      data: {
        'lastSyncedAt': payload.lastSyncedAt,
        'changes': payload.localChanges,
      },
    );

    final data = response.data as Map<String, dynamic>;
    return _TagsSyncResponse(
      serverChanges: (data['serverChanges'] as List)
          .map((e) => domain.Tag.fromJson(e as Map<String, dynamic>))
          .toList(),
      processedIds: (data['processedIds'] as List?)?.cast<String>() ?? [],
      syncedAt: data['syncedAt'] as String,
    );
  }

  Future<SyncUploadSnapshot> _applyServerChanges(
    List<domain.Tag> serverChanges,
    List<String> processedIds,
    SyncUploadSnapshot uploadSnapshots,
  ) async {
    // See notes_repository for the rationale: default to the pre-upload
    // snapshot, overwrite with the post-write value for ids we actually apply.
    final postApply = <String, DateTime?>{
      for (final id in processedIds)
        if (uploadSnapshots.contains(id)) id: uploadSnapshots[id],
    };

    for (final serverTag in serverChanges) {
      final localTag = await _getLocalTagRow(serverTag.id);
      final uploadedThisCycle = uploadSnapshots.contains(serverTag.id);

      if (localTag != null &&
          uploadSnapshots.hasChanged(serverTag.id, localTag.updatedAt)) {
        continue;
      }

      if (serverTag.isDeleted) {
        await _removeLocalTag(serverTag.id);
        if (uploadedThisCycle) {
          postApply[serverTag.id] = null;
        }
        continue;
      }

      await _upsertServerTag(
        serverTag,
        localTag,
        forceApply: uploadedThisCycle,
      );

      if (uploadedThisCycle) {
        final applied = await _getLocalTagRow(serverTag.id);
        postApply[serverTag.id] = applied?.updatedAt;
      }
    }

    return SyncUploadSnapshot(postApply);
  }

  Future<Tag?> _getLocalTagRow(String id) {
    return (_db.select(
      _db.tags,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  Future<void> _removeLocalTag(String id) async {
    await (_db.delete(_db.noteTags)..where((tbl) => tbl.tagId.equals(id))).go();
    await (_db.delete(_db.tags)..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<void> _upsertServerTag(
    domain.Tag serverTag,
    Tag? localTag, {
    required bool forceApply,
  }) async {
    if (localTag == null) {
      await _db
          .into(_db.tags)
          .insert(
            _mapToData(serverTag, isSynced: true),
            mode: drift.InsertMode.insertOrReplace,
          );
      return;
    }

    if (!forceApply && !_serverShouldReplaceLocal(serverTag, localTag)) {
      return;
    }

    await (_db.update(
      _db.tags,
    )..where((tbl) => tbl.id.equals(serverTag.id))).write(
      TagsCompanion(
        name: drift.Value(serverTag.name),
        color: drift.Value(serverTag.color),
        updatedAt: drift.Value(serverTag.updatedAt),
        isSynced: const drift.Value(true),
        isDeleted: const drift.Value(false),
      ),
    );
  }

  bool _serverShouldReplaceLocal(domain.Tag serverTag, Tag localTag) {
    final serverUpdatedAt = serverTag.updatedAt;
    final localUpdatedAt = localTag.updatedAt;

    return serverUpdatedAt != null &&
        (localUpdatedAt == null ||
            serverUpdatedAt.isAfter(localUpdatedAt) ||
            serverUpdatedAt.isAtSameMomentAs(localUpdatedAt));
  }

  Future<void> _markProcessedTagsSynced(
    List<String> processedIds,
    SyncUploadSnapshot postApplySnapshot,
  ) async {
    for (final id in processedIds) {
      final tag = await _getLocalTagRow(id);
      if (!postApplySnapshot.isCurrent(id, tag?.updatedAt)) continue;

      if (tag != null && tag.isDeleted) {
        await _removeLocalTag(id);
      } else if (tag != null) {
        await (_db.update(_db.tags)..where((tbl) => tbl.id.equals(id))).write(
          const TagsCompanion(isSynced: drift.Value(true)),
        );
      }
    }
  }

  domain.Tag _mapToDomain(Tag row, {int noteCount = 0}) {
    return domain.Tag(
      id: row.id,
      name: row.name,
      color: row.color,
      updatedAt: row.updatedAt,
      isSynced: row.isSynced,
      isDeleted: row.isDeleted,
      count: domain.TagCount(notes: noteCount),
    );
  }

  Tag _mapToData(domain.Tag tag, {required bool isSynced}) {
    return Tag(
      id: tag.id,
      name: tag.name,
      color: tag.color,
      updatedAt: tag.updatedAt,
      isSynced: isSynced,
      isDeleted: tag.isDeleted,
    );
  }
}

class _TagSyncPayload {
  final String? lastSyncedAt;
  final List<Map<String, dynamic>> localChanges;
  final SyncUploadSnapshot uploadSnapshots;

  _TagSyncPayload({
    required this.lastSyncedAt,
    required this.localChanges,
    required this.uploadSnapshots,
  });
}

class _TagsSyncResponse {
  final List<domain.Tag> serverChanges;
  final List<String> processedIds;
  final String syncedAt;

  _TagsSyncResponse({
    required this.serverChanges,
    required this.processedIds,
    required this.syncedAt,
  });
}
