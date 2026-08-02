import 'package:drift/drift.dart';

/// Local persistence table for master reference catalog (routes, stops, fare stages, ticket types)
@DataClassName('ReferenceCatalogData')
class ReferenceCatalogTable extends Table {
  TextColumn get catalogId => text().withLength(min: 1, max: 100)();
  TextColumn get version => text().withLength(min: 1, max: 50)();
  TextColumn get payloadJson => text()();
  DateTimeColumn get fetchedAt => dateTime()();
  DateTimeColumn get expiresAt => dateTime()();
  BoolColumn get isStale => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {catalogId};
}
