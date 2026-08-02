import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nr_etm/core/capture/data/app_database.dart';
import 'package:nr_etm/core/config/secure_storage_service.dart';
import 'package:nr_etm/core/network/mqtt_transport.dart';
import 'package:nr_etm/core/network/network_observer.dart';
import 'package:nr_etm/core/platform/native_service_manager.dart';
import 'package:nr_etm/core/sync/sync_engine.dart';
import 'package:nr_etm/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:nr_etm/features/auth/domain/models/conductor_session.dart';
import 'package:nr_etm/features/diagnostics/domain/models/system_health.dart';
import 'package:nr_etm/features/diagnostics/domain/services/health_engine.dart';
import 'package:nr_etm/features/reference/data/repositories/reference_repository_impl.dart';
import 'package:nr_etm/features/reference/domain/models/reference_catalog.dart';

class MockSecureStorageService extends Mock implements SecureStorageService {}

class MockMqttTransport extends Mock implements MqttTransport {}

class MockReferenceRepository extends Mock implements ReferenceRepository {}

class MockNativeServiceManager extends Mock implements NativeServiceManager {}

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late AppDatabase database;
  late MockSecureStorageService mockSecureStorage;
  late NetworkObserver networkObserver;
  late MockMqttTransport mockMqtt;
  late SyncEngine syncEngine;
  late MockReferenceRepository mockRefRepo;
  late MockNativeServiceManager mockNativeServices;
  late MockAuthRepository mockAuthRepo;
  late HealthEngine healthEngine;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    mockSecureStorage = MockSecureStorageService();
    networkObserver = NetworkObserver();
    mockMqtt = MockMqttTransport();
    mockRefRepo = MockReferenceRepository();
    mockNativeServices = MockNativeServiceManager();
    mockAuthRepo = MockAuthRepository();

    syncEngine = SyncEngine(
      database: database,
      transportAdapter: mockMqtt,
      networkObserver: networkObserver,
    );

    healthEngine = HealthEngine(
      database: database,
      secureStorage: mockSecureStorage,
      networkObserver: networkObserver,
      mqttTransport: mockMqtt,
      syncEngine: syncEngine,
      referenceRepository: mockRefRepo,
      nativeServiceManager: mockNativeServices,
      authRepository: mockAuthRepo,
    );

    when(() => mockMqtt.isConnected).thenReturn(true);
    when(() => mockRefRepo.getCachedCatalog()).thenAnswer(
      (_) async => ReferenceCatalog(
        catalogId: 'cat_1',
        version: 'v1.0',
        routes: const [],
        ticketTypes: const [],
        fetchedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 24)),
      ),
    );
    when(() => mockAuthRepo.getActiveSession()).thenAnswer(
      (_) async => ConductorSession(
        sessionId: 'sess_1',
        deviceId: 'DEV_001',
        status: AuthStatus.authenticated,
        conductorId: 'COND_101',
        lastSyncAt: DateTime.now(),
      ),
    );
    when(
      () => mockSecureStorage.getDeviceToken(),
    ).thenAnswer((_) async => 'token_123');
  });

  tearDown(() async {
    syncEngine.dispose();
    networkObserver.dispose();
    await database.close();
  });

  test(
    'evaluateSystemHealth reports healthy overall status when all components are green',
    () async {
      final report = await healthEngine.evaluateSystemHealth();
      expect(report.overallStatus, equals(HealthStatus.healthy));
      expect(
        report.subsystems['database']?.status,
        equals(HealthStatus.healthy),
      );
      expect(
        report.subsystems['network']?.status,
        equals(HealthStatus.healthy),
      );
      expect(report.subsystems['mqtt']?.status, equals(HealthStatus.healthy));
    },
  );

  test(
    'runSelfTest returns allPassed when subsystems are operational',
    () async {
      final selfTest = await healthEngine.runSelfTest();
      expect(selfTest.isAllPassed, isTrue);
      expect(selfTest.items.length, equals(9));
    },
  );
}
