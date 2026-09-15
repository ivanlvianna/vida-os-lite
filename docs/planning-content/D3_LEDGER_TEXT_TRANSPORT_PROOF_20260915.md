# D3 Ledger Text Transport Proof — 2026-09-15

Status: **PASS for the tested transport channel sample; full 30-migration materialization remains in progress.**

## Purpose

Prove that exact SQL retained by the canonical D3 ledger can be transported to GitHub as UTF-8 Base64 text and reconstructed byte-for-byte, avoiding the binary corruption previously observed in transported `.gz` / `.tar.gz` artifacts.

## Canonical source

`supabase_migrations.schema_migrations.statements` in D3 project `aregdlspacytbrrdowps`.

## Method

1. Read exact migration SQL from the D3 migration ledger.
2. Convert UTF-8 bytes to standard Base64 text inside PostgreSQL.
3. Store the Base64 text under `supabase/bootstrap/d3_ledger_exact/` on the technical proof branch.
4. GitHub Actions decodes each file.
5. The workflow compares decoded byte length and MD5 against the canonical D3 ledger values.
6. Any mismatch stops the proof before SQL execution.

## Tested sample

The current sample covers migration families at different points of history:

- `20260913214041 v0_7_onboard_client_account_member` — 3292 bytes — MD5 `00b66beff0b48e3a493231cdd329ca1f`
- `20260915003143 pc_m01_actor_authorship_infrastructure` — 2738 bytes — MD5 `c2d19c8958952391985d2ee882c772a3`
- `20260915010615 pc_performance_targeted_indexes_v1` — 1469 bytes — MD5 `95cf1962dfec09bb69bdc07587c8da3b`
- `20260915022715 pc_m09_staff_summary_visibility_fix` — 2757 bytes — MD5 `ad3e1bef37e6a75ebc4ca0d1761ccd08`

## Detection behavior

The first CI run intentionally demonstrated the gate behavior in practice: the targeted-index transport was reconstructed as 1446 bytes with MD5 `b63dd6204c295490344e6d26523377d9`, so the job failed immediately. The file was re-exported from the D3 ledger and corrected without changing canonical SQL.

The subsequent GitHub Actions run `34964163325` completed successfully. All four decoded files matched their expected byte lengths and MD5 values, and the job concluded `success`.

## Interpretation

The text-safe Base64 transport channel is now proven to detect corruption and to preserve exact D3 migration bytes when the check passes.

This does **not** close `PC-INDEPENDENT-BOOTSTRAP-REPLAY-GATE-001`. The remaining work is:

1. materialize all 30 exact D3 migrations using the same verified transport method;
2. validate every decoded migration byte length + MD5;
3. create only the minimal Supabase Auth compatibility surface in disposable PostgreSQL 17;
4. execute all 30 exact migrations in order with stop-on-first-error;
5. recompute the resulting catalog oracle;
6. compare it with the canonical D3 oracle.

No D3 schema mutation, production deploy, merge, or paid Supabase resource was performed by this proof.
