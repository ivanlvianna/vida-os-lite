import { supabase } from '@/lib/supabase'

export default async function Home() {
  const { error } = await supabase.from('_test').select('*').limit(1)
  const connected = !error || error.code === 'PGRST116' || error.code === '42P01'

  return (
    <main className="min-h-screen flex flex-col items-center justify-center bg-white">
      <div className="text-center space-y-6 px-8">
        <div className="w-16 h-1 mx-auto" style={{ backgroundColor: '#d7ae4d' }} />
        <h1 className="text-4xl font-bold" style={{ color: '#1A3C2E' }}>
          VIDA OS™
        </h1>
        <p className="text-lg text-gray-500">
          Seu ambiente patrimonial
        </p>
        <div className="w-16 h-1 mx-auto" style={{ backgroundColor: '#d7ae4d' }} />
        <p className="text-sm text-gray-400">
          {connected ? '✓ Conexão com Supabase ativa' : '⚠ Verificando conexão...'}
        </p>
      </div>
    </main>
  )
}
