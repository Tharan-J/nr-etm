#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# NammaRoute ETM — Release Build Pipeline (Phase 12)
# ═══════════════════════════════════════════════════════════════════════════════
#
# Usage:
#   ./scripts/release.sh [--env dev|staging|prod] [--skip-tests] [--skip-analyze]
#
# Prerequisites:
#   - Flutter SDK on PATH
#   - Dart SDK on PATH
#   - protoc compiler installed
#   - Android SDK configured
#   - key.properties configured (for signed release)
#
# Exit immediately on any failure.
set -euo pipefail
export SQLITE3_DONT_DOWNLOAD_PRECOMPILED=1

# ── Constants ────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
FLUTTER_BIN="${FLUTTER_BIN:-$(which flutter 2>/dev/null || echo "/home/tharan/Development/flutter/bin/flutter")}"
DART_BIN="${DART_BIN:-$(which dart 2>/dev/null || echo "/home/tharan/Development/flutter/bin/dart")}"

# ── Defaults ─────────────────────────────────────────────────────────────────
ENV="prod"
SKIP_TESTS=false
SKIP_ANALYZE=false
FLAVOR="prod"
BUILD_MODE="release"

# ── Argument Parsing ─────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case "$1" in
        --env)
            ENV="$2"
            shift 2
            ;;
        --skip-tests)
            SKIP_TESTS=true
            shift
            ;;
        --skip-analyze)
            SKIP_ANALYZE=true
            shift
            ;;
        *)
            echo "Unknown argument: $1"
            exit 1
            ;;
    esac
done

# Map environment to flavor
case "$ENV" in
    dev)     FLAVOR="dev" ;;
    staging) FLAVOR="staging" ;;
    prod)    FLAVOR="prod" ;;
    *)
        echo "ERROR: Unknown environment '$ENV'. Use dev, staging, or prod."
        exit 1
        ;;
esac

CONFIG_FILE="$PROJECT_DIR/config/${ENV}.json"

# ── Validation ───────────────────────────────────────────────────────────────
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "ERROR: Environment config not found: $CONFIG_FILE"
    exit 1
fi

# ── Build Metadata ───────────────────────────────────────────────────────────
GIT_COMMIT=$(git -C "$PROJECT_DIR" rev-parse --short HEAD 2>/dev/null || echo "unknown")
GIT_DIRTY=$(git -C "$PROJECT_DIR" diff --quiet 2>/dev/null && echo "" || echo "-dirty")
BUILD_TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
VERSION=$(grep 'version:' "$PROJECT_DIR/pubspec.yaml" | head -1 | awk '{print $2}' | cut -d'+' -f1)
BUILD_NUMBER=$(grep 'version:' "$PROJECT_DIR/pubspec.yaml" | head -1 | awk '{print $2}' | cut -d'+' -f2)

echo "═══════════════════════════════════════════════════════════════════════"
echo "  NammaRoute ETM Release Build Pipeline"
echo "═══════════════════════════════════════════════════════════════════════"
echo "  Environment  : $ENV"
echo "  Flavor       : $FLAVOR"
echo "  Version      : $VERSION+$BUILD_NUMBER"
echo "  Git Commit   : $GIT_COMMIT$GIT_DIRTY"
echo "  Build Time   : $BUILD_TIMESTAMP"
echo "  Config File  : $CONFIG_FILE"
echo "═══════════════════════════════════════════════════════════════════════"
echo ""

# ── Step 1: Clean ────────────────────────────────────────────────────────────
echo "▶ [1/8] Cleaning previous build artifacts..."
cd "$PROJECT_DIR"
$FLUTTER_BIN clean
echo "  ✓ Clean complete"
echo ""

# ── Step 2: Get Dependencies ────────────────────────────────────────────────
echo "▶ [2/8] Fetching dependencies..."
$FLUTTER_BIN pub get
echo "  ✓ Dependencies resolved"
echo ""

# ── Step 3: Code Generation ─────────────────────────────────────────────────
echo "▶ [3/8] Running code generation..."

# Protobuf generation
if [[ -f "$SCRIPT_DIR/generate_proto.sh" ]]; then
    bash "$SCRIPT_DIR/generate_proto.sh"
    echo "  ✓ Protobuf contracts generated"
fi

# Drift / build_runner generation
$DART_BIN run build_runner build --delete-conflicting-outputs
echo "  ✓ Drift database code generated"
echo ""

# ── Step 4: Static Analysis ─────────────────────────────────────────────────
if [[ "$SKIP_ANALYZE" == false ]]; then
    echo "▶ [4/8] Running static analysis..."
    $FLUTTER_BIN analyze --no-pub
    echo "  ✓ Static analysis passed (zero warnings)"
    echo ""
else
    echo "▶ [4/8] Static analysis SKIPPED (--skip-analyze)"
    echo ""
