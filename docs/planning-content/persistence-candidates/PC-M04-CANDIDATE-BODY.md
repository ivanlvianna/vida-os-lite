# PC-M04 — Candidate Body

Status: NON-EXECUTABLE / DO NOT APPLY.

Objective: create typed child/reference tables and exact-version relationships. No universal polymorphic `target_type + target_id` registry.

Required families include:
- InstrumentRun contributions;
- DiagnosticSynthesis source references, exactly one each for ICV-01 / IMDP-01 / IVRP-01 where required by the domain contract;
- DiagnosticSynthesis hypothesis proposals with aggregate-local proposal keys;
- WorkingHypothesis immutable origin reference to exact synthesis version + proposal key;
- HypothesisAgenda items referencing WorkingHypothesis;
- DiagnosticSession hypothesis entries and decision notes;
- DiagnosticReport source sessions, hypothesis references and consensus-subject EconomicEntity;
- FinancialPlan goals, strategies and hypothesis references;
- exact-version targets for ImplementationEpisode and ReviewEpisode.

Cross-cutting rules:
- same client account + same planning engagement must be physically enforceable through typed composite FKs when feasible;
- report submit requires at least one exact DiagnosticSessionVersion source;
- FinancialPlan commit requires at least one WorkingHypothesis reference; no arbitrary maximum in v1;
- DiagnosticReportVersion freezes `consensus_subject_economic_entity_id`;
- child/reference rows are immutable with their owning durable version;
- RLS + REVOKE ALL at creation.

Do not introduce Decision Ledger foreign keys or Evidence/Provenance links in this packet.
