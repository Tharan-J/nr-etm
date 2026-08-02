# NammaRoute Conductor ETM — Product Specification
### `docs/etm-product-specification.md`

**Document type:** Product Specification — defines *what* the ETM is, for *whom*, and *why*. It does not define features, workflows, architecture, or technology.
**Position in the hierarchy:** Derives from the Product Engineering Blueprint and Domain Model Specification. Feeds `08_ETM_Features.md` (functional/UX scope), an ETM Architecture document, and an ETM Technology/Architecture Decisions document. None of those are this document, and none of their content is duplicated here.

---

## 1. Purpose

Define the ETM as a product — its reason for existing, its users, and its boundaries — before any feature, architecture, or technology decision is made. Every later ETM document must trace back to this one; this one traces back only to the Blueprint and Domain Model.

## 2. Product Vision

The Conductor ETM turns the moment a passenger pays their fare into the first, most reliable link in NammaRoute's real-time data fabric — a ticketing tool conductors adopt because it is faster and easier than what they use today, not because it is mandated.

## 3. Problem Statement

A conductor's ticketing tool and a bus's location tracker are, today, disconnected systems, each blind to what the other knows. A ticket sale is evidence of occupancy and route progress that nowhere else captures. The ETM exists to make that evidence usable, without asking a conductor to work differently or tolerating failure the moment cellular signal drops.

## 4. Background

The backend this product runs against already exists and is treated as a fixed input, not open design space (Execution Philosophy: the transport layer was deliberately built and validated ahead of any production client). The ETM is that first production client. This document does not renegotiate backend behavior; it defines the product experience on top of it.

## 5. Scope

The ETM is responsible, as a product, for two things:

- **Ticket issuance** — capturing a fare sale as an attributable business record, usable with or without connectivity.
- **Telemetry origination** — at MVP, the same operator-provisioned device is the Bus's sole source of location/status reporting (Domain Model Part 2.5). The ETM is a dual-purpose instrument, not a ticketing app with an incidental location feature.

Both must hold up under intermittent, rural connectivity as the normal operating condition, not an exception. *How* either is captured, buffered, or synced is functional/architectural scope, defined in `08_ETM_Features.md` and the ETM Architecture document — not here.

## 6. Out of Scope

- Cashless or wallet-based payment at point of sale (deferred platform-wide).
- Linking a Ticket to a Commuter account at point of sale (no supporting capability exists platform-wide).
- Conductor-level authentication (no such scheme exists anywhere in the platform).
- Trip scheduling, crew assignment, dispatch, route/fare authoring (Operator Dashboard responsibilities).
- Dedicated ETM hardware, receipt printing, ticket media (later-phase, per Blueprint Part 21).
- Multi-operator UI (a Device is scoped to one Operator structurally; no ETM-side concept needed).
- Analytics, historical reporting, fleet-wide visibility (Operator Dashboard responsibilities).
- Commuter-facing features of any kind.

## 7. Target Users

- **Conductor** — the direct, primary user. Operates the device on the bus for the duration of a shift.
- **Operator Admin** — an indirect user. Provisions devices, onboards conductors, and schedules Trips from the Dashboard; never opens the ETM, but every one of these actions is a precondition the ETM depends on.

## 8. Stakeholders

| Stakeholder | Interest |
|---|---|
| Conductor | A tool that is fast and reliable, not a burden. |
| Fleet Operator | Complete, faithful fare records without new operating burden. |
| Commuter (indirect) | Benefits from the occupancy/tracking signal, never interacts with the ETM. |
| Platform Team | The ETM is the first real field validation of the backend's offline-reliability design. |

## 9. User Personas

**Murugan, Conductor.** Experienced, not hostile to a new tool, but has no tolerance for one slower than his current method or one that fails visibly in weak-signal terrain. May hand his phone to a relief conductor mid-shift without connectivity available at that moment.

**Deepa, Operator Admin.** Manages the fleet from the Dashboard. Not present on the bus; only sees the downstream consequence of an in-field problem, often after the fact.

## 10. Business Goals

- Prove the ticket→track→display loop works with one operator, in real field conditions, before further investment.
- Make adoption a side-effect of conductor self-interest, not enforcement.
- Protect operator revenue integrity — ticket data is fare-leakage-accountable.
- Generate the occupancy and route-progress signal the rest of the platform depends on.

## 11. Product Objectives

1. Ticket issuance is faster or easier than the conductor's current method.
2. No ticket is ever silently lost, regardless of connectivity or device conditions.
3. A conductor always has an honest answer to "did my sale go through."
4. The same device reliably serves both ticketing and telemetry without either starving the other.

