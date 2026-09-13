# VIDA OS™ — Gate 002 executable-test map v3

Status: **TEST SPEC / SQL HARNESS PENDING**

This supersedes the v2 test plan where it conflicts with the FROZEN Authorization/Membership criteria.

## A. Phase 1A preservation and security

- Snapshot IDs/counts for `economic_entities`, `reconciliation_source`, `reconciliation_record` before the chain; compare after.
- Confirm M1 fixes all six mutable `search_path` findings.
- Confirm `reconciliation_record_economic_entity_id_idx` exists.
- Confirm current production-like ACL baseline: PUBLIC/anon/authenticated/service_role have no direct privileges on all seven Phase 1A canonical tables before Phase 1B access grants.

## B. Structure

After M2 + M2.1 + M4, assert existence of:
- seven Phase 1B core tables;
- `client_account_membership_events`;
- `client_account_offboarding_workflows`;
- `client_account_offboarding_events`.

Assert no Phase 1A canonical table was recreated or dropped.

## C. FROZEN C1 — Membership governance

### AUTH-P4
`planner_owner` calls `add_client_account_membership` for a valid Auth user:
- membership created;
- exactly one `added` event created;
- actor equals `auth.uid()`;
- justification persisted.

### AUTH-P5
`planner_owner` calls `remove_client_account_membership`:
- active authorizations are revoked, not deleted;
- membership removed;
- exactly one `removed` event created;
- all effects commit atomically.

### C1 concurrency
Two concurrent calls to add the same `(client_account_id, auth_user_id)`:
- exactly one membership exists;
- exactly one `added` event exists;
- the second call is a no-op or returns the idempotent result.

### Direct-DML negatives
As `authenticated` and `service_role`:
- direct INSERT into `client_account_users` fails by privilege;
- direct DELETE from `client_account_users` fails by privilege;
- direct UPDATE/DELETE of membership events fails / is impossible.

### Last-owner invariant
Removing the last active account-scope `planner_owner` fails with the expected last-owner error and leaves all rows unchanged.

## D. FROZEN C2 — Internal helper exposure

- `vida_internal` exists.
- Authorization helpers live in `vida_internal`, not `public`.
- Confirm the project PostgREST exposed-schemas list does NOT contain `vida_internal`.
- RLS policies still evaluate successfully for authenticated users.
- HTTP/PostgREST cannot resolve helpers as RPC endpoints.

## E. FROZEN C3 — Policy roles

For every Identity/Access/Planning policy:
- `pg_policies.roles = {authenticated}` (or a deliberately more-specific role if ever introduced);
- no `{public}` policy exists.

Expected M3 v3 policy count: **16**.

## F. FROZEN C4 — EconomicEntity update

- `economic_entities_update` has non-null `USING` and `WITH CHECK`.
- Attempt to change `economic_entities.id` fails specifically with `Apenas display_name pode ser atualizado em economic_entities`.
- Unauthorized `client_account_entities` INSERT/DELETE fails by its own policy.

## G. Existing RBAC/ABAC invariants

- AUTH-P1/P2/P3 as defined in the FROZEN criteria.
- AUTH-N1 through AUTH-N10 individually captured.
- Exact error message/constraint name captured for every negative case where specified.
- No access from authorization without current membership.
- Revoked authorization cannot be reactivated.
- No duplicate active exact role/scope tuple.

## H. Planning lifecycle

- Valid transitions succeed.
- Invalid transitions fail.
- Paused resumes only to prior state or allowed terminal path.
- Terminal requires reason.
- Terminal cannot reopen.
- Direct state mutation fails.
- Transition ledger update/delete fails.
- Predecessor belongs to same account and is terminal.

## I. VRI activation

- `ambiguous_match` auto-activation fails.
- `no_match` requires entity type + display name.
- `match_confident` requires existing entity and forbids creation fields.
- Same activation token + same payload is idempotent.
- Same activation token + conflicting payload fails.
- One initial activation per account.
- Initial backend bootstrap creates exactly one membership `added` event with backend-system provenance.

## J. FROZEN C5 — Offboarding

### AUTH-L1
1. Start workflow as `planner_owner`.
2. If target is last owner, establish replacement owner first.
3. DB step revokes target authorizations, removes target membership and preserves audit ledgers.
4. Workflow state becomes `database_access_removed`.
5. Simulate Auth Admin session revocation; only after `auth.sessions` has zero target rows can backend mark `sessions_revoked`.
6. Simulate Auth Admin user deletion; only after `auth.users` has no target row can backend mark `completed`.

### AUTH-L1b retry
- Inject external failure after DB step; record retryable failure; state remains `database_access_removed`.
- Retry session revocation and continue without duplicating membership/offboarding events.
- Inject failure after sessions revoked; state remains `sessions_revoked`; retry user deletion safely.

### AUTH-L2
Direct deletion of an Auth user while an active membership/authorization still exists, outside the canonical workflow, must fail; capture the exact enforcing error/constraint.

### AUTH-L3
After completion:
- authorization rows remain as revoked history;
- membership add/remove event ledger remains intact;
- offboarding event ledger remains intact;
- no historical actor/subject identifier is erased merely because Auth login was deleted.

## K. Replay / rollback / residue

- Forward chain on clean production-like Phase 1A baseline.
- Negative tests leave no partial residue.
- Reverse rehearsal removes only Phase 1B objects when eligible and leaves Phase 1A unchanged.
- Clean replay produces an equivalent schema.
- Re-run Supabase security/performance advisors.
