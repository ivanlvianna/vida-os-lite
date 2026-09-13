# Bootstrap baseline — status

Status: **NOT YET EXECUTABLE / recovery and clean-install proof still pending**.

The production migration ledger starts after some Lite tables already existed. Therefore, replaying `../history/` alone cannot reconstruct a blank database. The first tracked migration reads/alters `users_profile`, `prontuario_patrimonial` and `diagnosticos` instead of creating them, and the tracked ledger also does not contain the original creation of `diagnosticos_vida`.

## Completed proof work

- [x] Read-only inventory of the live production public schema.
- [x] Production equivalence oracle captured in `SCHEMA_EQUIVALENCE_QUERY.sql`.
- [x] Baseline fingerprint captured: `997d3e04bd3e160bc9368f55560cf59a` across 552 normalized object lines.
- [x] Baseline counts captured: 17 public tables, 148 columns, 65 constraints, 42 indexes, 13 policies, 12 public functions and 9 relevant non-internal triggers.
- [x] Current structural definitions/invariants of the four pre-ledger/untracked Lite objects documented in `PRODUCTION_SCHEMA_BASELINE_20260913.md`.
- [x] A non-executable reconstruction of those four legacy Lite objects is stored in `drafts/legacy_lite_current_state_20260913.DRAFT.sql` for review and later clean-install validation.
- [x] Gate 002 forward chain independently qualified in the zero-cost rehearsal project.

## Still required before this directory becomes executable

- [ ] Complete byte-for-byte Git archival of the remaining large Identity Phase 1A historical migration (history is forensic evidence, not the bootstrap itself).
- [ ] Generate a direct-current-state bootstrap DDL containing the full approved production baseline, with no production data or secrets.
- [ ] Represent required owners/roles and ACL semantics reproducibly.
- [ ] Install the bootstrap on a blank compatible Supabase project/environment.
- [ ] Run `SCHEMA_EQUIVALENCE_QUERY.sql` against that clean install and reconcile any difference against the production oracle.
- [ ] Run application/auth smoke tests against the clean installation.

The canonical bootstrap file may be promoted to executable only after those proofs pass. Until then, do not create or label a guessed `production_schema_20260913.sql` as canonical, and do not treat historical migrations as a blank-database bootstrap chain.
