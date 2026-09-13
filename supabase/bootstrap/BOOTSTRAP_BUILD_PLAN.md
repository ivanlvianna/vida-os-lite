# VIDA OS™ — Bootstrap Build Plan

Status: **QUALIFIED / CLOSED FOR CURRENT GATE 0 BASELINE**

Canonical output:

`supabase/bootstrap/production_schema_20260913.sql`

Artifact identity:

- bytes: `100307`
- SHA-256: `188be8b6bc309c911f9973d00d1bbb158108cecfe6927aacf8a4f50d2c6cae4d`
- Git blob SHA: `2e4860e499c36c50032a5ea2e2ce48247115643c`
- production-equivalence fingerprint after replay: `e100181fbc05659e2e9fbcb2c3b296b1` / 584 normalized lines

## Objective

Provide a reproducible, standalone bootstrap for the current application-owned VIDA OS Lite production-schema baseline on a compatible Supabase environment, without relying on the incomplete beginning of the historical migration ledger and without embedding production data or secrets.

## Source discipline

The bootstrap is assembled only from verified Git-resident sources:

1. Current Legacy Lite structural state (`users_profile`, `prontuario_patrimonial`, `diagnosticos`, `diagnosticos_vida`, policies, ACLs, functions and Auth triggers).
2. Current Hotmart operational schema.
3. Scanner VIDA Empresa intake schema.
4. VIDA public submissions intake schema.
5. Exact archived Identity Phase 1A + 1A.5 historical SQL, with only its outer transaction boundary removed mechanically so all components can live under one bootstrap transaction.

The Identity Phase 1A source is independently fixed by all of the following:

- 83,433 bytes
- MD5 `ec71b6ffea682f6ae36ace47d5632fa3`
- SHA-256 `70adae1b00c135a220a7116b52f87286ffd94d0bbd59b7803f7ef824f4f62670`
- Git blob SHA `5c8f71dfd8b62a0b8b28d24d214478af7715cc68`

No inferred replacement of historical SQL is accepted.

## Qualification sequence — completed

1. Production catalog inventory and ACL/role inventory captured read-only.
2. Equivalence oracle v2 frozen in `SCHEMA_EQUIVALENCE_QUERY.sql`.
3. Production acceptance fingerprint fixed at `e100181fbc05659e2e9fbcb2c3b296b1`, 584 normalized lines.
4. Pre-ledger/current-state components reconstructed from production evidence and recovered migration sources.
5. Exact Identity Phase 1A body physically archived in Git.
6. Standalone bootstrap candidate assembled mechanically in Git.
7. Exact Git candidate transferred byte-for-byte into the existing zero-cost rehearsal project.
8. Candidate identity re-hashed in rehearsal before execution.
9. Candidate replayed against a clean application-owned surface inside a rollback-only transaction.
10. Equivalence oracle returned exactly 584/584 lines and the production fingerprint.
11. Database smoke tests passed for Auth profile creation, email sync, runtime RLS isolation, column ACLs, canonical-table isolation and idempotent canonical reconciliation.
12. Rollback/read-back confirmed the rehearsal project returned to its original data state with no synthetic users remaining.
13. Candidate promoted by Git rename only; SQL bytes did not change.

Full proof: `../tests/GATE_0_CANONICAL_BOOTSTRAP_QUALIFICATION.md`.

## Operational use

This bootstrap is the baseline for creating a current Gate 0 schema on a compatible Supabase environment. It is not a migration to run over the existing production database; production already contains this state through its historical evolution.

Future intentional schema changes must be represented by new migrations and a new versioned bootstrap/fingerprint rather than by silently editing this baseline.

## Out of scope / not authorized

- Gate 002 / Phase 1B production application.
- Merge to `main`.
- Production data migration or backfill.
- Automatic EconomicEntity/client creation.
- Treating this 2026-09-13 baseline as canonical after future migrations without re-versioning.
