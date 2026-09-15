import type { SupabaseClient } from '@supabase/supabase-js'
import { VidaOsError } from '../vida-os/errors'

export const PLANNING_CONTENT_READ_MODEL_CONTRACT = {
  summary: {
    view: 'pc_rm_engagement_content_summary',
    select:
      'client_account_id,planning_engagement_id,interview_count,instrument_run_count,synthesis_count,active_hypothesis_count,accepted_hypothesis_count,open_agenda_count,session_count,report_count,current_validated_report_count,plan_count,implementation_count,review_count',
  },
  interview: {
    view: 'pc_rm_interview_current',
    select:
      'client_account_id,planning_engagement_id,interview_record_id,current_version_id,current_version_no,current_version_recorded_at,context_narrative,objectives_narrative,draft_revision,draft_base_version_id,draft_updated_at,has_active_draft',
  },
  instrument: {
    view: 'pc_rm_instrument_current',
    select:
      'client_account_id,planning_engagement_id,instrument_run_id,instrument_code,current_version_id,current_version_no,current_version_recorded_at,instrument_completed_at,result_envelope,contribution_count',
  },
  synthesis: {
    view: 'pc_rm_synthesis_current',
    select:
      'client_account_id,planning_engagement_id,diagnostic_synthesis_id,current_version_id,current_version_no,current_version_recorded_at,integrated_synthesis_narrative,proposal_count',
  },
  hypothesis: {
    view: 'pc_rm_working_hypothesis_current',
    select:
      'client_account_id,planning_engagement_id,working_hypothesis_id,origin_diagnostic_synthesis_version_id,origin_proposal_key,current_version_id,current_version_no,current_version_recorded_at,hypothesis_statement,current_state,current_state_at,draft_revision,draft_base_version_id,has_active_draft',
  },
  agenda: {
    view: 'pc_rm_open_agenda_current',
    select:
      'client_account_id,planning_engagement_id,hypothesis_agenda_id,current_version_id,current_version_no,current_version_recorded_at,agenda_narrative,current_state,current_state_at,item_count,draft_revision,has_active_draft',
  },
  session: {
    view: 'pc_rm_session_current',
    select:
      'client_account_id,planning_engagement_id,diagnostic_session_id,current_version_id,current_version_no,current_version_recorded_at,session_occurred_at,session_narrative,hypothesis_count,decision_note_count,draft_revision,draft_base_version_id,has_active_draft',
  },
  report: {
    view: 'pc_rm_report_current',
    select:
      'client_account_id,planning_engagement_id,diagnostic_report_id,current_version_id,current_version_no,current_version_recorded_at,report_narrative,consensus_subject_economic_entity_id,current_state,current_state_at,latest_consensus_understood,latest_consensus_agreed,latest_consensus_at,source_session_count,hypothesis_count,draft_revision,draft_base_version_id,has_active_draft',
  },
  plan: {
    view: 'pc_rm_plan_current',
    select:
      'client_account_id,planning_engagement_id,financial_plan_id,current_version_id,current_version_no,current_version_recorded_at,diagnostic_report_id,diagnostic_report_version_id,goal_count,strategy_count,hypothesis_count,draft_revision,draft_base_version_id,has_active_draft',
  },
  implementation: {
    view: 'pc_rm_implementation_current',
    select:
      'client_account_id,planning_engagement_id,implementation_episode_id,current_version_id,current_version_no,current_version_recorded_at,financial_plan_id,financial_plan_version_id,implemented_at,implementation_narrative',
  },
  review: {
    view: 'pc_rm_review_current',
    select:
      'client_account_id,planning_engagement_id,review_episode_id,current_version_id,current_version_no,current_version_recorded_at,implementation_episode_id,implementation_episode_version_id,reviewed_at,review_narrative',
  },
  timeline: {
    view: 'pc_rm_engagement_timeline',
    select:
      'client_account_id,planning_engagement_id,occurred_at,object_type,object_id,version_or_event_id,event_key,actor_stamp_id,state',
  },
} as const

export type EngagementContentSummary = {
  client_account_id: string
  planning_engagement_id: string
  interview_count: number
  instrument_run_count: number
  synthesis_count: number
  active_hypothesis_count: number
  accepted_hypothesis_count: number
  open_agenda_count: number
  session_count: number
  report_count: number
  current_validated_report_count: number
  plan_count: number
  implementation_count: number
  review_count: number
}

