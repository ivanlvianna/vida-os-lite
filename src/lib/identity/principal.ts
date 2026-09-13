export type IdentityState = 'anonymous' | 'pending_invitation' | 'active'

export type AuthorizationRole =
  | 'planner_owner'
  | 'internal_staff'
  | 'client_primary'
  | 'client_participant'
  | 'external_advisor'

export type AuthorizationScope = 'account' | 'engagement' | 'entity'

export type SessionIdentity = {
  isAuthenticated: boolean
  provider: string | null
  authUserId: string | null
  email: string | null
}

export type PrincipalAuthorization = {
  id: string
  clientAccountId: string
  role: AuthorizationRole
  scopeType: AuthorizationScope
  planningEngagementId: string | null
  economicEntityId: string | null
}

export type PrincipalMembership = {
  clientAccountId: string
  joinedAt: string
  authorizations: PrincipalAuthorization[]
}

export type ActiveContext = {
  clientAccountId: string | null
  planningEngagementId: string | null
}

export type CurrentPrincipal = {
  session: SessionIdentity
  isInternalStaff: boolean
  memberships: PrincipalMembership[]
  activeContext: ActiveContext
  identityState: IdentityState
}

export const ANONYMOUS_PRINCIPAL: CurrentPrincipal = {
  session: {
    isAuthenticated: false,
    provider: null,
    authUserId: null,
    email: null,
  },
  isInternalStaff: false,
  memberships: [],
  activeContext: {
    clientAccountId: null,
    planningEngagementId: null,
  },
  identityState: 'anonymous',
}
