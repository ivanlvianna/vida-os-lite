import Link from 'next/link'

export default function Home() {
  return (
    <main style={{
      minHeight: '100vh',
      backgroundColor: '#ffffff',
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      justifyContent: 'center',
      padding: '48px 24px',
      fontFamily: "'Inter', 'Helvetica Neue', Arial, sans-serif",
    }}>
      <div style={{
        maxWidth: '440px',
        width: '100%',
        textAlign: 'center',
      }}>
        <div style={{
          display: 'inline-block',
          borderBottom: '3px solid #d7ae4d',
          paddingBottom: '12px',
          marginBottom: '40px',
        }}>
          <h1 style={{
            fontSize: '2.4rem',
            fontWeight: '800',
            color: '#1A3C2E',
            margin: 0,
            letterSpacing: '-0.5px',
            lineHeight: 1.15,
          }}>
            VIDA OS™
          </h1>
          <p style={{
            fontSize: '0.85rem',
            fontWeight: '600',
            color: '#d7ae4d',
            margin: '6px 0 0',
            letterSpacing: '2px',
            textTransform: 'uppercase',
          }}>
            Arquitetura patrimonial
          </p>
        </div>

        <p style={{
          fontSize: '1.1rem',
          color: '#1a1a1a',
          lineHeight: 1.6,
          marginBottom: '48px',
          textAlign: 'justify',
        }}>
          Organize, proteja e evolua seu patrimônio com clareza decisória.
          Acesse sua plataforma ou crie uma conta para começar.
        </p>

        <div style={{
          display: 'flex',
          flexDirection: 'column',
          gap: '14px',
        }}>
          <Link href="/cadastro" style={{
            display: 'block',
            padding: '16px 32px',
            backgroundColor: '#1A3C2E',
            color: '#ffffff',
            textDecoration: 'none',
            borderRadius: '6px',
            fontSize: '1rem',
            fontWeight: '600',
            textAlign: 'center',
            letterSpacing: '0.3px',
          }}>
            Criar conta
          </Link>

          <Link href="/login" style={{
            display: 'block',
            padding: '15px 32px',
            backgroundColor: 'transparent',
            color: '#1A3C2E',
            textDecoration: 'none',
            borderRadius: '6px',
            fontSize: '1rem',
            fontWeight: '600',
            textAlign: 'center',
            border: '2px solid #d7ae4d',
            letterSpacing: '0.3px',
          }}>
            Entrar
          </Link>
        </div>

        <p style={{
          marginTop: '48px',
          fontSize: '0.78rem',
          color: '#888',
          letterSpacing: '0.3px',
        }}>
          Ivan Vianna · CFP® · ivanviannafinancas.com.br
        </p>
      </div>
    </main>
  )
}
