import { createClient } from '@supabase/supabase-js'
import { NextResponse } from 'next/server'

// Webhook fino de retorno do Motor Único (Fase 3) para o VIDA OS™ Lite.
//
// O Motor Único é quem roda o questionário, o scoring e a classificação de
// perfil (Construtor/Protetor/Explorador/Estrategista/Desalinhado) — nada
// disso é recalculado aqui. Este endpoint só recebe o resultado já pronto
// (id externo, status, score, perfil, data, link do relatório) e grava em
// diagnosticos_vida, associado ao usuário do VIDA OS™ Lite pelo e-mail.
//
// Autenticação: o Motor Único deve enviar o header
//   X-Motor-Vida-Secret: <MOTOR_VIDA_WEBHOOK_SECRET>
// (mesmo valor configurado nos dois lados — ver .env.local)
//
// Payload esperado (JSON):
// {
//   "email": "pessoa@exemplo.com",
//   "instrumento": "IVAD",
//   "external_id": "id-do-resultado-no-motor-unico",
//   "status": "concluido",           // ou "processando" | "erro"
//   "score": 72.5,                    // opcional
//   "perfil": "Construtor",           // opcional
//   "link_relatorio": "https://...",  // opcional
//   "processado_em": "2026-07-16T12:00:00Z" // opcional, default: agora
// }
export async function POST(request) {
  const secretRecebido = request.headers.get('x-motor-vida-secret')
  const secretEsperado = process.env.MOTOR_VIDA_WEBHOOK_SECRET

  if (!secretEsperado || secretRecebido !== secretEsperado) {
    return NextResponse.json({ erro: 'não autorizado' }, { status: 401 })
  }

  let body
  try {
    body = await request.json()
  } catch {
    return NextResponse.json({ erro: 'JSON inválido' }, { status: 400 })
  }

  const {
    email,
    instrumento,
    external_id,
    status,
    score = null,
    perfil = null,
    link_relatorio = null,
    processado_em = null,
  } = body || {}

  if (!email || !instrumento || !external_id || !status) {
    return NextResponse.json(
      { erro: 'campos obrigatórios: email, instrumento, external_id, status' },
      { status: 400 }
    )
  }

  const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL,
    process.env.SUPABASE_SERVICE_ROLE_KEY,
    { auth: { autoRefreshToken: false, persistSession: false } }
  )

  const { data: perfilUsuario, error: erroBusca } = await supabase
    .from('users_profile')
    .select('id')
    .eq('email', email.toLowerCase().trim())
    .maybeSingle()

  if (erroBusca) {
    console.error('Erro ao buscar usuário por e-mail:', erroBusca)
    return NextResponse.json({ erro: 'falha ao buscar usuário' }, { status: 500 })
  }

  if (!perfilUsuario) {
    // Sem conta correspondente no VIDA OS™ Lite ainda (ex: lead que respondeu
    // o diagnóstico mas nunca criou conta). Não é um erro do webhook — só não
    // há onde gravar o resultado agora.
    return NextResponse.json(
      { aviso: 'nenhum usuário do VIDA OS™ Lite encontrado para este e-mail' },
      { status: 202 }
    )
  }

  const { error: erroUpsert } = await supabase
    .from('diagnosticos_vida')
    .upsert(
      {
        user_id: perfilUsuario.id,
        instrumento,
        external_id,
        status,
        score,
        perfil,
        link_relatorio,
        processado_em: processado_em || new Date().toISOString(),
        updated_at: new Date().toISOString(),
      },
      { onConflict: 'instrumento,external_id' }
    )

  if (erroUpsert) {
    console.error('Erro ao gravar diagnóstico:', erroUpsert)
    return NextResponse.json({ erro: 'falha ao gravar resultado' }, { status: 500 })
  }

  return NextResponse.json({ ok: true })
}
