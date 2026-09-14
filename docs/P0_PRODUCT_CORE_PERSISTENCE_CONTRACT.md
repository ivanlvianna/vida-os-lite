# VIDA OS™ — P0 Product Core Persistence Contract

Status: **FROZEN FOR P0 INTEGRATION / PHYSICAL DDL NOT AUTHORIZED**  
Date: 2026-09-14  
Working branch: `p0-functional-integration`  
Parent contract: `P0_FUNCTIONAL_INTEGRATION_CONTRACT.md`

## 1. Purpose

Define the **minimum persistence boundary** required by the first VIDA OS™ functional vertical slice:

`Auth → Identity → Account → Engagement → Product Core → Persistence → Reload → UI → Isolation`

This contract is intentionally narrower than the broader Planning Content / Prontuário / diagnostics persistence workstream. It does not authorize a new production migration.

## 2. Canonical identity rule

The Product Core must not reintroduce the legacy identity chain

`auth.users → profiles → financial_profiles`

as canonical VIDA OS identity.

For P0:

- `auth.users` identifies the login/session principal;
- `economic_entities` identifies the economic subject;
- `client_accounts` identifies the governed client relationship / authorization perimeter;
- `planning_engagements` identifies the professional planning cycle in which the Product Core case occurs.

Any compatibility financial projection required by Product Core is anchored to an `EconomicEntity`. Legacy `profile_id` is not a canonical owner identifier.

## 3. P0 result binding

A persisted Product Core execution/result accepted by P0 must be bound, directly and unambiguously, to all of the following:

- `economic_entity_id` — subject of the financial case;
- `client_account_id` — authorization and relationship perimeter;
- `planning_engagement_id` — planning cycle that owns the case;
- Product Core contract/version — at minimum enough to distinguish the frozen v0.5.2 behavior from future versions;
- one immutable execution/result identity;
- creation time and deterministic payload/result required for faithful reload.

No UI route, e-mail address, login UUID, active-navigation state or timestamp heuristic may substitute for those domain bindings.

## 4. Financial projection compatibility

The preferred compatibility direction is a financial projection object anchored explicitly to `EconomicEntity`, rather than importing legacy `profiles` as a new identity layer.

Conceptually, Product Core may consume a projection containing the established cents-based financial inputs (income, expenses, debt service, contributions, reserve, investments/assets and debt balance), preserving BRL cent precision.

The exact physical projection schema, projection-kind catalog and migration/RPC surface remain **unfrozen** until the exact Product Core v0.5.2 source artifact has been recovered and inspected. P0 must not invent fields from prose summaries.

## 5. Repository boundary

Application code must access Product Core persistence through a dedicated repository/application-service boundary. That boundary is responsible for:

1. receiving a resolved `CurrentPrincipal` / canonical client context;
2. verifying the target `client_account_id` and `planning_engagement_id` belong to the resolved authorized context;
3. loading the Product Core compatibility projection for the selected `EconomicEntity`;
4. executing the exact frozen Product Core v0.5.2 implementation;
5. persisting the execution/result under the explicit entity + account + engagement tuple;
6. reloading the persisted result through the authenticated/RLS-backed read surface;
7. returning a typed object to the UI.

The UI never becomes an authorization source and must not write Product Core domain tables directly.

## 6. Isolation requirement

P0 is not accepted merely because one user can save and reload a result.

The persistence surface must prove that a different unauthorized user/account cannot:

- read the Product Core execution/result;
- mutate or replace it;
- bind a result to an engagement outside the authorized account;
- use a valid execution identifier to bypass account/engagement isolation.

RLS/canonical authorization remains authoritative for reads and canonical write workflows/RPC/application services remain authoritative for writes.

## 7. Idempotency and immutability

The P0 physical design must provide an explicit idempotency rule for retrying the same Product Core execution request. A retry must not silently create contradictory duplicate canonical results.

A completed deterministic Product Core result is treated as an immutable historical execution. A recalculation caused by changed inputs, engine version or scenario is a new execution/result, not an in-place rewrite of history.

The exact idempotency key shape remains open until the recovered v0.5.2 artifact is inspected.

## 8. Product Core v0.5.2 boundary

The exact v0.5.2 implementation remains frozen:

- deterministic factual calculations remain authoritative;
- monetary calculations preserve cent precision;
- deterministic summary/scenario/classification are not rewritten by an LLM;
- the LLM, when used, is restricted to the previously validated concept-only complementary surface;
- the implementation must be imported from the exact validated source/artifact rather than reconstructed from documentation.

Therefore no Product Core engine source is added under this contract until exact artifact recovery is complete.

## 9. Explicit separation from broader persistence

The following are **not** pulled into P0 merely to persist one Product Core case:

- broad Prontuário / InterviewRecord;
- additional InstrumentRun/diagnostic families;
- DiagnosticSynthesis / WorkingHypothesis;
- Decision Ledger;
- FinancialPlan / PLAN / implementation/review domain;
- broad patrimony / Financial Reality R2;
- Temporal/Provenance rollout;
- mass backfill;
- generic JSON storage inside `planning_engagements` as a shortcut.

Those workstreams remain separate gates and may consume the Product Core result later.

## 10. Physical gate before DDL

Before any Product Core persistence migration is eligible for rehearsal/apply, the following must be completed:

1. recover the exact Product Core v0.5.2 artifact/source and verify its known identity/checksums;
2. map its exact input/output contracts, including cents semantics;
3. freeze the minimal projection and execution/result physical model;
4. freeze the write/read RPC or repository surface;
5. produce RLS/ACL and negative-isolation tests;
6. prove clean apply → functional test → rollback/replay in a zero-cost non-production environment;
7. only then request a separate production migration authorization.

## 11. P0 acceptance consequence

This contract closes only the **semantic persistence boundary** for P0. It does not close the P0 itself.

P0 remains open until the real path is proven end-to-end:

`Auth → Identity → Account → Engagement → exact Product Core v0.5.2 → persisted result → reload → UI → negative isolation`.
