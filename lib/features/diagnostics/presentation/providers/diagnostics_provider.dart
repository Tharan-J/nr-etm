import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/mqtt_transport.dart';
import '../../../../core/network/network_observer.dart';
import '../../../../core/platform/native_service_manager.dart';
import '../../../../core/sync/sync_engine.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../reference/presentation/providers/reference_provider.dart';
import '../../domain/models/system_health.dart';
import '../../domain/services/health_engine.dart';

final networkObserverProvider = Provider<NetworkObserver>((ref) {
  return NetworkObserver();
});

final mqttTransportProvider = Provider<MqttTransport>((ref) {
  return MqttTransport();
});

final syncEngineProvider = Provider<SyncEngine>((ref) {
  return SyncEngine(
    database: ref.watch(appDatabaseProvider),
    transportAdapter: ref.watch(mqttTransportProvider),
    networkObserver: ref.watch(networkObserverProvider),
  );
});

final healthEngineProvider = Provider<HealthEngine>((ref) {
  return HealthEngine(
    database: ref.watch(appDatabaseProvider),
    secureStorage: ref.watch(secureStorageProvider),
    networkObserver: ref.watch(networkObserverProvider),
    mqttTransport: ref.watch(mqttTransportProvider),
    syncEngine: ref.watch(syncEngineProvider),
    referenceRepository: ref.watch(referenceRepositoryProvider),
    nativeServiceManager: ref.watch(nativeServiceManagerProvider),
    authRepository: ref.watch(authRepositoryProvider),
  );
});

final systemHealthReportProvider = FutureProvider<SystemHealthReport>((
  ref,
) async {
  return ref.watch(healthEngineProvider).evaluateSystemHealth();
});
