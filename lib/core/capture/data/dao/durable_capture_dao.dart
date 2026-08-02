import 'package:drift/drift.dart';
import '../../../generated/proto/etm_telemetry.pb.dart';
import '../../../generated/proto/etm_ticket.pb.dart';
import '../app_database.dart';
import '../tables/outbound_queue_table.dart';
import '../tables/telemetry_table.dart';
import '../tables/ticket_table.dart';

part 'durable_capture_dao.g.dart';

@DriftAccessor(tables: [TicketTable, TelemetryTable, OutboundQueueTable])
class DurableCaptureDao extends DatabaseAccessor<AppDatabase>
    with _$DurableCaptureDaoMixin {
  DurableCaptureDao(super.db);

  /// Atomically captures a ticket and enqueues its binary protobuf representation.
  /// Durable-Capture-First guarantee (Spec 06 §5, Spec 07 §6.1).
  Future<void> captureTicketTransaction({
    required TicketTableCompanion ticketCompanion,
    required TicketRecord ticketRecord,
  }) async {
    return transaction(() async {
      // 1. Durably insert ticket record
      await into(ticketTable).insert(ticketCompanion);

      // 2. Serialize protobuf message to binary wire format
      final Uint8List payloadBytes = ticketRecord.writeToBuffer();

      // 3. Atomically enqueue into outbound queue
      await into(outboundQueueTable).insert(
        OutboundQueueTableCompanion.insert(
          id: ticketRecord.ticketId,
          payloadType: 'ticket',
          payloadBytes: payloadBytes,
          createdAt: DateTime.now(),
        ),
      );
    });
  }

  /// Atomically captures a telemetry ping and enqueues its binary protobuf representation.
  Future<void> captureTelemetryTransaction({
    required TelemetryTableCompanion telemetryCompanion,
    required TelemetryPingRecord telemetryRecord,
  }) async {
    return transaction(() async {
      // 1. Durably insert telemetry ping record
      await into(telemetryTable).insert(telemetryCompanion);

      // 2. Serialize protobuf message to binary wire format
      final Uint8List payloadBytes = telemetryRecord.writeToBuffer();

      // 3. Atomically enqueue into outbound queue
      await into(outboundQueueTable).insert(
        OutboundQueueTableCompanion.insert(
          id: telemetryRecord.pingId,
          payloadType: 'telemetry',
          payloadBytes: payloadBytes,
          createdAt: DateTime.now(),
        ),
      );
    });
  }
}
