# EPIC-PC-001 — Executable Design Freeze v0.1

**Date:** 2026-09-14  
**Status:** TECHNICAL FREEZE / PRE-EXECUTABLE / NON-APPLIED  
**Gate:** `PLANNING-CONTENT-PERSISTENCE-GATE-001 = OPEN / CANDIDATE GENERATION ONLY`

## Purpose

Freeze the database-design decisions that are technical, do not require new Method VIDA™ doctrine, and are necessary before PC-M01…PC-M09 can be written as executable candidates.

This artifact authorizes design refinement only. It does not authorize migration apply, project link, remote reset, production changes or merge to `main`.

## D3 authorization facts verified read-only

Current canonical D3 behavior:

- `has_role_in_scope(...)` recognizes an active account-, engagement- or entity-scoped authorization only when current membership exists in `client_account_users`;
- `matched_staff_role(client_account_id)` recognizes only active account-scope `planner_owner` / `internal_staff`, with `planner_owner` precedence;
- `grant_client_account_authorization(...)` requires authenticated `planner_owner` and existing membership;
- actor display label is derived server-side from `auth.users`;
- current helpers use `SECURITY DEFINER` + `SET search_path=''`.

## Frozen technical decisions

### EDF-01 — CHECK constraints, not PostgreSQL ENUMs, in v1

Use CHECK constraints for evolving domain state/code sets. This matches current D3 practice and avoids premature enum migration complexity.

### EDF-02 — Supporting engagement/entity unique key

PC-M01 may add:

`UNIQUE (client_account_id, planning_engagement_id, economic_entity_id)`

on `planning_engagement_entities` solely as a reference-support key. It does not redefine the table's domain identity.

DiagnosticReportVersion should use this key to physically pin its frozen consensus subject to the same account/engagement.

### EDF-03 — Same-root predecessor FK for every durable version family

Every version table exposes an exact composite key sufficient for self-reference.

A successor's predecessor reference must be a composite FK containing:

`client_account_id + planning_engagement_id + root_id + supersedes_version_id`

pointing to the exact predecessor key on the same version table.

This prevents cross-account, cross-engagement and cross-root predecessor chains physically. Writer locking still enforces terminal-predecessor and `version_no + 1` semantics.

### EDF-04 — Aggregate-local lifecycle sequence

Lifecycle/event ledgers receive monotonic aggregate-local sequence fields:

- WorkingHypothesis: `transition_no`;
- HypothesisAgenda: `transition_no`;
- DiagnosticReport workflow: `event_no`;
- DiagnosticReport consensus manifestation: `manifestation_no` per report version/subject lineage as appropriate.

Sequence allocation occurs under the same aggregate lock used for compare-and-set. Current state is derived by sequence, not timestamp ordering.

### EDF-05 — WorkingHypothesis exact origin carries context

`planning_content_hypothesis_proposals` carries `client_account_id` and `planning_engagement_id` and exposes a composite exact key including synthesis version + proposal key.

WorkingHypothesis root carries the same context and references the proposal through a composite FK. Writer validation remains defense in depth.

### EDF-06 — PCP source instrument code must match the referenced run

InstrumentRun root exposes a key that includes `instrument_code`. PCP source rows carry the exact run root/version plus instrument code. The physical references must prevent an `ICV-01` source label from pointing to an IMDP/IVRP run.

The derive writer still enforces exactly one source each for ICV-01, IMDP-01 and IVRP-01.

### EDF-07 — Draft base version is exact and same-root

Every draft family with `base_version_id` uses a composite FK:

`client_account_id + planning_engagement_id + root_id + base_version_id`

→ exact version key of the same aggregate family.

`base_version_id IS NULL` is permitted only before the first durable version exists; the writer proves that condition under lock.

### EDF-08 — ReviewEpisode targets an exact ImplementationEpisodeVersion

Correct the commented DDL. `ReviewEpisodeVersion` contains both:

- `implementation_episode_id`;
- `implementation_episode_version_id`.

It references the exact implementation version through same-engagement composite FK. A correction to a ReviewEpisode creates a successor version under the same ReviewEpisode root; it does not fabricate a new real review occurrence.

### EDF-09 — Historical immutability guard permits only auth-FK nullification

Durable versions, immutable child/reference rows and lifecycle ledgers reject application UPDATE/DELETE.

The immutable-row guard may permit only the narrow technical effect required by `auth.users ... ON DELETE SET NULL`: an actor auth id may change from non-null to null while all semantic fields, actor label snapshot, authorization snapshot and domain references remain unchanged.

