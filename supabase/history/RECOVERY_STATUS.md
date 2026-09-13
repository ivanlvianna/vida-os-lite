# Historical migration recovery status

Production migration ledger contains seven recorded migrations.

Exact SQL bodies recovered into Git history on this branch:

- [x] `20260716005752_harden_vida_os_lite_rls_and_profiles.sql`
- [x] `20260727220336_create_hotmart_operations.sql`
- [x] `20260728020506_create_scanner_vida_empresa_submissions.sql`
- [x] `20260911032427_legacy_safety_hardening_auth_fks.sql`
- [ ] `20260912222334_identity_phase1a_1a5_production_70adae1b.sql`
- [x] `20260913013410_security_hardening_profiles_and_diagnostics.sql`
- [x] `20260913013519_create_vida_public_submissions_intake.sql`

The remaining Identity Phase 1A body has been re-read directly from the authoritative production migration ledger and its authoritative fingerprint remains `ec71b6ffea682f6ae36ace47d5632fa3` (MD5), 83,433 bytes. A similarly named Library artifact was explicitly rejected as a substitute because its MD5/size do not match the production ledger. See `20260912222334_identity_phase1a_1a5_production_70adae1b.RECOVERY.md`.

Do not recreate the remaining file from memory, a similarly named artifact, or inferred live state. It must be archived byte-for-byte from the authoritative migration ledger and then matched against `MANIFEST.md`.

Important: even when all seven historical bodies are archived, this folder is forensic history, not a blank-database bootstrap. The first tracked migration assumes legacy tables already existed; `../bootstrap/` therefore remains non-executable until a complete fresh-schema bootstrap is independently proven.