export type InterviewCurrent = {
  client_account_id: string
  planning_engagement_id: string
  interview_record_id: string
  current_version_id: string | null
  current_version_no: number | null
  current_version_recorded_at: string | null
  context_narrative: string | null
  objectives_narrative: string | null
  draft_revision: number | null
  draft_base_version_id: string | null
  draft_updated_at: string | null
  has_active_draft: boolean
}

export type InstrumentCurrent = {
  client_account_id: string
  planning_engagement_id: string
  instrument_run_id: string
  instrument_code: string
  current_version_id: string | null
  current_version_no: number | null
  current_version_recorded_at: string | null
  instrument_completed_at: string | null
  result_envelope: unknown
  contribution_count: number
}

export type SynthesisCurrent = {
  client_account_id: string
  planning_engagement_id: string
  diagnostic_synthesis_id: string
  current_version_id: string | null
  current_version_no: number | null
  current_version_recorded_at: string | null
  integrated_synthesis_narrative: string | null
  proposal_count: number
}

export type WorkingHypothesisCurrent = {
  client_account_id: string
  planning_engagement_id: string
  working_hypothesis_id: string
  origin_diagnostic_synthesis_version_id: string
  origin_proposal_key: string
  current_version_id: string | null
  current_version_no: number | null
  current_version_recorded_at: string | null
  hypothesis_statement: string | null
  current_state: string | null
  current_state_at: string | null
  draft_revision: number | null
  draft_base_version_id: string | null
  has_active_draft: boolean
}

export type OpenAgendaCurrent = {
  client_account_id: string
  planning_engagement_id: string
  hypothesis_agenda_id: string
  current_version_id: string | null
  current_version_no: number | null
  current_version_recorded_at: string | null
  agenda_narrative: string | null
  current_state: string
  current_state_at: string
  item_count: number
  draft_revision: number | null
  has_active_draft: boolean
}

export type SessionCurrent = {
  client_account_id: string
  planning_engagement_id: string
  diagnostic_session_id: string
  current_version_id: string | null
  current_version_no: number | null
  current_version_recorded_at: string | null
  session_occurred_at: string | null
  session_narrative: string | null
  hypothesis_count: number
  decision_note_count: number
  draft_revision: number | null
  draft_base_version_id: string | null
  has_active_draft: boolean
}

export type ReportCurrent = {
  client_account_id: string
  planning_engagement_id: string
  diagnostic_report_id: string
  current_version_id: string | null
  current_version_no: number | null
  current_version_recorded_at: string | null
  report_narrative: string | null
  consensus_subject_economic_entity_id: string | null
  current_state: string | null
  current_state_at: string | null
  latest_consensus_understood: boolean | null
  latest_consensus_agreed: boolean | null
  latest_consensus_at: string | null
  source_session_count: number
  hypothesis_count: number
  draft_revision: number | null
  draft_base_version_id: string | null
  has_active_draft: boolean
}

export type PlanCurrent = {
  client_account_id: string
  planning_engagement_id: string
  financial_plan_id: string
  current_version_id: string | null
  current_version_no: number | null
  current_version_recorded_at: string | null
  diagnostic_report_id: string | null
  diagnostic_report_version_id: string | null
  goal_count: number
  strategy_count: number
  hypothesis_count: number
  draft_revision: number | null
  draft_base_version_id: string | null
  has_active_draft: boolean
}

export type ImplementationCurrent = {
  client_account_id: string
  planning_engagement_id: string
  implementation_episode_id: string
  current_version_id: string | null
  current_version_no: number | null
  current_version_recorded_at: string | null
  financial_plan_id: string | null
  financial_plan_version_id: string | null
  implemented_at: string | null
  implementation_narrative: string | null
}

export type ReviewCurrent = {
  client_account_id: string
  planning_engagement_id: string
  review_episode_id: string
  current_version_id: string | null
  current_version_no: number | null
  current_version_recorded_at: string | null
  implementation_episode_id: string | null
  implementation_episode_version_id: string | null
  reviewed_at: string | null
  review_narrative: string | null
}

