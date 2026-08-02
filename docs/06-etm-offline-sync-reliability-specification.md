# NammaRoute Conductor ETM — Offline Synchronization and Reliability Specification
### `docs/etm-offline-sync-reliability-specification.md`

**Document type:** Offline Synchronization and Reliability Specification — the complete behavioral contract for how the ETM guarantees reliable operation under intermittent connectivity, long offline periods, application crashes, process termination, device reboot, and network recovery. It is not an implementation document, not a Flutter guide, and not a database specification.
**Position in the hierarchy:** Derives from, and must not contradict, the ETM Product Specification, ETM Domain Specification, ETM Workflow Specification, and ETM System Architecture Specification. Constrained by the Product Engineering Blueprint, the Architecture Review, the MQTT Specification, the API Specification, the Database Specification, the Sequence Diagrams, and the full ADR collection — especially ADR-001, ADR-002, ADR-005, ADR-007, ADR-008, ADR-009, ADR-011, and ADR-013. Feeds Engineering Guidelines, Feature Specifications, and Implementation Planning for every subsystem the ETM System Architecture Specification names in §12 — none of which may redefine a guarantee fixed here, only implement it.
**Status:** Living document, updated when a reliability guarantee itself changes — not when a technology, library, or implementation detail changes underneath it.

---

## 1. Purpose

This document answers one question, exhaustively: **what does the ETM guarantee about a captured Ticket or Telemetry Ping, under every failure condition the field will actually produce, and why can that guarantee be trusted?**

It is the single point where every upstream document's reliability-relevant statements are drawn together into one coherent, testable contract — the ETM System Architecture Specification's subsystem boundaries (§12 of that document), the ETM Domain Specification's lifecycle and source-of-truth model (§9, §14 of that document), the ETM Workflow Specification's exceptional-path business rules (§11, §12, §15, §16 of that document), and the backend's own reliability layering (Architecture Review §16; ADR-005, ADR-007, ADR-008, ADR-011, ADR-013). None of those documents is restated here in full; each is extended, at the one boundary this document owns: the precise behavioral guarantees governing capture, durability, synchronization, recovery, and consistency.

Where an upstream document leaves a question open, this document says so explicitly rather than inventing a resolution. Where the backend already answers a question for its own side of the same mechanism (LocalBuffer, QoS 1, dedup), this document extends that answer to the ETM rather than re-deriving or, worse, silently diverging from it.

## 2. Reliability Goals

Ranked in the order a failure review would actually need them, not alphabetically:

1. **No captured Ticket or Telemetry Ping is ever lost**, regardless of connectivity, process death, OEM background-execution interference, device reboot, or any combination of these occurring simultaneously (ADR-008, ADR-011; System Architecture §2, goal 1). This is the one guarantee every other goal below is subordinate to.
2. **No duplicate delivery ever produces a duplicate business outcome** — specifically, never a duplicate fare charge (ADR-005, MQTT Spec §14.2; Domain Specification §5.4). Duplicate *delivery* is expected and acceptable; duplicate *effect* is not, and the backend, not the ETM, is where this is actually prevented (§11 of this document).
3. **Ticketing and Telemetry never starve each other.** A high-frequency, lower-stakes-per-event responsibility and a lower-frequency, higher-stakes-per-event responsibility share one Device without either degrading the other's reliability (System Architecture §2, goal 2).
4. **The ETM is never falsely reassuring about what has and hasn't reached the backend.** Sync status, authorization status, and reference-context staleness are represented as far as the ETM can actually observe them, and no further (Product Specification §13; System Architecture §2, goal 3).
5. **Recovery is deterministic and automatic**, never dependent on a Conductor noticing a problem and taking corrective action (System Architecture §4, "Recoverability").
6. **A capture action is never blocked or delayed by network state, authorization state, or reference-context staleness** (Product Specification §13, Core Product Principle 2; Workflow Specification §18).

## 3. Offline Philosophy

Connectivity is the exception this entire specification is built around failure for, not the assumption normal operation depends on (Product Engineering Blueprint Part 11; Architecture Review §9). This is not a qualified or module-specific posture for the ETM — it is the baseline the ETM's reliability model is validated against, with connectivity treated as an optimization when present, never as a precondition for correctness.

Four governing principles, carried directly from the Blueprint's offline-first philosophy (Part 11) and restated at ETM scope:

- **Every edge action is locally durable before it is remotely durable.** A Ticket or Telemetry Ping is not "at risk of loss" the moment it is created — it is written to durable local storage first, synced when possible, never the reverse (ADR-008).
- **Sync is eventual, not blocking.** No Conductor-facing action is ever gated on a network round-trip succeeding (Product Specification §13; Workflow Specification §9, §10).
- **The system is honest about staleness.** A stale reference-context read is represented as stale, never as current; a sync status the ETM cannot verify is represented as unverified, never as confirmed (Product Specification §18; System Architecture §8, Principle 9).
- **Recovery is idempotent.** Whatever arrives late must never be double-counted merely because it arrived late instead of on time (ADR-005; MQTT Spec §14).

This philosophy applies with different intensity to different parts of the ETM's own domain: Ticket Capture and Telemetry Origination carry the full offline-write burden this document exists to govern; Reference Context Resolution is a read-side concern that degrades to staleness, never to data loss, under the same conditions (System Architecture §12.2).

## 4. Reliability Principles

These are the fixed points every subsequent section in this document derives from. None is independently invented here — each restates, at the ETM's own boundary, a principle the backend's ADRs or the ETM's upstream specifications already establish.

1. **Local durability strictly precedes any network attempt, with no exception for urgency.** This is, in ADR-008's own words, the single most load-bearing design fact in the entire platform, and it is never reversed on the ETM side for any reason — not perceived urgency, not a "small" payload, not a seemingly reliable connection at the moment of capture (ADR-008; System Architecture §12.5, §8 Principle 8).
2. **The ETM's own durable local store is the actual, temporary source of truth for a captured Ticket or Ping until the backend reconciles it — not a cache, not a convenience copy.** This is a deliberate, narrow departure from "no cache is ever a source of truth" (ADR-013), scoped precisely to this one class of data, for the reason ADR-013 itself states when generalizing the principle: until reconciliation, nothing else holds this fact at all (Domain Specification §8; System Architecture §8, Principle 2).
3. **Every other kind of local data the ETM holds is always disposable.** Reference Context (Trip, Fare Rule, Route Stop, Bus, Conductor pairing) is a cache in the fullest sense — refreshable, replaceable, never authoritative (Domain Specification §14; System Architecture §8, Principle 3). Conflating this with Principle 2's non-disposable class is named, upstream, as the single most likely architectural mistake this system could make, and this document treats that warning as binding.
4. **At-least-once delivery is the actual, practical guarantee; duplicate delivery is routine, expected behavior, never an error condition.** Every consumer of edge-event data — durable capture, synchronization, and (on the backend side) persistence — must be idempotent to duplicate delivery, because QoS 2's alternative guarantee does not hold across a session boundary and buys no additional correctness for the added protocol cost (ADR-005; MQTT Spec §14).
5. **A Ticket and a Telemetry Ping are the same reliability class, sharing one mechanism, differentiated only where the domain requires it.** Capture, durability, transport, retry, and recovery are identical for both; dedup permanence, Conductor-attribution preconditions, and correction handling differ because the domain — not the transport — says they should (ADR-011; Domain Specification §3, Principle 3; System Architecture §3).
6. **Fail-closed on authorization; fail-honest on everything else.** An unauthorized or revoked state is represented distinctly and is never silently retried as though it were a connectivity gap. Everywhere else — a network outage, a stale cache, an unresolved context — the ETM represents exactly what it knows and no more (ADR-007; System Architecture §8, Principle 9).
7. **Recovery is a function of durable state alone, never of in-memory state that happened to survive.** Every recovery path — from a killed process, a device reboot, or an ordinary reconnect — re-derives its work exclusively from what Durable Capture actually holds, never from an assumption about what was "in flight" (ADR-008; System Architecture §13, "the pattern worth naming explicitly").
8. **Synchronization pacing protects the shared broker infrastructure, not the ETM's own throughput.** Draining a backlog is throttled deliberately, out of respect for a fragile, just-recovered connection and a broker serving an entire fleet simultaneously — never bursted, regardless of how large the backlog has grown (MQTT Spec §12; System Architecture §18).