fi

# ── Step 5: Tests ────────────────────────────────────────────────────────────
if [[ "$SKIP_TESTS" == false ]]; then
    echo "▶ [5/8] Running test suite..."
    SQLITE3_DONT_DOWNLOAD_PRECOMPILED=1 $FLUTTER_BIN test --no-pub || {
        echo "  ✗ Tests failed. Aborting release build."
        exit 1
    }
    echo "  ✓ All tests passed"
    echo ""
else
    echo "▶ [5/8] Tests SKIPPED (--skip-tests)"
    echo ""
fi

# ── Step 6: Environment Verification ────────────────────────────────────────
echo "▶ [6/8] Verifying environment configuration..."
echo "  Config: $CONFIG_FILE"

# Verify required keys exist in config
for key in ENV_NAME API_BASE_URL MQTT_BROKER_URL MQTT_PORT; do
    if ! grep -q "\"$key\"" "$CONFIG_FILE"; then
        echo "  ✗ Missing required key: $key in $CONFIG_FILE"
        exit 1
    fi
done
echo "  ✓ Environment configuration validated"

# Check signing for release
if [[ "$ENV" == "prod" ]]; then
    KEY_PROPS="$PROJECT_DIR/android/key.properties"
    if [[ ! -f "$KEY_PROPS" ]]; then
        echo ""
        echo "  ⚠ WARNING: android/key.properties not found."
        echo "  ⚠ Release APK will use debug signing."
        echo "  ⚠ For production, create key.properties from key.properties.template."
        echo ""
    else
        echo "  ✓ Release signing configuration found"
    fi
fi
echo ""

# ── Step 7: Build APK ───────────────────────────────────────────────────────
echo "▶ [7/8] Building ${BUILD_MODE} APK for ${FLAVOR}..."

# Determine entry point
case "$ENV" in
    dev)     TARGET="lib/main.dart" ;;
    staging) TARGET="lib/main_staging.dart" ;;
    prod)    TARGET="lib/main_prod.dart" ;;
esac

$FLUTTER_BIN build apk \
    --${BUILD_MODE} \
    --flavor "$FLAVOR" \
    --target "$TARGET" \
    --dart-define-from-file="$CONFIG_FILE" \
    --dart-define="GIT_COMMIT=${GIT_COMMIT}${GIT_DIRTY}" \
    --dart-define="BUILD_TIMESTAMP=${BUILD_TIMESTAMP}" \
    --dart-define="APP_VERSION=${VERSION}" \
    --dart-define="BUILD_NUMBER=${BUILD_NUMBER}"

echo "  ✓ APK build complete"
echo ""

# ── Step 8: Verify APK ──────────────────────────────────────────────────────
echo "▶ [8/8] Verifying build output..."

APK_DIR="$PROJECT_DIR/build/app/outputs/flutter-apk"

# Find the APK
APK_FILE=$(find "$APK_DIR" -name "*.apk" -type f 2>/dev/null | head -1)

if [[ -z "$APK_FILE" ]]; then
    echo "  ✗ No APK found in $APK_DIR"
    exit 1
fi

APK_SIZE=$(du -h "$APK_FILE" | cut -f1)
echo "  APK: $APK_FILE"
echo "  Size: $APK_SIZE"

# Verify APK signing (requires apksigner or jarsigner)
if command -v apksigner &>/dev/null; then
    if apksigner verify --print-certs "$APK_FILE" 2>/dev/null; then
        echo "  ✓ APK signature verified"
    else
        echo "  ⚠ APK signature verification failed or unsigned"
    fi
elif command -v jarsigner &>/dev/null; then
    if jarsigner -verify "$APK_FILE" &>/dev/null; then
        echo "  ✓ APK signature verified (jarsigner)"
    else
        echo "  ⚠ APK signature verification failed"
    fi
else
    echo "  ⚠ apksigner/jarsigner not found — skipping signature verification"
fi

echo ""
echo "═══════════════════════════════════════════════════════════════════════"
echo "  BUILD SUMMARY"
echo "═══════════════════════════════════════════════════════════════════════"
echo "  Status       : SUCCESS"
echo "  Environment  : $ENV"
echo "  Version      : $VERSION+$BUILD_NUMBER"
echo "  Git Commit   : $GIT_COMMIT$GIT_DIRTY"
echo "  Build Time   : $BUILD_TIMESTAMP"
echo "  APK          : $APK_FILE"
echo "  APK Size     : $APK_SIZE"
echo "═══════════════════════════════════════════════════════════════════════"
echo ""
echo "Next steps:"
echo "  1. Install on device:  adb install $APK_FILE"
echo "  2. Run smoke test checklist"
echo "  3. Tag release:  git tag -a v${VERSION}+${BUILD_NUMBER} -m 'Release ${VERSION}+${BUILD_NUMBER}'"
echo ""
