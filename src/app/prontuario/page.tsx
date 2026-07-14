'use client'

import { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { salvarProntuario, carregarProntuario } from './actions'

type StatusFlag = 'ok' | 'atencao' | 'critico' | 'pendente'

type Dimensao = {
  id: string
  nome: string
  descricao: string
  campos: Campo[]
}

type Campo = {
  id: string
  label: string
  tipo: 'texto' | 'select' | 'radio' | 'numero' | 'textarea'
  opcoes?: string[]
  placeholder?: string
}

type FormValues = Record<string, string | number | boolean>

const DIMENSOES: Dimensao[] = [
  {
    id: 'fiscal',
    nome: 'Fiscal',
    descricao: 'Estrutura tributária e obrigações fiscais',
    campos: [
      { id: 'fiscal_regime', label: 'Regime tributário', tipo: 'select', opcoes: ['Simples Nacional', 'Lucro Presumido', 'Lucro Real', 'MEI', 'Pessoa Física', 'Não se aplica'] },
      { id: 'fiscal_planejamento', label: 'Possui planejamento tributário ativo?', tipo: 'radio', opcoes: ['Sim', 'Não', 'Em andamento'] },
      { id: 'fiscal_pendencias', label: 'Pendências fiscais conhecidas', tipo: 'textarea', placeholder: 'Descreva pendências, parcelamentos ou contenciosos relevantes…' },
      { id: 'fiscal_status', label: 'Status da dimensão fiscal', tipo: 'select', opcoes: ['ok', 'atencao', 'critico', 'pendente'] },
    ]
  },
  {
    id: 'sucessorio',
    nome: 'Sucessório',
    descricao: 'Planejamento de transferência patrimonial',
    campos: [
      { id: 'suc_testamento', label: 'Possui testamento?', tipo: 'radio', opcoes: ['Sim', 'Não', 'Em elaboração'] },
      { id: 'suc_holding', label: 'Possui holding patrimonial?', tipo: 'radio', opcoes: ['Sim', 'Não', 'Em estudo'] },
      { id: 'suc_herdeiros', label: 'Número de herdeiros', tipo: 'numero' },
      { id: 'suc_acordos', label: 'Acordos ou pactos entre herdeiros', tipo: 'textarea', placeholder: 'Descreva acordos formais ou informais existentes…' },
      { id: 'suc_status', label: 'Status da dimensão sucessória', tipo: 'select', opcoes: ['ok', 'atencao', 'critico', 'pendente'] },
    ]
  },
  {
    id: 'protecao',
    nome: 'Proteção',
    descricao: 'Seguros e coberturas de risco patrimonial',
    campos: [
      { id: 'prot_vida', label: 'Possui seguro de vida?', tipo: 'radio', opcoes: ['Sim', 'Não'] },
      { id: 'prot_vida_capital', label: 'Capital segurado (R$)', tipo: 'numero' },
      { id: 'prot_invalidez', label: 'Possui seguro de invalidez?', tipo: 'radio', opcoes: ['Sim', 'Não'] },
      { id: 'prot_imoveis', label: 'Imóveis segurados?', tipo: 'radio', opcoes: ['Sim', 'Parcialmente', 'Não'] },
      { id: 'prot_gaps', label: 'Gaps de proteção identificados', tipo: 'textarea', placeholder: 'Riscos sem cobertura adequada…' },
      { id: 'prot_status', label: 'Status da dimensão de proteção', tipo: 'select', opcoes: ['ok', 'atencao', 'critico', 'pendente'] },
    ]
  },
  {
    id: 'liquidez',
    nome: 'Liquidez',
    descricao: 'Disponibilidade e reservas de emergência',
    campos: [
      { id: 'liq_reserva_meses', label: 'Reserva de emergência (meses de custo)', tipo: 'numero' },
      { id: 'liq_percentual', label: 'Percentual do patrimônio em ativos líquidos (%)', tipo: 'numero' },
      { id: 'liq_prazo', label: 'Prazo médio para liquidação do patrimônio', tipo: 'select', opcoes: ['Imediato', 'Até 30 dias', '30 a 90 dias', '90 dias a 1 ano', 'Acima de 1 ano'] },
      { id: 'liq_observacoes', label: 'Observações sobre liquidez', tipo: 'textarea', placeholder: 'Ativos ilíquidos relevantes, restrições de resgate…' },
      { id: 'liq_status', label: 'Status da dimensão de liquidez', tipo: 'select', opcoes: ['ok', 'atencao', 'critico', 'pendente'] },
    ]
  },
  {
    id: 'previdencia',
    nome: 'Previdência',
    descricao: 'Planejamento para independência financeira e aposentadoria',
    campos: [
      { id: 'prev_pgbl_vgbl', label: 'Possui PGBL ou VGBL?', tipo: 'radio', opcoes: ['PGBL', 'VGBL', 'Ambos', 'Nenhum'] },
      { id: 'prev_inss', label: 'Contribui para o INSS?', tipo: 'radio', opcoes: ['Sim', 'Não', 'Contribuição complementar'] },
      { id: 'prev_meta_idade', label: 'Idade alvo para independência financeira', tipo: 'numero' },
      { id: 'prev_renda_alvo', label: 'Renda mensal alvo na independência (R$)', tipo: 'numero' },
      { id: 'prev_observacoes', label: 'Observações previdenciárias', tipo: 'textarea', placeholder: 'Benefícios, pensões, rendas passivas previstas…' },
      { id: 'prev_status', label: 'Status da dimensão previdenciária', tipo: 'select', opcoes: ['ok', 'atencao', 'critico', 'pendente'] },
    ]
  },
  {
    id: 'governanca',
    nome: 'Governança',
    descricao: 'Estrutura de decisão e gestão patrimonial',
    campos: [
      { id: 'gov_conselho', label: 'Possui conselho de família ou familiar office?', tipo: 'radio', opcoes: ['Sim', 'Não', 'Em estruturação'] },
      { id: 'gov_politica', label: 'Possui política de investimentos formalizada?', tipo: 'radio', opcoes: ['Sim', 'Não', 'Em elaboração'] },
      { id: 'gov_reunioes', label: 'Frequência de revisão patrimonial', tipo: 'select', opcoes: ['Mensal', 'Trimestral', 'Semestral', 'Anual', 'Sem periodicidade definida'] },
      { id: 'gov_mandato', label: 'Existe mandato formal para gestão do patrimônio?', tipo: 'radio', opcoes: ['Sim', 'Não'] },
      { id: 'gov_observacoes', label: 'Observações de governança', tipo: 'textarea', placeholder: 'Estruturas, acordos ou conflitos de governança relevantes…' },
      { id: 'gov_status', label: 'Status da dimensão de governança', tipo: 'select', opcoes: ['ok', 'atencao', 'critico', 'pendente'] },
    ]
  },
]

const STATUS_LABEL: Record<StatusFlag, string> = {
  ok: 'Adequado',
  atencao: 'Atenção',
  critico: 'Crítico',
  pendente: 'Pendente',
}

const STATUS_COR: Record<StatusFlag, string> = {
  ok: '#16a34a',
  atencao: '#d97706',
  critico: '#dc2626',
  pendente: '#6b7280',
}

const STATUS_BG: Record<StatusFlag, string> = {
  ok: '#f0fdf4',
  atencao: '#fffbeb',
  critico: '#fef2f2',
  pendente: '#f9fafb',
}

function calcularCompletude(values: FormValues): number {
  const totalCampos = DIMENSOES.reduce((acc, d) => acc + d.campos.length, 0)
  const preenchidos = Object.values(values).filter(v => v !== '' && v !== null && v !== undefined && v !== 0).length
  return Math.round((preenchidos / totalCampos) * 100)
}

function getStatusDim(values: FormValues, dimId: string): StatusFlag {
  const val = values[`${dimId}_status`] as StatusFlag
  return val || 'pendente'
}

export default function ProntuarioPage() {
  const router = useRouter()
  const [values, setValues] = useState<FormValues>({})
  const [dimAtiva, setDimAtiva] = useState('fiscal')
  const [salvando, setSalvando] = useState(false)
  const [msg, setMsg] = useState<{ tipo: 'ok' | 'erro'; texto: string } | null>(null)
  const [carregando, setCarregando] = useState(true)

  useEffect(() => {
    carregarProntuario().then(dados => {
      if (dados) setValues(dados)
      setCarregando(false)
    })
  }, [])

  function handleChange(id: string, value: string | number) {
    setValues(prev => ({ ...prev, [id]: value }))
  }

  async function handleSalvar() {
    setSalvando(true)
    setMsg(null)
    const resultado = await salvarProntuario(values)
    if (resultado?.erro) {
      setMsg({ tipo: 'erro', texto: resultado.erro })
    } else {
      setMsg({ tipo: 'ok', texto: 'Prontuário salvo com sucesso.' })
    }
    setSalvando(false)
  }

  const completude = calcularCompletude(values)
  const dimAtual = DIMENSOES.find(d => d.id === dimAtiva)!

  if (carregando) {
    return (
      <div style={styles.loading}>
        <div style={styles.loadingDot} />
        <p style={styles.loadingTxt}>Carregando prontuário…</p>
      </div>
    )
  }

  return (
    <div style={styles.page}>
      {/* Cabeçalho */}
      <div style={styles.header}>
        <button style={styles.btnVoltar} onClick={() => router.push('/dashboard')}>← Painel</button>
        <div>
          <div style={styles.logo}>VIDA OS™</div>
          <h1 style={styles.titulo}>Prontuário arquitetural</h1>
          <p style={styles.subtitulo}>Mapeamento das seis dimensões do seu patrimônio</p>
        </div>
      </div>

      {/* Completude */}
      <div style={styles.completudeCard}>
        <div style={styles.completudeInfo}>
          <span style={styles.completudeTxt}>Completude do prontuário</span>
          <span style={styles.completudePct}>{completude}%</span>
        </div>
        <div style={styles.barraWrap}>
          <div style={{ ...styles.barraFill, width: `${completude}%` }} />
        </div>
        <div style={styles.flagsRow}>
          {DIMENSOES.map(d => {
            const st = getStatusDim(values, d.id)
            return (
              <div key={d.id} style={{ ...styles.flag, backgroundColor: STATUS_BG[st], borderColor: STATUS_COR[st] }}>
                <div style={{ ...styles.flagDot, backgroundColor: STATUS_COR[st] }} />
                <span style={{ ...styles.flagNome, color: STATUS_COR[st] }}>{d.nome}</span>
              </div>
            )
          })}
        </div>
      </div>

      <div style={styles.corpo}>
        {/* Sidebar */}
        <div style={styles.sidebar}>
          {DIMENSOES.map(d => {
            const st = getStatusDim(values, d.id)
            const ativa = d.id === dimAtiva
            return (
              <button
                key={d.id}
                onClick={() => setDimAtiva(d.id)}
                style={{
                  ...styles.sideItem,
                  ...(ativa ? styles.sideItemAtivo : {}),
                }}
              >
                <div style={styles.sideItemLeft}>
                  <div style={{ ...styles.sideStatus, backgroundColor: STATUS_COR[st] }} />
                  <span style={{ ...styles.sideNome, color: ativa ? '#1A3C2E' : '#444444' }}>{d.nome}</span>
                </div>
                <span style={{ ...styles.sideBadge, backgroundColor: STATUS_BG[st], color: STATUS_COR[st] }}>
                  {STATUS_LABEL[st]}
                </span>
              </button>
            )
          })}
        </div>

        {/* Formulário */}
        <div style={styles.form}>
          <div style={styles.dimHeader}>
            <h2 style={styles.dimNome}>{dimAtual.nome}</h2>
            <p style={styles.dimDesc}>{dimAtual.descricao}</p>
          </div>

          {dimAtual.campos.map(campo => (
            <div key={campo.id} style={styles.campo}>
              <label style={styles.label}>{campo.label}</label>

              {campo.tipo === 'texto' && (
                <input
                  type="text"
                  value={(values[campo.id] as string) || ''}
                  onChange={e => handleChange(campo.id, e.target.value)}
                  placeholder={campo.placeholder}
                  style={styles.input}
                />
              )}

              {campo.tipo === 'numero' && (
                <input
                  type="number"
                  value={(values[campo.id] as number) || ''}
                  onChange={e => handleChange(campo.id, Number(e.target.value))}
                  placeholder="0"
                  style={{ ...styles.input, maxWidth: '180px' }}
                />
              )}

              {campo.tipo === 'textarea' && (
                <textarea
                  value={(values[campo.id] as string) || ''}
                  onChange={e => handleChange(campo.id, e.target.value)}
                  placeholder={campo.placeholder}
                  style={styles.textarea}
                />
              )}

              {campo.tipo === 'select' && (
                <select
                  value={(values[campo.id] as string) || ''}
                  onChange={e => handleChange(campo.id, e.target.value)}
                  style={campo.id.endsWith('_status') ? styles.selectStatus : styles.select}
                >
                  <option value="">Selecione</option>
                  {campo.opcoes?.map(op => (
                    <option key={op} value={op}>
                      {campo.id.endsWith('_status') ? STATUS_LABEL[op as StatusFlag] || op : op}
                    </option>
                  ))}
                </select>
              )}

              {campo.tipo === 'radio' && (
                <div style={styles.radioGrupo}>
                  {campo.opcoes?.map(op => (
                    <button
                      key={op}
                      type="button"
                      onClick={() => handleChange(campo.id, op)}
                      style={values[campo.id] === op ? styles.radioBotaoAtivo : styles.radioBotao}
                    >
                      {op}
                    </button>
                  ))}
                </div>
              )}
            </div>
          ))}

          {/* Navegação entre dimensões */}
          <div style={styles.navDims}>
            {DIMENSOES.findIndex(d => d.id === dimAtiva) > 0 && (
              <button
                style={styles.btnNav}
                onClick={() => {
                  const idx = DIMENSOES.findIndex(d => d.id === dimAtiva)
                  setDimAtiva(DIMENSOES[idx - 1].id)
                }}
              >
                ← {DIMENSOES[DIMENSOES.findIndex(d => d.id === dimAtiva) - 1].nome}
              </button>
            )}
            <span />
            {DIMENSOES.findIndex(d => d.id === dimAtiva) < DIMENSOES.length - 1 && (
              <button
                style={styles.btnNavAv}
                onClick={() => {
                  const idx = DIMENSOES.findIndex(d => d.id === dimAtiva)
                  setDimAtiva(DIMENSOES[idx + 1].id)
                }}
              >
                {DIMENSOES[DIMENSOES.findIndex(d => d.id === dimAtiva) + 1].nome} →
              </button>
            )}
          </div>
        </div>
      </div>

      {/* Rodapé fixo */}
      <div style={styles.rodape}>
        {msg && (
          <div style={msg.tipo === 'ok' ? styles.msgOk : styles.msgErro}>{msg.texto}</div>
        )}
        <button
          onClick={handleSalvar}
          disabled={salvando}
          style={salvando ? styles.btnSalvarDis : styles.btnSalvar}
        >
          {salvando ? 'Salvando…' : 'Salvar prontuário'}
        </button>
      </div>
    </div>
  )
}

const styles: Record<string, React.CSSProperties> = {
  page: { minHeight: '100vh', backgroundColor: '#fafaf8', fontFamily: "'Inter','Helvetica Neue',Arial,sans-serif", paddingBottom: '80px' },
  loading: { minHeight: '100vh', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: '16px' },
  loadingDot: { width: '32px', height: '32px', borderRadius: '50%', border: '3px solid #e8e0cc', borderTopColor: '#d7ae4d', animation: 'spin 1s linear infinite' },
  loadingTxt: { fontSize: '14px', color: '#888' },
  header: { backgroundColor: '#1A3C2E', padding: '24px 32px', display: 'flex', flexDirection: 'column', gap: '4px' },
  btnVoltar: { background: 'none', border: 'none', color: 'rgba(255,255,255,0.6)', fontSize: '13px', cursor: 'pointer', padding: 0, marginBottom: '8px', textAlign: 'left' },
  logo: { fontSize: '11px', fontWeight: 700, letterSpacing: '0.14em', color: '#d7ae4d', textTransform: 'uppercase', marginBottom: '6px' },
  titulo: { fontSize: '22px', fontWeight: 700, color: '#ffffff', margin: 0, lineHeight: 1.2 },
  subtitulo: { fontSize: '14px', color: 'rgba(255,255,255,0.6)', margin: '4px 0 0 0' },
  completudeCard: { backgroundColor: '#ffffff', borderBottom: '1px solid #e8e0cc', padding: '20px 32px' },
  completudeInfo: { display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '8px' },
  completudeTxt: { fontSize: '13px', color: '#666', fontWeight: 500 },
  completudePct: { fontSize: '15px', fontWeight: 700, color: '#1A3C2E' },
  barraWrap: { height: '6px', backgroundColor: '#e8e0cc', borderRadius: '3px', overflow: 'hidden', marginBottom: '16px' },
  barraFill: { height: '100%', backgroundColor: '#d7ae4d', borderRadius: '3px', transition: 'width .4s ease' },
  flagsRow: { display: 'flex', gap: '8px', flexWrap: 'wrap' },
  flag: { display: 'flex', alignItems: 'center', gap: '5px', padding: '4px 10px', borderRadius: '100px', border: '1px solid', fontSize: '12px', fontWeight: 500 },
  flagDot: { width: '6px', height: '6px', borderRadius: '50%', flexShrink: 0 },
  flagNome: { fontWeight: 600 },
  corpo: { display: 'flex', maxWidth: '960px', margin: '0 auto', padding: '24px 16px', gap: '24px' },
  sidebar: { width: '200px', flexShrink: 0, display: 'flex', flexDirection: 'column', gap: '4px' },
  sideItem: { display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '10px 12px', borderRadius: '6px', border: '1px solid transparent', background: 'none', cursor: 'pointer', textAlign: 'left', transition: 'all .15s ease' },
  sideItemAtivo: { backgroundColor: '#ffffff', border: '1px solid #e8e0cc', boxShadow: '0 1px 3px rgba(0,0,0,0.06)' },
  sideItemLeft: { display: 'flex', alignItems: 'center', gap: '8px' },
  sideStatus: { width: '8px', height: '8px', borderRadius: '50%', flexShrink: 0 },
  sideNome: { fontSize: '13px', fontWeight: 600 },
  sideBadge: { fontSize: '10px', fontWeight: 600, padding: '2px 7px', borderRadius: '100px' },
  form: { flex: 1, backgroundColor: '#ffffff', border: '1px solid #e8e0cc', borderRadius: '8px', padding: '28px', display: 'flex', flexDirection: 'column', gap: '20px' },
  dimHeader: { borderBottom: '1px solid #e8e0cc', paddingBottom: '16px', marginBottom: '4px' },
  dimNome: { fontSize: '17px', fontWeight: 700, color: '#1A3C2E', margin: '0 0 4px 0' },
  dimDesc: { fontSize: '13px', color: '#888', margin: 0 },
  campo: { display: 'flex', flexDirection: 'column', gap: '6px' },
  label: { fontSize: '13px', fontWeight: 600, color: '#1A3C2E' },
  input: { height: '40px', border: '1.5px solid #d0c9b8', borderRadius: '6px', padding: '0 12px', fontSize: '14px', color: '#1a1a1a', backgroundColor: '#fff', outline: 'none', width: '100%', boxSizing: 'border-box' },
  textarea: { border: '1.5px solid #d0c9b8', borderRadius: '6px', padding: '10px 12px', fontSize: '14px', color: '#1a1a1a', backgroundColor: '#fff', outline: 'none', width: '100%', boxSizing: 'border-box', minHeight: '80px', resize: 'vertical', fontFamily: 'inherit' },
  select: { height: '40px', border: '1.5px solid #d0c9b8', borderRadius: '6px', padding: '0 12px', fontSize: '14px', color: '#1a1a1a', backgroundColor: '#fff', outline: 'none', width: '100%', boxSizing: 'border-box', appearance: 'none' },
  selectStatus: { height: '40px', border: '1.5px solid #d7ae4d', borderRadius: '6px', padding: '0 12px', fontSize: '14px', fontWeight: 600, color: '#1A3C2E', backgroundColor: '#fffbf0', outline: 'none', width: '100%', boxSizing: 'border-box', appearance: 'none' },
  radioGrupo: { display: 'flex', gap: '8px', flexWrap: 'wrap' },
  radioBotao: { height: '36px', padding: '0 16px', border: '1.5px solid #d0c9b8', borderRadius: '6px', backgroundColor: '#fff', fontSize: '13px', fontWeight: 500, color: '#444', cursor: 'pointer' },
  radioBotaoAtivo: { height: '36px', padding: '0 16px', border: '1.5px solid #d7ae4d', borderRadius: '6px', backgroundColor: '#fffbf0', fontSize: '13px', fontWeight: 700, color: '#1A3C2E', cursor: 'pointer' },
  navDims: { display: 'flex', justifyContent: 'space-between', paddingTop: '8px', borderTop: '1px solid #e8e0cc', marginTop: '8px' },
  btnNav: { background: 'none', border: 'none', color: '#888', fontSize: '13px', cursor: 'pointer', padding: '4px 0' },
  btnNavAv: { background: 'none', border: 'none', color: '#1A3C2E', fontSize: '13px', fontWeight: 600, cursor: 'pointer', padding: '4px 0' },
  rodape: { position: 'fixed', bottom: 0, left: 0, right: 0, backgroundColor: '#fff', borderTop: '1px solid #e8e0cc', padding: '12px 32px', display: 'flex', alignItems: 'center', justifyContent: 'flex-end', gap: '16px', zIndex: 100 },
  msgOk: { fontSize: '13px', color: '#16a34a', fontWeight: 500 },
  msgErro: { fontSize: '13px', color: '#dc2626', fontWeight: 500 },
  btnSalvar: { height: '40px', padding: '0 28px', backgroundColor: '#1A3C2E', color: '#fff', border: 'none', borderRadius: '6px', fontSize: '14px', fontWeight: 700, cursor: 'pointer' },
  btnSalvarDis: { height: '40px', padding: '0 28px', backgroundColor: '#8aab9a', color: '#fff', border: 'none', borderRadius: '6px', fontSize: '14px', fontWeight: 700, cursor: 'not-allowed' },
}
