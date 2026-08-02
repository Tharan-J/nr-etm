import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nr_etm/core/capture/data/app_database.dart';
import 'package:nr_etm/core/config/secure_storage_service.dart';
import 'package:nr_etm/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:nr_etm/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:nr_etm/features/auth/domain/models/conductor_session.dart';
import 'package:nr_etm/features/auth/domain/models/pairing_request.dart';

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  late MockAuthRemoteDataSource mockRemote;
  late MockSecureStorageService mockStorage;
  late AppDatabase database;
  late AuthRepository repository;

  setUp(() {
    mockRemote = MockAuthRemoteDataSource();
    mockStorage = MockSecureStorageService();
    database = AppDatabase(NativeDatabase.memory());

    repository = AuthRepositoryImpl(
      remoteDataSource: mockRemote,
      secureStorage: mockStorage,
      database: database,
    );
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'getActiveSession returns unpaired status when no stored token exists',
    () async {
      when(() => mockStorage.getDeviceToken()).thenAnswer((_) async => null);
      when(() => mockStorage.getDeviceId()).thenAnswer((_) async => 'dev_101');

      final session = await repository.getActiveSession();

      expect(session.status, equals(AuthStatus.unpaired));
      expect(session.deviceId, equals('dev_101'));
    },
  );

  test(
    'pairOperator calls remote API, saves credentials, and updates session state',
    () async {
      const request = PairingRequest(
        deviceId: 'dev_101',
        conductorPin: '1234',
        busId: 'BUS_77',
      );

      const response = PairingResponse(
        token: 'jwt_token_99',
        conductorId: 'cond_55',
        sessionId: 'sess_abc',
      );

      when(
        () => mockRemote.pairDevice(request),
      ).thenAnswer((_) async => response);
      when(
        () => mockStorage.saveDeviceToken('jwt_token_99'),
      ).thenAnswer((_) async {});
      when(() => mockStorage.saveDeviceId('dev_101')).thenAnswer((_) async {});

      final session = await repository.pairOperator(request);

      expect(session.status, equals(AuthStatus.authenticated));
      expect(session.sessionId, equals('sess_abc'));
      expect(session.conductorId, equals('cond_55'));

      final storedSessions = await database
          .select(database.sessionStateTable)
          .get();
      expect(storedSessions.length, equals(1));
      expect(storedSessions.first.sessionId, equals('sess_abc'));
    },
  );
}
