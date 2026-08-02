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
  final AuthRemoteDataSource remoteDataSource;
  final SecureStorageService secureStorage;
  final AppDatabase database;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.secureStorage,
    required this.database,
  });

  @override
  Future<ConductorSession> getActiveSession() async {
    final token = await secureStorage.getDeviceToken();
    final deviceId = await secureStorage.getDeviceId() ?? 'dev_unknown';

    if (token == null || token.isEmpty) {
      return ConductorSession(
        sessionId: 'sess_none',
        deviceId: deviceId,
        status: AuthStatus.unpaired,
        lastSyncAt: DateTime.now(),
      );
    }

    final sessionRecords = await (database.select(database.sessionStateTable)
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
    final pairingResponse = await remoteDataSource.pairDevice(request);

    // Save tokens securely
    await secureStorage.saveDeviceToken(pairingResponse.token);
    await secureStorage.saveDeviceId(request.deviceId);
    if (pairingResponse.refreshToken != null) {
      await secureStorage.saveRefreshToken(pairingResponse.refreshToken!);
    }

    final now = DateTime.now();

    // Persist session state in Drift database
    await database.into(database.sessionStateTable).insertOnConflictUpdate(
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
    await secureStorage.clearAllCredentials();
    await database.delete(database.sessionStateTable).go();
  }
}
