# PC-M05 — Candidate Body

Status: NON-EXECUTABLE / DO NOT APPLY.

Objective: create typed mutable WorkingDraft structures separated from immutable DurableVersion history.

Draft families are required only where professional work needs edit-before-commit semantics, including InterviewRecord, DiagnosticSynthesis, WorkingHypothesis, HypothesisAgenda, DiagnosticSession, DiagnosticReport and FinancialPlan as frozen by the logical model.

Required fields/invariants:
- one active draft per root in v1;
- `root_id` as draft identity anchor;
- optional `base_version_id`;
- `draft_revision` monotonic optimistic-concurrency token;
- created/updated timestamps and actor stamps;
- typed payload and typed child-draft tables where aggregate children require editing;
- save requires expected `draft_revision` and must fail on stale write;
- commit requires expected base version and stale-base rejection;
- committing creates immutable DurableVersion + immutable child references atomically and removes/closes the draft;
- draft content is never authoritative professional history;
- drafts are staff-only in v1;
- RLS + REVOKE ALL at creation.

Do not expose collaborative client draft editing in v1.
