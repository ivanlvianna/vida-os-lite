import { createServerClient } from '@supabase/ssr'
import { cookies } from 'next/headers'

/**
 * Delivery-layer session client. It owns cookie/session mechanics only.
 * Authorization decisions must stay outside this module.
 */
export async function createSessionContext() {
  const cookieStore = await cookies()

  return createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return cookieStore.getAll()
        },
        setAll(cookiesToSet) {
          try {
            cookiesToSet.forEach(({ name, value, options }) =>
              cookieStore.set(name, value, options)
            )
          } catch {
            // Server Components cannot always persist refreshed cookies.
            // proxy.ts owns request-level session refresh.
          }
        },
      },
    }
  )
}
