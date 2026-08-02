import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../../core/capture/data/app_database.dart';
import '../../domain/models/reference_catalog.dart';
import '../datasources/reference_remote_datasource.dart';

abstract class ReferenceRepository {
  Future<ReferenceCatalog> fetchAndCacheCatalog();
  Future<ReferenceCatalog?> getCachedCatalog();
  Future<bool> isCatalogStale();
}

class ReferenceRepositoryImpl implements ReferenceRepository {
  final ReferenceRemoteDataSource remoteDataSource;
  final AppDatabase database;

  ReferenceRepositoryImpl({
    required this.remoteDataSource,
    required this.database,
  });

  @override
  Future<ReferenceCatalog> fetchAndCacheCatalog() async {
    final catalog = await remoteDataSource.fetchCatalog();
    final jsonStr = jsonEncode(catalog.toJson());

    await database
        .into(database.referenceCatalogTable)
        .insertOnConflictUpdate(
          ReferenceCatalogTableCompanion.insert(
            catalogId: catalog.catalogId,
            version: catalog.version,
            payloadJson: jsonStr,
            fetchedAt: catalog.fetchedAt,
            expiresAt: catalog.expiresAt,
            isStale: Value(catalog.isStale),
          ),
        );

    return catalog;
  }

  @override
  Future<ReferenceCatalog?> getCachedCatalog() async {
    final records = await database.select(database.referenceCatalogTable).get();
    if (records.isEmpty) {
      return null;
    }

    final first = records.first;
    final map = jsonDecode(first.payloadJson) as Map<String, dynamic>;
    final catalog = ReferenceCatalog.fromJson(map);

    // Check if catalog has expired locally
    final isStale = DateTime.now().isAfter(first.expiresAt);
    return ReferenceCatalog(
      catalogId: catalog.catalogId,
      version: catalog.version,
      routes: catalog.routes,
      ticketTypes: catalog.ticketTypes,
      fetchedAt: catalog.fetchedAt,
      expiresAt: catalog.expiresAt,
      isStale: isStale,
    );
  }

  @override
  Future<bool> isCatalogStale() async {
    final catalog = await getCachedCatalog();
    if (catalog == null) return true;
    return catalog.isStale || catalog.isExpired;
  }
}