## 5. Capture Lifecycle

The complete responsibility-level lifecycle of a single Ticket or Telemetry Ping, from the moment it becomes a candidate fact to the furthest state the ETM can itself observe:

```
Fact occurs (fare sale completed / location-status reading taken)
   ↓
Domain validation (Ticket only — Trip, Conductor, Fare Rule, Route Stop preconditions;
                    Telemetry Ping has no equivalent precondition)
   ↓
Durable persistence — the record is written to durable local storage,
   completing BEFORE any network attempt is even considered
   ↓
Capture confirmed — this state is reachable and observable independent of
   network state, authorization state, or reference-context freshness
   ↓
Pending synchronization — the record awaits a connectivity- and
   session-readiness signal; no urgency shortcut exists past this gate
   ↓
Transport attempt — the record is published toward the backend at the
   platform's at-least-once delivery guarantee
   ↓
Transport acknowledgement — the backend's transport layer confirms receipt
   ↓
Synced (as far as the ETM can observe) — the record's local lifecycle
   state advances; the ETM's own obligation for this record is discharged
   ↓
Reconciled (backend-side only — not directly observable by the ETM)
```

**Responsibilities at each stage, stated without implementation detail:**

- **Domain validation** is a refusal gate, not a degraded-capture path. A Ticket missing a hard precondition (resolved Trip, Conductor, Fare Rule, boarding/destination Route Stop pair) is refused before it ever reaches durable persistence — it is never captured in a partial or malformed state (Domain Specification §5.4; System Architecture §12.3). A Telemetry Ping has no such precondition and proceeds to durable persistence on the strength of the Device's own identity alone (Domain Specification §5.5; System Architecture §12.4).
- **Durable persistence** is the system's single most load-bearing responsibility. It must complete — as an atomic, all-or-nothing operation — before any network attempt is made, with no exception for perceived urgency (ADR-008; System Architecture §12.5). A process killed before this stage completes must never have allowed a network attempt in its place; a process killed after this stage completes loses nothing.
- **Capture confirmed** is a Conductor-visible outcome (via Sync-Status & Reconciliation Honesty, §12.8 of the System Architecture Specification) that is available the instant durable persistence completes — independent of whether synchronization has even begun, let alone succeeded. The Conductor's confidence that "my sale was captured" must never wait on network state.
- **Pending synchronization → Transport attempt** is gated on genuine connectivity and session readiness (§7 of this document), never on urgency, record age, or record type priority.
- **Transport acknowledgement → Synced** is the furthest state the ETM can itself observe. The ETM's own obligation toward this record is discharged here — it has no visibility into, and no retry behavior triggered by, whatever happens to the record afterward on the backend side (Domain Specification §5.4, Note; MQTT Spec §12).
- **Reconciled** is named for completeness and is explicitly out of the ETM's observable range. No mechanism reviewed anywhere in this specification's dependency set gives the ETM visibility into this transition (Domain Specification §17, item 2). This document does not invent one.

This lifecycle applies identically, stage for stage, to both a Ticket and a Telemetry Ping (ADR-011). The only divergence is the domain-validation gate at the top, which Telemetry does not have.

## 6. Synchronization Lifecycle

The record-level states a captured Ticket or Telemetry Ping moves through once durably captured, as actually observable and supported by the platform:

| State | Meaning | Entered when | Exited when |
|---|---|---|---|
| **Pending** | Durably captured; not yet eligible for a transport attempt. | Durable persistence completes. | Connectivity and session readiness are both confirmed. |
| **Eligible** | Durably captured and eligible to be drained in the next batch; not yet actively being transmitted. | Both connectivity conditions (§7) are met. | Selected into an active drain batch, oldest-first, within its own event-type partition. |
| **Publishing** | Actively being transmitted as part of the current drain batch. | Selected for transmission. | A transport acknowledgement is received, or the attempt fails. |
| **Waiting Acknowledgement** | Transmitted; awaiting the backend transport's delivery confirmation. | Publish call issued. | Acknowledgement received, or the attempt is judged failed (a timeout or an explicit failure signal). |
| **Succeeded** | Transport acknowledgement received; the ETM's own obligation for this record is discharged. | Acknowledgement received. | Terminal for correctness purposes; the record may be retained locally for history at a future feature's discretion (System Architecture §14). |
| **Retry Pending** | A publish attempt within the current batch failed; the record awaits the next retry window per the backoff policy (§11 of this document). | Any publish failure within a batch. | The backoff delay elapses and a new attempt is made. |
| **Failed** | Reserved for a condition distinct from an ordinary transport failure — this state is not separately defined at this specification's level, because no reviewed upstream document names a terminal, un-retriable failure state for a record that has passed domain validation. A record that fails transport is always Retry Pending, never abandoned (§11, §12 of this document). | — | — |

**No record silently disappears from this lifecycle.** Every record durably captured is, at every moment, in exactly one of the states above, and the transition graph has no path that discards a record. This mirrors the backend's own dead-letter discipline (MQTT Spec §24; Sequence Diagrams §11.3) at the one point in the pipeline the ETM itself controls: capture and outbound transport. What happens to a record after the backend's own transport acknowledgement (validation failure, dead-lettering) is outside the ETM's observable range and is not a state this document defines for the ETM's own lifecycle, consistent with §5's Reconciled boundary.

**Expired and Archived, named in this document's own drafting brief, are deliberately not included as ETM-observable states.** No reviewed specification — Product, Domain, Workflow, Architecture, or any backend document — defines a time-based expiry for a pending Ticket or Telemetry Ping, nor an archival transition distinct from "Succeeded, retained for local history." Inventing either here would be exactly the kind of unsupported state this document's own governing instruction prohibits. This is named as an open question (§18).

**Independence between event types:** the Ticket partition and the Telemetry partition of this lifecycle operate independently of one another. Neither event type's backlog blocks, waits for, or is prioritized ahead of the other's, as a blanket rule — both drain on their own schedule, consistent with the backend's own non-prioritization (MQTT Spec §12; ADR-011).

## 7. Connectivity Model

The logical connectivity states the ETM's synchronization behavior is governed by, and the transitions between them:

| State | Meaning | Consequence for capture | Consequence for synchronization |
|---|---|---|---|
| **Offline** | Neither genuine network connectivity nor a confirmed transport session exists. | Fully unaffected — capture continues exactly as it would with connectivity present (§3, §5). | No transport attempts are made; the pending backlog accumulates. |
| **Recovering** | Network connectivity has returned, but a confirmed transport session has not yet been (re-)established. | Unaffected. | No transport attempts are made yet — both conditions must hold before draining begins (§7.1). |
| **Online** | Both genuine network connectivity and a confirmed transport session exist. | Unaffected. | Eligible for synchronization — the drain loop may begin or continue. |
| **Synchronizing** | Online, and actively draining a pending backlog (batches in flight, per §6, §11). | Unaffected. | Paced, throttled batches proceed per §11's retry/pacing model. |
| **Degraded** | Connectivity or session state is flapping — repeated, short-lived transitions between Online and Offline/Recovering within a short window. | Unaffected. | Synchronization proceeds opportunistically whenever a genuinely Online window appears, without a special-cased "degraded mode" distinct from ordinary retry/backoff handling (§11). |
| **Disconnected** | A previously Online or Synchronizing session has ended abnormally (process death, an unclean disconnect, a device reboot). | Unaffected for any record already durably captured before the disconnection. | Synchronization resumes exactly as it would after any other reconnect, re-deriving its work from Durable Capture's state alone (§9, §13). |

