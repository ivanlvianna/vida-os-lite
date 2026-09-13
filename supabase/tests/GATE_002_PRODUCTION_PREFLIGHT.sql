-- VIDA OS™ — Gate 002 production preflight
-- READ-ONLY. Target: production project dlobyyzixcandloxbeth.
--
-- Purpose: prove immediately before any authorized production apply that the
-- live database is still the expected Phase 1A baseline and that Gate 002 has
-- not been partially installed. This script performs no DDL/DML.

with
phase1a_tables(name) as (
  values
    ('economic_entities'),
    ('entity_relationships'),
    ('client_accounts'),
    ('client_account_entities'),
    ('client_account_users'),
    ('reconciliation_source'),
    ('reconciliation_record')
),
phase1b_tables(name) as (
  values
    ('client_account_vri_links'),
    ('client_account_user_authorizations'),
    ('planning_engagements'),
    ('planning_engagement_vri_links'),
    ('planning_engagement_entities'),
    ('planning_engagement_transitions'),
    ('client_activation_seeds'),
    ('client_account_membership_events'),
    ('client_account_offboarding_workflows'),
    ('client_account_offboarding_events')
),
phase1b_rpcs(signature) as (
  values
    ('public.create_economic_entity(uuid,text,text)'),
    ('public.create_planning_engagement(uuid,uuid,text,text,text)'),
    ('public.grant_client_account_authorization(uuid,uuid,text,text,uuid,uuid)'),
    ('public.revoke_client_account_authorization(uuid)'),
    ('public.record_planning_engagement_transition(uuid,text,text,text,text,text,text)'),
    ('public.activate_client_from_vri(uuid,text,text,text,uuid,text,text)'),
    ('public.add_client_account_membership(uuid,uuid,text)'),
    ('public.remove_client_account_membership(uuid,uuid,text)'),
    ('public.start_client_account_offboarding(uuid,uuid,uuid,text)'),
    ('public.mark_client_offboarding_sessions_revoked(uuid)'),
    ('public.mark_client_offboarding_user_deleted(uuid)'),
    ('public.record_client_offboarding_retryable_failure(uuid,text,text)')
),
m1_functions(signature) as (
  values
    ('public.canonical_reconciliation(uuid,timestamp with time zone)'),
    ('public.reconciliation_source_block_mutation()'),
    ('public.reconciliation_record_block_mutation()'),
    ('public.reconciliation_record_validate_succession()'),
    ('public.entity_relationships_enforce_owns_target()'),
    ('public.economic_entities_protect_owns_target()')
),
blocking_checks(check_name, passed, detail) as (
  select
    'phase1a_tables_present',
    count(*) = 0,
    coalesce(string_agg(name, ', ' order by name), 'all present')
  from phase1a_tables
  where to_regclass(format('public.%I',name)) is null

  union all
  select
    'phase1b_tables_absent',
    count(*) = 0,
    coalesce(string_agg(name, ', ' order by name), 'none present')
  from phase1b_tables
  where to_regclass(format('public.%I',name)) is not null

  union all
  select
    'phase1b_public_rpcs_absent',
    count(*) = 0,
    coalesce(string_agg(signature, ', ' order by signature), 'none present')
  from phase1b_rpcs
  where to_regprocedure(signature) is not null

  union all
  select
    'vida_internal_absent',
    to_regnamespace('vida_internal') is null,
    case when to_regnamespace('vida_internal') is null then 'absent as expected' else 'schema already exists' end

  union all
  select
    'client_account_users_auth_fk_absent',
    not exists (
      select 1 from pg_constraint
      where conname='client_account_users_auth_user_id_fkey'
        and conrelid='public.client_account_users'::regclass
    ),
    case when exists (
      select 1 from pg_constraint
      where conname='client_account_users_auth_user_id_fkey'
        and conrelid='public.client_account_users'::regclass
    ) then 'already present' else 'absent as expected' end

  union all
  select
    'phase1a_required_indexes_present',
    to_regclass('public.idx_client_account_entities_economic_entity_id') is not null
      and to_regclass('public.idx_client_account_users_auth_user_id') is not null,
    format('cae=%s; cau=%s',
      to_regclass('public.idx_client_account_entities_economic_entity_id') is not null,
      to_regclass('public.idx_client_account_users_auth_user_id') is not null)

  union all
  select
    'm1_reconciliation_entity_index_absent',
    to_regclass('public.reconciliation_record_economic_entity_id_idx') is null,
    case when to_regclass('public.reconciliation_record_economic_entity_id_idx') is null
      then 'absent as expected before M1' else 'already present' end

  union all
  select
    'm1_functions_present_and_unhardened',
    (select count(*) from m1_functions where to_regprocedure(signature) is not null) = 6
      and (
        select count(*)
        from pg_proc p
        join pg_namespace n on n.oid=p.pronamespace
        where p.oid in (select to_regprocedure(signature) from m1_functions)
          and p.proconfig is not null
      ) = 0,
    format('present=%s/6; with_proconfig=%s',
      (select count(*) from m1_functions where to_regprocedure(signature) is not null),
      (
        select count(*)
        from pg_proc p
        where p.oid in (select to_regprocedure(signature) from m1_functions)
          and p.proconfig is not null
      ))

  union all
  select
    'phase1a_rls_prestate',
    count(*) filter (where c.relrowsecurity) = 0,
    format('rls_enabled=%s/7', count(*) filter (where c.relrowsecurity))
  from pg_class c
  join pg_namespace n on n.oid=c.relnamespace
  where n.nspname='public'
    and c.relname in (select name from phase1a_tables)

  union all
  select
    'phase1a_policy_prestate',
    count(*) = 0,
    format('policies=%s',count(*))
  from pg_policy p
  where p.polrelid in (
    select to_regclass(format('public.%I',name)) from phase1a_tables
  )

  union all
  select
    'phase1a_no_direct_api_crud',
    count(*) = 0,
    format('unexpected_acl_entries=%s',count(*))
  from pg_class c
  join pg_namespace n on n.oid=c.relnamespace
  cross join lateral aclexplode(coalesce(c.relacl,acldefault('r',c.relowner))) e
  where n.nspname='public'
    and c.relname in (select name from phase1a_tables)
    and e.privilege_type in ('SELECT','INSERT','UPDATE','DELETE')
    and (
      e.grantee=0
      or pg_get_userbyid(e.grantee) in ('anon','authenticated','service_role')
    )

  union all
  select
    'client_account_users_auth_integrity',
    count(*) = 0,
    format('orphans=%s',count(*))
  from public.client_account_users cu
  left join auth.users u on u.id=cu.auth_user_id
  where u.id is null

  union all
  select
    'client_account_entities_entity_integrity',
    count(*) = 0,
    format('orphans=%s',count(*))
  from public.client_account_entities cae
  left join public.economic_entities e on e.id=cae.economic_entity_id
  where e.id is null

  union all
  select
    'reconciliation_entity_integrity',
    count(*) = 0,
    format('orphans=%s',count(*))
  from public.reconciliation_record rr
  left join public.economic_entities e on e.id=rr.economic_entity_id
  where rr.economic_entity_id is not null and e.id is null

  union all
  select
    'gate002_not_in_migration_ledger',
    count(*) = 0,
    format('matching_ledger_rows=%s',count(*))
  from supabase_migrations.schema_migrations
  where name like 'gate002%'
     or name like 'phase1b%'
     or name like '%membership_governance%'
     or name like '%offboarding_workflow%'
),
summary as (
  select bool_and(passed) as overall_ready,
         count(*) filter (where passed) as passed_checks,
         count(*) as total_checks
  from blocking_checks
),
data_snapshot as (
  select jsonb_build_object(
    'auth_users',(select count(*) from auth.users),
    'economic_entities',(select count(*) from public.economic_entities),
    'entity_relationships',(select count(*) from public.entity_relationships),
    'client_accounts',(select count(*) from public.client_accounts),
    'client_account_entities',(select count(*) from public.client_account_entities),
    'client_account_users',(select count(*) from public.client_account_users),
    'reconciliation_source',(select count(*) from public.reconciliation_source),
    'reconciliation_record',(select count(*) from public.reconciliation_record)
  ) as snapshot
)
select jsonb_build_object(
  'overall_ready', summary.overall_ready,
  'passed_checks', summary.passed_checks,
  'total_checks', summary.total_checks,
  'checks', (
    select jsonb_agg(jsonb_build_object(
      'check',check_name,
      'passed',passed,
      'detail',detail
    ) order by check_name)
    from blocking_checks
  ),
  'data_snapshot', data_snapshot.snapshot
) as gate002_production_preflight
from summary cross join data_snapshot;
