import type { ReactNode } from 'react'
import Link from 'next/link'
import { notFound, redirect } from 'next/navigation'
import { loadPfpCockpitWorkflow } from '../../../../app-services/load-pfp-cockpit'
import { resolveCurrentPrincipal } from '../../../../lib/identity/identity-context'
import { createSessionContext } from '../../../../lib/identity/session-context'
import { VidaOsError } from '../../../../lib/vida-os/errors'

type PageProps = {
  params: Promise<{ planningEngagementId: string }>
}

function shortId(value: string | null | undefined): string {
  return value ? value.slice(0, 8) : '—'
}

function formatDate(value: string | null | undefined): string {
  if (!value) return '—'
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return '—'
  return new Intl.DateTimeFormat('pt-BR', {
    dateStyle: 'short',
    timeStyle: 'short',
  }).format(date)
}

function stateLabel(value: string | null | undefined): string {
  return value ? value.replaceAll('_', ' ') : 'Sem estado'
}

function Section({
  title,
  eyebrow,
  children,
}: {
  title: string
  eyebrow: string
  children: ReactNode
}) {
  return (
    <section
      style={{
        background: '#ffffff',
        border: '1px solid #e3e3df',
        borderRadius: '8px',
        padding: '24px',
      }}
    >
      <div style={{ marginBottom: '18px' }}>
        <div
          style={{
            color: '#a17b22',
            fontWeight: 800,
            textTransform: 'uppercase',
            letterSpacing: '1.4px',
            fontSize: '0.68rem',
            marginBottom: '5px',
          }}
        >
          {eyebrow}
        </div>
        <h2 style={{ margin: 0, color: '#1A3C2E', fontSize: '1.15rem' }}>{title}</h2>
      </div>
      {children}
    </section>
  )
}

function Empty({ children }: { children: ReactNode }) {
  return <p style={{ margin: 0, color: '#888', lineHeight: 1.6 }}>{children}</p>
}

function Badge({ children }: { children: ReactNode }) {
  return (
    <span
      style={{
        display: 'inline-block',
        borderRadius: '999px',
        background: '#f2eee1',
        color: '#725719',
        padding: '4px 9px',
        fontSize: '0.7rem',
        fontWeight: 800,
        textTransform: 'uppercase',
        letterSpacing: '0.5px',
      }}
    >
      {children}
    </span>
  )
}

function RootBlock({ children }: { children: ReactNode }) {
  return (
    <div
      style={{
        border: '1px solid #efeee9',
        borderRadius: '6px',
        padding: '14px',
        marginBottom: '10px',
      }}
    >
      {children}
    </div>
  )
}

