# VIDA OS™ — PFP Cockpit Validation Checkpoint — 2026-09-15

## Scope

Validation of the current staff-only PFP Cockpit integration against the homologated D3 Planning Content read layer. No production deployment, merge, or persistent D3 schema change was performed.

## 1. Read-model contract vs D3

The TypeScript adapter in `src/lib/planning-content/read-models.ts` defines explicit projections for all twelve PC-M09 views.

A read-only information_schema comparison checked every column named by the application contract against the homologated D3 views.

Result:

- missing application-contract columns in D3: **0**
- extra D3 columns relative to the application contract: **0**

Therefore:

`PFP-COCKPIT-READ-CONTRACT-GATE = PASS`

This proves the current application read contract is structurally aligned with the homologated PC-M09 view surface.

## 2. Staff-only visibility probe

Persistent D3 schema was not changed. Read-only probes were executed inside transactions with `ROLLBACK`.

Canonical planning fixture:

- planning engagement: `69c0ec5f-976e-4e69-99b2-941a8f473739`
- planner auth user: `9ca0284e-e7d1-4d7d-87b7-b553725b60be`

Observed as authenticated planner:

- `pc_rm_engagement_content_summary`: **1 row** for the fixture engagement
- `pc_rm_engagement_timeline`: **0 rows**, expected because prior content smoke tests were rolled back and no durable Planning Content case data remains in the fixture

Observed as an unrelated authenticated UUID:

- `pc_rm_engagement_content_summary`: **0 rows**
- `pc_rm_engagement_timeline`: **0 rows**

Therefore:

`PFP-COCKPIT-STAFF-VISIBILITY-GATE = PASS (HOMOLOGATION)`

The positive planner read plus zero-row unauthorized read is consistent with the intended staff-only PC-M09 boundary.

## 3. Current branch application validation

GitHub Actions run:

- run id: `34966450429`
- commit: `dcc7dc5932e1ac620353b5ce6abf90aaeb5a6a10`
- job: `validate`
- conclusion: **success**

Passed steps:

- `npm ci`
- `npm run lint`
- `npm run build`

The temporary validation trigger was then removed and the strict-replay status workflow restored.

Therefore:

`PFP-COCKPIT-APPLICATION-BUILD-GATE = PASS`

## 4. Current Cockpit scope

The current Cockpit is a read-only staff projection around one `planning_engagement`. It renders the Planning Content bounded context only:

- InterviewRecord
- InstrumentRun
- DiagnosticSynthesis / PCP
- WorkingHypothesis
- HypothesisAgenda
- DiagnosticSession
- DiagnosticReport + consensus
- FinancialPlan
- ImplementationEpisode
- ReviewEpisode
- Planning Content timeline

It deliberately does not fabricate domains that are not yet canonical/read-modelled, including Financial Reality, canonical Decision Ledger, Documents/Evidence, Provenance/PC-M10, investments/assets and the protection/pension/tax/succession domains.

## 5. Remaining non-Cockpit blocker

`PC-INDEPENDENT-BOOTSTRAP-REPLAY-GATE-001` remains **OPEN / BLOCKED ON SAFE EXACT-LEDGER TRANSPORT**.

This is a strict reproducibility-proof transport blocker. It is not a failure of the current Cockpit code, PC-M09 views, D3 catalog, or staff-only read boundary.

No merge or deployment is authorized by this checkpoint.
