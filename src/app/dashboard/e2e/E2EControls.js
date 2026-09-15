'use client'

import { useState } from 'react'
import {
  grantAccessAction,
  revokeAccessAction,
  changeEngagementStateAction,
} from '../access-actions'

const ACCOUNT_ID = 'c21d928b-e627-41ff-97bf-d4dd331b00c2'
const TARGET_AUTH_USER_ID = 'db521537-5ad5-4943-9c82-552b7ac57f35'
const ENGAGEMENT_ID = '69c0ec5f-976e-4e69-99b2-941a8f473739'

export default function E2EControls() {
  const [result, setResult] = useState(null)
  const [authorizationId, setAuthorizationId] = useState('')
  const [busy, setBusy] = useState('')

  async function runGrant() {
    setBusy('grant')
    setResult(null)
    try {
      const formData = new FormData()
      formData.set('clientAccountId', ACCOUNT_ID)
      formData.set('targetAuthUserId', TARGET_AUTH_USER_ID)
      formData.set('role', 'client_participant')
      formData.set('scopeType', 'account')
      const next = await grantAccessAction(formData)
      setResult(next)
      if (next?.ok && next.authorizationId) setAuthorizationId(next.authorizationId)
    } finally {
      setBusy('')
    }
  }

  async function runRevoke() {
    if (!authorizationId) {
      setResult({ ok: false, code: 'MISSING_AUTHORIZATION_ID', message: 'Execute primeiro o teste GrantAccess.' })
      return
    }
    setBusy('revoke')
    setResult(null)
    try {
      const formData = new FormData()
      formData.set('authorizationId', authorizationId)
      const next = await revokeAccessAction(formData)
      setResult(next)
    } finally {
      setBusy('')
    }
  }

  async function runChangeState() {
    setBusy('change')
    setResult(null)
    try {
      const formData = new FormData()
      formData.set('engagementId', ENGAGEMENT_ID)
      formData.set('toState', 'dados_incompletos')
      formData.set('event', 'live_e2e_change_state')
      formData.set('eventOrigin', 'planner')
      formData.set('reason', 'Homologacao live E2E da Delivery Layer')
      const next = await changeEngagementStateAction(formData)
      setResult(next)
    } finally {
      setBusy('')
    }
  }

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
    <>
      {result && (
        <div style={{ ...boxStyle, borderColor: result.ok ? '#1A3C2E' : '#b91c1c', background: result.ok ? '#f2f8f5' : '#fff5f5' }}>
          <strong>{result.ok ? 'PASS' : 'ERRO'}</strong>
          <pre style={{ whiteSpace: 'pre-wrap', marginBottom: 0 }}>{JSON.stringify(result, null, 2)}</pre>
        </div>
      )}

      <section style={boxStyle}>
        <h2 style={{ color: '#1A3C2E' }}>1. GrantAccessWorkflow</h2>
        <p>Concede ao usuario-alvo papel <code>client_participant</code> na conta de homologacao.</p>
        <button style={buttonStyle} type="button" onClick={runGrant} disabled={Boolean(busy)}>
          {busy === 'grant' ? 'Executando...' : 'Executar GrantAccess'}
        </button>
      </section>

      <section style={boxStyle}>
        <h2 style={{ color: '#1A3C2E' }}>2. RevokeAccessWorkflow</h2>
        <p>Revoga exatamente a autorizacao criada pelo passo 1.</p>
        <button style={{ ...buttonStyle, opacity: authorizationId ? 1 : 0.5 }} type="button" onClick={runRevoke} disabled={Boolean(busy)}>
          {busy === 'revoke' ? 'Executando...' : 'Executar RevokeAccess'}
        </button>
      </section>

      <section style={boxStyle}>
        <h2 style={{ color: '#1A3C2E' }}>3. ChangeEngagementStateWorkflow</h2>
        <p>Move o Planning Engagement de <code>onboarding_em_andamento</code> para <code>dados_incompletos</code>.</p>
        <button style={buttonStyle} type="button" onClick={runChangeState} disabled={Boolean(busy)}>
          {busy === 'change' ? 'Executando...' : 'Executar ChangeEngagementState'}
        </button>
      </section>
    </>
  )
}
