import type { SupabaseClient } from '@supabase/supabase-js'
import {
  ANONYMOUS_PRINCIPAL,
  type ActiveContext,
  type AuthorizationRole,
  type AuthorizationScope,
  type CurrentPrincipal,
  type PrincipalAuthorization,
} from './principal'

type MembershipRow = {
  client_account_id: string
  created_at: string
}

type AuthorizationRow = {
  id: string
  client_account_id: string
  role: AuthorizationRole
  scope_type: AuthorizationScope
  planning_engagement_id: string | null
  economic_entity_id: string | null
}

function normalizeRequestedContext(
  memberships: MembershipRow[],
  requestedContext?: Partial<ActiveContext>
): ActiveContext {
  const accountIds = new Set(memberships.map((row) => row.client_account_id))
  const requestedAccountId = requestedContext?.clientAccountId ?? null

  const clientAccountId =
    requestedAccountId && accountIds.has(requestedAccountId)
      ? requestedAccountId
      : memberships.length === 1
        ? memberships[0].client_account_id
        : null

  return {
    clientAccountId,
    planningEngagementId:
      clientAccountId && requestedContext?.planningEngagementId
        ? requestedContext.planningEngagementId
        : null,
  }
}

/**
 * Framework-agnostic identity resolver.
 *
 * It may read auth/session facts and RLS-protected identity/account data, but it
 * does not execute workflows and does not make domain-write authorization
 * decisions.
 */
export async function resolveCurrentPrincipal(
  supabase: SupabaseClient,
  requestedContext?: Partial<ActiveContext>
): Promise<CurrentPrincipal> {
  const {
    data: { user },
    error: userError,
  } = await supabase.auth.getUser()

  if (!user) {
    if (userError) {
      return ANONYMOUS_PRINCIPAL
    }
    return ANONYMOUS_PRINCIPAL
  }

  const [membershipsResult, authorizationsResult] = await Promise.all([
    supabase
      .from('client_account_users')
      .select('client_account_id, created_at')
      .eq('auth_user_id', user.id)
      .order('created_at', { ascending: true }),
    supabase
      .from('client_account_user_authorizations')
      .select(
        'id, client_account_id, role, scope_type, planning_engagement_id, economic_entity_id'
      )
      .eq('auth_user_id', user.id)
      .is('revoked_at', null),
  ])

  if (membershipsResult.error) throw membershipsResult.error
  if (authorizationsResult.error) throw authorizationsResult.error

  const membershipRows = (membershipsResult.data ?? []) as MembershipRow[]
  const authorizationRows = (authorizationsResult.data ?? []) as AuthorizationRow[]

  const authorizations: PrincipalAuthorization[] = authorizationRows.map((row) => ({
    id: row.id,
    clientAccountId: row.client_account_id,
    role: row.role,
    scopeType: row.scope_type,
    planningEngagementId: row.planning_engagement_id,
    economicEntityId: row.economic_entity_id,
  }))

  const memberships = membershipRows.map((row) => ({
    clientAccountId: row.client_account_id,
    joinedAt: row.created_at,
    authorizations: authorizations.filter(
      (authorization) => authorization.clientAccountId === row.client_account_id
    ),
  }))

  const provider =
    (typeof user.app_metadata?.provider === 'string' && user.app_metadata.provider) ||
    user.identities?.[0]?.provider ||
    null

  return {
    session: {
      isAuthenticated: true,
      provider,
      authUserId: user.id,
      email: user.email ?? null,
    },
    // Current architecture keeps the global administrative capability in Auth
    // metadata. Account-scoped staff authority still comes from PostgreSQL/RLS.
    isInternalStaff: user.app_metadata?.internal_staff === true,
    memberships,
    activeContext: normalizeRequestedContext(membershipRows, requestedContext),
    identityState: memberships.length > 0 ? 'active' : 'pending_invitation',
  }
}
