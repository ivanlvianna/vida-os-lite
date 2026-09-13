-- VIDA OS™ — Gate 002 v4 / M1
-- Production-compatible Phase 1A hardening.
-- postgres temporarily inherits vida_identity_owner only inside this transaction.

begin;
grant vida_identity_owner to postgres with inherit true, set true;

alter function public.canonical_reconciliation(uuid, timestamp with time zone) set search_path = '';
alter function public.reconciliation_source_block_mutation() set search_path = '';
alter function public.reconciliation_record_block_mutation() set search_path = '';
alter function public.reconciliation_record_validate_succession() set search_path = '';
alter function public.entity_relationships_enforce_owns_target() set search_path = '';
alter function public.economic_entities_protect_owns_target() set search_path = '';

create index if not exists reconciliation_record_economic_entity_id_idx
  on public.reconciliation_record (economic_entity_id);

alter table public.entity_relationships enable row level security;
alter table public.reconciliation_source enable row level security;
alter table public.reconciliation_record enable row level security;

revoke execute on function public.canonical_reconciliation(uuid,timestamp with time zone) from public,anon,authenticated,service_role;
revoke execute on function public.reconciliation_source_block_mutation() from public,anon,authenticated,service_role;
revoke execute on function public.reconciliation_record_block_mutation() from public,anon,authenticated,service_role;
revoke execute on function public.reconciliation_record_validate_succession() from public,anon,authenticated,service_role;
revoke execute on function public.entity_relationships_enforce_owns_target() from public,anon,authenticated,service_role;
revoke execute on function public.economic_entities_protect_owns_target() from public,anon,authenticated,service_role;

grant vida_identity_owner to postgres with inherit false, set true;
commit;
