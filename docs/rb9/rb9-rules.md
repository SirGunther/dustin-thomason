# RB9 Rules — How Planet Depos Uses the System

Status: Seeded working artifact; requires validation  
Owner: Dustin Thomason  
Started: 2026-10-20  
Last reviewed: 2026-10-20

## Purpose

This document captures the rules, workarounds, conventions, and oddities that have grown around RB9 at Planet Depos. “Rule” here does not always mean an RB9 product rule. It may be:

- a vendor or hosting constraint;
- a Planet Depos business rule implemented through RB9;
- an operational convention people rely on;
- a workaround implemented in Power Apps, Power Automate, Power BI, SharePoint, or another system;
- a data-shape or migration constraint future Atlas and Callisto architecture must preserve or deliberately retire.

The architectural goal is not to reproduce every workaround. It is to understand the outcome each workaround protects before replacing it.

## System frame

- **OMTI** is the vendor/host associated with RB9.
- **ReporterBase 9 (RB9)** is the operational system of record for core job, case, scheduling, billing, and related administrative data.
- **Lagrange** replicates RB9-shaped data for internal use.
- **Callisto** is the intended long-term internal source for the data needed by Power Platform consumers under Jira STAR-2.
- **Power Platform consumers** may include Power Apps, Power Automate flows, Power BI semantic models/reports, gateways, connections, and SharePoint lists. The full live dependency chain must be verified rather than inferred from an app's display name.

## Evidence vocabulary

| Status | Meaning |
| --- | --- |
| Confirmed | Verified in a primary source, live configuration, schema, query, or current owner validation. |
| Reported | Stated in a meeting, ticket, or prior note but not yet independently verified. |
| Conflicting | Current sources disagree; do not build against either version without resolving it. |
| Hypothesis | Plausible interpretation that still needs evidence. |
| Retired | Previously true but deliberately no longer part of current behavior. |

## Seed rule register

These entries are starting leads, not a claim that discovery is complete.

| ID | Area | Rule, oddity, or workaround | Why it matters to future architecture | Status | Source / next proof |
| --- | --- | --- | --- | --- | --- |
| RB9-R-001 | Query execution | OMTI has been reported to enforce a non-negotiable 60-second query execution limit. Earlier OJB recovery work used 45 seconds as a pre-production target and 55 seconds as a production stop threshold. | Replacement queries, views, APIs, and backfills need explicit latency and load budgets. Do not copy an emergency threshold into permanent architecture without confirming the actual vendor constraint. | Reported | `docs/power-platform-aws-investigation/decision-memo.md`; obtain a current OMTI constraint statement. |
| RB9-R-002 | Time | Naive timestamp columns replicated from RB9 represent America/New_York wall time rather than UTC. | Callisto mappings, incremental cutoffs, reports, and APIs must not silently reinterpret these values as UTC. | Confirmed in shared wiki | `pd-tech-wiki/standards/data/rb9-replicated-timestamps.md`; verify each selected STAR-2 field against the live schema. |
| RB9-R-003 | Naming and schema | Lagrange preserves RB9-style PascalCase names while Callisto uses renamed columns and relationships. A consumer cannot be repointed by connection change alone. | Every used table and column needs an explicit old-to-new mapping, including nullability, keys, semantics, and transformations. | Reported; mapping required by STAR-2 | `pd-tech-wiki/projects/atlas-workflows/kickoff.md`; live Lagrange and Callisto schemas. |
| RB9-R-004 | Power Platform access | Sources conflict on whether Power Apps connect directly to RB9. July documentation describes direct RB9 coupling; the October Atlas Workflows kickoff says direct app connections were removed and RB9 data reaches apps only through Power Automate and Power BI. | The migration unit is the real connection/query layer, not necessarily the visible app. Live connection references and flow/dataset definitions must settle this. | Conflicting | Compare live Power Platform admin inventory and source exports with both documents. |
| RB9-R-005 | Read and write direction | Do not assume every RB9-dependent app is read-only or that every write returns to RB9. Record reads and writes separately, including writes to SharePoint or other operational stores. | Future architecture must preserve authoritative writes, temporary overrides, reconciliation, and audit behavior—not merely supply query results. | Required discovery rule | STAR-2 requirements; verify formulas, flows, datasets, and connection references per app. |
| RB9-R-006 | Cutover sequencing | Users should retool only once; required Callisto data must exist before a Power Platform consumer is cut over. | “Connection works” is not a cutover gate. Completeness, mapping, validation, and user sign-off are prerequisites. | Confirmed requirement | Jira STAR-2. |
| RB9-R-007 | OJB synchronization | Earlier OJB notes describe a high-water mark / changed-ID pattern followed by small updates of approximately 15–20 items. Reconnecting from an old high-water mark risked a large historical catch-up. | A replacement needs an explicit incremental-sync contract, replay/backfill policy, idempotency, and observable cursor ownership. | Reported; current state unknown | `docs/power-platform-aws-investigation/architecture-map.md` and `decision-memo.md`; inspect each live OJB flow. |
| RB9-R-008 | OJB working state | Earlier OJB documentation describes Power Automate reading RB9 and materializing operational state into working and archive SharePoint lists. | The SharePoint lists may be projections or workflow state rather than sources of truth. Their retention, reconciliation, indexes, and failure behavior must be documented before replacement. | Reported; current state unknown | Live OJB flows and SharePoint list schemas; identify owners and validators. |
| RB9-R-009 | ADB overrides | Earlier ADB recovery work describes Power BI data as a base state with manual SharePoint overrides taking precedence until reconciliation. | The architectural requirement is immediate, visible user correction with provenance and deterministic reconciliation—not necessarily continued use of SharePoint. | Reported; current state unknown | `docs/power-platform-aws-investigation/decision-memo.md`; inspect ADB formulas, semantic model, and override list. |
| RB9-R-010 | Connection path | Gateway, connector, connection reference, semantic model, and flow ownership are part of the dependency, not deployment trivia. | A future data service can be correct while the app still fails because of gateway reachability, connector limits, licensing, ownership, or stale shared connections. | Confirmed as inventory requirement | STAR-2 plus live Power Platform and gateway configuration. |
| RB9-R-011 | Scope and ownership | No single complete Power App list exists; apps were built by Dustin, Jamie, and LitTech, and ownership may differ from current maintenance responsibility. | Discovery must search the tenant and interview builders/owners. “Known to Dustin” is not a completeness boundary. | Confirmed requirement | Jira STAR-2. |

