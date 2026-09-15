# VIDA OS™ — Application Services Live E2E Evidence

Date: **2026-09-14 / 2026-09-15 UTC**  
Branch: `app-services-live-e2e-2026-09-14`  
Runtime: Vercel Preview only  
Database: Supabase D3 `vida-os-homologacao` / `aregdlspacytbrrdowps`

## Scope

Authenticated live E2E validation of the Delivery Layer for:

1. `GrantAccessWorkflow`;
2. `RevokeAccessWorkflow`;
3. `ChangeEngagementStateWorkflow`;
4. controlled live validation attempt of reconstructed `InviteClientWorkflow`.

No production deployment, merge, schema migration, RLS change, trigger change or RPC change is authorized by this evidence record.

## Authenticated actor

Dedicated E2E planner Auth user:

- email: `vidaos.e2e.planner@example.com`
- auth user id: `12c1823e-3817-4630-95e2-21a5e03549ab`
- active account authorization id: `fbeb1742-acdb-4799-9f20-aa529b470886`
- role: `planner_owner`
- scope: `account`
- client account: `c21d928b-e627-41ff-97bf-d4dd331b00c2`

The user authenticated through the real Vercel Preview UI against D3. Supabase Auth `last_sign_in_at` was observed after the successful login.

## 1. GrantAccessWorkflow — PASS

Action executed from authenticated Preview UI.

Target:

- target auth user id: `db521537-5ad5-4943-9c82-552b7ac57f35`
- role granted: `client_participant`
- scope: `account`
- client account: `c21d928b-e627-41ff-97bf-d4dd331b00c2`

Result returned by Delivery Layer:

- `ok: true`
- authorization id: `25ba2fe0-2379-494e-afe3-b0160fbfa121`

Post-action D3 verification confirmed the authorization existed, was active and matched the expected target, role, scope and account.

Status: **PASS**.

## 2. RevokeAccessWorkflow — PASS

Action executed from the same authenticated Preview session against the authorization created in step 1.

Result returned by Delivery Layer:

- `ok: true`

Post-action D3 verification confirmed authorization `25ba2fe0-2379-494e-afe3-b0160fbfa121` had `revoked_at` populated (`2026-09-15 02:13:54.842574+00`).

Status: **PASS**.

## 3. ChangeEngagementStateWorkflow — PASS

Planning Engagement:

- id: `69c0ec5f-976e-4e69-99b2-941a8f473739`
- client account: `c21d928b-e627-41ff-97bf-d4dd331b00c2`

Action executed from authenticated Preview UI.

Requested transition:

- from: `onboarding_em_andamento`
- to: `dados_incompletos`
- event: `live_e2e_change_state`
- origin: `planner`
- reason: `Homologacao live E2E da Delivery Layer`

Result returned by Delivery Layer:

- `ok: true`
- transition id: `17e0583f-a619-4919-9540-181e52aa3b89`

Post-action D3 verification confirmed:

- transition id: `17e0583f-a619-4919-9540-181e52aa3b89`
- actor auth user id: `12c1823e-3817-4630-95e2-21a5e03549ab`
- executor role: `planner_owner`
- recorded from state: `onboarding_em_andamento`
- recorded to state: `dados_incompletos`
- current Planning Engagement state: `dados_incompletos`
- occurred at: `2026-09-15 02:15:31.452584+00`

Status: **PASS**.

## 4. InviteClientWorkflow — LIVE D3 ATTEMPT / TRANSPORT BLOCKED

The reconstructed `InviteClientWorkflow` was exercised from the authenticated Preview path with the same D3 `planner_owner` principal.

Safety/runtime prerequisites verified before the invitation attempt:

- Preview branch pinned to D3 URL `https://aregdlspacytbrrdowps.supabase.co`;
- branch-specific administrative Supabase secret configured in Vercel Preview;
- Production variables and Production deployment left unchanged;
- D3 guard accepts modern `sb_secret_...` administrative key format only when the configured Supabase URL is the expected D3 project;
- authenticated session established on the same Preview hostname used for the Server Action.

Observed progression:

1. initial placeholder target `vidaos.e2e.invite.20260914@example.com` reached Supabase Auth admin and was rejected with `email_address_invalid` / HTTP 400;
2. target was changed to the real test address `ivanlvianna@gmail.com`;
3. the live attempt again reached Supabase Auth admin `inviteUserByEmail()`;
4. Supabase returned `over_email_send_rate_limit` / HTTP 429 / `email rate limit exceeded`.

Interpretation:

- authentication path: **REACHED**;
- account-scoped `planner_owner` authorization path: **REACHED**;
- D3 administrative client construction: **REACHED**;
- `auth.admin.inviteUserByEmail()` invocation: **REACHED**;
- successful invitation creation and returned Auth user id: **NOT YET OBSERVED**;
- post-invitation proof of no membership and no authorization rows: **NOT YET EXECUTABLE** because no successful invitation result exists;
- current blocker: **external Supabase email transport rate limit**, not a demonstrated workflow-contract failure.

Status: **PENDING — EXTERNAL EMAIL RATE-LIMIT BLOCKER**.

Do not classify `InviteClientWorkflow` live E2E as PASS until all of the following are observed in one successful controlled run:

1. invitation returns `ok: true`;
2. returned `authUserId` is captured;
3. D3 Auth contains the invited identity for the target address;
4. no Client Account membership is created by the invitation;
5. no Client Account authorization is created by the invitation.

## Authentication/runtime finding

During setup, Server Actions returned `AUTH_REQUIRED` when the E2E page was opened on a new Vercel deployment hostname while authentication had occurred on a different Preview hostname. Re-authenticating on the same Preview hostname used for the E2E action resolved the issue. This was a runtime session/cookie-host boundary issue, not a failure of the Application Service or PostgreSQL authorization rules.

## Branch/governance finding

The controlled reconstruction branch `invite-client-reconstruction-2026-09-14` and the live E2E branch `app-services-live-e2e-2026-09-14` are currently **diverged**. The live E2E branch is not a drop-in replacement for PR #10 and must not be merged or retargeted mechanically. PR #10 remains a Draft reconstruction candidate. Any promotion of live-E2E findings into the reconstruction PR requires a deliberate reconciliation of only the contract-relevant changes.

## Final result

- `GrantAccessWorkflow`: **PASS**
- `RevokeAccessWorkflow`: **PASS**
- `ChangeEngagementStateWorkflow`: **PASS**
- `InviteClientWorkflow`: **PENDING — external Supabase email rate limit**
- authenticated Delivery Layer → Application Service → canonical PostgreSQL path for the first three workflows: **VALIDATED on D3 Preview**
- `InviteClientWorkflow` path through Supabase Auth admin invocation: **REACHED, final side effect not yet proven**
- Production: **UNCHANGED / NOT AUTHORIZED by this record**

This record closes the previously pending live authenticated Application Services E2E readiness blocker for the first three workflows only. It does not close the separate `InviteClientWorkflow` live side-effect homologation item.
