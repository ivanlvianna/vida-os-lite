import type { SupabaseClient } from '@supabase/supabase-js'
import { VidaOsError } from './errors'
import type {
  AuthorizationRole,
  PlanningEngagementState,
  PlanningEventOrigin,
} from './types'

export type VriIdentityResolution = 'no_match' | 'match_confident' | 'ambiguous_match'

export type ActivateClientFromVriInput =
  | {
      plannerAuthUserId: string
      vriCorrelationId: string
      vriActivationCorrelationId: string
      identityResolution: 'no_match'
      entityType: 'person' | 'organization'
      displayName: string
      existingEconomicEntityId?: never
    }
  | {
      plannerAuthUserId: string
      vriCorrelationId: string
      vriActivationCorrelationId: string
      identityResolution: 'match_confident'
      existingEconomicEntityId: string
      entityType?: never
      displayName?: never
    }
  | {
      plannerAuthUserId: string
      vriCorrelationId: string
      vriActivationCorrelationId: string
      identityResolution: 'ambiguous_match'
      existingEconomicEntityId?: string
      entityType?: 'person' | 'organization'
      displayName?: string
    }

export type ActivateClientFromVriResult = {
  clientAccountId: string
  economicEntityId: string
  planningEngagementId: string
}

export type OnboardClientAccountMemberInput =
  | {
      clientAccountId: string
      targetAuthUserId: string
      role: AuthorizationRole
      scopeType: 'account'
      planningEngagementId?: never
      economicEntityId?: never
    }
  | {
      clientAccountId: string
      targetAuthUserId: string
      role: AuthorizationRole
      scopeType: 'engagement'
      planningEngagementId: string
      economicEntityId?: never
    }
  | {
      clientAccountId: string
      targetAuthUserId: string
      role: AuthorizationRole
      scopeType: 'entity'
      planningEngagementId?: never
      economicEntityId: string
    }

export type RecordPlanningEngagementTransitionInput = {
  engagementId: string
  toState: PlanningEngagementState
  event: string
  requiredDocument?: string | null
  reason?: string | null
  automaticEffect?: string | null
  eventOrigin?: PlanningEventOrigin | null
}

function assertNonBlank(value: string, field: string) {
  if (!value.trim()) {
    throw new VidaOsError('INVALID_INPUT', `${field} must not be blank.`)
  }
}

function optionalText(value: string | null | undefined): string | null {
  if (value == null) return null
  const trimmed = value.trim()
  return trimmed.length > 0 ? trimmed : null
}

/**
 * Thin RPC adapter. Domain invariants remain authoritative in PostgreSQL.
 */
export async function activateClientFromVri(
  serviceClient: SupabaseClient,
  input: ActivateClientFromVriInput
): Promise<ActivateClientFromVriResult> {
  assertNonBlank(input.vriCorrelationId, 'vriCorrelationId')
  assertNonBlank(input.vriActivationCorrelationId, 'vriActivationCorrelationId')

  if (input.identityResolution === 'ambiguous_match') {
    throw new VidaOsError(
      'INVALID_INPUT',
      'ambiguous_match requires human review and cannot activate automatically.'
    )
  }

  if (input.identityResolution === 'no_match') {
    assertNonBlank(input.displayName, 'displayName')
  }

  const { data, error } = await serviceClient.rpc('activate_client_from_vri', {
    p_planner_auth_user_id: input.plannerAuthUserId,
    p_vri_correlation_id: input.vriCorrelationId,
    p_vri_activation_correlation_id: input.vriActivationCorrelationId,
    p_identity_resolution: input.identityResolution,
    p_existing_economic_entity_id:
      input.identityResolution === 'match_confident'
        ? input.existingEconomicEntityId
        : null,
    p_entity_type: input.identityResolution === 'no_match' ? input.entityType : null,
    p_display_name: input.identityResolution === 'no_match' ? input.displayName.trim() : null,
  })

  if (error) {
    throw new VidaOsError(
      'DOMAIN_RPC_FAILED',
      'Canonical VRI activation RPC failed.',
      error
    )
  }

  const row = Array.isArray(data) ? data[0] : null

  if (
    !row ||
    typeof row.client_account_id !== 'string' ||
    typeof row.economic_entity_id !== 'string' ||
    typeof row.planning_engagement_id !== 'string'
  ) {
    throw new VidaOsError(
      'DOMAIN_RPC_FAILED',
      'Canonical VRI activation RPC returned an invalid result shape.'
    )
  }

  return {
    clientAccountId: row.client_account_id,
    economicEntityId: row.economic_entity_id,
    planningEngagementId: row.planning_engagement_id,
  }
}

