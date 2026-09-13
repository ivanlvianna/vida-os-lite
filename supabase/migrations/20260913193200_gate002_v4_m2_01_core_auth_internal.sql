-- VIDA OS™ — Gate 002 v4 / M2.01
-- Core authorization/internal layer, qualified against production ownership semantics.

begin;
grant vida_identity_owner to postgres with inherit true, set true;
grant create on schema public to vida_identity_owner;
grant usage,create on schema vida_internal to vida_identity_owner;

do $preflight$
declare
  v_missing text[] := array[]::text[];
  v_existing text[] := array[]::text[];
  v_name text;
begin
  foreach v_name in array array['economic_entities','client_accounts','client_account_entities','client_account_users'] loop
    if to_regclass(format('public.%I', v_name)) is null then v_missing := array_append(v_missing, v_name); end if;
  end loop;
  foreach v_name in array array['client_account_vri_links','client_account_user_authorizations','planning_engagements','planning_engagement_vri_links','planning_engagement_entities','planning_engagement_transitions','client_activation_seeds'] loop
    if to_regclass(format('public.%I', v_name)) is not null then v_existing := array_append(v_existing, v_name); end if;
  end loop;
  if cardinality(v_missing) > 0 then raise exception 'M2 ABORTADA: objetos Phase 1A esperados ausentes: %', array_to_string(v_missing, ', '); end if;
  if cardinality(v_existing) > 0 then raise exception 'M2 ABORTADA: objetos Phase 1B já existem: %', array_to_string(v_existing, ', '); end if;
  if exists (select 1 from pg_constraint where conname='client_account_users_auth_user_id_fkey' and conrelid='public.client_account_users'::regclass) then raise exception 'M2 ABORTADA: client_account_users_auth_user_id_fkey já existe'; end if;
  if to_regclass('public.idx_client_account_entities_economic_entity_id') is null then raise exception 'M2 ABORTADA: índice Phase 1A idx_client_account_entities_economic_entity_id ausente'; end if;
  if to_regclass('public.idx_client_account_users_auth_user_id') is null then raise exception 'M2 ABORTADA: índice Phase 1A idx_client_account_users_auth_user_id ausente'; end if;
end;
$preflight$;

create schema if not exists vida_internal;
revoke all on schema vida_internal from public, anon, authenticated, service_role;
grant usage,create on schema vida_internal to vida_identity_owner;

create function vida_internal.forbid_update_delete()
returns trigger language plpgsql set search_path='' as $$ begin raise exception 'Esta tabela é append-only: % não é permitido em %', TG_OP, TG_TABLE_NAME; return null; end; $$;
revoke all on function vida_internal.forbid_update_delete() from public, anon, authenticated, service_role;

create function vida_internal.auth_user_display_label(p_auth_user_id uuid)
returns text language sql security definer stable set search_path='' as $$ select coalesce(email,id::text) from auth.users where id=p_auth_user_id; $$;
revoke all on function vida_internal.auth_user_display_label(uuid) from public, anon, authenticated, service_role;
grant execute on function vida_internal.auth_user_display_label(uuid) to vida_identity_owner;

create function vida_internal.guard_economic_entity_immutable_fields()
returns trigger language plpgsql set search_path='' as $$ begin if new.id is distinct from old.id or new.entity_type is distinct from old.entity_type or new.created_at is distinct from old.created_at then raise exception 'Apenas display_name pode ser atualizado em economic_entities'; end if; return new; end; $$;
revoke all on function vida_internal.guard_economic_entity_immutable_fields() from public, anon, authenticated, service_role;
create trigger economic_entities_guard_immutable_fields before update on public.economic_entities for each row execute function vida_internal.guard_economic_entity_immutable_fields();

alter table public.client_account_users add constraint client_account_users_auth_user_id_fkey foreign key(auth_user_id) references auth.users(id) on delete cascade;

