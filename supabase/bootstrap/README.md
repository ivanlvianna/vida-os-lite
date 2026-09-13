# Bootstrap baseline — status

Status: **NOT YET EXECUTABLE / recovery and clean-install proof still pending**.

The production migration ledger starts after some Lite tables already existed. Therefore, replaying `../history/` alone cannot reconstruct a blank database. The first tracked migration reads/alters `users_profile`, `prontuario_patrimonial` and `diagnosticos` instead of creating them, and the tracked ledger also does not contain the original creation of `diagnosticos_vida`.

## Completed proof work

- [x] Read-only inventory of the live production public schema.
- [x] Production equivalence oracle strengthened to v2 in `SCHEMA_EQUIVALENCE_QUERY.sql`.
- [x] Current acceptance fingerprint v2 captured: `e100181fbc05659e2e9fbcb2c3b296b1` across 584 normalized object lines.
- [x] v2 covers the 17 public relations / 148 columns / 65 constraints / 42 indexes / 13 policies / 12 public functions / 9 relevant triggers, plus schema ACL, 14 column-ACL entries, effective table/function ACLs, function ownership and the VIDA technical roles/memberships.
- [x] The old `997d3e04bd3e160bc9368f55560cf59a` / 552-line fingerprint is explicitly superseded as the acceptance oracle because it did not cover column ACLs or VIDA technical-role semantics.
- [x] Current structural definitions/invariants of the four pre-ledger/untracked Lite objects documented in `PRODUCTION_SCHEMA_BASELINE_20260913.md`.
- [x] A non-executable reconstruction of those four legacy Lite objects is stored in `drafts/legacy_lite_current_state_20260913.DRAFT.sql` for review and later clean-install validation.
- [x] Gate 002 forward chain independently qualified in the zero-cost rehearsal project.

## Still required before this directory becomes executable

- [ ] Complete byte-for-byte Git archival of the remaining large Identity Phase 1A historical migration (history is forensic evidence, not the bootstrap itself).
- [ ] Generate a direct-current-state bootstrap DDL containing the full approved production baseline, with no production data or secrets.
- [ ] Represent required owners/roles, role memberships and ACL semantics reproducibly.
- [ ] Install the bootstrap on a blank compatible Supabase project/environment.
- [ ] Run `SCHEMA_EQUIVALENCE_QUERY.sql` against that clean install and reconcile any difference against the v2 production oracle.
- [ ] Run application/auth smoke tests against the clean installation.

The canonical bootstrap may be promoted to executable only after those proofs pass. Until then, do not create or label a guessed `production_schema_20260913.sql` as canonical, and do not treat historical migrations as a blank-database bootstrap chain.
