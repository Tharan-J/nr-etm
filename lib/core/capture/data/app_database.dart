import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'dao/durable_capture_dao.dart';
import 'tables/metadata_table.dart';
import 'tables/outbound_queue_table.dart';
import 'tables/reference_catalog_table.dart';
import 'tables/session_state_table.dart';
import 'tables/telemetry_table.dart';
import 'tables/ticket_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    MetadataTable,
    TicketTable,
    TelemetryTable,
    OutboundQueueTable,
    SessionStateTable,
    ReferenceCatalogTable,
  ],
  daos: [DurableCaptureDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  AppDatabase.forTesting(DatabaseConnection super.connection);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.createTable(referenceCatalogTable);
        }
      },
      beforeOpen: (details) async {
        // Enforce SQLite Foreign Key constraints for relational integrity
        await customStatement('PRAGMA foreign_keys = ON;');
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'nr_etm_durable_store.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
