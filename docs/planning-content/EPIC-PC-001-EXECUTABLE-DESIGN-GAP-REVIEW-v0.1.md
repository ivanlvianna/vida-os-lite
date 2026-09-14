# EPIC-PC-001 — Executable Design Gap Review v0.1

**Date:** 2026-09-14  
**Status:** REVIEW COMPLETE / PRE-EXECUTABLE / NO DATABASE MUTATION  
**Gate:** `PLANNING-CONTENT-PERSISTENCE-GATE-001 = OPEN / CANDIDATE GENERATION ONLY`

## Purpose

Determine whether the current Physical Target v0.2 + full commented DDL can be converted mechanically into executable PC-M01…PC-M09 migrations without inventing domain or security semantics.

## Conclusion

**No. Not yet mechanically.** The architecture is mature, but the commented DDL still contains templates/placeholders. Executable SQL may be generated only after the gaps below are either frozen technically or explicitly left out of v1.

This is not a regression of the architecture. It is the expected transition from architectural physical design to executable database design.

## Findings and dispositions

### EDG-01 — Common root/version/draft templates are not expanded

The candidate still contains placeholders such as `...common root...`, `...common version...`, `...common draft...` and `<typed payload>`.

**Disposition:** BLOCKER TO EXECUTABLE SQL. Expand every physical table explicitly before PC-M02/03/05 can be considered executable candidates.

### EDG-02 — ReviewEpisode exact target is incomplete in the commented DDL

Physical Target v0.2 requires a ReviewEpisode correction to preserve the real occurrence root while pinning an **exact ImplementationEpisodeVersion**. The current commented `ReviewEpisodeVersion` shows `implementation_episode_id` but omits `implementation_episode_version_id`.

**Disposition:** ERROR FOUND / MUST FIX. Add both root id and exact version id with same-engagement composite FK.

### EDG-03 — Version predecessor integrity needs a physical same-root FK

`supersedes_version_id` is unique, but writer-only validation is weaker than the v0.2 physical principle.

**Technical freeze candidate:** use a composite self-FK including `client_account_id`, `planning_engagement_id`, `root_id`, `supersedes_version_id` → the predecessor exact-version composite key. This physically prevents cross-root/cross-engagement predecessor chains.

### EDG-04 — Lifecycle order cannot rely only on timestamps

UUID ids plus `occurred_at` do not provide a deterministic aggregate-local order when timestamps collide.

**Technical freeze candidate:** add monotonic aggregate-local `event_no`/`transition_no` to WorkingHypothesis, HypothesisAgenda and DiagnosticReport lifecycle ledgers; writers allocate it under the same aggregate lock used for compare-and-set.

### EDG-05 — WorkingHypothesis origin needs stronger same-engagement integrity

The current proposal table key proves exact synthesis-version/proposal identity, but does not itself carry the account/engagement context used by the new WorkingHypothesis root.

**Technical freeze candidate:** carry `client_account_id` and `planning_engagement_id` in the proposal row and expose a composite unique key so WorkingHypothesis origin can be enforced physically across the same engagement.

### EDG-06 — PCP source instrument code can drift from the referenced InstrumentRun root

The source row has an `instrument_code`, while the canonical run code lives on InstrumentRun root. A writer can validate this, but the database can enforce it more strongly.

**Technical freeze candidate:** expose a root key including `instrument_code` and use it in the PCP source reference, while retaining exact version linkage.

### EDG-07 — Draft child schemas are still placeholders

Agenda draft items, session draft hypotheses/notes, report draft sources/hypotheses and plan draft goals/strategies/hypotheses are not fully expanded.

**Disposition:** BLOCKER TO EXECUTABLE PC-M05. Expand typed child-draft tables explicitly; no generic JSON draft bucket.

### EDG-08 — Base-version FKs for drafts must be exact and same-root

`base_version_id` is conceptually defined but not yet fully constrained in every draft family.

**Technical freeze candidate:** composite FK `(account, engagement, root_id, base_version_id)` → exact version key of the same family. `NULL` only for first draft before v1 exists.

### EDG-09 — Historical immutability trigger needs an auth-FK nullification exception

Actor auth ids use `ON DELETE SET NULL` so history survives deletion of the login. A blanket BEFORE UPDATE trigger on durable rows would block that FK action.

**Technical freeze candidate:** immutable-row guard rejects all UPDATE/DELETE except a narrowly defined transition from non-null actor auth id to null where all semantic/history fields and actor label snapshot remain unchanged.

### EDG-10 — RPC signatures are not yet executable contracts

Several writers are listed by name but not by final SQL argument/return types; `derive_diagnostic_synthesis` still contains `p_proposals <typed collection>`.

**Disposition:** BLOCKER TO EXECUTABLE PC-M07. Freeze one typed command contract per writer. Transport JSON may be considered only per-domain and must be validated into typed persistence; a universal `write_planning_content(jsonb)` remains forbidden.

### EDG-11 — Actor authorization basis needs a deterministic selection contract

A user may hold account-, engagement- and entity-scoped grants. The writer must snapshot the authorization that actually justified the operation, not an arbitrary active authorization.

**Disposition:** BLOCKER TO FINAL RPC IMPLEMENTATION. Freeze authorization precedence/required scope per command; `pc_resolve_actor_stamp` must receive enough command context to return the exact authorization basis.

### EDG-12 — Report consensus subject composite FK should be physical

D3 verification confirmed `planning_engagement_entities` lacks a redundant `(client_account_id, planning_engagement_id, economic_entity_id)` unique key.

**Technical freeze candidate:** PC-M01 adds that unique key, then DiagnosticReportVersion uses it to pin the frozen consensus subject to the same engagement. Writer checks remain defense in depth.

### EDG-13 — Read-model security form can now be frozen

D3 runs PostgreSQL 17.6. Staff projections can use PostgreSQL `security_invoker` views so underlying RLS remains authoritative.

**Technical freeze candidate:** PC-M09 uses `WITH (security_invoker = true)` for ordinary staff views. Use a SECURITY DEFINER function only where a separately reviewed projection genuinely requires it.

### EDG-14 — CHECK constraints vs ENUM

Existing D3 lifecycle/state contracts already use CHECK-style constraints and the domain is still evolving.

**Technical freeze candidate:** use CHECK constraints in v1 rather than introducing PostgreSQL ENUMs prematurely.

## What does NOT require Ivan's domain decision now

The following are technical persistence choices and can be closed inside this workstream: composite FKs, event sequencing, CHECK vs ENUM, security-invoker views, draft exact-version FKs, immutable-row guard mechanics and the ReviewEpisode exact-version correction.

## What remains outside this technical gate

The Method VIDA™ P0 semantic conflicts — ICV, IVRP, IVCP, PCP centrality, Variables of Rupture and Causa Final — remain separate doctrinal governance issues. This persistence work must not resolve those conflicts by inference.

## Next admissible artifact

`EPIC-PC-001-EXECUTABLE-DESIGN-FREEZE-v0.1` should:

1. freeze the technical candidates above where no domain decision is required;
2. expand every root/version/draft/child/ledger table explicitly;
3. define exact same-engagement keys/FKs;
4. freeze per-writer SQL signatures and authorization basis;
5. produce candidate SQL bodies only after this review passes;
6. still perform **zero apply** to D3 or production.
