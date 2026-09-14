# PC-M03 — Candidate Body

Status: NON-EXECUTABLE / DO NOT APPLY.

Objective: create immutable durable-version tables for all versioned Planning Content aggregates.

Common version fields:
`id`, account/engagement context, `root_id`, `version_no`, optional `supersedes_version_id`, `recorded_at`, actor/authorship snapshot and typed payload.

Required invariants:
- unique `(root_id, version_no)`;
- unique predecessor successor (`supersedes_version_id`) to prevent forks;
- no self-supersede;
- composite FK to root context;
- expose exact-version composite key for later typed references;
- first version is version 1 with no predecessor;
- successor must reference the terminal version of the same root;
- monotonic version number under root lock;
- immutable after insert; no direct UPDATE/DELETE through application roles;
- RLS + REVOKE ALL at table creation.

Families include versions for InterviewRecord, InstrumentRun, DiagnosticSynthesis, WorkingHypothesis, HypothesisAgenda, DiagnosticSession, DiagnosticReport, FinancialPlan, ImplementationEpisode and ReviewEpisode.

Special semantics:
- DiagnosticReport validated versions remain immutable; revision means a successor version under the same root;
- ImplementationEpisode stores exact FinancialPlan version on the episode version, not on the occurrence root;
- ReviewEpisode stores exact ImplementationEpisode version on the review version.
