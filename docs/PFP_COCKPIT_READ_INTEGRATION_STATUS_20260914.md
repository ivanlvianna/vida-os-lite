# VIDA OS™ — PFP Cockpit Read Integration Status — 2026-09-14

## Executive status

Branch:

`pfp-cockpit-read-integration-2026-09-14`

Current classification:

- Planning Content persistence in D3: **HOMOLOGATED**
- PC-M09 staff read models: **HOMOLOGATED WITH ONE SUMMARY-VIEW SECURITY CORRECTION PENDING**
- post-PC-M09 freeze reconciliation: **HOMOLOGATED**
- PFP Cockpit read integration code: **CI GREEN / DEFENSE-IN-DEPTH HARDENED**
- Supabase production deployment: **NOT AUTHORIZED / NOT PERFORMED**
- merge to `main`: **NOT AUTHORIZED / BLOCKED**

Current merge blockers:

1. applied-SQL history sync / reproducibility;
2. permanent correction of `pc_rm_engagement_content_summary` staff-only visibility.

## Git lineage

`planning-content-persistence-2026-09-14` is linearly ahead of `app-services-prereqs-2026-09-14` with no divergence.

The PFP Cockpit integration branch was created from `planning-content-persistence-2026-09-14` so it contains:

- the Application Services prerequisite lineage;
- Planning Content design/candidate documentation;
- the new read-only Cockpit integration.

No merge into `main` has been performed.

## Application integration added

### Planning Content read adapter

`src/lib/planning-content/read-models.ts`

Provides an explicit TypeScript contract for all twelve PC-M09 views and uses explicit select lists rather than `select('*')`.

The architectural path is:

`session-scoped Supabase client → PC-M09 security-invoker view → underlying PostgreSQL RLS`

The read adapter does **not** use the service role.

### Application workflows

`src/app-services/load-pfp-cockpit.ts`

Adds:

- `listPfpCockpitsWorkflow`
- `loadPfpCockpitWorkflow`

After the D3 security probe described below, these workflows were hardened with a defense-in-depth account-staff check:

- account-scope `planner_owner`; or
- account-scope `internal_staff`.

This application guard prevents a projection mistake from becoming a Cockpit navigation/data exposure. It is deliberately redundant and does **not** replace the database correction required for direct Data API safety.

### UI routes

- `/dashboard/pfp`
- `/dashboard/pfp/[planningEngagementId]`

The detail Cockpit renders the Planning Content bounded context only:

- InterviewRecord;
- InstrumentRun;
- DiagnosticSynthesis / PCP;
- WorkingHypothesis;
- HypothesisAgenda;
- DiagnosticSession;
- DiagnosticReport / consensus state;
- FinancialPlan;
- ImplementationEpisode;
- ReviewEpisode;
- Planning Content timeline.

## No-primary-root invariant

The Cockpit does **not** infer a single report, financial plan, implementation or review as the engagement's “primary” object by timestamp, array position or latest date.

Each Aggregate Root returned by PC-M09 is rendered separately.

This preserves the executable-design freeze and prevents the presentation layer from inventing domain semantics.

## Deliberately absent bounded contexts

The UI explicitly refuses to fabricate or absorb:

- Financial Reality;
- investments/assets;
- protection;
- pension;
- tax/succession;
- canonical Decision Ledger;
- Documents/Evidence;
- Provenance / PC-M10.

Those areas must enter the Cockpit only through their own canonical domains/read models.

## Live D3 contract verification

The twelve PC-M09 view schemas were inspected directly in `vida-os-homologacao` through `information_schema.columns` after freeze reconciliation.

The TypeScript read contract was aligned to the live view columns, including the exact:

`pc_rm_review_current.implementation_episode_version_id`

field introduced by the post-PC-M09 reconciliation.

## Security finding — `pc_rm_engagement_content_summary`

A real transactional D3 probe identified one staff-surface leak in PC-M09.

Test identity received only:

- ClientAccount membership;
- engagement-scoped `client_primary` authorization;
- entity-scoped `client_primary` authorization.

Observed current persistent behavior:

- `pc_rm_engagement_content_summary`: **1 row visible**;
- `pc_rm_engagement_timeline`: 0 rows;
- `pc_rm_report_current`: 0 rows.

Root cause:

`pc_rm_engagement_content_summary` is rooted directly in `planning_engagements`, whose RLS correctly allows an authorized client to see the engagement. The correlated Planning Content sources remain staff-hidden, but the summary row itself survives.

That violates the PC-M09 v1 rule that the read layer is staff-only.

### Candidate correction

Candidate source:

`docs/planning-content/persistence-candidates/PC-M09-STAFF-SUMMARY-FIX-CANDIDATE-v0.1.sql`

The candidate adds:

`WHERE public.is_staff(pe.client_account_id)`

to the `security_invoker=true` summary view.

Transactional assertion evidence:

- current summary view for client: 1 row;
- candidate staff filter for same client: 0 rows;
- candidate staff filter for planner staff: 1 row.

No D3 mutation from this test persisted; the fixture transaction was rolled back.

The candidate has **not** been applied permanently because that requires separate explicit authorization.

## CI evidence

### Run 14 — initial Cockpit integration

GitHub Actions run:

`34920610880`

Validated commit:

`cd6e178f66a57e2148aea49773844b135dd1fe28`

Result: **SUCCESS**

### Run 15 — security-hardened Cockpit

GitHub Actions run:

`34920963764`

Validated commit:

`ac9dfe5c1df888bbd4fce6854fa69e4671cc206e`

Result: **SUCCESS**

Both runs passed:

- Checkout
- Setup Node
- `npm ci`
- `npm run lint`
- `npm run build`

For each validation, the workflow was temporarily configured to include the integration branch. After validation, `.github/workflows/p0-ci.yml` was restored byte-for-byte to its canonical trigger content.

The final product diff therefore does not retain the temporary CI trigger.

## Repository-history drift discovered

The D3 Planning Content migrations were applied and homologated before the repository had preserved a complete one-file-per-remote-migration forensic SQL history.

This does not invalidate D3 homologation, but it blocks mergeability because the repository cannot yet independently reconstruct the exact homologated state from its versioned SQL history.

Forensic ledger:

`supabase/history/PLANNING_CONTENT_APPLIED_LEDGER_20260914.md`

It records:

- exact remote migration versions and names;
- logical PC-M01…PC-M09 mapping;
- freeze-reconciliation submigrations;
- hashes of recovered SQL source artifacts;
- the distinction between recovered source payloads and exact remote migration boundaries.

## Merge gate

`PFP-COCKPIT-MERGE-GATE = BLOCKED`

Before preparing a merge-ready PR:

1. permanently close the PC-M09 summary staff-visibility gap;
2. preserve recovered Planning Content SQL source payloads under `supabase/history/`;
3. reconstruct exact applied submigration boundaries where possible;
4. qualify a bootstrap/replay from the canonical v0.6/v0.7 baseline to the current Planning Content catalog;
5. compare the replayed catalog with the homologated D3 catalog;
6. rerun lint/build if application code changes further.

## What is not authorized by this checkpoint

This status does not authorize:

- the PC-M09 summary-view migration candidate;
- merge into `main`;
- merge of PR #9;
- production Supabase migrations;
- production deployment of the Cockpit;
- PC-M10;
- Financial Reality / Temporal deployment;
- broad client-facing Planning Content read access.

## Next decision

The immediate database correction is narrow, already demonstrated behaviorally and has no data backfill requirement.

It still changes the official homologation migration history and therefore requires explicit authorization before permanent application.
