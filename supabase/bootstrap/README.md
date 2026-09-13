# Bootstrap baseline — status

Status: **SHADOW CLEAN-INSTALL QUALIFIED / standalone canonical assembly still pending**.

The production migration ledger starts after some Lite tables already existed. Therefore, replaying `../history/` alone cannot reconstruct a blank database. The first tracked migration reads/alters `users_profile`, `prontuario_patrimonial` and `diagnosticos` instead of creating them, and the tracked ledger also does not contain the original creation of `diagnosticos_vida`.

Under the explicit zero-cost constraint, the bootstrap has now been qualified by reconstructing the application-owned `public` surface inside a rollback-only transaction in the existing rehearsal Supabase project while retaining the platform-managed schemas (`auth`, migration ledger, etc.). That reconstruction matched production exactly under the v2 equivalence oracle and passed database-level Auth/RLS/ACL/reconciliation smoke tests. See `../tests/GATE_0_CLEAN_BOOTSTRAP_EVIDENCE.md`.

## Completed proof work

- [x] Read-only inventory of the live production public schema.
- [x] Production equivalence oracle strengthened to v2 in `SCHEMA_EQUIVALENCE_QUERY.sql`.
- [x] Current acceptance fingerprint v2 captured: `e100181fbc05659e2e9fbcb2c3b296b1` across 584 normalized object lines.
- [x] v2 covers the 17 public relations / 148 columns / 65 constraints / 42 indexes / 13 policies / 12 public functions / 9 relevant triggers, plus schema ACL, 14 column-ACL entries, effective table/function ACLs, function ownership and the VIDA technical roles/memberships.
- [x] The old `997d3e04bd3e160bc9368f55560cf59a` / 552-line fingerprint is explicitly superseded as the acceptance oracle because it did not cover column ACLs or VIDA technical-role semantics.
- [x] Current structural definitions/invariants of the four pre-ledger/untracked Lite objects documented in `PRODUCTION_SCHEMA_BASELINE_20260913.md`.
- [x] Legacy Lite reconstruction staged at `drafts/legacy_lite_current_state_20260913.DRAFT.sql` and normalized to the exact production function source where required by the equivalence oracle.
- [x] Direct-current-state build order and proof gates frozen in `BOOTSTRAP_BUILD_PLAN.md`.
- [x] Non-executable technical-role reconstruction staged at `drafts/identity_roles_current_state_20260913.DRAFT.sql`.
- [x] Non-executable Phase 1A structural reconstruction staged at `drafts/phase1a_structure_current_state_20260913.DRAFT.sql`.
- [x] Non-executable Phase 1A final ownership/ACL reconstruction staged at `drafts/phase1a_ownership_acl_current_state_20260913.DRAFT.sql`.
- [x] Hotmart, Scanner VIDA Empresa and `vida_public_submissions` current-state bootstrap candidates staged under `drafts/integrations/` from recovered authoritative migration sources.
- [x] Identity Phase 1A authoritative body content recovered and independently fingerprinted: 83,433 bytes; MD5 `ec71b6ffea682f6ae36ace47d5632fa3`; SHA-256 `70adae1b00c135a220a7116b52f87286ffd94d0bbd59b7803f7ef824f4f62670`.
- [x] Zero-cost shadow clean reconstruction matched the production v2 oracle exactly: `e100181fbc05659e2e9fbcb2c3b296b1`, 584/584 lines.
- [x] Clean-bootstrap smoke harness passed: Auth profile creation, email sync, runtime RLS isolation, column ACLs, canonical-table isolation, intake isolation and synthetic/idempotent Phase 1A reconciliation.
- [x] Post-test rollback/read-back confirmed rehearsal data returned to its pre-test state with no synthetic smoke users remaining.
- [x] Gate 002 forward chain independently qualified in the zero-cost rehearsal project.

## Still required before a standalone canonical bootstrap file is promoted

- [ ] Complete byte-for-byte Git archival of the large Identity Phase 1A historical migration. The content is recovered and hash-verified; the remaining issue is final Git transport/archival.
- [ ] Assemble one standalone direct-current-state bootstrap artifact in Git using only verified source material, with no production data or secrets and no runtime dependency on the rehearsal migration ledger.
- [ ] Re-run the same equivalence oracle and smoke harness against that Git-hosted standalone artifact.
- [ ] Run application/auth smoke tests with the app pointed at a compatible disposable clean installation if such an environment can be provided without violating the zero-cost constraint.

The database reconstruction logic is now qualified. What is still intentionally blocked is promotion of a single standalone file as the canonical blank-database bootstrap before its large Phase 1A payload is physically archived and the assembled Git artifact is replayed as the source under test.
