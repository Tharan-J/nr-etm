import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nr_etm/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:nr_etm/features/auth/domain/models/conductor_session.dart';
import 'package:nr_etm/features/auth/domain/models/pairing_request.dart';
import 'package:nr_etm/features/auth/presentation/providers/auth_provider.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
  });

  test('AuthNotifier initializes by fetching active session', () async {
    final now = DateTime.now();
    final mockSession = ConductorSession(
      sessionId: 'sess_1',
      deviceId: 'dev_01',
      status: AuthStatus.authenticated,
      lastSyncAt: now,
    );

    when(
      () => mockRepository.getActiveSession(),
    ).thenAnswer((_) async => mockSession);

    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(mockRepository)],
    );
    addTearDown(container.dispose);

    // Initial state is loading then resolves to data
    expect(
      container.read(authNotifierProvider),
      const AsyncValue<ConductorSession>.loading(),
    );

    await container.read(authNotifierProvider.notifier).checkInitialSession();

    final state = container.read(authNotifierProvider);
    expect(state.value?.status, equals(AuthStatus.authenticated));
    expect(state.value?.sessionId, equals('sess_1'));
  });

  test(
    'AuthNotifier pairOperator updates state to authenticated session',
    () async {
      final now = DateTime.now();
      when(() => mockRepository.getActiveSession()).thenAnswer(
        (_) async => ConductorSession(
          sessionId: 'none',
          deviceId: 'dev_01',
          status: AuthStatus.unpaired,
          lastSyncAt: now,
        ),
      );

      const request = PairingRequest(
        deviceId: 'dev_01',
        conductorPin: '9999',
        busId: 'BUS_01',
      );

      final pairedSession = ConductorSession(
        sessionId: 'sess_paired',
        deviceId: 'dev_01',
        conductorId: 'cond_99',
        busId: 'BUS_01',
        status: AuthStatus.authenticated,
        lastSyncAt: now,
      );

      when(
        () => mockRepository.pairOperator(request),
      ).thenAnswer((_) async => pairedSession);

      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(mockRepository)],
      );
      addTearDown(container.dispose);

      await container.read(authNotifierProvider.notifier).pairOperator(request);

      final state = container.read(authNotifierProvider);
      expect(state.value?.status, equals(AuthStatus.authenticated));
      expect(state.value?.conductorId, equals('cond_99'));
    },
  );
}
