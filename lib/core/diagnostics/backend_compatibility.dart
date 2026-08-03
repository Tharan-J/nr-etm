import '../config/env_config.dart';
import 'app_logger.dart';

/// Backend Compatibility Checker (Phase 8)
///
/// Validates that the connected backend version, protocol version,
/// data contract version, and reference schema version are compatible
/// with this ETM build. Prevents unsupported operation when incompatible.
class BackendCompatibility {
  /// Check if the backend version string is >= minimum required.
  /// Returns a [CompatibilityResult] with details.
  static CompatibilityResult checkCompatibility({
    required String backendVersion,
    required int backendProtocolVersion,
    required int backendDataContractVersion,
    required int backendReferenceSchemaVersion,
  }) {
    final env = EnvConfig();
    final issues = <String>[];

    // Version comparison
    final minParts = env.minBackendVersion.split('.').map(int.parse).toList();
    final backendParts = backendVersion.split('.').map(int.tryParse).toList();

    if (backendParts.any((p) => p == null) || backendParts.length < 3) {
      issues.add(
        'Invalid backend version format: "$backendVersion" '
        '(expected semver like ${env.minBackendVersion})',
      );
    } else {
      final bMajor = backendParts[0]!;
      final bMinor = backendParts[1]!;
      final bPatch = backendParts[2]!;

      if (bMajor < minParts[0] ||
          (bMajor == minParts[0] && bMinor < minParts[1]) ||
          (bMajor == minParts[0] &&
              bMinor == minParts[1] &&
              bPatch < minParts[2])) {
        issues.add(
          'Backend version $backendVersion is below minimum '
          'required ${env.minBackendVersion}',
        );
      }
    }

    // Protocol version check (must match exactly)
    if (backendProtocolVersion != env.protocolVersion) {
      issues.add(
        'Protocol version mismatch: backend=$backendProtocolVersion, '
        'etm=${env.protocolVersion}',
      );
    }

    // Data contract version (must match exactly)
    if (backendDataContractVersion != env.dataContractVersion) {
      issues.add(
        'Data contract version mismatch: backend=$backendDataContractVersion, '
        'etm=${env.dataContractVersion}',
      );
    }

    // Reference schema version (must match exactly)
    if (backendReferenceSchemaVersion != env.referenceSchemaVersion) {
      issues.add(
        'Reference schema version mismatch: '
        'backend=$backendReferenceSchemaVersion, '
        'etm=${env.referenceSchemaVersion}',
      );
    }

    final isCompatible = issues.isEmpty;

    if (!isCompatible) {
      for (final issue in issues) {
        AppLogger.warning('BackendCompatibility: $issue');
      }
    } else {
      AppLogger.info(
        'BackendCompatibility: backend v$backendVersion is compatible '
        '(protocol=${env.protocolVersion}, '
        'contract=${env.dataContractVersion}, '
        'schema=${env.referenceSchemaVersion})',
      );
    }

    return CompatibilityResult(
      isCompatible: isCompatible,
      backendVersion: backendVersion,
      minimumVersion: env.minBackendVersion,
      issues: issues,
    );
  }
}

/// Result of a backend compatibility check.
class CompatibilityResult {
  final bool isCompatible;
  final String backendVersion;
  final String minimumVersion;
  final List<String> issues;

  const CompatibilityResult({
    required this.isCompatible,
    required this.backendVersion,
    required this.minimumVersion,
    required this.issues,
  });

  /// User-facing message for UI display when incompatible.
  String get userMessage {
    if (isCompatible) return 'Backend is compatible.';
    return 'This ETM version is not compatible with the current backend '
        '(v$backendVersion). Minimum required: v$minimumVersion. '
        'Please update the application.';
  }
}
