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
- [x] Non-executable Legacy Lite reconstruction staged at `drafts/legacy_lite_current_state_20260913.DRAFT.sql`.
- [x] Direct-current-state build order and proof gates frozen in `BOOTSTRAP_BUILD_PLAN.md`.
- [x] Non-executable technical-role reconstruction staged at `drafts/identity_roles_current_state_20260913.DRAFT.sql`.
- [x] Non-executable Phase 1A structural reconstruction staged at `drafts/phase1a_structure_current_state_20260913.DRAFT.sql`.
- [x] Non-executable Phase 1A final ownership/ACL reconstruction staged at `drafts/phase1a_ownership_acl_current_state_20260913.DRAFT.sql`.
- [x] Hotmart, Scanner VIDA Empresa and `vida_public_submissions` current-state bootstrap candidates staged under `drafts/integrations/` using the already recovered authoritative migration blobs as source candidates; clean-install equivalence is still required before promotion.
- [x] Gate 002 forward chain independently qualified in the zero-cost rehearsal project.

## Still required before this directory becomes executable

- [ ] Complete byte-for-byte Git archival of the remaining large Identity Phase 1A historical migration (history is forensic evidence, not the bootstrap itself).
- [ ] Materialize the Phase 1A current function/trigger source without retyping or semantically normalizing the authoritative production source.
- [ ] Assemble the full direct-current-state bootstrap with no production data or secrets.
- [ ] Represent required owners/roles, role memberships and ACL semantics reproducibly.
- [ ] Install the bootstrap on a blank compatible Supabase project/environment.
- [ ] Run `SCHEMA_EQUIVALENCE_QUERY.sql` against that clean install and reconcile any difference against the v2 production oracle.
- [ ] Run application/auth smoke tests against the clean installation.

The canonical bootstrap may be promoted to executable only after those proofs pass. Until then, do not create or label a guessed `production_schema_20260913.sql` as canonical, and do not treat historical migrations as a blank-database bootstrap chain.
