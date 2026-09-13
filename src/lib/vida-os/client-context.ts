import type { SupabaseClient } from '@supabase/supabase-js'
import type {
  CurrentPrincipal,
  IdentityState,
} from '../identity/principal'
import type { AuthorizationRole } from './types'

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
  identityState?: IdentityState
  activeAccountId?: string
  activeEngagementId?: string
}

export type ClientContext = ClientContextBase & {
  activeAccount: ActiveAccount | null
  activeEngagement: ActiveEngagement | null
}

type LinkedEntityRow = {
  economic_entities: {
    id: string
    display_name: string
    entity_type: string
  } | null
}

export function deriveClientContextBase(
  principal: CurrentPrincipal,
  requestedPlanningEngagementId?: string
): ClientContextBase {
  const accountIds = Array.from(
    new Set(principal.memberships.map((membership) => membership.clientAccountId))
  )

  const availableAccounts: AvailableAccount[] = accountIds.map((accountId) => ({
    id: accountId,
    roles: Array.from(
      new Set(
        principal.memberships
          .filter(
            (membership) =>
              membership.clientAccountId === accountId &&
              membership.scopeType === 'account'
          )
          .map((membership) => membership.role)
      )
    ),
  }))

  const accountRoles = principal.activeClientAccountId
    ? principal.memberships
        .filter(
          (membership) =>
            membership.clientAccountId === principal.activeClientAccountId &&
            membership.scopeType === 'account'
        )
        .map((membership) => membership.role)
    : []

  const plannerRole = accountRoles.includes('planner_owner')
    ? 'planner_owner'
    : accountRoles.includes('internal_staff')
      ? 'internal_staff'
      : null

  // Identity state is a client-final self-assessment. Global internal staff is
  // deliberately not treated as a pending client merely because it has no
  // account membership.
  const identityState: IdentityState | undefined = principal.isInternalStaff
    ? undefined
    : principal.memberships.length > 0
      ? 'active'
      : principal.session.isAuthenticated
        ? 'pending_invitation'
        : undefined

  return {
    availableAccounts,
    plannerRole,
    identityState,
    ...(principal.activeClientAccountId
      ? { activeAccountId: principal.activeClientAccountId }
      : {}),
    ...(requestedPlanningEngagementId
      ? { activeEngagementId: requestedPlanningEngagementId }
      : {}),
  }
}

export async function enrichClientContext(
  supabase: SupabaseClient,
  principal: CurrentPrincipal,
  requestedPlanningEngagementId?: string
): Promise<ClientContext> {
  const base = deriveClientContextBase(principal, requestedPlanningEngagementId)

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
        .select('economic_entities(id, display_name, entity_type)')
        .eq('client_account_id', base.activeAccountId),
    ])

    if (accountResult.error) throw accountResult.error
    if (entitiesResult.error) throw entitiesResult.error

    if (accountResult.data) {
      const entityRows = (entitiesResult.data ?? []) as unknown as LinkedEntityRow[]
      const economicEntities = entityRows
        .map((row) => row.economic_entities)
        .filter(
          (entity): entity is NonNullable<LinkedEntityRow['economic_entities']> =>
            entity !== null
        )
        .map((entity) => ({
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
      .select(
        'id, client_account_id, state, opened_at, closed_at, predecessor_engagement_id'
      )
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
