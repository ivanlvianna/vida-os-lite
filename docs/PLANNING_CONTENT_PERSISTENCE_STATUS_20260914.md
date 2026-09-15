# VIDA OS™ — Planning Content Persistence Status — 2026-09-14

## Status executivo

Planning Content não está mais em fase de candidate generation only.

Estado homologado no `vida-os-homologacao`:

- `PLANNING-CONTENT-PERSISTENCE-GATE-001 = PASS (HOMOLOGATION)`
- `PC-M09-PERSISTENCE-GATE-001 = PASS (HOMOLOGATION)`
- `PC-FREEZE-RECONCILIATION-CONCURRENCY-GATE-001 = PASS`
- `PC-FREEZE-RECONCILIATION-PERSISTENCE-GATE-001 = PASS (HOMOLOGATION)`
- `PC-PERFORMANCE-HARDENING-GATE-001 = OPEN / WORKLOAD-BASED`
- `PC-M10 = BLOCKED ON CANONICAL PROVENANCE`

Isso não autoriza produção, merge em `main` ou criação especulativa dos bounded contexts ainda ausentes.

## Linhagem Git

- `app-services-prereqs-2026-09-14` — Application Services pré-requisitos;
- `planning-content-persistence-2026-09-14` — documentação/candidates Planning Content, linearmente à frente da branch de Application Services;
- `pfp-cockpit-read-integration-2026-09-14` — integração de leitura do PFP Cockpit sobre PC-M09.

A branch de integração não implica merge e não altera produção.

## Ambiente homologado

- project id: `aregdlspacytbrrdowps`
- nome: `vida-os-homologacao`
- PostgreSQL: 17.6

Baseline core:

- v0.6 oficial;
- v0.7 presente;
- membership: `client_account_users`;
- authorization history: `client_account_user_authorizations`;
- ciclo canônico: `planning_engagement`.

## Planning Content persistente

Homologado fisicamente:

- 51 tabelas Planning Content;
- writers canônicos W1…W5;
- 74 triggers/guards de imutabilidade na instalação inicial;
- RLS/ACL deny-by-default;
- 9 índices direcionados;
- 12 staff read models PC-M09 com `security_invoker=true`.

A reconciliação pós-PC-M09 também está persistida:

- predecessor FKs com contexto completo em 10/10 famílias;
- draft base-version FKs com contexto completo em 6/6 drafts;
- `transition_no` para WorkingHypothesis;
- `transition_no` para HypothesisAgenda;
- `event_no` para DiagnosticReport workflow;
- `manifestation_no` para report consensus;
- ReviewEpisodeVersion referencia a ImplementationEpisodeVersion exata;
- consenso do cliente exige membership + autorização específica de engagement + autorização específica de EconomicEntity;
- helper interno de ActorStamp do consenso não é executável por `authenticated`;
- concorrência real consenso × validação passou nos dois ordenamentos legais.

## PC-M09 — staff read layer

Read models homologados:

1. `pc_rm_interview_current`
2. `pc_rm_instrument_current`
3. `pc_rm_synthesis_current`
4. `pc_rm_working_hypothesis_current`
5. `pc_rm_open_agenda_current`
6. `pc_rm_session_current`
7. `pc_rm_report_current`
8. `pc_rm_plan_current`
9. `pc_rm_implementation_current`
10. `pc_rm_review_current`
11. `pc_rm_engagement_content_summary`
12. `pc_rm_engagement_timeline`

Todos preservam o RLS do caller por `security_invoker=true`.

Cliente não recebe acesso a essa camada. O consenso client-side é uma capability estreita de escrita e não altera a separação staff/client.

## Integração de aplicação PFP Cockpit

Na branch `pfp-cockpit-read-integration-2026-09-14` foram introduzidos:

- contrato TypeScript explícito das 12 views PC-M09;
- adapter de leitura Planning Content usando `SupabaseClient` autenticado da sessão;
- `listPfpCockpitsWorkflow`;
- `loadPfpCockpitWorkflow`;
- rota `/dashboard/pfp` para listar apenas ciclos visíveis via RLS;
- rota `/dashboard/pfp/[planningEngagementId]` para o Cockpit read-only;
- UI sem inferir um único relatório/plano/implementação/revisão “principal” por ordem ou data;
- separação explícita dos bounded contexts ainda ausentes.

Regra arquitetural da integração:

`Session client → PC-M09 security-invoker views → base-table RLS`

Não usar `service_role` para leitura do Cockpit.

## Drift de repositório detectado

A governança do repositório prevê:

- `history/` para cópia forense de migrations já aplicadas/recuperadas;
- `bootstrap/` para baseline qualificado reproduzível;
- `migrations/` para novas migrations canônicas.

Durante a homologação, o D3 avançou mais rápido que essa preservação Git. O banco está homologado, mas a árvore Git ainda não contém uma cópia forense completa dos SQL payloads Planning Content aplicados.

Por isso:

`PFP-COCKPIT-MERGE-GATE = BLOCKED ON APPLIED-SQL HISTORY SYNC`

Antes de merge:

1. registrar ledger completo de versions/names aplicados;
2. preservar os SQL sources recuperados em `supabase/history`;
3. qualificar bootstrap/replay da baseline corrente;
4. rodar lint/build em runner com dependências;
5. revisar diff final antes de qualquer PR/merge.

## Performance

O advisor ainda aponta dívida de índices/FKs. Esse débito permanece separado sob:

`PC-PERFORMANCE-HARDENING-GATE-001 = OPEN / WORKLOAD-BASED`

Não criar índices em massa apenas para zerar linter. A seleção continua condicionada aos query shapes reais e telemetria de workload.

## Dependências deliberadamente fora desta frente

Não inventar antes da definição canônica:

- PC-M10 / Provenance-Evidence físico;
- Decision Ledger físico;
- Financial Reality / Temporal;
- Documents/Evidence;
- client-facing read models amplos;
- produção/deploy do PFP Cockpit.

## Próximo passo técnico

Sincronizar a evidência/history SQL aplicada com o repositório e qualificar o bootstrap. Só depois fechar lint/build da branch do Cockpit e preparar PR de integração.
