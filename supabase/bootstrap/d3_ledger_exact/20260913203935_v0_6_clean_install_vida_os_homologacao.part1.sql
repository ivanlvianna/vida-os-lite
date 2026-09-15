-- ============================================================================
-- VIDA OSâ„¢ â€” Migration ExecutÃ¡vel Consolidada
-- migration-executable-consolidated-v0.6.sql
-- SHA-256: 89b3930de12fde6f050388b05ec4eff81d8da626ac79a2ad0a30893d467c90ef
-- Aplicada como clean install no ambiente de homologaÃ§Ã£o dedicado
-- (ADR-0001-D3), criado em 13/09/2026.
-- ============================================================================

begin;

create or replace function forbid_update_delete()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  raise exception 'Esta tabela Ã© append-only: % nÃ£o Ã© permitido em %',
    TG_OP, TG_TABLE_NAME;
  return null;
end;
$$;
revoke all on function forbid_update_delete from public, anon, authenticated, service_role;

create or replace function auth_user_display_label(p_auth_user_id uuid)
returns text
language sql
security definer
stable
set search_path = ''
as $$
  select coalesce(email, id::text) from auth.users where id = p_auth_user_id;
$$;
revoke all on function auth_user_display_label from public, anon, authenticated, service_role;

create table economic_entities (
  id            uuid primary key default gen_random_uuid(),
  entity_type   text not null
                  check (entity_type in ('person', 'organization')),
  display_name  text not null
                  check (btrim(display_name) <> ''),
  created_at    timestamptz not null default now()
);

alter table economic_entities enable row level security;

comment on table economic_entities is
  'Sujeito econÃ´mico canÃ´nico. ApÃ³s criado, sÃ³ display_name Ã© mutÃ¡vel.';

create or replace function guard_economic_entity_immutable_fields()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.id is distinct from old.id
     or new.entity_type is distinct from old.entity_type
     or new.created_at is distinct from old.created_at
  then
    raise exception 'Apenas display_name pode ser atualizado em economic_entities';
  end if;
  return new;
end;
$$;
revoke all on function guard_economic_entity_immutable_fields from public, anon, authenticated, service_role;

create trigger economic_entities_guard_immutable_fields
  before update on economic_entities
  for each row execute function guard_economic_entity_immutable_fields();

create table client_accounts (
  id          uuid primary key default gen_random_uuid(),
  created_at  timestamptz not null default now()
);

alter table client_accounts enable row level security;

comment on table client_accounts is
  'Conta comercial. CriaÃ§Ã£o exclusiva via bootstrap_client_account().';

create table client_account_vri_links (
  client_account_id             uuid primary key references client_accounts(id) on delete cascade,
  vri_correlation_id            text not null
                                   check (btrim(vri_correlation_id) <> ''),
  bootstrap_planner_auth_user_id  uuid not null,
  created_at                     timestamptz not null default now()
);

alter table client_account_vri_links enable row level security;

create unique index client_account_vri_links_vri_correlation_id_uq
  on client_account_vri_links (vri_correlation_id);

comment on table client_account_vri_links is
  'Token opaco de correlaÃ§Ã£o com o VRI. Escrita exclusiva de bootstrap_client_account().';

create table client_account_entities (
  client_account_id   uuid not null references client_accounts(id) on delete restrict,
  economic_entity_id  uuid not null references economic_entities(id) on delete restrict,
  created_at          timestamptz not null default now(),

  primary key (client_account_id, economic_entity_id)
);

alter table client_account_entities enable row level security;

comment on table client_account_entities is
  'AssociaÃ§Ã£o pura, nÃ­vel de CONTA. Se cria ou remove â€” nunca "atualiza".';

create table client_account_users (
  client_account_id  uuid not null references client_accounts(id) on delete cascade,
  auth_user_id       uuid not null references auth.users(id) on delete cascade,
  created_at         timestamptz not null default now(),

  primary key (client_account_id, auth_user_id)
);

alter table client_account_users enable row level security;

comment on table client_account_users is
  'Membership entre UserIdentity e ClientAccount.';

create or replace function client_account_users_before_delete_guard()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform 1 from public.client_accounts where id = old.client_account_id for update;

  if exists (
    select 1 from public.client_account_user_authorizations
    where client_account_id = old.client_account_id
      and auth_user_id = old.auth_user_id
      and role = 'planner_owner'
      and scope_type = 'account'
      and revoked_at is null
  ) then
    if not exists (
      select 1 from public.client_account_user_authorizations
      where client_account_id = old.client_account_id
        and role = 'planner_owner'
        and scope_type = 'account'
        and revoked_at is null
        and auth_user_id <> old.auth_user_id
    ) then
      raise exception
        'nÃ£o Ã© possÃ­vel remover o membership do Ãºltimo planner_owner account-scope da conta %',
        old.client_account_id;
    end if;
  end if;

  if exists (select 1 from auth.users where id = old.auth_user_id) then
    update public.client_account_user_authorizations
    set revoked_at = clock_timestamp(),
        revoked_by = null,
        revoked_by_label = 'sistema (membership removido)'
    where client_account_id = old.client_account_id
      and auth_user_id = old.auth_user_id
      and revoked_at is null;
  end if;

  return old;
end;
$$;
revoke all on function client_account_users_before_delete_guard from public, anon, authenticated, service_role;

create trigger client_account_users_before_delete
  before delete on client_account_users
  for each row execute function client_account_users_before_delete_guard();

create table client_account_user_authorizations (
  id                      uuid primary key default gen_random_uuid(),

  client_account_id       uuid not null references client_accounts(id) on delete restrict,

  auth_user_id            uuid references auth.users(id) on delete set null,
  auth_user_label         text not null,

  role                    text not null
                            check (role in (
                              'planner_owner',
                              'internal_staff',
                              'client_primary',
                              'client_participant',
                              'external_advisor'
                            )),

  scope_type              text not null
                            check (scope_type in ('account', 'engagement', 'entity')),

  planning_engagement_id  uuid,
  economic_entity_id      uuid,

  granted_by              uuid references auth.users(id) on delete set null,
  granted_by_label        text not null,
  granted_at              timestamptz not null default now(),

  revoked_at              timestamptz,
  revoked_by              uuid references auth.users(id) on delete set null,
  revoked_by_label        text,

  constraint chk_scope_columns_match check (
    (scope_type = 'account'    and planning_engagement_id is null     and economic_entity_id is null) or
    (scope_type = 'engagement' and planning_engagement_id is not null and economic_entity_id is null) or
    (scope_type = 'entity'     and economic_entity_id is not null     and planning_engagement_id is null)
  ),

  constraint chk_active_requires_auth_user check (
    revoked_at is not null or auth_user_id is not null
  ),

  constraint chk_revoked_at_after_granted_at check (
    revoked_at is null or revoked_at >= granted_at
  ),
  constraint chk_revoked_by_label_when_revoked check (
    revoked_at is null or revoked_by_label is not null
  ),

  foreign key (client_account_id, economic_entity_id)
    references client_account_entities (client_account_id, economic_entity_id)
);

