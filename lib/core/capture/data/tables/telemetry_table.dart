import 'package:drift/drift.dart';

/// Telemetry Table — Local durable store for location & status pings (Spec 07 §6.2)
class TelemetryTable extends Table {
  TextColumn get pingId => text()();
  TextColumn get deviceId => text()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  RealColumn get speedMps => real()();
  RealColumn get headingDegrees => real()();
  DateTimeColumn get capturedAt => dateTime()();
  TextColumn get tripId => text().nullable()();
  IntColumn get batteryLevelPct => integer()();
  BoolColumn get isCharging => boolean()();
  TextColumn get syncStatus => text().withDefault(const Constant('buffered'))();

  @override
  Set<Column> get primaryKey => {pingId};
}
