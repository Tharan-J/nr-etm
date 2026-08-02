import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nr_etm/core/capture/data/app_database.dart';
import 'package:nr_etm/core/platform/native_service_manager.dart';
import 'package:nr_etm/features/duty/domain/models/conductor_duty.dart';
import 'package:nr_etm/features/duty/presentation/providers/operational_state_provider.dart';
import 'package:nr_etm/features/trip/domain/models/bus_trip.dart';

class MockNativeServiceManager extends Mock implements NativeServiceManager {}

void main() {
  late AppDatabase database;
  late MockNativeServiceManager mockNativeServices;
  late OperationalStateNotifier notifier;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    mockNativeServices = MockNativeServiceManager();

    when(
      () => mockNativeServices.startDutyForegroundService(),
    ).thenAnswer((_) async => true);
    when(
      () => mockNativeServices.stopDutyForegroundService(),
    ).thenAnswer((_) async => true);

    notifier = OperationalStateNotifier(database, mockNativeServices);
  });

  tearDown(() async {
    await database.close();
  });

  test('Duty start initializes active conductor duty', () async {
    await notifier.startDuty(conductorId: 'COND_001', busId: 'BUS_101');

    expect(notifier.state.state, equals(OperationalState.dutyActive));
    expect(notifier.state.activeDuty?.conductorId, equals('COND_001'));
    expect(notifier.state.activeDuty?.status, equals(DutyStatus.active));
  });

  test(
    'Trip start activates trip state and starts native foreground service',
    () async {
      await notifier.startDuty(conductorId: 'COND_001', busId: 'BUS_101');
      await notifier.startTrip(
        routeId: 'route_335e',
        routeName: '335E',
        direction: TripDirection.up,
      );

      expect(notifier.state.state, equals(OperationalState.tripActive));
      expect(notifier.state.activeTrip?.routeId, equals('route_335e'));
      expect(notifier.state.activeTrip?.direction, equals(TripDirection.up));

      verify(() => mockNativeServices.startDutyForegroundService()).called(1);
    },
  );

  test(
    'Ending trip updates status and stops native foreground service',
    () async {
      await notifier.startDuty(conductorId: 'COND_001', busId: 'BUS_101');
      await notifier.startTrip(
        routeId: 'route_335e',
        routeName: '335E',
        direction: TripDirection.up,
      );
      await notifier.endTrip();

      expect(notifier.state.state, equals(OperationalState.tripCompleted));
      expect(notifier.state.activeTrip?.status, equals(TripStatus.completed));

      verify(() => mockNativeServices.stopDutyForegroundService()).called(1);
    },
  );

  test(
    'State recovery restores active trip state after simulated restart',
    () async {
      await notifier.startDuty(conductorId: 'COND_001', busId: 'BUS_101');
      await notifier.startTrip(
        routeId: 'route_335e',
        routeName: '335E',
        direction: TripDirection.up,
      );

      // Simulate app restart with existing SQLite database
      final restartedNotifier = OperationalStateNotifier(
        database,
        mockNativeServices,
      );
      await restartedNotifier.restoreStateFromStorage();

      expect(
        restartedNotifier.state.state,
        equals(OperationalState.tripActive),
      );
      expect(
        restartedNotifier.state.activeDuty?.conductorId,
        equals('COND_001'),
      );
      expect(restartedNotifier.state.activeTrip?.routeId, equals('route_335e'));
    },
  );
}
