# VIDA OS™ — PFP Cockpit 12-Area Canonical Gap Map — 2026-09-15

## Purpose

Translate the agreed PFP Cockpit information architecture into explicit canonical data dependencies. The Cockpit remains a presentation/operational layer around one `planning_engagement`; this document does not create a second system or authorize new persistence.

## Area-by-area status

### 1. Case header

**Partially available now.**

Canonical current sources:
- `planning_engagement_id`
- `client_account_id`
- engagement identity/access context from Product Core

Missing for a business-grade header:
- preferred client/entity display name projection for the case
- engagement state presentation in the current PC-M09 snapshot contract
- responsible planner/staff display projection

Rule: do not infer case identity from arbitrary participant ordering.

### 2. Executive view

**Partially available now.**

PC-M09 `pc_rm_engagement_content_summary` provides durable Planning Content counts and current-stage signals.

Missing:
- cross-domain financial reality indicators
- decision status
- implementation/action status beyond Planning Content episode counts
- protection/retirement/tax/succession status

Rule: the executive view must aggregate canonical domain read models; it must not become a new source of truth.

### 3. Financial reality

**Not available in the current Cockpit.**

Required dependency:
- Financial Reality bounded context / canonical read models

Candidate physical work exists separately, but no permanent D3 Financial Reality migration/read layer is authorized by this checkpoint.

Do not reuse legacy `prontuario_patrimonial` as if it were the canonical Financial Reality model unless an explicit compatibility bridge is approved.

### 4. Objectives / Possible States

**Partially available now.**

Current signals:
- Interview objectives narrative
- WorkingHypothesis / diagnostic continuity
- FinancialPlan goal count

Missing:
- canonical structured goal/possible-state projection suitable for dashboard display
- target values, horizons, priorities and dependencies as explicit read data

Rule: narrative text is not equivalent to a structured objective model.

### 5. VIDA diagnosis

**Available for the current Planning Content scope.**

Canonical sources:
- InstrumentRun
- DiagnosticSynthesis / PCP
- WorkingHypothesis
- HypothesisAgenda
- DiagnosticSession
- DiagnosticReport / consensus

Important boundary:
- ICV/IMDP/IVRP internal instrument IP remains black-box; Cockpit consumes only durable result envelopes and sanctioned projections.

### 6. Decisions / Decision Ledger

**Not canonically available.**

DiagnosticSession decision notes are local session content and must not be promoted or displayed as canonical Decision Ledger entries.

Required dependency:
- canonical Decision Ledger bounded context/read model

Rule: no silent conversion from session notes to formal decisions.

### 7. Financial plan

**Available at Planning Content aggregate level, partially available at business-detail level.**

Current source:
- FinancialPlan current projection

Current visible data:
- plan/version identity
- source DiagnosticReportVersion
- goal count
- strategy count
- hypothesis count
- draft state

Missing for richer plan presentation:
- structured goal details
- structured strategy details
- financial amounts/scenarios from Financial Reality where applicable

Rule: no arbitrary “primary plan” inference by array order or timestamp.

### 8. Action plan

**Partially available.**

Current source:
- ImplementationEpisode
- ReviewEpisode

Missing:
- canonical task/action-item model with owner, due date, status and evidence of completion
- explicit linkage to formal Decision Ledger entries when that domain exists

Rule: ImplementationEpisode is not automatically a generic task manager.

### 9. Assets / investments

**Not canonically available in the Cockpit.**

Required dependency:
- Financial Reality / portfolio/investment projections as governed by the future canonical domain model

Rule: do not copy brokerage-position data directly into Planning Content as a second source of truth.

### 10. Protection / pension / tax / succession

**Not canonically available in the Cockpit.**

Required dependency:
- domain-specific canonical facts/read models or a governed Financial Reality extension, depending on later design

Rule: keep facts, professional assessments, recommendations and client decisions distinct.

### 11. Documents / evidence

**Not canonically available.**

Required dependency:
- Documents/Evidence bounded context

Rule:
- document != evidence
- evidence used to support a fact/assessment/decision must preserve provenance and exact relationship to the object it supports.

### 12. Longitudinal timeline

**Available for Planning Content only.**

Current source:
- `pc_rm_engagement_timeline`

Missing:
- cross-domain temporal composition across Financial Reality, Decision Ledger, Documents/Evidence and future canonical domains

Rule: timeline is derived presentation, never the source of truth.

## Coverage summary

Current status of the 12 areas:

- substantially available in Planning Content: **2** — VIDA diagnosis; Planning Content longitudinal timeline
- partially available: **5** — case header, executive view, objectives/Possible States, financial plan, action plan
- not canonically available yet: **5** — Financial Reality, Decision Ledger, assets/investments, protection/pension/tax/succession, Documents/Evidence

This count is an information-coverage statement, not a completion percentage for the whole VIDA OS.

## Recommended integration sequence

1. strengthen Case Header using existing Product Core identity + engagement projections, without new persistence;
2. define a cross-domain Cockpit composition contract so each section names its canonical source explicitly;
3. bring Financial Reality through its own persistence/read-model gate;
4. define Decision Ledger persistence/read models;
5. define Documents/Evidence and canonical Provenance before PC-M10;
6. only then compose the full Executive View and cross-domain Timeline.

## Governance

- Read models are projections, not source of truth.
- PFP Cockpit remains bound to one `planning_engagement`.
- Missing domains must render as unavailable/not yet integrated, never as synthetic inferred data.
- No new D3 migration, production deployment, or merge is authorized by this document.
