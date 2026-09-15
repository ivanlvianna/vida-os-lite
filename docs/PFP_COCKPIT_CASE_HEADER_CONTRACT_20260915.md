# VIDA OS™ — PFP Cockpit Case Header Contract — 2026-09-15

## Purpose

Define the canonical source and fallback rules for the PFP Cockpit case header. The header must represent the specific `planning_engagement` being opened; it must not depend on unrelated UI navigation state.

## Canonical anchor

The header is anchored by:

`planning_engagement_id`

From that engagement, resolve:

- `client_account_id`
- engagement `state`
- `opened_at`
- `closed_at`
- zero, one, or multiple participating `economic_entities`

The existing `CurrentPrincipal.activeClientAccountId` is navigation state only and must not be used as the case identity source.

## Display contract

### Primary case label

1. If the engagement has one participating EconomicEntity with a non-empty `display_name`, show that display name.
2. If the engagement has multiple participating EconomicEntities, show a deterministic participant summary; do not choose a “primary” participant by row order or timestamp unless a future canonical role explicitly identifies one.
3. If the engagement has no participating EconomicEntity, show a neutral fallback based on the `client_account_id` (for example `Conta c21d928b…`).

No synthetic client name may be inferred from e-mail, account position, membership order, or navigation state.

### Engagement state

Show the canonical `planning_engagement.state` separately from any content-health or completeness indicator.

Important distinction:

`engagement state != health/completeness`

A future executive-health indicator must remain a separate projection.

### Dates

Display:

- opened date/time
- closed date/time only when present

Do not derive closure merely from Planning Content counts.

### Responsible professional

Do not infer one responsible planner from arbitrary authorization ordering.

A responsible-professional label may be shown only when a canonical responsibility/ownership projection exists. Authorization role and operational responsibility remain distinct concepts.

## D3 fixture validation

Read-only D3 inspection for the canonical fixture engagement:

- `planning_engagement_id`: `69c0ec5f-976e-4e69-99b2-941a8f473739`
- `client_account_id`: `c21d928b-e627-41ff-97bf-d4dd331b00c2`
- current engagement state: `dados_incompletos`
- `closed_at`: null
- participating EconomicEntity rows: none

Therefore the fixture must currently use the neutral ClientAccount fallback in the header. This is expected data state, not an error.

## Application rule

Authorization is resolved first through the existing staff-only PFP Cockpit workflow/read boundary. Header enrichment must occur only for the already-authorized engagement/account pair.

Recommended application sequence:

1. load staff-authorized Planning Content snapshot;
2. take the returned `planning_engagement_id` + `client_account_id` as the case anchor;
3. load Product Core engagement metadata and participating entities for that exact pair;
4. build presentation-only header data;
5. never let header enrichment widen authorization.

## Not authorized here

This document does not authorize:

- new D3 tables/views/functions;
- changes to Product Core authorization;
- merge to `main`;
- production deployment;
- creation of a synthetic “primary client” concept.
