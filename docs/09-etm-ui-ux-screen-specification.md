# NammaRoute Conductor ETM — UI, UX & Screen Specification
### `docs/etm-ui-ux-screen-specification.md`

**Document type:** Product Design Specification — defines how the Conductor experiences and interacts with the ETM: design philosophy, interaction rules, design system guidelines, navigation model, and per-screen behaviour. It is not a Flutter implementation guide, not a Figma file, and not a widget specification.
**Position in the hierarchy:** Derives from, and must not contradict, the ETM Product Specification, ETM Workflow Specification, and ETM Functional Feature Specification (primary inputs), constrained by the ETM System Architecture Specification and ETM Offline Synchronization & Reliability Specification (supporting references). Feeds a future Flutter Implementation Plan, which owns widgets, state management, and code — none of which is redefined here.
**Status:** Living document, updated when a screen's purpose, behaviour, or business rule changes underneath it — not when a color token or spacing value changes.

---

## 1. Purpose

This document defines how a Conductor experiences the NammaRoute ETM — every screen they see, every state that screen can be in, and every rule that governs what they can do on it. It exists so a product designer and a frontend engineer share one authoritative reference for *what to build and how it should behave*, without either having to re-derive business logic from the Workflow or Feature Specifications, and without inventing behaviour those documents don't already establish.

Two facts from the upstream documents shape this specification more than any single design choice could:

- **The Device, not the Conductor, is the authenticated identity.** There is no Conductor login anywhere in this platform (Product Specification §15; Feature Specification §5.1). Every screen in this document is designed around that fact — there is no username/password screen, no "Profile" screen, and no session the Conductor manages.
- **Connectivity is the exception the product is built for failure around, not the assumption it's built around** (Product Specification §13). Every screen's Offline Behaviour is not an edge case appended at the end — it is load-bearing to the screen's core design.

This document also deliberately does **not** invent screens for capabilities the Feature Specification explicitly found unsupported: Help & Support, Application Updates, and a Conductor Profile are named there as not corresponding to any real ETM capability (Feature Specification §15 item 14, §16), and Passenger Category Selection has no supporting Domain concept (§15 item 6). None of the four appear in this document's Screen Catalog. Where the objective brief's own illustrative screen list names one of these, this document says so explicitly rather than fabricating an interaction for it.

---

## 2. Design Philosophy

### 2.1 Design Goals

1. **Make the fast path the only path.** A Conductor issuing a fare should never encounter a choice, a field, or a confirmation that doesn't exist to protect the sale's correctness. Product Objective 1 — "ticket issuance is faster or easier than the conductor's current method" (Product Specification §11) — is a design constraint, not an aspiration.
2. **Never let the interface claim more than the system actually knows.** Product Objective 3 — an honest answer to "did my sale go through" — means every status indicator in this design is built from Sync-Status & Reconciliation Honesty's own vocabulary (Captured → Buffered → Synced, never "Reconciled"; Feature Specification §6.1), never a friendlier-sounding paraphrase of it.
3. **Design for a hand that is also holding a fare box, a ticket punch, or a passenger's change**, in a moving vehicle, in outdoor light. Every primary action is reachable and legible under those conditions before it is anything else.
4. **Offline is the default rendering, not a banner.** A screen's offline appearance is designed first; its online appearance is the enhancement, not the reverse.
5. **Say "I don't know yet" out loud.** Where an upstream document names an open question — reference-context staleness, whether "not authorized" is distinguishable from "no connectivity," whether a device handoff has silently misattributed a sale — this design surfaces that honestly to the Conductor rather than picking a comfortable default no specification actually supports.

### 2.2 UX Principles

- **Minimum interaction to revenue.** Every tap between "passenger boards" and "fare captured" is scrutinized. The Boarding & Destination Selection and Fare Confirmation screens (§8.6 to §8.7) exist because Ticket Issuance requires them as hard preconditions (Feature Specification §5.6) — not because a richer flow felt more complete.
- **Status before action.** Before a Conductor can act on a screen, they can see, at a glance, whatever state that action depends on — Trip context, connectivity, authorization — so no action is attempted against a precondition that's silently missing.
- **No dead ends.** Every failure state (no Trip resolvable, no Fare Rule resolvable, Device revoked) tells the Conductor plainly what happened and, where one exists, what to do next — even when the honest next step is "wait for an Operator Admin," never a fabricated self-service fix the backend doesn't support.
- **Consistency over novelty.** The same status vocabulary, the same iconography, and the same confirmation pattern recur everywhere they apply.
- **Progressive disclosure, not information hiding.** Diagnostic-level detail is available on demand, never on the primary ticketing surface, but never entirely absent.

### 2.3 Design Language

The ETM's visual language is **utilitarian, high-contrast, and calm under pressure** — closer to a transit-operations instrument panel than a consumer app. Large, unambiguous status colors; minimal ornamentation; type sized for a glance, not a read. Nothing about the visual language should suggest leisure, browsing, or exploration.

### 2.4 Navigation Philosophy

Navigation is **shallow and task-anchored**, not exploratory. A Conductor's entire working vocabulary is: *where am I in my Trip, what's my sync/connectivity state, and how do I sell a ticket right now.* The navigation model (§5) reflects exactly that vocabulary and nothing more — there is no drawer of miscellaneous destinations, because no upstream feature justifies one.

### 2.5 Information Hierarchy

On every screen, information is layered in this strict order of visual priority:

1. **What blocks me right now** (no Trip resolved, Device unauthorized, no Fare Rule for this segment).
2. **The primary action itself** (issue a ticket, confirm a fare).
3. **Confidence signals** (sync status, connectivity, staleness).
4. **Everything else** (history, settings) — reachable, never surfaced unprompted.

### 2.6 Visual Hierarchy

Size, weight, and color — in that order — carry hierarchy; layout position is secondary, because position is less reliable than a large, saturated, high-contrast element in variable outdoor light and a moving vehicle. Status color is reserved exclusively for state, never decoration.

### 2.7 Layout Principles

- **Single-column, single-focus layouts** on every ticketing-critical screen — one decision at a time, matching Boarding & Destination Selection's own single, atomic step (Feature Specification §5.4).
- **Bottom-anchored primary actions**, reachable by a thumb while the phone is held one-handed, per the Product Specification's own operational framing (§14).
- **Persistent status strip** at the top of every screen — connectivity, sync, and authorization state — so a Conductor never has to navigate away from their current task to answer "is everything okay."

### 2.8 Consistency Principles

A given business state renders identically everywhere it appears — a "Synced" ticket looks the same on the Ticket Confirmation screen as it does in Ticket History; an "Offline" indicator uses the same color and icon on the Home Dashboard as on Trip Context.

### 2.9 Simplicity Principles

