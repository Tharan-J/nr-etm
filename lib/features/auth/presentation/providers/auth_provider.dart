import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/capture/data/app_database.dart';
import '../../../../core/config/secure_storage_service.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/models/conductor_session.dart';
import '../../domain/models/pairing_request.dart';

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceImpl();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remoteDataSource: ref.watch(authRemoteDataSourceProvider),
    secureStorage: ref.watch(secureStorageProvider),
    database: ref.watch(appDatabaseProvider),
  );
});

class AuthNotifier extends StateNotifier<AsyncValue<ConductorSession>> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AsyncValue.loading()) {
    checkInitialSession();
  }

  Future<void> checkInitialSession() async {
    state = const AsyncValue.loading();
    try {
      final session = await _repository.getActiveSession();
      state = AsyncValue.data(session);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> pairOperator(PairingRequest request) async {
    state = const AsyncValue.loading();
    try {
      final session = await _repository.pairOperator(request);
      state = AsyncValue.data(session);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    try {
      await _repository.logout();
      state = AsyncValue.data(
        ConductorSession(
          sessionId: 'sess_none',
          deviceId: 'dev_unknown',
          status: AuthStatus.unpaired,
          lastSyncAt: DateTime.now(),
        ),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<ConductorSession>>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});
