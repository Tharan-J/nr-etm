import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nr_etm/core/capture/data/app_database.dart';
import 'package:nr_etm/core/capture/data/dao/durable_capture_dao.dart';
import 'package:nr_etm/core/config/secure_storage_service.dart';
import 'package:nr_etm/core/network/mqtt_transport.dart';
import 'package:nr_etm/core/network/network_observer.dart';
import 'package:nr_etm/core/platform/native_service_manager.dart';
import 'package:nr_etm/core/sync/sync_engine.dart';
import 'package:nr_etm/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:nr_etm/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:nr_etm/features/auth/domain/models/conductor_session.dart';
import 'package:nr_etm/features/auth/domain/models/pairing_request.dart';
import 'package:nr_etm/features/duty/presentation/providers/operational_state_provider.dart';
import 'package:nr_etm/features/reference/data/datasources/reference_remote_datasource.dart';
import 'package:nr_etm/features/reference/data/repositories/reference_repository_impl.dart';
import 'package:nr_etm/features/reference/domain/models/bus_route.dart';
import 'package:nr_etm/features/reference/domain/models/bus_stop.dart';
import 'package:nr_etm/features/reference/domain/models/reference_catalog.dart';
import 'package:nr_etm/features/reference/domain/models/ticket_type.dart';
import 'package:nr_etm/features/ticketing/domain/services/fare_engine.dart';
import 'package:nr_etm/features/ticketing/domain/services/ticket_issuance_engine.dart';
import 'package:nr_etm/features/ticketing/domain/services/ticket_validator.dart';
import 'package:nr_etm/features/trip/domain/models/bus_trip.dart';

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

