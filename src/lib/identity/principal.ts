import type {
  AuthorizationRole,
  AuthorizationScopeType,
} from '../vida-os/types'

export type AuthProvider = 'supabase'

export interface PrincipalSession {
  readonly isAuthenticated: boolean
  readonly provider: AuthProvider
  readonly authUserId?: string
  readonly email?: string
}

/**
 * Resolved active authorization carried by CurrentPrincipal.
 * Membership existence and authorization remain distinct in PostgreSQL; this
 * projection exposes only active role/scope facts consumed by the app layer.
 */
export type Membership = Readonly<{
  clientAccountId: string
  role: AuthorizationRole
  scopeType: AuthorizationScopeType
  planningEngagementId?: string
  economicEntityId?: string
}>

export type IdentityState = 'pending_invitation' | 'active' | 'disabled'

/**
 * Central identity contract. IdentityContext resolves it; ClientContext derives
 * account-facing UI state from it. Active context is navigation state only and
 * is never a source of authorization.
 */
export interface CurrentPrincipal {
  readonly session: PrincipalSession
  readonly isInternalStaff: boolean
  readonly memberships: readonly Membership[]
  readonly activeClientAccountId?: string
  readonly identityState?: IdentityState
}

export const ANONYMOUS_PRINCIPAL: CurrentPrincipal = {
  session: {
    isAuthenticated: false,
    provider: 'supabase',
  },
  isInternalStaff: false,
  memberships: [],
}