## Rule entry template

Add one entry per independently testable behavior. If a note contains two separate failure modes or architectural obligations, split it.

### RB9-R-XXX — Short name

- **Statement:** What is true today?
- **Type:** Vendor constraint | business rule | operating convention | workaround | data rule | integration rule.
- **Scope:** Which department, RB9 module, app, flow, table, or time period does it apply to?
- **Status:** Confirmed | Reported | Conflicting | Hypothesis | Retired.
- **Evidence:** Query, export, screenshot, ticket, meeting, named communicator, or source document.
- **Last verified:** ISO date and how it was verified.
- **Consumers:** Systems and people relying on it.
- **Failure mode:** What breaks or becomes misleading if it is missed?
- **Future architecture obligation:** Preserve the outcome, replace it deliberately, or retire it with approval.
- **Open questions / owner:** Who can settle what remains unknown?

## Conflicts to resolve first

1. **Direct RB9 connections versus mediated access.** The July system map and October kickoff disagree.
2. **Complete app universe.** The October kickoff list differs from the June/July notes and explicitly says more apps may exist.
3. **Target data source.** Older work studied Lagrange/AWS as a fallback; STAR-2 says Callisto and a Callisto read replica are the long-term target.
4. **OJB recovery state.** July recovery notes may describe a historical outage plan rather than the current production design.
5. **Write behavior.** Reads from RB9/Lagrange, writes to SharePoint, manual overrides, and any RB9-side writes must be separated.

## Future-architecture obligations emerging from the seed rules

- Preserve field meaning, keys, null behavior, and Eastern-time semantics during schema translation.
- Provide stable, bounded query surfaces rather than allowing each app to recreate broad RB9 queries.
- Treat incremental cursors, backfill, reconciliation, and drift detection as explicit product behavior.
- Keep ownership and monitoring independent of a single maker account.
- Model manual overrides as first-class, attributable state with an expiry or reconciliation rule.
- Validate behavior with business owners, not only row counts and connector success.
- Keep RB9-specific names at a boundary so consumers do not need a second wholesale retool when RB9 is retired.

## Source trail

- Jira STAR-2, supplied by Dustin Thomason on 2026-10-20.
- `pd-tech-wiki/catalog/systems-map.md`, reviewed 2026-10-20.
- `pd-tech-wiki/projects/atlas-workflows/kickoff.md`, kickoff dated 2026-10-14.
- `pd-tech-wiki/standards/data/rb9-replicated-timestamps.md`.
- `docs/power-platform-aws-investigation/`, prepared 2026-07-06 from internal notes and vendor documentation.

When a rule becomes stable cross-system knowledge, promote it to `pd-tech-wiki` with provenance and leave a link here. Do not maintain competing canonical versions.
