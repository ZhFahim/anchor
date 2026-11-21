import 'package:intl/intl.dart';

import '../../../core/text/date_formats.dart';
import '../../../l10n/l10n.dart';
import '../domain/note.dart';
import '../domain/note_attachment.dart';
import '../domain/note_dates.dart';
import '../domain/note_history.dart';
import '../domain/note_revision.dart';
import '../domain/note_share_permission.dart';

String sharedCountLabel(
  int count,
  AppLocalizations l10n, {
  required bool isOnline,
}) => count == 0
    ? l10n.shareOnlyYou
    : isOnline
    ? l10n.shareSharedWith(count)
    : l10n.shareSharedWithOffline(count);

String namesLabel(List<String> names, AppLocalizations l10n) =>
    switch (names.length) {
      0 => '',
      1 => names.first,
      2 => l10n.namesTwo(names[0], names[1]),
      _ => l10n.namesMore(names[0], names[1], names.length - 2),
    };

String displayTitleOf(String title, AppLocalizations l10n) =>
    hasTitleText(title) ? title : l10n.noteUntitled;

String permissionLabel(NoteSharePermission permission, AppLocalizations l10n) =>
    switch (permission) {
      NoteSharePermission.viewer => l10n.shareCanView,
      NoteSharePermission.editor => l10n.shareCanEdit,
    };

String permissionChangedLabel(
  NoteSharePermission permission,
  String person,
  AppLocalizations l10n,
) => switch (permission) {
  NoteSharePermission.viewer => l10n.shareNowCanView(person),
  NoteSharePermission.editor => l10n.shareNowCanEdit(person),
};

String _fullDate(DateTime date) => DateFormat.yMMMMd(dateLocale).format(date);

String _shortDate(DateTime date, DateTime now) => date.year == now.year
    ? DateFormat.MMMd(dateLocale).format(date)
    : DateFormat.yMMMd(dateLocale).format(date);

String _longDate(DateTime date, DateTime now) => date.year == now.year
    ? DateFormat.MMMMd(dateLocale).format(date)
    : DateFormat.yMMMMd(dateLocale).format(date);

T byDay<T>(
  DateTime date,
  DateTime now, {
  required T Function() today,
  required T Function() yesterday,
  required T Function() other,
}) => switch (daysFromToday(date, now)) {
  0 => today(),
  -1 => yesterday(),
  _ => other(),
};

String dayLabel(DateTime date, DateTime now, AppLocalizations l10n) => byDay(
  date,
  now,
  today: () => l10n.commonToday,
  yesterday: () => l10n.commonYesterday,
  other: () => _fullDate(date),
);

String dayTimeLabel(DateTime date, AppLocalizations l10n, {DateTime? now}) {
  final local = date.toLocal();
  final time = clockLabel(local);
  return byDay(
    local,
    now ?? DateTime.now(),
    today: () => l10n.dayTodayAt(time),
    yesterday: () => l10n.dayYesterdayAt(time),
    other: () => l10n.dayOnAt(_fullDate(local), time),
  );
}

String _editedAtLabel(DateTime at, AppLocalizations l10n, {DateTime? now}) {
  final local = at.toLocal();
  final time = clockLabel(local);
  return byDay(
    local,
    now ?? DateTime.now(),
    today: () => l10n.editedTodayAt(time),
    yesterday: () => l10n.editedYesterdayAt(time),
    other: () => l10n.editedOnAt(_fullDate(local), time),
  );
}

String comparedWithLabel(DateTime at, AppLocalizations l10n, {DateTime? now}) {
  final local = at.toLocal();
  final time = clockLabel(local);
  return byDay(
    local,
    now ?? DateTime.now(),
    today: () => l10n.revisionComparedTodayAt(time),
    yesterday: () => l10n.revisionComparedYesterdayAt(time),
    other: () => l10n.revisionComparedOnAt(_fullDate(local), time),
  );
}

String shortDayLabel(DateTime date, AppLocalizations l10n, {DateTime? now}) {
  final today = now ?? DateTime.now();
  return byDay(
    date,
    today,
    today: () => l10n.commonToday,
    yesterday: () => l10n.commonYesterday,
    other: () => _shortDate(date, today),
  );
}

