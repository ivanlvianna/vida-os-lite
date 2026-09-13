'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '../../lib/supabase'

export default function NovaSenhaPage() {
  const router = useRouter()
  const [senha, setSenha] = useState('')
  const [confirmacao, setConfirmacao] = useState('')
  const [erro, setErro] = useState('')
  const [salvando, setSalvando] = useState(false)

  async function handleSubmit(e) {
    e.preventDefault()
    setErro('')

    if (senha.length < 8) {
      setErro('A nova senha deve ter pelo menos 8 caracteres.')
      return
    }

    if (senha !== confirmacao) {
      setErro('As senhas não coincidem.')
      return
    }

    setSalvando(true)
    const supabase = createClient()
    const { error } = await supabase.auth.updateUser({ password: senha })

    if (error) {
      setErro('Não foi possível atualizar a senha. Solicite um novo link de recuperação e tente novamente.')
      setSalvando(false)
      return
    }

    router.replace('/dashboard')
    router.refresh()
  }

  const inputStyle = {
    width: '100%', padding: '13px 14px', fontSize: '1rem', border: '1.5px solid #d7ae4d',
    borderRadius: '5px', outline: 'none', color: '#1a1a1a', backgroundColor: '#fafafa', boxSizing: 'border-box'
  }

  return (
    <main style={{ minHeight: '100vh', backgroundColor: '#ffffff', display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '48px 24px', fontFamily: "'Inter','Helvetica Neue',Arial,sans-serif" }}>
      <div style={{ maxWidth: '420px', width: '100%' }}>
        <p style={{ fontSize: '0.72rem', fontWeight: 700, color: '#d7ae4d', letterSpacing: '2.5px', textTransform: 'uppercase', marginBottom: '10px' }}>VIDA OS™</p>
        <h1 style={{ fontSize: '2rem', fontWeight: 800, color: '#1A3C2E', margin: '0 0 8px', lineHeight: 1.15 }}>Definir nova senha</h1>
        <p style={{ fontSize: '0.95rem', color: '#444', marginBottom: '36px', lineHeight: 1.6 }}>Escolha uma nova senha para sua conta.</p>

        <form onSubmit={handleSubmit}>
          {erro && <div style={{ padding: '14px', backgroundColor: '#fff5f5', border: '1px solid #e57373', borderRadius: '5px', color: '#c62828', fontSize: '0.9rem', lineHeight: 1.5, marginBottom: '20px' }}>{erro}</div>}

          <div style={{ marginBottom: '18px' }}>
            <label htmlFor="senha" style={{ display: 'block', fontSize: '0.82rem', fontWeight: 600, color: '#1A3C2E', marginBottom: '6px' }}>Nova senha</label>
            <input id="senha" type="password" minLength={8} required autoComplete="new-password" value={senha} onChange={(e) => setSenha(e.target.value)} style={inputStyle} />
          </div>

          <div style={{ marginBottom: '22px' }}>
            <label htmlFor="confirmacao" style={{ display: 'block', fontSize: '0.82rem', fontWeight: 600, color: '#1A3C2E', marginBottom: '6px' }}>Confirmar nova senha</label>
            <input id="confirmacao" type="password" minLength={8} required autoComplete="new-password" value={confirmacao} onChange={(e) => setConfirmacao(e.target.value)} style={inputStyle} />
          </div>

          <button type="submit" disabled={salvando} style={{ width: '100%', padding: '15px', backgroundColor: '#1A3C2E', color: '#ffffff', border: 'none', borderRadius: '6px', fontSize: '1rem', fontWeight: 600, cursor: salvando ? 'not-allowed' : 'pointer', opacity: salvando ? 0.6 : 1 }}>
            {salvando ? 'Atualizando...' : 'Atualizar senha'}
          </button>
        </form>
      </div>
    </main>
  )
}
