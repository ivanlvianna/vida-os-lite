# Production schema baseline inventory — 2026-09-13

Status: **READ-ONLY CAPTURE / BOOTSTRAP STILL NON-EXECUTABLE**

Source: live production project `dlobyyzixcandloxbeth`, inspected only through read-only catalog queries. No DDL/DML was executed in production.

## Equivalence fingerprint

The canonical read-only query in `SCHEMA_EQUIVALENCE_QUERY.sql` produced:

- fingerprint: `997d3e04bd3e160bc9368f55560cf59a`
- normalized object lines: **552**

Current catalog counts inside that baseline:

- public tables: **17**
- public columns: **148**
- public constraints: **65**
- public indexes: **42**
- public policies: **13**
- public functions: **12**
- non-internal triggers on public plus `auth.users`: **9**

This fingerprint is a comparison oracle, not a replacement for installation testing. A clean bootstrap candidate must be installed on a blank compatible Supabase project and then compared to this baseline.

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

The Phase 1A tables are deny-by-ACL in the production baseline: PUBLIC, `anon`, `authenticated` and `service_role` have no direct table privileges on them. Gate 002 separately qualified enabling RLS in rehearsal; production remains unchanged.

## Undocumented/pre-ledger bootstrap gap

The first tracked production migration (`20260716005752_harden_vida_os_lite_rls_and_profiles`) immediately reads or alters existing objects. It does not create the legacy Lite schema. Therefore migration-history replay alone cannot build a blank database.

At minimum, a direct-current-state bootstrap must account for four legacy objects whose creation is not represented by the tracked production ledger:

### `users_profile`

Current columns: `id`, `nome_completo`, `telefone_whatsapp`, `data_nascimento`, `profissao`, `estado_civil`, `numero_dependentes`, `possui_empresa`, `possui_imoveis`, `faixa_patrimonio`, `origin_lead`, `lgpd_aceito`, `termos_aceito`, `created_at`, `updated_at`, `onboarding_concluido`, `email`.

Key current invariants:
- PK `id`;
- FK `id -> auth.users(id) ON DELETE CASCADE`;
- unique index `users_profile_email_idx(email)`;
- own-user RLS policies for SELECT/INSERT/UPDATE/DELETE;
- authenticated UPDATE is column-scoped and intentionally excludes `email`/`id`;
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

No tracked production migration creates `diagnosticos_vida`, so its creation is also part of the untracked bootstrap gap.

## Auth/public trigger surface relevant to bootstrap

Current relevant triggers include:

- `auth.users.on_auth_user_created` → `public.handle_new_user()` after INSERT;
- `auth.users.sync_user_profile_email_after_auth_update` → `public.sync_user_profile_email()` after e-mail UPDATE;
- `public.users_profile.set_updated_at_users_profile` → `public.set_updated_at()` before UPDATE;
- `public.prontuario_patrimonial.set_updated_at_prontuario` → `public.set_updated_at()` before UPDATE.

The current `handle_new_user`, `set_updated_at` and `sync_user_profile_email` functions are not executable by `anon` or `authenticated`; service-role execution remains effective.

## Bootstrap acceptance path

The directory remains non-executable until all of the following are proven:

1. direct-current-state DDL is generated without production data/secrets;
2. all 17 current public tables, functions, triggers, policies, indexes, constraints, owners and ACL semantics are represented;
3. required Identity Phase 1A roles/ownership are reproducible;
4. the candidate installs cleanly on a blank compatible Supabase project;
5. the candidate's `SCHEMA_EQUIVALENCE_QUERY.sql` result matches `997d3e04bd3e160bc9368f55560cf59a` / 552 object lines, or any intentional difference is explicitly reviewed;
6. application smoke tests pass against the clean installation.

Until then, `production_schema_20260913.sql` must not be labeled executable or canonical.
