# Gate 002 — Canonical candidate sequence v4

Status: **QUALIFIED AGAINST PRODUCTION OWNERSHIP SEMANTICS / READY FOR AUTHORIZED PRODUCTION APPLY**.

v4 supersedes the earlier v3 candidate. The reason is material: production Phase 1A objects are owned by `vida_identity_owner`, while migration execution occurs as `postgres` without inherited owner privileges. v4 reproduces that boundary in rehearsal, keeps direct `auth` access away from `vida_identity_owner`, and uses narrow postgres-owned adapters in `vida_internal` for Auth/runtime facts.

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

## Qualification result

The exact Git-resident v4 files were replayed in the existing zero-cost rehearsal project from a production-like Phase 1A ownership baseline. The chain was then rolled back and replayed a second time from the recorded exact migration bodies.

Focused v4 schema/ACL/ownership fingerprint:

- replay 1: `fdac4d2c256f380ab38682e8ffb67def`
- rollback + replay 2: `fdac4d2c256f380ab38682e8ffb67def`
- normalized object lines: **244**
- result: **PASS**

The v4 runtime smoke passed after both replay cycles, including VRI idempotency, account RLS isolation, canonical membership administration, last-owner protection, direct Auth-delete shortcut protection and the complete offboarding lifecycle.

Advisors after exact replay show no new unindexed Gate-002 FK. The single remaining unindexed FK is legacy `diagnosticos_vida.user_id`. Authenticated `SECURITY DEFINER` warnings correspond to the intentionally exposed, authorization-checked canonical RPC surface.

## Recovery / test artifacts

- production read-only preflight: `../tests/GATE_002_PRODUCTION_PREFLIGHT.sql`
- v4 rollback rehearsal: `../tests/GATE_002_V4_ROLLBACK_REHEARSAL.sql`
- v4 runtime smoke: `../tests/GATE_002_V4_RUNTIME_SMOKE.sql`
- prior v3 evidence remains historical only and is superseded for production apply.

This sequence is the only Gate 002 sequence eligible for a production apply. Presence in Git does not authorize a merge to `main`.
