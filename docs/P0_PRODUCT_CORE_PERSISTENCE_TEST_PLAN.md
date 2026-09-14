# VIDA OS™ — P0 Product Core Persistence Test Plan

Status: **TEST PLAN FROZEN / EXECUTION PENDING PHYSICAL MIGRATION CANDIDATE**  
Date: 2026-09-14

This plan qualifies only the narrow Product Core execution persistence needed by P0.

## Acceptance families

### PC-P1 — Structure and ownership

- dedicated `product_core_executions` object exists;
- owned by the canonical VIDA OS domain owner chosen by the executable migration;
- RLS enabled;
- no direct application-role INSERT/UPDATE/DELETE;
- append-only mutation guard active;
- required account/entity and account/engagement composite foreign keys exist;
- required idempotency uniqueness exists.

### PC-P2 — Canonical context integrity

Prove that a row cannot be written when:

- `planning_engagement_id` belongs to another `client_account_id`;
- `economic_entity_id` is not linked to the supplied account;
- engagement/entity UUIDs are individually valid but cross-account mismatched.

Expected result: database-level rejection independent of application code.

### PC-P3 — Canonical writer authorization

For the eventual `record_product_core_execution(...)` RPC:

- authorized planner/staff can write in permitted scope;
- ordinary unauthorized account member cannot use professional write authority;
- caller cannot spoof `created_by`;
- anon cannot execute;
- service-role exposure is not used as a substitute for authenticated authorization unless a separately documented backend workflow requires it.

### PC-P4 — Frozen engine identity

P0 candidate accepts only the expected product/core identity:

```text
product = amortizar-investir
version = 0.5.2
artifact MD5 = 78f7b0d877b3c8128048d9b286023217
```

A different engine fingerprint/version must create a distinct execution contract or be rejected according to the frozen RPC design; it must never masquerade as v0.5.2.

### PC-P5 — Monetary fidelity

Use test vectors containing values that would lose cents if converted through unsafe JavaScript `number` arithmetic.

Prove:

- input bigint cents serialize losslessly to canonical decimal strings;
- adapter restores exact bigint cents;
- persisted public result preserves Product Core exact decimal money strings;
- reload returns byte-equivalent deterministic money fields.

### PC-P6 — Deterministic pipeline

For one frozen input fixture:

```text
analisarAmortizarOuInvestir
→ construirResultadoPublico
→ construirExplicacaoEstruturada
→ renderizarExplicacaoDeterministica
```

Run twice and prove the persisted deterministic output is equal. No LLM is required for this acceptance family.

### PC-P7 — Idempotent retry

Same canonical context + same engine identity + same canonical input:

- first request creates exactly one execution;
- retry returns/resolves to the same execution;
- row count remains one;
- no duplicate history event/result is created.

Conflicting retry using an existing idempotency identity with different snapshots must fail rather than overwrite history.

### PC-P8 — Append-only history

Attempt direct and privileged-path UPDATE/DELETE according to the supported test roles.

Expected result: completed Product Core execution remains immutable. A changed financial input or recalculation creates a new execution ID.

### PC-P9 — RLS positive read

Authenticated authorized principal can reload its Product Core execution through the same account/engagement context used by the UI.

### PC-P10 — Cross-account negative isolation

Create synthetic account A/user A and account B/user B.

Prove user B cannot:

- SELECT execution A by ID;
- enumerate execution A through list queries;
- infer it through a repository "latest" query;
- write/update/delete it;
- create an execution bound to account A's engagement/entity.

Possession of execution UUID must not change the result.

### PC-P11 — Same-account scoped isolation

Where the authorization model grants a role only for a specific engagement/entity, prove that the role does not gain access to another engagement/entity in the same account unless its scope permits it.

### PC-P12 — UI reload proof

End-to-end non-production proof:

1. authenticated session resolves `CurrentPrincipal`;
2. canonical account/entity/engagement context resolves;
3. one real v0.5.2 case runs;
4. canonical writer persists it;
5. process/request boundary is crossed;
6. result is reloaded from DB rather than reused from memory;
7. deterministic result is displayed inside the same Planning Engagement;
8. negative user/account sees no result.

This is the P0 acceptance path:

`Auth → Identity → Account → Engagement → Product Core → Persistence → Reload → UI → Isolation`.

### PC-P13 — Rollback / replay

In the existing zero-cost non-production environment:

- apply exact candidate;
- run PC-P1–PC-P12 synthetic-safe subset;
- record schema fingerprint / object inventory;
- rollback cleanly to prior Gate 002 baseline;
- replay exact candidate;
- obtain equivalent structural result;
- preserve pre-existing Gate 002 sentinel/baseline data.

### PC-P14 — Advisors

After replay:

- security advisor reviewed;
- performance advisor reviewed;
- no new unintended public/anon surface;
- no new unindexed FK introduced by the Product Core persistence candidate;
- intentional SECURITY DEFINER/RLS findings explicitly classified.

## Production boundary

Passing this plan in rehearsal does **not** authorize production DDL. A separate explicit production apply decision remains mandatory.
