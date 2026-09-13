# Recovery note — `20260912222334_identity_phase1a_1a5_production_70adae1b`

Status: **CLOSED — exact production-ledger SQL body recovered, cryptographically verified and physically archived in Git.**

Authoritative source: `supabase_migrations.schema_migrations` in production project `dlobyyzixcandloxbeth`.

- version: `20260912222334`
- name: `identity_phase1a_1a5_production_70adae1b`
- SQL bytes: `83433`
- SQL MD5: `ec71b6ffea682f6ae36ace47d5632fa3`
- SQL SHA-256: `70adae1b00c135a220a7116b52f87286ffd94d0bbd59b7803f7ef824f4f62670`
- Git blob SHA: `5c8f71dfd8b62a0b8b28d24d214478af7715cc68`
- archived path: `supabase/history/20260912222334_identity_phase1a_1a5_production_70adae1b.sql`

## Recovery proof

The production ledger body was re-read directly. A similarly named Library artifact was not accepted as-is because its bytes do not match production. The authoritative body was reconstructed and independently matched on byte length, MD5 and SHA-256; its SHA-256 also matches the value recorded by the historical Release Gate 3.13 execution plan for `migration_b_identity_phase1.sql`.

For final archival, a one-shot zero-cost workflow read the authoritative 83,433-byte ledger body from the existing rehearsal project, verified the expected byte length, MD5 and SHA-256 before writing, re-verified the written file with standard hashing tools, and committed it to the Gate 0 branch. GitHub then reported the exact expected byte length and Git blob SHA `5c8f71dfd8b62a0b8b28d24d214478af7715cc68`.

The temporary export surface and the one-shot workflow were removed immediately after successful archival.

The earlier partial Base64 transport attempt remains rejected. The older Library candidate remains rejected as historical evidence. Neither is used by the canonical history.

## Result

No historical migration body remains missing: production migration history recovery is **7/7 complete**.
