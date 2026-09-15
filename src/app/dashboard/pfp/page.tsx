import Link from 'next/link'
import { redirect } from 'next/navigation'
import { listPfpCockpitsWorkflow } from '../../../app-services/load-pfp-cockpit'
import { resolveCurrentPrincipal } from '../../../lib/identity/identity-context'
import { createSessionContext } from '../../../lib/identity/session-context'

function shortId(value: string): string {
  return value.slice(0, 8)
}

export default async function PfpCockpitIndexPage() {
  const supabase = await createSessionContext()
  const principal = await resolveCurrentPrincipal(supabase)

  if (!principal.session.isAuthenticated) redirect('/login')

  const engagements = await listPfpCockpitsWorkflow(principal, supabase)

  return (
    <main
      style={{
        minHeight: '100vh',
        backgroundColor: '#f7f7f5',
        fontFamily: "'Inter','Helvetica Neue',Arial,sans-serif",
      }}
    >
      <header
        style={{
          borderBottom: '3px solid #d7ae4d',
          padding: '18px 40px',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          backgroundColor: '#ffffff',
        }}
      >
        <div>
          <span style={{ fontSize: '1.2rem', fontWeight: 800, color: '#1A3C2E' }}>
            VIDA OS™
          </span>
          <span
            style={{
              marginLeft: '10px',
              fontSize: '0.72rem',
              fontWeight: 700,
              color: '#d7ae4d',
              letterSpacing: '2px',
              textTransform: 'uppercase',
            }}
          >
            PFP Cockpit
          </span>
        </div>
        <Link href="/dashboard" style={{ color: '#1A3C2E', fontWeight: 700 }}>
          Dashboard
        </Link>
      </header>

      <div style={{ maxWidth: '1080px', margin: '0 auto', padding: '48px 24px 72px' }}>
        <div style={{ marginBottom: '32px' }}>
          <p
            style={{
              color: '#a17b22',
              fontWeight: 800,
              letterSpacing: '1.5px',
              textTransform: 'uppercase',
              fontSize: '0.74rem',
              margin: '0 0 8px',
            }}
          >
            Planejamento Financeiro Pessoal
          </p>
          <h1 style={{ color: '#1A3C2E', fontSize: '2rem', margin: '0 0 10px' }}>
            Ciclos de planejamento autorizados
          </h1>
          <p style={{ color: '#666', maxWidth: '760px', lineHeight: 1.6, margin: 0 }}>
            Esta lista é derivada exclusivamente do PC-M09. Se um ciclo não estiver visível
            pelo RLS do PostgreSQL, ele não aparece aqui.
          </p>
        </div>

        {engagements.length === 0 ? (
          <div
            style={{
              background: '#ffffff',
              border: '1px solid #e3e3df',
              borderRadius: '8px',
              padding: '32px',
              color: '#666',
            }}
          >
            Nenhum ciclo PFP está disponível para esta identidade.
          </div>
        ) : (
          <div
            style={{
              display: 'grid',
              gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))',
              gap: '18px',
            }}
          >
            {engagements.map((item) => (
              <article
                key={item.planning_engagement_id}
                style={{
                  background: '#ffffff',
                  border: '1px solid #e3e3df',
                  borderTop: '3px solid #1A3C2E',
                  borderRadius: '8px',
                  padding: '24px',
                }}
              >
                <div style={{ marginBottom: '18px' }}>
                  <div style={{ color: '#888', fontSize: '0.72rem', marginBottom: '5px' }}>
                    PlanningEngagement
                  </div>
                  <div style={{ color: '#1A3C2E', fontWeight: 800, fontSize: '1.05rem' }}>
                    Ciclo {shortId(item.planning_engagement_id)}
                  </div>
                  <div style={{ color: '#999', fontSize: '0.72rem', marginTop: '4px' }}>
                    Conta {shortId(item.client_account_id)}
                  </div>
                </div>

                <div
                  style={{
                    display: 'grid',
                    gridTemplateColumns: 'repeat(3, 1fr)',
                    gap: '8px',
                    marginBottom: '20px',
                  }}
                >
                  {[
                    ['Hipóteses', item.active_hypothesis_count + item.accepted_hypothesis_count],
                    ['Sessões', item.session_count],
                    ['Planos', item.plan_count],
                  ].map(([label, value]) => (
                    <div
                      key={String(label)}
                      style={{ background: '#f5f4ef', borderRadius: '5px', padding: '10px' }}
                    >
                      <div style={{ color: '#777', fontSize: '0.68rem' }}>{label}</div>
                      <div style={{ color: '#1A3C2E', fontWeight: 800, fontSize: '1.15rem' }}>
                        {value}
                      </div>
                    </div>
                  ))}
                </div>

                <Link
                  href={`/dashboard/pfp/${item.planning_engagement_id}`}
                  style={{
                    display: 'inline-block',
                    textDecoration: 'none',
                    background: '#1A3C2E',
                    color: '#ffffff',
                    fontWeight: 700,
                    borderRadius: '4px',
                    padding: '9px 16px',
                    fontSize: '0.82rem',
                  }}
                >
                  Abrir Cockpit →
                </Link>
              </article>
            ))}
          </div>
        )}
      </div>
    </main>
  )
}
