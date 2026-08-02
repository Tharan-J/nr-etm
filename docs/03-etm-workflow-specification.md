# NammaRoute Conductor ETM — Workflow Specification
### `docs/etm-workflow-specification.md`

**Document type:** Workflow Specification — describes how the ETM operates during real-world business operations, from the perspective of the Conductor, the Operator, and the platform. It is not a UI flow, not an application navigation flow, not an API sequence, and not an implementation document.
**Position in the hierarchy:** Derives from the ETM Product Specification and the ETM Domain Specification; constrained by the Product Engineering Blueprint, the Domain Model Specification, the Architecture Review, and the Sequence Diagrams / API Specification / MQTT Specification as backend ground truth. Feeds every future ETM Feature Specification and UI Specification — neither of which redefines a workflow's business shape, only its screens and interactions.
**Status:** Living document, updated when a business workflow itself changes — a new operational step, a new actor responsibility, a new exception path — not when an endpoint, topic, or screen changes underneath it.

---

## 1. Purpose

This document describes *how the ETM operates*, as a sequence of real-world business operations a Conductor, an Operator Admin, and the platform jointly carry out — not how a screen is navigated or which API call fires when. It exists so that a future Feature Specification or UI Specification has a single, authoritative operational reference to derive screens, interactions, and edge-case handling from, rather than each independently re-deriving "what actually happens" from the backend sequence diagrams.

Every workflow below is grounded in the ETM Domain Specification's entities, ownership, and lifecycle, and in the backend's actual, frozen behavior (API Specification, MQTT Specification, Sequence Diagrams). Where the backend leaves a workflow's business shape genuinely undefined, this document says so explicitly (each workflow's own **Open Questions**) rather than inventing a resolution a future document would then be built against incorrectly.

## 2. Scope

**In scope:** the operational shape of each workflow — its actors, what triggers it, the business steps that must occur in what order, the rules that govern it, its normal and exceptional paths, and what a successful (or failed) outcome means in business terms.

**Out of scope, deliberately:** REST endpoints and payloads, MQTT topics and message framing, database rows and status columns, Flutter screens, navigation, and any Android/backend implementation detail. Where a workflow's business step is *implemented* by a specific backend mechanism (e.g., "the backend resolves Trip and Fare Rule context"), this document names that the mechanism exists and where it's defined, without describing the mechanism itself.

## 3. How This Document Was Built

Before writing, each workflow below was checked against three things: (1) how a Conductor actually performs the work in the field, per the ETM Product Specification's personas and operational environment; (2) what the backend actually supports, per the Sequence Diagrams, API Specification, and MQTT Specification — a workflow is not described here as if a capability exists when the backend specifications show it doesn't; (3) the entities, ownership, and lifecycle already fixed in the ETM Domain Specification — no workflow here introduces an entity, a state, or an ownership claim that document does not already establish.

