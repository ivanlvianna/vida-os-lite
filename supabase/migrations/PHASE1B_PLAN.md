# VIDA OS™ — Phase 1B Gate 002 Plan v3

Status: **RECONCILED AGAINST FROZEN AUTHORIZATION/MEMBERSHIP CRITERIA / NOT EXECUTION-VALIDATED / NOT FOR PRODUCTION**

## Why v3 exists

The v2 candidate correctly moved internal RLS/authorization helpers out of `public`, but a later-recovered FROZEN acceptance document for Authorization/Membership imposes additional mandatory requirements that v2 did not satisfy. Therefore v2 is superseded and MUST NOT be applied.

## Canonical migration chain

### M1 — Phase 1A security hardening

Unchanged scope:
- fix mutable `search_path` on the six Phase 1A functions flagged by the advisor;
- add the missing covering index on `reconciliation_record(economic_entity_id)`;
- no data backfill;
- no Phase 1A object recreation.

### M2 — Planning / RBAC-ABAC / VRI core

Create the seven Phase 1B core tables only:
- `client_account_vri_links`
- `client_account_user_authorizations`
- `planning_engagements`
- `planning_engagement_vri_links`
- `planning_engagement_entities`
- `planning_engagement_transitions`
- `client_activation_seeds`

Shared-object hardening remains targeted: Auth FK on `client_account_users.auth_user_id`, strong `economic_entities` immutability, required indexes, and internal helpers in `vida_internal`.

### M2.1 — Membership governance (FROZEN C1)

Add:
- `client_account_membership_events` append-only ledger;
- `add_client_account_membership(client_account_id, auth_user_id, justification)`;
- `remove_client_account_membership(client_account_id, auth_user_id, justification)`;
- physical canonical-mutation guard on `client_account_users`;
- internal backend bootstrap path that logs the initial membership event.

Rules:
- actor is never supplied by the interactive caller; it is derived from `auth.uid()`;
- direct INSERT/DELETE on `client_account_users` is not granted to application roles;
- concurrent add/remove operations serialize on the ClientAccount row;
- retry of an already-satisfied add/remove is a no-op and does not duplicate the ledger event;
- removal revokes active authorizations before deleting membership;
- the last active account-scope `planner_owner` is never removed.

### M3 — Access surface / RLS (FROZEN C2-C4)

Changes from v2:
- every policy in this layer is explicitly `TO authenticated`;
- the two direct membership mutation policies are removed;
- no INSERT/DELETE table grant on `client_account_users` to `authenticated` or `service_role`;
- `economic_entities_update` has both `USING` and equivalent `WITH CHECK`;
- helpers remain in `vida_internal`, which must remain outside PostgREST exposed schemas;
- canonical membership RPCs are added to the authenticated RPC surface.

Expected RLS policy count becomes **16**, not the staging-v0.6 historical count of 18, because direct membership INSERT/DELETE is intentionally eliminated.

### M4 — Offboarding workflow (FROZEN C5)

Add:
- `client_account_offboarding_workflows` — persisted workflow state;
- `client_account_offboarding_events` — append-only audit events;
- `start_client_account_offboarding(...)` — authenticated, planner_owner only;
- `mark_client_offboarding_sessions_revoked(...)` — backend-only;
- `mark_client_offboarding_user_deleted(...)` — backend-only;
- `record_client_offboarding_retryable_failure(...)` — backend-only.

State model:
1. `requested`
2. `database_access_removed`
3. `sessions_revoked`
4. `completed`

The database step is transactional. Supabase Auth Admin API actions are external milestones. If an external action fails, the workflow remains at the last completed state, records a retryable failure, and can resume safely.

## Production Phase 1A security fact established on 2026-09-13

Read-only privilege inspection confirmed effective table privileges are **zero** for `anon`, `authenticated`, `service_role`, and PUBLIC on all seven canonical Phase 1A tables:
- `economic_entities`
- `entity_relationships`
- `client_accounts`
- `client_account_entities`
- `client_account_users`
- `reconciliation_source`
- `reconciliation_record`

Therefore the Supabase `RLS disabled` advisor warning is not evidence of current API exposure by itself. The present production posture is deny-by-ACL. RLS policy design remains a separate hardening/governance decision.

## Gate 002 cannot close until

- M1 + M2 + M2.1 + M3 + M4 replay successfully in the zero-cost rehearsal project;
- all AUTH-P*, AUTH-N* and AUTH-L* cases are captured individually;
- negative cases fail for the expected reason/message;
- concurrency tests prove no duplicate membership/event on concurrent add;
- `vida_internal` is confirmed outside PostgREST exposed schemas;
- `anon` has effective zero access to every object in the layer;
- advisors are rerun and every new finding is remediated or explicitly accepted;
- Phase 1A rows/IDs remain unchanged by the Phase 1B delta.

No production application is authorized by this document.
