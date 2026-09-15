# VIDA OS™ — Application Services Live E2E Readiness

Date: **2026-09-14**  
Branch: `app-services-live-e2e-2026-09-14`  
Base: PR #9 head `1f2d22560e073f199c4f98124000c51745a307f5`

## Purpose

Prepare live authenticated E2E validation of:

1. `GrantAccessWorkflow`;
2. `RevokeAccessWorkflow`;
3. `ChangeEngagementStateWorkflow`.

This branch does not modify PostgreSQL schema, RLS, triggers, RPCs or Supabase migrations.

## Delivery Layer readiness

The PR #9 branch implemented the three Application Services, but did not expose them through Delivery Layer server actions. This branch adds:

- `src/app/dashboard/access-actions.ts`
  - `grantAccessAction()`
  - `revokeAccessAction()`
  - `changeEngagementStateAction()`

The adapters:

- resolve the real authenticated session with `createSessionContext()`;
- resolve `CurrentPrincipal` with `resolveCurrentPrincipal()`;
- validate transport-level input shape only;
- use the authenticated Supabase client;
- delegate domain authority to the existing Application Services and canonical PostgreSQL RPCs;
- do not use `service_role`;
- do not duplicate planner-owner, scope, last-owner or lifecycle rules.

## CI evidence

A temporary branch filter was added only to execute the existing P0 CI workflow and then restored byte-for-byte.

Run `34889431526`:
- `npm ci`: PASS
- lint: PASS
- build: FAIL due only to TypeScript union/default result typing in the newly added Delivery adapter.

The typing was corrected without changing domain behavior.

Run `34889546092`:
- `npm ci`: PASS
- lint: PASS
- build: PASS
- job conclusion: SUCCESS

The CI workflow was then restored to its original policy (`p0-functional-integration` only).

## D3 fixture state verified read-only

Environment: `vida-os-homologacao` / `aregdlspacytbrrdowps`.

Current persistent fixture:

- one Client Account: `c21d928b-e627-41ff-97bf-d4dd331b00c2`;
- one active account-scope `planner_owner` authorization;
- planner auth user: `9ca0284e-e7d1-4d7d-87b7-b553725b60be`;
- no `planning_engagement` currently exists.

No mutation was performed during this inspection.

## Remaining blockers for true live authenticated E2E

### 1. Authenticated planner session

A real Delivery Layer E2E requires a valid Supabase Auth login/session for the D3 planner user (or another dedicated D3 planner fixture). Database-level role simulation is not equivalent and must not be reported as Delivery Layer E2E.

No usable Auth password/session credential is available in the connected tools for the existing planner fixture.

### 2. Planning Engagement fixture

`ChangeEngagementStateWorkflow` requires a real Planning Engagement. D3 currently has none. A fixture must be created through an already-approved canonical path before that E2E scenario can execute.

### 3. Preview/runtime target

The branch is connected to Vercel and a preview deployment is being evaluated by the repository integration. A live E2E must target a runtime built from this branch (preview or controlled local runtime) with D3 environment configuration, not production.

## Gate status

- Delivery adapters: **IMPLEMENTED**
- lint/build: **PASS**
- Core Domain: **UNCHANGED**
- D3: **UNCHANGED by this branch/readiness work**
- live authenticated `GrantAccessWorkflow` E2E: **PENDING**
- live authenticated `RevokeAccessWorkflow` E2E: **PENDING**
- live authenticated `ChangeEngagementStateWorkflow` E2E: **PENDING**
- PR #9 merge/homologation: **NOT AUTHORIZED by this record**

## Next safe action

Establish a dedicated authenticated D3 planner test session and a canonical Planning Engagement fixture, then execute the three Delivery Layer actions against a non-production runtime built from this branch. Preserve before/after evidence and clean up only through approved domain paths.

## Runtime refresh marker

A documentation-only commit was made after configuring branch-scoped Vercel Preview variables for D3, solely to force a fresh Preview build from `app-services-live-e2e-2026-09-14`. No application logic, database object, migration, RLS policy or production setting is changed by this marker.
