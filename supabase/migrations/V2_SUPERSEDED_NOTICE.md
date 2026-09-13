# Gate 002 — v2 superseded

The M2/M3 v2 candidate MUST NOT be applied.

Reason: a FROZEN Authorization/Membership acceptance document was recovered after v2 was drafted. v2 conflicts with mandatory criteria:

1. C1: v2 allows direct authenticated INSERT/DELETE on `client_account_users` and has no append-only membership event ledger / canonical add-remove functions.
2. C3: v2 policies are not explicitly `TO authenticated`.
3. C4: v2 `economic_entities_update` has no `WITH CHECK`.
4. C5: v2 has no persisted idempotent offboarding workflow across the database/Auth Admin API boundary.

C2 is retained: moving helpers to `vida_internal` is directionally correct and remains part of v3.

No v2 SQL is eligible for staging execution after this notice except as a historical comparison artifact.
