# 00_READ_FIRST — NammaRoute Conductor ETM
### `docs/00_READ_FIRST.md`

**Read this before opening any source code or any other document.** It is the front door to the ETM documentation set — a 10–15 minute orientation, not a specification. Every claim below is explained in full somewhere in the documents listed in §3; this document tells you *which one*, not the whole answer.

---

## 1. Project Overview

**NammaRoute** is a bus-fleet platform connecting rural and hill-terrain bus operators, their conductors, and commuters through real-time location and ticketing data.

**The Conductor ETM (Electronic Ticketing Machine)** is the Android app conductors use, on an operator-provisioned phone, to do two things every shift: sell fare tickets, and report the bus's location. It is the first production client built against the platform's already-existing, already-validated backend.

**Primary users:**
- **Conductors** — the direct, hands-on users, operating the ETM for a full shift, often with weak or no cellular signal.
- **Operator Admins** — indirect users who provision devices and schedule trips from a separate Dashboard; they never open the ETM themselves.

**High-level goals:** make ticket issuance faster than a conductor's current method, never lose a captured sale or location reading regardless of connectivity, and be honest with the conductor about what has and hasn't reached the backend.

For the full product story, read `01_ETM_Product.md`. This section exists only so the rest of this document makes sense without it.

## 2. Repository Structure

| Folder | Purpose |
|---|---|
| `docs/` | Every specification and this handbook — the authoritative source of *why* and *what*, read before any folder below. |
| `lib/` | The Flutter/Dart application: feature modules (`identity`, `reference_context`, `ticketing`, `telemetry`), the shared core (`capture`, `sync`, `background`, `diagnostics`, `config`), the composition root (`app`), and the platform-channel bridge (`platform`). |
| `android/` | The native Android project, including the Kotlin foreground-service module (background execution, location, MQTT client). |
| `assets/` | Static assets bundled into the app (icons, fonts, non-code resources). |
| `test/` | Unit and widget tests — plain Dart `test` for domain/application logic, `flutter_test` for presentation. |
| `integration_test/` | On-device/emulator tests for flows that span the native module (background survival, MQTT reconnect, location cadence) and the offline/chaos scenarios the reliability model depends on. |
| `tool/` | Developer scripts and build tooling (code generation triggers, environment setup helpers). |

This is a map, not a manual — module responsibilities and dependency rules live in `10_ETM_Engineering_Implementation.md` §3–§5.

## 3. Documentation Reading Order

```
00_READ_FIRST  (you are here)
   ↓
01  Product              — what the ETM is for, and for whom
   ↓
02  Domain                — the business concepts: Ticket, Trip, Conductor, Device...
   ↓
03  Workflows              — the operational sequences those concepts move through
   ↓
04  System Architecture    — the subsystems and boundaries that implement those workflows
   ↓
05  Technology Decisions   — the concrete stack chosen to build that architecture
   ↓
06  Reliability            — the exact guarantees the offline/durability model provides
   ↓
07  Data Contracts         — the business promises behind every piece of exchanged data
   ↓
08  Features               — the functional scope, broken into buildable units
   ↓
09  UI & Screens            — what the conductor actually sees and touches
   ↓
10  Engineering Handbook    — how all of the above becomes code, day to day
```

Each document answers a narrower question than the one before it, and none repeats the one before it:

- **01 Product** — *why does this exist, and who is it for?* Read this first; everything else assumes it.
- **02 Domain** — *what do the words mean?* "Ticket," "Trip," "Device" have precise, non-obvious definitions used consistently everywhere downstream.
- **03 Workflows** — *what actually happens, step by step?* Shift start, ticket issuance, device revocation, and every other operational sequence.
- **04 System Architecture** — *what are the pieces, and what does each one own?* The subsystem boundaries every later document assumes.
- **05 Technology Decisions** — *which specific library, framework, or service satisfies each piece?* Not a free choice — a translation of §04 into a concrete stack.
- **06 Reliability** — *what exactly is guaranteed when things go wrong?* The precise behavioral contract behind "no ticket is ever lost."
- **07 Data Contracts** — *who owns each piece of information, and what happens when its shape changes?*
- **08 Features** — *what are the buildable units, and what does "done" mean for each?*
- **09 UI & Screens** — *what does the conductor see, screen by screen?*
- **10 Engineering Handbook** — *how do I actually write this, day to day?* The one document you'll return to most often once you're building.

If you only have time for one document beyond this one before writing code, read **04 System Architecture**, then **10 Engineering Handbook** — together they tell you where your code goes and what it may depend on.

## 4. Project Architecture Summary

*(One page. The full story is in `04_ETM_System_Architecture.md`.)*

- **Offline-first, not offline-tolerant.** Connectivity is treated as an occasional bonus, never a precondition. Every conductor-facing action — issuing a ticket, reporting location — succeeds with zero network signal, by architecture, not by best effort.
- **Two kinds of local data, never confused.** A captured-but-unsynced Ticket or location Ping is, temporarily, the *only* copy of that fact that exists anywhere — it is not disposable. Everything else the app caches (Trip, Fare Rule, Route Stop, pairing info) is always disposable and never authoritative. Mixing these two up is named, upstream, as the single most likely mistake this project could make.
- **Hybrid Clean Architecture.** Every module that touches capture is layered domain → application → infrastructure, dependency pointing inward only. The domain layer has zero Flutter/Android dependency — it's plain Dart business rules, testable without a device, a database, or a network.
- **Feature-first modularity, shared core underneath.** Ticketing, Telemetry, Reference Context, and Identity are separate feature modules, each owning its own business rules. But Ticketing and Telemetry both delegate durability and synchronization to one **Shared Edge-Event Core** — one reliability mechanism, two payload types, not two independently-invented ones.
- **Honest by design.** The app never claims more certainty than it has. "Captured" is shown the instant a local write completes; "synced" only after the backend actually acknowledges receipt; a stale cached Trip is shown as stale, never as current.

