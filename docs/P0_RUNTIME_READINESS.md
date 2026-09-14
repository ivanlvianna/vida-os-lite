# VIDA OS™ — P0 Runtime Readiness

Status: **IMPLEMENTATION ACTIVE / RUNTIME ACTIVATION BLOCKED BY MISSING INTERNAL-STAFF PRINCIPAL**  
Date: 2026-09-13

## CI baseline

The P0 branch now has a dedicated CI workflow that runs `npm ci`, `npm run lint` and `npm run build` on every push to `p0-functional-integration`.

After one TypeScript narrowing defect in the new service-role authorization adapter was detected and corrected, CI run #2 completed successfully: install PASS, lint PASS, production build PASS.

## Current production prerequisite

A read-only check against production Auth found **0 users** carrying `app_metadata.internal_staff = true`.

That is a legitimate runtime blocker for the controlled initial activation path because the frozen P0 contract requires:

- an authenticated `CurrentPrincipal`;
- global `internal_staff` authorization at the application-service boundary before service-role use;
- `activate_client_from_vri()` to remain backend/service-role only;
- no interactive user session to call the activation RPC directly.

Therefore the first real production VRI activation **must not be attempted yet**.

Provisioning an internal-staff Auth claim is a separate production Auth metadata mutation and is not authorized merely by this implementation branch. It requires an explicit decision identifying the intended principal before any production change.

## Safe work that can continue before that decision

- CurrentPrincipal/session resolution;
- RLS-backed Client Account and Planning Engagement context reads;
- service-role authorization/application-service boundaries;
- UI state for missing/existing/ambiguous context;
- import/integration of the frozen Product Core v0.5.2 artifact;
- persistence contract/migration candidate development in Git and rehearsal only;
- negative isolation tests in a non-production environment.

No production backfill, Client Account activation, Auth metadata change or merge to `main` is implied by this status.
