# PC-M07 — Candidate Body

Status: NON-EXECUTABLE / DO NOT APPLY.

Objective: create typed canonical writer RPCs. Direct application DML remains forbidden.

Writer families:
- open/save/discard/commit typed drafts;
- record/commit immutable versions for occurrence-style aggregates;
- WorkingHypothesis lifecycle transition writers;
- HypothesisAgenda open/close writers;
- DiagnosticReport submit/validate/consensus writers;
- FinancialPlan create/revise writers where root-vs-version distinction is explicit;
- ImplementationEpisode and ReviewEpisode record/correction writers preserving occurrence identity.

Mandatory writer flow:
1. authenticate/authorize caller;
2. derive actor stamp server-side;
3. resolve account/engagement scope;
4. lock relevant aggregate root or engagement row;
5. validate expected draft/base/current lifecycle state;
6. validate exact-version and same-engagement references;
7. create immutable version + children/refs/events atomically;
8. close/remove draft when applicable;
9. return stable typed identifiers.

Security:
- no universal `write_planning_content(jsonb)` RPC;
- every `SECURITY DEFINER` function uses `SET search_path=''`;
- immediately `REVOKE ALL ON FUNCTION ... FROM PUBLIC, anon, authenticated, service_role`;
- grant EXECUTE later only to explicitly approved functions/roles in PC-M08;
- caller never supplies authoritative actor label or authorization snapshot.
