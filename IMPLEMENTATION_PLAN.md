# NammaRoute Conductor ETM — Master Engineering Implementation Plan

**Document Version:** 2.0.0  
**Status:** Approved for Execution  
**Author:** Principal Flutter Architect / Technical Lead  
**Target System:** NammaRoute Conductor ETM (Android Mobile Client)  

---

## 0. Implementation Guardrails & Non-Negotiable Rules

When implementing any part of this roadmap, the engineering agent / developer **MUST NEVER** perform any of the following without explicit prior approval from the Lead Architect / User:

1. 🚫 **Redesign Architecture:** Do not alter the Hexagonal-Core + Feature-Sliced structure or inward dependency direction.
2. 🚫 **Introduce New Packages:** Do not add third-party dependencies outside those authorized in `05_ETM_Technology_Decisions.md`.
3. 🚫 **Bypass Shared Core:** Do not write feature-local local-storage, network, or durability logic; all features must use `core/capture` and `core/sync`.
4. 🚫 **Move Business Logic into UI:** Do not perform precondition checks, fare calculations, or state validation inside Flutter widgets.
5. 🚫 **Change Synchronization Behaviour:** Do not alter batch sizes, backoff curves, or the 2-condition gate (Connectivity + Broker Session).
6. 🚫 **Alter Data Contracts:** Do not modify Protobuf or REST JSON wire schemas, field names, or types.
7. 🚫 **Modify Reliability Guarantees:** Do not make durable capture contingent on network, authorization, or battery state.

### Phase-by-Phase Review & Commit Protocol
To prevent architectural drift and accumulate verified code:
```
Phase X ──► Verification Gate ──► STOP & User Review ──► Git Commit ──► Phase X+1
```
Development will **NOT** proceed continuously across phases without explicit user review and a clean git commit after each phase.

---

## 1. Executive Summary & Architectural Commitments

This document defines the authoritative, production-grade **Master Implementation Plan** for the **NammaRoute Conductor ETM (Electronic Ticketing Machine)** application. It is the direct synthesis of all 11 foundational specifications (`00` through `10`).

The primary purpose of the ETM is to serve as an **offline-first data originator** for fare sales (Tickets) and bus location reports (Telemetry Pings) on low-cost Android hardware operating in intermittent, degraded, or non-existent connectivity environments.

### Core Architectural Commitments:
1. **Durable Capture First (ADR-008):** A ticket or telemetry ping is persisted to disk in SQLite/Drift before any network transmission is attempted. Captures never fail or block due to network or authorization outages.
2. **Fail-Closed on Authorization (ADR-007):** Device authorization is checked per-request by the platform backend. Unverifiable states during connectivity loss are treated as "Unknown, pending verification" and halt outbound synchronization while preserving local capture capability.
3. **Hexagonal-Core + Feature-Sliced Architecture:** The application core is strictly separated into inward-pointing layers (Domain $\rightarrow$ Application $\rightarrow$ Infrastructure/Adapters $\rightarrow$ Presentation/Platform Channels).
4. **Native Android Module Isolation:** Foreground service execution, location sensing, and MQTT transport live in a co-located Kotlin native module to bypass Flutter engine suspension risks under aggressive Android OEM power management.
5. **Separation of Storage Guarantees:** **Durable Capture** (Tickets & Pings) is non-disposable and durable. **Reference Context** (Trips, Stops, Fares, Pairing) is disposable read-only cache. Conflation of these layers is strictly forbidden.

---

## 2. Document Traceability Matrix

Every component of this implementation plan derives directly from the 11 authoritative specifications:

