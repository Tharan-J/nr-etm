// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'durable_capture_dao.dart';

// ignore_for_file: type=lint
mixin _$DurableCaptureDaoMixin on DatabaseAccessor<AppDatabase> {
  $TicketTableTable get ticketTable => attachedDatabase.ticketTable;
  $TelemetryTableTable get telemetryTable => attachedDatabase.telemetryTable;
  $OutboundQueueTableTable get outboundQueueTable =>
      attachedDatabase.outboundQueueTable;
  DurableCaptureDaoManager get managers => DurableCaptureDaoManager(this);
}

class DurableCaptureDaoManager {
  final _$DurableCaptureDaoMixin _db;
  DurableCaptureDaoManager(this._db);
  $$TicketTableTableTableManager get ticketTable =>
      $$TicketTableTableTableManager(_db.attachedDatabase, _db.ticketTable);
  $$TelemetryTableTableTableManager get telemetryTable =>
      $$TelemetryTableTableTableManager(
        _db.attachedDatabase,
        _db.telemetryTable,
      );
  $$OutboundQueueTableTableTableManager get outboundQueueTable =>
      $$OutboundQueueTableTableTableManager(
        _db.attachedDatabase,
        _db.outboundQueueTable,
      );
}
