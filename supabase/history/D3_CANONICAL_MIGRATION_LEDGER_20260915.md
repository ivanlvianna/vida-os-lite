# D3 Canonical Migration Ledger — 2026-09-15

Source of truth: `supabase_migrations.schema_migrations` in Supabase project `vida-os-homologacao` (`aregdlspacytbrrdowps`).

This file records the exact applied migration sequence and the MD5 fingerprint of each migration's stored SQL statement. It is evidence only; it does not authorize or perform any schema change.

Full canonical history: **30 migrations**, deterministic wrapped-script size **330325 bytes**, wrapped-script MD5 **9803080cb70257ff02f4cfa4f6249415**.

Planning Content subset (from `20260915003143` onward): **28 migrations**, wrapped-script size **259251 bytes**, wrapped-script MD5 **3ba49601811307725c9e19aba790f68e**.

| # | Version | Name | SQL bytes | SQL MD5 |
|---:|---|---|---:|---|
| 1 | 20260913203935 | v0_6_clean_install_vida_os_homologacao | 67574 | 55c4ed52f6a6a1480c738574e93370c6 |
| 2 | 20260913214041 | v0_7_onboard_client_account_member | 3292 | 00b66beff0b48e3a493231cdd329ca1f |
| 3 | 20260915003143 | pc_m01_actor_authorship_infrastructure | 2738 | c2d19c8958952391985d2ee882c772a3 |
| 4 | 20260915003214 | pc_m02_typed_aggregate_roots | 10377 | c385096cfe0503207f500ae40ae58d39 |
| 5 | 20260915003446 | pc_m03_immutable_version_families | 22039 | 5bcd1ab4fb05b8c8dc8e749a6d4b9f95 |
| 6 | 20260915003521 | pc_m04_typed_child_reference_tables | 13677 | c34826fddfdae6cf0d1d9a0a9b598174 |
| 7 | 20260915003603 | pc_m05_typed_working_drafts | 16887 | 07c7d84f3cee906aa89df1d7d7ba6cca |
| 8 | 20260915003624 | pc_m06_lifecycle_workflow_ledgers | 5259 | cc64f819c15dc186d1d99c6bd166302d |
| 9 | 20260915003719 | pc_m07a_guards_and_immutability_triggers | 14138 | 3d12dc905cce70e99ea2d0208c297aba |
| 10 | 20260915003752 | pc_m07b_w1_foundation_interview_writers | 11298 | 5db8659a09ab729d7767fe0865d2a4a9 |
| 11 | 20260915003837 | pc_m07c1_w2_instruments_synthesis_establish_hypothesis | 8786 | 38cd4c6914c340be5c8ec6f0eaab88ba |
| 12 | 20260915003908 | pc_m07c2_w2_corrections_hypothesis_revision_lifecycle | 11140 | f2d3ae6228607bb5678f77b477bb43a3 |
| 13 | 20260915003947 | pc_m07d1_w3_hypothesis_agenda_writers | 12375 | 2fac69e1caf2c8652a0d3245bdae0674 |
| 14 | 20260915004019 | pc_m07d2_w3_diagnostic_session_writers | 11882 | 5189baa8cdb42f23e13df60871048ca5 |
| 15 | 20260915004054 | pc_m07e1_w4_report_draft_submit | 10254 | 118f1f0339e1bbcfc47e50da4999fae0 |
| 16 | 20260915004119 | pc_m07e2_w4_consensus_validate_revision | 8074 | 5b8dfa598bfec45a79cc0fe1db66931a |
| 17 | 20260915004249 | pc_m07f1_w5_financial_plan_writers | 13771 | bd87442c05c7325c37a88fd4cff570f9 |
| 18 | 20260915004314 | pc_m07f2_w5_implementation_review_writers | 9757 | 30338783ee731731b5966c132ef321f2 |
| 19 | 20260915004352 | pc_m08_rls_controlled_acl_opening | 6090 | e8d892cc5dabbddae071261dc66f0c93 |
| 20 | 20260915010615 | pc_performance_targeted_indexes_v1 | 1469 | 95cf1962dfec09bb69bdc07587c8da3b |
| 21 | 20260915010654 | pc_m09_staff_read_models_v1 | 17510 | cadb313cf9f04c214f099810ed3130b4 |
| 22 | 20260915014703 | pc_freeze_reconcile_a_context_fks | 8427 | 2b8f683ca4bc4540e5ea8f1201dd0390 |
| 23 | 20260915014719 | pc_freeze_reconcile_b_sequences_review_exact | 2732 | 1c0df9d73520276bd33050b7ee249a48 |
| 24 | 20260915014749 | pc_freeze_reconcile_c_consensus_actor_helper | 3238 | 84ee94803ff3d527e2efb4f1bde938da |
| 25 | 20260915014817 | pc_freeze_reconcile_d_hypothesis_agenda_writers | 8059 | 8b282b118bf20557e78732676960ad1f |
| 26 | 20260915014847 | pc_freeze_reconcile_e_report_consensus_writers | 8875 | 6a023001bc88ce43be6016e2ec31f3cd |
| 27 | 20260915014913 | pc_freeze_reconcile_f_review_exact_version_writers | 5184 | 9efab99861f9d6f3694d54cdc21eef5a |
| 28 | 20260915014938 | pc_freeze_reconcile_g_read_models | 5388 | e69d79662aca25b549e94cb96a01b549 |
| 29 | 20260915014957 | pc_freeze_reconcile_h_report_revision_and_grants | 4093 | 92838a9159925ea33613d377cb223353 |
| 30 | 20260915022715 | pc_m09_staff_summary_visibility_fix | 2757 | ad3e1bef37e6a75ebc4ca0d1761ccd08 |

## Reproducibility rule

An independent replay is PASS only if:

1. it uses this exact ordered history or SQL verified against these per-migration fingerprints;
2. it runs in a disposable PostgreSQL environment, not in D3;
3. it stops on the first migration failure;
4. the resulting Planning Content catalog matches the D3 catalog oracle deterministically;
5. no permanent D3 schema change is made by the proof.

Earlier proof attempts based on connector-transported `.gz` / `.tar.gz` artifacts are superseded as transport-invalid and are not evidence of migration failure.