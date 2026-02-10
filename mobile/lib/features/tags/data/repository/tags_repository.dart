import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:drift/drift.dart' as drift;
import '../../../../core/database/app_database.dart';
import '../../../../core/network/dio_provider.dart';
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
    final tagWithTimestamp = tag.copyWith(updatedAt: DateTime.now());

    // Save locally
    await _db
        .into(_db.tags)
        .insert(
          _mapToData(tagWithTimestamp, isSynced: false),
          mode: drift.InsertMode.insertOrReplace,
        );

    // Trigger sync in background
    sync();

    return tagWithTimestamp;
  }

  // Update tag
  Future<void> updateTag(domain.Tag tag) async {
    final tagWithTimestamp = tag.copyWith(updatedAt: DateTime.now());

    await _db
        .update(_db.tags)
        .replace(_mapToData(tagWithTimestamp, isSynced: false));

    sync();
  }

  // Delete tag
  Future<void> deleteTag(String id) async {
    final now = DateTime.now();
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

    sync();
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
    try {
      // 1. Get last sync timestamp
      final lastSyncedAt = await _storage.read(key: _lastTagSyncKey);

      // 2. Get all unsynced local tags
      final unsyncedRows = await (_db.select(
        _db.tags,
      )..where((tbl) => tbl.isSynced.equals(false))).get();

      final localChanges = unsyncedRows.map((row) {
        final tag = _mapToDomain(row);
        return {
          'id': tag.id,
          'name': tag.name,
          'color': tag.color,
          'updatedAt': tag.updatedAt?.toIso8601String(),
          'isDeleted': tag.isDeleted,
        };
      }).toList();

      // 3. Send sync request to server
      final response = await _dio.post(
        '/api/tags/sync',
        data: {'lastSyncedAt': lastSyncedAt, 'changes': localChanges},
      );

      final data = response.data as Map<String, dynamic>;
      final serverChanges = (data['serverChanges'] as List)
          .map((e) => domain.Tag.fromJson(e as Map<String, dynamic>))
          .toList();
      final syncedAt = data['syncedAt'] as String;
      final processedIds =
          (data['processedIds'] as List?)?.cast<String>() ?? [];

      // 4. Process server changes
      await _db.transaction(() async {
        for (final serverTag in serverChanges) {
          // If server tag is deleted (tombstone), remove it locally
          if (serverTag.isDeleted) {
            await (_db.delete(
              _db.noteTags,
            )..where((tbl) => tbl.tagId.equals(serverTag.id))).go();
            await (_db.delete(
              _db.tags,
            )..where((tbl) => tbl.id.equals(serverTag.id))).go();
            continue;
          }

          final localTag = await (_db.select(
            _db.tags,
          )..where((tbl) => tbl.id.equals(serverTag.id))).getSingleOrNull();

          if (localTag == null) {
            // Tag doesn't exist locally - insert it
            await _db
                .into(_db.tags)
                .insert(
                  _mapToData(serverTag, isSynced: true),
                  mode: drift.InsertMode.insertOrReplace,
                );
          } else {
            // Tag exists - compare timestamps
            final serverUpdatedAt = serverTag.updatedAt;
            final localUpdatedAt = localTag.updatedAt;

            if (serverUpdatedAt != null &&
                (localUpdatedAt == null ||
                    serverUpdatedAt.isAfter(localUpdatedAt) ||
                    serverUpdatedAt.isAtSameMomentAs(localUpdatedAt))) {
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
          }
        }

        // Mark all pushed tags as synced
        for (final id in processedIds) {
          final tag = await (_db.select(
            _db.tags,
          )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
          if (tag != null && tag.isDeleted) {
            // Remove deleted tags and their associations
            await (_db.delete(
              _db.noteTags,
            )..where((tbl) => tbl.tagId.equals(id))).go();
            await (_db.delete(
              _db.tags,
            )..where((tbl) => tbl.id.equals(id))).go();
          } else if (tag != null) {
            await (_db.update(_db.tags)..where((tbl) => tbl.id.equals(id)))
                .write(const TagsCompanion(isSynced: drift.Value(true)));
          }
        }
      });

      // 5. Save new sync timestamp
      await _storage.write(key: _lastTagSyncKey, value: syncedAt);
      debugPrint(
        'Tags sync completed: ${serverChanges.length} changes from server',
      );
    } catch (e) {
      debugPrint('Tags sync failed: $e');
      // Sync failed, will retry later
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
