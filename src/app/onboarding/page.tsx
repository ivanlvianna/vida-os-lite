'use client'

import { useState } from 'react'
import { salvarOnboarding } from './actions'

const profissaoOpcoes = ['Executivo','Empresário','Médico','Advogado','Profissional liberal','Outros']
const estadoCivilOpcoes = ['Solteiro','Casado','Divorciado','Viúvo','União estável']
const faixaPatrimonioOpcoes = [
  'Até R$ 500.000,00',
  'R$ 500.000,00 a R$ 2.000.000,00',
  'R$ 2.000.000,00 a R$ 5.000.000,00',
  'Acima de R$ 5.000.000,00',
]

type FormData = {
  nome_completo: string
  telefone_whatsapp: string
  data_nascimento: string
  profissao: string
  estado_civil: string
  numero_dependentes: number
  possui_empresa: boolean | null
  possui_imoveis: boolean | null
  faixa_patrimonio: string
  lgpd_aceito: boolean
  termos_aceito: boolean
}

const initialForm: FormData = {
  nome_completo: '',
  telefone_whatsapp: '',
  data_nascimento: '',
  profissao: '',
  estado_civil: '',
  numero_dependentes: 0,
  possui_empresa: null,
  possui_imoveis: null,
  faixa_patrimonio: '',
  lgpd_aceito: false,
  termos_aceito: false,
}

