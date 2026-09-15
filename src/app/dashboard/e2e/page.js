import Link from 'next/link'
import E2EControls from './E2EControls'

export default function E2EPage() {
  return (
    <main style={{ maxWidth: 760, margin: '40px auto', padding: '0 20px', fontFamily: "'Inter','Helvetica Neue',Arial,sans-serif" }}>
      <Link href="/dashboard" style={{ color: '#1A3C2E' }}>← Voltar ao dashboard</Link>
      <h1 style={{ color: '#1A3C2E', marginTop: 24 }}>Homologacao Live E2E</h1>
      <p style={{ color: '#555' }}>Painel temporario desta branch de Preview. Nenhum controle desta pagina existe em Production.</p>
      <E2EControls />
    </main>
  )
}
