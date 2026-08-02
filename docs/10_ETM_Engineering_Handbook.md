# NammaRoute Conductor ETM — Engineering & Implementation Handbook
### `docs/10_ETM_Engineering_Handbook.md`

**Document type:** Engineering & Implementation Handbook — the bridge between the approved ETM specifications and the Flutter codebase. It defines *how* engineers implement the already-approved architecture and technology decisions consistently. It does not define product behaviour, does not redefine workflows, and does not redesign architecture or select technology.
**Position in the hierarchy:** Derives from, and must never contradict, `01_ETM_Product.md`, `02_ETM_Domain.md`, `03_ETM_Workflows.md`, `04_ETM_System_Architecture.md`, `05_ETM_Technology_Decisions.md`, `06_ETM_Reliability.md`, `07_ETM_Data_Contracts.md`, `08_ETM_Features.md`, `09_ETM_UI_UX_and_Screens.md`, and every backend ADR. Where this document appears to add a rule, it is translating one of those documents into engineering practice — it never invents a new architectural boundary, technology, or business rule.
**Status:** Living document. Changes when engineering practice needs to change, never as a way to quietly re-open a decision one of the documents above already made.

---

## 1. Purpose

A new Flutter engineer joining the ETM project can read this document once and know: which folder a piece of code belongs in, which layer may depend on which, how state is owned and exposed, how a repository or service is expected to behave, how errors are classified and handled, what a test suite must cover before a feature is called done, and what a code reviewer checks for. This document exists so ten engineers, over several years and staff turnover, produce a codebase that still looks like one person wrote it — because it was written against one shared discipline, not ten individually reasonable but divergent ones.

This document does not repeat the reasoning already recorded upstream. Where a rule below exists, it exists because a specific upstream document requires it; the citation is the justification, and re-arguing it here would only invite drift between two copies of the same idea.

## 2. Engineering Principles

Carried directly from the approved specifications, restated as engineering conduct rather than architectural or product reasoning:

1. **A durable write is never made contingent on anything else being healthy.** The single most important rule in this codebase. Identity, Reference Context, Synchronization, or the network being broken must never be a reason a Ticket or Telemetry Ping fails to reach durable local storage (ADR-008; System Architecture §12.5).
2. **Two kinds of local data exist, and they are never mixed.** Durable Capture data (unsynced Tickets, unsynced Pings) is not disposable. Everything else — Reference Context, Configuration & Session State, diagnostics — is always disposable (System Architecture §8, Principles 2–3; §14). An engineer who is unsure which kind a new piece of data is must resolve that question before writing a single line of storage code, not after.
3. **The domain layer has zero Flutter, Android, or infrastructure dependency.** If a domain-layer class imports `flutter/material.dart`, a Drift table, or a platform channel, that is a defect, not a style nit (System Architecture §11; Technology Decisions §5.3).
4. **Dependency direction is inward, always.** Infrastructure depends on application; application depends on domain; domain depends on nothing beneath it. A dependency pointing the other way is never an acceptable shortcut, regardless of deadline pressure (System Architecture §11, Architectural Principle 6).
5. **State has exactly one owner.** Before writing a provider that tracks "is this synced," "are we authorized," or "how stale is this," check whether an owning subsystem already exposes that fact. A second, independently-derived copy of the same fact is a defect the moment it's written, not something to reconcile later (System Architecture §15).
6. **Fail closed on authorization; fail honest everywhere else.** Code must never collapse "not authorized" into the same handling path as "no connectivity," and must never represent a status the ETM cannot actually verify as though it were confirmed (ADR-007; System Architecture §8, Principle 9; Reliability §4, Principle 6).
7. **Duplicate delivery is routine, not exceptional.** Every consumer on the capture-to-sync path is written assuming a record may be transmitted more than once; idempotence is a base requirement of the code, not a follow-up hardening pass (ADR-005; Reliability §4, Principle 4).
8. **A shared mechanism serves both Ticketing and Telemetry.** Do not build a second durability, transport, retry, or recovery path "just for tickets" or "just for telemetry" — one mechanism, two payload types (ADR-011; System Architecture §10).
9. **Boring, proven, minimal.** A new dependency is guilty until proven necessary; a library that duplicates what an already-selected one does adequately is rejected (Technology Decisions, Decision Principle 4–5).
10. **The engineer's job is to implement the guarantee, not to renegotiate it.** If a rule in this handbook seems to make a feature harder to build than skipping it would, the correct response is to ask whether the implementation is missing something the specification already accounted for — not to quietly relax the rule.

## 3. Project Organization

### 3.1 Top-level structure

The codebase is organized as **feature-sliced modules over a shared hexagonal core**, matching System Architecture §6 exactly — this is not a free implementation choice, it is the direct realization of an already-approved architecture:

```
lib/
  core/                     # Shared Edge-Event Core + cross-cutting concerns
    domain/                 # Ticket/Ping-agnostic domain primitives shared across features
    capture/                # Durable Capture — the ETM's LocalBuffer analog
    sync/                   # Synchronization & Transport
    background/             # Background Execution & Device Lifecycle Management
    diagnostics/            # Sync-Status & Reconciliation Honesty, Observability
    config/                 # Configuration & Session State
  features/
    identity/               # Identity & Authorization Awareness
    reference_context/      # Reference Context Resolution
    ticketing/               # Ticket Capture & Validation
    telemetry/               # Telemetry Origination
  app/                      # Composition root, routing, app-level bootstrap
  platform/                 # Platform-channel contracts to the native module
native/
  android/                  # Kotlin: foreground service, location, MQTT client (co-located, §5.9–§5.11)
```

Each entry above maps to exactly one subsystem named in System Architecture §12 or one feature module named in §10 of that document. There is no folder in this tree that does not have a named owner upstream — if a piece of code doesn't obviously belong in one of these, that is a signal the responsibility itself hasn't been assigned yet, and the question is resolved by checking §12 of the System Architecture Specification, not by picking a folder that seems close enough.

