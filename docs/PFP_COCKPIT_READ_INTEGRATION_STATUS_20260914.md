# VIDA OS™ — PFP Cockpit Read Integration Status — 2026-09-14

## Executive status

Branch:

`pfp-cockpit-read-integration-2026-09-14`

Current classification:

- Planning Content persistence in D3: **HOMOLOGATED**
- PC-M09 staff read models: **HOMOLOGATED / STAFF-SUMMARY FIX APPLIED**
- post-PC-M09 freeze reconciliation: **HOMOLOGATED**
- PFP Cockpit read integration code: **CI GREEN / DEFENSE-IN-DEPTH HARDENED**
- Supabase production deployment: **NOT AUTHORIZED / NOT PERFORMED**
- merge to `main`: **NOT AUTHORIZED / BLOCKED ON APPLIED-SQL HISTORY REPRODUCIBILITY**

The previous PC-M09 summary-view security blocker is closed. The remaining merge blocker is repository SQL-history synchronization/bootstrap reproducibility.

## Git lineage

`planning-content-persistence-2026-09-14` is linearly ahead of `app-services-prereqs-2026-09-14` with no divergence.

The PFP Cockpit integration branch was created from `planning-content-persistence-2026-09-14` and contains the Application Services prerequisite lineage, Planning Content design/candidate documentation and the new read-only Cockpit integration.

No merge into `main` has been performed.

## Application integration

### Planning Content read adapter

`src/lib/planning-content/read-models.ts`

Provides an explicit TypeScript contract for all twelve PC-M09 views and uses explicit select lists.

Architectural path:

`session-scoped Supabase client → PC-M09 security-invoker view → underlying PostgreSQL RLS`

The read adapter does not use the service role.

### Application workflows

`src/app-services/load-pfp-cockpit.ts`

Adds:

- `listPfpCockpitsWorkflow`
- `loadPfpCockpitWorkflow`

Defense in depth requires account-scope `planner_owner` or `internal_staff` in the application layer. This is deliberately redundant with the database staff-only read boundary.

### UI routes

- `/dashboard/pfp`
- `/dashboard/pfp/[planningEngagementId]`

The Cockpit currently renders only the Planning Content bounded context: InterviewRecord, InstrumentRun, DiagnosticSynthesis/PCP, WorkingHypothesis, HypothesisAgenda, DiagnosticSession, DiagnosticReport/consensus, FinancialPlan, ImplementationEpisode, ReviewEpisode and Planning Content timeline.

It does not infer one report/plan/implementation/review as a primary root by timestamp or array position.

## Deliberately absent bounded contexts

The UI does not fabricate Financial Reality, investments/assets, protection, pension, tax/succession, canonical Decision Ledger, Documents/Evidence or Provenance/PC-M10. These must enter through their own canonical domains/read models.

## PC-M09 staff-summary security correction — CLOSED

A real D3 probe had shown that an engagement-authorized client could see one row from `pc_rm_engagement_content_summary`, because the view was rooted in `planning_engagements` whose RLS correctly exposes the client's own engagement.

The approved correction was permanently applied in `vida-os-homologacao` as:

`20260915022715 — pc_m09_staff_summary_visibility_fix`

The view remains `security_invoker=true` and now additionally requires:

`WHERE public.is_staff(pe.client_account_id)`

### Persistent post-migration homologation

A transaction used the canonical `onboard_client_account_member` RPC to give a non-member fixture a legitimate engagement-scoped `client_primary` authorization.

Observed against the persistent corrected view:

- authorized client summary rows: **0**
- planner staff summary rows: **1**

The transaction ended with `ROLLBACK`.

Zero residue verified:

- temporary membership rows: **0**
- temporary active authorization rows: **0**

Catalog verified:

- PC-M09 views: **12**
- `security_invoker=true`: **12/12**
- summary view authenticated SELECT grant: **1**
- summary view authenticated non-SELECT grants: **0**

Exact applied migration SQL is preserved at:

`supabase/history/20260915022715_pc_m09_staff_summary_visibility_fix.sql`

Therefore:

`PC-M09-STAFF-SUMMARY-VISIBILITY-GATE = PASS (HOMOLOGATION)`

## CI evidence

### Run 14 — initial Cockpit integration

- GitHub Actions run `34920610880`
- commit `cd6e178f66a57e2148aea49773844b135dd1fe28`
- result: **SUCCESS**

### Run 15 — security-hardened Cockpit

- GitHub Actions run `34920963764`
- commit `ac9dfe5c1df888bbd4fce6854fa69e4671cc206e`
- result: **SUCCESS**

Both passed `npm ci`, lint and Next build. The workflow trigger was restored to canonical content after validation.

## Advisor state after summary fix

No new security category was introduced by the view correction.

Existing baseline remains:

- `client_activation_seeds` RLS/no-policy INFO;
- 46 intentional/authenticated-callable SECURITY DEFINER warnings across the existing core + Planning Content RPC surface;
- leaked-password protection disabled.

Performance baseline remains:

- 115 unindexed foreign-key notices;
- two pre-existing Auth RLS initplan warnings;
- unused-index notices expected in the low-workload homologation environment.

These remain separate governance/performance items and were not expanded by this fix.

## Repository-history drift

Planning Content was homologated in D3 before the repository had preserved a complete one-file-per-remote-migration SQL history.

Forensic ledger:

`supabase/history/PLANNING_CONTENT_APPLIED_LEDGER_20260914.md`

The newly applied PC-M09 summary fix is now preserved exactly one-to-one in `supabase/history`. Earlier Planning Content migrations still require full boundary reconstruction/bootstrap qualification.

## Merge gate

`PFP-COCKPIT-MERGE-GATE = BLOCKED ON APPLIED-SQL HISTORY REPRODUCIBILITY`

Remaining work before a merge-ready PR:

1. preserve/reconstruct the earlier applied Planning Content SQL history under `supabase/history/`;
2. qualify a bootstrap/replay from the canonical v0.6/v0.7 baseline to the current Planning Content catalog;
3. compare the replayed catalog with homologated D3;
4. rerun lint/build if application code changes during that work.

## Not authorized by this checkpoint

This status does not authorize merge into `main`, merge of PR #9, production Supabase migrations, production Cockpit deployment, PC-M10, Financial Reality/Temporal deployment or broad client-facing Planning Content reads.
