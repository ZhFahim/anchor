import 'package:freezed_annotation/freezed_annotation.dart';

import 'user_summary.dart';

part 'note.freezed.dart';

@immutable
class NoteImagePreview {
  final String attachmentId;
  final String noteId;
  final String filename;
  final String? localPath;

  const NoteImagePreview({
    required this.attachmentId,
    required this.noteId,
    required this.filename,
    this.localPath,
  });

  @override
  bool operator ==(Object other) =>
      other is NoteImagePreview &&
      other.attachmentId == attachmentId &&
      other.noteId == noteId &&
      other.filename == filename &&
      other.localPath == localPath;

  @override
  int get hashCode => Object.hash(attachmentId, noteId, filename, localPath);
}

enum NoteType {
  note,
  checklist;

  static NoteType fromString(String? value) => NoteType.values.firstWhere(
    (type) => type.name == value,
    orElse: () => NoteType.note,
  );
}

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
  bool get canEdit =>
      this == NotePermission.owner || this == NotePermission.editor;
}

enum ReminderRecurrence {
  none,
  daily,
  weekly,
  monthly,
  yearly;

  static ReminderRecurrence fromString(String? value) {
    return ReminderRecurrence.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ReminderRecurrence.none,
    );
  }

  bool get repeats => this != ReminderRecurrence.none;
}

/// [remindAt] is a local wall clock ("YYYY-MM-DDTHH:mm") with no zone.
@freezed
abstract class NoteReminder with _$NoteReminder {
  const NoteReminder._();

  const factory NoteReminder({
    required String remindAt,
    @Default(ReminderRecurrence.none) ReminderRecurrence recurrence,
    @Default(0) int version,
  }) = _NoteReminder;

  bool sameIntentAs(NoteReminder? other) =>
      other != null &&
      other.remindAt == remindAt &&
      other.recurrence == recurrence;
}

bool hasTitleText(String title) => title.trim().isNotEmpty;

/// A title as it is kept: exactly as typed, or empty when it's blank.
String storedTitleOf(String title) => hasTitleText(title) ? title : '';

@freezed
abstract class Note with _$Note {
  const Note._();

  const factory Note({
    required String id,
    required String title,
    @Default(NoteType.note) NoteType noteType,
    String? content,
    @Default(false) bool isPinned,
    @Default(false) bool isArchived,
    String? background,
    @Default(NoteState.active) NoteState state,
    DateTime? updatedAt,
    @Default([]) List<String> tagIds,
    @Default(NotePermission.owner) NotePermission permission,
    List<String>? shareIds,
    UserSummary? sharedBy,
    NoteReminder? reminder,
    @Default(true) bool isSynced,
    // The OS notification id this note's reminder occupies.
    int? reminderSlot,
    @Default([]) List<NoteImagePreview> imagePreviewData,
    @Default(0) int attachmentCount,
  }) = _Note;

  bool get hasTitle => hasTitleText(title);

  bool get isActive => state == NoteState.active;
  bool get isTrashed => state == NoteState.trashed;
  bool get isDeleted => state == NoteState.deleted;
  bool get isOwner => permission.isOwner;
  bool get canEdit => permission.canEdit;
  bool get isShared => sharedBy != null;
  bool get hasShares => shareIds != null && shareIds!.isNotEmpty;
  bool get hasReminder => reminder != null;
}
