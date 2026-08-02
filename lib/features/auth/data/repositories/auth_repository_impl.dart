import 'package:drift/drift.dart';

import '../../../../core/capture/data/app_database.dart';
import '../../../../core/config/secure_storage_service.dart';
import '../../domain/models/conductor_session.dart';
import '../../domain/models/pairing_request.dart';
import '../datasources/auth_remote_datasource.dart';

abstract class AuthRepository {
  Future<ConductorSession> getActiveSession();
  Future<ConductorSession> pairOperator(PairingRequest request);
  Future<void> logout();
}

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final SecureStorageService _secureStorage;
  final AppDatabase _database;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required SecureStorageService secureStorage,
    required AppDatabase database,
  })  : _remoteDataSource = remoteDataSource,
        _secureStorage = secureStorage,
        _database = database;

  @override
  Future<ConductorSession> getActiveSession() async {
    final token = await _secureStorage.getDeviceToken();
    final deviceId = await _secureStorage.getDeviceId() ?? 'dev_unknown';

    if (token == null || token.isEmpty) {
      return ConductorSession(
        sessionId: 'sess_none',
        deviceId: deviceId,
        status: AuthStatus.unpaired,
        lastSyncAt: DateTime.now(),
      );
    }

    final sessionRecords = await (_database.select(_database.sessionStateTable)
          ..where((t) => t.deviceId.equals(deviceId)))
        .get();

    if (sessionRecords.isNotEmpty) {
      final record = sessionRecords.first;
      return ConductorSession(
        sessionId: record.sessionId,
        deviceId: record.deviceId,
        conductorId: record.conductorId,
        busId: record.busId,
        tripId: record.tripId,
        status: record.authState == 'authorized' ? AuthStatus.authenticated : AuthStatus.unpaired,
        lastSyncAt: record.lastSyncAt ?? record.updatedAt,
      );
    }

    return ConductorSession(
      sessionId: 'sess_${DateTime.now().millisecondsSinceEpoch}',
      deviceId: deviceId,
      status: AuthStatus.authenticated,
      lastSyncAt: DateTime.now(),
    );
  }

  @override
  Future<ConductorSession> pairOperator(PairingRequest request) async {
    final pairingResponse = await _remoteDataSource.pairDevice(request);

    // Save tokens securely
    await _secureStorage.saveDeviceToken(pairingResponse.token);
    await _secureStorage.saveDeviceId(request.deviceId);
    if (pairingResponse.refreshToken != null) {
      await _secureStorage.saveRefreshToken(pairingResponse.refreshToken!);
    }

    final now = DateTime.now();

    // Persist session state in Drift database
    await _database.into(_database.sessionStateTable).insertOnConflictUpdate(
          SessionStateTableCompanion.insert(
            sessionId: pairingResponse.sessionId,
            deviceId: request.deviceId,
            conductorId: Value(pairingResponse.conductorId),
            busId: Value(request.busId),
            authState: const Value('authorized'),
            isConnected: const Value(true),
            lastSyncAt: Value(now),
            updatedAt: now,
          ),
        );

    return ConductorSession(
      sessionId: pairingResponse.sessionId,
      deviceId: request.deviceId,
      conductorId: pairingResponse.conductorId,
      busId: request.busId,
      status: AuthStatus.authenticated,
      lastSyncAt: now,
    );
  }

  @override
  Future<void> logout() async {
    await _secureStorage.clearAllCredentials();
    await _database.delete(_database.sessionStateTable).go();
  }
}
