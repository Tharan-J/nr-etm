# NammaRoute Conductor ETM — Functional Feature Specification
### `docs/etm-functional-feature-specification.md`

**Document type:** Functional Feature Specification — translates the Product, Domain, Workflow, Architecture, Technology, Reliability, and Data Contract Specifications into implementable product features. It is not a UI specification, not a Flutter implementation guide, and not an engineering coding document.
**Position in the hierarchy:** Derives from, and must not contradict, the ETM Product Specification, ETM Domain Specification, ETM Workflow Specification, ETM System Architecture Specification, ETM Technology Decisions, ETM Offline Synchronization and Reliability Specification, and ETM Data Contracts Specification. Feeds every future ETM UI Specification and Implementation Plan — neither of which redefines a feature's business behaviour or business rules fixed here, only its screens, interactions, and code.
**Status:** Living document, updated when a feature's business behaviour changes — not when a screen, endpoint, or library changes underneath it.

---

## 1. Purpose

This document defines *every functional capability of the ETM*, expressed strictly in business and behavioural terms: what each feature is for, who it serves, how it behaves — normally, offline, and under failure — what rules and validations govern it, and how its success is measured. It exists so that a future UI Specification and Implementation Plan have one authoritative, unambiguous source for *what to build*, leaving *how it looks* and *how it's coded* to documents downstream of this one.

Every feature below is derived, not invented. Each is traced to specific sections of the seven upstream ETM specifications and, through them, to the platform's ADRs. Where a feature's shape is genuinely undefined upstream — a real, recurring condition in this document set, not a drafting gap — this document says so explicitly in that feature's own **Open Questions**, rather than resolving it unilaterally. Consistent with the ETM's own product principle of honesty about what it does and doesn't know (Product Specification §13), this document is equally honest about what it does and doesn't yet define.

**What this document does not do:** it does not name a screen, a widget, a navigation flow, a package, a folder, a database table, an API endpoint, or an MQTT topic. Every one of those already has an authoritative home in an upstream document or belongs to a future one. Where this document must reference a mechanism to explain a business behaviour (e.g., "the platform validates referential integrity at ingestion"), it names that the mechanism exists without describing it.

## 2. How This Document Was Built

Before naming a single feature, every upstream document was read for what it already fixes:

- The **Product Specification** for scope, users, objectives, principles, and risks.
- The **Domain Specification** for entities, ownership, lifecycle, and domain events.
- The **Workflow Specification** for the actual business sequences a Conductor, an Operator Admin, and the platform jointly carry out.
- The **System Architecture Specification** for subsystem boundaries and responsibilities.
- The **Technology Decisions** document for scope-gating facts (what is deferred, what is MVP) without adopting any of its technology choices.
- The **Offline Synchronization and Reliability Specification** for the durability, consistency, and recovery guarantees every feature must honour.
- The **Data Contracts Specification** for the business promises every piece of exchanged information carries.

Related behaviour was then grouped into coherent, Conductor- or Operator-experienced product features — never into a technical subsystem dressed up as a feature. A feature exists here only if a real actor (Conductor, Operator Admin, or the platform acting on their behalf) experiences a business outcome from it. Where the objective brief's own illustrative feature list (Authentication, Passenger Category Selection, Application Updates, Profile, Help & Support, and others) names a capability no upstream specification actually supports, this document says so plainly rather than fabricating scope: several of those names do not survive contact with the seven specifications as first-class ETM features, and this document explains why in §13 (Future Feature Candidates) and §15 (Open Questions) rather than inventing behaviour for them.

## 3. Feature Classification

| Class | Definition | Features in this class |
|---|---|---|
| **Core Features** | The Conductor's essential, everyday capabilities — the reason the ETM exists (Product Specification §5). | Device Identity & Authorization Awareness; Reference Context Resolution; Trip Assignment & Lifecycle Awareness; Boarding & Destination Selection; Fare Determination; Ticket Issuance; Continuous Telemetry Origination; Durable Capture; Synchronization & Connectivity Recovery |
| **Supporting Features** | Capabilities that make the Core Features trustworthy and usable, without themselves being the reason the ETM exists. | Sync-Status & Reconciliation Honesty; Connectivity & Authorization Status Awareness; Locally Retained Ticket History |
| **Operational Features** | Capabilities that keep the ETM running correctly across the conditions the field actually produces. | Background Execution & Device Lifecycle Management; Battery Optimization Onboarding; Crash / Reboot / Process-Kill Recovery; Device Revocation Response; Device Replacement & Handoff Continuity |
| **Administrative Features** | Capabilities governing the Conductor's own working period and pairing, distinct from ticketing/telemetry themselves. | Shift Boundary Awareness; Conductor Pairing Awareness |
| **Cross-Cutting Features** | Capabilities that apply across every other feature rather than standing alone. | Fail-Closed Authorization Enforcement; Diagnostic Observability; Fleet Version Compatibility |

Nothing in this classification is a technology, a screen, or a subsystem name — every entry is a capability a Conductor, an Operator Admin, or the platform jointly experiences a business outcome from.

## 4. Feature Dependency Map

```
Device Identity & Authorization Awareness
        │
        ├──► Reference Context Resolution ──► Trip Assignment & Lifecycle Awareness
        │            │                                  │
        │            ▼                                  ▼
        │     Conductor Pairing Awareness      Boarding & Destination Selection
        │            │                                  │
        │            │                                  ▼
        │            │                          Fare Determination
        │            │                                  │
        │            └──────────────┬───────────────────┘
        │                           ▼
        │                    Ticket Issuance ───┐
        │                                       │
        ├──────────────────► Continuous Telemetry Origination
        │                                       │
        │                    ┌──────────────────┘
        │                    ▼
        │             Durable Capture
        │                    │
        │                    ▼
        │        Synchronization & Connectivity Recovery
        │                    │
        │                    ▼
        │      Sync-Status & Reconciliation Honesty ──► Locally Retained Ticket History
        │                    │
        └────────────────────┴──► Connectivity & Authorization Status Awareness

Background Execution & Device Lifecycle Management ──► sustains Continuous Telemetry Origination
                                                     └─► sustains Synchronization & Connectivity Recovery
Battery Optimization Onboarding ──► improves Background Execution & Device Lifecycle Management
Crash / Reboot / Process-Kill Recovery ──► re-derives from Durable Capture, resumes Synchronization
Device Revocation Response ──► halts Synchronization, Reference Context Resolution, Ticket Issuance's precondition
Device Replacement & Handoff Continuity ──► composes Device Revocation Response with a fresh Device Identity instance
Shift Boundary Awareness ──► frames, without gating, Ticket Issuance and Continuous Telemetry Origination

Fail-Closed Authorization Enforcement, Diagnostic Observability, and Fleet Version Compatibility
apply across every feature above rather than sitting at one point in this chain.
```

Two dependency facts carried directly from the Workflow Specification (§4) govern this map and are restated because later feature descriptions rely on them without re-deriving them:

- **Continuous Telemetry Origination does not depend on Trip Assignment, Reference Context Resolution, or Ticket Issuance.** It depends only on Device Identity being established (Workflow Specification §4; Domain Specification §5.5).
- **Ticket Issuance depends on Reference Context Resolution having successfully resolved a Trip, Conductor, and Fare Rule at least once.** Telemetry has no such dependency (Workflow Specification §4; Domain Specification §5.4, §11).

## 5. Core Features

### 5.1 Device Identity & Authorization Awareness

**Purpose:** Establish and continuously represent the ETM's own authenticated identity and current authorization state — the root every other feature depends on.

**Business Context:** The Device, never the Conductor, is the platform's authenticated identity; no Conductor-level credential exists anywhere in the platform (Product Specification §15; Domain Specification §3, Principle 4). This feature is what makes every other feature's authorization behaviour possible and honest.

**Business Value:** Gives the Operator confidence that only provisioned hardware can originate business records, and gives the Conductor a working device the instant it is powered on, without a login step that doesn't exist in this platform.

