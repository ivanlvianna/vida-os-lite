import type { SupabaseClient } from '@supabase/supabase-js'
import type {
  AuthorizationRole,
  AuthorizationScopeType,
} from '../vida-os/types'
import {
  ANONYMOUS_PRINCIPAL,
  type CurrentPrincipal,
  type Membership,
} from './principal'

type AuthorizationRow = {
  client_account_id: string
  role: AuthorizationRole
  scope_type: AuthorizationScopeType
  planning_engagement_id: string | null
  economic_entity_id: string | null
}

function resolveActiveClientAccountId(
  memberships: readonly Membership[],
  requestedClientAccountId?: string
): string | undefined {
  const accountIds = Array.from(
    new Set(memberships.map((membership) => membership.clientAccountId))
  )

  if (requestedClientAccountId && accountIds.includes(requestedClientAccountId)) {
    return requestedClientAccountId
  }

  return accountIds.length === 1 ? accountIds[0] : undefined
}

/**
 * Framework-agnostic identity resolver.
 *
 * It may inspect session/auth metadata and RLS-protected authorization facts.
 * It never executes a workflow and never replaces PostgreSQL authorization.
 */
export async function resolveCurrentPrincipal(
  supabase: SupabaseClient,
  requestedClientAccountId?: string
): Promise<CurrentPrincipal> {
  const {
    data: { user },
  } = await supabase.auth.getUser()

  if (!user) return ANONYMOUS_PRINCIPAL

  const { data, error } = await supabase
    .from('client_account_user_authorizations')
    .select(
      'client_account_id, role, scope_type, planning_engagement_id, economic_entity_id'
    )
    .eq('auth_user_id', user.id)
    .is('revoked_at', null)

  if (error) throw error

  const memberships: readonly Membership[] = ((data ?? []) as AuthorizationRow[]).map(
    (row) => ({
      clientAccountId: row.client_account_id,
      role: row.role,
      scopeType: row.scope_type,
      ...(row.planning_engagement_id
        ? { planningEngagementId: row.planning_engagement_id }
        : {}),
      ...(row.economic_entity_id
        ? { economicEntityId: row.economic_entity_id }
        : {}),
    })
  )

  return {
    session: {
      isAuthenticated: true,
      provider: 'supabase',
      authUserId: user.id,
      ...(user.email ? { email: user.email } : {}),
    },
    // Global administrative privilege remains an Auth fact. Account-scoped
    // authority remains in PostgreSQL authorizations/RLS.
    isInternalStaff: user.app_metadata?.internal_staff === true,
    memberships,
    activeClientAccountId: resolveActiveClientAccountId(
      memberships,
      requestedClientAccountId
    ),
  }
}
