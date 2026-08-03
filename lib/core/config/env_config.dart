/// Environment Configuration System (Phase 1)
///
/// All values are sourced from --dart-define-from-file at build time.
/// Zero hardcoded environment values. Each field maps to a JSON key
/// in config/{dev,staging,prod}.json.
class EnvConfig {
  // ── Singleton ──────────────────────────────────────────────────────────────
  static final EnvConfig _instance = EnvConfig._();
  factory EnvConfig() => _instance;
  EnvConfig._();

  // ── Environment Identity ───────────────────────────────────────────────────
  String get envName =>
      const String.fromEnvironment('ENV_NAME', defaultValue: 'development');

  bool get isProduction => envName == 'production';
  bool get isStaging => envName == 'staging';
  bool get isDevelopment => envName == 'development';

  // ── Backend API ────────────────────────────────────────────────────────────
  String get apiBaseUrl => const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'https://dev.api.nammaroute.com',
      );

  int get apiTimeoutSeconds =>
      const int.fromEnvironment('API_TIMEOUT_SECONDS', defaultValue: 30);

  Duration get apiTimeout => Duration(seconds: apiTimeoutSeconds);

  // ── MQTT Broker ────────────────────────────────────────────────────────────
  String get mqttBrokerUrl => const String.fromEnvironment(
        'MQTT_BROKER_URL',
        defaultValue: 'dev.mqtt.nammaroute.com',
      );

  int get mqttPort =>
      const int.fromEnvironment('MQTT_PORT', defaultValue: 1883);

  bool get mqttUseTls =>
      const bool.fromEnvironment('MQTT_USE_TLS', defaultValue: false);

  // ── Logging ────────────────────────────────────────────────────────────────
  String get logLevel =>
      const String.fromEnvironment('LOG_LEVEL', defaultValue: 'debug');

  // ── Crash Reporting ────────────────────────────────────────────────────────
  bool get enableCrashReporting =>
      const bool.fromEnvironment('ENABLE_CRASH_REPORTING', defaultValue: false);

  // ── Synchronization ────────────────────────────────────────────────────────
  int get syncFlushIntervalSeconds => const int.fromEnvironment(
        'SYNC_FLUSH_INTERVAL_SECONDS',
        defaultValue: 5,
      );

  int get syncMaxBatchSize =>
      const int.fromEnvironment('SYNC_MAX_BATCH_SIZE', defaultValue: 50);

  int get syncMaxRetryCount =>
      const int.fromEnvironment('SYNC_MAX_RETRY_COUNT', defaultValue: 10);

  // ── Telemetry ──────────────────────────────────────────────────────────────
  int get telemetrySamplingIntervalSeconds => const int.fromEnvironment(
        'TELEMETRY_SAMPLING_INTERVAL_SECONDS',
        defaultValue: 5,
      );

  int get telemetryUploadIntervalSeconds => const int.fromEnvironment(
        'TELEMETRY_UPLOAD_INTERVAL_SECONDS',
        defaultValue: 30,
      );

  // ── Backend Compatibility (Phase 8) ────────────────────────────────────────
  String get minBackendVersion =>
      const String.fromEnvironment('MIN_BACKEND_VERSION', defaultValue: '1.0.0');

  int get protocolVersion =>
      const int.fromEnvironment('PROTOCOL_VERSION', defaultValue: 1);

  int get dataContractVersion =>
      const int.fromEnvironment('DATA_CONTRACT_VERSION', defaultValue: 1);

  int get referenceSchemaVersion =>
      const int.fromEnvironment('REFERENCE_SCHEMA_VERSION', defaultValue: 1);

  // ── Diagnostics Summary ────────────────────────────────────────────────────
  Map<String, String> toMap() => {
        'envName': envName,
        'apiBaseUrl': apiBaseUrl,
        'apiTimeoutSeconds': apiTimeoutSeconds.toString(),
        'mqttBrokerUrl': mqttBrokerUrl,
        'mqttPort': mqttPort.toString(),
        'mqttUseTls': mqttUseTls.toString(),
        'logLevel': logLevel,
        'enableCrashReporting': enableCrashReporting.toString(),
        'syncFlushIntervalSeconds': syncFlushIntervalSeconds.toString(),
        'syncMaxBatchSize': syncMaxBatchSize.toString(),
        'syncMaxRetryCount': syncMaxRetryCount.toString(),
        'telemetrySamplingIntervalSeconds':
            telemetrySamplingIntervalSeconds.toString(),
        'telemetryUploadIntervalSeconds':
            telemetryUploadIntervalSeconds.toString(),
        'minBackendVersion': minBackendVersion,
        'protocolVersion': protocolVersion.toString(),
        'dataContractVersion': dataContractVersion.toString(),
        'referenceSchemaVersion': referenceSchemaVersion.toString(),
      };

  @override
  String toString() =>
      'EnvConfig($envName | api=$apiBaseUrl | mqtt=$mqttBrokerUrl:$mqttPort)';
}