### 7.1 The two-condition gate

Synchronization is triggered only when **both** genuine network connectivity **and** a confirmed transport session are present — neither condition alone is sufficient (MQTT Spec §12). A Device may have cellular signal while its transport session is still negotiating or has failed independently; treating network presence alone as sufficient would risk exactly this failure mode. This two-condition gate is the authoritative definition of "Online" throughout this document and is never simplified to a single connectivity signal.

### 7.2 Behavior during transitions

- **Offline → Recovering → Online:** capture is unaffected throughout. Synchronization remains inactive until both conditions are simultaneously true, then begins draining per §11's paced batch model — never a burst of the accumulated backlog.
- **Online/Synchronizing → Offline (an ordinary disconnect):** any batch in flight halts; already-succeeded records remain Succeeded; records still in Publishing or Waiting Acknowledgement at the moment of disconnection return to a re-attemptable state on the next Online transition — never assumed delivered without an actual acknowledgement (§9).
- **Any state → Disconnected (an abnormal process/session end):** covered fully in §16. Recovery re-derives entirely from Durable Capture; no in-flight assumption survives this transition.
- **Degraded (flapping) connectivity:** no distinct backoff curve exists for this condition beyond the retry/backoff policy already governing ordinary failures (§11) — a rapid sequence of short Online windows is handled as a rapid sequence of ordinary attempt-then-retry cycles, not as a special case requiring its own state machine.

## 8. Durability Model

**The core guarantee, stated once and referenced throughout this document rather than re-derived per section:** a Ticket or Telemetry Ping is written to durable local storage as an atomic, all-or-nothing operation, and this write completes **before any network attempt is even considered** — never the reverse, for either event type, with no exception for urgency (ADR-008, applied to the ETM directly; System Architecture §12.5).

**What "durable" means at this document's level of abstraction:**

- The write either fully completes or is entirely absent — there is no partially-written, ambiguous state a record can be observed in. A process killed mid-write must never leave behind a record that is neither clearly captured nor clearly absent.
- Once the write completes, the record survives any subsequent event this document's failure scenarios (§14) describe — a process kill, a device reboot, a battery-optimization-induced suspension — without further action from any other subsystem.
- The write's durability does not depend on, and is not weakened by, the state of any other subsystem — Identity, Reference Context, or Synchronization being unhealthy, unavailable, or in an error state must never prevent or delay a durable capture write (System Architecture §12.5, "Dependencies: None").

**What is never treated as durable, and must never be substituted for the guarantee above:**

- **An in-memory publish queue.** Anything held only in process memory is lost the instant the process is killed, and is explicitly named, at the backend's own LocalBuffer level, as a secondary safety net only — never the actual source of truth (ADR-008; Domain Specification §5.4).
- **Transport session persistence.** A broker-side or client-library session persistence mechanism bridges brief reconnects; it is not designed, and must never be relied upon, to survive a multi-hour dead zone the way durable local storage is (ADR-008; MQTT Spec §16.2 — "LocalBuffer's own durability, not session continuity, is what guarantees no data loss across this boundary").
- **A "believed successful" write that was never confirmed.** A write is durable only once its completion is actually confirmed by the storage mechanism itself — an assumed-successful write that was never confirmed is treated as not durable at all.

**Scope of this guarantee:** it applies identically to a Ticket and a Telemetry Ping, with no reduced-durability path for either (ADR-011; System Architecture §2, goal 1). It does not apply to Reference Context data, Configuration & Session State, or Observability records, each of which is disposable by design (§14 of the System Architecture Specification, restated in §9 of this document below).

## 9. Consistency Model

Consistency in this system is defined by **who holds the single authoritative copy of a given fact at a given point in its lifecycle** — never by two subsystems independently agreeing to treat a fact the same way (System Architecture §15).

### 9.1 What is strongly consistent, and where

- **A captured-but-not-yet-reconciled Ticket or Telemetry Ping** has exactly one authoritative holder at any moment: the ETM's own durable local store, until the backend reconciles the fact, at which point authority transfers to the backend (Domain Specification §14; ADR-013's pattern, deliberately extended to this one class of data per System Architecture §8, Principle 2). There is no window in which two copies of this fact are simultaneously authoritative, and no window in which neither is.
- **The record's own lifecycle state** (Captured → Buffered → Synced, as locally observable) is owned exclusively by Durable Capture; no other subsystem maintains a competing notion of "has this been sent yet" (System Architecture §15).

### 9.2 What is eventually consistent, by design

- **Reference Context** (Trip, Fare Rule, Route Stop, Bus pairing, Conductor pairing) is never guaranteed current while the ETM is offline. Every read is a snapshot as of the last successful resolution, and the backend remains the sole authority regardless of how old the ETM's copy is (Domain Specification §14, §17.5; System Architecture §12.2). This is an accepted, permanent property of offline-first operation — not a defect to be resolved by faster polling.
- **A record's presence at the backend** is eventually consistent with its capture on-device: the delay between capture and backend arrival is bounded only by connectivity and the pacing model (§11), not by any deadline this document imposes.
- **The backend's reconciliation of a transport-acknowledged record** is entirely outside the ETM's observable window (§5, §6) and is, by construction, eventually consistent from the ETM's perspective in a sense the ETM cannot itself verify.

### 9.3 Temporary inconsistency the model explicitly accepts

- **A Ticket may be issued against a Trip, Fare Rule, or Route Stop snapshot the backend has already superseded**, if the supersession occurred while the ETM was disconnected. The Ticket's fare, once captured, is a permanent, immutable snapshot regardless of this — it is priced correctly against the version the ETM actually held, and is never retroactively repriced (Domain Specification §5.4, §5.6; Workflow Specification §13).
- **A Ticket may be attributed to a Conductor the Device no longer currently carries**, if a Conductor handoff occurred without an Operator Admin re-pairing action while the ETM was offline (Domain Specification §17, item 1; Workflow Specification §6, §17). This document does not resolve this — it is a named, open domain gap (§18).
- **A duplicate record may reach the backend more than once.** This is not an inconsistency this document treats as a defect — it is expected, routine behavior that the backend's dedup mechanism (§11 of this document; MQTT Spec §14) resolves to a single business outcome, never the ETM's own responsibility to prevent at the transport level.

### 9.4 What consistency this document does not, and cannot, promise

- **This document does not promise the ETM can always detect that its Reference Context is stale relative to a specific, known threshold.** No staleness bound is defined anywhere upstream (Domain Specification §17, item 5); this document's consistency model can only state that staleness is *knowable in principle* (an age can be tracked), not that a specific age is treated as unacceptable.
- **This document does not promise the ETM can distinguish "not yet reconciled" from "reconciled and then subsequently failed backend-side validation."** Both are invisible to the ETM in the same way; the ETM's consistency guarantee terminates at transport acknowledgement, not at reconciliation (§5, §6).

## 10. Recovery Model

Recovery, in this document, is any process by which the ETM resumes correct operation after an interruption — a connectivity loss, a process kill, a device reboot, or a background-execution suspension — without depending on anything other than durably captured state.

### 10.1 The unifying recovery principle

**Every recovery path re-derives its work exclusively from Durable Capture's own durable state.** No recovery path assumes a record was "in flight" unless that record is also, independently, durably persisted and observable as pending (ADR-008; System Architecture §13). This is true whether the interruption was a brief network flicker or a multi-day device outage — the recovery mechanism does not scale in kind with the severity of the interruption, only in the size of the backlog it must drain.

