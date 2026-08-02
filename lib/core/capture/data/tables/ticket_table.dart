import 'package:drift/drift.dart';

/// Ticket Table — Local durable store for captured tickets (Spec 07 §6.1)
class TicketTable extends Table {
  TextColumn get ticketId => text()();
  TextColumn get deviceId => text()();
  TextColumn get conductorId => text()();
  TextColumn get tripId => text()();
  TextColumn get fareRuleId => text()();
  TextColumn get boardingStopId => text()();
  TextColumn get destinationStopId => text()();
  Int64Column get fareAmountPaise => int64()();
  DateTimeColumn get capturedAt => dateTime()();
  TextColumn get currency => text().withDefault(const Constant('INR'))();
  TextColumn get commuterId => text().nullable()();
  IntColumn get ticketSequenceNumber => integer()();
  TextColumn get syncStatus => text().withDefault(const Constant('buffered'))();

  @override
  Set<Column> get primaryKey => {ticketId};
}
