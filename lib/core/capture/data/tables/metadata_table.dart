import 'package:drift/drift.dart';

/// Minimal table to validate database infrastructure, versioning, and migration framework
class MetadataTable extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {key};
}
