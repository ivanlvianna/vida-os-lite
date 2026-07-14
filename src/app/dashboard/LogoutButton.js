'use client'
import { useRouter } from 'next/navigation'
import { createClient } from '../../lib/supabase'
export default function LogoutButton() {
  const router = useRouter()
  async function handleLogout() {
    const supabase = createClient()
    await supabase.auth.signOut()
    router.push('/')
    router.refresh()
  }
  return (
    <button onClick={handleLogout} style={{padding:'9px 20px',backgroundColor:'transparent',color:'#1A3C2E',border:'1.5px solid #d7ae4d',borderRadius:'5px',fontSize:'0.88rem',fontWeight:'600',cursor:'pointer'}}>
      Sair
    </button>
  )
}
