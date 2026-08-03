# 15 — ETM Release Configuration

> NammaRoute Conductor Electronic Ticket Machine — Release Engineering Handbook

**Document Version**: 1.0.0
**Last Updated**: 2026-08-02
**Status**: Internal Field Validation

---

## Table of Contents

1. [Environment Configuration](#1-environment-configuration)
2. [Versioning Strategy](#2-versioning-strategy)
3. [Signing Process](#3-signing-process)
4. [Release Process](#4-release-process)
5. [Build Commands](#5-build-commands)
6. [Configuration Files](#6-configuration-files)
7. [Crash Reporting](#7-crash-reporting)
8. [Logging Policy](#8-logging-policy)
9. [Security Checklist](#9-security-checklist)
10. [Deployment Checklist](#10-deployment-checklist)
11. [Internal Testing Checklist](#11-internal-testing-checklist)
12. [Rollback Strategy](#12-rollback-strategy)
13. [Known Limitations](#13-known-limitations)

---

## 1. Environment Configuration

The ETM application supports three deployment environments. All configuration is injected at build time via `--dart-define-from-file`, ensuring **zero hardcoded values** in the application binary.

### Environment Files

| Environment | Config File | Flavor | Entry Point |
|---|---|---|---|
| Development | `config/dev.json` | `dev` | `lib/main.dart` |
| Staging | `config/staging.json` | `staging` | `lib/main_staging.dart` |
| Production | `config/prod.json` | `prod` | `lib/main_prod.dart` |

### Configuration Keys

| Key | Description | Dev | Staging | Prod |
|---|---|---|---|---|
| `ENV_NAME` | Environment identifier | `development` | `staging` | `production` |
| `API_BASE_URL` | Backend REST API | dev URL | staging URL | prod URL |
| `MQTT_BROKER_URL` | MQTT broker hostname | dev broker | staging broker | prod broker |
| `MQTT_PORT` | MQTT port | `1883` | `8883` | `8883` |
| `MQTT_USE_TLS` | TLS for MQTT | `false` | `true` | `true` |
| `LOG_LEVEL` | Minimum log level | `debug` | `info` | `warning` |
| `ENABLE_CRASH_REPORTING` | Sentry reporting | `false` | `true` | `true` |
| `API_TIMEOUT_SECONDS` | HTTP timeout | `30` | `15` | `10` |

### Feature Flags

| Flag | Description | Dev | Staging | Prod |
|---|---|---|---|---|
| `ENABLE_TELEMETRY` | GPS telemetry collection | ✓ | ✓ | ✓ |
| `ENABLE_DIAGNOSTICS` | System health monitoring | ✓ | ✓ | ✓ |
| `ENABLE_PRINTER` | Bluetooth printer support | ✓ | ✓ | ✓ |
| `ENABLE_BACKGROUND_UPLOAD` | Background MQTT upload | ✓ | ✓ | ✓ |
| `ENABLE_EXPERIMENTAL` | Pre-release features | ✓ | ✗ | ✗ |

---

## 2. Versioning Strategy

### Semantic Versioning

Format: `MAJOR.MINOR.PATCH+BUILD_NUMBER`

- **MAJOR**: Breaking changes to data contracts or protocol
- **MINOR**: New features, backward-compatible
- **PATCH**: Bug fixes, performance improvements
- **BUILD_NUMBER**: Monotonically increasing integer (Android versionCode)

### Build Metadata

Every build includes:

| Field | Source | Example |
|---|---|---|
| Version | `pubspec.yaml` | `1.0.0` |
| Build Number | `pubspec.yaml` | `1` |
| Git Commit | `git rev-parse --short HEAD` | `a1b2c3d` |
| Build Timestamp | Build time UTC | `2026-08-02T10:30:00Z` |

These values are displayed in:
- Settings → About
- Diagnostics screen
- Startup log
- Crash report tags

### Version Increment Process

```bash
# Before release, update pubspec.yaml version
# Example: 1.0.0+1 → 1.0.1+2
```

---

## 3. Signing Process

### Development Builds

Debug builds use the auto-generated Android debug keystore. No configuration needed.

### Release Builds

1. Generate a release keystore (one-time):
   ```bash
   keytool -genkey -v -keystore release-keystore.jks \
     -keyalg RSA -keysize 2048 -validity 10000 \
     -alias etm-release
   ```

2. Create `android/key.properties` from template:
   ```bash
   cp android/key.properties.template android/key.properties
   ```

3. Fill in actual values in `key.properties`:
   ```properties
   storeFile=path/to/release-keystore.jks
   storePassword=<actual_password>
   keyAlias=etm-release
   keyPassword=<actual_password>
   ```

4. **CRITICAL**: `key.properties` and `.jks` files must **NEVER** be committed to version control.

### CI/CD Signing

For CI, inject signing credentials via environment variables or secure secrets.

---

## 4. Release Process

### Pre-Release

1. Increment version in `pubspec.yaml`
2. Run validation: `./scripts/validate.sh`
3. Ensure git working tree is clean
4. Review changelog

### Build

```bash
# Full release pipeline
./scripts/release.sh --env prod

# With test skip (for hot-fixes only)
./scripts/release.sh --env prod --skip-tests
```

### Post-Build

1. Verify APK size is reasonable (< 30MB)
2. Install on test device: `adb install <path-to-apk>`
3. Run smoke test checklist
4. Tag release: `git tag -a v1.0.0+1 -m "Release 1.0.0+1"`
5. Push tag: `git push origin v1.0.0+1`

---

## 5. Build Commands

### Development

```bash
# Run dev build
flutter run --dart-define-from-file=config/dev.json --flavor dev

# Run with specific device
flutter run --dart-define-from-file=config/dev.json --flavor dev -d <device-id>
```

### Staging

```bash
flutter run --dart-define-from-file=config/staging.json \
  --flavor staging --target lib/main_staging.dart
```

### Production APK

```bash
# Via release script (recommended)
./scripts/release.sh --env prod

# Manual build
flutter build apk --release \
  --flavor prod \
  --target lib/main_prod.dart \
  --dart-define-from-file=config/prod.json \
  --dart-define="GIT_COMMIT=$(git rev-parse --short HEAD)" \
  --dart-define="BUILD_TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
```

---

## 6. Configuration Files

| File | Purpose | Committed |
|---|---|---|
| `config/dev.json` | Development environment config | ✓ |
| `config/staging.json` | Staging environment config | ✓ |
| `config/prod.json` | Production environment config | ✓ |
| `android/key.properties` | Release signing credentials | ✗ NEVER |
| `android/key.properties.template` | Signing template | ✓ |
| `android/app/proguard-rules.pro` | R8/ProGuard rules | ✓ |
| `android/app/src/main/res/xml/network_security_config.xml` | HTTPS enforcement | ✓ |

---

## 7. Crash Reporting

### Configuration

Crash reporting uses Sentry Flutter SDK.

- **DSN**: Provided via `SENTRY_DSN` dart-define (never hardcoded)
- **Enabled**: `ENABLE_CRASH_REPORTING` flag
- **Sampling**: 10% in production, 100% in development

### Event Context

Every crash event includes:

| Tag | Description |
|---|---|
| `environment` | dev/staging/production |
| `app_version` | Semantic version |
| `build_number` | Android versionCode |
| `git_commit` | Source commit hash |
| `session_id` | Current conductor session |
| `device_id` | ETM hardware identifier |
| `duty_state` | Active/inactive duty |
| `trip_state` | Active trip identifier |
| `queue_size` | Outbound queue depth |
| `network_state` | Online/offline/degraded |

### Data Protection

Sensitive data is automatically redacted:
- JWT tokens
- Conductor PINs
- Bearer tokens
- Passwords
- Device secrets

---

## 8. Logging Policy

### Log Levels by Environment

| Level | Dev | Staging | Prod |
|---|---|---|---|
| DEBUG | ✓ | ✗ | ✗ |
| INFO | ✓ | ✓ | ✗ |
| WARNING | ✓ | ✓ | ✓ |
| ERROR | ✓ | ✓ | ✓ |

### Sensitive Data Protection

The following patterns are automatically redacted from all log output:
- JWT tokens (`eyJ...`)
- PIN values
- Bearer tokens
- Passwords
- Secrets

### Log Storage

- **In-memory buffer**: 2000 entries (ring buffer)
- **File logging**: Production only, max 5MB per file, 3 file rotation
- **Export**: Available via diagnostics screen

---

## 9. Security Checklist

- [ ] All API calls use HTTPS (`usesCleartextTraffic="false"`)
- [ ] Certificate validation enabled (network_security_config.xml)
- [ ] Secure storage for credentials (FlutterSecureStorage with EncryptedSharedPreferences)
- [ ] No hardcoded API URLs (all from EnvConfig)
- [ ] No hardcoded secrets in source code
- [ ] No development credentials in production config
- [ ] No debug endpoints accessible in release builds
- [ ] Release manifest reviewed (no debug-only permissions)
- [ ] ProGuard/R8 enabled for release builds
- [ ] key.properties excluded from version control
- [ ] Sensitive data redacted from logs and crash reports
- [ ] MQTT uses TLS in production

---

## 10. Deployment Checklist

### Pre-Deployment

- [ ] Version incremented in `pubspec.yaml`
- [ ] Git working tree is clean
- [ ] All tests passing (`flutter test`)
- [ ] Static analysis passing (`flutter analyze`)
- [ ] Code generation up to date (`dart run build_runner build`)
- [ ] Environment config reviewed (`config/prod.json`)

### Build

- [ ] Release APK built via `./scripts/release.sh --env prod`
- [ ] APK signature verified
- [ ] APK size within expected range

### Installation

- [ ] APK installed on target device (Moto G96)
- [ ] Application launches without crash
- [ ] Splash screen displays correctly
- [ ] Version info visible in diagnostics

### Verification

- [ ] Backend reachable from device
- [ ] MQTT broker reachable
- [ ] Device pairing succeeds
- [ ] Reference catalog downloads
- [ ] Ticket issuance works
- [ ] Diagnostics screen functional

---

## 11. Internal Testing Checklist

### Device Setup

- [ ] Moto G96 running Android 12+
- [ ] GPS enabled
- [ ] Bluetooth enabled (for printer)
- [ ] Mobile data active
- [ ] Battery optimization disabled for ETM

### Functional Verification

- [ ] Device pairing with valid conductor PIN
- [ ] Duty start/stop lifecycle
- [ ] Trip context activation
- [ ] Ticket issuance (single journey, concession, pass)
- [ ] Offline ticket issuance
- [ ] Queue drain on network recovery
- [ ] GPS telemetry streaming
- [ ] Printer connection and ticket print
- [ ] Diagnostics screen accuracy
- [ ] Self-test execution

### Resilience Testing

- [ ] Airplane mode toggle (offline/online transition)
- [ ] Force-stop and relaunch
- [ ] Device reboot recovery (boot receiver)
- [ ] Extended offline operation (30+ minutes)
- [ ] Queue backpressure under load

---

## 12. Rollback Strategy

### APK Rollback

1. Retain previous APK build artifacts
2. Reinstall previous version: `adb install -r <previous-apk>`
3. Application data persists between versions (Drift migration handles schema)

### Backend Incompatibility

If the backend version becomes incompatible:
1. ETM displays a compatibility warning
2. Unsupported operations are prevented
3. Deploy backend update or rollback ETM to compatible version

### Data Recovery

- Local SQLite database persists across reinstalls
- Outbound queue drains automatically when connectivity restores
- Secure storage credentials survive app updates

---

## 13. Known Limitations

### Current Release (v1.0.0)

1. **Feature flags are compile-time only**: No remote configuration support yet. Flag changes require a new build.

2. **Crash reporting requires DSN**: Sentry DSN must be provided via `SENTRY_DSN` dart-define. Without it, crash reporting is a no-op.

3. **Debug signing fallback**: If `key.properties` is missing, release builds fall back to debug signing. This is acceptable for internal field validation but not for public distribution.

4. **Log rotation is per-session**: Log files rotate on app restart, not during runtime.

5. **Battery optimization check**: Currently displayed as "requires native query" in diagnostics. Full implementation requires additional platform channel work.

6. **GPS status check**: Displayed as "requires runtime permission check" in diagnostics. Requires runtime permission flow integration.

7. **Foreground service status**: Requires native query via existing MethodChannel.

---

*This document is the canonical reference for ETM release engineering. Update this document when release processes change.*
