'use client'
import { useState } from 'react'
import Link from 'next/link'
import { createClient } from '../../lib/supabase'
export default function RecuperarSenha() {
  const [email, setEmail] = useState('')
  const [carregando, setCarregando] = useState(false)
  const [sucesso, setSucesso] = useState(false)
  const [erro, setErro] = useState('')
  async function handleRecuperar(e) {
    e.preventDefault()
    setErro('')
    setCarregando(true)
    const supabase = createClient()
    const { error } = await supabase.auth.resetPasswordForEmail(email, {
      redirectTo: `${window.location.origin}/auth/callback?next=/nova-senha`,
    })
    if (error) {
      setErro('Não foi possível enviar o e-mail. Verifique o endereço e tente novamente.')
    } else {
      setSucesso(true)
    }
    setCarregando(false)
  }
  const s = {
    page: { minHeight:'100vh', backgroundColor:'#ffffff', display:'flex', alignItems:'center', justifyContent:'center', padding:'48px 24px', fontFamily:"'Inter','Helvetica Neue',Arial,sans-serif" },
    card: { maxWidth:'420px', width:'100%' },
    eyebrow: { fontSize:'0.72rem', fontWeight:'700', color:'#d7ae4d', letterSpacing:'2.5px', textTransform:'uppercase', marginBottom:'10px' },
    title: { fontSize:'2rem', fontWeight:'800', color:'#1A3C2E', margin:'0 0 8px', lineHeight:1.15 },
    subtitle: { fontSize:'0.95rem', color:'#444', marginBottom:'36px', lineHeight:1.6 },
    label: { display:'block', fontSize:'0.82rem', fontWeight:'600', color:'#1A3C2E', marginBottom:'6px' },
    input: { width:'100%', padding:'13px 14px', fontSize:'1rem', border:'1.5px solid #d7ae4d', borderRadius:'5px', outline:'none', color:'#1a1a1a', backgroundColor:'#fafafa', boxSizing:'border-box', marginBottom:'20px' },
    button: { width:'100%', padding:'15px', backgroundColor:'#1A3C2E', color:'#ffffff', border:'none', borderRadius:'6px', fontSize:'1rem', fontWeight:'600', cursor:'pointer' },
    success: { padding:'16px', backgroundColor:'#f0f7f4', border:'1px solid #2E5C46', borderRadius:'5px', color:'#1A3C2E', fontSize:'0.95rem', lineHeight:1.6, marginBottom:'20px' },
    error: { padding:'14px', backgroundColor:'#fff5f5', border:'1px solid #e57373', borderRadius:'5px', color:'#c62828', fontSize:'0.9rem', lineHeight:1.5, marginBottom:'20px' },
  }
  return (
    <main style={s.page}>
      <div style={s.card}>
        <p style={s.eyebrow}>VIDA OS™</p>
        <h1 style={s.title}>Recuperar acesso</h1>
        <p style={s.subtitle}>Informe seu e-mail cadastrado. Enviaremos um link para redefinir sua senha.</p>
        {sucesso ? (
          <div style={s.success}><strong>E-mail enviado.</strong> Verifique sua caixa de entrada em <strong>{email}</strong> e siga as instruções para redefinir sua senha.</div>
        ) : (
          <form onSubmit={handleRecuperar}>
            {erro && <div style={s.error}>{erro}</div>}
            <div><label style={s.label} htmlFor="email">E-mail</label><input id="email" type="email" required value={email} onChange={e=>setEmail(e.target.value)} placeholder="seu@email.com.br" style={s.input} autoComplete="email"/></div>
            <button type="submit" disabled={carregando} style={{...s.button,...(carregando?{opacity:0.6,cursor:'not-allowed'}:{})}}>{carregando?'Enviando...':'Enviar link de recuperação'}</button>
          </form>
        )}
        <Link href="/login" style={{display:'block',textAlign:'center',marginTop:'24px',fontSize:'0.88rem',color:'#1A3C2E',textDecoration:'none',fontWeight:'500'}}>Voltar ao login</Link>
      </div>
    </main>
  )
}
