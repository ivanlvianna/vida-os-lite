# Bootstrap baseline — status

Status: **QUALIFIED / CANONICAL FOR THE CURRENT GATE 0 PRODUCTION-SCHEMA BASELINE**.

Canonical artifact:

- `production_schema_20260913.sql`
- bytes: `100307`
- SHA-256: `188be8b6bc309c911f9973d00d1bbb158108cecfe6927aacf8a4f50d2c6cae4d`
- Git blob SHA: `2e4860e499c36c50032a5ea2e2ce48247115643c`
- digest sidecar: `production_schema_20260913.sha256`

This artifact reconstructs the current application-owned VIDA OS Lite + integrations + Identity Phase 1A schema on a compatible Supabase environment. It does not contain production data or secrets and it does not include the future Gate 002 / Phase 1B rollout.

## Why a standalone bootstrap was necessary

The production migration ledger begins after several Lite objects already existed. Replaying `../history/` alone therefore cannot reconstruct a blank database: early tracked migrations alter `users_profile`, `prontuario_patrimonial` and `diagnosticos` rather than creating them, and the ledger does not contain the original creation of `diagnosticos_vida`.

The canonical bootstrap is a direct-current-state reconstruction assembled mechanically from verified Git-resident sources, including the now fully recovered exact Identity Phase 1A historical migration.

## Qualification evidence

The canonical SQL was first assembled as a byte-identified candidate in Git, transferred byte-for-byte into the existing zero-cost rehearsal project and replayed inside a rollback-only clean-install transaction. Before execution, rehearsal recomputed the same artifact identity observed in Git.

The replay passed the production schema equivalence oracle exactly:

- production fingerprint: `e100181fbc05659e2e9fbcb2c3b296b1`
- reconstructed fingerprint: `e100181fbc05659e2e9fbcb2c3b296b1`
- normalized object lines: `584 / 584`

The same exact candidate then passed functional database smoke tests covering Auth profile creation, Auth email synchronization, runtime RLS isolation, column ACLs, canonical-table isolation and idempotent Phase 1A reconciliation.

After rollback, rehearsal returned to its prior state with zero synthetic users remaining. The qualified SQL was then promoted by Git rename only; its bytes and Git blob remained unchanged.

Full evidence: `../tests/GATE_0_CANONICAL_BOOTSTRAP_QUALIFICATION.md`.

## Completed proof work

- [x] Read-only inventory of the live production public schema.
- [x] Production equivalence oracle v2 in `SCHEMA_EQUIVALENCE_QUERY.sql`.
- [x] Acceptance fingerprint `e100181fbc05659e2e9fbcb2c3b296b1` across 584 normalized object lines.
- [x] Current structural definitions/invariants of the pre-ledger Lite objects documented.
- [x] Exact function source normalization where the oracle includes `pg_get_functiondef`.
- [x] Hotmart, Scanner VIDA Empresa and `vida_public_submissions` current-state sources recovered.
- [x] Identity Phase 1A historical SQL physically archived byte-for-byte in Git: 83,433 bytes, MD5 `ec71b6ffea682f6ae36ace47d5632fa3`, SHA-256 `70adae1b00c135a220a7116b52f87286ffd94d0bbd59b7803f7ef824f4f62670`.
- [x] Standalone bootstrap assembled with no runtime dependency on the rehearsal migration ledger.
- [x] Exact Git-artifact shadow replay against a clean application-owned surface.
- [x] Schema equivalence PASS at 584/584 lines.
- [x] Functional database smoke PASS against the exact Git artifact.
- [x] Rollback/read-back cleanliness PASS.
- [x] Qualified candidate promoted without changing SQL bytes.
- [x] Gate 002 forward chain independently qualified in the zero-cost rehearsal project.

## Boundaries

This qualification does **not** authorize:

- applying Gate 002 / Phase 1B to production;
- merging PR #1 into `main`;
- automatic creation/backfill of clients or EconomicEntities;
- treating the current bootstrap as the schema of a future VIDA OS release after additional migrations are applied.

If the production schema intentionally changes, this baseline and its fingerprint must be versioned again rather than silently edited in place.
