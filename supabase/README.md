# VIDA OS™ — Supabase schema governance

Este diretório é a fonte versionada de governança do schema do VIDA OS™.

## Estrutura

- `bootstrap/`: baseline direto de estado atual capaz de reconstruir a superfície de aplicação em um ambiente Supabase compatível. Não representa a ordem histórica de produção.
- `history/`: cópia forense das migrations já executadas no projeto principal, preservando versão, nome e SQL do ledger `supabase_migrations.schema_migrations`.
- `migrations/`: migrations canônicas novas daqui em diante. Migrations já aplicadas não são reescritas.
- `tests/`: provas SQL de identidade, autorização, Planning Engagement, reconciliação, replay e rollback.

## Regras de governança

1. Produção nunca é alterada a partir deste diretório sem migration aprovada, preflight explícito e prova em ambiente de ensaio.
2. `auth.users` é credencial/autenticação; não é identidade econômica canônica.
3. `economic_entities` representa identidade econômica canônica.
4. `client_accounts` define o perímetro de relacionamento/autorização.
5. `planning_engagements` representa o ciclo de planejamento.
6. `reconciliation_source` / `reconciliation_record` registram a verdade epistemológica de resolução de identidade.
7. Nenhum backfill de usuários legados é inferido automaticamente.
8. Nenhuma migration Phase 1B pode recriar ou apagar objetos Phase 1A existentes em produção.
9. Um baseline qualificado é versionado; mudanças futuras exigem nova migration e nova qualificação, nunca edição silenciosa do baseline anterior.

## Estado atual dos gates

- `MIGRATION-APPLY-GATE-001 — Identity Phase 1A`: **APPLIED / CLOSED**.
- recuperação histórica Gate 0: **7/7 ARCHIVED / CLOSED**.
- bootstrap standalone Gate 0 (`bootstrap/production_schema_20260913.sql`): **QUALIFIED / CLOSED para o baseline de 2026-09-13**.
- qualificação técnica Gate 002 — Planning Engagement / RBAC-ABAC / VRI: **PASS em ensaio**.
- `MIGRATION-APPLY-GATE-002 — produção`: **OPEN / NOT AUTHORIZED**.

## Baseline de referência

Projeto principal Supabase: `dlobyyzixcandloxbeth`.

Ambiente de ensaio zero-cost: `jijdyrinuzyjampptbaf` (`migration-a-phase0-ensaio`).

O conteúdo deste diretório não autoriza por si só qualquer DDL em produção nem merge para `main`.
