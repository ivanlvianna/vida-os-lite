create or replace view public.pc_rm_engagement_content_summary
with (security_invoker=true) as
select
  pe.client_account_id,
  pe.id as planning_engagement_id,
  (select count(*) from public.planning_content_interview_records x
    where x.client_account_id=pe.client_account_id and x.planning_engagement_id=pe.id)::bigint as interview_count,
  (select count(*) from public.planning_content_instrument_runs x
    where x.client_account_id=pe.client_account_id and x.planning_engagement_id=pe.id)::bigint as instrument_run_count,
  (select count(*) from public.planning_content_diagnostic_syntheses x
    where x.client_account_id=pe.client_account_id and x.planning_engagement_id=pe.id)::bigint as synthesis_count,
  (select count(*) from public.pc_rm_working_hypothesis_current x
    where x.client_account_id=pe.client_account_id and x.planning_engagement_id=pe.id
      and x.current_state='active')::bigint as active_hypothesis_count,
  (select count(*) from public.pc_rm_working_hypothesis_current x
    where x.client_account_id=pe.client_account_id and x.planning_engagement_id=pe.id
      and x.current_state='accepted_for_planning')::bigint as accepted_hypothesis_count,
  (select count(*) from public.pc_rm_open_agenda_current x
    where x.client_account_id=pe.client_account_id and x.planning_engagement_id=pe.id)::bigint as open_agenda_count,
  (select count(*) from public.planning_content_diagnostic_sessions x
    where x.client_account_id=pe.client_account_id and x.planning_engagement_id=pe.id)::bigint as session_count,
  (select count(*) from public.planning_content_diagnostic_reports x
    where x.client_account_id=pe.client_account_id and x.planning_engagement_id=pe.id)::bigint as report_count,
  (select count(*) from public.pc_rm_report_current x
    where x.client_account_id=pe.client_account_id and x.planning_engagement_id=pe.id
      and x.current_state='validated')::bigint as current_validated_report_count,
  (select count(*) from public.planning_content_financial_plans x
    where x.client_account_id=pe.client_account_id and x.planning_engagement_id=pe.id)::bigint as plan_count,
  (select count(*) from public.planning_content_implementation_episodes x
    where x.client_account_id=pe.client_account_id and x.planning_engagement_id=pe.id)::bigint as implementation_count,
  (select count(*) from public.planning_content_review_episodes x
    where x.client_account_id=pe.client_account_id and x.planning_engagement_id=pe.id)::bigint as review_count
from public.planning_engagements pe
where public.is_staff(pe.client_account_id);

revoke all on table public.pc_rm_engagement_content_summary
from public,anon,authenticated,service_role;

grant select on table public.pc_rm_engagement_content_summary
to authenticated;
