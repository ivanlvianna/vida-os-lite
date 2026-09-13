-- VIDA OS™ — Identity technical-role current-state bootstrap DRAFT
-- STATUS: NON-EXECUTABLE / NOT CLEAN-INSTALL-VALIDATED / DO NOT RUN IN PRODUCTION.
--
-- Purpose: reconstruct the three technical roles and the stable membership/schema
-- surface observed in the 2026-09-13 production catalog before Phase 1A objects are
-- materialized. This assumes a compatible Supabase/PostgreSQL 17 environment where
-- migrations execute as role postgres, which is CREATEROLE but not superuser.
--
-- PostgreSQL 17 behavior used deliberately here: when a non-superuser CREATEROLE
-- member creates another role, the new role is automatically granted back to the
-- creator with ADMIN TRUE, INHERIT FALSE, SET FALSE by the bootstrap superuser.
-- That behavior explains the supabase_admin -> postgres membership rows observed
-- in production. The explicit vida_identity_owner grant below adds the second,
-- postgres-granted SET TRUE / INHERIT FALSE membership required for ALTER OWNER / SET ROLE.
--
-- This draft MUST be proven on a blank compatible Supabase project and compared with
-- SCHEMA_EQUIVALENCE_QUERY.sql before promotion.

begin;

create role vida_identity_owner
  nologin
  nosuperuser
  inherit
  nocreaterole
  nocreatedb
  noreplication
  nobypassrls;

create role vida_reconciliation_operator
  nologin
  nosuperuser
  inherit
  nocreaterole
  nocreatedb
  noreplication
  nobypassrls;

create role vida_identity_rollback_operator
  nologin
  nosuperuser
  inherit
  nocreaterole
  nocreatedb
  noreplication
  nobypassrls;

-- Permanent SET path only for the technical owner. The two operator roles remain
-- ADMIN-manageable by postgres but without permanent SET access; operational SET
-- membership is granted only when a controlled operation explicitly requires it.
grant vida_identity_owner to postgres
  with inherit false, set true;

-- Current production public-schema surface for the VIDA roles is USAGE only.
grant usage on schema public to vida_identity_owner;
grant usage on schema public to vida_reconciliation_operator;
grant usage on schema public to vida_identity_rollback_operator;

commit;
