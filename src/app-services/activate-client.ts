import type { SupabaseClient } from '@supabase/supabase-js'
import type { CurrentPrincipal } from '../lib/identity/principal'
import { VidaOsError } from '../lib/vida-os/errors'
import {
  activateClientFromVri,
  type ActivateClientFromVriResult,
} from '../lib/vida-os/rpc'
import { authorizeServiceRoleAction } from '../lib/vida-os/service-role-authorization'

export type ActivateClientWorkflowInput =
  | {
      vriCorrelationId: string
      vriActivationCorrelationId: string
      identityResolution: 'no_match'
      entityType: 'person' | 'organization'
      displayName: string
    }
  | {
      vriCorrelationId: string
      vriActivationCorrelationId: string
      identityResolution: 'match_confident'
      existingEconomicEntityId: string
    }

/**
 * Application-service boundary for initial Client Account activation.
 *
 * The workflow authorizes service-role use, derives the planner identity from
 * CurrentPrincipal and delegates domain mutation to the canonical Gate 002 RPC.
 */
export async function activateClientWorkflow(
  principal: CurrentPrincipal,
  serviceClient: SupabaseClient,
  input: ActivateClientWorkflowInput
): Promise<ActivateClientFromVriResult> {
  const authorization = authorizeServiceRoleAction(principal, {
    type: 'activate_client',
  })

  if (!authorization.allowed) {
    if (authorization.reason === 'unauthenticated') {
      throw new VidaOsError(
        'AUTH_REQUIRED',
        'An authenticated principal is required to activate a client.'
      )
    }

    throw new VidaOsError(
      'FORBIDDEN',
      'Only authorized internal staff can activate a Client Account from VRI.'
    )
  }

  const plannerAuthUserId = principal.session.authUserId
  if (!plannerAuthUserId) {
    throw new VidaOsError(
      'AUTH_REQUIRED',
      'The authenticated principal does not contain an auth user id.'
    )
  }

  if (input.identityResolution === 'no_match') {
    return activateClientFromVri(serviceClient, {
      plannerAuthUserId,
      vriCorrelationId: input.vriCorrelationId,
      vriActivationCorrelationId: input.vriActivationCorrelationId,
      identityResolution: 'no_match',
      entityType: input.entityType,
      displayName: input.displayName,
    })
  }

  return activateClientFromVri(serviceClient, {
    plannerAuthUserId,
    vriCorrelationId: input.vriCorrelationId,
    vriActivationCorrelationId: input.vriActivationCorrelationId,
    identityResolution: 'match_confident',
    existingEconomicEntityId: input.existingEconomicEntityId,
  })
}
