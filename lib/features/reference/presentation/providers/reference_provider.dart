import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/reference_remote_datasource.dart';
import '../../data/repositories/reference_repository_impl.dart';
import '../../domain/models/reference_catalog.dart';

final referenceRemoteDataSourceProvider = Provider<ReferenceRemoteDataSource>((
  ref,
) {
  return ReferenceRemoteDataSourceImpl();
});

final referenceRepositoryProvider = Provider<ReferenceRepository>((ref) {
  return ReferenceRepositoryImpl(
    remoteDataSource: ref.watch(referenceRemoteDataSourceProvider),
    database: ref.watch(appDatabaseProvider),
  );
});

class ReferenceCatalogNotifier
    extends StateNotifier<AsyncValue<ReferenceCatalog>> {
  final ReferenceRepository _repository;

  ReferenceCatalogNotifier(this._repository)
    : super(const AsyncValue.loading()) {
    loadCatalog();
  }

  Future<void> loadCatalog() async {
    state = const AsyncValue.loading();
    try {
      var catalog = await _repository.getCachedCatalog();
      if (catalog == null || catalog.isStale) {
        catalog = await _repository.fetchAndCacheCatalog();
      }
      state = AsyncValue.data(catalog);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> forceRefreshCatalog() async {
    state = const AsyncValue.loading();
    try {
      final catalog = await _repository.fetchAndCacheCatalog();
      state = AsyncValue.data(catalog);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final referenceCatalogNotifierProvider =
    StateNotifierProvider<
      ReferenceCatalogNotifier,
      AsyncValue<ReferenceCatalog>
    >((ref) {
      return ReferenceCatalogNotifier(ref.watch(referenceRepositoryProvider));
    });
