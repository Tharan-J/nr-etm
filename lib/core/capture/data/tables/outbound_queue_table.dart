import 'package:drift/drift.dart';

/// Outbound Queue Table — Buffer queue for background synchronization (Spec 07 §6.1, §6.2)
class OutboundQueueTable extends Table {
  TextColumn get id => text()();
  TextColumn get payloadType => text()(); // 'ticket' or 'telemetry'
  BlobColumn get payloadBytes => blob()(); // Serialized Protobuf payload
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();
  TextColumn get status => text().withDefault(
    const Constant('queued'),
  )(); // 'queued', 'in_flight', 'failed', 'sent'

  @override
  Set<Column> get primaryKey => {id};
}
