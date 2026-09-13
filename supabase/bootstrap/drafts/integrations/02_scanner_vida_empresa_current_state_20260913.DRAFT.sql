create table public.scanner_vida_empresa_submissions (
  id uuid primary key default gen_random_uuid(),
  submission_id uuid not null,
  stage text not null check (stage in ('partial', 'complete')),
  nome text not null check (char_length(nome) between 5 and 120),
  whatsapp text not null check (whatsapp ~ '^[0-9]{10,13}$'),
  email text,
  faturamento text,
  pergunta_atual smallint check (pergunta_atual between 1 and 9),
  indice_vida_empresa smallint check (indice_vida_empresa between 0 and 100),
  fase text,
  dependencia_operacional smallint check (dependencia_operacional between 0 and 100),
  blindagem_juridica smallint check (blindagem_juridica between 0 and 100),
  continuidade_financeira smallint check (continuidade_financeira between 0 and 100),
  respostas jsonb not null default '[]'::jsonb,
  consentimento_dados boolean not null,
  consentimento_marketing boolean not null default false,
  versao_consentimento text not null,
  origem text not null default 'scanner-vida-empresa',
  pagina_origem text,
  user_agent text,
  ip_hash text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint scanner_vida_empresa_submission_stage_key unique (submission_id, stage),
  constraint scanner_vida_empresa_email_check check (
    email is null or email ~* '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]{2,}$'
  ),
  constraint scanner_vida_empresa_respostas_check check (jsonb_typeof(respostas) = 'array'),
  constraint scanner_vida_empresa_complete_check check (
    stage <> 'complete' or (
      email is not null and
      indice_vida_empresa is not null and
      fase is not null and
      dependencia_operacional is not null and
      blindagem_juridica is not null and
      continuidade_financeira is not null and
      jsonb_array_length(respostas) = 9
    )
  )
);

comment on table public.scanner_vida_empresa_submissions is
  'Capturas parcial e completa do Scanner VIDA Empresa. Sem leitura pública; escrita somente pela Edge Function validada.';

alter table public.scanner_vida_empresa_submissions enable row level security;
revoke all on table public.scanner_vida_empresa_submissions from anon, authenticated;
grant select, insert, update, delete on table public.scanner_vida_empresa_submissions to service_role;

create index scanner_vida_empresa_submissions_created_at_idx
  on public.scanner_vida_empresa_submissions (created_at desc);
create index scanner_vida_empresa_submissions_ip_hash_created_at_idx
  on public.scanner_vida_empresa_submissions (ip_hash, created_at desc);
create index scanner_vida_empresa_submissions_email_idx
  on public.scanner_vida_empresa_submissions (lower(email))
  where email is not null;