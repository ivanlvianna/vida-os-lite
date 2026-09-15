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
const EXPECTED_D3_URL = `https://${EXPECTED_D3_REF}.supabase.co`

function assertD3ServiceRoleKey() {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY

  if (!url || !key) {
    throw new VidaOsError('MISSING_SERVER_CONFIGURATION', 'D3 server configuration is incomplete.')
  }

  if (url !== EXPECTED_D3_URL) {
    throw new VidaOsError('MISSING_SERVER_CONFIGURATION', 'Supabase URL is not the D3 homologation project. Invite blocked safely.')
  }

  // Modern Supabase secret keys are opaque sb_secret_... values and do not
  // contain a JWT payload with the project ref. The exact D3 project is
  // therefore pinned by NEXT_PUBLIC_SUPABASE_URL above.
  if (key.startsWith('sb_secret_')) {
    return
  }

  // Backward-compatible validation for legacy service_role JWT keys.
  const parts = key.split('.')
  if (parts.length !== 3) {
    throw new VidaOsError('MISSING_SERVER_CONFIGURATION', 'Administrative key format is not recognized. Invite blocked safely.')
  }

  try {
    const payload = JSON.parse(Buffer.from(parts[1], 'base64url').toString('utf8')) as { ref?: string; role?: string }
    if (payload.ref !== EXPECTED_D3_REF || payload.role !== 'service_role') {
      throw new Error('mismatch')
    }
  } catch {
    throw new VidaOsError('MISSING_SERVER_CONFIGURATION', 'Administrative key is not the D3 homologation key. Invite blocked safely.')
  }
}

function safeCauseSummary(cause: unknown): string | null {
  if (!cause || typeof cause !== 'object') return null

  const value = cause as { message?: unknown; code?: unknown; status?: unknown; name?: unknown }
  const parts: string[] = []

  if (typeof value.name === 'string' && value.name) parts.push(`name=${value.name}`)
  if (typeof value.code === 'string' && value.code) parts.push(`code=${value.code}`)
  if (typeof value.status === 'number') parts.push(`status=${value.status}`)
  if (typeof value.message === 'string' && value.message) parts.push(`message=${value.message}`)

  return parts.length ? parts.join('; ') : null
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
      const causeSummary = safeCauseSummary(error.causeValue)
      return {
        ok: false,
        code: error.code,
        message: causeSummary ? `${error.message} [${causeSummary}]` : error.message,
      }
    }

    return {
      ok: false,
      code: 'UNEXPECTED_ERROR',
      message: 'InviteClientWorkflow live E2E failed unexpectedly.',
    }
  }
}
