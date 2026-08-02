import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nr_etm/core/capture/data/app_database.dart';
import 'package:nr_etm/features/reference/data/datasources/reference_remote_datasource.dart';
import 'package:nr_etm/features/reference/data/repositories/reference_repository_impl.dart';
import 'package:nr_etm/features/reference/domain/models/bus_route.dart';
import 'package:nr_etm/features/reference/domain/models/bus_stop.dart';
import 'package:nr_etm/features/reference/domain/models/reference_catalog.dart';
import 'package:nr_etm/features/reference/domain/models/ticket_type.dart';

class MockReferenceRemoteDataSource extends Mock
    implements ReferenceRemoteDataSource {}

void main() {
  late MockReferenceRemoteDataSource mockRemote;
  late AppDatabase database;
  late ReferenceRepository repository;

  setUp(() {
    mockRemote = MockReferenceRemoteDataSource();
    database = AppDatabase(NativeDatabase.memory());
    repository = ReferenceRepositoryImpl(
      remoteDataSource: mockRemote,
      database: database,
    );
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'fetchAndCacheCatalog retrieves catalog from remote and persists into Drift storage',
    () async {
      final now = DateTime.now();
      final catalog = ReferenceCatalog(
        catalogId: 'cat_test_1',
        version: 'v1.0.0',
        routes: [
          const BusRoute(
            routeId: 'r1',
            routeName: 'Route 1',
            routeCode: 'R1',
            origin: 'A',
            destination: 'B',
            stops: [
              BusStop(
                stopId: 's1',
                name: 'Stop 1',
                code: 'ST1',
                latitude: 12.0,
                longitude: 77.0,
                stageNumber: 1,
              ),
            ],
          ),
        ],
        ticketTypes: [
          const TicketType(
            typeId: 'tt1',
            name: 'Single',
            category: 'single',
            defaultFare: 10.0,
            isPass: false,
          ),
        ],
        fetchedAt: now,
        expiresAt: now.add(const Duration(hours: 12)),
      );

      when(() => mockRemote.fetchCatalog()).thenAnswer((_) async => catalog);

      final result = await repository.fetchAndCacheCatalog();

      expect(result.catalogId, equals('cat_test_1'));
      expect(result.routes.first.routeName, equals('Route 1'));

      final cached = await repository.getCachedCatalog();
      expect(cached, isNotNull);
      expect(cached?.catalogId, equals('cat_test_1'));
      expect(cached?.routes.first.stops.first.name, equals('Stop 1'));
    },
  );

  test('isCatalogStale identifies expired catalogs accurately', () async {
    final past = DateTime.now().subtract(const Duration(hours: 2));
    final expiredCatalog = ReferenceCatalog(
      catalogId: 'cat_expired',
      version: 'v1.0.0',
      routes: [],
      ticketTypes: [],
      fetchedAt: past.subtract(const Duration(hours: 24)),
      expiresAt: past,
      isStale: true,
    );

    when(
      () => mockRemote.fetchCatalog(),
    ).thenAnswer((_) async => expiredCatalog);

    await repository.fetchAndCacheCatalog();

    final isStale = await repository.isCatalogStale();
    expect(isStale, isTrue);
  });
}
