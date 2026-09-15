# VIDA OS™ — PFP Cockpit Read Integration Status — 2026-09-14

## Executive status

Branch:

`pfp-cockpit-read-integration-2026-09-14`

Current classification:

- Planning Content persistence in D3: **HOMOLOGATED**
- PC-M09 staff read models: **HOMOLOGATED**
- post-PC-M09 freeze reconciliation: **HOMOLOGATED**
- PFP Cockpit read integration code: **CI GREEN**
- Supabase production deployment: **NOT AUTHORIZED / NOT PERFORMED**
- merge to `main`: **NOT AUTHORIZED / BLOCKED ON SQL HISTORY SYNC**

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

The app layer requires authentication but does not reconstruct account/engagement authorization from in-memory principal state. Visibility remains authoritative in PostgreSQL/RLS.

### UI routes

- `/dashboard/pfp`
- `/dashboard/pfp/[planningEngagementId]`

The detail Cockpit currently renders the Planning Content bounded context only:

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

## CI evidence

GitHub Actions run:

`34920610880`

Validated commit:

`cd6e178f66a57e2148aea49773844b135dd1fe28`

Result:

**SUCCESS**

All relevant steps passed:

- Checkout
- Setup Node
- `npm ci`
- `npm run lint`
- `npm run build`

The workflow was temporarily configured to run on this branch only for validation. After the successful run, `.github/workflows/p0-ci.yml` was restored byte-for-byte to its canonical branch trigger content.

Therefore the final product diff does not retain the temporary CI trigger.

## Repository-history drift discovered

The D3 Planning Content migrations were applied and homologated before the repository had preserved a complete one-file-per-remote-migration forensic SQL history.

This does not invalidate D3 homologation, but it blocks mergeability because the repository cannot yet independently reconstruct the exact homologated state from its versioned SQL history.

Forensic ledger created:

`supabase/history/PLANNING_CONTENT_APPLIED_LEDGER_20260914.md`

It records:

- exact remote migration versions and names;
- logical PC-M01…PC-M09 mapping;
- freeze-reconciliation submigrations;
- hashes of recovered SQL source artifacts;
- the distinction between recovered source payloads and exact remote migration boundaries.

## Merge gate

`PFP-COCKPIT-MERGE-GATE = BLOCKED ON APPLIED-SQL HISTORY SYNC`

Before preparing a merge-ready PR, the remaining repository-governance work is:

1. preserve recovered Planning Content SQL source payloads under `supabase/history/`;
2. reconstruct exact applied submigration boundaries where possible;
3. qualify a bootstrap/replay from the canonical v0.6/v0.7 baseline to the current Planning Content catalog;
4. compare the replayed catalog with the homologated D3 catalog;
5. rerun lint/build on the final integration head if application code changes during that work.

## What is not authorized by this checkpoint

This status does not authorize:

- merge into `main`;
- merge of PR #9;
- production Supabase migrations;
- production deployment of the Cockpit;
- PC-M10;
- Financial Reality / Temporal deployment;
- broad client-facing Planning Content read access.

## Next technical step

Complete applied-SQL history preservation and bootstrap qualification. Once reproducibility is proven, the Cockpit branch can move from **CI GREEN / MERGE BLOCKED** to a merge-review candidate.
