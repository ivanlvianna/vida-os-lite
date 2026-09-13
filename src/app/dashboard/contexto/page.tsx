import Link from 'next/link'
import { redirect } from 'next/navigation'
import { createSessionContext } from '../../../lib/identity/session-context'
import { resolveFunctionalContext } from '../../../lib/vida-os/functional-context'

function statusLabel(value: boolean, yes: string, no: string) {
  return value ? yes : no
}

export default async function CanonicalContextPage() {
  const supabase = await createSessionContext()
  const context = await resolveFunctionalContext(supabase)

  if (!context.principal.session.isAuthenticated) {
    redirect('/login')
  }

  const account = context.client.activeAccount
  const engagement = context.client.activeEngagement

  return (
    <main
      style={{
        minHeight: '100vh',
        background: '#f7f7f4',
        padding: '48px 24px',
        fontFamily: "Inter, 'Helvetica Neue', Arial, sans-serif",
      }}
    >
      <div style={{ maxWidth: 880, margin: '0 auto' }}>
        <Link
          href="/dashboard"
          style={{ color: '#1A3C2E', fontSize: 14, textDecoration: 'none' }}
        >
          ← Dashboard
        </Link>

        <section
          style={{
            marginTop: 24,
            background: '#fff',
            borderTop: '4px solid #d7ae4d',
            padding: 32,
            borderRadius: 6,
          }}
        >
          <p
            style={{
              margin: 0,
              color: '#d7ae4d',
              fontWeight: 800,
              fontSize: 12,
              letterSpacing: 1.6,
              textTransform: 'uppercase',
            }}
          >
            P0 · contexto canônico
          </p>
          <h1 style={{ margin: '8px 0 10px', color: '#1A3C2E' }}>
            Identity → Account → Engagement
          </h1>
          <p style={{ margin: 0, color: '#555', lineHeight: 1.6 }}>
            Esta tela lê somente o contexto que o PostgreSQL/RLS torna visível ao
            usuário autenticado. Ela não concede autorização e não cria contexto.
          </p>
        </section>

        <section
          style={{
            marginTop: 20,
            display: 'grid',
            gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))',
            gap: 16,
          }}
        >
          <article style={{ background: '#fff', padding: 24, borderRadius: 6 }}>
            <strong style={{ color: '#1A3C2E' }}>Principal</strong>
            <p style={{ marginBottom: 6, color: '#555' }}>
              Sessão: autenticada
            </p>
            <p style={{ margin: 0, color: '#555' }}>
              Internal staff:{' '}
              {statusLabel(context.principal.isInternalStaff, 'sim', 'não')}
            </p>
          </article>

          <article style={{ background: '#fff', padding: 24, borderRadius: 6 }}>
            <strong style={{ color: '#1A3C2E' }}>Client Account</strong>
            <p style={{ marginBottom: 6, color: '#555' }}>
              Contas visíveis: {context.client.availableAccounts.length}
            </p>
            <p style={{ margin: 0, color: '#555' }}>
              Contexto ativo: {account ? 'resolvido' : 'ausente'}
            </p>
          </article>

          <article style={{ background: '#fff', padding: 24, borderRadius: 6 }}>
            <strong style={{ color: '#1A3C2E' }}>Planning Engagement</strong>
            <p style={{ marginBottom: 6, color: '#555' }}>
              Engagement ativo: {engagement ? 'resolvido' : 'ausente'}
            </p>
            <p style={{ margin: 0, color: '#555' }}>
              Estado: {engagement?.state ?? '—'}
            </p>
          </article>
        </section>

        {(context.needsContextCreation ||
          context.awaitingAccess ||
          context.needsAccountSelection ||
          context.needsEngagementSelection ||
          context.missingEngagement) && (
          <section
            style={{
              marginTop: 20,
              background: '#fff',
              padding: 24,
              borderLeft: '4px solid #d7ae4d',
              borderRadius: 6,
            }}
          >
            <strong style={{ color: '#1A3C2E' }}>Próxima resolução</strong>
            {context.needsContextCreation && (
              <p style={{ color: '#555', lineHeight: 1.6 }}>
                Este principal interno ainda não possui contexto. O próximo passo
                canônico é ativação controlada via VRI no backend.
              </p>
            )}
            {context.awaitingAccess && (
              <p style={{ color: '#555', lineHeight: 1.6 }}>
                Este usuário autenticado ainda não possui autorização em uma Client
                Account. A aplicação não cria conta automaticamente para um cliente.
              </p>
            )}
            {context.needsAccountSelection && (
              <p style={{ color: '#555', lineHeight: 1.6 }}>
                Há mais de uma Client Account visível. A conta deve ser selecionada
                explicitamente; seleção de UI não altera autorização.
              </p>
            )}
            {context.needsEngagementSelection && (
              <p style={{ color: '#555', lineHeight: 1.6 }}>
                Há mais de um Planning Engagement visível. O ciclo deve ser escolhido
                explicitamente.
              </p>
            )}
            {context.missingEngagement && (
              <p style={{ color: '#555', lineHeight: 1.6 }}>
                A conta selecionada não possui Planning Engagement visível.
              </p>
            )}
          </section>
        )}

        {account && (
          <section style={{ marginTop: 20, background: '#fff', padding: 24, borderRadius: 6 }}>
            <strong style={{ color: '#1A3C2E' }}>Economic Entities</strong>
            {account.economicEntities.length === 0 ? (
              <p style={{ color: '#555' }}>Nenhuma entidade econômica visível.</p>
            ) : (
              <ul style={{ color: '#555', lineHeight: 1.7 }}>
                {account.economicEntities.map((entity) => (
                  <li key={entity.id}>
                    {entity.displayName} · {entity.entityType}
                  </li>
                ))}
              </ul>
            )}
          </section>
        )}
      </div>
    </main>
  )
}
