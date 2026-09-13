-- VIDA OS™ — Identity Phase 1A current-state structure DRAFT
-- STATUS: NON-EXECUTABLE / NOT CLEAN-INSTALL-VALIDATED / DO NOT RUN IN PRODUCTION.
--
-- Scope: the seven Phase 1A tables, constraints and non-constraint indexes exactly
-- as observed in the 2026-09-13 production catalog. Functions, triggers, owners and
-- privileges are intentionally split into later bootstrap components.
--
-- IMPORTANT: client_account_users.auth_user_id deliberately has NO physical FK to
-- auth.users in the approved production baseline. Gate 002 proposes adding that FK,
-- but the forward delta must not be folded into this baseline reconstruction.

begin;

create table public.economic_entities (
  id uuid primary key default gen_random_uuid(),
  entity_type text not null,
  display_name text not null,
  created_at timestamptz not null default now(),
  constraint economic_entities_entity_type_check
    check (entity_type = any (array['person'::text,'organization'::text])),
  constraint economic_entities_display_name_not_blank
    check (btrim(display_name) <> ''::text)
);

create table public.entity_relationships (
  id uuid primary key default gen_random_uuid(),
  from_entity_id uuid not null
    references public.economic_entities(id) on delete restrict,
  to_entity_id uuid not null
    references public.economic_entities(id) on delete restrict,
  relationship_type text not null,
  created_at timestamptz not null default now(),
  constraint entity_relationships_no_self_reference
    check (from_entity_id <> to_entity_id),
  constraint entity_relationships_relationship_type_check
    check (relationship_type = 'owns'::text),
  constraint entity_relationships_unique_relationship
    unique (from_entity_id,to_entity_id,relationship_type)
);

create index idx_entity_relationships_to_entity_id
  on public.entity_relationships(to_entity_id);

create table public.client_accounts (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now()
);

create table public.client_account_entities (
  client_account_id uuid not null
    references public.client_accounts(id) on delete restrict,
  economic_entity_id uuid not null
    references public.economic_entities(id) on delete restrict,
  created_at timestamptz not null default now(),
  primary key (client_account_id,economic_entity_id)
);

create index idx_client_account_entities_economic_entity_id
  on public.client_account_entities(economic_entity_id);

create table public.client_account_users (
  client_account_id uuid not null
    references public.client_accounts(id) on delete cascade,
  auth_user_id uuid not null,
  created_at timestamptz not null default now(),
  primary key (client_account_id,auth_user_id)
);

create index idx_client_account_users_auth_user_id
  on public.client_account_users(auth_user_id);

create table public.reconciliation_source (
  id uuid primary key default gen_random_uuid(),
  source_namespace text not null,
  source_value text not null,
  created_at timestamptz not null default now(),
  constraint reconciliation_source_unique
    unique (source_namespace,source_value)
);

create table public.reconciliation_record (
  id uuid primary key default gen_random_uuid(),
  reconciliation_source_id uuid not null
    references public.reconciliation_source(id) on delete restrict,
  result text not null,
  economic_entity_id uuid
    references public.economic_entities(id) on delete restrict,
  supersedes_reconciliation_record_id uuid unique
    references public.reconciliation_record(id) on delete restrict,
  recorded_at timestamptz not null,
  decided_by text not null,
  decided_note text,
  constraint reconciliation_record_result_check
    check (result = any (array['BLOCKED'::text,'REJECTED'::text,'CONFIRMED'::text])),
  constraint reconciliation_record_entity_matches_result
    check (
      result = 'CONFIRMED'::text and economic_entity_id is not null
      or (result = any (array['BLOCKED'::text,'REJECTED'::text])) and economic_entity_id is null
    ),
  constraint reconciliation_record_no_self_supersede
    check (
      supersedes_reconciliation_record_id is null
      or supersedes_reconciliation_record_id <> id
    ),
  constraint reconciliation_record_decided_by_not_blank
    check (btrim(decided_by) <> ''::text)
);

create index idx_reconciliation_record_source
  on public.reconciliation_record(reconciliation_source_id,recorded_at);

create unique index uq_reconciliation_record_root
  on public.reconciliation_record(reconciliation_source_id)
  where supersedes_reconciliation_record_id is null;

commit;
