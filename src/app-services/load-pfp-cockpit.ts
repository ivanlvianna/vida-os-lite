import type { SupabaseClient } from '@supabase/supabase-js'
import type { CurrentPrincipal } from '../lib/identity/principal'
import { VidaOsError } from '../lib/vida-os/errors'
import {
  listPfpEngagementSummaries,
  loadPfpCockpitSnapshot,
  type EngagementContentSummary,
  type PfpCockpitSnapshot,
} from '../lib/planning-content/read-models'

function requireAuthenticatedPrincipal(principal: CurrentPrincipal): void {
  if (!principal.session.isAuthenticated || !principal.session.authUserId) {
    throw new VidaOsError(
      'AUTH_REQUIRED',
      'An authenticated principal is required to access the PFP Cockpit.'
    )
  }
}

/**
 * Lists only PlanningEngagements visible through PC-M09 security-invoker
 * read models. Authorization remains authoritative in PostgreSQL/RLS.
 */
export async function listPfpCockpitsWorkflow(
  principal: CurrentPrincipal,
  authenticatedClient: SupabaseClient
): Promise<EngagementContentSummary[]> {
  requireAuthenticatedPrincipal(principal)
  return listPfpEngagementSummaries(authenticatedClient)
}

/**
 * Loads a staff PFP Cockpit projection for one PlanningEngagement.
 *
 * The application layer does not infer authorization from CurrentPrincipal.
 * The session-scoped Supabase client queries PC-M09 views, whose
 * security_invoker behavior preserves the underlying staff-only RLS boundary.
 */
export async function loadPfpCockpitWorkflow(
  principal: CurrentPrincipal,
  authenticatedClient: SupabaseClient,
  planningEngagementId: string
): Promise<PfpCockpitSnapshot> {
  requireAuthenticatedPrincipal(principal)

  if (!planningEngagementId.trim()) {
    throw new VidaOsError(
      'INVALID_INPUT',
      'planningEngagementId is required to load the PFP Cockpit.'
    )
  }

  const snapshot = await loadPfpCockpitSnapshot(
    authenticatedClient,
    planningEngagementId
  )

  if (!snapshot) {
    throw new VidaOsError(
      'FORBIDDEN',
      'The requested PlanningEngagement is not visible to this principal.'
    )
  }

  return snapshot
}
