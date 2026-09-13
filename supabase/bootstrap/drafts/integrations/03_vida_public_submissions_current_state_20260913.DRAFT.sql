
CREATE TABLE IF NOT EXISTS public.vida_public_submissions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  submission_id uuid NOT NULL,
  instrument text NOT NULL CHECK (instrument IN (
    'diagnostico-360','scanner-protecao-global','planejamento-sucessorio',
    'robustez-patrimonial','mapa-vida-protecao','tensoes-patrimoniais',
    'continuidade-patrimonial','arquitetura-decisoria',
    'comportamento-patrimonial','continuidade-medica','protecao-global',
    'scanner-advogados','motor-vida-ivad','risco-comportamental',
    'independencia-financeira','maturidade-decisoria','eficiencia-fiscal'
  )),
  stage text NOT NULL DEFAULT 'complete'
    CHECK (stage IN ('lead','partial','complete')),
  nome text NOT NULL CHECK (char_length(nome) BETWEEN 2 AND 120),
  email text CHECK (
    email IS NULL OR
    (char_length(email) <= 254 AND email ~* '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]{2,}$')
  ),
  whatsapp text CHECK (
    whatsapp IS NULL OR whatsapp ~ '^[0-9]{10,13}$'
  ),
  answers jsonb NOT NULL DEFAULT '{}'::jsonb
    CHECK (jsonb_typeof(answers) IN ('object','array')),
  result jsonb NOT NULL DEFAULT '{}'::jsonb
    CHECK (jsonb_typeof(result) = 'object'),
  client_computed boolean NOT NULL DEFAULT true,
  consentimento_dados boolean NOT NULL CHECK (consentimento_dados = true),
  consentimento_marketing boolean NOT NULL DEFAULT false,
  versao_consentimento text NOT NULL,
  pagina_origem text,
  user_agent text,
  ip_hash text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (submission_id, instrument, stage)
);

COMMENT ON TABLE public.vida_public_submissions IS
'Recepção central de scanners públicos VIDA. Sem leitura/escrita pública direta; acesso somente pela Edge Function validada. Resultados marcados como client_computed até migração do scoring para servidor.';

ALTER TABLE public.vida_public_submissions ENABLE ROW LEVEL SECURITY;
REVOKE ALL PRIVILEGES ON TABLE public.vida_public_submissions FROM PUBLIC;
REVOKE ALL PRIVILEGES ON TABLE public.vida_public_submissions FROM anon;
REVOKE ALL PRIVILEGES ON TABLE public.vida_public_submissions FROM authenticated;
GRANT ALL PRIVILEGES ON TABLE public.vida_public_submissions TO service_role;

CREATE INDEX IF NOT EXISTS vida_public_submissions_created_at_idx
ON public.vida_public_submissions (created_at DESC);
CREATE INDEX IF NOT EXISTS vida_public_submissions_instrument_created_at_idx
ON public.vida_public_submissions (instrument, created_at DESC);
CREATE INDEX IF NOT EXISTS vida_public_submissions_ip_hash_created_at_idx
ON public.vida_public_submissions (ip_hash, created_at DESC);
CREATE INDEX IF NOT EXISTS vida_public_submissions_email_idx
ON public.vida_public_submissions (email);
