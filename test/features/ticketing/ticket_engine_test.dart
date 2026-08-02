import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nr_etm/core/capture/data/app_database.dart';
import 'package:nr_etm/core/capture/data/dao/durable_capture_dao.dart';
import 'package:nr_etm/features/duty/domain/models/conductor_duty.dart';
import 'package:nr_etm/features/ticketing/domain/services/fare_engine.dart';
import 'package:nr_etm/features/ticketing/domain/services/ticket_issuance_engine.dart';
import 'package:nr_etm/features/ticketing/domain/services/ticket_validator.dart';
import 'package:nr_etm/features/trip/domain/models/bus_trip.dart';

void main() {
  late FareEngine fareEngine;
  late TicketValidator validator;
  late AppDatabase database;
  late DurableCaptureDao captureDao;
  late TicketIssuanceEngine issuanceEngine;

  setUp(() {
    fareEngine = FareEngine();
    validator = TicketValidator();
    database = AppDatabase(NativeDatabase.memory());
    captureDao = DurableCaptureDao(database);
    issuanceEngine = TicketIssuanceEngine(
      validator: validator,
      fareEngine: fareEngine,
      captureDao: captureDao,
    );
  });

  tearDown(() async {
    await database.close();
  });

  group('FareEngine Tests', () {
    test('calculateFare computes stage-to-stage adult fare accurately', () {
      final fare = fareEngine.calculateFare(
        sourceStage: 1,
        destStage: 4,
        passengerCategory: 'adult',
      );
      expect(fare.finalAmount, equals(30.0));
    });

    test('calculateFare applies senior citizen 40% discount', () {
      final fare = fareEngine.calculateFare(
        sourceStage: 1,
        destStage: 4,
        passengerCategory: 'senior',
      );
      expect(fare.finalAmount, equals(18.0));
    });

    test('calculateFare applies child 50% discount', () {
      final fare = fareEngine.calculateFare(
        sourceStage: 1,
        destStage: 4,
        passengerCategory: 'child',
      );
      expect(fare.finalAmount, equals(15.0));
    });
  });

  group('TicketValidator Business Invariant Tests', () {
    test('fails validation if duty is inactive', () {
      final res = validator.validateIssuanceRequest(
        activeDuty: null,
        activeTrip: null,
        sourceStage: 1,
        destStage: 3,
      );

      expect(res.isValid, isFalse);
      expect(res.errorCode, equals('ERR_DUTY_INACTIVE'));
    });

    test('fails validation if destination stage is before source stage', () {
      final duty = ConductorDuty(
        dutyId: 'd1',
        conductorId: 'c1',
        busId: 'b1',
        startTime: DateTime.now(),
        status: DutyStatus.active,
      );

      final trip = BusTrip(
        tripId: 't1',
        dutyId: 'd1',
        routeId: 'r1',
        routeName: '335E',
        direction: TripDirection.up,
        currentStage: 3,
        startTime: DateTime.now(),
        status: TripStatus.active,
      );

      final res = validator.validateIssuanceRequest(
        activeDuty: duty,
        activeTrip: trip,
        sourceStage: 4,
        destStage: 2,
      );

      expect(res.isValid, isFalse);
      expect(res.errorCode, equals('ERR_INVALID_STAGE'));
    });
  });

  group('TicketIssuanceEngine Atomic Issuance & Receipt Tests', () {
    test(
      'issues ticket and persists atomically to SQLite and sync queue',
      () async {
        final duty = ConductorDuty(
          dutyId: 'duty_01',
          conductorId: 'cond_01',
          busId: 'BUS_101',
          startTime: DateTime.now(),
          status: DutyStatus.active,
        );

        final trip = BusTrip(
          tripId: 'trip_01',
          dutyId: 'duty_01',
          routeId: 'route_335e',
          routeName: '335E',
          direction: TripDirection.up,
          currentStage: 1,
          startTime: DateTime.now(),
          status: TripStatus.active,
        );

        final result = await issuanceEngine.issueTicket(
          activeDuty: duty,
          activeTrip: trip,
          sourceStopId: 'stop_majestic',
          destStopId: 'stop_itpl',
          sourceStopName: 'Majestic',
          destStopName: 'ITPL',
          sourceStage: 1,
          destStage: 5,
          passengerCategory: 'adult',
        );

        expect(result.isSuccess, isTrue);
        expect(result.ticket?.fareAmount, equals(40.0));
        expect(result.receipt?.formattedPlainText, contains('NAMMAROUTE ETM'));
        expect(result.receipt?.thermalPrinterBytes, isNotNull);

        // Verify Drift database persistence
        final savedTickets = await database.select(database.ticketTable).get();
        final queueItems = await database
            .select(database.outboundQueueTable)
            .get();

        expect(savedTickets.length, equals(1));
        expect(queueItems.length, equals(1));
        expect(savedTickets.first.fareAmountPaise, equals(BigInt.from(4000)));
      },
    );
  });
}