No other historical mutation is permitted.

### EDF-10 — Staff writer authorization contract

All professional Planning Content writers require current account-scope staff authorization:

roles = `planner_owner` or `internal_staff`.

Actor snapshot basis is the actual active account-scope authorization that authorizes the command. If both roles exist, `planner_owner` wins, matching current `matched_staff_role` precedence.

A new internal resolver may return:

- `actor_auth_user_id`;
- exact `actor_authorization_id`;
- immutable `actor_label_snapshot`;
- resolved staff role;
- `actor_origin='planner'` for authenticated professional commands.

Callers cannot supply or override these values.

### EDF-11 — Client consensus self-service is a narrow exception

`record_report_consensus(...)` may accept either:

1. staff account-scope authorization (`planner_owner`/`internal_staff`) recording a client's manifestation; or
2. authenticated client self-service with current membership **and** appropriate engagement-specific **and** entity-specific authorization for the frozen consensus subject.

Client self-service does not grant raw table DML and does not turn the client's EconomicEntity into the technical actor identity. Actor and manifestation subject remain distinct.

`external_advisor` is not treated as the report-consensus subject by default in v1 unless separately authorized by future doctrine.

### EDF-12 — Writer functions are fail-closed at creation

Every public `SECURITY DEFINER` writer:

- uses `SET search_path=''`;
- is created with no broad usable surface;
- immediately receives `REVOKE ALL ... FROM PUBLIC, anon, authenticated, service_role`;
- receives explicit EXECUTE only in PC-M08 after function-specific review.

Internal helpers remain postgres-only unless explicitly approved.

### EDF-13 — PC-M09 staff read models use security-invoker views by default

D3 is PostgreSQL 17.6. Ordinary staff projections should use:

`CREATE VIEW ... WITH (security_invoker = true)`

so underlying table privileges/RLS remain authoritative.

A SECURITY DEFINER read function is an exception requiring separate review; it is not the default projection mechanism.

### EDF-14 — No universal persistence endpoint

There is no `write_planning_content(jsonb)` or generic target registry.

A domain-specific RPC may use JSON as **transport** for a bounded collection only if:

- the RPC is specific to one domain command;
- structure is validated deterministically before persistence;
- storage is normalized into typed tables;
- malformed/unknown keys fail closed;
- the JSON payload is never stored as a generic substitute for the domain schema.

Instrument result envelope remains the already approved opaque JSON persistence exception.

## Per-command authorization matrix v0.1

| Command family | Authorized technical actor |
|---|---|
| Interview draft/commit/correction | account-scope staff |
| Instrument run record/correction | account-scope staff |
| DiagnosticSynthesis derive | account-scope staff |
| WorkingHypothesis establish/edit/transition | account-scope staff |
| HypothesisAgenda create/edit/close | account-scope staff |
| DiagnosticSession create/edit/correct | account-scope staff |
| DiagnosticReport create/edit/submit/validate/revise | account-scope staff |
| Report consensus — staff recording | account-scope staff |
| Report consensus — client self-service | membership + engagement authorization + entity authorization for frozen subject |
| FinancialPlan create/revise | account-scope staff |
| ImplementationEpisode record/correct | account-scope staff |
| ReviewEpisode record/correct | account-scope staff |

## Remaining blockers before executable candidate SQL

The technical architecture is now frozen enough to continue, but these implementation artifacts must still be produced explicitly:

1. fully expanded root tables — no `...common root...` placeholders;
2. fully expanded version tables — no `<typed payload>` placeholders;
3. fully expanded draft + draft-child tables;
4. fully expanded lifecycle tables with sequence keys;
5. exact FK/index/constraint names;
6. final per-domain RPC SQL signatures and return contracts;
7. static proof that all PC-M02…PC-M06 table creation blocks include RLS + REVOKE in the same transaction;
8. test-harness mapping from each frozen invariant to a test id.

These are implementation-definition tasks, not new Method VIDA™ decisions.

## Separate unresolved doctrine

Nothing in this freeze resolves the Method VIDA™ P0 semantic conflicts around ICV / IVRP / IVCP / PCP / Variáveis de Ruptura / Causa Final. Those remain explicitly outside the persistence gate.

## Next step

Produce `EPIC-PC-001-PHYSICAL-EXPANSION-v0.1` with every PC-M02…PC-M06 table written out explicitly, followed by the RPC signature freeze for PC-M07. Still no Supabase apply.
