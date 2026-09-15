# PC Full-History Namespace Replay Gate — 2026-09-15

Status: **PASS**

Gate: `PC-FULL-HISTORY-NAMESPACE-REPLAY-GATE-001`

## Scope

This gate replays the complete current Planning Content migration history recorded in the canonical D3 Supabase migration ledger, from `20260915003143 pc_m01_actor_authorship_infrastructure` through `20260915022715 pc_m09_staff_summary_visibility_fix`.

The replay was executed inside a temporary schema named `pc_full_history_replay` in one explicit transaction and ended with `ROLLBACK`. No Planning Content migration-history rows were inserted, changed, deleted, or repaired by this gate.

The replay mechanically redirected Planning Content objects from `public` to the isolated schema while preserving canonical Core dependencies in `public`. PC-M08 dynamic policy/GRANT targets were redirected explicitly. The post-PC-M09 reconciliation migration `20260915014703 pc_freeze_reconcile_a_context_fks` contains one Core alteration that adds `uq_planning_engagement_entities_account_engagement_entity`; because the canonical D3 Core already contains that exact required constraint, only that already-satisfied Core DDL statement was suppressed in the isolated replay. All Planning Content DDL in the migration remained replayed.

## Executed result

The complete 28-migration Planning Content sequence compiled in order and produced:

- 51 Planning Content tables
- 399 columns
- 314 constraints
- 126 indexes
- 40 `pc_%` functions
- 74 non-internal triggers
- 51 RLS policies
- 12 `pc_rm_%` views
- 504 table grants
- 75 routine grants

These counts equal the current canonical D3 catalog.

## Definition equivalence

After symmetric schema-name normalization, the replayed catalog and canonical `public` catalog were compared structurally.

Exact matches:

- columns MD5: `e96b4174c491c97f03c3dbcc20b8f9e4`
- constraints MD5: `e6c3e5a48a899054fabd089eaee51d1d`
- indexes MD5: `893385bd72389008c34b48e2d7f824f9`
- functions MD5: `1026d9c1df2adb8d988f66466b2489ad`
- triggers MD5: `e73c072ece89da32319cadb824229ed5`
- policies MD5: `c56f139fd5637c3a8be752d1d42ced94`
- views MD5: `63675e07daaaa508b5768abe230f9e9f`
- table grants MD5: `093bbf6569e282babeb6a74a1928830d`
- routine grants MD5: `a6865834ee39fb609489d30c2c095437`

For constraints, triggers and views, set-difference checks after symmetric schema normalization returned zero rows in both directions.

## Cleanup verification

After `ROLLBACK`:

- schema `pc_full_history_replay`: absent
- canonical migration count: 30
- latest migration: `20260915022715 pc_m09_staff_summary_visibility_fix`
- canonical public Planning Content tables: 51
- canonical public `pc_rm_%` views: 12

No persistent D3 change was made by this gate.

## Governance interpretation

This gate proves that the **current canonical Planning Content migration history can be replayed in order into an isolated namespace against the current canonical VIDA OS Core dependencies and reproduces the current Planning Content catalog exactly**.

It does **not** prove a clean-room reconstruction on a fully independent empty PostgreSQL/Supabase database. Therefore:

- `PC-FULL-HISTORY-NAMESPACE-REPLAY-GATE-001 = PASS`
- `PC-INDEPENDENT-BOOTSTRAP-REPLAY-GATE-001 = NOT YET PASS`

The independent-bootstrap gate remains separate because the binary bootstrap/history artifacts previously preserved in Git were found to be corrupted during transport. They must not be used as canonical replay evidence.