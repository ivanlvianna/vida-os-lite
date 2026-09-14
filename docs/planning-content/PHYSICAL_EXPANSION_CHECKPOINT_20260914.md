# VIDA OS™ — Planning Content Physical Expansion Checkpoint — 2026-09-14

## Gate

`PLANNING-CONTENT-PERSISTENCE-GATE-001 = OPEN / CANDIDATE GENERATION ONLY`

No Planning Content migration has been created under `supabase/migrations/`, applied to D3, applied to production, or merged to `main`.

## Expansion status

The architectural DDL has now been expanded off-branch into explicit pre-migration candidates for PC-M01…PC-M09. This was used as a static design proof before handing the work to a Supabase CLI-enabled executor.

Current explicit physical inventory for PC-M02…PC-M06:

- PC-M02 Roots: 10 tables;
- PC-M03 Durable Versions: 10 tables;
- PC-M04 Typed Children/References: 11 tables;
- PC-M05 WorkingDraft + draft-child structures: 14 tables;
- PC-M06 Lifecycle/Workflow ledgers: 4 tables;
- total PC-M02…PC-M06: **49 tables**.

Static mechanical checks on the expanded candidate:

- 49/49 tables have same-block `ENABLE ROW LEVEL SECURITY`;
- 49/49 tables have same-block `REVOKE ALL ... FROM PUBLIC, anon, authenticated, service_role`;
- every referenced Planning Content table is created earlier in the dependency sequence or is an existing verified D3 dependency;
- no explicit constraint name exceeds PostgreSQL's 63-byte identifier limit;
- no duplicate explicit constraint name was found;
- immutable roots, versions, child/reference rows and lifecycle ledgers have candidate mutation-guard triggers;
- drafts remain the only intentionally mutable Planning Content persistence structures.

## Technical corrections frozen after expansion

1. `ReviewEpisodeVersion` must store both `implementation_episode_id` and exact `implementation_episode_version_id`.
2. Version predecessor chain uses same-account/same-engagement/same-root composite self-FK.
3. Lifecycle ledgers use aggregate-local deterministic sequence numbers (`transition_no`, `event_no`, `manifestation_no`); timestamps are not the canonical ordering mechanism.
4. WorkingHypothesis proposal origin carries account/engagement context for physical same-engagement enforcement.
5. PCP source `instrument_code` is physically tied to the referenced InstrumentRun root as well as the exact run version.
6. Draft `base_version_id` references an exact version of the same root/engagement.
7. Historical immutability permits only narrowly defined auth-user-id nullification required by `ON DELETE SET NULL`; semantic history remains immutable.
8. `planning_engagement_entities` receives a supporting unique triple `(client_account_id, planning_engagement_id, economic_entity_id)` before report consensus-subject FKs.
9. v1 uses CHECK constraints rather than new PostgreSQL ENUM types.

## Authorization freeze

Professional Planning Content commands require current account-scope `planner_owner` or `internal_staff`; when both exist, `planner_owner` has precedence, matching current D3 behavior.

`record_report_consensus` is the only v1 client-write exception. Client self-service requires current membership plus engagement-specific and entity-specific authorization for the frozen consensus subject. Actor identity and manifestation subject remain distinct.

## PC-M07 signature direction

RPC signatures are frozen by domain family. Simple collections use typed PostgreSQL arrays. Complex bounded child collections may use domain-specific JSON command transport, validated strictly and normalized immediately into typed tables. No generic `write_planning_content(jsonb)` endpoint exists.

## Test plan reconciliation

The physical test plan has been advanced to candidate v0.4 with explicit tests for:

- same-root predecessor composite FK;
- source `instrument_code` consistency;
- lifecycle deterministic sequence numbers;
- exact ImplementationEpisodeVersion target from ReviewEpisodeVersion;
- consensus-subject same-engagement FK;
- WorkingHypothesis proposal-origin same-engagement FK;
- prohibition on inferring an engagement-level primary FinancialPlan from timestamps or arbitrary root ordering.

## Presentation-layer caveat found

Multiple FinancialPlan roots are permitted in one PlanningEngagement. The persistence model currently has no canonical event/command that designates one of those roots as the engagement-level **primary/current plan**.

Therefore the v1 read model may safely expose the terminal version **per plan root**, but must not infer a single primary plan using `max(created_at)`, last update, or arbitrary ordering. An engagement-level primary-plan selection contract, if desired, is a later governed decision.

The same caution applies to collapsing multiple independent DiagnosticReport roots into a single engagement-level report.

## Remaining path before any D3 apply

1. Supabase CLI-enabled worktree checks out `planning-content-persistence-2026-09-14`.
2. Record `supabase --version` / help and close the toolchain gate.
3. Create official PC-M01…PC-M09 filenames with `supabase migration new`.
4. Transfer/reconcile the expanded candidate bodies into those files.
5. Run static checks and local/sandbox DB validation.
6. Run real multi-session concurrency harness.
7. Run rollback/replay/zero-residue proof.
8. Review advisors/security findings.
9. Only then request a separate authorization to apply to `vida-os-homologacao`.

No step in this checkpoint authorizes apply.
