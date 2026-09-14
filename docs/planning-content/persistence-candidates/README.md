# VIDA OS™ — Planning Content Persistence Candidate Bodies

Status: NON-EXECUTABLE / REVIEW ONLY / DO NOT APPLY.

This directory is not `supabase/migrations/` and does not contain official migration filenames. Its sole purpose is to preserve the candidate bodies and scope for PC-M01…PC-M09 before a Supabase CLI-enabled executor creates the real migration files with `supabase migration new`.

Source baseline: Planning Content Physical Target v0.2, D3 read-only verification 2026-09-14, Persistence Gate 001 = OPEN / CANDIDATE GENERATION ONLY.

Rules:
- do not apply these files to any Supabase project;
- do not rename them into migration filenames manually;
- do not invent timestamps;
- create the official migration file first with Supabase CLI;
- then transfer/reconcile the corresponding candidate body;
- run static review, single-session tests, real multi-session concurrency tests, rollback/replay and security review before any apply authorization;
- PC-M10 remains blocked until canonical Provenance/Evidence exists physically.

Candidate mapping:
- PC-M01 — foundations, actor/authorship helpers, internal guards;
- PC-M02 — aggregate roots, same-engagement context, RLS+REVOKE at creation;
- PC-M03 — durable versions, version-chain integrity, append-only guards;
- PC-M04 — typed child/reference tables and exact-version links;
- PC-M05 — typed working drafts and optimistic concurrency;
- PC-M06 — lifecycle/workflow ledgers and current-state derivation;
- PC-M07 — canonical typed RPC writers, no universal JSON writer;
- PC-M08 — controlled SELECT/EXECUTE opening, no direct app DML;
- PC-M09 — read models/projections for planner/Cockpit.