| Spec ID | Document Title | Primary Implementation Focus |
|---|---|---|
| `00` | `00_READ_FIRST.md` | Core engineering philosophy, folder layout, documentation hierarchy. |
| `01` | `01-Product-Specification.md` | Product vision, non-functional requirements, key field risks. |
| `02` | `02-etm-domain-specification.md` | Entities (`Ticket`, `TelemetryPing`, `Trip`, `FareRule`), ownership, and state machines. |
| `03` | `03-etm-workflow-specification.md` | Conductor and system operational flows (Device Ready, Ticket Capture, Connectivity Recovery). |
| `04` | `04-etm-system-architecture.md` | Subsystem boundaries, shared edge-event core, dependency direction rules. |
| `05` | `05-etm-technology-decisions.md` | Tech stack selection (Dart 3, Flutter 3.x, Riverpod 2.x, Drift, Kotlin, MQTT/Paho). |
| `06` | `06-etm-offline-sync-reliability-specification.md` | Durable buffer specifications, 2-condition sync gate, exponential backoff rules. |
| `07` | `07-etm-data-contracts-specification.md` | JSON REST & Protobuf MQTT binary schemas, serialization rules, additive evolution principles. |
| `08` | `08-etm-functional-feature-specification.md` | Complete functional inventory (Core, Supporting, Operational, Administrative, Cross-Cutting). |
| `09` | `09-etm-ui-ux-screen-specification.md` | High-contrast, one-handed operational UI design, 12 screen specs, state visibility rules. |
| `10` | `10_ETM_Engineering_Handbook.md` | Coding guidelines, package breakdown, state ownership rules, PR review checklist. |

---

## 3. Consolidated Gap & Risk Analysis

| # | Identified Gap / Risk | Architectural Impact | Mitigation Strategy in Implementation |
|---|---|---|---|
| 1 | **OEM Background Killing** | Android OEMs kill background Flutter engines & services, risking telemetry gaps. | Implement Kotlin Native Foreground Service with explicit `START_STICKY` & notification. Guide battery optimization onboarding (`09` §8.3). |
| 2 | **Mid-Shift Conductor Handoff** | Relief Conductor uses device without backend re-pairing, risking ticket misattribution. | Attribute tickets to Device Identity & last-known paired Conductor ID. Surface carried Conductor ID explicitly on UI. |
| 3 | **Unbounded Buffer Growth** | Multi-day dead zones cause SQLite storage accumulation. | Implement WAL mode in SQLite/Drift. Introduce local retention pruning policy for records marked `Synced`. |
| 4 | **Lack of Ticket Void / Correction Workflow** | Erroneous ticket cannot be edited/deleted. | Maintain strict append-only ticket posture. Structure `Ticket` entity to support future parent-referencing void events without schema mutation. |
| 5 | **Reference Data Staleness** | Fares or trips updated upstream during offline operation. | Store `cached_at` timestamps on all reference models. Surface staleness age honestly in UI ("Updated 2 hrs ago"). |
| 6 | **Transport vs Reconciliation Ambiguity** | Client only observes MQTT ACK (`Synced`), not backend database write (`Reconciled`). | Restrict client UI status vocabulary to `Captured` $\rightarrow$ `Buffered` $\rightarrow$ `Synced`. Never render "Reconciled". |

---

## 4. Target Technical Architecture & Directory Blueprint

```
lib/
├── app/                        # Composition Root & Routing
│   ├── app.dart                # MaterialApp setup with dark high-contrast theme
│   ├── bootstrap.dart          # Async startup & Riverpod container initialization
│   ├── router.dart             # GoRouter navigation table (12 screens)
│   └── theme.dart              # Utilitarian, high-contrast visual tokens
├── core/                       # Shared Edge-Event Core
│   ├── background/             # Platform channel controller for Kotlin Foreground Service
│   ├── capture/                # Durable Capture subsystem (Drift SQLite engine)
│   │   ├── data/               # Drift tables (`DurableTickets`, `DurablePings`) & DAO
│   │   └── domain/             # DurableCapturePort interface & buffer state models
│   ├── config/                 # Preferences & Session Storage (Shared Preferences)
│   ├── diagnostics/            # Diagnostic Logging & Observability (Sentry & Logger)
│   └── sync/                   # Synchronization & Transport Subsystem
│       ├── data/               # MQTT Platform Channel Transport Adapter
│       ├── domain/             # SyncEngine, 2-condition gate logic, pacing queues
│       └── presentation/       # SyncStatusNotifier & ConnectionStatusNotifier
├── features/                   # Feature-Sliced Modules
│   ├── identity/               # Device Identity & Authorization Subsystem
│   │   ├── data/               # Secure Storage Adapter (flutter_secure_storage)
│   │   └── domain/             # DeviceCredentials & AuthorizationState models
│   ├── reference_context/      # Reference Context Subsystem (Trips, Fares, Stops)
│   │   ├── data/               # Dio REST Client & Drift Reference Cache
│   │   └── domain/             # Reference Models & ContextResolutionPort
│   ├── telemetry/              # Telemetry Origination Subsystem
│   │   ├── data/               # Native Location Stream Adapter
│   │   └── domain/             # LocationPingGenerator & TelemetryPort
│   └── ticketing/              # Ticket Capture & Validation Subsystem
│       ├── domain/             # Ticket Validation Engine & Pricing Logic
│       └── presentation/       # Ticket Issuance, Selection & Confirmation Notifiers
├── platform/                   # Platform Channel Contracts
│   ├── location_channel.dart   # Native location stream bridge
│   ├── mqtt_channel.dart       # Native MQTT Paho client bridge
│   └── service_channel.dart    # Native foreground service bridge
└── ui/                         # Presentation Layer (Screens & Shared Components)
    ├── components/             # Status strip, high-contrast buttons, badges, sheets
    └── screens/                # 12 Screens per Spec 09 (Splash to Revoked)
android/
└── app/src/main/kotlin/com/nammaroute/etm/
    ├── MainActivity.kt         # Platform channel dispatcher
    ├── background/             # Foreground Service controller & WakeLock management
    ├── location/               # FusedLocationProviderClient wrapper
    └── mqtt/                   # Android Paho MQTT v3/v5 client integration
```

