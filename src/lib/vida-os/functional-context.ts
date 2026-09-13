import type { SupabaseClient } from '@supabase/supabase-js'
import { resolveCurrentPrincipal } from '../identity/identity-context'
import type { ActiveContext, CurrentPrincipal } from '../identity/principal'
import { enrichClientContext, type ClientContext } from './client-context'

export type FunctionalContextResolution = {
  principal: CurrentPrincipal
  client: ClientContext
  needsContextCreation: boolean
  needsAccountSelection: boolean
  needsEngagementSelection: boolean
}

/**
 * Resolves the product-facing context without turning Active Context into an
 * authorization mechanism. All database visibility still comes from RLS.
 */
export async function resolveFunctionalContext(
  supabase: SupabaseClient,
  requestedContext?: Partial<ActiveContext>
): Promise<FunctionalContextResolution> {
  let principal = await resolveCurrentPrincipal(supabase, requestedContext)

  const needsContextCreation =
    principal.session.isAuthenticated && principal.memberships.length === 0

  const needsAccountSelection =
    principal.memberships.length > 1 && !principal.activeContext.clientAccountId

  if (
    principal.activeContext.clientAccountId &&
    !principal.activeContext.planningEngagementId
  ) {
    const { data, error } = await supabase
      .from('planning_engagements')
      .select('id')
      .eq('client_account_id', principal.activeContext.clientAccountId)
      .order('opened_at', { ascending: false })
      .limit(2)

    if (error) throw error

    // Auto-select only when there is exactly one RLS-visible engagement. With
    // multiple visible engagements the user must choose explicitly.
    if (data?.length === 1) {
      principal = {
        ...principal,
        activeContext: {
          ...principal.activeContext,
          planningEngagementId: data[0].id,
        },
      }
    }
  }

  const client = await enrichClientContext(supabase, principal)

  const needsEngagementSelection = Boolean(
    principal.activeContext.clientAccountId &&
      !principal.activeContext.planningEngagementId &&
      !needsContextCreation
  )

  return {
    principal,
    client,
    needsContextCreation,
    needsAccountSelection,
    needsEngagementSelection,
  }
}
