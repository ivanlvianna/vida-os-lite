-- VIDA OS™ — Gate 002 v4 runtime smoke
-- Transactional / rollback-only. Creates synthetic Auth users and Gate 002 rows, then rolls everything back.

begin;

create temp table gate002_v4_ctx(owner1 uuid, target uuid, owner2 uuid, account1 uuid, engagement1 uuid, account2 uuid, workflow uuid) on commit drop;
insert into gate002_v4_ctx(owner1,target,owner2) values(gen_random_uuid(),gen_random_uuid(),gen_random_uuid());
grant select,update on gate002_v4_ctx to authenticated;
grant select on gate002_v4_ctx to service_role;

insert into auth.users(id,aud,role,email,raw_app_meta_data,raw_user_meta_data,created_at,updated_at)
select owner1,'authenticated','authenticated','gate002-v4-owner1@example.invalid','{}'::jsonb,'{}'::jsonb,now(),now() from gate002_v4_ctx
union all select target,'authenticated','authenticated','gate002-v4-target@example.invalid','{}'::jsonb,'{}'::jsonb,now(),now() from gate002_v4_ctx
union all select owner2,'authenticated','authenticated','gate002-v4-owner2@example.invalid','{}'::jsonb,'{}'::jsonb,now(),now() from gate002_v4_ctx;

do $activation$
declare r1 record; r1b record; r2 record; v_owner1 uuid; v_owner2 uuid;
begin
 select owner1,owner2 into v_owner1,v_owner2 from gate002_v4_ctx;
 perform set_config('request.jwt.claim.sub','',true);
 select * into r1 from public.activate_client_from_vri(v_owner1,'gate002-v4-vri-a','gate002-v4-activation-a','no_match',null,'person','Gate002 V4 Client A');
 select * into r1b from public.activate_client_from_vri(v_owner1,'gate002-v4-vri-a','gate002-v4-activation-a','no_match',null,'person','Gate002 V4 Client A');
 if r1.client_account_id is distinct from r1b.client_account_id or r1.planning_engagement_id is distinct from r1b.planning_engagement_id then raise exception 'SMOKE FAIL: VRI retry not idempotent'; end if;
 select * into r2 from public.activate_client_from_vri(v_owner2,'gate002-v4-vri-b','gate002-v4-activation-b','no_match',null,'person','Gate002 V4 Client B');
 update gate002_v4_ctx set account1=r1.client_account_id,engagement1=r1.planning_engagement_id,account2=r2.client_account_id;
 if (select count(*) from public.client_account_membership_events where client_account_id=r1.client_account_id and event_type='added')<>1 then raise exception 'SMOKE FAIL: bootstrap membership ledger count'; end if;
end;$activation$;

select set_config('request.jwt.claim.sub',(select owner1::text from gate002_v4_ctx),true);
set local role authenticated;
do $owner_ops$
declare c record; v_added boolean; v_failed boolean:=false;
begin
 select * into c from gate002_v4_ctx;
 v_added:=public.add_client_account_membership(c.account1,c.target,'v4 smoke add target');
 if not v_added then raise exception 'SMOKE FAIL: first membership add returned false'; end if;
 if public.add_client_account_membership(c.account1,c.target,'v4 smoke add target') then raise exception 'SMOKE FAIL: membership retry not idempotent'; end if;
 perform public.grant_client_account_authorization(c.account1,c.target,'internal_staff','account',null,null);
 begin
   perform public.remove_client_account_membership(c.account1,c.owner1,'must reject last owner');
 exception when others then
   if sqlerrm like '%último planner_owner%' then v_failed:=true; else raise; end if;
 end;
 if not v_failed then raise exception 'SMOKE FAIL: last planner_owner removal allowed'; end if;
end;$owner_ops$;

