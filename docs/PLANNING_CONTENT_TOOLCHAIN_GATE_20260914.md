# VIDA OS™ — Planning Content Toolchain Gate — 2026-09-14

## Status

`PC-TOOLCHAIN-GATE-001 = OPEN / BLOCKS MIGRATION FILE CREATION`

Este gate não bloqueia arquitetura, revisão estática ou documentação. Ele bloqueia somente a criação legítima dos arquivos PC-M01..PC-M09 enquanto a Supabase CLI do executor não estiver identificada.

## Evidência do repositório

O `package.json` da branch `planning-content-persistence-2026-09-14` fixa os SDKs Supabase, mas não contém a Supabase CLI como `devDependency`.

Portanto a versão da CLI não pode ser inferida do repositório.

## Regra

Antes de criar a primeira migration candidate, o executor deve registrar:

```bash
supabase --version
supabase --help
supabase migration --help
supabase migration new --help
```

Se a CLI não estiver instalada, instalar/fixar uma versão deliberadamente no ambiente de desenvolvimento antes da geração. Não alterar `package.json`/lockfile apenas para contornar este gate sem revisão específica de toolchain.

## Geração

Somente depois da identificação da CLI:

```bash
supabase migration new pc_m01_planning_content_foundations
```

O nome/timestamp retornado pela própria CLI passa a ser o primeiro migration candidate. Repetir sequencialmente para PC-M02..PC-M09.

## Proibições

- não criar filenames manualmente;
- não copiar timestamps de exemplos;
- não usar GitHub Contents API para fabricar arquivos sob `supabase/migrations/` antes da CLI;
- não linkar o projeto remoto apenas para gerar nomes;
- não executar `db push`, `migration up`, `execute_sql` DDL ou qualquer apply remoto;
- não criar PC-M10 enquanto Provenance/Evidence físico canônico estiver ausente.

## Supabase 2026

A documentação corrente confirma `supabase migration new <name>` como mecanismo oficial de criação do arquivo e mantém migrations em `supabase/migrations/` com padrão `<timestamp>_<name>.sql`.

O changelog de 2026 também alterou o comportamento de autoexposição de novas tabelas à Data API. Isso reforça a necessidade de grants explícitos e não altera a estratégia deny-by-default já definida para Planning Content.

## Critério de fechamento

`PC-TOOLCHAIN-GATE-001` fecha quando existir evidência registrada de:

1. versão da Supabase CLI;
2. help/command surface compatível;
3. worktree na branch correta;
4. primeiro arquivo PC-M01 criado pela própria CLI.

Fechar este gate não autoriza apply no D3.