## 12. Success Metrics

- Median ticket issuance time, vs. the conductor's prior method.
- Conductor-reported trust in the app's sync-status signal.
- Zero-loss rate over a real pilot period, including genuine dead-zone conditions.
- Voluntary daily active usage, without administrative mandate.
- Revenue reconciliation completeness, from the operator's perspective.

## 13. Core Product Principles

- Connectivity is the exception the product is built for failure around, not the assumption it's built around.
- A ticket sale is never blocked or delayed by network state.
- The product is honest, never falsely reassuring, about what has and hasn't reached the backend.
- The device does exactly two jobs — ticketing and telemetry — and nothing else.

## 14. Operational Environment

- Operator-provisioned, low-cost Android hardware — not conductors' personal phones.
- Rural and hill-terrain cellular connectivity, including multi-hour dead zones, as normal.
- Use inside a moving vehicle, by a conductor whose attention is on passengers, not the device.
- Devices may pass between conductors across shifts and may be lost or replaced mid-operation.

## 15. Constraints

- The device, not the conductor, is the authenticated identity; there is no conductor login anywhere in the platform.
- Fare and Trip context are resolved from the backend, not authored on-device.
- A confirmed sale, once issued, never changes its recorded fare.
- Trip lifecycle (start/complete/cancel) is an Operator Admin action; the ETM has no control over it.

## 16. Assumptions

- Conductors operate an operator-provisioned device, not a personal one, for this product's design horizon.
- A device will typically have some connectivity near the start of a shift — not yet validated, and consequential if false.
- A device changing hands between conductors mid-shift is a real, expected occurrence in this fleet, not an edge case.

## 17. Risks

- **OEM background-execution killing** — the platform's highest-ranked risk, doubly consequential here since the ETM carries both ticketing and telemetry.
- **Conductor adoption/tampering** — ticketing touches conductor income directly, raising the stakes on this risk beyond telemetry alone.
- **Conductor misattribution on device handoff** — since pairing is an Operator Admin action, an offline mid-shift handoff risks tickets attributed to the wrong conductor.
- **Device loss or theft mid-shift** — a bounded but non-zero access window until revocation is actioned.
- **Field connectivity profile is an estimate, not a measurement**, for this specific terrain.

## 18. Non-Functional Expectations (Product Perspective)

- Ticket capture should feel instantaneous, regardless of network state.
- The product should never claim more certainty about a sale than it has.
- A conductor's normal day — screen off, backgrounded app, OS battery management — must never silently lose a sale or stop location reporting.
- The device must sustain a full shift of both responsibilities without becoming a battery or data burden.

## 19. Future Roadmap

- **MVP** — Phone-based ticketing and telemetry, single operator, offline-tolerant.
- **V2** — Field-validated improvements to conductor identity handling and ticket correction, once real usage patterns are observed; deeper conductor-facing visibility into their own sales, contingent on backend support.
- **V3** — Dedicated ETM hardware; commuter-linked ticket capture, contingent on Wallet/Commuter features being in scope.

## 20. Backend Dependencies (Reference Only)

Product Engineering Blueprint · Domain Model Specification · Execution Philosophy · Architecture Review · MQTT Specification · API Specification · Database Specification · ADR-001, 002, 005, 007, 008, 009, 011.

## 21. Open Questions

- How does a device receive its credentials and identity in the field — is this an ETM-app responsibility or a separate provisioning tool?
- Is a Ticket ever expected to link to a Commuter account, or is this permanently out of scope until Wallet/Commuter features exist?
- What is the true, measured connectivity profile of this fleet's actual routes?

Product decisions that follow from these questions (e.g., how conductor identity should be handled on shared devices, how ticket correction should work, whether occupancy should be conductor-visible) are **Architecture/Technology Decisions**, tracked in that document, not resolved here.

## 22. Glossary

| Term | Meaning |
|---|---|
| Operator | The bus-operating business the conductor works for. |
| Route / Trip | A defined path; one specific run of a Bus along it on one day. |
| Device | The operator-provisioned phone running the ETM; the authenticated identity. |
| Conductor | The staff member carrying the Device; a business identity, not a login. |
| Ticket | A single fare transaction. |
| Telemetry | Location/status reporting originated by the same Device. |
| Fare Rule | The pricing logic in effect for a Route or segment. |

---

*End of NammaRoute Conductor ETM Product Specification v1.1.*
