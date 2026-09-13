# Gate 002 — v3 superseded by v4

The earlier Gate 002 v3 files remain in Git only as historical rehearsal artifacts and **MUST NOT be used for production apply**.

Reason: production Phase 1A objects are owned by `vida_identity_owner`, while migration execution occurs as `postgres` without inherited owner privileges. The first v3 production M1 attempt therefore failed atomically before any change was committed. Rehearsal v3 had not reproduced that ownership boundary.

Gate 002 v4 corrects the mismatch by:

- rehearsing with the production ownership model;
- preserving `vida_identity_owner` as the canonical owner;
- temporarily enabling inherited owner capability only inside migration transactions and restoring the baseline membership option before commit;
- keeping direct `auth` schema access away from `vida_identity_owner`;
- introducing narrow postgres-owned internal adapters for Auth/runtime facts;
- re-running rollback/replay equivalence and runtime smoke tests using the exact Git-resident v4 chain.

Canonical production sequence is documented in `GATE_002_SEQUENCE.md`.
