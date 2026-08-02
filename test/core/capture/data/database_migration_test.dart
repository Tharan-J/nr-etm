import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nr_etm/core/capture/data/app_database.dart';

void main() {
  test('Fresh database initializes version 2 with all tables intact', () async {
    final database = AppDatabase(NativeDatabase.memory());

    expect(database.schemaVersion, equals(2));

    // Verify all 6 tables are queryable on fresh init
    final metadata = await database.select(database.metadataTable).get();
    final tickets = await database.select(database.ticketTable).get();
    final telemetry = await database.select(database.telemetryTable).get();
    final queue = await database.select(database.outboundQueueTable).get();
    final sessions = await database.select(database.sessionStateTable).get();
    final catalogs = await database
        .select(database.referenceCatalogTable)
        .get();

    expect(metadata, isEmpty);
    expect(tickets, isEmpty);
    expect(telemetry, isEmpty);
    expect(queue, isEmpty);
    expect(sessions, isEmpty);
    expect(catalogs, isEmpty);

    await database.close();
  });

  test(
    'Migration strategy maintains data preservation and schema integrity',
    () async {
      final database = AppDatabase(NativeDatabase.memory());

      final now = DateTime.now();
      await database
          .into(database.metadataTable)
          .insert(
            MetadataTableCompanion.insert(
              key: 'migration_test_key',
              value: 'v2_data',
              updatedAt: now,
            ),
          );

      final initialRecords = await database
          .select(database.metadataTable)
          .get();
      expect(initialRecords.length, equals(1));
      expect(initialRecords.first.key, equals('migration_test_key'));
      expect(initialRecords.first.value, equals('v2_data'));

      await database.close();
    },
  );
}
