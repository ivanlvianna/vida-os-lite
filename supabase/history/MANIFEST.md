# Migration history manifest — produção

Fonte: `supabase_migrations.schema_migrations` do projeto principal `dlobyyzixcandloxbeth`, inventariado em 2026-09-13.

| Version | Name | SQL MD5 | SQL SHA-256 / status | Observação |
|---|---|---|---|---|
| 20260716005752 | harden_vida_os_lite_rls_and_profiles | 4e34739922b0a97997fa4c2c839455c9 | body archived | histórico Lite |
| 20260727220336 | create_hotmart_operations | 3d12b0cedec1a5a79c11dd00f32a488d | body archived | histórico operacional |
| 20260728020506 | create_scanner_vida_empresa_submissions | 73d75da2e2e3c9eea40d51e9cd2b7853 | body archived | intake legado |
| 20260911032427 | legacy_safety_hardening_auth_fks | b3d77cd7551201547c14b14bd8b14eb0 | body archived | hardening legado |
| 20260912222334 | identity_phase1a_1a5_production_70adae1b | ec71b6ffea682f6ae36ace47d5632fa3 | `70adae1b00c135a220a7116b52f87286ffd94d0bbd59b7803f7ef824f4f62670` — body archived, Git blob `5c8f71dfd8b62a0b8b28d24d214478af7715cc68` | Identity Phase 1A aplicada em produção |
| 20260913013410 | security_hardening_profiles_and_diagnostics | 46e52a492429c490c43d0dd3d1e69ade | body archived | hardening Lite |
| 20260913013519 | create_vida_public_submissions_intake | cae6f02825317a586c9d24f832b7347c | body archived | intake público |

## Regras

Os arquivos desta pasta são forenses: devem refletir o SQL registrado pelo Supabase para migrations já executadas. Não devem ser editados para acomodar um estado futuro.

Para a migration `20260912222334`, o corpo arquivado mede exatamente 83.433 bytes; seu MD5 e SHA-256 coincidem com o ledger de produção, e o SHA-256 também coincide com o hash do artefato `migration_b_identity_phase1.sql` aprovado no Release Gate 3.13 histórico.

A recuperação física está completa em 7/7 migrations. A presença de uma migration aqui, isoladamente, não a torna um bootstrap desde banco vazio; o bootstrap qualificado atual está em `../bootstrap/production_schema_20260913.sql`.
