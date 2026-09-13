-- VIDA OS™ — Gate 002 v4 / M0
-- Production-ownership compatibility bridge.
-- Platform/Auth adapters remain postgres-owned SECURITY DEFINER functions.

begin;

create schema if not exists vida_internal;
revoke all on schema vida_internal from public,anon,authenticated,service_role;
grant usage on schema vida_internal to vida_identity_owner;

create function vida_internal.current_auth_uid()
returns uuid
language sql
stable
security definer
set search_path=''
as $$ select auth.uid(); $$;
revoke all on function vida_internal.current_auth_uid() from public,anon,authenticated,service_role;
grant execute on function vida_internal.current_auth_uid() to vida_identity_owner;

create function vida_internal.auth_user_has_sessions(p_auth_user_id uuid)
returns boolean
language sql
volatile
security definer
set search_path=''
as $$ select exists(select 1 from auth.sessions where user_id=p_auth_user_id); $$;
revoke all on function vida_internal.auth_user_has_sessions(uuid) from public,anon,authenticated,service_role;
grant execute on function vida_internal.auth_user_has_sessions(uuid) to vida_identity_owner;

commit;
