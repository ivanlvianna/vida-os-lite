'use client'
import { useState } from 'react'
import Link from 'next/link'
import { createClient } from '../../lib/supabase'
export default function Cadastro() {
  const [email, setEmail] = useState('')
  const [senha, setSenha] = useState('')
  const [carregando, setCarregando] = useState(false)
  const [sucesso, setSucesso] = useState(false)
  const [erro, setErro] = useState('')
  async function handleCadastro(e) {
    e.preventDefault()
    setErro('')
    setCarregando(true)
    const supabase = createClient()
    const { error } = await supabase.auth.signUp({
      email,
      password: senha,
      options: { emailRedirectTo: `${window.location.origin}/auth/callback` },
    })
    if (error) {
      if (error.message.includes('already registered')) setErro('Este e-mail já possui cadastro. Tente fazer login.')
      else if (error.message.includes('Password should be')) setErro('A senha deve ter no mínimo 6 caracteres.')
      else setErro('Ocorreu um erro. Tente novamente.')
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
        <h1 style={s.title}>Criar conta</h1>
        <p style={s.subtitle}>Preencha os dados abaixo. Você receberá um e-mail para confirmar o acesso.</p>
        {sucesso ? (
          <div style={s.success}><strong>Verifique seu e-mail.</strong> Enviamos um link de confirmação para <strong>{email}</strong>. Clique no link para ativar seu acesso.</div>
        ) : (
          <form onSubmit={handleCadastro}>
            {erro && <div style={s.error}>{erro}</div>}
            <div><label style={s.label} htmlFor="email">E-mail</label><input id="email" type="email" required value={email} onChange={e=>setEmail(e.target.value)} placeholder="seu@email.com.br" style={s.input} autoComplete="email"/></div>
            <div><label style={s.label} htmlFor="senha">Senha</label><input id="senha" type="password" required minLength={6} value={senha} onChange={e=>setSenha(e.target.value)} placeholder="Mínimo 6 caracteres" style={s.input} autoComplete="new-password"/></div>
            <button type="submit" disabled={carregando} style={{...s.button,...(carregando?{opacity:0.6,cursor:'not-allowed'}:{})}}>{carregando?'Criando conta...':'Criar conta'}</button>
          </form>
        )}
        <Link href="/login" style={{display:'block',textAlign:'center',marginTop:'24px',fontSize:'0.88rem',color:'#1A3C2E',textDecoration:'none',fontWeight:'500'}}>Já tem conta? Entrar</Link>
      </div>
    </main>
  )
}