### 10.2 Recovery composition

A recovery event is the composition of exactly two facts, restated because conflating them is a realistic source of confusion:

1. **What durably survived the interruption** — this is entirely a durability question (§8), answered before recovery ever begins, and answered identically regardless of what caused the interruption.
2. **How the surviving backlog is drained once conditions allow** — this is entirely a synchronization/pacing question (§11), and is not different in kind for a connectivity-loss recovery, a process-kill recovery, or a reboot recovery. The trigger differs; the drain mechanism does not.

### 10.3 What recovery is not responsible for

- Recovery is not responsible for correctness of the underlying data — that is Durability's job (§8), already discharged before recovery begins.
- Recovery is not responsible for detecting or correcting a stale Reference Context snapshot beyond making one further resolution attempt as connectivity allows — a Reference Context refresh is a parallel, independent concern (§13.1), not a recovery-path responsibility for Ticket/Telemetry records specifically.
- Recovery is not responsible for prioritizing one event type's backlog over the other's — both partitions recover and drain independently (§6, §11).

## 11. Retry Model

### 11.1 Retry triggers

A retry attempt is triggered whenever a prior publish attempt for a given record fails — whether that failure was caused by a connectivity loss mid-attempt, a transport-level rejection, or the absence of a confirmed acknowledgement within the expected window. A retry is never triggered by record age, perceived urgency, or event type; the same trigger condition applies identically to Ticket and Telemetry records (ADR-011).

### 11.2 Two genuinely distinct backoff curves

Conflating these is a realistic source of confusion and this document deliberately separates them, mirroring the backend's own separation (MQTT Spec §15):

- **Connection-level backoff** governs how aggressively a new transport session (the more expensive operation) is re-established following an abnormal disconnect. This follows the backend's own defined curve: an initial delay near 1 second, doubling on each consecutive failed attempt, capped at a 5-minute maximum interval per attempt (MQTT Spec §15.1). The ETM does not define an independent curve for this — it adopts the backend's own contract, since the transport session is a shared resource whose reconnection behavior the backend already specifies for every client.
- **Publish-retry backoff** governs how aggressively an already-open session retries sending a batch that failed partway through. This follows the backend's own defined curve: a base delay of 2,000ms, doubling per consecutive failed batch, capped at a 120,000ms (2-minute) maximum, resetting to the 2-second base immediately after any fully successful batch (MQTT Spec §15.2). This cap is deliberately shorter than the connection-level cap, because it governs a cheaper operation on an already-open connection, and because recovering promptly matters more for keeping a growing backlog from accumulating unbounded during a long shift.

**Both curves apply identically to the Ticket partition and the Telemetry partition** — there is no separate, more aggressive retry curve for Tickets despite their revenue sensitivity. The fare-leakage-accountability concern this might otherwise raise is addressed by Ticket dedup's permanence (§11.4 below) and by whatever reconciliation-visibility the backend exposes, never by transport-layer prioritization (ADR-011; MQTT Spec §15.2).

### 11.3 Ordering during retry and recovery

Records are drained **oldest-first, within each event-type partition, independently** — never newest-first, and never interleaved across event types as a single combined queue. A batch (bounded, per §11.5) is pulled from the oldest unsynced records in a given partition; the two partitions (Ticket, Telemetry) drain on independent schedules with no blanket priority rule favoring either (MQTT Spec §12; System Architecture §12.6).

### 11.4 Priority

**Neither event type is prioritized over the other as a blanket rule.** This is a deliberate consequence of ADR-011's unified reliability model, not an oversight: Tickets are not fast-tracked ahead of Telemetry despite carrying direct revenue stakes, and Telemetry is not fast-tracked ahead of Tickets despite its higher frequency. Duplicate-delivery protection at the backend (a permanent constraint for Tickets, a time-windowed ledger for Telemetry — MQTT Spec §14.1, §14.2) is the mechanism that actually protects Ticket correctness, not transport-layer sequencing.

### 11.5 Batch size and pacing

Draining proceeds in small, bounded batches — never a burst of an entire accumulated backlog, regardless of how large that backlog has grown during an extended offline period. A deliberate pacing gap is enforced between successfully completed batches, even when the connection is healthy, as a throttle against overwhelming a shared, possibly fragile link — this is a designed behavior, not a defect, and exists specifically to protect the backend's own shared broker infrastructure from a fleet-wide reconnection surge, not to protect the ETM's own throughput (MQTT Spec §12; System Architecture §18).

### 11.6 On any single failure within a batch

The moment a single record within an in-progress batch fails to be delivered, the ETM stops attempting the remaining records in that batch immediately and enters the backoff path — it does not continue through the rest of the batch on the theory that only one record was affected, since the underlying condition causing one failure very likely affects the next record too (MQTT Spec §12; Sequence Diagrams §11.1).

### 11.7 Partial synchronization

A batch that partially succeeds before a failure is recorded precisely: records already acknowledged before the failure are Succeeded (§6); records not yet attempted, or attempted and failed, return to Retry Pending. No partial-batch outcome is treated as a full-batch success or a full-batch failure — the record-level state is always the true state, never rounded in either direction.

### 11.8 Interrupted synchronization, recovery after restart, recovery after reboot

An interruption to synchronization at any point — mid-batch, mid-backoff-delay, or between batches — is handled identically regardless of cause. On resumption (whether from an ordinary reconnect, a process restart, or a device reboot), the ETM does not assume any record was "in flight" unless that record is independently, durably marked as still-pending in Durable Capture. Recovery re-enters the same oldest-first, paced, per-partition drain loop exactly as it would after any other interruption — there is no distinct "recovery within a recovery" handling, and no escalated urgency applied merely because the interruption was severe (ADR-008; System Architecture §13; Sequence Diagrams §11.1, "Alternative and Failure Scenarios").

## 12. Failure Scenarios

Each scenario below states expected behavior, data protection, recovery, and business impact, at the behavioral level this document is scoped to.

### 12.1 No mobile signal

- **Expected behavior:** Capture continues fully. Synchronization does not attempt transport (§7 — the two-condition gate is unmet). The pending backlog accumulates.
- **Data protection:** Complete — every captured record is already durable before this condition has any bearing on it (§8).
- **Recovery:** Automatic, the moment the two-condition gate is next satisfied (§7.1, §11).
- **Business impact:** None to data integrity. Reference Context may age without refresh (§13); this is a named, accepted cost of offline-first operation (Domain Specification §13), not a failure of this scenario specifically.

### 12.2 Poor GPS

- **Expected behavior:** A Telemetry Ping reading is degraded in quality or delayed, but this is a sensor-read condition, not a capture-pipeline failure. A degraded-cadence condition is resumed at the next scheduled interval; it is never a reason to stop originating readings entirely (System Architecture §12.4).
- **Data protection:** Whatever reading is actually obtained is captured durably exactly as any other reading would be; there is no reduced-durability path for a lower-quality reading.
- **Recovery:** The next scheduled reading attempt, per the platform's adaptive cadence — no distinct recovery mechanism exists for this condition because it is not treated as a failure requiring one.
- **Business impact:** Minor, transient degradation of tracking accuracy for a given interval — never a data-loss or duplication concern.

### 12.3 MQTT unavailable (broker unreachable, or session cannot be established)

- **Expected behavior:** Identical to §12.1 from the ETM's perspective — the two-condition gate (§7.1) is unmet regardless of whether the cause is a network-layer or broker-session-layer failure, and the ETM does not need to distinguish the two causes to behave correctly.
- **Data protection:** Complete (§8).
- **Recovery:** Automatic on the next successful session establishment, per the connection-level backoff curve (§11.2).
- **Business impact:** None to data integrity; delivery is delayed, not lost.

