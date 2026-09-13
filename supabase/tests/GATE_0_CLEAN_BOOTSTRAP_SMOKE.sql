begin;

do $bootstrap$
declare v_sql text;
begin
  select statements[1] into v_sql
  from supabase_migrations.schema_migrations
  where name='gate0_clean_bootstrap_shadow_proof_v2'
  order by version desc limit 1;
  if v_sql is null then raise exception 'bootstrap proof source missing'; end if;
  v_sql := regexp_replace(v_sql,'^[[:space:]]*begin;[[:space:]]*','','i');
  v_sql := regexp_replace(v_sql,'[[:space:]]*rollback;[[:space:]]*$','','i');
  execute v_sql;
end;
$bootstrap$;

create temp table gate0_smoke_ctx(user1 uuid,user2 uuid,record_id uuid) on commit drop;
insert into gate0_smoke_ctx values (gen_random_uuid(),gen_random_uuid(),gen_random_uuid());
select set_config('gate0.user1',(select user1::text from gate0_smoke_ctx),true);
select set_config('gate0.user2',(select user2::text from gate0_smoke_ctx),true);
select set_config('gate0.record_id',(select record_id::text from gate0_smoke_ctx),true);

insert into auth.users(id,aud,role,email,raw_app_meta_data,raw_user_meta_data,created_at,updated_at)
values
  (current_setting('gate0.user1')::uuid,'authenticated','authenticated','gate0-smoke-1@example.invalid','{}'::jsonb,'{}'::jsonb,now(),now()),
  (current_setting('gate0.user2')::uuid,'authenticated','authenticated','gate0-smoke-2@example.invalid','{}'::jsonb,'{}'::jsonb,now(),now());

do $profile_trigger$
begin
  if (select count(*) from public.users_profile where id in (current_setting('gate0.user1')::uuid,current_setting('gate0.user2')::uuid)) <> 2 then
    raise exception 'SMOKE FAIL: new-user trigger did not create both profiles';
  end if;
  if exists(select 1 from public.users_profile where id=current_setting('gate0.user1')::uuid and (lgpd_aceito or termos_aceito or onboarding_concluido)) then
    raise exception 'SMOKE FAIL: new-user defaults are not false';
  end if;
end;
$profile_trigger$;

update auth.users set email='gate0-smoke-1-updated@example.invalid',updated_at=now() where id=current_setting('gate0.user1')::uuid;

do $email_sync$
begin
  if not exists(select 1 from public.users_profile where id=current_setting('gate0.user1')::uuid and email='gate0-smoke-1-updated@example.invalid') then
    raise exception 'SMOKE FAIL: auth email sync trigger did not update users_profile';
  end if;
end;
$email_sync$;

select set_config('request.jwt.claim.sub',current_setting('gate0.user1'),true);
set local role authenticated;

do $rls_runtime$
declare rc integer;
begin
  if (select count(*) from public.users_profile) <> 1 then
    raise exception 'SMOKE FAIL: RLS did not restrict SELECT to own profile';
  end if;
  update public.users_profile set nome_completo='Gate0 Smoke User' where id=auth.uid();
  get diagnostics rc = row_count;
  if rc <> 1 then raise exception 'SMOKE FAIL: own-profile UPDATE was not allowed'; end if;
  update public.users_profile set nome_completo='SHOULD NOT WRITE' where id=current_setting('gate0.user2')::uuid;
  get diagnostics rc = row_count;
  if rc <> 0 then raise exception 'SMOKE FAIL: cross-user UPDATE escaped RLS'; end if;
end;
$rls_runtime$;

reset role;

