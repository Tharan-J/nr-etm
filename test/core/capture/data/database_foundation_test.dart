import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nr_etm/core/capture/data/app_database.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'Database opens successfully and metadata table operations succeed',
    () async {
      final now = DateTime.now();
      await database
          .into(database.metadataTable)
          .insert(
            MetadataTableCompanion.insert(
              key: 'schema_version',
              value: '1.0.0',
              updatedAt: now,
            ),
          );

      final entries = await database.select(database.metadataTable).get();
      expect(entries.length, equals(1));
      expect(entries.first.key, equals('schema_version'));
      expect(entries.first.value, equals('1.0.0'));
    },
  );

  test('Foreign key pragma is enabled on database initialization', () async {
    final result = await database
        .customSelect('PRAGMA foreign_keys;')
        .getSingle();
    expect(result.data['foreign_keys'], equals(1));
  });
}