### 12.4 REST unavailable

- **Expected behavior:** Reference Context Resolution's attempt-then-fall-back behavior applies — a failed read degrades to operating against the last-known cached value; it never blocks a capture action (System Architecture §12.2). Because offline synchronization has no REST role whatsoever (API Specification §21), REST unavailability has zero bearing on Ticket or Telemetry Ping durability or delivery.
- **Data protection:** Not applicable to Ticket/Telemetry durability — this pathway carries no durable-write obligation. A failed reference read costs nothing, since the ETM never held data this kind of read was responsible for delivering (System Architecture §12.2, Failure Boundaries).
- **Recovery:** The next reference-read attempt, on Reference Context Resolution's own independent cadence (§13.1).
- **Business impact:** Reference Context staleness may increase; a Ticket may be validated against progressively older cached data for as long as this condition lasts (Domain Specification §13).

### 12.5 Application crash

- **Expected behavior:** Any record whose durable write had already completed before the crash survives unaffected. Any record mid-capture at the moment of the crash is governed entirely by §8's atomicity guarantee — it either fully exists afterward or is entirely absent; there is no partial, ambiguous outcome.
- **Data protection:** Complete for every record whose durable write completed; by definition, no protection claim is made for a record whose write had not yet reached the durability boundary, because such a record does not yet exist as a captured fact.
- **Recovery:** On next process start, Durable Capture's existing state is read fresh; Synchronization resumes draining exactly as it would after any other interruption (§10, §16).
- **Business impact:** None to already-captured data. A Conductor whose crash occurred mid-action (e.g., mid-Ticket-entry, before the domain-validated record was handed to durable capture) must re-enter that action — this is a UI/workflow-layer concern outside this document's scope, not a durability failure.

### 12.6 Foreground service restart

- **Expected behavior:** Background Execution Management's restart, once it occurs, triggers Synchronization to resume draining Durable Capture exactly as it would after any other reconnect (System Architecture §12.7, §13). Telemetry Origination resumes at its next scheduled cadence interval.
- **Data protection:** Complete — this subsystem's own failure (a restart being needed at all) is explicitly not a data-loss event, because Durable Capture already guarantees that independently (System Architecture §12.7, Failure Boundaries).
- **Recovery:** Automatic, triggered by the restart itself.
- **Business impact:** A reduction in capture/sync *frequency* for the duration of the interruption — never a correctness impact. This is a deliberate, explicit non-overlap this document treats as fixed: Background Execution Management's failure degrades frequency, never correctness (System Architecture §16).

### 12.7 Battery optimization (OEM background-execution killing)

- **Expected behavior:** This is the platform's highest-ranked risk, with no code-only fix (Architecture Review §9). The ETM's entire durability design (§8) exists specifically so this risk's worst case — data loss — is architected out regardless of how often or how severely it occurs. Its lesser consequence — reduced capture/sync frequency on an aggressively-managed device — is real and is not eliminated, only bounded, by Background Execution Management's mitigation posture (System Architecture §12.7, §20).
- **Data protection:** Complete for the same reason as §12.5 and §12.6 — durability at capture time is entirely independent of whatever happens to the process afterward.
- **Recovery:** Whenever the process is next permitted to run (by the OS, or by a Conductor reopening the app), Synchronization resumes exactly as any other restart (§16).
- **Business impact:** Reduced Telemetry cadence and delayed Ticket transmission during the affected period, bounded in severity but not eliminated by mitigation; a named, accepted architectural risk (System Architecture §20), not a defect this document claims to fully solve.

### 12.8 Authentication expiration / Device credential failure

- **Expected behavior:** The Device's own authorization state, once recognized as denied or unverifiable, is propagated as a distinct state — never merged with, or treated identically to, a connectivity gap (Workflow Specification §16; System Architecture §12.1, §17). Synchronization and Reference Context Resolution both stop attempting new outbound activity on recognizing this state; already-durable local data is neither deleted nor exposed elsewhere.
- **Data protection:** Complete for already-captured records — a revoked or unauthenticated Device's un-transmitted backlog remains on the Device, safely durable, but unreachable to the platform until authorization is restored (Workflow Specification §15, "Expected Outcome"; System Architecture §17).
- **Recovery:** Not automatic in the way a connectivity gap is — resolving an authentication failure requires the underlying cause to be addressed (most commonly, an Operator Admin action), not merely the passage of time or a network state change (Workflow Specification §16).
- **Business impact:** The Device cannot originate new Tickets or Telemetry, or resolve any context, until resolved. The backlog accumulated before the denial is preserved but stalled — this document does not resolve what becomes of that backlog if the Device is never restored (§18; Domain Specification §17, item 7 equivalent).

### 12.9 Device revocation

- **Expected behavior:** Identical in kind to §12.8 — revocation is a specific, named cause of the same authorization-denial state, and the ETM's behavior does not, and structurally cannot, distinguish "revoked" from any other cause of authentication failure at its own boundary (Workflow Specification §15, §16; System Architecture §12.1). A Device already mid-session at the moment of revocation may retain its existing session's ability to transmit until that session's next re-establishment — a named, bounded exception to "instant," not a contradiction of it (Workflow Specification §15; MQTT Spec §19.2; Sequence Diagrams §11.4).
- **Data protection:** Complete for already-durable records, exactly as §12.8.
- **Recovery:** Only via restoration of the Device's operable status — an action entirely outside the ETM's own control (Workflow Specification §15).
- **Business impact:** Identical to §12.8, with the added, explicitly named consequence that the fate of a revoked Device's un-transmitted backlog is an open question this specification does not resolve (§18; Workflow Specification §15, Open Questions).

### 12.10 Reference data becoming stale

- **Expected behavior:** The ETM continues operating against its last-known Trip, Fare Rule, Route Stop, or Conductor-pairing snapshot for as long as a connectivity gap or a resolution failure lasts. No staleness bound is defined anywhere upstream at which the ETM should refuse to issue a Ticket or warn the Conductor (Domain Specification §17, item 5; Workflow Specification §7, §11, §19).
- **Data protection:** Not applicable in the durability sense — Reference Context carries no durable-write obligation and is never at risk of loss, only of being outdated (System Architecture §14).
- **Recovery:** The next successful reference-read attempt, on Reference Context Resolution's own independent cadence (§13.1), replaces the stale snapshot in full.
- **Business impact:** A Ticket may be issued against a Trip, Fare Rule, or Route Stop set the backend has since superseded, cancelled, or reordered. This is a named, accepted risk of offline-first operation (Domain Specification §13), not a defect — but it is a real one, with genuine business weight if a Trip is reassigned or a Fare Rule superseded while the ETM is disconnected.

### 12.11 Storage exhaustion

- **Expected behavior:** No reviewed upstream document defines what the ETM should do if local durable storage approaches or reaches capacity during an extended offline period. Durable Capture's storage footprint is expected to grow under a worst-case dead zone, and its retention/pruning behavior is explicitly deferred to a future Technology Decision (System Architecture §18, §23 item 3; ETM Technology Decisions §13, item 1) — this specification does not invent a resolution.
- **Data protection:** Cannot be characterized definitively at this document's level, because the underlying policy is undefined. This document flags storage exhaustion as a reliability risk (§14) rather than asserting a guarantee it cannot support.
- **Recovery:** Undefined at this level, for the reason above.
- **Business impact:** Undefined at this level; named explicitly as an open question (§18).

### 12.12 Clock drift

