# NammaRoute Conductor ETM — Domain Specification
### `docs/etm-domain-specification.md`

**Document type:** Domain Specification — the business model of the ETM's slice of the platform domain: entities, ownership, relationships, rules, and lifecycle. It is not a database specification, not an API specification, and not an implementation document.
**Position in the hierarchy:** Derives from the platform-wide Domain Model Specification and the ETM Product Specification; constrained by the Product Engineering Blueprint, the Architecture Review, and every ADR that touches edge-originated data. Feeds every future ETM architecture, API-consumption, and Flutter/Android modeling document — none of which redefine the business concepts fixed here.
**Status:** Living document, updated when the business model changes, not when a schema, endpoint, or topic name changes underneath it.

---

## 1. Purpose

This document defines the business language, entities, ownership, relationships, rules, and lifecycle of the ETM's domain — the conductor-facing slice of NammaRoute's platform. It exists so that every future ETM specification (architecture, API-consumption, Flutter data model, feature spec) derives from one shared business model, rather than each independently reinterpreting what a Ticket, a Trip, or a Device *means*.

The ETM does not introduce a new domain. The platform-wide Domain Model Specification already defines Operator, Bus, Route, Trip, Device, Conductor, Ticket, Telemetry Ping, and Fare Rule as business truths. This document's job is narrower: to state precisely which of those entities the ETM touches, in what capacity (owns, creates, reads, never sees), and what that means for how the ETM must behave — especially offline, where the ETM carries the platform's hardest domain-consistency problem.

Where the backend specifications leave a question genuinely open, this document says so explicitly (§17) rather than inventing an answer the ETM would then be built against incorrectly.

## 2. Domain Overview

The ETM is the operator-provisioned device a Conductor carries for a shift. It is a dual-purpose instrument — ticketing and telemetry origination — not a ticketing app with an incidental location feature (Product Specification §5). Domain-wise, this means the ETM sits at the point where two of the platform's five bounded contexts meet:

- **Identity & Access** — the ETM *is* a Device, one specific instance of that entity, paired to a Conductor and a Bus.
- **Operations (Edge-Generated Events)** — the ETM is the sole origin, for its paired Bus, of two append-only facts: Ticket and Telemetry Ping, both anchored to a Trip.

Every other bounded context — Fleet & Network, Fare & Commerce, Rider Experience — is visible to the ETM only as read-only reference data resolved from the backend, never authored or mutated on-device. The ETM's entire domain contribution to the platform is: originate Tickets and Telemetry Pings, correctly attributed, without ever losing one, regardless of connectivity.

## 3. Domain Principles

These are restatements, at ETM scope, of principles the platform-wide Domain Model and Blueprint already establish — not independently invented:

1. **The ETM is an instrument, not an authority.** It resolves Trip, Fare Rule, Route Stop, and Conductor-assignment context from the backend; it never authors business truth about what a fare *is*, what Route a Trip runs, or who a Conductor *is* assigned to. It only originates the two facts that only it can originate: a Ticket being sold, and a location being reported.
2. **Offline is the normal case, not the exception.** Every entity the ETM creates is captured durably on-device before any network attempt, with no exception for urgency (Domain Model Part 11 — Offline-First Capture).
3. **A Ticket and a Telemetry Ping are the same class of problem.** Both are edge-generated operational events with an identical reliability contract — captured, buffered, synced, reconciled (ADR-011). The domain model does not give ticketing a lesser or different reliability posture than telemetry, even though it is the newer of the two capabilities.
4. **The Device is the authenticated identity; the Conductor is not.** No authentication scheme names a Conductor. The Conductor's identity travels *inside* an already-authenticated Device's Ticket payload as an attribute, not as a credential. This is a structural absence in the platform, not an ETM-side omission (§17).
5. **Once issued, a Ticket's fare never changes.** A correction is a new fact referencing the original; it is never an edit (Domain Model Part 2.13).
6. **The ETM is honest about what it doesn't know.** It must never represent a Ticket or Ping as reconciled with the backend when it only knows that the backend received it, nor imply certainty about sync status it cannot actually verify.

## 4. Domain Boundaries

