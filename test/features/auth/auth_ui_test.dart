import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nr_etm/app/app.dart';
import 'package:nr_etm/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:nr_etm/features/auth/domain/models/conductor_session.dart';
import 'package:nr_etm/features/auth/presentation/providers/auth_provider.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
  });

  testWidgets(
    'App renders SplashScreen on boot and navigates to PairingScreen when unpaired',
    (WidgetTester tester) async {
      final now = DateTime.now();
      when(() => mockRepository.getActiveSession()).thenAnswer(
        (_) async => ConductorSession(
          sessionId: 'none',
          deviceId: 'dev_01',
          status: AuthStatus.unpaired,
          lastSyncAt: now,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [authRepositoryProvider.overrideWithValue(mockRepository)],
          child: const EtmApp(),
        ),
      );

      // Initial Splash Screen rendering
      expect(find.text('NAMMAROUTE ETM'), findsOneWidget);

      await tester.pumpAndSettle();

      // After async resolution, navigates to Pairing Screen
      expect(find.text('Operator Pairing'), findsOneWidget);
      expect(find.text('PAIR DEVICE & AUTHENTICATE'), findsOneWidget);
    },
  );
}
