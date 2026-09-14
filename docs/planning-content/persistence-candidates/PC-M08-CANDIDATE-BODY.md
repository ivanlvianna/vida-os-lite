# PC-M08 — Candidate Body

Status: NON-EXECUTABLE / DO NOT APPLY.

Objective: open only the minimum reviewed access surface after PC-M02…PC-M07 exist and their guards are proven.

Rules:
- base Planning Content tables remain staff-only;
- authenticated staff SELECT is protected by RLS predicates based on `public.is_staff(client_account_id)` or a narrower approved predicate;
- no INSERT/UPDATE/DELETE policies for application roles;
- no broad raw-table access to clients;
- grant EXECUTE only on approved canonical writer RPCs;
- internal helper functions retain no app-facing EXECUTE grant;
- client self-service, where approved, goes through narrow RPCs such as report-consensus recording, never direct DML;
- service-role privileges are not treated as a substitute for domain authorization.

Before this migration is considered ready, perform explicit review of all `SECURITY DEFINER` functions, function ACLs and RLS policy interaction.