---

## 5. Granular Milestone Roadmap

### Phase 0: Project Bootstrap & Environment Verification
*   **Goal:** Verify toolchain, lock dependencies, validate local Android/Gradle environment, and verify existing backend contracts.
*   **Tasks:**
    1. Audit host system environment (Flutter 3.x, Dart 3.x, Android SDK API 34+, Java/JDK 17).
    2. Audit upstream backend contracts (`07_ETM_Data_Contracts_Specification.md`) and verify local protobuf compiler (`protoc`).
    3. Verify target directory `/home/tharan/Seeds/nammaroute/nr-etm/` posture.
*   **Verification Gate:** Toolchain versions recorded and verified; environment readiness confirmed.
*   **Stop & Review:** Present audit findings and request authorization for Phase 1A.

---

### Phase 1A: Flutter Project & Build Infrastructure
*   **Goal:** Initialize clean Flutter project, configure dependencies, linter rules, and Gradle build flavors (`dev`, `staging`, `prod`).
*   **Tasks:**
    1. Run `flutter create --org com.nammaroute --template=app --platforms=android .` inside project root.
    2. Configure `pubspec.yaml` with explicit dependency locks (`flutter_riverpod`, `drift`, `sqlite3_flutter_libs`, `dio`, `flutter_secure_storage`, `protobuf`, `go_router`, `logger`, `sentry_flutter`).
    3. Configure `analysis_options.yaml` with strict lints enforcing zero-warning threshold and inward architectural imports.
    4. Setup Android Gradle build flavors (`dev`, `staging`, `prod`) and Dart environment config parsing via `--dart-define-from-file`.
*   **Verification Gate:** `flutter analyze` passes clean; app builds for `dev` flavor without errors.
*   **Stop & Review:** Review project baseline and commit to git.

---

### Phase 1B: App Architecture Foundation, Composition Root & Router
*   **Goal:** Construct the hexagonal folder structure, composition root, logger, high-contrast theme, and `GoRouter` shell for all 12 screens.
*   **Tasks:**
    1. Scaffold directory hierarchy matching Section 4.
    2. Build composition root (`app/bootstrap.dart`, `app/app.dart`) and Riverpod provider scope.
    3. Build utilitarian high-contrast theme (`app/theme.dart`) per Spec 09 design tokens.
    4. Set up structured Logger & Sentry initialization (`core/diagnostics/`).
    5. Construct `GoRouter` table covering all 12 UI screens with visual placeholder screens.
*   **Verification Gate:** App launches, displays Splash $\rightarrow$ Router navigates through placeholder screens clean without error.
*   **Stop & Review:** Review composition root & router implementation; commit to git.

---

