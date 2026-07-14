'use server'

import { createServerClient } from '@supabase/ssr'
import { cookies } from 'next/headers'

async function getSupabase() {
  const cookieStore = cookies()
  return createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() { return cookieStore.getAll() },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value, options }) => cookieStore.set(name, value, options))
        },
      },
    }
  )
}

export async function salvarProntuario(dados: Record<string, string | number | boolean>) {
  const supabase = await getSupabase()
  const { data: { user }, error: authError } = await supabase.auth.getUser()
  if (authError || !user) return { erro: 'Sessão expirada. Faça login novamente.' }

  const { error } = await supabase
    .from('prontuario_patrimonial')
    .upsert({
      user_id: user.id,
      dados: dados,
      updated_at: new Date().toISOString(),
    }, { onConflict: 'user_id' })

  if (error) {
    console.error('Supabase error:', error)
    return { erro: 'Erro ao salvar. Tente novamente.' }
  }

  return { ok: true }
}

export async function carregarProntuario() {
  const supabase = await getSupabase()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) return null

  const { data } = await supabase
    .from('prontuario_patrimonial')
    .select('dados')
    .eq('user_id', user.id)
    .single()

  return data?.dados || null
}
