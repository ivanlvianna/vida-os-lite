# VIDA OS™ — Strict D3 Replay Transport Blocker — 2026-09-15

## Scope

This note records the current state of `PC-INDEPENDENT-BOOTSTRAP-REPLAY-GATE-001` without changing D3, merging any branch, or weakening the acceptance criteria.

## What is already proven

1. `PC-CANONICAL-REPLAY-SOURCE-GATE-001 = PASS`: the authoritative source is the exact SQL retained by D3 in `supabase_migrations.schema_migrations.statements`.
2. D3 contains 30 migrations in the target history: canonical v0.6 + v0.7 + 28 Planning Content migrations.
3. M01–M06 recovered local SQL was independently shown byte-for-byte identical to the D3 ledger.
4. A small text-safe transport sample was verified end-to-end for v0.7, PC-M01, the targeted-index migration and the final M09 visibility fix. The first index transport was deliberately rejected because its bytes/hash differed; a corrected D3 export then passed.
5. The canonical Gate 0 standalone bootstrap `supabase/bootstrap/production_schema_20260913.sql` is separately qualified. That proof reconstructed the application-owned baseline and reproduced its acceptance fingerprint with functional smoke tests and rollback.
6. The full 28-migration Planning Content history has already replayed transactionally in an isolated namespace against canonical Core dependencies and matched the D3 Planning Content catalog. This is strong schema/replay evidence, but it is not the independent PostgreSQL-17 byte-exact 30-migration proof required by the strict gate.

## Transport experiments rejected

The following are NOT admissible canonical replay sources:

- GitHub-resident `.gz` / `.tar.gz` copies that failed integrity/readability checks;
- superseded `byteexact_chunks` binary transport;
- oversized manual Base64 transfer.

An oversized manual transfer of the first v0.6 Core part demonstrated the problem concretely:

- expected D3 part: 17,052 bytes, MD5 `d5eac4e58c4a36d25ab408c19ce8bbdf`;
- transported Git blob: 34,085 bytes, MD5 `d3632c2c6a95a38e35d3d6b1c3da8516`;
- CI rejected it before execution;
- the invalid artifact was then deleted from the branch.

## Connector constraint

Current connected tools provide:

- Supabase: SQL query/migration/branch/project operations, but no dump/export-file primitive;
- GitHub: text/blob repository operations, but no upload-from-local-file bridge from the assistant working container;
- GitHub Actions: no configured `DATABASE_URL`, `SUPABASE_DB_URL`, `SUPABASE_DATABASE_URL`, `SUPABASE_DB_PASSWORD` or `SUPABASE_ACCESS_TOKEN` secret for D3.

A temporary Data API export surface would require persistent D3 DDL/grants/RLS changes. That is deliberately not performed without explicit authorization and is unnecessary for the already-qualified operational schema.

## Gate classification

`PC-INDEPENDENT-BOOTSTRAP-REPLAY-GATE-001 = OPEN / BLOCKED ON SAFE EXACT-LEDGER TRANSPORT`

This is a reproducibility-proof transport blocker, not evidence of a schema defect, SQL failure, behavioral failure, or D3 catalog mismatch.

## Acceptance criteria remain unchanged

The strict gate may be marked PASS only after all of the following occur:

1. exact D3 SQL for all 30 migrations is materialized in the proof environment;
2. each migration matches the D3 byte length and MD5 before execution;
3. disposable PostgreSQL 17 receives only the minimal Supabase Auth compatibility surface outside the canonical migrations;
4. all 30 migrations execute in exact order, stopping at first failure;
5. the resulting catalog matches the D3 canonical oracle;
6. the proof environment is disposable and D3 remains unchanged.

No PASS is claimed by this document.
