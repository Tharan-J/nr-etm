import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nr_etm/core/capture/data/app_database.dart';
import 'package:nr_etm/core/capture/data/dao/durable_capture_dao.dart';
import 'package:nr_etm/core/network/mqtt_transport.dart';
import 'package:nr_etm/core/network/network_observer.dart';
import 'package:nr_etm/core/platform/models/location_event.dart';
import 'package:nr_etm/core/sync/backpressure_manager.dart';
import 'package:nr_etm/core/sync/sync_engine.dart';
import 'package:nr_etm/features/telemetry/domain/services/telemetry_engine.dart';

class MockMqttTransport extends Mock implements MqttTransport {}

void main() {
  late AppDatabase database;
  late DurableCaptureDao captureDao;
  late MockMqttTransport mockTransport;
  late NetworkObserver networkObserver;
  late SyncEngine syncEngine;
  late TelemetryEngine telemetryEngine;
  late BackpressureManager backpressureManager;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    captureDao = DurableCaptureDao(database);
    mockTransport = MockMqttTransport();
    networkObserver = NetworkObserver();

    syncEngine = SyncEngine(
      database: database,
      transportAdapter: mockTransport,
      networkObserver: networkObserver,
    );

    telemetryEngine = TelemetryEngine(captureDao: captureDao);

    backpressureManager = BackpressureManager(
      syncEngine: syncEngine,
      telemetryEngine: telemetryEngine,
    );
  });

  tearDown(() async {
    syncEngine.dispose();
    networkObserver.dispose();
    await database.close();
  });

  test(
    'SyncEngine flushes items strictly by priority (tickets before telemetry)',
    () async {
      when(
        () => mockTransport.publishPayload(
          id: any(named: 'id'),
          payloadType: any(named: 'payloadType'),
          payloadBytes: any(named: 'payloadBytes'),
        ),
      ).thenAnswer((_) async => true);

      // Insert 1 telemetry ping (Priority 4) and 1 ticket (Priority 1)
      await database
          .into(database.outboundQueueTable)
          .insert(
            OutboundQueueTableCompanion.insert(
              id: 'ping_01',
              payloadType: 'telemetry',
              payloadBytes: Uint8List.fromList([1, 2, 3]),
              createdAt: DateTime.now(),
            ),
          );

      await database
          .into(database.outboundQueueTable)
          .insert(
            OutboundQueueTableCompanion.insert(
              id: 'tkt_01',
              payloadType: 'ticket',
              payloadBytes: Uint8List.fromList([4, 5, 6]),
              createdAt: DateTime.now(),
            ),
          );

      await syncEngine.flush();

      final capturedCalls = verify(
        () => mockTransport.publishPayload(
          id: captureAny(named: 'id'),
          payloadType: captureAny(named: 'payloadType'),
          payloadBytes: any(named: 'payloadBytes'),
        ),
      ).captured;

      // First invocation ID (Ticket - Priority 1)
      expect(capturedCalls[0], equals('tkt_01'));
      // Second invocation ID (Telemetry - Priority 4)
      expect(capturedCalls[2], equals('ping_01'));
    },
  );

  test(
    'TelemetryEngine captures position update into SQLite and outbound queue',
    () async {
      final event = LocationEvent(
        latitude: 12.9716,
        longitude: 77.5946,
        speed: 10.0,
        bearing: 90.0,
        accuracy: 4.0,
        timestamp: DateTime.now(),
      );

      await telemetryEngine.processLocationPing(
        event: event,
        tripId: 'trip_01',
        conductorId: 'cond_01',
        deviceId: 'DEV_001',
      );

      final telemetryRecords = await database
          .select(database.telemetryTable)
          .get();
      final queueItems = await database
          .select(database.outboundQueueTable)
          .get();

      expect(telemetryRecords.length, equals(1));
      expect(queueItems.length, equals(1));
      expect(queueItems.first.payloadType, equals('telemetry'));
    },
  );

  test(
    'BackpressureManager evaluates throttled state when queue count exceeds threshold',
    () async {
      // Populate database with 600 items
      for (int i = 0; i < 600; i++) {
        await database
            .into(database.outboundQueueTable)
            .insert(
              OutboundQueueTableCompanion.insert(
                id: 'item_$i',
                payloadType: 'telemetry',
                payloadBytes: Uint8List.fromList([1]),
                createdAt: DateTime.now(),
              ),
            );
      }

      await backpressureManager.evaluateQueueBackpressure();
      expect(backpressureManager.state, equals(BackpressureState.throttled));
    },
  );
}
