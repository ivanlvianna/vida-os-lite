import Link from 'next/link'
import InviteControl from './InviteControl'

export default function InviteE2EPage() {
  return (
    <main style={{ maxWidth: '920px', margin: '40px auto', padding: '0 24px' }}>
      <p><Link href="/dashboard">← Voltar ao dashboard</Link></p>
      <h1 style={{ color: '#1A3C2E' }}>Homologacao InviteClient Live E2E</h1>
      <p>Painel temporario desta branch de Preview. Nenhum controle desta pagina existe em Production.</p>
      <InviteControl />
    </main>
  )
}
