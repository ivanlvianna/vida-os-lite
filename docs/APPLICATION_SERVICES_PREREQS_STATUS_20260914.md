# VIDA OS™ — Application Services Prerequisites Status

Date: **2026-09-14**  
Branch: `app-services-prereqs-2026-09-14`  
Base: `p0-functional-integration` @ `bd49df4eca4c6d2289deb88985f9d797322450d2`

## Scope

This branch implements the three Application Services that AH-001 v1.5 places immediately before EPIC-PC-001 Phase 3 (Persistence):

1. `GrantAccessWorkflow`;
2. `RevokeAccessWorkflow`;
3. `ChangeEngagementStateWorkflow`.

No migration, RLS policy, database trigger or PostgreSQL RPC is changed by this branch.

## Physical Core Domain contract verified against D3

Reference environment: Supabase `aregdlspacytbrrdowps` (`vida-os-homologacao`).

Verified read-only before implementation:

- `onboard_client_account_member(uuid,uuid,text,text,uuid,uuid) -> uuid`;
- `revoke_client_account_authorization(uuid) -> void`;
- `record_planning_engagement_transition(uuid,text,text,text,text,text,text) -> uuid`;
- all three are `SECURITY DEFINER` with empty `search_path`;
- all three are executable by `authenticated` and remain Core Domain authority for authorization and lifecycle invariants.

## Application-layer rule

The new workflows use an authenticated Supabase client. They do not use `service_role` and do not duplicate PostgreSQL authorization rules.

The Application Layer verifies only the authenticated application boundary and transport-level input shape. PostgreSQL remains authoritative for, among other things:

- planner-owner authorization;
- target user existence;
- account / engagement / entity scope consistency;
- duplicate active authorization;
- last planner-owner protection;
- valid Planning Engagement transitions;
- terminal-state protection;
- pause/resume rules;
- required reason for terminal transitions;
- actor, executor and origin derivation;
- append-only transition history.

## Implemented files

- `src/app-services/grant-access.ts`;
- `src/app-services/revoke-access.ts`;
- `src/app-services/change-engagement-state.ts`;
- RPC adapters added to `src/lib/vida-os/rpc.ts`;
- Planning lifecycle types added to `src/lib/vida-os/types.ts`.

## Validation performed

### Static TypeScript contract

A strict TypeScript type-check of the changed contracts and their direct dependencies completed successfully.

Result: **PASS**.

### Application-service runtime contract harness

Seven local checks were executed with a simulated `SupabaseClient` boundary:

1. unauthenticated grant is rejected before RPC call;
2. authenticated grant delegates the exact v0.7 RPC payload and returns `authorizationId`;
3. RPC failure maps to `DOMAIN_RPC_FAILED`;
4. revoke delegates the exact RPC argument and preserves the physical `void` return;
5. change-state delegates the exact transition RPC payload;
6. optional text is normalized to `null` without reproducing lifecycle rules;
7. blank transition event is rejected as application input.

Result: **7/7 PASS**.

### Full repository CI

GitHub Actions run `34839179553` was executed from this branch after temporarily adding the branch to the existing P0 CI push filter.

Results:

- checkout: **PASS**;
- Node setup: **PASS**;
- `npm ci`: **PASS**;
- `npm run lint`: **PASS**;
- `npm run build`: **PASS**;
- job conclusion: **SUCCESS**.

After the successful run, `.github/workflows/p0-ci.yml` was restored byte-for-byte to the base-branch content. The final PR diff does not alter CI policy.

## Validation not yet claimed

This record does **not** claim:

- live authenticated E2E execution of the three workflows through the Delivery Layer;
- v0.7 Caso 7 real multi-session concurrency;
- merge into `p0-functional-integration` or `main`;
- AH-001 status update to “homologated”.

## Artifact-recovery gap — InviteClientWorkflow

AH-001 states that `InviteClientWorkflow` was implemented/tested and its artifact index names `app-services/invite-client.ts`. The accessible Git repository contains no `invite-client.ts` in any current branch. This is recorded as an artifact-recovery divergence.

No replacement implementation is invented here. The architectural contract remains: `planner_owner` authorizes the invite; the server-side admin client calls `inviteUserByEmail()`; invitation does not grant Client Account access; `GrantAccessWorkflow` remains a later independent use case.

## Current gate state

- GrantAccessWorkflow: **IMPLEMENTED / CONTRACT-VALIDATED / CI-GREEN / LIVE-E2E PENDING**
- RevokeAccessWorkflow: **IMPLEMENTED / CONTRACT-VALIDATED / CI-GREEN / LIVE-E2E PENDING**
- ChangeEngagementStateWorkflow: **IMPLEMENTED / CONTRACT-VALIDATED / CI-GREEN / LIVE-E2E PENDING**
- InviteClientWorkflow artifact recovery: **OPEN**
- `PC-PERSISTENCE-START-GATE-001`: **NOT CLOSED**

Planning Content Phase 3 must not be promoted to started solely from this branch until the remaining application-layer evidence and governance status are reconciled.