create table public.client_account_vri_links (
 client_account_id uuid primary key references public.client_accounts(id) on delete cascade,
 vri_correlation_id text not null check (btrim(vri_correlation_id)<>''),
 bootstrap_planner_auth_user_id uuid not null,
 created_at timestamptz not null default now()
);
create unique index client_account_vri_links_vri_correlation_id_uq on public.client_account_vri_links(vri_correlation_id);

create table public.client_account_user_authorizations (
 id uuid primary key default gen_random_uuid(),
 client_account_id uuid not null references public.client_accounts(id) on delete restrict,
 auth_user_id uuid references auth.users(id) on delete set null,
 auth_user_label text not null,
 role text not null check(role in ('planner_owner','internal_staff','client_primary','client_participant','external_advisor')),
 scope_type text not null check(scope_type in ('account','engagement','entity')),
 planning_engagement_id uuid,
 economic_entity_id uuid,
 granted_by uuid references auth.users(id) on delete set null,
 granted_by_label text not null,
 granted_at timestamptz not null default now(),
 revoked_at timestamptz,
 revoked_by uuid references auth.users(id) on delete set null,
 revoked_by_label text,
 constraint chk_scope_columns_match check ((scope_type='account' and planning_engagement_id is null and economic_entity_id is null) or (scope_type='engagement' and planning_engagement_id is not null and economic_entity_id is null) or (scope_type='entity' and economic_entity_id is not null and planning_engagement_id is null)),
 constraint chk_active_requires_auth_user check(revoked_at is not null or auth_user_id is not null),
 constraint chk_revoked_at_after_granted_at check(revoked_at is null or revoked_at>=granted_at),
 constraint chk_revoked_by_label_when_revoked check(revoked_at is null or revoked_by_label is not null),
 foreign key(client_account_id,economic_entity_id) references public.client_account_entities(client_account_id,economic_entity_id)
);
create unique index client_account_user_authorizations_active_scope_uq on public.client_account_user_authorizations(client_account_id,auth_user_id,scope_type,coalesce(planning_engagement_id,'00000000-0000-0000-0000-000000000000'),coalesce(economic_entity_id,'00000000-0000-0000-0000-000000000000')) where revoked_at is null;
create index client_account_user_authorizations_auth_user_id_idx on public.client_account_user_authorizations(auth_user_id) where revoked_at is null;

create function vida_internal.guard_authorization_immutable_after_grant()
returns trigger language plpgsql security definer set search_path='' as $$
declare v_expected_auth_user_id uuid; v_expected_granted_by uuid;
begin
 if new.auth_user_id is null and old.auth_user_id is not null and old.revoked_at is null then
  perform 1 from public.client_accounts where id=old.client_account_id for update;
  if old.role='planner_owner' and old.scope_type='account' and not exists(select 1 from public.client_account_user_authorizations where client_account_id=old.client_account_id and role='planner_owner' and scope_type='account' and revoked_at is null and id<>old.id) then raise exception 'não é possível excluir o login do último planner_owner account-scope da conta % — transfira a titularidade antes de excluir este auth.users',old.client_account_id; end if;
  new.revoked_at:=now(); new.revoked_by:=null; new.revoked_by_label:='sistema (login removido)';
 end if;
 if new.id is distinct from old.id or new.client_account_id is distinct from old.client_account_id or new.role is distinct from old.role or new.scope_type is distinct from old.scope_type or new.planning_engagement_id is distinct from old.planning_engagement_id or new.economic_entity_id is distinct from old.economic_entity_id or new.granted_at is distinct from old.granted_at or new.auth_user_label is distinct from old.auth_user_label or new.granted_by_label is distinct from old.granted_by_label then raise exception 'campos estruturais e rótulos de snapshot são imutáveis em client_account_user_authorizations'; end if;
 v_expected_auth_user_id:=old.auth_user_id;
 if old.auth_user_id is not null and new.auth_user_id is null then v_expected_auth_user_id:=null; elsif new.auth_user_id is distinct from old.auth_user_id then raise exception 'auth_user_id só pode transicionar de um valor para NULL'; end if;
 if new.auth_user_id is distinct from v_expected_auth_user_id then raise exception 'mudança não permitida em auth_user_id'; end if;
 v_expected_granted_by:=old.granted_by;
 if old.granted_by is not null and new.granted_by is null then v_expected_granted_by:=null; elsif new.granted_by is distinct from old.granted_by then raise exception 'granted_by só pode transicionar de um valor para NULL'; end if;
 if new.granted_by is distinct from v_expected_granted_by then raise exception 'mudança não permitida em granted_by'; end if;
 if old.revoked_at is null then
  if new.revoked_at is null and (new.revoked_by is distinct from old.revoked_by or new.revoked_by_label is distinct from old.revoked_by_label) then raise exception 'revoked_by/revoked_by_label não podem mudar sem revoked_at ser definido'; end if;
 else
  if new.revoked_at is distinct from old.revoked_at then raise exception 'revoked_at é imutável depois de definido'; end if;
  if new.revoked_by_label is distinct from old.revoked_by_label then raise exception 'revoked_by_label é imutável depois de definido'; end if;
  if old.revoked_by is not null and new.revoked_by is null then null; elsif new.revoked_by is distinct from old.revoked_by then raise exception 'revoked_by só pode transicionar de um valor para NULL, depois de já revogada'; end if;
 end if;
 return new;
