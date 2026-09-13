# Gate 002 — Canonical sequence v4

Status: **APPLIED TO PRODUCTION / POSTFLIGHT PASS / CLOSED**.

v4 supersedes the earlier v3 candidate. The reason is material: production Phase 1A objects are owned by `vida_identity_owner`, while migration execution occurs as `postgres` without inherited owner privileges. v4 reproduces that boundary, keeps direct `auth` access away from `vida_identity_owner`, and uses narrow postgres-owned adapters in `vida_internal` for Auth/runtime facts.

## Canonical v4 order

| Order | Logical step | File |
|---:|---|---|
| 0 | M0 — runtime/Auth compatibility bridge | `20260913193000_gate002_v4_m0_runtime_bridge.sql` |
| 1 | M1 — Phase 1A security hardening | `20260913193100_gate002_v4_m1_phase1a_security_hardening.sql` |
| 2 | M2.01 — internal schema / authorization core | `20260913193200_gate002_v4_m2_01_core_auth_internal.sql` |
| 3 | M2.02 — Planning Engagement core | `20260913193300_gate002_v4_m2_02_planning_core.sql` |
| 4 | M2.03 — public application RPCs | `20260913193400_gate002_v4_m2_03_public_rpcs.sql` |
| 5 | M2.04 — VRI activation | `20260913193500_gate002_v4_m2_04_activation.sql` |
| 6 | M2.1 — membership governance | `20260913193600_gate002_v4_m2_1_membership_governance.sql` |
| 7 | M2.2 — Auth cascade contract | `20260913193700_gate002_v4_m2_2_auth_cascade_contract.sql` |
| 8 | M2.3 — active-authorization Auth-delete block | `20260913193800_gate002_v4_m2_3_active_authorization_auth_delete_block.sql` |
| 9 | M3 — access surface / RLS | `20260913193900_gate002_v4_m3_access_surface.sql` |
| 10 | M4 — retryable offboarding workflow | `20260913194000_gate002_v4_m4_offboarding_workflow.sql` |
| 11 | M5 — performance hardening | `20260913194100_gate002_v4_m5_performance_hardening.sql` |

## Rehearsal qualification

The exact Git-resident v4 files were replayed in the existing zero-cost rehearsal project from a production-like Phase 1A ownership baseline. The chain was rolled back and replayed a second time.

Focused v4 schema/ACL/ownership fingerprint:

- replay 1: `fdac4d2c256f380ab38682e8ffb67def`
- rollback + replay 2: `fdac4d2c256f380ab38682e8ffb67def`
- normalized object lines: **244**
- result: **PASS**

The v4 runtime smoke passed after both replay cycles, including VRI idempotency, account RLS isolation, canonical membership administration, last-owner protection, direct Auth-delete shortcut protection and the complete offboarding lifecycle.

## Production apply and postflight

All 12 migrations are present in the production migration ledger and applied successfully.

Postflight result:

- Phase 1B/governance/offboarding tables: **10/10 present, 10/10 owned by `vida_identity_owner`, 10/10 RLS enabled**;
- relevant Identity/Planning tables: **17/17 RLS enabled**;
- RLS policies: **16/16 explicitly `authenticated`**;
- canonical public Gate RPCs: **12/12 present and owned by `vida_identity_owner`**;
- direct membership `INSERT`/`DELETE` grants to API roles: **0**;
- Phase 1A reconciliation data preserved: **1 EconomicEntity / 3 sources / 3 records, 0 orphans**;
- Phase 1B data rows after schema installation: **0** — no automatic activation/backfill occurred;
- Gate-scope production/rehearsal parity after repairing pre-existing rehearsal baseline drift: `9668927a1cea1f614eb6feb0ed5a91fc`, **388/388 normalized lines**, PASS.

Security and performance Advisors were reviewed after deployment. Gate-related RLS/no-policy INFO findings are deliberate deny-all/backend-only surfaces; the eight authenticated `SECURITY DEFINER` warnings are the intended authorization-checked canonical RPC surface. No unindexed-FK finding remains for Gate 002. Fresh Gate indexes currently appear as unused because there is no Phase 1B production workload yet.

Full production evidence: `../tests/GATE_002_PRODUCTION_POSTFLIGHT.md`.

## Recovery / test artifacts

- production read-only preflight: `../tests/GATE_002_PRODUCTION_PREFLIGHT.sql`
- v4 rollback rehearsal: `../tests/GATE_002_V4_ROLLBACK_REHEARSAL.sql`
- v4 runtime smoke: `../tests/GATE_002_V4_RUNTIME_SMOKE.sql`
- production postflight: `../tests/GATE_002_PRODUCTION_POSTFLIGHT.md`
- prior v3 evidence remains historical only and is superseded by v4.

Gate 002 is closed. Presence of the closed gate in this branch does **not** authorize merge of PR #1 into `main` or any client/backfill operation.
