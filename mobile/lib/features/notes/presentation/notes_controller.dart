import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:anchor/core/network/sync_requester.dart';
import 'package:anchor/features/notes/domain/note.dart';
import '../data/repository/notes_repository.dart';
import '../../tags/presentation/tags_controller.dart';

part 'notes_controller.g.dart';

/// Provider to track syncing state globally
@riverpod
class SyncingState extends _$SyncingState {
  @override
  bool build() => false;

  void setSyncing(bool syncing) {
    state = syncing;
  }
}

@riverpod
class NotesController extends _$NotesController {
  @override
  Stream<List<Note>> build() {
    final selectedTagId = ref.watch(selectedTagFilterProvider);
    return ref.watch(notesRepositoryProvider).watchNotes(tagId: selectedTagId);
  }

  Future<void> sync() async {
    await requestAppSync(trigger: 'NotesController.sync');
  }

  Future<void> deleteNote(String id) async {
    await ref.read(notesRepositoryProvider).deleteNote(id);
  }

  Future<int> bulkDeleteNotes(List<String> ids) async {
    return await ref.read(notesRepositoryProvider).bulkDeleteNotes(ids);
  }

  Future<int> bulkArchiveNotes(List<String> ids) async {
    return await ref.read(notesRepositoryProvider).bulkArchiveNotes(ids);
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

/// Provider to track selection mode state
@riverpod
class SelectionMode extends _$SelectionMode {
  @override
  bool build() => false;

  void setEnabled(bool enabled) {
    state = enabled;
  }
}

/// Provider to track selected note IDs
@riverpod
class SelectedNoteIds extends _$SelectedNoteIds {
  @override
  Set<String> build() => {};

  void toggle(String id) {
    final newSet = Set<String>.from(state);
    if (newSet.contains(id)) {
      newSet.remove(id);
    } else {
      newSet.add(id);
    }
    state = newSet;
  }

  void selectAll(List<String> ids) {
    state = Set<String>.from(ids);
  }

  void clear() {
    state = {};
  }

  void add(String id) {
    final newSet = Set<String>.from(state);
    newSet.add(id);
    state = newSet;
  }

  void remove(String id) {
    final newSet = Set<String>.from(state);
    newSet.remove(id);
    state = newSet;
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

@riverpod
class ArchiveController extends _$ArchiveController {
  @override
  Stream<List<Note>> build() {
    return ref.watch(notesRepositoryProvider).watchArchivedNotes();
  }

  Future<void> unarchiveNote(String id) async {
    await ref.read(notesRepositoryProvider).unarchiveNote(id);
  }
}