end; $$;
revoke all on function vida_internal.guard_authorization_immutable_after_grant() from public, anon, authenticated, service_role;
create trigger client_account_user_authorizations_guard_immutable before update on public.client_account_user_authorizations for each row execute function vida_internal.guard_authorization_immutable_after_grant();
create trigger client_account_user_authorizations_forbid_delete before delete on public.client_account_user_authorizations for each row execute function vida_internal.forbid_update_delete();

create function vida_internal.client_account_users_before_delete_guard()
returns trigger language plpgsql security definer set search_path='' as $$
begin
 perform 1 from public.client_accounts where id=old.client_account_id for update;
 if exists(select 1 from public.client_account_user_authorizations where client_account_id=old.client_account_id and auth_user_id=old.auth_user_id and role='planner_owner' and scope_type='account' and revoked_at is null) and not exists(select 1 from public.client_account_user_authorizations where client_account_id=old.client_account_id and role='planner_owner' and scope_type='account' and revoked_at is null and auth_user_id<>old.auth_user_id) then raise exception 'não é possível remover o membership do último planner_owner account-scope da conta %',old.client_account_id; end if;
 if public.vida_auth_user_exists(old.auth_user_id) then update public.client_account_user_authorizations set revoked_at=clock_timestamp(),revoked_by=null,revoked_by_label='sistema (membership removido)' where client_account_id=old.client_account_id and auth_user_id=old.auth_user_id and revoked_at is null; end if;
 return old;
end; $$;
revoke all on function vida_internal.client_account_users_before_delete_guard() from public, anon, authenticated, service_role;
create trigger client_account_users_before_delete before delete on public.client_account_users for each row execute function vida_internal.client_account_users_before_delete_guard();

