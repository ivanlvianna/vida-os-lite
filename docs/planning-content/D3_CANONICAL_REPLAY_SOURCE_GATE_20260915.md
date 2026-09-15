# D3 Canonical Replay Source Gate — 2026-09-15

## Decision

For independent bootstrap/replay proof, the only admissible canonical migration source is the exact SQL retained by D3 in `supabase_migrations.schema_migrations.statements`.

This supersedes binary `.gz` / `.tar.gz` copies transported through the GitHub connector, because those copies failed byte-integrity checks during disposable PostgreSQL proof runs.

## Evidence established

- D3 current migration history: 30 migrations total.
- Core baseline: v0.6 + v0.7.
- Planning Content history: 28 migrations.
- Full wrapped migration history: 330325 bytes; MD5 `9803080cb70257ff02f4cfa4f6249415`.
- Planning Content wrapped subset: 259251 bytes; MD5 `3ba49601811307725c9e19aba790f68e`.
- M01–M06 local recovered SQL files were independently checked and match the D3 ledger byte-for-byte.
- Later migrations were applied as split bodies that are not recoverable as simple contiguous byte slices of the preserved candidate files; therefore they must be exported from the D3 migration ledger rather than inferred or reconstructed.
- Current D3 Planning Content catalog oracle was re-captured on 2026-09-15 and matches the previously recorded oracle exactly.

## Gate status

`PC-CANONICAL-REPLAY-SOURCE-GATE-001 = PASS`

This PASS means the authoritative replay source and deterministic target oracle are known and stable.

It does **not** mean the independent PostgreSQL bootstrap replay has passed. That separate gate remains open until the exact ledger SQL is materialized in the proof environment, all 30 migrations execute successfully in order, and the resulting catalog equals the D3 oracle.

## Next admissible proof

1. Export exact stored SQL from `schema_migrations.statements` as text-safe chunks.
2. Verify per-migration byte length and MD5 against `supabase/history/D3_CANONICAL_MIGRATION_LEDGER_20260915.md`.
3. Reassemble in a disposable PostgreSQL 17 environment.
4. Provide only the minimal Supabase Auth compatibility surface required by the core migration; do not edit canonical migration SQL.
5. Execute the 30 migrations in exact order, stopping at first failure.
6. Recompute the catalog oracle and compare with `supabase/history/D3_CANONICAL_CATALOG_ORACLE_20260915.json`.
7. Only then may `PC-INDEPENDENT-BOOTSTRAP-REPLAY-GATE-001` be classified PASS.

No permanent schema change, merge, deployment, or D3 mutation is authorized by this document.