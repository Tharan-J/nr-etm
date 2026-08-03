import 'package:flutter_test/flutter_test.dart';
import 'package:nr_etm/core/config/build_info.dart';
import 'package:nr_etm/core/config/env_config.dart';
import 'package:nr_etm/core/config/feature_flags.dart';
import 'package:nr_etm/core/diagnostics/backend_compatibility.dart';

void main() {
  group('Release Engineering Configuration Unit Tests', () {
    test('EnvConfig returns default development environment values', () {
      final config = EnvConfig();
      expect(config.envName, equals('development'));
      expect(config.isDevelopment, isTrue);
      expect(config.isProduction, isFalse);
      expect(config.isStaging, isFalse);
      expect(config.apiBaseUrl, isNotEmpty);
      expect(config.mqttBrokerUrl, isNotEmpty);
      expect(config.apiTimeoutSeconds, greaterThan(0));
      expect(config.toMap(), contains('envName'));
    });

    test('FeatureFlags evaluates compile-time flags', () {
      final flags = FeatureFlags();
      expect(flags.telemetry, isTrue);
      expect(flags.diagnostics, isTrue);
      expect(flags.printer, isTrue);
      expect(flags.backgroundUpload, isTrue);
      expect(flags.experimental, isFalse);
      expect(flags.isEnabled('telemetry'), isTrue);
      expect(flags.isEnabled('non_existent'), isFalse);
      expect(flags.toMap(), contains('experimental'));
    });

    test('BuildInfo provides version and build metadata', () {
      final info = BuildInfo();
      expect(BuildInfo.version, equals('1.0.0'));
      expect(BuildInfo.buildNumber, equals(1));
      expect(info.displayVersion, contains('1.0.0+1'));
      expect(info.versionTag, equals('1.0.0+1'));
      expect(info.toMap(), contains('gitCommit'));
    });

    test('BackendCompatibility validates semver and protocol versions', () {
      // Compatible check
      final resultValid = BackendCompatibility.checkCompatibility(
        backendVersion: '1.0.0',
        backendProtocolVersion: 1,
        backendDataContractVersion: 1,
        backendReferenceSchemaVersion: 1,
      );
      expect(resultValid.isCompatible, isTrue);
      expect(resultValid.issues, isEmpty);

      // Incompatible check - lower major version
      final resultOld = BackendCompatibility.checkCompatibility(
        backendVersion: '0.9.0',
        backendProtocolVersion: 1,
        backendDataContractVersion: 1,
        backendReferenceSchemaVersion: 1,
      );
      expect(resultOld.isCompatible, isFalse);
      expect(resultOld.issues, isNotEmpty);

      // Incompatible check - protocol mismatch
      final resultProto = BackendCompatibility.checkCompatibility(
        backendVersion: '1.0.0',
        backendProtocolVersion: 2,
        backendDataContractVersion: 1,
        backendReferenceSchemaVersion: 1,
      );
      expect(resultProto.isCompatible, isFalse);
      expect(resultProto.issues.first, contains('Protocol version mismatch'));
    });
  });
}
