-- VIDA OS™ — Identity Phase 1A ownership/ACL current-state DRAFT
-- STATUS: NON-EXECUTABLE / NOT CLEAN-INSTALL-VALIDATED / DO NOT RUN IN PRODUCTION.
--
-- Precondition: B1 technical roles, Phase 1A structures and Phase 1A functions exist.
-- Purpose: reproduce the final ownership and direct-access surface observed in the
-- 2026-09-13 production catalog. Gate 002 RLS/RBAC changes are intentionally absent.

begin;

-- -----------------------------------------------------------------------------
-- Final table owners and current RLS state
-- -----------------------------------------------------------------------------

alter table public.economic_entities owner to vida_identity_owner;
alter table public.entity_relationships owner to vida_identity_owner;
alter table public.client_accounts owner to vida_identity_owner;
alter table public.client_account_entities owner to vida_identity_owner;
alter table public.client_account_users owner to vida_identity_owner;
alter table public.reconciliation_source owner to vida_identity_owner;
alter table public.reconciliation_record owner to vida_identity_owner;

alter table public.economic_entities disable row level security;
alter table public.entity_relationships disable row level security;
alter table public.client_accounts disable row level security;
alter table public.client_account_entities disable row level security;
alter table public.client_account_users disable row level security;
alter table public.reconciliation_source disable row level security;
alter table public.reconciliation_record disable row level security;

alter table public.economic_entities no force row level security;
alter table public.entity_relationships no force row level security;
alter table public.client_accounts no force row level security;
alter table public.client_account_entities no force row level security;
alter table public.client_account_users no force row level security;
alter table public.reconciliation_source no force row level security;
alter table public.reconciliation_record no force row level security;

-- Current production relacl for every Phase 1A table contains only the technical
-- owner. Explicitly remove the API/backend/operator roles from direct table access.
revoke all privileges on table
  public.economic_entities,
  public.entity_relationships,
  public.client_accounts,
  public.client_account_entities,
  public.client_account_users,
  public.reconciliation_source,
  public.reconciliation_record
from public, anon, authenticated, service_role,
     vida_reconciliation_operator, vida_identity_rollback_operator;

-- -----------------------------------------------------------------------------
-- Function owners
-- -----------------------------------------------------------------------------

alter function public.canonical_reconciliation(uuid,timestamptz)
  owner to vida_identity_owner;
alter function public.canonical_reconcile(uuid,text,text,text,text,text,uuid,text,text,boolean)
  owner to vida_identity_owner;
alter function public.canonical_rollback_guard()
  owner to vida_identity_owner;
alter function public.economic_entities_protect_owns_target()
  owner to vida_identity_owner;
alter function public.entity_relationships_enforce_owns_target()
  owner to vida_identity_owner;
alter function public.reconciliation_record_block_mutation()
  owner to vida_identity_owner;
alter function public.reconciliation_record_validate_succession()
  owner to vida_identity_owner;
alter function public.reconciliation_source_block_mutation()
  owner to vida_identity_owner;

-- Platform bridge deliberately remains owned by postgres because it is the minimal
-- SECURITY DEFINER adapter that reads auth.users for the technical identity owner.
alter function public.vida_auth_user_exists(uuid) owner to postgres;

-- -----------------------------------------------------------------------------
-- Function execution surface
-- -----------------------------------------------------------------------------

revoke all on function public.canonical_reconciliation(uuid,timestamptz)
  from public, anon, authenticated, service_role,
       vida_reconciliation_operator, vida_identity_rollback_operator;
revoke all on function public.canonical_reconcile(uuid,text,text,text,text,text,uuid,text,text,boolean)
  from public, anon, authenticated, service_role,
       vida_reconciliation_operator, vida_identity_rollback_operator;
revoke all on function public.canonical_rollback_guard()
  from public, anon, authenticated, service_role,
       vida_reconciliation_operator, vida_identity_rollback_operator;
revoke all on function public.economic_entities_protect_owns_target()
  from public, anon, authenticated, service_role,
       vida_reconciliation_operator, vida_identity_rollback_operator;
revoke all on function public.entity_relationships_enforce_owns_target()
  from public, anon, authenticated, service_role,
       vida_reconciliation_operator, vida_identity_rollback_operator;
revoke all on function public.reconciliation_record_block_mutation()
  from public, anon, authenticated, service_role,
       vida_reconciliation_operator, vida_identity_rollback_operator;
revoke all on function public.reconciliation_record_validate_succession()
  from public, anon, authenticated, service_role,
       vida_reconciliation_operator, vida_identity_rollback_operator;
revoke all on function public.reconciliation_source_block_mutation()
  from public, anon, authenticated, service_role,
       vida_reconciliation_operator, vida_identity_rollback_operator;
revoke all on function public.vida_auth_user_exists(uuid)
  from public, anon, authenticated, service_role,
       vida_reconciliation_operator, vida_identity_rollback_operator,
       vida_identity_owner;

-- The production write path is callable only through its dedicated operator role.
grant execute on function public.canonical_reconcile(uuid,text,text,text,text,text,uuid,text,text,boolean)
  to vida_reconciliation_operator;

-- Structural rollback is a separate administrative capability.
grant execute on function public.canonical_rollback_guard()
  to vida_identity_rollback_operator;

-- Minimal Auth existence bridge is callable only by the technical owner.
grant execute on function public.vida_auth_user_exists(uuid)
  to vida_identity_owner;

commit;
