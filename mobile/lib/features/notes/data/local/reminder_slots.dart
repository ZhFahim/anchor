import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';

/// The OS notification id a note keeps for the life of its reminder.
Future<int> ensureReminderSlot(AppDatabase db, String noteId) async {
  final existing =
      await (db.selectOnly(db.notes)
            ..addColumns([db.notes.reminderSlot])
            ..where(db.notes.id.equals(noteId)))
          .map((row) => row.read(db.notes.reminderSlot))
          .getSingleOrNull();
  if (existing != null) return existing;

  final highest =
      await (db.selectOnly(db.notes)..addColumns([db.notes.reminderSlot.max()]))
          .map((row) => row.read(db.notes.reminderSlot.max()))
          .getSingleOrNull();
  return (highest ?? 0) + 1;
}
