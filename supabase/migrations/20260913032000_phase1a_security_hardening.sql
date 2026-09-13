-- VIDA OS™ — Gate 0 / M1
-- Phase 1A security hardening only.
-- This migration is intentionally non-functional: it changes no business semantics
-- and performs no data backfill.

begin;

-- Fix mutable search_path findings on Phase 1A functions/triggers.
alter function public.canonical_reconciliation(uuid, timestamp with time zone)
  set search_path = '';

alter function public.reconciliation_source_block_mutation()
  set search_path = '';

alter function public.reconciliation_record_block_mutation()
  set search_path = '';

alter function public.reconciliation_record_validate_succession()
  set search_path = '';

alter function public.entity_relationships_enforce_owns_target()
  set search_path = '';

alter function public.economic_entities_protect_owns_target()
  set search_path = '';

-- Cover the Phase 1A FK reported by the Supabase performance advisor.
create index if not exists reconciliation_record_economic_entity_id_idx
  on public.reconciliation_record (economic_entity_id);

commit;