export default async function PfpCockpitPage({ params }: PageProps) {
  const { planningEngagementId } = await params
  const supabase = await createSessionContext()
  const principal = await resolveCurrentPrincipal(supabase)

  if (!principal.session.isAuthenticated) redirect('/login')

  let cockpit
  try {
    cockpit = await loadPfpCockpitWorkflow(principal, supabase, planningEngagementId)
  } catch (error) {
    if (error instanceof VidaOsError && error.code === 'FORBIDDEN') notFound()
    throw error
  }

  const { summary } = cockpit
  const metricCards = [
    ['Instrumentos', summary.instrument_run_count],
    ['Hipóteses ativas', summary.active_hypothesis_count],
    ['Hipóteses aceitas', summary.accepted_hypothesis_count],
    ['Sessões', summary.session_count],
    ['Relatórios validados', summary.current_validated_report_count],
    ['Planos', summary.plan_count],
    ['Implementações', summary.implementation_count],
    ['Revisões', summary.review_count],
  ] as const

  return (
    <main
      style={{
        minHeight: '100vh',
        background: '#f7f7f5',
        fontFamily: "'Inter','Helvetica Neue',Arial,sans-serif",
        color: '#2b2b2b',
      }}
    >
      <header
        style={{
          position: 'sticky',
          top: 0,
          zIndex: 10,
          borderBottom: '3px solid #d7ae4d',
          padding: '16px 32px',
          background: '#ffffff',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
        }}
      >
        <div>
          <span style={{ color: '#1A3C2E', fontWeight: 900 }}>VIDA OS™</span>
          <span
            style={{
              marginLeft: '9px',
              color: '#d7ae4d',
              fontSize: '0.7rem',
              fontWeight: 800,
              letterSpacing: '1.5px',
              textTransform: 'uppercase',
            }}
          >
            PFP Cockpit
          </span>
        </div>
        <nav style={{ display: 'flex', gap: '18px', fontSize: '0.82rem', fontWeight: 700 }}>
          <Link href="/dashboard/pfp" style={{ color: '#1A3C2E' }}>
            Ciclos
          </Link>
          <Link href="/dashboard" style={{ color: '#1A3C2E' }}>
            Dashboard
          </Link>
        </nav>
      </header>

      <div style={{ maxWidth: '1280px', margin: '0 auto', padding: '34px 24px 72px' }}>
        <div
          style={{
            background: '#17382b',
            color: '#ffffff',
            borderRadius: '10px',
            padding: '30px',
            marginBottom: '22px',
          }}
        >
          <div
            style={{
              fontSize: '0.7rem',
              textTransform: 'uppercase',
              letterSpacing: '1.6px',
              color: '#d7ae4d',
              fontWeight: 800,
              marginBottom: '8px',
            }}
          >
            Ciclo de Planejamento VIDA™
          </div>
          <h1 style={{ margin: '0 0 10px', fontSize: '2rem' }}>
            PlanningEngagement {shortId(planningEngagementId)}
          </h1>
          <div style={{ color: '#d7ddd9', fontSize: '0.84rem' }}>
            ClientAccount {shortId(summary.client_account_id)} · projeção staff PC-M09 · leitura sob RLS
          </div>
        </div>

        <div
          style={{
            display: 'grid',
            gridTemplateColumns: 'repeat(auto-fit, minmax(135px, 1fr))',
            gap: '10px',
            marginBottom: '22px',
          }}
        >
          {metricCards.map(([label, value]) => (
            <div
              key={label}
              style={{
                background: '#ffffff',
                border: '1px solid #e3e3df',
                borderRadius: '7px',
                padding: '15px',
              }}
            >
              <div style={{ color: '#777', fontSize: '0.68rem', minHeight: '30px' }}>{label}</div>
              <div style={{ color: '#1A3C2E', fontSize: '1.45rem', fontWeight: 900 }}>{value}</div>
            </div>
          ))}
        </div>

        <div
          style={{
            display: 'grid',
            gridTemplateColumns: 'repeat(auto-fit, minmax(420px, 1fr))',
            gap: '18px',
            alignItems: 'start',
          }}
        >
          <Section eyebrow="Realidade registrada" title="Entrevista e contexto">
            {cockpit.interviews.length === 0 ? (
              <Empty>Nenhuma InterviewRecord durável registrada neste ciclo.</Empty>
            ) : (
              cockpit.interviews.map((item) => (
                <RootBlock key={item.interview_record_id}>
                  <div style={{ display: 'flex', gap: '8px', marginBottom: '9px', flexWrap: 'wrap' }}>
                    <Badge>Root {shortId(item.interview_record_id)}</Badge>
                    <Badge>Versão {item.current_version_no ?? '—'}</Badge>
                    {item.has_active_draft && <Badge>Draft ativo</Badge>}
                  </div>
                  <p style={{ margin: '0 0 8px', lineHeight: 1.55 }}>
                    <strong>Contexto:</strong> {item.context_narrative || '—'}
                  </p>
                  <p style={{ margin: 0, lineHeight: 1.55 }}>
                    <strong>Objetivos:</strong> {item.objectives_narrative || '—'}
                  </p>
                </RootBlock>
              ))
            )}
          </Section>

          <Section eyebrow="Diagnóstico VIDA" title="Instrumentos e sínteses">
            <div style={{ marginBottom: '18px' }}>
              {cockpit.instruments.length === 0 ? (
                <Empty>Nenhum InstrumentRun registrado.</Empty>
              ) : (
                <div style={{ display: 'flex', gap: '8px', flexWrap: 'wrap' }}>
                  {cockpit.instruments.map((item) => (
                    <Badge key={item.instrument_run_id}>
                      {item.instrument_code} · root {shortId(item.instrument_run_id)} · v
                      {item.current_version_no ?? '—'}
                    </Badge>
                  ))}
                </div>
              )}
            </div>
            {cockpit.syntheses.length === 0 ? (
              <Empty>Nenhum PCP/DiagnosticSynthesis derivado.</Empty>
            ) : (
              cockpit.syntheses.map((item) => (
                <RootBlock key={item.diagnostic_synthesis_id}>
                  <div style={{ marginBottom: '7px' }}>
                    <Badge>Root {shortId(item.diagnostic_synthesis_id)}</Badge>
                  </div>
                  <p style={{ lineHeight: 1.6, margin: '0 0 8px' }}>
                    {item.integrated_synthesis_narrative || 'Síntese sem narrativa.'}
                  </p>
                  <span style={{ color: '#777', fontSize: '0.76rem' }}>
                    {item.proposal_count} proposta(s) de hipótese
                  </span>
                </RootBlock>
              ))
            )}
          </Section>

          <Section eyebrow="Cognição → decisão" title="Hipóteses de trabalho">
            {cockpit.hypotheses.length === 0 ? (
              <Empty>Nenhuma WorkingHypothesis estabelecida.</Empty>
            ) : (
              cockpit.hypotheses.map((item) => (
                <RootBlock key={item.working_hypothesis_id}>
                  <div style={{ display: 'flex', gap: '8px', marginBottom: '7px', flexWrap: 'wrap' }}>
                    <Badge>Root {shortId(item.working_hypothesis_id)}</Badge>
                    <Badge>{stateLabel(item.current_state)}</Badge>
                  </div>
                  <div style={{ lineHeight: 1.55 }}>{item.hypothesis_statement || '—'}</div>
                </RootBlock>
              ))
            )}
          </Section>

          <Section eyebrow="Trabalho diagnóstico" title="Agenda e sessões">
            <div style={{ marginBottom: '16px' }}>
              <strong style={{ color: '#1A3C2E' }}>Agenda aberta: </strong>
              {cockpit.openAgendas.length === 0
                ? 'nenhuma'
                : `${cockpit.openAgendas.length} agenda(s), ${cockpit.openAgendas.reduce(
                    (sum, item) => sum + item.item_count,
                    0
                  )} item(ns)`}
            </div>
            {cockpit.sessions.length === 0 ? (
              <Empty>Nenhuma DiagnosticSession registrada.</Empty>
            ) : (
              cockpit.sessions.map((item) => (
                <RootBlock key={item.diagnostic_session_id}>
                  <div style={{ fontSize: '0.84rem', lineHeight: 1.6 }}>
                    <strong>Root {shortId(item.diagnostic_session_id)}</strong> ·{' '}
                    {formatDate(item.session_occurred_at)} · v{item.current_version_no ?? '—'} ·{' '}
                    {item.hypothesis_count} hipótese(s) · {item.decision_note_count} nota(s) de decisão
                  </div>
                </RootBlock>
              ))
            )}
          </Section>

          <Section eyebrow="REL-01" title="Relatórios diagnósticos">
            {cockpit.reports.length === 0 ? (
              <Empty>Nenhum DiagnosticReport registrado.</Empty>
            ) : (
              cockpit.reports.map((report) => (
                <RootBlock key={report.diagnostic_report_id}>
                  <div style={{ display: 'flex', gap: '8px', flexWrap: 'wrap', marginBottom: '12px' }}>
                    <Badge>Root {shortId(report.diagnostic_report_id)}</Badge>
                    <Badge>{stateLabel(report.current_state)}</Badge>
                    <Badge>v{report.current_version_no ?? '—'}</Badge>
                    {report.has_active_draft && <Badge>Draft ativo</Badge>}
                  </div>
                  <p style={{ lineHeight: 1.6, margin: '0 0 12px' }}>
                    {report.report_narrative || 'Relatório sem narrativa.'}
                  </p>
                  <div style={{ fontSize: '0.78rem', color: '#666', lineHeight: 1.6 }}>
                    Consenso mais recente:{' '}
                    {report.latest_consensus_understood === null
                      ? 'não manifestado'
                      : `${report.latest_consensus_understood ? 'compreendido' : 'não compreendido'} / ${
                          report.latest_consensus_agreed ? 'acordado' : 'não acordado'
                        }`}
                  </div>
                </RootBlock>
              ))
            )}
          </Section>

          <Section eyebrow="PLAN-01" title="Planos financeiros">
            {cockpit.plans.length === 0 ? (
              <Empty>Nenhum FinancialPlan registrado.</Empty>
            ) : (
              cockpit.plans.map((plan) => (
                <RootBlock key={plan.financial_plan_id}>
                  <div style={{ display: 'flex', gap: '8px', marginBottom: '12px', flexWrap: 'wrap' }}>
                    <Badge>Root {shortId(plan.financial_plan_id)}</Badge>
                    <Badge>v{plan.current_version_no ?? '—'}</Badge>
                    {plan.has_active_draft && <Badge>Draft ativo</Badge>}
                  </div>
                  <div style={{ lineHeight: 1.7, fontSize: '0.85rem' }}>
                    <div><strong>Metas:</strong> {plan.goal_count}</div>
                    <div><strong>Estratégias:</strong> {plan.strategy_count}</div>
                    <div><strong>Hipóteses referenciadas:</strong> {plan.hypothesis_count}</div>
                    <div><strong>ReportVersion base:</strong> {shortId(plan.diagnostic_report_version_id)}</div>
                  </div>
                </RootBlock>
              ))
            )}
            <div style={{ marginTop: '10px', color: '#888', fontSize: '0.72rem' }}>
              Nenhum plano é inferido como “principal” pelo Cockpit; cada Aggregate Root é exibido separadamente.
            </div>
          </Section>

          <Section eyebrow="PRI-01" title="Implementações">
            {cockpit.implementations.length === 0 ? (
              <Empty>Nenhuma ImplementationEpisode registrada.</Empty>
            ) : (
              cockpit.implementations.map((item) => (
                <RootBlock key={item.implementation_episode_id}>
                  <div style={{ display: 'flex', gap: '8px', marginBottom: '7px', flexWrap: 'wrap' }}>
                    <Badge>Root {shortId(item.implementation_episode_id)}</Badge>
                    <Badge>v{item.current_version_no ?? '—'}</Badge>
                  </div>
                  <div style={{ fontSize: '0.84rem', lineHeight: 1.6 }}>
                    {item.implementation_narrative || '—'}
                  </div>
                  <div style={{ color: '#777', fontSize: '0.74rem', marginTop: '7px' }}>
                    FinancialPlanVersion: {shortId(item.financial_plan_version_id)}
                  </div>
                </RootBlock>
              ))
            )}
          </Section>

          <Section eyebrow="RPM-01" title="Revisões">
            {cockpit.reviews.length === 0 ? (
              <Empty>Nenhuma ReviewEpisode registrada.</Empty>
            ) : (
              cockpit.reviews.map((item) => (
                <RootBlock key={item.review_episode_id}>
                  <div style={{ display: 'flex', gap: '8px', marginBottom: '7px', flexWrap: 'wrap' }}>
                    <Badge>Root {shortId(item.review_episode_id)}</Badge>
                    <Badge>v{item.current_version_no ?? '—'}</Badge>
                  </div>
                  <div style={{ fontSize: '0.84rem', lineHeight: 1.6 }}>
                    {item.review_narrative || '—'}
                  </div>
                  <div style={{ color: '#777', fontSize: '0.74rem', marginTop: '7px' }}>
                    ImplementationVersion exata: {shortId(item.implementation_episode_version_id)}
                  </div>
                </RootBlock>
              ))
            )}
          </Section>

          <Section eyebrow="Histórico derivado" title="Timeline Planning Content">
            {cockpit.timeline.length === 0 ? (
              <Empty>Nenhum evento durável registrado.</Empty>
            ) : (
              <div style={{ maxHeight: '420px', overflowY: 'auto', display: 'grid', gap: '10px' }}>
                {cockpit.timeline.slice(0, 50).map((entry) => (
                  <div
                    key={`${entry.object_type}-${entry.version_or_event_id}`}
                    style={{
                      display: 'grid',
                      gridTemplateColumns: '112px 1fr',
                      gap: '10px',
                      borderBottom: '1px solid #efeee9',
                      paddingBottom: '9px',
                    }}
                  >
                    <div style={{ fontSize: '0.7rem', color: '#888' }}>
                      {formatDate(entry.occurred_at)}
                    </div>
                    <div style={{ fontSize: '0.78rem', lineHeight: 1.45 }}>
                      <strong style={{ color: '#1A3C2E' }}>{entry.object_type}</strong> ·{' '}
                      {entry.event_key}
                      {entry.state ? ` · ${stateLabel(entry.state)}` : ''}
                    </div>
                  </div>
                ))}
              </div>
            )}
          </Section>

          <Section eyebrow="Bounded contexts" title="Áreas ainda não projetadas aqui">
            <Empty>
              Realidade Financeira, investimentos/ativos, proteção, previdência, fiscal/sucessório,
              Decision Ledger, Documents/Evidence e Provenance permanecem fora do PC-M09. O Cockpit
              não inventa essas informações nem as substitui por campos genéricos.
            </Empty>
          </Section>
        </div>
      </div>
    </main>
  )
}
