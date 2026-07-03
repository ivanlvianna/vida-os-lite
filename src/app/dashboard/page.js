import { createServerClient } from '@supabase/ssr'
import { cookies } from 'next/headers'
import { redirect } from 'next/navigation'
import LogoutButton from './LogoutButton'
export default async function Dashboard() {
  const cookieStore = cookies()
  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY,
    {
      cookies: {
        getAll() { return cookieStore.getAll() },
        setAll(cookiesToSet) { cookiesToSet.forEach(({ name, value, options }) => cookieStore.set(name, value, options)) },
      },
    }
  )
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) { redirect('/login') }
  return (
    <main style={{minHeight:'100vh',backgroundColor:'#ffffff',fontFamily:"'Inter','Helvetica Neue',Arial,sans-serif"}}>
      <header style={{borderBottom:'3px solid #d7ae4d',padding:'18px 40px',display:'flex',alignItems:'center',justifyContent:'space-between',backgroundColor:'#ffffff'}}>
        <div>
          <span style={{fontSize:'1.2rem',fontWeight:'800',color:'#1A3C2E',letterSpacing:'-0.3px'}}>VIDA OS™</span>
          <span style={{marginLeft:'10px',fontSize:'0.72rem',fontWeight:'700',color:'#d7ae4d',letterSpacing:'2px',textTransform:'uppercase'}}>Lite</span>
        </div>
        <LogoutButton />
      </header>
      <div style={{maxWidth:'860px',margin:'0 auto',padding:'64px 24px'}}>
        <div style={{borderLeft:'4px solid #d7ae4d',paddingLeft:'24px',marginBottom:'56px'}}>
          <p style={{fontSize:'0.82rem',fontWeight:'700',color:'#d7ae4d',letterSpacing:'2px',textTransform:'uppercase',margin:'0 0 8px'}}>Plataforma ativa</p>
          <h1 style={{fontSize:'2.4rem',fontWeight:'800',color:'#1A3C2E',margin:'0 0 12px',lineHeight:1.15}}>Bem-vindo ao VIDA OS™</h1>
          <p style={{fontSize:'1rem',color:'#444',lineHeight:1.6,margin:0}}>Acesso autenticado como <strong>{user.email}</strong></p>
        </div>
        <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit, minmax(240px, 1fr))',gap:'20px'}}>
          {[{titulo:'Arquitetura patrimonial',desc:'Mapeie a estrutura do seu patrimônio.'},{titulo:'Capital decisório',desc:'Avalie a qualidade das suas decisões financeiras.'},{titulo:'Diagnóstico VIDA',desc:'Acesse seus diagnósticos e índices.'}].map((m)=>(
            <div key={m.titulo} style={{padding:'28px',border:'1.5px solid #e8e8e8',borderRadius:'6px',borderTop:'3px solid #d7ae4d'}}>
              <h3 style={{fontSize:'1rem',fontWeight:'700',color:'#1A3C2E',margin:'0 0 10px',lineHeight:1.2}}>{m.titulo}</h3>
              <p style={{fontSize:'0.88rem',color:'#666',lineHeight:1.6,margin:'0 0 16px'}}>{m.desc}</p>
              <span style={{fontSize:'0.75rem',fontWeight:'700',color:'#d7ae4d',letterSpacing:'1.5px',textTransform:'uppercase'}}>Em breve</span>
            </div>
          ))}
        </div>
      </div>
    </main>
  )
}