export default function OnboardingPage() {
  const [form, setForm] = useState<FormData>(initialForm)
  const [erro, setErro] = useState<string | null>(null)
  const [salvando, setSalvando] = useState(false)

  function handleChange(e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) {
    const target = e.target as HTMLInputElement
    const { name, value, type } = target
    const checked = type === 'checkbox' ? target.checked : undefined
    setForm((prev) => ({ ...prev, [name]: type === 'checkbox' ? checked : value }))
  }

  function handleRadio(name: keyof FormData, value: boolean) {
    setForm((prev) => ({ ...prev, [name]: value }))
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setErro(null)
    if (!form.telefone_whatsapp.trim()) { setErro('O telefone WhatsApp é obrigatório.'); return }
    if (!form.lgpd_aceito) { setErro('É necessário aceitar a política de privacidade para continuar.'); return }
    if (!form.termos_aceito) { setErro('É necessário aceitar os termos de uso para continuar.'); return }
    setSalvando(true)
    const resultado = await salvarOnboarding(form)
    if (resultado?.erro) { setErro(resultado.erro); setSalvando(false) }
  }

  return (
    <div style={styles.page}>
      <div style={styles.card}>
        <div style={styles.header}>
          <div style={styles.logo}>VIDA OS™</div>
          <h1 style={styles.titulo}>Configure seu perfil patrimonial</h1>
          <p style={styles.subtitulo}>Estas informações permitem personalizar sua experiência e gerar diagnósticos precisos. Você pode atualizar seus dados a qualquer momento.</p>
        </div>
        <form onSubmit={handleSubmit} style={styles.form}>
          <section style={styles.secao}>
            <h2 style={styles.secaoTitulo}>Dados pessoais</h2>
            <div style={styles.campo}>
              <label style={styles.label}>Nome completo</label>
              <input type="text" name="nome_completo" value={form.nome_completo} onChange={handleChange} placeholder="Seu nome completo" style={styles.input} />
            </div>
            <div style={styles.campo}>
              <label style={styles.label}>Telefone WhatsApp <span style={styles.obrigatorio}>*</span></label>
              <input type="tel" name="telefone_whatsapp" value={form.telefone_whatsapp} onChange={handleChange} placeholder="+55 11 99999-9999" style={styles.input} />
            </div>
            <div style={styles.campo}>
              <label style={styles.label}>Data de nascimento</label>
              <input type="date" name="data_nascimento" value={form.data_nascimento} onChange={handleChange} style={styles.input} />
            </div>
            <div style={styles.grade2}>
              <div style={styles.campo}>
                <label style={styles.label}>Profissão</label>
                <select name="profissao" value={form.profissao} onChange={handleChange} style={styles.select}>
                  <option value="">Selecione</option>
                  {profissaoOpcoes.map((o) => <option key={o} value={o}>{o}</option>)}
                </select>
              </div>
              <div style={styles.campo}>
                <label style={styles.label}>Estado civil</label>
                <select name="estado_civil" value={form.estado_civil} onChange={handleChange} style={styles.select}>
                  <option value="">Selecione</option>
                  {estadoCivilOpcoes.map((o) => <option key={o} value={o}>{o}</option>)}
                </select>
              </div>
            </div>
            <div style={styles.campo}>
              <label style={styles.label}>Número de dependentes</label>
              <input type="number" name="numero_dependentes" value={form.numero_dependentes} onChange={handleChange} min={0} max={20} style={{ ...styles.input, maxWidth: '120px' }} />
            </div>
          </section>
          <section style={styles.secao}>
            <h2 style={styles.secaoTitulo}>Perfil patrimonial</h2>
            <div style={styles.grade2}>
              <div style={styles.campo}>
                <label style={styles.label}>Possui empresa?</label>
                <div style={styles.radioGrupo}>
                  <button type="button" onClick={() => handleRadio('possui_empresa', true)} style={form.possui_empresa === true ? styles.radioBotaoAtivo : styles.radioBotao}>Sim</button>
                  <button type="button" onClick={() => handleRadio('possui_empresa', false)} style={form.possui_empresa === false ? styles.radioBotaoAtivo : styles.radioBotao}>Não</button>
                </div>
              </div>
              <div style={styles.campo}>
                <label style={styles.label}>Possui imóveis?</label>
                <div style={styles.radioGrupo}>
                  <button type="button" onClick={() => handleRadio('possui_imoveis', true)} style={form.possui_imoveis === true ? styles.radioBotaoAtivo : styles.radioBotao}>Sim</button>
                  <button type="button" onClick={() => handleRadio('possui_imoveis', false)} style={form.possui_imoveis === false ? styles.radioBotaoAtivo : styles.radioBotao}>Não</button>
                </div>
              </div>
            </div>
            <div style={styles.campo}>
              <label style={styles.label}>Faixa de patrimônio estimado</label>
              <select name="faixa_patrimonio" value={form.faixa_patrimonio} onChange={handleChange} style={styles.select}>
                <option value="">Selecione</option>
                {faixaPatrimonioOpcoes.map((o) => <option key={o} value={o}>{o}</option>)}
              </select>
            </div>
          </section>
          <section style={styles.secao}>
            <h2 style={styles.secaoTitulo}>Consentimento e termos</h2>
            <label style={styles.checkboxLabel}>
              <input type="checkbox" name="lgpd_aceito" checked={form.lgpd_aceito} onChange={handleChange} style={styles.checkbox} />
              <span>Li e aceito a <a href="/privacidade" target="_blank" style={styles.link}>política de privacidade</a> e o tratamento dos meus dados conforme a LGPD. <span style={styles.obrigatorio}>*</span></span>
            </label>
            <label style={styles.checkboxLabel}>
              <input type="checkbox" name="termos_aceito" checked={form.termos_aceito} onChange={handleChange} style={styles.checkbox} />
              <span>Li e aceito os <a href="/termos" target="_blank" style={styles.link}>termos de uso</a> da plataforma VIDA OS™. <span style={styles.obrigatorio}>*</span></span>
            </label>
          </section>
          {erro && <div style={styles.erro}>{erro}</div>}
          <button type="submit" disabled={salvando} style={salvando ? styles.botaoDesabilitado : styles.botao}>
            {salvando ? 'Salvando...' : 'Concluir configuração e acessar o painel'}
          </button>
        </form>
      </div>
    </div>
  )
}

