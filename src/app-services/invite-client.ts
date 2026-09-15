import type { SupabaseClient } from '@supabase/supabase-js'
import type { CurrentPrincipal } from '../lib/identity/principal'
import { VidaOsError } from '../lib/vida-os/errors'
import { authorizeServiceRoleAction } from '../lib/vida-os/service-role-authorization'

export type InviteClientWorkflowInput = {
  clientAccountId: string
  email: string
  redirectTo?: string
}

export type InviteClientWorkflowResult = {
  authUserId: string
  email: string | null
}

export async function inviteClientWorkflow(
  principal: CurrentPrincipal,
  serviceClient: SupabaseClient,
  input: InviteClientWorkflowInput
): Promise<InviteClientWorkflowResult> {
  const clientAccountId = input.clientAccountId.trim()
  const email = input.email.trim().toLowerCase()

  if (!clientAccountId || !email) {
    throw new VidaOsError(
      'INVALID_INPUT',
      'Client Account id and invitation email are required.'
    )
  }

  const authorization = authorizeServiceRoleAction(principal, {
    type: 'invite_client',
    clientAccountId,
  })

  if (authorization.allowed === false) {
    if (authorization.reason === 'unauthenticated') {
      throw new VidaOsError(
        'AUTH_REQUIRED',
        'An authenticated principal is required to invite a client.'
      )
    }

    throw new VidaOsError(
      'FORBIDDEN',
      'Only a planner_owner of the Client Account can invite a client.'
    )
  }

  const options = input.redirectTo?.trim()
    ? { redirectTo: input.redirectTo.trim() }
    : undefined

  const { data, error } = await serviceClient.auth.admin.inviteUserByEmail(
    email,
    options
  )

  if (error) {
    throw new VidaOsError(
      'DOMAIN_RPC_FAILED',
      'The client invitation could not be created.',
      error
    )
  }

  if (!data.user?.id) {
    throw new VidaOsError(
      'DOMAIN_RPC_FAILED',
      'The invitation completed without returning an Auth user id.'
    )
  }

  return {
    authUserId: data.user.id,
    email: data.user.email ?? null,
  }
}
