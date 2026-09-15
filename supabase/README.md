# VIDA OS™ — Supabase schema governance

Este diretório é a fonte versionada de governança do schema do VIDA OS™. Ele preserva história, baselines e migrations sem permitir que snapshots antigos sejam confundidos com o estado operacional corrente.

## Estrutura

- `bootstrap/`: baseline direto de estado qualificado capaz de reconstruir uma superfície conhecida em ambiente Supabase compatível; não representa a ordem histórica de produção.
- `history/`: cópia forense das migrations já executadas/recuperadas, preservando versão, nome e SQL quando o payload aplicado está disponível.
- `migrations/`: migrations canônicas novas daqui em diante. Migrations já aplicadas nunca são reescritas silenciosamente.
- `tests/`: provas SQL de identidade, autorização, Planning Engagement, replay, rollback e Planning Content.
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

Ambiente dedicado de homologação:

- project id: `aregdlspacytbrrdowps`;
- nome: `vida-os-homologacao`;
- PostgreSQL verificado: 17.6.

O ambiente histórico `jijdyrinuzyjampptbaf` não é o D3 corrente. Referências antigas a outros projetos permanecem apenas como história de implantação.

### Identity + Access + Planning Cycle

- baseline operacional: v0.6;
- evolução v0.7 presente no D3;
- membership física: `client_account_users`;
- authorization history: `client_account_user_authorizations`;
- `planning_engagement` permanece o objeto canônico do ciclo de planejamento.

### Planning Content — estado físico homologado

Planning Content **existe fisicamente** no `vida-os-homologacao`.

Homologado:

- PC-M01…PC-M08 — persistência tipada, drafts, durable versions, lifecycle ledgers, writers e RLS/ACL;
- 9 índices direcionados de leitura/lineage;
- PC-M09 — 12 staff read models com `security_invoker=true`;
- reconciliação pós-PC-M09 com o executable-design freeze;
- full-context predecessor integrity — 10/10 famílias;
- full-context draft-base integrity — 6/6 drafts;
- sequências determinísticas `transition_no`, `event_no` e `manifestation_no`;
- `ReviewEpisodeVersion` referenciando a `ImplementationEpisodeVersion` exata;
- consenso do cliente por RPC estreita, exigindo membership + autorização de engagement + autorização de EconomicEntity;
- concorrência real consenso × validação homologada nos dois ordenamentos legais.

Gates correntes:

- `PLANNING-CONTENT-PERSISTENCE-GATE-001 = PASS (HOMOLOGATION)`;
- `PC-M09-PERSISTENCE-GATE-001 = PASS (HOMOLOGATION)`;
- `PC-FREEZE-RECONCILIATION-CONCURRENCY-GATE-001 = PASS`;
- `PC-FREEZE-RECONCILIATION-PERSISTENCE-GATE-001 = PASS (HOMOLOGATION)`;
- `PC-PERFORMANCE-HARDENING-GATE-001 = OPEN / WORKLOAD-BASED`;
- `PC-M10 = BLOCKED ON CANONICAL PROVENANCE`.

## Superfície Planning Content

A superfície persistente continua deny-by-default:

- nenhum DML direto para papéis de aplicação;
- escrita canônica via RPC tipada;
- tabelas-base internas staff-only;
- PC-M09 é staff-only e preserva RLS por `security_invoker=true`;
- cliente não recebe leitura raw de Planning Content;
- o ato estreito de consenso do cliente não implica acesso aos read models staff;
- `SECURITY DEFINER` exige `search_path=''`, autorização interna e grants mínimos;
- root/version/draft/event permanecem objetos distintos;
- versions e ledgers históricos são append-only;
- AI/system assistance não substitui autoria profissional.

## Bounded contexts ainda não materializados nesta frente

Planning Content não deve inventar ou absorver antecipadamente:

- PC-M10 / Provenance-Evidence físico canônico;
- Decision Ledger físico;
- Financial Reality / Temporal;
- Documents/Evidence;
- projeções client-facing amplas;
- produção/deploy do PFP Cockpit.

## Branch de integração do PFP Cockpit

A integração de leitura está sendo feita em:

`pfp-cockpit-read-integration-2026-09-14`

Essa branch parte de `planning-content-persistence-2026-09-14`, que por sua vez está linearmente à frente de `app-services-prereqs-2026-09-14`. Portanto ela preserva os Application Services pré-requisitos e a documentação Planning Content sem merge prematuro em `main`.

A camada de aplicação do Cockpit usa cliente Supabase de sessão e consulta exclusivamente os PC-M09 read models. Ela **não usa `service_role` para leitura** e não replica regras de autorização que pertencem ao PostgreSQL/RLS.

## Drift de histórico SQL — gate antes de merge

O D3 avançou durante a homologação por migrations aplicadas diretamente no ambiente, enquanto a árvore Git ainda não contém uma cópia forense completa, um-a-um, de todos os payloads Planning Content aplicados.

Consequência:

`PFP-COCKPIT-MERGE-GATE = BLOCKED ON APPLIED-SQL HISTORY SYNC`

Antes de merge da integração, é obrigatório:

1. registrar em `history/` o ledger completo de versões/names aplicados;
2. preservar os SQL sources recuperados que deram origem a PC-M01…PC-M09 e à reconciliação;
3. qualificar/recriar um bootstrap capaz de reproduzir o estado corrente a partir da baseline oficial;
4. executar lint/build da branch de aplicação em runner com dependências disponíveis;
5. manter `main` e produção intocados até aprovação separada.

Esse bloqueio é de reprodutibilidade/governança do repositório; não invalida a homologação já concluída do banco.

## Fonte de verdade para retomada

Ao retomar esta frente, conferir nesta ordem:

1. este README;
2. `docs/PLANNING_CONTENT_PERSISTENCE_STATUS_20260914.md`;
3. branch/PR atuais;
4. estado do `vida-os-homologacao` em leitura;
5. ledger de migrations aplicadas;
6. gates vigentes.

Nenhum documento, por si só, constitui autorização para nova mutation remota.