Every screen answers exactly one question. Where a real business flow has two questions (e.g., Ticket Issuance's boarding *and* destination), it is broken into sequential single-question screens rather than one screen with two questions at once.

### 2.10 Accessibility Principles

Accessibility here is inseparable from operational safety (§11): large touch targets, high-contrast color pairs, and text sizing all serve a Conductor working outdoors and one-handed as much as they serve a Conductor with low vision. Full treatment in §10.

---

## 3. UX Principles — Applied to This Product's Specific Constraints

The general UX principles above (§2.2) are restated here against the four constraints that most directly shape this product, because each one changes what "good UX" actually means in this context:

- **Offline-first, not offline-tolerant.** A Conductor should never be able to tell, from the ticketing flow alone, whether the Device currently has connectivity — the flow behaves identically either way (Feature Specification §5.6, "Offline Behaviour"). Connectivity only ever changes what the *status strip* says, never what the *ticketing flow* allows.
- **Speed is a correctness requirement, not a nicety.** "Ticket capture should feel instantaneous, regardless of network state" (Product Specification §18) means the UI must never show a spinner gated on a network call between "Conductor taps Confirm" and "ticket is captured" — the durable local write is what the confirmation waits on, nothing else (Feature Specification §5.8).
- **Honesty is a retention feature, not just an ethical one.** The product's own success metric — "conductor-reported trust in the app's sync-status signal" (Product Specification §12) — means an overstated status is a measurable product failure, not a cosmetic one.
- **The interface must tolerate its own user changing mid-shift.** A relief Conductor picking up a Device without an Operator Admin re-pairing action is a *named, expected occurrence* (Product Specification §16), not an edge case — so no screen in this design assumes "the Conductor using this screen right now" is a stable fact across a session.


---

## 4. Design System Guidelines

These are guidelines, not a component library — a future frontend-implementation pass owns exact tokens, widgets, and code.

### 4.1 Typography

- Two weights only in the core ticketing flow: a **Regular** weight for labels and secondary text, a **Bold/Heavy** weight for the fare amount, primary action labels, and any blocking-state message. Restraint here is deliberate — a Conductor scanning a screen at a glance should never have to interpret more than two levels of typographic emphasis at once.
- A minimum base size well above typical mobile-app defaults, since the operating context (outdoors, moving vehicle, brief glances) is closer to a dashboard than a reading surface. The fare amount and any blocking message are the largest text on any screen.
- No decorative or condensed typefaces — legibility at a glance and at arm's length, in bright outdoor light, is the only typographic requirement that matters here.

### 4.2 Color Usage

- Color is a **status carrier**, not a brand or decorative device. A small, fixed palette maps directly onto the states Sync-Status & Reconciliation Honesty (§6.1) and Connectivity & Authorization Status Awareness (§6.2) already define:
  - **Neutral/Informational** — Captured, Buffered (not yet synced, not an error).
  - **Positive/Confirmed** — Synced.
  - **Caution** — offline, degraded connectivity, stale reference context.
  - **Critical/Blocking** — authorization denied, no resolvable Trip/Fare Rule/Conductor.
- These four map onto every status surface in the product identically — a Conductor should never have to relearn what "the orange one" means between screens.
- Color is never the *only* signal for a state — every color pairing is backed by an icon and a text label, since color-only signaling fails both accessibility (§10) and outdoor-glare legibility.
- High-contrast pairings only; no color combination relies on a subtle tonal difference to be distinguishable in direct sunlight.

### 4.3 Icons

- A small, fixed icon set, each icon mapped one-to-one with a specific state or action — never reused across two different meanings. Icons for connectivity, sync, and authorization state are the most frequently seen in the product and are held to the highest legibility bar.
- Icons are always paired with a text label on first appearance per screen; icon-only usage is reserved for secondary, already-learned actions (e.g., a back arrow).

### 4.4 Buttons

- **Primary action** — one per screen, maximum, bottom-anchored, full-width or near-full-width, sized well above the platform's default minimum touch target (see §11 for the specific rationale).
- **Secondary action** — visually subordinate (outline or text-only), never competing with the primary action for the thumb's resting position.
- **Destructive or high-consequence actions** (none exist in the MVP ticketing flow itself, since a Ticket, once captured, is never edited or voided — Feature Specification §5.6, Business Rules) are out of scope for this button style; where a future correction/void feature is added, it earns its own confirmation pattern rather than reusing this one.
- A button is disabled, never hidden, when its precondition isn't met — a Conductor should always be able to see that an action exists and why it isn't currently available, per the "no dead ends" principle (§2.2).

### 4.5 Cards

- Used for discrete, scannable records — a Ticket History entry, a Trip summary. A card always shows its own status indicator, never relying on position or surrounding context to convey state.

### 4.6 Lists

- Ticket History and any Route Stop selection list are simple, single-column, reverse-chronological (history) or route-ordered (stop selection) lists — no filtering, sorting, or search UI, since no upstream feature specifies one and the retention/volume this needs to support is a single Conductor's own recent activity, not a searchable archive.

### 4.7 Tables

- Not used in the Conductor-facing surface. Tabular, multi-column data belongs to the Operator Dashboard, out of this product's scope entirely (Product Specification §6).

### 4.8 Chips

- Used sparingly, for a Route Stop's own short label within the boarding/destination selection list, and for a Ticket's status label within History. Never used for multi-select, since no ETM screen requires multi-select.

### 4.9 Badges

- A small, fixed set of status badges (Captured / Buffered / Synced; Online / Offline / Recovering) applied consistently wherever a record or the Device's own state needs a compact status marker.

### 4.10 Progress Indicators

- A determinate indicator only where genuine progress is knowable (e.g., backlog drain count during Connectivity Recovery). An indeterminate spinner is never shown gating the ticketing flow's own confirmation, since capture confirmation must never wait on a network round-trip (§3).

### 4.11 Status Indicators

- The single most load-bearing design-system element in this product. Every status indicator (connectivity, sync, authorization, staleness) uses the same shape/color/icon grammar defined in §4.2 and §4.3, everywhere it appears, with no screen-specific variant.

### 4.12 Toasts

- Used for transient, non-blocking confirmations that don't require the Conductor's continued attention (e.g., "3 tickets synced"). Never used for a state the Conductor needs to act on — that always earns a persistent indicator or a full failure state instead.

### 4.13 Snackbars

- Used identically to toasts, with an optional single action (e.g., "View" linking to Ticket History) — never more than one action, and never used for a blocking condition.

### 4.14 Bottom Sheets

- Used for the Route Stop selection list within Boarding & Destination Selection, and for expanded status detail (tapping the status strip). A bottom sheet keeps the Conductor's place on the underlying screen, matching the "minimum interaction to revenue" principle (§2.2) — dismissing it returns exactly to where the Conductor was.

### 4.15 Modals

- Reserved for genuinely blocking conditions that require acknowledgement before any other action is possible — chiefly, the Device Revoked / Unauthorized state (§8.12). Never used for anything that could instead be a persistent status indicator or a toast; a modal is this product's strongest interruption and is spent accordingly.

---

## 5. Navigation Model

### 5.1 Application Entry

The ETM has exactly one entry point: opening the app. There is no login screen and no account picker, because the Device itself, not a Conductor credential, is what the platform authenticates (Feature Specification §5.1). The app always opens to the Splash screen (§8.1), which resolves directly into Device Initialization (§8.2) and then the Home Dashboard (§8.4) — never into a menu of destinations to choose from.

### 5.2 Primary Navigation

Primary navigation is a small, fixed, always-available set of destinations reachable from the Home Dashboard: **Trip Context, Ticket Issuance, Ticket History, Settings.** These four are exhaustive — every other screen in the Screen Catalog (§7) is reached *through* one of these, never as an independent, freestanding destination, because no sixth top-level concern exists in the upstream Feature Specification.

### 5.3 Secondary Navigation

Within a primary destination, navigation is linear and forward-only for the ticketing flow (Boarding & Destination Selection → Fare Confirmation → Ticket Confirmation), and simple back-navigation everywhere else (Ticket History, Settings). No screen in this product requires tabs, nested drawers, or a multi-level hierarchy.

### 5.4 Feature Transitions

Transitions follow the business sequence they represent, not an arbitrary screen order: Trip Context transitions into Ticket Issuance only once a Trip is actually resolved and started (Workflow Specification §8); Ticket Issuance transitions into Ticket Confirmation only once Durable Capture's write completes (Feature Specification §5.8) — never earlier, and never gated on a network response.

### 5.5 Back Navigation

Back navigation always returns to the immediately prior step, never resets the flow. An in-progress ticket sale (boarding selected, destination not yet chosen) is preserved if the Conductor backs out and returns, since interrupting a sale mid-flow (a passenger question, a second boarding) is a normal operational occurrence, not an error condition.

### 5.6 Authentication Flow

There is no Conductor-facing authentication flow. Device Identity & Authorization Awareness (Feature Specification §5.1) is entirely a Device-level, background concern; the only Conductor-visible consequence of it is the Device Initialization screen's own readiness state (§8.2) and, on denial, the Device Revoked / Unauthorized screen (§8.12).

### 5.7 Trip Flow

Home Dashboard → Trip Context (view current assignment and its lifecycle state) → Ticket Issuance (once the Trip is started). A Conductor cannot navigate directly into Ticket Issuance without the app first confirming a Trip is resolved and started — this is a navigational reflection of Ticket Issuance's own hard precondition (Feature Specification §5.6), not an independent design choice.

### 5.8 Ticketing Flow

Home Dashboard (or Trip Context) → Boarding & Destination Selection → Fare Confirmation → Ticket Confirmation → back to Home Dashboard or directly into a new Boarding & Destination Selection for the next sale. The flow is designed to loop back to its own start with a single tap, since issuing the next ticket immediately is the single most common next action a Conductor takes.

### 5.9 Settings Flow

Home Dashboard → Settings → (Battery Optimization Onboarding re-entry, Device Info). Settings is intentionally shallow — a short, flat list, not a nested preferences hierarchy, because the Feature Specification names exactly one Conductor-actionable setting-like capability (Battery Optimization Onboarding, §7.2) plus read-only device information.


---

## 6. Interaction Guidelines

### 6.1 Navigation Behaviour

Forward navigation always requires an explicit, intentional tap on a primary action — never an automatic transition the Conductor didn't trigger (with the single exception of Ticket Confirmation auto-returning after a brief, interruptible pause, §8.8). Every screen provides a visible way back or out, per the "no dead ends" principle (§2.2).

### 6.2 Touch Target Guidelines

Every interactive element meets or exceeds a large minimum touch target, sized for a thumb operating one-handed in a moving vehicle (§11) — well above typical platform-default minimums. Primary actions (Confirm, Issue Ticket) use the largest touch targets in the product. Adjacent interactive elements maintain generous spacing to prevent mis-taps during vehicle motion, which the Product Specification names directly as a real operating condition (§14).

### 6.3 Input Behaviour

The ticketing flow uses **selection, never free text entry** — boarding and destination are chosen from the Route Stop sequence (Feature Specification §5.4), never typed. This eliminates input-method switching (no keyboard ever appears during a sale), which is itself a speed and one-handed-operation requirement, not merely a convenience.

### 6.4 Form Behaviour

The ETM has no traditional multi-field form anywhere in the Conductor-facing surface — every "form" in this product is a sequence of single selections. Where the Feature Specification describes a "selection," this design renders it as a single-tap list or grid, never a form field.

### 6.5 Validation Behaviour

Validation is enforced **before** an action is offered, not after it's attempted — a Route Stop that isn't reachable from the current boarding point is never shown as selectable in the first place (Feature Specification §5.4, Validation Rules), rather than being selectable and then rejected. Where a precondition fails entirely (no Trip resolved, no Fare Rule resolvable), the primary action is disabled and the reason is stated in plain language at the point of the action, consistent with the Feature Specification's own rule that a missing precondition is refused entirely, never captured in a partial state (§5.6, Validation Rules).

### 6.6 Feedback Behaviour

Every action produces immediate, visible feedback — a selection highlights instantly; a confirmed capture transitions to the Ticket Confirmation screen the instant the durable write completes (§3). Feedback timing is calibrated to the underlying guarantee: capture feedback is instantaneous (local-write-bound); sync feedback is eventual and is represented as such, never accelerated cosmetically.

### 6.7 Loading States

A loading state is shown **only** where a real wait exists (e.g., Reference Context's first-ever resolution attempt on a brand-new Device). It is never shown for capture, which must never wait on the network (§3). Where a loading state is shown, it always distinguishes "resolving from the platform" from "reading from local cache" in its label, so a Conductor is never left wondering whether a wait implies a connectivity problem.

### 6.8 Success States

A success state states the specific business fact that succeeded (a fare amount, a boarding/destination pair) — never a generic "Success!" message — and always shows the record's current, honest status per Sync-Status & Reconciliation Honesty (§6.1 of the Feature Specification): Captured, Buffered, or Synced, never a stronger claim.

### 6.9 Error States

An error state names the specific unmet precondition (no Trip, no Conductor identity, no Fare Rule) rather than a generic failure message, and states the actual expected resolution path from the Workflow Specification — e.g., "This will resolve automatically once connectivity returns" versus "An Operator Admin needs to act" — never conflating the two, per Connectivity & Authorization Status Awareness's own distinction (Feature Specification §6.2).

### 6.10 Confirmation Patterns

A confirmation step exists only where the Feature Specification's own business flow includes a distinct fare-determination step before capture (§5.5 → §5.6) — the Fare Confirmation screen (§8.7) is this pattern's sole instance in the MVP ticketing flow. No confirmation dialog is shown for an action with no meaningful undo, since none of this product's MVP actions are destructive or reversible in the first place (a Ticket, once captured, is never edited or voided).

### 6.11 Empty States

Ticket History's empty state ("No tickets issued yet this session") is informational, never treated as an error — issuing the first ticket of a shift is the normal starting condition, not a fault.

### 6.12 Offline Indicators

A persistent, always-visible connectivity indicator distinguishes at minimum: **Online**, **Offline**, and **Recovering** (draining a backlog) — matching Connectivity & Authorization Status Awareness's own state vocabulary (Feature Specification §6.2). "Offline" is never styled as an error state (red/critical); it is styled as a caution/neutral state, since it is this product's normal, expected operating condition (§3), not a fault.

### 6.13 Synchronization Indicators

A distinct indicator, separate from the connectivity indicator, shows the current backlog's status (e.g., "3 pending") wherever a Conductor might reasonably ask "did my sales actually go through" — the Home Dashboard, Ticket History, and each individual Ticket Confirmation. It never claims "Reconciled" or any state stronger than "Synced," per Sync-Status & Reconciliation Honesty's own hard rule (Feature Specification §6.1, Business Rules).

### 6.14 Connectivity Behaviour

No interactive element in the ticketing flow is ever disabled because of connectivity state alone — only a genuinely unresolved precondition (no cached Trip, Fare Rule, or Conductor identity) disables an action, and that can occur with or without connectivity present (§3).

### 6.15 Notification Behaviour

The ETM issues no push notifications in the MVP scope — no upstream Feature names a notification capability, and the product's own principle that nothing should demand a Conductor's attention away from passengers (Product Specification §14) argues against introducing one without a specific business need.

### 6.16 Dialog Behaviour

Reserved for the single genuinely blocking condition in this product — Device Revoked / Unauthorized (§8.12) — and battery-optimization onboarding's own OS-level permission dialog, which is outside the ETM's own visual system entirely (an Android system dialog). No other screen in this product uses a blocking dialog.

### 6.17 Search Behaviour

Not applicable. No screen in the MVP Screen Catalog requires search — Route Stop lists are short and route-ordered, and Ticket History is a single Conductor's own recent activity, not a searchable archive (§4.6).


---

## 7. Screen Catalog

Every screen below is supported by a specific Core, Supporting, Operational, or Administrative Feature in the Functional Feature Specification. No screen exists here that isn't traceable to one.

| # | Screen | Primary Feature(s) Supported |
|---|---|---|
| 1 | Splash | Device Identity & Authorization Awareness (§5.1) |
| 2 | Device Initialization | Device Identity & Authorization Awareness (§5.1) |
| 3 | Battery Optimization Onboarding | Battery Optimization Onboarding (§7.2) |
| 4 | Home Dashboard | Shift Boundary Awareness (§8.1); Sync-Status & Reconciliation Honesty (§6.1); Connectivity & Authorization Status Awareness (§6.2) |
| 5 | Trip Context | Trip Assignment & Lifecycle Awareness (§5.3); Reference Context Resolution (§5.2) |
| 6 | Boarding & Destination Selection | Boarding & Destination Selection (§5.4) |
| 7 | Fare Confirmation | Fare Determination (§5.5) |
| 8 | Ticket Confirmation | Ticket Issuance (§5.6); Durable Capture (§5.8) |
| 9 | Ticket History | Locally Retained Ticket History (§6.3) |
| 10 | Sync & Connectivity Status (detail) | Sync-Status & Reconciliation Honesty (§6.1); Connectivity & Authorization Status Awareness (§6.2) |
| 11 | Settings | Battery Optimization Onboarding (§7.2); Diagnostic Observability (§9.2, device-info subset only) |
| 12 | Device Revoked / Unauthorized | Device Revocation Response (§7.4); Authentication Failure (Workflow Specification §16) |

**Deliberately excluded, and why:** Authentication (conductor-level login) — no Conductor credential exists anywhere in the platform (Domain Specification §3, Principle 4). Profile, Help & Support, Application Updates — none correspond to a real ETM capability (Feature Specification §15 item 14, §16). Passenger Category Selection — no supporting Domain concept exists (§15 item 6). A Diagnostics screen in the engineering sense — Diagnostic Observability is explicitly not Conductor-facing (§9.2); a minimal, plain-language device-info view is retained inside Settings instead, since it serves a real Conductor need (reporting a device to an Operator Admin) without pretending to be the engineering-facing diagnostics layer.

---

## 8. Individual Screen Specifications

### 8.1 Splash

**Purpose:** Bridge the moment between the Conductor opening the app and the app knowing enough about its own state to show something meaningful.

**Business Goal:** Establish presence instantly — the Conductor should never wonder whether the app has actually launched.

**Primary User:** Conductor.

**Entry Points:** App icon tap; app resumed from a fully-terminated state.

**Exit Points:** Automatically to Device Initialization (§8.2).

**Preconditions:** None — this is the app's own first frame.

**Information Displayed:** App identity only (name/mark). No status data is shown here, because none has been resolved yet.

**Primary Actions:** None — this screen is not interactive.

**Secondary Actions:** None.

**Validation Rules:** Not applicable.

**Offline Behaviour:** Identical with or without connectivity — this screen makes no network call of its own.

**Loading Behaviour:** Brief, fixed-feeling transition only; never gated on a network response, since Device Identity's own readiness check happens on the next screen, not this one.

**Success Behaviour:** Transitions automatically to Device Initialization.

**Failure Behaviour:** Not applicable — this screen cannot itself fail, since it performs no operation.

**Connectivity Behaviour:** No indicator shown yet — connectivity state isn't meaningfully known to the Conductor until Device Initialization begins resolving it.

**Synchronization Behaviour:** Not applicable.

**Related Features:** Device Identity & Authorization Awareness (§5.1), as the screen this flow leads into.

**Related Workflows:** Device Ready (Workflow Specification §5), steps prior to step 1.

**Acceptance Criteria:**
- ✓ The Splash screen never blocks on, or waits for, any network call.
- ✓ The transition to Device Initialization is automatic, requiring no Conductor action.

---

### 8.2 Device Initialization

**Purpose:** Establish and represent the Device's own readiness — authenticated, aware of its pairing, able to report Telemetry and, once context resolves, issue Tickets (Feature Specification §5.1).

**Business Goal:** Get the Conductor into a working state as fast as possible, with no login step that doesn't exist in this platform, while representing honestly whatever isn't yet resolved.

**Primary User:** Conductor.

**Entry Points:** Automatically from Splash (§8.1).

**Exit Points:** To Home Dashboard (§8.4) once the Device is Ready; to Device Revoked / Unauthorized (§8.12) on a denied authentication.

**Preconditions:** The Device has already been provisioned and registered to a Bus by an Operator Admin — a prerequisite entirely outside this screen (Workflow Specification §5).

**Information Displayed:** Device readiness state, broken into its two separable facts (Feature Specification §5.1, Business Rules): Telemetry readiness (near-instant) and Reference Context readiness (Trip/Conductor resolution, which may still be in progress or may fail to resolve with no connectivity). If Reference Context hasn't resolved, this is stated plainly, not hidden behind a generic "Loading."

**Primary Actions:** "Continue" — enabled the instant Telemetry readiness is established, since Ticketing readiness is not a precondition for entering the app (Feature Specification §5.1, Performance Expectations).

**Secondary Actions:** None.

**Validation Rules:** None Conductor-facing — all validation here is the platform's own authentication and authorization determination, which the ETM cannot second-guess (§5.1, Validation Rules).

**Offline Behaviour:** Fully operable — the Device proceeds into a degraded-but-operable state using its last-known pairing and context rather than blocking the Conductor from starting work (Workflow Specification §5, Alternative Flow). If this is the Device's first-ever launch with no prior cached context and no connectivity, Telemetry readiness still succeeds, but the screen states plainly that Ticketing isn't yet available.

**Loading Behaviour:** A brief, labelled wait while Device authentication resolves; distinguished clearly from Reference Context resolution, which may take longer or may not complete at all in this session.

**Success Behaviour:** Transitions to Home Dashboard.

**Failure Behaviour:** The platform denies authentication outright — transitions to Device Revoked / Unauthorized (§8.12), since the ETM cannot distinguish "wrong credential" from "no longer authorized" from "platform temporarily unable to verify" (§5.1, Failure Behaviour) and must represent all three identically and honestly as "cannot currently operate this Device."

**Connectivity Behaviour:** A connectivity indicator appears here for the first time, reflecting whatever the Device can currently establish.

**Synchronization Behaviour:** Not applicable — nothing has been captured yet.

**Related Features:** Device Identity & Authorization Awareness (§5.1); Reference Context Resolution (§5.2).

**Related Workflows:** Device Ready (Workflow Specification §5).

**Acceptance Criteria:**
- ✓ A Device with connectivity and valid prior pairing reaches Home Dashboard without any Conductor-entered credential.
- ✓ A Device with zero connectivity at launch still reaches Home Dashboard, using last-known pairing, per the Alternative Flow.
- ✓ Telemetry readiness is never blocked on Reference Context resolution completing.
- ✓ A denied authentication is represented distinctly from an ordinary connectivity gap wherever the underlying signal supports the distinction (§6.2 of the Feature Specification).

---

### 8.3 Battery Optimization Onboarding

**Purpose:** Guide the Conductor (or Operator Admin, at provisioning time) toward exempting the ETM from aggressive OEM battery management — an improvement, never a precondition, for Background Execution & Device Lifecycle Management (Feature Specification §7.2).

**Business Goal:** Reduce, at the point of greatest leverage, the platform's single highest-ranked risk — OEM background-execution killing (Product Specification §17).

**Primary User:** Conductor or Operator Admin, whoever completes device setup.

**Entry Points:** First app launch (offered once, automatically, after Device Initialization succeeds); re-entry from Settings (§8.11) at any later point.

**Exit Points:** To Home Dashboard (first-run) or back to Settings (re-entry); "Skip" is always available and exits identically.

**Preconditions:** The Device is provisioned and has completed Device Initialization (§8.2).

**Information Displayed:** A plain-language explanation of why this matters (uninterrupted ticketing and location reporting through a full shift), and whether the Device's current OS-level configuration already permits background execution.

**Primary Actions:** "Open Battery Settings" — hands off to the Android OS's own settings surface, outside this product's visual system.

**Secondary Actions:** "Skip" / "Remind me later" (via Settings re-entry) — always available, since declining never gates any ETM capability (§7.2, Business Rules).

**Validation Rules:** Not applicable — no business validation occurs on this screen.

**Offline Behaviour:** Fully available — a local, on-device settings interaction with no network dependency (§7.2, Offline Behaviour).

**Loading Behaviour:** None distinct — this is a static, informational screen until the Conductor acts.

**Success Behaviour:** Returns to the ETM with the exemption granted; the screen reflects the updated OS state if re-visited.

**Failure Behaviour:** The OS may not expose an exemption path on some device models — this is a named, genuine limitation the screen states honestly rather than implying a fix exists (§7.2, Failure Behaviour).

**Connectivity Behaviour:** Not applicable — no network dependency.

**Synchronization Behaviour:** Not applicable.

**Related Features:** Battery Optimization Onboarding (§7.2); Background Execution & Device Lifecycle Management (§7.1).

**Related Workflows:** Device Ready (Workflow Specification §5), as a natural point this onboarding would occur.

**Acceptance Criteria:**
- ✓ This screen can be completed, skipped, or revisited with zero connectivity.
- ✓ Declining or being unable to complete it never blocks Ticket Issuance or Telemetry Origination.
- ✓ The screen never implies the exemption is guaranteed to succeed or is a required step.


---

### 8.4 Home Dashboard

**Purpose:** The Conductor's single anchor screen — a glance answers "where am I in my Trip, is everything synced, and how do I sell a ticket right now."

**Business Goal:** Minimize time-to-action for the product's most frequent Conductor need (issuing a ticket) while giving Shift Boundary Awareness (§8.1 of the Feature Specification) a real, Conductor-experienced home despite having no backend representation.

**Primary User:** Conductor.

**Entry Points:** Automatically from Device Initialization on success (§8.2); back-navigation from Trip Context, Ticket History, Settings, or after a Ticket Confirmation auto-returns.

**Exit Points:** To Trip Context (§8.5); to Boarding & Destination Selection (§8.6, only once a Trip is started); to Ticket History (§8.9); to Settings (§8.11); to Sync & Connectivity Status detail (§8.10) via the status strip.

**Preconditions:** The Device is Ready (§5.1 of the Feature Specification).

**Information Displayed:** Persistent status strip (connectivity, sync backlog count, authorization state, per §6.12–§6.13); current Trip's headline state if one is resolved (assigned / not yet started / actively running / none currently assigned); a lightweight Shift framing ("Shift in progress" since [time]) — explicitly a Conductor-experienced, ETM-local concept only, never implying a corresponding backend record exists, per Shift Boundary Awareness's own open question (Feature Specification §8.1, Open Questions).

**Primary Actions:** "Issue Ticket" — the single most prominent element on the screen, enabled only once a Trip is assigned and started and Conductor identity is resolvable; disabled with a plain-language reason otherwise (per §6.5).

**Secondary Actions:** "View Trip," "Ticket History," "Settings," "End Shift" (a purely local, ETM-side framing action — see Business Rules).

**Validation Rules:** "Issue Ticket" requires a started Trip, a resolvable Conductor identity, and a resolvable Fare Rule set for the Trip's Route — checked against cached context, exactly mirroring Ticket Issuance's own hard preconditions (Feature Specification §5.6).

**Offline Behaviour:** Fully operable — every element on this screen reflects last-known cached state and never blocks on a live call (§8.1 of the Feature Specification, Offline Behaviour). "Issue Ticket" remains enabled offline provided Trip, Conductor, and Fare Rule context were previously cached.

**Loading Behaviour:** None beyond an initial, brief population from cache; this screen does not show a loading spinner in ordinary use.

**Success Behaviour:** Not applicable in isolation — success is expressed through the sub-flows this screen launches.

**Failure Behaviour:** If no Trip has ever resolved and no connectivity is available, "Issue Ticket" is disabled with the plain-language reason "Waiting for trip assignment" — never a generic error.

**Connectivity Behaviour:** The persistent status strip is this screen's connectivity surface; tapping it opens Sync & Connectivity Status detail (§8.10).

**Synchronization Behaviour:** A backlog count ("3 pending") is always visible when non-zero; it clears to a neutral "All synced" state once the backlog drains, using Sync-Status & Reconciliation Honesty's own vocabulary (Feature Specification §6.1) — never "Reconciled."

**Related Features:** Shift Boundary Awareness (§8.1); Sync-Status & Reconciliation Honesty (§6.1); Connectivity & Authorization Status Awareness (§6.2); Trip Assignment & Lifecycle Awareness (§5.3).

**Related Workflows:** Shift Start (Workflow Specification §6); Shift Completion (§14).

**Acceptance Criteria:**
- ✓ "Issue Ticket" is reachable in one tap from this screen whenever its precondition is met.
- ✓ The screen never implies a backend-recognized "shift" exists — its own framing is explicitly local (per Feature Specification §8.1's own Open Questions).
- ✓ Every status element reflects cached state with zero connectivity.
- ✓ "End Shift" never unassigns the Conductor from the Device or affects Telemetry origination, matching Shift Completion's own Business Rules (Workflow Specification §14).

---

### 8.5 Trip Context

**Purpose:** Show the Conductor which specific Trip they are currently operating against, and that Trip's own lifecycle state, honestly reflecting whatever staleness the cached data may carry.

**Business Goal:** Anchor every subsequent sale to a real, accountable operational run, and give the Conductor visibility into a resolution process they otherwise take no direct action in (Trip Assignment is exclusively an Operator Admin action; Feature Specification §5.3).

**Primary User:** Conductor.

**Entry Points:** From Home Dashboard.

**Exit Points:** Back to Home Dashboard; forward to Boarding & Destination Selection once the Trip is confirmed started.

**Preconditions:** Device Identity is established (§5.1).

**Information Displayed:** Route name and direction; current lifecycle state (scheduled / actively running / completed / none currently assigned); the age of the last successful resolution ("last confirmed 6 minutes ago"), since no staleness bound is defined upstream and this document does not invent one — it surfaces the raw fact instead (Feature Specification §5.2, Open Questions).

**Primary Actions:** "Start Selling Tickets" — enabled only once the Trip's lifecycle state is actively running (Workflow Specification §8); this button is this screen's bridge into the ticketing flow.

**Secondary Actions:** Manual "Refresh" — attempts an opportunistic re-resolution if connectivity allows; never required for the screen to function, since resolution is already continuous and opportunistic in the background (Feature Specification §5.2, Trigger).

**Validation Rules:** None Conductor-facing — Trip lifecycle transitions are exclusively an Operator Admin, platform-side determination this screen only ever reads (§5.3, Business Rules).

**Offline Behaviour:** Fully operable against the last-resolved assignment (§5.2, Offline Behaviour: "Partially — the last-known snapshot remains usable; a fresh read is not"). If the Device has never resolved a Trip at all, this is stated distinctly from "the cache is merely aging," per the Feature Specification's own distinction between these two conditions (§5.2, Alternative Behaviour).

**Loading Behaviour:** A labelled "Resolving trip..." state only on a genuine first-ever resolution attempt; never shown for an ordinary background refresh of already-cached data.

**Success Behaviour:** The screen updates in place the moment a fresher resolution succeeds, with no manual reload required.

**Failure Behaviour:** No Trip has ever been resolved and no connectivity exists — the screen states this plainly ("No trip assigned yet — this will resolve once you're connected") rather than showing an empty or broken-looking state.

**Connectivity Behaviour:** Reflects the persistent status strip; additionally shows the specific staleness age for this screen's own Trip data.

**Synchronization Behaviour:** Not applicable — this screen displays read-only Reference Context, not Ticket/Telemetry sync state.

**Related Features:** Trip Assignment & Lifecycle Awareness (§5.3); Reference Context Resolution (§5.2).

**Related Workflows:** Trip Assignment (Workflow Specification §7); Trip Start (§8); Trip Completion (§13).

**Acceptance Criteria:**
- ✓ "Start Selling Tickets" is enabled if and only if the cached Trip lifecycle state is actively running.
- ✓ A stale cached value is never presented as fresh — the last-resolved age is always visible.
- ✓ A genuine first-resolution gap is distinguished from ordinary staleness in the screen's own messaging.


---

### 8.6 Boarding & Destination Selection

**Purpose:** Let the Conductor identify a passenger's boarding and destination points along the current Trip's Route — the single, atomic first step of every ticket sale (Feature Specification §5.4).

**Business Goal:** Turn "where did this passenger get on and off" into a structured, fare-computable fact in the fewest possible taps — this is the screen Design Goal 1 (§2.1) is written for most directly.

**Primary User:** Conductor.

**Entry Points:** "Issue Ticket" from Home Dashboard; "Start Selling Tickets" from Trip Context; the loop-back action from a completed Ticket Confirmation (§8.8).

**Exit Points:** Forward to Fare Confirmation (§8.7) once both points are selected; back to the entry screen if the Conductor cancels mid-selection.

**Preconditions:** A Trip is resolved and started (§5.3); Route Stop data for that Trip's Route is cached (§5.4).

**Information Displayed:** The current Trip's Route Stop sequence, in route order, as a single scrollable list; the currently-selected boarding point, once chosen, pinned or highlighted while the destination list narrows to only stops reachable from it.

**Primary Actions:** Tap a stop to select boarding; then tap a stop to select destination — two sequential single-tap selections, never a form.

**Secondary Actions:** "Cancel" — discards the in-progress selection and returns to the entry point; back navigation preserves an in-progress selection if the Conductor is only briefly interrupted (§5.5).

**Validation Rules:** A destination not reachable from the selected boarding point on the cached sequence is never shown as selectable in the first place (§5.4, Validation Rules) — invalid selections are prevented, not rejected after the fact, per §6.5.

**Offline Behaviour:** Fully operable — selection runs entirely against cached Route Stop data with no live call made (§5.4, Offline Behaviour). A reorder or removal made upstream while disconnected will not be reflected until reconnection — a named, accepted risk (Domain Specification §5.7) this screen does not attempt to mask.

**Loading Behaviour:** None in the ordinary case — this is a cached-data, local operation. If no cached Route Stop sequence exists at all for the current Trip's Route (a genuine first-resolution gap), the screen shows this plainly instead of an empty list.

**Success Behaviour:** The instant both points are selected, the screen transitions automatically to Fare Confirmation — no separate "Next" tap required, minimizing interaction count per Design Goal 1.

**Failure Behaviour:** No cached Route Stop sequence exists for the current Trip's Route — the sale cannot proceed; the screen states this and returns the Conductor to Trip Context, since selection cannot begin at all (§5.4, Failure Behaviour).

**Connectivity Behaviour:** The persistent status strip remains visible but never gates any interaction on this screen — selection behaves identically online or offline (§3).

**Synchronization Behaviour:** Not applicable — nothing is captured yet at this step.

**Related Features:** Boarding & Destination Selection (§5.4); Reference Context Resolution (§5.2).

**Related Workflows:** Ticket Issuance (Workflow Specification §9, step 1).

**Acceptance Criteria:**
- ✓ A boarding/destination pair can be selected with zero connectivity, provided a Route Stop sequence was ever previously cached.
- ✓ An internally inconsistent pair is never offered as a selectable option.
- ✓ Selection triggers no live network call.
- ✓ Completing selection transitions automatically into Fare Confirmation with no extra tap.

---

### 8.7 Fare Confirmation

**Purpose:** Show the computed fare for the selected boarding/destination pair and let the Conductor confirm the sale — the point at which a fare is permanently fixed to the Ticket (Feature Specification §5.5).

**Business Goal:** Protect operator revenue integrity by making the fare visible and confirmed before capture, while keeping this the only confirmation step in the entire ticketing flow (§6.10).

**Primary User:** Conductor.

**Entry Points:** Automatically from Boarding & Destination Selection, once both points are chosen.

**Exit Points:** Forward to Ticket Confirmation (§8.8) on confirm; back to Boarding & Destination Selection if the Conductor cancels.

**Preconditions:** A valid boarding/destination pair is selected (§5.4); a Fare Rule applicable to that pair is resolvable, live or cached (§5.5).

**Information Displayed:** The selected boarding and destination points; the computed fare amount, shown as the single largest element on the screen per §4.1; the Trip and Route this sale belongs to, for the Conductor's own confirmation at a glance.

**Primary Actions:** "Confirm Sale" — the single primary action; captures the Ticket the instant it's tapped.

**Secondary Actions:** "Cancel" — discards the selection and returns to Boarding & Destination Selection with no record created.

**Validation Rules:** If no Fare Rule can be resolved for the selected segment, "Confirm Sale" is never offered as an enabled action — the sale is refused before this screen can be reached in a confirmable state, per Fare Determination's own rule to refuse rather than guess a fare (Feature Specification §5.5, Validation Rules).

**Offline Behaviour:** Fully operable — computation uses only cached Fare Rule data with no live call (§5.5, Offline Behaviour). A Fare Rule superseded upstream while disconnected won't be reflected until reconnection; this is a named, accepted cost, not a defect (§5.5, Open Questions) — this screen does not attempt to signal a false confidence about the fare's currency beyond what's actually known.

**Loading Behaviour:** None — fare computation is local and instantaneous (§5.5, Performance Expectations).

**Success Behaviour:** Tapping "Confirm Sale" transitions immediately to Ticket Confirmation the moment the durable local write completes — never gated on a network round-trip (§3).

**Failure Behaviour:** Not reachable in a state where the fare can't be shown, per Validation Rules above — this screen has no distinct in-place failure state of its own beyond that upstream refusal.

**Connectivity Behaviour:** The persistent status strip remains visible but never gates "Confirm Sale."

**Synchronization Behaviour:** Not applicable — synchronization begins only after capture, on the next screen.

**Related Features:** Fare Determination (§5.5); Ticket Issuance (§5.6).

**Related Workflows:** Ticket Issuance (Workflow Specification §9, step 2).

**Acceptance Criteria:**
- ✓ A fare is computed and shown with zero connectivity, provided a Fare Rule was ever previously cached for the segment.
- ✓ "Confirm Sale" produces capture confirmation instantly, never waiting on a network response.
- ✓ A later Fare Rule change never alters an already-confirmed Ticket's fare.


---

### 8.8 Ticket Confirmation

**Purpose:** Confirm, honestly and immediately, that the sale was captured — the Conductor's proof of a completed transaction, independent of whether it has yet reached the platform.

**Business Goal:** Deliver Product Objective 3 directly: a Conductor always has an honest answer to "did my sale go through" (Product Specification §11) — starting from the very first moment that answer exists.

**Primary User:** Conductor.

**Entry Points:** Automatically from Fare Confirmation, the instant the durable write completes.

**Exit Points:** Automatically back to Home Dashboard after a brief, interruptible pause; or directly into a new Boarding & Destination Selection via "Sell Another."

**Preconditions:** A Ticket has just been durably captured (§5.8).

**Information Displayed:** The captured Ticket's business facts — boarding/destination, fare, Trip — and its current lifecycle status using Sync-Status & Reconciliation Honesty's own three-state vocabulary: **Captured** (written locally, not yet queued), **Buffered** (queued for transmission), or **Synced** (platform has acknowledged receipt) — never "Reconciled," which the ETM cannot observe (Feature Specification §6.1, Business Rules).

**Primary Actions:** "Sell Another" — the dominant action, since issuing the next ticket is this screen's single most likely next step, matching §5.8's own navigation design.

**Secondary Actions:** "Done" / implicit auto-return to Home Dashboard.

**Validation Rules:** Not applicable — this is a read-only confirmation of an already-completed capture.

**Offline Behaviour:** Fully available — capture confirmation is available the instant the durable write completes, entirely independent of network state (§5.6, Main Behaviour step 4). With zero connectivity, the status shown is simply "Captured," honestly, never a placeholder implying sync is imminent.

**Loading Behaviour:** None — by the time this screen appears, capture has already completed; there is nothing left to wait for on this screen itself.

**Success Behaviour:** The status label updates in place, live, if the Ticket's state advances (Captured → Buffered → Synced) while the Conductor is still looking at this screen — a genuine, visible confidence-building moment when connectivity is present.

**Failure Behaviour:** Not applicable to the capture act itself, since this screen is only ever reached after a successful durable write (§5.6, Failure Behaviour lists the failure cases that prevent reaching this screen at all, not a failure within it).

**Connectivity Behaviour:** The persistent status strip remains visible; this screen's own status label is a per-record instance of the same vocabulary, never a stronger or weaker claim than the strip's own aggregate state.

**Synchronization Behaviour:** This screen is the first place a Conductor sees an individual record's synchronization journey begin; it never claims a stronger state than what Synchronization & Connectivity Recovery (§5.9) has actually achieved.

**Related Features:** Ticket Issuance (§5.6); Durable Capture (§5.8); Sync-Status & Reconciliation Honesty (§6.1).

**Related Workflows:** Ticket Issuance (Workflow Specification §9).

**Acceptance Criteria:**
- ✓ This screen appears the instant the durable write completes, never gated on network state.
- ✓ The displayed status never exceeds "Synced," and is "Captured" honestly when offline.
- ✓ "Sell Another" reaches Boarding & Destination Selection in a single tap.

---

### 8.9 Ticket History

**Purpose:** Let a Conductor self-serve a basic "what have I sold" answer for their own recent activity, without contacting an Operator Admin (Feature Specification §6.3).

**Business Goal:** Give partial reassurance beyond the per-Ticket sync-status signal, for a Conductor reviewing their own shift.

**Primary User:** Conductor.

**Entry Points:** From Home Dashboard.

**Exit Points:** Back to Home Dashboard; tapping an individual entry may expand it in place to show its full status detail — never a separate edit or void action, since a Ticket, once captured, is never modified (§6.3, Business Rules).

**Preconditions:** At least one Ticket has been captured during the current retention window (§6.3, Preconditions).

**Information Displayed:** A reverse-chronological list of the Conductor's own recently issued Tickets, each showing Trip, boarding/destination, fare, timestamp, and current sync status using the identical three-state vocabulary as Ticket Confirmation (§8.8) — consistency per §2.8.

**Primary Actions:** None — this is a read-only view; there is no capture or correction action anywhere on this screen (§6.3, Business Rules: "never permits editing, voiding, or otherwise mutating a listed Ticket").

**Secondary Actions:** Tap an entry to expand its own status detail.

**Validation Rules:** Not applicable — a read-only view over already-validated, already-captured records.

**Offline Behaviour:** Fully available — reads only already-durable local data, with no network dependency (§6.3, Offline Behaviour).

**Loading Behaviour:** None — this is a local-storage read, not a network call.

**Success Behaviour:** Not applicable beyond the list rendering correctly.

**Failure Behaviour:** Empty state ("No tickets issued yet this session") shown when no Tickets exist yet — informational, not an error (§6.11).

**Connectivity Behaviour:** Reflects the persistent status strip; individual entries update their own sync status live if it advances while the screen is open.

**Synchronization Behaviour:** No listed Ticket ever displays a status beyond what Sync-Status & Reconciliation Honesty (§6.1) can honestly support, mirroring §8.8's own rule exactly.

**Related Features:** Locally Retained Ticket History (§6.3); Sync-Status & Reconciliation Honesty (§6.1); Durable Capture (§5.8).

**Related Workflows:** Ticket Issuance (Workflow Specification §9); Shift Completion (§14), as a natural point a Conductor might review this history.

**Acceptance Criteria:**
- ✓ A Conductor can view their own recently issued Tickets with zero connectivity.
- ✓ No listed Ticket ever displays a status beyond "Synced."
- ✓ No control on this screen permits mutating a listed Ticket.


---

### 8.10 Sync & Connectivity Status (Detail)

**Purpose:** Give a Conductor who taps the persistent status strip a fuller, still-honest picture of what's currently happening — the expanded view behind the always-visible summary.

**Business Goal:** Serve Product Objective 3 with the same honesty discipline as every other status surface, at the level of detail a Conductor reasonably wants when they deliberately ask for it.

**Primary User:** Conductor.

**Entry Points:** Tapping the persistent status strip from any screen it appears on.

**Exit Points:** Dismiss (bottom sheet, per §4.14) returns exactly to the underlying screen and its exact prior state.

**Preconditions:** None.

**Information Displayed:** Connectivity state (Online / Offline / Recovering, per §6.2 of the Feature Specification); authorization state, represented as its own distinct value — authorized / denied / unknown-pending-verification — never conflated with connectivity (§6.2, Main Behaviour); current backlog counts for Tickets and Telemetry Pings, shown independently since neither is prioritized over the other (§5.9, Business Rules); the age of the last successful Reference Context resolution.

**Primary Actions:** None required — this is primarily an informational surface. A manual "Retry now" affordance may be offered where connectivity appears present but a session hasn't yet been confirmed, purely as a Conductor-initiated nudge, never as something the underlying mechanism actually depends on (Synchronization proceeds automatically regardless; §5.9, Recovery behaviour).

**Secondary Actions:** Dismiss.

**Validation Rules:** Not applicable — pure observation, no business validation (§6.2, Validation Rules).

**Offline Behaviour:** Fully available — this screen's entire purpose is to represent the offline condition itself (§6.2, Offline Behaviour).

**Loading Behaviour:** None — reflects already-observed local signals.

**Success Behaviour:** Updates live the instant any underlying signal changes, with no manual refresh required (§6.2, Main Behaviour).

**Failure Behaviour:** Where the underlying platform signal genuinely cannot distinguish "not authorized" from "no connectivity," this screen states that ambiguity honestly (e.g., "Unable to confirm — check connectivity or contact your operator") rather than guessing which one it is — a named, accepted limitation, not resolved by this design (System Architecture §23 item 2).

**Connectivity Behaviour:** This screen *is* the connectivity behaviour surface.

**Synchronization Behaviour:** Shows Ticket and Telemetry backlog counts as two independent figures, never merged into one number, since neither event type is prioritized over the other (§5.9, Business Rules).

**Related Features:** Sync-Status & Reconciliation Honesty (§6.1); Connectivity & Authorization Status Awareness (§6.2); Synchronization & Connectivity Recovery (§5.9).

**Related Workflows:** Offline Operations (Workflow Specification §11); Connectivity Recovery (§12).

**Acceptance Criteria:**
- ✓ Authorization and connectivity are always represented as two distinct signals, never merged into one.
- ✓ "Unknown, pending verification" is shown as its own genuine state during a connectivity gap — never silently treated as "still authorized."
- ✓ Ticket and Telemetry backlog counts are always shown independently.

---

### 8.11 Settings

**Purpose:** Host the small, fixed set of Conductor-actionable configuration this product actually has — deliberately shallow, per §5.9.

**Business Goal:** Give the Conductor a single, predictable place to revisit Battery Optimization Onboarding and view basic device information, without implying a broader preferences surface no upstream feature supports.

**Primary User:** Conductor (occasionally, Operator Admin at provisioning time).

**Entry Points:** From Home Dashboard.

**Exit Points:** Back to Home Dashboard; forward into Battery Optimization Onboarding (§8.3) re-entry.

**Preconditions:** None.

**Information Displayed:** A short, flat list: "Battery Optimization" (with current exemption status shown plainly), and "Device Info" (Device identity's own non-sensitive facts — app version, last successful sync time, last successful Reference Context resolution time), included here because it serves a real, narrow Conductor need — describing the Device accurately to an Operator Admin — without duplicating the engineering-facing Diagnostic Observability feature (§9.2), which remains explicitly not Conductor-facing.

**Primary Actions:** Tap "Battery Optimization" to re-enter §8.3.

**Secondary Actions:** None beyond back navigation.

**Validation Rules:** Not applicable.

**Offline Behaviour:** Fully available — every element here reads local, already-known state (§7.2, Offline Behaviour, extended to Device Info's own local facts).

**Loading Behaviour:** None.

**Success Behaviour:** Not applicable beyond correct rendering.

**Failure Behaviour:** Not applicable — this screen has no operation of its own that can fail.

**Connectivity Behaviour:** The persistent status strip remains visible but has no special role on this screen.

**Synchronization Behaviour:** Not applicable.

**Related Features:** Battery Optimization Onboarding (§7.2); Device Identity & Authorization Awareness (§5.1, for the Device Info subset).

**Related Workflows:** Device Ready (Workflow Specification §5).

**Acceptance Criteria:**
- ✓ Every element on this screen is available with zero connectivity.
- ✓ This screen never grows beyond the two entries named above without a corresponding new upstream Feature justifying it — no speculative "Profile" or "Help" entry appears here.

---

### 8.12 Device Revoked / Unauthorized

**Purpose:** Represent, honestly and without ambiguity where possible, that the Device can no longer operate — the Conductor-facing consequence of Device Revocation Response (§7.4) or an unresolved Authentication Failure (Workflow Specification §16).

**Business Goal:** Bound the damage of a lost or stolen Device by making the state unmistakable, while protecting whatever data the Conductor had already legitimately captured — that data is neither deleted nor exposed elsewhere (§7.4, Business Rules).

**Primary User:** Conductor (experiences the consequence; cannot resolve it themselves).

**Entry Points:** From Device Initialization on a denied authentication (§8.2); from any screen, at any point, the instant a revocation is recognized on a live session (Workflow Specification §15, Business Rules: revocation is valid from any operational status, including mid-Trip).

**Exit Points:** None self-service — this screen has no "retry" action that resolves the underlying condition, since the Conductor cannot resolve it themselves (§7.4, Offline Behaviour: "The Conductor cannot resolve this state themselves by retrying or waiting"). The screen automatically clears only if the platform's own state changes (e.g., an Operator Admin restores the Device).

**Preconditions:** The platform has denied or withdrawn this Device's authorization.

**Information Displayed:** A plain statement that this Device cannot currently operate, and — honestly, per the Feature Specification's own named limitation — that the ETM cannot always distinguish "not authorized" from "connectivity is simply unavailable," so the message states what's actually knowable rather than guessing (§5.1, Failure Behaviour; Workflow Specification §16, Open Questions). Where the underlying signal does support the distinction, the more specific message is shown. A reassurance, stated plainly, that any tickets or location data already captured on this Device remain safely stored and are not lost (§7.4, Business Rules).

**Primary Actions:** None that resolve the state — this is a blocking, informational modal-equivalent (§4.15), not an actionable failure.

**Secondary Actions:** None beyond a general "Contact your operator" instruction, since the honest next step is most commonly an Operator Admin action (Workflow Specification §16, Expected Outcome).

**Validation Rules:** Not applicable — this state is entirely platform-determined; the ETM performs no local logic that decides it is authorized (§7.4, Validation Rules).

**Offline Behaviour:** A Device already offline at the moment of revocation continues capturing (never syncing) until its next connection attempt, at which point revocation takes full effect (§7.4, Alternative Behaviour) — this screen only appears once that recognition actually occurs, never speculatively.

**Loading Behaviour:** None — this is a static, blocking state until the underlying condition changes.

**Success Behaviour:** Not applicable to this screen directly — "success" here is the platform restoring the Device's status, at which point the app resumes into Home Dashboard automatically on its next successful verification.

**Failure Behaviour:** This screen *is* the failure state being represented; it has no further failure mode of its own.

**Connectivity Behaviour:** The persistent status strip is superseded by this screen's own blocking message while active, since authorization denial takes precedence over an ordinary connectivity read (§6.2, Business Rules: fail-closed is never relaxed by a reliability concern).

**Synchronization Behaviour:** Explicitly halted — Synchronization & Connectivity Recovery and Reference Context Resolution both stop attempting new outbound activity the moment this state is recognized (§7.4, Main Behaviour), and this screen states that plainly rather than showing a spinner that implies an attempt is still in progress.

**Related Features:** Device Revocation Response (§7.4); Device Identity & Authorization Awareness (§5.1); Fail-Closed Authorization Enforcement (§9.1).

**Related Workflows:** Device Revocation (Workflow Specification §15); Authentication Failure (§16).

**Acceptance Criteria:**
- ✓ This screen appears the moment a denial is recognized, from any prior screen, with no unbounded grace period.
- ✓ Already-captured data is stated as safe and is neither deleted nor exposed while this screen is active.
- ✓ No control on this screen implies a self-service resolution that doesn't exist.
- ✓ Where the underlying signal cannot distinguish "not authorized" from "no connectivity," the message says so honestly rather than picking one.


---

## 9. User Journey

```
Device Ready
   │  (Splash → Device Initialization, §8.1–§8.2 — no login, Device-level only)
   ▼
Authentication
   │  (Device-level, background; Conductor-visible only as readiness or denial)
   ▼
Reference Data Ready
   │  (Reference Context Resolution continues opportunistically in the background,
   │   independent of any Conductor action — Feature Specification §5.2)
   ▼
Shift
   │  (Home Dashboard, §8.4 — a Conductor-experienced framing only; no backend event)
   ▼
Trip
   │  (Trip Context, §8.5 — Conductor views assignment and lifecycle state)
   ▼
Ticketing
   │  (Boarding & Destination Selection §8.6 → Fare Confirmation §8.7 →
   │   Ticket Confirmation §8.8 — repeats for every sale, looping directly
   │   back into §8.6 via "Sell Another")
   ▼
Synchronization
   │  (Continuous, background, from the moment of capture onward — visible via
   │   the persistent status strip and Sync & Connectivity Status detail, §8.10,
   │   never gating the Conductor's next action)
   ▼
Trip Completion
   │  (Operator Admin action; Conductor experiences this only as Trip Context's
   │   own lifecycle state changing to "completed" — no Conductor-initiated step)
   ▼
Shift End
   │  ("End Shift" on Home Dashboard, §8.4 — again, purely local framing;
   │   Telemetry origination and the Device's own operation continue
   │   unaffected, per Shift Completion's own Business Rules)
```

**Major user interactions**, in the order a Conductor actually experiences them across a working day:

1. **Open the app.** No credential entry — the Device's own identity carries the Conductor straight through to a working state, degraded-but-operable even with zero connectivity at launch.
2. **Glance at the status strip.** Before doing anything else, a Conductor can register connectivity, sync backlog, and authorization state at a glance, from any screen, without navigating anywhere.
3. **Confirm the Trip.** A quick check of Trip Context to see the assignment is correct and started — usually once per Trip, not once per sale.
4. **Sell tickets, repeatedly.** The dominant, highest-frequency interaction: select boarding, select destination, confirm fare, see confirmation, sell another. This loop is designed to require the fewest possible taps and zero typing.
5. **Occasionally check history.** A Conductor reviews Ticket History when they want reassurance about the shift so far — not a required step in any individual sale.
6. **Occasionally check sync detail.** Tapping the status strip when a Conductor genuinely wants more than the glance-level summary — most commonly after a period offline, wanting to confirm the backlog is draining.
7. **End the shift.** A simple, local acknowledgement that the Conductor's own working period is over — never a step that affects the Device's continued Telemetry origination or the backlog's continued draining.

Handoff between two Conductors on the same Device — a real, expected occurrence (Product Specification §16) — is not a distinct step in this journey because no screen in this design gates on "which Conductor is this." A relief Conductor experiences the identical journey above, starting fresh from whatever the Device's currently-cached Conductor pairing happens to be, with the misattribution risk this creates surfaced honestly wherever Conductor identity is displayed (§8.4, §8.9), never silently hidden.

---

## 10. Accessibility Guidelines

- **Touch targets** meet or exceed a large minimum size everywhere in the app, sized for one-handed, thumb-only operation in a moving vehicle — not merely platform-default minimums (§6.2).
- **Color is never the sole carrier of meaning.** Every status color pairing (§4.2) is backed by an icon and a text label; a Conductor with color-vision deficiency, or reading the screen in harsh glare where color differentiation degrades, can still read every state correctly.
- **Contrast ratios** across every text/background and icon/background pairing meet or exceed WCAG AA at minimum, chosen deliberately higher than that floor for any element used outdoors (status strip, fare amount, primary action).
- **Text scaling** respects the OS-level accessibility text-size setting without breaking any layout — no fixed-height container is allowed to truncate the fare amount or a blocking-state message at any supported text scale.
- **Screen-reader labelling** is applied to every status indicator using the same plain-language vocabulary this document defines for sighted Conductors — "Synced," "Offline," "Not authorized" — never an internal or technical term a screen reader would announce differently from what's visually shown.
- **No interaction depends on a gesture more complex than a single tap.** No swipe-to-dismiss, long-press, or multi-finger gesture is required for any primary or secondary action in the MVP scope, since a Conductor's attention and dexterity are both frequently divided (Product Specification §14).
- **Motion is minimal and interruptible.** The one automatic transition in the product (Ticket Confirmation's auto-return, §8.8) is always interruptible by a Conductor tap, never a fixed, un-skippable delay.

---

## 11. Design Constraints

- **Offline operation.** Every screen except Device Revoked / Unauthorized (§8.12, which is itself a representation of a platform-side denial, not a connectivity concern) is fully usable with zero connectivity, because offline is the platform's central design condition, not an edge case (Product Specification §13). This is not a constraint applied after the fact — it is the starting condition every screen spec above was designed against.
- **Low connectivity.** Where connectivity is present but poor, the design shows the same honest, incremental status progression (Captured → Buffered → Synced) rather than a binary online/offline signal — a Conductor in marginal signal should see genuine, if slow, progress, never a stuck or misleading indicator.
- **Battery limitations.** No screen polls, animates, or refreshes more aggressively than its own underlying data actually changes; Background Execution & Device Lifecycle Management's own cadence (Feature Specification §7.1) governs how often data can meaningfully update, and the UI never implies a freshness the underlying system isn't actually producing.
- **Outdoor visibility.** High-contrast, large-type, color-plus-icon-plus-label status design (§4.2–§4.3, §10) is a direct response to a Conductor working in direct sunlight glare, not a general accessibility nicety layered on top.
- **One-handed operation.** Bottom-anchored primary actions, single-tap selection instead of typed input, and generous touch-target spacing (§2.7, §6.2–§6.3) all serve a Conductor whose other hand is frequently occupied with a fare box or change.
- **Large touch targets.** Stated explicitly and repeatedly across this document (§4.4, §6.2) because vehicle motion measurably increases mis-tap risk — this is treated as a safety-relevant design constraint, not merely a usability preference.
- **Fast ticket issuance.** The three-screen ticketing flow (§8.6–§8.8) is the minimum this design could arrive at while still honouring Ticket Issuance's own hard preconditions (Feature Specification §5.6) — boarding/destination selection and fare confirmation are not collapsible into fewer steps without either skipping a required precondition or overloading a single screen with two decisions at once, which §2.9 explicitly rules out.
- **Accessibility.** Treated as inseparable from the operational constraints above, not a separate checklist — see §10.
- **Operational safety.** No screen ever demands sustained visual attention from a Conductor who should be watching the road, doorway, or passengers — every ticketing interaction is designed to be completable in brief, interruptible glances, and an interrupted flow is always safely resumable (§5.5).

---

## 12. Future Design Considerations

These are named because a comprehensive design specification should distinguish "not currently in scope" from "considered and rejected" — every item below is the former (Feature Specification §16), and none is designed for in this document:

- **Ticket Correction/Void.** Once the platform defines an actor, trigger, and mechanism for correcting an issued Ticket (Feature Specification §5.6, Open Questions), it would compose as a new capture-time flow producing a new, distinct record referencing the original — reusing the existing Boarding & Destination Selection / Fare Confirmation pattern rather than introducing an edit-in-place interaction, which this design deliberately avoids everywhere else.
- **Conductor Self-Identification.** Should a mechanism ever be introduced to address the device-handoff misattribution risk directly (Feature Specification §7.5, §8.2), it would need its own screen — most plausibly inserted between Device Initialization (§8.2) and Home Dashboard (§8.4) — without weakening the Device-only authentication boundary this entire navigation model is built around (§5.6).
- **Reference-Context Staleness Bound & Warning.** Once a staleness threshold is defined upstream (Feature Specification §15 item 3), Trip Context (§8.5), Boarding & Destination Selection (§8.6), and Fare Confirmation (§8.7) would each gain an explicit warning state at that threshold — today, this design surfaces raw staleness age honestly but implements no refusal or warning threshold, because none is defined to implement.
- **A Stronger Reconciliation-Visibility Signal.** Should the platform ever expose confirmation beyond transport acknowledgement (Feature Specification §6.1, Future Enhancements), it would extend the existing three-state status vocabulary (Captured/Buffered/Synced) additively — a fourth state, not a redesign of the pattern.
- **Passenger-Category / Concession Fare Support.** Contingent on a Domain Specification revision (Feature Specification §15 item 6). If introduced, it would insert a new selection step between Boarding & Destination Selection (§8.6) and Fare Confirmation (§8.7) — this document does not design that step today, since no upstream concept exists for it.
- **A Defined Local-Storage Retention/Pruning Policy.** Once fixed by a future Technology Decision (Feature Specification §15 item 7), it directly bounds Ticket History's (§8.9) own retention window without requiring a redesign of the screen itself.
- **Dedicated ETM Hardware.** Named in the Product Specification's own V3 roadmap (§19) as a later-phase consideration, contingent on hardware decisions entirely outside this document's scope; this design assumes the current operator-provisioned Android phone form factor throughout.

---

*End of NammaRoute Conductor ETM UI, UX & Screen Specification v1.0.*