do $acl_checks$
declare r text; t text; p text;
begin
  if not has_column_privilege('authenticated','public.users_profile','nome_completo','UPDATE') then
    raise exception 'SMOKE FAIL: authenticated lost allowed profile column UPDATE';
  end if;
  if has_column_privilege('authenticated','public.users_profile','email','UPDATE') then
    raise exception 'SMOKE FAIL: authenticated can UPDATE protected email column';
  end if;

  if exists (
    select 1
    from pg_class c
    join pg_namespace n on n.oid=c.relnamespace
    cross join lateral aclexplode(coalesce(c.relacl,acldefault('r',c.relowner))) e
    where n.nspname='public'
      and c.relname in ('economic_entities','entity_relationships','client_accounts','client_account_entities','client_account_users','reconciliation_source','reconciliation_record')
      and e.grantee=0
      and e.privilege_type in ('SELECT','INSERT','UPDATE','DELETE')
  ) then
    raise exception 'SMOKE FAIL: PUBLIC has direct canonical table privilege';
  end if;

  foreach r in array array['anon','authenticated','service_role'] loop
    foreach t in array array['economic_entities','entity_relationships','client_accounts','client_account_entities','client_account_users','reconciliation_source','reconciliation_record'] loop
      foreach p in array array['SELECT','INSERT','UPDATE','DELETE'] loop
        if has_table_privilege(r,format('public.%I',t),p) then
          raise exception 'SMOKE FAIL: % has % on %',r,p,t;
        end if;
      end loop;
    end loop;
  end loop;

  foreach r in array array['anon','authenticated'] loop
    foreach t in array array['hotmart_products','hotmart_purchases','hotmart_webhook_events','hotmart_integration_config','scanner_vida_empresa_submissions','vida_public_submissions'] loop
      if has_table_privilege(r,format('public.%I',t),'SELECT') or has_table_privilege(r,format('public.%I',t),'INSERT') then
        raise exception 'SMOKE FAIL: % has public intake/ops access on %',r,t;
      end if;
    end loop;
  end loop;
end;
$acl_checks$;

grant vida_reconciliation_operator to postgres with set true, inherit false;
set local role vida_reconciliation_operator;

select (public.canonical_reconcile(
  current_setting('gate0.record_id')::uuid,
  'auth.users.id',
  current_setting('gate0.user1'),
  'CONFIRMED_NEW',
  'gate0-clean-bootstrap-smoke',
  'synthetic rollback-only smoke test',
  null,
  'person',
  'Gate0 Synthetic Smoke',
  false
)).id;

select (public.canonical_reconcile(
  current_setting('gate0.record_id')::uuid,
  'auth.users.id',
  current_setting('gate0.user1'),
  'CONFIRMED_NEW',
  'gate0-clean-bootstrap-smoke',
  'synthetic rollback-only smoke test',
  null,
  'person',
  'Gate0 Synthetic Smoke',
  false
)).id;

reset role;

do $reconcile_checks$
declare v_entity uuid;
begin
  if (select count(*) from public.reconciliation_source where source_namespace='auth.users.id' and source_value=current_setting('gate0.user1')) <> 1 then
    raise exception 'SMOKE FAIL: canonical reconciliation source count != 1';
  end if;
  if (select count(*) from public.reconciliation_record where id=current_setting('gate0.record_id')::uuid) <> 1 then
    raise exception 'SMOKE FAIL: reconciliation retry was not idempotent';
  end if;
  select economic_entity_id into v_entity from public.reconciliation_record where id=current_setting('gate0.record_id')::uuid;
  if v_entity is null or not exists(select 1 from public.economic_entities where id=v_entity and entity_type='person' and display_name='Gate0 Synthetic Smoke') then
    raise exception 'SMOKE FAIL: canonical reconcile did not create expected EconomicEntity';
  end if;
  if not has_function_privilege('vida_reconciliation_operator','public.canonical_reconcile(uuid,text,text,text,text,text,uuid,text,text,boolean)','EXECUTE') then
    raise exception 'SMOKE FAIL: reconciliation operator cannot execute canonical RPC';
  end if;
  if has_table_privilege('vida_reconciliation_operator','public.reconciliation_record','INSERT') then
    raise exception 'SMOKE FAIL: reconciliation operator has direct INSERT';
  end if;
end;
$reconcile_checks$;

rollback;
