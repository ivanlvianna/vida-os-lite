# Codex Handoff — VIDA OS™ Planning Content Persistence — 2026-09-14

## Missão

Continuar a frente `EPIC-PC-001 / Planning Content Persistence` na branch:

`planning-content-persistence-2026-09-14`

Objetivo desta rodada: **gerar e preencher migration candidates PC-M01..PC-M09 e seus harnesses, sem aplicar nada no D3 ou produção**.

## Estado de entrada obrigatório

Antes de modificar qualquer arquivo, confirmar:

```bash
git status --short
git branch --show-current
git rev-parse HEAD
supabase --version
supabase --help
supabase migration --help
supabase migration new --help
```

A branch precisa ser `planning-content-persistence-2026-09-14`.

Ler primeiro:

1. `docs/PLANNING_CONTENT_PERSISTENCE_STATUS_20260914.md`
2. `docs/PLANNING_CONTENT_TOOLCHAIN_GATE_20260914.md`
3. `supabase/README.md`
4. `docs/APPLICATION_SERVICES_PREREQS_STATUS_20260914.md`

Não assumir que `main`, ambientes históricos ou README antigo são fonte corrente.

## Gate vigente

`PLANNING-CONTENT-PERSISTENCE-GATE-001 = OPEN / CANDIDATE GENERATION ONLY`

Isso **não** autoriza:

- `supabase db push`;
- `supabase migration up` contra remoto;
- `execute_sql` DDL remoto;
- `apply_migration`;
- merge em `main`;
- alterações no D3;
- alterações em produção.

## Criação dos migration files

É obrigatório usar Supabase CLI. Não inventar timestamps manualmente.

Executar sequencialmente:

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

Não criar PC-M10: Provenance/Evidence físico canônico ainda não existe no D3.

## Physical design invariants

### Persistência

- typed relational model; sem EAV universal;
- `Root`, `WorkingDraft`, `DurableVersion`, `LifecycleEvent` são objetos distintos;
- versions e events append-only;
- um active draft por root em v1;
- optimistic concurrency para drafts;
- version chain sem forks;
- same-engagement integrity fisicamente enforceable;
- historical professional references apontam para exact versions.

### Segurança

- `public` continua o schema de domínio;
- toda tabela criada em PC-M02..PC-M06 nasce, na mesma transaction, com RLS habilitada e ACL deny-by-default;
- `REVOKE ALL` de `PUBLIC`, `anon`, `authenticated`, `service_role` onde aplicável antes da abertura controlada;
- nenhum INSERT/UPDATE/DELETE direto para application roles;
- canonical writes somente por RPC tipada;
- base reads staff-only;
- client-facing reads somente via projections/read models específicos;
- toda função `SECURITY DEFINER` precisa de `SET search_path = ''`, autenticação/autorização interna e grants mínimos;
- caller nunca fornece/forja actor, role ou label histórico.

### Baseline D3 já verificado

- PostgreSQL 17.6;
- `planning_engagements` possui `UNIQUE(client_account_id, id)`;
- membership física chama-se `client_account_users`;
- authorization history: `client_account_user_authorizations`;
- helpers existentes: `is_staff`, `has_role_in_scope`, `has_engagement_specific_role`, `has_entity_specific_role`, `matched_staff_role`, `auth_user_display_label`;
- RPCs existentes: `onboard_client_account_member`, `revoke_client_account_authorization`, `record_planning_engagement_transition`.

## Migrations

### PC-M01 — Foundations

Somente helpers/guards específicos de Planning Content que não pertençam a outra migration. Nenhuma abertura de acesso de aplicação.

### PC-M02 — Roots

Criar os dez Aggregate Roots tipados:

- InterviewRecord
- InstrumentRun
- DiagnosticSynthesis
- WorkingHypothesis
- HypothesisAgenda
- DiagnosticSession
- DiagnosticReport
- FinancialPlan
- ImplementationEpisode
- ReviewEpisode

Cada root carrega `client_account_id` + `planning_engagement_id` e prova same-engagement contra `planning_engagements(client_account_id,id)`.

