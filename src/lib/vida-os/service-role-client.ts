import { createClient, type SupabaseClient } from '@supabase/supabase-js'
import { VidaOsError } from './errors'

/**
 * Server-only administrative Supabase client.
 *
 * Never import this module from a Client Component. The service-role secret
 * must exist only in the server runtime.
 */
export function createServiceRoleClient(): SupabaseClient {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL
  const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY

  if (!url || !serviceRoleKey) {
    throw new VidaOsError(
      'MISSING_SERVER_CONFIGURATION',
      'Supabase service-role configuration is missing in the server runtime.'
    )
  }

  return createClient(url, serviceRoleKey, {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
      detectSessionInUrl: false,
    },
  })
}
