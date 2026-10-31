import '../../notes/domain/note.dart';

const int maxChangesPerRequest = 200;
const int maxRevisionsPerNote = 20;
const int maxRequestBytes = 8 * 1024 * 1024;

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

sealed class SyncChange {
  const SyncChange({required this.id});

  final String id;

  String get type;

  int get approximateBytes;

  Map<String, dynamic> toJson();
}

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
    this.noteType = NoteType.note,
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
  final NoteType noteType;
  final int? baseVersion;
  final String title;
  final String? content;
  final bool isArchived;
  final String? background;

  /// Sent for a shared note only when it is being removed.
  final String? state;
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
    // Normal notes keep working with servers from before note types.
    if (baseVersion == null && noteType == NoteType.checklist)
      'noteType': noteType.name,
    'title': title,
    'content': content,
    'isArchived': isArchived,
    'background': background,
    if (state != null) 'state': state,
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

/// `remindAt: null` clears the reminder.
class SyncReminderChange extends SyncChange {
  const SyncReminderChange({
    required super.id,
    required this.remindAt,
    required this.recurrence,
    this.baseVersion,
  });

  final String? remindAt;
  final ReminderRecurrence recurrence;
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