**In scope for the ETM's domain model:**
- Device (as self — the ETM's own identity)
- Conductor (as an attribute the Device carries, not an identity the Device authenticates as)
- Trip (read-only, resolved from backend, the anchor for everything the ETM creates)
- Ticket (created by the ETM)
- Telemetry Ping (created by the ETM)
- Fare Rule (read-only reference, resolved and cached for offline fare calculation)
- Route Stop (read-only reference, resolved and cached for boarding/destination selection)
- Bus (read-only reference — the vehicle the Device is currently paired to)

**Explicitly out of scope — the ETM never owns, authors, or mutates these, even though it reads or is affected by them:**
- Operator (tenancy root; the ETM operates within exactly one, never aware of others)
- Route, Route Stop *sequence*, Fare Rule *definition* (Fleet & Network / Fare & Commerce contexts — Operator Admin, dashboard-side authorship)
- Trip lifecycle transitions (Scheduled → In Progress → Completed/Cancelled) — an Operator Admin action per the Product Specification (§15); the ETM reads its current Trip assignment but never starts, completes, or cancels one
- Conductor onboarding and Device-to-Conductor pairing — an Operator Admin, dashboard-side action (§8)
- Device provisioning and revocation — Operator Admin actions; the ETM can be the *subject* of a revocation but never its actor
- Commuter, Journey, Occupancy Estimate, ETA, Analytics Record — Rider Experience and derived concepts the ETM neither produces nor consumes directly

**Deliberately named as ETM-adjacent but not ETM domain concepts:** local sync state (`synced`/`unsynced`, retry backoff, batch state) is operational/technical state of the transport mechanism, not a business entity — it does not appear in §5's entity analysis for that reason, though its business consequence (a Ticket or Ping not yet reaching the backend) is very much in scope and covered in §13.

## 5. Domain Entities

Each entity below is the ETM's *view* of a platform-wide entity already fully defined in the Domain Model Specification — this section states only what changes, is added, or is constrained specifically at ETM scope. No entity here contradicts its platform-wide definition.

### 5.1 Device (the ETM itself)

- **Purpose:** The ETM's own business identity — the thing that authenticates, is provisioned, is revoked, and is the attributed origin of every Ticket and Telemetry Ping it produces.
- **Business Definition:** Operator-provisioned conductor hardware; never a commuter's phone; never itself a Conductor.
- **Business Responsibility:** Originate Tickets and Telemetry Pings faithfully and durably; carry the currently-paired Conductor's identity on every Ticket it creates.
- **Owner:** The Operator (provisioned and revoked by Operator Admins); the Device is its own aggregate root for the revocation invariant specifically — nothing about its pairing to a Bus or Conductor weakens that.
- **Source of Truth:** Backend (`devices` record) for identity, status, and pairing. The ETM holds a local, potentially stale, copy of its own pairing state for offline operation, never the authoritative copy.
- **Lifecycle:** Provisioned → Assigned (to a Bus) → Active → Unassigned → Revoked.
- **Relationships:** Paired to at most one Bus at a time; carries at most one currently-assigned Conductor; originates Tickets and Telemetry Pings; resolves its current Trip assignment from the backend.
- **Business Rules:** Revocation must be instant and unconditional from the backend's perspective; when the backend cannot verify the Device's status, it denies by default. From the ETM's own perspective, this means a revoked Device will find every subsequent network attempt refused — a domain event the ETM must be able to represent honestly (§13, §11.2), not merely a technical connection failure.
- **State Changes:** All state transitions are backend-initiated (Operator Admin action); the ETM has no domain action that changes its own Device state.
- **Creation Rules:** Provisioning happens entirely on the backend/Dashboard side, ahead of the ETM ever running on the hardware (§8, Open Question in §17 on exactly how credentials reach the field).
- **Modification Rules:** None available to the ETM itself.
- **Deletion Rules:** Not applicable — a Device is deactivated (Revoked), never deleted; historical Tickets and Pings it originated survive.
- **Synchronization Behaviour:** The Device's own identity/credential is resolved once at provisioning and used for every subsequent authenticated call; its pairing (Bus, Conductor, Trip) is re-resolved from the backend as connectivity allows, never authored locally.
- **Offline Behaviour:** A Device with no connectivity continues to operate against its last-known pairing and Trip assignment; it cannot detect its own revocation until connectivity returns.
- **Validation Rules:** None the ETM enforces on itself; validity is entirely a backend determination.
- **Dependencies:** Bus (pairing), Conductor (current assignment), Trip (current assignment, resolved separately).
- **Notes:** The Device is the single point through which every other ETM-domain concept below is attributed and authenticated. Every Ticket and Ping is stamped with the originating Device's identity as a structural fact, not an optional field.

### 5.2 Conductor (as carried by the Device)

- **Purpose:** Attributes a Ticket to the specific staff member who issued it — a business, not authentication, identity.
- **Business Definition:** The operator-staff member physically carrying the Device for a shift.
- **Business Responsibility (ETM's view):** None beyond being the attribute every Ticket the Device issues must carry. The ETM does not manage the Conductor entity's lifecycle.
- **Owner:** The Operator; assigned by Operator Admins via the Dashboard, never by the ETM.
- **Source of Truth:** Backend `conductors` record and the Device's current `conductor_id` pairing.
- **Lifecycle (read by the ETM, never advanced by it):** Onboarded → Assigned (to a Device) → Unassigned → Deactivated.
- **Relationships:** Uses exactly one Device at a time; a Ticket always names exactly one Conductor.
- **Business Rules:** A Ticket with no attributable Conductor is not a valid business record (Domain Model Part 2.3). The ETM must therefore never construct a Ticket without a currently-assigned Conductor identity to attribute it to.
- **State Changes:** Not initiated by the ETM.
- **Creation / Modification / Deletion Rules:** Not applicable at ETM scope — entirely a Dashboard/Operator Admin responsibility.
- **Synchronization Behaviour:** The ETM must resolve *which* Conductor it currently carries before issuing a Ticket; this resolution is a backend read (directly or via cached last-known pairing), never a locally-authored fact.
- **Offline Behaviour:** If the ETM has no fresh read of its current Conductor pairing, it operates against its last-known one — this is the direct mechanism behind the misattribution risk named in §17.
- **Validation Rules:** None enforced by the ETM beyond "a Conductor identity must be present" before a Ticket can be captured.
- **Dependencies:** Device (the pairing mechanism).
- **Notes:** There is no Conductor authentication scheme anywhere in the platform (§8). This is the single most consequential domain fact for how the ETM must reason about identity — a Ticket's Conductor attribution is only ever as fresh as the Device's last confirmed pairing read.

### 5.3 Trip (read-only)

- **Purpose:** The anchor that gives every Ticket and Telemetry Ping the ETM produces its business meaning.
- **Business Definition:** One specific, scheduled or actual operational run of the ETM's paired Bus along one specific Route, on one specific day.
- **Business Responsibility (ETM's view):** Supply the `trip_id` context every Ticket and (where correlated) Telemetry Ping requires. The ETM does not schedule, start, complete, or cancel a Trip.
- **Owner:** The Operator owning the Bus/Route; Trip lifecycle is entirely an Operator Admin action (Product Specification §15).
- **Source of Truth:** Backend `trips` record.
- **Lifecycle (read-only from the ETM's perspective):** Scheduled → In Progress → Completed, with Cancelled reachable from Scheduled. One-directional — a Completed Trip never re-enters In Progress.
- **Relationships:** Belongs to one Bus and one Route; every Ticket the ETM issues belongs to exactly one Trip; every Telemetry Ping is attributable to at most one Trip by correlation, not a hard requirement.
- **Business Rules:** A Ticket's fare must be explainable by the Fare Rule active at the Trip's operative time — this is why Trip resolution must happen (or be cached) before fare calculation, not after.
- **State Changes:** None available to the ETM.
- **Creation / Modification / Deletion Rules:** Not applicable at ETM scope.
- **Synchronization Behaviour:** The ETM resolves its currently-assigned Trip via a backend reference lookup; this is a read, not a sync operation — a failed read simply means the ETM retries later, since it never held data this lookup was responsible for delivering.
- **Offline Behaviour:** The ETM operates against its last successfully resolved Trip assignment when connectivity is unavailable; it has no way to learn of a Trip transition (e.g. an Operator Admin cancelling the Trip mid-run) until connectivity returns.
- **Validation Rules:** A Ticket cannot be constructed without a resolved Trip context.
- **Dependencies:** Bus, Route, Device/Conductor assignment.
- **Notes:** The ETM's picture of "which Trip am I on" can be stale during a connectivity gap — an accepted consequence of offline-first design, not a defect, but one with real business weight if a Trip is reassigned or cancelled while the ETM is disconnected.

### 5.4 Ticket (created by the ETM)

- **Purpose:** The ETM's primary business output — a single fare transaction, attributable and fare-leakage-accountable.
- **Business Definition:** One conductor, one fare, one Trip, one passenger movement (boarding stop to destination stop).
- **Business Responsibility:** Capture a fare sale as a durable, correctly-attributed business record, with or without connectivity, and never lose it or duplicate its charge.
- **Owner:** The Operator, as the fare-leakage-accountable party. The Commuter who purchased it (if linked) has a durable interest in it as proof of travel, but does not own it as a business record.
- **Source of Truth:** The ETM's local durable store is the *actual* source of truth for a Ticket between capture and the backend's acknowledgement — not the ETM's in-memory state, and not the broker's session persistence, both of which are secondary safety nets only. Once reconciled backend-side, the backend becomes and remains authoritative.
- **Lifecycle:** Captured (on-device) → Buffered → Synced → Reconciled. A correction, if one ever occurs, is a new Ticket referencing the original — never an edit to it.
- **Relationships:** Belongs to exactly one Trip, issued by exactly one Conductor via exactly one Device (itself), priced under exactly one Fare Rule; optionally linked to one Commuter.
- **Business Rules:**
  - A Ticket must never be lost between capture and reconciliation.
  - Duplicate delivery is routine, expected behaviour and must never produce a duplicate fare.
  - A Ticket's fare, once issued, never changes — regardless of any later change to the Fare Rule it was issued under.
  - A Ticket with no attributable Conductor is not a valid business record.
- **State Changes:** Captured → Buffered happens the instant local durable storage confirms the write, before any network attempt. Buffered → Synced happens on successful transport delivery. Synced → Reconciled is a backend-side transition the ETM does not observe directly (§14, §17).
- **Creation Rules:** Requires a resolved Trip, a currently-assigned Conductor, a resolved Fare Rule for the selected boarding/destination Route Stops, and the Device's own identity. Every one of these is a precondition, not something the Ticket-creation act itself resolves independently.
- **Modification Rules:** A Ticket, once captured, is never modified. Any correction is a new record.
- **Deletion Rules:** Never deleted. A Ticket found to be erroneous is voided by a new record referencing it, never removed.
- **Synchronization Behaviour:** Captured locally before any network attempt, transported at-least-once, deduplicated on arrival by a permanent uniqueness rule keyed to the Device's identity and the Ticket's own capture time — never a time-windowed allowance, given the fare-leakage stakes of a duplicate charge.
- **Offline Behaviour:** Fully creatable with zero connectivity; remains safely buffered for as long as a dead zone lasts, with no risk of loss and no requirement that the ETM know or care that this happened.
- **Validation Rules:** Boarding/destination Route Stops, Fare Rule, Trip, and Conductor must all be present and internally consistent (e.g., destination reachable from boarding stop on the resolved Route) before a Ticket can be captured; the ETM performs this validation against its (possibly cached) reference data, not against a live backend call.
- **Dependencies:** Trip, Conductor, Fare Rule, Route Stop, Device, optionally Commuter.
- **Notes:** The ETM's own obligation toward a Ticket is discharged once transport delivery is acknowledged — the ETM has no visibility into, and no retry behaviour triggered by, a Ticket subsequently failing backend-side validation. This is a named, accepted trade-off (§17), not an oversight.

### 5.5 Telemetry Ping (created by the ETM)

- **Purpose:** A single location/status report from the ETM's paired Bus — the highest-frequency fact the ETM produces.
- **Business Definition:** Evidence of where the Bus is and, by extension, of the Trip's route progress.
- **Business Responsibility:** Report location/status at a regular cadence, with the same durability guarantee as a Ticket, at higher frequency and lower per-event business stakes.
- **Owner:** Generated by the Device on behalf of the Bus and Operator it belongs to.
- **Source of Truth:** Same relationship as Ticket — the ETM's local durable store is the real source of truth pre-sync; the backend is authoritative once reconciled.
- **Lifecycle:** Captured → Buffered → Synced → Reconciled — identical in shape to a Ticket's, because it is the same failure mode with a different payload (ADR-011).
- **Relationships:** Generated by the Device (itself); attributable to at most one Trip by time-and-position correlation, never a hard requirement the way a Ticket's Trip link is.
- **Business Rules:** Must never be silently lost; duplicates are expected and deduplicated at the backend, never treated as an error.
- **State Changes:** Same shape as Ticket's, without the Reconciled-state visibility gap being any different — the ETM has no more insight into a Ping's reconciliation than a Ticket's.
- **Creation Rules:** Requires only the Device's own identity and a coordinate/status reading — notably, unlike a Ticket, does not require a resolved Trip to be captured (correlation to a Trip happens backend-side, after the fact, by time-and-position, not as a precondition of capture).
- **Modification / Deletion Rules:** Never modified or deleted once captured.
- **Synchronization Behaviour:** Captured locally before any network attempt; transported at-least-once; deduplicated backend-side using a time-windowed ledger (not a permanent constraint, reflecting the materially lower per-event stakes of a duplicate ping versus a duplicate fare charge).
- **Offline Behaviour:** Continues to be captured and buffered through any length of dead zone; nothing about capture requires connectivity.
- **Validation Rules:** A well-formed coordinate/status reading and the Device's own identity; no Trip or Conductor precondition.
- **Dependencies:** Device only, at capture time.
- **Notes:** Telemetry origination and Ticket issuance share a device, a buffer, and a transport mechanism, but Telemetry carries none of the Conductor-attribution or Trip-precondition requirements a Ticket does — the two entities are reliability-equivalent, not requirement-equivalent.

### 5.6 Fare Rule (read-only reference)

- **Purpose:** Supplies the price a Ticket is issued under.
- **Business Definition:** The pricing logic in effect for the current Trip's Route or a segment of it.
- **Business Responsibility (ETM's view):** None beyond consuming the currently-active rule to price a Ticket at the moment of capture, and snapshotting the resulting amount onto the Ticket permanently.
- **Owner:** The Operator that owns the Route; authored and superseded entirely on the Dashboard side.
- **Source of Truth:** Backend `fare_rules` record; the ETM holds a read-only, possibly cached, copy for offline fare calculation.
- **Lifecycle (read-only):** Defined → Active → Superseded — never deleted while any Ticket references it.
- **Relationships:** Belongs to exactly one Route (or a segment); a Ticket is issued under exactly one Fare Rule.
- **Business Rules:** A Fare Rule change never retroactively reprices an already-issued Ticket — this is precisely why the ETM must snapshot the fare amount onto the Ticket at capture time, not merely reference the rule by ID.
- **Creation / Modification / Deletion Rules:** Not applicable at ETM scope.
- **Synchronization Behaviour:** Resolved/cached from the backend for offline availability; the ETM never authors a Fare Rule.
- **Offline Behaviour:** If the ETM has no fresh Fare Rule for the current Route, it must operate against its last cached version — a Fare Rule change made at the Dashboard while the ETM's Bus is in a dead zone will not be reflected until the ETM reconnects and re-resolves it (§17).
- **Validation Rules:** The ETM must ensure it applies the Fare Rule version actually valid for the Trip's operative time, from its cached set, not simply "whatever it has."
- **Dependencies:** Route, Route Stop (for segment-anchored rules).
- **Notes:** Fare and Trip context are resolved from the backend, never authored on-device (Product Specification §15) — this applies to the Fare Rule's definition, not to the act of pricing a specific Ticket, which necessarily happens on-device to support offline issuance.

### 5.7 Route Stop (read-only reference)

- **Purpose:** Supplies the boarding and destination points a Ticket references.
- **Business Definition:** A Stop's position within the current Trip's Route.
- **Business Responsibility (ETM's view):** Populate the boarding/destination selection in the ticketing UI, and anchor Fare Rule segment lookups.
- **Owner:** The Route's owning Operator; authored on the Dashboard side.
- **Source of Truth:** Backend `route_stops` record; ETM holds a read-only, cached copy.
- **Lifecycle (read-only):** Added to Route → Active → Reordered → Removed from Route.
- **Relationships:** Belongs to exactly one Route; referenced by boarding/destination fields on a Ticket, and by Fare Rule segment anchors.
- **Business Rules:** Ordering within a Route is load-bearing for fare and progress logic — the ETM must not assume a stable order beyond what it has most recently cached.
- **Creation / Modification / Deletion Rules:** Not applicable at ETM scope.
- **Offline Behaviour:** A Route reorder or Stop removal made while the ETM is disconnected will not be reflected until it reconnects and re-resolves the Route — a Ticket captured against stale Route Stop data in the interim is a named risk (§17).
- **Dependencies:** Route, Stop.
- **Notes:** Distinguishes the *Stop* (a stable, platform-shared physical location) from its *Route Stop* role (a position within one specific Route) — the ETM only ever needs the latter for ticketing purposes.

### 5.8 Bus (read-only reference)

- **Purpose:** Identifies the physical vehicle the ETM's Telemetry Pings and, transitively, the current Trip belong to.
- **Business Definition:** The specific vehicle the Device is currently paired to.
- **Business Responsibility (ETM's view):** None beyond being the pairing context the ETM's identity resolves through.
- **Owner:** The Operator; the ETM never modifies its own Bus pairing.
- **Source of Truth:** Backend `buses`/`devices` pairing record.
- **Lifecycle (read-only):** Registered → Active → Under Maintenance → Active → Retired.
- **Relationships:** Paired to at most one Device at a time (the ETM, when paired); performs many Trips.
- **Dependencies:** Bus Type (capacity, referenced only indirectly via Occupancy Estimate, which the ETM does not compute).
- **Notes:** The ETM has no business reason to read Bus Type or capacity directly — Occupancy Estimate is a backend-derived concept the ETM neither produces nor needs.

## 6. Entity Relationships

```
Operator
   │  (owns, structurally isolated)
   ▼
Bus ──────────────┐
   │               │ (paired, at most one at a time)
   │               ▼
   │            Device (the ETM)
   │               │ (carries, at most one at a time)
   │               ▼
   │           Conductor
   │
   ▼
Trip  ◄──────────── Route ──── Route Stop ──── Fare Rule (segment-anchored)
   │
   ├── Ticket  (exactly one Trip, one Conductor, one Device, one Fare Rule; optionally one Commuter)
   │
   └── Telemetry Ping  (exactly one Device; at most one Trip, by correlation only)
```

- **Device ↔ Bus:** one-to-one at any instant; historically one-to-many (a Bus is paired with many Devices over its life, one at a time).
- **Device ↔ Conductor:** one-to-one at any instant; the Conductor is a distinct identity from the Device carrying it, never merged into a single credential.
- **Device ↔ Trip:** many Trips over the Device's life; at most one current assignment at a time, resolved by reference lookup, not owned by the Device.
- **Trip ↔ Ticket:** one-to-many; every Ticket belongs to exactly one Trip, never zero, never more than one.
- **Trip ↔ Telemetry Ping:** one-to-many by correlation, not by hard foreign key — a Ping can exist with no resolvable Trip if correlation fails, and this is not an error condition.
- **Ticket ↔ Fare Rule:** many-to-one; every Ticket pins the exact Fare Rule version active at issuance.
- **Ticket ↔ Route Stop:** two references per Ticket (boarding, destination), both required.
- **Ticket ↔ Commuter:** optional many-to-one; a cash sale carries no Commuter link.

## 7. Business Rules

Restated at ETM scope, drawn from the platform-wide Domain Model and the ETM Product Specification, not independently invented:

1. A Ticket always belongs to exactly one Trip, one Conductor, one Device, and one Fare Rule — the ETM cannot construct a Ticket missing any of these.
2. A Ticket's fare, once issued, never changes — captured as a permanent snapshot at issuance time, never a live reference to the Fare Rule.
3. A Ticket must never be silently lost between capture and backend reconciliation, regardless of connectivity — the ETM's core reliability contract.
4. Duplicate delivery of a Ticket or Telemetry Ping is routine, expected behaviour, never an error condition, and must never produce a duplicate fare charge.
5. A Ticket with no attributable Conductor is not a valid business record.
6. Every edge-generated fact the ETM produces (Ticket, Telemetry Ping) is captured durably on-device before any network attempt — never the reverse, regardless of urgency.
7. The Device, not the Conductor, is the authenticated identity; the Conductor's identity travels inside an already-authenticated Device's Ticket payload, never as its own credential.
8. Trip, Fare Rule, and Route Stop context are resolved from the backend, never authored on the ETM.
9. Trip lifecycle transitions (start, complete, cancel) are exclusively an Operator Admin action; the ETM has no domain action that changes a Trip's state.
10. A confirmed Ticket sale never changes its recorded fare, even if a later correction is issued — a correction is a new record referencing the original.
11. The ETM does exactly two jobs — ticket issuance and telemetry origination — and carries no other business responsibility (Product Specification §13).
12. A Telemetry Ping requires no Trip precondition to be captured, unlike a Ticket, which requires a resolved Trip, Conductor, and Fare Rule before it can exist.

## 8. Ownership Model

| Owner | Owns |
|---|---|
| **Operator** | Bus, Route, Route Stop, Fare Rule, Conductor identity, Device identity — all authored and lifecycle-managed via the Dashboard, never the ETM. |
| **Backend (platform)** | Business truth for every entity — Trip state, Fare Rule versions, Device/Conductor pairing, and the reconciled record of every Ticket and Telemetry Ping. |
| **Conductor** | Nothing persisted — a business identity carried by the Device, not a data owner. |
| **ETM (Device)** | Nothing permanently. Its only durable contribution is originating Tickets and Telemetry Pings, which become Operator-owned business records the instant they exist — the ETM never retains an authoritative copy once reconciled. |
| **ETM (local, temporary)** | Its own local durable buffer of not-yet-synced Tickets and Telemetry Pings, and cached read-only reference data (current Trip assignment, active Fare Rules, Route Stops) — all provisional, all superseded by the backend's authoritative copy the moment connectivity allows reconciliation. |

**Why this split:** the platform's own multi-tenant and reliability principles (Domain Model Part 11) require exactly one authoritative owner per kind of truth. The ETM's temporary local ownership exists solely to make offline capture possible — it is never meant to be, and must never be treated as, a second source of truth once the backend has reconciled the same fact. This mirrors ADR-013's "no cache is ever a source of truth" reasoning, extended to the edge device's own local buffer: the buffer is the *actual* source of truth only until the backend takes over, at which point the local copy becomes disposable.

## 9. Lifecycle Model

### Ticket
`Captured (on-device)` → `Buffered` → `Synced` → `Reconciled`, with `Voided` reachable at any point after `Reconciled` via a new, separate correcting record.

### Telemetry Ping
`Captured` → `Buffered` → `Synced` → `Reconciled` — structurally identical to Ticket's, reflecting ADR-011's "same failure mode, different payload" reasoning.

### Device (read-only from the ETM's perspective)
`Provisioned` → `Assigned` (to a Bus) → `Active` → `Unassigned` → `Revoked`.

### Conductor (read-only from the ETM's perspective)
`Onboarded` → `Assigned` (to a Device) → `Unassigned` → `Deactivated`.

### Trip (read-only from the ETM's perspective)
`Scheduled` → `In Progress` → `Completed`, with `Cancelled` reachable only from `Scheduled`. One-directional — never re-enters `In Progress` once `Completed`.

### Fare Rule (read-only from the ETM's perspective)
`Defined` → `Active` → `Superseded` — never deleted while any Ticket still references it.

## 10. State Transitions

The ETM is the **initiator** of exactly two transitions in the entire platform domain: `(Ticket: nonexistent → Captured)` and `(Telemetry Ping: nonexistent → Captured)`. Every other transition of every entity in its domain view — Device, Conductor, Trip, Fare Rule, Route Stop, Bus — is initiated elsewhere (Operator Admin via the Dashboard, or the backend's own ingestion/reconciliation pipeline) and only ever *observed* by the ETM.

The `Buffered → Synced` transition is the ETM's own transport mechanism confirming delivery; the ETM does not observe, and cannot force, the subsequent `Synced → Reconciled` transition — that is a backend-side determination the ETM has no visibility into (§17). This asymmetry — the ETM can confirm delivery but not final reconciliation — is a deliberate, named property of the platform's reliability design, not a gap specific to the ETM.

## 11. Domain Events

The backend this platform runs on is event-driven end to end (Domain Model Part 12 — Domain Events). This section names the business events relevant to the ETM's domain specifically: the events it originates, and the events originated elsewhere that the ETM must be able to react to or account for. These are business events, not implementation signals — a topic name, a webhook, or a push notification is a possible *delivery mechanism* for one of these events, not the event itself, and none is specified here (that is API/MQTT Specification scope).

### 11.1 Events the ETM originates

| Domain Event | Meaning | Fires when |
|---|---|---|
| **Ticket Issued** | A Conductor has completed a fare sale. | A Ticket is captured on-device, before any network attempt (§5.4). |
| **Telemetry Captured** | The paired Bus's location/status has been reported. | A Telemetry Ping is captured on-device (§5.5). |

These are the ETM's only two originating events, matching its two domain responsibilities (§3, Principle 1). Both fire at *capture* time, independent of connectivity — an event firing does not imply the backend has seen it yet (§10, §13).

### 11.2 Events the ETM must observe or account for

These originate elsewhere (the backend, or an Operator Admin via the Dashboard) but have direct consequences for the ETM's own domain behaviour — principally, that a locally cached read (§13, §14) may now be stale:

| Domain Event | Meaning | Consequence for the ETM |
|---|---|---|
| **Device Revoked** | The backend has instantly and unconditionally invalidated this Device's authorization. | Every subsequent network attempt is refused (§5.1); the ETM must be able to represent this honestly as "no longer authorized," not merely "offline." |
| **Trip Assigned** | An Operator Admin has assigned this Device/Conductor to a Trip. | The ETM's current-Trip context becomes resolvable; Tickets can now be attributed to it (§5.3). |
| **Trip Changed** | An Operator Admin has reassigned, cancelled, or otherwise altered the Trip this Device was assigned to. | If the ETM is offline when this happens, it continues issuing Tickets against its last-known Trip assignment until it reconnects and re-resolves (§13, §17). |
| **Conductor Changed** | An Operator Admin has paired a different Conductor to this Device (or unassigned the current one). | Tickets issued after this event, but before the ETM re-resolves its pairing, risk misattribution to the outgoing Conductor (§17, item 1). |
| **Fare Updated** | A Fare Rule active on the ETM's current Route has been superseded. | Tickets issued from cached, now-stale Fare Rule data are priced correctly against the version the ETM actually held, but may no longer match the backend's current rule until the ETM refreshes (§5.6, §13). |
| **Route Updated** | A Route Stop has been added, reordered, or removed on the ETM's current Route. | Boarding/destination selection and Fare Rule segment resolution on the ETM may reflect a stale sequence until refreshed (§5.7, §13). |

### 11.3 Why this matters beyond this document

Naming these as domain events — rather than only as database status columns or cache-invalidation triggers — is what lets a future architecture, API-consumption, or notification design reason about the ETM correctly: each event above is a business fact first, and only secondarily something that might one day be delivered to the ETM over a push channel, polled via a reference endpoint, or simply inferred from a changed value on next reconnect. This document does not choose a delivery mechanism for any of them — that decision belongs to a future ETM architecture document, constrained by whatever the platform's existing transport (MQTT, REST) already supports.

## 12. Domain Constraints

- A Ticket cannot exist without a resolved Trip, Conductor, Fare Rule, and boarding/destination Route Stop pair — these are hard preconditions to the `Captured` state itself, not later validation steps.
- A Telemetry Ping has no such precondition beyond the Device's own identity — it can be captured with no Trip, Conductor, or Fare context resolved at all.
- The Device cannot author, modify, or delete any entity other than the Tickets and Telemetry Pings it originates.
- No entity the ETM reads (Trip, Fare Rule, Route Stop, Bus, Conductor pairing) can be assumed current while offline — every read is a snapshot as of the last successful resolution, never guaranteed live.
- A Ticket's fare amount, once captured, is immutable for the life of that record — any later correction is a distinct record, never a mutation.
- The ETM has no domain concept of "logged in" or "logged out" tied to a Conductor — only the Device's own authentication state and its currently-carried Conductor attribute.

## 13. Offline Domain Behaviour

Offline is the ETM's designed-for normal operating condition, not a degraded mode (Product Specification §13). Domain-wise, this has different consequences for what the ETM *creates* versus what it *reads*:

**For entities the ETM creates (Ticket, Telemetry Ping):** offline changes nothing about validity. A Ticket captured with zero connectivity is exactly as valid a business record as one captured with a live connection, for as long as it takes to reach the backend — durability and correctness of these two facts must never depend on network state.

**For entities the ETM only reads (Trip, Fare Rule, Route Stop, Conductor pairing, Bus/Device pairing):** offline means the ETM necessarily operates against a snapshot of unknown age. This is where the ETM's domain model carries real, named risk rather than a solved problem:

- A Trip cancelled or reassigned at the Dashboard while the ETM is disconnected will not be reflected until reconnection — Tickets may continue to be issued against a Trip assignment the backend no longer considers current.
- A Fare Rule superseded at the Dashboard mid-dead-zone will not be picked up until reconnection — Tickets may be priced under a rule the backend has already retired.
- A Conductor reassignment (a Device handed to a different Conductor without an Operator Admin action, or an admin reassignment made while the Device is offline) risks Tickets attributed to the wrong Conductor for as long as the mismatch persists (Product Specification §17 — named explicitly as a platform risk, not resolved at the domain level today; see §17).

None of these are failures of the offline-first design — they are the honest, named cost of resolving business context from a backend the ETM cannot always reach, and the domain model's job is to name them precisely rather than pretend they don't exist.

## 14. Source of Truth

| Entity | Authoritative source | ETM's relationship to it |
|---|---|---|
| Ticket, Telemetry Ping (pre-reconciliation) | The ETM's own local durable buffer | Actual source of truth until the backend reconciles it — not the in-memory publish queue, not the broker's session state, both of which are secondary safety nets only. |
| Ticket, Telemetry Ping (post-reconciliation) | Backend (PostgreSQL/TimescaleDB) | The ETM's local copy becomes disposable the instant the backend has durably recorded the fact. |
| Device identity, status, pairing | Backend | The ETM holds a read-only, potentially stale, cached view for offline operation. |
| Conductor identity, current assignment | Backend | Same relationship — read-only, cached, never authored by the ETM. |
| Trip | Backend | Same relationship. |
| Fare Rule | Backend | Same relationship. |
| Route Stop | Backend | Same relationship. |

The general rule: **the ETM is never the authoritative source for anything except a Ticket or Telemetry Ping it has captured but not yet had reconciled by the backend.** Every other fact it holds locally is a cache of backend truth, held only to make offline operation possible, and is disposable without data loss the moment it can be refreshed.

## 15. Local vs Backend Responsibilities

| Responsibility | ETM (local) | Backend |
|---|---|---|
| Capturing a Ticket/Ping durably | Yes — before any network attempt | No role until delivery |
| Deciding a Ticket's fare amount at issuance | Yes — computed from cached Fare Rule, snapshotted onto the Ticket | Supplies the Fare Rule the computation uses |
| Deduplicating a Ticket/Ping on arrival | No | Yes — permanent constraint (Ticket), time-windowed ledger (Telemetry) |
| Reconciling a Ticket/Ping into the authoritative record | No | Yes |
| Authoring Trip, Route, Fare Rule, Conductor, Device records | No | Yes — exclusively Operator Admin / Dashboard actions |
| Determining Device revocation | No | Yes — the ETM can only be its subject |
| Computing Occupancy Estimate, ETA, Analytics | No | Yes — the ETM neither produces nor consumes these directly |
| Resolving current Trip/Conductor/Fare Rule/Route Stop context | Cached copy, refreshed opportunistically | Authoritative source, resolved by reference lookup |

## 16. Domain Assumptions

Stated explicitly, distinct from the platform-level assumptions the Blueprint and Product Specification already name:

- A Conductor identity, once assigned to a Device by an Operator Admin, remains valid for the ETM's purposes until the ETM next successfully re-resolves its pairing — the ETM has no independent way to detect a stale pairing.
- The cached Trip, Fare Rule, and Route Stop data the ETM operates against while offline is assumed "recent enough" for the business context it supports; no domain-level staleness bound is defined today (§17).
- A device handoff between Conductors mid-shift is assumed to be a real, expected occurrence (Product Specification §16), but the domain model assumes — without current backend support to guarantee it — that such a handoff is promptly reflected by an Operator Admin action.
- The ETM assumes a Ticket's preconditions (Trip, Conductor, Fare Rule, Route Stop pair) can always be resolved from cache even with zero live connectivity for the duration of a shift — an assumption the Product Specification names as unvalidated for real field conditions (start-of-shift connectivity, Product Specification §16).

## 17. Open Domain Questions

Identified explicitly, per this document's own instruction not to invent behaviour where the backend specifications leave a gap:

1. **Conductor misattribution on device handoff.** The Product Specification names this directly as a risk (§17): since Conductor-to-Device pairing is exclusively an Operator Admin, Dashboard-side action, an offline mid-shift handoff between two Conductors has no domain mechanism to correct the Device's carried Conductor identity until connectivity returns and an admin acts. No compensating domain rule (e.g., a Conductor self-identifying on-device) exists in any reviewed specification. This is an open question for a future ETM feature or architecture decision, not resolved here.
2. **Ticket reconciliation visibility.** No reviewed specification (API, MQTT, or sequence diagrams) defines a mechanism by which the ETM learns that a specific Ticket has actually reached `Reconciled` status, as opposed to merely having been acknowledged at the transport layer. The ETM's own obligation is discharged on transport acknowledgement; whether a Conductor should ever be shown a stronger "confirmed by backend" signal, and how that would be delivered, is open.
3. **Ticket correction/void mechanism.** The Domain Model states a correction is "a new event referencing the original," and the database and MQTT specifications both name `voided_ticket_id` and a `voided` status — but no reviewed API, MQTT topic, or sequence diagram defines an actual endpoint, topic, or workflow by which a correction or void is created, by whom (Conductor, Operator Admin, or both), or under what conditions. This is a named gap in the backend specification set, not an ETM domain decision to make unilaterally.
4. **Commuter linkage at point of sale.** The database schema carries a nullable `commuter_id` on Ticket, but the Product Specification states linking a Ticket to a Commuter account at point of sale is explicitly out of scope for the ETM (no supporting capability exists platform-wide). The domain model treats this field as present in the backend schema but never populated by the ETM at MVP — a forward-compatibility placeholder, not a live ETM capability.
5. **Staleness bound on cached reference data.** No specification defines how old a cached Trip, Fare Rule, or Route Stop set may be before the ETM should refuse to issue a Ticket against it, or warn the Conductor. This is left to a future ETM architecture/feature decision.
6. **Device credential provisioning in the field.** The Product Specification itself asks (§21) whether initial credential/identity delivery to a Device is an ETM-app responsibility or a separate provisioning tool. The domain model assumes the Device arrives at the ETM's first run already provisioned, but does not resolve who performs that provisioning step or how.

## 18. Platform Dependencies

The ETM's domain model depends on, and must never contradict, the following upstream documents:

- **Domain Model Specification** — the platform-wide definition of every entity named here (Operator, Bus, Route, Route Stop, Trip, Device, Conductor, Ticket, Telemetry Ping, Fare Rule).
- **Product Engineering Blueprint** — Part 6.1 (Conductor ETM's product responsibility), Part 10.5 (offline conductor operation), Part 11 (offline-first philosophy), Part 12 (multi-tenant model).
- **ETM Product Specification** — the product-level scope, users, risks, and constraints this domain model implements the business language for.
- **ADR-001, ADR-002** (MQTT, Protobuf transport for edge events), **ADR-005** (QoS 1 and application-level dedup), **ADR-007** (fail-closed authorization), **ADR-008** (LocalBuffer-before-network ordering), **ADR-009** (Device vs. dashboard-user authentication), **ADR-011** (Ticket as an edge-generated operational event, same reliability class as Telemetry).
- **Database Specification** §10.1.3 (`conductors`), §10.1.5 (`devices`), §10.4.1 (`trips`), §10.4.2 (`tickets`), §10.3.1 (`fare_rules`) — implementation of the entities this document defines in business terms; this document does not restate their schema.
- **MQTT Specification, API Specification, Sequence Diagrams** — implementation detail of how the ETM's domain facts are transported, read, and diagrammed; referenced here only where a business rule (e.g., "no endpoint ingests a Ticket over REST") has direct domain consequence (§14).

## 19. Glossary

| Term | Meaning, as used in this document |
|---|---|
| **ETM** | The operator-provisioned Android device a Conductor carries; in this document's terms, one specific Device. |
| **Device** | The authenticated business identity the ETM embodies; never a Conductor, never a commuter's own phone. |
| **Conductor** | The staff member carrying the ETM; a business identity attributed on every Ticket, never itself a login. |
| **Trip** | One specific run of a Bus along a Route on one day; the anchor every Ticket and (by correlation) Telemetry Ping resolves against. |
| **Ticket** | A single fare transaction the ETM creates; one Conductor, one fare, one Trip. |
| **Telemetry Ping** | A single location/status report the ETM creates on behalf of its paired Bus. |
| **Fare Rule** | The pricing logic, resolved read-only from the backend, that determines a Ticket's fare. |
| **Route Stop** | A Stop's position within the current Trip's Route; the boarding/destination reference a Ticket carries. |
| **Reconciled** | The backend-side state confirming a Ticket or Telemetry Ping is durably and correctly recorded — a state the ETM cannot directly observe. |
| **Buffered** | The state of a Ticket or Telemetry Ping once durably written on-device, before any network attempt has succeeded. |
| **Source of truth** | The single authoritative holder of a given fact at a given point in its lifecycle — the ETM's local buffer pre-reconciliation, the backend thereafter. |

---

*End of NammaRoute Conductor ETM Domain Specification v1.1.*
