'use server'

import { createServerClient } from '@supabase/ssr'
import { cookies } from 'next/headers'
import { redirect } from 'next/navigation'

export async function salvarOnboarding(formData: {
  nome_completo: string
  telefone_whatsapp: string
  data_nascimento: string
  profissao: string
  estado_civil: string
  numero_dependentes: number
  possui_empresa: boolean | null
  possui_imoveis: boolean | null
  faixa_patrimonio: string
  lgpd_aceito: boolean
  termos_aceito: boolean
}) {
  const cookieStore = cookies()

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return cookieStore.getAll()
        },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value, options }) => {
            cookieStore.set(name, value, options)
          })
        },
      },
    }
  )

  const { data: { user }, error: authError } = await supabase.auth.getUser()

  if (authError || !user) {
    return { erro: 'Sessão expirada. Faça login novamente.' }
  }

  const { error } = await supabase
    .from('users_profile')
    .upsert({
      id: user.id,
      nome_completo: formData.nome_completo || null,
      telefone_whatsapp: formData.telefone_whatsapp,
      data_nascimento: formData.data_nascimento || null,
      profissao: formData.profissao || null,
      estado_civil: formData.estado_civil || null,
      numero_dependentes: Number(formData.numero_dependentes),
      possui_empresa: formData.possui_empresa,
      possui_imoveis: formData.possui_imoveis,
      faixa_patrimonio: formData.faixa_patrimonio || null,
      lgpd_aceito: formData.lgpd_aceito,
      termos_aceito: formData.termos_aceito,
      onboarding_concluido: true,
      updated_at: new Date().toISOString(),
    }, { onConflict: 'id' })

  if (error) {
    console.error('Supabase error:', error)
    return { erro: 'Erro ao salvar as informações. Tente novamente.' }
  }

  redirect('/dashboard')
}
