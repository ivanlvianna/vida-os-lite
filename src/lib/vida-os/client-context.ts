import type { SupabaseClient } from '@supabase/supabase-js'
import type {
  AuthorizationRole,
  CurrentPrincipal,
  IdentityState,
} from '../identity/principal'

export type AvailableAccount = {
  id: string
  roles: AuthorizationRole[]
}

export type EconomicEntitySummary = {
  id: string
  displayName: string
  entityType: string
}

export type ActiveAccount = {
  id: string
  createdAt: string
  economicEntities: EconomicEntitySummary[]
}

export type ActiveEngagement = {
  id: string
  clientAccountId: string
  state: string
  openedAt: string
  closedAt: string | null
  predecessorEngagementId: string | null
}

export type ClientContextBase = {
  availableAccounts: AvailableAccount[]
  plannerRole: 'planner_owner' | 'internal_staff' | null
  identityState: IdentityState
  activeAccountId: string | null
  activeEngagementId: string | null
}

export type ClientContext = ClientContextBase & {
  activeAccount: ActiveAccount | null
  activeEngagement: ActiveEngagement | null
}

export function deriveClientContextBase(principal: CurrentPrincipal): ClientContextBase {
  const availableAccounts: AvailableAccount[] = principal.memberships.map((membership) => ({
    id: membership.clientAccountId,
    roles: Array.from(
      new Set(
        membership.authorizations
          .filter((authorization) => authorization.scopeType === 'account')
          .map((authorization) => authorization.role)
      )
    ),
  }))

  const activeMembership = principal.activeContext.clientAccountId
    ? principal.memberships.find(
        (membership) => membership.clientAccountId === principal.activeContext.clientAccountId
      )
    : undefined

  const accountRoles = activeMembership?.authorizations
    .filter((authorization) => authorization.scopeType === 'account')
    .map((authorization) => authorization.role) ?? []

  const plannerRole = accountRoles.includes('planner_owner')
    ? 'planner_owner'
    : accountRoles.includes('internal_staff')
      ? 'internal_staff'
      : null

  return {
    availableAccounts,
    plannerRole,
    identityState: principal.identityState,
    activeAccountId: principal.activeContext.clientAccountId,
    activeEngagementId: principal.activeContext.planningEngagementId,
  }
}

export async function enrichClientContext(
  supabase: SupabaseClient,
  principal: CurrentPrincipal
): Promise<ClientContext> {
  const base = deriveClientContextBase(principal)

  let activeAccount: ActiveAccount | null = null
  let activeEngagement: ActiveEngagement | null = null

  if (base.activeAccountId) {
    const [accountResult, entitiesResult] = await Promise.all([
      supabase
        .from('client_accounts')
        .select('id, created_at')
        .eq('id', base.activeAccountId)
        .maybeSingle(),
      supabase
        .from('client_account_entities')
        .select('economic_entity_id, economic_entities(id, display_name, entity_type)')
        .eq('client_account_id', base.activeAccountId),
    ])

    if (accountResult.error) throw accountResult.error
    if (entitiesResult.error) throw entitiesResult.error

    if (accountResult.data) {
      const economicEntities: EconomicEntitySummary[] = (entitiesResult.data ?? [])
        .map((row: any) => row.economic_entities)
        .filter(Boolean)
        .map((entity: any) => ({
          id: entity.id,
          displayName: entity.display_name,
          entityType: entity.entity_type,
        }))

      activeAccount = {
        id: accountResult.data.id,
        createdAt: accountResult.data.created_at,
        economicEntities,
      }
    }
  }

  if (base.activeAccountId && base.activeEngagementId) {
    const { data, error } = await supabase
      .from('planning_engagements')
      .select('id, client_account_id, state, opened_at, closed_at, predecessor_engagement_id')
      .eq('id', base.activeEngagementId)
      .eq('client_account_id', base.activeAccountId)
      .maybeSingle()

    if (error) throw error

    if (data) {
      activeEngagement = {
        id: data.id,
        clientAccountId: data.client_account_id,
        state: data.state,
        openedAt: data.opened_at,
        closedAt: data.closed_at,
        predecessorEngagementId: data.predecessor_engagement_id,
      }
    }
  }

  return {
    ...base,
    activeAccount,
    activeEngagement,
  }
}
