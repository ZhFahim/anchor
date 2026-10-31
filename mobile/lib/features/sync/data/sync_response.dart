import '../../notes/domain/note.dart';
import '../../notes/domain/note_attachment.dart';
import '../../notes/domain/user_summary.dart';

enum SyncStatus {
  applied,
  conflict,
  denied,
  failed;

  // An unknown status counts as failed and stays queued.
  static SyncStatus fromString(String? value) => SyncStatus.values.firstWhere(
    (status) => status.name == value,
    orElse: () => SyncStatus.failed,
  );
}

enum SyncEntityType {
  note,
  tag,
  pin,
  attachments,
  reminder;

  static SyncEntityType? fromString(String? value) {
    for (final type in SyncEntityType.values) {
      if (type.name == value) return type;
    }
    return null;
  }
}

class SyncResult {
  const SyncResult({
    required this.type,
    required this.id,
    required this.status,
    this.version,
    this.hasServerCopy = false,
    this.serverNote,
    this.serverTag,
    this.serverReminder,
  });

  factory SyncResult.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String? ?? '';
    final serverCopy = json['serverCopy'] as Map<String, dynamic>?;
    return SyncResult(
      type: type,
      id: json['id'] as String? ?? '',
      status: SyncStatus.fromString(json['status'] as String?),
      version: json['version'] as int?,
      hasServerCopy: json.containsKey('serverCopy'),
      serverNote: type == 'note' && serverCopy != null
          ? SyncServerNote.fromJson(serverCopy)
          : null,
      serverTag: type == 'tag' && serverCopy != null
          ? SyncServerTag.fromJson(serverCopy)
          : null,
      serverReminder: type == 'reminder'
          ? SyncServerReminder.fromJson(serverCopy)
          : null,
    );
  }

  final String type;
  final String id;
  final SyncStatus status;
  final int? version;
  final bool hasServerCopy;
  final SyncServerNote? serverNote;

  /// For a tag that clashed by name, a different tag to merge into.
  final SyncServerTag? serverTag;

  /// Null alongside [hasServerCopy] means the winning state is "no reminder".
  final SyncServerReminder? serverReminder;
}

class SyncServerReminder {
  const SyncServerReminder({
    required this.remindAt,
    required this.recurrence,
    required this.version,
  });

  static SyncServerReminder? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final remindAt = json['remindAt'] as String?;
    if (remindAt == null) return null;
    return SyncServerReminder(
      remindAt: remindAt,
      recurrence: ReminderRecurrence.fromString(json['recurrence'] as String?),
      version: json['version'] as int? ?? 1,
    );
  }

  final String remindAt;
  final ReminderRecurrence recurrence;
  final int version;
}

class SyncServerNote {
  const SyncServerNote({
    this.noteType = 'note',
    required this.id,
    required this.title,
    required this.content,
    required this.version,
    required this.isPinned,
    required this.isArchived,
    required this.background,
    required this.state,
    required this.updatedAt,
    required this.tagIds,
    required this.permission,
    required this.shareIds,
    required this.sharedBy,
    required this.hasReminderField,
    required this.reminder,
  });

  factory SyncServerNote.fromJson(Map<String, dynamic> json) {
    final sharedBy = json['sharedBy'] as Map<String, dynamic>?;
    return SyncServerNote(
      noteType: NoteType.fromString(json['noteType'] as String?).name,
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      content: json['content'] as String?,
      version: json['version'] as int? ?? 1,
      isPinned: json['isPinned'] as bool? ?? false,
      isArchived: json['isArchived'] as bool? ?? false,
      background: json['background'] as String?,
      state: json['state'] as String? ?? NoteState.active.name,
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '')?.toUtc(),
      tagIds: (json['tagIds'] as List?)?.cast<String>() ?? const [],
      permission: json['permission'] as String? ?? NotePermission.owner.name,
      shareIds: (json['shareIds'] as List?)?.cast<String>() ?? const [],
      sharedBy: sharedBy != null ? UserSummary.fromJson(sharedBy) : null,
      // An absent key means "not loaded"; an explicit null means "no reminder".
      hasReminderField: json.containsKey('reminder'),
      reminder: SyncServerReminder.fromJson(
        json['reminder'] as Map<String, dynamic>?,
      ),
    );
  }

  final String id;
  final String title;
  final String noteType;
  final String? content;
  final int version;
  final bool isPinned;
  final bool isArchived;
  final String? background;
  final String state;
  final DateTime? updatedAt;
  final List<String> tagIds;
  final String permission;
  final List<String> shareIds;
  final UserSummary? sharedBy;
  final bool hasReminderField;
  final SyncServerReminder? reminder;

  bool get isDeleted => state == NoteState.deleted.name;

  bool get canEdit =>
      permission == NotePermission.owner.name ||
      permission == NotePermission.editor.name;
}

class SyncServerTag {
  const SyncServerTag({
    required this.id,
    required this.name,
    required this.color,
    required this.version,
    required this.updatedAt,
  });

  factory SyncServerTag.fromJson(Map<String, dynamic> json) => SyncServerTag(
    id: json['id'] as String,
    name: json['name'] as String? ?? '',
    color: json['color'] as String?,
    version: json['version'] as int? ?? 1,
    updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '')?.toUtc(),
  );

  final String id;
  final String name;
  final String? color;
  final int version;
  final DateTime? updatedAt;
}

class SyncEntry {
  const SyncEntry({
    required this.entityType,
    required this.entityId,
    required this.isRemove,
    this.note,
    this.tag,
    this.reminder,
    this.attachments = const [],
  });

  static SyncEntry? fromJson(Map<String, dynamic> json) {
    final entityType = SyncEntityType.fromString(json['entityType'] as String?);
    if (entityType == null) return null;

    final note = json['note'] as Map<String, dynamic>?;
    final tag = json['tag'] as Map<String, dynamic>?;
    final attachments = json['attachments'] as List?;
    return SyncEntry(
      entityType: entityType,
      entityId: json['entityId'] as String? ?? '',
      isRemove: json['op'] == 'remove',
      note: note != null ? SyncServerNote.fromJson(note) : null,
      tag: tag != null ? SyncServerTag.fromJson(tag) : null,
      reminder: SyncServerReminder.fromJson(
        json['reminder'] as Map<String, dynamic>?,
      ),
      attachments: [
        for (final item in attachments ?? const [])
          NoteAttachment.fromJson(item as Map<String, dynamic>),
      ],
    );
  }

  final SyncEntityType entityType;
  final String entityId;
  final bool isRemove;
  final SyncServerNote? note;
  final SyncServerTag? tag;
  final SyncServerReminder? reminder;
  final List<NoteAttachment> attachments;
}

class SyncResponse {
  const SyncResponse({
    required this.results,
    required this.entries,
    required this.nextCursor,
    required this.hasMore,
    required this.resetRequired,
  });

  factory SyncResponse.fromJson(Map<String, dynamic> json) => SyncResponse(
    results: [
      for (final result in (json['results'] as List?) ?? const [])
        SyncResult.fromJson(result as Map<String, dynamic>),
    ],
    entries: [
      for (final entry in (json['entries'] as List?) ?? const [])
        ?SyncEntry.fromJson(entry as Map<String, dynamic>),
    ],
    nextCursor: json['nextCursor'] as String?,
    hasMore: json['hasMore'] as bool? ?? false,
    resetRequired: json['resetRequired'] as bool? ?? false,
  );

  final List<SyncResult> results;
  final List<SyncEntry> entries;
  final String? nextCursor;
  final bool hasMore;

  /// The cursor is too old; drop it and download everything again.
  final bool resetRequired;
}
