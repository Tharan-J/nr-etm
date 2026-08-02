# NammaRoute Conductor ETM — Data Contracts Specification
### `docs/etm-data-contracts-specification.md`

**Document type:** Data Contracts Specification — the authoritative business contract governing every piece of information exchanged between the ETM and the NammaRoute Platform: what is exchanged, who owns it, who produces and consumes it, when it changes, how it evolves, and what guarantees it carries. It is not an API specification, not a Protobuf schema, not an MQTT topic specification, and not a database specification.
**Position in the hierarchy:** Derives from, and must not contradict, the ETM Product Specification, ETM Domain Specification, ETM Workflow Specification, ETM System Architecture Specification, ETM Technology Decisions, and ETM Reliability & Offline Synchronization Specification. Constrained by the Product Engineering Blueprint, the Domain Model Specification, the API Specification, the MQTT Specification, the Database Specification, the Sequence Diagrams, and the full ADR collection. Feeds every future ETM Feature Specification, UI Specification, and Implementation Plan — none of which may redefine a contract's ownership, mutability, or evolution rule fixed here, only implement it.
**Status:** Living document, updated when a contract's business meaning, ownership, or evolution rule changes — not when a transport mechanism, schema, or endpoint changes underneath it.

---

## 1. Purpose

This document answers one question, for every piece of information that crosses the boundary between the ETM and the platform: **what is this, in business terms, who is allowed to say it's true, who produces it, who consumes it, and what happens to it as the system evolves?**

It exists because the ETM's upstream specifications each answer a narrower question — the Domain Specification defines what an entity *means*, the System Architecture Specification defines which *subsystem* handles it, the Reliability Specification defines what *durability and delivery guarantee* applies to it — but none of them collects, in one place, the actual contract each piece of exchanged information represents: its producer, its consumer, its authoritative owner, its lifecycle, and its evolution rule. This document is that collection point. It does not redefine any mechanism those documents, or the backend's own API/MQTT/Database specifications, already fix — it states the business contract each mechanism carries, so that a future engineer changing a payload field, a reference read, or a lifecycle transition knows precisely what business promise they are changing, and to whom.

Every backend mechanism this document references — REST endpoints, MQTT topics, Protobuf messages, database tables — already exists and is treated as fixed (Product Specification §4). This document does not name a single endpoint path, topic string, or field number; it names the *business contract* those mechanisms already carry, extended honestly to describe the ETM's participation in it.

## 2. Contract Philosophy

A **contract**, in this document's sense, is not a schema or a wire format — it is a business promise between two parties about a piece of information: what it means, who may assert it, how fresh it must be, and what happens when one side changes its shape. Every contract named below already has a technical implementation somewhere in the backend's frozen specification set; this document's job is to state the business promise that implementation is actually keeping, in a form durable enough to survive that implementation changing underneath it.

Four philosophical commitments govern every contract this document names:

- **A contract has exactly one authoritative owner.** Two parties may both hold a copy of a fact, but only one of them is ever entitled to say which copy is correct (Domain Specification §8, §14; ADR-013). A contract without a named, singular owner is not yet a contract — it is an ambiguity this document exists to resolve, not to preserve.
- **A contract's mutability is a business fact, not an implementation accident.** Some information, once exchanged, is permanently fixed (a Ticket's fare); some is expected to change on every read (a live position); most falls somewhere between. This document states which, for every contract, because conflating an immutable contract with a mutable one is exactly the kind of mistake the Domain and Architecture Specifications already warn is the single most consequential error this system could make (Domain Specification §8, §17; System Architecture §8, Principle 3).
- **A contract's evolution must never surprise the party that didn't change it.** The ETM cannot be force-upgraded fleet-wide (Product Specification §14, "device may pass between conductors... over a long operational life"; ETM Technology Decisions §5.27), so every contract's versioning strategy (§12 of this document) is built around a fleet running mixed versions indefinitely, not around a coordinated cutover that may never actually happen cleanly.
- **A contract is described by its business shape, never its wire shape.** This document names what a Trip assignment *means* to the ETM, not which HTTP verb retrieves it; what a Ticket *is*, not which Protobuf field number carries its fare. The wire-level and schema-level implementation of every contract named here is already fixed by the API Specification, the MQTT Specification, and the Database Specification, and this document defers to them entirely for that layer.

## 3. Contract Principles

These are the fixed points every contract classification and every individual contract description in this document is built from. Each restates, at the contract-definition layer, a principle the ETM's upstream specifications or the platform's own ADRs already establish — none is independently invented here.

