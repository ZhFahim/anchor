import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../data/repository/tags_repository.dart';
import '../domain/tag.dart';

part 'tags_controller.g.dart';

@riverpod
class TagsController extends _$TagsController {
  @override
  Stream<List<Tag>> build() {
    // Trigger initial sync
    Future.microtask(() => sync());
    return ref.watch(tagsRepositoryProvider).watchTags();
  }

  Future<void> sync() async {
    try {
      await ref.read(tagsRepositoryProvider).sync();
    } catch (e) {
      debugPrint('Tags sync error: $e');
    }
  }

  Future<Tag> createTag(String name, {String? color}) async {
    // Validate name is not empty
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Tag name cannot be empty');
    }

    // Check for duplicate name
    final existingTags = await ref.read(tagsRepositoryProvider).getTags();
    final duplicateTag = existingTags.firstWhere(
      (tag) => tag.name.toLowerCase() == trimmedName.toLowerCase(),
      orElse: () => Tag(id: '', name: '', isSynced: false),
    );

    if (duplicateTag.id.isNotEmpty) {
      throw Exception('A tag with this name already exists');
    }

    final tag = Tag(
      id: const Uuid().v4(),
      name: trimmedName,
      color: color ?? generateRandomTagColor(),
      updatedAt: DateTime.now(),
      isSynced: false,
    );
    // This now waits for server response when online
    return ref.read(tagsRepositoryProvider).createTag(tag);
  }

  Future<void> updateTag(Tag tag) async {
    // Validate name is not empty
    final trimmedName = tag.name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Tag name cannot be empty');
    }

    // Check for duplicate name (excluding current tag)
    final existingTags = await ref.read(tagsRepositoryProvider).getTags();
    final duplicateTag = existingTags.firstWhere(
      (t) =>
          t.id != tag.id && t.name.toLowerCase() == trimmedName.toLowerCase(),
      orElse: () => Tag(id: '', name: '', isSynced: false),
    );

    if (duplicateTag.id.isNotEmpty) {
      throw Exception('A tag with this name already exists');
    }

    await ref
        .read(tagsRepositoryProvider)
        .updateTag(tag.copyWith(name: trimmedName));
  }

  Future<void> deleteTag(String id) async {
    await ref.read(tagsRepositoryProvider).deleteTag(id);
  }
}

// Provider for tags on a specific note
@riverpod
Stream<List<Tag>> noteTagsStream(Ref ref, String noteId) {
  return ref.watch(tagsRepositoryProvider).watchTagsForNote(noteId);
}

// Provider for available tags (all tags that exist)
@riverpod
Future<List<Tag>> availableTags(Ref ref) async {
  return ref.watch(tagsRepositoryProvider).getTags();
}

// Selected tag for filtering
@riverpod
class SelectedTagFilter extends _$SelectedTagFilter {
  @override
  String? build() => null;

  void select(String? tagId) {
    state = tagId;
  }

  void clear() {
    state = null;
  }
}
