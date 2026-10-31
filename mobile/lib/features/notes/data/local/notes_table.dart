import 'package:drift/drift.dart';

@DataClassName('NoteRow')
class Notes extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get noteType => text().withDefault(const Constant('note'))();
  TextColumn get content => text().nullable()();
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  TextColumn get background => text().nullable()();
  // State: 'active', 'trashed', 'deleted'
  TextColumn get state => text().withDefault(const Constant('active'))();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  // The server version this note was written against; null until it exists there.
  IntColumn get version => integer().nullable()();
  // Must go up on every local edit.
  IntColumn get localRev => integer().withDefault(const Constant(0))();
  // Pins are per user and sync on their own.
  BoolColumn get isPinSynced => boolean().withDefault(const Constant(true))();

  // The note as the server last confirmed it; null until confirmed.
  TextColumn get syncedTitle => text().nullable()();
  TextColumn get syncedContent => text().nullable()();
  TextColumn get syncedBackground => text().nullable()();
  TextColumn get syncedState => text().nullable()();

  // A local wall clock ("YYYY-MM-DDTHH:mm"), not an instant.
  TextColumn get reminderAt => text().nullable()();
  TextColumn get reminderRecurrence => text().nullable()();
  IntColumn get reminderVersion => integer().nullable()();
  BoolColumn get isReminderSynced =>
      boolean().withDefault(const Constant(true))();

  // Local only, never synced: the OS notification id this note occupies.
  IntColumn get reminderSlot => integer().nullable()();

  TextColumn get permission => text().withDefault(const Constant('owner'))();
  TextColumn get shareIds => text().nullable()(); // JSON array of user IDs
  TextColumn get sharedById => text().nullable()();
  TextColumn get sharedByName => text().nullable()();
  TextColumn get sharedByEmail => text().nullable()();
  TextColumn get sharedByProfileImage => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
