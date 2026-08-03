/// Feature Flags System (Phase 9)
///
/// Environment-driven feature flags sourced from --dart-define-from-file.
/// Supports runtime querying for conditional feature enablement.
class FeatureFlags {
  // ── Singleton ──────────────────────────────────────────────────────────────
  static final FeatureFlags _instance = FeatureFlags._();
  factory FeatureFlags() => _instance;
  FeatureFlags._();

  // ── Feature Gates ──────────────────────────────────────────────────────────

  /// GPS telemetry collection and upload.
  bool get telemetry =>
      const bool.fromEnvironment('ENABLE_TELEMETRY', defaultValue: true);

  /// System diagnostics and health monitoring.
  bool get diagnostics =>
      const bool.fromEnvironment('ENABLE_DIAGNOSTICS', defaultValue: true);

  /// Bluetooth thermal printer support.
  bool get printer =>
      const bool.fromEnvironment('ENABLE_PRINTER', defaultValue: true);

  /// Background queue upload via MQTT.
  bool get backgroundUpload =>
      const bool.fromEnvironment('ENABLE_BACKGROUND_UPLOAD', defaultValue: true);

  /// Experimental / pre-release features.
  bool get experimental =>
      const bool.fromEnvironment('ENABLE_EXPERIMENTAL', defaultValue: false);

  // ── Querying ───────────────────────────────────────────────────────────────

  /// Returns true if the named feature is enabled.
  bool isEnabled(String feature) {
    switch (feature) {
      case 'telemetry':
        return telemetry;
      case 'diagnostics':
        return diagnostics;
      case 'printer':
        return printer;
      case 'backgroundUpload':
        return backgroundUpload;
      case 'experimental':
        return experimental;
      default:
        return false;
    }
  }

  /// All flags as a diagnostic map.
  Map<String, bool> toMap() => {
        'telemetry': telemetry,
        'diagnostics': diagnostics,
        'printer': printer,
        'backgroundUpload': backgroundUpload,
        'experimental': experimental,
      };
}