- **Expected behavior:** `client_timestamp`, device-supplied at capture time, is the deterministic key the backend's own dedup mechanisms depend on (MQTT Spec §13, §14.1, §14.2). This document does not define a clock-synchronization mechanism (that is implementation scope), but states the behavioral consequence: the ETM's own ordering and dedup correctness depends on `client_timestamp` being stable and monotonic for a given Device across capture events, not on the Device's clock being accurate relative to true time. The backend orders reads by its own server-received time for Telemetry and by insertion order for Tickets, never by `client_timestamp` as a sequencing dependency across distinct records (MQTT Spec §13).
- **Data protection:** Unaffected — durability does not depend on clock accuracy.
- **Recovery:** Not applicable — this is not a failure the ETM detects or recovers from at this document's level; it is a boundary condition the backend's ordering design already tolerates.
- **Business impact:** None to durability or delivery. A materially drifted clock could, in principle, affect a Ticket's fare-rule-version selection if fare rules are time-bound and the ETM's notion of "now" is wrong — this is named as a risk (§14) rather than resolved, since no upstream document defines a clock-drift tolerance bound.

### 12.13 Duplicate publication

- **Expected behavior:** Fully expected, routine behavior, never an error condition, for either event type — every retried publish, every reconnect within a session's replay window, and every restart mid-drain is a plausible, accepted source of a duplicate (ADR-005; MQTT Spec §14). The ETM makes no attempt to suppress or detect duplicates locally beyond the ordinary retry/state-tracking behavior already described (§6, §11) — deduplication is a backend, persistence-layer responsibility (§11 of this document; MQTT Spec §14.1, §14.2), not an ETM-side one.
- **Data protection:** Not at risk — a duplicate is, by definition, a record that was already durably captured and already (at least once) successfully transmitted.
- **Recovery:** Not applicable — there is nothing to recover from; a duplicate is absorbed transparently at the backend and is invisible to the originating Device (Sequence Diagrams §11.2).
- **Business impact:** None, by design. A duplicate Telemetry Ping is absorbed via a time-windowed ledger; a duplicate Ticket is absorbed via a permanent uniqueness constraint, reflecting the materially higher stakes of a duplicate fare charge versus a duplicate location reading (MQTT Spec §14.1, §14.2).

### 12.14 Out-of-order delivery

- **Expected behavior:** Not treated as a failure condition requiring ETM-side correction. The backend orders reads by server-received time (Telemetry) or insertion order (Tickets) — never by wire-arrival order — and every record carries its own `client_timestamp` precisely so that reconnect-induced reordering is a non-event rather than a defect to defend against (MQTT Spec §13). A Ticket's business meaning is fully self-contained in its own payload and does not depend on arrival order relative to any other Ticket.
- **Data protection:** Unaffected.
- **Recovery:** Not applicable — no recovery action is needed for a condition the system's ordering design already tolerates by construction.
- **Business impact:** None.

### 12.15 Unexpected shutdown (device powered off, battery depleted, forced stop)

- **Expected behavior:** Governed entirely by §8's durability guarantee — any record durably captured before the shutdown is unaffected; no record can be left in a partially-written, ambiguous state, by construction.
- **Data protection:** Complete for every durably captured record, identical in reasoning to §12.5.
- **Recovery:** On next power-on and app start, exactly as §16 describes for device reboot.
- **Business impact:** None to already-durable data. Telemetry cadence and Ticket transmission simply pause for the duration of the shutdown.

## 13. Ordering Guarantees

- **Within a single event-type partition, records are drained oldest-first.** This is a synchronization-pacing guarantee (§11.3), not a claim about wire-level delivery order, which the transport does not guarantee across a reconnect boundary (MQTT Spec §13).
- **No ordering guarantee exists, or is needed, between the Ticket partition and the Telemetry partition.** They are independent streams; interleaving between them carries no business meaning (System Architecture §12.6).
- **A record's business meaning never depends on its arrival order relative to any other record.** Each Ticket and each Telemetry Ping is fully self-contained, carrying its own `client_timestamp` as the fact the backend actually orders and deduplicates against — never the sequence in which messages happened to arrive at the subscriber (MQTT Spec §13). This document treats the backend's own ordering-key design as authoritative and does not propose an ETM-side alternative.
- **Reconnection may reorder delivery relative to capture order, and this is explicitly a non-event, not a bug to defend against** — a deliberate design choice inherited directly from the backend (MQTT Spec §13).

### 13.1 Reference Context refresh cadence

Reference Context Resolution operates on its own independent cadence, distinct from and unblocked by the Ticket/Telemetry synchronization backlog (System Architecture §13, "Reconnection/Recovery"). A refresh attempt reduces staleness opportunistically whenever connectivity allows; it is never gated on, or gating of, the durable-capture drain loop.

## 14. Duplicate Prevention

**The ETM does not implement duplicate prevention as its own mechanism.** This is stated plainly because it is easy to assume otherwise: deduplication is a backend, persistence-layer responsibility, not a client-side one (ADR-005; MQTT Spec §14; System Architecture §12.6, Failure Boundaries — "This subsystem owns no business-validation logic"). The ETM's actual contribution to duplicate-safety is narrower and specific:

- **Every record carries a stable, device-supplied `client_timestamp`, set once at capture time and never altered on retry.** This is the fact the backend's dedup mechanisms key against, and the ETM's obligation is to ensure this value is set correctly once and reused identically across every retry of the same underlying record — never regenerated per attempt, which would defeat the backend's dedup key entirely.
- **The ETM does not attempt to suppress a retry because it "might" be a duplicate.** Retrying a record whose delivery outcome is unconfirmed is always the correct behavior — under-delivering (skipping a retry out of caution) would risk data loss, the one outcome this entire specification is built to prevent, whereas over-delivering (a duplicate) is safely absorbed downstream (ADR-005).
- **Telemetry Ping duplicates are absorbed via a time-windowed ledger (48-hour retention); Ticket duplicates are absorbed via a permanent uniqueness constraint** — this asymmetry exists entirely on the backend side, reflecting the different cost of a rare missed dedup for each payload type, and this document does not propose narrowing or widening that asymmetry from the ETM side (MQTT Spec §14.1, §14.2).

## 15. Conflict Handling

- **A Ticket, once captured, is never edited.** Any correction to an already-issued Ticket is a new record referencing the original — never a mutation of the original record (Domain Specification §3, Principle 5; §5.4). This means no conflict-resolution mechanism is needed for a Ticket's own fields, because the record is immutable from the moment of capture.
- **No correction/void mechanism is actually defined anywhere in the reviewed specification set** — the Domain Model names the intended shape ("a new event referencing the original"), but no actor, trigger, endpoint, or workflow exists yet to perform one (Domain Specification §17, item 3; Workflow Specification §9, Open Questions). This document does not invent one; conflict handling for a correction/void scenario is out of scope until that gap is closed upstream.
- **A stale Reference Context read is never a source of a "conflict" in the data-merge sense** — there is nothing to merge. The ETM's cached snapshot is simply superseded, in full, by the next successful resolution; there is no partial reconciliation between an old and new snapshot (Domain Specification §14).
- **Two records with the same `client_timestamp` for the same Device are not a conflict the ETM resolves** — they are, definitionally, the same underlying capture event delivered more than once, and dedup (§14) is how the backend resolves that, not a merge operation of any kind.

## 16. Crash Recovery, Process Restart, and Device Reboot Recovery

These three triggers are treated together because their recovery behavior is identical in kind, differing only in what triggers the recovery, not in how it proceeds:

- **Application crash** (an unhandled exception or OS-forced kill while the app is in the foreground or background) — recovery is triggered on next process start.
- **Process restart** (the OS restarts a previously-killed background/foreground service) — recovery is triggered by the restart event itself, detected by Background Execution Management (System Architecture §12.7).
- **Device reboot** (the entire device powers off and on again, taking every app process down with it) — recovery is triggered on the app's next launch, whether by the OS restarting a persisted service or by the Conductor manually reopening the app.

