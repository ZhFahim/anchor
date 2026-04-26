import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:drift/drift.dart' as drift;
import '../../../../core/database/app_database.dart';
import '../../../../core/sync/sync_outbox_dao.dart';
import '../../../../core/sync/sync_worker.dart';
import '../../domain/tag.dart' as domain;

part 'tags_repository.g.dart';

@riverpod
TagsRepository tagsRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  void triggerSync() {
    try {
      ref.read(syncWorkerProvider).requestSync();
    } catch (e) {
      debugPrint('Sync trigger failed: $e');
    }
  }
  return TagsRepository(db, triggerSync);
}

class TagsRepository {
  final AppDatabase _db;
  final void Function() _triggerSync;
  late final SyncOutboxDao _outbox = SyncOutboxDao(_db);

  TagsRepository(this._db, this._triggerSync);

  Stream<List<domain.Tag>> watchTags() {
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

        if (noteTag != null && note != null) {
          final isActive = note.state == 'active' && !note.isArchived;
          if (isActive) {
            tagCounts[tag.id] = (tagCounts[tag.id] ?? 0) + 1;
          }
        }
      }

      return tagMap.values
          .map(
            (tag) => tag.copyWith(
              count: domain.TagCount(notes: tagCounts[tag.id] ?? 0),
            ),
          )
          .toList();
    });
  }

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

  Future<domain.Tag?> getTag(String id) async {
    final row = await (_db.select(
      _db.tags,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    return row != null ? _mapToDomain(row) : null;
  }

  Future<List<String>> getTagIdsForNote(String noteId) async {
    final rows = await (_db.select(
      _db.noteTags,
    )..where((tbl) => tbl.noteId.equals(noteId))).get();
    return rows.map((row) => row.tagId).toList();
  }

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

  Future<void> setTagsForNote(String noteId, List<String> tagIds) async {
    await _db.transaction(() async {
      await (_db.delete(
        _db.noteTags,
      )..where((tbl) => tbl.noteId.equals(noteId))).go();

      if (tagIds.isEmpty) return;

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

  Future<domain.Tag> createTag(domain.Tag tag) async {
    final stamped = tag.copyWith(updatedAt: DateTime.now());

    await _db.transaction(() async {
      await _db
          .into(_db.tags)
          .insert(
            _mapToData(stamped),
            mode: drift.InsertMode.insertOrReplace,
          );
      await _enqueueUpsert(stamped);
    });

    _triggerSync();
    return stamped;
  }

  Future<void> updateTag(domain.Tag tag) async {
    final stamped = tag.copyWith(updatedAt: DateTime.now());
    await _db.transaction(() async {
      await _db.update(_db.tags).replace(_mapToData(stamped));
      await _enqueueUpsert(stamped);
    });
    _triggerSync();
  }

  Future<void> deleteTag(String id) async {
    final now = DateTime.now();
    await _db.transaction(() async {
      await (_db.update(_db.tags)..where((tbl) => tbl.id.equals(id))).write(
        TagsCompanion(
          isDeleted: const drift.Value(true),
          updatedAt: drift.Value(now),
          isSynced: const drift.Value(false),
        ),
      );
      await (_db.delete(
        _db.noteTags,
      )..where((tbl) => tbl.tagId.equals(id))).go();

      final row = await (_db.select(
        _db.tags,
      )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
      await _outbox.enqueue(
        entityType: 'tag',
        entityId: id,
        op: 'delete',
        payloadJson: jsonEncode(<String, dynamic>{}),
        baseSyncVersion: row?.syncVersion,
        clientUpdatedAt: now,
      );
    });
    _triggerSync();
  }

  Future<void> _enqueueUpsert(domain.Tag tag) async {
    final row = await (_db.select(
      _db.tags,
    )..where((tbl) => tbl.id.equals(tag.id))).getSingleOrNull();
    final payload = <String, dynamic>{
      'name': tag.name,
      'color': tag.color,
    };
    await _outbox.enqueue(
      entityType: 'tag',
      entityId: tag.id,
      op: 'upsert',
      payloadJson: jsonEncode(payload),
      baseSyncVersion: row?.syncVersion,
      clientUpdatedAt: tag.updatedAt,
    );
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

  Tag _mapToData(domain.Tag tag) {
    return Tag(
      id: tag.id,
      name: tag.name,
      color: tag.color,
      updatedAt: tag.updatedAt,
      isSynced: false,
      isDeleted: tag.isDeleted,
      syncVersion: null,
    );
  }
}