alter table client_account_user_authorizations enable row level security;

create unique index client_account_user_authorizations_active_scope_uq
  on client_account_user_authorizations (
    client_account_id,
    auth_user_id,
    scope_type,
    coalesce(planning_engagement_id, '00000000-0000-0000-0000-000000000000'),
    coalesce(economic_entity_id, '00000000-0000-0000-0000-000000000000')
  )
  where revoked_at is null;

comment on table client_account_user_authorizations is
  'RBAC/ABAC fÃ­sico.';

create or replace function guard_authorization_immutable_after_grant()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_expected_auth_user_id  uuid;
  v_expected_granted_by    uuid;
begin
  if new.auth_user_id is null and old.auth_user_id is not null and old.revoked_at is null then
    perform 1 from public.client_accounts where id = old.client_account_id for update;

    if old.role = 'planner_owner' and old.scope_type = 'account' then
      if not exists (
        select 1 from public.client_account_user_authorizations
        where client_account_id = old.client_account_id
          and role = 'planner_owner'
          and scope_type = 'account'
          and revoked_at is null
          and id <> old.id
      ) then
        raise exception
          'nÃ£o Ã© possÃ­vel excluir o login do Ãºltimo planner_owner account-scope da conta % â€” '
          'transfira a titularidade antes de excluir este auth.users',
          old.client_account_id;
      end if;
    end if;

    new.revoked_at := now();
    new.revoked_by := null;
    new.revoked_by_label := 'sistema (login removido)';
  end if;

  if new.id is distinct from old.id
     or new.client_account_id is distinct from old.client_account_id
     or new.role is distinct from old.role
     or new.scope_type is distinct from old.scope_type
     or new.planning_engagement_id is distinct from old.planning_engagement_id
     or new.economic_entity_id is distinct from old.economic_entity_id
     or new.granted_at is distinct from old.granted_at
     or new.auth_user_label is distinct from old.auth_user_label
     or new.granted_by_label is distinct from old.granted_by_label
  then
    raise exception
      'id, client_account_id, role, scope_type, planning_engagement_id, '
      'economic_entity_id, granted_at e os rÃ³tulos de snapshot sÃ£o '
      'imutÃ¡veis em client_account_user_authorizations';
  end if;

  v_expected_auth_user_id := old.auth_user_id;
  if old.auth_user_id is not null and new.auth_user_id is null then
    v_expected_auth_user_id := null;
  elsif new.auth_user_id is distinct from old.auth_user_id then
    raise exception 'auth_user_id sÃ³ pode transicionar de um valor para NULL';
  end if;
  if new.auth_user_id is distinct from v_expected_auth_user_id then
    raise exception 'mudanÃ§a nÃ£o permitida em auth_user_id';
  end if;

  v_expected_granted_by := old.granted_by;
  if old.granted_by is not null and new.granted_by is null then
    v_expected_granted_by := null;
  elsif new.granted_by is distinct from old.granted_by then
    raise exception 'granted_by sÃ³ pode transicionar de um valor para NULL';
  end if;
  if new.granted_by is distinct from v_expected_granted_by then
    raise exception 'mudanÃ§a nÃ£o permitida em granted_by';
  end if;

  if old.revoked_at is null then
    if new.revoked_at is null then
      if new.revoked_by is distinct from old.revoked_by
         or new.revoked_by_label is distinct from old.revoked_by_label
      then
        raise exception 'revoked_by/revoked_by_label nÃ£o podem mudar sem revoked_at ser definido';
      end if;
    end if;
  else
    if new.revoked_at is distinct from old.revoked_at then
      raise exception 'revoked_at Ã© imutÃ¡vel depois de definido';
    end if;
    if new.revoked_by_label is distinct from old.revoked_by_label then
      raise exception 'revoked_by_label Ã© imutÃ¡vel depois de definido';
    end if;
    if old.revoked_by is not null and new.revoked_by is null then
      null;
    elsif new.revoked_by is distinct from old.revoked_by then
      raise exception 'revoked_by sÃ³ pode transicionar de um valor para NULL, depois de jÃ¡ revogada';
    end if;
  end if;

  return new;
end;
$$;
revoke all on function guard_authorization_immutable_after_grant from public, anon, authenticated, service_role;

create trigger client_account_user_authorizations_guard_immutable
  before update on client_account_user_authorizations
  for each row execute function guard_authorization_immutable_after_grant();

create trigger client_account_user_authorizations_forbid_delete
  before delete on client_account_user_authorizations
  for each row execute function forbid_update_delete();

create or replace function is_account_member(p_client_account_id uuid)
returns boolean
language sql
security definer
stable
set search_path = ''
as $$
  select exists (
    select 1
    from public.client_account_users cau
    where cau.client_account_id = p_client_account_id
      and cau.auth_user_id = auth.uid()
  );
$$;
revoke all on function is_account_member from public, anon, authenticated, service_role;
grant execute on function is_account_member to authenticated;

create or replace function has_role_in_scope(
  p_client_account_id       uuid,
  p_roles                   text[],
  p_planning_engagement_id  uuid default null,
  p_economic_entity_id      uuid default null
)
returns boolean
language sql
security definer
stable
set search_path = ''
as $$
  select exists (
    select 1
    from public.client_account_user_authorizations a
    where a.client_account_id = p_client_account_id
      and a.auth_user_id = auth.uid()
      and a.revoked_at is null
      and a.role = any(p_roles)
      and (
        a.scope_type = 'account'
        or (a.scope_type = 'engagement' and a.planning_engagement_id = p_planning_engagement_id)
        or (a.scope_type = 'entity'     and a.economic_entity_id = p_economic_entity_id)
      )
      and exists (
        select 1 from public.client_account_users cu
        where cu.client_account_id = a.client_account_id
          and cu.auth_user_id = a.auth_user_id
      )
  );
