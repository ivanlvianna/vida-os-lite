# VIDA OS™ — Planning Content Bootstrap Qualification — 2026-09-14

## Reconstructed applied history

The post-v0.7 Planning Content history has been reconstructed into **28 ordered SQL migrations**, matching every remote Planning Content migration through `20260915022715_pc_m09_staff_summary_visibility_fix`.

- M01–M06, M08, targeted indexes, M09 and the staff-summary fix come from their preserved source payloads.
- The ten PC-M07 reconstructed files concatenate byte-for-byte to the canonical validated M07 source (`0bbdad...c929`).
- The eight freeze-reconciliation files concatenate byte-for-byte to the canonical validated reconciliation source (`6885b8...ba6fc`).

## Replay evidence already established

The exact source families represented by this reconstruction were previously subjected to:

- real PostgreSQL physical compile;
- PC-M01…PC-M08 ordered migration replay;
- W1–W5 behavioral replay;
- real multi-session concurrency;
- PC-M09 semantic/RLS homologation;
- freeze-reconciliation compile, serial behavior and real consensus×validation concurrency;
- persistent post-migration homologation;
- staff-summary visibility correction and homologation.

The reconstructed split boundaries do not modify the concatenated SQL of the validated canonical sources.

## Current D3 catalog fingerprint

See `supabase/history/PLANNING_CONTENT_CURRENT_CATALOG_FINGERPRINT_20260914.json`.

This fingerprint is the comparison target for any future fresh-database bootstrap qualification.

## Artifacts

- exact applied-history archive: `supabase/history/archives/PLANNING_CONTENT_EXACT_APPLIED_HISTORY_20260914.tar.gz`
- replay helper: `supabase/bootstrap/replay_planning_content_history.sh`
- deterministic catalog fingerprint: `supabase/history/PLANNING_CONTENT_CURRENT_CATALOG_FINGERPRINT_20260914.json`

The replay helper extracts the exact-history archive, verifies that exactly 28 timestamped SQL migrations are present, sorts them by remote migration version, and applies them one by one to a disposable database already at canonical v0.7.

## Classification

Repository reproducibility is now materially restored: the exact ordered SQL payloads, executable replay path, and current catalog fingerprint are preserved.

A truly independent fresh PostgreSQL/Supabase instance replay remains the strongest final proof, but no SQL now needs to be reconstructed from memory. The replay can be executed directly from the preserved archive without touching the official homologation database.
