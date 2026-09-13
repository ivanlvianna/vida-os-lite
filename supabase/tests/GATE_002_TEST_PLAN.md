# Gate 002 test plan

These tests must be converted to executable SQL before the Phase 1B migration is eligible for production.

## Phase 1A preservation

- Assert that `economic_entities`, `entity_relationships`, `reconciliation_source` and `reconciliation_record` still exist.
- Snapshot row counts and canonical IDs before migration; compare after migration.
- Verify the existing reconciliation chain remains canonical for the same knowledge timestamps.
- Verify the six Phase 1A functions flagged for mutable search path have a fixed empty search path after M1.
- Verify the covering index on `reconciliation_record(economic_entity_id)` exists.

## Phase 1B structure

Assert existence of exactly the intended new core tables:

- `client_account_vri_links`
- `client_account_user_authorizations`
- `planning_engagements`
- `planning_engagement_vri_links`
- `planning_engagement_entities`
- `planning_engagement_transitions`
- `client_activation_seeds`

Verify `client_account_users.auth_user_id` references `auth.users(id)` with `ON DELETE CASCADE`.

## Planning Engagement state machine

- Valid forward transitions succeed.
- Invalid transitions fail.
- Paused engagement resumes only to `state_before_pause` or a terminal state allowed by contract.
- Terminal states require a non-empty reason.
- Terminal engagements cannot be reopened.
- Direct state mutation outside the transition function fails.
- Transition ledger rows cannot be updated or deleted.
- A predecessor must belong to the same account and be terminal.

## Identity / VRI activation

- `ambiguous_match` is rejected from automatic activation.
- `no_match` requires `entity_type` and non-empty `display_name`.
- `match_confident` requires an existing economic entity and forbids duplicate creation fields.
- Reusing the same activation correlation ID with identical parameters is idempotent.
- Reusing the same activation correlation ID with conflicting parameters fails.
- Initial activation of the same client account cannot occur twice.

## Authorization

- Only a planner owner can grant/revoke account authorizations.
- The target user must have membership before authorization is granted.
- The last active account-scope `planner_owner` cannot be revoked or removed.
- Removing membership revokes that user's active authorizations according to the approved semantics.
- Cross-account reads are denied.
- Client/entity/engagement scoped access is limited to the corresponding scope.

## RPC exposure

Expected authenticated public RPCs only:

- `create_economic_entity`
- `create_planning_engagement`
- `grant_client_account_authorization`
- `revoke_client_account_authorization`
- `record_planning_engagement_transition`

Expected backend-only:

- `activate_client_from_vri`

Internal helpers must not be exposed as public PostgREST RPCs.

## Replay / rollback

- Forward migration passes on the rehearsal environment.
- Reverse migration restores the pre-Phase-1B shape without corrupting Phase 1A objects.
- Clean reinstall from the same baseline produces an equivalent schema.
- Concurrency/idempotency probes for VRI activation and planner-owner revocation pass.

## Advisors

Run Supabase security and performance advisors after each DDL cycle. Every finding must be either remediated or explicitly accepted with rationale before Gate 002 closes.
