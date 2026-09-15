'use server'

import Link from 'next/link'
import { redirect } from 'next/navigation'
import {
  grantAccessAction,
  revokeAccessAction,
  changeEngagementStateAction,
} from '../access-actions'

const ACCOUNT_ID = 'c21d928b-e627-41ff-97bf-d4dd331b00c2'
const TARGET_AUTH_USER_ID = 'db521537-5ad5-4943-9c82-552b7ac57f35'
const ENGAGEMENT_ID = '69c0ec5f-976e-4e69-99b2-941a8f473739'

function encodeResult(result) {
  return encodeURIComponent(JSON.stringify(result))
}

async function runGrant() {
  'use server'
  const formData = new FormData()
  formData.set('clientAccountId', ACCOUNT_ID)
  formData.set('targetAuthUserId', TARGET_AUTH_USER_ID)
  formData.set('role', 'client_participant')
  formData.set('scopeType', 'account')

  const result = await grantAccessAction(formData)
  const authorizationId = result.ok ? result.authorizationId : ''
  redirect(`/dashboard/e2e?step=grant&result=${encodeResult(result)}&authorizationId=${encodeURIComponent(authorizationId)}`)
}

async function runRevoke(formData) {
  'use server'
  const authorizationId = formData.get('authorizationId')
  if (typeof authorizationId !== 'string' || !authorizationId) {
    redirect(`/dashboard/e2e?step=revoke&result=${encodeResult({ ok: false, code: 'MISSING_AUTHORIZATION_ID', message: 'Execute primeiro o teste GrantAccess.' })}`)
  }

  const payload = new FormData()
  payload.set('authorizationId', authorizationId)
  const result = await revokeAccessAction(payload)
  redirect(`/dashboard/e2e?step=revoke&result=${encodeResult(result)}&authorizationId=${encodeURIComponent(authorizationId)}`)
}

async function runChangeState() {
  'use server'
  const formData = new FormData()
  formData.set('engagementId', ENGAGEMENT_ID)
  formData.set('toState', 'dados_incompletos')
  formData.set('event', 'live_e2e_change_state')
  formData.set('eventOrigin', 'planner')
  formData.set('reason', 'Homologacao live E2E da Delivery Layer')

  const result = await changeEngagementStateAction(formData)
  redirect(`/dashboard/e2e?step=change-state&result=${encodeResult(result)}`)
}

export default async function E2EPage({ searchParams }) {
  const params = await searchParams
  let result = null
  if (params?.result) {
    try {
      result = JSON.parse(decodeURIComponent(params.result))
    } catch {
      result = { ok: false, code: 'RESULT_PARSE_ERROR', message: 'Nao foi possivel ler o resultado.' }
    }
  }

  const authorizationId = typeof params?.authorizationId === 'string' ? params.authorizationId : ''

  const boxStyle = {
    border: '1px solid #ddd',
    borderRadius: '8px',
    padding: '20px',
    marginBottom: '16px',
  }

  const buttonStyle = {
    background: '#1A3C2E',
    color: '#fff',
    border: 0,
    borderRadius: '4px',
    padding: '10px 16px',
    fontWeight: 700,
    cursor: 'pointer',
  }

  return (
    <main style={{ maxWidth: 760, margin: '40px auto', padding: '0 20px', fontFamily: "'Inter','Helvetica Neue',Arial,sans-serif" }}>
      <Link href="/dashboard" style={{ color: '#1A3C2E' }}>← Voltar ao dashboard</Link>
      <h1 style={{ color: '#1A3C2E', marginTop: 24 }}>Homologacao Live E2E</h1>
      <p style={{ color: '#555' }}>Painel temporario desta branch de Preview. Nenhum controle desta pagina existe em Production.</p>

      {result && (
        <div style={{ ...boxStyle, borderColor: result.ok ? '#1A3C2E' : '#b91c1c', background: result.ok ? '#f2f8f5' : '#fff5f5' }}>
          <strong>{result.ok ? 'PASS' : 'ERRO'}</strong>
          <pre style={{ whiteSpace: 'pre-wrap', marginBottom: 0 }}>{JSON.stringify(result, null, 2)}</pre>
        </div>
      )}

      <section style={boxStyle}>
        <h2 style={{ color: '#1A3C2E' }}>1. GrantAccessWorkflow</h2>
        <p>Concede ao usuario-alvo papel <code>client_participant</code> na conta de homologacao.</p>
        <form action={runGrant}>
          <button style={buttonStyle} type="submit">Executar GrantAccess</button>
        </form>
      </section>

      <section style={boxStyle}>
        <h2 style={{ color: '#1A3C2E' }}>2. RevokeAccessWorkflow</h2>
        <p>Revoga exatamente a autorizacao criada pelo passo 1.</p>
        <form action={runRevoke}>
          <input type="hidden" name="authorizationId" value={authorizationId} />
          <button style={{ ...buttonStyle, opacity: authorizationId ? 1 : 0.5 }} type="submit">Executar RevokeAccess</button>
        </form>
      </section>

      <section style={boxStyle}>
        <h2 style={{ color: '#1A3C2E' }}>3. ChangeEngagementStateWorkflow</h2>
        <p>Move o Planning Engagement de <code>onboarding_em_andamento</code> para <code>dados_incompletos</code>.</p>
        <form action={runChangeState}>
          <button style={buttonStyle} type="submit">Executar ChangeEngagementState</button>
        </form>
      </section>
    </main>
  )
}
