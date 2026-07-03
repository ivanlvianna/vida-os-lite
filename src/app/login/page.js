'use client'
import { useState } from 'react'
import Link from 'next/link'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase'
export default function Login() {
  const [email, setEmail] = useState('')
  const [senha, setSenha] = useState('')
  const [carregando, setCarregando] = useState(false)
  const [erro, setErro] = useState('')
  const router = useRouter()
  async function handleLogin(e) {
    e.preventDefault()
    setErro('')
    setCarregando(true)
    const supabase = createClient()
    const { error } = await supabase.auth.signInWithPassword({ email, password: senha })
    if (error) {
      if (error.message.includes('Invalid login credentials')) setErro('E-mail ou senha incorretos.')
      else if (error.message.includes('Email not confirmed')) setErro('Confirme seu e-mail antes de fazer login. Verifique sua caixa de entrada.')
      else setErro('Erro ao fazer login. Tente novamente.')
      setCarregando(false)
    } else {
      router.push('/dashboard')
      router.refresh()
    }
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
    error: { padding:'14px', backgroundColor:'#fff5f5', border:'1px solid #e57373', borderRadius:'5px', color:'#c62828', fontSize:'0.9rem', lineHeight:1.5, marginBottom:'20px' },
  }
  return (
    <main style={s.page}>
      <div style={s.card}>
        <p style={s.eyebrow}>VIDA OS™</p>
        <h1 style={s.title}>Entrar</h1>
        <p style={s.subtitle}>Acesse sua plataforma de arquitetura patrimonial.</p>
        <form onSubmit={handleLogin}>
          {erro && <div style={s.error}>{erro}</div>}
          <div><label style={s.label} htmlFor="email">E-mail</label><input id="email" type="email" required value={email} onChange={e=>setEmail(e.target.value)} placeholder="seu@email.com.br" style={s.input} autoComplete="email"/></div>
          <div><label style={s.label} htmlFor="senha">Senha</label><input id="senha" type="password" required value={senha} onChange={e=>setSenha(e.target.value)} placeholder="Sua senha" style={s.input} autoComplete="current-password"/></div>
          <button type="submit" disabled={carregando} style={{...s.button,...(carregando?{opacity:0.6,cursor:'not-allowed'}:{})}}>{carregando?'Entrando...':'Entrar'}</button>
        </form>
        <div style={{display:'flex',justifyContent:'space-between',marginTop:'24px'}}>
          <Link href="/cadastro" style={{fontSize:'0.88rem',color:'#1A3C2E',textDecoration:'none',fontWeight:'500'}}>Criar conta</Link>
          <Link href="/recuperar-senha" style={{fontSize:'0.88rem',color:'#1A3C2E',textDecoration:'none',fontWeight:'500'}}>Esqueci a senha</Link>
        </div>
      </div>
    </main>
  )
}
