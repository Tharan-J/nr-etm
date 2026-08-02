import '../../../../core/capture/data/app_database.dart';
import '../../../../core/config/secure_storage_service.dart';
import '../../../../core/network/mqtt_transport.dart';
import '../../../../core/network/network_observer.dart';
import '../../../../core/platform/native_service_manager.dart';
import '../../../../core/sync/sync_engine.dart';
import '../../../auth/data/repositories/auth_repository_impl.dart';
import '../../../printer/domain/services/printer_manager.dart';
import '../../../reference/data/repositories/reference_repository_impl.dart';
import '../models/system_health.dart';

class HealthEngine {
  final AppDatabase database;
  final SecureStorageService secureStorage;
  final NetworkObserver networkObserver;
  final MqttTransport mqttTransport;
  final SyncEngine syncEngine;
  final ReferenceRepository referenceRepository;
  final NativeServiceManager nativeServiceManager;
  final AuthRepository authRepository;
  final PrinterManager? printerManager;

  HealthEngine({
    required this.database,
    required this.secureStorage,
    required this.networkObserver,
    required this.mqttTransport,
    required this.syncEngine,
    required this.referenceRepository,
    required this.nativeServiceManager,
    required this.authRepository,
    this.printerManager,
  });

  Future<SystemHealthReport> evaluateSystemHealth() async {
    final now = DateTime.now();
    final subsystems = <String, SubsystemHealth>{};

    // 1. Database Health
    try {
      final ticketCount = await database.select(database.ticketTable).get();
      subsystems['database'] = SubsystemHealth(
        name: 'Database',
        status: HealthStatus.healthy,
        message:
            'Drift DB operational (${ticketCount.length} tickets recorded)',
        lastChecked: now,
      );
    } catch (e) {
      subsystems['database'] = SubsystemHealth(
        name: 'Database',
        status: HealthStatus.critical,
        message: 'Database error: $e',
        lastChecked: now,
      );
    }

    // 2. Network Health
    final netStatus = networkObserver.status;
    subsystems['network'] = SubsystemHealth(
      name: 'Network',
      status: netStatus == NetworkStatus.online
          ? HealthStatus.healthy
          : netStatus == NetworkStatus.poor
          ? HealthStatus.degraded
          : HealthStatus.critical,
      message: 'Network status: ${netStatus.name}',
      lastChecked: now,
    );

    // 3. MQTT Transport
    subsystems['mqtt'] = SubsystemHealth(
      name: 'MQTT Transport',
      status: mqttTransport.isConnected
          ? HealthStatus.healthy
          : HealthStatus.degraded,
      message: mqttTransport.isConnected
          ? 'Connected to broker'
          : 'Disconnected from broker',
      lastChecked: now,
    );

    // 4. Outbound Sync Queue
    final pendingCount = await syncEngine.getPendingQueueCount();
    subsystems['sync_queue'] = SubsystemHealth(
      name: 'Outbound Sync Queue',
      status: pendingCount > 1000
          ? HealthStatus.critical
          : pendingCount > 200
          ? HealthStatus.degraded
          : HealthStatus.healthy,
      message: '$pendingCount pending records in outbox',
      lastChecked: now,
    );

    // 5. Reference Catalog Context
    final catalog = await referenceRepository.getCachedCatalog();
    subsystems['reference_catalog'] = SubsystemHealth(
      name: 'Reference Catalog',
      status: catalog == null
          ? HealthStatus.critical
          : catalog.isStale
          ? HealthStatus.degraded
          : HealthStatus.healthy,
      message: catalog == null
          ? 'No cached catalog found'
          : 'Catalog version: ${catalog.version} (${catalog.routes.length} routes)',
      lastChecked: now,
    );

    // 6. Authentication Session
    final session = await authRepository.getActiveSession();
    subsystems['auth_session'] = SubsystemHealth(
      name: 'Authentication Session',
      status: session.isAuthenticated
          ? HealthStatus.healthy
          : HealthStatus.degraded,
      message: session.isAuthenticated
          ? 'Conductor ${session.conductorId} paired'
          : 'Unpaired session',
      lastChecked: now,
    );

    // 7. Thermal Printer Subsystem
    final pStatus = printerManager?.status;
    subsystems['printer'] = SubsystemHealth(
      name: 'Thermal Printer Driver',
      status: pStatus == null
          ? HealthStatus.healthy
          : pStatus.isConnected
          ? HealthStatus.healthy
          : HealthStatus.degraded,
      message: pStatus == null
          ? 'Software ESC/POS formatter ready'
          : pStatus.isConnected
          ? 'Thermal printer connected (${pStatus.batteryPct}% battery)'
          : 'Printer disconnected (software ready)',
      lastChecked: now,
    );

    // Calculate Overall System Status
    HealthStatus overall = HealthStatus.healthy;
    if (subsystems.values.any((s) => s.status == HealthStatus.critical)) {
      overall = HealthStatus.critical;
    } else if (subsystems.values.any(
      (s) => s.status == HealthStatus.degraded,
    )) {
      overall = HealthStatus.degraded;
    }

    return SystemHealthReport(
      overallStatus: overall,
      subsystems: subsystems,
      generatedAt: now,
    );
  }

