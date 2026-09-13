# Gate 002 — Historical v3 Rehearsal Qualification Evidence

Status: **HISTORICAL / SUPERSEDED BY CANONICAL v4**

Date: 2026-09-13

This document preserves the evidence trail for the v3 rehearsal candidate. It is **not** the current Gate 002 status and must not be used as a production deployment instruction.

Current canonical references:

- migration sequence and final status: `../migrations/GATE_002_SEQUENCE.md`;
- current test status: `GATE_002_TEST_PLAN.md`;
- v4 runtime smoke: `GATE_002_V4_RUNTIME_SMOKE.sql`;
- v4 rollback rehearsal: `GATE_002_V4_ROLLBACK_REHEARSAL.sql`;
- final production evidence: `GATE_002_PRODUCTION_POSTFLIGHT.md`.

## Historical v3 result

The zero-cost rehearsal project qualified the original v3 chain across functional, negative, RLS/ACL, concurrency, PostgREST isolation, VRI, Planning Engagement, membership governance, Auth-delete protection and retryable offboarding tests.

Two corrected v3 rollback/replay cycles produced the same historical focused fingerprint:

- replay 1: `a1d16abf1a6ae8acbb261bcbd72afb76`;
- replay 2: `a1d16abf1a6ae8acbb261bcbd72afb76`;
- compared object lines: **218**;
- result: **PASS**.

The v3 work also established the following important invariants that were carried forward into v4:

- canonical add/remove membership workflows and append-only membership ledger;
- real concurrent membership add produces one membership and one `added` event;
- direct membership DML denied to application roles;
- last active account-scope `planner_owner` cannot be removed;
- internal helpers remain outside public PostgREST RPC surface;
- 16/16 Identity/Access/Planning policies explicitly target `authenticated`;
- EconomicEntity update uses both `USING` and `WITH CHECK`, with immutable-field protection;
- Planning Engagement terminal/transition invariants;
- VRI activation idempotency and `ambiguous_match` rejection;
- persisted retryable offboarding;
- direct Auth-user deletion cannot bypass active authorization rules.

## Why v3 was superseded

The first production application attempt revealed a material environment boundary not faithfully represented by the earlier rehearsal baseline: production Phase 1A objects are owned by `vida_identity_owner`, while migration execution occurs as `postgres` without inherited owner privileges.

That attempt failed transactionally before effective schema change. The candidate was then redesigned as v4 with an explicit M0 runtime/Auth bridge and production-compatible owner semantics. v4 was requalified, replayed twice, applied successfully to production and passed postflight.

Therefore:

- v3 qualification remains valid as historical engineering evidence;
- v3 is **not eligible for production apply**;
- Gate 002 current status is **v4 APPLIED / POSTFLIGHT PASS / CLOSED**;
- no merge to `main` is implied by this historical evidence.