**Normal vs. exceptional workflows** are separated deliberately: Device Ready, Shift Start, Trip Assignment, Trip Start, Ticket Issuance, Continuous Telemetry, Trip Completion, and Shift Completion are the *normal*, expected operational sequence of a working day. Offline Operations, Connectivity Recovery, Device Revocation, Authentication Failure, and Device Replacement are the *exceptional* workflows — each one a real, expected occurrence in this fleet (not an edge case, per the Product Specification's own framing), but distinct from the happy path a Conductor experiences on an ordinary shift.

## 4. Workflow Index and Dependencies

```
Device Ready ──► Shift Start ──► Trip Assignment ──► Trip Start ──┬─► Ticket Issuance (repeating)
                                                                    ├─► Continuous Telemetry (repeating, device-scoped)
                                                                    └─► Trip Completion ──► Shift Completion

Offline Operations        — a condition that can begin and end at any point after Device Ready
Connectivity Recovery     — always follows a period of Offline Operations
Device Revocation         — can occur at any point in the diagram above, initiated externally
Authentication Failure    — can occur at Device Ready or at any reconnect attempt thereafter
Device Replacement        — composes Device Revocation with a new Device's Device Ready, for the same Bus
```

Two dependency facts worth stating plainly, because later workflows rely on them without re-deriving them each time:

- **Continuous Telemetry does not depend on Trip Assignment or Trip Start.** A Device reports location/status from the moment it is authenticated and operating, independent of whether a Trip is currently assigned — Trip correlation happens after the fact, by time-and-position, never as a precondition of reporting (ETM Domain Specification §5.5).
- **Ticket Issuance depends on Trip Assignment having resolved successfully at least once.** Unlike Telemetry, a Ticket cannot exist without a resolved Trip, Conductor, and Fare Rule context (ETM Domain Specification §5.4, §11).

## 5. Workflow: Device Ready

**Purpose:** Establish that the ETM is in a state where a Conductor can begin depending on it — authenticated, aware of its own pairing, and able to report and issue.

**Actors:** Conductor (initiates use); the platform (authenticates and authorizes the Device).

**Preconditions:** The Device has already been provisioned and registered to a Bus by an Operator Admin (a prerequisite handled entirely outside this workflow — see Dependencies).

**Trigger:** The Conductor powers on or unlocks the Device and opens the ETM at the start of a period of use.

**Business Flow:**
1. The Device establishes connectivity and authenticates itself to the platform as the specific, provisioned identity it is.
2. The platform confirms the Device's current status is one that permits operation, and resolves which Bus it is currently paired to.
3. The Device becomes able to originate Telemetry immediately, independent of any Trip or Conductor context.
4. The Device attempts to resolve its currently-assigned Conductor and current Trip, for use once a Ticket needs to be issued.
5. The ETM presents itself to the Conductor as ready for use, or as constrained (e.g., not yet paired to a Conductor) if step 4 could not be resolved.

**Business Rules:**
- A Device that is not currently in an operable status (see ETM Domain Specification §5.1's lifecycle) cannot become Ready — this is a platform determination the Device cannot override or work around locally.
- Readiness for Telemetry and readiness for Ticketing are separable — a Device can be Ready to report location before it has successfully resolved a Conductor or Trip.

**Alternative Flow:** The Device has no connectivity at the moment it is powered on. It proceeds into a degraded-but-operable state (see Offline Operations, §11), using its last-known pairing and context, rather than blocking the Conductor from starting work.

**Failure Cases:**
- The platform denies the Device's authentication outright (see Authentication Failure, §14) — the Device cannot become Ready at all, regardless of connectivity.
- The Device has never previously resolved a Conductor or Trip assignment and has no connectivity to do so now — it can report Telemetry but cannot yet support Ticket Issuance until context resolves.

**Expected Outcome:** The Device is operating under its own authenticated identity, is originating Telemetry, and either has or is working to obtain the Conductor and Trip context Ticket Issuance depends on.

**Dependencies:** Device provisioning and registration (an Operator Admin, Dashboard-side prerequisite, entirely outside this workflow); Authentication Failure (§14, the failure path this workflow can fall into).

**Open Questions:** How a Device receives its initial credentials and identity in the field — whether this is an ETM-app responsibility or a separate provisioning tool — is unresolved (ETM Domain Specification §16, item 6; ETM Product Specification §21).

## 6. Workflow: Shift Start

**Purpose:** Mark the beginning of a Conductor's period of carrying and operating a specific Device.

**Actors:** Conductor.

**Preconditions:** The Device is Ready (§5); the Conductor is the one currently assigned to this Device, per the Operator Admin's prior pairing action.

**Trigger:** The Conductor begins their working period with this Device — physically taking possession of it for the day or for a specific duty.

**Business Flow:**
1. The Conductor takes possession of the Device already paired to them by an Operator Admin.
2. The Conductor confirms (implicitly, by using the Device) that they are the currently-assigned Conductor for it.
3. The Device, already Ready, continues originating Telemetry and awaits a Trip Assignment if one has not already resolved.

**Business Rules:**
- There is no authentication step naming the Conductor specifically — the Device's own authenticated identity, plus its currently-carried Conductor attribute, stands in for a Conductor-specific "shift start" (ETM Domain Specification §3, Principle 4).
- A Conductor cannot begin a shift with a Device they are not currently paired to without an Operator Admin first re-pairing that Device to them.

**Alternative Flow:** The Conductor is a relief Conductor taking over a Device from another Conductor mid-operation, without an Operator Admin action having yet occurred to re-pair it — see Device Replacement (§15) and the misattribution risk it shares.

**Failure Cases:** The Device still carries a different Conductor's pairing (the prior Conductor was never unassigned), and no connectivity is available to detect or correct this — Tickets issued in this state will be misattributed until the mismatch is corrected (ETM Domain Specification §16, item 1).

**Expected Outcome:** The Conductor is operating the Device, and any Ticket subsequently issued will be attributed to whichever Conductor identity the Device currently carries.

**Dependencies:** Device Ready (§5); the Operator Admin's Conductor-to-Device pairing action (external to this workflow — an Operator responsibility, not an ETM one).

**Open Questions:** "Shift" itself is a real, named concept in the Product Specification's operational description (a Conductor's period of carrying a Device) but has no corresponding entity, state, or lifecycle anywhere in the platform's Domain Model or backend specifications — there is no "shift started" or "shift ended" domain event. This workflow is therefore a purely Conductor-experienced operational boundary with no backend representation today; whether one should exist (e.g., to bound a Conductor's attributable working period more precisely than "whatever Ticket carries their conductor_id") is an open question for a future domain or feature decision, not resolved here.

## 7. Workflow: Trip Assignment

**Purpose:** Establish which specific Trip the Device's Bus is currently running, giving every subsequent Ticket and (by correlation) Telemetry Ping its business meaning.

**Actors:** Operator Admin (assigns); the platform (resolves the assignment to the Device); Conductor (benefits from the resolved context, takes no direct action in this workflow).

**Preconditions:** The Trip already exists, scheduled against the correct Bus and Route; the Device and Conductor to run it may be named at scheduling time or deferred.

**Trigger:** An Operator Admin schedules a Trip and names (immediately, or at a later point before the Trip starts) which Device and Conductor will run it.

