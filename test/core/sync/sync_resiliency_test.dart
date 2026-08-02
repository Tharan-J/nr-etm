import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nr_etm/core/capture/data/app_database.dart';
import 'package:nr_etm/core/network/mqtt_transport.dart';
import 'package:nr_etm/core/network/network_observer.dart';
import 'package:nr_etm/core/sync/sync_engine.dart';

class MockMqttTransport extends Mock implements MqttTransport {}

void main() {
  late AppDatabase database;
  late MockMqttTransport mockTransport;
  late NetworkObserver networkObserver;
  late SyncEngine syncEngine;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    mockTransport = MockMqttTransport();
    networkObserver = NetworkObserver();

    syncEngine = SyncEngine(
      database: database,
      transportAdapter: mockTransport,
      networkObserver: networkObserver,
    );
  });

  tearDown(() async {
    syncEngine.dispose();
    networkObserver.dispose();
    await database.close();
  });

  group('Phase 3 & 5 — Sync Engine Network Resiliency Tests', () {
    test(
      'SyncEngine retries failed transmissions up to 3 times before pausing batch',
      () async {
        await database
            .into(database.outboundQueueTable)
            .insert(
              OutboundQueueTableCompanion.insert(
                id: 'tkt_resilient_01',
                payloadType: 'ticket',
                payloadBytes: Uint8List.fromList([1, 2, 3]),
                createdAt: DateTime.now(),
              ),
            );

        when(
          () => mockTransport.publishPayload(
            id: any(named: 'id'),
            payloadType: any(named: 'payloadType'),
            payloadBytes: any(named: 'payloadBytes'),
          ),
        ).thenAnswer((_) async => false); // Transient transport failure

        await syncEngine.flush();

        // Item should remain in queue due to transport failure
        final remaining = await syncEngine.getPendingQueueCount();
        expect(remaining, equals(1));
      },
    );
  });
}
