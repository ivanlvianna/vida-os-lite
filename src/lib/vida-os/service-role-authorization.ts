import type { CurrentPrincipal } from '../identity/principal'

export type ServiceRoleAction =
  | { type: 'activate_client' }
  | { type: 'invite_client'; clientAccountId: string }

export type ServiceRoleAuthorization =
  | { allowed: true }
  | {
      allowed: false
      reason:
        | 'unauthenticated'
        | 'internal_staff_required'
        | 'planner_owner_required'
    }

/**
 * Single application-layer gate for operations that require a service-role
 * client. It never grants account/domain permissions that PostgreSQL/RLS owns.
 */
export function authorizeServiceRoleAction(
  principal: CurrentPrincipal,
  action: ServiceRoleAction
): ServiceRoleAuthorization {
  if (!principal.session.isAuthenticated || !principal.session.authUserId) {
    return { allowed: false, reason: 'unauthenticated' }
  }

  switch (action.type) {
    case 'activate_client':
      return principal.isInternalStaff
        ? { allowed: true }
        : { allowed: false, reason: 'internal_staff_required' }

    case 'invite_client': {
      const isPlannerOwner = principal.memberships.some(
        (membership) =>
          membership.clientAccountId === action.clientAccountId &&
          membership.role === 'planner_owner' &&
          membership.scopeType === 'account'
      )

      return isPlannerOwner
        ? { allowed: true }
        : { allowed: false, reason: 'planner_owner_required' }
    }
  }
}
