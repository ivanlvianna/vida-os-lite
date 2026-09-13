# Historical migration recovery status

Production migration ledger contains seven recorded migrations.

## Recovery versus Git archival

All **7/7 authoritative SQL bodies are now recovered** at the content level. Six are already archived as exact SQL files in this Git branch. The large Identity Phase 1A body has also been reconstructed byte-for-byte and cryptographically matched to production, but its final 83,433-byte Git file transfer is still pending because the current GitHub connector does not accept a mounted local file directly as file content.

Exact SQL bodies already archived in Git on this branch:

- [x] `20260716005752_harden_vida_os_lite_rls_and_profiles.sql`
- [x] `20260727220336_create_hotmart_operations.sql`
- [x] `20260728020506_create_scanner_vida_empresa_submissions.sql`
- [x] `20260911032427_legacy_safety_hardening_auth_fks.sql`
- [ ] `20260912222334_identity_phase1a_1a5_production_70adae1b.sql` — **content recovered and verified; Git body transfer pending**
- [x] `20260913013410_security_hardening_profiles_and_diagnostics.sql`
- [x] `20260913013519_create_vida_public_submissions_intake.sql`

Authoritative Identity Phase 1A identity:

- bytes: `83433`
- MD5: `ec71b6ffea682f6ae36ace47d5632fa3`
- SHA-256: `70adae1b00c135a220a7116b52f87286ffd94d0bbd59b7803f7ef824f4f62670`
- expected Git blob SHA after exact transfer: `5c8f71dfd8b62a0b8b28d24d214478af7715cc68`

The SHA-256 independently matches the hash recorded in the historical Release Gate 3.13 plan for `migration_b_identity_phase1.sql`. See `20260912222334_identity_phase1a_1a5_production_70adae1b.RECOVERY.md` for the recovery proof.

The earlier failed partial transport remains rejected and is not evidence. A similarly named older Library file also remains rejected as the historical body unless transformed by the proven authoritative delta and re-hashed to the exact values above.

Important: even after the final Git transfer makes archival 7/7, this folder is forensic history, not a blank-database bootstrap. The first tracked migration assumes legacy tables already existed; `../bootstrap/` therefore remains non-executable until a complete fresh-schema bootstrap is independently proven.
