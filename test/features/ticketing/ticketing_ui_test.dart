import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nr_etm/features/reference/data/repositories/reference_repository_impl.dart';
import 'package:nr_etm/features/reference/domain/models/bus_route.dart';
import 'package:nr_etm/features/reference/domain/models/bus_stop.dart';
import 'package:nr_etm/features/reference/domain/models/reference_catalog.dart';
import 'package:nr_etm/features/reference/presentation/providers/reference_provider.dart';
import 'package:nr_etm/ui/screens/ticketing_screen.dart';

void main() {
  const sampleStops = [
    BusStop(stopId: 'stop_1', name: 'Majestic', code: 'STP01', latitude: 12.97, longitude: 77.57, stageNumber: 1),
    BusStop(stopId: 'stop_2', name: 'Corporation', code: 'STP02', latitude: 12.96, longitude: 77.58, stageNumber: 2),
    BusStop(stopId: 'stop_3', name: 'Indiranagar', code: 'STP03', latitude: 12.97, longitude: 77.63, stageNumber: 3),
  ];

  const sampleRoute = BusRoute(
    routeId: 'route_1',
    routeName: '335E',
    routeCode: 'R335E',
    origin: 'Majestic',
    destination: 'ITPL',
    stops: sampleStops,
  );

  final sampleCatalog = ReferenceCatalog(
    catalogId: 'cat_1',
    version: 'v1.0',
    routes: const [sampleRoute],
    ticketTypes: const [],
    fetchedAt: DateTime.now(),
    expiresAt: DateTime.now().add(const Duration(hours: 24)),
  );

  testWidgets('TicketingScreen renders quick stage control and responds to NEXT STOP +', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          referenceCatalogNotifierProvider.overrideWith(
            (ref) => MockCatalogNotifier(sampleCatalog),
          ),
        ],
        child: const MaterialApp(
          home: TicketingScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title & Screen Elements
    expect(find.text('E-Ticketing'), findsOneWidget);
    expect(find.text('OFFLINE READY'), findsOneWidget);
    expect(find.text('NEXT STOP +'), findsOneWidget);

    // Tap NEXT STOP +
    await tester.tap(find.byKey(const Key('next_stop_button')));
    await tester.pumpAndSettle();

    // Verify stage incremented stop display
    expect(find.text('Corporation (Stage 2)'), findsWidgets);
  });
}

class MockCatalogNotifier extends ReferenceCatalogNotifier {
  MockCatalogNotifier(ReferenceCatalog catalog)
      : super(FakeReferenceRepository(catalog));
}

class FakeReferenceRepository implements ReferenceRepository {
  final ReferenceCatalog catalog;
  FakeReferenceRepository(this.catalog);

  @override
  Future<ReferenceCatalog?> getCachedCatalog() async => catalog;

  @override
  Future<ReferenceCatalog> fetchAndCacheCatalog() async => catalog;

  Future<bool> hasValidCatalog() async => true;

  @override
  Future<bool> isCatalogStale() async => false;
}