### 3.2 Module responsibilities

- **`core/capture`** — the single implementation of Durable Capture (§12.5). Both Ticketing and Telemetry write through this module's port; neither feature module implements its own local-durability logic. This module has no dependency on any other module in the tree, by design (System Architecture §12.5, "Dependencies: None").
- **`core/sync`** — the single implementation of Synchronization & Transport (§12.6). Drains `core/capture`'s pending records, independently per event-type partition, gated on Identity's authorization state and on connectivity/session-readiness. Owns no business-validation logic.
- **`core/background`** — the platform-channel bridge to the native foreground-service/location/MQTT module (Technology Decisions §5.9–§5.11). Nothing outside this module and `native/android` should reference Android lifecycle APIs directly.
- **`core/diagnostics`** — the single implementation of Sync-Status & Reconciliation Honesty and Observability (§12.8, §12.10). Read-only over every other subsystem's state; writes nothing anywhere else.
- **`core/config`** — Configuration & Session State (§12.9). A passive store; holds no authoritative data.
- **`features/identity`** — Device credential custody and authorization-state tracking (§12.1). The root of trust; depends on nothing else in the tree.
- **`features/reference_context`** — resolution and caching of Trip, Fare Rule, Route Stop, Bus, and Conductor pairing (§12.2). Depends on `features/identity` only.
- **`features/ticketing`** — Ticket business validation and capture orchestration (§12.3). Depends on `features/reference_context`, `features/identity`, and `core/capture` — never on `core/sync` directly (a Ticket's job ends at Durable Capture; synchronization is `core/sync`'s concern, not this module's).
- **`features/telemetry`** — Ping capture orchestration (§12.4). Depends on `core/capture` and `features/identity` only — deliberately independent of `features/reference_context` and `features/ticketing` (Workflow §4; System Architecture §12.4).
- **`app`** — the Riverpod composition root, `go_router` route table, and app bootstrap. This is the only place where concrete infrastructure implementations are bound to the abstract ports the domain and application layers depend on.
- **`platform`** — Dart-side platform-channel method/event-channel contracts. Contains no business logic; it is a typed bridge, nothing more.

### 3.3 What does not get its own module

Analytics, printing, barcode/QR, maps, and image handling have no module because they have no MVP responsibility (Technology Decisions §5.17–§5.21). Do not scaffold empty modules for these in anticipation of future work — an empty module with no owning subsystem is a structure with nothing to keep it honest, and it will accrete the wrong things over time.

## 4. Layer Responsibilities

Every module that touches capture (`core/capture`, `core/sync`, `features/ticketing`, `features/telemetry`) is internally layered exactly as System Architecture §11 describes. This layering is mandatory in every such module, not a suggestion for the ones that happen to be complex enough to want it.

### 4.1 Domain layer

Contains: entities (`Ticket`, `TelemetryPing`, read-only view models for `Trip`, `FareRule`, `RouteStop`, `Conductor`), the capture-time validation rules that belong to those entities, and value objects. No Flutter import, no Drift import, no platform-channel reference, no `dart:io`. Fully testable with plain Dart `test` (Technology Decisions §5.23) and no test double for anything, because nothing here reaches outside itself.

### 4.2 Application layer

Orchestrates a use case: "capture a Ticket" (validate → hand to Durable Capture port → surface capture-confirmation), "resolve Reference Context" (attempt refresh → fall back to cache → mark staleness), "drain pending records" (check gate → pull oldest-first batch → attempt → update state). This layer calls ports; it never performs I/O itself. It is where Riverpod `AsyncNotifier`/`Notifier` classes typically live, expressed against the domain layer's types and the infrastructure layer's port interfaces — never against a concrete Drift table or a concrete `dio` client.

### 4.3 Infrastructure / adapter layer

Concrete implementations: the Drift-backed Durable Capture adapter, the Paho-backed transport adapter (via `core/background`'s platform channel), the `dio`-backed Reference Context REST adapter, the `flutter_secure_storage`-backed credential store. Each adapter implements exactly one port the application layer depends on, and nothing more — an adapter that starts making a business decision (e.g., a storage adapter deciding a Ticket is invalid) has leaked a responsibility that belongs to the domain layer, and is a defect to correct in review, not a convenience to leave in.

### 4.4 Presentation layer

Widgets and screens (`09_ETM_UI_UX_and_Screens.md`'s screen catalog). Reads state exclusively through Riverpod providers exposed by the application layer of the relevant feature module. Contains no business logic, no direct storage or network calls, and no validation logic duplicating what the domain layer already enforces — a screen that re-implements a Ticket precondition check "for a snappier UI" has created a second, divergeable copy of a business rule.

### 4.5 Platform layer

The native Kotlin module (`native/android`) and its Dart-side platform-channel contract (`lib/platform`). This is where Background Execution, Location, and the MQTT client live, co-located per Technology Decisions §5.9–§5.11. This layer is never reached into directly from the domain, application, or presentation layers of any feature module — only `core/sync` and `core/background`'s infrastructure adapters call across the platform-channel boundary.

### 4.6 No responsibility leakage

A short list of leaks to watch for in review, because each has appeared in comparable codebases and each violates a rule stated explicitly upstream:

- Business validation appearing inside a repository or a platform-channel adapter (belongs in the domain layer, System Architecture §12.3).
- A widget directly querying Drift (belongs behind an application-layer provider).
- The transport adapter (`core/sync`) making a decision about whether a Ticket is valid (transport owns no business-validation logic, §12.6).
- A feature module implementing its own local-durability write path instead of depending on `core/capture` (directly contradicts ADR-011 and System Architecture §10).

## 5. Dependency Rules

### 5.1 Allowed and forbidden dependencies

| From → To | Domain | Application | Infrastructure | Presentation | Platform |
|---|---|---|---|---|---|
| **Domain** | — | Forbidden | Forbidden | Forbidden | Forbidden |
| **Application** | Allowed | — | Forbidden (depends on port, not implementation) | Forbidden | Forbidden |
| **Infrastructure** | Allowed (to satisfy a port's types) | Allowed (implements a port) | — | Forbidden | Allowed (adapter calls across the channel) |
| **Presentation** | Allowed (reads domain types) | Allowed (reads providers) | Forbidden | — | Forbidden |
| **Platform** | Forbidden | Forbidden | Forbidden | Forbidden | — |

Across feature modules: `features/telemetry` never depends on `features/ticketing` or `features/reference_context` (System Architecture §12.4). `features/ticketing` depends on `features/reference_context` and `features/identity`, never the reverse. Every feature module that captures an event depends on `core/capture`; nothing depends on a feature module's internals from another feature module — cross-feature communication, if ever needed, happens through a shared core port, never a direct import of another feature's application layer.

### 5.2 Shared abstractions

Ports (abstract interfaces the application layer depends on) live alongside the application layer that defines them, in the module that owns the responsibility — e.g., the Durable Capture port lives in `core/capture`, not in a separate cross-cutting "interfaces" package. A port is defined by the module whose responsibility it represents, and consumed by whichever module needs it; it is never defined by the consumer.

### 5.3 Composition Root responsibilities

`app/` is the only place in the codebase where a Riverpod provider binds a concrete infrastructure adapter to the abstract port an application-layer class depends on. No feature module's own provider file should instantiate a concrete `DriftDatabase`, `Dio`, or platform-channel handle directly — it should depend on a provider the composition root wires up. This is what makes Technology Decisions §5.8's "no separate DI framework" claim actually true in practice: Riverpod's provider graph *is* the composition root, and it has exactly one place doing the wiring, not one implicit wiring site per feature.

## 6. Coding Standards

### 6.1 Naming

- Domain entities: singular nouns matching the Domain Specification exactly (`Ticket`, `TelemetryPing`, `Trip`, `FareRule`, `RouteStop`, `Conductor`) — never a synonym or abbreviation that requires a reader to reverse-translate back to the domain vocabulary.
- Ports: named for the responsibility, not the technology (`DurableCapturePort`, not `DriftRepository`; `ReferenceContextGateway`, not `DioClient`).
- Adapters: named for the technology they wrap plus the port they implement (`DriftDurableCaptureAdapter implements DurableCapturePort`).
- Providers: named for the fact they expose, not the mechanism (`authorizationStateProvider`, not `identityStreamProvider`) — a provider name should read like an answer to "what does this tell me," matching System Architecture §15's one-owner-per-fact model.

### 6.2 File organization

One domain concept per file in the domain layer. One use case per class in the application layer (a `CaptureTicketUseCase`/notifier does not also own reference-context refresh logic). Adapters are one file per port implementation, not one giant "repository" file implementing several unrelated ports.

### 6.3 Class and function responsibilities

A class has one reason to change — traceable to exactly one subsystem in System Architecture §12. A function does one thing at one level of abstraction; a capture-orchestration function that also formats a log line and also computes a retry delay is doing three jobs, and each belongs to a distinct, narrower function or subsystem.

### 6.4 Immutability

Domain entities and value objects are immutable (Technology Decisions §5.13's `freezed` is deferred but not required for this — plain immutable Dart classes with `const` constructors and `copyWith` where needed are sufficient at MVP). A Ticket, once captured, never has a field mutated in place — a correction is a new event referencing the original (System Architecture §19; Domain Specification §3, Principle 5), never a mutation of the captured record.

### 6.5 Error handling and null handling

Dart's sound null safety (Technology Decisions §5.1) is the first line of defense — a nullable type in the domain layer must represent a genuine, named "may legitimately be absent" business state (e.g., "no Reference Context has ever been resolved," System Architecture §23 item 4), never a shortcut around handling a case properly. See §9 of this handbook for the full error-classification model.

### 6.6 Documentation and code comments

A comment on a class or function in `core/capture`, `core/sync`, `features/identity`, or any other subsystem-owning code should cite the upstream section it implements (e.g., `// Implements System Architecture §12.5 — durable write precedes any network attempt.`) — this is not decorative; it is what lets a future engineer verify the code still matches the specification after a change, and what lets a reviewer check a diff against the actual requirement rather than against their own memory of it.

### 6.7 Constants and configuration

Backend-defined parameters that are not free implementation choices — the connection-level backoff curve (1s initial, doubling, 5-minute cap) and the publish-retry backoff curve (2,000ms base, doubling, 120,000ms cap) (Reliability §11.2; MQTT Specification §15.1–§15.2) — are named constants sourced from, and commented with, the specification section that fixes them. They are never tuned locally "for better UX" without a corresponding change to the Reliability Specification first; a local-only change here is exactly the kind of silent divergence ADR-011 and the Reliability Specification's own Principle 5 both warn against.

## 7. State Management Guidelines

Built directly on Riverpod (Technology Decisions §5.4) and the State Ownership model (System Architecture §15). The question "where does this state live" is never answered by convenience — it is answered by checking which subsystem in §15 already owns the fact.

### 7.1 When state is local

Presentation-only state with no meaning outside a single screen's widget tree (a text field's current draft value before submission, a bottom sheet's open/closed state) is local `StateProvider`/`useState`-equivalent state, scoped to that screen. It is never promoted to a shared provider "just in case" — that would manufacture a second owner for a fact that has, and should have, exactly one.

### 7.2 When state is shared

Anything another part of the app needs to read — authorization state, sync/reconciliation status, reference-context staleness, background-execution health — is exposed by exactly one provider, owned by the subsystem responsible for it per System Architecture §15. A second provider computing "probably still authorized" from a pattern of failures, instead of reading Identity's actual state, is exactly the anti-pattern §15 names as a defect to correct on sight.

### 7.3 When state is derived

A UI-facing "can I issue a ticket right now" signal is derived — computed by combining Reference Context's staleness state and Identity's authorization state — but it is derived transparently, as a `Provider` that reads the two owning providers, never as a third place independently tracking its own approximation of either fact.

### 7.4 When state should be persisted

Only two categories of state are durably persisted for correctness: unsynced Tickets and unsynced Pings, through `core/capture` (System Architecture §14). Everything else that is persisted — the Device credential (`flutter_secure_storage`), the last-known pairing snapshot and last-sync timestamps (`shared_preferences`, `core/config`), cached Reference Context (Drift, in tables structurally distinct from the capture tables) — is persisted for continuity across restarts, not for correctness, and every provider exposing it must be able to answer "what happens if this is wiped" with "a graceful re-resolution," never "a data loss" (System Architecture §14; ADR-013).

### 7.5 State ownership and lifecycle

A provider's lifecycle matches its owning subsystem's lifecycle, not the widget tree that happens to be reading it. `core/sync`'s drain-loop state, for instance, must survive a screen navigation — it is scoped at the app/composition-root level (`keepAlive`), never accidentally disposed because the screen displaying sync status was popped. Conversely, purely local screen state should not be kept alive past the screen's own lifetime — an over-retained provider is as much a defect as an under-retained one, because it manufactures state that outlives the fact it represents.

## 8. Repository & Service Guidelines

### 8.1 Repository responsibilities

A repository (an infrastructure-layer adapter implementing a domain/application-layer port) does exactly what its port contract says: read, write, or query a specific class of data. It does not decide whether a Ticket is valid, does not decide whether a record is "urgent enough" to skip the pacing model, and does not silently retry beyond what the application layer's retry orchestration explicitly asks it to do.

- **Caching responsibilities:** a repository implementing Reference Context (Trip, Fare Rule, Route Stop, Bus pairing, Conductor pairing) always attempts a fresh read first when connectivity allows, falls back to the last-cached value on failure, and always surfaces the value's age/staleness alongside the value itself — never silently substituting a cached value without that fact being observable upstream (System Architecture §12.2; ADR-013).
- **Synchronization responsibilities:** a repository never synchronizes on its own initiative. `core/sync` is the sole subsystem that decides *when* a drain happens; a Durable Capture repository's job is to answer "what's pending" and "mark this synced" when asked, not to independently push data over the network.
- **Validation responsibilities:** structural validation (a field is the right type, a required field is present) may happen at the repository/adapter boundary, since the adapter is the first party positioned to catch a defect at the wire-parsing layer (Data Contracts §3, Principle 5). Business validation (a Ticket's Trip/Conductor/Fare Rule/Route Stop preconditions) never happens in a repository — it happens in `features/ticketing`'s domain layer, before a Ticket ever reaches `core/capture`.
- **What repositories must NOT do:** author business truth (a repository never invents a Fare Rule or a Trip assignment — Domain Specification §3, Principle 1); block a capture write on any other subsystem's health (§12.5's "Dependencies: None" applies to the concrete Drift adapter as much as to the abstract port); treat a cache miss or stale value as an error condition rather than an expected, honestly-represented state.

### 8.2 Service guidelines

- **MQTT service (`core/sync`'s transport adapter, native module):** publishes at QoS 1 only (ADR-005), never assumes a session survives a process kill on its own (that guarantee belongs to `core/capture`, not to session persistence — Reliability §8), and treats a publish failure as "return to Retry Pending," never as a reason to drop a record.
- **REST service (Reference Context / Identity adapters, `dio`-based):** every request carries the Device's Basic-auth credential via a `dio` interceptor (Technology Decisions §5.12); every request has a bounded timeout and degrades to "use cached value" on failure or timeout, consistent with API Specification §17's framing — a REST call is never allowed to block a Conductor-facing screen indefinitely.
- **Location service (native module):** reads at the adaptive cadence the backend's telemetry contract defines; a sensor-read failure or gap is a degraded-cadence condition to resume at the next interval, never a reason to stop originating readings (System Architecture §12.4).
- **Background execution service (native foreground service):** exposes its own health so a kill-and-restart triggers `core/sync` to resume draining exactly as it would after any other reconnect (System Architecture §12.7) — it never itself decides that data has been lost; that determination is never this service's to make.
- **Authentication (Identity):** custodies the Device credential via `flutter_secure_storage`; presents it on every outbound call; treats any rejection or ambiguous signal as fail-closed, propagated as a distinct state from a connectivity failure (ADR-007, ADR-009).
- **Synchronization orchestration (`core/sync`, application layer):** implements the two-condition gate (network *and* confirmed broker session, MQTT Specification §12) before ever attempting a drain; implements oldest-first, per-partition, paced batching exactly as Reliability §11 specifies — no engineer-local tuning of batch size or pacing without a corresponding Reliability Specification change.
- **Secure storage (Identity's credential store):** the only thing ever written here is the Device credential. Nothing else — not a Ticket, not a Trip snapshot — belongs in secure storage; putting non-sensitive cache data there does not add safety, it adds unnecessary friction and an unclear precedent for what secure storage is for.
- **Reference context (repository):** see §8.1's caching responsibilities above; this service's read path is the one and only place a Reference Context staleness signal is computed.
- **Telemetry (application-layer orchestration in `features/telemetry`):** requires no Trip, Conductor, or Fare Rule precondition (System Architecture §12.4) — a telemetry capture path that starts checking Reference Context "just to be safe" has added a dependency the architecture explicitly forbids.

## 9. Error Handling Standards

### 9.1 Recoverable errors

A connectivity loss, a broker-session negotiation failure, a REST timeout, a transient sensor-read gap, a batch that partially failed — all recoverable, all handled by the existing retry/backoff/recovery machinery already specified (Reliability §10–§11), never by inventing a parallel, feature-local retry loop. A recoverable error is retried, logged (§10 of this handbook), and never surfaced to the Conductor as a failure of *their* action — the Ticket or Ping was still captured; only its delivery is pending.

### 9.2 Fatal errors

A durable-capture write that genuinely cannot complete (storage exhaustion, a corrupted database file) is fatal in the sense that it must be surfaced loudly and immediately — this is the one class of failure the architecture has no tolerance for, because it is the one guarantee (§12.5) nothing else compensates for. A fatal error here is never silently swallowed or downgraded to a retry; it is escalated to Observability (§12.10) at the highest severity the logging framework supports and, where the UI can represent it honestly, to the Conductor as well (never as a generic "something went wrong" — as specifically as the ETM's own honesty principle, Product Specification §18, requires).

### 9.3 User-visible errors

Only errors that change what the Conductor should reasonably do are surfaced: "not authorized — contact your operator" (distinct, never merged with a connectivity message, ADR-007), "no signal — your ticket is saved and will send once connected" (never alarming, since capture already succeeded), "this Trip/Fare context hasn't loaded yet" (a Reference Context resolution failure, per Workflow §5). A user-visible error never states more certainty than the ETM actually has — never "sale confirmed by the backend" when only transport acknowledgement has occurred (Reliability §9.4).

### 9.4 Developer-visible errors

Anything the Conductor does not need to see but an engineer investigating a field issue does — a malformed Reference Context payload, an unexpected provider-graph exception, a native-module bridge failure — goes to Observability (§12.10) with full structured context, never to the UI, and never only to `debugPrint` (Technology Decisions §5.15's rejection of print-only logging applies here directly).

### 9.5 Logging expectations

Every capture attempt, durability confirmation, sync attempt and outcome, authorization-state change, and background-execution lifecycle transition is logged structurally, through the durable `logger`-plus-rotating-sink mechanism (Technology Decisions §5.15) — never only in memory, since the failure modes this system is built to survive are exactly the ones that would also erase an in-memory-only log.

### 9.6 Retry ownership

Retry logic lives in exactly one place per concern: `core/sync`'s application layer owns transport-retry orchestration (Reliability §11); no repository, adapter, or feature module implements its own competing retry loop. A feature module that wraps a call to `core/sync` in its own additional retry wrapper has created two retry policies for one record, which is exactly the kind of silent divergence this handbook's Principle 8 (§2) exists to prevent.

## 10. Testing Strategy

Directly implementing Technology Decisions §5.23–§5.24 and System Architecture §4's testability goal.

- **Unit testing (domain and application layers):** plain Dart `test`, no Flutter dependency, for every domain entity's validation rule and every application-layer use case, with `mocktail` fakes standing in for every port (Durable Capture, Synchronization, Reference Context resolution, Identity). If a domain-layer test requires `flutter_test` to run, that is itself evidence the domain layer has taken on a dependency it shouldn't have (Technology Decisions §5.23).
- **Widget testing (presentation layer):** `flutter_test`, against fake providers overriding the real application-layer providers — never against a real Drift database or a real network call.
- **Integration testing:** `integration_test`, for the native-module-spanning flows §5.23 names explicitly as untestable in isolation — background-service survival across backgrounding, MQTT publish/reconnect behavior, location-capture cadence.
- **Offline testing:** every capture-path test must include a "no connectivity, no broker session" variant as a first-class case, not an edge case — capture succeeding while fully offline is the baseline the architecture is validated against (System Architecture §4), so a test suite that only exercises the connected path has not actually validated the architecture's central claim.
- **Synchronization testing:** exercises the two-condition gate, oldest-first per-partition draining, both backoff curves (§11.2 of the Reliability Specification), partial-batch handling (§11.7), and the "no record silently disappears from its lifecycle" invariant (Reliability §6).
- **Failure testing:** a kill-process-mid-write chaos test and a dead-zone-then-reconnect smoke test are required for any change touching `core/capture` or `core/sync`, mirroring the exact tests ADR-011 requires at the backend for the equivalent mechanism — these are not optional "if time allows" tests; they are the tests that actually validate this system's one non-negotiable guarantee.
- **Performance testing:** ticket-issuance latency (must feel instantaneous, decoupled from network latency — Product Specification §18) and app-start latency are measured against the Performance Guidelines in §12 of this handbook, not against a subjective "feels fine" judgment.
- **Acceptance testing:** every feature's acceptance criteria trace to `08_ETM_Features.md`'s Validation Matrix and Acceptance Criteria sections; a feature is not "done" against this handbook's Definition of Done (§16) until its stated acceptance criteria are demonstrably met, not merely until its code compiles and its unit tests pass.
- **Test ownership:** the engineer implementing a feature owns its unit and widget tests as part of the same change; integration and chaos/failure tests for `core/capture`/`core/sync` changes are reviewed by whoever owns the Shared Edge-Event Core, given the blast radius named explicitly in System Architecture §20 and Reliability §22 item 6.

## 11. Logging & Observability

Implements System Architecture §12.10 and Technology Decisions §5.15–§5.16, §5.29.

- **Log levels:** `debug` (verbose, disabled in production builds), `info` (routine lifecycle events — capture confirmed, batch drained, resolution succeeded), `warn` (a recoverable failure entered retry — a REST timeout, a publish failure), `error` (a fatal condition per §9.2 of this handbook), `critical` (reserved for a durable-capture failure — the one condition this system has zero tolerance for).
- **Structured logging:** every log entry carries, at minimum, the subsystem it originated from (matching a §12 subsystem name), the event type (Ticket/Ping/Reference Context/Authorization/Background-lifecycle), and enough context to reconstruct the sequence of events during a post-incident review — never a bare string with no structured fields.
- **Sensitive data policy:** Observability captures operational facts, never full business-sensitive payload contents beyond what diagnosing a reliability problem requires (System Architecture §12.10) — a Ticket's fare amount and Trip reference may be logged for diagnosis; a Conductor's full identity details are not logged more expansively than the Domain Specification itself treats them.
- **Diagnostic events:** authorization-state transitions, background-execution restarts, sync-batch outcomes, and Reference Context resolution failures are always logged, since these are exactly the events a field-incident review needs and exactly the events an in-memory-only log would lose at the moment they matter most.
- **Crash reporting:** Sentry (Technology Decisions §5.16), including native (NDK) crash capture for the `native/android` module, with offline queuing so a crash occurring in a dead zone is not lost, only delayed.
- **Metrics:** Sentry Performance (§5.29) for frame timing and app-start latency; no separate APM tool is introduced at this scale (Technology Decisions §5.29).
- **Non-negotiable boundary:** a failure anywhere in Observability must never propagate to a capture, durability, or sync path (System Architecture §12.10's failure boundary) — "logging a failure to log" is an acceptable terminal state; blocking any other subsystem on a logging call succeeding is not.

## 12. Security Guidelines

Implements System Architecture §17 and Technology Decisions §5.7, §5.30.

- **Secrets and tokens:** the Device credential is the ETM's only security principal (System Architecture §17); it is stored exclusively in `flutter_secure_storage`, never in Drift, `shared_preferences`, or a plaintext asset. Build-time secrets (API base URL, Sentry DSN) are supplied via `--dart-define-from-file` and Gradle flavors (Technology Decisions §5.30), never via a bundled `.env` asset — this device class is explicitly named as at risk of loss or theft (Product Specification §17), and a shipped plaintext configuration asset is exactly the exposure that risk names.
- **Device identity:** the ETM never models "the Conductor" as an authentication concept (System Architecture §17); Conductor identity is domain data carried on a Ticket, handled entirely within Ticketing's business validation, never within Identity & Authorization Awareness.
- **Authorization is observed, never computed locally:** no code path in the ETM decides whether the Device is authorized — that determination is exclusively the backend's; the ETM's job is to carry and propagate the backend's determination faithfully, never to second-guess it with local logic (ADR-007, ADR-009).
- **On revocation:** a revoked Device stops attempting new outbound activity, but its already-durable local data is neither deleted nor exposed elsewhere (Workflow §15) — do not write "cleanup" logic that deletes a revoked Device's pending backlog; that backlog's disposition is explicitly a named open question upstream (Reliability §25 item 2), not a decision an engineer resolves unilaterally in code.
- **PII:** the ETM holds a Conductor's identity only as an attribute on a Ticket it originates, never as a security principal or a separately-stored profile; no new local store of Conductor personal data should be introduced without checking this against the Domain Specification's ownership model first.
- **Transport security:** every REST call carries the Device's Basic-auth credential via interceptor; every MQTT publish happens over the connection parameters Identity supplies — no code path constructs a transport request without going through the Identity-supplied credential path.
- **Replay protection:** the ETM does not implement its own replay/dedup protection — it relies on the backend's dedup mechanism (permanent constraint for Tickets, time-windowed ledger for Telemetry — MQTT Specification §14.1–§14.2), and the ETM's own job is limited to at-least-once delivery, never inventing a client-side "already sent this" cache that could itself become a second, competing source of truth about delivery state.
- **Cross-Device/cross-Operator isolation:** requires no ETM-side enforcement, because the ETM is, by construction, exactly one Device's worth of state scoped to exactly one Operator (System Architecture §17, mirroring ADR-012) — do not build a multi-tenant abstraction into the ETM; there is nothing else present to isolate from.

## 13. Performance Guidelines

Implements System Architecture §4's Performance quality attribute and Product Specification §18.

- **Startup:** app launch to a usable Home Dashboard should not be gated on any network call completing; Reference Context and Identity state are read from local cache/storage first, with a network refresh happening opportunistically afterward.
- **Ticket issuance:** the Conductor-visible "captured" outcome must be reachable the instant the durable local write completes (Reliability §5) — never gated on synchronization, however briefly. A capture path that shows a spinner waiting for network acknowledgement is a defect against this system's central promise, not a minor UX rough edge.
- **Synchronization:** batch size and pacing follow the backend's own contract (Reliability §11.5) exactly; do not widen batches or shorten the pacing gap to make sync "feel faster" — this protects shared broker infrastructure the ETM does not own, and a local performance win here is a fleet-wide reliability cost.
- **Scrolling (Ticket History, Trip Context lists):** backed by Drift's reactive `Stream` queries, paginated where a list could grow large across a long shift, never a full unbounded table scan rebuilding the entire widget tree per rebuild.
- **Background execution:** the foreground service (native module) must sustain Telemetry Origination and Synchronization for a full shift's duration without becoming the reason the OS kills the process — this is validated empirically (integration testing, §10 of this handbook), not assumed from the choice of `START_STICKY` alone.
- **Memory:** the native module's location/MQTT/foreground-service cluster is the part of the stack most exposed to long-running memory pressure across a full shift; any addition to this cluster is reviewed for retained-object growth across an extended run, not just correctness on a short test.
- **Battery:** cadence-adaptive telemetry (per the backend's contract) and the native module's own tuning are the levers available; a feature change that increases telemetry frequency or foreground-service wakefulness without a corresponding product/backend decision is out of scope for a routine engineering change.

## 14. Build & Environment Strategy

Implements Technology Decisions §5.25–§5.27, §5.30.

- **Development:** local builds against the `dev` Gradle flavor, pointed at a local or staging backend, Mosquitto for local MQTT testing (Phase 1 broker — ADR-006); validating EMQX-specific ACL/revocation behavior requires the staging environment or a local EMQX instance, never Mosquitto, since Mosquitto cannot exercise that behavior (ADR-006).
- **Testing:** CI runs the full unit/widget suite against every PR; `integration_test` runs against emulator/device targets in the same GitHub Actions pipeline (Technology Decisions §5.26) for changes touching `core/background`, `core/sync`, or `native/android`.
- **Staging:** the `staging` Gradle flavor, pointed at the staging backend, is the environment integration and chaos/failure tests (§10 of this handbook) run against before a release candidate is cut.
- **Production:** the `prod` flavor; releases go through Google Play's internal → closed → staged-rollout tracks (Technology Decisions §5.27) — never a direct-to-100% production push, given the operational cost a fleet-wide defect would carry on hardware that is often out of easy physical reach.
- **Configuration handling:** every environment-specific value (API base URL, Sentry DSN) is supplied via `--dart-define-from-file`, sourced from CI-managed secret files per environment, composed with the Gradle flavor (Technology Decisions §5.30) — never hardcoded, never committed, never bundled as a plaintext asset.
- **Feature flags:** not part of this stack at MVP; no flagging framework is introduced speculatively. If a future feature genuinely needs staged, flag-gated rollout beyond what Play's own staged-rollout percentage provides, that is a Technology Decision to make explicitly, not a convention to improvise per-feature.

## 15. Code Review Checklist

A reviewer works through this list for every non-trivial change, in addition to ordinary correctness review:

- [ ] **Architecture compliance:** does the change respect the module boundaries in §3 and the dependency rules in §5? Does any new or moved code cross a forbidden dependency direction?
- [ ] **Layer discipline:** is domain-layer code free of Flutter/Android/infrastructure imports? Does the application layer perform I/O directly anywhere it shouldn't?
- [ ] **Durability ordering:** for any change touching a capture path, is the durable write still strictly ordered before any network attempt, with no new exception carved out for "this case is different"?
- [ ] **State ownership:** does the change introduce a new provider that duplicates a fact another subsystem already owns (§7.2)?
- [ ] **Naming:** do domain-layer names match the Domain Specification's vocabulary exactly?
- [ ] **Testing:** are unit tests present for new domain/application logic? Does a capture-path change include an offline-first test case (§10)? Does a `core/capture`/`core/sync` change include the required failure/chaos test?
- [ ] **Logging:** are the relevant lifecycle events (capture, sync attempt/outcome, authorization change) logged structurally, per §11?
- [ ] **Error handling:** is each new error classified correctly per §9 (recoverable, fatal, user-visible, developer-visible), and handled at the layer that actually owns the response to it?
- [ ] **Security:** does the change introduce any new storage of the Device credential outside `flutter_secure_storage`, or any new plaintext configuration asset?
- [ ] **Performance:** does the change add anything that could block ticket-issuance latency or widen a sync batch/pacing parameter without an upstream Reliability Specification change?
- [ ] **Documentation:** does new subsystem-owning code cite the upstream section it implements (§6.6)?
- [ ] **Reliability:** for anything touching the shared core, has the "what happens on an arbitrary process kill at this exact point" question been answered explicitly, not assumed?

## 16. Definition of Done

A feature is complete only when all of the following hold — not merely when its acceptance criteria in `08_ETM_Features.md` are met, though that is one necessary condition among several:

- **Architecture:** implemented within the correct feature module and shared-core boundaries (§3–§5); no responsibility leakage (§4.6) introduced.
- **Tests:** unit tests for domain/application logic, widget tests for new UI, and — where the feature touches `core/capture`, `core/sync`, or the native module — the required integration and offline/failure tests (§10) all pass in CI.
- **Offline support:** the feature's capture-relevant paths (if any) have been explicitly verified to succeed with zero connectivity, not merely "expected to work by inheritance" from the shared core.
- **Accessibility:** the feature's screens meet the Accessibility Guidelines named in `09_ETM_UI_UX_and_Screens.md` §10 — touch target sizing, sufficient contrast, and screen-reader-usable labeling, verified, not assumed.
- **Logging:** the feature emits the structured diagnostic events §11 requires for its own lifecycle-relevant transitions.
- **Documentation:** subsystem-owning code carries the upstream-citation comments §6.6 requires; any new open question genuinely surfaced by implementation is raised with the relevant specification's own Open Questions section, not silently resolved in code.
- **Performance:** the feature meets the relevant expectation in §13 (ticket-issuance latency, startup latency, or the applicable pacing/battery constraint) — measured, not assumed.
- **Security:** the feature introduces no new secret-storage location, no new plaintext configuration asset, and no new local authorization-decision logic (§12).
- **Acceptance criteria:** the feature's stated acceptance criteria in `08_ETM_Features.md` are demonstrably satisfied, reviewed against the actual behavior, not against the code's intent.

## 17. Implementation Roadmap

A dependency-aware sequence, not a sprint plan — each phase exists because the phase before it is a structural precondition, not merely a scheduling convenience:

```
Foundation
  (project scaffolding per §3, Clean Architecture layering per §4,
   Riverpod composition root per §5.3, CI pipeline per §14)
   ↓
Core Infrastructure
  (Drift schema for Durable Capture + Reference Context, distinct table
   families per §3.2 of the System Architecture Specification;
   flutter_secure_storage integration; native module scaffold —
   foreground service, location, MQTT client co-located per §5.9–§5.11)
   ↓
Authentication
  (Identity & Authorization Awareness — Device credential custody,
   authorization-state propagation, fail-closed handling per ADR-007/009)
   ↓
Reference Context
  (resolution, caching, staleness tracking — depends on Identity only)
   ↓
Trip
  (Trip/Fare Rule/Route Stop context consumption — depends on
   Reference Context)
   ↓
Ticketing
  (business validation, capture orchestration — depends on Reference
   Context, Identity, and Durable Capture)
   ↓
Synchronization
  (transport, retry/backoff per Reliability §11, two-condition gate —
   drains both Ticketing's and Telemetry's backlogs)
   ↓
Telemetry
  (capture orchestration — depends on Durable Capture and Identity
   only; can be built in parallel with Ticketing once the shared core
   is proven, since it shares the same mechanism per ADR-011)
   ↓
Settings
  (Conductor-facing configuration screens, battery-optimization
   onboarding flow per Technology Decisions §5.9)
   ↓
Diagnostics
  (Sync-Status & Reconciliation Honesty — depends on every subsystem
   above already exposing the state it aggregates)
   ↓
Testing
  (chaos/failure test suite hardening — dead-zone smoke test,
   kill-process-mid-write test, per §10 of this handbook)
   ↓
Release
  (staged Google Play rollout per §14, single-operator pilot scope)
```

**Why this order, not another:** Durable Capture and the native module must exist before either Ticketing or Telemetry can be built against something real, since both feature modules depend on the shared core rather than implementing their own durability (§3.2, ADR-011). Identity precedes Reference Context because Reference Context Resolution's own failure boundary depends on knowing whether resolution attempts are even meaningful (§12.2's stated dependency on §12.1). Synchronization is sequenced after Ticketing specifically (rather than immediately after Core Infrastructure) so that the first thing draining through it is a real, validated business record — but Telemetry can and should proceed in parallel with Ticketing once Synchronization is proven, since it shares the identical mechanism and adds no new durability or transport surface (System Architecture §19; ADR-011).

## 18. Engineering Risks

- **Technical risk — the native-module cluster is hand-maintained Kotlin, not a third-party plugin.** This is the stack's highest-maintenance-burden component (Technology Decisions §9) and the part most exposed to Android platform-version drift. Mitigation: treat `native/android` changes with the same review rigor as `core/capture`/`core/sync`, and track Android OS release notes for foreground-service and battery-optimization API changes as a standing engineering responsibility, not a reactive one.
- **Maintainability risk — a `build_runner` pipeline (Drift, Protobuf, `json_serializable`) is now load-bearing across most of the stack** (Technology Decisions §9). A single ecosystem regression could stall multiple categories at once. Mitigation: pin generator versions deliberately; do not casually add a fourth generator (Technology Decisions consistently rejects candidates on exactly this ground — §5.5, §5.8, §5.24).
- **Operational risk — Sentry now covers both error reporting and performance monitoring** (Technology Decisions §9). A vendor-side disruption affects two observability categories simultaneously. Mitigation: Sentry's self-hosting option is a real, available hedge if this risk materializes (§5.16) — this is a known, accepted, and reversible risk, not an oversight.
- **Testing risk — the shared core's blast radius.** A defect in `core/capture` or `core/sync` affects both Ticketing and Telemetry simultaneously (System Architecture §20; Reliability §22 item 6). Mitigation: the chaos/failure test suite for the shared core (§10 of this handbook) is treated as release-blocking, not optional, precisely because of this concentrated blast radius.
- **Dependency risk — local-storage migration cost is deliberately high** (Technology Decisions §5.6). This is a feature of the decision, not a risk to eliminate, but it means any future storage-engine change must budget for an explicit, tested field-data migration path for Devices holding unsynced records at the moment of upgrade.
- **Future migration risk — several categories are scope-gated, not technology-gated** (Analytics, Printing, Barcode/QR, Maps — Technology Decisions §5.17–§5.20). Building any of these speculatively ahead of an actual Product Specification change is itself a risk this handbook explicitly discourages (§3.3).
- **Field-data risk — several parameters in this handbook (batch sizing, backoff caps, storage growth assumptions) are validated against an estimated, not measured, connectivity profile** (Reliability §22 item 5; Product Specification §17, §21). Engineering should expect these to be revisited once real pilot data exists, per the Technology Decisions' own capability-triggered (not calendar-triggered) review philosophy (§11 of that document).

## 19. Future Engineering Considerations

- **A third edge-generated event type** (commuter location-sharing, explicitly anticipated by ADR-001, ADR-002, and ADR-008) is added as a new feature module depending on the existing Shared Edge-Event Core — no new durability or transport mechanism, only a new domain-validation layer analogous to `features/ticketing` or `features/telemetry` (System Architecture §19). Engineers building this should look to `features/telemetry` as the closer structural template, since it has no Reference Context dependency either.
- **A Conductor self-identification mechanism**, should the platform introduce one to address the device-handoff misattribution risk (Domain Specification §17 item 1; Workflow §6), extends `features/identity`'s domain — what the Device currently carries as its Conductor attribute — without touching the Device-level authentication boundary itself (System Architecture §19). This is additive to an existing module, not a new authentication concept.
- **A staleness bound on cached Reference Context**, once the domain defines one (Domain Specification §17 item 5), becomes a policy value `features/reference_context` consumes — the module is already structured to track staleness (§8.1 of this handbook); only the threshold at which staleness becomes a refusal, rather than a warning, needs to be added.
- **Ticket correction/void**, once the backend defines the mechanism (Domain Specification §17 item 3), is a new capture-time flow within `features/ticketing` producing a new, distinct Ticket referencing the original — it reuses `core/capture` and `core/sync` exactly as ordinary issuance does, since a correction is a new event, never a mutation (System Architecture §19).
- **A local-storage retention/pruning policy** for synced-but-historically-retained records is an open Technology Decision (Technology Decisions §13 item 1; System Architecture §23 item 3) that should be revisited once field-pilot storage-growth data exists — engineering should not preemptively build a pruning mechanism against an unmeasured assumption.
- **`freezed` adoption** alongside `json_serializable` for REST-model ergonomics remains an open, deliberately deferred, additive question (Technology Decisions §13 item 2) — a reasonable candidate for a future revision of this handbook's Coding Standards (§6.4), not a gap in the current one.

---

*End of NammaRoute Conductor ETM Engineering & Implementation Handbook v1.0.*
