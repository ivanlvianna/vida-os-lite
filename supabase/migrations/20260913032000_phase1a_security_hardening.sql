-- VIDA OS™ — Gate 002 / M1
-- Phase 1A security hardening, consolidated from rehearsal-proven steps.
-- No business-data backfill. No Phase 1A object recreation.

begin;

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

revoke execute on function public.canonical_reconciliation(uuid,timestamp with time zone)
  from public,anon,authenticated,service_role;
revoke execute on function public.reconciliation_source_block_mutation()
  from public,anon,authenticated,service_role;
revoke execute on function public.reconciliation_record_block_mutation()
  from public,anon,authenticated,service_role;
revoke execute on function public.reconciliation_record_validate_succession()
  from public,anon,authenticated,service_role;
revoke execute on function public.entity_relationships_enforce_owns_target()
  from public,anon,authenticated,service_role;
revoke execute on function public.economic_entities_protect_owns_target()
  from public,anon,authenticated,service_role;

commit;
