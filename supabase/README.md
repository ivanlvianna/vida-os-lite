# VIDA OS™ — Supabase schema governance

Este diretório é a fonte versionada de governança do schema do VIDA OS™. Ele preserva história, baselines e migrations sem permitir que snapshots antigos sejam confundidos com o estado operacional corrente.

## Estrutura

- `bootstrap/`: baseline direto de estado qualificado capaz de reconstruir uma superfície conhecida em ambiente Supabase compatível; não representa a ordem histórica de produção.
- `history/`: cópia forense das migrations já executadas/recuperadas, preservando versão, nome e SQL.
- `migrations/`: migrations canônicas novas daqui em diante. Migrations já aplicadas nunca são reescritas silenciosamente.
- `tests/`: provas SQL de identidade, autorização, Planning Engagement, replay, rollback e futuras provas de Planning Content.
- `types/`: contratos/tipos auxiliares versionados.

## Regras permanentes de governança

1. Nenhum ambiente Supabase é alterado a partir deste diretório sem migration aprovada, preflight explícito e prova em ambiente de homologação.
2. `auth.users` é credencial/autenticação; não é identidade econômica canônica.
3. `economic_entities` representa identidade econômica canônica.
4. `client_accounts` define o perímetro de relacionamento/autorização.
5. `planning_engagements` representa o ciclo de planejamento.
6. Histórico profissional referenciado não é sobrescrito silenciosamente.
7. Nenhum backfill ou vínculo de identidade é inferido automaticamente sem contrato explícito.
8. Migrations aplicadas/históricas não são reescritas; evolução exige nova migration.
9. Baselines qualificados são versionados; uma nova qualificação não apaga a anterior.
10. Concorrência só recebe `PASS` quando testada com sessões PostgreSQL realmente simultâneas.

## Estado operacional corrente — 14/09/2026

A fotografia corrente desta branch está documentada em:

`docs/PLANNING_CONTENT_PERSISTENCE_STATUS_20260914.md`

### Linhagem de aplicação

- base funcional: `p0-functional-integration`;
- PR #9: `app-services-prereqs-2026-09-14` → `p0-functional-integration`;
- branch isolada de Planning Content: `planning-content-persistence-2026-09-14`.

A branch de Planning Content foi criada a partir do head validado do PR #9 para preservar os três Application Services pré-requisitos sem exigir merge prematuro.

### Ambiente dedicado de homologação atual

- project id: `aregdlspacytbrrdowps`;
- nome: `vida-os-homologacao`;
- PostgreSQL verificado: 17.6.

O antigo ambiente `jijdyrinuzyjampptbaf` pertence à linha histórica/arquivada e não deve ser tratado como D3 corrente.

Referências antigas a `dlobyyzixcandloxbeth` e a gates anteriores permanecem relevantes como história de implantação, mas não são autorização para target/apply no trabalho corrente.

## Baseline arquitetural relevante

- VIDA OS Identity + Access + Planning Cycle: baseline operacional v0.6;
- evolução v0.7 está fisicamente presente no D3 e possui seis casos funcionais homologados; concorrência real do Caso 7 continua pendente de evidência multi-session;
- Application Services `GrantAccessWorkflow`, `RevokeAccessWorkflow` e `ChangeEngagementStateWorkflow` estão implementados e CI-green na linhagem do PR #9;
- Planning Content possui especificação normativa e modelo de persistência candidato; ainda não existe fisicamente no D3.

## Planning Content Persistence Gate

`PLANNING-CONTENT-PERSISTENCE-GATE-001 = OPEN / CANDIDATE GENERATION ONLY`

Isso autoriza somente:

- geração de migration candidates;
- harnesses e testes;
- revisão estática;
- advisors/security review;
- rollback/replay planning.

Isso **não** autoriza:

- apply no D3;
- mutation em produção;
- merge em `main`;
- relaxamento de RLS/ACL para facilitar testes;
- acesso raw de cliente às tabelas internas;
- criação especulativa de Provenance/Decision Ledger ausentes.

## Sequência Planning Content

Migration candidates devem ser criados com Supabase CLI, nunca por timestamp inventado manualmente:

1. `PC-M01` — Foundations
2. `PC-M02` — Roots
3. `PC-M03` — Versions
4. `PC-M04` — Child/reference tables
5. `PC-M05` — Drafts
6. `PC-M06` — Lifecycle/workflow ledgers
7. `PC-M07` — Canonical writers
8. `PC-M08` — Controlled access surface
9. `PC-M09` — Read models
10. `PC-M10` — Provenance extension, somente quando a dependência canônica existir fisicamente

## Segurança da superfície Planning Content

O desenho aprovado para geração candidata é deny-by-default:

- novas tabelas nascem com RLS + ACL fechadas na mesma transaction;
- nenhum DML direto para papéis de aplicação;
- escrita canônica via RPC tipada;
- base read staff-only;
- cliente recebe projections/read models específicos e estreitos;
- `SECURITY DEFINER` exige `search_path=''`, autorização interna explícita e grants mínimos;
- root/version/draft/event permanecem objetos distintos;
- versões e ledgers históricos são append-only;
- cross-engagement references devem falhar estruturalmente;
- Provenance/evidence e autoria permanecem separados.

## Data API

O comportamento atual da Supabase para novas tabelas pode exigir grants explícitos para exposição à Data API. Isso não substitui RLS e é compatível com este desenho: Planning Content não deve ser automaticamente exposto; a superfície é aberta apenas de forma explícita e mínima em `PC-M08`.

## Fonte de verdade para retomada

Ao retomar esta frente, não derivar target de ambiente ou status de gate a partir de commits/documentos históricos isolados. Conferir primeiro:

1. `docs/PLANNING_CONTENT_PERSISTENCE_STATUS_20260914.md`;
2. branch/PR atuais;
3. estado do D3 em leitura;
4. migrations já existentes;
5. gate vigente.

Este README descreve governança e estado de retomada. Ele não constitui autorização de apply por si só.