do $rls$
declare c record; n1 int; n2 int;
begin
 select * into c from gate002_v4_ctx;
 select count(*) into n1 from public.client_accounts where id=c.account1;
 select count(*) into n2 from public.client_accounts where id=c.account2;
 if n1<>1 or n2<>0 then raise exception 'SMOKE FAIL: account RLS isolation own=% other=%',n1,n2; end if;
end;$rls$;
reset role;

do $auth_delete_block$
declare c record; v_failed boolean:=false;
begin
 select * into c from gate002_v4_ctx;
 begin delete from auth.users where id=c.target;
 exception when check_violation then v_failed:=true;
          when others then if sqlerrm like '%chk_active_requires_auth_user%' or sqlerrm like '%active%' then v_failed:=true; else raise; end if;
 end;
 if not v_failed then raise exception 'SMOKE FAIL: direct Auth deletion shortcut allowed'; end if;
end;$auth_delete_block$;

-- Authenticated planner may invoke the canonical workflow but cannot read its backend-only ledgers directly.
select set_config('request.jwt.claim.sub',(select owner1::text from gate002_v4_ctx),true);
set local role authenticated;
do $start_offboarding$
declare c record; w uuid;
begin
 select * into c from gate002_v4_ctx;
 w:=public.start_client_account_offboarding(c.account1,c.target,null,'v4 smoke canonical offboarding');
 update gate002_v4_ctx set workflow=w;
end;$start_offboarding$;
reset role;

-- Verify database stage as postgres, then simulate external Auth milestones.
do $database_stage$
declare c record;
begin
 select * into c from gate002_v4_ctx;
 if (select state from public.client_account_offboarding_workflows where id=c.workflow)<>'database_access_removed' then raise exception 'SMOKE FAIL: offboarding DB stage'; end if;
 if exists(select 1 from public.client_account_users where client_account_id=c.account1 and auth_user_id=c.target) then raise exception 'SMOKE FAIL: target membership remains'; end if;
 if exists(select 1 from public.client_account_user_authorizations where client_account_id=c.account1 and auth_user_id=c.target and revoked_at is null) then raise exception 'SMOKE FAIL: target authorization remains active'; end if;
end;$database_stage$;

delete from auth.sessions where user_id=(select target from gate002_v4_ctx);
set local role service_role;
select public.mark_client_offboarding_sessions_revoked((select workflow from gate002_v4_ctx));
reset role;
delete from auth.users where id=(select target from gate002_v4_ctx);
set local role service_role;
select public.mark_client_offboarding_user_deleted((select workflow from gate002_v4_ctx));
reset role;

do $final_checks$
declare c record;
begin
 select * into c from gate002_v4_ctx;
 if (select state from public.client_account_offboarding_workflows where id=c.workflow)<>'completed' then raise exception 'SMOKE FAIL: offboarding did not complete'; end if;
 if not exists(select 1 from public.client_account_user_authorizations where client_account_id=c.account1 and auth_user_label is not null and revoked_at is not null) then raise exception 'SMOKE FAIL: authorization history missing'; end if;
 if (select count(*) from public.client_account_membership_events where client_account_id=c.account1 and auth_user_id=c.target)<>2 then raise exception 'SMOKE FAIL: membership history is not add+remove'; end if;
 if (select count(*) from public.client_account_offboarding_events where workflow_id=c.workflow)<3 then raise exception 'SMOKE FAIL: offboarding event history incomplete'; end if;
 if has_table_privilege('authenticated','public.client_account_users','INSERT') or has_table_privilege('authenticated','public.client_account_users','DELETE') then raise exception 'SMOKE FAIL: authenticated has direct membership DML'; end if;
 if has_schema_privilege('anon','vida_internal','USAGE') then raise exception 'SMOKE FAIL: anon has vida_internal usage'; end if;
 if to_regprocedure('public.is_staff(uuid)') is not null then raise exception 'SMOKE FAIL: internal helper leaked into public'; end if;
end;$final_checks$;

rollback;
