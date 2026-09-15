-- VIDA OS™ — PC-M09 Staff Summary Fix Candidate v0.1
-- STATUS: CANDIDATE / NON-DEPLOYED
-- DATE: 2026-09-14
--
-- Problem proven in D3:
-- a client with valid ClientAccount membership + engagement/entity client
-- authorizations can see one pc_rm_engagement_content_summary row because the
-- view is rooted in planning_engagements, whose RLS legitimately exposes that
-- PlanningEngagement to the client. The Planning Content subqueries themselves
-- remain hidden, but the summary row leaks the staff read surface.
--
-- Required invariant:
-- PC-M09 v1 is staff-only. Client report consensus is a narrow write
-- capability and must not imply staff read-model visibility.
--
-- Candidate behavior proven with transactional assertions:
-- client current view row count = 1;
-- client with public.is_staff(pe.client_account_id) filter = 0;
-- staff with the same filter = 1.
--
-- DO NOT APPLY WITHOUT EXPLICIT AUTHORIZATION.

create or replace view public.pc_rm_engagement_content_summary
with (security_invoker=true) as
select
  pe.client_account_id,
  pe.id as planning_engagement_id,
  (select count(*)
     from public.planning_content_interview_records x
    where x.client_account_id=pe.client_account_id
      and x.planning_engagement_id=pe.id)::bigint as interview_count,
  (select count(*)
     from public.planning_content_instrument_runs x
    where x.client_account_id=pe.client_account_id
      and x.planning_engagement_id=pe.id)::bigint as instrument_run_count,
  (select count(*)
     from public.planning_content_diagnostic_syntheses x
    where x.client_account_id=pe.client_account_id
      and x.planning_engagement_id=pe.id)::bigint as synthesis_count,
  (select count(*)
     from public.pc_rm_working_hypothesis_current x
    where x.client_account_id=pe.client_account_id
      and x.planning_engagement_id=pe.id
      and x.current_state='active')::bigint as active_hypothesis_count,
  (select count(*)
     from public.pc_rm_working_hypothesis_current x
    where x.client_account_id=pe.client_account_id
      and x.planning_engagement_id=pe.id
      and x.current_state='accepted_for_planning')::bigint as accepted_hypothesis_count,
  (select count(*)
     from public.pc_rm_open_agenda_current x
    where x.client_account_id=pe.client_account_id
      and x.planning_engagement_id=pe.id)::bigint as open_agenda_count,
  (select count(*)
     from public.planning_content_diagnostic_sessions x
    where x.client_account_id=pe.client_account_id
      and x.planning_engagement_id=pe.id)::bigint as session_count,
  (select count(*)
     from public.planning_content_diagnostic_reports x
    where x.client_account_id=pe.client_account_id
      and x.planning_engagement_id=pe.id)::bigint as report_count,
  (select count(*)
     from public.pc_rm_report_current x
    where x.client_account_id=pe.client_account_id
      and x.planning_engagement_id=pe.id
      and x.current_state='validated')::bigint as current_validated_report_count,
  (select count(*)
     from public.planning_content_financial_plans x
    where x.client_account_id=pe.client_account_id
      and x.planning_engagement_id=pe.id)::bigint as plan_count,
  (select count(*)
     from public.planning_content_implementation_episodes x
    where x.client_account_id=pe.client_account_id
      and x.planning_engagement_id=pe.id)::bigint as implementation_count,
  (select count(*)
     from public.planning_content_review_episodes x
    where x.client_account_id=pe.client_account_id
      and x.planning_engagement_id=pe.id)::bigint as review_count
from public.planning_engagements pe
where public.is_staff(pe.client_account_id);

revoke all on table public.pc_rm_engagement_content_summary
from public,anon,authenticated,service_role;

grant select on table public.pc_rm_engagement_content_summary
to authenticated;
