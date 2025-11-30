import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:drift/drift.dart' as drift;
import '../../../../core/database/app_database.dart';
import '../../../../core/network/dio_provider.dart';
import '../../domain/note.dart' as domain;

part 'notes_repository.g.dart';

@riverpod
NotesRepository notesRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  final dio = ref.watch(dioProvider);
  return NotesRepository(db, dio);
}

class NotesRepository {
  final AppDatabase _db;
  final Dio _dio;

  NotesRepository(this._db, this._dio);

  Stream<List<domain.Note>> watchNotes() {
    return _db.select(_db.notes).watch().map((rows) {
      return rows.map((row) => _mapToDomain(row)).toList();
    });
  }

  Future<domain.Note?> getNote(String id) async {
    final row = await (_db.select(
      _db.notes,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    return row != null ? _mapToDomain(row) : null;
  }

  Future<void> createNote(domain.Note note) async {
    await _db
        .into(_db.notes)
        .insert(
          _mapToData(note, isSynced: false),
          mode: drift.InsertMode.insertOrReplace,
        );
    _syncPush(note);
  }

  Future<void> updateNote(domain.Note note) async {
    await _db.update(_db.notes).replace(_mapToData(note, isSynced: false));
    _syncPush(note);
  }

  Future<void> deleteNote(String id) async {
    await (_db.delete(_db.notes)..where((tbl) => tbl.id.equals(id))).go();
    try {
      await _dio.delete('/api/notes/$id');
    } catch (e) {
      // Ignore
    }
  }

  Future<void> sync() async {
    try {
      final unsynced = await (_db.select(
        _db.notes,
      )..where((tbl) => tbl.isSynced.equals(false))).get();
      for (final row in unsynced) {
        await _syncPush(_mapToDomain(row));
      }

      final response = await _dio.get('/api/notes');
      final List data = response.data;
      final serverNotes = data.map((e) => domain.Note.fromJson(e)).toList();

      await _db.batch((batch) {
        for (final note in serverNotes) {
          batch.insert(
            _db.notes,
            _mapToData(note, isSynced: true),
            mode: drift.InsertMode.insertOrReplace,
          );
        }
      });
    } catch (e) {
      print('Sync failed: $e');
    }
  }

  Future<void> _syncPush(domain.Note note) async {
    try {
      final data = note.toJson();
      data.remove('id');
      data.remove('updatedAt');

      try {
        await _dio.patch('/api/notes/${note.id}', data: data);
        // If successful, mark as synced
        await (_db.update(_db.notes)..where((tbl) => tbl.id.equals(note.id)))
            .write(const NotesCompanion(isSynced: drift.Value(true)));
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          // Note doesn't exist on server, create it
          final response = await _dio.post('/api/notes', data: data);
          final serverNote = domain.Note.fromJson(response.data);

          // Update local DB with server ID and data
          await _db.transaction(() async {
            await (_db.delete(
              _db.notes,
            )..where((tbl) => tbl.id.equals(note.id))).go();
            await _db
                .into(_db.notes)
                .insert(
                  _mapToData(serverNote, isSynced: true),
                  mode: drift.InsertMode.insertOrReplace,
                );
          });
        } else {
          rethrow;
        }
      }
    } catch (e) {
      print('Push failed for ${note.id}: $e');
    }
  }

  domain.Note _mapToDomain(Note row) {
    return domain.Note(
      id: row.id,
      title: row.title,
      content: row.content,
      isPinned: row.isPinned,
      isArchived: row.isArchived,
      color: row.color,
      updatedAt: row.updatedAt,
      isSynced: row.isSynced,
    );
  }

  Note _mapToData(domain.Note note, {required bool isSynced}) {
    return Note(
      id: note.id,
      title: note.title,
      content: note.content,
      isPinned: note.isPinned,
      isArchived: note.isArchived,
      color: note.color,
      updatedAt: note.updatedAt,
      isSynced: isSynced,
    );
  }
}
