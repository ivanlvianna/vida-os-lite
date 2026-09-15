# VIDA OS™ — InviteClientWorkflow Controlled Reconstruction

Date: **2026-09-14**  
Branch: `invite-client-reconstruction-2026-09-14`

## Classification

`ARTIFACT RECOVERY GAP / CONTROLLED RECONSTRUCTION CANDIDATE`

The historical `invite-client.ts` described by AH-001 was not recovered from accessible Git history. Commit-history queries for both `src/app-services/invite-client.ts` and `app-services/invite-client.ts` returned no commits.

This candidate is therefore **not** represented as the recovered historical artifact.

## Preserved AH-001 contract

The reconstruction preserves only the contract explicitly documented by AH-001:

1. the operation is an Application Service;
2. only `planner_owner` of the target Client Account may invite;
3. the administrative Auth operation is `inviteUserByEmail()`;
4. invitation creates/preserves an Auth identity in `pending_invitation` semantics;
5. invitation does **not** create membership;
6. invitation does **not** grant Client Account authorization;
7. `GrantAccessWorkflow` remains a separate later use case.

## Implementation

Added:
- `src/app-services/invite-client.ts`

Extended:
- `src/lib/vida-os/service-role-authorization.ts`
  - new discriminated action: `invite_client`
  - account-scoped `planner_owner` capability check

The workflow receives a server-side Supabase service client as a dependency. It does not instantiate or expose the service-role secret itself.

## Explicit non-claims

This record does **not** claim:

- recovery of the original historical source file;
- equivalence with any unrecovered implementation detail;
- live invitation E2E;
- delivery of a real email;
- merge into PR #9, `p0-functional-integration`, or `main`;
- production deployment;
- closure of `PC-PERSISTENCE-START-GATE-001`;
- closure of v0.7 Caso 7 concurrency.

## Validation status

At creation time:
- source candidate: **IMPLEMENTED**
- Vercel build: **PENDING**
- live side-effect test: **NOT RUN**
- Production mutation: **ZERO**

## Next safe validation

1. require build/type-check success;
2. inspect diff for scope leakage;
3. run a simulated admin-client contract test without sending email;
4. only then decide whether a controlled live D3 invitation test is warranted.
