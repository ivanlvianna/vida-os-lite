# Gate 0 — canonical bootstrap qualification

Date: 2026-09-13

## Verdict

**PASS — `supabase/bootstrap/production_schema_20260913.sql` is the qualified standalone Gate 0 bootstrap for the current production-schema baseline.**

This verdict is limited to reconstructing the current application-owned database schema on a compatible Supabase environment. It is not authorization to apply any Gate 002 / Phase 1B migration to production and is not authorization to merge the PR.

## Canonical artifact identity

- path: `supabase/bootstrap/production_schema_20260913.sql`
- Git blob SHA: `2e4860e499c36c50032a5ea2e2ce48247115643c`
- bytes: `100307`
- MD5 observed during rehearsal transfer: `2485a6ba8e65d13e53c2bc323807d7c9`
- SHA-256: `188be8b6bc309c911f9973d00d1bbb158108cecfe6927aacf8a4f50d2c6cae4d`
- sidecar: `production_schema_20260913.sha256`

The artifact was assembled mechanically from Git-resident sources. The embedded Identity Phase 1A source was accepted only after its exact historical file had been archived and independently verified at 83,433 bytes, MD5 `ec71b6ffea682f6ae36ace47d5632fa3`, SHA-256 `70adae1b00c135a220a7116b52f87286ffd94d0bbd59b7803f7ef824f4f62670`.

## Exact Git-artifact replay proof

The 100,307-byte candidate produced by GitHub was transferred byte-for-byte to the existing zero-cost rehearsal Supabase project. Rehearsal recomputed the same candidate identity before execution:

- bytes `100307`
- MD5 `2485a6ba8e65d13e53c2bc323807d7c9`
- SHA-256 `188be8b6bc309c911f9973d00d1bbb158108cecfe6927aacf8a4f50d2c6cae4d`

The test then ran inside a rollback-only transaction. The only transformation before execution was mechanical removal of the candidate's outer `BEGIN`/`COMMIT`, so the test transaction could control rollback. No schema statement inside the artifact was edited or substituted.

After rebuilding the clean application-owned surface, the production equivalence oracle returned exactly:

- fingerprint: `e100181fbc05659e2e9fbcb2c3b296b1`
- normalized object lines: `584`

Result: **PASS**.

## Functional smoke proof against the exact candidate

The same rollback-only replay then validated:

1. `auth.users` insertion creates `users_profile` through the reconstructed trigger.
2. Auth email changes synchronize into `users_profile`.
3. Runtime `authenticated` RLS exposes only the caller's own profile.
4. Own-profile allowed-column update succeeds; cross-user update affects zero rows.
5. Column ACL permits update of allowed profile fields and blocks direct update of protected `email`.
6. PUBLIC, `anon`, `authenticated` and `service_role` have no direct CRUD privilege on the seven Phase 1A canonical tables.
7. `vida_reconciliation_operator` executes `canonical_reconcile` but has no direct INSERT privilege on `reconciliation_record`.
8. Synthetic `CONFIRMED_NEW` reconciliation creates exactly one source, one record and one EconomicEntity.
9. Repeating the same `p_record_id` is idempotent.

Result: **PASS**.

## Rollback / cleanliness proof

After rollback, rehearsal read-back returned to its pre-test state:

- `auth.users = 15`
- `users_profile = 15`
- `prontuario_patrimonial = 1`
- `economic_entities = 0`
- `reconciliation_source = 1`
- `reconciliation_record = 1`
- `planning_engagements = 0`
- synthetic `gate0-git-*` users = `0`

Temporary PostgREST transfer tables were removed after qualification. One-shot GitHub workflows used only for byte transport/assembly/promotion were removed from the branch after successful execution.

## Promotion proof

The qualified candidate was promoted by Git rename only. The SQL bytes were not altered during promotion: the canonical path retains Git blob SHA `2e4860e499c36c50032a5ea2e2ce48247115643c`, size 100,307 bytes and SHA-256 `188be8b6bc309c911f9973d00d1bbb158108cecfe6927aacf8a4f50d2c6cae4d`.

## Boundaries

- Production database: unchanged.
- `main`: unchanged.
- Gate 002 production apply: still OPEN / NOT AUTHORIZED.
- PR merge: not authorized by this qualification.
