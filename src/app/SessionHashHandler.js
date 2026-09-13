'use client'
import { useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '../lib/supabase'

// Safety net for legacy/auth links that land with tokens in the URL hash.
// Recovery links are routed to /nova-senha; other authenticated links continue
// to /dashboard after the browser client establishes the session.
export default function SessionHashHandler() {
  const router = useRouter()

  useEffect(() => {
    if (typeof window === 'undefined') return
    if (!window.location.hash.includes('access_token')) return

    const hashParams = new URLSearchParams(window.location.hash.slice(1))
    const authType = hashParams.get('type')
    const supabase = createClient()

    supabase.auth.getSession().then(({ data }) => {
      if (data.session) {
        window.history.replaceState(null, '', window.location.pathname)
        router.replace(authType === 'recovery' ? '/nova-senha' : '/dashboard')
      }
    })
  }, [router])

  return null
}
