import type { SupabaseClient } from '@supabase/supabase-js'
import { VidaOsError } from './errors'

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

function assertNonBlank(value: string, field: string) {
  if (!value.trim()) {
    throw new VidaOsError('INVALID_INPUT', `${field} must not be blank.`)
  }
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
