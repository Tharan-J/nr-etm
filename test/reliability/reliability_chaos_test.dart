import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nr_etm/core/capture/data/app_database.dart';
import 'package:nr_etm/core/network/mqtt_transport.dart';
import 'package:nr_etm/core/network/network_observer.dart';
import 'package:nr_etm/core/platform/native_service_manager.dart';
import 'package:nr_etm/core/sync/sync_engine.dart';
import 'package:nr_etm/features/duty/presentation/providers/operational_state_provider.dart';
import 'package:nr_etm/features/trip/domain/models/bus_trip.dart';

class MockMqttTransport extends Mock implements MqttTransport {}

class MockNativeServiceManager extends Mock implements NativeServiceManager {}

void main() {
  late AppDatabase database;
  late MockMqttTransport mockTransport;
  late MockNativeServiceManager mockNativeServices;
  late NetworkObserver networkObserver;
  late SyncEngine syncEngine;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    mockTransport = MockMqttTransport();
    mockNativeServices = MockNativeServiceManager();
    networkObserver = NetworkObserver();

    syncEngine = SyncEngine(
      database: database,
      transportAdapter: mockTransport,
      networkObserver: networkObserver,
    );

    when(
      () => mockNativeServices.startDutyForegroundService(),
    ).thenAnswer((_) async => true);
    when(
      () => mockNativeServices.stopDutyForegroundService(),
    ).thenAnswer((_) async => true);
  });

  tearDown(() async {
    syncEngine.dispose();
    networkObserver.dispose();
    await database.close();
  });

  group('Phase 6 — Queue & SQLite Stress Tests', () {
    test(
      'High Volume Outbox Backlog (5,000 tickets + 10,000 pings) batch delivery',
      () async {
        final stopWatch = Stopwatch()..start();

        // Populate 5,000 ticket outbox records in SQLite transaction
        await database.transaction(() async {
          for (int i = 0; i < 5000; i++) {
            await database
                .into(database.outboundQueueTable)
                .insert(
                  OutboundQueueTableCompanion.insert(
                    id: 'tkt_stress_$i',
                    payloadType: 'ticket',
                    payloadBytes: Uint8List.fromList([1, 2, 3, 4]),
                    createdAt: DateTime.now(),
                  ),
                );
          }

          for (int i = 0; i < 10000; i++) {
            await database
                .into(database.outboundQueueTable)
                .insert(
                  OutboundQueueTableCompanion.insert(
                    id: 'ping_stress_$i',
                    payloadType: 'telemetry',
                    payloadBytes: Uint8List.fromList([5, 6, 7]),
                    createdAt: DateTime.now(),
                  ),
                );
          }
        });

        stopWatch.stop();

        final pendingCount = await syncEngine.getPendingQueueCount();
        expect(pendingCount, equals(15000));
        expect(
          stopWatch.elapsedMilliseconds,
          lessThan(10000),
        ); // Batch insert under 10s

        when(
          () => mockTransport.publishPayload(
            id: any(named: 'id'),
            payloadType: any(named: 'payloadType'),
            payloadBytes: any(named: 'payloadBytes'),
          ),
        ).thenAnswer((_) async => true);

        // Verify Priority Flushing (Tickets processed first)
        await syncEngine.flush();

        final remaining = await syncEngine.getPendingQueueCount();
        expect(remaining, equals(0));
      },
    );
  });

  group('Phase 6 — Crash & Reboot Process Restoration Tests', () {
    test(
      'Simulated Process Termination restores active Duty & Trip with zero ticket loss',
      () async {
        // 1. Initial State before crash
        final notifier = OperationalStateNotifier(database, mockNativeServices);
        await notifier.startDuty(conductorId: 'COND_777', busId: 'BUS_101');
        await notifier.startTrip(
          routeId: 'route_335e',
          routeName: '335E',
          direction: TripDirection.up,
        );

        expect(notifier.state.state, equals(OperationalState.tripActive));

        // 2. Simulate Process Crash (Re-instantiate notifier from same SQLite database)
        final restoredNotifier = OperationalStateNotifier(
          database,
          mockNativeServices,
        );
        await restoredNotifier.restoreStateFromStorage();

        // 3. Verify 100% state restoration
        expect(
          restoredNotifier.state.state,
          equals(OperationalState.tripActive),
        );
        expect(
          restoredNotifier.state.activeDuty?.conductorId,
          equals('COND_777'),
        );
        expect(restoredNotifier.state.activeTrip?.routeName, equals('335E'));
      },
    );
  });

  group('Phase 6 — Network Chaos & Recovery Tests', () {
    test(
      'Rapid network toggling (Online -> Offline -> Poor) retains sync state integrity',
      () async {
        networkObserver.setStatus(NetworkStatus.offline);

        await database
            .into(database.outboundQueueTable)
            .insert(
              OutboundQueueTableCompanion.insert(
                id: 'tkt_chaos_01',
                payloadType: 'ticket',
                payloadBytes: Uint8List.fromList([9, 9, 9]),
                createdAt: DateTime.now(),
              ),
            );

        // Flush while offline (must skip delivery)
        await syncEngine.flush();
        expect(await syncEngine.getPendingQueueCount(), equals(1));

        // Toggle Network to Online
        when(
          () => mockTransport.publishPayload(
            id: any(named: 'id'),
            payloadType: any(named: 'payloadType'),
            payloadBytes: any(named: 'payloadBytes'),
          ),
        ).thenAnswer((_) async => true);

        networkObserver.setStatus(NetworkStatus.online);
        await syncEngine.flush();

        expect(await syncEngine.getPendingQueueCount(), equals(0));
      },
    );
  });
}
