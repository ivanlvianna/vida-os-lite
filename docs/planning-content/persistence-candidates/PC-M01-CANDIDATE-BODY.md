# PC-M01 — Candidate Body

Status: NON-EXECUTABLE / DO NOT APPLY.

Objective: foundations, actor/authorship support, same-engagement guards and internal helper contracts required by later Planning Content migrations.

D3-verified dependencies:
- `public.client_account_users(client_account_id, auth_user_id)`;
- `public.planning_engagements` has `UNIQUE (client_account_id, id)`;
- `public.planning_engagement_entities` currently lacks a redundant `(client_account_id, planning_engagement_id, economic_entity_id)` unique key;
- existing helpers: `is_staff`, `has_engagement_specific_role`, `has_entity_specific_role`, `has_role_in_scope`, `auth_user_display_label`, `matched_staff_role`.

Candidate content:
- optionally add a redundant unique constraint to `planning_engagement_entities` only if the final report-consensus FK design requires it;
- create internal `pc_assert_staff_context(...)` helper;
- create internal `pc_resolve_actor_stamp(...)` helper;
- create internal same-engagement, terminal-version, draft-revision and lifecycle transition guards;
- helpers must not receive broad application EXECUTE grants;
- any `SECURITY DEFINER` helper must use `SET search_path = ''`, derive actor identity server-side and fail closed.

Unresolved by this packet: ENUM vs CHECK representation. Prefer CHECK semantics unless executable-design review freezes another choice.
