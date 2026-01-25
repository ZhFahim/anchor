import 'package:drift/drift.dart';

class Notes extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get content => text().nullable()();
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  TextColumn get background => text().nullable()();
  // State: 'active', 'trashed', 'deleted'
  TextColumn get state => text().withDefault(const Constant('active'))();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  
  // Sharing fields
  TextColumn get permission => text().withDefault(const Constant('owner'))();
  TextColumn get shareIds => text().nullable()(); // JSON array of user IDs
  TextColumn get sharedById => text().nullable()();
  TextColumn get sharedByName => text().nullable()();
  TextColumn get sharedByEmail => text().nullable()();
  TextColumn get sharedByProfileImage => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
