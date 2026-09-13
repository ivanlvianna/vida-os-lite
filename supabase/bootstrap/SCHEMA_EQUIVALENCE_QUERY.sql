-- VIDA OS™ — production schema equivalence fingerprint v2
-- Read-only catalog query. Run against the approved production baseline and any
-- candidate clean install; matching fingerprints are necessary (not sufficient)
-- evidence of schema equivalence.
--
-- v2 closes material blind spots in the first oracle by including:
--   * public schema owner + ACLs;
--   * VIDA technical role definitions and memberships;
--   * relation kinds beyond ordinary tables (so an accidental view/sequence is visible);
--   * column-level ACLs (required for users_profile UPDATE restrictions);
--   * function owners;
--   * public enum/domain types, if any.
--
-- Scope: public schema/ACL, VIDA roles/memberships, relations/columns/constraints/
-- indexes/policies/functions/table ACLs/column ACLs/function ACLs, public enum/domain
-- types, plus non-internal triggers on public and auth.users.

with lines as (
  select 'SCHEMA|public|owner='||pg_get_userbyid(n.nspowner) as line
  from pg_namespace n
  where n.nspname='public'

  union all

  select 'SCHEMAACL|public|'
      ||case when e.grantee=0 then 'PUBLIC' else pg_get_userbyid(e.grantee) end
      ||'|'||e.privilege_type
      ||'|grantable='||e.is_grantable::text
  from pg_namespace n
  cross join lateral aclexplode(n.nspacl) e
  where n.nspname='public'

  union all

  select 'ROLE|'||r.rolname
      ||'|super='||r.rolsuper::text
      ||'|inherit='||r.rolinherit::text
      ||'|createrole='||r.rolcreaterole::text
      ||'|createdb='||r.rolcreatedb::text
      ||'|login='||r.rolcanlogin::text
      ||'|replication='||r.rolreplication::text
      ||'|bypassrls='||r.rolbypassrls::text
  from pg_roles r
  where r.rolname like 'vida_%'

  union all

  select 'ROLEMEMBER|role='||role.rolname
      ||'|member='||member.rolname
      ||'|grantor='||pg_get_userbyid(m.grantor)
      ||'|admin='||m.admin_option::text
      ||'|inherit='||m.inherit_option::text
      ||'|set='||m.set_option::text
  from pg_auth_members m
  join pg_roles role on role.oid=m.roleid
  join pg_roles member on member.oid=m.member
  where role.rolname like 'vida_%'
     or member.rolname like 'vida_%'

  union all

  select 'RELATION|'||c.relname
      ||'|kind='||c.relkind::text
      ||'|owner='||pg_get_userbyid(c.relowner)
      ||'|rls='||c.relrowsecurity::text
      ||'|force='||c.relforcerowsecurity::text
  from pg_class c
  join pg_namespace n on n.oid=c.relnamespace
  where n.nspname='public'
    and c.relkind in ('r','p','v','m','S','f')

  union all

  select 'COLUMN|'||c.relname
      ||'|'||a.attnum::text
      ||'|'||a.attname
      ||'|'||pg_catalog.format_type(a.atttypid,a.atttypmod)
      ||'|notnull='||a.attnotnull::text
      ||'|default='||coalesce(pg_get_expr(d.adbin,d.adrelid),'')
  from pg_class c
  join pg_namespace n on n.oid=c.relnamespace
  join pg_attribute a on a.attrelid=c.oid and a.attnum>0 and not a.attisdropped
  left join pg_attrdef d on d.adrelid=c.oid and d.adnum=a.attnum
  where n.nspname='public'
    and c.relkind in ('r','p','v','m','f')

  union all

  select 'COLUMNACL|'||c.relname
      ||'|'||a.attname
      ||'|'||case when e.grantee=0 then 'PUBLIC' else pg_get_userbyid(e.grantee) end
      ||'|'||e.privilege_type
      ||'|grantable='||e.is_grantable::text
  from pg_class c
  join pg_namespace n on n.oid=c.relnamespace
  join pg_attribute a on a.attrelid=c.oid and a.attnum>0 and not a.attisdropped
  cross join lateral aclexplode(a.attacl) e
  where n.nspname='public'
    and c.relkind in ('r','p','v','m','f')
    and a.attacl is not null

  union all

  select 'CONSTRAINT|'||conrelid::regclass::text
      ||'|'||conname
      ||'|'||contype::text
      ||'|'||pg_get_constraintdef(oid,true)
  from pg_constraint
  where connamespace='public'::regnamespace
    and conrelid<>0

  union all

  select 'INDEX|'||tablename||'|'||indexname||'|'||indexdef
  from pg_indexes
  where schemaname='public'

  union all

  select 'POLICY|'||tablename
      ||'|'||policyname
      ||'|'||cmd
      ||'|'||roles::text
      ||'|'||coalesce(qual,'')
      ||'|'||coalesce(with_check,'')
  from pg_policies
  where schemaname='public'

  union all

  select 'FUNCTION|public.'||p.proname
      ||'('||pg_get_function_identity_arguments(p.oid)||')'
      ||'|owner='||pg_get_userbyid(p.proowner)
      ||'|definer='||p.prosecdef::text
      ||'|volatile='||p.provolatile::text
      ||'|config='||coalesce(array_to_string(p.proconfig,','),'')
      ||'|def='||pg_get_functiondef(p.oid)
  from pg_proc p
  join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='public'

  union all

  select 'TRIGGER|'||n.nspname||'.'||c.relname
      ||'|'||t.tgname
      ||'|'||pg_get_triggerdef(t.oid,true)
  from pg_trigger t
  join pg_class c on c.oid=t.tgrelid
  join pg_namespace n on n.oid=c.relnamespace
  where not t.tgisinternal
    and (n.nspname='public' or (n.nspname='auth' and c.relname='users'))

  union all

  select 'TABLEACL|'||c.relname
      ||'|'||case when e.grantee=0 then 'PUBLIC' else pg_get_userbyid(e.grantee) end
      ||'|'||e.privilege_type
      ||'|grantable='||e.is_grantable::text
  from pg_class c
  join pg_namespace n on n.oid=c.relnamespace
  cross join lateral aclexplode(coalesce(c.relacl,acldefault('r',c.relowner))) e
  where n.nspname='public'
    and c.relkind in ('r','p','v','m','f')

  union all

  select 'FUNCTIONACL|public.'||p.proname
      ||'('||pg_get_function_identity_arguments(p.oid)||')'
      ||'|'||case when e.grantee=0 then 'PUBLIC' else pg_get_userbyid(e.grantee) end
      ||'|'||e.privilege_type
      ||'|grantable='||e.is_grantable::text
  from pg_proc p
  join pg_namespace n on n.oid=p.pronamespace
  cross join lateral aclexplode(coalesce(p.proacl,acldefault('f',p.proowner))) e
  where n.nspname='public'

  union all

  select 'TYPE|'||t.typname
      ||'|kind='||t.typtype::text
      ||'|owner='||pg_get_userbyid(t.typowner)
  from pg_type t
  join pg_namespace n on n.oid=t.typnamespace
  where n.nspname='public'
    and t.typtype in ('e','d')
)
select
  md5(string_agg(line,E'\n' order by line)) as production_schema_fingerprint_v2,
  count(*) as object_lines
from lines;
