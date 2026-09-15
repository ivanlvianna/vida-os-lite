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

Current status:
- source candidate: **IMPLEMENTED**
- Vercel Preview build: **PASS**
- diff scope audit: **PASS — exactly 3 changed files**
- live side-effect test: **NOT RUN**
- Production mutation: **ZERO**
- D3 mutation: **ZERO**

## Contract validation matrix

The following cases are the acceptance matrix for the candidate before any controlled live invitation is considered:

| Case | Principal / input | Expected result | Side effect allowed |
|---|---|---|---|
| IC-01 | unauthenticated principal | `AUTH_REQUIRED` before Auth admin call | none |
| IC-02 | authenticated principal without account-scoped `planner_owner` | `FORBIDDEN` before Auth admin call | none |
| IC-03 | authenticated account-scoped `planner_owner` + valid email | exactly one `auth.admin.inviteUserByEmail(email, options)` call and returned Auth user id | simulated admin client only |
| IC-04 | successful invitation path | no membership creation and no authorization grant inside `InviteClientWorkflow` | none beyond invitation operation |

Repository note: there is currently no dedicated test framework/script in `package.json`. No new Jest/Vitest infrastructure is introduced solely for this reconstruction. The application build provides TypeScript compilation coverage; the matrix above remains the explicit behavioral contract for a simulated harness or controlled live validation.

## Governance checkpoint

Draft PR: `#10`  
Base: `app-services-prereqs-2026-09-14`  
Head: `invite-client-reconstruction-2026-09-14`

PR #10 is intentionally Draft. No merge is authorized by this record.

## Next safe validation

1. keep PR #10 in Draft;
2. verify the final Preview build after documentation update;
3. verify PR diff/mergeability after GitHub recalculates state;
4. do not send a real invitation until an explicit controlled D3 live-test decision is made.
