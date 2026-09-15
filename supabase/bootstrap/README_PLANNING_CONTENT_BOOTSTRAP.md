# Planning Content bootstrap artifact

The bootstrap source is the exact applied-history archive:

`supabase/history/archives/PLANNING_CONTENT_EXACT_APPLIED_HISTORY_20260914.tar.gz`

It contains the 28 reconstructed Planning Content SQL migrations in remote migration order, from PC-M01 through the PC-M09 staff-summary visibility fix.

Use only on a disposable database already migrated through canonical v0.7.

Replay helper:

```bash
DATABASE_URL='postgresql://...' bash supabase/bootstrap/replay_planning_content_history.sh
```

The helper extracts the archive, verifies that exactly 28 timestamped SQL migrations are present, sorts them by remote version, and applies them one by one with `ON_ERROR_STOP=1`.

Never point the helper at official homologation or production.

After replay, compare the resulting catalog against:

`supabase/history/PLANNING_CONTENT_CURRENT_CATALOG_FINGERPRINT_20260914.json`
