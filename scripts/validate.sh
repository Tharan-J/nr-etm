#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# NammaRoute ETM — Release Validation (Phase 11)
# ═══════════════════════════════════════════════════════════════════════════════

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
export SQLITE3_DONT_DOWNLOAD_PRECOMPILED=1
FLUTTER_BIN="${FLUTTER_BIN:-/home/tharan/Development/flutter/bin/flutter}"
DART_BIN="${DART_BIN:-/home/tharan/Development/flutter/bin/dart}"

PASS=0
FAIL=0
WARN=0

check() {
    local desc="$1"
    shift
    echo -n "  Checking: $desc... "
    if "$@" >/dev/null 2>&1; then
        echo "✓ PASS"
        PASS=$((PASS + 1))
    else
        echo "✗ FAIL"
        FAIL=$((FAIL + 1))
    fi
}

warn_check() {
    local desc="$1"
    shift
    echo -n "  Checking: $desc... "
    if "$@" >/dev/null 2>&1; then
        echo "✓ PASS"
        PASS=$((PASS + 1))
    else
        echo "⚠ WARNING"
        WARN=$((WARN + 1))
    fi
}

echo "═══════════════════════════════════════════════════════════════════════"
echo "  NammaRoute ETM — Pre-Release Validation"
echo "═══════════════════════════════════════════════════════════════════════"
echo ""

cd "$PROJECT_DIR"

# ── 1. Environment Configs ───────────────────────────────────────────────────
echo "▶ Environment Configuration"
check "dev.json exists" test -f config/dev.json
check "staging.json exists" test -f config/staging.json
check "prod.json exists" test -f config/prod.json
echo ""

# ── 2. Git State ─────────────────────────────────────────────────────────────
echo "▶ Git State"
check "Git repository" git rev-parse --git-dir
warn_check "Working tree clean" git diff --quiet
warn_check "No uncommitted staged files" git diff --cached --quiet
echo ""

# ── 3. Dependencies ─────────────────────────────────────────────────────────
echo "▶ Dependencies"
check "pub get succeeds" $FLUTTER_BIN pub get
echo ""

# ── 4. Code Generation ──────────────────────────────────────────────────────
echo "▶ Code Generation"
check "Protobuf files exist" test -f lib/core/generated/proto/etm_telemetry.pb.dart
check "Drift generated files exist" test -f lib/core/capture/data/app_database.g.dart
echo ""

# ── 5. Static Analysis ──────────────────────────────────────────────────────
echo "▶ Static Analysis"
check "flutter analyze" $FLUTTER_BIN analyze --no-pub
echo ""

# ── 6. Test Suite ────────────────────────────────────────────────────────────
echo "▶ Test Suite"
check "flutter test" $FLUTTER_BIN test --no-pub
echo ""

# ── 7. Security Checks ──────────────────────────────────────────────────────
echo "▶ Security Review"

# Check for hardcoded URLs (excluding config files, comments, and imports)
HARDCODED_URLS=$(grep -rn "https\?://.*nammaroute" lib/ --include="*.dart" \
    | grep -v "env_config.dart" \
    | grep -v "// " \
    | grep -v "import " \
    || true)

if [[ -z "$HARDCODED_URLS" ]]; then
    echo "  Checking: No hardcoded API URLs in lib/... ✓ PASS"
    PASS=$((PASS + 1))
else
    echo "  Checking: No hardcoded API URLs in lib/... ✗ FAIL"
    FAIL=$((FAIL + 1))
fi

# Check for hardcoded secrets (excluding key names in storage)
HARDCODED_SECRETS=$(grep -rniE "(password|secret|api_key)\s*[:=]\s*['\"][^'\"]{4,}" lib/ --include="*.dart" \
    | grep -v "secure_storage_service.dart" \
    || true)
if [[ -z "$HARDCODED_SECRETS" ]]; then
    echo "  Checking: No hardcoded secrets in lib/... ✓ PASS"
    PASS=$((PASS + 1))
else
    echo "  Checking: No hardcoded secrets in lib/... ✗ FAIL"
    FAIL=$((FAIL + 1))
fi

# Check key.properties not committed
if git ls-files --error-unmatch android/key.properties >/dev/null 2>&1; then
    echo "  Checking: key.properties not tracked... ✗ FAIL (remove from git)"
    FAIL=$((FAIL + 1))
else
    echo "  Checking: key.properties not tracked... ✓ PASS"
    PASS=$((PASS + 1))
fi

echo ""

# ── 8. Build Configuration ──────────────────────────────────────────────────
echo "▶ Build Configuration"
check "AndroidManifest.xml exists" test -f android/app/src/main/AndroidManifest.xml
check "ProGuard rules exist" test -f android/app/proguard-rules.pro
check "Network security config exists" test -f android/app/src/main/res/xml/network_security_config.xml
warn_check "Release key.properties exists" test -f android/key.properties
echo ""

# ── 9. Release Signing ──────────────────────────────────────────────────────
echo "▶ Signing Configuration"
if [[ -f android/key.properties ]]; then
    echo "  Checking: key.properties present... ✓ PASS"
    PASS=$((PASS + 1))
else
    echo "  Checking: key.properties present... ⚠ WARNING (debug signing fallback)"
    WARN=$((WARN + 1))
fi
echo ""

# ── Summary ──────────────────────────────────────────────────────────────────
echo "═══════════════════════════════════════════════════════════════════════"
echo "  VALIDATION SUMMARY"
echo "═══════════════════════════════════════════════════════════════════════"
echo "  ✓ Passed  : $PASS"
echo "  ⚠ Warnings: $WARN"
echo "  ✗ Failed  : $FAIL"
echo "═══════════════════════════════════════════════════════════════════════"

if [[ $FAIL -gt 0 ]]; then
    echo ""
    echo "  VERDICT: NOT READY FOR RELEASE ($FAIL failures)"
    echo ""
    exit 1
else
    echo ""
    echo "  VERDICT: READY TO BUILD INTERNAL FIELD VALIDATION APK"
    if [[ $WARN -gt 0 ]]; then
        echo "  ($WARN warnings — review before production distribution)"
    fi
    echo ""
    exit 0
fi
