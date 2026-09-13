'use server'

import { activateClientWorkflow } from '../../app-services/activate-client'
import { resolveCurrentPrincipal } from '../../lib/identity/identity-context'
import { createSessionContext } from '../../lib/identity/session-context'
import { VidaOsError } from '../../lib/vida-os/errors'
import { createServiceRoleClient } from '../../lib/vida-os/service-role-client'

export type ActivateClientActionResult =
  | {
      ok: true
      clientAccountId: string
      economicEntityId: string
      planningEngagementId: string
    }
  | {
      ok: false
      code: string
      message: string
    }

function requiredText(formData: FormData, name: string): string {
  const value = formData.get(name)
  if (typeof value !== 'string' || !value.trim()) {
    throw new VidaOsError('INVALID_INPUT', `${name} is required.`)
  }
  return value.trim()
}

/**
 * Thin Delivery-layer adapter. It resolves session/principal, validates the
 * transport payload and delegates all orchestration to ActivateClientWorkflow.
 * It never performs domain table writes directly.
 */
export async function activateClientAction(
  formData: FormData
): Promise<ActivateClientActionResult> {
  try {
    const sessionClient = await createSessionContext()
    const principal = await resolveCurrentPrincipal(sessionClient)
    const serviceClient = createServiceRoleClient()

    const vriCorrelationId = requiredText(formData, 'vriCorrelationId')
    const vriActivationCorrelationId = requiredText(
      formData,
      'vriActivationCorrelationId'
    )
    const identityResolution = requiredText(formData, 'identityResolution')

    const result =
      identityResolution === 'no_match'
        ? await activateClientWorkflow(principal, serviceClient, {
            vriCorrelationId,
            vriActivationCorrelationId,
            identityResolution: 'no_match',
            entityType: (() => {
              const value = requiredText(formData, 'entityType')
              if (value !== 'person' && value !== 'organization') {
                throw new VidaOsError(
                  'INVALID_INPUT',
                  'entityType must be person or organization.'
                )
              }
              return value
            })(),
            displayName: requiredText(formData, 'displayName'),
          })
        : identityResolution === 'match_confident'
          ? await activateClientWorkflow(principal, serviceClient, {
              vriCorrelationId,
              vriActivationCorrelationId,
              identityResolution: 'match_confident',
              existingEconomicEntityId: requiredText(
                formData,
                'existingEconomicEntityId'
              ),
            })
          : (() => {
              throw new VidaOsError(
                'INVALID_INPUT',
                'identityResolution must be no_match or match_confident.'
              )
            })()

    return { ok: true, ...result }
  } catch (error) {
    if (error instanceof VidaOsError) {
      return {
        ok: false,
        code: error.code,
        message: error.message,
      }
    }

    return {
      ok: false,
      code: 'UNEXPECTED_ERROR',
      message: 'Client activation failed unexpectedly.',
    }
  }
}