$$;
revoke all on function has_role_in_scope from public, anon, authenticated, service_role;
grant execute on function has_role_in_scope to authenticated;

create or replace function is_staff(p_client_account_id uuid)
returns boolean
language sql
security definer
stable
set search_path = ''
as $$
  select public.has_role_in_scope(p_client_account_id, array['planner_owner', 'internal_staff']);
$$;
revoke all on function is_staff from public, anon, authenticated, service_role;
grant execute on function is_staff to authenticated;

create or replace function matched_staff_role(p_client_account_id uuid)
returns text
language sql
security definer
stable
set search_path = ''
as $$
  select a.role
  from public.client_account_user_authorizations a
  where a.client_account_id = p_client_account_id
    and a.auth_user_id = auth.uid()
    and a.revoked_at is null
    and a.role in ('planner_owner', 'internal_staff')
    and a.scope_type = 'account'
    and exists (
      select 1 from public.client_account_users cu
     where cu.client_account_id = a.client_account_id
        and cu.auth_user_id = a.auth_user_id
    )
  order by (a.role = 'planner_owner') desc
  limit 1;
$$;
revoke all on function matched_staff_role from public, anon, authenticated, service_role;

create or replace function has_entity_specific_role(
  p_client_account_id   uuid,
  p_roles               text[],
  p_economic_entity_id  uuid
)
returns boolean
language sql
security definer
stable
set search_path = ''
as $$
  select exists (
    select 1
    from public.client_account_user_authorizations a
    where a.client_account_id = p_client_account_id
      and a.auth_user_id = auth.uid()
      and a.revoked_at is null
      and a.role = any(p_roles)
      and a.scope_type = 'entity'
      and a.economic_entity_id = p_economic_entity_id
      and exists (
        select 1 from public.client_account_users cu
        where cu.client_account_id = a.client_account_id
          and cu.auth_user_id = a.auth_user_id
    )
  );
$$;
revoke all on function has_entity_specific_role from public, anon, authenticated, service_role;
grant execute on function has_entity_specific_role to authenticated;

create or replace function has_engagement_specific_role(
  p_client_account_id       uuid,
  p_roles                   text[],
  p_planning_engagement_id  uuid
)
returns boolean
language sql
security definer
stable
set search_path = ''
as $$
  select exists (
    select 1
    from public.client_account_user_authorizations a
    where a.client_account_id = p_client_account_id
      and a.auth_user_id = auth.uid()
      and a.revoked_at is null
      and a.role = any(p_roles)
      and a.scope_type = 'engagement'
      and a.planning_engagement_id = p_planning_engagement_id
      and exists (
        select 1 from public.client_account_users cu
        where cu.client_account_id = a.client_account_id
          and cu.auth_user_id = a.auth_user_id
    )
  );
$$;
revoke all on function has_engagement_specific_role from public, anon, authenticated, service_role;
grant execute on function has_engagement_specific_role to authenticated;

comment on function auth_user_display_label is 'RÃ³tulo legÃ­vel de um login.';
comment on function has_role_in_scope is 'RBAC/ABAC com fallback de conta.';
comment on function has_entity_specific_role is 'Papel client-side especÃ­fico de entidade.';
comment on function has_engagement_specific_role is 'Papel client-side especÃ­fico de engagement.';comment on function matched_staff_role is 'Papel de staff ACCOUNT-SCOPE.';

create table planning_engagements (
  id                              uuid primary key default gen_random_uuid(),

  client_account_id              uuid not null references client_accounts(id),

  state                           text not null default 'onboarding_em_andamento'
    check (state in (
      'onboarding_em_andamento',
      'dados_incompletos',
      'dados_completos',
      'diagnostico_em_elaboracao',
      'diagnostico_validado',
      'plano_em_elaboracao',
      'plano_aprovado',
      'implementacao',
      'acompanhamento',
      'revisao',
      'documentos_pendentes',
      'pausado',
      'encerrado_concluido',
      'encerrado_cancelado',
      'abandonado'
    )),

  state_before_pause              text
    check (state_before_pause is null or state_before_pause in (
      'onboarding_em_andamento', 'dados_incompletos', 'dados_completos',
      'diagnostico_em_elaboracao', 'diagnostico_validado', 'plano_em_elaboracao',
      'plano_aprovado', 'implementacao', 'acompanhamento', 'revisao',
      'documentos_pendentes'
    )),

  predecessor_engagement_id      uuid references planning_engagements(id),

  opened_at                      timestamptz not null default now(),
  closed_at                      timestamptz,

  created_at                     timestamptz not null default now(),

  constraint chk_closed_at_matches_state check (
    (state in ('encerrado_concluido', 'encerrado_cancelado', 'abandonado') and closed_at is not null)
    or
    (state not in ('encerrado_concluido', 'encerrado_cancelado', 'abandonado') and closed_at is null)
  ),

  constraint chk_state_before_pause_matches check (
    (state = 'pausado' and state_before_pause is not null)
    or
    (state <> 'pausado' and state_before_pause is null)
  ),

  constraint chk_predecessor_not_self check (
    predecessor_engagement_id is null or predecessor_engagement_id <> id
  ),

  constraint uq_planning_engagements_account_id unique (client_account_id, id)
);

alter table planning_engagements enable row level security;

comment on table planning_engagements is
  'Ciclo de Planejamento VIDAâ„¢.';

alter table client_account_user_authorizations
  add constraint client_account_user_authorizations_engagement_fkey
  foreign key (client_account_id, planning_engagement_id)
  references planning_engagements (client_account_id, id);

create table planning_engagement_vri_links (
  client_account_id              uuid not null,
  planning_engagement_id         uuid primary key references planning_engagements(id),
  vri_activation_correlation_id  text not null
                                  check (btrim(vri_activation_correlation_id) <> ''),
  created_at                     timestamptz not null default now(),

  foreign key (client_account_id, planning_engagement_id)
    references planning_engagements (client_account_id, id)
);

alter table planning_engagement_vri_links enable row level security;

create unique index planning_engagement_vri_links_correlation_id_uq
  on planning_engagement_vri_links (vri_activation_correlation_id);

comment on table planning_engagement_vri_links is
  'Token opaco de correlaÃ§Ã£o com o VRI.';

