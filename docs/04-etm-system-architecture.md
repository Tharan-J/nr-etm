# NammaRoute Conductor ETM — System Architecture Specification
### `docs/etm-system-architecture-specification.md`

**Document type:** System Architecture Specification — defines the logical architecture of the ETM application: the responsibilities, boundaries, and interactions of every major subsystem. It is not an implementation guide, not a Flutter coding guide, and not a technology decision document.
**Position in the hierarchy:** Derives from the ETM Product Specification, ETM Domain Specification, and ETM Workflow Specification. Constrained by the Product Engineering Blueprint, the Architecture Review, the Deployment Architecture, the API/MQTT/Database Specifications, the Sequence Diagrams, the Domain Model Specification, and every ADR touching edge-originated data. Feeds the future ETM Technology/Architecture Decisions document, Engineering Guidelines, Offline Synchronization design, Feature Specifications, and Implementation Planning — none of which redefine the boundaries fixed here.
**Status:** Living document, updated when a subsystem's responsibility or boundary changes, not when a package, library, or folder structure changes underneath it.

---

## 1. Purpose

This document defines *how the ETM is architected*, not what it does (Product Specification), what it means (Domain Specification), or how it is operated (Workflow Specification). It exists so that every future engineering decision — technology selection, module implementation, offline sync design, feature build-out — derives from one shared logical architecture, rather than each independently re-deriving the ETM's shape from the product, domain, and workflow documents in isolation.

The backend is a fixed dependency (Product Specification §4). This document does not design, redesign, or restate backend architecture — it designs the first production client that consumes it, within the constraints the backend's ADRs already impose on any edge device.

## 2. Architectural Goals

1. **A ticket sale and a location report are never lost**, regardless of connectivity, process death, or OEM background-execution interference — the architecture's non-negotiable goal, inherited directly from ADR-008 and ADR-011.
2. **Neither of the ETM's two jobs (ticketing, telemetry) can starve the other** — one high-frequency, low-stakes-per-event responsibility (telemetry) and one lower-frequency, high-stakes-per-event responsibility (ticketing) must share a device without either degrading the other's reliability (Product Specification §11).
3. **The architecture is honest about what it does and doesn't know** — sync status, reconciliation status, and context staleness must be representable as first-class architectural facts, not an afterthought bolted onto a UI layer (Domain Specification §3, Principle 6).
4. **The ETM never originates business truth it isn't entitled to originate** — Trip, Fare Rule, Route Stop, Conductor identity, and Device identity are read-only context; only a Ticket and a Telemetry Ping are ever created here (Domain Specification §3, Principle 1).
5. **The architecture survives a device being killed at an arbitrary point** — not merely makes killing less likely (Architecture Review §9). Every subsystem boundary below is drawn with this as a standing constraint, not a special case.
6. **The architecture is extensible to a third edge-generated event type** without a redesign — the backend already anticipates this (ADR-001, ADR-002, ADR-008, ADR-011 all generalize beyond telemetry and ticketing), and the ETM's architecture must not close a door the backend has deliberately left open.

## 3. Architectural Drivers

Derived from the Product, Domain, and Workflow Specifications, ranked by how strongly they constrain the architecture's shape:

| Driver | Source | Architectural consequence |
|---|---|---|
| Offline is the normal operating condition, not an exception | Product §13, Domain §3.2, Workflow §11 | Every write path must be fully functional with zero connectivity; no subsystem may block on a network call for a capture action. |
| OEM background-execution killing is the platform's highest-ranked risk | Architecture Review §9 | No subsystem may assume it will run to completion; every capture-then-forward operation must be resumable from durable state after an arbitrary kill. |
| A ticket and a telemetry ping are the same reliability class, different stakes | ADR-011, Domain §3.3 | One shared durability/transport mechanism, not two parallel ones — but stakes-appropriate behavior (dedup permanence, correction handling) still differentiates them where the domain requires it. |
| The Device, not the Conductor, is the authenticated identity | Product §15, Domain §3.4 | No subsystem may treat "Conductor" as a security principal; Conductor is an attribute carried on a Ticket, never a credential the ETM manages. |
| Trip, Fare Rule, Route Stop, and Conductor pairing are read-only, resolved, possibly-stale context | Domain §5, §13, §14 | A distinct architectural boundary must separate "things the ETM authors" from "things the ETM caches" — they have opposite disposability rules. |
| Fail-closed is the platform's universal posture under uncertainty | ADR-007, ADR-009, Workflow §15, §16 | The ETM must represent an unauthorized/revoked state honestly and distinctly from a connectivity gap, never silently retry as if it were the same problem. |
| Sync must be throttled, not bursted, on reconnect | MQTT Spec §12 | The synchronization subsystem owns pacing as a first-class responsibility, not an incidental detail of a retry loop. |
| The ETM does exactly two jobs and nothing else | Product §13, §6 | No subsystem may accrete responsibility belonging to the Operator Dashboard (scheduling, fleet analytics) or Commuter product (journey search) — out-of-scope by architecture, not just by product decision. |

## 4. Quality Attributes

