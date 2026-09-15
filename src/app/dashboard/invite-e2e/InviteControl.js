'use client'

import { useState } from 'react'
import { runInviteClientE2E } from './invite-action'

export default function InviteControl() {
  const [result, setResult] = useState(null)
  const [busy, setBusy] = useState(false)

  async function run() {
    setBusy(true)
    setResult(null)
    try {
      const next = await runInviteClientE2E()
      setResult(next)
    } finally {
      setBusy(false)
    }
  }

  const boxStyle = {
    border: '1px solid #ddd',
    borderRadius: '8px',
    padding: '20px',
    marginBottom: '16px',
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
        <h2 style={{ color: '#1A3C2E' }}>InviteClientWorkflow — Live E2E</h2>
        <p>Conta de homologacao ja existente. Alvo: <code>vidaos.e2e.invite.20260914@example.com</code>.</p>
        <p>Este teste cria apenas a identidade convidada no Auth. Nao cria membership nem authorization.</p>
        <button
          type="button"
          onClick={run}
          disabled={busy}
          style={{
            background: '#1A3C2E',
            color: '#fff',
            border: 0,
            borderRadius: '4px',
            padding: '10px 16px',
            fontWeight: 700,
            cursor: 'pointer',
          }}
        >
          {busy ? 'Executando...' : 'Executar InviteClient'}
        </button>
      </section>
    </>
  )
}
