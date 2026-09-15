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
- successful live invitation E2E;
- successful delivery of a real email;
- merge into PR #9, `p0-functional-integration`, or `main`;
- production deployment;
- closure of `PC-PERSISTENCE-START-GATE-001`;
- closure of v0.7 Caso 7 concurrency.

## Validation status

Current status:
- source candidate: **IMPLEMENTED**
- Vercel Preview build: **PASS**
- diff scope audit: **PASS — exactly 3 changed files in PR #10**
- live authenticated D3 path to Auth admin API: **REACHED**
- live invitation side effect: **BLOCKED BY SUPABASE EMAIL RATE LIMIT**
- Production mutation: **ZERO**
- Production deployment: **ZERO**

## Live D3 evidence — 2026-09-15

A controlled live E2E was executed from the Preview branch `app-services-live-e2e-2026-09-14` using the authenticated D3 planner fixture.

Validated before the Auth admin call:
- authenticated Preview session resolved successfully;
- D3 project URL was pinned to `https://aregdlspacytbrrdowps.supabase.co`;
- the branch-specific administrative secret was accepted by the server-side client;
- the `planner_owner` authorization path was passed;
- execution reached `serviceClient.auth.admin.inviteUserByEmail(...)`.

Observed attempts:

1. Placeholder address `vidaos.e2e.invite.20260914@example.com`
   - Supabase Auth response: `email_address_invalid` / HTTP 400.
   - Interpretation: the workflow reached the Auth admin invitation endpoint; the placeholder recipient was rejected.

2. Real controlled address `ivanlvianna@gmail.com`
   - Supabase Auth response: `over_email_send_rate_limit` / HTTP 429 / `email rate limit exceeded`.
   - Interpretation: the invitation request reached Supabase Auth, but the built-in email transport refused the send because its temporary email quota was exhausted.

This 429 is classified as an **external transport/rate-limit blocker**, not as evidence of an authorization, D3 routing, secret, workflow, or application-service failure.

No successful invitation may be claimed until a later attempt returns an Auth user id and the resulting D3 state is verified.

## Contract validation matrix

The following cases are the acceptance matrix for the candidate before any controlled live invitation is considered complete:

| Case | Principal / input | Expected result | Side effect allowed |
|---|---|---|---|
| IC-01 | unauthenticated principal | `AUTH_REQUIRED` before Auth admin call | none |
| IC-02 | authenticated principal without account-scoped `planner_owner` | `FORBIDDEN` before Auth admin call | none |
| IC-03 | authenticated account-scoped `planner_owner` + valid email | exactly one `auth.admin.inviteUserByEmail(email, options)` call and returned Auth user id | invitation only |
| IC-04 | successful invitation path | no membership creation and no authorization grant inside `InviteClientWorkflow` | none beyond invitation operation |

Repository note: there is currently no dedicated test framework/script in `package.json`. No new Jest/Vitest infrastructure is introduced solely for this reconstruction. The application build provides TypeScript compilation coverage; the matrix above remains the explicit behavioral contract for a simulated harness or controlled live validation.

## Governance checkpoint

Draft PR: `#10`  
Base: `app-services-prereqs-2026-09-14`  
Head: `invite-client-reconstruction-2026-09-14`

PR #10 is intentionally Draft. No merge is authorized by this record.

## Next safe validation

1. keep PR #10 in Draft;
2. do not change Production or `main`;
3. do not change SMTP solely to force this homologation test;
4. after the Supabase built-in email rate limit clears, rerun exactly one controlled invite to `ivanlvianna@gmail.com` from the D3 Preview;
5. if the call succeeds, record the returned Auth user id and verify directly that the invited identity exists in D3 while no membership or authorization was created by the workflow;
6. only then promote the live side-effect status from blocked/pending to PASS.