## 5. Technology Stack Summary

*(Approved, binding choices only — full rationale and rejected alternatives live in `05_ETM_Technology_Decisions.md`.)*

| Category | Technology |
|---|---|
| Language | Dart |
| Framework | Flutter |
| Architecture pattern | Clean Architecture (domain/application/infrastructure), composed via Riverpod |
| State management | Riverpod |
| Local database | Drift (SQLite, WAL mode) |
| Secure storage | flutter_secure_storage (Android Keystore-backed) |
| Networking (REST) | dio |
| Messaging (MQTT) | Native Eclipse Paho Android Client, co-located with the native foreground service |
| Serialization | Protobuf (MQTT payloads) + json_serializable (REST payloads) |
| Background execution | Native Android Foreground Service (Kotlin) |
| Location | Native FusedLocationProviderClient (same native module) |
| Security | Device-credential-only trust model; no conductor-level login anywhere |
| Logging | `logger` package + durable rotating local sink |
| Error reporting / performance | Sentry |
| Testing | Dart `test` (domain), `flutter_test` (widgets), `integration_test` (native-spanning flows), `mocktail` (mocking) |

## 6. Engineering Principles

The short version of `10_ETM_Engineering_Implementation.md` §2 — the instincts every engineer should carry into every change:

- **Offline First** — a capture action never waits on the network.
- **Platform as Source of Truth** — the ETM reads Trip, Fare Rule, and Conductor assignment; it never invents or overrides them.
- **Separation of Concerns** — one subsystem, one responsibility; a transport module never makes a business decision.
- **Dependency Inversion** — domain logic depends on abstractions; infrastructure implements them, never the reverse.
- **Feature Isolation** — Ticketing and Telemetry each own their own business rules, sharing only the underlying durability/sync mechanism.
- **Fail Closed** — an unauthorized or revoked state is never treated as, or silently retried like, a mere connectivity gap.
- **Reliability over Convenience** — if a shortcut would risk losing a captured ticket or ping, the shortcut loses, every time, regardless of deadline.

## 7. Development Workflow

```
Read the relevant specification(s)
   ↓
Create an implementation plan
  (which module, which layer, which existing port or provider it extends)
   ↓
Develop
  (against the module and dependency rules in §3–§5 of the Engineering Handbook)
   ↓
Test
  (unit + widget always; integration/offline/chaos tests for shared-core changes)
   ↓
Review
  (against the Engineering Handbook's Code Review Checklist)
   ↓
Merge
```

Skipping the first step is the most common source of avoidable rework on this project — a plan built without reading the relevant specification tends to reinvent something already decided, usually differently.

## 8. Contribution Guidelines

- **Where to place a new feature:** find its owning subsystem in `04_ETM_System_Architecture.md` §12 first. If it originates a new kind of edge event, it becomes a new feature module depending on the existing Shared Edge-Event Core — it does not get its own durability or sync mechanism.
- **How to avoid architecture violations:** check the dependency matrix in `10_ETM_Engineering_Implementation.md` §5 before writing an import. If your change makes the domain layer depend on Flutter, Drift, or a platform channel, stop and restructure before continuing.
- **How to propose an architectural change:** open the question against the specific specification document it would change (Architecture, Reliability, Data Contracts, etc.) before writing code — this project's documents are living, but a change to one is a deliberate, reviewed event, not a side effect of a feature PR.
- **When to update documentation:** whenever an implementation reveals a genuine gap or open question upstream (several are already named explicitly in each specification's own "Open Questions" section) — raise it against that document, don't silently resolve it in code.
- **When to create an ADR:** when a decision is made that a future engineer would otherwise have to reverse-engineer from the code — a new dependency, a changed retry/backoff parameter, a new storage technology. If it would surprise someone reading only the Technology Decisions document, it needs an entry there or a new ADR, not just a comment.

## 9. Definition of Success

Every completed feature should satisfy, before it's considered done:

- **Architecture compliant** — correct module, correct layer, no dependency-direction violation.
- **Tested** — unit and widget coverage; offline-first and (where applicable) chaos/failure tests for anything touching the shared core.
- **Offline capable** — verified to work with zero connectivity, not assumed to work by inheritance.
- **Documented** — subsystem-owning code cites the specification section it implements.
- **Reviewed** — against the Engineering Handbook's Code Review Checklist.
- **Performance verified** — ticket issuance still feels instantaneous; no sync batching/pacing parameter quietly widened.
- **Security verified** — no new secret-storage location, no new plaintext configuration asset, no new local authorization logic.

The full, authoritative version of this list is the Engineering Handbook's Definition of Done (`10_ETM_Engineering_Implementation.md` §16) — this is the summary, not a substitute.

## 10. Useful References

- **`01_ETM_Product.md`** — why this project exists and who it serves.
- **`04_ETM_System_Architecture.md`** — the subsystem map every module boundary derives from.
- **`05_ETM_Technology_Decisions.md`** — the approved stack and why each choice was made.
- **`06_ETM_Reliability.md`** — the precise guarantees behind "no ticket is ever lost."
- **`10_ETM_Engineering_Implementation.md`** — the day-to-day engineering handbook: project structure, coding standards, testing strategy, and the Code Review Checklist.

When in doubt about where an answer lives, it is almost always one of these five.

---

*End of NammaRoute Conductor ETM `00_READ_FIRST.md`.*
