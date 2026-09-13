# Recovery note — `20260912222334_identity_phase1a_1a5_production_70adae1b`

Status: **exact byte-equivalent SQL body recovered and cryptographically verified outside Git; Git archival of the 83,433-byte body still pending connector transfer**.

Authoritative source: `supabase_migrations.schema_migrations` in production project `dlobyyzixcandloxbeth`.

- version: `20260912222334`
- name: `identity_phase1a_1a5_production_70adae1b`
- SQL bytes: `83433`
- SQL MD5: `ec71b6ffea682f6ae36ace47d5632fa3`
- SQL SHA-256: `70adae1b00c135a220a7116b52f87286ffd94d0bbd59b7803f7ef824f4f62670`
- expected Git blob SHA for the exact recovered bytes: `5c8f71dfd8b62a0b8b28d24d214478af7715cc68`

## Recovery proof

The production ledger body was re-read directly. A similarly named Library artifact was not accepted as-is because its bytes do not match production. Instead, it was used only as a candidate ancestor for a line-level comparison against the authoritative ledger.

The production artifact has 1,639 LF-split rows versus 1,602 rows in the candidate file. Anchor mapping showed four insertion regions totaling exactly 37 rows plus three `search_path` hardening substitutions. Those deltas correspond to the security-hardening comments and the explicit `pg_temp`-last configuration for the three SECURITY DEFINER functions documented in the production artifact.

A recovered local copy was then rebuilt from those exact authoritative line ranges and verified independently with standard local hashing tools. It matches all three authoritative identity checks simultaneously:

- bytes = `83433`
- MD5 = `ec71b6ffea682f6ae36ace47d5632fa3`
- SHA-256 = `70adae1b00c135a220a7116b52f87286ffd94d0bbd59b7803f7ef824f4f62670`

The SHA-256 also matches the hash recorded by the historical Release Gate 3.13 execution plan for `migration_b_identity_phase1.sql`, providing an independent historical provenance check.

The earlier connector-mediated partial Base64 transport attempt remains rejected; it was removed from the branch. No truncated or normalized representation is accepted as the historical SQL.

## Remaining action

The SQL body itself is not yet present as a Git blob because this connector does not accept a mounted local file as the `content` argument for GitHub file creation. Until the exact 83,433-byte body is transferred into Git and re-read from Git with matching hashes, `RECOVERY_STATUS.md` must distinguish **7/7 recovered** from **6/7 archived in Git**.

Do not recreate this migration from the live schema or substitute the older Library candidate. The recovered byte-equivalent file is the only eligible source for final Git archival.
