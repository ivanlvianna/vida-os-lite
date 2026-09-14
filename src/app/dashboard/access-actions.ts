'use server'

import { grantAccessWorkflow } from '../../app-services/grant-access'
import { revokeAccessWorkflow } from '../../app-services/revoke-access'
import { changeEngagementStateWorkflow } from '../../app-services/change-engagement-state'
import { resolveCurrentPrincipal } from '../../lib/identity/identity-context'
import { createSessionContext } from '../../lib/identity/session-context'
import { VidaOsError } from '../../lib/vida-os/errors'
import type { OnboardClientAccountMemberInput } from '../../lib/vida-os/rpc'
import type {
  AuthorizationRole,
  PlanningEngagementState,
  PlanningEventOrigin,
} from '../../lib/vida-os/types'

type DeliveryActionSuccess<T extends object | void> = T extends void
  ? { ok: true }
  : { ok: true } & T

export type DeliveryActionResult<T extends object | void = void> =
  | DeliveryActionSuccess<T>
  | { ok: false; code: string; message: string }

const AUTHORIZATION_ROLES: AuthorizationRole[] = [
  'planner_owner',
  'internal_staff',
  'client_primary',
  'client_participant',
  'external_advisor',
]

const PLANNING_STATES: PlanningEngagementState[] = [
  'onboarding_em_andamento',
  'dados_incompletos',
  'dados_completos',
  'diagnostico_em_elaboracao',
  'diagnostico_validado',
  'plano_em_elaboracao',
  'plano_aprovado',
  'implementacao',
  'acompanhamento',
  'revisao',
  'documentos_pendentes',
  'pausado',
  'encerrado_concluido',
  'encerrado_cancelado',
  'abandonado',
]

const EVENT_ORIGINS: PlanningEventOrigin[] = [
  'system',
  'planner',
  'client',
  'external',
]

function text(formData: FormData, name: string): string | null {
  const value = formData.get(name)
  if (typeof value !== 'string') return null
  const trimmed = value.trim()
  return trimmed.length > 0 ? trimmed : null
}

function requiredText(formData: FormData, name: string): string {
  const value = text(formData, name)
  if (!value) {
    throw new VidaOsError('INVALID_INPUT', `${name} is required.`)
  }
  return value
}

function oneOf<T extends string>(
  value: string,
  allowed: readonly T[],
  field: string
): T {
  if (!allowed.includes(value as T)) {
    throw new VidaOsError('INVALID_INPUT', `${field} has an invalid value.`)
  }
  return value as T
}

function failure<T extends object | void = void>(
  error: unknown
): DeliveryActionResult<T> {
  if (error instanceof VidaOsError) {
    return { ok: false, code: error.code, message: error.message }
  }

  return {
    ok: false,
    code: 'UNEXPECTED_ERROR',
    message: 'VIDA OS operation failed unexpectedly.',
  }
}

export async function grantAccessAction(
  formData: FormData
): Promise<DeliveryActionResult<{ authorizationId: string }>> {
  try {
    const authenticatedClient = await createSessionContext()
    const principal = await resolveCurrentPrincipal(authenticatedClient)

    const clientAccountId = requiredText(formData, 'clientAccountId')
    const targetAuthUserId = requiredText(formData, 'targetAuthUserId')
    const role = oneOf(
      requiredText(formData, 'role'),
      AUTHORIZATION_ROLES,
      'role'
    )
    const scopeType = oneOf(
      requiredText(formData, 'scopeType'),
      ['account', 'engagement', 'entity'] as const,
      'scopeType'
    )

    let input: OnboardClientAccountMemberInput
    if (scopeType === 'account') {
      input = { clientAccountId, targetAuthUserId, role, scopeType }
    } else if (scopeType === 'engagement') {
      input = {
        clientAccountId,
        targetAuthUserId,
        role,
        scopeType,
        planningEngagementId: requiredText(formData, 'planningEngagementId'),
      }
    } else {
      input = {
        clientAccountId,
        targetAuthUserId,
        role,
        scopeType,
        economicEntityId: requiredText(formData, 'economicEntityId'),
      }
    }

    const result = await grantAccessWorkflow(
      principal,
      authenticatedClient,
      input
    )

    return { ok: true, authorizationId: result.authorizationId }
  } catch (error) {
    return failure<{ authorizationId: string }>(error)
  }
}

export async function revokeAccessAction(
  formData: FormData
): Promise<DeliveryActionResult<void>> {
  try {
    const authenticatedClient = await createSessionContext()
    const principal = await resolveCurrentPrincipal(authenticatedClient)

    await revokeAccessWorkflow(principal, authenticatedClient, {
      authorizationId: requiredText(formData, 'authorizationId'),
    })

    return { ok: true }
  } catch (error) {
    return failure<void>(error)
  }
}

export async function changeEngagementStateAction(
  formData: FormData
): Promise<DeliveryActionResult<{ transitionId: string }>> {
  try {
    const authenticatedClient = await createSessionContext()
    const principal = await resolveCurrentPrincipal(authenticatedClient)

    const eventOriginRaw = text(formData, 'eventOrigin')
    const eventOrigin = eventOriginRaw
      ? oneOf(eventOriginRaw, EVENT_ORIGINS, 'eventOrigin')
      : null

    const result = await changeEngagementStateWorkflow(
      principal,
      authenticatedClient,
      {
        engagementId: requiredText(formData, 'engagementId'),
        toState: oneOf(
          requiredText(formData, 'toState'),
          PLANNING_STATES,
          'toState'
        ),
        event: requiredText(formData, 'event'),
        requiredDocument: text(formData, 'requiredDocument'),
        reason: text(formData, 'reason'),
        automaticEffect: text(formData, 'automaticEffect'),
        eventOrigin,
      }
    )

    return { ok: true, transitionId: result.transitionId }
  } catch (error) {
    return failure<{ transitionId: string }>(error)
  }
}
