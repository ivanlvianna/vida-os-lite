import type { SupabaseClient } from '@supabase/supabase-js'
import type { CurrentPrincipal } from '../lib/identity/principal'
import { VidaOsError } from '../lib/vida-os/errors'
import {
  onboardClientAccountMember,
  type OnboardClientAccountMemberInput,
} from '../lib/vida-os/rpc'

export type GrantAccessWorkflowInput = OnboardClientAccountMemberInput

export type GrantAccessWorkflowResult = {
  authorizationId: string
}

/**
 * Application-service boundary for granting Client Account access.
 *
 * The workflow only establishes the authenticated application boundary and
 * delegates the atomic membership + authorization mutation to the canonical
 * v0.7 PostgreSQL RPC. Planner ownership, target validity, scope consistency
 * and duplicate-active-authorization rules remain authoritative in PostgreSQL.
 */
export async function grantAccessWorkflow(
  principal: CurrentPrincipal,
  authenticatedClient: SupabaseClient,
  input: GrantAccessWorkflowInput
): Promise<GrantAccessWorkflowResult> {
  if (!principal.session.isAuthenticated || !principal.session.authUserId) {
    throw new VidaOsError(
      'AUTH_REQUIRED',
      'An authenticated principal is required to grant Client Account access.'
    )
  }

  const authorizationId = await onboardClientAccountMember(
    authenticatedClient,
    input
  )

  return { authorizationId }
}
