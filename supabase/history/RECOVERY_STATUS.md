# Historical migration recovery status

Production migration ledger contains seven recorded migrations.

## Recovery and Git archival

**CLOSED — 7/7 authoritative SQL bodies are recovered and physically archived in Git on this branch.**

- [x] `20260716005752_harden_vida_os_lite_rls_and_profiles.sql`
- [x] `20260727220336_create_hotmart_operations.sql`
- [x] `20260728020506_create_scanner_vida_empresa_submissions.sql`
- [x] `20260911032427_legacy_safety_hardening_auth_fks.sql`
- [x] `20260912222334_identity_phase1a_1a5_production_70adae1b.sql`
- [x] `20260913013410_security_hardening_profiles_and_diagnostics.sql`
- [x] `20260913013519_create_vida_public_submissions_intake.sql`

Authoritative Identity Phase 1A identity and archived Git proof:

- bytes: `83433`
- MD5: `ec71b6ffea682f6ae36ace47d5632fa3`
- SHA-256: `70adae1b00c135a220a7116b52f87286ffd94d0bbd59b7803f7ef824f4f62670`
- Git blob SHA: `5c8f71dfd8b62a0b8b28d24d214478af7715cc68`

The archival workflow fetched the exact authoritative ledger body, verified all three content identities before writing, re-verified the resulting working-tree file, and committed that exact 83,433-byte artifact. GitHub's contents API subsequently reports the expected Git blob SHA and exact byte size.

The SHA-256 also independently matches the hash recorded in the historical Release Gate 3.13 plan for `migration_b_identity_phase1.sql`.

The earlier failed partial transport and the similarly named older Library artifact remain rejected historical sources. They are not part of the archived chain.

## Bootstrap distinction

Historical recovery and blank-database bootstrap are separate concerns. Historical recovery is now complete. The standalone bootstrap has also subsequently been assembled and qualified under `../bootstrap/production_schema_20260913.sql`; see `../tests/GATE_0_CANONICAL_BOOTSTRAP_QUALIFICATION.md` for its independent equivalence and smoke proof.