### PC-M03 — Versions

Criar as dez famílias de durable version com:

- version identity separada da root identity;
- `version_no >= 1`;
- predecessor opcional;
- no-fork enforcement;
- append-only guards;
- actor snapshot;
- exact account/engagement/root context.

### PC-M04 — Typed children/references

Incluir pelo menos:

- InstrumentRun contributions;
- DiagnosticSynthesis sources ICV/IMDP/IVRP;
- HypothesisProposal local identity;
- AgendaItems;
- SessionHypothesisEntries;
- SessionDecisionNotes sem criar Decision Ledger;
- Report source sessions;
- Report hypothesis refs;
- FinancialPlan goals/strategies/hypothesis refs;
- exact version references para PLAN/PRI/RPM onde estabelecido.

### PC-M05 — Drafts

Drafts tipados para:

- InterviewRecord
- WorkingHypothesis
- HypothesisAgenda
- DiagnosticSession
- DiagnosticReport
- FinancialPlan

`root_id`/equivalente deve garantir no máximo um draft ativo por root em v1. Saves usam expected revision.

### PC-M06 — Lifecycle/workflow ledgers

Append-only ledgers para:

- WorkingHypothesis lifecycle;
- HypothesisAgenda OPEN/CLOSED;
- DiagnosticReport workflow;
- report consensus manifestation.

WorkingHypothesis v1:

`active -> accepted_for_planning | rejected | retired`

`accepted_for_planning -> active | rejected | retired`

`rejected` e `retired` são terminais.

### PC-M07 — Canonical writers

RPCs tipadas por caso de uso; nenhum `write_planning_content(jsonb)` universal.

Writers devem resolver internamente actor/auth uid, authorization, label snapshot e locking.

### PC-M08 — Controlled access surface

Somente aqui abrir SELECT/EXECUTE mínimo aprovado. Nenhum DML direto.

### PC-M09 — Read models

Read models planner/cockpit somente após fontes e enforcement estarem definidos. Client read models devem ser separados e mais estreitos.

## Casos conceituais que NÃO devem ser inventados

Não transformar em constraint física sem decisão posterior:

- HAI obrigatório antes de SESS;
- REL.Validated alterando PlanningEngagement automaticamente;
- PLAN rigidamente bloqueado por REL;
- máximo de hipóteses por PLAN;
- máximo de sessões alimentando REL além do mínimo estabelecido de uma source session;
- RPM criando automaticamente novo ciclo diagnóstico;
- state machines completas de instrumentos/sessões/plano/PRI/RPM;
- Decision Ledger FK enquanto o bounded context físico não existir;
- client collaborative draft;
- AI como author identity.

## Testes mínimos

Construir harnesses para:

- schema/ACL/RLS;
- root context e cross-account/cross-engagement rejection;
- version chain e stale base;
- draft optimistic concurrency;
- InstrumentRun/DiagnosticSynthesis invariants;
- WorkingHypothesis lifecycle;
- HypothesisAgenda exclusividade OPEN;
- sessions;
- reports + consensus;
- FinancialPlan;
- PRI/RPM exact-version history;
- read isolation;
- future provenance extension boundary;
- rollback/replay;
- zero residue.

Concorrência real obrigatória para:

- simultaneous version commits;
- simultaneous draft saves;
- simultaneous OPEN agenda creation;
- consensus/validation races.

**Chamadas serializadas não contam como concurrency PASS.**

## Critério de parada desta rodada

Parar antes de qualquer apply remoto.

Entregar:

1. PC-M01..PC-M09 criadas pela CLI e preenchidas como candidates;
2. harnesses correspondentes;
3. static review DDL × specification × tests;
4. `supabase migration list --local` ou equivalente local suportado pela versão detectada;
5. lint/static SQL checks disponíveis;
6. advisors apenas se puderem ser executados sem alterar o remoto;
7. relatório explícito de blockers;
8. zero mutation no D3 e produção.

Somente uma autorização posterior pode abrir o apply/homologation execution gate.