**In every case, the recovery sequence is the same:**

1. Durable Capture's existing state is read fresh — never assumed from any in-memory value that happened to survive, because nothing in memory is trusted to have survived (§8, §10.1).
2. Any record found in a pending state (Pending, Eligible, or a record that was mid-Publishing/Waiting-Acknowledgement at the moment of the interruption, per §6) is treated as eligible for the next drain attempt, exactly as it would be after an ordinary reconnect — there is no distinct "post-crash" or "post-reboot" recovery mode.
3. Synchronization resumes its ordinary paced, oldest-first, per-partition drain loop (§11) the moment the two-condition connectivity gate (§7.1) is satisfied.
4. Reference Context Resolution independently re-attempts resolution on its own cadence, to reduce whatever staleness accumulated during the interruption (§13.1) — this proceeds in parallel with, and independently of, the Ticket/Telemetry drain.
5. Telemetry Origination resumes producing readings at its next scheduled cadence interval, with no special "catch-up" reading generated for the gap itself — a gap in readings is a degraded-cadence condition, not an error to compensate for (System Architecture §12.4).

**What recovery explicitly does not need to know:** which of the three triggers above caused the interruption. The recovery sequence does not branch on cause, because Durable Capture's guarantee (§8) already makes the cause irrelevant to what data survived.

## 17. Long Offline Operation

A dead zone lasting minutes to multiple hours — or, per the Product Specification's own operational framing, potentially longer — is the designed-for normal condition, not an edge case (Product Specification §14; Workflow Specification §11).

- **Capture is entirely unaffected by duration.** A Ticket or Telemetry Ping captured on hour one of a dead zone is exactly as durable, and exactly as valid a business record, as one captured on hour six (Domain Specification §13).
- **The pending backlog accumulates without a defined ceiling at this specification's level.** Durable Capture's storage growth under a worst-case, multi-day dead zone is bounded only by device storage itself today — no retention or pruning policy is fixed at the architectural level, and this document does not invent one (System Architecture §18, §23 item 3). This is named as a reliability risk (§14 of this document).
- **Recovery pacing does not scale up in aggressiveness merely because the backlog is large.** The same bounded-batch, paced-gap, oldest-first drain (§11.5) applies regardless of backlog size — specifically because a Device emerging from a long dead zone is emerging onto a weak, just-recovered connection least able to tolerate a burst, which is exactly the moment a larger backlog might otherwise tempt a more aggressive drain strategy (MQTT Spec §12).
- **Reference Context staleness compounds with duration, and this document does not define a point at which it becomes unacceptable.** The longer the offline period, the more likely a Trip reassignment, Fare Rule supersession, or Conductor re-pairing has occurred without the ETM's knowledge (Domain Specification §13). This is a named, accepted cost, not a resolved problem — see §18.
- **The true field connectivity profile this system will actually encounter is an estimate, not a measurement, at the time of this document's writing** (Product Specification §17, §21) — this document's guarantees are designed to hold regardless of how long an actual dead zone in the field turns out to be, precisely because no specific duration bound is assumed anywhere in the durability model (§8).

## 18. Consistency Guarantees

Restated concisely, as a single reference point distinct from the fuller discussion in §9:

- **Strong consistency (single authoritative holder, no window of ambiguity):** an unsynced Ticket or Telemetry Ping, held exclusively by the ETM's own durable store until backend reconciliation transfers authority (§9.1).
- **Eventual consistency (by design, not by defect):** Reference Context relative to the backend's current state; a record's presence at the backend relative to its capture time; the backend's reconciliation state relative to its transport-acknowledged state (§9.2).
- **Accepted temporary inconsistency:** a Ticket may reflect superseded Trip/Fare Rule/Route Stop context, or a stale Conductor pairing, for the duration of an offline period — named explicitly rather than hidden (§9.3).
- **Not promised:** a specific staleness bound at which cached Reference Context becomes unacceptable; visibility into backend-side reconciliation or post-acknowledgement validation failure (§9.4).

## 19. Data Integrity

- **A Ticket's fare, once captured, is immutable for the life of that record.** No later change to the underlying Fare Rule, and no later correction, ever alters the originally-captured amount — a correction is always a new, distinct record (Domain Specification §3, Principle 5; §7).
- **A record is never observable in a partially-written state.** The durability guarantee (§8) is atomic by definition — a crash mid-write results in either the complete record or no record at all, never a corrupted or half-populated one.
- **A `client_timestamp` is set once, at capture time, and is never regenerated on retry.** This is the integrity property the backend's entire dedup mechanism depends on (§14), and its violation would silently defeat deduplication without producing any visible symptom until a fare-leakage or data-quality investigation eventually surfaced it.
- **A Ticket cannot exist in durable storage without its hard preconditions already satisfied** (resolved Trip, Conductor, Fare Rule, boarding/destination Route Stop pair) — these are enforced at the domain-validation gate (§5), before durable persistence, never as a later correction step (Domain Specification §12).

## 20. Recovery Model — Cross-Reference

