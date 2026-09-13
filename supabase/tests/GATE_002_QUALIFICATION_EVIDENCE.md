# Gate 002 — Rehearsal Qualification Evidence

Status: **TECHNICALLY QUALIFIED IN ZERO-COST REHEARSAL / NOT AUTHORIZED FOR PRODUCTION APPLY**

Date: 2026-09-13
Rehearsal project: `migration-a-phase0-ensaio` (`jijdyrinuzyjampptbaf`)
Production project: `dlobyyzixcandloxbeth` — read-only verification only.

## Scope qualified

Logical chain:

1. M1 — Phase 1A security hardening.
2. M2.01–M2.04 — Planning / RBAC-ABAC / VRI core.
3. M2.1 — canonical membership governance + append-only membership ledger.
4. M2.2 — Auth FK-cascade contract.
5. M2.3 — active-authorization Auth-delete block.
6. M3 — access surface / RLS.
7. M4 — persisted retryable offboarding workflow.
8. M5 — performance hardening.

## Functional proofs

- VRI activation idempotency: PASS.
- Same activation token with conflicting payload: rejected.
- `ambiguous_match` automatic activation: rejected.
- Second initial activation for one account: rejected.
- Planning state-machine valid/invalid transitions: PASS.
- Terminal reason required and terminal reopen blocked: PASS.
- Membership add/remove canonical workflows: PASS.
- Membership event ledger append-only semantics: PASS.
- Repeated already-satisfied add/remove: idempotent.
- `internal_staff` cannot perform planner-owner membership administration: PASS.
- Last active account-scope `planner_owner` cannot be removed: PASS.
- Grant without current membership: rejected.
- Duplicate active exact authorization scope: rejected.
- Revoked authorization cannot be reactivated: PASS.
- EconomicEntity immutable-field guard exact error: PASS.
- Offboarding state/retry workflow: PASS.
- Direct Auth-user deletion shortcut with active authorization: blocked.
- Authorization/membership/offboarding history survives canonical offboarding: PASS.

## Real concurrency proof

Two independent `pg_cron` sessions executed `add_client_account_membership()` for the same `(client_account_id, auth_user_id)` at effectively the same time.

Observed final state:

- membership rows: **1**
- `added` membership ledger events: **1**
- both concurrent jobs: succeeded

The synthetic fixture and both cron jobs were then removed; Phase 1A sentinel data remained intact.

## PostgREST/internal-helper proof

External HTTP request to `/rest/v1/rpc/is_staff` returned **404 / PGRST202** because `public.is_staff` is absent from the schema cache. A public known RPC resolved separately, proving the request reached PostgREST.

Catalog checks also confirmed:

- `public.is_staff(uuid)`: absent
- `vida_internal.is_staff(uuid)`: present
- `anon` USAGE on `vida_internal`: false
- `anon` EXECUTE on helper: false

## RLS / ACL proof

Rehearsal final state:

- 17 relevant canonical/Gate tables with RLS ON
- 0 relevant tables with RLS OFF
- 16 Identity/Access/Planning policies
- 16/16 policies explicitly scoped to `authenticated`
- direct INSERT/DELETE grants on `client_account_users` for `authenticated`/`service_role`: **0**
- Phase 1A reconciliation tables remain unreadable directly by `anon` and `authenticated`

Production read-only inspection independently confirmed no direct table privileges for PUBLIC, `anon`, `authenticated` or `service_role` on the seven Phase 1A canonical tables.

## Performance/security advisor outcome

M5 removed the 14 Gate-002 unindexed-FK findings and the two RLS `auth.uid()` initplan findings. The remaining unindexed-FK finding belongs to legacy `diagnosticos_vida.user_id`, outside Phase 1B.

Security advisor remaining findings are classified as follows:

- authenticated-callable `SECURITY DEFINER` public RPCs: intentional reviewed application surface; negative authorization tests required and passed for relevant operations.
- RLS enabled/no policy on backend-only/deny-by-default ledgers and Phase 1A deny-by-ACL tables: informational and intentional pending any future read contract.
- leaked-password protection disabled: separate Supabase Auth configuration item, not a Gate 002 migration blocker.

## Rollback → replay equivalence

A full Gate-002 rollback to the Phase 1A baseline was executed in rehearsal. The first cycle exposed one rollback defect: `economic_entities_insert` survived because it did not depend on `vida_internal`. The rollback artifact was corrected to drop that policy explicitly.

After correction, two successive clean reconstructions were run from the Phase 1A baseline using the recorded Gate-002 migration bodies.

Final equivalence proof:

- replay fingerprint 1: `a1d16abf1a6ae8acbb261bcbd72afb76`
- rollback + replay fingerprint 2: `a1d16abf1a6ae8acbb261bcbd72afb76`
- compared object lines: **218**
- result: **PASS**

The fingerprint covered Gate-002 tables, constraints, indexes, policies, functions, ACLs and RLS configuration. Phase 1A sentinel data survived the cycles.

## Production boundary

None of M1–M5 in this candidate chain has been applied to the production Supabase project through this PR. No merge to `main` is implied or authorized by rehearsal qualification.

`MIGRATION-APPLY-GATE-002` therefore remains **OPEN FOR PRODUCTION APPLY**, while its **technical rehearsal qualification is PASS**.
