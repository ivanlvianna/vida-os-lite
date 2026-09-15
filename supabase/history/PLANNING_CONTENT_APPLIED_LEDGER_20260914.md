# VIDA OS™ — Applied Planning Content Migration Ledger — 2026-09-14

## Purpose

Forensic ledger for the Planning Content migrations applied and homologated in:

- project: `aregdlspacytbrrdowps`
- environment: `vida-os-homologacao`

Supabase migration versions below are UTC identifiers dated 2026-09-15. Local homologation date was 2026-09-14 (America/Sao_Paulo).

This file records the remote migration history and the recovered source payloads available after the homologation sequence.

It does **not** claim that the current Git tree already contains an exact one-file-per-remote-migration SQL replay. That reconstruction remains a merge gate.

## Canonical core head before Planning Content

| Version | Name |
|---|---|
| `20260913203935` | `v0_6_clean_install_vida_os_homologacao` |
| `20260913214041` | `v0_7_onboard_client_account_member` |

## Planning Content persistent migrations

| Version | Name | Logical scope |
|---|---|---|
| `20260915003143` | `pc_m01_actor_authorship_infrastructure` | PC-M01 |
| `20260915003214` | `pc_m02_typed_aggregate_roots` | PC-M02 |
| `20260915003446` | `pc_m03_immutable_version_families` | PC-M03 |
| `20260915003521` | `pc_m04_typed_child_reference_tables` | PC-M04 |
| `20260915003603` | `pc_m05_typed_working_drafts` | PC-M05 |
| `20260915003624` | `pc_m06_lifecycle_workflow_ledgers` | PC-M06 |
| `20260915003719` | `pc_m07a_guards_and_immutability_triggers` | PC-M07 guards/triggers |
| `20260915003752` | `pc_m07b_w1_foundation_interview_writers` | PC-M07 W1 |
| `20260915003837` | `pc_m07c1_w2_instruments_synthesis_establish_hypothesis` | PC-M07 W2 part 1 |
| `20260915003908` | `pc_m07c2_w2_corrections_hypothesis_revision_lifecycle` | PC-M07 W2 part 2 |
| `20260915003947` | `pc_m07d1_w3_hypothesis_agenda_writers` | PC-M07 W3 agenda |
| `20260915004019` | `pc_m07d2_w3_diagnostic_session_writers` | PC-M07 W3 sessions |
| `20260915004054` | `pc_m07e1_w4_report_draft_submit` | PC-M07 W4 report draft/submit |
| `20260915004119` | `pc_m07e2_w4_consensus_validate_revision` | PC-M07 W4 consensus/validate/revision |
| `20260915004249` | `pc_m07f1_w5_financial_plan_writers` | PC-M07 W5 plan |
| `20260915004314` | `pc_m07f2_w5_implementation_review_writers` | PC-M07 W5 implementation/review |
| `20260915004352` | `pc_m08_rls_controlled_acl_opening` | PC-M08 |
| `20260915010615` | `pc_performance_targeted_indexes_v1` | 9 targeted indexes |
| `20260915010654` | `pc_m09_staff_read_models_v1` | 12 PC-M09 staff read models |

## Post-PC-M09 freeze-reconciliation migrations

| Version | Name | Logical scope |
|---|---|---|
| `20260915014703` | `pc_freeze_reconcile_a_context_fks` | context/supporting FKs |
| `20260915014719` | `pc_freeze_reconcile_b_sequences_review_exact` | deterministic sequence columns + exact RPM reference |
| `20260915014749` | `pc_freeze_reconcile_c_consensus_actor_helper` | client-consensus ActorStamp helper |
| `20260915014817` | `pc_freeze_reconcile_d_hypothesis_agenda_writers` | sequence-aware hypothesis/agenda writers |
| `20260915014847` | `pc_freeze_reconcile_e_report_consensus_writers` | report/consensus sequence + client path |
| `20260915014913` | `pc_freeze_reconcile_f_review_exact_version_writers` | exact ImplementationEpisodeVersion review writers |
| `20260915014938` | `pc_freeze_reconcile_g_read_models` | PC-M09 sequence/exact-version alignment |
| `20260915014957` | `pc_freeze_reconcile_h_report_revision_and_grants` | report revision/grant alignment |

## Recovered source payloads and hashes

The following local artifacts were used to assemble/apply the homologated Planning Content surface. They are source payloads, not yet a byte-for-byte one-file-per-remote-migration archive.

| Source artifact | SHA-256 |
|---|---|
| `planning-content-pc-m01-executable-candidate-v0.1.sql` | `951ee180d627233670b1ff3645bc69c4a5d003c569696f83423f95038f66bef9` |
| `planning-content-pc-m02-executable-candidate-v0.1.sql` | `69acbeed5c1b3e2c5fea621c5df8ec1f04914a281428cba4d7f4cf0812c5e5f4` |
| `planning-content-pc-m03-executable-candidate-v0.1.sql` | `30852f264fb3c5d514c25c8a9c59760796817db8aad128e3ce9eb6a3cdeb6a17` |
| `planning-content-pc-m04-executable-candidate-v0.1.sql` | `2fd603898686b1ba2db4786073372839a004691fb36dd1d90283b7dfd064a54e` |
| `planning-content-pc-m05-executable-candidate-v0.1.sql` | `9f41de5b0bff6534700a6417ad7d276bd6f0210405d88d1c43f8b10409f2c320` |
| `planning-content-pc-m06-executable-candidate-v0.1.sql` | `6c129f68b94ca2bfa37b75c3395baaa5d772ca32fdd8667025bec0e7a8e5297a` |
| `planning-content-pc-m07-executable-candidate-v0.1.sql` | `0bbdadca9ec5982055c9c2fa2b3386fa091677d99861f9945192169daf37c929` |
| `planning-content-pc-m08-executable-candidate-v0.1.sql` | `411da588d2245ebaf8ddbe14afd44111d34ff79f72c6f060262c63080df4366c` |
| `planning-content-performance-hardening-candidate-v0.1.sql` | `5a3b215d5edba5eb7b67741aa1b93d6fe1a091b781863bcca9927c85cd666b25` |
| `planning-content-pc-m09-read-models-candidate-v0.1.sql` | `a7d89ed6f4d7a508c93d4e9cbe86e0bff90593af1a875800342bab2f23c39f39` |
| `planning-content-post-m09-freeze-reconciliation-candidate-v0.1.sql` | `6885b8d39463f08c57cc0ae2778f25ff32e54b8e3b44fdfc8fdb4f94032ba6fc` |

## Homologation evidence carried by this ledger

The D3 sequence passed:

- physical PostgreSQL compile;
- W1…W5 core behavior: 67/67;
- real multi-session concurrency: 5/5;
- migration assembly/replay;
- persistent PC-M01…PC-M08 homologation;
- PC-M09 read-model homologation;
- real report consensus × validation concurrency in both legal orderings;
- freeze-reconciliation persistent homologation;
- zero fixture residue after post-migration smokes.

## Remaining repository-reproducibility work

Before the PFP Cockpit integration is mergeable:

1. preserve recovered SQL payloads under `supabase/history/`;
2. reconstruct exact submigration payload boundaries where possible;
3. qualify a bootstrap/replay from the canonical core baseline to the current D3 state;
4. verify the reconstructed final catalog against the homologated catalog;
5. only then close `PFP-COCKPIT-MERGE-GATE`.

No future migration should rewrite or disguise the remote versions listed above.
