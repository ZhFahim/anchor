import 'package:freezed_annotation/freezed_annotation.dart';

part 'note.freezed.dart';
part 'note.g.dart';

enum NoteState {
  active,
  trashed,
  deleted;

  static NoteState fromString(String value) {
    return NoteState.values.firstWhere(
      (e) => e.name == value,
      orElse: () => NoteState.active,
    );
  }
}

/// Permission level for a note
enum NotePermission {
  owner,
  viewer,
  editor;

  static NotePermission fromString(String value) {
    if (value == 'owner') return NotePermission.owner;
    return NotePermission.values.firstWhere(
      (e) => e.name == value,
      orElse: () => NotePermission.owner,
    );
  }

  bool get isOwner => this == NotePermission.owner;
  bool get canEdit => this == NotePermission.owner || this == NotePermission.editor;
}

/// User who shared the note
@freezed
abstract class SharedByUser with _$SharedByUser {
  const factory SharedByUser({
    required String id,
    required String name,
    required String email,
    String? profileImage,
  }) = _SharedByUser;

  factory SharedByUser.fromJson(Map<String, dynamic> json) =>
      _$SharedByUserFromJson(json);
}

@freezed
abstract class Note with _$Note {
  const Note._();

  const factory Note({
    required String id,
    required String title,
    String? content,
    @Default(false) bool isPinned,
    @Default(false) bool isArchived,
    String? background,
    int? position,
    @Default(NoteState.active) NoteState state,
    DateTime? updatedAt,
    @Default([]) List<String> tagIds,
    @Default(NotePermission.owner) NotePermission permission,
    List<String>? shareIds,
    SharedByUser? sharedBy,
    // Local only - not serialized
    @Default(true)
    @JsonKey(includeFromJson: false, includeToJson: false)
    bool isSynced,
  }) = _Note;

  factory Note.fromJson(Map<String, dynamic> json) => _$NoteFromJson(json);

  bool get isActive => state == NoteState.active;
  bool get isTrashed => state == NoteState.trashed;
  bool get isDeleted => state == NoteState.deleted;
  bool get isOwner => permission.isOwner;
  bool get canEdit => permission.canEdit;
  bool get isShared => sharedBy != null;
  bool get hasShares => shareIds != null && shareIds!.isNotEmpty;
}
