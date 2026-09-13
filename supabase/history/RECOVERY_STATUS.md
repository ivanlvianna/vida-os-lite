# Historical migration recovery status

Production migration ledger contains seven recorded migrations.

Recovered into Git history on this branch:

- [x] `20260716005752_harden_vida_os_lite_rls_and_profiles.sql`

Fingerprint-only / exact SQL recovery still pending:

- [ ] `20260727220336_create_hotmart_operations.sql`
- [ ] `20260728020506_create_scanner_vida_empresa_submissions.sql`
- [ ] `20260911032427_legacy_safety_hardening_auth_fks.sql`
- [ ] `20260912222334_identity_phase1a_1a5_production_70adae1b.sql`
- [ ] `20260913013410_security_hardening_profiles_and_diagnostics.sql`
- [ ] `20260913013519_create_vida_public_submissions_intake.sql`

Do not recreate pending files from memory or inferred live state. They must be recovered from the authoritative migration ledger or another verifiable source and matched against the MD5 values in `MANIFEST.md`.

This status file exists to prevent an incomplete historical archive from being mistaken for a complete migration chain.