(Already covered fully in §10 and §16; this heading is retained to satisfy the document's own required-topics list and to make explicit that no additional recovery behavior exists beyond what §10 and §16 already state. There is no separate "recovery model" distinct from the durability-plus-drain composition already described.)

## 21. Security Considerations

- **The Device credential is the ETM's only security principal, and this document's reliability guarantees never weaken that boundary.** No retry, recovery, or backlog-drain behavior described in this document ever attempts delivery using anything other than the Device's own authenticated identity — there is no fallback credential, no anonymous retry path, and no bypass of authorization state under any failure condition (System Architecture §12.1, §17).
- **Fail-closed is never relaxed by a reliability concern.** A recognized authorization denial (revocation, an unverifiable status) always takes precedence over "keep retrying to avoid data loss" — Synchronization and Reference Context Resolution both stop attempting new outbound activity the moment such a state is recognized, and do not resume merely because a retry might otherwise have succeeded (ADR-007; System Architecture §12.1, §17; §12.8–§12.9 of this document). Data already durably captured remains safely on-device, neither deleted nor exposed, for the duration of the denial (Workflow Specification §15).
- **A durable local backlog surviving a lost or stolen Device is a named, accepted consequence, not a gap this document proposes closing.** The reliability guarantees in this document (durability, retry, recovery) apply regardless of whether the Device itself is later lost — they say nothing about, and are not a substitute for, whatever secure-storage or credential-protection mechanism governs the Device at rest, which is a Technology Decision concern (ETM Technology Decisions §5.7), not a reliability-model concern.
- **No retry or recovery behavior described here ever attempts to work around an authentication failure by falling back to a weaker or alternate verification path.** The ETM has no local logic that decides it is authorized — that determination is exclusively the backend's, and this document's retry model never substitutes its own judgment for that determination (System Architecture §17).

## 22. Reliability Risks

Risks named explicitly, because a reliability specification that hides its own limitations is dishonest in exactly the way this document's own governing principles (§3, §4 Principle 6) prohibit:

1. **OEM background-execution killing remains a partial, device-dependent mitigation, not an eliminated risk.** This document's durability guarantee (§8) architects out the worst case (data loss) regardless, but the lesser consequence — reduced capture/sync frequency — is real, not eliminated, and is bounded rather than solved (System Architecture §20; §12.7 of this document).
2. **Unbounded local storage growth under a worst-case, multi-day dead zone is not resolved at this specification's level.** No retention or pruning policy exists yet; this is deferred to a future Technology Decision, and until it is resolved, a sufficiently long field outage is a genuine, if currently unmeasured, storage-capacity risk (System Architecture §18, §23 item 3; §12.11 of this document).
3. **Reference Context staleness has no defined bound**, meaning a Ticket can, in principle, be issued against arbitrarily old cached context for as long as an offline period lasts, with no mechanism in this document (or any upstream document) to flag when that staleness has become business-unacceptable (Domain Specification §17, item 5; §9.4, §17 of this document).
4. **The fate of a revoked or otherwise-permanently-unauthorized Device's undelivered backlog is genuinely undefined.** This document cannot state whether such a backlog is ever expected to reach the platform, because no upstream specification resolves this (Workflow Specification §15, Open Questions; §12.8–§12.9 of this document).
5. **The true field connectivity profile this system will encounter is an estimate, not a measurement**, meaning every duration-sensitive design decision in this document (batch sizing, backoff caps) is validated against an assumed profile, not a proven one, until real pilot data confirms or contradicts it (Product Specification §17, §21; §17 of this document).
6. **A shared reliability mechanism (Durable Capture, Synchronization) concentrates significant blast radius in one place.** A defect in the shared core affects both Ticketing and Telemetry simultaneously, a deliberate trade-off (shared guarantee vs. independent-failure isolation) this document accepts for the same reason ADR-011 accepts the equivalent trade-off at the backend (System Architecture §20).
7. **Clock drift's effect on time-bound Fare Rule selection is not resolved.** This document names the risk (§12.12) without a defined tolerance bound, because no upstream document sets one.

## 23. Assumptions

Distinct from, and narrower than, the assumptions already named in the Product, Domain, and Architecture Specifications — stated here only where they carry direct reliability consequence:

- The device's durable local storage mechanism (whatever a future Technology Decision selects) genuinely supports the atomic, all-or-nothing transactional guarantee §8 depends on. This document assumes such a mechanism is available on the operator-provisioned hardware class named in the Product Specification, without naming the specific technology (System Architecture §21).
- The Android platform provides some mechanism (a foreground service or equivalent) sufficient to sustain background execution across most, though not all, OEM battery-management configurations. This document's recovery model assumes this capability exists in some form, not that it is absent (System Architecture §21).
- A Device will typically, though not reliably, have some connectivity near the start of a shift — this document's recovery and reference-resolution behavior tolerates this being false (operating with no cached context at all) but is not optimized primarily for that scenario (Product Specification §16; System Architecture §21).
- Exactly one Conductor's attention is directed at the ETM at a time — this document does not consider concurrent multi-Conductor use of a single Device (Domain Specification §5.2; System Architecture §21).
- A device handoff between Conductors mid-shift is a real, expected occurrence, and this document accepts the resulting misattribution risk (§9.3) as a named, unresolved consequence rather than a scenario this reliability model is responsible for correcting (Product Specification §16).

## 24. Platform Dependencies

This document depends on, and must never contradict:

- **ETM Product Specification** — the product-level scope, objectives, and risk framing this document's reliability goals (§2) directly serve (§9–§18 of that document).
- **ETM Domain Specification** — the entity lifecycle, source-of-truth model, and offline domain behavior this document's durability, consistency, and recovery models extend without redefining (§5, §8, §9, §13, §14, §17 of that document).
- **ETM Workflow Specification** — the exceptional-workflow business rules (Offline Operations §11, Connectivity Recovery §12, Device Revocation §15, Authentication Failure §16) this document's failure scenarios (§12 of this document) are built to honor precisely, not reinterpret.
- **ETM System Architecture Specification** — the subsystem boundaries, responsibilities, and failure-isolation model (§12, §14, §15, §16 of that document) this entire document is the behavioral contract for; no guarantee in this document may exceed what that document's subsystems are actually architected to provide.
- **ETM Technology Decisions** — acknowledged as the document that will implement the guarantees stated here; this document does not adopt or assume any specific technology named there, and any apparent alignment (e.g., the storage-durability assumption in §23) is stated at the behavioral level only.
- **Product Engineering Blueprint** — Part 7 (layered failure tolerance), Part 11 (offline-first philosophy, the direct source of §3's governing principles), Part 19 (field conditions as baseline).
- **Architecture Review** — §9 (offline-first architecture, the OEM background-execution risk framing §12.7 of this document inherits directly), §16 (the layered reliability philosophy this document's §4 restates at ETM scope).
- **ADR-001, ADR-002** (MQTT/Protobuf transport this document's synchronization model is built on top of, without restating topic or schema detail); **ADR-005** (QoS 1 and the routine-duplicate-delivery principle underlying §11, §14); **ADR-007** (fail-closed authorization, the direct model for §21's security posture); **ADR-008** (LocalBuffer-before-network ordering, the direct source of §4 Principle 1 and §8's entire durability model); **ADR-009** (Device authentication, informing §21); **ADR-011** (unified reliability model for Ticket and Telemetry, the direct source of §4 Principle 5 and the reason this document treats both event types identically throughout); **ADR-013** (no cache is ever a source of truth, and its deliberate, narrow departure for Durable Capture, restated in §4 Principle 2).
- **MQTT Specification** §12–§17 (trickle-sync mechanics, ordering, dedup, retry/backoff, connection lifecycle — the precise parameters §6, §11, §13, §14 of this document extend to the ETM's own behavioral contract).
- **API Specification** §21 (offline synchronization has no REST role — the direct basis for this document treating REST failures, §12.4, as having zero bearing on Ticket/Telemetry durability).
- **Database Specification** §9.4 (the dedup-ledger and permanent-constraint designs §11, §14 of this document reference without restating).
- **Sequence Diagrams** §11.1–§11.4 (offline synchronization recovery, duplicate handling, dead-letter handling, device revocation — the backend mechanics this document's failure scenarios, §12, are built to be consistent with).

## 25. Open Questions

Carried forward from upstream documents where they have direct reliability consequence, plus questions this document itself surfaces:

1. **What is the correct local-storage retention/pruning policy for synced-but-historically-retained records, and at what point (if any) does unbounded backlog growth under a worst-case dead zone become an actual operational problem rather than a theoretical one?** (§12.11, §17, §22 item 2) — deferred to a future Technology Decision; this document fixes only that synced data is disposable for correctness purposes, not when or whether it is actually pruned.
2. **What becomes of a revoked or permanently-unauthorized Device's undelivered backlog?** (§12.8, §12.9, §22 item 4) — genuinely unresolved by any reviewed specification; this document does not invent an answer.
3. **What staleness bound, if any, should apply to cached Reference Context before the ETM treats it as unreliable for Ticket issuance?** (§9.4, §12.10, §17, §22 item 3) — no upstream document defines one; this document can only make staleness knowable, not actionable against a threshold.
4. **What is the actual, measured field connectivity profile this system will encounter**, and does it validate or contradict the batch-size, backoff, and pacing parameters this document adopts from the backend's own specification? (§17, §22 item 5) — not yet measured at the time of this document's writing.
5. **Does Expired or Archived deserve to be a first-class ETM-observable synchronization state**, or does "Succeeded, retained for local history" already cover every case a future feature would need? (§6) — not resolved here, since no upstream document names either state; flagged rather than invented.
6. **How should a future ETM feature (or this document's own next revision) represent a clock-drift condition materially affecting time-bound Fare Rule selection**, if the field ever demonstrates this is a real, not theoretical, occurrence? (§12.12, §22 item 7) — no tolerance bound is defined anywhere upstream.
7. **Does the eventual introduction of a third edge-generated event type (explicitly anticipated by ADR-001, ADR-002, and ADR-008) require any change to this document's reliability model**, or does it compose entirely within the existing capture/durability/synchronization contract already described here, exactly as Ticketing composed within the mechanism originally proven for Telemetry? (System Architecture §19) — provisionally assessed as the latter, consistent with ADR-011's own generalization, but not conclusively exercised until such an event type is actually specified.

---

*End of NammaRoute Conductor ETM Offline Synchronization and Reliability Specification v1.0.*
