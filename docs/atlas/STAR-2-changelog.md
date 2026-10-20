# STAR-2 — Inventory OJB and the Lagrange tables/columns they use

## Ticket

- **Jira:** [STAR-2](https://pd-product-dev.atlassian.net/browse/STAR-2)
- **Work type:** Investigation and documentation; no application migration in scope
- **Repositories/systems inspected:** Power Platform, RB9/Lagrange, Callisto, `dustin-thomason`, and `pd-tech-wiki`
- **Branch:** Not cut; initial working artifacts are being recorded in `dustin-thomason`
- **PR:** Not opened
- **Artifacts:** [STAR-2/](STAR-2/)
- **Original ticket:** [STAR-2-original-ticket.md](STAR-2/STAR-2-original-ticket.md)

---

## Requirements (verbatim)

> As a member of the Starfleet team replacing RB9, I want a complete inventory of the Power Apps and the database tables and columns they depend on, so that we know exactly what data must be brought into Callisto for the read replica and can plan the Lagrange-to-Callisto migration without pulling unnecessary data.
>
> RB9 is being replaced; Callisto becomes the long-term source of truth and a Callisto read replica will replace direct RB9/Lagrange connections for reporting users and Power Apps.
>
> Power Apps currently read from RB9/Lagrange (Pascal-case names). Some were built by Dustin, some by Jamie, and some by LitTech, so no single complete list exists.
>
> Users should only have to retool once, so all required data must be in Callisto before cutover.
>
> **Inventory of Power Apps**
>
> Identify every Power App that reads from RB9 or Lagrange, including those built by LitTech.
>
> For each app record: name, owner/builder, business purpose and users, and data source(s) and connection type.
>
> **Inventory of tables and columns in use**
>
> For each Power App, list every table and column it uses (read and write) in RB9/Lagrange.
>
> Note whether each table/column already exists in Callisto, and the Callisto equivalent where it does.
>
> Consolidate into a single de-duplicated list of tables and columns.
>
> **Acceptance Criteria**
>
> A documented list of all known Power Apps with owner, purpose, and data source.
>
> Each Power App is mapped to the tables and columns it uses.
>
> A consolidated table/column inventory exists, with an old (Lagrange) to new (Callisto) mapping and a flag for items not yet in Callisto.
>
> Gaps and unknowns (e.g. apps with no identified owner) are listed explicitly.
>
> The inventory is stored in Confluence (or linked from this ticket) and shared with Megna so she can plan the Lagrange-to-Callisto data work.
>
> **Dependencies:** RB9/Lagrange database access, and input from Dustin and Jamie, who know where the Power Apps live.
>
> **Out of scope:** migrating the Power Apps or moving data into Callisto.

---

## Context

- The shared wiki's Atlas Workflows kickoff names Dustin as the Power Platform track lead, supported by Erik and Megna.
- The kickoff specifically asks Dustin, Megna, and Larry to compare OJB tables and fields with Lagrange, including existing views, and identify gaps.
- The kickoff also asks Megna, Dustin, and Erik to review whether Power BI datasets use views or direct queries.
- Dustin and Larry are named to find the existing OJB/ADB field-mapping spreadsheet.
- Earlier `docs/power-platform-aws-investigation/` artifacts contain useful ADB/OJB leads from June and July 2026, but they predate STAR-2 and must be revalidated.
- The shared wiki contains a material conflict: an older system map says Power Apps point directly at RB9; the newer kickoff says app access is mediated through Power Automate and Power BI. STAR-2 must resolve the live state from connection references and definitions.
- The long-lived companion [RB9 rules artifact](../rb9/rb9-rules.md) captures reusable behavior and architectural obligations discovered by this ticket.

## What is explicitly expected from Dustin

### From STAR-2

- [ ] Identify every Power App that reads RB9 or Lagrange, including LitTech-built apps.
- [ ] Record name, owner/builder, business purpose, users, data sources, and connection type for each.
- [ ] Record every RB9/Lagrange table and column each app reads or writes.
- [ ] Map each used object to its Callisto equivalent and flag missing objects.
- [ ] Produce a de-duplicated table/column inventory.
- [ ] List gaps and unknowns explicitly.
- [ ] Link the inventory from Jira/Confluence and share it with Megna.
- [ ] Keep migration and data movement out of this ticket.

### From the Atlas Workflows kickoff

- [ ] Lead the Power Platform track, with Erik and Megna supporting.
- [ ] Start with OJB and the other Power Platform consumers.
- [ ] Compare OJB fields with current Lagrange tables/views and identify gaps with Megna and Larry.
- [ ] Help review how Power BI datasets are built with Megna and Erik.
- [ ] Help locate the existing OJB/ADB field-mapping spreadsheet with Larry.
- [ ] Feed the discovered requirements to Megna's Lagrange-to-Callisto planning.

### Practical implication

Dustin is acting as the engineer documenting technical reality. The deliverable is the verified dependency and gap inventory, plus enough provenance that the data and migration teams can trust it. He is not expected to decide stakeholder relevance, application value, lifecycle, or product scope, and he is not migrating the apps in STAR-2.

### Engineering working boundary

- OJB, ADB, and TCB are the systems actively being inventoried.
- Scope follows their complete data paths, not the Power App boundary. Database objects, views/queries, gateways, connections, Power BI/Power Query assets, Power Automate flows, SharePoint stores, and app connections are all first-class inventory items.
- Each component must be named, assigned to its actual environment, and marked as existing, reported/unverified, missing/not created, inaccessible, or historical.
- Shared components may identify other consumers to show blast radius, but they do not trigger tenant-wide discovery of unrelated apps.
- Lucid must contain a separate current-state page for OJB, ADB, and TCB, using environment/platform swimlanes and visible missing-component states.
- Product decisions and building or testing replacement environments remain separate work.

---

## Plans

| Added | Plan (path or link) | Status | One-line approach |
| --- | --- | --- | --- |
| 2026-10-20 | [STAR-2 Power Platform dependency inventory](STAR-2/STAR-2-power-platform-dependency-inventory.md) | active | Trace the complete OJB, ADB, and TCB technical paths, name every connected asset and environment, extract RB9/Lagrange usage, map it to Callisto, and de-duplicate the result. |
| 2026-10-20 | [STAR-2 current-state Power Platform architecture](STAR-2/STAR-2-power-platform-current-state-architecture.md) | active companion | Produce one environment-aware Lucid page for OJB, ADB, and TCB and reconcile every database, gateway, query, flow, store, and application edge with evidence. |
| 2026-10-20 | [RB9 rules](../rb9/rb9-rules.md) | active companion | Capture reusable RB9 behavior and workaround obligations discovered during STAR-2 before promoting stable facts to the shared wiki. |
| 2026-07-06 | [Power Platform to AWS investigation](../power-platform-aws-investigation/README.md) | prior research; revalidate | Use earlier OJB/ADB architecture, risks, and interview leads as evidence leads rather than current truth. |

---

## Session log

_Newest first._

### 2026-10-20 — Engineering scope and Lucid deliverables tightened

- **Summary:** bounded active STAR-2 engineering work to OJB, ADB, and TCB while expanding each system boundary to include every technical component that feeds it. Removed tenant-wide Power App discovery from the working definition of complete. Added explicit environment/existence-state capture and a separate Lucid current-state page for each system.
- **Engineering boundary:** document system behavior, asset names, environments, data movement, tables/columns, and technical gaps. Stakeholder relevance, product scope, lifecycle choices, prioritization, migration implementation, and environment construction are not STAR-2 engineering decisions.
- **Files:**
  - docs/atlas/STAR-2/STAR-2-power-platform-dependency-inventory.md
  - docs/atlas/STAR-2/STAR-2-power-platform-current-state-architecture.md
  - docs/atlas/STAR-2-changelog.md
- **Notes:** Connected assets include queries/views, gateways, data sources, connectors, connection references, Power BI/Power Query assets, Power Automate flows/actions, SharePoint stores, and app connections. Shared consumers are recorded only when needed to describe reuse or blast radius.

### 2026-10-20T07:24:00Z — Job Completion, Job Suggestions, and ADB pipeline discovery

- **Summary:** created a current-state Power Platform architecture companion and mapped three distinct paths: the dormant Job Completion/Daily Jobs path, the reported-current `VUL  Job Suggestions`/TCB path, and the reported-current ADB path. Recorded that Job Suggestions and ADB reportedly use the same Power BI dataset/methodology and only the Jobs and JobsTasks families, while base versus VQM objects remains unresolved. Kept Daily Jobs and VUL separate, recorded the December 2025 staleness and missing alert/escalation, and treated rewiring as a future design rather than current state.
- **Evidence:** Dustin SME notes; shared kickoff; Lagrange code; Jaimie Shareplane docs confirming the distinct `VUL  Job Suggestions` title. The C3/RB9 Replacement Power Platform Lucid diagram was named but not inspected because no local export/cache was available.
- **Files:**
  - docs/atlas/STAR-2/STAR-2-power-platform-current-state-architecture.md
  - docs/atlas/STAR-2/STAR-2-power-platform-dependency-inventory.md
  - docs/rb9/rb9-rules.md
  - docs/atlas/STAR-2-changelog.md
- **Commit:** this documentation commit.
- **Notes:** Asset ids, Power BI dataset name, flow names, exact last refresh, MyPD identity, LitTech consumer, and Jobs versus VQM selection remain intentionally unverified. No app, flow, list, dataset, database, or production configuration changed.

### 2026-10-20T07:14:13Z — Power Platform query-surface ownership discovery

- **Summary:** captured why VQM surfaces were operationally necessary for legacy Power Apps: the implemented path could sort by date but could not safely perform the required filtering and cross-table lookups, so server-side objects supplied the usable shape. Recorded that direct RB9 Power App access was reportedly removed for permissions and that current RB9 touchpoints are Power Automate and Power BI. Separated technical connector availability from approved architecture, corrected RB9/MySQL terminology to an explicit evidence conflict, and added a blocking per-consumer decision over whether Callisto SQL, a semantic model, Power Automate/API, or another layer owns the rebuilt query.
- **Evidence:** Dustin SME report; Atlas Workflows kickoff; `lagrange-back-end` README/code; current Microsoft Power Apps delegation, PostgreSQL connector, and Power Query PostgreSQL documentation.
- **Files:**
  - docs/rb9/rb9-rules.md
  - docs/atlas/STAR-2/STAR-2-power-platform-dependency-inventory.md
  - docs/atlas/STAR-2-changelog.md
- **Commit:** this documentation commit.
- **Notes:** Microsoft currently documents a PostgreSQL connector, so inability to create any connection is not assumed. Direct access approval, exact delegation behavior, legacy connector type, Callisto surfaces, and query ownership remain intentionally undecided. No production configuration changed.

### 2026-10-20T07:07:47Z — VQM relationship and compatibility-rule discovery

- **Summary:** documented the third RB9 oddity: `VQM_*` query surfaces hide lookup and relationship logic behind consumer-friendly columns, creating migration risk when labels replace keys or a future model assumes one-to-one cardinality. Confirmed from `lagrange-back-end` that `VQM_Jobs` and `VQM_JobsTasks` already exist as ordinary PostgreSQL views. The reviewed task view remains one row per `TaskNo`, resolves task/resource labels through joins, omits raw `Task`/`RsrcNo`, and does not contain SQL aggregation. Added the two views as ADB dependency leads and preserved live RB9/consumer parity as an open validation item.
- **Plan used:** active STAR-2 dependency inventory plus the RB9 Rules companion artifact.
- **Files:**
  - docs/rb9/rb9-rules.md
  - docs/atlas/STAR-2/STAR-2-power-platform-dependency-inventory.md
  - docs/atlas/STAR-2-changelog.md
- **Commit:** this documentation commit.
- **Notes:** Historical notes saying `VQM jobs tests` were not rewritten; the inventory marks that phrase as a likely transcription error for `VQM_JobsTasks`. No live database, application, flow, semantic model, or production configuration changed.

### 2026-10-20T07:02:20Z — RB9/OJB activity-rule discovery

- **Summary:** documented the second concrete RB9 oddity: OJB repurposes selected Jobs Notes Log categories and metadata as an operational activity ledger because RB9 lacks a flexible structured task/activity mechanism. Split the finding into activity vocabulary, actor/time semantics, multi-million-row scale, and last-modified incremental behavior. Added Jobs Notes Log as a concrete STAR-2 dependency lead and expanded the discovery gaps.
- **Plan used:** active STAR-2 dependency inventory plus the RB9 Rules companion artifact.
- **Files:**
  - docs/rb9/rb9-rules.md
  - docs/atlas/STAR-2/STAR-2-power-platform-dependency-inventory.md
  - docs/atlas/STAR-2-changelog.md
- **Commit:** this documentation commit.
- **Notes:** The exact table/columns, category list, actor/completion semantics, and row count remain intentionally unverified. No application, flow, database, or production configuration changed.

### 2026-10-20T06:48:37Z — dustin-thomason documentation bootstrap

- **Summary:** established the STAR-2 working set and the separate RB9 Rules artifact. Preserved the Jira ticket verbatim, translated its acceptance criteria into a working inventory and evidence structure, identified Dustin's explicit responsibilities from the shared wiki, and seeded known app/dependency leads without marking them verified.
- **Plan used:** initial documentation bootstrap based on the ticket, the Atlas Workflows kickoff, and the existing Power Platform to AWS investigation.
- **Files:**
  - `docs/rb9/README.md`
  - `docs/rb9/rb9-rules.md`
  - `docs/atlas/STAR-2-changelog.md`
  - `docs/atlas/STAR-2/STAR-2-original-ticket.md`
  - `docs/atlas/STAR-2/STAR-2-power-platform-dependency-inventory.md`
- **Commit:** this documentation bootstrap commit.
- **Notes:** No Power Platform, database, or application configuration was changed.

---

## Key technical learnings

1. The visible Power App is not necessarily the layer that queries RB9/Lagrange; flows, semantic models, gateways, and connection references are first-class inventory items.
2. Existing sources disagree about direct RB9 connectivity, so live configuration must decide the current-state architecture.
3. OJB and ADB have prior recovery documentation, but its July 2026 state cannot be treated as current without verification.
4. A successful connection is insufficient. STAR-2 must prove field completeness and semantic equivalence in Callisto before a one-time consumer cutover.
5. Writes and manual overrides may target SharePoint or another operational store even when reads originate in RB9; both directions must be recorded.
6. OJB uses the Jobs Notes Log as an activity ledger: selected categories stand in for operational task types and metadata supplies who/when metrics.
7. Last-modified and modifying-user fields cannot be assumed to mean completed-at and performed-by until edit and automation behavior is verified.
8. The Jobs Notes Log is multi-million-row scale, but exact size and query/index behavior still require measurement.
9. Lagrange already implements `VQM_Jobs` and `VQM_JobsTasks` as ordinary PostgreSQL views; production RB9 parity remains unproven.
10. The reviewed `VQM_JobsTasks` view is lookup-enriched, not SQL-aggregated: it keeps one row per `TaskNo` but replaces raw `Task`/`RsrcNo` with derived labels.
11. View output grain, hidden join paths, omitted keys, null behavior, and mutable labels are migration contracts even when the view looks like a convenient flat table.
12. Callisto should preserve normalized Job → Job Task → Resource relationships and provide compatibility projections only for verified consumer needs.
13. Direct RB9 Power App connections were reportedly removed for permissions; inventory must follow Power Automate and Power BI rather than stop at the app.
14. The legacy constraint was specific to the implemented connector/formulas and delegation behavior; it should not be generalized into “Power Apps cannot filter SQL.”
15. Current artifacts identify RB9 as MSSQL and Lagrange as PostgreSQL; the recalled MySQL source is an evidence conflict to resolve from connection references.
16. PostgreSQL connector availability does not decide the target. Each consumer needs an owned query surface, approved access path, and parity test.
17. Power BI → Power Automate → SharePoint is a materialized application data product; dataset, flow, list, freshness, and owner are all part of the dependency.
18. Daily Jobs List Reference and `VUL  Job Suggestions` are similar but distinct projections and must not be collapsed without schema/consumer proof.
19. A reachable app/list can be silently stale: Daily Jobs reportedly stopped in Dec 2025 without alert or escalation.
20. Two logical RB-query uses can share one dataset; count apps, pipelines, queries, datasets, and physical database connections separately.
21. The source scope is narrowed to Jobs and JobsTasks families for the reported Job Suggestions/ADB pattern, but base versus VQM and exact columns remain open.
22. OJB, ADB, and TCB—not the entire Power Platform tenant—are the active engineering boundary.
23. The inventory follows complete data paths, so gateways, connections, queries, flows, semantic models, and SharePoint stores are deliverables even when they are not Power Apps.
24. Environment placement and existence state are required diagram facts; deciding whether a missing component should be built is separate work.

## Current state (as of 2026-10-20)

- Ticket requirements are captured verbatim.
- The working inventory structure exists.
- Known candidate apps and OJB flow names are seeded as unverified leads.
- Jobs Notes Log is recorded as a reported-current OJB dependency lead; its category vocabulary, columns, actor/time semantics, and measured scale remain open.
- `VQM_Jobs` and `VQM_JobsTasks` definitions are confirmed in Lagrange code and recorded as historical ADB dependency leads; deployed/live RB9 parity and actual consumer-selected columns remain open.
- A blocking target query-surface decision is now recorded for ADB, TCB, OJB, and other consumers; no layer or owner has yet been approved.
- Shared kickoff evidence says direct RB9 Power App connections were removed for permissions, but live connection references and the exact former connector still need export.
- A current-state architecture companion now records the reported Job Completion, Job Suggestions/TCB, MyPD/Jaimie, LitTech supervisor, and ADB wiring, with unknowns explicit.
- Daily Jobs List Reference is reported stale since Dec 2025 and is not wired to `VUL  Job Suggestions`; Job Completion lifecycle remains undecided.
- The C3/RB9 Replacement Power Platform Lucid diagram is registered as evidence but has not yet been exported or reconciled.
- No live tenant export, app source, flow definition, Power BI metadata, deployed-database result, or Callisto mapping has yet been recorded in the STAR-2 artifact; current VQM evidence is repository definition code only.
- No claim of inventory completeness has been made.
- Migration remains out of scope.

## Attempt history

None yet.
