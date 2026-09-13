# VIDA OS™ — direct-current-state bootstrap build plan

Status: **DESIGN FROZEN FOR BUILD / BOOTSTRAP ITSELF STILL NON-EXECUTABLE**

Purpose: define the order and proof obligations for reconstructing the approved 2026-09-13 production baseline on a blank compatible Supabase project without relying on undocumented manual history.

## Non-negotiable boundaries

- Do not copy production rows, secrets, API keys or user identities into the bootstrap.
- Do not replay `../history/` as if it were a blank-database install chain; that folder is forensic evidence.
- Do not apply any bootstrap draft to production.
- Do not mix Gate 002 / Phase 1B forward changes into the production-baseline bootstrap. The bootstrap first reproduces the approved current baseline; forward migrations are applied only afterward in a separately authorized environment.
- Do not call the bootstrap canonical/executable until the clean-install proof and v2 equivalence oracle pass.

## Build order

### B0 — platform prerequisites

Verify that the target is a compatible Supabase/PostgreSQL environment with the platform-owned `auth` schema and standard API roles (`anon`, `authenticated`, `service_role`). Do not attempt to recreate Supabase platform internals.

The production catalog exposes `gen_random_uuid()` in `pg_catalog` (and also through `extensions`), so application DDL must not assume a custom extension search path to resolve UUID generation.

### B1 — VIDA technical roles and schema access

Reproduce the three production NOLOGIN roles and their required membership/SET semantics:

- `vida_identity_owner`
- `vida_reconciliation_operator`
- `vida_identity_rollback_operator`

Reproduce public-schema USAGE for the VIDA roles and preserve the production privilege boundary. Role membership must be validated against PostgreSQL 17 `ADMIN` / `INHERIT` / `SET` semantics, including the platform-created grant surface visible in the production catalog.

### B2 — Legacy Lite current state

Materialize the four pre-ledger/untracked objects from `drafts/legacy_lite_current_state_20260913.DRAFT.sql` only after review:

- `users_profile`
- `prontuario_patrimonial`
- `diagnosticos`
- `diagnosticos_vida`

This includes their current constraints, indexes, RLS policies, effective table/column privileges and the Auth/profile trigger bridge.

### B3 — integration and intake current state

Materialize the current structures for Hotmart, Scanner VIDA Empresa and `vida_public_submissions`. Historical migrations may be used as evidence, but the bootstrap component must represent the current state directly and must not depend on prior objects having been created by an untracked manual step.

### B4 — Identity Phase 1A current state

Materialize the currently approved production Identity layer:

- `economic_entities`
- `entity_relationships`
- `client_accounts`
- `client_account_entities`
- `client_account_users`
- `reconciliation_source`
- `reconciliation_record`

Reproduce current functions, triggers, ownership, append-only/succession invariants, reconciliation write path, rollback guard and direct-access denials exactly as they exist in production. This is the production baseline only; do not import the Gate 002 Phase 1B delta into this component.

### B5 — ownership and ACL reconciliation

Apply final owners and privilege surfaces after all objects exist. This stage must preserve:

- Phase 1A ownership by `vida_identity_owner` where present in production;
- legacy/integration ownership by `postgres` where present;
- current table ACLs, function ACLs and the 14 explicit `users_profile` column UPDATE grants;
- public-schema ACL semantics;
- absence of accidental direct Phase 1A access by PUBLIC / `anon` / `authenticated` / `service_role`.

### B6 — clean-install proof

Install B0–B5 on a blank compatible Supabase environment. Do not use production data. The installation must complete without manual edits between components.

### B7 — structural equivalence gate

Run `SCHEMA_EQUIVALENCE_QUERY.sql` on the clean install.

Acceptance oracle v2:

- fingerprint: `e100181fbc05659e2e9fbcb2c3b296b1`
- normalized object lines: **584**

Any mismatch is a failed gate until reconciled object-by-object or explicitly approved as an intentional platform-version difference. The older 552-line fingerprint is not an acceptance oracle.

### B8 — behavioral smoke gate

After structural equivalence, verify at minimum:

- Auth INSERT creates/synchronizes the Lite profile as expected;
- Auth e-mail UPDATE synchronizes `users_profile.email`;
- authenticated user A cannot read or mutate user B's legacy records;
- authenticated cannot directly mutate `diagnosticos_vida`;
- Phase 1A canonical tables remain inaccessible directly to API roles in the production-baseline state;
- reconciliation append-only and succession invariants reject invalid mutations;
- canonical reconciliation read/write/rollback privilege boundaries behave as specified.

Only after B6–B8 pass may the bootstrap be promoted from draft to executable/canonical. Gate 002 forward migrations remain a separate authorization after that point.
