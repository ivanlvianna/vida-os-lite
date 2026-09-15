-- VIDA OS™ — canonical v0.7 onboarding extension reconstructed from live D3 catalog
-- Baseline prerequisite: canonical v0.6

create or replace function public.onboard_client_account_member(
  p_client_account_id uuid,
  p_target_auth_user_id uuid,
  p_role text,
  p_scope_type text,
  p_planning_engagement_id uuid default null::uuid,
  p_economic_entity_id uuid default null::uuid
)
returns uuid
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_authorization_id uuid;
  v_constraint_name  text;
begin
  if auth.uid() is null then
    raise exception 'onboard_client_account_member exige sessão autenticada';
  end if;

  if not public.has_role_in_scope(p_client_account_id, array['planner_owner']) then
    raise exception
      'usuário % não é planner_owner desta conta — não pode incorporar novo membro',
      auth.uid();
  end if;

  perform 1 from public.client_accounts where id = p_client_account_id for update;

  if not public.has_role_in_scope(p_client_account_id, array['planner_owner']) then
    raise exception
      'usuário % não é planner_owner desta conta — não pode incorporar novo membro',
      auth.uid();
  end if;

  if not exists (select 1 from auth.users where id = p_target_auth_user_id) then
    raise exception
      'auth_user % não existe — não é possível incorporar um membro que não tem login',
      p_target_auth_user_id;
  end if;

  insert into public.client_account_users (client_account_id, auth_user_id)
  values (p_client_account_id, p_target_auth_user_id)
  on conflict (client_account_id, auth_user_id) do nothing;

  begin
    v_authorization_id := public.grant_client_account_authorization(
      p_client_account_id, p_target_auth_user_id, p_role, p_scope_type,
      p_planning_engagement_id, p_economic_entity_id
    );
  exception when unique_violation then
    get stacked diagnostics v_constraint_name = constraint_name;
    if v_constraint_name = 'client_account_user_authorizations_active_scope_uq' then
      raise exception
        'já existe uma autorização ativa para % neste escopo da conta % — revogue a existente antes de conceder de novo',
        p_target_auth_user_id, p_client_account_id;
    else
      raise;
    end if;
  end;

  return v_authorization_id;
end;
$function$;

revoke all on function public.onboard_client_account_member(uuid,uuid,text,text,uuid,uuid)
from public,anon,authenticated,service_role;
grant execute on function public.onboard_client_account_member(uuid,uuid,text,text,uuid,uuid)
to authenticated;