export type TimelineEntry = {
  client_account_id: string
  planning_engagement_id: string
  occurred_at: string
  object_type: string
  object_id: string
  version_or_event_id: string
  event_key: string
  actor_stamp_id: string
  state: string | null
}

export type PfpCockpitSnapshot = {
  summary: EngagementContentSummary
  interviews: InterviewCurrent[]
  instruments: InstrumentCurrent[]
  syntheses: SynthesisCurrent[]
  hypotheses: WorkingHypothesisCurrent[]
  openAgendas: OpenAgendaCurrent[]
  sessions: SessionCurrent[]
  reports: ReportCurrent[]
  plans: PlanCurrent[]
  implementations: ImplementationCurrent[]
  reviews: ReviewCurrent[]
  timeline: TimelineEntry[]
}

function failRead(view: string, error: unknown): never {
  throw new VidaOsError(
    'DOMAIN_READ_FAILED',
    `Planning Content read failed for ${view}.`,
    error
  )
}

async function listRows<T>(
  supabase: SupabaseClient,
  contract: { readonly view: string; readonly select: string },
  planningEngagementId: string
): Promise<T[]> {
  const { data, error } = await supabase
    .from(contract.view)
    .select(contract.select)
    .eq('planning_engagement_id', planningEngagementId)

  if (error) failRead(contract.view, error)
  return (data ?? []) as T[]
}

export async function listPfpEngagementSummaries(
  supabase: SupabaseClient
): Promise<EngagementContentSummary[]> {
  const contract = PLANNING_CONTENT_READ_MODEL_CONTRACT.summary
  const { data, error } = await supabase
    .from(contract.view)
    .select(contract.select)
    .order('planning_engagement_id', { ascending: true })

  if (error) failRead(contract.view, error)
  return (data ?? []) as EngagementContentSummary[]
}

export async function loadPfpCockpitSnapshot(
  supabase: SupabaseClient,
  planningEngagementId: string
): Promise<PfpCockpitSnapshot | null> {
  const summaryContract = PLANNING_CONTENT_READ_MODEL_CONTRACT.summary
  const summaryResult = await supabase
    .from(summaryContract.view)
    .select(summaryContract.select)
    .eq('planning_engagement_id', planningEngagementId)
    .maybeSingle()

  if (summaryResult.error) failRead(summaryContract.view, summaryResult.error)
  if (!summaryResult.data) return null

  const c = PLANNING_CONTENT_READ_MODEL_CONTRACT
  const [
    interviews,
    instruments,
    syntheses,
    hypotheses,
    openAgendas,
    sessions,
    reports,
    plans,
    implementations,
    reviews,
  ] = await Promise.all([
    listRows<InterviewCurrent>(supabase, c.interview, planningEngagementId),
    listRows<InstrumentCurrent>(supabase, c.instrument, planningEngagementId),
    listRows<SynthesisCurrent>(supabase, c.synthesis, planningEngagementId),
    listRows<WorkingHypothesisCurrent>(supabase, c.hypothesis, planningEngagementId),
    listRows<OpenAgendaCurrent>(supabase, c.agenda, planningEngagementId),
    listRows<SessionCurrent>(supabase, c.session, planningEngagementId),
    listRows<ReportCurrent>(supabase, c.report, planningEngagementId),
    listRows<PlanCurrent>(supabase, c.plan, planningEngagementId),
    listRows<ImplementationCurrent>(supabase, c.implementation, planningEngagementId),
    listRows<ReviewCurrent>(supabase, c.review, planningEngagementId),
  ])

  const timelineContract = c.timeline
  const timelineResult = await supabase
    .from(timelineContract.view)
    .select(timelineContract.select)
    .eq('planning_engagement_id', planningEngagementId)
    .order('occurred_at', { ascending: false })

  if (timelineResult.error) failRead(timelineContract.view, timelineResult.error)

  return {
    summary: summaryResult.data as EngagementContentSummary,
    interviews,
    instruments,
    syntheses,
    hypotheses,
    openAgendas,
    sessions,
    reports,
    plans,
    implementations,
    reviews,
    timeline: (timelineResult.data ?? []) as TimelineEntry[],
  }
}