### Phase 1C: Code Generation & CI Pipeline Setup
*   **Goal:** Establish code generation pipeline (`build_runner`, Drift, Protobuf) and GitHub Actions CI workflow.
*   **Tasks:**
    1. Configure Protobuf compilation scripts (`protoc`) producing Dart and Kotlin data contracts.
    2. Setup `build_runner` configuration for Drift and JSON serialization.
    3. Create `.github/workflows/ci.yml` running `flutter analyze`, `flutter test`, and format checks on PRs.
*   **Verification Gate:** `protoc` and `build_runner` generate clean artifacts; local CI script passes.
*   **Stop & Review:** Review build scripts & CI workflow; commit to git.

---

### Phase 2A: Native Subsystem 1 — Android Foreground Service
*   **Goal:** Build independent Kotlin Foreground Service to protect process against OEM background termination.
*   **Tasks:**
    1. Implement `EtmForegroundService.kt` with persistent ongoing notification and `START_STICKY`.
    2. Build platform channel contract `lib/platform/service_channel.dart` to start/stop/monitor service state.
*   **Verification Gate:** Service starts, displays persistent status notification, and survives app minimization.
*   **Stop & Review:** Review Foreground Service Kotlin & Dart code; commit to git.

---

### Phase 2B: Native Subsystem 2 — Fused Location Provider
*   **Goal:** Build independent Kotlin location sensing module providing adaptive GPS coordinates.
*   **Tasks:**
    1. Implement `LocationProvider.kt` utilizing Android `FusedLocationProviderClient`.
    2. Build EventChannel `lib/platform/location_channel.dart` streaming coordinates into Dart.
*   **Verification Gate:** Location stream emits mock/real location updates into Flutter platform channel.
*   **Stop & Review:** Review Location Provider implementation; commit to git.

---

### Phase 2C: Native Subsystem 3 — MQTT Paho Transport Bridge
*   **Goal:** Build Kotlin MQTT client wrapper supporting TLS, Basic Auth, QoS 1 publish, and reconnect events.
*   **Tasks:**
    1. Implement `MqttTransportBridge.kt` using Eclipse Paho Android client library.
    2. Build MethodChannel/EventChannel `lib/platform/mqtt_channel.dart` for connection management & QoS 1 publishing.
*   **Verification Gate:** Kotlin MQTT bridge connects to broker and publishes test binary payload with ACK.
*   **Stop & Review:** Review MQTT Paho bridge implementation; commit to git.

---

### Phase 3: Shared Core — Durable Capture & Secure Storage
*   **Goal:** Construct the offline-first SQLite/Drift database layer for non-disposable capture of Tickets and Pings.
*   **Tasks:**
    1. Define Drift tables `DurableTickets` and `DurablePings` with WAL mode enabled.
    2. Implement `DurableCapturePort` and `DriftDurableCaptureAdapter`.
    3. Implement `SecureStorageAdapter` (`flutter_secure_storage`) for device auth credentials.
    4. Write Chaos Tests: verify mid-write app kill survivability.
*   **Verification Gate:** Test suite verifies 1,000 continuous captures complete in <10ms with zero data loss across app kills.
*   **Stop & Review:** Review Durable Capture core implementation & chaos tests; commit to git.

---

### Phase 4: Identity Subsystem & Device Readiness UI
*   **Goal:** Build device identity management, Basic Auth custody, fail-closed authorization, and complete `Splash`, `Initialization`, & `Revoked` UI screens.
*   **Tasks:**
    1. Build `IdentityRepository` managing credential lifecycle and authorization state tracking.
    2. Implement `Splash` screen (`09` §8.1) and `Device Initialization` screen (`09` §8.2).
    3. Implement `Device Revoked / Unauthorized` modal screen (`09` §8.12).
*   **Verification Gate:** App initializes, checks device identity state, routes to Initialization/Revoked appropriately.
*   **Stop & Review:** Review Identity module & readiness screens; commit to git.

---

### Phase 5: Reference Context Subsystem & Home Dashboard UI
*   **Goal:** Build REST client for Trips, Fares, and Route Stops with read-only SQLite caching, staleness engine, and `Home Dashboard` UI.
*   **Tasks:**
    1. Build `ReferenceContextRepository` consuming REST APIs and caching context in Drift reference tables.
    2. Implement staleness calculator (`cached_at` comparison).
    3. Build `Home Dashboard` (`09` §8.4) with top persistent status strip and shift framing.
    4. Build `Trip Context` screen (`09` §8.5).
