# Recovery note — `20260912222334_identity_phase1a_1a5_production_70adae1b`

Status: **authoritative ledger body identified; Git archival pending exact byte transfer**.

Authoritative source: `supabase_migrations.schema_migrations` in production project `dlobyyzixcandloxbeth`.

- version: `20260912222334`
- name: `identity_phase1a_1a5_production_70adae1b`
- SQL bytes: `83433`
- SQL MD5: `ec71b6ffea682f6ae36ace47d5632fa3`

The production SQL body was re-read directly from the migration ledger during Gate 0 recovery. The connector can return the body, including an exact base64 representation, but this large payload has not yet been committed as a Git blob. Until that byte transfer is completed and re-hashed from Git, this migration MUST remain marked pending in `RECOVERY_STATUS.md`.

A Library file named `migration_b_identity_phase1.sql` was evaluated as a possible source and rejected: its observed MD5 was `cd47d869aa7bc5ed74ae5ab1eed959c6` and its size was 79,979 bytes, so it is not the SQL body applied in production. Filename similarity is not accepted as artifact identity.

Do not substitute, edit, normalize, reformat, or reconstruct this migration from the current database schema. Recovery must be byte-for-byte from the production migration ledger.
