# Gate 002 v4 — Production Postflight

Date: 2026-09-13

Status: **PASS — MIGRATION-APPLY-GATE-002 APPLIED / CLOSED**.

This document records the read-only verification performed after the canonical Gate 002 v4 sequence was applied to production. It does not authorize a merge of PR #1 into `main`, and no client/economic-entity backfill is part of this gate.

## Applied migration ledger

Production records all 12 canonical v4 migrations, in order:

1. `gate002_v4_m0_runtime_bridge`
2. `gate002_v4_m1_phase1a_security_hardening`
3. `gate002_v4_m2_01_core_auth_internal`
4. `gate002_v4_m2_02_planning_core`
5. `gate002_v4_m2_03_public_rpcs`
6. `gate002_v4_m2_04_activation`
7. `gate002_v4_m2_1_membership_governance`
8. `gate002_v4_m2_2_auth_cascade_contract`
9. `gate002_v4_m2_3_active_authorization_auth_delete_block`
10. `gate002_v4_m3_access_surface`
11. `gate002_v4_m4_offboarding_workflow`
12. `gate002_v4_m5_performance_hardening`

## Structural postflight

- Phase 1B/governance/offboarding tables present: **10/10**.
- Those 10 tables owned by `vida_identity_owner`: **10/10**.
- Those 10 tables with RLS enabled: **10/10**.
- Full relevant Identity/Planning surface with RLS enabled: **17/17**.
- Gate access policies: **16**, all explicitly scoped to `authenticated`.
- Public canonical Gate RPCs present: **12/12**; all 12 owned by `vida_identity_owner`.
- `vida_internal` exists.
- `vida_internal.is_staff(uuid)` exists; `public.is_staff(uuid)` does not exist.
- `anon` has no `USAGE` on `vida_internal` and cannot execute the runtime Auth adapter.
- `authenticated` has the schema `USAGE` needed by RLS helper resolution but cannot execute `vida_internal.current_auth_uid()` directly.
- `client_account_users_auth_user_id_fkey` exists.
- `reconciliation_record_economic_entity_id_idx` exists.
- Direct `INSERT`/`DELETE` grants on `client_account_users` for `anon`, `authenticated`, and `service_role`: **0**.

The deliberate Phase 1A + Phase 1B table privilege matrix matched the v4 M3 contract exactly: **11 expected grants, 11 observed, 0 missing, 0 unexpected**. These are RLS-constrained read/write grants required by the new access surface; the earlier Phase-1A-only deny-by-ACL posture was intentionally superseded for the four tables participating in authenticated Phase 1B workflows.

## Phase 1A preservation / no accidental activation

Production data after deployment:

- `auth.users`: **3**
- `economic_entities`: **1**
- `reconciliation_source`: **3**
- `reconciliation_record`: **3**
- reconciliation entity orphans: **0**
- reconciliation source orphans: **0**
- `client_accounts`: **0**
- `client_account_users`: **0**
- `client_account_entities`: **0**
- aggregate Phase 1B/governance/offboarding data rows: **0**

Therefore Gate 002 installed schema and governance only. It did **not** backfill clients, create Planning Engagements, create memberships, or activate VRI data.

## Phase 1A hardening

All six Phase 1A functions covered by M1 now have an empty `search_path`, and `anon`, `authenticated`, and `service_role` have **zero** execute grants on those six functions.

## Runtime/API surface

Authenticated canonical RPCs are exactly:

- `add_client_account_membership`
- `create_economic_entity`
- `create_planning_engagement`
- `grant_client_account_authorization`
- `record_planning_engagement_transition`
- `remove_client_account_membership`
- `revoke_client_account_authorization`
- `start_client_account_offboarding`

Backend/service RPCs are exactly:

- `activate_client_from_vri`
- `mark_client_offboarding_sessions_revoked`
- `mark_client_offboarding_user_deleted`
- `record_client_offboarding_retryable_failure`

`anon` can execute none of the 12 Gate RPCs.

## Production ↔ rehearsal Gate-scope parity

Post-deploy comparison exposed pre-existing Phase 1A rehearsal-baseline drift: two `entity_relationships` FKs, the `reconciliation_record.economic_entity_id` FK, one canonical constraint name, and `trg_economic_entities_protect_owns_target` were absent in rehearsal. The old synthetic reconciliation sentinel had also outlived its referenced synthetic `economic_entities` row because that FK was missing.

The zero-cost rehearsal project was repaired to restore the synthetic EconomicEntity and the missing Phase 1A structural invariants. No production change was required.

A production/rehearsal Gate-scope parity fingerprint was then computed over 17 tables, columns, constraints, indexes, policies, non-internal triggers, table grants, the full source hashes of all Gate 002 functions, and signature/owner/security/search-path metadata for the six pre-existing Phase 1A functions.

Result in both environments:

- fingerprint: `9668927a1cea1f614eb6feb0ed5a91fc`
- normalized object lines: **388**
- result: **PASS**

The six historical Phase 1A function source bodies are intentionally not body-hashed in this postflight parity oracle because the rehearsal project contains earlier reconstructed source bodies rather than the byte-identical production historical bodies. Their Gate-002-relevant metadata (`signature`, owner, security mode, `search_path`) is compared and matches. The qualified standalone Gate 0 bootstrap remains the byte-faithful production reconstruction proof for the pre-Gate-002 baseline.

## Supabase Advisors after deployment

Security Advisor:

- `rls_enabled_no_policy`: informational findings remain. For the Gate surface, `client_account_membership_events`, offboarding ledgers/workflows, `client_activation_seeds`, `entity_relationships`, `reconciliation_source`, and `reconciliation_record` are deliberate deny-all/backend-controlled tables. Additional findings belong to pre-existing Hotmart/public-intake backend tables.
- `authenticated_security_definer_function_executable`: **8** warnings correspond exactly to the eight intentionally exposed, authorization-checked authenticated canonical RPCs listed above.
- leaked-password protection remains disabled in Supabase Auth. This is an Auth configuration item outside Gate 002 schema migration scope.

Supabase references:
- RLS/no-policy advisor: https://supabase.com/docs/guides/database/database-linter?lint=0008_rls_enabled_no_policy
- SECURITY DEFINER advisor: https://supabase.com/docs/guides/database/database-linter?lint=0029_authenticated_security_definer_function_executable
- leaked-password protection: https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection

Performance Advisor:

- no unindexed-FK finding remains for Gate 002.
- current findings are `unused_index` INFO notices. This is expected immediately after installation because production has zero Phase 1B data/workload and the new indexes have not yet accumulated usage statistics.

Reference: https://supabase.com/docs/guides/database/database-linter?lint=0005_unused_index

## Gate decision

`MIGRATION-APPLY-GATE-002 — Identity / Planning / Authorization / VRI / Offboarding`: **APPLIED / CLOSED**.

Outstanding work is outside this migration gate:

- no merge of PR #1 to `main` has been authorized or performed;
- no client backfill has been authorized or performed;
- the application has not yet been wired end-to-end to the new Phase 1B domain surface;
- Supabase leaked-password protection can be considered separately as an Auth-hardening decision.
