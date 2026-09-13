create table if not exists public.hotmart_products (
  id text primary key,
  name text not null,
  status text not null default 'active',
  delivery_type text not null,
  delivery_asset text,
  sales_count integer not null default 0 check (sales_count >= 0),
  net_revenue_cents integer not null default 0,
  updated_at timestamptz not null default now()
);

create table if not exists public.hotmart_purchases (
  transaction_id text primary key,
  product_id text not null,
  product_name text not null,
  buyer_name text,
  buyer_email text,
  purchase_status text not null,
  delivery_status text not null default 'pending',
  access_status text not null default 'not_applicable',
  gross_cents integer,
  net_cents integer,
  purchased_at timestamptz,
  first_access_at timestamptz,
  completed_at timestamptz,
  updated_at timestamptz not null default now()
);

create table if not exists public.hotmart_webhook_events (
  event_id text primary key,
  event_type text not null,
  transaction_id text,
  product_id text,
  accepted boolean not null default true,
  received_at timestamptz not null default now(),
  raw_payload jsonb not null
);

create table if not exists public.hotmart_integration_config (
  key text primary key,
  secret_value text not null,
  updated_at timestamptz not null default now()
);

alter table public.hotmart_products enable row level security;
alter table public.hotmart_purchases enable row level security;
alter table public.hotmart_webhook_events enable row level security;
alter table public.hotmart_integration_config enable row level security;

revoke all on table public.hotmart_products from anon, authenticated;
revoke all on table public.hotmart_purchases from anon, authenticated;
revoke all on table public.hotmart_webhook_events from anon, authenticated;
revoke all on table public.hotmart_integration_config from anon, authenticated;

grant all on table public.hotmart_products to service_role;
grant all on table public.hotmart_purchases to service_role;
grant all on table public.hotmart_webhook_events to service_role;
grant all on table public.hotmart_integration_config to service_role;

create index if not exists hotmart_purchases_product_idx on public.hotmart_purchases(product_id);
create index if not exists hotmart_purchases_access_idx on public.hotmart_purchases(access_status);
create index if not exists hotmart_events_received_idx on public.hotmart_webhook_events(received_at desc);