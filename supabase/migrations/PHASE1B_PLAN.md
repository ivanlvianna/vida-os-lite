# MIGRATION-APPLY-GATE-002 — Phase 1B production delta

Status: **OPEN**.

This document defines the intended production delta. It is not itself executable SQL.

## M1 — Phase 1A security hardening

Drafted as `20260913032000_phase1a_security_hardening.sql`.

Scope:
- fix mutable `search_path` on six Phase 1A functions;
- add a covering index on `reconciliation_record(economic_entity_id)`;
- no data backfill;
- no Phase 1A object recreation.

## M2 — Planning / RBAC-ABAC / VRI core

Create only objects absent from production:

- `client_account_vri_links`
- `client_account_user_authorizations`
- `planning_engagements`
- `planning_engagement_vri_links`
- `planning_engagement_entities`
- `planning_engagement_transitions`
- `client_activation_seeds`

Apply targeted hardening to shared Phase 1A objects instead of recreating them:

- add `client_account_users.auth_user_id -> auth.users(id) ON DELETE CASCADE`;
- preserve all existing `client_accounts`, `client_account_users`, `client_account_entities`, `economic_entities` rows and IDs;
- make `economic_entities.entity_type` immutable after creation while allowing `display_name` updates;
- preserve `entity_relationships`, `reconciliation_source` and `reconciliation_record` exactly.

M2 must include the Planning Engagement state machine, immutable transition ledger, predecessor validation, membership guard, activation idempotency and VRI correlation uniqueness proven in staging v0.6.

## M3 — Access surface

Public authenticated RPCs:

- `create_economic_entity`
- `create_planning_engagement`
- `grant_client_account_authorization`
- `revoke_client_account_authorization`
- `record_planning_engagement_transition`

Backend-only RPC:

- `activate_client_from_vri`

Internal/RLS/trigger helpers must not become accidental PostgREST RPC endpoints. Preferred target: schema `vida_internal` (or equivalent non-exposed schema), with minimal grants.

## Explicit non-goals

- no automatic backfill from `auth.users` to `economic_entities`;
- no automatic creation of client accounts for the three existing Auth users;
- no replacement of the Lite user-facing paths during this gate;
- no deletion of Lite tables;
- no promotion of synthetic staging data.

## Gate acceptance criteria

1. No `DROP` or recreation of Phase 1A canonical objects.
2. Existing `economic_entities`, `reconciliation_source` and `reconciliation_record` IDs/rows are preserved byte-for-byte at the semantic level.
3. Exactly seven Phase 1B core tables are added.
4. `client_account_users.auth_user_id` has the Auth FK with expected cascade semantics.
5. Invalid Planning Engagement transitions are rejected.
6. Terminal Planning Engagements cannot be reopened.
7. Planning transition rows cannot be updated or deleted.
8. Reprocessing the same VRI activation token is idempotent and parameter-compatible.
9. `ambiguous_match` cannot auto-activate a client/entity.
10. The last active account-scope `planner_owner` cannot be removed/revoked.
11. Helpers are not exposed as public RPCs.
12. Cross-account RLS access is denied.
13. Supabase security/performance advisors contain no unexplained new findings.
14. Forward migration, rollback rehearsal and clean replay all pass in the rehearsal environment before production application.
