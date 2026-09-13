-- VIDA OS™ — production schema equivalence fingerprint
-- Read-only catalog query. Run against the approved production baseline and any
-- candidate clean install; matching fingerprints are necessary (not sufficient)
-- evidence of schema equivalence.
--
-- Scope: public tables/columns/constraints/indexes/policies/functions/table ACLs/
-- function ACLs plus non-internal triggers on public and auth.users.

with lines as (
  select 'TABLE|'||c.relname||'|owner='||pg_get_userbyid(c.relowner)||'|rls='||c.relrowsecurity::text||'|force='||c.relforcerowsecurity::text as line
  from pg_class c
  join pg_namespace n on n.oid=c.relnamespace
  where n.nspname='public' and c.relkind='r'

  union all

  select 'COLUMN|'||c.relname||'|'||a.attnum::text||'|'||a.attname||'|'||pg_catalog.format_type(a.atttypid,a.atttypmod)||'|notnull='||a.attnotnull::text||'|default='||coalesce(pg_get_expr(d.adbin,d.adrelid),'')
  from pg_class c
  join pg_namespace n on n.oid=c.relnamespace
  join pg_attribute a on a.attrelid=c.oid and a.attnum>0 and not a.attisdropped
  left join pg_attrdef d on d.adrelid=c.oid and d.adnum=a.attnum
  where n.nspname='public' and c.relkind='r'

  union all

  select 'CONSTRAINT|'||conrelid::regclass::text||'|'||conname||'|'||contype::text||'|'||pg_get_constraintdef(oid,true)
  from pg_constraint
  where connamespace='public'::regnamespace and conrelid<>0

  union all

  select 'INDEX|'||tablename||'|'||indexname||'|'||indexdef
  from pg_indexes where schemaname='public'

  union all

  select 'POLICY|'||tablename||'|'||policyname||'|'||cmd||'|'||roles::text||'|'||coalesce(qual,'')||'|'||coalesce(with_check,'')
  from pg_policies where schemaname='public'

  union all

  select 'FUNCTION|public.'||p.proname||'('||pg_get_function_identity_arguments(p.oid)||')|definer='||p.prosecdef::text||'|volatile='||p.provolatile::text||'|config='||coalesce(array_to_string(p.proconfig,','),'')||'|def='||pg_get_functiondef(p.oid)
  from pg_proc p
  join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='public'

  union all

  select 'TRIGGER|'||n.nspname||'.'||c.relname||'|'||t.tgname||'|'||pg_get_triggerdef(t.oid,true)
  from pg_trigger t
  join pg_class c on c.oid=t.tgrelid
  join pg_namespace n on n.oid=c.relnamespace
  where not t.tgisinternal
    and (n.nspname='public' or (n.nspname='auth' and c.relname='users'))

  union all

  select 'TABLEACL|'||c.relname||'|'||case when e.grantee=0 then 'PUBLIC' else pg_get_userbyid(e.grantee) end||'|'||e.privilege_type||'|grantable='||e.is_grantable::text
  from pg_class c
  join pg_namespace n on n.oid=c.relnamespace
  cross join lateral aclexplode(coalesce(c.relacl,acldefault('r',c.relowner))) e
  where n.nspname='public' and c.relkind='r'

  union all

  select 'FUNCTIONACL|public.'||p.proname||'('||pg_get_function_identity_arguments(p.oid)||')|'||case when e.grantee=0 then 'PUBLIC' else pg_get_userbyid(e.grantee) end||'|'||e.privilege_type||'|grantable='||e.is_grantable::text
  from pg_proc p
  join pg_namespace n on n.oid=p.pronamespace
  cross join lateral aclexplode(coalesce(p.proacl,acldefault('f',p.proowner))) e
  where n.nspname='public'
)
select
  md5(string_agg(line,E'\n' order by line)) as production_public_schema_fingerprint,
  count(*) as object_lines
from lines;