- **Reliability** — the dominant quality attribute. Every architectural choice below is subordinate to "a captured Ticket or Ping is never lost," including choices that would otherwise favor simplicity or performance.
- **Availability (of the ETM's own two functions)** — ticketing and telemetry capture must remain available to the Conductor even when every backend-facing subsystem is unavailable; only *reading fresh context* degrades under disconnection, never *capturing a fact*.
- **Performance** — ticket capture must feel instantaneous (Product §18); this is a UI-thread and local-write latency concern, decoupled entirely from network latency by architecture, not by incidental behavior.
- **Offline Operation** — not a mode the architecture supports in addition to a "normal" connected mode; it is the baseline the architecture is validated against, with connectivity treated as an optimization when present.
- **Scalability** — bounded and modest at ETM scope: one Device, one Conductor's attention, one Bus's telemetry cadence. The architecture does not need to scale within a single device; it needs to scale across a growing fleet of independent, stateless-toward-each-other Device instances, which the backend's per-Device isolation already guarantees.
- **Maintainability** — module boundaries must map to the domain boundaries already fixed upstream (Ticket, Telemetry, Reference Context, Identity), so that a future change to one domain concept touches one module, not several.
- **Security** — the ETM enforces no authorization logic of its own; it correctly carries, protects, and stops using a Device credential the backend issues and can revoke, and it never fabricates a Conductor-level trust boundary the platform doesn't have.
- **Testability** — the domain and capture logic must be testable without a real device, a real broker, or a real network — achievable only if those concerns sit behind architectural boundaries the domain layer does not reach through.
- **Extensibility** — a third edge-generated event type, a Conductor self-identification mechanism, or a staleness bound on cached context (all named as open questions upstream) must be addable without restructuring existing subsystems.
- **Recoverability** — the architecture's central promise. Recovery from a killed process, a multi-hour dead zone, or a stale reference-data snapshot must be deterministic and automatic, never dependent on a Conductor noticing something and taking corrective action.

## 5. Architecture Evaluation

Before selecting an architecture, five candidate approaches were evaluated against this application's actual drivers (§3), not against general-purpose merit.

| Approach | Fit for offline-first | Fit for dual-purpose (ticketing + telemetry) | Modularity | Testability | Long-term extensibility | Learning complexity |
|---|---|---|---|---|---|---|
| **Pure Layered (horizontal: UI / business / data)** | Weak — a single "data layer" tends to blur the load-bearing distinction between the durable capture buffer and the disposable reference cache, since both are just "data" to a horizontal layer. | Weak — nothing in a horizontal layering forces ticketing and telemetry to share a reliability mechanism rather than silently diverging. | Weak — horizontal layers cut across domain concepts, not with them. | Moderate | Weak | Low |
| **Feature-first (vertical slices per feature)** | Moderate — each slice can be offline-first internally, but nothing structurally prevents two slices (ticketing, telemetry) from building two different local-durability mechanisms for what the domain says is one problem (ADR-011). | Weak on its own — vertical slices favor independence over the shared-mechanism requirement this domain explicitly demands. | Strong for unrelated features; weak for two features that must share infrastructure by design. | Strong | Strong for adding new features; weak for enforcing shared reliability primitives. | Low–Moderate |
| **MVVM (as an overall app architecture, not just a presentation pattern)** | Weak as a *system* architecture — MVVM answers how a screen binds to state, not how a domain fact survives a process kill before any screen exists to display it. | Not addressed — MVVM is silent on capture-to-sync concerns entirely. | N/A at this scope | Strong for view logic; silent on domain/infra separation | Weak | Low |
| **Hexagonal / Ports & Adapters (as the cross-cutting layering discipline)** | Strong — the domain (Ticket, Telemetry Ping, Trip context, capture rules) is defined independent of Android, MQTT, and Room specifics; adapters implement durability and transport behind ports the domain depends on, not the reverse. | Strong — a shared "Edge Event Capture" port can be implemented once and used by both Ticket and Telemetry domains, directly mirroring ADR-011's "same reliability mechanism, different payload." | Strong | Strong — domain logic is testable with fake adapters, no device or broker required. | Strong — a third edge event type implements the same port. | Moderate |
| **Vertical Slice only (no shared kernel)** | Weak — same objection as Feature-first, sharpened: without an explicit shared kernel, "one reliability mechanism for all edge events" (ADR-011) has nowhere architectural to live. | Weak | Strong per-slice, weak platform-wide | Strong | Weak — every new slice re-solves durability from scratch | Moderate |

**None of these alone is sufficient.** Feature-first organization is the right answer to *where a Conductor-facing capability lives* (a Conductor thinks in terms of "issuing a ticket," not "the capture port"). Hexagonal layering is the right answer to *how the domain stays independent of Android/MQTT/Room details* and *how two features share one reliability mechanism without duplicating it*. Neither answers the other's question.

## 6. Selected Architecture

**A Hybrid: Feature-Sliced Modules, Each Internally Layered on a Shared Hexagonal Core.**

- **Feature modules** (Ticketing, Telemetry, Reference Context, Identity) are the unit a Conductor-facing capability is organized around — this is what keeps the architecture maintainable and lets a future Feature Specification map cleanly onto a module boundary.
- **A shared domain/infrastructure core**, structured on ports-and-adapters discipline, is what every feature module that originates an edge-generated event (Ticketing, Telemetry) depends on for capture, durability, and synchronization — this is what makes ADR-011's "one mechanism, two payload types" architecturally real rather than a convention two independent teams might silently diverge from.
- **Reference Context is architecturally distinct from the shared core**, not a peer of it — it is a read-side cache with the opposite disposability rule (§14), and conflating it with the capture-side core would blur the single most consequential distinction in this system's data ownership.

**Why this beats each alternative on its own:** a pure feature-first design would let Ticketing and Telemetry independently reinvent "write locally before the network," risking exactly the kind of silent divergence ADR-011 was written to prevent. A pure hexagonal/layered design, applied uniformly across the whole app, would flatten Ticketing and Telemetry into generic "edge event" screens and lose the domain-specific validation each one legitimately needs (a Ticket's Trip/Conductor/Fare Rule preconditions have no Telemetry equivalent, per Domain Specification §5.4 vs. §5.5). The hybrid gives each concern the granularity it actually needs: shared where the domain says the mechanism is shared (capture, durability, transport), separate where the domain says the concern is separate (a Ticket's business validation, a Ping's cadence policy).

This selection is consistent with, and does not re-decide, any ADR: it is a decision about how the ETM's own code is organized to consume MQTT/Protobuf/QoS-1/LocalBuffer-ordering (ADR-001, ADR-002, ADR-005, ADR-008) — not a decision about which of those mechanisms to use.

## 7. System Context

```
                          ┌─────────────────────────────┐
                          │   Operator Admin (Dashboard) │
                          │  — provisions, pairs, sched- │
                          │    ules, revokes; never      │
                          │    opens the ETM directly    │
                          └───────────────┬───────────────┘
                                          │ (mediated entirely by the backend)
┌───────────────┐   authenticates as one   ┌────────────────────────────┐
│   Conductor    │◄── Device, carries no ──│         Backend Platform    │
│ (uses the ETM) │    credential of own    │ (fixed, external dependency)│
└───────┬────────┘                         │  — Auth, Trip/Route/Fare    │
        │ operates                          │    reference data, MQTT     │
        ▼                                   │    ingestion, reconciliation│
┌────────────────────────────────────────┐  └──────────────┬──────────────┘
│              ETM (this system)          │                 │
│  the operator-provisioned Device        │◄── async, durable, tolerant ──┤ (edge-generated events:
│  — one Bus, one Device identity,        │    of long disconnection      │  Ticket, Telemetry Ping)
│    one currently-carried Conductor      │──────────────────────────────►│
└────────────────────────────────────────┘   sync/request-response, tolerant
                                               of "no data yet" as a normal state
                                               (Trip, Fare Rule, Route Stop, pairing)
```

The ETM is a single node at the edge of a platform it does not control (Deployment Architecture §9.1: "operates outside platform infrastructure control"). It has exactly two external relationships: an asynchronous, durable event-publishing relationship (outbound Ticket and Telemetry data) and a synchronous, tolerant-of-absence reference-reading relationship (inbound Trip/Fare/Route/pairing context) — matching the two data-flow shapes the Architecture Review names for edge devices (§11). The ETM never talks to another product surface (Commuter App, Dashboard) directly, and never talks to any backend component other than the MQTT broker and the API service (Deployment Architecture §9.1: "MUST NOT talk to Ingestion Service, PostgreSQL, or Redis directly").

## 8. Architectural Principles

Only principles the platform architecture and ETM requirements actually support are included:

1. **Offline First.** Every actor-facing capture action (issuing a Ticket, originating a Ping) succeeds independent of network state, by architecture, not by best effort (Product §13, ADR-008).
2. **Local Buffer Is the Real Source of Truth, Temporarily.** For a Ticket or Ping between capture and backend reconciliation, the ETM's own durable store is authoritative — not disposable, not a cache. This is a deliberate departure from "cache is always disposable" (ADR-013), scoped precisely to this one class of data, for the reason the Domain Specification states directly (§8): it mirrors ADR-013's *pattern*, not its scope, because until reconciliation, nothing else holds this fact at all.
3. **Reference Context Is Always Disposable.** Trip, Fare Rule, Route Stop, Bus, and Conductor-pairing data held on-device is a cache in the fullest sense — refreshable, replaceable, and never the authoritative record of anything (Domain Specification §14). Principle 2 and Principle 3 are two different rules precisely because the two kinds of local data have opposite disposability properties; conflating them is the single most likely architectural mistake this system could make.
4. **Platform as Source of Business Truth.** The ETM never authors what a Fare Rule is, what Route a Trip runs, or who a Conductor is assigned to — it resolves these, it does not decide them (Domain Specification §3, Principle 1).
5. **Single Responsibility per Subsystem.** Each subsystem in §12 owns exactly one architectural concern; a subsystem that starts accreting a second concern (e.g., the transport subsystem making business-validation decisions) is a boundary violation to be corrected, not tolerated as a convenience.
6. **Dependency Inversion at the Domain Boundary.** Ticket and Telemetry domain logic (validation, state transitions) depends on abstractions (a durable-capture port, a context-resolution port) that infrastructure implements — never the reverse. This is what keeps §4's testability goal achievable.
7. **Event Driven, at the Edge Boundary.** A Ticket Issued or Telemetry Captured fact is produced once, at capture time, and its downstream delivery is decoupled from its production — mirroring the backend's own event-driven posture (Architecture Review §8) at the one boundary the ETM controls.
8. **Deterministic Recovery.** Recovery from a killed process or a reconnect is a function of durable state alone, never of in-memory state that happened to survive — matching ADR-008's own reasoning applied to the client side of the same mechanism.
9. **Fail Closed on Authorization, Fail Honest on Everything Else.** An unauthorized/revoked Device state is represented distinctly and never silently retried as if it were a connectivity gap (Workflow §15, §16); a stale reference-data read is represented as stale, never as current (Product §18).
10. **Modular, Feature-Aligned Design.** Module boundaries mirror the Domain Specification's entity boundaries (§6 of this document), so that a future domain change has one obvious module to change.

## 9. System Boundaries

**Inside the ETM's architectural boundary:**
- Ticket capture, validation (against cached context), and local durability.
- Telemetry capture and local durability.
- Local durable storage for both event types (the ETM-side analog of "LocalBuffer," ADR-008).
- Local caching of read-only reference context (Trip, Fare Rule, Route Stop, Bus, Conductor pairing).
- Outbound synchronization of buffered events to the backend, paced and ordered per the backend's own trickle-sync contract (MQTT Spec §12).
- Device-identity credential storage and use (never authorship — the credential is issued externally).
- Background execution management (foreground service posture, OEM battery-optimization mitigation) as a first-class architectural concern, not an implementation footnote.
- Conductor-facing representation of sync/reconciliation honesty (§4, goal 3) — the architectural obligation to make "did my sale go through" answerable, even though the full answer (reconciliation) is not observable (Domain Specification §17, item 2).

**Outside the ETM's architectural boundary (owned by the backend or by an Operator Admin action):**
- Trip, Route, Fare Rule, Conductor, and Device lifecycle authorship — the ETM only ever reads these.
- Device provisioning, credential issuance, and revocation decisioning.
- Ticket/Telemetry deduplication and reconciliation.
- Any cross-Device, cross-Bus, or cross-Operator visibility (fleet-wide analytics, dashboard views) — structurally impossible for the ETM to originate, since it operates as exactly one Device scoped to exactly one Operator (ADR-012).
- Ticket correction/void mechanism — named upstream as a genuine specification gap (Domain Specification §17, item 3; Workflow §9), and therefore explicitly **not** designed here; this document does not invent a mechanism the backend does not yet define an endpoint, topic, or workflow for.

## 10. Major Components

At the highest granularity, the ETM decomposes into four **feature modules** and one **shared core**:

- **Identity Module** — the ETM's own Device identity, credential custody, and authorization-state awareness.
- **Reference Context Module** — resolution and caching of Trip, Fare Rule, Route Stop, Bus, and Conductor-pairing data.
- **Ticketing Module** — fare capture, business validation, and Ticket lifecycle up to "buffered."
- **Telemetry Module** — location/status capture and Ping lifecycle up to "buffered."
- **Shared Edge-Event Core** — the durable-capture and synchronization mechanism both Ticketing and Telemetry depend on, plus the background-execution and diagnostics concerns that apply identically to both.

Each feature module owns its own domain rules; none owns durability or transport logic directly — that is delegated to the Shared Edge-Event Core through the dependency-inversion principle (§8, Principle 6).

## 11. Layer Responsibilities

Within the Shared Edge-Event Core (and, by the same discipline, within each feature module that touches capture), three layers are distinguished:

1. **Domain layer** — Ticket/Telemetry Ping entities, their capture-time validation rules, and the Reference Context's read-only view models, expressed with no dependency on Android, MQTT, or local-storage specifics. This is where Domain Specification §5's business rules live in code form.
2. **Application layer** — orchestrates a capture action (validate → durably store → signal the sync subsystem) and a context-resolution action (attempt refresh → fall back to cache → mark staleness), without itself performing storage or network I/O.
3. **Infrastructure/adapter layer** — concrete implementations of durable storage, network transport, background execution, and platform (Android) integration, each satisfying a port the application layer depends on and nothing more.

Dependency direction is strictly inward: infrastructure depends on application, application depends on domain, and domain depends on nothing beneath it. This ordering is what makes §4's testability goal achievable and is the direct architectural expression of Architectural Principle 6 (§8).

## 12. Subsystem Responsibilities

### 12.1 Identity & Authorization Awareness

- **Purpose:** Hold and use the ETM's own Device identity; recognize and represent an authorization failure honestly.
- **Responsibilities:** Custody of the Device credential; presenting the Device's authenticated identity to every outbound interaction; distinguishing "not authorized" from "no connectivity" wherever the underlying signal makes that distinguishable (Workflow §16 leaves the messaging question open; this subsystem's responsibility is to preserve the distinction internally so a future UI decision can act on it).
- **Inputs:** A credential issued once at provisioning (external to this subsystem, Domain Specification §5.1); backend authorization responses (or their absence) from every outbound call.
- **Outputs:** An authenticated identity attached to every outbound event and reference request; a current authorization-state signal consumed by Diagnostics (§12.8) and by the Reference Context and Edge-Event subsystems (which must stop attempting delivery, not merely retry, once revocation is recognized).
- **Dependencies:** None upstream within the ETM — this is the root of trust every other subsystem relies on.
- **Failure Boundaries:** A credential the backend rejects, or a Device found to be revoked, must not crash or wedge any other subsystem — it must propagate as a distinct, representable state (Workflow §15's "the ETM must be able to represent this honestly as 'no longer authorized'"), never silently collapse into the same code path as a connectivity failure.

### 12.2 Reference Context Resolution

- **Purpose:** Resolve and cache the read-only business context (Trip, Fare Rule, Route Stop, Bus, Conductor pairing) every other subsystem depends on, and be honest about its staleness.
- **Responsibilities:** Attempt-then-fall-back resolution of each context type; retention of the last-successfully-resolved value per type; tracking age/staleness per cached value so a consumer (principally Ticketing) can reason about it, even though no staleness bound is defined upstream today (Domain Specification §17, item 5) — this subsystem's job is to make staleness *knowable*, not to invent a bound the domain hasn't specified.
- **Inputs:** Backend reference reads, when connectivity allows; the Identity subsystem's current authorization state (a revoked Device cannot productively attempt resolution).
- **Outputs:** A current-or-last-known Trip, Fare Rule set, Route Stop set, Bus pairing, and Conductor pairing, each carrying an implicit or explicit staleness signal, to the Ticketing module and to Diagnostics.
- **Dependencies:** Identity & Authorization Awareness (§12.1) for whether resolution attempts are meaningful at all.
- **Failure Boundaries:** A failed resolution attempt degrades to "operate against the last-known value" (Workflow §7, §11) — it never blocks, and it never silently fabricates a value. This subsystem holds no durable-write obligation of its own; a failed read here costs nothing, since (per API Specification §21) the ETM never held data this subsystem's reads were responsible for delivering.

### 12.3 Ticket Capture & Validation

- **Purpose:** Turn a Conductor's fare sale into a durably captured, correctly-attributed Ticket.
- **Responsibilities:** Enforce the Ticket's hard preconditions (resolved Trip, Conductor, Fare Rule, and boarding/destination Route Stop pair — Domain Specification §5.4, §12) against whatever the Reference Context subsystem currently holds; compute and permanently snapshot the fare amount at capture time; hand a validated, complete Ticket to the Shared Edge-Event Core for durable capture. Never performs storage or network I/O itself.
- **Inputs:** Conductor-selected boarding/destination points; the current Reference Context (§12.2); the Device's own identity (§12.1).
- **Outputs:** A domain-valid Ticket, submitted to Durable Capture (§12.5); a refusal (not a partial or degraded Ticket) when a hard precondition cannot be met.
- **Dependencies:** Reference Context Resolution (§12.2); Durable Capture (§12.5).
- **Failure Boundaries:** A missing precondition is a business-rule refusal, handled entirely within this subsystem — it must never reach the durable-capture boundary as a malformed or partial record. This subsystem has no retry or sync responsibility of its own; once a Ticket is handed off to Durable Capture, this subsystem's job for that Ticket is complete (Domain Specification §5.4: "Captured → Buffered happens the instant local durable storage confirms the write").

### 12.4 Telemetry Origination

- **Purpose:** Produce a location/status reading at the platform-mandated cadence, independent of Trip or Conductor context.
- **Responsibilities:** Read device location/status at the adaptive cadence the backend's telemetry contract defines (a cadence policy, not a topic or wire concern — out of this document's scope per §"Out of Scope"); package each reading as a domain-valid Telemetry Ping; hand it to Durable Capture (§12.5). Requires no Trip, Conductor, or Fare Rule precondition (Domain Specification §5.5, §12).
- **Inputs:** Device location/status sensors; the Device's own identity (§12.1) only.
- **Outputs:** A domain-valid Telemetry Ping, submitted to Durable Capture (§12.5), on a continuous, cadence-driven basis.
- **Dependencies:** Durable Capture (§12.5) only — deliberately independent of Reference Context Resolution and of Ticketing, consistent with Workflow §4's explicit statement that "Continuous Telemetry does not depend on Trip Assignment or Trip Start."
- **Failure Boundaries:** A sensor read failure or gap is a degraded-cadence condition to be resumed at the next scheduled interval, never a reason to stop originating readings entirely; this subsystem has no awareness of, and no dependency on, Trip lifecycle state.

### 12.5 Durable Capture (Local Buffer)

- **Purpose:** The architectural analog of the platform's `LocalBuffer` — the ETM's own durable, transactional local store for not-yet-synced Tickets and Telemetry Pings, and the actual source of truth for that data until the backend reconciles it (§8, Principle 2; ADR-008 applied client-side).
- **Responsibilities:** Durably persist a submitted Ticket or Ping **before any network attempt is even considered**, with no exception for urgency (mirrors ADR-008's ordering exactly); maintain each record's local lifecycle state (Captured → Buffered → Synced, per Domain Specification §5.4/§5.5's lifecycle, up to the boundary this subsystem can actually observe — it never learns of `Reconciled`, per Domain Specification §17, item 2); expose pending records to the Synchronization subsystem in a way that survives an arbitrary process kill.
- **Inputs:** Validated Tickets (from §12.3) and Telemetry Pings (from §12.4).
- **Outputs:** Durably stored records, queryable by the Synchronization subsystem as "pending" or "synced"; a capture-confirmation signal back to Ticketing/Telemetry (and, transitively, to Diagnostics) the instant the durable write completes — independent of whether synchronization has even begun.
- **Dependencies:** None on any other ETM subsystem for its core write path — this is deliberate; a durable write must never be made contingent on Identity, Reference Context, or Synchronization being healthy.
- **Failure Boundaries:** This is the system's single most load-bearing failure boundary. A process kill at any point *after* a durable write completes here loses nothing. A process kill *before* it completes must never have allowed a network attempt to have been made in its place — the ordering is never reversed, matching ADR-008's own framing of this exact property as the single most load-bearing design fact in the entire backend system, now restated as the ETM's own.

### 12.6 Synchronization & Transport

- **Purpose:** Deliver durably captured Tickets and Pings to the backend when connectivity allows, paced appropriately, without ever being the thing a capture action depends on.
- **Responsibilities:** Detect genuine connectivity and transport-session readiness (mirroring the backend's own two-condition trickle-sync trigger — network *and* broker-session confirmed, MQTT Spec §12); drain Durable Capture's pending records in controlled, paced batches, independently per event type, matching the backend's oldest-first, small-batch, throttled-pacing contract; apply retry/backoff on failure; mark a record synced only on confirmed transport acknowledgement, never earlier.
- **Inputs:** Pending records from Durable Capture (§12.5); connectivity/session-readiness signals; the Identity subsystem's current authorization state (§12.1).
- **Outputs:** Transmitted records to the backend transport; a synced-state update back to Durable Capture; delivery-attempt signals to Diagnostics (§12.8).
- **Dependencies:** Durable Capture (§12.5) as its sole source of work; Identity & Authorization Awareness (§12.1) — a recognized revocation must stop this subsystem from continuing to attempt delivery, not merely fail and retry indefinitely; Background Execution Management (§12.7) to remain runnable while backgrounded.
- **Failure Boundaries:** A transport failure never touches Durable Capture's stored data — it only delays the synced-state transition. Neither event type is prioritized over the other as a blanket rule (mirroring the backend's own non-prioritization, MQTT Spec §12) — both drain independently, consistent with ADR-011's unified reliability model. This subsystem owns no business-validation logic and no knowledge of Ticket/Ping domain fields beyond what transport requires.

### 12.7 Background Execution & Device Lifecycle Management

- **Purpose:** Keep Telemetry Origination, Durable Capture, and Synchronization running across screen-off, backgrounding, and OEM battery-management conditions — the direct architectural response to the platform's highest-ranked risk (Architecture Review §9).
- **Responsibilities:** Maintain a foreground-service posture (or equivalent) sufficient to keep the capture-and-sync chain alive while the Conductor's attention is elsewhere; support an onboarding flow that helps a Conductor disable aggressive OEM battery optimization, understood architecturally as a partial, device-dependent mitigation, never a guarantee this subsystem is designed to assume; expose its own health so that a kill-and-restart is detected and recovery (§12.5, §12.6 resuming from durable state) proceeds automatically.
- **Inputs:** OS lifecycle signals (backgrounding, process death, restart).
- **Outputs:** A sustained execution context for Telemetry Origination and Synchronization; a restart/recovery trigger that causes Synchronization to resume draining Durable Capture exactly as it would after any other reconnect.
- **Dependencies:** None — this subsystem is a platform-integration concern that every other subsystem's continued operation depends on, not the reverse.
- **Failure Boundaries:** This subsystem's failure (a process genuinely killed and not promptly restarted) is explicitly **not** a data-loss event, because Durable Capture (§12.5) already guarantees that independently — this subsystem's job is to minimize how *often* and how *long* capture and sync are interrupted, not to be the thing standing between an interruption and data loss. Conflating the two responsibilities would be a boundary violation (§8, Principle 5).

### 12.8 Sync-Status & Reconciliation Honesty (Diagnostics)

- **Purpose:** Give the Conductor an honest, architecturally-grounded answer to "did my sale go through" (Product §11, Objective 3) without ever overstating certainty the ETM does not have.
- **Responsibilities:** Aggregate and expose, per Ticket or Ping, the furthest lifecycle state the ETM can actually observe (Captured, Buffered, Synced — never Reconciled, per Domain Specification §17, item 2); aggregate and expose current authorization state (from §12.1) and reference-context staleness (from §12.2) as distinct, non-conflated facts; never represent "transport-acknowledged" as "confirmed by the backend's authoritative record," since the ETM genuinely cannot observe that distinction today.
- **Inputs:** Lifecycle-state signals from Durable Capture (§12.5) and Synchronization (§12.6); authorization state from Identity (§12.1); staleness signals from Reference Context (§12.2).
- **Outputs:** A truthful, queryable sync/authorization/staleness status, consumed by whatever future UI layer presents it to the Conductor — this document defines the status this subsystem must be able to represent, not the screen that displays it.
- **Dependencies:** Read-only dependencies on §12.1, §12.2, §12.5, §12.6 — this subsystem authors nothing and mutates no other subsystem's state.
- **Failure Boundaries:** This subsystem's own failure or unavailability must never affect capture, durability, or sync — it is a pure observability layer over the state those subsystems already hold, and its absence degrades visibility, never correctness.

### 12.9 Configuration & Session State

- **Purpose:** Hold the small amount of ETM-local state that is neither a domain entity nor durable event data — the Device's currently-known pairing snapshot, last-successful-sync timestamps, and any local operational settings genuinely scoped to this Device.
- **Responsibilities:** Persist and expose this state across restarts; treat every value it holds as a cache with the same disposability posture as Reference Context (§12.2) — nothing here is ever authoritative.
- **Inputs:** Values written by Identity (§12.1) and Reference Context (§12.2) as a side effect of their own resolution.
- **Outputs:** Fast, offline-available reads of "what did we last know," for subsystems that need a value before or between resolution attempts.
- **Dependencies:** None — a passive store other subsystems write to and read from.
- **Failure Boundaries:** Loss of this subsystem's state degrades to "resolve from scratch on next connectivity," never to data loss, because it holds no data any other subsystem treats as authoritative.

### 12.10 Observability (Logging, Crash Handling, Monitoring)

- **Purpose:** Make the ETM's own behavior — not the Conductor-facing sync status (§12.8), but the engineering-facing operational signal — inspectable after the fact, especially after exactly the kind of kill-and-restart event (§12.7) this system is built to survive.
- **Responsibilities:** Capture structured operational events (capture attempts, durability confirmations, sync attempts and outcomes, authorization-state changes, background-execution lifecycle transitions) durably enough to survive the same failure modes the rest of the system survives; surface crash information for post-incident diagnosis; avoid capturing business-sensitive payload contents beyond what diagnosing a reliability problem requires.
- **Inputs:** Lifecycle and error events from every other subsystem.
- **Outputs:** A durable, inspectable operational record, consumed by engineering tooling, not by the Conductor.
- **Dependencies:** None functionally — every other subsystem may emit to it, but nothing depends on it to operate correctly, by design (an observability subsystem that becomes load-bearing for correctness would itself be an architectural defect, echoing ADR-013's cache-is-never-authoritative reasoning applied to telemetry-about-the-app rather than telemetry-about-the-bus).
- **Failure Boundaries:** This subsystem's own failure must never propagate to any capture, durability, or sync path — logging a failure to log is an acceptable terminal state; blocking on it is not.

## 13. Component Interactions

Interactions are described by responsibility, not by API — per this document's own scope discipline.

**Ticket Issuance:**
```
Conductor action
   ↓
Ticket Capture & Validation ──(reads)──► Reference Context Resolution
   ↓ (validated Ticket)
Durable Capture (Local Buffer)
   ↓ (capture confirmed — Conductor-visible outcome available here, independent of network)
Synchronization & Transport ──(gated by)──► Identity & Authorization Awareness
   ↓ (on confirmed delivery)
Durable Capture marks Synced
   ↓
Sync-Status & Reconciliation Honesty reflects the furthest observable state
```

**Continuous Telemetry:**
```
Device lifecycle (via Background Execution Management)
   ↓
Telemetry Origination  (no Reference Context dependency)
   ↓
Durable Capture (Local Buffer)
   ↓
Synchronization & Transport
   ↓
Sync-Status & Reconciliation Honesty
```

**Reconnection / Recovery (following Background Execution Management detecting a restart, or Synchronization detecting connectivity return):**
```
Durable Capture (Local Buffer) — the durable state that survived, regardless of what caused the interruption
   ↓ (source of pending work — never assumed "in flight" unless also durably persisted)
Synchronization & Transport resumes paced, oldest-first draining, per event-type partition
   ↓
Reference Context Resolution independently re-attempts, on its own cadence, to reduce staleness
```

**Authorization loss (originating externally — a Device Revocation, per Workflow §15):**
```
Identity & Authorization Awareness recognizes a denial
   ↓ (propagated as a distinct state, never merged with "offline")
Synchronization & Transport stops attempting delivery
   +
Reference Context Resolution stops attempting refresh
   +
Sync-Status & Reconciliation Honesty represents "not authorized," not "offline"
```

The pattern worth naming explicitly: **Durable Capture (§12.5) is the only subsystem every recovery path ultimately re-derives its state from.** Every other subsystem's own in-memory state is disposable across a restart; Durable Capture's is not. This is the architectural embodiment of ADR-008's ordering, restated at the ETM's own component-interaction level.

## 14. Data Ownership

| Data | Owner within the ETM | Disposability | Authoritative once |
|---|---|---|---|
| An unsynced Ticket or Telemetry Ping | Durable Capture (§12.5) | **Not disposable** — the actual source of truth until reconciled | The backend has durably reconciled it (an event the ETM cannot directly observe, Domain Specification §17, item 2) |
| A synced-but-not-yet-known-to-be-reconciled Ticket or Ping | Durable Capture (§12.5), retained for local history/diagnostics | Disposable for correctness purposes (the backend has taken over); may be retained locally for Conductor-facing history at a future feature's discretion | Immediately upon confirmed transport delivery, for correctness purposes |
| Trip, Fare Rule, Route Stop, Bus pairing, Conductor pairing (cached) | Reference Context Resolution (§12.2) | **Fully disposable**, always | Never — the backend is always the sole authority; the ETM's copy is a snapshot of unknown age (Domain Specification §14) |
| Device credential | Identity & Authorization Awareness (§12.1) | Not disposable in the sense of "safe to lose casually," but not authoritative either — the backend's authorization decision is what matters; the credential is a bearer of that decision, not itself the source of truth | Never — status is always a backend determination (Domain Specification §5.1) |
| Local pairing/session snapshot, last-sync timestamps | Configuration & Session State (§12.9) | Fully disposable | Never |
| Operational/diagnostic log records | Observability (§12.10) | Disposable, subject to its own retention policy (a future Technology Decision, not fixed here) | Never — informational only |

This table is the architectural enforcement mechanism for Architectural Principles 2 and 3 (§8): exactly two rows are non-disposable, and both belong to exactly one subsystem (Durable Capture). No other subsystem may hold non-disposable state, and Durable Capture may hold no other kind.

## 15. State Ownership

Beyond data-at-rest (§14), the ETM carries a small amount of process/session state whose ownership must be equally unambiguous:

- **Ticket/Ping lifecycle state** (Captured → Buffered → Synced, as locally observable) — owned exclusively by Durable Capture; no other subsystem maintains a competing notion of "has this been sent yet."
- **Connectivity/transport-session readiness** — owned exclusively by Synchronization & Transport; Durable Capture neither knows nor cares about network state, by design (§12.5's failure boundary).
- **Authorization state** (authorized / denied / unknown-pending-verification) — owned exclusively by Identity & Authorization Awareness; every other subsystem that needs to know reads this state, never infers its own version of it from a side effect (e.g., Synchronization must not infer "probably revoked" from a pattern of failures — it consults Identity's explicit state).
- **Reference-context freshness** — owned exclusively by Reference Context Resolution; a "how stale is my Trip assignment" question has exactly one place to be asked.
- **Background-execution lifecycle state** (running / backgrounded / restarted) — owned exclusively by Background Execution Management; no other subsystem tracks its own view of whether the process is "alive," since that would risk disagreeing with the one subsystem actually positioned to know.

The unifying rule: **every piece of state has exactly one owning subsystem, and every other subsystem that needs it reads, never re-derives independently.** A future engineering decision that finds two subsystems each maintaining their own view of the same fact is, by this document's own principles, a defect to correct — not a modeling choice to accept.

## 16. Failure Isolation

- **A failure in Reference Context Resolution never blocks Ticket capture's durability step** — a Ticket that cannot be validated (missing precondition) is refused at the Ticketing module boundary, before it ever reaches Durable Capture; it is never captured in a broken state and never causes Durable Capture itself to fail.
- **A failure in Synchronization & Transport never touches Durable Capture's stored data** — delivery failure only delays the synced-state transition; the underlying record is unaffected, by construction (§12.5, §12.6).
- **A failure in Background Execution Management degrades *frequency* of capture and sync, never their *correctness*** — per §12.7's failure boundary, this is a deliberate, explicit non-overlap with Durable Capture's guarantee, so that the two subsystems' responsibilities are never confused with each other during an incident review.
- **A failure in Identity & Authorization Awareness (e.g., unable to determine current status) results in the same fail-closed posture the backend itself applies (ADR-007)** — Synchronization and Reference Context both treat "cannot verify" as equivalent to "not authorized" for the purpose of *ceasing new attempts*, never as license to proceed optimistically. This mirrors, at the ETM's own boundary, the same asymmetric-recoverability reasoning ADR-007 applies at the broker.
- **A failure in Observability never propagates anywhere** — by definition (§12.10's failure boundary), since an observability subsystem that can cause a correctness failure elsewhere has violated its own purpose.
- **A failure in Configuration & Session State degrades to "resolve from scratch"** — never to data loss, since nothing it holds is authoritative (§14).

The general isolation rule this architecture enforces: **a failure anywhere outside Durable Capture degrades some other quality (freshness, timeliness, visibility) — never correctness of a captured Ticket or Ping.** Durable Capture is the one subsystem whose failure would be a correctness failure, which is exactly why §12.5 gives it the narrowest possible dependency surface (none, on its write path) of any subsystem in this document.

## 17. Security Boundaries

- **The Device credential is the ETM's only security principal.** No subsystem models "the Conductor" as an authentication concept (Product §15, Domain §3.4) — Conductor identity is domain data carried on a Ticket, handled entirely within Ticketing's business validation (§12.3), never within Identity & Authorization Awareness (§12.1).
- **Authorization state is a value the ETM observes, never one it computes.** The ETM has no local logic that decides whether it is authorized — that determination is exclusively the backend's (ADR-007, ADR-009), and Identity & Authorization Awareness's entire job is to carry and propagate that externally-determined state faithfully, never to second-guess or locally override it.
- **A revoked or unverifiable Device stops attempting new outbound activity, but its already-durable local data is neither deleted nor exposed elsewhere.** This matches the backend's own framing (Workflow §15's Expected Outcome: a revoked Device's un-transmitted backlog "remain[s] on the Device, unreachable to the platform") — the architecture treats this as a named, accepted consequence, not a gap to silently work around locally.
- **No subsystem below the Identity boundary is trusted to make its own authorization decision.** Synchronization, Reference Context, Ticketing, and Telemetry all defer to Identity & Authorization Awareness's current state rather than independently interpreting a network or server error as an authorization signal — centralizing this interpretation in one subsystem is what prevents four different, potentially inconsistent, local guesses about "are we still allowed to do this."
- **The ETM enforces no cross-Device or cross-Operator boundary of its own**, because it structurally cannot violate one — it is, by construction, exactly one Device's worth of state, scoped to exactly one Operator (mirroring ADR-012's structural isolation at the backend, expressed here as "there is nothing else this Device's data could be confused with, because there is no second Device's data present to confuse it with").

## 18. Scalability Considerations

Scalability at the ETM's own architectural scope is narrow by design, consistent with the Architecture Review's framing that ETM-scale concerns are not the platform's hard scaling dimension (Architecture Review §15):

- **The ETM does not scale within a device** — it serves one Bus, one Conductor's attention at a time, at a bounded telemetry cadence and a human-bounded ticket-issuance rate. No subsystem in §12 is designed against a throughput requirement beyond what one Conductor and one Bus can generate.
- **The ETM scales *across* a fleet by replication, not by internal complexity** — every Device instance is architecturally identical and mutually unaware of every other; fleet-wide scale is a backend and Operator Dashboard concern (Product §6, Out of Scope), never an ETM architectural concern.
- **Durable Capture's storage footprint must remain bounded under a worst-case dead zone** — a multi-hour-to-multi-day offline period accumulating both Ticket and Telemetry records is an expected, not exceptional, load profile for this subsystem (Product §14, §17), and its data-retention/pruning behavior (post-sync) is a Technology Decision, not resolved here, but the architectural requirement — bounded local storage growth under sustained offline operation — is fixed at this level.
- **Synchronization's pacing (§12.6) is itself a scalability mechanism aimed at the shared broker infrastructure**, not at the ETM's own throughput — small, paced batches on reconnect protect a resource the ETM does not own (the broker and its concurrent-fleet reconnection load) rather than any resource internal to the ETM.

## 19. Extensibility Strategy

- **A third edge-generated event type** (the backend's own ADR-001, ADR-002, and ADR-008 all explicitly anticipate this, naming commuter location-sharing as an example) is added as a new feature module that depends on the same Shared Edge-Event Core (§12.5, §12.6) already serving Ticketing and Telemetry — it does not require a new durability or transport mechanism, only a new domain-validation layer analogous to §12.3 or §12.4.
- **A Conductor self-identification mechanism**, should one ever be introduced to address the misattribution risk named upstream (Domain Specification §17, item 1; Workflow §6), extends Identity & Authorization Awareness's domain (what the Device carries as its current Conductor attribute) without touching the Device-level authentication boundary itself (§12.1) — the architecture already separates "who the Device is" from "who it currently carries" (Domain Specification §5.1 vs. §5.2), so this extension has a boundary to attach to today.
- **A staleness bound on cached Reference Context**, once the domain defines one (Domain Specification §17, item 5), is a policy value Reference Context Resolution (§12.2) consumes — the subsystem is already structured to track staleness; only the threshold at which staleness becomes a refusal (rather than a warning) is undefined today, and adding it does not require restructuring the subsystem.
- **Ticket correction/void**, once the backend defines the mechanism (Domain Specification §17, item 3), is a new capture-time flow within Ticketing (§12.3) that produces a new, distinct Ticket referencing the original — it reuses Durable Capture and Synchronization exactly as ordinary issuance does, since a correction is "a new event referencing the original," never a mutation (Domain Specification §3, Principle 5), and therefore fits the existing capture pipeline without modification to it.
- **A stronger reconciliation-visibility signal**, should the backend ever expose one (Domain Specification §17, item 2 names this as open), extends Sync-Status & Reconciliation Honesty (§12.8) by adding a new observable state above "Synced" — because this subsystem already models "the furthest state the ETM can observe" as an explicit, extensible concept rather than a hardcoded two-state flag, this is additive, not a redesign.

## 20. Architectural Risks

- **OEM background-execution killing remains a partial, device-dependent mitigation, not a guarantee**, even with Background Execution Management (§12.7) doing everything an app-level architecture can do (Architecture Review §9). This document's entire durability design (§12.5) exists specifically so this risk's *worst case* — data loss — is architected out regardless, but the risk's *lesser* consequence (reduced capture/sync frequency on aggressively-managed devices) remains real and is not eliminated by this architecture, only bounded.
- **The distinction between "not authorized" and "no connectivity" may not be reliably observable at the signal level the ETM actually receives**, even though §12.1 and §17 assume this distinction is worth preserving architecturally. If the underlying platform signal genuinely cannot distinguish the two cases (Workflow §16 names this open at the workflow level), Identity & Authorization Awareness's architecture is prepared to propagate a distinction it may not always be able to make — this is a named limitation, not a claim that this architecture solves a problem the backend's own specification leaves open.
- **Reference Context staleness has no defined bound**, so Reference Context Resolution (§12.2) is architected to make staleness *observable* but cannot itself make a business judgment about when stale becomes unacceptable — that judgment, once made upstream, becomes a threshold this subsystem consumes (§19), but until then, the architecture's honesty obligation (§4, goal 3) is discharged by exposing the fact, not by silently guessing a bound.
- **Durable Capture's storage growth under a worst-case, multi-day dead zone is bounded only by device storage itself today** — no retention/pruning policy is fixed at this architectural level (§18); an unusually long field outage is an architectural risk to flag here even though its resolution is a Technology Decision, not resolved in this document.
- **The shared-core design (§6, §10) concentrates significant reliability responsibility in one place (Durable Capture, Synchronization)** — this is a deliberate trade-off (shared reliability guarantee vs. independent-feature risk isolation), consistent with ADR-011's own reasoning, but it means a defect in the Shared Edge-Event Core has a larger blast radius than a defect confined to one feature module would. This is named as an accepted risk, not an oversight, for the same reason ADR-011 accepts the equivalent trade-off at the backend.

## 21. Assumptions

Distinct from, and narrower than, the assumptions already named in the Product and Domain Specifications (Product §16, Domain §16), stated here only where they carry architectural consequence:

- The Android platform provides *some* mechanism (foreground service or equivalent) sufficient to sustain background execution across most, though not all, OEM battery-management configurations — Background Execution Management (§12.7) is architected around this being a genuine, if imperfect, capability, not around its absence.
- The device's local durable-storage mechanism (whatever a future Technology Decision selects) supports transactional writes strong enough to guarantee Durable Capture's (§12.5) core ordering property — this architecture assumes such a mechanism exists and is available on the operator-provisioned hardware class named in the Product Specification (§14), without naming the specific technology.
- A Device will typically, though not reliably, have some connectivity near the start of a shift (Product §16) — Reference Context Resolution (§12.2) is architected to *tolerate* this being false (operating with no cached context at all, per Workflow §5's failure case) but is not optimized primarily for that scenario, since it is named upstream as consequential-if-false but not yet the expected case.
- Exactly one Conductor's attention is directed at the ETM at a time — the architecture assumes a single active user context per Device at any instant (consistent with Domain Specification §5.2: "uses exactly one Device at a time"), and does not architect for concurrent multi-Conductor use of a single Device.

## 22. Platform Dependencies

This architecture depends on, and must never contradict:

- **ETM Product Specification** — scope, users, principles, and constraints this architecture serves (§5, §6, §13, §14, §18 referenced throughout).
- **ETM Domain Specification** — the entities, ownership, lifecycle, and domain events this architecture's subsystems are built to carry (§5, §8, §13, §14, §17 referenced throughout).
- **ETM Workflow Specification** — the operational sequences this architecture must support without contradiction (§5–§17 referenced throughout, especially the exceptional workflows §11, §12, §15, §16, §17).
- **Product Engineering Blueprint** — Part 7 (layered failure tolerance by system tier), Part 8 (component boundaries), Part 11 (offline-first philosophy), Part 19 (field conditions as baseline).
- **Architecture Review** — §8 (event-driven architecture), §9 (offline-first architecture, the OEM background-execution risk framing this document's §12.7 and §20 directly inherit), §16 (layered reliability philosophy, the direct model for this document's own failure-isolation reasoning in §16).
- **Deployment Architecture** — §9.1 (the Android Conductor Device's external communication boundary: MQTT broker and API service only).
- **ADR-001, ADR-002** (MQTT/Protobuf transport this architecture's Synchronization subsystem ultimately drives, without this document naming topics or schemas); **ADR-005** (QoS 1 and application-level dedup — the reason Synchronization, §12.6, treats duplicate delivery as routine, not exceptional); **ADR-007** (fail-closed authorization — the direct model for §12.1's and §17's authorization-state handling); **ADR-008** (LocalBuffer-before-network ordering — the direct model for §12.5's core guarantee); **ADR-009** (Device authentication scheme — why Identity, §12.1, manages a Device credential and never a Conductor one); **ADR-011** (Ticket and Telemetry as one reliability class — the direct justification for this architecture's Shared Edge-Event Core, §10, §12.5, §12.6); **ADR-013** (no cache is ever a source of truth — the principle §8's Principle 3 restates for Reference Context, and the principle §8's Principle 2 deliberately, explicitly departs from for Durable Capture, with the departure's reasoning stated there).
- **MQTT Specification** §12–§17 (trickle-sync mechanics, ordering, dedup, retry/backoff, connection lifecycle) — the backend-side contract this architecture's Synchronization subsystem (§12.6) is built to honor, without this document restating its parameters.
- **API Specification** §21 (offline synchronization has no REST role; `GET /v1/devices/me/trip` is a reference read, not a sync operation) — the direct basis for this architecture's distinction between Durable Capture/Synchronization (event publishing) and Reference Context Resolution (reference reading) as two structurally different data-flow shapes.

## 23. Open Architectural Questions

Carried forward from upstream documents where they have direct architectural consequence, plus questions this document itself surfaces:

1. **Where does the line sit between "Background Execution Management's job" and "an accepted, un-mitigated risk"?** OEM background-killing has no code-only fix (Architecture Review §9); this document assigns §12.7 the mitigation responsibility but does not, and cannot, define how much residual risk is architecturally acceptable versus a product/business decision to accept. (§20)
2. **Can "not authorized" and "no connectivity" actually be distinguished at the signal level available to the ETM**, or does this architecture's §12.1/§17 assumption of a clean distinction outrun what the underlying platform genuinely provides? This is inherited unresolved from Workflow §16 and is flagged here as an architectural question, not answered by this document. (§20)
3. **What is the correct local-storage retention/pruning policy for synced-but-historically-retained Tickets and Pings**, and does the Diagnostics subsystem (§12.8) need query access to synced history, or only to pending state? This document fixes that synced data is disposable for correctness purposes (§14) but leaves whether it is *actually* disposed of, and on what schedule, to a future Technology Decision.
4. **Does Reference Context Resolution (§12.2) need a distinct "no context ever resolved" state versus a "stale context" state**, given Workflow §5's failure case (a Device that has never resolved a Conductor/Trip at all) is architecturally and Conductor-experience-wise different from a Device operating on a merely-aging cache? This document's §12.2 responsibilities imply the distinction should exist but do not fully specify its shape.
5. **How does a future Conductor self-identification mechanism (§19) interact with the Device-is-the-only-security-principal boundary (§17) without weakening it?** This document deliberately keeps that boundary firm today, but flags that any future workflow addressing the misattribution risk (Domain Specification §17, item 1) will need to extend Identity's domain (§12.1) carefully, not create a second, competing authentication concept.
6. **Should the Shared Edge-Event Core (§10, §12.5, §12.6) be a single implementation unit, or two closely-coordinated ones that share only a contract?** This document fixes that Ticketing and Telemetry share *one reliability mechanism* (per ADR-011) but leaves whether that manifests as one module or two contract-adherent modules to the Technology Decisions document — an implementation question this document deliberately does not resolve.

---

*End of NammaRoute Conductor ETM System Architecture Specification v1.0.*