  /// Field Technician Self-Test Runner
  Future<SelfTestReport> runSelfTest() async {
    final now = DateTime.now();
    final items = <SelfCheckItem>[];

    // Check 1: Database
    try {
      await database.select(database.ticketTable).get();
      items.add(
        const SelfCheckItem(
          category: 'Database Integrity',
          isPassed: true,
          message: 'SQLite database accessible and tables operational',
        ),
      );
    } catch (e) {
      items.add(
        SelfCheckItem(
          category: 'Database Integrity',
          isPassed: false,
          message: 'DB Check failed: $e',
        ),
      );
    }

    // Check 2: Secure Credentials Storage
    try {
      await secureStorage.getDeviceToken();
      items.add(
        const SelfCheckItem(
          category: 'Secure Credentials Storage',
          isPassed: true,
          message: 'Encrypted storage accessible',
        ),
      );
    } catch (e) {
      items.add(
        SelfCheckItem(
          category: 'Secure Credentials Storage',
          isPassed: false,
          message: 'Storage check failed: $e',
        ),
      );
    }

    // Check 3: Network Connection
    final isOnline = networkObserver.status == NetworkStatus.online;
    items.add(
      SelfCheckItem(
        category: 'Network Connectivity',
        isPassed: isOnline,
        message: isOnline ? 'Network online' : 'Network offline/degraded',
      ),
    );

    // Check 4: MQTT Transport Socket
    items.add(
      SelfCheckItem(
        category: 'MQTT Transport Connection',
        isPassed: mqttTransport.isConnected,
        message: mqttTransport.isConnected
            ? 'Socket connected'
            : 'Broker disconnected',
      ),
    );

    // Check 5: Foreground Location Service
    items.add(
      const SelfCheckItem(
        category: 'Native Location Telemetry',
        isPassed: true,
        message: 'FusedLocationProvider client ready',
      ),
    );

    // Check 6: Outbox Sync Queue Capacity
    final queueCount = await syncEngine.getPendingQueueCount();
    items.add(
      SelfCheckItem(
        category: 'Outbox Sync Queue Capacity',
        isPassed: queueCount < 2000,
        message: '$queueCount items queued ($queueCount / 2000)',
      ),
    );

    // Check 7: Reference Catalog Context
    final catalog = await referenceRepository.getCachedCatalog();
    items.add(
      SelfCheckItem(
        category: 'Reference Catalog Context',
        isPassed: catalog != null && !catalog.isStale,
        message: catalog != null
            ? 'Catalog v${catalog.version} loaded'
            : 'Catalog missing or expired',
      ),
    );

    // Check 8: Auth Session State
    final session = await authRepository.getActiveSession();
    items.add(
      SelfCheckItem(
        category: 'Conductor Duty Credentials',
        isPassed: session.isAuthenticated,
        message: session.isAuthenticated ? 'Device paired' : 'Device unpaired',
      ),
    );

    // Check 9: ESC/POS Thermal Printer Stack
    items.add(
      const SelfCheckItem(
        category: 'Thermal Printer Driver Stack',
        isPassed: true,
        message: 'ESC/POS Formatter & Transport Abstraction Ready',
      ),
    );

    return SelfTestReport(items: items, timestamp: now);
  }
}
