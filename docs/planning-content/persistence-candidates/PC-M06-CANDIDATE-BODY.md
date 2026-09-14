# PC-M06 — Candidate Body

Status: NON-EXECUTABLE / DO NOT APPLY.

Objective: create append-only lifecycle/workflow ledgers so current state is derived from canonical history rather than overwritten state columns.

Required lifecycle ledgers:
- WorkingHypothesis transitions: ACTIVE → ACCEPTED_FOR_PLANNING / REJECTED / RETIRED, with the approved return-to-ACTIVE behavior from ACCEPTED where defined; REJECTED/RETIRED terminal in v1;
- HypothesisAgenda transitions: OPEN/CLOSED; one OPEN agenda per engagement in v1; closing does not mutate hypothesis lifecycle;
- DiagnosticReport workflow events: submitted_for_review and validated;
- DiagnosticReport consensus events, including subject EconomicEntity, understood/agreed values and actor snapshot.

Required invariants:
- append-only; no direct UPDATE/DELETE;
- transition writer compares against current derived state under lock;
- stale-state transition fails;
- report validation requires current consensus manifestation for the frozen subject with `understood=true` and `agreed=true`;
- exactly one report consensus subject in v1;
- staff may record a client manifestation under the approved contract; self-service requires appropriate engagement/entity authorization;
- RLS + REVOKE ALL at creation.

Do not create speculative state machines for InstrumentRun, Session, Plan, PRI or RPM where the domain model intentionally left them open.
