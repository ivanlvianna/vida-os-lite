# Product Core v0.5.2 — Recovery Manifest

Status: **EXACT VALIDATED ARCHIVE RECOVERED / FRESH TEST PASS / SOURCE IMPORT PENDING**  
Date: 2026-09-14

## Recovered canonical artifact

The exact historical Product Core archive was recovered from the user Library, nested inside the historical package `files (7)(1).zip` created on 2026-09-11.

Repository copy:

`vendor/product-core-v0.5.2/amortizar-investir-core.zip`

Identity checks:

- archive MD5: `78f7b0d877b3c8128048d9b286023217`
- Git blob SHA: `1f7e79ffda358aa23a2a3bbc5411499176233df0`
- package name: `amortizar-investir-core`
- package version: `0.5.2`
- test suites declared by the package: **16**

Known component checks independently match the historical validation record:

- `src/mapeador-conceitos.ts` MD5: `3380644cbccab853aa05065a3edd50fc`
- `src/adaptador-llm.ts` MD5: `0b5d1a512804078d566a402c74b69da1`

This establishes byte-level recovery of the previously validated v0.5.2 archive; no Product Core implementation was reconstructed from prose.

## Frozen v0.5.2 boundary observed in package metadata

The package itself identifies v0.5.2 as the **Concept-Only LLM Boundary**. The LLM request surface contains only concept-level inputs, while the deterministic Product Core retains ownership of factual calculations, financial conclusion, summary/scenario and cent-precision monetary outputs.

## Fresh recovery verification

The exact recovered archive was extracted and its declared 16-suite test command was executed locally without modifying engine source.

Observed result: **PASS / exit code 0**.

The final v0.5.2 Concept-Only LLM Boundary suite reported **23 passed / 0 failed**, including the mandatory checks that the LLM receives only the reduced concept request and cannot rewrite the deterministic summary or factual central scenario. The preceding deterministic suites in the same run also completed with zero failures.

A separate `tsc --noEmit` attempt did **not** produce a valid typecheck result because the local dependency install was incomplete: `@types/node` was left invalid/missing after the package-install command exceeded the execution environment timeout. This is recorded as an **environment/dependency-install verification pending item**, not as an engine type error. No source change was made to suppress it.

Historical canonical qualification remains **245/245**.

## Integration rule

The ZIP is archived here for provenance and byte identity. The application must not execute the ZIP directly in production.

Before Product Core becomes part of the P0 runtime, its exact source tree must be imported from this archive without semantic edits, and the imported source must be checked against this archive plus its original test/typecheck surface.

Any VIDA OS adapter/repository code must live outside the frozen engine and depend on its exported contract rather than modifying the engine to fit the application.

## Persistence relationship

See `docs/P0_PRODUCT_CORE_PERSISTENCE_CONTRACT.md` and `docs/P0_PRODUCT_CORE_V052_INTEGRATION_MAP.md`.

The canonical VIDA OS integration anchors financial projection compatibility to `EconomicEntity` and binds each P0 execution/result to the explicit `economic_entity_id + client_account_id + planning_engagement_id` context. The legacy login-centric `profiles` identity model is not reinstated.
