import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../config/build_info.dart';
import '../config/env_config.dart';

/// Crash Reporting Configuration (Phase 6)
///
/// Configures Sentry with environment, version, device context,
/// and operational state tags. Sensitive data is stripped before upload.
class CrashReporter {
  static bool _initialized = false;

  /// Initialize Sentry crash reporting.
  /// No-op if crash reporting is disabled in the environment config.
  static Future<void> init() async {
    if (_initialized) return;
    if (!EnvConfig().enableCrashReporting) {
      _initialized = true;
      return;
    }

    await SentryFlutter.init((options) {
      // DSN should be set via dart-define, not hardcoded
      options.dsn = const String.fromEnvironment(
        'SENTRY_DSN',
        defaultValue: '',
      );

      // Environment and release tagging
      options.environment = EnvConfig().envName;
      options.release = '${BuildInfo.version}+${BuildInfo.buildNumber}';
      options.dist = BuildInfo.buildNumber.toString();

      // Performance / sampling
      options.tracesSampleRate = EnvConfig().isProduction ? 0.1 : 1.0;
      options.sampleRate = 1.0;

      // Strip sensitive data
      options.beforeSend = _scrubEvent;

      // Debug mode for non-production
      options.debug = kDebugMode;

      // Attach stack traces to all events
      options.attachStacktrace = true;
    });

    // Set global tags for all future events
    Sentry.configureScope((scope) {
      scope.setTag('environment', EnvConfig().envName);
      scope.setTag('app_version', BuildInfo.version);
      scope.setTag('build_number', BuildInfo.buildNumber.toString());
      scope.setTag('git_commit', BuildInfo.gitCommit);
      scope.setTag('protocol_version', EnvConfig().protocolVersion.toString());
      scope.setTag(
        'data_contract_version',
        EnvConfig().dataContractVersion.toString(),
      );

      // Device info
      scope.setTag('platform', Platform.operatingSystem);
      scope.setTag('os_version', Platform.operatingSystemVersion);
    });

    _initialized = true;
  }

  /// Update operational context on session state changes.
  /// Called when duty/trip/auth state changes.
  static void setOperationalContext({
    String? sessionId,
    String? deviceId,
    String? conductorId,
    String? dutyState,
    String? tripState,
    int? queueSize,
    String? networkState,
    String? referenceCatalogVersion,
  }) {
    if (!_initialized || !EnvConfig().enableCrashReporting) return;

    Sentry.configureScope((scope) {
      if (sessionId != null) scope.setTag('session_id', sessionId);
      if (deviceId != null) scope.setTag('device_id', deviceId);
      if (conductorId != null) scope.setTag('conductor_id', conductorId);
      if (dutyState != null) scope.setTag('duty_state', dutyState);
      if (tripState != null) scope.setTag('trip_state', tripState);
      if (queueSize != null) {
        scope.setTag('queue_size', queueSize.toString());
      }
      if (networkState != null) scope.setTag('network_state', networkState);
      if (referenceCatalogVersion != null) {
        scope.setTag('reference_catalog_version', referenceCatalogVersion);
      }
    });
  }

  /// Scrub sensitive data from Sentry events before upload.
  static SentryEvent? _scrubEvent(SentryEvent event, Hint hint) {
    // Strip PII from breadcrumb messages
    final breadcrumbs = event.breadcrumbs;
    if (breadcrumbs != null) {
      for (final b in breadcrumbs) {
        final msg = b.message;
        if (msg != null) {
          b.message = _redact(msg);
        }
      }
    }

    return event;
  }

  static final RegExp _sensitivePattern = RegExp(
    r'(eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,})'
    r'|(\bpin[:\s="]+\d{4,6}\b)'
    r'|(bearer\s+[A-Za-z0-9._~+/=-]+)'
    r'|(password[:\s="]+\S+)'
    r'|(token[:\s="]+[A-Za-z0-9._~+/=-]{8,})'
    r'|(secret[:\s="]+\S+)',
    caseSensitive: false,
  );

  static String _redact(String input) {
    return input.replaceAll(_sensitivePattern, '[REDACTED]');
  }
}
