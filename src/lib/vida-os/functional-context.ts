import type { SupabaseClient } from '@supabase/supabase-js'
import { resolveCurrentPrincipal } from '../identity/identity-context'
import type { CurrentPrincipal } from '../identity/principal'
import { enrichClientContext, type ClientContext } from './client-context'

export type RequestedFunctionalContext = {
  clientAccountId?: string
  planningEngagementId?: string
}

export type FunctionalContextResolution = {
  principal: CurrentPrincipal
  client: ClientContext
  needsContextCreation: boolean
  awaitingAccess: boolean
  needsAccountSelection: boolean
  needsEngagementSelection: boolean
  missingEngagement: boolean
}

/**
 * Resolves product-facing navigation context without turning it into an
 * authorization source. PostgreSQL/RLS still decides which rows are visible.
 */
export async function resolveFunctionalContext(
  supabase: SupabaseClient,
  requestedContext: RequestedFunctionalContext = {}
): Promise<FunctionalContextResolution> {
  const principal = await resolveCurrentPrincipal(
    supabase,
    requestedContext.clientAccountId
  )

  const accountIds = Array.from(
    new Set(principal.memberships.map((membership) => membership.clientAccountId))
  )

  const needsContextCreation = Boolean(
    principal.session.isAuthenticated &&
      principal.isInternalStaff &&
      accountIds.length === 0
  )

  const awaitingAccess = Boolean(
    principal.session.isAuthenticated &&
      !principal.isInternalStaff &&
      accountIds.length === 0
  )

  const needsAccountSelection =
    accountIds.length > 1 && !principal.activeClientAccountId

  let selectedEngagementId = requestedContext.planningEngagementId
  let visibleEngagementCount = 0

  if (principal.activeClientAccountId) {
    const { data, error } = await supabase
      .from('planning_engagements')
      .select('id')
      .eq('client_account_id', principal.activeClientAccountId)
      .order('opened_at', { ascending: false })
      .limit(3)

    if (error) throw error

    visibleEngagementCount = data?.length ?? 0

    if (!selectedEngagementId && visibleEngagementCount === 1) {
      selectedEngagementId = data?.[0]?.id
    }
  }

  const client = await enrichClientContext(
    supabase,
    principal,
    selectedEngagementId
  )

  const requestedEngagementWasNotVisible = Boolean(
    requestedContext.planningEngagementId && !client.activeEngagement
  )

  return {
    principal,
    client,
    needsContextCreation,
    awaitingAccess,
    needsAccountSelection,
    needsEngagementSelection: Boolean(
      principal.activeClientAccountId &&
        (visibleEngagementCount > 1 || requestedEngagementWasNotVisible) &&
        !client.activeEngagement
    ),
    missingEngagement: Boolean(
      principal.activeClientAccountId && visibleEngagementCount === 0
    ),
  }
}
