# Phase 10: ProGuard/R8 rules for NammaRoute ETM release builds.
#
# Flutter-specific rules are handled by the Flutter Gradle plugin.
# These rules cover native Android dependencies.

# ── Keep Google Play Services Location ────────────────────────────────────────
-keep class com.google.android.gms.location.** { *; }
-keep class com.google.android.gms.common.** { *; }

# ── Keep NammaRoute native service classes ────────────────────────────────────
-keep class com.nammaroute.nr_etm.service.** { *; }
-keep class com.nammaroute.nr_etm.MainActivity { *; }

# ── Keep Flutter engine ──────────────────────────────────────────────────────
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# ── Suppress warnings for common Flutter plugin dependencies ─────────────────
-dontwarn com.google.errorprone.annotations.**
-dontwarn javax.annotation.**
-dontwarn kotlin.Unit
-dontwarn com.google.android.play.core.**

