'use server'

import { inviteClientWorkflow } from '../../../app-services/invite-client'
import { resolveCurrentPrincipal } from '../../../lib/identity/identity-context'
import { createSessionContext } from '../../../lib/identity/session-context'
import { createServiceRoleClient } from '../../../lib/vida-os/service-role-client'
import { VidaOsError } from '../../../lib/vida-os/errors'

export type InviteE2EResult =
  | { ok: true; authUserId: string; email: string | null }
  | { ok: false; code: string; message: string }

const CLIENT_ACCOUNT_ID = 'c21d928b-e627-41ff-97bf-d4dd331b00c2'
const TEST_EMAIL = 'vidaos.e2e.invite.20260914@example.com'
const EXPECTED_D3_REF = 'aregdlspacytbrrdowps'

function assertD3ServiceRoleKey() {
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY
  if (!key) {
    throw new VidaOsError('MISSING_SERVER_CONFIGURATION', 'D3 service-role key is not configured.')
  }

  const parts = key.split('.')
  if (parts.length !== 3) {
    throw new VidaOsError('MISSING_SERVER_CONFIGURATION', 'Service-role key format cannot be verified safely for D3.')
  }

  try {
    const payload = JSON.parse(Buffer.from(parts[1], 'base64url').toString('utf8')) as { ref?: string; role?: string }
    if (payload.ref !== EXPECTED_D3_REF || payload.role !== 'service_role') {
      throw new Error('mismatch')
    }
  } catch {
    throw new VidaOsError('MISSING_SERVER_CONFIGURATION', 'Service-role key is not the D3 homologation key. Invite blocked safely.')
  }
}

export async function runInviteClientE2E(): Promise<InviteE2EResult> {
  try {
    assertD3ServiceRoleKey()
    const authenticatedClient = await createSessionContext()
    const principal = await resolveCurrentPrincipal(authenticatedClient)
    const serviceClient = createServiceRoleClient()

    const result = await inviteClientWorkflow(principal, serviceClient, {
      clientAccountId: CLIENT_ACCOUNT_ID,
      email: TEST_EMAIL,
    })

    return { ok: true, authUserId: result.authUserId, email: result.email }
  } catch (error) {
    if (error instanceof VidaOsError) {
      return { ok: false, code: error.code, message: error.message }
    }

    return {
      ok: false,
      code: 'UNEXPECTED_ERROR',
      message: 'InviteClientWorkflow live E2E failed unexpectedly.',
    }
  }
}
