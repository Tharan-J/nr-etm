import 'package:drift/drift.dart';

/// Session State Table — Local operational state & pairing cache (Spec 07 §7.3, §8.1)
class SessionStateTable extends Table {
  TextColumn get sessionId => text()();
  TextColumn get deviceId => text()();
  TextColumn get conductorId => text().nullable()();
  TextColumn get tripId => text().nullable()();
  TextColumn get busId => text().nullable()();
  TextColumn get authState => text().withDefault(
    const Constant('unknown'),
  )(); // 'authorized', 'denied', 'unknown'
  BoolColumn get isConnected => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastSyncAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {sessionId};
}