const styles: Record<string, React.CSSProperties> = {
  page: { minHeight: '100vh', backgroundColor: '#ffffff', display: 'flex', alignItems: 'flex-start', justifyContent: 'center', padding: '48px 16px', fontFamily: "'Inter', 'Helvetica Neue', Arial, sans-serif" },
  card: { width: '100%', maxWidth: '680px' },
  header: { marginBottom: '40px' },
  logo: { fontSize: '13px', fontWeight: 700, letterSpacing: '0.12em', color: '#d7ae4d', textTransform: 'uppercase', marginBottom: '20px' },
  titulo: { fontSize: '28px', fontWeight: 700, color: '#1A3C2E', margin: '0 0 12px 0', lineHeight: 1.2 },
  subtitulo: { fontSize: '16px', color: '#444444', lineHeight: 1.6, margin: 0 },
  form: { display: 'flex', flexDirection: 'column', gap: '0px' },
  secao: { borderTop: '1px solid #e8e0cc', paddingTop: '32px', marginBottom: '32px', display: 'flex', flexDirection: 'column', gap: '20px' },
  secaoTitulo: { fontSize: '13px', fontWeight: 700, letterSpacing: '0.10em', textTransform: 'uppercase', color: '#d7ae4d', margin: '0 0 4px 0' },
  campo: { display: 'flex', flexDirection: 'column', gap: '6px' },
  label: { fontSize: '14px', fontWeight: 600, color: '#1A3C2E', lineHeight: 1.4 },
  obrigatorio: { color: '#c0392b' },
  input: { height: '44px', border: '1.5px solid #d0c9b8', borderRadius: '6px', padding: '0 14px', fontSize: '15px', color: '#1a1a1a', backgroundColor: '#ffffff', outline: 'none', width: '100%', boxSizing: 'border-box' },
  select: { height: '44px', border: '1.5px solid #d0c9b8', borderRadius: '6px', padding: '0 14px', fontSize: '15px', color: '#1a1a1a', backgroundColor: '#ffffff', outline: 'none', width: '100%', boxSizing: 'border-box', appearance: 'none', cursor: 'pointer' },
  grade2: { display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' },
  radioGrupo: { display: 'flex', gap: '10px', marginTop: '2px' },
  radioBotao: { height: '40px', padding: '0 24px', border: '1.5px solid #d0c9b8', borderRadius: '6px', backgroundColor: '#ffffff', fontSize: '14px', fontWeight: 500, color: '#444444', cursor: 'pointer' },
  radioBotaoAtivo: { height: '40px', padding: '0 24px', border: '1.5px solid #d7ae4d', borderRadius: '6px', backgroundColor: '#fdf8ec', fontSize: '14px', fontWeight: 700, color: '#1A3C2E', cursor: 'pointer' },
  checkboxLabel: { display: 'flex', alignItems: 'flex-start', gap: '10px', fontSize: '14px', color: '#333333', lineHeight: 1.6, cursor: 'pointer' },
  checkbox: { marginTop: '3px', accentColor: '#1A3C2E', width: '16px', height: '16px', flexShrink: 0 },
  link: { color: '#1A3C2E', fontWeight: 600, textDecoration: 'underline' },
  erro: { backgroundColor: '#fef2f2', border: '1px solid #fca5a5', borderRadius: '6px', padding: '12px 16px', fontSize: '14px', color: '#991b1b', marginBottom: '8px' },
  botao: { height: '52px', backgroundColor: '#1A3C2E', color: '#ffffff', border: 'none', borderRadius: '6px', fontSize: '15px', fontWeight: 700, cursor: 'pointer', marginTop: '8px', width: '100%' },
  botaoDesabilitado: { height: '52px', backgroundColor: '#8aab9a', color: '#ffffff', border: 'none', borderRadius: '6px', fontSize: '15px', fontWeight: 700, cursor: 'not-allowed', marginTop: '8px', width: '100%' },
}
