# Gate 002 — Canonical candidate sequence

Status: **qualified in rehearsal; not applied to production**.

The physical files preserve the migration boundaries that were replayed successfully. Logical M2 is intentionally split into four files because those exact units were independently installed and then replayed from a clean Phase 1A baseline.

| Order | Logical step | File |
|---:|---|---|
| 1 | M1 — Phase 1A security hardening | `20260913032000_phase1a_security_hardening.sql` |
| 2 | M2.01 — internal schema / authorization core | `20260913033000_phase1b_m2_01_core_auth_internal.sql` |
| 3 | M2.02 — Planning Engagement core | `20260913033100_phase1b_m2_02_planning_core.sql` |
| 4 | M2.03 — public application RPCs | `20260913033200_phase1b_m2_03_public_rpcs.sql` |
| 5 | M2.04 — VRI activation | `20260913033300_phase1b_m2_04_activation.sql` |
| 6 | M2.1 — membership governance | `20260913034000_phase1b_m21_membership_governance.sql` |
| 7 | M2.2 — Auth cascade contract | `20260913034500_phase1b_m22_auth_cascade_contract.sql` |
| 8 | M2.3 — active-authorization Auth-delete block | `20260913035000_phase1b_m23_active_authorization_auth_delete_block.sql` |
| 9 | M3 — access surface / RLS | `20260913040000_phase1b_m3_access_surface.sql` |
| 10 | M4 — retryable offboarding workflow | `20260913041000_phase1b_m4_offboarding_workflow.sql` |
| 11 | M5 — performance hardening | `20260913042000_phase1b_m5_performance_hardening.sql` |

Rehearsal-only recovery proof is stored under `../tests/GATE_002_ROLLBACK_REHEARSAL.sql`; qualification evidence is in `../tests/GATE_002_QUALIFICATION_EVIDENCE.md`.

Important: these files are a production **candidate** only. Their presence in GitHub does not authorize execution against the production Supabase project.
