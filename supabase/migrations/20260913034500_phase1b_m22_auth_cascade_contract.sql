-- VIDA OS™ — Gate 002 / M2.2
-- Source: rehearsal migration gate002_v3_m22_auth_cascade_contract

begin;
create or replace function vida_internal.guard_membership_canonical_mutation()
returns trigger
language plpgsql
set search_path=''
as $$
begin
  -- FK cascades (not interactive direct DML) must be allowed to reach the
  -- authorization FK/CHECK contract. This preserves AUTH-L2: deleting an
  -- auth.users row with an active authorization fails at
  -- chk_active_requires_auth_user instead of being masked by the membership guard.
  if TG_OP='DELETE' and pg_trigger_depth()>1 then
    return old;
  end if;
  if coalesce(current_setting('vida_os.allow_membership_mutation',true),'')<>'on' then
    raise exception 'client_account_users só pode mudar via workflow canônico de membership/offboarding';
  end if;
  return case when TG_OP='DELETE' then old else new end;
end;
$$;
revoke all on function vida_internal.guard_membership_canonical_mutation() from public,anon,authenticated,service_role;

create or replace function vida_internal.client_account_users_before_delete_guard()
returns trigger
language plpgsql
security definer
set search_path=''
as $$
begin
  -- During an FK cascade from a parent table, do not auto-revoke here.
  -- Let the auth_user_id FK (ON DELETE SET NULL) and
  -- chk_active_requires_auth_user enforce the non-canonical auth deletion block.
  if pg_trigger_depth()>1 then
    return old;
  end if;

  perform 1 from public.client_accounts where id=old.client_account_id for update;
  if exists(
      select 1 from public.client_account_user_authorizations
      where client_account_id=old.client_account_id
        and auth_user_id=old.auth_user_id
        and role='planner_owner'
        and scope_type='account'
        and revoked_at is null
    )
    and not exists(
      select 1 from public.client_account_user_authorizations
      where client_account_id=old.client_account_id
        and role='planner_owner'
        and scope_type='account'
        and revoked_at is null
        and auth_user_id<>old.auth_user_id
    ) then
    raise exception 'não é possível remover o membership do último planner_owner account-scope da conta %',old.client_account_id;
  end if;

  update public.client_account_user_authorizations
     set revoked_at=clock_timestamp(),
         revoked_by=auth.uid(),
         revoked_by_label=case when auth.uid() is null then 'sistema (membership removido)' else vida_internal.auth_user_display_label(auth.uid()) end
   where client_account_id=old.client_account_id
     and auth_user_id=old.auth_user_id
     and revoked_at is null;
  return old;
end;
$$;
revoke all on function vida_internal.client_account_users_before_delete_guard() from public,anon,authenticated,service_role;
commit;