class MockReferenceRemoteDataSource extends Mock
    implements ReferenceRemoteDataSource {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

class MockNativeServiceManager extends Mock implements NativeServiceManager {}

class MockMqttTransport extends Mock implements MqttTransport {}

void main() {
  late AppDatabase database;
  late DurableCaptureDao captureDao;
  late MockAuthRemoteDataSource mockAuthRemote;
  late MockReferenceRemoteDataSource mockRefRemote;
  late MockSecureStorageService mockSecureStorage;
  late MockNativeServiceManager mockNativeServices;
  late MockMqttTransport mockTransport;
  late NetworkObserver networkObserver;

  late AuthRepositoryImpl authRepository;
  late ReferenceRepositoryImpl referenceRepository;
  late OperationalStateNotifier operationalNotifier;
  late TicketIssuanceEngine ticketingEngine;
  late SyncEngine syncEngine;

  setUpAll(() {
    registerFallbackValue(
      const PairingRequest(
        deviceId: 'DEV_001',
        conductorPin: '123456',
        busId: 'KA-01-F-1234',
      ),
    );
  });

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    captureDao = DurableCaptureDao(database);
    mockAuthRemote = MockAuthRemoteDataSource();
    mockRefRemote = MockReferenceRemoteDataSource();
    mockSecureStorage = MockSecureStorageService();
    mockNativeServices = MockNativeServiceManager();
    mockTransport = MockMqttTransport();
    networkObserver = NetworkObserver();

    when(
      () => mockSecureStorage.getDeviceToken(),
    ).thenAnswer((_) async => 'token_123');
    when(
      () => mockSecureStorage.getDeviceId(),
    ).thenAnswer((_) async => 'DEV_001');
    when(
      () => mockSecureStorage.saveDeviceToken(any()),
    ).thenAnswer((_) async => {});
    when(
      () => mockSecureStorage.saveDeviceId(any()),
    ).thenAnswer((_) async => {});

    when(
      () => mockNativeServices.startDutyForegroundService(),
    ).thenAnswer((_) async => true);
    when(
      () => mockNativeServices.stopDutyForegroundService(),
    ).thenAnswer((_) async => true);

    when(
      () => mockTransport.publishPayload(
        id: any(named: 'id'),
        payloadType: any(named: 'payloadType'),
        payloadBytes: any(named: 'payloadBytes'),
      ),
    ).thenAnswer((_) async => true);

    authRepository = AuthRepositoryImpl(
      remoteDataSource: mockAuthRemote,
      secureStorage: mockSecureStorage,
      database: database,
    );

    referenceRepository = ReferenceRepositoryImpl(
      database: database,
      remoteDataSource: mockRefRemote,
    );

    operationalNotifier = OperationalStateNotifier(
      database,
      mockNativeServices,
    );

    ticketingEngine = TicketIssuanceEngine(
      validator: TicketValidator(),
      fareEngine: FareEngine(),
      captureDao: captureDao,
    );

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

  test('Full E2E Operational & Ticketing Workflow', () async {
    // 1. Operator Pairing & Authentication
    when(() => mockAuthRemote.pairDevice(any())).thenAnswer(
      (_) async => const PairingResponse(
        token: 'jwt_mock_token_999',
        conductorId: 'COND_777',
        sessionId: 'sess_999',
      ),
    );

    const request = PairingRequest(
      deviceId: 'DEV_001',
      conductorPin: '123456',
      busId: 'KA-01-F-1234',
    );

    final session = await authRepository.pairOperator(request);
    expect(session.status, equals(AuthStatus.authenticated));

    // 2. Reference Catalog Caching
    final testCatalog = ReferenceCatalog(
      catalogId: 'cat_01',
      version: 'v1.0',
      routes: [
        const BusRoute(
          routeId: 'route_335e',
          routeName: '335E',
          routeCode: '335E',
          origin: 'Majestic',
          destination: 'ITPL',
          stops: [
            BusStop(
              stopId: 'stop_majestic',
              name: 'Majestic',
              code: 'MAJ',
              stageNumber: 1,
              latitude: 12.9776,
              longitude: 77.5713,
            ),
            BusStop(
              stopId: 'stop_itpl',
              name: 'ITPL',
              code: 'ITPL',
              stageNumber: 5,
              latitude: 12.9863,
              longitude: 77.7342,
            ),
          ],
        ),
      ],
      ticketTypes: [
        const TicketType(
          typeId: 'type_adult',
          name: 'Adult',
          category: 'single',
          defaultFare: 10.0,
          isPass: false,
        ),
      ],
      fetchedAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(hours: 24)),
    );

    when(
      () => mockRefRemote.fetchCatalog(),
    ).thenAnswer((_) async => testCatalog);

    final catalog = await referenceRepository.fetchAndCacheCatalog();
    expect(catalog.routes.length, equals(1));

    // 3. Start Duty
    await operationalNotifier.startDuty(
      conductorId: 'COND_777',
      busId: 'KA-01-F-1234',
    );
    expect(
      operationalNotifier.state.state,
      equals(OperationalState.dutyActive),
    );

    // 4. Start Trip
    await operationalNotifier.startTrip(
      routeId: 'route_335e',
      routeName: '335E',
      direction: TripDirection.up,
    );
    expect(
      operationalNotifier.state.state,
      equals(OperationalState.tripActive),
    );
    verify(() => mockNativeServices.startDutyForegroundService()).called(1);

    // 5. Issue Ticket & Atomic Durable Capture
    final issueResult = await ticketingEngine.issueTicket(
      activeDuty: operationalNotifier.state.activeDuty,
      activeTrip: operationalNotifier.state.activeTrip,
      sourceStopId: 'stop_majestic',
      destStopId: 'stop_itpl',
      sourceStopName: 'Majestic',
      destStopName: 'ITPL',
      sourceStage: 1,
      destStage: 5,
      passengerCategory: 'adult',
    );

    expect(issueResult.isSuccess, isTrue);
    expect(issueResult.ticket?.fareAmount, equals(40.0));

    // 6. Verify SQLite Persistence & Outbox Queue Enqueue
    final savedTickets = await database.select(database.ticketTable).get();
    var queueItems = await database.select(database.outboundQueueTable).get();
    expect(savedTickets.length, equals(1));
    expect(queueItems.length, equals(1));

    // 7. Flush Outbox Queue over MQTT Transport
    await syncEngine.flush();

    // 8. Verify ACK & Queue Cleared
    queueItems = await database.select(database.outboundQueueTable).get();
    expect(queueItems.length, equals(0));
  });
}
