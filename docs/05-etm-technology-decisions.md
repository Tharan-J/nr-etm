# NammaRoute Conductor ETM — Technology Decisions
### `docs/etm-technology-decisions.md`

**Document type:** Technology Decisions — translates the approved ETM System Architecture Specification into concrete technology choices. It does not redesign the architecture, does not discuss feature implementation, and does not write code.
**Position in the hierarchy:** Derives from, and must not contradict, the ETM System Architecture Specification, the ETM Product/Domain/Workflow Specifications, and every backend ADR. Feeds Engineering Guidelines, Implementation Planning, and every future Feature Specification's technical constraints — none of which reopen a decision made here without a superseding entry in this document.
**Status:** Living document. A technology choice changes here only through the review triggers named in §11 — not through individual engineer preference on a given feature.

---

## 1. Purpose

This document answers one question per category, and one question only: **given the architecture already fixed upstream, which specific technology satisfies it best, and why?** It does not ask "which technology is best in general" — a technology can be excellent and still wrong for this system if it doesn't satisfy a constraint the System Architecture Specification already fixed (offline-first durability, background-execution survivability, a shared reliability mechanism for Ticket and Telemetry capture, honest staleness representation).

The backend's technology stack (Go, PostgreSQL/TimescaleDB, Redis, MQTT, Protobuf, JWT) is fixed and external (Project Context). This document selects the ETM's own stack to integrate with that fixed backend — it does not revisit a single backend technology choice, and every ADR in the backend's ADR collection is treated here as a hard constraint, not a suggestion.

## 2. Decision Principles

Carried directly from the System Architecture Specification's Architectural Principles (§8 of that document), translated into technology-selection criteria:

1. **Offline-first is a selection filter, not a feature to bolt on.** A candidate technology that requires network availability to function correctly, or that degrades ungracefully without one, is disqualified regardless of its other merits.
2. **A technology choice may not blur the Durable-Capture-vs-Reference-Cache distinction** the architecture draws (System Architecture §14) — local storage technology selection in particular is evaluated against this distinction explicitly, not against generic "local database" criteria alone.
3. **Survive an arbitrary process kill.** Any technology touching the capture-to-sync path is evaluated on what happens to in-flight data when the OS kills the process without warning — the architecture's dominant constraint (System Architecture §9's "OEM background-execution killing" risk).
4. **Minimal unnecessary dependencies.** A second library solving a problem an already-selected library solves adequately is rejected by default; the burden of proof is on adding a dependency, not on avoiding one.
5. **Boring, proven technology unless the alternative is materially better for this specific problem** — inherited directly from the Product Engineering Blueprint (Part 15) and restated here as a technology-selection default, not merely a backend-scoped one.
6. **Testability is a selection criterion, not an afterthought.** A technology that cannot be exercised in a fast, hermetic unit or widget test without a real device, broker, or network is weighed down accordingly.
7. **Long-term stability over marginal capability.** Given a small team (Product Engineering Blueprint Part 19) and a multi-year field-deployment horizon for provisioned hardware, a technology with an uncertain maintenance trajectory is a bigger risk than one that is merely "less exciting."
8. **No technology may silently expand the ETM's scope beyond its two jobs** (System Architecture §9, "Out of Scope") — a technology category that would pull in fleet analytics, commuter features, or dashboard-adjacent capability is rejected on architectural grounds before it is evaluated on technical merit.

## 3. Evaluation Methodology

Every category in §5 follows the same eight-step discipline, applied uniformly rather than selectively:

1. **Identify the problem** the category solves, stated in terms of what the System Architecture Specification's subsystems (§12 of that document) actually need — never in terms of "what do Flutter apps typically use."
2. **Define evaluation criteria** specific to that problem, drawn from the shared criteria list (Product/Domain/Workflow/Architecture requirements: offline capability, performance, battery usage, memory footprint, maintainability, community maturity, documentation quality, Android compatibility, long-term support, testability, scalability, learning curve, ecosystem integration, backend compatibility, offline-first-architecture compatibility) — only the criteria materially relevant to that category are discussed, to avoid mechanically repeating all fifteen for every decision.
3. **List candidates** genuinely under consideration — not a padded list assembled for the appearance of rigor.
4. **Compare candidates** in a table.
5. **State trade-offs** plainly, including for the option ultimately selected — a selection with no acknowledged trade-off is treated as an incomplete evaluation, not a clean win.
6. **Select one** — this document does not leave a category multi-valued or deferred unless explicitly marked as such (categories 18–20 are the only deliberate exceptions, and each states why).
7. **Justify the decision** against the System Architecture Specification directly, by section reference where applicable — not against general popularity or the author's preference.
8. **Name migration risk** — what would have to be true for this decision to need revisiting, and roughly how expensive that would be.

## 4. Technology Stack Overview

| # | Category | Decision |
|---|---|---|
| 1 | Programming Language | Dart |
| 2 | UI Framework | Flutter |
| 3 | Architectural Pattern (implementation) | Clean Architecture (domain / application / infrastructure), realized via Riverpod as the composition layer |
| 4 | State Management | Riverpod |
| 5 | Navigation | go_router |
| 6 | Local Storage | Drift (SQLite, WAL mode) |
| 7 | Secure Storage | flutter_secure_storage (Android Keystore-backed) |
| 8 | Dependency Injection | Riverpod's provider graph (no separate DI framework) |
| 9 | Background Execution | Native Android Foreground Service (Kotlin), bridged via platform channel |
| 10 | Location Services | Native FusedLocationProviderClient, co-located with the foreground service |
| 11 | MQTT Client | Native Eclipse Paho Android Client, co-located with the foreground service |
| 12 | HTTP Client | dio |
| 13 | Serialization | `protobuf` (Dart, MQTT payloads) + `json_serializable` (REST payloads) |
| 14 | Local Preferences | shared_preferences |
| 15 | Logging | `logger` (Dart) + durable rotating local sink |
| 16 | Error Reporting | Sentry |
| 17 | Analytics | None at MVP — out of architectural scope |
| 18 | Printing Integration | Deferred — out of MVP scope |
| 19 | Barcode / QR | Deferred — out of MVP scope |
| 20 | Maps | Not required at MVP |
| 21 | Image Handling | Not required at MVP |
| 22 | Connectivity Monitoring | connectivity_plus (Dart signal) + native broker-session state (authoritative) |
| 23 | Testing Framework | flutter_test + Dart `test` + `integration_test` |
| 24 | Mocking Strategy | mocktail |
| 25 | Build System | Flutter/Gradle (Kotlin DSL), flavor-based (dev/staging/prod) |
| 26 | CI/CD | GitHub Actions |
| 27 | Release Strategy | Google Play, staged rollout, Android App Bundle (AAB) |
| 28 | Crash Recovery Support | SQLite WAL (via Drift) + foreground service `START_STICKY` |
| 29 | Performance Monitoring | Sentry Performance (same vendor as #16) |
| 30 | Configuration Management | `--dart-define-from-file` + Gradle build flavors |

## 5. Detailed Technology Evaluations

### 5.1 Programming Language

**Problem:** The ETM needs a language that can express the domain/application/infrastructure layering the System Architecture Specification fixes (§11 of that document), target Android reliably, and support long-lived, maintainable code for a small team.

**Requirements:** Strong null-safety guarantees (a null-related crash in the capture path is unacceptable given §12.5's durability guarantee); mature async/stream primitives (the architecture's event-driven capture-to-sync flow, §13 of that document, is naturally stream-shaped); acceptable performance on low-cost Android hardware (Product Specification §14).

| Candidate | Null safety | Async/stream model | Android-native interop | Team-fit for a small team |
|---|---|---|---|---|
| **Dart (via Flutter)** | Sound, compiler-enforced | First-class `Future`/`Stream` | Platform channels to Kotlin/Java, mature | Single codebase, one language for nearly all logic |
| **Kotlin (native Android only)** | Sound | Coroutines/Flow | Native, no bridging | Strong Android fit, but commits to a single-platform-only investment the architecture doesn't require |
| **Java (native Android only)** | Not sound by default | Weaker (RxJava bolt-on) | Native | Declining ecosystem investment; rejected outright |

**Decision: Dart.**

**Reasoning:** The System Architecture Specification's own reference framing (module boundaries, ports-and-adapters layering) was written to be realized in Flutter — the prior architecture document's explicit Out-of-Scope list (Riverpod, Bloc, Go Router, folder structure) presupposes a Flutter/Dart implementation target, not a native-Android-only one. Dart's sound null safety directly protects the one guarantee the architecture treats as non-negotiable (§12.5's durable-capture correctness); a null-related failure in that path is exactly the kind of defect null safety is designed to catch at compile time rather than at 2 a.m. in a dead zone.

**Rejected options:** Kotlin-only native Android was seriously considered, since it would remove all platform-channel bridging for categories 9–11 (background execution, location, MQTT) — a real simplification. It is rejected because it would require re-implementing the entire presentation and application layer in a second toolchain with no corresponding architectural benefit; the categories that genuinely warrant native code (9, 10, 11) are isolated to native modules regardless of host-language choice (§5.9–§5.11), so Kotlin-only buys native-throughout at the cost of Dart's productivity and testing ecosystem everywhere else, for no reliability gain where it matters (the native modules are native either way).

**Migration considerations:** Migrating off Dart would mean rewriting the entire application layer, not a single subsystem — this is the single highest-cost migration in this document by a wide margin, and is treated as effectively foreclosed once implementation begins in earnest, consistent with Decision Principle 7.

---

### 5.2 UI Framework

**Problem:** A presentation layer is needed that can render Conductor-facing screens on low-cost Android hardware, stay decoupled from the domain layer the architecture requires (§11 of that document), and not become a second source of business logic.

