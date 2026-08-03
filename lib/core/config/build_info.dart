/// Application Build Information (Phase 3)
///
/// Provides semantic version, build number, git commit hash, and
/// build timestamp for diagnostics, logging, and About screens.
class BuildInfo {
  // ── Singleton ──────────────────────────────────────────────────────────────
  static final BuildInfo _instance = BuildInfo._();
  factory BuildInfo() => _instance;
  BuildInfo._();

  /// Semantic version from pubspec.yaml (injected by Flutter build system).
  static const String version = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '1.0.0',
  );

  /// Build number / versionCode. Incremented on every release.
  static const int buildNumber = int.fromEnvironment(
    'BUILD_NUMBER',
    defaultValue: 1,
  );

  /// Short git commit hash at build time (injected by release.sh).
  static const String gitCommit = String.fromEnvironment(
    'GIT_COMMIT',
    defaultValue: 'dev',
  );

  /// ISO-8601 build timestamp (injected by release.sh).
  static const String buildTimestamp = String.fromEnvironment(
    'BUILD_TIMESTAMP',
    defaultValue: 'unknown',
  );

  /// Human-readable full version string for UI display.
  String get displayVersion => '$version+$buildNumber ($gitCommit)';

  /// Machine-parseable version for crash reporting tags.
  String get versionTag => '$version+$buildNumber';

  /// Structured map for diagnostics export and crash report context.
  Map<String, String> toMap() => {
        'version': version,
        'buildNumber': buildNumber.toString(),
        'gitCommit': gitCommit,
        'buildTimestamp': buildTimestamp,
        'displayVersion': displayVersion,
      };

  @override
  String toString() => 'BuildInfo($displayVersion built $buildTimestamp)';
}
