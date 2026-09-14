# VIDA OS™ — Product Core v0.5.2 Integration Map

Status: **SOURCE-RECOVERED / RUNTIME CONTRACT MAPPED / NO PRODUCTION DDL**  
Date: 2026-09-14  
Artifact: `vendor/product-core-v0.5.2/amortizar-investir-core.zip`  
Artifact MD5: `78f7b0d877b3c8128048d9b286023217`

## 1. Exact engine entry point

The recovered v0.5.2 source exports the canonical deterministic entry point:

```ts
analisarAmortizarOuInvestir(
  entradaBruta: EntradaProdutoAmortizarInvestir
): ResultadoAnaliseAmortizarOuInvestir
```

Its orchestration is explicitly:

```text
normalizarEntrada
→ criarContextoAvaliacao
→ otimizar
→ classificarResultadoVida
```

No VIDA OS adapter is allowed to reimplement those stages.

## 2. Exact raw input contract

`EntradaProdutoAmortizarInvestir` contains:

```text
divida
  saldoDevedor: Centavos
  taxaAnual: number
  sistema: SistemaAmortizacao
  prazoRemanescenteMeses: number

valorDisponivelParaDecisao: Centavos

alternativa
  retornoEsperadoAnual: number
  regimeTributario: RegimeTributario
  posicaoExistente? {
    saldoAtual: Centavos
    custoAquisicao: Centavos
    idadeAproximadaMeses: number
  }

liquidez
  disponivelHoje: Centavos
  reservaMinima:
    | { tipo: "valor"; valor: Centavos }
    | { tipo: "meses"; meses: number; despesaEssencialMensal: Centavos }

horizonte
  | { tipo: "vencimento_divida" }
  | { tipo: "meses"; meses: 12 | 24 | 60 }
  | { tipo: "personalizado"; meses: number }

fracaoAmortizarEstadoD?: number
```

`Centavos` remains the engine monetary unit. The application adapter must convert transport/storage values into the exact bigint-cent representation expected by the core; it must not route financial calculations through floating-point currency values.

## 3. Internal result vs public DTO

The deterministic engine returns `ResultadoAnaliseAmortizarOuInvestir`, containing normalized input, evaluation context, optimizer result and final VIDA classification.

For application persistence/display, v0.5.2 already exports the canonical public DTO builder:

```ts
construirResultadoPublico(
  resultado: ResultadoAnaliseAmortizarOuInvestir
): ResultadoPublicoAmortizarInvestir
```

P0 should persist the canonical public DTO as the product result snapshot rather than inventing a competing summary.

The public DTO includes:

- policy/core versions;
- key normalized input facts;
- `conclusao.classificacao`;
- optional non-calculable reason;
- `acaoIndicada`, explicitly null where policy forbids an actionable conclusion;
- materiality, distance and robustness when present;
- factual central-scenario result;
- economic allocation and optimization diagnostics when applicable.

Money exposed by the public DTO is formatted by Product Core as an exact decimal string, never as floating-point BRL.

## 4. Deterministic explanatory chain

The recovered core also defines the deterministic explanation path:

```text
ResultadoPublicoAmortizarInvestir
→ construirExplicacaoEstruturada(...)
→ renderizarExplicacaoDeterministica(...)
```

`renderizarExplicacaoDeterministica` returns the canonical professional pt-BR rendering, including deterministic summary, fundamentals, caveats and factual central scenario where available.

P0 must not ask an LLM to rewrite this deterministic content.

## 5. Concept-only LLM boundary

v0.5.2 exports:

```ts
gerarComplementoConceitualV1(
  explicacao,
  renderizacao,
  executor
)
```

The LLM receives neither the structured explanation nor the deterministic rendering. Product Core first maps the result to didactic concept codes and constructs a concept-only request.

The frozen rule is:

- deterministic summary: never LLM-authored;
- factual central scenario: never LLM-authored;
- deterministic fundamentals/caveats: never LLM-authored;
- financial conclusion/winner: never sent for narrative rewriting;
- LLM may only complement mapped didactic concepts;
- invalid/failed LLM output falls back to canonical deterministic content.

P0 can therefore ship the first E2E without requiring an LLM at all. The deterministic path is sufficient for acceptance.

## 6. Minimal P0 runtime pipeline

The application-layer pipeline is frozen as:

```text
CurrentPrincipal
→ resolved EconomicEntity / ClientAccount / PlanningEngagement
→ load/collect Product Core input facts
→ adapter builds EntradaProdutoAmortizarInvestir
→ analisarAmortizarOuInvestir
→ construirResultadoPublico
→ construirExplicacaoEstruturada
→ renderizarExplicacaoDeterministica
→ persist immutable Product Core execution snapshot
→ reload through authenticated/RLS read path
→ render inside same PlanningEngagement
```

Optional concept-only LLM enrichment is **not** on the critical path for the first P0 acceptance.

## 7. Minimal persistence payload classes

The physical model still requires a separate candidate/rehearsal gate, but the exact source now lets P0 distinguish what must be preserved.

At minimum, an immutable execution record needs:

### Canonical context

- `economic_entity_id`
- `client_account_id`
- `planning_engagement_id`

### Engine identity

- product = `amortizar-investir`
- Product Core version = `0.5.2`
- artifact/engine fingerprint sufficient to distinguish this exact frozen engine

### Reproducibility input snapshot

An exact serialization of the raw Product Core input contract, with monetary values represented losslessly. JSON transport may encode bigint cents as canonical decimal strings; parsing back into bigint is the adapter's responsibility.

### Deterministic output snapshot

- canonical `ResultadoPublicoAmortizarInvestir`;
- deterministic structured explanation and/or deterministic rendering required by the UI;
- execution timestamp and immutable execution identifier.

The snapshots belong in a **dedicated Product Core execution/result object**, not as generic JSON columns added to `planning_engagements`.

## 8. Idempotency candidate

The physical candidate should derive a stable request fingerprint from:

```text
product
+ engine version/fingerprint
+ economic_entity_id
+ client_account_id
+ planning_engagement_id
+ canonical serialized Product Core raw input
```

This allows an identical retry to resolve to the existing execution while changed input or engine version creates a new immutable execution.

The exact hash algorithm/storage constraint remains part of the physical candidate gate, not this source-map document.

## 9. Isolation invariant

Every read or write of an execution/result must remain within the account/engagement authorization boundary. Possession of an execution UUID alone is never authorization.

P0 negative acceptance must prove that another authenticated user/account cannot read, overwrite, rebind or infer the result through the canonical application surface.

## 10. Next implementation step

With exact source recovery complete, the next safe code step is:

1. import the recovered v0.5.2 source tree without semantic modification;
2. add a VIDA OS adapter outside the engine that performs bigint/string transport conversion;
3. add an application service that receives a resolved canonical context and invokes the deterministic pipeline;
4. create the **minimal Product Core execution persistence candidate** in Git/rehearsal only;
5. prove apply/test/rollback/replay and cross-account RLS isolation before any production DDL request.
