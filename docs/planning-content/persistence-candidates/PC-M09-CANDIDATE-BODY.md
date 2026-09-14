# PC-M09 — Candidate Body

Status: NON-EXECUTABLE / DO NOT APPLY.

Objective: create read models/projections for planner operations and future PFP Cockpit without turning the dashboard into a persistence source.

Candidate planner/internal projections:
- case summary;
- current hypothesis state;
- current agenda;
- report status;
- current validated report;
- current plan;
- implementation/review view;
- planning-content timeline.

Projection rules:
- current WorkingHypothesis text comes from terminal durable version; lifecycle state comes from transition ledger;
- current agenda respects the one-OPEN invariant and canonical lifecycle;
- current validated report follows validated successor lineage on the same root, not naive `max(timestamp)`;
- current plan must follow explicit professional selection/root-version semantics, not naive `max(timestamp)`;
- PRI/RPM timeline uses occurrence roots + durable versions;
- client projections are separate, narrower contracts; raw Planning Content tables are not a client API.

Executable-design review must freeze whether each projection is a `security_invoker` view, a narrow function or another controlled projection form. No materialized projection should become an independent source of truth.

PC-M10 Provenance/Evidence is explicitly out of this migration sequence until the canonical physical dependency exists.