*   **Verification Gate:** Dashboard displays cached trip/fare context offline, accurately surfaces staleness age.
*   **Stop & Review:** Review Reference Context & Dashboard UI; commit to git.

---

### Phase 6: Ticketing Engine & Ticketing UI Flow
*   **Goal:** Implement fare determination engine, ticket validation logic, and the complete 3-step ticketing screen flow.
*   **Tasks:**
    1. Build `FareDeterminationEngine` and `TicketValidationEngine`.
    2. Build `Boarding & Destination Selection` screen (`09` §8.6) with route-ordered stop list.
    3. Build `Fare Confirmation` screen (`09` §8.7) with large fare amount.
    4. Build `Ticket Confirmation` screen (`09` §8.8) surfacing instant local `Captured` status.
    5. Build `Ticket History` screen (`09` §8.9).
*   **Verification Gate:** Conductor can select stops, view fare, confirm sale, and verify instant capture offline in <50ms.
*   **Stop & Review:** Review Ticketing engine & UI workflow; commit to git.

---

### Phase 7: Telemetry Origination & Synchronization Engine
*   **Goal:** Implement telemetry generator and background sync engine operating under the 2-condition gate.
*   **Tasks:**
    1. Build `TelemetryGenerator` feeding location pings into `core/capture`.
    2. Build `SyncEngine` implementing oldest-first, paced batch draining for Tickets and Pings.
    3. Implement exponential backoff curves (Connection: 1s–5m; Publish: 2s–2m).
    4. Build `Sync & Connectivity Status Detail` screen (`09` §8.10).
*   **Verification Gate:** Accumulative offline queue of 500 records drains automatically in small paced batches upon connection restoration; sync detail sheet updates live.
*   **Stop & Review:** Review Telemetry & Sync engine; commit to git.

---

### Phase 8: Operational Support UI & Settings
*   **Goal:** Implement remaining administrative screens and battery optimization guidance.
*   **Tasks:**
    1. Build `Battery Optimization Onboarding` screen (`09` §8.3).
    2. Build `Settings` screen (`09` §8.11) with device info & battery exemption triggers.
*   **Verification Gate:** Conductor can toggle battery optimization settings and review device info.
*   **Stop & Review:** Review Settings & Battery Onboarding UI; commit to git.

---

### Phase 9: Hardening, Chaos Testing & Definition of Done
*   **Goal:** System-wide reliability audit, performance benchmarking, and final release preparation.
*   **Tasks:**
    1. Execute dead-zone recovery chaos tests (simulating total signal drop during active trip).
    2. Audit compliance against `10_ETM_Engineering_Handbook.md` review checklist.
    3. Configure production build signatures and Sentry crash reporting.
*   **Verification Gate:** 100% test pass rate across unit, widget, and integration test suites; zero static analysis warnings; signed release APK build generated.
*   **Stop & Review:** Final Architectural Audit & Master Review.

---

## 6. Testing, Quality Assurance & Definition of Done

### Verification Matrix:
*   **Unit Tests:** Coverage target $>90\%$ for Domain and Application layers (`features/ticketing`, `features/telemetry`, `core/capture`, `core/sync`).
*   **Widget Tests:** Screen state rendering tests for all 12 screens under `Online`, `Offline`, `Degraded`, and `Unauthorized` states.
*   **Integration Tests:** End-to-end flow execution on physical Android hardware verifying platform channel communication and background service retention.

### Final Definition of Done (DoD):
1. **Zero Data Loss Guarantee:** No captured ticket or telemetry ping is lost under app kill, battery death, or crash.
2. **Instant Ticket Capture:** Ticket capture feedback renders in $<50\text{ ms}$ locally without waiting for network ACK.
3. **Honest State Surfaces:** Client UI never claims "Reconciled" and explicitly distinguishes between "Offline" and "Unauthorized".
4. **Clean Code & Architecture:** Absolute adherence to inward hexagonal dependencies; strict zero-warning policy on static analysis.
