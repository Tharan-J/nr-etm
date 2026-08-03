import 'dart:io';

import 'package:flutter/services.dart';

import '../capture/data/app_database.dart';
import '../config/build_info.dart';
import '../config/env_config.dart';
import '../config/feature_flags.dart';
import '../network/mqtt_transport.dart';
import '../network/network_observer.dart';
import '../sync/sync_engine.dart';
import '../../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../../features/printer/domain/services/printer_manager.dart';
import '../../../features/reference/data/repositories/reference_repository_impl.dart';
import '../platform/native_service_manager.dart';
import 'app_logger.dart';

/// Expanded Diagnostics Service (Phase 7)
///
/// Collects comprehensive system state for field technician diagnostics,
/// copy-to-clipboard, and log export.
class DiagnosticsService {
  final AppDatabase database;
  final NetworkObserver networkObserver;
  final MqttTransport mqttTransport;
  final SyncEngine syncEngine;
  final AuthRepository authRepository;
  final ReferenceRepository referenceRepository;
  final NativeServiceManager? nativeServiceManager;
  final PrinterManager? printerManager;

  DiagnosticsService({
    required this.database,
    required this.networkObserver,
    required this.mqttTransport,
    required this.syncEngine,
    required this.authRepository,
    required this.referenceRepository,
    this.nativeServiceManager,
    this.printerManager,
  });

  /// Collect all diagnostic entries as an ordered map.
  Future<Map<String, String>> collectDiagnostics() async {
    final diag = <String, String>{};
    final env = EnvConfig();
    final flags = FeatureFlags();

    // ── Application Version ────────────────────────────────────────────────
    diag['Application Version'] = BuildInfo.version;
    diag['Build Number'] = BuildInfo.buildNumber.toString();
    diag['Git Commit'] = BuildInfo.gitCommit;
    diag['Build Timestamp'] = BuildInfo.buildTimestamp;

    // ── Environment ────────────────────────────────────────────────────────
    diag['Environment'] = env.envName;
    diag['Backend URL'] = env.apiBaseUrl;
    diag['MQTT Broker'] = '${env.mqttBrokerUrl}:${env.mqttPort}';
    diag['MQTT TLS'] = env.mqttUseTls.toString();

    // ── Database ───────────────────────────────────────────────────────────
    try {
      diag['Database Version'] = database.schemaVersion.toString();
    } catch (_) {
      diag['Database Version'] = 'unavailable';
    }

    // ── Sync Queue ─────────────────────────────────────────────────────────
    try {
      final queueDepth = await syncEngine.getPendingQueueCount();
      diag['Queue Depth'] = queueDepth.toString();
    } catch (_) {
      diag['Queue Depth'] = 'unavailable';
    }

    // ── Last Sync ──────────────────────────────────────────────────────────
    try {
      final session = await authRepository.getActiveSession();
      diag['Last Synchronization'] = session.lastSyncAt.toIso8601String();
      diag['JWT Status'] = session.isAuthenticated ? 'valid' : 'expired/missing';
      diag['Conductor ID'] = session.conductorId ?? 'unpaired';
      diag['Device ID'] = session.deviceId;
    } catch (_) {
      diag['Last Synchronization'] = 'unavailable';
      diag['JWT Status'] = 'unavailable';
    }

    // ── Reference Catalog ──────────────────────────────────────────────────
    try {
      final catalog = await referenceRepository.getCachedCatalog();
      diag['Reference Catalog Version'] =
          catalog != null ? catalog.version : 'not loaded';
    } catch (_) {
      diag['Reference Catalog Version'] = 'unavailable';
    }

    // ── Device & Platform ──────────────────────────────────────────────────
    diag['Device Identifier'] = Platform.localHostname;
    diag['Android Version'] = Platform.operatingSystemVersion;
    diag['Platform'] = Platform.operatingSystem;
    diag['Dart Version'] = Platform.version;

    // ── Network ────────────────────────────────────────────────────────────
    diag['Network Status'] = networkObserver.status.name;
    diag['MQTT Connected'] = mqttTransport.isConnected.toString();

    // ── Services ───────────────────────────────────────────────────────────
    diag['Foreground Service Status'] = 'requires native query';

    // ── Printer ────────────────────────────────────────────────────────────
    if (flags.printer) {
      final pStatus = printerManager?.status;
      diag['Printer Status'] = pStatus?.isConnected == true
          ? 'connected (${pStatus!.batteryPct}%)'
          : 'disconnected';
    } else {
      diag['Printer Status'] = 'disabled by feature flag';
    }

    // ── GPS ────────────────────────────────────────────────────────────────
    diag['GPS Status'] = 'requires runtime permission check';

    // ── Battery Optimization ───────────────────────────────────────────────
    diag['Battery Optimization Status'] = 'requires native query';

    // ── Feature Flags ──────────────────────────────────────────────────────
    flags.toMap().forEach((key, value) {
      diag['Feature: $key'] = value.toString();
    });

    // ── Log Buffer ─────────────────────────────────────────────────────────
    diag['Log Buffer Entries'] = AppLogger.bufferCount.toString();

    return diag;
  }

  /// Format diagnostics as a copyable plaintext report.
  Future<String> formatDiagnosticsReport() async {
    final diag = await collectDiagnostics();
    final buffer = StringBuffer();

    buffer.writeln('═══ NammaRoute ETM Diagnostics Report ═══');
    buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
    buffer.writeln('');

    for (final entry in diag.entries) {
      buffer.writeln('${entry.key}: ${entry.value}');
    }

    buffer.writeln('');
    buffer.writeln('═══ End of Report ═══');

    return buffer.toString();
  }

  /// Copy diagnostics to system clipboard.
  Future<void> copyDiagnosticsToClipboard() async {
    final report = await formatDiagnosticsReport();
    await Clipboard.setData(ClipboardData(text: report));
  }

  /// Export diagnostics + recent logs as a combined report string.
  Future<String> exportFullDiagnostics() async {
    final diagReport = await formatDiagnosticsReport();
    final logs = AppLogger.exportLogs();

    return '$diagReport\n\n═══ Recent Logs ═══\n$logs\n═══ End of Logs ═══';
  }
}
