import type { CurrentPrincipal } from '../identity/principal'

export type ServiceRoleAction =
  | { type: 'activate_client' }

export type ServiceRoleAuthorization =
  | { allowed: true }
  | {
      allowed: false
      reason: 'unauthenticated' | 'internal_staff_required'
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
  }
}
