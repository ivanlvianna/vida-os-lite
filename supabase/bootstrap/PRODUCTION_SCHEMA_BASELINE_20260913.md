# Production schema baseline inventory — 2026-09-13

Status: **READ-ONLY PRODUCTION CAPTURE / STANDALONE GATE 0 BOOTSTRAP QUALIFIED**

Source: live production project `dlobyyzixcandloxbeth`, inspected only through read-only catalog queries. No DDL/DML was executed in production.

Qualified reconstruction artifact: `production_schema_20260913.sql`. Its qualification is documented in `../tests/GATE_0_CANONICAL_BOOTSTRAP_QUALIFICATION.md`.

## Equivalence fingerprint v2

The canonical read-only query in `SCHEMA_EQUIVALENCE_QUERY.sql` includes the public schema ACL, VIDA technical roles and memberships, relation kinds, column-level ACLs, function owners and any public enum/domain types in addition to the structural objects already covered by v1.

It produced:

- fingerprint v2: `e100181fbc05659e2e9fbcb2c3b296b1`
- normalized object lines: **584**

The earlier v1 fingerprint `997d3e04bd3e160bc9368f55560cf59a` / 552 lines is **superseded as the acceptance oracle** because it did not detect column-level ACL differences or the VIDA technical-role surface. It is retained only as historical evidence of the first capture.

Current v2 catalog counts:

- public schema objects: **1**
- public schema ACL entries: **10**
- VIDA technical roles: **3**
- VIDA role-membership grants: **4**
- public relations in scope: **17** (all ordinary tables in the production baseline)
- public columns: **148**
- explicit column ACL entries: **14**
- public constraints: **65**
- public indexes: **42**
- public policies: **13**
- public functions: **12**
- non-internal triggers on public plus `auth.users`: **9**
- effective table ACL entries: **228**
- effective function ACL entries: **18**
- public enum/domain types: **0**

This fingerprint remains the comparison oracle for the 2026-09-13 baseline. The qualified standalone bootstrap was replayed against a clean application-owned surface in the existing compatible zero-cost rehearsal project and reproduced this fingerprint exactly at **584/584** normalized lines.

## VIDA technical role surface

The production baseline contains three dedicated NOLOGIN roles, all non-superuser, non-CREATEDB, non-CREATEROLE, non-replication and non-BYPASSRLS:

- `vida_identity_owner`
- `vida_identity_rollback_operator`
- `vida_reconciliation_operator`

The v2 oracle also captures their membership grants, including grantor and PostgreSQL 17 membership options (`ADMIN`, `INHERIT`, `SET`). This is material because Phase 1A ownership and rollback/reconciliation boundaries cannot be reproduced by table DDL alone.

## Public-table inventory

### Legacy Lite / user-facing core

- `users_profile` — RLS ON; owner `postgres`
- `prontuario_patrimonial` — RLS ON; owner `postgres`
- `diagnosticos` — RLS ON; owner `postgres`
- `diagnosticos_vida` — RLS ON; owner `postgres`

### Integrations / public intake

- `hotmart_integration_config` — RLS ON
- `hotmart_products` — RLS ON
- `hotmart_purchases` — RLS ON
- `hotmart_webhook_events` — RLS ON
- `scanner_vida_empresa_submissions` — RLS ON
- `vida_public_submissions` — RLS ON

### Identity Phase 1A canonical layer

- `economic_entities` — RLS OFF in production baseline; owner `vida_identity_owner`
- `entity_relationships` — RLS OFF; owner `vida_identity_owner`
- `client_accounts` — RLS OFF; owner `vida_identity_owner`
- `client_account_entities` — RLS OFF; owner `vida_identity_owner`
- `client_account_users` — RLS OFF; owner `vida_identity_owner`
- `reconciliation_source` — RLS OFF; owner `vida_identity_owner`
- `reconciliation_record` — RLS OFF; owner `vida_identity_owner`

The Phase 1A tables are deny-by-ACL in the production baseline: PUBLIC, `anon`, `authenticated` and `service_role` have no direct table privileges on them. Gate 002 separately qualified enabling the future RLS/RBAC access surface in rehearsal; production remains unchanged.

## Historical pre-ledger bootstrap gap — resolved by direct-current-state bootstrap

The first tracked production migration (`20260716005752_harden_vida_os_lite_rls_and_profiles`) immediately reads or alters existing objects. It does not create the legacy Lite schema. Therefore migration-history replay alone cannot build the current schema from a clean application-owned surface.

The standalone bootstrap resolves this historical gap by explicitly representing four legacy objects whose creation is not present in the tracked production ledger, plus the recovered integrations and exact Identity Phase 1A state.

### `users_profile`

