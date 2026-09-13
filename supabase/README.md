# VIDA OS™ — Supabase schema governance

Este diretório passa a ser a fonte versionada de governança do schema do VIDA OS™.

## Estrutura

- `bootstrap/`: baseline completo capaz de reconstruir um ambiente novo a partir de zero. Não representa a ordem histórica de produção.
- `history/`: cópia forense das migrations já executadas no projeto principal, preservando versão, nome e SQL sempre que recuperável do ledger `supabase_migrations.schema_migrations`.
- `migrations/`: somente migrations canônicas novas daqui em diante. Não reescrever migrations já aplicadas.
- `tests/`: provas SQL de invariantes de identidade, autorização, Planning Engagement, reconciliação e rollback.

## Regras do Gate 0

1. Produção nunca é alterada a partir deste diretório sem migration aprovada e prova em ambiente de ensaio.
2. `auth.users` é credencial/autenticação; não é identidade econômica canônica.
3. `economic_entities` representa identidade econômica canônica.
4. `client_accounts` define o perímetro de relacionamento/autorização.
5. `planning_engagements` representa o ciclo de planejamento.
6. `reconciliation_source` / `reconciliation_record` registram a verdade epistemológica de resolução de identidade.
7. Nenhum backfill de usuários legados é inferido automaticamente.
8. Nenhuma migration Phase 1B pode recriar ou apagar objetos Phase 1A existentes em produção.

## Estado dos gates

- `MIGRATION-APPLY-GATE-001 — Identity Phase 1A`: APPLIED / CLOSED.
- `MIGRATION-APPLY-GATE-002 — Planning Engagement / RBAC-ABAC / VRI`: OPEN.

## Baseline de referência

Projeto principal Supabase: `dlobyyzixcandloxbeth`.

Ambiente de ensaio Phase 1B: `jijdyrinuzyjampptbaf` (`migration-a-phase0-ensaio`).

O conteúdo deste diretório não autoriza por si só qualquer DDL em produção. A promoção ocorre somente após testes de replay, rollback, preservação de dados, RLS/RBAC e advisors.
