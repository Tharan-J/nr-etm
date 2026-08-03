import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/build_info.dart';
import '../core/config/env_config.dart';
import '../core/config/feature_flags.dart';
import '../core/diagnostics/app_logger.dart';
import '../core/diagnostics/crash_reporter.dart';
import 'app.dart';

/// Application Bootstrap (Release-Engineered)
///
/// Initialization sequence:
///   1. Flutter binding
///   2. Environment config validation
///   3. Production logging
///   4. Crash reporting
///   5. Startup telemetry log
///   6. Run app inside error boundary zone
Future<void> bootstrap({required String environment}) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Phase 1: Log environment config
  final env = EnvConfig();
  final flags = FeatureFlags();

  // Phase 5: Production logging
  await AppLogger.init(environment: environment);

  // Phase 6: Crash reporting
  await CrashReporter.init();

  // Phase 3: Startup version telemetry
  AppLogger.info(
    '══════════════════════════════════════════════════════════',
  );
  AppLogger.info(
    'NammaRoute ETM Starting | ${BuildInfo().displayVersion}',
  );
  AppLogger.info('Environment: ${env.envName}');
  AppLogger.info('API: ${env.apiBaseUrl}');
  AppLogger.info('MQTT: ${env.mqttBrokerUrl}:${env.mqttPort} (tls=${env.mqttUseTls})');
  AppLogger.info('Log Level: ${env.logLevel}');
  AppLogger.info('Crash Reporting: ${env.enableCrashReporting}');
  AppLogger.info('Features: ${flags.toMap()}');
  AppLogger.info(
    '══════════════════════════════════════════════════════════',
  );

  // Flutter framework error handler
  FlutterError.onError = (FlutterErrorDetails details) {
    AppLogger.error(
      'Unhandled Flutter framework error',
      details.exception,
      details.stack,
    );
  };

  // Async error boundary
  runZonedGuarded(
    () {
      runApp(const ProviderScope(child: EtmApp()));
    },
    (Object error, StackTrace stackTrace) {
      AppLogger.error('Unhandled async error in zone', error, stackTrace);
    },
  );
}
