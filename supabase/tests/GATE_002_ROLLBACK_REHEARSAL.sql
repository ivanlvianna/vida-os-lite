-- VIDA OS™ — Gate 002 rehearsal rollback
-- TEST/RECOVERY ARTIFACT ONLY. NOT A FORWARD PRODUCTION MIGRATION.
-- Corrected after equivalence cycle: explicitly removes economic_entities_insert,
-- the one M3 policy that does not depend on vida_internal.

begin;

do $pre$
declare v_nonempty text[]:=array[]::text[]; r record;
begin
  for r in select * from (values
    ('client_account_vri_links'),('client_account_user_authorizations'),('planning_engagements'),('planning_engagement_vri_links'),('planning_engagement_entities'),('planning_engagement_transitions'),('client_activation_seeds'),('client_account_membership_events'),('client_account_offboarding_workflows'),('client_account_offboarding_events')
  ) v(name) loop
    if to_regclass('public.'||r.name) is not null and (xpath('/row/c/text()', query_to_xml(format('select count(*) c from public.%I',r.name),false,true,'')))[1]::text::bigint > 0 then
      v_nonempty:=array_append(v_nonempty,r.name);
    end if;
  end loop;
  if cardinality(v_nonempty)>0 then raise exception 'ROLLBACK ABORTADO: tabelas Phase 1B não vazias: %',array_to_string(v_nonempty,', '); end if;
end;$pre$;

drop function if exists public.activate_client_from_vri(uuid,text,text,text,uuid,text,text) cascade;
drop function if exists public.create_economic_entity(uuid,text,text) cascade;
drop function if exists public.create_planning_engagement(uuid,uuid,text,text,text) cascade;
drop function if exists public.grant_client_account_authorization(uuid,uuid,text,text,uuid,uuid) cascade;
drop function if exists public.revoke_client_account_authorization(uuid) cascade;
drop function if exists public.record_planning_engagement_transition(uuid,text,text,text,text,text,text) cascade;
drop function if exists public.add_client_account_membership(uuid,uuid,text) cascade;
drop function if exists public.remove_client_account_membership(uuid,uuid,text) cascade;
drop function if exists public.start_client_account_offboarding(uuid,uuid,uuid,text) cascade;
drop function if exists public.mark_client_offboarding_sessions_revoked(uuid) cascade;
drop function if exists public.mark_client_offboarding_user_deleted(uuid) cascade;
drop function if exists public.record_client_offboarding_retryable_failure(uuid,text,text) cascade;

drop table if exists public.client_account_offboarding_events cascade;
drop table if exists public.client_account_offboarding_workflows cascade;
drop table if exists public.client_account_membership_events cascade;
drop table if exists public.client_activation_seeds cascade;
drop table if exists public.planning_engagement_entities cascade;
drop table if exists public.planning_engagement_transitions cascade;
drop table if exists public.planning_engagement_vri_links cascade;
drop table if exists public.planning_engagements cascade;
drop table if exists public.client_account_user_authorizations cascade;
drop table if exists public.client_account_vri_links cascade;

-- This policy has no vida_internal dependency, so CASCADE from the schema does not remove it.
drop policy if exists economic_entities_insert on public.economic_entities;

drop schema if exists vida_internal cascade;

alter table public.client_account_users drop constraint if exists client_account_users_auth_user_id_fkey;
drop index if exists public.reconciliation_record_economic_entity_id_idx;

alter function public.canonical_reconciliation(uuid,timestamp with time zone) reset search_path;
alter function public.reconciliation_source_block_mutation() reset search_path;
alter function public.reconciliation_record_block_mutation() reset search_path;
alter function public.reconciliation_record_validate_succession() reset search_path;
alter function public.entity_relationships_enforce_owns_target() reset search_path;
alter function public.economic_entities_protect_owns_target() reset search_path;

alter table public.economic_entities disable row level security;
alter table public.client_accounts disable row level security;
alter table public.client_account_entities disable row level security;
alter table public.client_account_users disable row level security;
alter table public.entity_relationships disable row level security;
alter table public.reconciliation_source disable row level security;
alter table public.reconciliation_record disable row level security;

revoke all privileges on public.economic_entities,public.entity_relationships,public.client_accounts,public.client_account_entities,public.client_account_users,public.reconciliation_source,public.reconciliation_record from public,anon,authenticated,service_role;

commit;
