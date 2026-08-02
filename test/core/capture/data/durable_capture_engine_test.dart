import 'package:drift/native.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nr_etm/core/capture/data/app_database.dart';
import 'package:nr_etm/core/capture/data/dao/durable_capture_dao.dart';
import 'package:nr_etm/core/generated/proto/etm_ticket.pb.dart';

void main() {
  late AppDatabase database;
  late DurableCaptureDao dao;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    dao = DurableCaptureDao(database);
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'Atomic ticket transaction saves ticket record and enqueues protobuf binary payload',
    () async {
      final now = DateTime.now();

      final ticketRecord = TicketRecord(
        ticketId: 'tkt_atomic_01',
        deviceId: 'dev_001',
        conductorId: 'cond_101',
        tripId: 'trip_55',
        fareRuleId: 'rule_v1',
        boardingStopId: 'stop_1',
        destinationStopId: 'stop_5',
        fareAmountPaise: Int64(4500),
        capturedAtEpochMs: Int64(now.millisecondsSinceEpoch),
        currency: 'INR',
        ticketSequenceNumber: 42,
      );

      final ticketCompanion = TicketTableCompanion.insert(
        ticketId: ticketRecord.ticketId,
        deviceId: ticketRecord.deviceId,
        conductorId: ticketRecord.conductorId,
        tripId: ticketRecord.tripId,
        fareRuleId: ticketRecord.fareRuleId,
        boardingStopId: ticketRecord.boardingStopId,
        destinationStopId: ticketRecord.destinationStopId,
        fareAmountPaise: BigInt.from(4500),
        capturedAt: now,
        ticketSequenceNumber: 42,
      );

      await dao.captureTicketTransaction(
        ticketCompanion: ticketCompanion,
        ticketRecord: ticketRecord,
      );

      // Verify ticket table state
      final tickets = await database.select(database.ticketTable).get();
      expect(tickets.length, equals(1));
      expect(tickets.first.ticketId, equals('tkt_atomic_01'));

      // Verify outbound queue state and protobuf binary deserialization integrity
      final queueItems = await database
          .select(database.outboundQueueTable)
          .get();
      expect(queueItems.length, equals(1));
      expect(queueItems.first.id, equals('tkt_atomic_01'));
      expect(queueItems.first.payloadType, equals('ticket'));

      final deserializedTicket = TicketRecord.fromBuffer(
        queueItems.first.payloadBytes,
      );
      expect(deserializedTicket.ticketId, equals('tkt_atomic_01'));
      expect(deserializedTicket.fareAmountPaise, equals(Int64(4500)));
      expect(deserializedTicket.ticketSequenceNumber, equals(42));
    },
  );

  test(
    'Transaction rollback ensures fail-closed integrity on unexpected failure',
    () async {
      final now = DateTime.now();
      final ticketRecord = TicketRecord(
        ticketId: 'tkt_rollback_01',
        deviceId: 'dev_001',
        conductorId: 'cond_101',
        tripId: 'trip_55',
        fareRuleId: 'rule_v1',
        boardingStopId: 'stop_1',
        destinationStopId: 'stop_5',
        fareAmountPaise: Int64(1500),
        capturedAtEpochMs: Int64(now.millisecondsSinceEpoch),
        ticketSequenceNumber: 1,
      );

      final ticketCompanion = TicketTableCompanion.insert(
        ticketId: ticketRecord.ticketId,
        deviceId: ticketRecord.deviceId,
        conductorId: ticketRecord.conductorId,
        tripId: ticketRecord.tripId,
        fareRuleId: ticketRecord.fareRuleId,
        boardingStopId: ticketRecord.boardingStopId,
        destinationStopId: ticketRecord.destinationStopId,
        fareAmountPaise: BigInt.from(1500),
        capturedAt: now,
        ticketSequenceNumber: 1,
      );

      // Force failure inside transaction by throwing custom exception
      try {
        await database.transaction(() async {
          await database.into(database.ticketTable).insert(ticketCompanion);
          throw Exception('Simulated power disruption mid-transaction');
        });
      } catch (_) {}

      // Verify neither table retained uncommitted state
      final tickets = await database.select(database.ticketTable).get();
      final queueItems = await database
          .select(database.outboundQueueTable)
          .get();

      expect(tickets, isEmpty);
      expect(queueItems, isEmpty);
    },
  );
}
