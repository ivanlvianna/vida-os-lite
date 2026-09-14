# VIDA OS™ — Planning Content Persistence Status — 2026-09-14

## Status

`PLANNING-CONTENT-PERSISTENCE-GATE-001 = OPEN / CANDIDATE GENERATION ONLY`

Esta branch **não autoriza apply no Supabase**. D3 e produção permanecem sem mutations de Planning Content.

## Branch canônica de trabalho

Branch isolada:

`planning-content-persistence-2026-09-14`

Ela foi criada a partir do commit `1f2d22560e073f199c4f98124000c51745a307f5`, head do PR #9 (`app-services-prereqs-2026-09-14` → `p0-functional-integration`). Portanto contém os três Application Services pré-requisitos já CI-green:

- `GrantAccessWorkflow`
- `RevokeAccessWorkflow`
- `ChangeEngagementStateWorkflow`

O PR #9 permanece separado; esta branch não o altera nem implica merge.

## Baseline físico verificado em leitura

Ambiente dedicado de homologação atual:

- project id: `aregdlspacytbrrdowps`
- nome: `vida-os-homologacao`
- PostgreSQL: 17.6

Confirmado no D3:

- `planning_engagements` possui `UNIQUE (client_account_id, id)`;
- membership física: `client_account_users`;
- `client_account_user_authorizations` preserva histórico e usa `auth.users` com `ON DELETE SET NULL` nos snapshots relevantes;
- helpers canônicos presentes: `is_staff`, `has_engagement_specific_role`, `has_entity_specific_role`, `has_role_in_scope`, `matched_staff_role`, `auth_user_display_label`;
- RPCs existentes: `onboard_client_account_member`, `revoke_client_account_authorization`, `record_planning_engagement_transition`;
- helpers/RPCs críticos usam `SECURITY DEFINER` com `search_path=''`;
- não existe ainda camada física canônica de Provenance / Evidence / Decision Ledger no D3.

Consequência: `PC-M10` continua dependente e não deve ser inventada antecipadamente.

## Planning Content — physical target

Baseline candidato atual:

- persistência tipada, sem EAV universal;
- `Root`, `WorkingDraft`, `DurableVersion` e `LifecycleEvent` separados;
- versions/events append-only;
- drafts tipados com optimistic concurrency;
- integridade same-engagement por FKs compostas quando aplicável;
- escrita canônica por RPC;
- tabelas-base internas staff-only;
- cliente acessa somente projections/read models futuros explicitamente aprovados;
- actor/authorship, computational lineage e evidence provenance permanecem conceitos distintos;
- AI/system assistance nunca substitui autoria profissional.

## Sequência de migrations autorizada para geração

Os arquivos devem ser criados **somente** pelo mecanismo oficial da Supabase CLI:

```bash
supabase migration new pc_m01_planning_content_foundations
supabase migration new pc_m02_planning_content_roots
supabase migration new pc_m03_planning_content_versions
supabase migration new pc_m04_planning_content_children_refs
supabase migration new pc_m05_planning_content_drafts
supabase migration new pc_m06_planning_content_lifecycle_ledgers
supabase migration new pc_m07_planning_content_writers
supabase migration new pc_m08_planning_content_access_surface
supabase migration new pc_m09_planning_content_read_models
```

`PC-M10` não deve ser criada enquanto a dependência física canônica de Provenance/Evidence não existir.

Não inventar timestamps ou filenames de migration manualmente.

## Gate de segurança

Gerar migration candidates não equivale a aplicar.

Antes de qualquer apply são obrigatórios:

1. static review final DDL × physical target × suíte;
2. RLS + ACL deny-by-default desde a mesma transaction que cria cada tabela;
3. revisão específica de todas as funções `SECURITY DEFINER`;
4. advisors/security review;
5. rollback/replay scripts;
6. harness single-session;
7. harness multi-session real para concorrência;
8. confirmação explícita do ambiente de homologação;
9. autorização separada para apply.

Chamadas seriais não podem ser declaradas concurrency PASS.

## Supabase 2026 — nota operacional

O comportamento atual de Data API exige grants explícitos para exposição de novas tabelas em projetos com auto-exposure desabilitado. Isso é compatível com o desenho desta frente: Planning Content nasce deny-by-default e só abre a superfície mínima aprovada em `PC-M08`.

## Bloqueio operacional atual deste ambiente ChatGPT

A branch foi criada via GitHub, mas o terminal desta sessão não possui resolução de rede para clonar o repositório. Por isso, nesta sessão não é legítimo executar `supabase migration new` dentro de um worktree real.

Não contornar esse bloqueio inventando nomes/timestamps via GitHub Contents API.

O próximo executor com worktree/CLI funcional deve:

1. checkout `planning-content-persistence-2026-09-14`;
2. rodar `supabase --version` e `supabase --help`;
3. criar PC-M01..PC-M09 com `supabase migration new`;
4. preencher os candidatos sem link/apply remoto;
5. executar apenas validações locais/estáticas até nova autorização.
