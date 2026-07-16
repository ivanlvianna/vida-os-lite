'use client'
import { useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '../lib/supabase'

// Safety net: if an auth link ever lands here with tokens in the URL hash
// fragment (#access_token=...) instead of going through /auth/confirm —
// e.g. an admin-generated link from the Supabase dashboard, or any template
// still using {{ .ConfirmationURL }} — the hash never reaches the server,
// so no page-level code could otherwise pick it up. Instantiating the
// browser Supabase client here triggers its built-in detectSessionInUrl
// handling, which reads the hash, establishes the session, and lets us
// route the user forward instead of silently dropping them on this page.
export default function SessionHashHandler() {
  const router = useRouter()

  useEffect(() => {
    if (typeof window === 'undefined') return
    if (!window.location.hash.includes('access_token')) return

    const supabase = createClient()
    supabase.auth.getSession().then(({ data }) => {
      if (data.session) {
        window.history.replaceState(null, '', window.location.pathname)
        router.replace('/dashboard')
      }
    })
  }, [router])

  return null
}
