import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:anchor/features/notes/domain/note.dart';
import '../data/repository/notes_repository.dart';

part 'notes_controller.g.dart';

@riverpod
class NotesController extends _$NotesController {
  @override
  Stream<List<Note>> build() {
    // Trigger sync on first build
    Future.microtask(() => sync());
    return ref.watch(notesRepositoryProvider).watchNotes();
  }

  Future<void> sync() async {
    await ref.read(notesRepositoryProvider).sync();
  }

  Future<void> deleteNote(String id) async {
    await ref.read(notesRepositoryProvider).deleteNote(id);
  }
}

@riverpod
class SearchQuery extends _$SearchQuery {
  @override
  String build() => '';

  void set(String query) {
    state = query;
  }
}

@riverpod
class TrashController extends _$TrashController {
  @override
  Stream<List<Note>> build() {
    return ref.watch(notesRepositoryProvider).watchTrashedNotes();
  }

  Future<void> restoreNote(String id) async {
    await ref.read(notesRepositoryProvider).restoreNote(id);
  }

  Future<void> permanentDelete(String id) async {
    await ref.read(notesRepositoryProvider).permanentDelete(id);
  }
}