Current columns: `id`, `nome_completo`, `telefone_whatsapp`, `data_nascimento`, `profissao`, `estado_civil`, `numero_dependentes`, `possui_empresa`, `possui_imoveis`, `faixa_patrimonio`, `origin_lead`, `lgpd_aceito`, `termos_aceito`, `created_at`, `updated_at`, `onboarding_concluido`, `email`.

Key current invariants:
- PK `id`;
- FK `id -> auth.users(id) ON DELETE CASCADE`;
- unique index `users_profile_email_idx(email)`;
- own-user RLS policies for SELECT/INSERT/UPDATE/DELETE;
- authenticated UPDATE is column-scoped and intentionally excludes `email`/`id`;
- the 14 explicit column UPDATE grants are fingerprinted by the v2 oracle;
- `handle_new_user()` creates/updates the profile from Auth;
- `sync_user_profile_email()` synchronizes later Auth e-mail changes;
- `set_updated_at_users_profile` maintains `updated_at`.

### `prontuario_patrimonial`

Current columns: `id`, `user_id`, legacy `secao/campo/valor`, `created_at`, `updated_at`, and `dados jsonb`.

Key current invariants:
- PK `id`;
- FK `user_id -> auth.users(id) ON DELETE RESTRICT`;
- UNIQUE `user_id`;
- legacy `secao` CHECK allowlist;
- own-user authenticated CRUD RLS;
- `set_updated_at_prontuario` trigger.

### `diagnosticos`

Current columns: `id`, `user_id`, `scanner_nome`, `perfil_identificado`, `scores`, `narrativa`, `mecanismo_dominante`, `capital_decisorio`, `raw_json`, `created_at`.

Key current invariants:
- PK `id`;
- FK `user_id -> auth.users(id) ON DELETE RESTRICT`;
- index `diagnosticos_user_id_idx`;
- own-user authenticated CRUD RLS.

### `diagnosticos_vida`

Current columns: `id`, `user_id`, `instrumento`, `external_id`, `status`, `score`, `perfil`, `link_relatorio`, `processado_em`, `created_at`, `updated_at`.

Key current invariants:
- PK `id`;
- FK `user_id -> auth.users(id) ON DELETE RESTRICT`;
- UNIQUE `(instrumento, external_id)`;
- index `diagnosticos_vida_user_id_idx`;
- authenticated has SELECT only, constrained by own-user RLS; writes are backend/service-role operations.

No tracked production migration creates `diagnosticos_vida`; its current-state DDL is therefore supplied explicitly by the standalone bootstrap.

## Auth/public trigger surface relevant to bootstrap

Current relevant triggers include:

- `auth.users.on_auth_user_created` → `public.handle_new_user()` after INSERT;
- `auth.users.sync_user_profile_email_after_auth_update` → `public.sync_user_profile_email()` after e-mail UPDATE;
- `public.users_profile.set_updated_at_users_profile` → `public.set_updated_at()` before UPDATE;
- `public.prontuario_patrimonial.set_updated_at_prontuario` → `public.set_updated_at()` before UPDATE.

The current `handle_new_user`, `set_updated_at` and `sync_user_profile_email` functions are not executable by `anon` or `authenticated`; service-role execution remains effective.

## Bootstrap qualification — completed

The former acceptance path has been completed under the explicit zero-cost constraint:

1. direct-current-state DDL was assembled without production data or secrets;
2. all 17 current public tables and the relevant functions, triggers, policies, indexes, constraints, owners, column ACLs, table/function ACLs, public-schema ACLs and VIDA technical-role semantics were represented;
3. the exact 83,433-byte Identity Phase 1A historical body was physically archived in Git and used as a verified source;
4. the standalone Git artifact was transferred byte-for-byte into the existing compatible rehearsal environment;
5. before replay, the artifact identity was re-hashed and matched its Git-qualified identity;
6. replay against a clean application-owned surface reproduced `e100181fbc05659e2e9fbcb2c3b296b1` at **584/584** normalized lines;
7. database-level smoke tests passed for Auth profile creation, Auth email synchronization, runtime RLS isolation, column ACLs, canonical-table isolation and idempotent canonical reconciliation;
8. the outer test transaction rolled back cleanly, leaving zero synthetic Gate 0 users and restoring rehearsal row counts;
9. the qualified candidate was promoted by Git rename only, without changing its SQL bytes.

Canonical artifact identity:

- path: `production_schema_20260913.sql`
- bytes: `100307`
- SHA-256: `188be8b6bc309c911f9973d00d1bbb158108cecfe6927aacf8a4f50d2c6cae4d`
- Git blob SHA: `2e4860e499c36c50032a5ea2e2ce48247115643c`

This closes the Gate 0 standalone-schema reconstruction for the 2026-09-13 baseline. It does **not** authorize Gate 002 / Phase 1B production application or a merge to `main`.