**Actors:** Conductor (initiates use); Operator Admin (provisions and revokes, entirely outside this feature's own operation); the platform (authenticates and authorizes).

**Dependencies:** None upstream within the ETM — this is the root of trust (System Architecture §12.1).

**Related Workflows:** Device Ready (Workflow Specification §5); Device Revocation (§15); Authentication Failure (§16).

**Related Domain Entities:** Device (Domain Specification §5.1).

**Related Architecture Modules:** Identity & Authorization Awareness (System Architecture §12.1).

**Related Data Contracts:** Device Identity (Data Contracts §7.1); Authorization State (§7.2).

**Preconditions:** The Device has already been provisioned and registered to a Bus by an Operator Admin — a prerequisite entirely outside this feature (Workflow Specification §5).

**Trigger:** The Conductor powers on or unlocks the Device and opens the ETM.

**Main Behaviour:**
1. The Device establishes connectivity and authenticates itself as the specific, provisioned identity it is.
2. The platform confirms the Device's current status permits operation and resolves its Bus pairing.
3. The Device becomes able to originate Telemetry immediately, independent of any Trip or Conductor context.
4. Authorization state is re-observed on every subsequent outbound interaction — never cached and reused across requests (Data Contracts §7.1, "Refresh Behaviour").

**Alternative Behaviour:** No connectivity at power-on — the Device proceeds into a degraded-but-operable state using its last-known pairing rather than blocking the Conductor from starting work (Workflow Specification §5, Alternative Flow).

**Offline Behaviour:**
- *Available offline?* Fully — the Device continues operating against its last-known status and pairing.
- *Recovery behaviour:* Automatic re-verification the moment connectivity returns; the platform's per-request verification is what makes revocation instant once it can be checked (Data Contracts §7.1).
- *User expectations:* The Conductor is never asked to "log in" a second time; readiness is a property of the Device, not a session the Conductor manages.

**Failure Behaviour:** The platform denies authentication outright (Authentication Failure, Workflow Specification §16) — the Device cannot become Ready at all, regardless of connectivity. The ETM cannot distinguish "wrong credential" from "correct credential, no longer authorized" from "platform temporarily unable to verify" — all three present identically (Data Contracts §7.1, "Failure Behaviour").

**Business Rules:**
- The Device, not the Conductor, is the sole authenticated identity (enforces Domain Specification §3, Principle 4).
- Revocation is unconditional and takes effect the moment the platform's own per-request verification next executes (enforces ADR-007, ADR-009).
- A Device not in an operable status cannot become Ready — a platform determination the Device cannot override (Workflow Specification §5).

**Validation Rules:**
- *Client:* None — the ETM performs no validation of its own credential's validity (Data Contracts §7.1).
- *Platform:* Exclusively responsible for all authentication and authorization determination.
- *Shared:* None.
- *Failure handling:* A denial is represented as a distinct, non-retryable-as-connectivity state (System Architecture §12.1, Failure Boundaries).

**Security Considerations:** This is the ETM's only security principal (System Architecture §17). Its compromise is the single most consequential event in the entire contract set (Data Contracts §13). No subsystem may model "the Conductor" as an authentication concept.

**Performance Expectations:** Readiness for Telemetry must be achievable independent of, and materially faster than, Reference Context resolution (Workflow Specification §5, Business Rules — "readiness for Telemetry and readiness for Ticketing are separable").

**Accessibility Considerations:** None specific to this feature beyond whatever general accessibility standard a future UI Specification adopts; this feature has no screen-specific interaction of its own beyond representing status.

**Observability:** Authorization-state transitions (authorized/denied/unknown) must be captured durably enough to survive a kill-and-restart, for engineering diagnosis (System Architecture §12.10).

**Acceptance Criteria:**
- ✓ A provisioned Device becomes Ready without any Conductor-entered credential.
- ✓ Telemetry origination is possible before Reference Context ever resolves.
- ✓ A revoked Device is refused on its next verification attempt, with no unbounded delay.
- ✓ "Not authorized" is never silently represented identically to a successful, cached state.

**Future Enhancements:** A Conductor self-identification mechanism, should the misattribution risk (§9.2 of this document) ever require one, would extend this feature's domain without weakening the Device-only authentication boundary (System Architecture §19, §23 item 5).

**Open Questions:** How a Device receives its initial credential and identity in the field — an ETM-app responsibility or a separate provisioning tool — is unresolved (Product Specification §21; Domain Specification §16, item 6; Workflow Specification §5). Whether "not authorized" and "no connectivity" can actually be distinguished at the signal level the ETM receives is inherited, unresolved (System Architecture §23 item 2; Workflow Specification §16).

---

### 5.2 Reference Context Resolution

**Purpose:** Resolve and cache the read-only business context — Trip, Fare Rule, Route Stop, Bus, Conductor pairing — every other feature depends on, and represent its staleness honestly.

**Business Context:** The ETM is an instrument, never an authority, over these facts (Domain Specification §3, Principle 1). It resolves them from the backend; it never authors them.

**Business Value:** Makes offline Ticket Issuance possible at all — without a cached, workable snapshot of this context, every Ticket would require a live network round-trip, directly contradicting the product's central design constraint (Product Specification §13).

**Actors:** The platform (produces); the Conductor (benefits, takes no direct action).

**Dependencies:** Device Identity & Authorization Awareness (§5.1) — a revoked Device cannot productively attempt resolution.

**Related Workflows:** Trip Assignment (Workflow Specification §7); Offline Operations (§11); Connectivity Recovery (§12).

**Related Domain Entities:** Trip, Fare Rule, Route Stop, Bus, Conductor (as pairing) — Domain Specification §5.3, §5.6, §5.7, §5.8, §5.2.

**Related Architecture Modules:** Reference Context Resolution (System Architecture §12.2).

**Related Data Contracts:** Operator, Bus, Route, Route Stop, Fare Rule, Trip, Conductor (Data Contracts §5.1–§5.8).

**Preconditions:** Device Identity is established (§5.1).

**Trigger:** Continuous, opportunistic, whenever connectivity allows — not gated on any Conductor action, and not on the Ticket/Telemetry synchronization cadence (Data Contracts §5.5, "Synchronization Behaviour").

**Main Behaviour:**
1. Attempt to resolve each context type (Trip, Fare Rule, Route Stop, Bus pairing, Conductor pairing) from the platform.
2. On success, replace the cached value wholesale — never an incremental patch (Data Contracts §5.2 through §5.7).
3. Track each cached value's age so a consuming feature (principally Ticket Issuance) can reason about staleness, even though no staleness bound is defined upstream (System Architecture §12.2).

**Alternative Behaviour:** The Device has never resolved a Conductor or Trip at all (a genuinely different condition from a merely-aging cache, named as an open architectural question — System Architecture §23 item 4) — Ticket Issuance cannot proceed until at least one resolution succeeds.

**Offline Behaviour:**
- *Available offline?* Partially — the last-known snapshot remains usable; a fresh read is not.
- *Recovery behaviour:* The next successful resolution attempt replaces the stale snapshot in full, on its own independent cadence, unblocked by the Ticket/Telemetry backlog (Reliability Specification §13.1).
- *User expectations:* Staleness is knowable, not hidden — but this feature cannot promise a bound at which staleness becomes unacceptable, because none is defined upstream (Reliability Specification §9.4).

**Failure Behaviour:** A failed resolution attempt costs nothing structurally — the ETM never held data this read was responsible for delivering (System Architecture §12.2, Failure Boundaries; API Specification §21). It degrades to "operate against the last-known value," never blocks, and never fabricates a value.

**Business Rules:**
- No entity read here can be assumed current while offline (enforces Domain Specification §12).
- A failed reference read never blocks a capture action (enforces Product Specification §13, Core Principle 2).
- Ordering within a Route is load-bearing; a stable order beyond the most recently cached one must never be assumed (Domain Specification §5.7).

**Validation Rules:**
- *Client:* Internal consistency of a selected boarding/destination pair against the cached sequence (consumed by §5.4).
- *Platform:* Definitional correctness of every Reference Contract (Data Contracts §9).
- *Shared:* None.
- *Failure handling:* Fall back to last-known value; never silently retry as though a connectivity gap were the same as an authorization denial (§5.1; ADR-007).

**Security Considerations:** No PII beyond a Conductor's name-level attribute (§9.2 of this document); ordinary Operator-scoped reference sensitivity otherwise (Data Contracts §13).

**Performance Expectations:** A resolution attempt must never block a capture action's own latency (System Architecture §4, "Performance").

**Accessibility Considerations:** Staleness must be representable in a form a future UI can surface plainly, not merely logged internally (System Architecture §4, "honest about what it does and doesn't know").

**Observability:** Per-context-type resolution attempts, successes, and failures should be logged durably for diagnosis (System Architecture §12.10).

**Acceptance Criteria:**
- ✓ Trip, Fare Rule, Route Stop, Bus, and Conductor pairing each resolve independently; a failure in one does not block another.
- ✓ A stale cached value is never presented as fresh.
- ✓ Resolution failure never blocks Ticket Issuance's own attempt to validate against whatever context is currently cached.
- ✓ Resolution proceeds on its own cadence, decoupled from the Ticket/Telemetry drain loop.

**Future Enhancements:** A staleness bound, once the domain defines one, is a policy value this feature consumes without restructuring (System Architecture §19).

**Open Questions:** No staleness bound is defined anywhere upstream for any Reference Contract (Domain Specification §17 item 5; Data Contracts §5.9 — named once there as the single most consequential open question the Data Contracts document inherits).

---

### 5.3 Trip Assignment & Lifecycle Awareness

**Purpose:** Give the Conductor's Ticket Issuance the Trip context it requires, and represent that context's own lifecycle (assigned, started, completed) honestly.

**Business Context:** Trip lifecycle transitions are exclusively an Operator Admin action; the ETM only ever reads them (Product Specification §15; Domain Specification §5.3).

**Business Value:** Anchors every sale to a real, accountable operational run, so revenue and occupancy reporting mean something specific rather than being merely "a fare sold sometime."

**Actors:** Operator Admin (assigns, starts, completes); the platform (resolves to the Device); Conductor (benefits, takes no lifecycle action).

**Dependencies:** Reference Context Resolution (§5.2), of which Trip is one instance.

**Related Workflows:** Trip Assignment (Workflow Specification §7); Trip Start (§8); Trip Completion (§13).

**Related Domain Entities:** Trip (Domain Specification §5.3).

**Related Architecture Modules:** Reference Context Resolution (System Architecture §12.2).

**Related Data Contracts:** Trip (Data Contracts §5.6).

**Preconditions:** The Trip already exists, scheduled against the correct Bus and Route (Workflow Specification §7).

**Trigger:** An Operator Admin schedules, starts, or completes a Trip; the Device attempts resolution whenever connectivity allows.

**Main Behaviour:**
1. The Device resolves which Trip it is currently assigned to as a reference lookup, not a sync operation.
2. Once the Operator Admin transitions the Trip to actively-running, subsequent Tickets are attributed to a live service instance.
3. Once the Operator Admin transitions the Trip to completed, further Tickets require a new Trip assignment.

**Alternative Behaviour:** A last-minute reassignment occurs after the Device already resolved an earlier assignment — the Device continues against its last-resolved assignment until it next successfully re-resolves (Workflow Specification §7, Alternative Flow).

**Offline Behaviour:**
- *Available offline?* Read-only access to the last-resolved assignment — fully available; a fresh resolution is not.
- *Recovery behaviour:* Next successful resolution replaces the snapshot in full.
- *User expectations:* A Trip cancelled or reassigned while disconnected will not be reflected until reconnection — a named, accepted risk (Domain Specification §13), not a defect.

**Failure Behaviour:** No connectivity to resolve a Trip assignment at all (the Device's first-ever attempt) — Ticket Issuance cannot proceed until resolution succeeds at least once (Workflow Specification §7, Failure Cases).

**Business Rules:**
- A Ticket's fare must be explainable by the Fare Rule active at the Trip's operative time (enforces Domain Specification §5.3).
- Trip Start requires both a Device and Conductor already assigned — a hard precondition the ETM cannot work around (Workflow Specification §8).
- A completed Trip never re-enters actively-running, even if the Bus continues moving (Workflow Specification §13).

**Validation Rules:**
- *Client:* A Ticket cannot be constructed without a resolved Trip context (Domain Specification §5.3).
- *Platform:* All Trip lifecycle-transition legality (Workflow Specification §8, §13, Failure Cases).
- *Shared:* None.
- *Failure handling:* Operate against the last-known assignment; never fabricate one.

**Security Considerations:** No PII; ordinary Operator-scoped reference sensitivity (Data Contracts §5.6).

**Performance Expectations:** Resolved once per Trip start, not re-resolved per Ticket (Data Contracts §5.5's framing, applying with equal force here per §5.6).

**Accessibility Considerations:** None distinct from §5.2.

**Observability:** Trip resolution attempts and the resolved Trip's lifecycle state should be logged for diagnosis of misattribution or stale-context incidents.

**Acceptance Criteria:**
- ✓ A Ticket is never captured without a resolved Trip.
- ✓ A Trip reassignment made while offline does not retroactively alter Tickets already captured against the prior assignment.
- ✓ Trip Completion is never initiated by the ETM itself.

**Future Enhancements:** None named upstream beyond the general staleness-bound candidate (§5.2).

**Open Questions:** No staleness bound is defined for how old a cached Trip assignment may be before the ETM should treat it as unreliable or warn the Conductor (Domain Specification §17 item 5; Workflow Specification §7).

---

### 5.4 Boarding & Destination Selection

**Purpose:** Let the Conductor identify the passenger's boarding and destination points along the current Trip's Route, anchoring both the Ticket and the Fare Rule lookup.

**Business Context:** A Route Stop's position within the current Trip's Route is read-only, Operator Admin-authored context (Domain Specification §5.7). This feature is the Conductor-facing consumption of that context, not its authorship.

**Business Value:** Turns an ambiguous "where did this passenger get on and off" into a structured, fare-computable business fact, without requiring the Conductor to know or enter a price directly.

**Actors:** Conductor (selects); the platform (defines and orders the underlying Route Stops).

**Dependencies:** Reference Context Resolution (§5.2), specifically Route Stop and Trip.

**Related Workflows:** Ticket Issuance (Workflow Specification §9, step 1).

**Related Domain Entities:** Route Stop (Domain Specification §5.7).

**Related Architecture Modules:** Ticket Capture & Validation (System Architecture §12.3), reading from Reference Context Resolution (§12.2).

**Related Data Contracts:** Route Stop (Data Contracts §5.4).

**Preconditions:** A Trip is resolved (§5.3); Route Stop data for that Trip's Route is cached.

**Trigger:** A passenger boards and states (or is understood to have) a destination; the Conductor begins recording the sale.

**Main Behaviour:**
1. The Conductor selects a boarding point and a destination point from the current Trip's Route Stop sequence.
2. The selection is checked for internal consistency against the cached sequence (e.g., destination reachable from boarding stop).
3. The validated boarding/destination pair is handed to Fare Determination (§5.5).

**Alternative Behaviour:** None distinct — this is a single, atomic selection step every Ticket requires.

**Offline Behaviour:**
- *Available offline?* Fully — selection operates entirely against cached Route Stop data; no live call is made.
- *Recovery behaviour:* The next successful Route Stop resolution replaces the cached sequence in full for subsequent selections; it does not retroactively revisit an already-captured Ticket.
- *User expectations:* A reorder or removal made upstream while the Device is disconnected will not be reflected until reconnection — a named, accepted risk (Domain Specification §5.7, §17 item 5).

**Failure Behaviour:** No cached Route Stop sequence exists at all for the current Trip's Route (a genuine first-resolution gap) — a boarding/destination pair cannot be selected and the Ticket cannot proceed (Domain Specification §5.4, hard precondition).

**Business Rules:**
- Ordering within a Route is load-bearing for fare and progress logic (enforces Domain Specification §5.7).
- Both boarding and destination references are required on every Ticket — neither is optional (enforces Data Contracts §6.1, "required fields").

**Validation Rules:**
- *Client:* Internal consistency of the selected pair against the cached Route Stop sequence.
- *Platform:* None distinct — the platform does not re-validate this pair independently of the Ticket it belongs to at ingestion beyond referential integrity (Data Contracts §6.1).
- *Shared:* None.
- *Failure handling:* Refuse the sale as an incomplete Ticket rather than allow a partial capture (System Architecture §12.3, Failure Boundaries).

**Security Considerations:** No PII; ordinary Operator-scoped reference sensitivity (Data Contracts §5.4).

**Performance Expectations:** Selection must feel instantaneous — it is a local, cached-data operation with no network dependency (Product Specification §18).

**Accessibility Considerations:** A future UI must make the boarding/destination selection legible to a Conductor whose attention is on passengers, not the device, per the Product Specification's own operational framing (§14) — a UI-layer concern this document flags without resolving.

**Observability:** Selection failures (no cached sequence available) should be logged for diagnosis distinct from an ordinary sale.

**Acceptance Criteria:**
- ✓ A boarding/destination pair can be selected with zero connectivity, provided a Route Stop sequence was ever previously cached.
- ✓ An internally inconsistent pair (destination not reachable from boarding stop on the cached sequence) is refused before capture.
- ✓ Selection never triggers a live network call.

**Future Enhancements:** A map-based stop-selection UI is named as a possible future trigger for a Maps technology evaluation, but is explicitly not required at MVP (Technology Decisions §5.20).

**Open Questions:** No staleness bound is defined for how old a cached Route Stop sequence may be before the ETM should refuse to issue a Ticket against it (Domain Specification §17 item 5; Data Contracts §5.4).

---

### 5.5 Fare Determination

**Purpose:** Compute the fare owed for a selected boarding/destination pair under the currently-active Fare Rule, and permanently fix that amount to the Ticket at the moment of capture.

**Business Context:** The ETM prices a specific sale on-device to support offline issuance, but never authors what a Fare Rule *is* — that remains an Operator Admin, Dashboard-side act (Domain Specification §5.6, "Notes").

**Business Value:** Protects operator revenue integrity by ensuring every fare is computed consistently against a defined rule, never left to ad hoc Conductor judgment, while still working with zero connectivity.

**Actors:** The platform (defines the Fare Rule); the Conductor (triggers the computation by completing boarding/destination selection).

**Dependencies:** Boarding & Destination Selection (§5.4); Reference Context Resolution (§5.2), specifically Fare Rule.

**Related Workflows:** Ticket Issuance (Workflow Specification §9, step 2).

**Related Domain Entities:** Fare Rule (Domain Specification §5.6).

**Related Architecture Modules:** Ticket Capture & Validation (System Architecture §12.3).

**Related Data Contracts:** Fare Rule (Data Contracts §5.5); Ticket (§6.1, the fare's permanent destination).

**Preconditions:** A valid boarding/destination pair is selected (§5.4); a Fare Rule applicable to that pair is resolvable, live or cached.

**Trigger:** Boarding/destination selection completes.

**Main Behaviour:**
1. Resolve the Fare Rule version active for the selected boarding/destination segment, from cache if no live connectivity exists.
2. Compute the fare amount under that rule.
3. Permanently snapshot the resulting amount onto the Ticket — never a live reference to the rule itself (Domain Specification §5.6, business rule).

**Alternative Behaviour:** None distinct from the normal path — fare computation is a single, deterministic step given a resolved rule and a valid segment.

**Offline Behaviour:**
- *Available offline?* Fully — computation uses only cached Fare Rule data; no live call is made.
- *Recovery behaviour:* The next successful Fare Rule resolution replaces the cached rule set for subsequent Tickets; it never retroactively reprices an already-captured Ticket.
- *User expectations:* A Fare Rule superseded upstream while disconnected will not be reflected until reconnection — Tickets may be priced under a rule the platform has already retired, and this is a named, accepted cost, not a defect (Domain Specification §11.2, "Fare Updated").

**Failure Behaviour:** No Fare Rule applicable to the selected segment can be resolved, live or cached — the fare cannot be determined and the sale cannot be captured (Workflow Specification §9, Failure Cases).

**Business Rules:**
- A Fare Rule change never retroactively reprices an already-issued Ticket (enforces Domain Specification §5.6).
- The ETM must apply the Fare Rule version actually valid for the Trip's operative time, from its cached set — not simply whichever version it happens to hold (Domain Specification §5.6, Validation Rules).
- A Ticket's fare, once captured, is immutable for the life of the record (enforces Domain Specification §7, rule 2).

**Validation Rules:**
- *Client:* That a resolvable Fare Rule exists for the selected segment and Trip time.
- *Platform:* Definitional correctness of the Fare Rule itself (Data Contracts §5.5).
- *Shared:* None.
- *Failure handling:* Refuse the sale rather than guess a fare or fall back to a default (Domain Specification §12).

**Security Considerations:** Directly revenue-sensitive; a defect here is a fare-leakage-accountability concern, not merely a UX one (Product Specification §10).

**Performance Expectations:** Computation must complete without a network round-trip, consistent with "ticket capture should feel instantaneous" (Product Specification §18).

**Accessibility Considerations:** None beyond a future UI's own responsibility to display the computed fare legibly.

**Observability:** A refusal due to an unresolvable Fare Rule should be logged distinctly from an ordinary successful computation, to help diagnose systemic staleness issues in the field.

**Acceptance Criteria:**
- ✓ A fare is computed and permanently fixed with zero connectivity, provided a Fare Rule was ever previously cached for the segment.
- ✓ A later Fare Rule change never alters an already-captured Ticket's fare.
- ✓ A Ticket cannot be captured if no Fare Rule can be resolved for its segment.

**Future Enhancements:** None named upstream.

**Open Questions:** No staleness bound is defined for how old a cached Fare Rule set may be before it should be treated as unreliable (Domain Specification §17 item 5; Data Contracts §5.5's dependence on the general staleness question named in §5.9 of that document). **Passenger-category or concession fare tiers are not named anywhere in the reviewed specification set** — this document does not invent a passenger-category concept; if the business intends differentiated fares by passenger type, that is a Domain Specification gap to close upstream before a corresponding ETM feature can be derived (see §15, item 6, of this document).

---

### 5.6 Ticket Issuance

**Purpose:** Capture a single fare sale as a durable, correctly-attributed business record — the ETM's primary reason for existing.

**Business Context:** A ticket sale is evidence of occupancy and route progress that nowhere else in the platform captures (Product Specification §3). This feature is the culmination of Reference Context Resolution, Boarding & Destination Selection, and Fare Determination into one committed business fact.

**Business Value:** Directly serves the product's first business goal — proving the ticket→track→display loop — and protects operator revenue integrity by making every sale attributable, durable, and never silently lost (Product Specification §10, §11).

**Actors:** Conductor (issues); Commuter (the fare payer, usually not a platform account at MVP); the platform (validates, deduplicates, reconciles).

**Dependencies:** Device Identity & Authorization Awareness (§5.1); Reference Context Resolution (§5.2); Boarding & Destination Selection (§5.4); Fare Determination (§5.5); Durable Capture (§5.8).

**Related Workflows:** Ticket Issuance (Workflow Specification §9).

**Related Domain Entities:** Ticket (Domain Specification §5.4).

**Related Architecture Modules:** Ticket Capture & Validation (System Architecture §12.3); Durable Capture (§12.5).

**Related Data Contracts:** Ticket (Data Contracts §6.1).

**Preconditions:** The Device is Ready (§5.1); a Trip is assigned and started (§5.3); a Conductor identity and applicable Fare Rule are resolvable, live or cached (§5.2, §5.5); a valid boarding/destination pair is selected (§5.4).

**Trigger:** A passenger boards and pays a fare; the Conductor records the sale.

**Main Behaviour:**
1. All hard preconditions (Trip, Conductor, Fare Rule, boarding/destination Route Stop pair) are checked against currently cached context.
2. The sale is captured as a Ticket, attributed to the current Trip, the currently-carried Conductor identity, and the Device itself, with the determined fare permanently fixed.
3. The Ticket is durably written to local storage before any network attempt is even considered (ADR-008; Reliability Specification §8).
4. Capture confirmation becomes available to the Conductor the instant the durable write completes — independent of network state (Reliability Specification §5).
5. The Ticket is later transmitted, deduplicated, and reconciled by the platform (§5.9 of this document).

**Alternative Behaviour:** The sale occurs with zero connectivity present — capture proceeds identically; nothing about the capture step itself requires network access (Workflow Specification §9, Alternative Flow).

**Offline Behaviour:**
- *Available offline?* Fully — capture requires no connectivity whatsoever.
- *Recovery behaviour:* No recovery needed for the capture act itself; recovery applies to synchronization (§5.9), never to durability, which is unconditional.
- *User expectations:* A Ticket's capture is never described to the Conductor as "at risk" merely because it hasn't yet synced — durability is established at capture, not at transmission (Reliability Specification §3).

**Failure Behaviour:**
- No Trip context resolvable at all, with no cached fallback — the sale cannot be captured.
- No Conductor identity resolvable — same outcome.
- No Fare Rule resolvable for the selected segment — same outcome.
- A previously-captured Ticket is later found erroneous — correction is a new record referencing the original; there is no reviewed mechanism yet for actually performing one (Workflow Specification §9, Open Questions).

**Business Rules:**
- A Ticket must never be lost between capture and reconciliation, regardless of connectivity (enforces Domain Specification §7, rule 3).
- A Ticket's fare never changes once captured (enforces rule 2, §5.5 above).
- A Ticket with no attributable Conductor is not a valid business record — the sale cannot be captured at all (enforces Domain Specification §7, rule 5).
- Duplicate transmission of the same sale must never produce a second fare charge (enforces ADR-005, ADR-011).

**Validation Rules:**
- *Client:* All hard preconditions (Trip, Conductor, Fare Rule, boarding/destination pair) checked against cached reference data before capture — a missing precondition is a refusal, never a partial or degraded Ticket (System Architecture §12.3).
- *Platform:* Referential integrity of the Trip, Fare Rule, and Route Stop references at ingestion, and a non-blocking Conductor/Device pairing plausibility check (Data Contracts §6.1, "Validation Expectations"; MQTT Specification §22.2).
- *Shared:* Structural/transport well-formedness — the ETM's domain-validation gate and the platform's decode/schema check catch different classes of defect; neither substitutes for the other (Data Contracts §9).
- *Failure handling:* A missing precondition is refused entirely within Ticket Capture & Validation; it never reaches durable storage as a malformed or partial record (System Architecture §12.3, Failure Boundaries).

**Security Considerations:** Fare-leakage-accountable and revenue-sensitive (Data Contracts §13). Carries an optional, nullable Commuter link, never populated by the ETM at MVP (Domain Specification §17 item 4).

**Performance Expectations:** Capture must feel instantaneous, regardless of network state — a UI-thread and local-write latency concern, decoupled entirely from network latency (Product Specification §18; System Architecture §4).

**Accessibility Considerations:** The capture flow must be usable by a Conductor whose attention is primarily on boarding passengers, not the screen (Product Specification §14) — a UI-layer responsibility this document names without resolving.

**Observability:** Capture attempts, durability confirmations, and precondition-refusal reasons should be logged durably (System Architecture §12.10).

**Acceptance Criteria:**
- ✓ A Ticket is durably captured with zero connectivity, provided Trip, Conductor, and Fare Rule context were previously cached.
- ✓ Capture confirmation is available to the Conductor the instant the durable write completes, never gated on sync.
- ✓ A Ticket missing any hard precondition is refused, not captured in a partial state.
- ✓ A Ticket's fare is identical, byte-for-byte, from capture through any later Fare Rule change.
- ✓ Duplicate delivery of the same Ticket never produces a duplicate fare charge (enforced platform-side, never the ETM's own responsibility to suppress).

**Future Enhancements:** A Ticket correction/void flow, once the platform defines the mechanism, composes as a new capture-time flow producing a new, distinct Ticket referencing the original — it reuses this feature's own capture pipeline without modification (System Architecture §19; Data Contracts §15).

**Open Questions:** No workflow, actor, or mechanism is defined anywhere for actually correcting or voiding an already-issued Ticket (Domain Specification §17 item 3; Workflow Specification §9, Open Questions). No mechanism exists for the ETM to learn a specific Ticket has been reconciled, as distinct from merely transmitted (Domain Specification §17 item 2).

---

### 5.7 Continuous Telemetry Origination

**Purpose:** Report the paired Bus's location and status at a regular, platform-defined cadence throughout the Device's operation.

**Business Context:** At MVP, the ETM is the Bus's sole source of location/status reporting (Product Specification §5). This is the ETM's second originating responsibility, structurally identical in reliability class to Ticket Issuance but carrying none of its business preconditions (ADR-011; Domain Specification §5.5).

**Business Value:** Generates the occupancy and route-progress signal the rest of the platform (ETA, Commuter tracking) depends on (Product Specification §10).

**Actors:** The Device (originates, without direct Conductor action); the platform (receives, deduplicates, reconciles).

**Dependencies:** Device Identity & Authorization Awareness (§5.1) only — deliberately independent of Reference Context Resolution, Trip Assignment, and Ticket Issuance (Workflow Specification §4).

**Related Workflows:** Continuous Telemetry (Workflow Specification §10).

**Related Domain Entities:** Telemetry Ping (Domain Specification §5.5).

**Related Architecture Modules:** Telemetry Origination (System Architecture §12.4); Durable Capture (§12.5).

**Related Data Contracts:** Telemetry Ping (Data Contracts §6.2).

**Preconditions:** The Device is Ready and authenticated (§5.1).

**Trigger:** Ongoing, at a regular, platform-defined adaptive cadence, for as long as the Device is operating — independent of whether a Trip is assigned or started.

**Main Behaviour:**
1. Capture a location/status reading at the platform-mandated cadence.
2. Write the reading durably before any network attempt is even considered.
3. Transmit the reading when connectivity allows; the platform correlates it to a Trip by time and position, never as a precondition of capture.

**Alternative Behaviour:** The Bus is stationary, between Trips, or has no current Trip assignment at all — Telemetry continues regardless, since it is not gated on Trip context (Workflow Specification §10, Alternative Flow).

**Offline Behaviour:**
- *Available offline?* Fully — capture requires no connectivity.
- *Recovery behaviour:* Resumes producing readings at its next scheduled cadence interval on reconnection; no "catch-up" reading is generated for the gap itself (Reliability Specification §16, step 5).
- *User expectations:* A gap in readings during a dead zone is a degraded-cadence condition, never an error requiring Conductor action.

**Failure Behaviour:** A sensor-read failure or degraded GPS quality is resumed at the next scheduled interval, never a reason to stop originating readings entirely (Reliability Specification §12.2).

**Business Rules:**
- Telemetry requires no Trip, Conductor, or Fare context to be captured (enforces Domain Specification §7, rule 12).
- A reading must never be silently lost; duplicate transmission is routine, never an error (enforces ADR-005).
- Telemetry carries the same durability contract as Ticket Issuance, but materially lower per-event stakes (Reliability Specification §2, goal 2).

**Validation Rules:**
- *Client:* A well-formed coordinate/status reading and the Device's own identity — no Trip or Conductor precondition (Domain Specification §5.5).
- *Platform:* Structural well-formedness (coordinate ranges, speed/heading bounds) and a plausibility signal the ETM has no visibility into or responsibility for (Data Contracts §6.2).
- *Shared:* None distinct from §5.6's structural/transport split.
- *Failure handling:* A degraded or failed reading is resumed at the next interval, never a reason to halt origination.

**Security Considerations:** No direct financial stakes; a location-data contract, though the ETM's own origination is a Device-level operational fact, not a Commuter-consent-gated feature (Data Contracts §6.2).

**Performance Expectations:** Cadence adapts per the platform's own telemetry contract (as often as every 8 seconds at full fleet scale), decoupled from Ticketing so neither responsibility starves the other (Product Specification §11, Objective 4; System Architecture §2, goal 2).

**Accessibility Considerations:** None — this feature has no Conductor-facing interaction of its own.

**Observability:** Cadence gaps, degraded readings, and capture/durability confirmations should be logged for diagnosis (System Architecture §12.10).

**Acceptance Criteria:**
- ✓ A reading is captured and durably buffered with zero connectivity and with no Trip currently assigned.
- ✓ A reading never blocks on, or is blocked by, Ticket Issuance's own activity.
- ✓ Cadence resumes automatically after any interruption, with no manual restart required.
- ✓ Duplicate delivery of the same reading never produces a duplicate business effect.

**Future Enhancements:** None named upstream beyond the platform's own general anticipation of a future third edge-generated event type (System Architecture §19).

**Open Questions:** None specific to this feature — its business shape is fully and unambiguously defined by the backend specifications (Workflow Specification §10, Open Questions).

---

### 5.8 Durable Capture

**Purpose:** Durably persist every captured Ticket and Telemetry Ping before any network attempt is even considered, and hold that data as the ETM's own actual (temporary) source of truth until the platform reconciles it.

**Business Context:** This is, in the platform's own words, the single most load-bearing design fact in the entire system (ADR-008), restated at the ETM's own boundary (System Architecture §12.5).

**Business Value:** This is the mechanism that makes the product's second objective — "no ticket is ever silently lost" — a lived guarantee rather than a stated aspiration (Product Specification §11).

**Actors:** Not directly actor-facing — a Conductor experiences this feature only as "my sale was captured, full stop," never as a subsystem name.

**Dependencies:** None on any other ETM feature for its core write path — deliberately, so that a durable write is never made contingent on Identity, Reference Context, or Synchronization being healthy (System Architecture §12.5).

**Related Workflows:** Offline Operations (Workflow Specification §11); underlies Ticket Issuance (§9) and Continuous Telemetry (§10).

**Related Domain Entities:** Ticket, Telemetry Ping (Domain Specification §5.4, §5.5, both at the Captured→Buffered transition).

**Related Architecture Modules:** Durable Capture / Local Buffer (System Architecture §12.5).

**Related Data Contracts:** Ticket, Telemetry Ping (Data Contracts §6.1, §6.2, "Authoritative Owner").

**Preconditions:** A domain-validated Ticket (§5.6) or Telemetry Ping (§5.7) has been submitted.

**Trigger:** Every submission from Ticket Issuance or Continuous Telemetry Origination.

**Main Behaviour:**
1. Write the record as an atomic, all-or-nothing operation to durable local storage.
2. Complete this write before any network attempt is even considered — never the reverse, with no exception for perceived urgency (ADR-008).
3. Maintain the record's local lifecycle state (Captured → Buffered → Synced) up to the furthest boundary the ETM can itself observe.
4. Expose pending records to Synchronization (§5.9) in a form that survives an arbitrary process kill.

**Alternative Behaviour:** None — this feature has exactly one behaviour, applied identically to both event types (ADR-011).

**Offline Behaviour:**
- *Available offline?* Fully — this is the mechanism that makes offline the normal condition rather than a degraded one.
- *Recovery behaviour:* Every recovery path re-derives its work exclusively from this feature's own durable state, never from in-memory assumption (Reliability Specification §10.1).
- *User expectations:* Nothing is ever "at risk" merely because it hasn't synced — durability, not transmission, is what the Conductor's confidence should rest on.

**Failure Behaviour:** A process killed *before* a write completes must never have allowed a network attempt in its place. A process killed *after* a write completes loses nothing (System Architecture §12.5, Failure Boundaries).

**Business Rules:**
- Local durability strictly precedes any network attempt, with no exception (enforces ADR-008; Reliability Specification §4, Principle 1).
- The ETM's own durable store is the actual, temporary source of truth for unsynced records — not a cache, not a convenience copy (enforces ADR-013's pattern, narrowly extended; Reliability Specification §4, Principle 2).
- Every other kind of local data (Reference Context) is always disposable — conflating the two is named upstream as the single most likely architectural mistake this system could make (Reliability Specification §4, Principle 3).

**Validation Rules:**
- *Client:* None beyond the domain validation already performed upstream (§5.4–§5.6) before a record ever reaches this feature.
- *Platform:* None — this feature has no platform counterpart of its own.
- *Shared:* None.
- *Failure handling:* Not applicable — a write either fully completes or is entirely absent; there is no ambiguous intermediate state to handle (Reliability Specification §8).

**Security Considerations:** A durable local backlog surviving a lost or stolen Device is a named, accepted consequence — this feature's guarantees apply regardless of whether the Device is later lost, and say nothing about, and are not a substitute for, whatever secure-storage mechanism governs the Device at rest (Reliability Specification §21).

**Performance Expectations:** The write itself must not become the bottleneck behind "ticket capture should feel instantaneous" (Product Specification §18).

**Accessibility Considerations:** None — this feature has no Conductor-facing interaction of its own.

**Observability:** Durability confirmations and any (theoretically impossible, per this feature's own guarantee) partial-write anomaly must be logged for engineering diagnosis (System Architecture §12.10).

**Acceptance Criteria:**
- ✓ A record durably captured before a process kill survives that kill unaffected.
- ✓ A record never reaches a partially-written, ambiguous state.
- ✓ A durable write never depends on Identity, Reference Context, or Synchronization being healthy.
- ✓ Both Ticket and Telemetry records share the identical durability guarantee, with no reduced-durability path for either.

**Future Enhancements:** A third edge-generated event type is expected to depend on this same mechanism without requiring a new durability design (System Architecture §19).

**Open Questions:** No local-storage retention/pruning policy exists for synced-but-historically-retained records; unbounded backlog growth under a worst-case, multi-day dead zone is a named, currently-unresolved reliability risk (Reliability Specification §22 item 2, §25 item 1).

---

### 5.9 Synchronization & Connectivity Recovery

**Purpose:** Deliver durably captured Tickets and Telemetry Pings to the platform when connectivity allows, paced deliberately, without ever being a precondition of capture itself.

**Business Context:** Composes the Workflow Specification's Offline Operations (§11) and Connectivity Recovery (§12) into a single, continuously-operating feature — the two are, in this feature's own terms, one mechanism observed under two different framings (a condition versus its resolution).

**Business Value:** Delivers the product's promise that connectivity is an optimization, never a precondition — and that a Conductor's entire day of sales and location reports genuinely reaches the platform, however long a dead zone lasted (Product Specification §13).

**Actors:** The Device (drains its own backlog); the platform (receives and reconciles).

**Dependencies:** Durable Capture (§5.8) as its sole source of work; Device Identity & Authorization Awareness (§5.1) — a recognized revocation must stop this feature from continuing to attempt delivery.

**Related Workflows:** Offline Operations (Workflow Specification §11); Connectivity Recovery (§12).

**Related Domain Entities:** Ticket, Telemetry Ping (at the Buffered→Synced transition).

**Related Architecture Modules:** Synchronization & Transport (System Architecture §12.6).

**Related Data Contracts:** Ticket, Telemetry Ping (Data Contracts §6.1, §6.2, "Synchronization Behaviour").

**Preconditions:** One or more records exist in Durable Capture's pending state.

**Trigger:** Both genuine network connectivity and a confirmed transport session become simultaneously present (the two-condition gate, Reliability Specification §7.1).

**Main Behaviour:**
1. Detect the two-condition gate is satisfied.
2. Drain Durable Capture's pending records in small, bounded, paced batches — oldest-first, within each event-type partition, independently (Reliability Specification §11.3, §11.5).
3. Mark a record synced only on confirmed transport acknowledgement, never earlier.
4. Continue draining until the backlog is exhausted, then resume ordinary per-event synchronization with no special "catch-up" behaviour thereafter.

**Alternative Behaviour:** Connectivity is lost again partway through recovery — the Device simply resumes Offline Operations and re-attempts recovery once connectivity returns again; there is no distinct "recovery within a recovery" handling (Workflow Specification §12, Alternative Flow).

**Offline Behaviour:**
- *Available offline?* Not applicable to this feature's own operation (it is, definitionally, inactive while offline) — but capture (§5.6, §5.7, §5.8) proceeds entirely unaffected.
- *Recovery behaviour:* Automatic and deterministic the moment the two-condition gate is satisfied; never dependent on a Conductor noticing a problem (Reliability Specification §2, goal 5).
- *User expectations:* Recovery is throttled deliberately, never a burst of the entire backlog at once, regardless of how large it has grown (Reliability Specification §11.5).

**Failure Behaviour:** A single record within an in-progress batch fails — the feature stops attempting the remaining records in that batch immediately and enters backoff, rather than continuing on the assumption only one record was affected (Reliability Specification §11.6). A transport failure never touches Durable Capture's stored data — it only delays the synced-state transition (System Architecture §12.6, Failure Boundaries).

**Business Rules:**
- Neither event type is prioritized over the other as a blanket rule (enforces ADR-011; Reliability Specification §11.4).
- Retry is triggered by publish failure alone — never by record age, perceived urgency, or event type (enforces Reliability Specification §11.1).
- Pacing protects the shared broker infrastructure, not the ETM's own throughput (enforces Reliability Specification §4, Principle 8).
- Duplicate delivery is expected, routine behaviour that this feature never attempts to suppress client-side (enforces ADR-005; Reliability Specification §14).

**Validation Rules:**
- *Client:* None — this feature owns no business-validation logic and no knowledge of Ticket/Ping domain fields beyond what transport requires (System Architecture §12.6, Failure Boundaries).
- *Platform:* Deduplication and reconciliation, entirely platform-side (ADR-005; Reliability Specification §11).
- *Shared:* None.
- *Failure handling:* A partially-succeeded batch is recorded precisely — already-acknowledged records remain Succeeded; unattempted or failed ones return to Retry Pending (Reliability Specification §11.7).

**Security Considerations:** Never attempts delivery using anything other than the Device's own authenticated identity; a recognized authorization denial always takes precedence over "keep retrying to avoid data loss" (Reliability Specification §21).

**Performance Expectations:** Connection-level backoff (≈1s initial, doubling, capped at 5 minutes) and publish-retry backoff (2s base, doubling, capped at 2 minutes) both apply, adopted from the platform's own defined curves, never independently re-derived by the ETM (Reliability Specification §11.2).

**Accessibility Considerations:** None — this feature's own operation has no direct Conductor interaction; its status is surfaced by §6.1 and §6.2.

**Observability:** Every delivery attempt, outcome, and backoff transition should be logged for diagnosis (System Architecture §12.10).

**Acceptance Criteria:**
- ✓ Synchronization never begins until both connectivity and a confirmed session exist simultaneously.
- ✓ A backlog accumulated over any duration drains in small, paced batches — never a single burst.
- ✓ A record is marked synced only on confirmed acknowledgement, never optimistically.
- ✓ Interrupted synchronization (mid-batch, mid-backoff) resumes identically after any restart, re-deriving entirely from Durable Capture.
- ✓ A recognized authorization denial halts further delivery attempts immediately.

**Future Enhancements:** None named upstream — this feature's mechanism is expected to serve any future third edge-generated event type unchanged (System Architecture §19).

**Open Questions:** What becomes of a revoked Device's undelivered backlog is genuinely unresolved (Workflow Specification §15, Open Questions; Reliability Specification §22 item 4). The actual field-measured connectivity profile that validates or contradicts this feature's batch-size and backoff parameters is not yet available (Reliability Specification §17, §25 item 4).

---

## 6. Supporting Features

### 6.1 Sync-Status & Reconciliation Honesty

**Purpose:** Give the Conductor an honest, architecturally-grounded answer to "did my sale go through," without ever overstating certainty the ETM does not have.

**Business Context:** Directly serves the product's third objective: a Conductor should always have an honest answer about their sale's status (Product Specification §11, Objective 3).

**Business Value:** Builds the trust the product's own success metrics name explicitly — "conductor-reported trust in the app's sync-status signal" (Product Specification §12).

**Actors:** Conductor (consumes); every upstream feature (Device Identity, Reference Context, Durable Capture, Synchronization) that supplies the underlying facts.

**Dependencies:** Read-only dependencies on Device Identity & Authorization Awareness (§5.1), Reference Context Resolution (§5.2), Durable Capture (§5.8), and Synchronization (§5.9) — this feature authors nothing and mutates no other feature's state.

**Related Workflows:** Ticket Issuance (Workflow Specification §9, Open Questions); Connectivity Recovery (§12, Open Questions).

**Related Domain Entities:** Ticket, Telemetry Ping (the "Reconciled" boundary each is subject to).

**Related Architecture Modules:** Sync-Status & Reconciliation Honesty / Diagnostics (System Architecture §12.8).

**Related Data Contracts:** Ticket, Telemetry Ping (Data Contracts §6.1, §6.2); Authorization State (§7.2).

**Preconditions:** None beyond the existence of at least one captured record or a currently-observable authorization/staleness state.

**Trigger:** Continuous — this feature aggregates state as it changes, and is queried whenever a future UI needs to display it.

**Main Behaviour:**
1. Aggregate, per Ticket or Ping, the furthest lifecycle state the ETM can actually observe: Captured, Buffered, or Synced — never Reconciled.
2. Aggregate current authorization state and reference-context staleness as distinct, non-conflated facts.
3. Never represent "transport-acknowledged" as "confirmed by the platform's authoritative record."

**Alternative Behaviour:** None distinct — this feature has one behaviour, applied uniformly to every record and every status dimension.

**Offline Behaviour:**
- *Available offline?* Fully — this feature reflects locally-known state and requires no live call of its own.
- *Recovery behaviour:* Not applicable — this feature has no durable-write obligation of its own; its own failure or unavailability degrades visibility, never correctness (System Architecture §12.8, Failure Boundaries).
- *User expectations:* A sync status the ETM cannot verify is represented as unverified, never as confirmed (Reliability Specification §3).

**Failure Behaviour:** This feature's own failure must never affect capture, durability, or sync — it is a pure observability layer over state those features already hold (System Architecture §12.8, Failure Boundaries).

**Business Rules:**
- The ETM is never falsely reassuring about what has and hasn't reached the backend (enforces Reliability Specification §2, goal 4).
- "Synced" is the furthest state this feature may ever claim — "Reconciled" is not observable and must never be implied (enforces Domain Specification §17 item 2).

**Validation Rules:**
- *Client:* None — this is a read-only aggregation, not a validated business action.
- *Platform:* None.
- *Shared:* None.
- *Failure handling:* Not applicable.

**Security Considerations:** None distinct from the features it reads from.

**Performance Expectations:** Status must be derivable from already-durable state without a network round-trip.

**Accessibility Considerations:** A future UI must be able to represent three genuinely distinct states (authorized/denied/unknown; fresh/stale; captured/buffered/synced) without collapsing any two of them into one signal — a UI-layer responsibility this document names without resolving.

**Observability:** This feature is itself a Conductor-facing observability layer; its own internal aggregation logic should additionally be covered by engineering-facing Diagnostic Observability (§9.2 of this document).

**Acceptance Criteria:**
- ✓ A Ticket's displayed status never exceeds "Synced" until a stronger signal is ever defined upstream.
- ✓ Authorization state, staleness, and sync state are never conflated into a single, ambiguous signal.
- ✓ This feature's own failure never blocks or corrupts capture, durability, or sync.

**Future Enhancements:** A stronger reconciliation-visibility signal, should the platform ever expose one, extends this feature by adding a new observable state above "Synced" — additive, not a redesign, because this feature already models "the furthest state the ETM can observe" as an extensible concept (System Architecture §19; Data Contracts §15).

**Open Questions:** The Conductor has no way to confirm a Ticket, or a recovered backlog, has actually reached the platform's authoritative record, as opposed to merely being transmitted (Workflow Specification §12, Open Questions; Domain Specification §17 item 2).

---

### 6.2 Connectivity & Authorization Status Awareness

**Purpose:** Represent the Device's current connectivity and authorization condition honestly and distinctly, so a Conductor is never left guessing why the ETM behaves as it does.

**Business Context:** "Not authorized" and "no connectivity" are two genuinely different conditions with different remedies (an Operator Admin action versus simply waiting for signal), yet the underlying platform signal may not always make them cleanly distinguishable — a named, unresolved limitation (Workflow Specification §16; System Architecture §23 item 2).

**Business Value:** Prevents a Conductor from wasting effort troubleshooting a connectivity problem that is actually an authorization denial, or vice versa, and reduces confused escalations to an Operator Admin.

**Actors:** Conductor (observes); Device Identity & Authorization Awareness (§5.1) and the platform's own connectivity signal (jointly produce the underlying facts).

**Dependencies:** Device Identity & Authorization Awareness (§5.1); Synchronization & Connectivity Recovery (§5.9), specifically its two-condition connectivity gate.

**Related Workflows:** Authentication Failure (Workflow Specification §16); Offline Operations (§11).

**Related Domain Entities:** None directly — this feature represents state, not a business entity.

**Related Architecture Modules:** Identity & Authorization Awareness (System Architecture §12.1); Synchronization & Transport's connectivity signal (§12.6).

**Related Data Contracts:** Authorization State (Data Contracts §7.2); Session/Connection State (§7.3).

**Preconditions:** None.

**Trigger:** Continuous — any transition in connectivity or authorization state.

**Main Behaviour:**
1. Observe the platform's per-request authorization determination and the transport layer's connectivity/session state.
2. Represent each as a distinct value: authorized / denied / unknown-pending-verification, and offline / recovering / online / synchronizing / degraded / disconnected.
3. Never carry forward "I was last authorized" as "I am currently authorized" during a connectivity gap — the honest representation is "unknown, pending next verification" (Data Contracts §7.2, "Offline Behaviour").

**Alternative Behaviour:** Connectivity is flapping (repeated short Online/Offline transitions) — represented via ordinary retry/backoff handling, with no special-cased "degraded" UI state distinct from what the underlying signal already carries (Reliability Specification §7, "Degraded").

**Offline Behaviour:**
- *Available offline?* Fully — this feature's entire purpose is to represent the offline condition itself.
- *Recovery behaviour:* Updates automatically the instant the underlying signal changes; no user action required.
- *User expectations:* "Offline" is never conflated with "not authorized" where the underlying signal permits telling them apart.

**Failure Behaviour:** The underlying platform signal genuinely cannot distinguish "not authorized" from "no connectivity" in some cases — this feature is prepared to propagate a distinction it may not always be able to make, a named limitation, not a claim this document resolves (System Architecture §23 item 2).

**Business Rules:**
- Fail-closed is never relaxed by a reliability concern — a recognized denial always takes precedence over "keep retrying" (enforces ADR-007; Reliability Specification §21).
- A stale reference-data read is represented as stale, never as current (enforces Product Specification §18).

**Validation Rules:**
- *Client:* None — pure observation.
- *Platform:* Authoritative for the actual authorization determination (§5.1).
- *Shared:* None.
- *Failure handling:* An unverifiable state is treated as "cannot currently confirm," never silently upgraded to "confirmed."

**Security Considerations:** This feature is what makes fail-closed a lived behaviour rather than a stated policy — every consuming feature that gates on this signal treats "cannot verify" as equivalent to "not authorized" for the purpose of ceasing new attempts (Data Contracts §7.2).

**Performance Expectations:** Must reflect state changes without a perceptible delay, since it is read-only aggregation over already-observed signals.

**Accessibility Considerations:** A future UI must present these as clearly distinguishable states, not merely a single "problem" icon — a UI-layer responsibility this document flags without resolving.

**Observability:** State transitions should be logged for engineering diagnosis of field connectivity patterns.

**Acceptance Criteria:**
- ✓ Authorization and connectivity are always represented as two distinct signals, never merged into one.
- ✓ "Unknown, pending verification" is a genuine, distinct state during an offline period — never silently treated as "still authorized."
- ✓ A recognized denial is represented in a way a Conductor could plausibly distinguish from an ordinary connectivity gap, wherever the underlying signal supports the distinction.

**Future Enhancements:** None named upstream.

**Open Questions:** Whether "not authorized" and "no connectivity" can genuinely be distinguished at the signal level available to the ETM is inherited, unresolved (System Architecture §23 item 2; Workflow Specification §16, Open Questions). What, if anything, the ETM should communicate to distinguish them is left to a future UI Specification decision (Workflow Specification §16).

---

### 6.3 Locally Retained Ticket History

**Purpose:** Retain a Conductor-visible record of recently issued Tickets for the current period of use, at a level of persistence this document deliberately scopes narrowly.

**Business Context:** The System Architecture Specification names this possibility explicitly but narrowly: a synced-but-not-yet-known-to-be-reconciled record "may be retained locally for Conductor-facing history at a future feature's discretion" (System Architecture §14). This document exercises that discretion by naming the feature, while deliberately not inventing a retention policy no upstream document defines.

**Business Value:** Lets a Conductor self-serve a basic "what have I sold today" answer without contacting an Operator Admin, and gives partial reassurance beyond the per-Ticket sync-status signal (§6.1) for a Conductor reviewing their own shift.

**Actors:** Conductor (views); Durable Capture (§5.8) and Synchronization (§5.9) (jointly supply the underlying records).

**Dependencies:** Durable Capture (§5.8); Sync-Status & Reconciliation Honesty (§6.1), for each listed Ticket's own status.

**Related Workflows:** Ticket Issuance (Workflow Specification §9); Shift Completion (§14, as the natural point a Conductor might want to review this history).

**Related Domain Entities:** Ticket (Domain Specification §5.4).

**Related Architecture Modules:** Durable Capture (System Architecture §12.5, "Data Ownership" table); Sync-Status & Reconciliation Honesty (§12.8).

**Related Data Contracts:** Ticket (Data Contracts §6.1, "Lifecycle").

**Preconditions:** At least one Ticket has been captured during the retention window this feature is scoped to.

**Trigger:** The Conductor requests to view their own recent sales.

**Main Behaviour:**
1. Read Durable Capture's own held records (both pending and, per its own discretion, synced-but-retained ones).
2. Present each Ticket's business facts (Trip, boarding/destination, fare, timestamp) alongside its Sync-Status & Reconciliation Honesty (§6.1) state.
3. Never claim a status stronger than "Synced" for any listed Ticket, exactly as §6.1 already governs.

**Alternative Behaviour:** No retention policy has yet fixed how long a synced Ticket remains visible here — this document does not invent one; a future Technology Decision determines the actual retention/pruning schedule (System Architecture §18, §23 item 3).

**Offline Behaviour:**
- *Available offline?* Fully — this feature reads only already-durable local data.
- *Recovery behaviour:* Not applicable — no durable-write obligation of its own.
- *User expectations:* History is never lost merely because of a connectivity gap; it may, in principle, eventually be pruned per a future retention policy this document does not fix.

**Failure Behaviour:** This feature's own failure or unavailability degrades visibility only, never the underlying Ticket data's own durability or correctness (mirroring System Architecture §12.8's failure-boundary reasoning).

**Business Rules:**
- Never represents a listed Ticket's status more confidently than Sync-Status & Reconciliation Honesty (§6.1) itself would (enforces Domain Specification §17 item 2).
- Never permits editing, voiding, or otherwise mutating a listed Ticket — a Ticket, once captured, is never modified (enforces Domain Specification §7, rule 10).

**Validation Rules:**
- *Client:* None — a read-only view over already-validated, already-captured records.
- *Platform:* None.
- *Shared:* None.
- *Failure handling:* Not applicable.

**Security Considerations:** Carries the same revenue-sensitivity as the underlying Ticket data (Data Contracts §13); a lost or stolen Device exposes this history exactly as it exposes the underlying backlog (Reliability Specification §21).

**Performance Expectations:** Must read from already-durable local storage without a network dependency.

**Accessibility Considerations:** A future UI must make this history legible without implying stronger certainty than §6.1 supports — a UI-layer responsibility this document flags without resolving.

**Observability:** None distinct from Durable Capture's own (§5.8).

**Acceptance Criteria:**
- ✓ A Conductor can view their own recently issued Tickets with zero connectivity.
- ✓ No listed Ticket ever displays a status beyond what §6.1 can honestly support.
- ✓ No mechanism in this feature permits mutating a listed Ticket.

**Future Enhancements:** A defined retention/pruning policy, once a future Technology Decision fixes one, directly bounds this feature's own retention window without requiring a redesign of the feature itself.

**Open Questions:** What the correct local-storage retention/pruning policy is for synced-but-historically-retained records, and at what point unbounded backlog growth under a worst-case dead zone becomes an operational problem, is deferred to a future Technology Decision (Reliability Specification §25 item 1; System Architecture §23 item 3). Whether "Expired" or "Archived" deserve to be first-class states distinct from "Succeeded, retained for local history" is not resolved by any upstream document (Reliability Specification §6, §25 item 5).

---

## 7. Operational Features

### 7.1 Background Execution & Device Lifecycle Management

**Purpose:** Keep Telemetry Origination, Durable Capture, and Synchronization running across screen-off, backgrounding, and OEM battery-management conditions.

**Business Context:** This is the direct architectural response to the platform's single highest-ranked risk — OEM background-execution killing, which has no code-only fix (Product Specification §17; Architecture Review §9).

**Business Value:** Protects the product's fourth objective — that the same device reliably serves both ticketing and telemetry without either starving the other — specifically against the risk most likely to defeat it in the field (Product Specification §11).

**Actors:** Conductor (benefits, and is asked to cooperate via §7.2); the Android OS (the actor whose behaviour this feature works to accommodate).

**Dependencies:** None — this feature is a platform-integration concern every other feature's continued operation depends on, not the reverse (System Architecture §12.7).

**Related Workflows:** Offline Operations (Workflow Specification §11), to the extent a background-execution interruption is one of its triggers.

**Related Domain Entities:** None directly.

**Related Architecture Modules:** Background Execution & Device Lifecycle Management (System Architecture §12.7).

**Related Data Contracts:** None directly — this feature sustains the execution context Operational Contracts depend on, rather than being itself a contract.

**Preconditions:** The Device is Ready (§5.1).

**Trigger:** App start, backgrounding, or an OS-level lifecycle event.

**Main Behaviour:**
1. Maintain a foreground-service posture (or equivalent) sufficient to keep the capture-and-sync chain alive while the Conductor's attention is elsewhere.
2. Detect a kill-and-restart event and trigger recovery (§7.3) automatically.
3. Expose its own health so a restart is detected without Conductor intervention.

**Alternative Behaviour:** None distinct — this feature operates continuously and identically regardless of foreground/background state, by design.

**Offline Behaviour:**
- *Available offline?* Fully — this feature has no connectivity dependency of its own.
- *Recovery behaviour:* A restart triggers Synchronization to resume draining Durable Capture exactly as it would after any other reconnect (§7.3).
- *User expectations:* A restart is invisible to the Conductor except as a brief interruption in cadence, never as data loss.

**Failure Behaviour:** This feature's own failure (a process genuinely killed and not promptly restarted) is explicitly **not** a data-loss event, because Durable Capture (§5.8) already guarantees that independently — this feature's job is to minimize how *often* and how *long* capture and sync are interrupted, never to be the thing standing between an interruption and data loss (System Architecture §12.7, Failure Boundaries).

**Business Rules:**
- A failure here degrades *frequency*, never *correctness* (enforces System Architecture §16).
- OEM background-killing is a partial, device-dependent mitigation, never eliminated (Product Specification §17; System Architecture §20).

**Validation Rules:** Not applicable — this feature performs no business validation.

**Security Considerations:** None distinct beyond sustaining the execution context Identity and Synchronization depend on.

**Performance Expectations:** Must sustain the platform's adaptive telemetry cadence (as fine as 8-second intervals) across most, though not all, OEM battery-management configurations (Technology Decisions §5.9).

**Accessibility Considerations:** None directly — see §7.2 for the Conductor-facing cooperation this feature depends on.

**Observability:** Restart events, background-execution lifecycle transitions, and their frequency should be logged durably (System Architecture §12.10).

**Acceptance Criteria:**
- ✓ Telemetry and Synchronization resume automatically after a kill-and-restart, with no manual Conductor action.
- ✓ A background-execution interruption never causes data loss, only a frequency reduction.
- ✓ This feature's own health is observably distinguishable from a genuine data-loss event.

**Future Enhancements:** None named upstream beyond continued OS-version-driven mitigation refinement.

**Open Questions:** Where the line sits between "this feature's mitigation responsibility" and "an accepted, unmitigated risk" is not, and cannot be, resolved by this document — it is a product/business risk-acceptance decision (System Architecture §23 item 1, §20).

---

### 7.2 Battery Optimization Onboarding

**Purpose:** Help a Conductor (or, more commonly, an Operator Admin at provisioning time) exempt the ETM from aggressive OEM battery management, improving — never guaranteeing — Background Execution & Device Lifecycle Management's (§7.1) effectiveness.

**Business Context:** Named directly as a System Architecture responsibility of Background Execution Management: "support an onboarding flow that helps a Conductor disable aggressive OEM battery optimization" (System Architecture §12.7).

**Business Value:** Reduces, at the point of greatest leverage (first setup), the single risk both the Product Specification and Architecture Review rank highest.

**Actors:** Conductor or Operator Admin (whoever completes device setup); the Android OS (whose settings this feature guides the actor toward).

**Dependencies:** Device Identity & Authorization Awareness (§5.1), since this onboarding is meaningful only once the Device itself is provisioned.

**Related Workflows:** Device Ready (Workflow Specification §5), as a natural point this onboarding would occur.

**Related Domain Entities:** None directly.

**Related Architecture Modules:** Background Execution & Device Lifecycle Management (System Architecture §12.7).

**Related Data Contracts:** None directly.

**Preconditions:** The Device is provisioned and running the ETM for the first time, or an Operator Admin/Conductor revisits this step later.

**Trigger:** First app launch, or an explicit later re-entry into this flow.

**Main Behaviour:**
1. Detect whether the Device's current OS-level battery-management configuration is aggressive enough to threaten background execution.
2. Guide the actor toward the OS-level setting that exempts the app, understood as a partial, device-dependent mitigation — never a guarantee this feature is designed to assume succeeds (System Architecture §12.7).

**Alternative Behaviour:** The actor declines or is unable to complete the exemption — the ETM continues operating; Durable Capture's guarantee is unaffected regardless (§5.8), only cadence and sync frequency are at greater risk.

**Offline Behaviour:**
- *Available offline?* Fully — this is a local, on-device settings interaction with no network dependency.
- *Recovery behaviour:* Not applicable — this is a one-time (or rarely revisited) setup action, not a recurring operational cycle.
- *User expectations:* Skipping this step does not disable ticketing or telemetry; it only leaves the device more exposed to OEM interference.

**Failure Behaviour:** The OS itself may not expose an exemption path on some device models — a genuine, named limitation this feature cannot work around (System Architecture §21).

**Business Rules:**
- This feature's success or failure never gates the Device's own operability — it is an improvement, not a precondition (Product Specification §13, Core Principle — connectivity/device conditions never block capture).

**Validation Rules:** Not applicable — this feature performs no business validation of Ticket or Telemetry data.

**Security Considerations:** None distinct.

**Performance Expectations:** None distinct — a one-time or rarely-repeated setup interaction.

**Accessibility Considerations:** Should be clear enough for an Operator Admin or Conductor unfamiliar with Android settings to complete correctly — a UI-layer concern this document flags without resolving.

**Observability:** Whether the exemption was successfully granted should be logged, to help correlate later background-execution incidents with device configuration.

**Acceptance Criteria:**
- ✓ The onboarding flow can be completed without connectivity.
- ✓ Declining or being unable to complete it never blocks Ticket Issuance or Telemetry Origination.
- ✓ The exemption's success/failure state is observable for later diagnosis.

**Future Enhancements:** None named upstream.

**Open Questions:** None specific beyond the general residual-risk question named in §7.1.

---

### 7.3 Crash / Reboot / Process-Kill Recovery

**Purpose:** Resume correct operation automatically after any interruption — an application crash, a process restart, or a full device reboot — without depending on anything other than durably captured state.

**Business Context:** Recovery is a function of durable state alone, never of in-memory state that happened to survive (ADR-008, restated at ETM scope — System Architecture §13; Reliability Specification §10.1).

**Business Value:** Delivers the product's fifth reliability goal — deterministic, automatic recovery, never dependent on a Conductor noticing a problem (Reliability Specification §2, goal 5).

**Actors:** Not directly Conductor-facing — experienced only as "the app keeps working" after any interruption.

**Dependencies:** Durable Capture (§5.8), the sole source every recovery path re-derives from; Background Execution & Device Lifecycle Management (§7.1), which detects the restart trigger.

**Related Workflows:** Offline Operations (Workflow Specification §11); Connectivity Recovery (§12).

**Related Domain Entities:** Ticket, Telemetry Ping (whatever was pending at the moment of interruption).

**Related Architecture Modules:** Durable Capture (System Architecture §12.5); Synchronization & Transport (§12.6); Background Execution Management (§12.7).

**Related Data Contracts:** Ticket, Telemetry Ping (Data Contracts §6.1, §6.2, "Synchronization Behaviour").

**Preconditions:** An interruption (crash, restart, or reboot) has occurred.

**Trigger:** Any of: an unhandled exception or OS-forced kill; an OS restart of a previously-killed service; a full device reboot and subsequent app launch.

**Main Behaviour:**
1. Read Durable Capture's existing state fresh — never assumed from any in-memory value.
2. Treat any record found in a pending state as eligible for the next drain attempt, exactly as after an ordinary reconnect.
3. Resume the ordinary paced, oldest-first, per-partition drain loop the moment the two-condition connectivity gate is satisfied.
4. Independently re-attempt Reference Context resolution on its own cadence, in parallel.
5. Resume Telemetry Origination at its next scheduled cadence interval, with no special "catch-up" reading.

**Alternative Behaviour:** None — the recovery sequence does not branch on which of the three triggers caused the interruption (Reliability Specification §16).

**Offline Behaviour:**
- *Available offline?* Fully — recovery of durable state requires no connectivity; only the drain-resumption step (item 3 above) requires it.
- *Recovery behaviour:* This feature *is* the recovery behaviour.
- *User expectations:* No distinct "recovering" experience beyond an ordinary reconnect; the Conductor is never asked to take a corrective action.

**Failure Behaviour:** Not applicable in the sense of a further failure mode distinct from an ordinary connectivity gap — recovery is designed to be indistinguishable in kind from ordinary Offline Operations (§5.9) resuming.

**Business Rules:**
- No recovery path assumes a record was "in flight" unless it is also, independently, durably persisted and observable as pending (enforces ADR-008).
- The recovery mechanism does not scale in kind with the severity of the interruption — only in the size of the backlog it must drain (Reliability Specification §10.1).

**Validation Rules:** Not applicable — this feature performs no business validation of its own.

**Security Considerations:** No retry or recovery behaviour ever attempts delivery using anything other than the Device's own authenticated identity, and fail-closed is never relaxed by a reliability concern (Reliability Specification §21).

**Performance Expectations:** Recovery must be triggered automatically and promptly on detection of the interruption, with no manual restart required in the ordinary case.

**Accessibility Considerations:** None — this feature has no Conductor-facing interaction of its own.

**Observability:** Every recovery trigger and its outcome should be logged durably, since these events correlate directly with the platform's own highest-ranked risk (System Architecture §12.10).

**Acceptance Criteria:**
- ✓ A crash, restart, or reboot never loses any record whose durable write had already completed.
- ✓ Recovery resumes the ordinary drain loop without any distinct "post-crash" mode.
- ✓ Recovery does not require the Conductor to notice or act.

**Future Enhancements:** None named upstream.

**Open Questions:** None specific to this feature beyond those already named for Durable Capture (§5.8) and Synchronization (§5.9).

---

### 7.4 Device Revocation Response

**Purpose:** Represent an instant, unconditional withdrawal of the Device's authorization honestly, and stop all outbound activity the moment it is recognized, without losing or exposing already-captured data.

**Business Context:** Revocation is the platform's response to a lost or stolen phone, a decommissioning, or a Conductor's departure — valid from any operational status the Device holds, including mid-Trip (Workflow Specification §15).

**Business Value:** Bounds the damage a lost or stolen device can do, directly serving the platform's fail-closed security posture (ADR-007, ADR-009) while still protecting whatever the Conductor had already legitimately captured.

**Actors:** Operator Admin (initiates, entirely outside this feature); the platform (enforces); Conductor (experiences the consequence).

**Dependencies:** Device Identity & Authorization Awareness (§5.1), whose observed denial this feature reacts to.

**Related Workflows:** Device Revocation (Workflow Specification §15).

**Related Domain Entities:** Device (Domain Specification §5.1).

**Related Architecture Modules:** Identity & Authorization Awareness (System Architecture §12.1); the halting behaviour it imposes on Synchronization (§12.6) and Reference Context Resolution (§12.2).

**Related Data Contracts:** Device Identity (Data Contracts §7.1); Authorization State (§7.2).

**Preconditions:** The Device currently holds some operable status.

**Trigger:** An Operator Admin revokes the Device via the Dashboard (entirely outside this feature).

**Main Behaviour:**
1. The next verification attempt (any authenticated interaction) is refused by the platform.
2. This feature recognizes the denial and propagates it as a distinct state, never merged with "offline."
3. Synchronization (§5.9) and Reference Context Resolution (§5.2) both stop attempting new outbound activity.
4. Already-durable local data remains on the Device, neither deleted nor exposed elsewhere.

**Alternative Behaviour:** The Device was already offline at the moment of revocation — nothing changes for it until it next attempts to reconnect, at which point revocation takes full effect (Workflow Specification §15, Alternative Flow).

**Offline Behaviour:**
- *Available offline?* Not applicable to this feature's own trigger — but a Device already offline at the moment of revocation continues operating (capturing, never syncing) until its next connection attempt.
- *Recovery behaviour:* Not automatic in the way a connectivity gap is — resolving revocation requires the underlying cause to be addressed, most commonly an Operator Admin restoring the Device's status (Workflow Specification §16).
- *User expectations:* The Conductor cannot resolve this state themselves by retrying or waiting.

**Failure Behaviour:** A Device already actively connected at the moment of revocation may retain its existing session's ability to transmit until that session is next re-established — a named, bounded exception to "instant," not a contradiction of it (Workflow Specification §15).

**Business Rules:**
- Revocation is valid from any operational status, including mid-Trip (enforces Workflow Specification §15).
- When the platform cannot verify status for any reason, it denies by default (enforces ADR-007).
- Data already durably captured remains safely on-device, neither deleted nor exposed, for the duration of the denial (enforces Reliability Specification §21).

**Validation Rules:**
- *Client:* None — the ETM has no local logic that decides it is authorized (System Architecture §17).
- *Platform:* Exclusively responsible for the revocation determination.
- *Shared:* None.
- *Failure handling:* An unverifiable state is treated identically to a confirmed denial for the purpose of ceasing new attempts (ADR-007).

**Security Considerations:** This feature is the direct enforcement point for the platform's fail-closed posture at the ETM's own boundary — no retry or recovery behaviour ever attempts to work around a recognized denial (Reliability Specification §21).

**Performance Expectations:** The refusal must take effect on the very next verification attempt, with no cached-authorization grace period (Data Contracts §7.1, "Refresh Behaviour").

**Accessibility Considerations:** A future UI must represent this state distinctly from an ordinary connectivity gap, wherever the underlying signal supports that distinction (see §6.2).

**Observability:** Revocation recognition events should be logged durably, distinct from ordinary connectivity-failure logging.

**Acceptance Criteria:**
- ✓ A revoked Device's next verification attempt is refused, with no unbounded grace period.
- ✓ Already-captured data is neither lost nor exposed once revocation is recognized.
- ✓ Synchronization and Reference Context Resolution both cease new attempts on recognizing the denial.

**Future Enhancements:** None named upstream.

**Open Questions:** What becomes of a revoked Device's own not-yet-transmitted backlog — whether it is ever expected to reach the platform via some out-of-band process, or is simply lost from the platform's perspective — is not addressed by any reviewed specification (Workflow Specification §15, Open Questions).

---

### 7.5 Device Replacement & Handoff Continuity

**Purpose:** Support the operational reality that a Bus's Device is sometimes lost, stolen, damaged, or swapped, and that a Conductor sometimes hands the Device to a relief Conductor mid-operation.

**Business Context:** Device Replacement is a composition of three Operator Admin primitives (revoke, register, re-pair), not a first-class backend operation in its own right (Workflow Specification §17). Handoff is a related but distinct condition named as a real, expected occurrence, not an edge case (Product Specification §16).

**Business Value:** Minimizes the operational disruption of a lost or swapped device, and names the misattribution risk a handoff creates honestly rather than silently.

**Actors:** Operator Admin (performs the replacement/re-pairing); Conductor (resumes operation, or hands off mid-shift).

**Dependencies:** Device Revocation Response (§7.4), typically the first half of a replacement; Device Identity & Authorization Awareness (§5.1), for the new Device's own first-run.

**Related Workflows:** Device Replacement (Workflow Specification §17); Shift Start (§6), sharing the same misattribution risk.

**Related Domain Entities:** Device (Domain Specification §5.1); Conductor (as pairing, §5.2).

**Related Architecture Modules:** Identity & Authorization Awareness (System Architecture §12.1).

**Related Data Contracts:** Device Identity (Data Contracts §7.1); Conductor (§5.7).

**Preconditions:** The Bus's current Device is being retired from service, commonly following or alongside a revocation.

**Trigger:** A Device is lost, stolen, damaged beyond use, or otherwise needs to be swapped for a new physical unit.

**Main Behaviour:**
1. An Operator Admin revokes the outgoing Device, if not already done (§7.4).
2. An Operator Admin provisions and registers a new Device against the same Bus.
3. An Operator Admin re-pairs the currently-assigned Conductor (or a new one) to the new Device.
4. The new Device proceeds through its own first-run Device Identity & Authorization Awareness (§5.1) instance.
5. Ticketing and Telemetry resume under the new Device's own identity; the outgoing Device's history remains intact and attributed to it as captured.

**Alternative Behaviour:** The replacement happens between shifts, with no Trip actively running — the simpler case, requiring no judgment call about mid-Trip continuity (Workflow Specification §17, Alternative Flow).

**Offline Behaviour:**
- *Available offline?* The new Device's own first-run proceeds exactly as any other Device Ready instance (§5.1) — fully tolerant of no connectivity at power-on.
- *Recovery behaviour:* Not applicable beyond what §5.1 already covers for the new Device.
- *User expectations:* The outgoing Device's own captured, not-yet-synced data is a separate concern governed entirely by §7.4 — this feature does not merge or transfer it to the new Device.

**Failure Behaviour:** An Operator Admin attempts to register the new Device against the Bus before the outgoing one has been unassigned or revoked — refused, since a Bus may only have one currently-operable Device paired to it at a time (Workflow Specification §17, Failure Cases).

**Business Rules:**
- The outgoing Device's historical Tickets and Telemetry Pings are never altered, reattributed, or merged into the new Device's identity (enforces Workflow Specification §17).
- Trip continuity across the swap is a business judgment for the Operator Admin, never an automated ETM behaviour (Workflow Specification §17).
- A Bus may only have one currently-operable Device paired to it at a time (Workflow Specification §17).

**Validation Rules:**
- *Client:* None — this feature involves no ETM-side business validation beyond what §5.1 already performs for the new Device's own first-run.
- *Platform:* Enforces the single-operable-Device-per-Bus constraint.
- *Shared:* None.
- *Failure handling:* A premature registration attempt is refused; it is never silently accepted.

**Security Considerations:** Identical to §5.1 and §7.4 for the respective outgoing and incoming Devices — no new security boundary is introduced by this feature.

**Performance Expectations:** None distinct from §5.1's own expectations for the new Device.

**Accessibility Considerations:** None distinct.

**Observability:** The revocation-then-registration sequence should be logged in a way that lets an Operator Admin later reconstruct which Device served a given Bus at a given time.

**Acceptance Criteria:**
- ✓ A new Device's first-run never inherits, merges, or overwrites the outgoing Device's own historical records.
- ✓ Registration of a new Device against a Bus already holding an active pairing is refused, not silently accepted.
- ✓ The Conductor is never left unable to operate the Bus longer than the Operator Admin's own provisioning sequence requires.

**Future Enhancements:** None named upstream.

**Open Questions:** No single, named workflow for "device replacement" exists anywhere in the backend specifications — this feature is, by the Workflow Specification's own admission, a composition of primitives, not a first-class operation (Workflow Specification §17, Open Questions). Whether a Trip actively running on the outgoing Device at the moment of replacement can or should transfer to the new Device mid-run is not addressed by any reviewed specification.

---

## 8. Administrative Features

### 8.1 Shift Boundary Awareness

**Purpose:** Frame, for the Conductor's own working-period understanding, the start and end of their period of carrying and operating the Device — without gating any ETM capability on it.

**Business Context:** "Shift" is a real, Conductor-experienced operational boundary named directly in the Product Specification's persona and operational descriptions, but it has **no corresponding domain event, status, or record anywhere in the platform** (Workflow Specification §6, §14, Open Questions). This document treats it as a real feature the Conductor experiences, while being explicit that no backend representation of it currently exists.

**Business Value:** Gives the Conductor a mental frame for "my period of responsibility for this Device," even though the platform itself cannot yet observe or bound that period directly.

**Actors:** Conductor.

**Dependencies:** Device Identity & Authorization Awareness (§5.1); Conductor Pairing Awareness (§8.2), whose currently-attributed identity this feature's framing relies on.

**Related Workflows:** Shift Start (Workflow Specification §6); Shift Completion (§14).

**Related Domain Entities:** None directly — this document's own upstream sources are explicit that no entity models "shift" (Domain Specification §16, item; Workflow Specification §6, Open Questions).

**Related Architecture Modules:** None directly — this feature is Conductor experience framed over existing subsystems, not a subsystem of its own.

**Related Data Contracts:** None directly.

**Preconditions:** The Device is Ready (§5.1); the Conductor is the one currently paired to it, per the Operator Admin's prior action.

**Trigger:** The Conductor begins or ends their working period with the Device.

**Main Behaviour:**
1. The Conductor takes possession of the Device already paired to them.
2. Ticket Issuance (§5.6) and Continuous Telemetry (§5.7) proceed exactly as they would at any other point — this feature adds no gate, no check, and no state transition of its own.
3. The Conductor ends their working period; the Device continues to originate Telemetry independent of this fact.

**Alternative Behaviour:** A relief Conductor takes over the Device mid-operation without an Operator Admin re-pairing action having yet occurred — this is the same handoff condition named in §7.5 and §8.2, and this feature does not resolve the resulting misattribution risk.

**Offline Behaviour:**
- *Available offline?* Fully — this feature has no data of its own to synchronize; it is purely a Conductor-experienced framing over already-offline-tolerant features.
- *Recovery behaviour:* Not applicable.
- *User expectations:* Nothing about beginning or ending a shift blocks, delays, or is delayed by ticketing or telemetry.

**Failure Behaviour:** None distinct — this feature has no platform-side transition it can fail, since it corresponds to no domain event (Workflow Specification §14, Failure Cases).

**Business Rules:**
- Shift Completion does not, by itself, unassign the Conductor from the Device or revoke anything — those remain exclusively Operator Admin actions (enforces Workflow Specification §14).
- The Device's own Telemetry origination is never gated on a Conductor's shift boundary (enforces Workflow Specification §10, §14).

**Validation Rules:** Not applicable — this feature has no business validation of its own, since no entity models it.

**Security Considerations:** None distinct — no authentication concept attaches to a shift boundary (Domain Specification §3, Principle 4).

**Performance Expectations:** None distinct.

**Accessibility Considerations:** None distinct.

**Observability:** Not applicable at the platform level, since no domain event exists to observe; a future UI-level "shift" concept, if introduced, would need its own local, ETM-only representation, explicitly understood as not backend-observed.

**Acceptance Criteria:**
- ✓ Beginning or ending a shift never blocks, gates, or delays Ticket Issuance or Continuous Telemetry.
- ✓ No platform-side record of a shift boundary is asserted or implied to exist by this feature.

**Future Enhancements:** Whether a first-class "shift started"/"shift ended" domain event should exist — to more precisely bound a Conductor's attributable working period than "whatever Ticket carries their conductor_id" — is an open question for a future domain or feature decision (Workflow Specification §6, Open Questions).

**Open Questions:** The platform has no way to distinguish "the Conductor's shift ended, and a new Conductor will pick this Device up later" from "the same Conductor will resume with this Device shortly" — both look identical from the platform's perspective until a new Ticket is issued or an Operator Admin acts (Workflow Specification §14, Open Questions).

---

### 8.2 Conductor Pairing Awareness

**Purpose:** Ensure every Ticket carries the Device's currently-attributed Conductor identity, and name the misattribution risk a stale pairing creates honestly rather than silently.

**Business Context:** No Conductor authentication scheme exists anywhere in the platform — pairing is an Operator Admin, Dashboard-side action, and the Device carries whichever Conductor identity it last successfully resolved (Domain Specification §3, Principle 4; §5.2).

**Business Value:** Makes every Ticket attributable to a specific staff member, which the product's revenue-accountability and adoption goals both depend on (Product Specification §10).

**Actors:** Operator Admin (pairs, via the Dashboard); Conductor (carries the resulting attribution); the platform (resolves and supplies the pairing).

**Dependencies:** Reference Context Resolution (§5.2), specifically the Conductor pairing instance; Device Identity & Authorization Awareness (§5.1), the pairing mechanism.

**Related Workflows:** Shift Start (Workflow Specification §6); Ticket Issuance (§9).

**Related Domain Entities:** Conductor (Domain Specification §5.2).

**Related Architecture Modules:** Reference Context Resolution (System Architecture §12.2).

**Related Data Contracts:** Conductor (Data Contracts §5.7).

**Preconditions:** An Operator Admin has previously paired some Conductor identity to this Device.

**Trigger:** Ticket Issuance's own attempt to resolve a currently-assigned Conductor (§5.6).

**Main Behaviour:**
1. Resolve the Device's currently-cached Conductor pairing.
2. Attribute that identity to every Ticket subsequently captured, until the pairing next changes.
3. Opportunistically re-resolve the pairing whenever connectivity allows, replacing the cached value wholesale.

**Alternative Behaviour:** A relief Conductor takes over the Device without an Operator Admin re-pairing action having yet occurred — Tickets continue to be attributed to whichever Conductor identity the Device still carries, not the Conductor physically holding it (Workflow Specification §6, Failure Cases).

**Offline Behaviour:**
- *Available offline?* Fully — the last-known pairing remains usable indefinitely.
- *Recovery behaviour:* The next successful resolution replaces the cached pairing in full.
- *User expectations:* A Conductor handoff mid-shift, without a corresponding Operator Admin action, is a real, expected occurrence this feature does not silently paper over — it is named as an active risk (Product Specification §17).

**Failure Behaviour:** No Conductor identity is currently resolvable at all (a genuine first-resolution gap) — a Ticket cannot be captured (Domain Specification §5.2, Business Rules).

**Business Rules:**
- A Ticket with no attributable Conductor is not a valid business record (enforces Domain Specification §7, rule 5).
- The ETM has no mechanism to validate that its cached pairing is still current, since no Conductor-side authentication exists anywhere to check against (Domain Specification §5.2, Validation Rules).

**Validation Rules:**
- *Client:* That *some* Conductor identity is currently resolvable before permitting capture.
- *Platform:* A non-blocking Conductor/Device pairing plausibility check at Ticket ingestion — a mismatch is treated as at least as plausibly a benign timing lag as a genuine anomaly, and never blocks persistence (Data Contracts §9; MQTT Specification §22.2).
- *Shared:* None.
- *Failure handling:* No resolvable Conductor identity refuses the Ticket entirely, never a partial attribution.

**Security Considerations:** A stale Conductor pairing is a data-quality/attribution incident, categorically distinct from a Device credential compromise, which is a security incident — this document does not conflate the two (Data Contracts §5.7, §13).

**Performance Expectations:** Resolved opportunistically, not on the Ticket/Telemetry synchronization cadence (Data Contracts §5.7).

**Accessibility Considerations:** None distinct.

**Observability:** Pairing resolution attempts and failures should be logged for diagnosis of misattribution incidents after the fact.

**Acceptance Criteria:**
- ✓ Every captured Ticket carries a Conductor identity; none is ever captured without one.
- ✓ A pairing change made upstream is reflected in subsequently captured Tickets the moment the ETM next successfully resolves it.
- ✓ No mechanism silently "corrects" a stale pairing without an actual re-resolution.

**Future Enhancements:** A future Conductor self-identification mechanism, should one be introduced to address this feature's own named risk, would extend the Conductor's carried attribute without touching the Device-level authentication boundary itself (System Architecture §19, §23 item 5).

**Open Questions:** Since pairing is exclusively an Operator Admin, Dashboard-side action, an offline mid-shift handoff between two Conductors has no domain mechanism to correct the Device's carried identity until connectivity returns and an admin acts (Domain Specification §17 item 1; Data Contracts §5.7, §18 item 2). This is named consistently across every upstream document as a genuine, unresolved gap — not a defect specific to this feature.

---

## 9. Cross-Cutting Features

### 9.1 Fail-Closed Authorization Enforcement

**Purpose:** Ensure that every feature gating an outbound attempt on authorization treats an unverifiable state exactly as it treats a confirmed denial — never as a license to proceed optimistically.

**Business Context:** This is a single platform-wide posture, restated at the ETM's own boundary, not independently decided per feature (ADR-007; System Architecture §16). It is named here as its own cross-cutting feature because it recurs identically across Synchronization (§5.9), Reference Context Resolution (§5.2), and Device Revocation Response (§7.4), and stating it once, centrally, is what prevents four different, potentially inconsistent, local interpretations of the same underlying rule.

**Business Value:** Makes the platform's asymmetric-recoverability reasoning — an unrecoverable trust failure is always worse than a recoverable data-delivery delay — a lived guarantee at the ETM's own boundary, not merely a backend-side policy.

**Actors:** Not directly actor-facing — a Conductor experiences this only through the honest state representations of §6.1 and §6.2.

**Dependencies:** Device Identity & Authorization Awareness (§5.1), the single subsystem every other feature defers to for this state, rather than independently interpreting a network or server error as an authorization signal.

**Related Workflows:** Device Revocation (Workflow Specification §15); Authentication Failure (§16).

**Related Domain Entities:** None directly.

**Related Architecture Modules:** Every subsystem in System Architecture §12 that gates on authorization state (§12.1, §12.2, §12.6).

**Related Data Contracts:** Authorization State (Data Contracts §7.2).

**Preconditions:** None — this rule applies continuously.

**Trigger:** Any outbound attempt by any feature.

**Main Behaviour:**
1. Every feature that would make an outbound attempt consults Device Identity & Authorization Awareness's current state before proceeding.
2. "Cannot verify" is treated identically to "denied" for the purpose of ceasing new attempts — never as license to proceed.
3. No feature independently infers "probably revoked" from a pattern of failures; each consults the one authoritative state.

**Alternative Behaviour:** None — this rule has no alternative path by design.

**Offline Behaviour:**
- *Available offline?* This rule applies during a connectivity gap exactly as it does when connected — an unverifiable state during an offline period is "unknown, pending verification," never silently treated as "still authorized" (Data Contracts §7.2).
- *Recovery behaviour:* Resumes evaluating fresh the moment verification can next occur.
- *User expectations:* No feature ever "keeps retrying to avoid data loss" at the expense of this rule (Reliability Specification §21).

**Failure Behaviour:** Not applicable — this feature is itself the failure-handling rule other features rely on.

**Business Rules:**
- An unrecoverable trust failure is always treated as strictly worse than a recoverable one (enforces ADR-007).
- No subsystem below the authorization boundary is trusted to make its own authorization decision (enforces System Architecture §17).

**Validation Rules:** Not applicable — this is itself a validation-gating rule, not a validated business record.

**Security Considerations:** This is, in effect, the security posture of the entire ETM stated as a single cross-cutting rule rather than scattered across each feature's own description.

**Performance Expectations:** Must never introduce a delay distinguishable from the underlying authorization check itself.

**Accessibility Considerations:** None directly.

**Observability:** Every instance of this rule being invoked (a feature ceasing an attempt due to an unverifiable or denied state) should be logged, tagged consistently so an incident review can distinguish a platform-wide verification outage from routine, isolated denials.

**Acceptance Criteria:**
- ✓ No feature ever proceeds with an outbound attempt when authorization state is unknown or denied.
- ✓ No feature independently infers an authorization state from indirect evidence (e.g., a pattern of transport failures).
- ✓ This rule applies identically across Synchronization, Reference Context Resolution, and any future feature with an outbound attempt of its own.

**Future Enhancements:** None named upstream — this is a fixed platform-wide posture, not one this document expects to evolve independently of the backend's own ADR-007.

**Open Questions:** None distinct from §5.1's and §6.2's own open questions about whether "not authorized" and "no connectivity" can genuinely be distinguished at the signal level.

---

### 9.2 Diagnostic Observability

**Purpose:** Make the ETM's own engineering-facing behaviour — as distinct from the Conductor-facing signal in §6.1 — inspectable after the fact, especially after exactly the kind of kill-and-restart event Background Execution Management (§7.1) is built to survive.

**Business Context:** Named directly as a distinct subsystem from Sync-Status & Reconciliation Honesty precisely because the two serve different audiences with different honesty obligations (System Architecture §12.10 versus §12.8).

**Business Value:** Gives engineering the ability to diagnose field incidents — a defect, an unusually long dead zone, a battery-optimization interference pattern — without which the reliability guarantees named throughout this document could not be verified or improved over time.

**Actors:** Not Conductor-facing at all — consumed exclusively by engineering tooling.

**Dependencies:** None functionally — every other feature may emit to this one, but nothing depends on it to operate correctly, by design (System Architecture §12.10).

**Related Workflows:** None specific — this feature spans every workflow rather than belonging to one.

**Related Domain Entities:** None directly.

**Related Architecture Modules:** Observability (System Architecture §12.10).

**Related Data Contracts:** None directly — this feature is explicitly not a Diagnostics Contract in the Conductor-facing sense (Data Contracts §4, distinguishing Sync/Reconciliation Status from Operational Log Record).

**Preconditions:** None.

**Trigger:** Any lifecycle or error event from any other feature.

**Main Behaviour:**
1. Capture structured operational events — capture attempts, durability confirmations, sync attempts and outcomes, authorization-state changes, background-execution lifecycle transitions — durably enough to survive the same failure modes the rest of the system survives.
2. Surface crash information for post-incident diagnosis.
3. Avoid capturing business-sensitive payload contents beyond what diagnosing a reliability problem actually requires.

**Alternative Behaviour:** None distinct.

**Offline Behaviour:**
- *Available offline?* Fully — logging requires no connectivity; upload, where applicable, is itself offline-tolerant (queues locally, uploads on reconnect).
- *Recovery behaviour:* Not applicable in the sense of data at risk — this feature's own failure never propagates to any capture, durability, or sync path (System Architecture §12.10, Failure Boundaries).
- *User expectations:* Not Conductor-facing; no user-facing expectation applies.

**Failure Behaviour:** This feature's own failure must never propagate to any capture, durability, or sync path — logging a failure to log is an acceptable terminal state; blocking on it is not (System Architecture §12.10, Failure Boundaries).

**Business Rules:**
- An observability feature that becomes load-bearing for correctness is itself a defect (enforces ADR-013's cache-never-authoritative reasoning, applied to telemetry-about-the-app rather than telemetry-about-the-bus).

**Validation Rules:** Not applicable.

**Security Considerations:** Must avoid capturing business-sensitive payload contents beyond what diagnosing a reliability problem requires (System Architecture §12.10).

**Performance Expectations:** Must never become a bottleneck for any capture, durability, or sync path it observes.

**Accessibility Considerations:** Not applicable — no Conductor-facing surface.

**Observability:** This feature is itself the observability layer; it has no meta-observability requirement beyond its own failure being visible to engineering through ordinary infrastructure monitoring.

**Acceptance Criteria:**
- ✓ A capture, durability, sync, authorization, or background-execution event is logged durably enough to survive a kill-and-restart.
- ✓ This feature's own unavailability never blocks or corrupts any other feature's operation.
- ✓ No business-sensitive payload content is captured beyond what reliability diagnosis requires.

**Future Enhancements:** Whether this feature's own durable log sink should be subsumed into a broader error-reporting vendor's own capture mechanism is an implementation question deferred to a future Engineering Guidelines document (Technology Decisions §5.15, §13 item 3) — not resolved here, since it does not change this feature's own business behaviour.

**Open Questions:** None specific to this feature's business behaviour.

---

### 9.3 Fleet Version Compatibility

**Purpose:** Ensure every feature above continues to operate correctly across a fleet running mixed ETM versions indefinitely — the assumed normal condition, not a transitional one.

**Business Context:** The ETM cannot be force-upgraded fleet-wide (Product Specification §14; Data Contracts §2). Every contract this document's features depend on is therefore built around additive-only evolution, never a coordinated cutover.

**Business Value:** Protects every other feature in this document from silently breaking the moment the platform evolves a Reference Contract, an Operational Contract, or a Diagnostics contract underneath it — a real, ongoing operational concern for a fleet of devices that cannot all be updated at once.

**Actors:** Not directly Conductor-facing — experienced only as "the app keeps working correctly" across a platform evolving underneath it.

**Dependencies:** Every Reference Contract, Operational Contract, and Identity Contract named throughout §5–§8 of this document.

**Related Workflows:** None specific — this concern spans every workflow.

**Related Domain Entities:** None directly.

**Related Architecture Modules:** None directly — this is a contract-level, not a subsystem-level, concern.

**Related Data Contracts:** Every contract named in the Data Contracts Specification (§12, Versioning Strategy).

**Preconditions:** None.

**Trigger:** Any change to a contract's shape on the platform side.

**Main Behaviour:**
1. A new optional field, a new Reference Contract entirely, or a new observable Diagnostics state is added without requiring an already-deployed ETM instance to change how it consumes fields it does not yet use.
2. Unknown fields are never treated as an error by any feature that consumes a contract — a feature ignores a field it does not recognize rather than rejecting the entire contract.
3. A required field is never added to an existing contract without an explicit, separately-announced migration window, during which both the old and new shapes are supported simultaneously.

**Alternative Behaviour:** None distinct — this is the single governing evolution rule for every contract in this document.

**Offline Behaviour:**
- *Available offline?* Not directly applicable — this is a compatibility discipline, not an operational state.
- *Recovery behaviour:* Not applicable.
- *User expectations:* Not applicable.

**Failure Behaviour:** A platform-side breaking change made without this migration discipline would invalidate every feature's own compatibility guarantees, not merely require a document update (Data Contracts §17).

**Business Rules:**
- A contract's evolution must never surprise the party that didn't change it (enforces Data Contracts §2).
- A required field is never made optional, or an optional field never made required, without a full contract revision, since either silently changes the underlying business guarantee (enforces Data Contracts §14).

**Validation Rules:**
- *Client:* Every feature that consumes a Reference or Operational Contract must tolerate an unrecognized additional field without failure.
- *Platform:* Bears the corresponding obligation to honour additive-only evolution on its own side.
- *Shared:* The discriminator-over-rigid-enumeration pattern (e.g., an event-type indicator) is preferred wherever a future value is plausible, so a new value can be introduced without a coordinated app-and-backend redeploy (Data Contracts §12, rule 3).
- *Failure handling:* Not applicable at this document's level of abstraction.

**Security Considerations:** None distinct.

**Performance Expectations:** None distinct.

**Accessibility Considerations:** Not applicable.

**Observability:** Contract-version mismatches or unrecognized-field occurrences should be logged (via §9.2) to help engineering identify when a fleet-wide migration window can safely close.

**Acceptance Criteria:**
- ✓ An older ETM instance continues operating correctly when the platform adds a new optional field to any contract it consumes.
- ✓ No feature ever fails outright on encountering an unrecognized field.
- ✓ A breaking contract change is never introduced without an explicit, separately-announced migration window at least as generous as the platform's own API deprecation discipline.

**Future Enhancements:** None named upstream beyond the platform's own general anticipation of a third edge-generated event type composing additively (System Architecture §19; Data Contracts §15).

**Open Questions:** No specific deprecation-window length is fixed for ETM-side contract changes distinct from the platform's own API deprecation window (Data Contracts §12, "Deprecation and migration").

---

## 10. Validation Matrix

| Feature | Client Validation | Platform Validation | Shared/Structural Validation |
|---|---|---|---|
| Device Identity & Authorization Awareness | None | Exclusively — all authentication/authorization | None |
| Reference Context Resolution | Internal consistency of consuming feature's own selection | Definitional correctness of every Reference Contract | None |
| Trip Assignment & Lifecycle Awareness | A Ticket cannot be constructed without a resolved Trip | All Trip lifecycle-transition legality | None |
| Boarding & Destination Selection | Internal consistency of the selected pair against cached sequence | None distinct | None |
| Fare Determination | A resolvable Fare Rule must exist for the segment/time | Definitional correctness of the Fare Rule | None |
| Ticket Issuance | All hard preconditions (Trip, Conductor, Fare Rule, Route Stop pair) | Referential integrity at ingestion; non-blocking pairing plausibility check | Structural/transport well-formedness, at both ends |
| Continuous Telemetry Origination | Well-formed reading + Device identity | Coordinate/speed/heading structural bounds; plausibility signal | Structural/transport well-formedness |
| Durable Capture | None (validation occurs upstream) | None | None |
| Synchronization & Connectivity Recovery | None — owns no business-validation logic | Deduplication and reconciliation | None |
| Sync-Status & Reconciliation Honesty | None — read-only aggregation | None | None |
| Connectivity & Authorization Status Awareness | None — pure observation | Authoritative for the actual determination | None |
| Locally Retained Ticket History | None — read-only view | None | None |
| Background Execution & Device Lifecycle Management | Not applicable | Not applicable | Not applicable |
| Battery Optimization Onboarding | Not applicable | Not applicable | Not applicable |
| Crash / Reboot / Process-Kill Recovery | Not applicable | Not applicable | Not applicable |
| Device Revocation Response | None — no local authorization logic | Exclusively — the revocation determination | None |
| Device Replacement & Handoff Continuity | None | Single-operable-Device-per-Bus enforcement | None |
| Shift Boundary Awareness | Not applicable — no entity exists | Not applicable | Not applicable |
| Conductor Pairing Awareness | Some Conductor identity must be resolvable | Non-blocking pairing plausibility check | None |
| Fail-Closed Authorization Enforcement | Governs every other feature's gating logic | Authoritative for the underlying state | None |
| Diagnostic Observability | Not applicable | Not applicable | Not applicable |
| Fleet Version Compatibility | Tolerate unrecognized fields | Honour additive-only evolution | Discriminator-over-enumeration pattern |

## 11. Offline Capability Matrix

| Feature | Available Offline? | Recovery Behaviour | Synchronization Behaviour |
|---|---|---|---|
| Device Identity & Authorization Awareness | Fully (against last-known status) | Automatic re-verification on reconnect | Not applicable — re-verified per request, never batched |
| Reference Context Resolution | Partially (last-known snapshot only) | Next successful resolution replaces snapshot wholesale | Own independent, opportunistic cadence |
| Trip Assignment & Lifecycle Awareness | Partially (last-resolved assignment) | Next successful resolution | Reference-read cadence, not sync cadence |
| Boarding & Destination Selection | Fully (against cached sequence) | Next Route Stop resolution | Reference-read cadence |
| Fare Determination | Fully (against cached rule set) | Next Fare Rule resolution | Reference-read cadence |
| Ticket Issuance | Fully | Not applicable to capture itself | Deferred to Synchronization |
| Continuous Telemetry Origination | Fully | Resumes at next scheduled cadence | Deferred to Synchronization |
| Durable Capture | Fully — this is the mechanism that makes offline the normal condition | Every recovery path re-derives from this feature | Not applicable — this feature precedes sync |
| Synchronization & Connectivity Recovery | Not applicable (inactive while offline) | Automatic, deterministic, paced, oldest-first | This feature *is* the synchronization behaviour |
| Sync-Status & Reconciliation Honesty | Fully | Not applicable | Not applicable |
| Connectivity & Authorization Status Awareness | Fully — represents the offline condition itself | Automatic on signal change | Not applicable |
| Locally Retained Ticket History | Fully | Not applicable | Not applicable |
| Background Execution & Device Lifecycle Management | Fully | Restart detection triggers recovery | Not applicable |
| Battery Optimization Onboarding | Fully | Not applicable | Not applicable |
| Crash / Reboot / Process-Kill Recovery | Fully for durable-state recovery; drain resumption requires connectivity | This feature *is* the recovery behaviour | Deferred to Synchronization |
| Device Revocation Response | Continues capturing; cannot detect revocation until next connection | Requires Operator Admin action, not automatic | Halted until authorization restored |
| Device Replacement & Handoff Continuity | New Device's first-run fully offline-tolerant | Not applicable beyond §5.1 | Not applicable |
| Shift Boundary Awareness | Fully — no data of its own | Not applicable | Not applicable |
| Conductor Pairing Awareness | Fully (last-known pairing) | Next successful resolution | Reference-read cadence |
| Fail-Closed Authorization Enforcement | Applies identically offline and online | Resumes evaluating fresh on reconnect | Not applicable |
| Diagnostic Observability | Fully | Queues locally, uploads on reconnect | Independent, non-blocking |
| Fleet Version Compatibility | Not applicable — a compatibility discipline, not a state | Not applicable | Not applicable |

## 12. Feature Interaction Matrix

| Feature | Depends On | Depended On By |
|---|---|---|
| Device Identity & Authorization Awareness | — (root) | Every other feature |
| Reference Context Resolution | Device Identity & Authorization Awareness | Trip Assignment & Lifecycle Awareness; Boarding & Destination Selection; Fare Determination; Ticket Issuance; Conductor Pairing Awareness |
| Trip Assignment & Lifecycle Awareness | Reference Context Resolution | Ticket Issuance |
| Boarding & Destination Selection | Reference Context Resolution | Fare Determination; Ticket Issuance |
| Fare Determination | Boarding & Destination Selection; Reference Context Resolution | Ticket Issuance |
| Ticket Issuance | Device Identity; Reference Context Resolution; Trip Assignment; Boarding & Destination Selection; Fare Determination; Durable Capture | Sync-Status & Reconciliation Honesty; Locally Retained Ticket History |
| Continuous Telemetry Origination | Device Identity & Authorization Awareness only | Durable Capture (as a source of records) |
| Durable Capture | — (no upstream ETM dependency on its write path) | Synchronization & Connectivity Recovery; Sync-Status & Reconciliation Honesty; Locally Retained Ticket History; Crash/Reboot/Process-Kill Recovery |
| Synchronization & Connectivity Recovery | Durable Capture; Device Identity & Authorization Awareness | Sync-Status & Reconciliation Honesty |
| Sync-Status & Reconciliation Honesty | Device Identity; Reference Context Resolution; Durable Capture; Synchronization | Locally Retained Ticket History |
| Connectivity & Authorization Status Awareness | Device Identity & Authorization Awareness; Synchronization's connectivity signal | (Conductor-facing terminus) |
| Locally Retained Ticket History | Durable Capture; Sync-Status & Reconciliation Honesty | (Conductor-facing terminus) |
| Background Execution & Device Lifecycle Management | — | Continuous Telemetry Origination; Synchronization & Connectivity Recovery; Crash/Reboot/Process-Kill Recovery |
| Battery Optimization Onboarding | Device Identity & Authorization Awareness | Background Execution & Device Lifecycle Management (improves) |
| Crash / Reboot / Process-Kill Recovery | Durable Capture; Background Execution & Device Lifecycle Management | Synchronization & Connectivity Recovery (resumption) |
| Device Revocation Response | Device Identity & Authorization Awareness | Synchronization & Connectivity Recovery; Reference Context Resolution (halts both) |
| Device Replacement & Handoff Continuity | Device Revocation Response; Device Identity & Authorization Awareness | Shift Boundary Awareness; Conductor Pairing Awareness (shares misattribution risk) |
| Shift Boundary Awareness | Device Identity & Authorization Awareness; Conductor Pairing Awareness | (Conductor-facing framing only) |
| Conductor Pairing Awareness | Reference Context Resolution; Device Identity & Authorization Awareness | Ticket Issuance |
| Fail-Closed Authorization Enforcement | Device Identity & Authorization Awareness | Synchronization; Reference Context Resolution; Device Revocation Response |
| Diagnostic Observability | — (every feature may emit to it) | (engineering terminus only) |
| Fleet Version Compatibility | Every contract named in §5–§8 | Every feature that consumes a Reference, Operational, or Identity contract |

## 13. Acceptance Criteria (Consolidated)

Restated at the whole-product level, drawing together the criteria already stated per-feature in §5–§9, because a feature-by-feature list alone risks losing sight of the product-level bar these criteria collectively serve (Product Specification §11):

- ✓ No captured Ticket or Telemetry Ping is ever lost, regardless of connectivity, process death, or OEM background-execution interference.
- ✓ No duplicate delivery ever produces a duplicate fare charge or any other duplicate business outcome.
- ✓ Ticket capture feels instantaneous, regardless of network state.
- ✓ A Conductor always has an honest, never-overstated answer to "did my sale go through."
- ✓ The same Device reliably serves both ticketing and telemetry without either starving the other.
- ✓ Neither Reference Context staleness nor an authorization denial is ever silently represented as something other than what it is.
- ✓ Recovery from any interruption is automatic and deterministic, never dependent on a Conductor noticing a problem.
- ✓ A fleet running mixed ETM versions continues to operate correctly against every contract this document's features depend on.

## 14. Platform Dependencies

This document depends on, and must never contradict:

- **ETM Product Specification** — scope, users, personas, objectives, principles, risks, and constraints every feature above traces to.
- **ETM Domain Specification** — the entities, ownership, lifecycle, and domain events every feature's business rules are drawn from without redefinition.
- **ETM Workflow Specification** — the actual business sequences every feature's Main/Alternative/Failure Behaviour sections restate at feature scope.
- **ETM System Architecture Specification** — the subsystem responsibilities and boundaries every feature's "Related Architecture Modules" entry traces to; no feature in this document claims a capability that document's subsystems are not actually architected to provide.
- **ETM Technology Decisions** — referenced only for scope-gating facts (what is deferred, what is MVP); no feature adopts or assumes a specific technology named there.
- **ETM Offline Synchronization and Reliability Specification** — the durability, consistency, retry, and recovery guarantees every feature's Offline Behaviour and Failure Behaviour sections are built to honour precisely.
- **ETM Data Contracts Specification** — the business promises every feature's "Related Data Contracts" entry extends without redefining ownership, mutability, or evolution rules.
- **Product Engineering Blueprint** — Part 6.1 (Conductor ETM's product responsibility), Part 10.5 (offline conductor operation), Part 11 (offline-first philosophy), Part 12 (multi-tenant model), Part 13 (security philosophy), Part 19 (field conditions and small-team constraints).
- **Domain Model Specification** — the platform-wide entity definitions every ETM-scoped entity in this document narrows without redefining.
- **ADR-001, ADR-002, ADR-005, ADR-007, ADR-008, ADR-009, ADR-011, ADR-012, ADR-013** — the platform-wide architectural decisions every feature's reliability, security, and consistency behaviour is ultimately grounded in.
- **API Specification, MQTT Specification, Database Specification, Sequence Diagrams, Architecture Review** — the backend mechanics referenced throughout without restating their wire-level, schema-level, or diagrammatic detail.

## 15. Open Questions

Consolidated from every feature above, for visibility as a single list — this document resolves none of these; it names them precisely so a future decision-maker knows exactly what remains open and why:

1. **How does a Device receive its initial credential and identity in the field?** Whether this is an ETM-app responsibility or a separate provisioning tool is unresolved (§5.1; Product Specification §21; Domain Specification §16 item 6).
2. **Can "not authorized" and "no connectivity" actually be distinguished at the signal level the ETM receives?** Inherited, unresolved, from the System Architecture and Workflow Specifications (§5.1, §6.2, §9.1; System Architecture §23 item 2; Workflow Specification §16).
3. **What staleness bound, if any, should apply to any cached Reference Context** (Trip, Fare Rule, Route Stop, Conductor pairing) before the ETM treats it as unreliable or warns the Conductor? No upstream document defines one (§5.2, §5.3, §5.4, §5.5, §8.2; Domain Specification §17 item 5; Data Contracts §5.9).
4. **How is Ticket correction/void actually performed, by whom, and under what conditions?** The Domain Model names the intended shape ("a new event referencing the original") but no actor, trigger, or mechanism exists in any reviewed specification (§5.6; Domain Specification §17 item 3; Workflow Specification §9).
5. **Does the ETM ever need visibility into a Ticket or Telemetry Ping's actual platform-side reconciliation**, distinct from mere transport acknowledgement? Named as a live gap throughout (§5.6, §5.7, §6.1; Domain Specification §17 item 2).
6. **Are passenger-category or concession fare tiers part of this product's intended scope?** No upstream specification (Product, Domain, Workflow, Architecture, Data Contracts) names a passenger-category concept distinct from a boarding/destination-segment-anchored Fare Rule. This document does not invent one; if the business intends differentiated fares by passenger type (student, senior, disabled, etc.), that requires a Domain Specification revision before a corresponding ETM feature can be derived (§5.5).
7. **What is the correct local-storage retention/pruning policy** for synced-but-historically-retained Tickets and Pings, and at what point does unbounded backlog growth under a worst-case dead zone become an operational problem? Deferred to a future Technology Decision (§5.8, §6.3; Reliability Specification §25 item 1; System Architecture §23 item 3).
8. **What becomes of a revoked or otherwise permanently-unauthorized Device's undelivered backlog?** Whether it is ever expected to reach the platform is unaddressed by any reviewed specification (§5.9, §7.4; Workflow Specification §15, Open Questions).
9. **What is the actual, measured field connectivity profile this system will encounter?** Every duration-sensitive parameter (batch sizing, backoff caps) this document's features rely on is validated against an assumed profile, not a proven one, at the time of this document's writing (§5.9; Reliability Specification §17, §25 item 4).
10. **How is Conductor misattribution on a Device handoff actually corrected, short of an Operator Admin action?** Genuinely unresolved by any reviewed specification (§7.5, §8.1, §8.2; Domain Specification §17 item 1).
11. **Should a first-class "shift started"/"shift ended" domain event exist?** "Shift" is a real, Conductor-experienced boundary with no backend representation today (§8.1; Workflow Specification §6, §14, Open Questions).
12. **Where does the line sit between Background Execution Management's mitigation responsibility and an accepted, unmitigated risk** for OEM background-execution killing? Not resolvable by this document — a product/business risk-acceptance decision (§7.1; System Architecture §23 item 1).
13. **Is a Conductor self-identification mechanism ever warranted** to address the misattribution risk directly, and if so, how does it extend Identity & Authorization Awareness without weakening the Device-only authentication boundary? Flagged as a future architectural question, not answered here (§5.1, §7.5, §8.2; System Architecture §23 item 5).
14. **Do "Help & Support," "Application Updates," and "Profile"** — named in this document's own drafting brief as illustrative feature candidates — correspond to any actual ETM capability? No reviewed specification (Product, Domain, Workflow, Architecture, Technology, Reliability, Data Contracts) names a Conductor-facing help/support mechanism, an in-app update experience distinct from ordinary Google Play staged rollout, or a Conductor profile of any kind (there being no Conductor authentication to attach a profile to). This document does not invent behaviour for any of the three; see §16 for their disposition.

## 16. Future Feature Candidates

Named here because a comprehensive specification should distinguish "not currently in scope" from "considered and rejected" — every candidate below is the former, not the latter:

- **Ticket Correction/Void** — a defined, first-class feature once the platform names an actor, trigger, and mechanism for it (§5.6, §15 item 4).
- **Conductor Self-Identification** — a mechanism addressing the misattribution risk directly, extending Identity & Authorization Awareness's domain without weakening its authentication boundary (§5.1, §8.2, §15 item 13).
- **Reference-Context Staleness Bound & Warning** — a defined threshold at which the ETM refuses or warns, once the domain defines one (§5.2, §5.3, §5.4, §5.5, §15 item 3).
- **Stronger Reconciliation-Visibility Signal** — a Conductor-facing status stronger than "Synced," should the platform ever expose one (§6.1, §15 item 5).
- **Defined Local-Storage Retention/Pruning Policy** — governing exactly how long synced records remain locally visible via Locally Retained Ticket History (§6.3, §15 item 7).
- **A Third Edge-Generated Event Type** (e.g., commuter location-sharing) — explicitly anticipated by the platform's own architecture to compose additively within the existing Durable Capture / Synchronization mechanism (§5.8, §5.9; System Architecture §19).
- **A First-Class Shift Domain Event** — should the business ever want to bound a Conductor's attributable working period more precisely than "whatever Ticket carries their conductor_id" (§8.1, §15 item 11).
- **Passenger-Category / Concession Fare Support** — contingent on a Domain Specification revision naming this concept; not currently supported by any upstream document (§5.5, §15 item 6).
- **Help & Support, Application Updates as Conductor-facing features, and a Conductor Profile** — none of these currently correspond to any ETM capability named in the reviewed specification set. Application delivery is governed entirely by the platform's own staged Google Play rollout (Technology Decisions §5.27), not by an in-app feature; no upstream document names a Conductor-facing help mechanism or a Conductor profile of any kind, consistent with there being no Conductor authentication to attach one to (Domain Specification §3, Principle 4). Should the Product Specification ever expand scope to include any of these, they would each require their own upstream product, domain, and workflow definition before a corresponding feature could be derived here.

## 17. Platform Dependencies Index

*(See §14 for the full dependency list; this section exists only to satisfy this document's own required-topics list and to confirm no additional dependency exists beyond what §14 already states.)*

---

*End of NammaRoute Conductor ETM Functional Feature Specification v1.0.*
