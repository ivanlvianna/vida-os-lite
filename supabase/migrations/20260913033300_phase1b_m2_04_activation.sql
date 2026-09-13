-- VIDA OS™ — Gate 002 / M2.04
-- Source: rehearsal migration gate002_v3_m2_chunk4_activation

begin;
create table public.client_activation_seeds (
  id uuid primary key default gen_random_uuid(),
  vri_correlation_id text not null check (btrim(vri_correlation_id) <> ''),
  vri_activation_correlation_id text not null check (btrim(vri_activation_correlation_id) <> ''),
  client_account_id uuid not null references public.client_accounts(id),
  planning_engagement_id uuid not null,
  identity_resolution text not null check (identity_resolution in ('match_confident', 'no_match')),
  economic_entity_id uuid not null references public.economic_entities(id),
  existing_economic_entity_id uuid references public.economic_entities(id),
  entity_type text check (entity_type is null or entity_type in ('person', 'organization')),
  display_name text check (display_name is null or btrim(display_name) <> ''),
  planner_auth_user_id uuid not null,
  created_at timestamptz not null default now(),
  constraint chk_identity_resolution_fields check ((identity_resolution='no_match' and entity_type is not null and display_name is not null and existing_economic_entity_id is null) or (identity_resolution='match_confident' and existing_economic_entity_id is not null and entity_type is null and display_name is null and economic_entity_id=existing_economic_entity_id)),
  constraint uq_client_activation_seeds_account unique (client_account_id),
  foreign key (client_account_id,planning_engagement_id) references public.planning_engagements(client_account_id,id) on delete restrict
);
create unique index client_activation_seeds_vri_correlation_id_uq on public.client_activation_seeds(vri_correlation_id);
create unique index client_activation_seeds_activation_correlation_uq on public.client_activation_seeds(vri_activation_correlation_id);
create trigger client_activation_seeds_forbid_update before update on public.client_activation_seeds for each row execute function vida_internal.forbid_update_delete();
create trigger client_activation_seeds_forbid_delete before delete on public.client_activation_seeds for each row execute function vida_internal.forbid_update_delete();
create function public.activate_client_from_vri(p_planner_auth_user_id uuid,p_vri_correlation_id text,p_vri_activation_correlation_id text,p_identity_resolution text,p_existing_economic_entity_id uuid default null,p_entity_type text default null,p_display_name text default null)
returns table(client_account_id uuid,economic_entity_id uuid,planning_engagement_id uuid)
language plpgsql security definer set search_path='' as $$
declare v_client_account_id uuid;v_economic_entity_id uuid;v_planning_engagement_id uuid;v_seed_vri_correlation_id text;v_seed_activation_id text;v_seed_account_id uuid;v_seed_entity_id uuid;v_seed_engagement_id uuid;v_seed_identity_res text;v_seed_existing_entity_id uuid;v_seed_entity_type text;v_seed_display_name text;v_seed_planner_id uuid;
begin
 if auth.uid() is not null then raise exception 'activate_client_from_vri é função de provisionamento backend — não deve ser chamada em sessão interativa (auth.uid() = %)',auth.uid();end if;
 if p_vri_correlation_id is null or btrim(p_vri_correlation_id)='' then raise exception 'p_vri_correlation_id é obrigatório e não pode ser vazio nesta função';end if;
 if p_vri_activation_correlation_id is null or btrim(p_vri_activation_correlation_id)='' then raise exception 'p_vri_activation_correlation_id é obrigatório e não pode ser vazio nesta função';end if;
 if p_planner_auth_user_id is null then raise exception 'p_planner_auth_user_id é obrigatório';end if;
 if p_identity_resolution is null then raise exception 'p_identity_resolution é obrigatório';end if;
 if p_identity_resolution='ambiguous_match' then raise exception 'identity_resolution = ambiguous_match não pode ativar automaticamente — requer revisão humana';end if;
 if p_identity_resolution not in ('match_confident','no_match') then raise exception 'p_identity_resolution inválido: %',p_identity_resolution;end if;
 if p_identity_resolution='no_match' then if p_entity_type is null or p_entity_type not in ('person','organization') then raise exception 'p_entity_type inválido para identity_resolution = no_match';end if;if p_display_name is null or btrim(p_display_name)='' then raise exception 'p_display_name é obrigatório quando identity_resolution = no_match';end if;if p_existing_economic_entity_id is not null then raise exception 'p_existing_economic_entity_id deve ser NULL quando identity_resolution = no_match';end if;else if p_existing_economic_entity_id is null then raise exception 'p_existing_economic_entity_id é obrigatório quando identity_resolution = match_confident';end if;if p_entity_type is not null or p_display_name is not null then raise exception 'p_entity_type e p_display_name devem ser NULL quando identity_resolution = match_confident';end if;end if;
 perform pg_advisory_xact_lock(hashtextextended(p_vri_activation_correlation_id,0));
 select s.vri_correlation_id,s.client_account_id,s.economic_entity_id,s.planning_engagement_id,s.identity_resolution,s.existing_economic_entity_id,s.entity_type,s.display_name,s.planner_auth_user_id into v_seed_vri_correlation_id,v_seed_account_id,v_seed_entity_id,v_seed_engagement_id,v_seed_identity_res,v_seed_existing_entity_id,v_seed_entity_type,v_seed_display_name,v_seed_planner_id from public.client_activation_seeds s where s.vri_activation_correlation_id=p_vri_activation_correlation_id;
 if found then if v_seed_vri_correlation_id is distinct from p_vri_correlation_id or v_seed_planner_id is distinct from p_planner_auth_user_id or v_seed_identity_res is distinct from p_identity_resolution or v_seed_existing_entity_id is distinct from p_existing_economic_entity_id or v_seed_entity_type is distinct from p_entity_type or v_seed_display_name is distinct from btrim(p_display_name) then raise exception 'vri_activation_correlation_id % já foi processado com parâmetros diferentes',p_vri_activation_correlation_id;end if;return query select v_seed_account_id,v_seed_entity_id,v_seed_engagement_id;return;end if;
 v_client_account_id:=vida_internal.bootstrap_client_account(p_planner_auth_user_id,p_vri_correlation_id);perform 1 from public.client_accounts where id=v_client_account_id for update;
 select s.vri_activation_correlation_id,s.economic_entity_id,s.planning_engagement_id into v_seed_activation_id,v_seed_entity_id,v_seed_engagement_id from public.client_activation_seeds s where s.client_account_id=v_client_account_id;
 if found then raise exception 'client_account % já foi ativada por outra ativação inicial (token %)',v_client_account_id,v_seed_activation_id;end if;
 if p_identity_resolution='no_match' then v_economic_entity_id:=vida_internal.create_economic_entity_internal(v_client_account_id,p_entity_type,p_display_name);else v_economic_entity_id:=p_existing_economic_entity_id;insert into public.client_account_entities(client_account_id,economic_entity_id) values(v_client_account_id,v_economic_entity_id) on conflict on constraint client_account_entities_pkey do nothing;end if;
 v_planning_engagement_id:=public.create_planning_engagement(p_client_account_id=>v_client_account_id,p_vri_activation_correlation_id=>p_vri_activation_correlation_id);
 insert into public.planning_engagement_entities(client_account_id,planning_engagement_id,economic_entity_id) values(v_client_account_id,v_planning_engagement_id,v_economic_entity_id);
 insert into public.client_activation_seeds(vri_correlation_id,vri_activation_correlation_id,client_account_id,planning_engagement_id,identity_resolution,economic_entity_id,existing_economic_entity_id,entity_type,display_name,planner_auth_user_id) values(p_vri_correlation_id,p_vri_activation_correlation_id,v_client_account_id,v_planning_engagement_id,p_identity_resolution,v_economic_entity_id,p_existing_economic_entity_id,p_entity_type,btrim(p_display_name),p_planner_auth_user_id);
 return query select v_client_account_id,v_economic_entity_id,v_planning_engagement_id;
end;$$;
revoke all on function public.activate_client_from_vri(uuid,text,text,text,uuid,text,text) from public,anon,authenticated,service_role;
revoke all on table public.client_account_vri_links,public.client_account_user_authorizations,public.planning_engagements,public.planning_engagement_vri_links,public.planning_engagement_entities,public.planning_engagement_transitions,public.client_activation_seeds from public,anon,authenticated,service_role;
commit;
