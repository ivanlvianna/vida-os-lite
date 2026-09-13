# Gate 0 — clean-bootstrap qualification evidence

Date: 2026-09-13
Environment: existing zero-cost rehearsal Supabase project `jijdyrinuzyjampptbaf`
Production project: unchanged.

## Result

**ZERO-COST SHADOW CLEAN-INSTALL QUALIFICATION: PASS**

The qualification deliberately keeps Supabase-managed platform schemas (`auth`, migration ledger, etc.) in place, removes the application-owned `public` surface inside a transaction, reconstructs the current VIDA OS Lite + integrations + Identity Phase 1A state, verifies schema equivalence, runs functional smoke tests, then rolls the entire test transaction back.

This is the closest reproducible clean-project proof available under the explicit zero-cost constraint without creating a paid Supabase development branch or another paid project.

## Structural equivalence

Acceptance oracle: `supabase/bootstrap/SCHEMA_EQUIVALENCE_QUERY.sql` v2.

Expected production fingerprint:

`e100181fbc05659e2e9fbcb2c3b296b1`

Expected normalized object lines: `584`.

Observed after shadow clean reconstruction:

- fingerprint: `e100181fbc05659e2e9fbcb2c3b296b1`
- normalized object lines: `584`
- result: **PASS**

The oracle covers public-schema ownership/ACLs, VIDA technical roles and memberships, relations, columns, column ACLs, constraints, indexes, RLS policies, public functions and ownership/configuration, triggers, effective table/function ACLs and public enum/domain types.

## Functional smoke proof

Executed harness: `supabase/tests/GATE_0_CLEAN_BOOTSTRAP_SMOKE.sql`.

Validated inside the same rollback-only shadow installation:

1. Two synthetic `auth.users` rows create exactly two `users_profile` rows through the production-equivalent `on_auth_user_created` trigger.
2. New-user defaults keep LGPD, terms and onboarding flags false.
3. Updating Auth email propagates to `users_profile.email` through `sync_user_profile_email_after_auth_update`.
4. Runtime `authenticated` RLS exposes exactly the caller's own profile.
5. Runtime update of the caller's own allowed profile field succeeds; cross-user update affects zero rows.
6. Column ACL permits authenticated update of `nome_completo` but not protected `email`.
7. PUBLIC, `anon`, `authenticated` and `service_role` retain no direct CRUD privileges on the seven Phase 1A canonical tables.
8. `anon` and `authenticated` retain no direct read/insert access to Hotmart/internal intake, Scanner VIDA Empresa or `vida_public_submissions` tables.
9. A synthetic Phase 1A reconciliation through `vida_reconciliation_operator` creates one source, one confirmed record and one EconomicEntity.
10. Repeating the same `p_record_id` is idempotent: still exactly one reconciliation record.
11. `vida_reconciliation_operator` can execute `canonical_reconcile` but cannot directly INSERT into `reconciliation_record`.
12. The outer transaction rolls back all synthetic users, profiles, reconciliation rows, role membership changes and reconstructed schema changes.

Post-run read-back confirmed zero synthetic `gate0-smoke-*` Auth users remained and rehearsal row counts returned to their prior state (`auth.users=15`, `users_profile=15`, `prontuario_patrimonial=1`, `economic_entities=0`, `reconciliation_source=1`, `reconciliation_record=1`, `planning_engagements=0`).

## Harness correction history

An initial smoke harness attempt aborted before functional testing because it passed the pseudo-grantee `PUBLIC` to `has_table_privilege()`, which expects a real role name. That was a test-harness defect, not a bootstrap/schema failure. The corrected v2 checks PUBLIC through ACL expansion (`aclexplode`, grantee OID `0`) and passed.

## Remaining distinction

This evidence proves reconstruction equivalence and database-level behavior in a zero-cost shadow clean installation. It does **not** by itself mean a single standalone canonical bootstrap file is already archived in Git. The large Identity Phase 1A body is content-recovered and hash-verified but still awaits final byte-for-byte Git archival/assembly into the standalone bootstrap path.

No production DDL was executed. No merge to `main` was performed.
