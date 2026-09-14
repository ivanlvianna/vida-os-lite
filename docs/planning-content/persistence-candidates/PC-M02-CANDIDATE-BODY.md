# PC-M02 — Candidate Body

Status: NON-EXECUTABLE / DO NOT APPLY.

Objective: create Planning Content aggregate roots with tenant/engagement context and deny-by-default security from the same transaction.

Root families:
- InterviewRecord;
- InstrumentRun;
- DiagnosticSynthesis;
- WorkingHypothesis;
- HypothesisAgenda;
- DiagnosticSession;
- DiagnosticReport;
- FinancialPlan;
- ImplementationEpisode;
- ReviewEpisode.

Common root fields:
`id`, `client_account_id`, `planning_engagement_id`, `created_at`, actor/authorship snapshot fields.

Required invariants:
- FK `(client_account_id, planning_engagement_id)` → `planning_engagements(client_account_id, id)`;
- expose unique `(client_account_id, planning_engagement_id, id)` for typed same-engagement references;
- `created_by_auth_user_id` may survive auth-user deletion through `ON DELETE SET NULL` while label snapshot remains immutable;
- no canonical hard delete;
- ownership/context are not mutable through application writers.

Security invariant for every created table, in the same migration transaction:
- `ENABLE ROW LEVEL SECURITY`;
- `REVOKE ALL ... FROM PUBLIC, anon, authenticated, service_role`;
- no create-now/protect-later window.

WorkingHypothesis root also stores immutable exact origin linkage to a DiagnosticSynthesisVersion + HypothesisProposal local key once PC-M03/PC-M04 make those references available.
