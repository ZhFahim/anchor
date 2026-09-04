import 'package:freezed_annotation/freezed_annotation.dart';

part 'note.freezed.dart';
part 'note.g.dart';

/// Preview info for note card image attachments; enough to fetch image if not cached.
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
  bool get canEdit =>
      this == NotePermission.owner || this == NotePermission.editor;
}

/// How often a reminder comes back.
enum ReminderRecurrence {
  none,
  daily,
  weekly,
  monthly,
  yearly;

  /// Unknown values fall back to a one-off.
  static ReminderRecurrence fromString(String? value) {
    return ReminderRecurrence.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ReminderRecurrence.none,
    );
  }

  bool get repeats => this != ReminderRecurrence.none;

  /// One word, for the repeat pills and the chip on a note card.
  String get label => switch (this) {
    ReminderRecurrence.none => 'Once',
    ReminderRecurrence.daily => 'Daily',
    ReminderRecurrence.weekly => 'Weekly',
    ReminderRecurrence.monthly => 'Monthly',
    ReminderRecurrence.yearly => 'Yearly',
  };
}

/// A reminder on a note, personal to the signed-in user.
///
/// [remindAt] is a local wall clock ("YYYY-MM-DDTHH:mm") with no zone.
@freezed
abstract class NoteReminder with _$NoteReminder {
  const NoteReminder._();

  const factory NoteReminder({
    required String remindAt,
    @Default(ReminderRecurrence.none) ReminderRecurrence recurrence,
    @Default(0) int version,
  }) = _NoteReminder;

  factory NoteReminder.fromJson(Map<String, dynamic> json) =>
      _$NoteReminderFromJson(json);

  /// True when the two describe the same reminder, ignoring the version.
  bool sameIntentAs(NoteReminder? other) =>
      other != null &&
      other.remindAt == remindAt &&
      other.recurrence == recurrence;
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

/// The display-only 'Untitled' placeholder; a blank title stays blank in
/// storage.
String displayTitleOf(String title) =>
    title.trim().isEmpty ? 'Untitled' : title;

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
    @Default(NoteState.active) NoteState state,
    DateTime? updatedAt,
    @Default([]) List<String> tagIds,
    @Default(NotePermission.owner) NotePermission permission,
    List<String>? shareIds,
    SharedByUser? sharedBy,
    NoteReminder? reminder,
    // Local only - not serialized
    @Default(true)
    @JsonKey(includeFromJson: false, includeToJson: false)
    bool isSynced,
    // Local only - the OS notification id this note's reminder occupies
    @JsonKey(includeFromJson: false, includeToJson: false) int? reminderSlot,
    // Local only - image attachment previews for card thumbnails
    @Default([])
    @JsonKey(includeFromJson: false, includeToJson: false)
    List<NoteImagePreview> imagePreviewData,
  }) = _Note;

  factory Note.fromJson(Map<String, dynamic> json) => _$NoteFromJson(json);

  /// Title for display; blank stored titles fall back to the 'Untitled' placeholder.
  String get displayTitle => displayTitleOf(title);

  bool get isActive => state == NoteState.active;
  bool get isTrashed => state == NoteState.trashed;
  bool get isDeleted => state == NoteState.deleted;
  bool get isOwner => permission.isOwner;
  bool get canEdit => permission.canEdit;
  bool get isShared => sharedBy != null;
  bool get hasShares => shareIds != null && shareIds!.isNotEmpty;
  bool get hasReminder => reminder != null;
}
