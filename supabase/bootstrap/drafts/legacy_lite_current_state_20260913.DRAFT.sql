-- VIDA OS™ — Legacy Lite current-state bootstrap DRAFT
-- STATUS: NON-EXECUTABLE / NOT CLEAN-INSTALL-VALIDATED / DO NOT RUN IN PRODUCTION.
--
-- Purpose: materialize, from read-only production catalog evidence, the four
-- legacy/untracked Lite objects that predate or are not created by the tracked
-- production migration ledger. This is only one component of a future full
-- direct-current-state bootstrap and is intentionally kept under drafts/.

begin;

create table public.users_profile (
  id uuid primary key references auth.users(id) on delete cascade,
  nome_completo text,
  telefone_whatsapp text not null default '',
  data_nascimento date,
  profissao text,
  estado_civil text,
  numero_dependentes integer default 0,
  possui_empresa boolean default false,
  possui_imoveis boolean default false,
  faixa_patrimonio text,
  origin_lead text,
  lgpd_aceito boolean not null default false,
  termos_aceito boolean not null default false,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  onboarding_concluido boolean default false,
  email text
);
create unique index users_profile_email_idx on public.users_profile(email);
alter table public.users_profile enable row level security;

create table public.prontuario_patrimonial (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete restrict,
  secao text check (secao = any (array['patrimonio'::text,'documentos'::text,'familia'::text,'empresas'::text,'agenda'::text,'diagnosticos'::text])),
  campo text,
  valor text,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  dados jsonb,
  unique (user_id)
);
alter table public.prontuario_patrimonial enable row level security;

create table public.diagnosticos (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete restrict,
  scanner_nome text,
  perfil_identificado text,
  scores jsonb,
  narrativa text,
  mecanismo_dominante text,
  capital_decisorio jsonb,
  raw_json jsonb,
  created_at timestamptz default now()
);
create index diagnosticos_user_id_idx on public.diagnosticos(user_id);
alter table public.diagnosticos enable row level security;

create table public.diagnosticos_vida (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete restrict,
  instrumento text not null,
  external_id text not null,
  status text not null default 'processando',
  score numeric,
  perfil text,
  link_relatorio text,
  processado_em timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (instrumento, external_id)
);
create index diagnosticos_vida_user_id_idx on public.diagnosticos_vida(user_id);
alter table public.diagnosticos_vida enable row level security;

-- Deny default API access first; rebuild the effective production ACL surface.
revoke all privileges on table public.users_profile from public,anon,authenticated,service_role;
revoke all privileges on table public.prontuario_patrimonial from public,anon,authenticated,service_role;
revoke all privileges on table public.diagnosticos from public,anon,authenticated,service_role;
revoke all privileges on table public.diagnosticos_vida from public,anon,authenticated,service_role;

grant all privileges on table public.users_profile to service_role;
grant all privileges on table public.prontuario_patrimonial to service_role;
grant all privileges on table public.diagnosticos to service_role;
grant all privileges on table public.diagnosticos_vida to service_role;

grant select,insert,delete on table public.users_profile to authenticated;
grant update (
  nome_completo,telefone_whatsapp,data_nascimento,profissao,estado_civil,
  numero_dependentes,possui_empresa,possui_imoveis,faixa_patrimonio,origin_lead,
  lgpd_aceito,termos_aceito,updated_at,onboarding_concluido
) on table public.users_profile to authenticated;
grant select,insert,update,delete on table public.prontuario_patrimonial to authenticated;
grant select,insert,update,delete on table public.diagnosticos to authenticated;
grant select on table public.diagnosticos_vida to authenticated;

create policy "usuario ve proprio perfil"
on public.users_profile for select to authenticated
using ((select auth.uid()) = id);
create policy "usuario cria proprio perfil"
on public.users_profile for insert to authenticated
with check ((select auth.uid()) = id);
create policy "usuario edita proprio perfil"
on public.users_profile for update to authenticated
using ((select auth.uid()) = id)
with check ((select auth.uid()) = id);
create policy "usuario deleta proprio perfil"
on public.users_profile for delete to authenticated
using ((select auth.uid()) = id);

create policy "usuario ve proprio prontuario"
on public.prontuario_patrimonial for select to authenticated
using ((select auth.uid()) = user_id);
create policy "usuario insere no proprio prontuario"
on public.prontuario_patrimonial for insert to authenticated
with check ((select auth.uid()) = user_id);
create policy "usuario edita proprio prontuario"
on public.prontuario_patrimonial for update to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);
create policy "usuario deleta do proprio prontuario"
on public.prontuario_patrimonial for delete to authenticated
using ((select auth.uid()) = user_id);

create policy "usuario ve proprios diagnosticos"
on public.diagnosticos for select to authenticated
using ((select auth.uid()) = user_id);
create policy "usuario insere proprio diagnostico"
on public.diagnosticos for insert to authenticated
with check ((select auth.uid()) = user_id);
create policy "usuario edita proprio diagnostico"
on public.diagnosticos for update to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);
create policy "usuario deleta proprio diagnostico"
on public.diagnosticos for delete to authenticated
using ((select auth.uid()) = user_id);

create policy "usuario ve seus proprios diagnosticos"
on public.diagnosticos_vida for select to authenticated
using ((select auth.uid()) = user_id);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path to ''
as $function$
begin
  new.updated_at = now();
  return new;
end;
$function$;
revoke all on function public.set_updated_at() from public,anon,authenticated,service_role;
grant execute on function public.set_updated_at() to service_role;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path to ''
as $function$
begin
  insert into public.users_profile (id,email,lgpd_aceito,termos_aceito,onboarding_concluido)
  values (new.id,new.email,false,false,false)
  on conflict (id) do update set email=excluded.email;
  return new;
end;
$function$;
revoke all on function public.handle_new_user() from public,anon,authenticated,service_role;
grant execute on function public.handle_new_user() to service_role;

create or replace function public.sync_user_profile_email()
returns trigger
language plpgsql
security definer
set search_path to ''
as $function$
begin
  update public.users_profile
     set email = new.email,
         updated_at = now()
   where id = new.id
     and email is distinct from new.email;
  return new;
end;
$function$;
revoke all on function public.sync_user_profile_email() from public,anon,authenticated,service_role;
grant execute on function public.sync_user_profile_email() to service_role;

create trigger set_updated_at_users_profile
before update on public.users_profile
for each row execute function public.set_updated_at();

create trigger set_updated_at_prontuario
before update on public.prontuario_patrimonial
for each row execute function public.set_updated_at();

create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

create trigger sync_user_profile_email_after_auth_update
after update of email on auth.users
for each row
when (old.email is distinct from new.email)
execute function public.sync_user_profile_email();

commit;