1. **Ownership is singular and structural, never a shared or negotiated fact.** Every contract in this document names exactly one authoritative owner. The ETM never simultaneously holds and disputes authority over the same fact with the backend (Domain Specification §8; System Architecture §14).
2. **A contract the ETM produces is authoritative from the ETM at the moment of production, and only until the platform reconciles it.** This is the one deliberate, narrow exception to "the platform is always authoritative" — scoped exclusively to Ticket and Telemetry Ping contracts, and only for the window between capture and reconciliation (ADR-013's pattern, narrowly extended per Domain Specification §8; Reliability Specification §4, Principle 2).
3. **Every contract the ETM only reads is disposable, cached, and never treated as a second source of truth.** Reference contracts carry no authority of their own regardless of how recently they were refreshed (Domain Specification §14; Reliability Specification §9.2).
4. **A contract's evolution is additive by default; a breaking change is a distinct, deliberately rare event requiring an explicit migration window.** This mirrors the platform's own additive-field-evolution philosophy (ADR-002) and versioning strategy (API Specification §5), extended here to the business-contract level rather than the wire-format level.
5. **A contract that crosses the ETM boundary is validated by whichever party is positioned to catch a defect first, and revalidated by whichever party is authoritative for correctness.** Business validation belongs to the party that understands the business rule; structural/transport validation belongs to whichever party first receives the data (§9 of this document).
6. **No contract may be described in a way that presumes network availability.** Every contract's offline behavior is a first-class part of its definition, not an afterthought — consistent with the Reliability Specification's own foundational posture (Reliability Specification §3).
7. **A contract's security posture is proportional to its sensitivity and its blast radius if compromised**, not uniform across every contract regardless of content (ADR-007, ADR-009; System Architecture §17).
8. **This document does not duplicate a backend document's authority.** Where the API Specification, MQTT Specification, or Database Specification already answers a wire-level or schema-level question, this document references that answer rather than restating or reinterpreting it.

## 4. Contract Classification

Every contract named in this document falls into one or more of the following classes. These are not assumed exhaustive — a future contract may require a class not yet named here, and this document's own governing discipline (Contract Principle 8) means a new class should be added deliberately, not stretched from an existing one that doesn't actually fit.

| Class | Defining characteristic | Contracts of this class in this document |
|---|---|---|
| **Reference Contracts** | Read-only from the ETM; authoritative only at the platform; a cached snapshot on the ETM, always disposable. | Operator, Bus, Route, Route Stop, Fare Rule, Trip (as read context), Conductor (as read context) — §5 |
| **Identity Contracts** | Govern who the ETM is and what it is currently authorized to do; the root of trust every other contract depends on. | Device Identity, Authorization State, Session/Connection State — §7 |
| **Operational (Event) Contracts** | Originated by the ETM; append-only; the ETM's actual business output. | Ticket, Telemetry Ping — §6 |
| **Configuration Contracts** | ETM-local, non-authoritative operational state; never a business record. | Local Pairing Snapshot, Last-Sync State — §8 |
| **Diagnostics Contracts** | Observability of the ETM's own behavior; never load-bearing for correctness. | Sync/Reconciliation Status (Conductor-facing), Operational Log Record (engineering-facing) — §8.3 |
| **Command Contracts** | Not present in this system at the ETM boundary — named here to state the negative explicitly (see §6.3). | None at MVP |

A single named contract may straddle two classes where the domain genuinely requires it — Trip, for instance, is a Reference Contract when read as context for Ticket validation, and its lifecycle state is separately observed as a domain event the ETM must account for (Domain Specification §11.2). This document notes such straddling explicitly rather than forcing an artificial single classification.

## 5. Reference Contracts

Reference Contracts are read-only, disposable, and never authoritative at the ETM — the backend is always the sole authority, and the ETM's copy is a snapshot of unknown age the moment it is read (Domain Specification §14; Reliability Specification §9.2). Each entry below states what changes and stays fixed relative to the entity's own platform-wide definition (Domain Model Specification) and its ETM-scoped definition (ETM Domain Specification §5).

### 5.1 Operator

- **Purpose:** The tenancy root every other Reference Contract resolves within.
- **Business Meaning:** The bus-operating business the Device is provisioned under.
- **Producer:** The platform (Operator Admin/Dashboard-side authorship, entirely outside ETM scope).
- **Consumer:** Every ETM subsystem that resolves scope-bound reference data implicitly resolves within its Device's own Operator — the ETM does not consume this contract as a distinct, separately-fetched fact so much as an ambient scoping condition every other Reference Contract inherits.
- **Authoritative Owner:** The platform, exclusively and permanently.
- **Lifecycle:** Effectively static from the ETM's perspective — a Device is provisioned under exactly one Operator and this document names no workflow by which that changes without a full re-provisioning (Domain Specification §4, §5.1).
- **Mutability:** Immutable from the ETM's vantage point for the life of a given Device provisioning.
- **Synchronization Behaviour:** Not independently synchronized — resolved implicitly as part of the Device's own identity resolution (§7.1).
- **Offline Behaviour:** Assumed unchanged for the life of the current provisioning; no offline degradation scenario applies because this fact does not change at ETM-observable timescales.
- **Validation Expectations:** None performed by the ETM; the platform is the sole party capable of validating Operator identity or scope.
- **Consistency Requirements:** Not applicable in a way distinct from Device Identity itself (§7.1) — this contract's consistency is inherited from that one.
- **Security Considerations:** Operator scope is what makes cross-tenant data exposure structurally impossible for the ETM (ADR-012's structural isolation, mirrored at the ETM's own boundary per System Architecture §17) — the ETM never asserts its own Operator scope; it is always resolved fresh by the platform from the Device's authenticated identity.
- **Versioning Strategy:** Not applicable — this contract carries no evolving shape at the ETM boundary.
- **Dependencies:** Device Identity (§7.1).
- **Open Questions:** None specific to this contract.

### 5.2 Bus

- **Purpose:** Identifies the specific vehicle the Device is currently paired to, and anchors the fleet-reference lookups the Conductor-facing UI depends on.
- **Business Meaning:** The physical vehicle whose location and status the Device reports, and whose Route/Trip history the Device's Tickets and Pings contribute to (Domain Specification §5.8).
- **Producer:** The platform (Operator Admin registers and pairs a Bus to a Device).
- **Consumer:** Ticket Capture & Validation (for Trip/Bus consistency checks the domain requires), Telemetry Origination (implicitly, as the entity being reported on), Conductor-facing bus-reference selection UI.
- **Authoritative Owner:** The platform, exclusively.
- **Lifecycle:** Registered → Active → (status transitions entirely Operator Admin-driven); pairing to a Device changes over the Bus's life, one Device at a time (Domain Specification §5.8, §6).
- **Mutability:** Mutable at the platform; the ETM's cached copy is replaced wholesale on each successful resolution, never incrementally patched.
- **Synchronization Behaviour:** Resolved as reference data, opportunistically, whenever connectivity allows; not tied to the Ticket/Telemetry synchronization cadence (Reliability Specification §13.1).
- **Offline Behaviour:** The ETM operates against its last-known Bus pairing indefinitely during a connectivity gap; a mid-gap re-pairing to a different Bus (a genuine, if rare, operational event) would not be reflected until reconnection (Domain Specification §13).
- **Validation Expectations:** The ETM performs no independent validation of Bus identity or status — it consumes what the platform resolves. The platform is solely responsible for validating that a Bus is not already paired to another active Device before completing a new pairing (API Specification §26.1.5's business rule).
- **Consistency Requirements:** Eventually consistent; no strong-consistency requirement exists for this contract, consistent with its Reference Contract classification.
- **Security Considerations:** No PII; a Bus's registration number and status carry no elevated sensitivity beyond ordinary Operator-scoped reference data.
- **Versioning Strategy:** Additive-only — a future field describing the Bus (e.g., a capacity attribute already present platform-wide) may be added to this contract's resolved shape without the ETM needing to change how it consumes fields it does not yet use (Contract Principle 4).
- **Dependencies:** Operator (§5.1), Device Identity (§7.1).
- **Open Questions:** None specific to this contract beyond the general Reference Contract staleness question named in §5.9.

### 5.3 Route

- **Purpose:** Supplies the reusable path definition a Trip is an instance of.
- **Business Meaning:** The named, defined path (e.g., "Ooty – Coonoor Ordinary") a Trip runs along on a given day (Domain Specification §5.3, dependency).
- **Producer:** The platform (Operator Admin authorship — Route creation and status management).
- **Consumer:** Ticket Capture & Validation (via Route Stop and Fare Rule resolution, which are anchored to a Route); Conductor-facing reference display, where relevant.
- **Authoritative Owner:** The platform, exclusively.
- **Lifecycle:** Drafted → Active → (further status transitions per platform-side Route lifecycle, entirely Operator Admin-driven; the ETM only ever reads a Route's current status).
- **Mutability:** Mutable at the platform (a Route's definition — name, status — may change); the ETM's cached copy is disposable and replaced wholesale on refresh.
- **Synchronization Behaviour:** Resolved as reference data opportunistically; not on the Ticket/Telemetry cadence.
- **Offline Behaviour:** Operates against the last-known Route definition; a Route status change (or, more consequentially, a Route Stop reorder — §5.4) made while the ETM is disconnected is not reflected until reconnection (Domain Specification §5.7, §13).
- **Validation Expectations:** The ETM does not validate Route authorship or status; it treats a resolved Route as valid context for downstream Route Stop and Fare Rule resolution. The platform is solely responsible for Route definitional correctness.
- **Consistency Requirements:** Eventually consistent.
- **Security Considerations:** No PII; ordinary Operator-scoped reference sensitivity.
- **Versioning Strategy:** Additive-only.
- **Dependencies:** Operator (§5.1).
- **Open Questions:** None specific to this contract.

### 5.4 Route Stop

- **Purpose:** Supplies the ordered boarding/destination points a Ticket references, and anchors Fare Rule segment resolution.
- **Business Meaning:** A Stop's position within the current Trip's Route — the physical boarding and alighting points a Conductor selects during Ticket Issuance (Domain Specification §5.7).
- **Producer:** The platform (Operator Admin authorship — adding, reordering, or removing a Route Stop).
- **Consumer:** Ticket Capture & Validation, directly — a Ticket cannot be constructed without a resolved boarding/destination Route Stop pair (Domain Specification §12).
- **Authoritative Owner:** The platform, exclusively. Ordering within a Route is load-bearing for fare and progress logic, and the ETM must never assume a stable order beyond what it has most recently cached (Domain Specification §5.7).
- **Lifecycle:** Added to Route → Active → Reordered → Removed from Route (read-only from the ETM's perspective).
- **Mutability:** Mutable at the platform; ETM's cached copy is fully disposable, replaced wholesale on refresh, never incrementally reconciled against a prior cached ordering.
- **Synchronization Behaviour:** Resolved as reference data, typically once per Trip start rather than per-Ticket (API Specification §26.3.1's own framing of the analogous Fare Rule read applies with equal force here); not on the Ticket/Telemetry synchronization cadence.
- **Offline Behaviour:** A Route reorder or Stop removal made while the ETM is disconnected is a named, real risk — a Ticket captured against stale Route Stop data in the interim reflects the ordering the ETM actually held, not the platform's current one (Domain Specification §5.7, §17 item 5; Reliability Specification §12.10).
- **Validation Expectations:** The ETM validates only that a selected boarding/destination pair is internally consistent against its own cached sequence (e.g., destination reachable from boarding stop on the resolved Route) — it does not, and cannot, validate that its cached sequence itself is current. The platform is solely responsible for the correctness of the Route Stop sequence itself.
- **Consistency Requirements:** Eventually consistent; explicitly named as an acceptable, if consequential, temporary inconsistency (Domain Specification §13; Reliability Specification §9.3).
- **Security Considerations:** No PII; ordinary Operator-scoped reference sensitivity.
- **Versioning Strategy:** Additive-only.
- **Dependencies:** Route (§5.3).
- **Open Questions:** No staleness bound is defined anywhere upstream for how old this contract's cached snapshot may be before the ETM should refuse to issue a Ticket against it (Domain Specification §17 item 5; Reliability Specification §22 item 3) — this document does not resolve that gap, only names it.

### 5.5 Fare Rule

- **Purpose:** Supplies the price a Ticket is issued under.
- **Business Meaning:** The pricing logic in effect for the current Trip's Route or a segment of it (Domain Specification §5.6).
- **Producer:** The platform (Operator Admin authorship — defining a new Fare Rule version).
- **Consumer:** Ticket Capture & Validation — the currently-active rule is consumed to price a Ticket at capture time, and the resulting amount is permanently snapshotted onto the Ticket (Domain Specification §5.6, §12).
- **Authoritative Owner:** The platform, exclusively.
- **Lifecycle:** Defined → Active → Superseded — never deleted while any Ticket still references it (Domain Specification §5.6, §9). A new Fare Rule version is never an edit to an existing one; the prior version is superseded, not mutated, in the same business transaction that activates the new one.
- **Mutability:** The Fare Rule *definition* is mutable at the platform (a new version supersedes the old); a Ticket's *pinned* fare, once captured, is permanently immutable regardless of any later change to the rule it was issued under (Domain Specification §5.6, business rule — "A Fare Rule change never retroactively reprices an already-issued Ticket").
- **Synchronization Behaviour:** Resolved once per Trip start, as the API Specification itself frames this exact read ("resolved once at Trip start, not per-Ticket") — not re-resolved on every Ticket issuance, and not on the Ticket/Telemetry synchronization cadence.
- **Offline Behaviour:** The ETM operates against its last-cached Fare Rule set for the duration of any connectivity gap. A Fare Rule superseded at the platform mid-dead-zone is not reflected until reconnection — Tickets issued in the interim are priced correctly against the version the ETM actually held, which is a permanent, valid business fact, not an error to later correct (Domain Specification §5.6, §13).
- **Validation Expectations:** The ETM validates that the Fare Rule version it applies is the one actually valid for the Trip's operative time, from its own cached set — it does not, and cannot, validate that its cached set is current. The platform is solely responsible for Fare Rule definitional correctness and for the supersession transaction's atomicity.
- **Consistency Requirements:** Eventually consistent for the *definition*; strongly immutable, permanently, for a Ticket's *pinned fare* once captured — these are two different consistency requirements applying to two different facts, and conflating them would be exactly the error Contract Principle 2 warns against.
- **Security Considerations:** Financially sensitive — a Fare Rule and the fare a Ticket is priced under are both revenue-relevant facts, though neither carries personal data. Fare Rule authorship changes are audited on the platform side (API Specification §26.3.2's audit-log side effect); this document does not alter that.
- **Versioning Strategy:** Additive-only at the reference-read level; the supersession lifecycle itself (Defined → Active → Superseded) is the platform's own established business-versioning mechanism, not a schema-versioning concern this document introduces.
- **Dependencies:** Route (§5.3), Route Stop (§5.4, for segment-anchored rules).
- **Open Questions:** None beyond the general staleness-bound question named in §5.4, applying with equal force here.

### 5.6 Trip (as Reference Context)

- **Purpose:** The anchor that gives every Ticket, and by correlation every Telemetry Ping, its business meaning.
- **Business Meaning:** One specific, scheduled or actual operational run of the Device's paired Bus along one specific Route, on one specific day (Domain Specification §5.3).
- **Producer:** The platform (Operator Admin schedules and transitions a Trip's lifecycle).
- **Consumer:** Ticket Capture & Validation, directly — a Ticket cannot be constructed without a resolved Trip. Telemetry Origination consumes this contract only by correlation, never as a precondition (Domain Specification §5.3 vs. §5.5).
- **Authoritative Owner:** The platform, exclusively. Trip lifecycle transitions (Scheduled → In Progress → Completed/Cancelled) are exclusively an Operator Admin action; the ETM has no contract-mutating action over this entity whatsoever (Domain Specification §5.3; Workflow Specification §8, §13).
- **Lifecycle:** Scheduled → In Progress → Completed, with Cancelled reachable only from Scheduled — one-directional, read-only from the ETM (Domain Specification §9).
- **Mutability:** Mutable at the platform (lifecycle transitions, reassignment); the ETM's cached copy is disposable, replaced wholesale on each successful resolution.
- **Synchronization Behaviour:** Resolved as a reference lookup — "which Trip am I currently assigned to" — a read, not a sync operation (API Specification §21; System Architecture §12.2). This is structurally distinct from Ticket/Telemetry synchronization: a failed read here costs nothing, because the ETM never held data this read was responsible for delivering.
- **Offline Behaviour:** The ETM operates against its last successfully resolved Trip assignment for as long as a connectivity gap lasts. It has no way to learn of a Trip transition (a reassignment, a mid-run cancellation) until connectivity returns (Domain Specification §5.3, §13; Workflow Specification §7).
- **Validation Expectations:** The ETM validates only that a resolved Trip context exists before permitting Ticket capture — it performs no validation of the Trip's own correctness (schedule, Route assignment), which is entirely the platform's responsibility.
- **Consistency Requirements:** Eventually consistent; a Ticket may, as a named and accepted consequence, be issued against a Trip assignment the platform no longer considers current, if the ETM was disconnected at the moment of a reassignment or cancellation (Domain Specification §13; Reliability Specification §9.3).
- **Security Considerations:** No PII; ordinary Operator-scoped reference sensitivity.
- **Versioning Strategy:** Additive-only.
- **Dependencies:** Route (§5.3), Bus (§5.2), Device Identity (§7.1, for scope resolution).
- **Open Questions:** No staleness bound is defined for how old a cached Trip assignment may be before the ETM should treat it as unreliable or warn the Conductor (Domain Specification §17 item 5; Workflow Specification §7, Open Questions).

### 5.7 Conductor (as Reference Context / Pairing)

- **Purpose:** Identifies which staff member the Device currently attributes Tickets to.
- **Business Meaning:** The operator-staff member physically carrying the Device for a shift — a business identity, never an authentication credential (Domain Specification §5.2, §3 Principle 4).
- **Producer:** The platform (Operator Admin pairs a Conductor to a Device via the Dashboard).
- **Consumer:** Ticket Capture & Validation, directly — a Ticket with no attributable Conductor is not a valid business record and cannot be captured at all (Domain Specification §5.2, §7).
- **Authoritative Owner:** The platform, exclusively — the ETM's currently-carried Conductor attribute is a cached pairing snapshot, never an authoritative fact the ETM itself asserts or authenticates.
- **Lifecycle:** Onboarded → Assigned (to a Device) → Unassigned → Deactivated — read by the ETM, never advanced by it (Domain Specification §9).
- **Mutability:** Mutable at the platform (a re-pairing action); the ETM's cached copy is replaced wholesale, never incrementally reconciled.
- **Synchronization Behaviour:** Resolved as reference data, opportunistically; not on the Ticket/Telemetry synchronization cadence.
- **Offline Behaviour:** If the ETM has no fresh read of its current Conductor pairing, it operates against its last-known one — this is the direct mechanism behind the misattribution risk named explicitly upstream (Domain Specification §5.2, §17 item 1; Workflow Specification §6, §17).
- **Validation Expectations:** The ETM validates only that *some* Conductor identity is currently resolvable before permitting Ticket capture — it has no mechanism to validate that its cached pairing is still current, since no Conductor-side authentication exists anywhere in the platform to check against (Domain Specification §3 Principle 4, §12).
- **Consistency Requirements:** Eventually consistent, with a named, currently-unresolved consequence (misattribution) if the ETM's cached pairing goes stale during a Conductor handoff — this is not a resolved contract, and this document does not pretend otherwise (§17 of this document, and Domain Specification §17 item 1).
- **Security Considerations:** Carries a personal name/identity attribute, but is not itself a security principal — the Device credential (§7.1) is what actually authenticates; the Conductor attribute travels inside an already-authenticated Device's Ticket payload (Domain Specification §3 Principle 4). This distinction is a security-relevant fact this document flags explicitly: a compromised Device credential is a security incident; a stale Conductor pairing is a data-quality/attribution incident, not an authentication bypass.
- **Versioning Strategy:** Additive-only.
- **Dependencies:** Device Identity (§7.1) — the pairing mechanism.
- **Open Questions:** Conductor misattribution on device handoff — since pairing is exclusively an Operator Admin, Dashboard-side action, an offline mid-shift handoff between two Conductors has no domain mechanism to correct the Device's carried Conductor identity until connectivity returns and an admin acts (Domain Specification §17 item 1; Workflow Specification §6, §17). This document does not resolve it, and treats it as a live open question for a future contract revision.

### 5.8 Configuration Reference Data

- **Purpose:** Any small, platform-defined operational parameter the ETM needs to behave correctly that is not itself a domain entity (e.g., a validation-rule bound, a currently-defined enumeration value set).
- **Business Meaning:** Platform-level operating parameters, not business entities in their own right.
- **Producer:** The platform, implicitly, through whatever mechanism already defines these values for backend consumers.
- **Consumer:** Whichever ETM subsystem needs the parameter to behave correctly (e.g., domain validation logic needing to know a currently-valid enumeration value set).
- **Authoritative Owner:** The platform.
- **Lifecycle:** Effectively static at ETM-observable timescales; no reviewed specification names a workflow by which this contract changes independent of an app release.
- **Mutability:** Presumed low-frequency; not separately governed by this document beyond the general Reference Contract disposability rule (§3 Principle 3).
- **Synchronization Behaviour:** Not separately defined; this document names the contract's existence without inventing a specific resolution mechanism no upstream document defines.
- **Offline Behaviour:** Operates against whatever value was last known or shipped with the app build; no reviewed specification names a runtime refresh mechanism for this class of data.
- **Validation Expectations:** Not separately defined beyond ordinary Reference Contract handling.
- **Consistency Requirements:** Eventually consistent, at most; likely closer to "fixed per app release" in practice, though this document does not assert a mechanism no upstream document names.
- **Security Considerations:** None distinct from ordinary Reference Contract handling.
- **Versioning Strategy:** Additive-only, consistent with every other Reference Contract.
- **Dependencies:** None named specifically.
- **Open Questions:** Whether this class of contract needs its own resolution mechanism distinct from the named entity-level Reference Contracts above is not resolved by any upstream document; this document names the class for completeness without inventing a mechanism for it.

### 5.9 General staleness posture across all Reference Contracts

Restated once here, because it applies identically to every contract in this section and repeating it per-contract would obscure rather than clarify: **no Reference Contract in this document carries a defined staleness bound.** The ETM can make staleness *knowable* (an age can, in principle, be tracked per cached value) but no upstream specification defines the threshold at which staleness becomes a business-unacceptable condition warranting a refusal or a Conductor-facing warning (Domain Specification §17 item 5; System Architecture §12.2, §23 item 4; Reliability Specification §9.4, §22 item 3). This is the single most consequential open question this document inherits, named once here and cross-referenced rather than repeated at every affected contract.

## 6. Operational Contracts

Operational Contracts are originated by the ETM, are append-only, and are the ETM's actual business output to the platform. Unlike Reference Contracts, the ETM is the authoritative source of an Operational Contract from the moment of capture until the platform reconciles it — the one deliberate exception to "the platform is always authoritative" (Contract Principle 2).

### 6.1 Ticket

- **Purpose:** The ETM's primary business output — a single fare transaction, attributable and fare-leakage-accountable.
- **Business Meaning:** One Conductor, one fare, one Trip, one passenger movement — boarding stop to destination stop (Domain Specification §5.4).
- **Producer:** The ETM, exclusively — the Conductor's fare-sale action, captured on-device.
- **Consumer:** The platform's ingestion and reconciliation pipeline; downstream, the Occupancy Estimate, ETA, and revenue-reporting concepts the platform derives from reconciled Tickets (none of which the ETM itself produces or consumes — Domain Specification §5.4, "Notes").
- **Authoritative Owner:** The ETM's own durable local store, from the moment of capture until the platform reconciles it; the platform thereafter, permanently (Domain Specification §14; Reliability Specification §9.1).
- **Lifecycle:** Captured → Buffered → Synced → Reconciled, with Voided reachable only after Reconciled via a new, separate correcting record — never an edit (Domain Specification §9; Reliability Specification §5, §6).
- **Mutability:** Immutable for the life of the record, permanently, from the moment of capture. A correction is a new, distinct Ticket referencing the original, never a mutation (Domain Specification §3 Principle 5, §5.4, business rule).
- **Synchronization Behaviour:** Captured durably before any network attempt is even considered, transported at-least-once, and synchronized independently of the Telemetry Ping partition, with no blanket priority between the two (Reliability Specification §5, §6, §11.4; ADR-011). Deduplicated at the platform by a permanent, non-expiring uniqueness rule — reflecting the materially higher stakes of a duplicate fare charge versus a duplicate location reading (Reliability Specification §11; MQTT Specification §14.2).
- **Offline Behaviour:** Fully creatable with zero connectivity; remains safely buffered for as long as a dead zone lasts, with no risk of loss and no requirement that the ETM know or care that this happened (Domain Specification §13; Reliability Specification §12.1).
- **Validation Expectations:** The ETM validates the Ticket's hard preconditions before capture — a resolved Trip, Conductor, Fare Rule, and boarding/destination Route Stop pair, all internally consistent against the ETM's own (possibly cached) reference data (Domain Specification §5.4, §12; §9 of this document). The platform separately, and independently, validates referential integrity (that the referenced Trip, Fare Rule, and Route Stops actually resolve within the Device's own Operator) at ingestion time, and performs a Conductor/Device pairing plausibility check that does not block persistence on a mismatch (MQTT Specification §22.2). Neither party's validation substitutes for the other's.
- **Consistency Requirements:** Strongly consistent in the sense that exactly one party is authoritative at any given moment (§6.1's "Authoritative Owner," above) — never eventually consistent in the sense of "either copy might currently be correct." Idempotent under duplicate delivery, by platform-side design, never by ETM-side suppression (§9 of this document; Reliability Specification §14).
- **Security Considerations:** Fare-leakage-accountable and revenue-sensitive; carries an optional, nullable link to a Commuter account (never populated by the ETM at MVP — Domain Specification §17 item 4). The Ticket's own primary key is platform-assigned, never asserted by the ETM (a deliberate boundary — the ETM's identity contribution to this contract is limited to `device_id` and `client_timestamp` as its dedup identity, not a business-record key it originates).
- **Versioning Strategy:** Additive-only, governed entirely by the platform's own field-safety rule for this payload shape — new fields may be added without breaking an ETM running an older schema version, and field identifiers are never reused for a different meaning (ADR-002; MQTT Specification §22.1). This document does not name the mechanism (that is Protobuf's own concern) — it states the business consequence: a fleet running mixed ETM versions can coexist indefinitely against this contract's evolution.
- **Dependencies:** Trip (§5.6), Conductor (§5.7), Fare Rule (§5.5), Route Stop (§5.4), Device Identity (§7.1).
- **Open Questions:** Ticket reconciliation visibility — no reviewed specification defines a mechanism by which the ETM learns that a specific Ticket has actually reached the platform's authoritative, reconciled record, as distinct from merely having been transmitted (Domain Specification §17 item 2; Workflow Specification §9, §12). Ticket correction/void — the Domain Model names the intended shape of a correction but no actor, trigger, or mechanism for actually performing one is defined anywhere in the reviewed specifications (Domain Specification §17 item 3; Workflow Specification §9). Neither gap is resolved here.

### 6.2 Telemetry Ping

- **Purpose:** A single location/status report from the Device's paired Bus — the highest-frequency contract the ETM produces.
- **Business Meaning:** Evidence of where the Bus is and, by extension, of the Trip's route progress (Domain Specification §5.5).
- **Producer:** The ETM, exclusively — a location/status reading captured at the platform's adaptive cadence.
- **Consumer:** The platform's ingestion pipeline; downstream, the live-position picture, ETA computation, and Commuter tracking the platform derives from reconciled Pings (none of which the ETM itself produces or consumes).
- **Authoritative Owner:** The ETM's own durable local store, from the moment of capture until the platform reconciles it; the platform thereafter — identical in shape to Ticket's ownership arrangement, because it is the same reliability class with a different payload (ADR-011; Domain Specification §5.5, §14).
- **Lifecycle:** Captured → Buffered → Synced → Reconciled — structurally identical to Ticket's (Domain Specification §9).
- **Mutability:** Immutable once captured; never modified or deleted (Domain Specification §5.5).
- **Synchronization Behaviour:** Identical mechanism to Ticket's — durable-before-network, at-least-once, independently drained, no blanket priority — differing only in dedup mechanism: a time-windowed ledger rather than a permanent constraint, reflecting the materially lower per-event stakes of a duplicate location reading versus a duplicate fare charge (Reliability Specification §11; MQTT Specification §14.1).
- **Offline Behaviour:** Continues to be captured and buffered through any length of dead zone; nothing about capture requires connectivity (Domain Specification §13; Reliability Specification §12.1).
- **Validation Expectations:** The ETM validates only that a well-formed coordinate/status reading exists and that the Device's own identity is attached — notably, unlike a Ticket, no Trip or Conductor precondition applies (Domain Specification §5.5, §12). The platform separately validates the reading's structural well-formedness (coordinate ranges, speed/heading bounds) at ingestion, and computes a cross-row plausibility signal the ETM has no equivalent visibility into or responsibility for (MQTT Specification §22.2, and its note on the platform-side-only plausibility flag).
- **Consistency Requirements:** Identical in shape to Ticket's (§6.1) — strongly consistent in single-owner terms, idempotent under duplicate delivery by platform-side design.
- **Security Considerations:** Carries no direct financial stakes, but is a location-data contract, and location data is treated platform-wide as consent-gated by default where it pertains to any consumer-facing sharing (Product Engineering Blueprint Part 13) — though the ETM's own Telemetry origination is a Device-level operational fact, not a Commuter consent-gated feature, and this document does not conflate the two.
- **Versioning Strategy:** Additive-only, identical governing rule to Ticket's (ADR-002; MQTT Specification §22.1).
- **Dependencies:** Device Identity (§7.1) only — deliberately independent of Trip, Conductor, and Fare Rule context (Domain Specification §5.5, "Dependencies").
- **Open Questions:** A Telemetry Ping's own reconciliation visibility carries the same gap named for Ticket (§6.1) — the ETM has no more insight into a Ping's reconciliation than a Ticket's (Domain Specification §5.5, "State Changes").

### 6.3 The absence of Command Contracts

Named explicitly, because a Data Contracts Specification that silently omits a classification invites the assumption it was overlooked rather than deliberately absent: **no Command Contract exists at the ETM boundary at MVP.** The platform never issues an instruction the ETM is obligated to execute — there is no push-command channel, no remote configuration push, and no dashboard-initiated action that reaches into the ETM's own operation (System Architecture §9, "Outside the ETM's architectural boundary"; MQTT Specification §9.4, naming a reserved, not-yet-used broker-to-device channel). This document does not invent a Command Contract to fill this classification — it states the absence as a deliberate architectural fact, consistent with the ETM's own scope discipline (Product Specification §13: "the device does exactly two jobs... and nothing else").

## 7. Identity Contracts

Identity Contracts govern who the ETM is and what it is currently authorized to do — the root of trust every other contract in this document depends on.

### 7.1 Device Identity

- **Purpose:** The ETM's own business identity — the thing that authenticates, is provisioned, is revoked, and is the attributed origin of every Ticket and Telemetry Ping it produces.
- **Business Meaning:** Operator-provisioned conductor hardware; never a commuter's phone; never itself a Conductor (Domain Specification §5.1).
- **Producer:** The platform, exclusively — provisioning happens entirely on the backend/Dashboard side, ahead of the ETM ever running on the hardware (Domain Specification §5.1, "Creation Rules").
- **Consumer:** Every ETM subsystem that presents an authenticated identity to an outbound interaction — this contract is the root every other contract's authorization ultimately traces back to (System Architecture §12.1).
- **Authoritative Owner:** The platform, permanently. The ETM holds a bearer credential and a locally-cached view of its own status and pairing, never the authoritative record of either (Domain Specification §5.1, "Source of Truth").
- **Lifecycle:** Provisioned → Assigned (to a Bus) → Active → Unassigned → Revoked — every transition is backend-initiated; the ETM has no contract action that changes its own Device state (Domain Specification §5.1, §9).
- **Mutability:** The credential itself is issued once and used for the life of the provisioning; the Device's status and pairing are mutable at the platform and re-resolved by the ETM as connectivity allows, never authored locally.
- **Synchronization Behaviour:** The credential is resolved once at provisioning; status and pairing are re-resolved from the platform on every subsequent authenticated interaction the ETM undertakes, and separately, explicitly, on every single request for the specific purpose of enforcing instant revocation (a distinguishing property of this contract relative to every other Identity or Reference Contract in this document — see "Refresh Behaviour" below).
- **Offline Behaviour:** A Device with no connectivity continues to operate against its last-known pairing and status; it cannot detect its own revocation until connectivity returns (Domain Specification §5.1, "Offline Behaviour").
- **Refresh Behaviour:** Unlike a Reference Contract, this contract's authorization component is re-verified fresh on every single request the ETM makes to the platform — never cached for a request's own duration, and never inferred from a prior success (API Specification §6.2; ADR-007, ADR-009). This is the direct mechanism behind instant, unconditional revocation: a lost or compromised Device loses access the moment the platform's own verification next executes, without waiting for any refresh interval to elapse.
- **Failure Behaviour:** When the platform cannot verify this contract's current status for any reason (including its own inability to reach its verification store), it denies by default — an unrecoverable trust failure is always treated as strictly worse than a recoverable one (ADR-007; Domain Specification §5.1, "Business Rules"). The ETM has no mechanism to distinguish, on its own, "wrong credential" from "correct credential, no longer authorized" from "platform temporarily could not verify" — all three present identically to the ETM (Workflow Specification §16).
- **Expiry Behaviour:** This contract carries no time-based expiry in the way a session token does — it remains valid until explicitly revoked, at which point it becomes invalid permanently unless the platform restores the Device to an operable status. There is no refresh-rotation concept for this contract, unlike the platform's own dashboard-user session contract (API Specification §6.3, by contrast, for a different caller class entirely).
- **Validation Expectations:** The ETM performs no validation of its own credential's validity — it presents the credential and observes the platform's response. All validation of this contract is exclusively the platform's responsibility (Domain Specification §5.1, "Validation Rules": "None the ETM enforces on itself").
- **Consistency Requirements:** Strongly consistent by design — the platform's per-request verification is precisely what makes this contract's authorization state impossible to observe as "stale" in the way a Reference Contract can be. The ETM's own cached view of its status (used only to decide whether to *attempt* an interaction, never to *authorize* one) is, by contrast, eventually consistent and may lag the platform's actual determination between attempts.
- **Security Considerations:** This is the ETM's only security principal (System Architecture §17). No subsystem models "the Conductor" as an authentication concept — Conductor identity (§5.7) is domain data carried on a Ticket, never itself a credential. The credential's compromise is the single event the platform's revocation and fail-closed mechanisms exist to bound the damage from (ADR-007, ADR-009); this document does not name the storage mechanism protecting the credential at rest (an ETM Technology Decision concern), only the business contract the credential represents.
- **Versioning Strategy:** Not applicable in the additive-field sense — this contract's shape (a credential plus an observable status) is not expected to evolve in a way this document's versioning discipline (§12) needs to separately govern; any future change (e.g., a Conductor self-identification mechanism extending this contract's domain, per System Architecture §19) would be a deliberate, explicitly-announced contract revision, not an incidental one.
- **Dependencies:** None upstream within the ETM — this is the root of trust every other contract in this document ultimately depends on (System Architecture §12.1).
- **Open Questions:** How a Device receives its initial credential and identity in the field — whether this is an ETM-app responsibility or a separate provisioning tool — is unresolved (Domain Specification §17 item 6; Product Specification §21). The fate of a revoked Device's own not-yet-transmitted Operational Contract backlog is likewise unresolved (Workflow Specification §15, Open Questions; Reliability Specification §22 item 4).

### 7.2 Authorization State

- **Purpose:** Represent, honestly and distinctly from a connectivity gap, whether the ETM is currently authorized to act.
- **Business Meaning:** Not a separate entity from Device Identity (§7.1) — this is the *observable state* Device Identity's authorization component resolves to at any given moment: authorized, denied, or unknown-pending-verification.
- **Producer:** The platform, exclusively — the ETM never computes or infers this state; it observes what the platform's own verification returns (System Architecture §12.1, §17: "Authorization state is a value the ETM observes, never one it computes").
- **Consumer:** Every ETM subsystem that gates an outbound attempt on authorization — Synchronization & Transport, Reference Context Resolution, and (indirectly, via Diagnostics) the Conductor-facing sync-status representation (System Architecture §12.1, §17).
- **Authoritative Owner:** The platform, permanently and exclusively.
- **Lifecycle:** Authorized ↔ Denied, with an Unknown/unverified transient state possible whenever the platform's own verification cannot complete (a connectivity gap, or a platform-side outage) — this document does not name Unknown as a business state the platform itself asserts, only as the ETM's own honest representation of "I do not currently know."
- **Mutability:** Fully mutable at the platform, at any time, unconditionally (Workflow Specification §15).
- **Synchronization Behaviour:** Re-observed on every outbound interaction attempt; this contract has no independent refresh cadence of its own distinct from Device Identity's per-request verification (§7.1).
- **Offline Behaviour:** During a connectivity gap, the ETM's last-observed Authorization State is retained, but the ETM must not treat "I was last authorized" as equivalent to "I am currently authorized" — the honest representation during an offline period is "unknown, pending next verification," not a carried-forward assumption of continued validity.
- **Validation Expectations:** None performed by the ETM — this is a pure observation contract.
- **Consistency Requirements:** By construction, this contract cannot be stale in the way a Reference Contract can, because it is re-verified on every request rather than cached and reused (§7.1's "Refresh Behaviour"). It can, however, be *unknown* during a connectivity gap, which this document treats as a distinct state from both "authorized" and "denied," never collapsed into either.
- **Security Considerations:** This is the contract that makes fail-closed a lived behavior rather than a stated policy — every subsystem that gates on this contract treats "cannot verify" as equivalent to "not authorized" for the purpose of ceasing new attempts, mirroring the platform's own fail-closed posture at the ETM's own boundary (ADR-007; System Architecture §16).
- **Versioning Strategy:** Not applicable — this is an observed state, not an evolving payload shape.
- **Dependencies:** Device Identity (§7.1).
- **Open Questions:** Whether "not authorized" and "no connectivity" can actually be distinguished at the signal level the ETM genuinely receives — or whether this document's own assumption that a clean distinction is preservable outruns what the underlying platform signal actually provides — is inherited, unresolved, from the System Architecture Specification (§23 item 2) and the Workflow Specification (§16, Open Questions). This document does not resolve it.

### 7.3 Session/Connection State

- **Purpose:** Represent whether a confirmed transport-session channel currently exists, distinct from mere network-interface presence.
- **Business Meaning:** The two-condition gate the platform's own synchronization contract requires — genuine network connectivity **and** a confirmed transport session, neither alone being sufficient (Reliability Specification §7.1; MQTT Specification §12).
- **Producer:** Jointly observed — network-interface presence is a device-platform (OS-level) fact; transport-session confirmation is a fact the platform's own transport-session mechanism establishes and the ETM observes the outcome of.
- **Consumer:** Synchronization & Transport, exclusively — this contract gates whether a synchronization attempt is made at all (System Architecture §12.6; Reliability Specification §7).
- **Authoritative Owner:** Neither the ETM nor the platform alone — this is a genuinely joint, observed fact about the current state of a specific connection, not a business record either party asserts unilaterally. It is named as a distinct contract here precisely because it does not fit this document's usual single-owner model, and forcing it into that model would misrepresent it.
- **Lifecycle:** Disconnected → Connecting → Connected → Disconnected (an ordinary cycle); no persistent identity survives across cycles in the way Device Identity does.
- **Mutability:** Continuously re-evaluated; never a cached, disposable snapshot in the way a Reference Contract is, and never authoritative in the way an Operational Contract is — it is a live, momentary observation.
- **Synchronization Behaviour:** Not itself synchronized — it is the *precondition* for Ticket/Telemetry synchronization, not a synchronized fact in its own right.
- **Offline Behaviour:** By definition, "Offline" is one of this contract's own possible values, not a degraded mode of it.
- **Validation Expectations:** None in the business-validation sense; this is an observed technical-readiness signal.
- **Consistency Requirements:** Momentary and continuously re-observed; no staleness concept applies, since this contract's entire purpose is to represent the current instant, not a cached snapshot of a past one.
- **Security Considerations:** None distinct from ordinary connection-level security already governed by Device Identity's authentication contract (§7.1).
- **Versioning Strategy:** Not applicable.
- **Dependencies:** None named beyond the underlying platform transport mechanism this document does not describe at the implementation level.
- **Open Questions:** None specific to this contract.

## 8. Configuration Contracts

Configuration Contracts are ETM-local, non-authoritative operational state — never a business record, and never treated as anything but fully disposable (System Architecture §12.9, §14).

### 8.1 Local Pairing Snapshot

- **Purpose:** Hold the ETM's own last-known view of its Bus/Conductor pairing between resolution attempts, so other subsystems have a fast, offline-available value to read before or between live resolutions.
- **Business Meaning:** Not a business entity in its own right — a locally-held echo of the Bus (§5.2) and Conductor (§5.7) Reference Contracts, retained for offline availability only.
- **Producer:** Written as a side effect of Reference Context Resolution's own successful resolutions (§5.2, §5.7); the ETM does not originate this value independently.
- **Consumer:** Any ETM subsystem needing a fast, offline-available "what did we last know" read (System Architecture §12.9).
- **Authoritative Owner:** Nothing — this contract is never authoritative for anything. It is a cache of a cache, and its loss costs nothing beyond a re-resolution on next connectivity (System Architecture §14).
- **Lifecycle:** Written, read, overwritten — no independent lifecycle beyond mirroring whatever Bus/Conductor pairing was last successfully resolved.
- **Mutability:** Fully mutable, fully disposable.
- **Synchronization Behaviour:** Not synchronized to the platform at all — this is a purely local artifact.
- **Offline Behaviour:** Its entire purpose is to remain available and useful during offline operation; there is no "offline behavior" distinct from its normal behavior.
- **Validation Expectations:** None.
- **Consistency Requirements:** None — this contract makes no consistency claim of its own; it is exactly as fresh (or stale) as the Reference Contract it last echoed.
- **Security Considerations:** None beyond whatever sensitivity the underlying Bus/Conductor Reference Contracts already carry (minimal — no PII on Bus; a name-level attribute on Conductor).
- **Versioning Strategy:** Not applicable.
- **Dependencies:** Bus (§5.2), Conductor (§5.7).
- **Open Questions:** None.

### 8.2 Last-Sync State

- **Purpose:** Hold a locally-observable record of when synchronization last succeeded, for diagnostic and Conductor-facing honesty purposes.
- **Business Meaning:** Not a business entity — an ETM-local operational fact about its own synchronization history.
- **Producer:** Written as a side effect of Synchronization & Transport's own successful drain cycles (System Architecture §12.6, §12.9).
- **Consumer:** Sync-Status & Reconciliation Honesty (Diagnostics — §8.3 of this document), for representing sync currency to the Conductor.
- **Authoritative Owner:** Nothing — fully disposable, never authoritative for anything a business decision depends on.
- **Lifecycle:** Continuously updated on each successful sync cycle.
- **Mutability:** Fully mutable, fully disposable.
- **Synchronization Behaviour:** Not itself synchronized to the platform.
- **Offline Behaviour:** Simply stops advancing during an offline period — its own staleness is itself the honest signal Diagnostics surfaces.
- **Validation Expectations:** None.
- **Consistency Requirements:** None of its own.
- **Security Considerations:** None.
- **Versioning Strategy:** Not applicable.
- **Dependencies:** Ticket (§6.1), Telemetry Ping (§6.2) synchronization outcomes.
- **Open Questions:** None.

### 8.3 Diagnostics Contracts

Two genuinely distinct contracts exist under this heading, and conflating them is a realistic source of confusion this document deliberately avoids:

- **Sync/Reconciliation Status (Conductor-facing):** The truthful, queryable answer to "did my sale go through," aggregating the furthest lifecycle state the ETM can actually observe (Captured, Buffered, Synced — never Reconciled) alongside current Authorization State (§7.2) and Reference Context staleness, as distinct, non-conflated facts (System Architecture §12.8). **Authoritative Owner:** nothing — this is a pure observability layer over state other contracts already hold; its own failure degrades visibility, never correctness. **Consumer:** whatever future UI layer presents this to the Conductor. **Versioning Strategy:** additive-only; a stronger reconciliation-visibility signal, should the platform ever expose one, extends this contract by adding a new observable state above "Synced," never requiring a redesign (System Architecture §19).
- **Operational Log Record (engineering-facing):** Structured operational events — capture attempts, durability confirmations, sync attempts and outcomes, authorization-state changes, background-execution lifecycle transitions — captured durably enough to survive the same failure modes the rest of the system survives, consumed by engineering tooling, never by the Conductor (System Architecture §12.10). **Authoritative Owner:** nothing — by design, an observability subsystem that became load-bearing for correctness would itself be a defect (System Architecture §12.10, echoing ADR-013's reasoning). **Security Considerations:** must avoid capturing business-sensitive payload contents beyond what diagnosing a reliability problem requires (System Architecture §12.10) — this is a data-minimization contract obligation, not merely a technical one.

Both Diagnostics contracts share the same governing rule: **their own failure or unavailability must never affect capture, durability, or synchronization** — they are pure consumers of state other contracts in this document already hold, never producers of anything another contract depends on.

## 9. Validation Responsibilities

Validation is split by which party is positioned to catch a defect first, and which party is authoritative for the underlying correctness the validation protects — these are frequently, but not always, the same party.

| Validation | Belongs to | Reasoning |
|---|---|---|
| A Ticket's hard preconditions (resolved Trip, Conductor, Fare Rule, Route Stop pair) are present and internally consistent | **ETM** | The ETM is the only party positioned to catch this before the record is even captured; a Ticket missing a precondition must never reach durable persistence in a partial state (Domain Specification §5.4, §12; Reliability Specification §5). |
| A Ticket/Telemetry Ping's referenced Trip, Fare Rule, and Route Stops actually resolve within the Device's own Operator | **Platform** | Only the platform holds the authoritative record these references must resolve against; the ETM's own cached copy cannot itself validate against the platform's current truth (MQTT Specification §22.2; Sequence Diagrams §11.3). |
| A Ticket's Conductor attribution plausibly matches the Device's currently-paired Conductor | **Platform, as a non-blocking monitoring signal, not a validation gate** | A mismatch is at least as plausibly a benign timing lag (a reassignment the ETM's cache hasn't caught up to) as a genuine anomaly, and blocking on it would risk the one outcome this system is built to prevent — losing a Ticket (MQTT Specification §22.2). |
| A Telemetry Ping's structural well-formedness (coordinate ranges, speed/heading bounds) | **Platform** | The ETM captures whatever reading its sensors actually produce; structural range validation is an ingestion-time concern, not a capture-time gate that would risk blocking or discarding a genuine reading (MQTT Specification §22.2). |
| The Device's own credential validity and current authorization status | **Platform, exclusively** | The ETM has no local logic that decides whether it is authorized — that determination is exclusively the platform's, and the ETM never second-guesses or overrides it (System Architecture §17). |
| A Reference Contract's own definitional correctness (a Route's name, a Fare Rule's amount, a Trip's schedule) | **Platform, exclusively** | The ETM never authors business truth about any Reference Contract; it resolves, never validates or corrects, what the platform asserts (Domain Specification §3 Principle 1). |
| Structural/transport well-formedness of any payload the ETM produces (decodability, field presence) | **Both, at different points** | The ETM's own domain-validation gate (above) is a business-rule check; the platform's decode/schema validation at ingestion is a structural check catching a defect the ETM's own business-rule validation would not catch (a malformed byte stream, a field outside a structurally valid range) — neither substitutes for the other (MQTT Specification §22.2). |

**The governing rule this table expresses:** business validation belongs to whichever party actually understands the business rule and is positioned to enforce it without either blocking a durability-critical capture action or requiring information only the other party holds; structural/transport validation belongs to whichever party first receives the data in a form that validation applies to. No contract in this document is validated by exactly zero parties, and no contract is validated redundantly in a way that duplicates the same check for no additional protection.

## 10. Ownership Model

Restated as a single consolidated table, because scattering ownership across each contract's own section (§5–§8) risks obscuring the pattern that actually matters — that exactly two contract classes ever hold ETM-side authority, and every other class is platform-authoritative without exception:

| Owner | Owns |
|---|---|
| **The Platform** | Every Reference Contract (§5), both Identity Contracts' authorization determination (§7.1, §7.2), and every Operational Contract (§6) from the moment of platform reconciliation onward. |
| **The ETM (temporarily)** | Ticket and Telemetry Ping (§6.1, §6.2), exclusively between capture and platform reconciliation — the one deliberate, narrow exception to platform authority, scoped precisely to this window and no further (Contract Principle 2). |
| **Nothing, permanently** | Every Configuration Contract (§8) and both Diagnostics contracts (§8.3) — these are disposable by design and never authoritative for any business decision. |
| **Neither party alone** | Session/Connection State (§7.3) — a genuinely joint, momentary observed fact rather than a business record either party asserts unilaterally. |

**The rule this table exists to protect:** exactly one class of contract (Operational Contracts, pre-reconciliation) ever grants the ETM temporary authority, and that authority is automatically, permanently surrendered the moment the platform reconciles the same fact. No other contract in this document grants the ETM authority under any circumstance, and this document treats any future proposal that would grant the ETM authority over a Reference, Identity, or Configuration Contract as a fundamental architectural change requiring explicit justification, not a routine contract update (Domain Specification §8; System Architecture §8, Principle 4).

## 11. Consistency Model

- **Strongly consistent (exactly one authoritative holder, no window of ambiguity):** Ticket and Telemetry Ping, pre-reconciliation, held exclusively by the ETM (§6.1, §6.2); Device Identity's authorization determination, re-verified fresh on every request rather than cached (§7.1, §7.2).
- **Eventually consistent (by design, not by defect):** every Reference Contract (§5) relative to the platform's current state; a Ticket or Telemetry Ping's presence at the platform relative to its capture time, bounded only by connectivity and the Reliability Specification's own pacing model (Reliability Specification §11).
- **Immutable once fixed:** a Ticket's pinned fare amount, permanently, regardless of any later Fare Rule change (§5.5, §6.1); every Operational Contract's own captured fields, permanently, once durable capture completes (§6.1, §6.2).
- **Momentary, continuously re-observed, no staleness concept applies:** Session/Connection State (§7.3).
- **Accepted, named temporary inconsistency:** a Ticket may reflect superseded Trip/Fare Rule/Route Stop context, or a stale Conductor pairing, for the duration of an offline period (§5.4, §5.6, §5.7, §9.3 of the Reliability Specification) — named explicitly here rather than glossed over, consistent with this document's own philosophy (§2).
- **Idempotent, never exactly-once:** both Operational Contracts, under duplicate delivery — a platform-side guarantee this document's Ticket/Telemetry entries (§6.1, §6.2) rely on but do not themselves implement (Reliability Specification §14; MQTT Specification §14).

## 12. Versioning Strategy

Four governing rules, applied uniformly across every contract in this document unless a specific contract's own section (§5–§8) states otherwise:

1. **Additive change never requires a breaking migration.** A new optional field on any contract's resolved shape, a new Reference Contract entirely, or a new observable Diagnostics state is added without requiring an already-deployed ETM instance to change how it consumes fields it does not yet use (Contract Principle 4; ADR-002; API Specification §5). An older ETM simply never populates or consumes the new addition — it is never broken by its absence.
2. **A required field is never added to an existing contract without an explicit, separately-announced migration.** Because the ETM cannot be force-upgraded fleet-wide (Product Specification §14), a contract change that would make an older ETM's existing production invalid is treated as a breaking change requiring the same discipline the platform's own API versioning already applies: introduce the new requirement alongside the old shape, support both during an explicit migration window, and retire the old shape only after fleet-wide rollout is confirmed, never on a calendar date (API Specification §5, §22; MQTT Specification §22.1a).
3. **A discriminator field (e.g., an event-type indicator) is preferred over a rigid enumeration wherever a future value is plausible**, because a discriminator validated against a currently-defined value set can be extended by a platform-side migration without a coordinated app-and-backend redeploy, whereas a rigid enumeration cannot (MQTT Specification §21.2, §22.1, restating this exact reasoning for the platform's own `BusEvent.type` field). This document does not name which specific contracts use this pattern at the wire level (that is the platform's own concern) — it states the business consequence: a future third Operational Contract type (already anticipated by the platform's own architecture — System Architecture §19) is expected to compose as an additive extension, not a breaking redefinition.
4. **Unknown fields are never treated as an error.** A contract's consumer — ETM or platform — ignores a field it does not recognize rather than rejecting the entire contract on account of it. This is what makes rule 1 actually work in practice, and this document treats it as a hard requirement of every contract's evolution, not an implementation nicety.

**Optional vs. required, as a business-contract distinction, not merely a schema one:** a field is optional at the contract level if the business fact it represents can genuinely be absent without invalidating the whole (a Ticket's `commuter_id`, absent for a cash sale — §6.1; a Telemetry Ping's Trip correlation, resolved by the platform, not asserted as a hard field by the ETM — §6.2, §5.6). A field is required at the contract level if its absence means the underlying business fact cannot exist at all (a Ticket's Trip, Conductor, Fare Rule, and Route Stop references — §6.1; a Telemetry Ping's Device identity — §6.2). This document's optional/required distinction is a statement about business meaning, and happens to be reflected in the platform's own wire-level schema without this document needing to restate that schema.

**Deprecation and migration**, at the contract level: a contract is never removed from this document while any deployed ETM instance still depends on it, and a superseding contract is introduced alongside the deprecated one during an explicit window, mirroring the platform's own 90-day minimum concurrent-availability discipline for its own API surface (API Specification §22) — this document does not fix a specific window length for ETM-side contract deprecation, since no upstream document has yet named one distinct from the platform's own API deprecation window, but states the governing principle: the ETM's own inability to be force-upgraded means any deprecation window chosen must be at least as generous as the platform's own.

## 13. Security Considerations

- **Sensitive contracts, ranked by consequence of compromise:** Device Identity (§7.1) is the single most consequential contract in this document to compromise — its compromise grants an attacker the ability to originate Tickets and Telemetry as though legitimately authorized, until revoked. Ticket (§6.1) is the next most consequential — a fare-leakage-accountable, financially sensitive contract. Every Reference Contract (§5) carries materially lower sensitivity, since none of them are ETM-originated and none grant write authority over anything.
- **Personally identifiable information:** Conductor (§5.7) carries a name-level personal attribute, though it is not itself a security principal. Ticket (§6.1) carries an optional, nullable Commuter link, never populated by the ETM at MVP (Domain Specification §17 item 4). No other contract in this document carries PII.
- **Device identity:** covered fully in §7.1; restated here only to note that this document treats Device Identity's compromise and a Conductor-attribution error (§5.7) as two categorically different severities — the former a security incident, the latter a data-quality/attribution incident — and this document does not conflate them anywhere in its treatment.
- **Authentication:** exclusively Device Identity's (§7.1) concern; no other actor type (Conductor, Operator) is ever an authentication concept at the ETM boundary (Domain Specification §3 Principle 4).
- **Authorization:** exclusively Authorization State's (§7.2) concern, always platform-determined, never ETM-computed (System Architecture §17).
- **Integrity:** every Operational Contract's (§6) durability guarantee (an atomic, all-or-nothing local write — Reliability Specification §8) is itself an integrity property this document depends on without restating; every Reference Contract's integrity is exclusively the platform's responsibility, since the ETM never authors or corrects one.
- **Confidentiality:** this document does not name a specific encryption or storage mechanism (an ETM Technology Decision concern) — it states that Device Identity's credential and any Conductor personal-attribute data carried on a Ticket are the two classes of information in this document warranting confidentiality treatment beyond ordinary operational data, consistent with the Product Specification's own named risk (device loss or theft mid-shift, Product Specification §17).
- **Replay protection:** achieved entirely at the platform side, via the deduplication mechanisms named in §6.1 and §6.2 — the ETM contributes a stable, non-regenerated capture-time identifier to every Operational Contract instance (§14 of the Reliability Specification), but the actual replay-protection mechanism (a permanent constraint for Ticket, a time-windowed ledger for Telemetry) is exclusively platform-side and this document does not restate it.
- **Trust boundaries:** the Device credential is the ETM's only trust boundary with the platform (§7.1). No contract in this document crosses a second, independent trust boundary — there is no separate Conductor-level or Commuter-level trust boundary the ETM itself manages, consistent with the platform's own differentiated-trust model applying a distinct scheme to each caller class (ADR-009), of which the Device is exactly one.

## 14. Compatibility Strategy

- **Backward compatibility** (an older platform version consuming a newer ETM's contract instance, or vice versa) is achieved through additive-only evolution (§12, rule 1) — the dominant compatibility strategy this document relies on for every contract.
- **Forward compatibility** (a newer platform version's contract instance being consumed by an older, not-yet-upgraded ETM) is achieved through the "unknown fields are never an error" rule (§12, rule 4) — an older ETM simply ignores a Reference Contract field it does not yet know to consume, and continues operating correctly against the fields it does recognize.
- **A fleet running mixed ETM versions indefinitely is the assumed normal condition, not a transitional one.** No contract in this document is described as though a coordinated, fleet-wide cutover is a viable compatibility strategy, because it is not one available to this platform (Product Specification §14; ETM Technology Decisions §5.27's staged-rollout rationale, itself a response to this same constraint).
- **A contract's optional fields are always safe to omit; a contract's required fields are never made optional without a full contract revision**, since weakening a required field to optional silently changes the underlying business guarantee (e.g., making Ticket's Trip reference optional would silently permit an unattributable Ticket, which Domain Specification §7 names as an invalid business record under any circumstance).

## 15. Evolution Strategy

- **A new Operational Contract type** (the platform's own architecture already anticipates a third edge-generated event type, per System Architecture §19, naming commuter location-sharing as an illustrative future example) is expected to compose as an additive extension of the existing Ticket/Telemetry pattern — sharing the same durability, synchronization, and dedup-pattern guarantees already established, differentiated only where its own domain genuinely requires it, exactly as Ticketing composed within the mechanism originally proven for Telemetry (ADR-011; Reliability Specification §25 item 7). This document does not invent that contract now; it states the shape a future one would take.
- **A new Reference Contract** (e.g., a future staleness-bound parameter, once the domain defines one — Domain Specification §17 item 5) is added the same way any other Reference Contract is: additively, disposably, never granting the ETM authority it does not already have.
- **A Conductor self-identification mechanism**, should one ever be introduced to address the misattribution risk named in §5.7, would extend the Conductor contract's own domain (what the Device carries as its currently-attributed Conductor) without touching the Device Identity contract's own authentication boundary (§7.1) — the platform's own architecture already separates "who the Device is" from "who it currently carries" (System Architecture §19), giving this future extension a boundary to attach to today, without this document needing to invent that boundary now.
- **A Ticket correction/void contract**, once the platform defines the mechanism (§6.1's own named open question), would be a new, additive Operational Contract instance referencing the original — never a mutation of the existing Ticket contract's own immutability guarantee (§6.1, §11). This document commits, ahead of that mechanism's definition, that whatever shape it takes will not require weakening Ticket's existing immutability contract.
- **A stronger reconciliation-visibility signal**, should the platform ever expose one, extends the Sync/Reconciliation Status Diagnostics contract (§8.3) by adding a new observable state above "Synced" — additive, because that contract is already structured to represent "the furthest state the ETM can observe" as an extensible concept, not a hardcoded two-state flag (System Architecture §19).

## 16. Platform Dependencies

This document depends on, and must never contradict:

- **ETM Product Specification** — the product-level scope and constraints (§13, §14, §15, §17, §21) that motivate several contracts' offline and versioning treatment throughout.
- **ETM Domain Specification** — the entity definitions, ownership model, lifecycle, and domain events this document's contracts are drawn from directly, especially §5 (Entities), §8 (Ownership Model), §9–§11 (Lifecycle, State Transitions, Domain Events), §14 (Source of Truth), and §17 (Open Domain Questions).
- **ETM Workflow Specification** — the exceptional-workflow business rules (§6, §7, §9, §11, §12, §15, §16, §17) this document's offline and failure-adjacent contract behaviors are built to be consistent with.
- **ETM System Architecture Specification** — the subsystem responsibilities and data-ownership table (§12, §14, §15, §17) this document's producer/consumer/owner assignments trace directly to.
- **ETM Technology Decisions** — acknowledged as the document governing implementation of these contracts; this document does not adopt or assume any technology named there.
- **ETM Reliability & Offline Synchronization Specification** — the durability, synchronization lifecycle, retry, and consistency models (§4–§14) this document's Operational Contract entries (§6) extend rather than restate.
- **Product Engineering Blueprint** — Part 11 (offline-first philosophy), Part 12 (multi-tenant model, informing Operator's contract treatment), Part 13 (security philosophy, informing §13 of this document), Part 19 (field conditions and small-team constraints, informing this document's versioning discipline).
- **Domain Model Specification** — the platform-wide entity definitions every contract in §5–§7 of this document narrows to ETM scope without redefining.
- **ADR-001, ADR-002** (MQTT/Protobuf transport, the direct source of §12's additive-evolution rules); **ADR-005** (QoS 1 and duplicate-delivery-as-routine, informing §11's idempotency treatment); **ADR-007** (fail-closed authorization, the direct model for §7.1's and §7.2's failure behavior); **ADR-008** (LocalBuffer-before-network ordering, underlying every Operational Contract's synchronization behavior in §6); **ADR-009** (Device vs. dashboard-user authentication, the direct model for §7.1's differentiated refresh/expiry treatment); **ADR-011** (unified reliability model for Ticket and Telemetry, the direct source of this document's parallel treatment of §6.1 and §6.2); **ADR-012** (structural operator isolation, informing §5.1's security treatment); **ADR-013** (no cache is ever a source of truth, and its deliberate departure for Operational Contracts pre-reconciliation, restated in Contract Principle 2).
- **API Specification** §5 (versioning strategy, the direct model for §12 of this document), §6–§7 (authentication/authorization model, the direct source of §7.1's and §7.2's treatment), §21 (offline synchronization has no REST role, informing §5.6's and §6's synchronization-behaviour distinctions), §26.1.5, §26.1.6, §26.3.1, §26.3.11 (the specific reference-read and identity endpoints this document's contract entries extend at the business level without restating).
- **MQTT Specification** §14 (deduplication, informing §6's consistency treatment), §21–§22 (payload serialization and schema evolution, the direct source of §12's versioning rules), §24 (dead-letter handling, informing §9's validation-responsibility split).
- **Database Specification** §9.4 (the dedup-ledger and permanent-constraint designs §6.1 and §6.2 reference without restating).
- **Sequence Diagrams** §11.1–§11.4 (offline synchronization recovery, duplicate handling, dead-letter handling, device revocation — the backend mechanics this document's contract behaviors are built to be consistent with).

## 17. Assumptions

Distinct from, and narrower than, the assumptions already named in the Product, Domain, Architecture, and Reliability Specifications — stated here only where they carry direct contract-level consequence:

- Every contract named in this document assumes the backend mechanism implementing it (a specific endpoint, topic, or schema) remains fixed for the duration of this document's own currency — this document does not anticipate or design around a backend-side redesign of a mechanism it treats as given.
- This document assumes the platform's own additive-evolution discipline (ADR-002, API Specification §5) continues to be honored on the platform side for the life of every contract named here; a platform-side breaking change made without the migration discipline §12 describes would invalidate this document's compatibility guarantees, not merely require an update to them.
- This document assumes no contract named here will be asked to carry a business meaning beyond what its own section (§5–§8) states, without a deliberate, explicit contract revision — a future feature that would repurpose an existing contract for a new business meaning is treated as requiring a new contract, not a silent reinterpretation of an existing one.
- This document assumes the ETM's own inability to be force-upgraded fleet-wide (Product Specification §14) remains true for the design horizon this document covers; a future shift to a centrally-managed, force-updatable fleet would materially relax §12's and §14's compatibility discipline, though this document does not anticipate that shift occurring.

## 18. Open Questions

Carried forward from upstream documents where they have direct contract-level consequence, plus questions this document itself surfaces:

1. **What staleness bound, if any, should apply to any Reference Contract before the ETM treats it as unreliable?** (§5.9, §5.4, §5.5, §5.6) — no upstream document defines one; this document can only state that staleness is knowable, not actionable against a threshold.
2. **How is Conductor misattribution on device handoff actually corrected, if at all, short of an Operator Admin action?** (§5.7) — genuinely unresolved by any reviewed specification; this document does not invent an answer.
3. **What mechanism, if any, will govern a future Ticket correction/void contract**, and will it require any revision to this document's existing Ticket immutability treatment (§6.1, §15)? — not yet defined upstream.
4. **Does the ETM ever need visibility into a Ticket or Telemetry Ping's actual platform-side reconciliation, distinct from mere transport acknowledgement**, and if the platform ever exposes this, what new contract (or extension to §6.1/§6.2) would represent it? (§6.1, §6.2, §15) — named as a live gap, not resolved here.
5. **What becomes of a revoked Device's undelivered Operational Contract backlog** — is it ever expected to reach the platform, or is it permanently unreachable once revocation occurs? (§7.1) — unresolved by any reviewed specification.
6. **Does Configuration Reference Data (§5.8) need its own resolution mechanism distinct from the named entity-level Reference Contracts**, or does it compose entirely within the existing Reference Contract pattern? — not resolved by any upstream document; this document names the class without inventing a mechanism for it.
7. **How a Device receives its initial credential and identity in the field** — whether this is an ETM-app responsibility or a separate provisioning tool — remains open (§7.1), inherited unresolved from the Product and Domain Specifications.

---

*End of NammaRoute Conductor ETM Data Contracts Specification v1.0.*
