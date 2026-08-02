import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nr_etm/core/capture/data/app_database.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test('TicketTable stores and retrieves ticket records accurately', () async {
    final now = DateTime.now();
    await database
        .into(database.ticketTable)
        .insert(
          TicketTableCompanion.insert(
            ticketId: 'tkt_1001',
            deviceId: 'dev_001',
            conductorId: 'cond_404',
            tripId: 'trip_88',
            fareRuleId: 'rule_v1',
            boardingStopId: 'stop_a',
            destinationStopId: 'stop_b',
            fareAmountPaise: BigInt.from(2500),
            capturedAt: now,
            ticketSequenceNumber: 1,
          ),
        );

    final tickets = await database.select(database.ticketTable).get();
    expect(tickets.length, equals(1));
    expect(tickets.first.ticketId, equals('tkt_1001'));
    expect(tickets.first.fareAmountPaise, equals(BigInt.from(2500)));
    expect(tickets.first.currency, equals('INR'));
    expect(tickets.first.syncStatus, equals('buffered'));
  });

  test('TelemetryTable stores and retrieves location ping records', () async {
    final now = DateTime.now();
    await database
        .into(database.telemetryTable)
        .insert(
          TelemetryTableCompanion.insert(
            pingId: 'ping_501',
            deviceId: 'dev_001',
            latitude: 11.4102,
            longitude: 76.6950,
            speedMps: 12.5,
            headingDegrees: 180.0,
            capturedAt: now,
            batteryLevelPct: 85,
            isCharging: false,
          ),
        );

    final pings = await database.select(database.telemetryTable).get();
    expect(pings.length, equals(1));
    expect(pings.first.pingId, equals('ping_501'));
    expect(pings.first.latitude, equals(11.4102));
    expect(pings.first.syncStatus, equals('buffered'));
  });

  test('OutboundQueueTable manages buffer queue records', () async {
    final now = DateTime.now();
    await database
        .into(database.outboundQueueTable)
        .insert(
          OutboundQueueTableCompanion.insert(
            id: 'q_001',
            payloadType: 'ticket',
            payloadBytes: Uint8List.fromList([1, 2, 3, 4]),
            createdAt: now,
          ),
        );

    final items = await database.select(database.outboundQueueTable).get();
    expect(items.length, equals(1));
    expect(items.first.id, equals('q_001'));
    expect(items.first.payloadType, equals('ticket'));
    expect(items.first.status, equals('queued'));
  });

  test(
    'SessionStateTable maintains local identity and connectivity state',
    () async {
      final now = DateTime.now();
      await database
          .into(database.sessionStateTable)
          .insert(
            SessionStateTableCompanion.insert(
              sessionId: 'sess_default',
              deviceId: 'dev_001',
              updatedAt: now,
            ),
          );

      final sessions = await database.select(database.sessionStateTable).get();
      expect(sessions.length, equals(1));
      expect(sessions.first.sessionId, equals('sess_default'));
      expect(sessions.first.authState, equals('unknown'));
      expect(sessions.first.isConnected, isFalse);
    },
  );
}