create function vida_internal.is_account_member(p_client_account_id uuid) returns boolean language sql security definer stable set search_path='' as $$ select exists(select 1 from public.client_account_users cau where cau.client_account_id=p_client_account_id and cau.auth_user_id=vida_internal.current_auth_uid()); $$;
revoke all on function vida_internal.is_account_member(uuid) from public, anon, authenticated, service_role;
create function vida_internal.has_role_in_scope(p_client_account_id uuid,p_roles text[],p_planning_engagement_id uuid default null,p_economic_entity_id uuid default null) returns boolean language sql security definer stable set search_path='' as $$ select exists(select 1 from public.client_account_user_authorizations a where a.client_account_id=p_client_account_id and a.auth_user_id=vida_internal.current_auth_uid() and a.revoked_at is null and a.role=any(p_roles) and (a.scope_type='account' or (a.scope_type='engagement' and a.planning_engagement_id=p_planning_engagement_id) or (a.scope_type='entity' and a.economic_entity_id=p_economic_entity_id)) and exists(select 1 from public.client_account_users cu where cu.client_account_id=a.client_account_id and cu.auth_user_id=a.auth_user_id)); $$;
revoke all on function vida_internal.has_role_in_scope(uuid,text[],uuid,uuid) from public, anon, authenticated, service_role;
create function vida_internal.is_staff(p_client_account_id uuid) returns boolean language sql security definer stable set search_path='' as $$ select vida_internal.has_role_in_scope(p_client_account_id,array['planner_owner','internal_staff']); $$;
revoke all on function vida_internal.is_staff(uuid) from public, anon, authenticated, service_role;
create function vida_internal.matched_staff_role(p_client_account_id uuid) returns text language sql security definer stable set search_path='' as $$ select a.role from public.client_account_user_authorizations a where a.client_account_id=p_client_account_id and a.auth_user_id=vida_internal.current_auth_uid() and a.revoked_at is null and a.role in ('planner_owner','internal_staff') and a.scope_type='account' and exists(select 1 from public.client_account_users cu where cu.client_account_id=a.client_account_id and cu.auth_user_id=a.auth_user_id) order by (a.role='planner_owner') desc limit 1; $$;
revoke all on function vida_internal.matched_staff_role(uuid) from public, anon, authenticated, service_role;
create function vida_internal.has_entity_specific_role(p_client_account_id uuid,p_roles text[],p_economic_entity_id uuid) returns boolean language sql security definer stable set search_path='' as $$ select exists(select 1 from public.client_account_user_authorizations a where a.client_account_id=p_client_account_id and a.auth_user_id=vida_internal.current_auth_uid() and a.revoked_at is null and a.role=any(p_roles) and a.scope_type='entity' and a.economic_entity_id=p_economic_entity_id and exists(select 1 from public.client_account_users cu where cu.client_account_id=a.client_account_id and cu.auth_user_id=a.auth_user_id)); $$;
revoke all on function vida_internal.has_entity_specific_role(uuid,text[],uuid) from public, anon, authenticated, service_role;
create function vida_internal.has_engagement_specific_role(p_client_account_id uuid,p_roles text[],p_planning_engagement_id uuid) returns boolean language sql security definer stable set search_path='' as $$ select exists(select 1 from public.client_account_user_authorizations a where a.client_account_id=p_client_account_id and a.auth_user_id=vida_internal.current_auth_uid() and a.revoked_at is null and a.role=any(p_roles) and a.scope_type='engagement' and a.planning_engagement_id=p_planning_engagement_id and exists(select 1 from public.client_account_users cu where cu.client_account_id=a.client_account_id and cu.auth_user_id=a.auth_user_id)); $$;
revoke all on function vida_internal.has_engagement_specific_role(uuid,text[],uuid) from public, anon, authenticated, service_role;

alter table public.client_account_vri_links owner to vida_identity_owner;
alter table public.client_account_user_authorizations owner to vida_identity_owner;
alter function vida_internal.forbid_update_delete() owner to vida_identity_owner;
alter function vida_internal.guard_economic_entity_immutable_fields() owner to vida_identity_owner;
alter function vida_internal.guard_authorization_immutable_after_grant() owner to vida_identity_owner;
alter function vida_internal.client_account_users_before_delete_guard() owner to vida_identity_owner;
alter function vida_internal.is_account_member(uuid) owner to vida_identity_owner;
alter function vida_internal.has_role_in_scope(uuid,text[],uuid,uuid) owner to vida_identity_owner;
alter function vida_internal.is_staff(uuid) owner to vida_identity_owner;
alter function vida_internal.matched_staff_role(uuid) owner to vida_identity_owner;
alter function vida_internal.has_entity_specific_role(uuid,text[],uuid) owner to vida_identity_owner;
alter function vida_internal.has_engagement_specific_role(uuid,text[],uuid) owner to vida_identity_owner;

revoke create on schema public from vida_identity_owner;
revoke create on schema vida_internal from vida_identity_owner;
grant vida_identity_owner to postgres with inherit false, set true;
commit;
