import type { SupabaseClient } from '@supabase/supabase-js'
import type { CurrentPrincipal } from '../lib/identity/principal'
import { VidaOsError } from '../lib/vida-os/errors'
import { revokeClientAccountAuthorization } from '../lib/vida-os/rpc'

export type RevokeAccessWorkflowInput = {
  authorizationId: string
}

/**
 * Application-service boundary for revoking one active authorization.
 *
 * The canonical PostgreSQL RPC is the authority for planner ownership,
 * account locking, already-revoked detection and last-planner-owner safety.
 * This workflow never deletes identity, membership or authorization history.
 */
export async function revokeAccessWorkflow(
  principal: CurrentPrincipal,
  authenticatedClient: SupabaseClient,
  input: RevokeAccessWorkflowInput
): Promise<void> {
  if (!principal.session.isAuthenticated || !principal.session.authUserId) {
    throw new VidaOsError(
      'AUTH_REQUIRED',
      'An authenticated principal is required to revoke Client Account access.'
    )
  }

  await revokeClientAccountAuthorization(
    authenticatedClient,
    input.authorizationId
  )
}