/**
 * Atomic membership + authorization adapter for v0.7.
 * Authorization and domain constraints stay inside PostgreSQL.
 */
export async function onboardClientAccountMember(
  authenticatedClient: SupabaseClient,
  input: OnboardClientAccountMemberInput
): Promise<string> {
  assertNonBlank(input.clientAccountId, 'clientAccountId')
  assertNonBlank(input.targetAuthUserId, 'targetAuthUserId')

  if (input.scopeType === 'engagement') {
    assertNonBlank(input.planningEngagementId, 'planningEngagementId')
  }

  if (input.scopeType === 'entity') {
    assertNonBlank(input.economicEntityId, 'economicEntityId')
  }

  const { data, error } = await authenticatedClient.rpc('onboard_client_account_member', {
    p_client_account_id: input.clientAccountId,
    p_target_auth_user_id: input.targetAuthUserId,
    p_role: input.role,
    p_scope_type: input.scopeType,
    p_planning_engagement_id:
      input.scopeType === 'engagement' ? input.planningEngagementId : null,
    p_economic_entity_id: input.scopeType === 'entity' ? input.economicEntityId : null,
  })

  if (error) {
    throw new VidaOsError(
      'DOMAIN_RPC_FAILED',
      'Canonical member onboarding RPC failed.',
      error
    )
  }

  if (typeof data !== 'string' || !data) {
    throw new VidaOsError(
      'DOMAIN_RPC_FAILED',
      'Canonical member onboarding RPC returned an invalid result shape.'
    )
  }

  return data
}

/**
 * Revocation adapter. The canonical RPC returns void and preserves history.
 */
export async function revokeClientAccountAuthorization(
  authenticatedClient: SupabaseClient,
  authorizationId: string
): Promise<void> {
  assertNonBlank(authorizationId, 'authorizationId')

  const { error } = await authenticatedClient.rpc('revoke_client_account_authorization', {
    p_authorization_id: authorizationId,
  })

  if (error) {
    throw new VidaOsError(
      'DOMAIN_RPC_FAILED',
      'Canonical authorization revocation RPC failed.',
      error
    )
  }
}

/**
 * Planning Engagement state-transition adapter.
 * The PostgreSQL state machine remains the only authority on valid transitions,
 * terminal states, pause/resume behavior, required reason and actor/origin rules.
 */
export async function recordPlanningEngagementTransition(
  authenticatedClient: SupabaseClient,
  input: RecordPlanningEngagementTransitionInput
): Promise<string> {
  assertNonBlank(input.engagementId, 'engagementId')
  assertNonBlank(input.event, 'event')

  const { data, error } = await authenticatedClient.rpc(
    'record_planning_engagement_transition',
    {
      p_engagement_id: input.engagementId,
      p_to_state: input.toState,
      p_event: input.event.trim(),
      p_required_document: optionalText(input.requiredDocument),
      p_reason: optionalText(input.reason),
      p_automatic_effect: optionalText(input.automaticEffect),
      p_event_origin: input.eventOrigin ?? null,
    }
  )

  if (error) {
    throw new VidaOsError(
      'DOMAIN_RPC_FAILED',
      'Canonical Planning Engagement transition RPC failed.',
      error
    )
  }

  if (typeof data !== 'string' || !data) {
    throw new VidaOsError(
      'DOMAIN_RPC_FAILED',
      'Canonical Planning Engagement transition RPC returned an invalid result shape.'
    )
  }

  return data
}