**Candidates:** Flutter, native Android (Jetpack Compose/Views), React Native.

| Candidate | Offline capability | Performance on low-end hardware | Android ecosystem maturity | Fit with selected language (§5.1) |
|---|---|---|---|---|
| **Flutter** | No inherent dependency on network for rendering; fully compatible with an offline-first data layer | Compiled, predictable frame performance; well-proven on budget Android devices | Mature, first-party Google support, large plugin ecosystem | Native fit — Dart is Flutter's language |
| **Jetpack Compose (native)** | Same | Best-in-class on Android specifically | Mature, first-party | Would require Kotlin (§5.1's rejected option) |
| **React Native** | Workable, but bridges through a JS runtime for every native interaction | Historically weaker on low-end hardware for animation-heavy UI; less relevant here since the ETM's UI is not animation-heavy, but the JS-bridge overhead still applies to every platform-channel-equivalent call | Mature but a third language (JS/TS) added on top of the native Kotlin modules already required (§5.9–§5.11) | Adds a language rather than reusing one |

**Decision: Flutter.**

**Reasoning:** Given Dart is already selected (§5.1) for the reasons stated there, Flutter is the only UI framework that shares that language natively. React Native would introduce a third language (JavaScript/TypeScript) into a system that already requires native Kotlin modules for the background-execution/location/MQTT cluster (§5.9–§5.11) — three languages in one small-team codebase directly violates Decision Principle 4 (minimal unnecessary dependencies) with no offsetting benefit, since neither React Native nor Flutter avoids the native-module requirement that risk (§9 of the Architecture Specification) forces regardless.

**Rejected options:** Native Android (Jetpack Compose) was the closest competitor and is rejected for the same single reason Kotlin-only was rejected in §5.1 — it would eliminate platform-channel bridging entirely, a genuine simplification, but at the cost of the presentation-layer productivity and single-codebase maintainability Flutter provides, for a system whose hardest reliability problems (§5.9–§5.11) are isolated to native modules regardless of the UI framework surrounding them.

**Migration considerations:** Tightly coupled to §5.1; migrating away from Flutter is, in practice, the same event as migrating away from Dart.

---

### 5.3 Architectural Pattern (Implementation)

**Problem:** The System Architecture Specification fixes a layering discipline (domain → application → infrastructure, dependency direction strictly inward, §11 of that document) but does not fix how that discipline is expressed in Flutter code. A concrete pattern is needed that realizes it without contradicting it.

**Candidates:** MVC, MVVM (as a whole-app pattern), MVI, Clean Architecture (data/domain/presentation) paired with a reactive state layer.

| Candidate | Matches the architecture's inward dependency rule | Testability of domain logic in isolation | Fit for stream-shaped capture/sync state |
|---|---|---|---|
| **MVC** | Weak — Android/Flutter MVC implementations routinely let the "Controller" reach into infrastructure directly, eroding the domain/infrastructure boundary §11 requires | Moderate | Weak — no native reactive-state concept |
| **MVVM (whole-app)** | Partial — MVVM answers view-to-state binding well but is silent on the domain/infrastructure separation the architecture actually requires beneath the ViewModel | Moderate | Strong for view state; silent below it |
| **MVI** | Strong on unidirectional flow, but is a presentation-layer pattern, not a whole-system layering answer | Strong for presentation | Strong |
| **Clean Architecture + reactive state layer** | Strong — this is the pattern the System Architecture Specification's own layer descriptions (domain/application/infrastructure, §11) are already written in the vocabulary of | Strong — domain layer has zero Flutter/Android dependency, directly satisfying Decision Principle 6 | Strong, when paired with a reactive state-management library (§5.4) |

**Decision: Clean Architecture (domain / application / infrastructure), with Riverpod (§5.4) as the composition and reactive-state layer connecting them.**

**Reasoning:** This is not a new decision so much as the direct Dart/Flutter realization of a decision the System Architecture Specification already made — its own Layer Responsibilities section (§11 of that document) is written in domain/application/infrastructure terms with a strict inward dependency rule, which is Clean Architecture's own vocabulary. Selecting anything else here would mean re-deriving that layering under different names, adding confusion without adding value. Riverpod is the composition mechanism (not a separate architectural pattern) because its provider graph gives dependency inversion (Decision Principle discussed in §5.8) without a separate DI framework, and its `StreamProvider`/`AsyncNotifier` primitives map directly onto the architecture's stream-shaped capture-and-sync-status flows (System Architecture §12.8) without requiring a second state-management concept layered on top.

**Rejected options:** A dedicated BLoC-pattern library (the `bloc`/`flutter_bloc` package family) was considered as the reactive layer instead of Riverpod and is a legitimate alternative — its event-driven, unidirectional-flow discipline maps well onto the architecture's own event-driven framing. It is not selected because it solves a narrower problem (presentation-layer reactive state) than Riverpod does (reactive state *and* the dependency-inversion/composition role §5.8 needs), and adopting both would mean two competing composition mechanisms in one codebase, a direct Decision Principle 4 violation.

**Migration considerations:** Moderate cost if reversed — the domain layer itself, being framework-agnostic by construction, would not need to change; only the application-layer composition and presentation bindings would need rewriting.

---

### 5.4 State Management

**Problem:** The presentation layer needs to reactively reflect capture state, sync status, authorization state, and reference-context staleness (System Architecture §12.8, §15) without those concerns leaking business logic into widgets.

**Candidates:** Riverpod, Bloc/Cubit, Provider (legacy), GetX.

| Candidate | Compile-time safety | Testability without a widget tree | Doubles as DI (§5.8) | Maintenance trajectory |
|---|---|---|---|---|
| **Riverpod** | Strong — providers are compile-time checked, no `BuildContext` lookup failures at runtime | Strong — providers can be instantiated and overridden in plain Dart tests | Yes — this is a first-class use case of the library | Actively maintained, explicitly designed as Provider's successor |
| **Bloc/Cubit** | Moderate | Strong — a well-established pattern for testing state machines in isolation | No — a separate DI mechanism (get_it, etc.) is conventionally paired with it | Actively maintained, large enterprise adoption |
| **Provider (legacy)** | Weaker — relies on `BuildContext`, more runtime-discoverable failures | Moderate | Partial | Effectively superseded by Riverpod (same author) |
| **GetX** | Weak — relies on service-locator-style global state and string/type-based lookup, resists compile-time verification | Weak — global singletons are harder to isolate in tests | Yes, but via a global locator, not a scoped graph | Maintained, but its all-in-one (routing/state/DI) design increases coupling in ways that cut against Decision Principle 4 |

**Decision: Riverpod.**

**Reasoning:** Riverpod is selected specifically because it satisfies two categories at once — state management and dependency injection (§5.8) — without adding a second library for the latter, directly serving Decision Principle 4. Its compile-time-checked provider graph reduces an entire class of runtime failure (a missing provider in the widget tree) that would otherwise surface exactly where this system can least afford surprise failures: the screens a Conductor depends on mid-shift. Its `Stream`/`AsyncValue`-based providers map directly onto the System Architecture Specification's own state-ownership model (§15 of that document — each piece of state has exactly one owning subsystem) by letting each owning subsystem expose exactly one provider as its external read surface.

**Rejected options:** Bloc/Cubit is the strongest rejected alternative and is not a poor choice in absolute terms — it is rejected here specifically because pairing it with a separate DI mechanism (conventionally get_it) to cover §5.8 would mean two libraries doing overlapping composition work, where Riverpod does both with one. GetX is rejected outright: its reliance on global, loosely-typed service location resists the compile-time safety Decision Principle 6 and 7 both weight heavily, and its tendency to blur state/DI/routing into one package cuts against the modular, single-responsibility-per-concern discipline the System Architecture Specification requires of every subsystem (§8, Principle 5 of that document).

**Migration considerations:** Riverpod's provider-based composition is pervasive by design once adopted; migrating away would touch every feature module's presentation and application-layer wiring, though the domain layer itself (framework-agnostic per §5.3) would be unaffected.

---

### 5.5 Navigation

**Problem:** The ETM has a small, bounded set of Conductor-facing screens (ticketing flow, telemetry/sync status, device-ready/authorization states) that need declarative, testable routing without pulling in unnecessary complexity.

**Candidates:** go_router, imperative `Navigator` 1.0, auto_route.

| Candidate | Declarative | Deep-link support | Testability | Code-generation dependency |
|---|---|---|---|---|
| **go_router** | Yes | Yes, first-party Flutter team package | Strong — routes are plain, testable objects | None required |
| **Navigator 1.0 (imperative)** | No | Manual, error-prone | Weaker — route stack state is harder to assert on in tests | None |
| **auto_route** | Yes | Yes | Strong | Requires `build_runner` code generation |

**Decision: go_router.**

**Reasoning:** The ETM's navigation surface is small and does not need auto_route's code-generation convenience badly enough to justify adding another `build_runner`-dependent tool to a build already using code generation for local storage (§5.6), serialization (§5.13), and DI-adjacent providers is unnecessary here since Riverpod requires none — go_router avoids adding a code-generation step for no proportionate benefit at this navigation complexity, directly serving Decision Principle 4. It is first-party maintained by the Flutter team, which weighs favorably under Decision Principle 7 (long-term stability).

**Rejected options:** Imperative `Navigator` 1.0 is rejected because its route-stack state is harder to test deterministically, and the architecture's own testability goal (System Architecture §4) extends to every layer, including navigation state relevant to conditional flows (e.g., routing to an "unauthorized" screen on revocation, §12.1 of that document). auto_route is rejected narrowly, on Decision Principle 4 grounds alone, not on technical merit.

**Migration considerations:** Low — navigation logic is typically well-isolated from domain and application layers in this architecture; a future migration would be localized to the presentation layer.

---

### 5.6 Local Storage

**Problem:** This is the single most architecturally load-bearing technology decision in this document. It must implement the System Architecture Specification's Durable Capture subsystem (§12.5 of that document) — durable, transactional writes that complete *before* any network attempt, survivable across an arbitrary process kill — and, separately, the disposable Reference Context cache (§12.2 of that document), with the two roles kept structurally distinct per Architectural Principles 2 and 3 (§8 of that document).

**Requirements:** ACID-transactional writes; crash-safe persistence (a partial write must never be observable as a complete one); reactive query support (Sync-Status Honesty, §12.8, needs to observe lifecycle-state changes as they happen, not only poll); a data model expressive enough to represent Ticket, Telemetry Ping, and each Reference Context type distinctly, so the two disposability rules (§14 of the Architecture Specification) can be enforced by schema, not just by convention.

| Candidate | Transactional guarantees | Reactive queries | Type safety | Migration tooling | Maturity on Android |
|---|---|---|---|---|---|
| **Drift (SQLite)** | Full ACID via SQLite, WAL mode supported | Native `Stream<List<Row>>` query support | Compile-time-checked schema and queries via code generation | Built-in, versioned schema migrations | Mature, widely deployed |
| **sqflite (raw SQLite)** | Full ACID | Manual — no reactive layer without hand-rolled wrapping | None — raw SQL strings | Manual | Mature |
| **Isar** | Transactional | Native reactive queries (`watch()`) | Strong, code-generated | Built-in | Newer, smaller community than SQLite-based options |
| **Hive** | Weaker transactional guarantees — designed as a fast key-value/object store, not a relational engine with multi-row transaction semantics | Limited | Moderate | Manual | Mature but purpose-built for simpler data, not ideal for the relational shape of Ticket↔Trip↔FareRule↔RouteStop references |
| **ObjectBox** | Transactional | Reactive (`watch()`) | Strong | Built-in | Mature, but a proprietary storage engine rather than SQLite, a materially different long-term-support profile |

**Decision: Drift, running on SQLite in WAL (Write-Ahead Logging) mode.**

**Reasoning:** SQLite's transactional model is exactly what ADR-008's ordering (write durably, then and only then attempt network) requires at the storage-engine level — a transaction either fully commits or is entirely rolled back, which is what makes "the process was killed mid-write" resolvable to "either the Ticket exists durably, or it doesn't" rather than a partially-written, ambiguous record. WAL mode specifically is selected (over SQLite's default rollback-journal mode) because it provides better crash-safety and concurrent read/write behavior — the Synchronization subsystem (§12.6 of the Architecture Specification) reading pending records while Ticket Capture or Telemetry Origination (§12.3, §12.4) is concurrently writing new ones is a normal, continuous operating condition for this system, not an edge case. Drift is chosen over raw sqflite because its compile-time-checked schema directly enforces the architecture's Durable-Capture-vs-Reference-Cache distinction: Ticket, Telemetry Ping, and each Reference Context type are modeled as distinct, statically-typed tables, making it a compile error, not a runtime bug, to accidentally treat a cached Fare Rule row the same way as an unsynced Ticket row. Drift's native `Stream`-based queries feed Sync-Status Honesty (§12.8) and Reference Context staleness signals (§12.2) directly, without a hand-rolled observation layer.

**Rejected options:** Isar and ObjectBox are both reactive, well-performing NoSQL-style local databases and were seriously considered; both are rejected because they are non-SQLite storage engines with smaller long-term-support track records than SQLite itself (which underlies Drift and sqflite) — given Decision Principle 7 and the multi-year field-deployment horizon of provisioned hardware (Product Specification §14, devices "may pass between conductors across shifts" over a long operational life), betting the system's single most load-bearing subsystem on a newer, smaller-ecosystem storage engine is a risk this document declines to take when a SQLite-based option satisfies every functional requirement. Hive is rejected because its key-value/object-store model is a poor structural fit for the relational shape of a Ticket's required references (Trip, Conductor, Fare Rule, Route Stop pair — Domain Specification §5.4), and its transactional guarantees are weaker than SQLite's ACID model.

**Migration considerations:** High cost, deliberately — this is the one category where the migration cost is treated as a *feature* of the decision, not a risk to minimize, because a storage-engine migration mid-deployment (with field devices holding unsynced data) is exactly the kind of operation this document wants to make expensive enough that it is never undertaken casually. A future migration would require an explicit, tested data-migration path for any Devices holding unsynced records at the moment of upgrade — this constraint should inform any future review under §11.

---

### 5.7 Secure Storage

**Problem:** The Device credential (System Architecture §12.1) is the ETM's only security principal and must be stored in a way that resists casual extraction if a device is lost or stolen — a named platform risk (Product Specification §17: "Device loss or theft mid-shift").

**Candidates:** flutter_secure_storage, custom Android Keystore integration, storing the credential in Drift/SQLite directly.

| Candidate | Encryption at rest | Backed by hardware-level keystore | Simplicity |
|---|---|---|---|
| **flutter_secure_storage** | Yes — delegates to Android Keystore (EncryptedSharedPreferences under the hood on supported API levels) | Yes | Simple, small API surface |
| **Custom Keystore integration (hand-rolled)** | Yes, if implemented correctly | Yes | More implementation and maintenance burden for no functional gain over the plugin |
| **Storing the credential in Drift/SQLite** | No, not by default — SQLite files are not encrypted at rest without an additional extension | No | Simplest to build, wrong on security grounds |

**Decision: flutter_secure_storage.**

**Reasoning:** The Device credential's compromise is the single event Workflow Specification §15 and §17 (Device Revocation, Authentication Failure) exist to bound the damage from — storing it anywhere other than hardware-backed secure storage would materially widen the exposure window a lost device creates, directly undermining the backend's own fail-closed posture (ADR-007, ADR-009) by making the client-side credential easier to extract than the backend's revocation model assumes. flutter_secure_storage is a thin, well-maintained wrapper over the Android platform's own Keystore-backed encrypted storage rather than a reimplementation of cryptographic storage — consistent with Decision Principle 5 (boring, proven technology), the "boring" choice here is deferring to the OS's own security primitive, not building one.

**Rejected options:** Storing the credential in Drift is rejected outright on security grounds, not convenience grounds — it is not a close call. A hand-rolled Keystore integration is rejected because it duplicates what a narrowly-scoped, widely-audited plugin already does correctly, violating Decision Principle 4 for no security benefit.

**Migration considerations:** Low — the credential is a single value with a narrow read/write surface (Identity & Authorization Awareness, §12.1); a future migration to a different secure-storage mechanism would be localized to that subsystem's infrastructure adapter.

---

### 5.8 Dependency Injection

**Problem:** The System Architecture Specification's dependency-inversion principle (§8, Principle 6 of that document) requires the domain layer to depend on abstractions the infrastructure layer implements — some composition mechanism must wire concrete implementations to those abstractions at startup.

**Candidates:** Riverpod's provider graph (already selected, §5.4), get_it (service locator), injectable (code-generation over get_it).

| Candidate | Compile-time safety | Scoping (e.g., per-feature-module lifetimes) | Additional dependency beyond §5.4 |
|---|---|---|---|
| **Riverpod provider graph** | Strong | Strong — Riverpod's provider scoping directly supports this | None — already present for state management |
| **get_it** | Weak — runtime service-locator lookups, type-mismatch failures surface at runtime | Weaker, manual scope management | Yes, a second library |
| **injectable (get_it + code-gen)** | Improves get_it's safety via generated registration code | Improved | Yes, a second library plus another `build_runner` generator |

**Decision: Riverpod's provider graph — no separate dependency-injection framework.**

**Reasoning:** This decision is dictated by §5.4, not independently re-derived: Riverpod's compile-time-checked provider graph *is* a dependency-injection mechanism, and using it for that purpose costs nothing beyond what state management already requires. Adding get_it or injectable on top would mean two parallel composition graphs in the same codebase — a direct, avoidable violation of Decision Principle 4, and a genuine maintainability risk, since a future engineer would have to know which mechanism resolves which dependency.

**Rejected options:** get_it and injectable are both mature, credible choices in a codebase that did not already need Riverpod for state management — they are rejected here specifically because that precondition doesn't hold in this stack, not because they are poor tools generally.

**Migration considerations:** Coupled entirely to §5.4's migration profile.

---

### 5.9 Background Execution

**Problem:** This category exists to satisfy the architecture's single highest-ranked risk directly (System Architecture §9, §12.7, §20 — "OEM background-execution killing," "no code-only fix"). Telemetry Origination (§12.4) and Synchronization (§12.6) must keep running while the Conductor's attention is elsewhere, across screen-off, backgrounding, and aggressive OEM battery management.

**Requirements:** A true Android foreground service (the only mechanism with any real standing against OEM background-killing, per Android platform behavior); `START_STICKY` restart semantics; the ability to request the Conductor's cooperation in exempting the app from aggressive battery optimization (an onboarding-flow requirement named directly in the Architecture Specification, §12.7).

**Candidates:** Native Android Foreground Service (Kotlin) bridged via platform channel; `flutter_background_service` plugin; `workmanager` plugin.

| Candidate | True foreground-service backing | Restart semantics | Control over notification/lifecycle edge cases | Coupling to §5.10/§5.11 |
|---|---|---|---|---|
| **Native foreground service (Kotlin), platform-channel bridged** | Yes, direct | Full control (`START_STICKY`) | Full control — no abstraction layer between the app and the exact Android APIs this risk requires precise handling of | Natural — the same native module can host location and MQTT client code (§5.10, §5.11), minimizing cross-process/cross-engine chatter |
| **flutter_background_service** | Yes, wraps a foreground service | Plugin-managed, less direct control | Abstracted — a real convenience, but exactly the layer of indirection this system's highest-ranked risk argues against | Would still likely need native code for MQTT/location anyway, reducing its own benefit |
| **workmanager** | No — Android `WorkManager` is designed for deferrable, periodic background work with a practical minimum interval (historically 15 minutes) | Not designed for continuous foreground operation | N/A | Incompatible with the 8-second-to-60-second adaptive telemetry cadence entirely |

**Decision: A native Android Foreground Service, written in Kotlin, bridged to the Flutter layer via platform channels — not a Flutter-side plugin abstraction.**

**Reasoning:** The System Architecture Specification treats OEM background-killing as a risk with "no code-only fix" and states that every reliability property must be "designed to survive a device being killed at an arbitrary point" (§9 of that document) — this is precisely the situation where Decision Principle 4's general preference for fewer dependencies is overridden by Decision Principle 3 (survive an arbitrary process kill): the extra native-code investment here is justified specifically because the risk it mitigates is the architecture's own highest-ranked one, and an abstraction plugin between the app and the exact Android foreground-service/battery-optimization APIs would remove precisely the fine-grained control this risk demands. `workmanager` is disqualified outright, not merely disfavored — its scheduling model cannot express the continuous, sub-minute cadence Continuous Telemetry (Domain Specification §5.5, MQTT Specification's adaptive 8s/15s/60s cadence) requires.

**Rejected options:** `flutter_background_service` is a reasonable, widely-used plugin and is rejected narrowly: since native code is already required for the MQTT client (§5.11) and location services (§5.10) for the same underlying reliability reasoning, co-locating the foreground service in that same native module removes an abstraction layer for no loss of Flutter-side convenience that matters at this system's scale.

**Migration considerations:** Native module code is the least portable part of this stack by design; any future migration (e.g., a hypothetical iOS variant — not in current scope, since the Device is Android-only per Product Specification §14) would require an entirely separate native implementation, not a shared one. This is treated as an accepted, scoped cost, not an oversight.

---

### 5.10 Location Services

**Problem:** Telemetry Origination (System Architecture §12.4) needs a location source with the accuracy and background reliability to support the adaptive cadence the platform's telemetry contract defines, running inside the same execution context as the foreground service (§5.9) for reliability reasons already established there.

**Candidates:** Native `FusedLocationProviderClient` (Google Play Services), `geolocator` Flutter plugin, `flutter_background_geolocation` (commercial plugin).

| Candidate | Background reliability | Accuracy/power tuning control | Licensing | Coupling to §5.9's native module |
|---|---|---|---|---|
| **Native FusedLocationProviderClient, in the same native module as §5.9** | Highest — no engine-boundary crossing between the foreground service and the location callback | Full control over priority/interval tuning per the adaptive cadence | Free (Google Play Services) | Natural — same Kotlin code, same lifecycle |
| **geolocator (Flutter plugin)** | Good, but every location callback crosses the Flutter-engine/platform-channel boundary, which is itself a place background-execution problems can surface (an engine that is suspended independently of the native service) | Good, exposed via Dart API | Free, open-source | Would require callbacks to cross back into Flutter even though the foreground service driving the whole cadence is already native (§5.9) — an unnecessary boundary crossing |
| **flutter_background_geolocation** | Very strong, purpose-built for exactly this problem | Strong | Commercial license required | Adds licensing cost and a third-party dependency for a capability the free, native option already covers given §5.9's architecture |

**Decision: Native `FusedLocationProviderClient`, implemented directly inside the same Kotlin foreground-service module selected in §5.9.**

**Reasoning:** Once §5.9 places the foreground service natively, keeping location capture in the same native module avoids a Flutter-engine round-trip for every single location reading at the highest-frequency cadence in the system (as often as every 8 seconds at full fleet scale, per the backend's own telemetry-frequency framing) — a real latency and reliability cost for no benefit, since nothing about location capture needs Flutter/Dart involvement between sensor read and durable-capture handoff. `FusedLocationProviderClient` is Google's own recommended, actively maintained API for this purpose on Android and requires no additional licensing.

**Rejected options:** `flutter_background_geolocation` is a strong, purpose-built commercial product and would be a reasonable choice in a codebase where the foreground service itself were not already native — it is rejected here because §5.9 already establishes native Kotlin as the location capture context, making the commercial plugin's main value proposition (background reliability without writing native code) moot, while its licensing cost remains a genuine downside under Decision Principle 4/5.

**Migration considerations:** Tightly coupled to §5.9; any change to the foreground-service strategy would need to be evaluated jointly with this decision, not independently.

---

### 5.11 MQTT Client

**Problem:** Synchronization & Transport (System Architecture §12.6) must publish `BusPing` and `BusEvent` payloads at QoS 1 (ADR-005), maintain a persistent MQTT session (MQTT Specification §11), and remain resilient across backgrounding and reconnects — all while running inside whatever execution context §5.9 established.

**Candidates:** Native Eclipse Paho Android Client (co-located with §5.9's native module), a pure-Dart MQTT plugin (`mqtt_client`), a Flutter plugin wrapping a native MQTT library.

| Candidate | Session persistence across process restarts | Backend Android-tooling alignment | Execution-context coupling |
|---|---|---|---|
| **Eclipse Paho Android Client, native, co-located with §5.9** | Strong — designed for exactly this: persistent sessions, QoS handling, reconnect logic, proven on Android | Direct — ADR-001 itself names "Mature Android tooling (Eclipse Paho)" as part of the backend's own stated rationale for choosing MQTT at all; the backend's architecture already assumes this client exists on the Android side | Natural — same native module as the foreground service and location capture, no engine-boundary crossing for publish/ack/reconnect events |
| **mqtt_client (pure Dart)** | Workable, but its session and reconnect state lives in the Dart/Flutter engine's process space, which is exactly the execution context most exposed to being suspended independently of a native foreground service | No particular alignment advantage; a general-purpose Dart MQTT library, not Android-tooling-specific | Would reintroduce the same engine-boundary-crossing concern §5.10 avoided, for the system's most reliability-critical transport path |
| **Flutter plugin wrapping a native MQTT library** | Depends on the specific plugin's maintenance quality; introduces a third-party abstraction over exactly the mechanism ADR-008/ADR-005's guarantees depend on | Indirect | Partial — better than pure-Dart, worse than direct native integration with full control |

**Decision: Eclipse Paho Android Client, integrated natively inside the same Kotlin module as the foreground service (§5.9) and location capture (§5.10).**

**Reasoning:** This is the clearest case in this document of a backend ADR directly informing a client-side technology choice: ADR-001 names Eclipse Paho's Android tooling maturity as part of the backend's own justification for choosing MQTT as the transport protocol in the first place, meaning the backend's architecture already assumes a client of Paho's caliber exists on the Android side. Keeping it in the same native module as §5.9 and §5.10 is not merely a convenience — it means the publish/PUBACK/reconnect state machine that Synchronization & Transport (§12.6 of the Architecture Specification) depends on lives in the one execution context (the native foreground service) most likely to survive exactly the OEM-killing scenario the whole system is built around, rather than in the Flutter engine's process space, which has its own, additional suspension risk independent of the native service's.

**Rejected options:** `mqtt_client` (pure Dart) is a legitimate, maintained library and would be simpler to integrate from the Flutter side — it is rejected specifically because its natural home is the Dart/Flutter engine's execution context, reintroducing the engine-boundary-crossing risk this document's native-module strategy (§5.9, §5.10) was built to avoid, for the system's single highest-stakes data path.

**Migration considerations:** Tightly coupled to §5.9 and §5.10 as a single native-module decision; any future re-evaluation should treat all three together, not independently, since their co-location is itself part of the reasoning.

---

### 5.12 HTTP Client

**Problem:** Reference Context Resolution (System Architecture §12.2) and Device registration need a REST client for synchronous, tolerant-of-absence reads (API Specification §21) — a different data-flow shape from the MQTT-based event path (§5.11), living in the Flutter/Dart layer rather than the native module, since these calls are not background-execution-critical in the same way.

**Candidates:** dio, the built-in `http` package, chopper.

| Candidate | Interceptor support (for auth header injection, retry) | Testability | Ecosystem maturity |
|---|---|---|---|
| **dio** | Strong, first-class interceptor chain | Strong — widely used with mock adapters | Mature, actively maintained |
| **http (package:http)** | Minimal — no built-in interceptor concept | Workable, more manual | Mature, but minimal by design |
| **chopper** | Retrofit-style, code-generated | Strong | Smaller community than dio |
| **dio** | | | |

**Decision: dio.**

**Reasoning:** Reference Context Resolution needs consistent handling of the Device's Basic-auth credential (ADR-009's per-request database check on the backend side means every request must carry it correctly) and a bounded-timeout, fail-gracefully-to-cache behavior (API Specification §17's 5-second Postgres timeout framing) — dio's interceptor chain is a direct, idiomatic fit for both concerns without hand-rolling retry/timeout/header logic on top of the bare `http` package. It does not require code generation (unlike chopper), keeping build complexity lower, consistent with Decision Principle 4.

**Rejected options:** `package:http` is rejected only because dio's interceptor model removes enough repetitive plumbing to justify the added dependency; chopper is rejected on the same code-generation-proliferation grounds as auto_route in §5.5 — this codebase already generates code for Drift (§5.6) and Protobuf/json_serializable (§5.13), and every additional generator is a build-time and tooling-maintenance cost.

**Migration considerations:** Low — HTTP client usage is naturally confined to Reference Context Resolution's and Identity's infrastructure adapters (System Architecture §12.1, §12.2), which the Clean Architecture layering (§5.3) already isolates behind ports.

---

### 5.13 Serialization

**Problem:** Two genuinely different wire formats exist on two genuinely different paths — MQTT payloads (`BusPing`, `BusEvent`), which the backend has already fixed as Protobuf (ADR-002), and REST payloads (Trip, Fare Rule, Route Stop reads), which the API Specification defines as JSON. This is a backend-dictated constraint, not a free choice.

**Candidates for the MQTT path:** the official `protobuf` Dart package with `protoc`-generated code (the only real candidate, since the wire format itself is fixed by ADR-002 as Protobuf — this is not an open evaluation).

**Candidates for the REST path:** `json_serializable` (code-generated), manual `fromJson`/`toJson`, `freezed` (adds immutable data-class generation on top of `json_serializable`).

| Candidate (REST path) | Type safety | Boilerplate | Additional dependency beyond `json_serializable` |
|---|---|---|---|
| **json_serializable** | Strong, generated | Low once generated | None |
| **Manual parsing** | Weak — easy to silently drop or mistype a field | High, error-prone | None |
| **freezed + json_serializable** | Strongest — adds immutability, union types, `copyWith` | Lowest boilerplate per model, but adds a second generator | Yes |

**Decision: `protobuf` (Dart, `protoc`-generated) for every MQTT-transported payload; `json_serializable` for every REST-transported payload.**

**Reasoning:** The MQTT-path decision is not this document's to make — ADR-002 already fixes Protobuf as the wire format for `BusPing` and `BusEvent`, and using the official Dart `protobuf` package with generated code from the same `.proto` schema the backend uses is the only choice that keeps the Android client and the Go backend (ADR-002's own consequence: "generated code for both Android (Kotlin) and backend (Go)") speaking the identical schema without hand-maintained drift risk — even though the backend's own generated-code target names Kotlin specifically, this is precisely why §5.9–§5.11 place the MQTT client in a native Kotlin module: the Protobuf-generated Kotlin code and the native Paho client (§5.11) live in the same execution context, avoiding a second Dart-side Protobuf-to-native bridging step entirely. For the REST path, `json_serializable` is selected over manual parsing because compile-time-generated (de)serialization directly reduces the risk of a silently-mistyped field in Reference Context data — a category of bug that would otherwise surface as a confusing runtime failure in exactly the offline-context-resolution path the architecture depends on being trustworthy (System Architecture §12.2).

**Rejected options:** `freezed` is a strong, widely-used pairing with `json_serializable` and is not rejected on technical grounds — it is deferred as an optional, additive enhancement a future Engineering Guidelines document may adopt for REST model ergonomics, rather than fixed here, since it is not required to satisfy any architectural requirement this document is responsible for.

**Migration considerations:** The MQTT-path decision is effectively fixed for as long as ADR-002 stands — a Protobuf-format change would be a backend-initiated event this document would need to react to, not one the ETM side could trigger independently.

---

### 5.14 Local Preferences

**Problem:** A small amount of non-sensitive, non-relational local state — Configuration & Session State (System Architecture §12.9) — needs a lightweight store distinct from Drift's relational/queryable role (§5.6), to avoid overloading the local-storage subsystem with data that doesn't need SQL or reactive-query capability.

**Candidates:** shared_preferences, storing this data in Drift as well, Hive.

| Candidate | Fit for simple key-value data | Adds a dependency beyond §5.6 | Read/write simplicity |
|---|---|---|---|
| **shared_preferences** | Strong — purpose-built for exactly this | Yes, but a very small, first-party-adjacent plugin | Simple |
| **Also using Drift for this data** | Workable, but conflates Configuration & Session State (fully disposable, §14 of the Architecture Specification) with the same store holding non-disposable Ticket/Ping data, weakening the architectural distinction §5.6 was selected partly to enforce | No additional dependency | Requires schema/query overhead for trivial key-value reads |
| **Hive** | Strong for this narrow use, but already rejected in §5.6 for the larger relational role; adopting it only for this smaller role adds a second local-storage technology | Yes | Simple |

**Decision: shared_preferences.**

**Reasoning:** Keeping Configuration & Session State's genuinely disposable, non-relational data in a separate, simpler store than Drift reinforces rather than undermines the architectural distinction §5.6 exists to protect — mixing "the last-known pairing snapshot" into the same schema as "an unsynced Ticket" would make it marginally easier for a future engineer to accidentally treat the two with the same durability assumptions, precisely the confusion Architectural Principles 2 and 3 (System Architecture §8) warn against.

**Rejected options:** Hive is rejected here for the same long-term-support reasoning as §5.6, applied to a smaller surface — introducing a second local-storage engine for a handful of key-value pairs is not justified when shared_preferences already covers the need adequately.

**Migration considerations:** Very low — this subsystem holds no authoritative data (§14 of the Architecture Specification); a migration would cost nothing beyond re-resolving cached values from the backend on next connectivity.

---

### 5.15 Logging

**Problem:** Observability (System Architecture §12.10) needs a structured, durable operational record — capture attempts, durability confirmations, sync outcomes, authorization-state changes, background-execution lifecycle transitions — that survives the same kill-and-restart events the rest of the system is built to survive, without ever becoming load-bearing for correctness (§12.10's own failure boundary).

**Candidates:** the `logger` Dart package with a custom durable sink, `print`/`debugPrint` only, a dedicated structured-logging plugin.

| Candidate | Structured output | Durable persistence across restarts | Overhead |
|---|---|---|---|
| **`logger` + custom rotating file/table sink** | Yes, configurable formatting and log levels | Yes, once paired with a durable sink (a rotating local file, or a low-priority table distinct from Drift's Ticket/Ping tables) | Low, tunable by log level |
| **`print`/`debugPrint` only** | No | No — lost on process death, exactly the failure mode this system needs post-incident visibility into | Minimal, but functionally inadequate |
| **Dedicated structured-logging plugin** | Yes | Varies by plugin | Adds a dependency for a problem `logger` plus a small custom sink already solves |

**Decision: The `logger` Dart package, paired with a durable, rotating local sink.**

**Reasoning:** `print`/`debugPrint`-only logging is disqualified immediately: it disappears exactly when it would be most useful, on the process-kill events this entire architecture is built around surviving (§9 of the Architecture Specification) — a logging strategy that loses its own evidence at the moment of failure fails its one job. `logger` is selected over a dedicated plugin because the actual hard problem here (durable persistence across a kill) is a thin custom sink, not a large library concern — adding a heavier plugin for log formatting alone would not address the part of the problem that actually matters, and would be an unjustified dependency under Decision Principle 4.

**Rejected options:** A dedicated logging-as-a-service plugin (e.g., one bundled with a broader observability vendor SDK) is deferred rather than rejected outright — if Sentry (§5.16) offers adequate structured-breadcrumb capture for this purpose during implementation, the custom durable sink's scope may shrink accordingly; this is flagged as a §11 review trigger, not resolved definitively here.

**Migration considerations:** Low — Observability is explicitly a non-load-bearing subsystem (§12.10 of the Architecture Specification); any logging-technology change carries no correctness risk by construction.

---

### 5.16 Error Reporting

**Problem:** Crash and error visibility is needed for a fleet of devices operating largely out of engineering's direct sight, including crashes that occur while offline — reports must queue locally and upload once connectivity returns, mirroring (at the observability layer) the same offline-tolerance discipline the rest of the system applies to business data.

**Candidates:** Sentry, Firebase Crashlytics.

| Candidate | Offline queuing of crash events | Self-hosting option | Vendor footprint | NDK/native-crash capture (relevant given native modules, §5.9–§5.11) |
|---|---|---|---|---|
| **Sentry** | Yes | Yes — open-source, self-hostable if data residency or vendor-independence ever becomes a concern | Single-purpose SDK, no broader platform suite bundled in | Supported |
| **Firebase Crashlytics** | Yes | No — tied to Google's Firebase platform | Pulls in the broader Firebase SDK surface, more than this system needs given no other Firebase product is selected anywhere in this stack | Strong, mature Android-native support |

**Decision: Sentry.**

**Reasoning:** No other category in this stack selects a Firebase product, so adopting Crashlytics would introduce the Firebase SDK surface into the app for this purpose alone — a footprint cost Decision Principle 4 weighs against when a single-purpose alternative (Sentry) satisfies the same requirement. Sentry's self-hosting option is a meaningful long-term-stability hedge (Decision Principle 7) for a system whose Product Engineering Blueprint explicitly favors a "pre-seed / cost-conscious infrastructure posture" (Blueprint Part 19) and avoiding premature vendor lock-in.

**Rejected options:** Firebase Crashlytics is a mature, credible option and is rejected specifically on footprint and vendor-lock-in grounds, not on crash-capture quality, where the two are close to equivalent.

**Migration considerations:** Low-to-moderate — error-reporting SDKs are typically integrated at a small number of well-defined hook points (global error handlers, native crash handlers in the §5.9–§5.11 module); a vendor swap would not touch domain or application logic.

---

### 5.17 Analytics

**Problem:** Whether a product/usage analytics SDK (event funnels, engagement tracking) belongs in the ETM at all.

**Decision: None at MVP — explicitly out of architectural scope, not merely deferred for convenience.**

**Reasoning:** The Product Specification is direct on this point: "Analytics, historical reporting, fleet-wide visibility" are named Operator Dashboard responsibilities, explicitly out of ETM scope (Product Specification §6), and the System Architecture Specification independently reinforces that "the ETM does exactly two jobs — ticketing and telemetry origination — and nothing else" (Product Specification §13, carried into Architecture Specification §9's system boundaries). A usage-analytics SDK would, by its nature, start collecting data about *how the Conductor uses the app* — a third kind of responsibility this system is deliberately architected not to carry. This is a Decision Principle 8 case: the category is rejected on architectural-scope grounds before any technical comparison is even relevant.

**Rejected options:** Firebase Analytics, Mixpanel, and Amplitude were all considered and rejected identically, for the scope reason above rather than any technical differentiation between them.

**Migration considerations:** None — there is no analytics integration to migrate away from. If a future product decision genuinely expands ETM scope to include Conductor-usage analytics, that would be a Product Specification change first, and only then a technology decision for this document to make.

---

### 5.18 Printing Integration

**Problem:** Whether the ETM needs a receipt-printing integration.

**Decision: Deferred — out of MVP scope, not a technology gap.**

**Reasoning:** The Product Specification names "dedicated ETM hardware, receipt printing, ticket media" as explicitly later-phase, per the platform's own roadmap (Product Specification §6, §19 — V3). No workflow in the Workflow Specification references a print step anywhere in Ticket Issuance (Workflow §9). Evaluating specific Bluetooth-printer SDKs now would be speculative work against a requirement that does not exist yet, which Decision Principle 7 and the Product Engineering Blueprint's own "defer complexity until a measured need justifies it" principle (Blueprint Part 15) both argue against.

**Rejected options:** None evaluated — no candidates were compared, deliberately, since the category itself is not yet active.

**Migration considerations:** When this becomes active (Product Specification's V3), it will require its own category-5 evaluation against whatever specific printer hardware the Operator Admin's hardware roadmap selects — not resolved here.

---

### 5.19 Barcode / QR

**Problem:** Whether the ETM needs barcode/QR scanning or generation capability.

**Decision: Deferred — out of MVP scope.**

**Reasoning:** No entity in the Domain Specification (Ticket, §5.4) carries a barcode or QR representation at MVP — a Ticket is a data record, not a printed or scannable medium, since ticket media itself is named as a later-phase capability alongside printing (§5.18, Product Specification §6). There is nothing for a barcode/QR library to scan or generate yet.

**Rejected options:** None evaluated, for the same reason as §5.18.

**Migration considerations:** Coupled to §5.18 — likely to become relevant at the same roadmap stage (V3), and worth evaluating jointly with the printing decision at that time, since ticket media and QR-based validation are a natural pairing.

---

### 5.20 Maps

**Problem:** Whether the ETM needs a map-rendering SDK.

**Decision: Not required at MVP.**

**Reasoning:** Live fleet-map visualization is an Operator Dashboard responsibility (Product Specification §6, §9); the ETM's own boarding/destination selection during Ticket Issuance is against a cached, ordered Route Stop list (Domain Specification §5.7, Workflow §9) — a list-selection interaction, not a spatial one. No document in the reviewed set describes the Conductor viewing a map on the ETM itself.

**Rejected options:** None evaluated — no map-rendering requirement exists to compare candidates against.

**Migration considerations:** If a future feature introduces map-based stop selection or Conductor-visible live position, this category would need a full evaluation (Google Maps Flutter plugin vs. Mapbox vs. others) against criteria not yet defined — flagged as an open dependency, not resolved here.

---

### 5.21 Image Handling

**Problem:** Whether the ETM needs an image-capture or image-display subsystem.

**Decision: Not required at MVP.**

**Reasoning:** No workflow (Workflow Specification §5–§17) or domain entity (Domain Specification §5) names any image, photo, or visual-media capture or display requirement anywhere in the ETM's scope.

**Rejected options:** None evaluated.

**Migration considerations:** None currently foreseeable from the reviewed specification set.

---

### 5.22 Connectivity Monitoring

**Problem:** Synchronization & Transport's trickle-sync trigger requires **both** genuine network connectivity **and** a confirmed broker session (MQTT Specification §12: "`NetworkMonitor.isOnline == true` **and** the broker connection is confirmed") — a coarse "is the device online" signal alone is insufficient and, used alone, would risk attempting sync when only the network layer, not the broker session, is actually ready.

**Candidates:** connectivity_plus (Dart plugin, coarse network-state signal) combined with the native MQTT module's (§5.11) own broker-session state; connectivity_plus alone; a native-only connectivity check.

| Candidate | Detects network-interface state | Detects broker-session state | Matches the two-condition trigger the backend contract requires |
|---|---|---|---|
| **connectivity_plus + native broker-session state (combined)** | Yes (connectivity_plus) | Yes (native module, §5.11, already tracks Paho's connection lifecycle) | Yes — exactly the two-condition check MQTT Specification §12 describes |
| **connectivity_plus alone** | Yes | No | No — would treat "has cellular signal" as sufficient, which the backend's own contract explicitly says is not the same as "broker connection confirmed" |
| **Native-only connectivity check** | Yes, via native Android `ConnectivityManager` | Yes | Workable, but duplicates functionality connectivity_plus already provides for the Dart-side UI (which also needs to display connectivity state to the Conductor, an honesty obligation per Product Specification §18) |

**Decision: connectivity_plus for the Dart-side/UI-facing network-state signal, combined with the native module's own broker-session state (already tracked as part of §5.11's MQTT client integration) as the authoritative gate for triggering sync.**

**Reasoning:** This decision directly implements a backend contract, not a free architectural choice — MQTT Specification §12 is explicit that both conditions are required, and using only one would risk exactly the failure mode that section calls out (a device with cellular signal but no negotiated broker session attempting to publish). connectivity_plus is retained for the Dart/UI layer specifically because Sync-Status Honesty (System Architecture §12.8) needs a connectivity signal to help represent staleness and sync state to the Conductor honestly (Product Specification §18) — a UI concern distinct from, but informed by, the same underlying fact the native module also tracks for its own gating purposes.

**Rejected options:** connectivity_plus alone is rejected as functionally insufficient against the backend's own stated two-condition requirement, not as a poor library.

**Migration considerations:** Low for the Dart-side signal; any change to the native broker-session tracking is coupled to §5.11's migration profile.

---

### 5.23 Testing Framework

**Problem:** Every layer of the Clean Architecture (§5.3) — domain logic, application-layer orchestration, and presentation — needs to be exercisable in fast, hermetic tests, per Decision Principle 6 and the System Architecture Specification's own testability goal (§4 of that document).

**Candidates:** `flutter_test` (built-in widget/unit testing), Dart's own `test` package (pure-Dart unit testing, no Flutter dependency), `integration_test` (on-device/emulator end-to-end testing).

**Decision: Dart `test` for domain-layer unit tests (deliberately Flutter-independent, matching §5.3's framework-agnostic domain layer), `flutter_test` for widget/presentation-layer tests, and `integration_test` for on-device flows spanning the native modules (§5.9–§5.11) that cannot be meaningfully exercised in a pure-Dart or widget-only test.**

**Reasoning:** Using the plain Dart `test` package for domain logic — rather than `flutter_test` for everything — is a direct, deliberate reinforcement of §5.3's architectural requirement that the domain layer have zero Flutter/Android dependency: if domain-layer tests required the Flutter test harness to run, that would itself be evidence the domain layer had accreted a framework dependency it shouldn't have. `integration_test` is necessary specifically because §5.9–§5.11's native modules (foreground service, location, MQTT) cannot be adequately verified by widget or pure-Dart tests alone — their correctness depends on real Android platform behavior.

**Rejected options:** No serious alternative exists for the Flutter-specific layers; these are the Flutter team's own first-party testing tools, and Decision Principle 7 favors them over any third-party alternative for exactly that reason.

**Migration considerations:** Minimal — testing-framework choices are the lowest-migration-cost category in this document, since tests are not shipped, runtime code.

---

### 5.24 Mocking Strategy

**Problem:** Domain and application-layer tests (§5.23) need to substitute fake implementations for infrastructure-layer ports (Durable Capture, Synchronization, Reference Context resolution) without invoking real storage, network, or native modules.

**Candidates:** `mocktail` (no code generation), `mockito` (code-generation-based).

| Candidate | Code generation required | Null-safety ergonomics | Fit given other generators already in use (§5.6, §5.13) |
|---|---|---|---|
| **mocktail** | No | Strong, designed post-null-safety | Adds no additional `build_runner` burden |
| **mockito** | Yes, for the strongest type-safety mode | Workable, retrofitted for null safety | A third `build_runner` generator alongside Drift and Protobuf/json_serializable |

**Decision: mocktail.**

**Reasoning:** This codebase already depends on `build_runner` code generation for Drift (§5.6) and json_serializable (§5.13); adding mockito's generation step for mocking specifically would be a third generator solving a problem mocktail solves without one, a direct Decision Principle 4 consideration. mocktail's null-safety-native design fits cleanly with the sound-null-safety rationale already established for the language choice itself (§5.1).

**Rejected options:** mockito is a mature, credible library and is rejected narrowly on the code-generation-proliferation grounds stated above, not on mocking-capability grounds.

**Migration considerations:** Very low — confined entirely to test code, with no production-code impact.

---

### 5.25 Build System

**Problem:** The Android build needs to support environment-specific configuration (dev/staging/prod, per the Deployment Architecture's environment strategy) and integrate cleanly with the native Kotlin modules (§5.9–§5.11) alongside the Flutter/Dart application code.

**Decision: Flutter's standard Gradle-based Android build, using Gradle's Kotlin DSL (rather than the Groovy DSL), with product flavors mapping to dev/staging/prod.**

**Reasoning:** Gradle is not an open evaluation — it is the only build system Flutter's Android target supports natively; the decision here is Kotlin DSL over Groovy DSL specifically, chosen for consistency with the Kotlin already required for the native modules (§5.9–§5.11), giving the team one JVM-ecosystem language across all native build and module code rather than two (Kotlin for modules, Groovy for build scripts) — a Decision Principle 4-consistent simplification. Product flavors are the standard, well-supported Android mechanism for the multi-environment configuration the Deployment Architecture already requires backend-side (its own environment strategy), and reusing that mechanism here rather than inventing a Flutter-only equivalent avoids duplicating a solved problem.

**Rejected options:** Groovy DSL is rejected narrowly on language-consistency grounds, not functional grounds — both DSLs are fully supported by Gradle.

**Migration considerations:** Low — build-script language choice does not affect application logic or architecture; a future migration between DSLs is a mechanical, low-risk change.

---

### 5.26 CI/CD Considerations

**Problem:** Automated build, test, and release-candidate generation is needed for a small team without dedicated release engineering (Product Engineering Blueprint Part 19).

**Candidates:** GitHub Actions, Codemagic (Flutter-specialized CI), Bitrise.

| Candidate | Fit with existing infrastructure | Flutter-specific tooling maturity | Cost profile for a small, single-platform (Android-only) team |
|---|---|---|---|
| **GitHub Actions** | Strong — the backend's own network/deployment configuration already reflects a GitHub-centric workflow (source hosting, package registries) | Good — official and community Flutter actions are mature and well-maintained | Generous free tier at this scale, no new vendor relationship |
| **Codemagic** | New vendor relationship | Very strong, purpose-built for Flutter (including iOS signing automation this project doesn't need, since the Device is Android-only) | Adds a paid, Flutter-specialized vendor for capability (iOS pipeline sophistication) this project does not currently need |
| **Bitrise** | New vendor relationship | Strong, general mobile CI | Similar cost/relationship profile to Codemagic |

**Decision: GitHub Actions.**

**Reasoning:** Consistent with the backend's own apparent GitHub-centric posture and Decision Principle 5 (boring, proven technology), GitHub Actions avoids introducing a new vendor relationship for a capability a general-purpose CI platform already provides adequately at this project's current scale — the Android-only (Product Specification §14: operator-provisioned Android hardware, no iOS target) scope specifically removes the one area (iOS build/signing orchestration) where a Flutter-specialized CI vendor's advantage over GitHub Actions would be most pronounced.

**Rejected options:** Codemagic and Bitrise are both credible, mature options and are rejected on cost/vendor-relationship grounds specific to this project's Android-only scope and small-team posture, not on technical capability.

**Migration considerations:** Moderate — CI pipeline definitions are workflow-specific but not deeply embedded in application code; a future migration to a Flutter-specialized CI vendor remains straightforward if release complexity grows (§11).

---

### 5.27 Release Strategy

**Problem:** Provisioned Android devices need a controlled, staged release mechanism, given the Product Specification's own risk framing (a defect reaching the whole pilot fleet at once is a materially worse outcome than reaching a small percentage first).

**Decision: Google Play, using staged/percentage rollout, distributed as an Android App Bundle (AAB) rather than a universal APK, with internal-testing and closed-testing tracks preceding production for the single-operator pilot (Product Specification §19, MVP stage).**

**Reasoning:** AAB is Google Play's required and recommended format for new app publication and produces smaller, device-optimized downloads — directly relevant given the constrained cellular bandwidth this entire system is built around (Product Specification §14). Staged rollout is a direct mitigation for the same class of risk ADR-006 and ADR-007 name at the backend layer (an operational cost, stated plainly, not hidden) — a defect in a build pushed to 100% of a pilot fleet simultaneously would be a materially worse operational event than one caught at a 5–10% rollout stage, on hardware that is often out of easy physical reach (rural, hill-terrain deployment, Product Specification §14).

**Rejected options:** A universal APK sideloading strategy (bypassing Google Play entirely) was considered, given the operator-provisioned, non-consumer nature of the device fleet — it is rejected because it would forfeit Play's staged-rollout, crash-rate-gated rollout halting, and update-delivery infrastructure, all of which directly serve this system's own reliability principles for no offsetting benefit at this fleet's scale.

**Migration considerations:** Low — release-channel strategy is independent of application architecture and can evolve (e.g., a private enterprise distribution channel, if operator requirements change) without touching code.

---

### 5.28 Crash Recovery Support

**Problem:** Beyond the storage-engine-level transactional guarantees already established in §5.6, this category asks what the *application and OS-level* crash-recovery posture should be — how the app resumes correctly after a kill, distinct from how a single write is protected.

**Decision: SQLite WAL mode (already selected in §5.6) as the storage-level crash-safety mechanism, combined with the foreground service's `START_STICKY` restart semantics (§5.9) as the process-level recovery mechanism — no additional crash-recovery library is introduced.**

**Reasoning:** This category is deliberately not treated as requiring a new technology — it is the composition of two decisions already made for independent reasons (§5.6's WAL mode, §5.9's `START_STICKY`), and naming that composition explicitly here is what closes the loop the System Architecture Specification's Failure Isolation section (§16 of that document) describes: a killed process loses no durable data (§5.6) and is restarted promptly by the OS where possible (§5.9), and Synchronization resumes by reading Durable Capture's state fresh on restart (Architecture Specification §13's Reconnection/Recovery interaction), never from assumed in-memory state. No third library is needed because the recovery guarantee is a property of how §5.6 and §5.9 are used together, not a separate mechanism.

**Rejected options:** A dedicated "crash recovery" framework or library was not identified as solving a problem not already covered by the composition above — evaluating one would be adding a dependency in search of a problem, which Decision Principle 4 argues against.

**Migration considerations:** None distinct from §5.6 and §5.9's own migration profiles.

---

### 5.29 Performance Monitoring

**Problem:** Runtime performance characteristics (frame timing, app-start latency, potentially battery/resource usage trends) need visibility across a fleet of devices engineering cannot physically inspect.

**Candidates:** Sentry Performance (same vendor as §5.16), Firebase Performance Monitoring, a standalone APM tool.

**Decision: Sentry Performance, using the same Sentry integration already selected for error reporting (§5.16).**

**Reasoning:** Given Sentry is already the selected vendor for crash/error reporting (§5.16), and it offers a performance-monitoring module within the same SDK and account, adding it is a configuration change rather than a new vendor integration — directly serving Decision Principle 4. Introducing Firebase Performance Monitoring instead would reintroduce the Firebase-footprint objection already raised and rejected in §5.16, for a closely related capability.

**Rejected options:** Firebase Performance Monitoring is rejected for the same reason Firebase Crashlytics was in §5.16. A standalone APM tool was not seriously considered given this system's scale does not warrant a dedicated APM product's cost and operational overhead.

**Migration considerations:** Coupled to §5.16's migration profile.

---

### 5.30 Configuration Management

**Problem:** Build-time configuration (API base URL, Sentry DSN, and any other value that legitimately differs per environment — dev/staging/prod) must be supplied without committing secrets to source control and without bundling them in a form easily extracted from a lost or stolen device (a named platform risk, Product Specification §17).

**Candidates:** `flutter_dotenv` (bundles a `.env` asset file into the app), Dart's `--dart-define` / `--dart-define-from-file` compile-time constants integrated with Gradle build flavors (§5.25).

| Candidate | Secrets committed to source | Secrets present as an extractable plaintext asset in the shipped app | Integration with build flavors (§5.25) |
|---|---|---|---|
| **flutter_dotenv** | Avoidable via `.gitignore`, but the `.env` file still ships as a plaintext asset bundled into the release APK/AAB, readable by unpacking the archive | Yes — this is exactly the extractable-plaintext-on-a-lost-device risk Product Specification §17 names generally | Indirect — flavor-awareness has to be layered on manually |
| **`--dart-define-from-file` + Gradle flavors** | Values supplied at build time from CI secrets, never committed | No — values are compiled as Dart constants, not shipped as a separately readable asset file | Direct — flavor and compile-time-constant selection compose naturally in the same Gradle build step |

**Decision: `--dart-define-from-file`, sourced from CI-managed secret files per environment, composed with the Gradle product flavors already established in §5.25.**

**Reasoning:** `flutter_dotenv`'s core mechanism — bundling a `.env` file as a shipped asset — is a poor fit specifically because this device class is explicitly named as at-risk of loss or theft mid-shift (Product Specification §17); a plaintext, unpackable configuration asset on that device class is a real, named-risk-adjacent exposure this document declines to accept when a compile-time-constant alternative exists that avoids shipping the values as an extractable file at all. `--dart-define-from-file` composes directly with the flavor-based build already selected in §5.25, giving one coherent per-environment configuration mechanism rather than two loosely-coordinated ones.

**Rejected options:** `flutter_dotenv` is rejected specifically on the device-loss-risk grounds above, not on general unsuitability — it would be a reasonable choice for a consumer app on a personally-controlled device, which this is explicitly not (Product Specification §14: "operator-provisioned... not conductors' personal phones").

**Migration considerations:** Low — configuration-supply mechanism is orthogonal to application logic; values themselves (URLs, DSNs) are already expected to change per environment as a matter of course.

---

## 6. Comparison Tables

Per-category comparison tables are embedded directly within each evaluation in §5, adjacent to the decision they inform, rather than repeated in a separate consolidated section — this keeps each comparison legible against the specific criteria that category actually needed, consistent with the Evaluation Methodology's (§3) instruction to discuss only criteria materially relevant to each decision.

## 7. Final Decisions

The Technology Stack Overview (§4) is this document's authoritative, confirmed decision list. Every entry there is binding as of this document's version — a future change to any row requires either a new revision of this document or an explicit superseding entry, per this document's own Status statement.

Two structural groupings are worth stating explicitly, since they recur across §5's reasoning and are easy to lose sight of entry-by-entry:

- **The native module cluster (§5.9, §5.10, §5.11)** — Background Execution, Location Services, and MQTT Client are one coordinated decision, co-located in a single native Kotlin module for the reliability reasons stated in each. They should be reviewed together, never independently.
- **The Flutter/Dart application cluster (§5.1–§5.8, §5.12–§5.30, excluding the native cluster above)** — everything else in this stack lives in the Dart/Flutter layer, composed through Riverpod (§5.4, §5.8) over a Clean Architecture layering (§5.3).

## 8. Stack Compatibility Matrix

| Layer | Technology | Compatible with backend constraint | Governing ADR/spec |
|---|---|---|---|
| Wire format (MQTT path) | `protobuf` (Dart), Kotlin-generated code in the native module | Matches backend's Go-side generated code from the same `.proto` schema | ADR-002 |
| Transport (MQTT path) | Eclipse Paho Android Client, QoS 1 | Matches backend's broker (Mosquitto/EMQX) and QoS contract | ADR-001, ADR-005, ADR-006 |
| Delivery ordering/dedup | `client_timestamp`-keyed records in Drift, consumed by Synchronization | Matches backend's server-received-time ordering and dedup-key design | MQTT Specification §13–§14, Database Specification §9.4 |
| Wire format (REST path) | `json_serializable` (Dart) | Matches API Specification's JSON convention | API Specification §9–§10 |
| Device authentication | flutter_secure_storage-held credential, presented via dio interceptor on every REST call, and via the native Paho client's connection parameters on MQTT | Matches ADR-009's per-request Basic-auth, database-checked-every-request device scheme | ADR-009, MQTT Specification §18 |
| Authorization-failure handling | Identity & Authorization Awareness (Riverpod provider) treats any denial as fail-closed, per §17 of the Architecture Specification | Matches the backend's own fail-closed posture | ADR-007, ADR-009 |
| Local durability | Drift/SQLite WAL, write-before-network ordering enforced at the application layer | Matches ADR-008's ordering requirement, restated client-side | ADR-008 |
| Reference-context caching | Drift tables, distinct from Ticket/Ping tables, always treated as disposable | Matches ADR-013's cache-is-never-authoritative principle, applied to client-side cached reads | ADR-013, System Architecture §14 |

## 9. Risks

Beyond the per-category risks already named in §5, three cross-cutting risks apply to the stack as a whole:

- **The native-module cluster (§5.9–§5.11) is the stack's highest-maintenance-burden component**, since it is hand-written Kotlin rather than a maintained third-party plugin — this is an accepted, deliberate trade-off (each category's own reasoning states why), but it means the team carries direct maintenance responsibility for exactly the part of the stack most sensitive to Android platform-version changes (foreground-service and battery-optimization API behavior shifts across Android releases historically). This risk should be weighed explicitly against Android OS updates as part of the review triggers in §11.
- **A `build_runner`-based code-generation pipeline (Drift, Protobuf, json_serializable) is now a build-time dependency across most of the stack** — a `build_runner` ecosystem regression or breaking change would affect multiple categories simultaneously rather than one in isolation, since the decision to avoid *additional* generators (§5.5, §5.8, §5.24) concentrated generation into these three rather than spreading it thinner.
- **Sentry as a single vendor now covers both error reporting (§5.16) and performance monitoring (§5.29)** — a deliberate consolidation under Decision Principle 4, but it means a Sentry-specific outage or service change affects two observability categories at once rather than one.

## 10. Migration Strategy

This document does not propose migrating any decision proactively — every entry in §4 is the current, binding choice. This section states *how* a migration would be approached, if a review trigger (§11) is ever met:

1. **A migration is scoped to the smallest coupled group a decision belongs to** (§7's groupings) — the native-module cluster is never migrated piecemeal; the Flutter/Dart application-layer decisions are each migrated independently where §5's own migration-considerations note allows it.
2. **The domain layer (§5.3) is the intended stability anchor for any migration.** Because it depends on no framework or infrastructure technology by construction, a migration in any infrastructure-layer category (storage, transport, HTTP client) should never require domain-layer changes — if it does, that is itself a signal the dependency-inversion boundary (System Architecture §8, Principle 6) has been violated somewhere and needs correcting before the migration proceeds.
3. **Local-storage migrations (§5.6) require an explicit field-data migration path** for any Device holding unsynced records at the moment of upgrade — no local-storage technology change is considered "complete" without this, given §5.6's own stated reasoning for why this category's migration cost is treated as a deliberate deterrent, not merely a cost to minimize.
4. **A vendor-technology migration (Sentry, GitHub Actions, Google Play) is evaluated against Decision Principle 5 and 7 before being executed** — vendor changes should be justified by a genuine capability or cost gap, not novelty.

## 11. Future Review Triggers

A decision in this document should be revisited only when one of the following becomes true — not on a fixed calendar cadence, mirroring the backend's own capability-driven (not calendar-driven) migration philosophy (ADR-006):

- **A measured field-pilot result contradicts an assumption a decision here relied on** — for example, if real dead-zone durations or backlog sizes (System Architecture §18) reveal Drift/SQLite storage growth becoming a genuine device-storage constraint, triggering a §5.6-adjacent retention-policy decision (already flagged as an open question, System Architecture §23, item 3).
- **Android platform changes materially affect the native-module cluster's (§5.9–§5.11) viability** — a new OS-level background-execution restriction with no accommodation would be exactly this kind of trigger, and is the single most plausible reason this document would need a near-term revision given §9's own risk framing.
- **The ETM's scope changes at the Product Specification level** — most directly, §5.17 (Analytics), §5.18 (Printing), §5.19 (Barcode/QR), and §5.20 (Maps) are all scope-gated, not technology-gated, and should be revisited the moment their governing Product Specification section changes, not before.
- **A single-vendor consolidation risk (§9) materializes** — a sustained Sentry service disruption or an adverse pricing/policy change would trigger re-evaluation of §5.16/§5.29 specifically.
- **Team composition changes materially** — Decision Principle 7's "small team" framing is a real input to several decisions (notably §5.1–§5.2, §5.26); a materially larger or differently-skilled team could change the balance those decisions struck.

## 12. Platform Dependencies

This document depends on, and must never contradict:

- **ETM System Architecture Specification** — every subsystem referenced throughout §5 (§12.1–§12.10 of that document) is this document's technology-selection target; no decision here may satisfy a requirement that document does not state.
- **ETM Product/Domain/Workflow Specifications** — the scope boundaries (§5.17–§5.21) and risk framing (§5.9, §5.27, §5.30) drawn on throughout.
- **Product Engineering Blueprint** — Part 15 (Engineering Principles: boring technology, defer speculative complexity), Part 19 (Product Constraints: small-team execution, cost-conscious infrastructure posture).
- **Architecture Review** — §9 (offline-first architecture, OEM background-execution risk), §16 (layered reliability philosophy), §17 (backend technology-decision index, the direct model for this document's own per-category format).
- **ADR-001, ADR-002** (the direct source of §5.11's and §5.13's MQTT/Protobuf client-side decisions); **ADR-005** (QoS 1, informing §5.11 and §5.22); **ADR-006** (Mosquitto/EMQX phasing — the model for this document's own capability-triggered, not calendar-triggered, review philosophy in §11); **ADR-007, ADR-009** (fail-closed and dual-authentication, informing §5.7's and §5.22's reasoning); **ADR-008** (LocalBuffer ordering — the direct model for §5.6's and §5.28's reasoning); **ADR-011** (unified reliability model — the reason §5.6, §5.9–§5.11 treat Ticket and Telemetry capture as sharing infrastructure); **ADR-013** (cache-never-authoritative — informing §5.6's and §5.14's Reference-Context-vs-Durable-Capture distinction).
- **API Specification** §17, §21 (REST timeout/staleness framing informing §5.12; offline sync having no REST role, confirming §5.11/§5.6 as the correct locus for sync logic, not §5.12).
- **MQTT Specification** §11–§18 (session persistence, offline buffering, retry strategy, connection lifecycle, authentication — the direct technical basis for §5.6, §5.9–§5.11, §5.22).
- **Deployment Architecture** §9.1 (the Android Conductor Device's external communication boundary, constraining §5.11/§5.12 to MQTT broker and API service only, consistent with the System Architecture Specification's own §7).

## 13. Open Technical Questions

1. **What is the actual field-measured storage growth profile under a worst-case dead zone**, and does it require a retention/pruning policy for synced records sooner than anticipated? (§5.6, §9, §11) — not resolved here; requires field-pilot data the Product Specification itself names as not yet measured (Product Specification §17, §21).
2. **Should `freezed` be adopted alongside `json_serializable` (§5.13) for REST-model ergonomics?** Deferred as a non-architectural, additive question for a future Engineering Guidelines document.
3. **Should Observability's (§5.15) custom durable log sink be subsumed into Sentry's breadcrumb capture (§5.16), reducing custom code?** Flagged in §5.15 as a decision to make once implementation reveals how much of the requirement Sentry's own capture actually satisfies.
4. **What Android OS/API-level range must the native foreground-service and battery-optimization-exemption flow (§5.9) actually support**, given the operator-provisioned hardware's likely multi-year, mixed-Android-version field life (Product Specification §14)? This document fixes the *technology* (native foreground service) but not the specific minimum-API-level support matrix, which depends on hardware-procurement decisions outside this document's scope.
5. **Does the eventual introduction of a Conductor self-identification mechanism (System Architecture §19, §23 item 5) require any new technology category**, or does it compose entirely within Identity & Authorization Awareness's existing technology choices (§5.4, §5.7)? Provisionally assessed as the latter, but not conclusively resolved until that feature is actually specified.

---

*End of NammaRoute Conductor ETM Technology Decisions v1.0.*
