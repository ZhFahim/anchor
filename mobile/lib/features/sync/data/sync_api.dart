import 'package:dio/dio.dart';

import '../../notes/domain/note.dart' as domain;
import '../../notes/domain/note_attachment.dart' as domain;

const int maxChangesPerRequest = 200;
const int maxRevisionsPerNote = 20;
const int maxRequestBytes = 8 * 1024 * 1024;

/// Ids, flags and field names around the text of one change.
const int _changeOverheadBytes = 256;

/// The leading items that fit [maxRequestBytes] on top of [used]; the first
/// always goes.
List<T> takeUnderBudget<T>(
  Iterable<T> items,
  int Function(T item) sizeOf, {
  int used = 0,
}) {
  final taken = <T>[];
  var bytes = used;

  for (final item in items) {
    final size = sizeOf(item);
    if (taken.isNotEmpty && bytes + size > maxRequestBytes) break;
    taken.add(item);
    bytes += size;
  }

  return taken;
}

const String syncPath = '/api/sync';
const String syncEventsPath = '/api/sync/events';

sealed class SyncChange {
  const SyncChange({required this.id});

  final String id;

  String get type;

  int get approximateBytes;

  Map<String, dynamic> toJson();
}

/// What the note said before this device changed it.
class SyncNoteRevision {
  const SyncNoteRevision({
    required this.id,
    required this.version,
    required this.title,
    required this.content,
    required this.cause,
    required this.createdAt,
  });

  final String id;
  final int version;
  final String title;
  final String? content;
  final String cause;
  final DateTime createdAt;

  int get approximateBytes =>
      title.length + (content?.length ?? 0) + _changeOverheadBytes;

  Map<String, dynamic> toJson() => {
    'id': id,
    'version': version,
    'title': title,
    'content': content,
    'cause': cause,
    'createdAt': createdAt.toUtc().toIso8601String(),
  };
}

/// Leaving [baseVersion] out asks the server to create the note.
class SyncNoteChange extends SyncChange {
  const SyncNoteChange({
    required super.id,
    required this.localRev,
    required this.baseVersion,
    required this.title,
    required this.content,
    required this.isArchived,
    required this.background,
    required this.state,
    required this.tagIds,
    this.revisions = const [],
    this.isRevisionsOnly = false,
  });

  final int localRev;
  final int? baseVersion;
  final String title;
  final String? content;
  final bool isArchived;
  final String? background;
  final String state;
  final List<String> tagIds;
  final List<SyncNoteRevision> revisions;

  /// True when the row itself is already synced and this change only carries
  /// recorded versions.
  final bool isRevisionsOnly;

  @override
  String get type => 'note';

  @override
  int get approximateBytes => [
    title.length,
    content?.length ?? 0,
    for (final tagId in tagIds) tagId.length,
    for (final revision in revisions) revision.approximateBytes,
    _changeOverheadBytes,
  ].reduce((total, bytes) => total + bytes);

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    'id': id,
    if (baseVersion != null) 'baseVersion': baseVersion,
    'title': title,
    'content': content,
    'isArchived': isArchived,
    'background': background,
    'state': state,
    'tagIds': tagIds,
    if (revisions.isNotEmpty)
      'revisions': [for (final revision in revisions) revision.toJson()],
    if (isRevisionsOnly) 'revisionsOnly': true,
  };
}

class SyncTagChange extends SyncChange {
  const SyncTagChange({
    required super.id,
    required this.localRev,
    required this.baseVersion,
    required this.name,
    required this.color,
    required this.isDeleted,
  });

  final int localRev;
  final int? baseVersion;
  final String name;
  final String? color;
  final bool isDeleted;

  @override
  String get type => 'tag';

  @override
  int get approximateBytes =>
      name.length + (color?.length ?? 0) + _changeOverheadBytes;

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    'id': id,
    if (baseVersion != null) 'baseVersion': baseVersion,
    'name': name,
    'color': color,
    'isDeleted': isDeleted,
  };
}

/// [id] is the note being pinned; pins have no id of their own.
class SyncPinChange extends SyncChange {
  const SyncPinChange({required super.id, required this.isPinned});

  final bool isPinned;

  @override
  String get type => 'pin';

  @override
  int get approximateBytes => _changeOverheadBytes;

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    'id': id,
    'isPinned': isPinned,
  };
}

/// A reminder push. `remindAt: null` clears it.
class SyncReminderChange extends SyncChange {
  const SyncReminderChange({
    required super.id,
    required this.remindAt,
    required this.recurrence,
    this.baseVersion,
  });

  final String? remindAt;
  final domain.ReminderRecurrence recurrence;
  final int? baseVersion;

  @override
  String get type => 'reminder';

  @override
  int get approximateBytes => _changeOverheadBytes;

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    'id': id,
    'remindAt': remindAt,
    'recurrence': recurrence.name,
    if (baseVersion != null) 'baseVersion': baseVersion,
  };
}

enum SyncStatus {
  applied,
  conflict,
  denied,
  failed;

  // An unknown status stays queued rather than being dropped.
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

  /// Whether the answer spoke about the server's own copy at all.
  final bool hasServerCopy;

  /// For a tag that clashed by name this is a different tag, to merge into.
  final SyncServerNote? serverNote;
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
      recurrence: domain.ReminderRecurrence.fromString(
        json['recurrence'] as String?,
      ),
      version: json['version'] as int? ?? 1,
    );
  }

  final String remindAt;
  final domain.ReminderRecurrence recurrence;
  final int version;
}

class SyncServerNote {
  const SyncServerNote({
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
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      content: json['content'] as String?,
      version: json['version'] as int? ?? 1,
      isPinned: json['isPinned'] as bool? ?? false,
      isArchived: json['isArchived'] as bool? ?? false,
      background: json['background'] as String?,
      state: json['state'] as String? ?? 'active',
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '')?.toUtc(),
      tagIds: (json['tagIds'] as List?)?.cast<String>() ?? const [],
      permission: json['permission'] as String? ?? 'owner',
      shareIds: (json['shareIds'] as List?)?.cast<String>() ?? const [],
      sharedBy: sharedBy != null
          ? domain.SharedByUser.fromJson(sharedBy)
          : null,
      // An absent key means "not loaded"; an explicit null means "no reminder".
      hasReminderField: json.containsKey('reminder'),
      reminder: SyncServerReminder.fromJson(
        json['reminder'] as Map<String, dynamic>?,
      ),
    );
  }

  final String id;
  final String title;
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
  final domain.SharedByUser? sharedBy;

  /// Whether the payload spoke about the reminder at all.
  final bool hasReminderField;
  final SyncServerReminder? reminder;

  bool get isDeleted => state == 'deleted';
  bool get canEdit => permission == 'owner' || permission == 'editor';
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
          domain.NoteAttachment.fromJson(item as Map<String, dynamic>),
      ],
    );
  }

  final SyncEntityType entityType;
  final String entityId;
  final bool isRemove;
  final SyncServerNote? note;
  final SyncServerTag? tag;
  final SyncServerReminder? reminder;
  final List<domain.NoteAttachment> attachments;
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

class SyncApi {
  const SyncApi(this._dio);

  final Dio _dio;

  Future<SyncResponse> sync({
    String? cursor,
    List<SyncChange> changes = const [],
  }) async {
    final response = await _dio.post(
      syncPath,
      data: {
        'cursor': ?cursor,
        if (changes.isNotEmpty)
          'changes': [for (final change in changes) change.toJson()],
      },
    );
    return SyncResponse.fromJson(response.data as Map<String, dynamic>);
  }
}