create or replace function guard_planning_engagement_state_change()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.id is distinct from old.id
     or new.client_account_id is distinct from old.client_account_id
      or new.predecessor_engagement_id is distinct from old.predecessor_engagement_id
     or new.opened_at is distinct from old.opened_at
     or new.created_at is distinct from old.created_at
  then
    raise exception
      'id, client_account_id, predecessor_engagement_id, opened_at e created_at '
      'sÃ£o imutÃ¡veis apÃ³s a criaÃ§Ã£o do engagement';
  end if;

  if (new.state is distinct from old.state
      or new.closed_at is distinct from old.closed_at
      or new.state_before_pause is distinct from old.state_before_pause)
     and coalesce(current_setting('vida_os.allow_engagement_state_change', true), '') <> 'on'
  then
    raise exception
      'state, closed_at eİ]WØ™Y›Ü™WÜ]\ÙHğìÈ]Y[HšXH™XÛÜ™Ü[›š[™×Ù[™ØYÙ[Y[İ˜[œÚ][ÛŠ
IÎÂˆ[™YÂ‚ˆ™]\›ˆ™]ÎÂ™[™Â‰	Âœ™]›ÚÙH[Ûˆ[˜İ[ÛˆİX\™Ü[›š[™×Ù[™ØYÙ[Y[Üİ]WØÚ[™ÙHœ›ÛHX›XË[›Û‹]][XØ]YÙ\šXÙWÜ›ÛNÂ‚˜Ü™X]HšYÙÙ\ˆ[›š[™×Ù[™ØYÙ[Y[×ÙİX\™Üİ]WØÚ[™ÙBˆ™Y›Ü™H\]HÛˆ[›š[™×Ù[™ØYÙ[Y[Âˆ›ÜˆXXÚ›İÈ^Xİ]H[˜İ[ÛˆİX\™Ü[›š[™×Ù[™ØYÙ[Y[Üİ]WØÚ[™ÙJ
NÂ‚˜Ü™X]HÜˆ™\XÙH[˜İ[Ûˆ˜[Y]WÜ[›š[™×Ù[™ØYÙ[Y[Ü™YXÙ\ÜÛÜŠ
Bœ™]\›œÈšYÙÙ\‚›[™İXYÙHÜÜ[œÙ]ÙX\˜ÚÜ]H	ÉÂ˜\È		™XÛ\™Bˆ—Ü™YXÙ\ÜÛÜ—ØXØÛİ[ÚY]ZYÂˆ—Ü™YXÙ\ÜÛÜ—Üİ]H^Â˜™YÚ[‚ˆYˆ™]Ëœ™YXÙ\ÜÛÜ—Ù[™ØYÙ[Y[ÚY\È›İ[[‚ˆÙ[XİÛY[ØXØÛİ[ÚYİ]Bˆ[È—Ü™YXÙ\ÜÛÜ—ØXØÛİ[ÚY—Ü™YXÙ\ÜÛÜ—Üİ]Bˆœ›ÛHX›XËœ[›š[™×Ù[™ØYÙ[Y[ÂˆÚ\™HYH™]Ëœ™YXÙ\ÜÛÜ—Ù[™ØYÙ[Y[ÚYÂ‚ˆYˆ—Ü™YXÙ\ÜÛÜ—ØXØÛİ[ÚY\È[[‚ˆ˜Z\ÙH^Ù\[Ûˆ	Ü™YXÙ\ÜÛÜ—Ù[™ØYÙ[Y[ÚY	H°èÛÈ[˜ÛÛ˜YÉË™]Ëœ™YXÙ\ÜÛÜ—Ù[™ØYÙ[Y[ÚYÂˆ[™YÂ‚ˆYˆ—Ü™YXÙ\ÜÛÜ—ØXØÛİ[ÚYˆ™]Ë˜ÛY[ØXØÛİ[ÚY[‚ˆ˜Z\ÙH^Ù\[Û‚ˆ	Ü™YXÙ\ÜÛÜ—Ù[™ØYÙ[Y[ÚY]™H\[˜Ù\ˆ0èY\ÛXHÛY[ØXØÛİ[
[˜ÛÛ˜YÈ	H\Ü\˜YÈ	JIËˆ—Ü™YXÙ\ÜÛÜ—ØXØÛİ[ÚY™]Ë˜ÛY[ØXØÛİ[ÚYÂˆ[™YÂ‚ˆYˆ—Ü™YXÙ\ÜÛÜ—Üİ]H›İ[ˆ
	Ù[˜Ù\œ˜Y×ØÛÛ˜ÛZYÉË	Ù[˜Ù\œ˜Y×ØØ[˜Ù[YÉË	ØX˜[™Û˜YÉÊH[‚ˆ˜Z\ÙH^Ù\[Û‚ˆ	Ü™YXÙ\ÜÛÜ—Ù[™ØYÙ[Y[ÚY	H°èÛÈ\İ0èH[H\İYÈ\›Z[˜[
\İYÈ]X[ˆ	JIËˆ™]Ëœ™YXÙ\ÜÛÜ—Ù[™ØYÙ[Y[ÚY—Ü™YXÙ\ÜÛÜ—Üİ]NÂˆ[™YÂˆ[™YÂˆ™]\›ˆ™]ÎÂ™[™Â‰	Âœ™]›ÚÙH[Ûˆ[˜İ[Ûˆ˜[Y]WÜ[›š[™×Ù[™ØYÙ[Y[Ü™YXÙ\ÜÛÜˆœ›ÛHX›XË[›Û‹]][XØ]YÙ\šXÙWÜ›ÛNÂ‚˜Ü™X]HšYÙÙ\ˆ[›š[™×Ù[™ØYÙ[Y[×İ˜[Y]WÜ™YXÙ\ÜÛÜ‚ˆ™Y›Ü™H[œÙ\Üˆ\]HÛˆ[›š[™×Ù[™ØYÙ[Y[Âˆ›ÜˆXXÚ›İÈ^Xİ]H[˜İ[Ûˆ˜[Y]WÜ[›š[™×Ù[™ØYÙ[Y[Ü™YXÙ\ÜÛÜŠ
NÂ‚˜Ü™X]HX›H[›š[™×Ù[™ØYÙ[Y[Ù[]Y\È
ˆÛY[ØXØÛİ[ÚY]ZY›İ[ˆ[›š[™×Ù[™ØYÙ[Y[ÚY]ZY›İ[ˆXÛÛ›ÛZX×Ù[]WÚY]ZY›İ[ˆÜ™X]YØ][Y\İ[\ˆ›İ[Y˜][›İÊ
K‚ˆš[X\HÙ^H
[›š[™×Ù[™ØYÙ[Y[ÚYXÛÛ›ÛZX×Ù[]WÚY
K‚ˆ›Ü™ZYÛˆÙ^H
ÛY[ØXØÛİ[ÚY[›š[™×Ù[™ØYÙ[Y[ÚY
Bˆ™Y™\™[˜Ù\È[›š[™×Ù[™ØYÙ[Y[È
ÛY[ØXØÛİ[ÚYY
HÛˆ[]H™\İšXİ‚ˆ›Ü™ZYÛˆÙ^H
ÛY[ØXØÛİ[ÚYXÛÛ›ÛZX×Ù[]WÚY
Bˆ™Y™\™[˜Ù\ÈÛY[ØXØÛİ[Ù[]Y\È
ÛY[ØXØÛİ[ÚYXÛÛ›ÛZX×Ù[]WÚY
HÛˆ[]H™\İšXİŠNÂ‚˜[\ˆX›H[›š[™×Ù[™ØYÙ[Y[Ù[]Y\È[˜X›H›İÈ]™[ÙXİ\š]NÂ‚˜Ü™X]H[™^[›š[™×Ù[™ØYÙ[Y[Ù[]Y\×ÙXÛÛ›ÛZX×Ù[]WÚYÚYˆÛˆ[›š[™×Ù[™ØYÙ[Y[Ù[]Y\È
XÛÛ›ÛZX×Ù[]WÚY
NÂ‚˜ÛÛ[Y[ÛˆX›H[›š[™×Ù[™ØYÙ[Y[Ù[]Y\È\Âˆ	Ô]XZ\ÈXÛÛ›ÛZXÑ[]H\XÚ\[HH[H[›š[™×Ù[™ØYÙ[Y[\ÜXğëYšXÛË‰ÎÂ‚˜Ü™X]HX›H[›š[™×Ù[™ØYÙ[Y[İ˜[œÚ][ÛœÈ
ˆY]ZYš[X\HÙ^HY˜][Ù[—Ü˜[™ÛWİ]ZY

K‚ˆ[›š[™×Ù[™ØYÙ[Y[ÚY]ZY›İ[™Y™\™[˜Ù\È[›š[™×Ù[™ØYÙ[Y[ÊY
K‚ˆœ›ÛWÜİ]H^ˆÚXÚÈ
œ›ÛWÜİ]H\È[Üˆœ›ÛWÜİ]H[ˆ
ˆ	ÛÛ˜›Ø\™[™×Ù[WØ[™[Y[ÉË	ÙYÜ×Ú[˜ÛÛ\]ÜÉË	ÙYÜ×ØÛÛ\]ÜÉËˆ	ÙXYÛ›ÜİXÛ×Ù[WÙ[X›Ü˜XØ[ÉË	ÙXYÛ›ÜİXÛ×İ˜[YYÉË	Ü[›×Ù[WÙ[X›Ü˜XØ[ÉËˆ	Ü[›×Ø\›İ˜YÉË	Ú[\[Y[XØ[ÉË	ØXÛÛ\[š[Y[ÉË	Ü™]š\Ø[ÉËˆ	ÙØİ[Y[Ü×Ü[™[\ÉË	Ü]\ØYÉËˆ	Ù[˜Ù\œ˜Y×ØÛÛ˜ÛZYÉË	Ù[˜Ù\œ˜Y×ØØ[˜Ù[YÉË	ØX˜[™Û˜YÉÂˆ
JKˆ×Üİ]H^›İ[ˆÚXÚÈ
×Üİ]H[ˆ
ˆ	ÛÛ˜›Ø\™[™×Ù[WØ[™[Y[ÉË	ÙYÜ×Ú[˜ÛÛ\]ÜÉË	ÙYÜ×ØÛÛ\]ÜÉËˆ	ÙXYÛ›ÜİXÛ×Ù[WÙ[X›Ü˜XØ[ÉË	ÙXYÛ›ÜİXÛ×İ˜[YYÉË	Ü[›×Ù[WÙ[X›Ü˜XØ[ÉËˆ	Ü[›×Ø\›İ˜YÉË	Ú[\[Y[XØ[ÉË	ØXÛÛ\[š[Y[ÉË	Ü™]š\Ø[ÉËˆ	ÙØİ[Y[Ü×Ü[™[\ÉË	Ü]\ØYÉËˆ	Ù[˜Ù\œ˜Y×ØÛÛ˜ÛZYÉË	Ù[˜Ù\œ˜Y×ØØ[˜Ù[YÉË	ØX˜[™Û˜YÉÂˆ
JK‚ˆ]™[^›İ[ˆ™\]Z\™YÙØİ[Y[^‚ˆXİÜ—Ø]]İ\Ù\—ÚY]ZY™Y™\™[˜Ù\È]]\Ù\œÊY
HÛˆ[]HÙ][ˆXİÜ—ÛX™[^›İ[ˆ^Xİ]Ü—Ü›ÛH^›İ[ˆÚXÚÈ
^Xİ]Ü—Ü›ÛH[ˆ
	Ü[›™\—ÛİÛ™\‰Ë	Ú[\›˜[ÜİY™‰Ë	ÜŞ\İ[IÊJK‚ˆ™X\ÛÛˆ^ˆÜšYÚ[ˆ^›İ[ˆÚXÚÈ
ÜšYÚ[ˆ[ˆ
	ÜŞ\İ[IË	Ü[›™\‰Ë	ØÛY[	Ë	Ù^\›˜[	ÊJKˆ]]ÛX]X×ÙY™™Xİ^‚ˆØØİ\œ™YØ][Y\İ[\ˆ›İ[Y˜][›İÊ
K‚ˆÛÛœİ˜Z[Ú×Ü™X\ÛÛ—Ü™\]Z\™YÙ›Ü—İ\›Z[˜[Üİ]\ÈÚXÚÈ
ˆ×Üİ]H›İ[ˆ
	Ù[˜Ù\œ˜Y×ØÛÛ˜ÛZYÉË	Ù[˜Ù\œ˜Y×ØØ[˜Ù[YÉË	ØX˜[™Û˜YÉÊBˆÜˆ
™X\ÛÛˆ\È›İ[[™š[J™X\ÛÛŠHˆ	ÉÊBˆ
BŠNÂ‚˜[\ˆX›H[›š[™×Ù[™ØYÙ[Y[İ˜[œÚ][ÛœÈ[˜X›H›İÈ]™[ÙXİ\š]NÂ‚˜Ü™X]HÜˆ™\XÙH[˜İ[ÛˆİX\™Ü[›š[™×Ù[™ØYÙ[Y[İ˜[œÚ][Û—Ú[[]]X›J
Bœ™]\›œÈšYÙÙ\‚›[™İXYÙHÜÜ[œÙ]ÙX\˜ÚÜ]H	ÉÂ˜\È		˜™YÚ[‚ˆYˆ™]Ë˜XİÜ—Ø]]İ\Ù\—ÚY\È\İ[˜İœ›ÛHÛ˜XİÜ—Ø]]İ\Ù\—ÚY[‚ˆYˆ›İ
Û˜XİÜ—Ø]]İ\Ù\—ÚY\È›İ[[™™]Ë˜XİÜ—Ø]]İ\Ù\—ÚY\È[
H[‚ˆ˜Z\ÙH^Ù\[Ûˆ	ØXİÜ—Ø]]İ\Ù\—ÚYğìÈÙH˜[œÚXÚ[Û˜\ˆH[H˜[Üˆ\˜H•S	ÎÂˆ[™YÂˆ[™YÂ‚ˆYˆ™]ËšY\È\İ[˜İœ›ÛHÛšYˆÜˆ™]Ëœ[›š[™×Ù[™ØYÙ[Y[ÚY\È\İ[˜İœ›ÛHÛœ[›š[™×Ù[™ØYÙ[Y[ÚYˆÜˆ™]Ë™œ›ÛWÜİ]H\È\İ[˜İœ›ÛHÛ™œ›ÛWÜİ]BˆÜˆ™]Ë×Üİ]H\È\İ[˜İœ›ÛHÛ×Üİ]BˆÜˆ™]Ë™]™[\È\İ[˜İœ›ÛHÛ™]™[ˆÜˆ™]Ëœ™\]Z\™YÙØİ[Y[\È\İ[˜İœ›ÛHÛœ™\]Z\™YÙØİ[Y[ˆÜˆ™]Ë˜XİÜ—ÛX™[\È\İ[˜İœ›ÛHÛ˜XİÜ—ÛX™[ˆÜˆ™]Ë™^Xİ]Ü—Ü›ÛH\È\İ[˜İœ›ÛHÛ™^Xİ]Ü—Ü›ÛBˆÜˆ™]Ëœ™X\ÛÛˆ\È\İ[˜İœ›ÛHÛœ™X\ÛÛ‚ˆÜˆ™]Ë›ÜšYÚ[ˆ\È\İ[˜İœ›ÛHÛ›ÜšYÚ[‚ˆÜˆ™]Ë˜]]ÛX]X×ÙY™™Xİ\È\İ[˜İœ›ÛHÛ˜]]ÛX]X×ÙY™™XİˆÜˆ™]Ë›ØØİ\œ™YØ]\È\İ[˜İœ›ÛHÛ›ØØİ\œ™YØ]ˆ[‚ˆ˜Z\ÙH^Ù\[Û‚ˆ	Ü[›š[™×Ù[™ØYÙ[Y[İ˜[œÚ][ÛœÈ0êH[]]0è]™[8 %\[˜\ÈXİÜ—Ø]]İ\Ù\—ÚY	Âˆ	ÜÙH˜[œÚXÚ[Û˜\ˆH[H˜[Üˆ\˜H•S
^Û\ğèÛÈÈÙÚ[ˆÈ]ÜŠIÎÂˆ[™YÂ‚ˆ™]\›ˆ™]ÎÂ™[™Â‰	Âœ™]›ÚÙH[Ûˆ[˜İ[ÛˆİX\™Ü[›š[™×Ù[™ØYÙ[Y[İ˜[œÚ][Û—Ú[[]]X›Hœ›ÛHX›XË[›Û‹]][XØ]YÙ\šXÙWÜ›ÛNÂ‚˜Ü™X]HšYÙÙ\ˆ[›š[™×Ù[™ØYÙ[Y[İ˜[œÚ][Ûœ×ÙİX\™Ú[[]]X›Bˆ™Y›Ü™H\]HÛˆ[›š[™×Ù[™ØYÙ[Y[İ˜[œÚ][ÛœÂˆ›ÜˆXXÚ›İÈ^Xİ]H[˜İ[ÛˆİX\™Ü[›š[™×Ù[™ØYÙ[Y[İ˜[œÚ][Û—Ú[[]]X›J
NÂ‚˜Ü™X]HšYÙÙ\ˆ[›š[™×Ù[™ØYÙ[Y[İ˜[œÚ][Ûœ×Ù›Ü˜šYÙ[]Bˆ™Y›Ü™H[]HÛˆ[›š[™×Ù[™ØYÙ[Y[İ˜[œÚ][ÛœÂˆ›ÜˆXXÚ›İÈ^Xİ]H[˜İ[Ûˆ›Ü˜šYİ\]WÙ[]J
NÂ‚˜ÛÛ[Y[ÛˆX›H[›š[™×Ù[™ØYÙ[Y[İ˜[œÚ][ÛœÈ\Âˆ	Ò\İ0ìÜšXÛÈ]]Üš]]]›Ë\İÜšXØ[Y[H[]]0è]™[‰ÎÂ‚˜Ü™X]H[™^ÛY[ØXØÛİ[Ù[]Y\×ÙXÛÛ›ÛZX×Ù[]WÚYÚYˆÛˆÛY[ØXØÛİ[Ù[]Y\È
XÛÛ›ÛZX×Ù[]WÚY
NÂ‚˜Ü™X]H[™^ÛY[ØXØÛİ[İ\Ù\œ×Ø]]İ\Ù\—ÚYÚYˆÛˆÛY[ØXØÛİ[İ\Ù\œÈ
]]İ\Ù\—ÚY
NÂ‚˜Ü™X]H[™^ÛY[ØXØÛİ[İ\Ù\—Ø]]Üš^˜][Ûœ×Ø]]İ\Ù\—ÚYÚYˆÛˆÛY[ØXØÛİ[İ\Ù\—Ø]]Üš^˜][ÛœÈ
]]İ\Ù\—ÚY
BˆÚ\™H™]›ÚÙYØ]\È[Â‚˜Ü™X]H[™^[›š[™×Ù[™ØYÙ[Y[×ØÛY[ØXØÛİ[ÚYÚYˆÛˆ[›š[™×Ù[™ØYÙ[Y[È
ÛY[ØXØÛİ[ÚY
NÂ‚˜Ü™X]H[™^[›š[™×Ù[™ØYÙ[Y[İ˜[œÚ][Ûœ×Ù[™ØYÙ[Y[ÚYÚYˆÛˆ[›š[™×Ù[™ØYÙ[Y[İ˜[œÚ][ÛœÈ
[›š[™×Ù[™ØYÙ[Y[ÚYØØİ\œ™YØ]
NÂ‚˜Ü™X]HÜˆ™\XÙH[˜İ[Ûˆ\×İ˜[YÜ[›š[™×Ù[™ØYÙ[Y[İ˜[œÚ][ÛŠˆÙœ›ÛWÜİ]H^ˆİ×Üİ]H^ŠBœ™]\›œÈ›ÛÛX[‚›[™İXYÙHÜ[š[[]]X›BœÙ]ÙX\˜ÚÜ]H	ÉÂ˜\È		ˆÙ[Xİˆ
Ùœ›ÛWÜİ]H\È[[™İ×Üİ]HH	ÛÛ˜›Ø\™[™×Ù[WØ[™[Y[ÉÊBˆÜˆ
Ùœ›ÛWÜİ]Kİ×Üİ]JH[ˆ
ˆ
	ÛÛ˜›Ø\™[™×Ù[WØ[™[Y[ÉË	ÙYÜ×Ú[˜ÛÛ\]ÜÉÊKˆ
	ÛÛ˜›Ø\™[™×Ù[WØ[™[Y[ÉË	ÙYÜ×ØÛÛ\]ÜÉÊKˆ
	ÛÛ˜›Ø\™[™×Ù[WØ[™[Y[ÉË	ÙØİ[Y[Ü×Ü[™[\ÉÊKˆ
	ÙØİ[Y[Ü×Ü[™[\ÉË	ÙYÜ×Ú[˜ÛÛ\]ÜÉÊKˆ
	ÙØİ[Y[Ü×Ü[™[\ÉË	ÙYÜ×ØÛÛ\]ÜÉÊKˆ
	ÙYÜ×Ú[˜ÛÛ\]ÜÉË	ÙYÜ×ØÛÛ\]ÜÉÊKˆ
	ÙYÜ×Ú[˜ÛÛ\]ÜÉË	ÙØİ[Y[Ü×Ü[™[\ÉÊKˆ
	ÙYÜ×ØÛÛ\]ÜÉË	ÙXYÛ›ÜİXÛ×Ù[WÙ[X›Ü˜XØ[ÉÊKˆ
	ÙXYÛ›ÜİXÛ×Ù[WÙ[X›Ü˜XØ[ÉË	ÙXYÛ›ÜİXÛ×İ˜[YYÉÊKˆ
	ÙXYÛ›ÜİXÛ×İ˜[YYÉË	Ü[›×Ù[WÙ[X›Ü˜XØ[ÉÊKˆ
	Ü[›×Ù[WÙ[X›Ü˜XØ[ÉË	Ü[›×Ø\›İ˜YÉÊKˆ
	Ü[›×Ø\›İ˜YÉË	Ú[\[Y[XØ[ÉÊKˆ
	Ú[\[Y[XØ[ÉË	ØXÛÛ\[š[Y[ÉÊKˆ
	ÙXYÛ›ÜİXÛ×İ˜[YYÉË	Ù[˜Ù\œ˜Y×ØÛÛ˜ÛZYÉÊKˆ
	Ü[›×Ø\›İ˜YÉË	Ù[˜Ù\œ˜Y×ØÛÛ˜ÛZYÉÊKˆ
	Ú[\[Y[XØ[ÉË	Ù[˜Ù\œ˜Y×ØÛÛ˜ÛZYÉÊKˆ
	ØXÛÛ\[š[Y[ÉË	Ü™]š\Ø[ÉÊKˆ
	ØXÛÛ\[š[Y[ÉË	ÙYÜ×Ú[˜ÛÛ\]ÜÉÊKˆ
	ØXÛÛ\[š[Y[ÉË	ÙXYÛ›ÜİXÛ×Ù[WÙ[X›Ü˜XØ[ÉÊKˆ
	ØXÛÛ\[š[Y[ÉË	Ü[›×Ù[WÙ[X›Ü˜XØ[ÉÊKˆ
	ØXÛÛ\[š[Y[ÉË	Ù[˜Ù\œ˜Y×ØÛÛ˜ÛZYÉÊKˆ
	Ü™]š\Ø[ÉË	ØXÛÛ\[š[Y[ÉÊKˆ
	Ü™]š\Ø[ÉË	ÙYÜ×Ú[˜ÛÛ\]ÜÉÊKˆ
	Ü™]š\Ø[ÉË	ÙXYÛ›ÜİXÛ×Ù[WÙ[X›Ü˜XØ[ÉÊKˆ
	Ü™]š\Ø[ÉË	Ü[›×Ù[WÙ[X›Ü˜XØ[ÉÊKˆ
	Ü™]š\Ø[ÉË	Ù[˜Ù\œ˜Y×ØÛÛ˜ÛZYÉÊBˆ
BˆÜˆ
ˆİ×Üİ]HH	Ü]\ØYÉÂˆ[™Ùœ›ÛWÜİ]H›İ[ˆ
	Ù[˜Ù\œ˜Y×ØÛÛ˜ÛZYÉË	Ù[˜Ù\œ˜Y×ØØ[˜Ù[YÉË	ØX˜[™Û˜YÉË	Ü]\ØYÉÊBˆ
BˆÜˆ
ˆİ×Üİ]H[ˆ
	Ù[˜Ù\œ˜Y×ØØ[˜Ù[YÉË	ØX˜[™Û˜YÉÊBˆ[™Ùœ›ÛWÜİ]H›İ[ˆ
	Ù[˜Ù\œ˜Y×ØÛÛ˜ÛZYÉË	Ù[˜Ù\œ˜Y×ØØ[˜Ù[YÉË	ØX˜[™Û˜YÉË	Ü]\ØYÉÊBˆ
NÂ‰	Âœ™]›ÚÙH[Ûˆ[˜İ[Ûˆ\×İ˜[YÜ[›š[™×Ù[™ØYÙ[Y[İ˜[œÚ][Ûˆœ›ÛHX›XË[›Û‹]][XØ]YÙ\šXÙWÜ›ÛNÂ‚˜Ü™X]HÜˆ™\XÙH[˜İ[Ûˆ™XÛÜ™Ü[›š[™×Ù[™ØYÙ[Y[İ˜[œÚ][ÛŠˆÙ[™ØYÙ[Y[ÚY]ZYˆİ×Üİ]H^ˆÙ]™[^ˆÜ™\]Z\™YÙØİ[Y[^Y˜][[ˆÜ™X\ÛÛˆ^Y˜][[ˆØ]]ÛX]X×ÙY™™Xİ^Y˜][[ˆÙ]™[ÛÜšYÚ[ˆ^Y˜][[ŠBœ™]\›œÈ]ZY›[™İXYÙHÜÜ[œÙXİ\š]HYš[™\‚œÙ]ÙX\˜ÚÜ]H	ÉÂ˜\È		™XÛ\™Bˆ—Ùœ›ÛWÜİ]H^Âˆ—Üİ]WØ™Y›Ü™WÜ]\ÙH^Âˆ—ØÛY[ØXØÛİ[ÚY]ZYÂˆ—ØXİÜ—Ø]]İ\Ù\—ÚY]ZYÂˆ—ØXİÜ—ÛX™[^Âˆ—Ù^Xİ]Ü—Ü›ÛH^Âˆ—ÛÜšYÚ[ˆ^Âˆ—Û™]×Üİ]WØ™Y›Ü™WÜ]\ÙH^Âˆ—İ˜[œÚ][Û—ÚY]ZYÂˆ—Ü™]š[İ\×Ø[İ×Üİ]WØÚ[™ÙH^Â˜™YÚ[‚ˆYˆÙ]™[ÛÜšYÚ[ˆ\È›İ[[™Ù]™[ÛÜšYÚ[ˆ›İ[ˆ
	ÜŞ\İ[IË	Ü[›™\‰Ë	ØÛY[	Ë	Ù^\›˜[	ÊH[‚ˆ˜Z\ÙH^Ù\[Ûˆ	ÜÙ]™[ÛÜšYÚ[ˆ[°è[YÎˆ	IËÙ]™[ÛÜšYÚ[Âˆ[™YÂ‚ˆÙ[XİK˜ÛY[ØXØÛİ[ÚY[È—ØÛY[ØXØÛİ[ÚYˆœ›ÛHX›XËœ[›š[™×Ù[™ØYÙ[Y[ÈBˆÚ\™HKšYHÙ[™ØYÙ[Y[ÚYˆ[™
ˆ]]ZY

H\È[ˆÜˆX›XËš\×ÜİY™ŠK˜ÛY[ØXØÛİ[ÚY
Bˆ
NÂ‚ˆYˆ›İ›İ[™[‚ˆ˜Z\ÙH^Ù\[Ûˆ	Ü[›š[™×Ù[™ØYÙ[Y[[™^\İ[HİH°èÛÈ]]Üš^˜YÉÎÂˆ[™YÂ‚ˆYˆ]]ZY

H\È›İ[[‚ˆ—ØXİÜ—Ø]]İ\Ù\—ÚYH]]ZY

NÂˆ—ØXİÜ—ÛX™[HX›XË˜]]İ\Ù\—Ù\Ü^WÛX™[
]]ZY

JNÂˆ—Ù^Xİ]Ü—Ü›ÛHHÛØ[\ØÙJX›XË›X]ÚYÜİY™—Ü›ÛJ—ØÛY[ØXØÛİ[ÚY
K	Ú[\›˜[ÜİY™‰ÊNÂˆ—ÛÜšYÚ[ˆHÛØ[\ØÙJÙ]™[ÛÜšYÚ[‹	Ü[›™\‰ÊNÂˆ[ÙBˆ—ØXİÜ—Ø]]İ\Ù\—ÚYH[Âˆ—ØXİÜ—ÛX™[H	ÜÚ\İ[XIÎÂˆ—Ù^Xİ]Ü—Ü›ÛHH	ÜŞ\İ[IÎÂˆ—ÛÜšYÚ[ˆHÛØ[\ØÙJÙ]™[ÛÜšYÚ[‹	ÜŞ\İ[IÊNÂˆ[™YÂ‚ˆÙ[Xİİ]Kİ]WØ™Y›Ü™WÜ]\ÙKÛY[ØXØÛİ[ÚYˆ[È—Ùœ›ÛWÜİ]K—Üİ]WØ™Y›Ü™WÜ]\ÙK—ØÛY[ØXØÛİ[ÚYˆœ›ÛHX›XËœ[›š[™×Ù[™ØYÙ[Y[ÂˆÚ\™HYHÙ[™ØYÙ[Y[ÚYˆ›Üˆ\]NÂ‚ˆYˆ]]ZY

H\È›İ[[™›İX›XËš\×ÜİY™Š—ØÛY[ØXØÛİ[ÚY
H[‚ˆ˜Z\ÙH^Ù\[Û‚ˆ	Ø]]Üš^˜péğèÛÈH	HÛØœ™HÈ[›š[™×Ù[™ØYÙ[Y[	H°èÛÈ0êHXZ\È°è[YIËˆ]]ZY

KÙ[™ØYÙ[Y[ÚYÂˆ[™YÂ‚ˆYˆ—Ùœ›ÛWÜİ]H[ˆ
	Ù[˜Ù\œ˜Y×ØÛÛ˜ÛZYÉË	Ù[˜Ù\œ˜Y×ØØ[˜Ù[YÉË	ØX˜[™Û˜YÉÊH[‚ˆ˜Z\ÙH^Ù\[Û‚ˆ	Ü[›š[™×Ù[™ØYÙ[Y[	H\İ0èH[H\İYÈ\›Z[˜[
	JH8 %™[š[XH˜[œÚpéğèÛÈ0êH\›Z]YIËˆÙ[™ØYÙ[Y[ÚY—Ùœ›ÛWÜİ]NÂˆ[™YÂ‚ˆYˆ—Ùœ›ÛWÜİ]HH	Ü]\ØYÉÈ[‚ˆYˆİ×Üİ]H›İ[ˆ
	Ù[˜Ù\œ˜Y×ØØ[˜Ù[YÉË	ØX˜[™Û˜YÉÊH[™İ×Üİ]Hˆ—Üİ]WØ™Y›Ü™WÜ]\ÙH[‚ˆ