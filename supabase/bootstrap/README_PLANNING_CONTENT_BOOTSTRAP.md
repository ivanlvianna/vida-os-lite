# Planning Content bootstrap artifact

`PLANNING_CONTENT_CURRENT_BOOTSTRAP_20260914.sql.gz` is the concatenation, in remote migration order, of the 28 reconstructed Planning Content SQL migrations applied after canonical v0.7 through the PC-M09 staff-summary visibility fix.

Use only on a disposable database already migrated through canonical v0.7.

Replay helper:

```bash
DATABASE_URL='postgresql://...' bash supabase/bootstrap/replay_planning_content_history.sh
```

Never point the helper at official homologation or production.

After replay, compare the resulting catalog against:

`supabase/history/PLANNING_CONTENT_CURRENT_CATALOG_FINGERPRINT_20260914.json`
