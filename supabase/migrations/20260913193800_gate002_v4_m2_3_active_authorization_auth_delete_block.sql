begin;
grant vida_identity_owner to postgres with inherit true, set true;

create or replace function vida_internal.guard_authorization_immutable_after_grant()
returns trigger
language plpgsql
security definer
set search_path=''
as $$
declare
  v_expected_auth_user_id uuid;
  v_expected_granted_by uuid;
begin
  if new.id is distinct from old.id
     or new.client_account_id is distinct from old.client_account_id
     or new.role is distinct from old.role
     or new.scope_type is distinct from old.scope_type
     or new.planning_engagement_id is distinct from old.planning_engagement_id
     or new.economic_entity_id is distinct from old.economic_entity_id
     or new.granted_at is distinct from old.granted_at
     or new.auth_user_label is distinct from old.auth_user_label
     or new.granted_by_label is distinct from old.granted_by_label then
    raise exception 'campos estruturais e rótulos de snapshot são imutáveis em client_account_user_authorizations';
  end if;

  v_expected_auth_user_id:=old.auth_user_id;
  if old.auth_user_id is not null and new.auth_user_id is null then
    v_expected_auth_user_id:=null;
  elsif new.auth_user_id is distinct from old.auth_user_id then
    raise exception 'auth_user_id só pode transicionar de um valor para NULL';
  end if;
  if new.auth_user_id is distinct from v_expected_auth_user_id then
    raise exception 'mudança não permitida em auth_user_id';
  end if;

  v_expected_granted_by:=old.granted_by;
  if old.granted_by is not null and new.granted_by is null then
    v_expected_granted_by:=null;
  elsif new.granted_by is distinct from old.granted_by then
    raise exception 'granted_by só pode transicionar de um valor para NULL';
  end if;
  if new.granted_by is distinct from v_expected_granted_by then
    raise exception 'mudança não permitida em granted_by';
  end if;

  if old.revoked_at is null then
    if new.revoked_at is null and (
      new.revoked_by is distinct from old.revoked_by
      or new.revoked_by_label is distinct from old.revoked_by_label
    ) then
      raise exception 'revoked_by/revoked_by_label não podem mudar sem revoked_at ser definido';
    end if;
  else
    if new.revoked_at is distinct from old.revoked_at then
      raise exception 'revoked_at é imutável depois de definido';
    end if;
    if new.revoked_by_label is distinct from old.revoked_by_label then
      raise exception 'revoked_by_label é imutável depois de definido';
    end if;
    if old.revoked_by is not null and new.revoked_by is null then
      null;
    elsif new.revoked_by is distinct from old.revoked_by then
      raise exception 'revoked_by só pode transicionar de um valor para NULL, depois de já revogada';
    end if;
  end if;
  return new;
end;
$$;
revoke all on function vida_internal.guard_authorization_immutable_after_grant() from public,anon,authenticated,service_role;

grant vida_identity_owner to postgres with inherit false, set true;
commit;