**Business Flow:**
1. An Operator Admin creates or updates a Trip, naming the Bus, Route, and (immediately or later) the Device and Conductor.
2. The Device, when connectivity allows, resolves which Trip it is currently assigned to.
3. The resolved Trip becomes the context against which the Conductor's subsequent Ticket sales are attributed.

**Business Rules:**
- A Trip's Device and Conductor assignment may be deferred at scheduling time — this is a normal, expected pattern, not an incomplete Trip.
- The Device resolves its Trip assignment as a reference lookup, not as something it is told to remember indefinitely — a stale resolution is a real possibility during a connectivity gap (see Offline Operations, §11).

**Alternative Flow:** The Trip's Device/Conductor assignment is changed by an Operator Admin after the Device has already resolved an earlier assignment (e.g., a last-minute reassignment) — the Device continues operating against its last-resolved assignment until it next successfully re-resolves.

**Failure Cases:** The Device attempts to resolve its Trip assignment and has no connectivity — it falls back to its last-known assignment, which may be absent (if this is the Device's first-ever resolution attempt) or stale (if a change occurred since the last successful resolution).

**Expected Outcome:** The Device holds a current, correctly-resolved Trip assignment, ready to support Ticket Issuance once the Trip is started.

**Dependencies:** Device Ready (§5); Trip Start (§8, which requires this assignment to already be in place); the Operator Admin's scheduling action (external to the ETM).

**Open Questions:** No staleness bound is defined for how old a cached Trip assignment may be before the ETM should treat it as unreliable or warn the Conductor (ETM Domain Specification §16, item 5).

## 8. Workflow: Trip Start

**Purpose:** Transition a scheduled Trip into an actively-running one — the point at which Tickets and Telemetry become attributable to a live service instance rather than a merely-planned one.

**Actors:** Operator Admin (initiates the transition); Conductor (operates within it once started); the platform (enforces the transition's legality).

**Preconditions:** The Trip is currently scheduled, with both a Device and Conductor already assigned to it (§7).

**Trigger:** An Operator Admin marks the Trip as started, typically at or near the Bus's actual departure.

**Business Flow:**
1. An Operator Admin transitions the Trip from its scheduled state to an actively-running one.
2. The Device's already-resolved Trip assignment (§7) now corresponds to a Trip the platform considers live.
3. Ticket Issuance (§9) becomes fully meaningful — sales are now attributed to a Trip actually in progress, not merely planned.

**Business Rules:**
- A Trip cannot start without both a Device and Conductor already assigned — this is a hard precondition, not a warning.
- Trip Start is exclusively an Operator Admin action; the ETM has no business action that starts a Trip on its own initiative, even if the Conductor knows the Bus has physically departed.

**Alternative Flow:** None distinct from the normal path — Trip Start is a single, atomic business transition with no partial or intermediate state.

**Failure Cases:** An Operator Admin attempts to start a Trip missing its Device or Conductor assignment — the transition is refused until both are present. An Operator Admin attempts to start a Trip that is not currently in the scheduled state (e.g., already started, or cancelled) — refused as an invalid transition.

**Expected Outcome:** The Trip is actively running; every Ticket the Conductor subsequently issues, and every Telemetry Ping correlated to it, is understood as belonging to a live, in-progress service instance.

**Dependencies:** Trip Assignment (§7); feeds Ticket Issuance (§9) and is a precondition for Trip Completion (§13).

**Open Questions:** None beyond those already named for Trip Assignment (§7) — Trip Start itself is fully and unambiguously defined by the backend specifications.

## 9. Workflow: Ticket Issuance

**Purpose:** Capture a single fare sale as a durable, correctly-attributed business record — the ETM's primary reason for existing.

**Actors:** Conductor (issues); Commuter (the fare payer, usually not a platform account at MVP); the platform (validates, deduplicates, and reconciles).

**Preconditions:** The Device is Ready (§5); a Trip is assigned and started (§7, §8); a Conductor identity and applicable Fare Rule are resolvable (live or cached).

**Trigger:** A passenger boards and pays a fare; the Conductor records the sale.

**Business Flow:**
1. The Conductor selects the passenger's boarding and destination points along the current Trip's Route.
2. The applicable Fare Rule for that boarding/destination pair is resolved and the fare amount determined.
3. The sale is captured as a Ticket, attributed to the current Trip, the currently-carried Conductor identity, and the Device itself, with the determined fare permanently fixed to it.
4. The Ticket is transmitted to the platform when connectivity allows; the platform deduplicates and reconciles it into the authoritative record.
5. The sale contributes to the Trip's occupancy signal on the platform's next read of that data.

**Business Rules:**
- A Ticket must never be lost between capture and reconciliation, regardless of connectivity at the moment of sale.
- A Ticket's fare, once captured, never changes — even if the underlying Fare Rule is later superseded.
- A Ticket with no attributable Conductor is not a valid business record — the sale cannot be captured at all if no Conductor identity is currently resolvable.
- Duplicate transmission of the same sale (a retried send, a reconnect replay) must never produce a second fare charge.

**Alternative Flow:** The sale occurs with no connectivity present at all — the Ticket is still captured in full, and nothing about the capture step itself requires network access (see Offline Operations, §11).

**Failure Cases:**
- No Trip context is currently resolvable (the Device has never successfully resolved one, and has no cached fallback) — a sale cannot be captured as a valid Ticket.
- No Conductor identity is currently resolvable — same outcome; the sale cannot be captured as a valid business record.
- The Fare Rule applicable to the selected boarding/destination pair cannot be resolved (live or cached) — the fare cannot be determined and the sale cannot be captured.
- A previously-captured Ticket is later found to be erroneous — it is corrected by issuing a new record referencing the original, never by editing the original (see Open Questions below).

**Expected Outcome:** Exactly one Ticket exists for the sale, correctly attributed to its Trip, Conductor, Device, and Fare Rule, eventually visible to the Operator as part of that Trip's revenue and occupancy picture.

**Dependencies:** Trip Assignment and Trip Start (§7, §8); Continuous Telemetry shares the same underlying capture-and-transmit mechanism but is a separate workflow (§10); Offline Operations and Connectivity Recovery (§11, §12) govern what happens when transmission cannot happen immediately.

**Open Questions:** No workflow, actor, or mechanism is defined anywhere in the backend specifications for actually correcting or voiding an already-issued Ticket, despite the Domain Model naming "a new event referencing the original" as the intended shape of a correction. Who initiates a correction (the Conductor, an Operator Admin, or both) and under what conditions is unresolved (ETM Domain Specification §16, item 3) — this workflow describes issuance only; correction is out of scope until that gap is closed upstream.

## 10. Workflow: Continuous Telemetry

**Purpose:** Report the paired Bus's location and status at a regular cadence throughout the Device's operation — the evidence base for live tracking, ETA, and (via Ticket-derived occupancy) the platform's real-time picture of the fleet.

**Actors:** The Device (originates, without direct Conductor action); the platform (receives, deduplicates, reconciles).

**Preconditions:** The Device is Ready (§5) and authenticated.

**Trigger:** Ongoing, at a regular cadence, for as long as the Device is operating — independent of whether a Trip is currently assigned or started.

**Business Flow:**
1. The Device captures a location/status reading.
2. The reading is captured durably before any network attempt.
3. The reading is transmitted to the platform when connectivity allows.
4. The platform deduplicates and reconciles the reading, correlating it to a Trip by time and position where one applies.
5. The reconciled reading updates the platform's live-position picture of the Bus, consumed by ETA and Commuter tracking.

**Business Rules:**
- Telemetry reporting requires no Trip, Conductor, or Fare context — unlike a Ticket, a reading can be captured and is valid the moment the Device itself is authenticated and operating.
- A reading must never be silently lost; duplicate transmission is routine, expected behaviour, never an error.
- Telemetry carries the same durability and reliability contract as Ticket Issuance, but materially lower per-event stakes — a lost or duplicated reading degrades tracking accuracy briefly, never revenue accountability.

**Alternative Flow:** The Bus is stationary, between Trips, or the Device has no current Trip assignment at all — Telemetry continues regardless, since it is not gated on Trip context.

**Failure Cases:** Extended loss of connectivity delays transmission (see Offline Operations, §11) but does not prevent capture; a reading that cannot be correlated to any Trip by time and position simply carries no Trip attribution — this is expected, not an error.

**Expected Outcome:** A continuous, eventually-consistent stream of location/status readings reaches the platform, correctly deduplicated, supporting live tracking regardless of any given reading's timeliness.

**Dependencies:** Device Ready (§5); shares its offline-tolerance mechanism with Ticket Issuance (§9) and the same recovery workflow (§12), but is otherwise fully independent of Trip Assignment, Trip Start, and Trip Completion.

**Open Questions:** None specific to this workflow — its business shape is fully and unambiguously defined by the backend specifications.

## 11. Workflow: Offline Operations

**Purpose:** Describe how the Conductor's and the Device's work continues, uninterrupted, in the complete absence of connectivity — the platform's central design condition, not an edge case.

**Actors:** Conductor (continues working); the Device (continues capturing).

**Preconditions:** The Device was previously Ready (§5); connectivity is now unavailable, for any duration from moments to multiple hours.

**Trigger:** Loss of cellular connectivity, broker unreachability, or any combination of the two.

**Business Flow:**
1. The Conductor continues issuing Tickets exactly as they would with connectivity present — nothing about the act of selling a fare or reporting location requires a live network connection.
2. Every Ticket and Telemetry Ping is captured durably on the Device the instant it occurs, with no dependency on when (or whether) it can be transmitted.
3. The Device continues operating against its last-resolved Trip, Conductor, and Fare Rule context for as long as the gap lasts.
4. Nothing is transmitted during this period; nothing is at risk of loss because of it.

**Business Rules:**
- Connectivity is the exception this entire workflow is built around, not the assumption normal operation depends on.
- A Ticket or Telemetry Ping is never "at risk" merely because it hasn't yet reached the platform — durability is established at the moment of capture, not at the moment of transmission.
- No actor-facing action (issuing a Ticket, reporting a location) is ever blocked or delayed by the absence of connectivity.

**Alternative Flow:** Connectivity is intermittent rather than fully absent — brief windows may allow a partial trickle of transmission; this is treated as an ordinary variation of this same workflow, not a distinct one.

**Failure Cases:** The Device's ability to resolve *new* or *changed* context (a Trip reassignment, a superseded Fare Rule, a Conductor re-pairing) is genuinely degraded during this period — the Device continues operating correctly against what it already has, but cannot detect a change made elsewhere on the platform until connectivity returns (see Trip Assignment §7, Open Questions across the affected read-only entities).

**Expected Outcome:** The Conductor experiences no interruption to their work; a complete, correctly-attributed backlog of Tickets and Telemetry Pings accumulates on the Device, ready for Connectivity Recovery (§12) the moment a connection is available.

**Dependencies:** Every normal workflow above (Ticket Issuance, Continuous Telemetry) continues to operate during this condition without modification; feeds directly into Connectivity Recovery (§12).

**Open Questions:** How long a Device may reasonably be expected to operate offline before its cached context (Trip, Fare Rule, Route Stop, Conductor pairing) should be considered too stale to trust is not defined (ETM Domain Specification §16, item 5); the Product Specification itself names the true field connectivity profile as an estimate, not yet a measurement.

## 12. Workflow: Connectivity Recovery

**Purpose:** Describe how a backlog of Tickets and Telemetry Pings accumulated during Offline Operations (§11) is delivered to the platform once connectivity returns, without overwhelming a just-recovered, potentially fragile connection.

**Actors:** The Device (drains its backlog); the platform (receives and reconciles).

**Preconditions:** A period of Offline Operations (§11) has ended; the Device holds one or more not-yet-transmitted Tickets and/or Telemetry Pings.

**Trigger:** Connectivity becomes available again after a period of absence.

**Business Flow:**
1. The Device detects that connectivity has genuinely returned.
2. Accumulated Tickets and Telemetry Pings are transmitted in controlled, bounded groups rather than all at once, so as not to burden a freshly-recovered connection.
3. Ticket and Telemetry backlogs are drained independently of one another — neither is prioritized over the other by default.
4. Each transmitted item is deduplicated and reconciled by the platform exactly as it would be for an item sent in real time.
5. Once the backlog is fully drained, the Device returns to reporting each new Ticket or Telemetry Ping as it occurs, without any special "catching up" behaviour thereafter.

**Business Rules:**
- Recovery is throttled and paced deliberately — it is not a burst delivery of the entire backlog at once, out of respect for the fragility of a just-recovered connection.
- A failure partway through recovery is treated as a signal to pause and retry, not to abandon the remaining backlog or treat it differently from items already delivered.
- Nothing about recovery changes a Ticket's or Telemetry Ping's business meaning — a late-arriving item is reconciled exactly as an on-time one would be, with the same deduplication guarantee.

**Alternative Flow:** Connectivity is lost again partway through recovery — the Device simply resumes Offline Operations (§11) and re-attempts recovery once connectivity returns again; no distinct "recovery within a recovery" handling exists.

**Failure Cases:** A transmitted item fails validation on arrival at the platform for reasons unrelated to connectivity (e.g., a Trip or Fare Rule reference that no longer resolves) — the item is preserved by the platform for investigation rather than silently dropped, but the Device itself has no visibility into this outcome and does not retry based on it.

**Expected Outcome:** Every Ticket and Telemetry Ping captured during the offline period reaches the platform's authoritative record, correctly deduplicated, with no data loss attributable to the connectivity gap having occurred.

**Dependencies:** Directly follows Offline Operations (§11); shares its underlying mechanism with ordinary Ticket Issuance (§9) and Continuous Telemetry (§10) transmission.

**Open Questions:** The Conductor has no visibility into whether a specific transmitted Ticket has actually been reconciled by the platform, as opposed to merely delivered — the same gap named in Ticket Issuance (§9) applies with added weight here, since a Conductor recovering from a long dead zone may reasonably want assurance that a large backlog genuinely landed (ETM Domain Specification §16, item 2).

## 13. Workflow: Trip Completion

**Purpose:** Transition an actively-running Trip to its terminal, completed state, closing the window within which Tickets and Telemetry are attributed to it as a live service instance.

**Actors:** Operator Admin (initiates); Conductor (operates until completion, takes no direct action in this specific transition).

**Preconditions:** The Trip is currently actively running (§8).

**Trigger:** An Operator Admin marks the Trip as completed, typically once the Bus has finished its run along the Route.

**Business Flow:**
1. An Operator Admin transitions the Trip from its actively-running state to completed.
2. Any Ticket issued or Telemetry Ping correlated after this point no longer belongs to this Trip as a live instance — subsequent Tickets require a new Trip assignment.
3. The Trip's full record — every Ticket and correlated Telemetry Ping captured during it — becomes the historical basis for occupancy and revenue reporting.

**Business Rules:**
- A Trip's transition to completed is one-directional — a completed Trip can never become actively-running again, even if the Bus continues to move or the Conductor continues issuing sales (those sales would belong to a different Trip, not this one).
- A Trip that ends early or unexpectedly (a cut-short run) still transitions to the same completed state as one that ran its full course — the business model does not distinguish a "partial" completion from a full one.
- Trip Completion is exclusively an Operator Admin action; the ETM has no business action that completes a Trip.

**Alternative Flow:** The Trip is cancelled rather than completed — this is a distinct terminal state, reachable only while the Trip was still scheduled (before Trip Start), not after it was actively running.

**Failure Cases:** An Operator Admin attempts to complete a Trip that is not currently actively running (e.g., already completed, or still only scheduled) — refused as an invalid transition.

**Expected Outcome:** The Trip's record is closed and historically complete; the Conductor and Device await a new Trip Assignment (§7) before further Tickets can be issued.

**Dependencies:** Trip Start (§8); feeds Shift Completion (§14) where a Conductor's period of work ends at or near the same point as their final Trip.

**Open Questions:** None beyond those already named for Trip Start (§8).

## 14. Workflow: Shift Completion

**Purpose:** Mark the end of a Conductor's period of carrying and operating the Device.

**Actors:** Conductor.

**Preconditions:** The Conductor's working period is ending — typically, though not necessarily, coinciding with their final Trip's Completion (§13).

**Trigger:** The Conductor ends their working period with this Device.

**Business Flow:**
1. The Conductor stops actively using the Device for ticketing purposes.
2. The Device continues to originate Telemetry for as long as it remains powered on and paired to its Bus, independent of the Conductor's own working period having ended.
3. No platform-side transition of the Conductor's own status necessarily occurs at this point — the Conductor remains "assigned" to the Device, per the Operator Admin's last pairing action, until an Operator Admin changes that.

**Business Rules:**
- Shift Completion does not, by itself, unassign the Conductor from the Device or revoke anything — those remain Operator Admin actions, entirely independent of when a Conductor stops working.
- The Device's own operation (Telemetry origination in particular) is not gated on a Conductor's shift boundary.

**Alternative Flow:** The Device is handed directly to a relief Conductor at this point, without an Operator Admin action having occurred yet — this is the same handoff condition named in Shift Start (§6) and Device Replacement (§15).

**Failure Cases:** None distinct — this workflow has no platform-side transition to fail, since it corresponds to no domain event.

**Expected Outcome:** The Conductor stops actively issuing Tickets; the Device and its Telemetry origination continue independent of this fact, until the Device itself is powered off, revoked, or reassigned.

**Dependencies:** Trip Completion (§13), where the two typically coincide; Shift Start (§6), whose same open question applies here.

**Open Questions:** As with Shift Start (§6), "shift" has no backend representation — there is no domain event, status, or record marking that a Conductor's working period has ended. The business consequence is that the platform has no way to distinguish "the Conductor's shift ended, and a new Conductor will pick this Device up later" from "the same Conductor will resume with this Device shortly" — both look identical from the platform's perspective until a new Ticket is issued or an Operator Admin acts.

## 15. Workflow: Device Revocation

**Purpose:** Instantly and unconditionally withdraw a Device's authorization to operate — the platform's response to a lost or stolen phone, a Device being decommissioned, or a Conductor leaving.

**Actors:** Operator Admin (initiates); the platform (enforces); Conductor (loses the ability to continue operating the Device).

**Preconditions:** The target Device exists and is not already revoked.

**Trigger:** An Operator Admin revokes the Device — most commonly in response to a loss, theft, decommissioning, or a Conductor's departure.

**Business Flow:**
1. An Operator Admin revokes the Device, from whatever operational status it currently holds — including mid-Trip.
2. The platform's authorization for this Device is withdrawn immediately and unconditionally for any subsequent authentication attempt.
3. Any attempt by the Device to authenticate again — to report Telemetry, issue a Ticket, or resolve any context — is refused from this point forward.

**Business Rules:**
- Revocation is valid from any current operational status the Device holds — a Device does not need to first reach some "safe" or idle state to be revoked; a lost phone can be revoked mid-Trip.
- When the platform cannot verify a Device's authorization status for any reason, it denies by default — an unrecoverable trust failure (an unauthenticated Device continuing to act) is always treated as worse than a recoverable one (a temporary gap in telemetry or ticketing).
- A Device already actively connected at the moment of revocation may retain its existing session's ability to transmit until that session is next re-established — this is a named, bounded exception to "instant," not a contradiction of it; the operational remedy for an urgent case is for the Operator Admin to also force-close the Device's live session at the same moment as revoking it.

**Alternative Flow:** The Device was already offline (in a dead zone) at the moment of revocation — nothing changes for it until it next attempts to reconnect, at which point the revocation takes full effect.

**Failure Cases:** An Operator Admin attempts to revoke a Device that is already revoked — refused as a redundant, invalid transition, not silently accepted as a no-op.

**Expected Outcome:** The Device can no longer originate Tickets or Telemetry, resolve any context, or authenticate in any capacity, from the moment of revocation onward (subject to the bounded live-session exception named above); any Tickets or Telemetry it had already durably captured but not yet transmitted before revocation remain on the Device, unreachable to the platform unless the Device is later restored to an operable status.

**Dependencies:** Can interrupt any other workflow in this document at any point; is the first half of Device Replacement (§16).

**Open Questions:** What becomes of a revoked Device's own not-yet-transmitted backlog of Tickets and Telemetry — whether it is expected to ever reach the platform (e.g., via a data-extraction process outside normal operation) or is simply lost from the platform's perspective — is not addressed by any reviewed specification.

## 16. Workflow: Authentication Failure

**Purpose:** Describe what happens, in business terms, when a Device is unable to establish itself as a valid, authorized identity to the platform.

**Actors:** The Device (attempts); the platform (denies); Conductor (experiences the consequence).

**Preconditions:** The Device attempts to authenticate — at Device Ready (§5), or at any subsequent reconnection attempt.

**Trigger:** Any authentication attempt where the Device's claimed identity and credential do not correspond to a currently-operable Device.

**Business Flow:**
1. The Device attempts to authenticate itself to the platform.
2. The platform is unable to confirm the Device is a valid, currently-operable identity — because it has been revoked, was never fully provisioned, has been unassigned, or its underlying verification could not be completed at all.
3. The platform denies the attempt.
4. The Device is left unable to originate Tickets or Telemetry, or to resolve any context, until whatever condition caused the denial is resolved.

**Business Rules:**
- The platform does not distinguish, from the Device's own perspective, between "wrong credential" and "correct credential, but no longer authorized" — both are refused identically, with no differentiated business signal exposed to the failing Device itself.
- When the platform's own ability to verify a Device's status is itself unavailable (rather than the Device specifically being invalid), the same denial outcome applies — the platform does not grant the benefit of the doubt in either case.
- A denial-because-the-platform-couldn't-verify is operationally distinguishable from a denial-because-the-Device-is-genuinely-invalid *by the platform*, even though the Device experiences both identically — this distinction matters for how an Operator responds (a wave of the former across many Devices signals a platform-side problem, not a fleet of bad actors).

**Alternative Flow:** The Device was previously authenticated and operating normally, then loses its authorization mid-session due to a Revocation (§15) that occurs while it happens to be connected — this is a delayed, not immediate, instance of the same underlying failure, bounded by the session's own natural end.

**Failure Cases:** This workflow is itself the failure case for Device Ready (§5) and for every reconnection attempt during Connectivity Recovery (§12) — a Device that cannot authenticate cannot proceed into any other workflow in this document.

**Expected Outcome:** The Conductor cannot operate the Device for either ticketing or telemetry purposes until the underlying cause is resolved — most commonly, an Operator Admin restoring or re-provisioning the Device, or a transient platform-side condition clearing on its own.

**Dependencies:** Device Ready (§5, the workflow this failure blocks); Device Revocation (§15, one of the possible underlying causes); Connectivity Recovery (§12, where a reconnection attempt can also surface this failure).

**Open Questions:** No specification defines what, if anything, the ETM should communicate to the Conductor to distinguish "you are not authorized to operate this Device" from "connectivity is simply unavailable right now" — both can present identically to the Device itself, and whether the Conductor should be able to tell them apart is a future Feature/UI Specification decision, not resolved here.

## 17. Workflow: Device Replacement

**Purpose:** Restore ticketing and telemetry capability for a Bus whose Device has been lost, stolen, damaged, or otherwise needs to be swapped for a different physical unit.

**Actors:** Operator Admin (performs the replacement); Conductor (resumes operation on the new Device).

**Preconditions:** The Bus's current Device is being retired from service (commonly following, or alongside, a Device Revocation, §15).

**Trigger:** A Device is lost, stolen, damaged beyond use, or otherwise needs to be swapped for a new physical unit serving the same Bus.

**Business Flow:**
1. An Operator Admin revokes the outgoing Device, if this has not already occurred (§15).
2. An Operator Admin provisions and registers a new Device against the same Bus.
3. An Operator Admin re-pairs the currently-assigned Conductor (or a new one) to the new Device.
4. The new Device proceeds through Device Ready (§5) and Shift Start (§6) as its own, independent first use.
5. Ticketing and Telemetry origination for this Bus resume under the new Device's identity; the outgoing Device's history remains intact and attributed to it as it was captured.

**Business Rules:**
- A Bus may only have one currently-operable Device paired to it at a time — the new Device cannot be registered against the Bus while the outgoing one still holds an active pairing, which is precisely why revocation (or an equivalent unassignment) must precede or accompany registration.
- The outgoing Device's historical Tickets and Telemetry Pings are never altered, reattributed, or merged into the new Device's identity — they remain a permanent record of what that specific Device, while it was operating, actually captured.
- Trip continuity across the swap is a business judgment for the Operator Admin, not an automated platform behaviour — if a Trip was actively running on the outgoing Device, the Operator Admin decides whether and how the new Device picks it up.

**Alternative Flow:** The replacement happens between shifts, with no Trip actively running — the simpler case, requiring no judgment call about mid-Trip continuity.

**Failure Cases:** An Operator Admin attempts to register the new Device against the Bus before the outgoing Device has been unassigned or revoked — refused, since the Bus already has an operable Device bound to it.

**Expected Outcome:** The Bus is served by a new, distinct Device identity going forward; the outgoing Device's history is preserved and unaffected; ticketing and telemetry resume under the new identity once it completes its own Device Ready and Shift Start.

**Dependencies:** Composes Device Revocation (§15) with a fresh instance of Device Ready (§5) and Shift Start (§6); shares the misattribution risk named in Shift Start with any handoff scenario.

**Open Questions:** No single, named workflow for "device replacement" exists anywhere in the backend specifications — this workflow is a composition of three separately-defined primitives (revoke, register, re-pair), not a first-class operation in its own right. Whether a Trip actively running on the outgoing Device at the moment of replacement should or can be transferred to the new Device mid-run is not addressed by any reviewed specification, and is named here as a genuine business-process gap, not a resolved judgment call.

## 18. Cross-Workflow Business Rules

A small number of rules recur across several workflows above and are stated once here for traceability, rather than only inline:

- **The Device, never the Conductor, is what authenticates.** Every workflow's Preconditions and Failure Cases trace back to the Device's own authorization status, never to a Conductor-specific credential, because no such credential exists anywhere in the platform.
- **Fail-closed is the platform's universal default under uncertainty.** Authentication Failure (§16) and Device Revocation (§15) both resolve an unverifiable state as a denial, never as a provisional allowance — this is a single platform-wide posture, not independently decided per workflow.
- **Nothing the Conductor does is ever blocked by connectivity.** Ticket Issuance (§9) and Continuous Telemetry (§10) both hold this as an absolute rule; Offline Operations (§11) is this rule's natural consequence, not an exception to it.
- **Operator Admin actions govern every entity's lifecycle transition except the two facts the Device itself originates.** Trip Assignment, Trip Start, Trip Completion, Device Revocation, and Conductor pairing are all Operator Admin actions; only Ticket Issuance and Continuous Telemetry are ETM-initiated business events.

## 19. Consolidated Open Questions

Gathered from each workflow above, for visibility as a single list:

1. **Shift has no backend representation** (§6, §14) — a real Conductor-experienced operational boundary with no corresponding domain event, status, or record.
2. **Conductor misattribution on device handoff** (§6, §17) — no domain mechanism corrects a stale Conductor pairing during an offline handoff until an Operator Admin acts.
3. **Ticket reconciliation visibility** (§9, §12) — the Conductor has no way to confirm a Ticket, or a recovered backlog of them, has actually reached the platform's authoritative record, as opposed to merely being transmitted.
4. **Ticket correction/void has no defined workflow** (§9) — the Domain Model names the intended shape of a correction, but no actor, trigger, or mechanism for actually performing one is defined anywhere in the reviewed specifications.
5. **Staleness bound for cached context is undefined** (§7, §11) — no rule states how old a cached Trip, Fare Rule, or Route Stop set may be before the ETM should treat it as unreliable.
6. **Device credential provisioning in the field is unresolved** (§5) — whether this is an ETM-app responsibility or a separate tool is an open product/architecture decision.
7. **Post-revocation backlog fate is undefined** (§15) — whether a revoked Device's not-yet-transmitted Tickets and Telemetry are ever expected to reach the platform is unaddressed.
8. **Authentication-failure Conductor messaging is undefined** (§16) — whether the Conductor should be able to distinguish "not authorized" from "no connectivity" is left to a future Feature/UI decision.
9. **Device Replacement is a composition, not a first-class workflow** (§17) — including an unresolved judgment call on transferring a mid-run Trip to a replacement Device.

## 20. Platform Dependencies

This document depends on, and must never contradict:

- **ETM Product Specification** — product-level scope, users, personas, risks, and constraints (§7, §9, §14, §16, §17 of that document, referenced throughout).
- **ETM Domain Specification** — the entities, ownership, lifecycle, and domain events every workflow above is built from, especially §5 (Entities), §9–§11 (Lifecycle, State Transitions, Domain Events), and §16 (Open Domain Questions), several of which are restated at workflow scope here.
- **Product Engineering Blueprint** — Part 6.1 (Conductor ETM), Part 10.5 (offline conductor operation), Part 11 (offline-first philosophy).
- **Domain Model Specification** — Part 8 (Business Workflows), Part 11 (Domain Policies), Part 12 (Domain Events) — the platform-wide versions of the workflows and events this document narrows to ETM scope.
- **Sequence Diagrams** §5.2–§5.4 (Device registration and authentication), §6.1–§6.3 (Trip operations), §7.1 (Ticket Issuance), §8.1 (Telemetry), §11.1 (Offline Synchronization Recovery), §11.4 (Device Revocation) — the backend mechanics this document deliberately does not restate, referenced only where a business rule depends directly on a fact those diagrams establish (e.g., the bounded, not-instant, effect of revocation on an already-connected session, §15).
- **API Specification, MQTT Specification** — implementation detail underlying the above; not restated here.

---

*End of NammaRoute Conductor ETM Workflow Specification v1.0.*
