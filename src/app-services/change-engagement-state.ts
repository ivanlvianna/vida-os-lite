import type { SupabaseClient } from '@supabase/supabase-js'
import type { CurrentPrincipal } from '../lib/identity/principal'
import { VidaOsError } from '../lib/vida-os/errors'
import {
  recordPlanningEngagementTransition,
  type RecordPlanningEngagementTransitionInput,
} from '../lib/vida-os/rpc'

export type ChangeEngagementStateWorkflowInput =
  RecordPlanningEngagementTransitionInput

export type ChangeEngagementStateWorkflowResult = {
  transitionId: string
}

/**
 * Application-service boundary for a Planning Engagement state transition.
 *
 * The PostgreSQL lifecycle state machine remains authoritative for allowed
 * transitions, pause/resume behavior, terminal states, required reasons,
 * actor/executor derivation and append-only transition history.
 */
export async function changeEngagementStateWorkflow(
  principal: CurrentPrincipal,
  authenticatedClient: SupabaseClient,
  input: ChangeEngagementStateWorkflowInput
): Promise<ChangeEngagementStateWorkflowResult> {
  if (!principal.session.isAuthenticated || !principal.session.authUserId) {
    throw new VidaOsError(
      'AUTH_REQUIRED',
      'An authenticated principal is required to change Planning Engagement state.'
    )
  }

  const transitionId = await recordPlanningEngagementTransition(
    authenticatedClient,
    input
  )

  return { transitionId }
}
