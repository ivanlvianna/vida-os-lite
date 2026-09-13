insert into public.users_profile (id, lgpd_aceito, termos_aceito, onboarding_concluido)
select u.id, false, false, false
from auth.users u
left join public.users_profile p on p.id = u.id
where p.id is null
on conflict (id) do nothing;

revoke all on table public.users_profile from anon;
revoke all on table public.prontuario_patrimonial from anon;
revoke all on table public.diagnosticos from anon;

revoke all on table public.users_profile from authenticated;
revoke all on table public.prontuario_patrimonial from authenticated;
revoke all on table public.diagnosticos from authenticated;

grant select, insert, update, delete on table public.users_profile to authenticated;
grant select, insert, update, delete on table public.prontuario_patrimonial to authenticated;
grant select, insert, update, delete on table public.diagnosticos to authenticated;

drop policy if exists "usuario ve proprio perfil" on public.users_profile;
drop policy if exists "usuario cria proprio perfil" on public.users_profile;
drop policy if exists "usuario edita proprio perfil" on public.users_profile;
drop policy if exists "usuario deleta proprio perfil" on public.users_profile;

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

drop policy if exists "usuario ve proprio prontuario" on public.prontuario_patrimonial;
drop policy if exists "usuario insere no proprio prontuario" on public.prontuario_patrimonial;
drop policy if exists "usuario edita proprio prontuario" on public.prontuario_patrimonial;
drop policy if exists "usuario deleta do proprio prontuario" on public.prontuario_patrimonial;

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

drop policy if exists "usuario ve proprios diagnosticos" on public.diagnosticos;
drop policy if exists "usuario insere proprio diagnostico" on public.diagnosticos;
drop policy if exists "usuario edita proprio diagnostico" on public.diagnosticos;
drop policy if exists "usuario deleta proprio diagnostico" on public.diagnosticos;

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

create index if not exists diagnosticos_user_id_idx
on public.diagnosticos (user_id);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.users_profile (id, lgpd_aceito, termos_aceito, onboarding_concluido)
  values (new.id, false, false, false)
  on conflict (id) do nothing;
  return new;
end;
$$;

revoke execute on function public.handle_new_user() from public, anon, authenticated;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

revoke execute on function public.set_updated_at() from public, anon, authenticated;
