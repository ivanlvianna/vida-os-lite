# VIDA OS™ — P0 Product Core Execution Physical Candidate

Status: **PHYSICAL DESIGN CANDIDATE / NON-EXECUTABLE / NO PRODUCTION AUTHORIZATION**  
Date: 2026-09-14  
Depends on: `P0_PRODUCT_CORE_PERSISTENCE_CONTRACT.md`, `P0_PRODUCT_CORE_V052_INTEGRATION_MAP.md`

## 1. Scope

This candidate defines only the persistence object needed to prove **one** Product Core v0.5.2 execution in the first P0 vertical slice.

It deliberately does not implement broad Planning Content, Prontuário, diagnostics, Decision Ledger, Temporal, Financial Reality or mass backfill.

## 2. Existing production relationships verified read-only

The current canonical production schema already provides the exact composite boundaries needed by P0:

- `planning_engagements` has `UNIQUE (client_account_id, id)`;
- `client_account_entities` has `PRIMARY KEY (client_account_id, economic_entity_id)`;
- authorization helpers exist in `vida_internal`, including `is_account_member`, `is_staff`, `has_role_in_scope`, `has_engagement_specific_role` and `has_entity_specific_role`.

Therefore a Product Core execution can be structurally prevented from pointing to an engagement or entity outside its own account. No e-mail/login heuristic is needed.

## 3. Candidate root object

Candidate table name:

`product_core_executions`

Candidate columns:

```text
id                         uuid primary key
client_account_id          uuid not null
economic_entity_id         uuid not null
planning_engagement_id     uuid not null
product_code               text not null
product_core_version       text not null
engine_artifact_md5        text not null
request_fingerprint        text not null
input_snapshot             jsonb not null
result_snapshot            jsonb not null
deterministic_render       jsonb not null
created_by                 uuid not null
created_at                 timestamptz not null default now()
```

For P0 the frozen values are:

```text
product_code = amortizar-investir
product_core_version = 0.5.2
engine_artifact_md5 = 78f7b0d877b3c8128048d9b286023217
```

## 4. Mandatory structural foreign keys

The candidate must include:

```text
(client_account_id, planning_engagement_id)
  → planning_engagements(client_account_id, id)

(client_account_id, economic_entity_id)
  → client_account_entities(client_account_id, economic_entity_id)

created_by
  → auth.users(id)
```

The two composite foreign keys are critical. They make cross-account rebinding impossible even to a privileged writer accidentally supplying mismatched UUIDs.

## 5. Immutability

A completed Product Core execution is an append-only historical fact.

P0 candidate rule:

- no direct `UPDATE`;
- no direct `DELETE`;
- changed facts/input/version produce a new execution;
- retries of the **same canonical request** resolve idempotently to the existing execution.

A trigger/internal guard should reject UPDATE/DELETE rather than relying only on application convention.

## 6. Request fingerprint

The request fingerprint must be produced from a canonical serialization of:

```text
product_code
product_core_version / engine_artifact fingerprint
client_account_id
economic_entity_id
planning_engagement_id
exact Product Core raw input snapshot
```

Candidate constraint:

`UNIQUE (client_account_id, planning_engagement_id, request_fingerprint)`

The fingerprint format/hash algorithm must be frozen in the executable candidate together with test vectors. P0 should not assume arbitrary JavaScript object-key order is a canonical serialization rule.

## 7. Snapshot semantics

### `input_snapshot`

Contains only the exact Product Core input contract needed for reproducibility. Monetary bigint cents must cross JSON as canonical base-10 strings and be parsed back to bigint by the adapter.

### `result_snapshot`

Contains the canonical `ResultadoPublicoAmortizarInvestir` produced by `construirResultadoPublico()`. It is not an LLM summary.

### `deterministic_render`

Contains the deterministic professional pt-BR rendering produced by:

`construirExplicacaoEstruturada()` → `renderizarExplicacaoDeterministica()`.

Optional concept-only LLM enrichment is not required for P0 and should not be mixed into the immutable deterministic result snapshot.

## 8. Candidate write surface

No direct application-role INSERT is proposed.

Candidate canonical RPC:

```text
record_product_core_execution(...)
```

Responsibilities:

1. derive the actor from the authenticated principal, never a caller-supplied actor UUID;
2. verify planner/staff authorization for the explicit account + engagement + entity scope;
3. validate the composite account/entity and account/engagement relationships;
4. validate frozen product/version/artifact identity for this P0 contract;
5. insert append-only execution or return the existing row for an identical idempotent retry;
6. reject a conflicting retry where the same idempotency identity maps to different snapshots.

Initial write roles should be restricted to the professional side (`planner_owner` / `internal_staff`) unless a later product decision explicitly authorizes client-originated Product Core execution.

## 9. Candidate read surface / RLS

RLS remains the read authority.

A Product Core execution is visible only if the current authenticated principal is authorized for the execution's `client_account_id`, `planning_engagement_id` and `economic_entity_id` according to the existing Gate 002 authorization model.

No policy may authorize by:

- e-mail;
- active UI context;
- possession of execution UUID;
- `created_by` alone;
- economic_entity_id without confirming the account/engagement perimeter.

The executable candidate must include negative tests for a second user/account.

## 10. Indexes required by the candidate

At minimum:

```text
(client_account_id, planning_engagement_id, created_at desc)
(client_account_id, economic_entity_id, created_at desc)
(created_by)
```

plus the unique idempotency index/constraint.

Indexes are finalized only together with the executable migration and advisor check.

## 11. P0 read model

The first UI does not require a general dashboard read-model layer.

A narrow authenticated repository query may load:

- the selected Planning Engagement;
- its latest/selected Product Core execution;
- the deterministic public result/render snapshot.

Selection of a "latest" execution must be explicit in repository semantics. A future dashboard must not silently redefine canonical history from `ORDER BY created_at DESC` across different engagement roots.

## 12. Physical gate checklist

Before this candidate becomes executable SQL:

- [x] exact Product Core v0.5.2 archive recovered and fingerprint verified;
- [x] exact input/public-output/deterministic-render pipeline mapped;
- [x] existing production composite account/entity and account/engagement constraints verified read-only;
- [ ] exact source tree imported into the P0 branch without semantic modification;
- [ ] canonical request serialization + hash test vectors frozen;
- [ ] executable migration candidate generated;
- [ ] RPC signature frozen;
- [ ] RLS/ACL negative-isolation tests written;
- [ ] zero-cost rehearsal apply/test/rollback/replay PASS;
- [ ] production DDL separately authorized.

No item below the first three is implied by this design document.
