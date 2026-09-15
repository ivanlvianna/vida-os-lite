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

function staffAccountIds(principal: CurrentPrincipal): ReadonlySet<string> {
  return new Set(
    principal.memberships
      .filter(
        (membership) =>
          membership.scopeType === 'account' &&
          (membership.role === 'planner_owner' || membership.role === 'internal_staff')
      )
      .map((membership) => membership.clientAccountId)
  )
}

/**
 * Defense-in-depth guard for the staff-only PFP Cockpit surface.
 *
 * PostgreSQL/RLS remains the canonical authorization boundary. This check is
 * intentionally redundant so a projection mistake cannot turn a client-visible
 * row into a staff Cockpit navigation entry.
 */
function requireStaffAccount(
  principal: CurrentPrincipal,
  clientAccountId: string
): void {
  if (!staffAccountIds(principal).has(clientAccountId)) {
    throw new VidaOsError(
      'FORBIDDEN',
      'The PFP Cockpit is restricted to staff account authorization.'
    )
  }
}

/**
 * Lists PlanningEngagement summaries visible through PC-M09 and then fails
 * closed to account-scoped planner_owner/internal_staff memberships.
 *
 * The application filter is defense in depth; it does not replace the required
 * database correction that keeps PC-M09 staff-only for direct Data API access.
 */
export async function listPfpCockpitsWorkflow(
  principal: CurrentPrincipal,
  authenticatedClient: SupabaseClient
): Promise<EngagementContentSummary[]> {
  requireAuthenticatedPrincipal(principal)
  const allowedAccounts = staffAccountIds(principal)
  if (allowedAccounts.size === 0) return []

  const summaries = await listPfpEngagementSummaries(authenticatedClient)
  return summaries.filter((summary) => allowedAccounts.has(summary.client_account_id))
}

/**
 * Loads a staff PFP Cockpit projection for one PlanningEngagement.
 *
 * The session-scoped Supabase client queries PC-M09 views. After the summary is
 * returned, the application additionally requires an account-scoped staff role
 * before returning any Cockpit content to the Delivery layer.
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

  requireStaffAccount(principal, snapshot.summary.client_account_id)
  return snapshot
}