String editedDayLabel(DateTime at, AppLocalizations l10n, {DateTime? now}) {
  final local = at.toLocal();
  final today = now ?? DateTime.now();
  return byDay(
    local,
    today,
    today: () => l10n.editedToday,
    yesterday: () => l10n.editedYesterday,
    other: () => l10n.editedOn(_shortDate(local, today)),
  );
}

String editedTimeLabel(DateTime at, AppLocalizations l10n, {DateTime? now}) {
  final local = at.toLocal();
  final today = now ?? DateTime.now();
  return switch (minutesAgo(local, now: today)) {
    0 => l10n.editedJustNow,
    final minutes? => l10n.editedMinutesAgo(minutes),
    null => _editedAtLabel(local, l10n, now: today),
  };
}

String trashDaysLeftLabel(
  DateTime? trashedAt,
  AppLocalizations l10n, {
  DateTime? now,
}) {
  final since = trashedAt == null
      ? 0
      : (now ?? DateTime.now()).difference(trashedAt.toLocal()).inDays;
  return l10n.trashDaysLeft((trashDays - since).clamp(0, trashDays));
}

String trashDeletionLabel(
  DateTime? trashedAt,
  AppLocalizations l10n, {
  DateTime? now,
}) {
  if (trashedAt == null) return l10n.trashDeletesAfter(trashDays);
  final deletedOn = trashedAt.toLocal().add(const Duration(days: trashDays));
  return l10n.trashDeletesOn(_longDate(deletedOn, now ?? DateTime.now()));
}

String revisionLabel(RevisionCause cause, AppLocalizations l10n) =>
    switch (cause) {
      RevisionCause.edit => l10n.historyEarlier,
      RevisionCause.conflict => l10n.historyNotSaved,
      RevisionCause.restore => l10n.historyBeforeRestore,
    };

String revisionAuthorName(
  NoteRevision revision,
  String? currentUserId,
  AppLocalizations l10n,
) {
  final author = revision.author;
  if (author == null) return l10n.historySomeone;
  return author.id == currentUserId ? l10n.historyYou : author.name;
}

/// "2 lines added", or "2 lines added, 1 removed" when it did more.
String lineChangesLabel(LineCounts counts, AppLocalizations l10n) {
  final kinds = [
    (counts.added, l10n.diffLinesAdded, l10n.diffAdded),
    (counts.removed, l10n.diffLinesRemoved, l10n.diffRemoved),
    (counts.changed, l10n.diffLinesChanged, l10n.diffChanged),
  ].where((kind) => kind.$1 > 0).toList();
  if (kinds.isEmpty) return l10n.historyNoChanges;
  final (count, inLines, _) = kinds.first;
  return l10n.joinList([
    inLines(count),
    for (final (count, _, short) in kinds.skip(1)) short(count),
  ]);
}

String attachmentAddedLabel(
  AttachmentKind kind,
  AppLocalizations l10n, {
  required bool isOnline,
}) => switch ((kind, isOnline)) {
  (AttachmentKind.picture, true) => l10n.attachmentPictureAdded,
  (AttachmentKind.voiceNote, true) => l10n.attachmentVoiceAdded,
  (AttachmentKind.audioFile, true) => l10n.attachmentAudioAdded,
  (AttachmentKind.picture, false) => l10n.attachmentPictureAddedOffline,
  (AttachmentKind.voiceNote, false) => l10n.attachmentVoiceAddedOffline,
  (AttachmentKind.audioFile, false) => l10n.attachmentAudioAddedOffline,
};

String attachmentAddFailedLabel(AttachmentKind kind, AppLocalizations l10n) =>
    switch (kind) {
      AttachmentKind.picture => l10n.attachmentPictureAddFailed,
      AttachmentKind.voiceNote => l10n.attachmentVoiceAddFailed,
      AttachmentKind.audioFile => l10n.attachmentAudioAddFailed,
    };

String attachmentDeletedLabel(AttachmentKind kind, AppLocalizations l10n) =>
    switch (kind) {
      AttachmentKind.picture => l10n.attachmentPictureDeleted,
      AttachmentKind.voiceNote => l10n.attachmentVoiceDeleted,
      AttachmentKind.audioFile => l10n.attachmentAudioDeleted,
    };
