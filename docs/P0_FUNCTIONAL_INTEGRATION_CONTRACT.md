# VIDA OS™ — P0 Functional Integration Contract

Status: **FROZEN FOR IMPLEMENTATION**  
Date: 2026-09-13  
Working branch: `p0-functional-integration`  
Governance base: `gate-0-schema-as-code`

## Objective

Prove the first real end-to-end VIDA OS™ vertical slice on top of the Gate 002 v4 production foundation.

Canonical acceptance path:

`Auth → Identity → Account → Engagement → Product Core → Persistence → Reload → UI → Isolation`

The slice is accepted only when the same persisted result can be recovered from the database and displayed inside the same Planning Engagement, while a different account/user cannot read or mutate it.

## Required context-creation path

Phase 1B intentionally entered production with zero Client Accounts, memberships and Planning Engagements. Therefore P0 must prove both context creation and context consumption.

For an authenticated principal without context:

1. resolve `CurrentPrincipal`;
2. detect absence of a usable Client Account;
3. invoke the canonical backend VRI activation workflow;
4. obtain/create the Economic Entity according to VRI identity resolution;
5. obtain the Client Account;
6. confirm canonical membership + authorization;
7. obtain the initial Planning Engagement;
8. continue into the Product Core case.

`activate_client_from_vri()` remains backend/service-role only. Interactive sessions must never call it directly.

## Architectural boundaries

- Identity, authorization and scope remain distinct concepts.
- Session/cookie/JWT mechanics live only in SessionContext / IdentityContext.
- `CurrentPrincipal` is the identity contract consumed above the identity layer.
- RLS is the source of truth for reads; UI/application code must not duplicate read authorization rules.
- Domain writes use canonical RPCs/workflows. No direct table mutation is introduced where Gate 002 defines an RPC boundary.
- Service-role access is server-only and passes through a dedicated authorizer/application-service boundary.
- Active Context is a UI/navigation convention, never an authorization source.
- No homologated migration is edited as part of this P0.

## Gate 002 production facts consumed by P0

- `activate_client_from_vri()` is service-role/backend provisioned and rejects interactive `auth.uid()` sessions.
- Supported VRI identity resolutions for automatic activation are `no_match` and `match_confident`; `ambiguous_match` must not auto-activate.
- `no_match` requires `entity_type` (`person` or `organization`) plus nonblank `display_name` and no existing Economic Entity id.
- `match_confident` requires an existing Economic Entity id and no new entity fields.
- Activation is idempotent by `vri_activation_correlation_id` and rejects conflicting retries.
- Authenticated domain reads are protected by RLS.
- Canonical membership/authorization and Planning Engagement lifecycle rules remain enforced in PostgreSQL.

## Product Core boundary

The frozen Product Core v0.5.2 is integrated as a deterministic domain component. Its canonical factual summary/scenario are not rewritten by the LLM layer. LLM usage, when present, is restricted to concept-only complementary text without numeric content. Monetary values retain cent precision and user-facing BRL formatting.

P0 will integrate one real Product Core case before adding broader modules.

## Explicitly out of scope

- broad Prontuário expansion;
- additional diagnostics;
- Decision Ledger;
- broad patrimony domain;
- Temporal/Provenance workstream;
- mass backfill;
- merge of PR #1 or this P0 into `main`;
- reopening Gate 002/foundation unless implementation reveals a concrete contract violation.

## Definition of done

P0 is complete only when all of the following are demonstrated against the real Supabase/RLS surface:

- authenticated principal resolved;
- existing vs missing context detected correctly;
- missing context created only through canonical VRI/backend activation;
- Economic Entity, Client Account, membership/authorization and Planning Engagement resolved;
- one Product Core v0.5.2 case executed;
- result persisted under the correct account + engagement boundary;
- reload reads the persisted result back;
- UI renders it inside the same Planning Engagement;
- negative isolation test proves a different user/account cannot access it;
- build/lint/tests remain green.
