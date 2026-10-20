# STAR-2 — Inventory OJB and the Lagrange tables/columns they use

## Ticket

- **Jira:** [STAR-2](https://pd-product-dev.atlassian.net/browse/STAR-2)
- **Work type:** Investigation and documentation; no application migration in scope
- **Repositories/systems inspected:** Power Platform, RB9/Lagrange, Callisto, `dustin-thomason`, and `pd-tech-wiki`
- **Documentation state:** The maintained technical artifacts now live in `pd-tech-wiki`; this file remains the STAR-2 work log and provenance trail.
- **Wiki PRs:** [Bootstrap #61](https://github.com/planetdepos/pd-tech-wiki/pull/61); [Jaimie architecture review #62](https://github.com/planetdepos/pd-tech-wiki/pull/62)
- **Maintained artifacts:** [Dependency inventory](https://github.com/planetdepos/pd-tech-wiki/blob/main/projects/atlas-workflows/power-platform-dependency-inventory.md), [current-state architecture](https://github.com/planetdepos/pd-tech-wiki/blob/main/projects/atlas-workflows/power-platform-current-state-architecture.md), and [RB9 rules](https://github.com/planetdepos/pd-tech-wiki/blob/main/projects/atlas-workflows/rb9-rules.md)
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
- The maintained [RB9 rules artifact](https://github.com/planetdepos/pd-tech-wiki/blob/main/projects/atlas-workflows/rb9-rules.md) captures reusable behavior and architectural obligations discovered by this ticket; the personal-repository copy is historical working material.

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
| 2026-10-20 | [STAR-2 Power Platform dependency inventory](https://github.com/planetdepos/pd-tech-wiki/blob/main/projects/atlas-workflows/power-platform-dependency-inventory.md) | active; nearing closure | Trace the complete OJB, ADB, and TCB technical paths, name every connected asset and environment, extract RB9/Lagrange usage, map it to Callisto, and de-duplicate the result. |
| 2026-10-20 | [STAR-2 current-state Power Platform architecture](https://github.com/planetdepos/pd-tech-wiki/blob/main/projects/atlas-workflows/power-platform-current-state-architecture.md) | active companion | Maintain the evidence-backed OJB, ADB, and TCB current-state paths and use them to complete the Lucid pages. |
| 2026-10-20 | [RB9 rules](https://github.com/planetdepos/pd-tech-wiki/blob/main/projects/atlas-workflows/rb9-rules.md) | active companion | Preserve reusable RB9 behavior, workaround obligations, and migration compatibility contracts in the shared wiki. |
| 2026-07-06 | [Power Platform to AWS investigation](../power-platform-aws-investigation/README.md) | prior research; revalidate | Use earlier OJB/ADB architecture, risks, and interview leads as evidence leads rather than current truth. |

---

## Session log

_Newest first._

### 2026-10-20 — Jaimie architecture review incorporated and wiki made source of record

- **Summary:** incorporated the relevant Jaimie review findings into the shared PD Tech Wiki and made those pages the maintained technical artifacts. The documented path now shows the Ops semantic model branching to ADB Lite and ADB Lite Live, with the current ADB and Job Suggestions paths reportedly using ADB Lite Live.
- **Pipeline detail:** recorded the hourly `VUL Ingest Job ADBLite` flow and a separate SB-originated on-demand ingestion path. ADB receives an intentionally limited selected-field payload and performs additional sorting in the app; the exact payload field list still requires an export or captured definition.
- **Shared blast radius:** recorded MyPD only as an adjacent consumer of shared assets, including `VUL  Job Suggestions`, the OJB list/interface, DCR Regions, and purpose-built SharePoint lists. This does not expand active STAR-2 discovery beyond OJB, ADB, and TCB.
- **Compatibility rule:** clarified that a SharePoint list is a Phase 1 compatibility boundary only when its schema/internal names, types, keys, grain, permissions, update behavior, cadence, freshness, and lineage are preserved—not merely its rows.
- **Closure assessment:** the bounded topology is nearing completion. STAR-2 should remain open until the exact selected columns (including the ADB payload), the de-duplicated Lagrange-to-Callisto mapping and missing flags, stable asset IDs/exports, reviewed Lucid pages, and the Jira/data-team handoff are linked or reconciled. If these already exist in the take-off material, the remaining work is evidence reconciliation rather than new discovery.
- **Maintained files:** [dependency inventory](https://github.com/planetdepos/pd-tech-wiki/blob/main/projects/atlas-workflows/power-platform-dependency-inventory.md), [current-state architecture](https://github.com/planetdepos/pd-tech-wiki/blob/main/projects/atlas-workflows/power-platform-current-state-architecture.md), and [RB9 rules](https://github.com/planetdepos/pd-tech-wiki/blob/main/projects/atlas-workflows/rb9-rules.md).
- **Wiki change:** [planetdepos/pd-tech-wiki#62](https://github.com/planetdepos/pd-tech-wiki/pull/62), merged as `5b402439c329e7608a8daa64053844c3cf6f9e30`.
- **Scope note:** unrelated meeting topics were intentionally omitted. No application, flow, list, semantic model, database, or production configuration changed.

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
25. The reviewed current path is RB9/Lagrange → Ops semantic model → ADB Lite/ADB Lite Live; ADB and Job Suggestions reportedly consume the Live branch.
26. Scheduled and on-demand refreshes are separate lineage edges even when they land in the same SharePoint-backed application surface.
27. A limited payload between a flow and Power App is a field-level contract; app-side sorting does not reveal which upstream columns were omitted.
28. A SharePoint projection is compatible only when schema, keys, grain, permissions, update behavior, cadence, freshness, and lineage remain equivalent.
29. Shared consumers such as MyPD should be recorded for blast radius without turning STAR-2 into tenant-wide or cross-department discovery.

## Current state (as of 2026-10-20)

- The maintained dependency inventory, current-state architecture, and RB9 rules now live in PD Tech Wiki; this personal-repository file remains the chronological STAR-2 work log.
- Active engineering scope remains OJB, ADB, and TCB, following each complete data path through semantic models, flows, connectors, SharePoint stores, and app surfaces.
- The current ADB/Job Suggestions lineage is documented as RB9/Lagrange → Ops semantic model → ADB Lite/ADB Lite Live, with both consumers reportedly using ADB Lite Live.
- The scheduled `VUL Ingest Job ADBLite` flow and separate SB-originated on-demand flow are documented, but stable IDs, exported definitions, exact queries, and the precise ADB payload fields remain open.
- Jobs Notes Log activity semantics and VQM compatibility behavior remain captured as OJB/RB9 migration contracts; unresolved field-level details stay explicitly marked.
- MyPD is recorded only as adjacent shared-component blast radius and does not expand the bounded STAR-2 inventory.
- The SharePoint boundary now includes schema, internal names, types, keys, grain, permissions, update behavior, cadence, freshness, and lineage—not row parity alone.
- The ticket is nearing technical completion, but closure still requires reconciliation of exact selected columns, the de-duplicated Lagrange-to-Callisto mapping and missing flags, stable asset evidence, reviewed Lucid pages, and the Jira/data-team handoff.
- Migration, replacement environment construction, and product lifecycle decisions remain out of scope.

## Attempt history

None yet.
