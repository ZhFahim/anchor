import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:anchor/features/notes/domain/note.dart';
import '../data/repository/notes_repository.dart';

part 'notes_controller.g.dart';

@riverpod
class NotesController extends _$NotesController {
  @override
  Stream<List<Note>> build() {
    return ref.watch(notesRepositoryProvider).watchNotes();
  }

  Future<void> deleteNote(String id) async {
    await ref.read(notesRepositoryProvider).deleteNote(id);
  }
}

