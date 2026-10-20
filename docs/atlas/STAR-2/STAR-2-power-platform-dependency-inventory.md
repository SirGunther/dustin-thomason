# STAR-2 — Power Platform and RB9/Lagrange Dependency Inventory

Status: Discovery scaffold; not complete  
Owner: Dustin Thomason  
Started: 2026-10-20  
Last updated: 2026-10-20  
Jira: [STAR-2](https://pd-product-dev.atlassian.net/browse/STAR-2)

## Outcome

Produce a verified engineering dependency inventory for OJB, ADB, and TCB. The inventory covers the complete technical paths that feed those systems—not only the visible Power Apps—including database objects, views and queries, gateways, connections, semantic models, Power Query logic, Power Automate flows, SharePoint stores, and application connections.

For each path, name every technical asset, record the environment in which it exists, show how data moves between assets, and map the RB9/Lagrange fields to Callisto or an explicit technical gap.

This document is the working evidence artifact. It distinguishes live evidence from historical leads. An empty mapping cell means unknown—not absent.

## Definition of complete

- [ ] OJB, ADB, and TCB each have a bounded end-to-end technical dependency record.
- [ ] Every component on those paths is named and typed, with a stable id or location where available.
- [ ] Each component's environment and observed existence state are recorded: existing, reported/unverified, missing/not created, inaccessible, or historical.
- [ ] Every path is traced through its actual source objects, views/queries, gateways, connections, semantic models or Power Query, flows, intermediate stores, and app connections.
- [ ] Every RB9/Lagrange table and column read or written by those paths is recorded.
- [ ] Each old object has a verified Callisto equivalent or an explicit missing, partial, or unknown flag.
- [ ] A de-duplicated object list is produced.
- [ ] One Lucid current-state page exists for each of OJB, ADB, and TCB, with environment boundaries and missing components visible.
- [ ] Technical conflicts, inaccessible assets, and unknowns are explicit.
- [ ] Ticket metadata such as owner/builder, purpose, and users is recorded from available evidence or marked unknown; resolving those business fields is not an engineering scope decision.
- [ ] The inventory is linked from Jira or Confluence and supplied to the data team for Lagrange-to-Callisto planning.

## Evidence levels

| Level | Meaning |
| --- | --- |
| Verified-live | Observed in the current tenant, exported source, flow definition, query, schema, or owner-confirmed screen share. |
| Verified-schema | Confirmed in current Lagrange or Callisto schema/code but not yet tied to a live app reference. |
| Reported-current | Current owner/team states it is true; primary technical evidence still needed. |
| Historical-lead | Prior note or document that may no longer reflect production. |
| Unknown | No reliable evidence yet. |

## Discovery method

1. **Bound the three systems**
   - Treat OJB, ADB, and TCB as the systems in scope.
   - Include every asset that feeds, transforms, stores, or exposes their data.
   - Do not expand this work into a tenant-wide search for unrelated applications.
2. **Trace every technical path**
   - Follow each path from RB9/Lagrange through any view or query, gateway, connection, semantic model or Power Query, Power Automate flow, SharePoint store, and application connection.
   - Record asset names, stable ids, environments, direction, query/connection mode, trigger or refresh behavior, and read/write behavior without copying secrets.
3. **Record environment and existence**
   - Identify the Power Platform environment, Power BI workspace, gateway/data-source location, SharePoint site, and database environment for each asset.
   - Mark each expected component as existing, reported/unverified, missing/not created, inaccessible, or historical.
4. **Extract data usage**
   - Capture source query text or formula evidence.
   - Expand views and stored procedures when needed to identify underlying objects.
   - Separate reads, writes, filters, joins, sort keys, high-water marks, and override/reconciliation fields.
5. **Map to Callisto and diagram**
   - Verify names, keys, types, nullability, semantics, relationships, and timestamp behavior.
   - Mark absent and semantically different objects explicitly.
   - Produce one environment-aware Lucid page for OJB, ADB, and TCB.
6. **Consolidate the engineering handoff**
   - De-duplicate the used objects and link supporting exports or sanitized evidence.
   - Record technical unknowns without turning them into product, stakeholder, or lifecycle decisions.

## System and connected-asset inventory

OJB, ADB, and TCB are the active engineering scope. Their records include every connected asset on the data path, even when the asset is not a Power App. The remaining rows are retained only as adjacent evidence leads; they do not expand STAR-2 unless they are proven to be a component or shared dependency of an OJB, ADB, or TCB path.

This register was assembled from STAR-2, the 2026-10-14 Atlas Workflows kickoff, the older systems map, and the July Power Platform investigation.

| Asset | Type | Owner / builder | Business purpose / users | Reported data path | Dependency state | Inventory state | Evidence / next action |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Ops Job Board (OJB) | Power App plus flow family | Unknown; Dustin is current investigation lead | Operations job-board workflows and activity metrics; exact user groups to confirm | Historical lead: RB9 via Power Automate/gateway → SharePoint working/archive lists → app. Current SME lead: selected Jobs Notes Log categories supply operational activity records and who/when metrics. | Reported-current dependency plus historical architecture leads | Priority; partial leads only | Export app and all related flows; verify environment, owners, lists, connection references, Jobs Notes Log queries/categories, and current production state. |
| Automated Double Board (ADB) | Power App with Power BI/Power Automate and SharePoint leads | Unknown; Dustin/Jamie are knowledge sources | Scheduling/operations double-board process; exact users to confirm | Reported-current: the same Power BI dataset/methodology as Job Suggestions reads the Jobs/JobsTasks families, then Power Automate populates an ADB state/list layer. Historical notes also describe SharePoint overrides. | Reported-current dependency; exact topology pending | Partial SME map | Identify dataset/query, flow, destination list/state, app formulas, override path, owners, refresh, and whether base or VQM objects are used. |
| True Up Calendar (TUC) | Power App | Unknown | Calendar/operations process; confirm | Older systems map says SharePoint-backed; RB9/Lagrange dependency not proven | Unknown | Not inventoried | Locate live app and connections; ask Dustin/Jamie and business owner. |
| Job Completion Form | Power App | Unknown | Historically validated job data and made the correct job number easy for the signed-in user to select on web/mobile | Historical: RB-derived data → Power BI dataset/query → Power Automate → Daily Jobs List Reference → app. The list reportedly has not refreshed since Dec 2025. | Historical/dormant; retain-or-retire decision pending | Partial SME map | Confirm app id/owner, AD scoping, last successful run/list update, current usage, and formal lifecycle decision. Do not conflate with Job Submission Form/AJSF. |
| Certifications app | Power App | Unknown | Confirm purpose and users | RB9/Lagrange dependency reported by kickoff only | Reported-current | Not inventoried | Locate app and dependency chain. |
| MyPD | Power App or related tool; exact identity pending | Jaimie work referenced; owner/builder pending | Reported consumer/use around job suggestions; exact purpose and users to confirm | Reported lead: `VUL  Job Suggestions`, with apparent old and new connections created in Jaimie's work | Reported-current lead; identity and duplicate connections unverified | Partial verbal lead | Confirm whether “MyPD” was the intended name, inspect both connections, identify live/retired one, and trace producer/consumer direction. |
| Title and Contents Builder (TCB) | Power App | Unknown | Uses suggested jobs to tell users which work needs to be completed; exact user groups to confirm | Reported-current: consumes SharePoint `VUL  Job Suggestions`, populated from a Power BI RB query by Power Automate | Reported-current indirect RB9 dependency | Partial SME map | Export app/formulas/connections; identify list id/schema, dataset/query/flow, exact Jobs/JobsTasks columns, owner, and freshness expectations. |
| LitTech-built apps | One or more Power Apps | LitTech; individuals unknown | Unknown | Ticket states some RB9/Lagrange apps were built by LitTech | Reported-current | Names unknown | Request LitTech inventory and compare with tenant admin export. |
| Jurisdictional Requirements | Power App over SharePoint list | Historical lead: Ops process owner; current owner unknown | Jurisdiction-specific production requirements | Older system map mentions SharePoint list + Power App; RB9 dependency unclear | Unknown | Scope undecided | Inspect connections and determine whether it belongs in STAR-2. |
| Out-of-Town (OOT) chart | Power BI/reporting, not necessarily a Power App | Unknown | Calendar team location/services view | Older system map reports Excel + RB data | Historical-lead | Scope decision needed | Track as an RB9 Power Platform consumer even if excluded from “Power Apps”; coordinate with reporting inventory. |
| Inquiries list | SharePoint/Power Platform candidate | Unknown | International inquiries | Older system map says moved out of RB | Historical-lead | Likely out of scope; verify | Confirm no current RB9/Lagrange dependency before excluding. |

## Known OJB component leads

These names came from July 2026 working notes. Confirm exact current names, IDs, environments, owners, state, and relationships.

| Component lead | Reported role | Current state | Proof needed |
| --- | --- | --- | --- |
| `PROTOTYPE - RB Dispatcher V2` | RB dispatcher / delta population | Unknown | Flow definition, trigger, recurrence, queries, connection references, write targets, owner. |
| `OJB - Clean Up Cancelled Jobs` | Cleanup | Unknown | Flow definition and source/write objects. |
| `OJB Full Board Reconciliation RB Dispatcher` | Full-board reconciliation | Unknown | Flow definition, query shape, cursor/backfill behavior, owner. |
| `Full Board Reconciliation Tool` | Reconciliation support | Unknown | Determine asset type and relationship to production OJB. |
| `GEN - SP List Automate Create Columns` | SharePoint schema support | Unknown | Determine whether runtime dependency or setup utility. |
| Operations Job Boards | SharePoint working list | Unknown | URL/ID pointer, schema export, item count, indexes, views, retention, owner. |
| Operations Job Boards Archive | SharePoint archive list | Unknown | URL/ID pointer, schema differences, retention, owner. |
| `rbPayload.json` | Payload/config reference | Unknown | Locate sanitized current source and determine whether still used. |
| Jobs Notes Log | Large RB9/Lagrange activity source used by OJB | Reported-current; exact physical object, count, fields, and query unknown | Confirm schema; extract OJB filters/categories and incremental query; validate performer/completion semantics; measure scale and indexes. |

## Known materialization pipelines

The detailed [current-state architecture notes](STAR-2-power-platform-current-state-architecture.md) separate three paths:

1. **Job Suggestions / TCB — reported current:** RB Jobs/JobsTasks family → unnamed Power BI dataset/query → unnamed Power Automate flow → SharePoint `VUL  Job Suggestions` → TCB, with MyPD/Jaimie and LitTech supervisor consumers still to confirm.
2. **ADB — reported current:** the same dataset/methodology is reported to populate ADB state through another Power Automate action.
3. **Job Completion Form — historical/dormant:** RB-derived data → Power BI → Power Automate → Daily Jobs List Reference → Job Completion Form. The list reportedly has not updated since December 2025.

These are logical pipeline records. The number of physical RB connections is still unknown.

## Known VQM view leads

The July ADB notes refer to `VQM jobs` and `VQM jobs tests`. Lagrange code confirms the physical names `lagrange.VQM_Jobs` and `lagrange.VQM_JobsTasks`, making “tests” likely a transcription error. The historical note has not yet been validated against the live ADB semantic model.

| Object | Confirmed Lagrange definition | Consumer lead | Remaining proof |
| --- | --- | --- | --- |
| `lagrange.VQM_Jobs` | Ordinary view over `Jobs`, with left joins to `Cases`, `Lists`, `Contacts`, and `Firms`; no SQL aggregation in reviewed definition | ADB Power BI semantic model (historical lead) | Live semantic-model query and selected columns; deployed Lagrange revision; live RB9 definition; Callisto mapping |
| `lagrange.VQM_JobsTasks` | Ordinary view with one row per `JobsTasks.TaskNo`; resolves `Task` through `Lists` and `Resource` through `Resources`; omits raw `Task` and `RsrcNo`; no SQL aggregation in reviewed definition | ADB Power BI semantic model (historical lead); other Power Platform consumers unknown | Confirm “tests” typo; live semantic-model query and selected columns; production row grain; live RB9 definition; Callisto mapping |

See [RB9 Problem 3](../../rb9/rb9-rules.md) for lineage, cardinality, and compatibility obligations.

## Target query-surface decision — blocking handoff

Direct Power App access to RB9 was reportedly removed for permissions, so the visible app is not necessarily where the database query lives. The target cannot be decided by asking only whether Callisto contains the same table names.

STAR-2 owns discovery of the required output and legacy logic. It does **not** implement the replacement, but it must make the implementation handoff unambiguous.

| Consumer | Current query layer | Legacy server-side shape | Candidate target layer | Decision owner(s) | Status / evidence needed |
| --- | --- | --- | --- | --- | --- |
| ADB | Reported: shared Power BI dataset/query → Power Automate → ADB state/list; prior semantic-model and override leads also exist | Jobs and JobsTasks families; base versus VQM unresolved | Callisto compatibility view, rebuilt semantic-model query, purpose-built payload, or combination | Dustin + Megna + semantic-model/Ops owner; confirm | Blocking: reconcile dataset, materialization, and override paths; export exact queries/columns/refresh/owner |
| Title and Contents Builder (TCB) | SharePoint `VUL  Job Suggestions` | Upstream Jobs and JobsTasks families; base versus VQM unresolved | Preserve/replace curated Job Suggestions projection | Dustin + app owner + Megna; confirm | Blocking: export app/list/flow/model and define required list contract/freshness |
| Job Completion Form | Historical Daily Jobs List Reference; no refresh since Dec 2025 | Jobs and JobsTasks family lead; exact dataset and objects unknown | Retire, leave dormant, restore, or redesign | Business owner + Dustin + Megna; confirm | Blocking lifecycle decision before migration scope is closed |
| MyPD / Jaimie-related consumer | Reported VUL Job Suggestions old/new connections | Indirect Jobs and JobsTasks family lead | Keep one supported list contract or replace | Jaimie/app owner + Dustin + Megna; confirm | Blocking: confirm asset identity, two connections, live consumer, and direction |
| OJB | Historical/current leads: Power Automate plus SharePoint projections | Jobs Notes Log and other queries/views pending | Purpose-built Callisto view/API/flow query; decide | Dustin + Megna + OJB/Ops owner; confirm | Blocking: extract every flow query, payload, cursor, and required output |
| Other consumers of a shared OJB/ADB/TCB component | Unknown | Unknown | Record only when needed to describe a shared component's blast radius | _not a STAR-2 engineering decision_ | Trace the shared edge; do not expand into tenant-wide application discovery |

### Required decision package

For each consumer, produce:

- current connection path and database engine/connector, including gateway and connection reference;
- exact source objects, columns, formulas/queries, filters, joins, lookups, sorting, row grain, and freshness;
- whether each transformation currently occurs in a VQM object, Power Query/semantic model, flow, or Power Fx;
- Callisto's available base tables, relationships, views, and approved access paths;
- chosen target layer and named owner for rebuilding/maintaining the query;
- a representative old-versus-new parity test and business acceptance owner.

A PostgreSQL connector exists, but that fact alone does not select direct Power App access. The sanctioned security model, delegation behavior, data volume, and support ownership remain decision inputs.

## Per-app dependency mapping

Add one row per source object usage. Do not combine columns whose behavior differs.

| App | Component/query evidence | Direction | Lagrange/RB9 schema | Table/view/procedure | Column | Usage (select/filter/join/sort/write/cursor) | Callisto object | Mapping state | Semantic difference / transform | Last verified | Evidence link |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| OJB | Dustin current-practice report; live query pending | read | RB9/Lagrange (confirm) | Jobs Notes Log (business label; physical object pending) | Job key, note category, actor/modified-by, last-modified, and note/details fields (exact columns pending) | Selected categories represent activities; metadata supports who/when metrics; last-modified supports incremental updates | _pending_ | unknown | Category vocabulary is incomplete; performer versus editor and completion versus modification semantics are not validated | 2026-10-20 SME report | [RB9 Problem 2](../../rb9/rb9-rules.md) |
| ADB | July investigation names `VQM jobs`; live semantic-model query pending | read | `lagrange` | `VQM_Jobs` | Consumer-selected columns pending; view exposes job fields plus lookup/relationship labels | Semantic-model source; exact selects, filters, and transformations unknown | _pending_ | unknown | View definition is confirmed in code, but production parity and actual ADB usage are not | 2026-10-20 code review plus historical lead | [RB9 Problem 3](../../rb9/rb9-rules.md) |
| ADB | July investigation says `VQM jobs tests`, likely `VQM_JobsTasks`; live semantic-model query pending | read | `lagrange` | `VQM_JobsTasks` | Consumer-selected columns pending; physical view exposes `TaskNo`, `JobNo`, derived `Task` label, derived `Resource` name, and task dates/notes | Semantic-model source; exact selects, filters, and transformations unknown | _pending_ | unknown | View omits raw `Task` and `RsrcNo`; historical consumer name still needs confirmation | 2026-10-20 code review plus historical lead | [RB9 Problem 3](../../rb9/rb9-rules.md) |
| TCB | Current SME report; live dataset/flow query pending | indirect read | RB9/Lagrange (confirm) | `Jobs` or `VQM_Jobs` | Exact columns pending | Upstream Power BI query populates `VUL  Job Suggestions` through Power Automate; TCB reads the list | _pending_ | unknown | Physical base versus VQM source, filters, selected columns, and refresh behavior unknown | 2026-10-20 SME report | [Architecture notes](STAR-2-power-platform-current-state-architecture.md) |
| TCB | Current SME report; live dataset/flow query pending | indirect read | RB9/Lagrange (confirm) | `JobsTasks` or `VQM_JobsTasks` | Exact columns pending | Upstream task data contributes to the same Job Suggestions projection | _pending_ | unknown | Relationship/lookup logic and selected task columns unknown | 2026-10-20 SME report | [Architecture notes](STAR-2-power-platform-current-state-architecture.md) |
| Job Completion Form | Historical SME report; live/historical definitions pending | historical indirect read | RB9/Lagrange (confirm) | `Jobs` or `VQM_Jobs` | Job number and validation fields; exact columns pending | Power BI/Power Automate historically populated Daily Jobs List Reference | _pending_ | unknown | Feed stale since Dec 2025; lifecycle and exact source unresolved | 2026-10-20 SME report | [Architecture notes](STAR-2-power-platform-current-state-architecture.md) |
| Job Completion Form | Historical SME report; live/historical definitions pending | historical indirect read | RB9/Lagrange (confirm) | `JobsTasks` or `VQM_JobsTasks` | Exact columns and necessity pending | Reported second source family for the historical projection | _pending_ | unknown | Whether task data was actually selected must be proven from dataset/query | 2026-10-20 SME report | [Architecture notes](STAR-2-power-platform-current-state-architecture.md) |
| MyPD / Jaimie-related consumer | Current verbal lead; asset identity pending | indirect read | RB9/Lagrange via SharePoint (confirm) | `Jobs` or `VQM_Jobs` | Exact columns pending | Reported old/new connections to `VUL  Job Suggestions` | _pending_ | unknown | Exact app name, live connection, direction, and duplicate status unknown | 2026-10-20 SME report | [Architecture notes](STAR-2-power-platform-current-state-architecture.md) |
| MyPD / Jaimie-related consumer | Current verbal lead; asset identity pending | indirect read | RB9/Lagrange via SharePoint (confirm) | `JobsTasks` or `VQM_JobsTasks` | Exact columns pending | Reported upstream source family for Job Suggestions | _pending_ | unknown | Consumer may not directly expose task fields; verify dataset lineage | 2026-10-20 SME report | [Architecture notes](STAR-2-power-platform-current-state-architecture.md) |

### Mapping-state vocabulary

- **exact** — same meaning, type, key behavior, and null behavior.
- **renamed** — semantically equivalent but named differently.
- **transformed** — available only through a defined conversion or relationship.
- **partial** — Callisto has some but not all required semantics.
- **missing** — no Callisto equivalent found.
- **unknown** — not yet checked.

## Consolidated de-duplicated object inventory

Populate from the per-app rows; do not maintain this independently by memory.

| Lagrange/RB9 object | Type | Used columns | Used by apps/components | Operations | Callisto equivalent(s) | Coverage | Gap owner | Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Jobs family: `Jobs` or `VQM_Jobs` (physical source unresolved) | Base table or ordinary view | Exact per-consumer subset pending | ADB; TCB upstream; MyPD/Jaimie lead; Job Completion historical | read | _pending_ | unknown | Dustin / Megna | Lagrange code plus SME pipeline map; live dataset query pending |
| Job Tasks family: `JobsTasks` or `VQM_JobsTasks` (physical source unresolved) | Base table or ordinary view | Exact per-consumer subset pending | ADB; TCB upstream; MyPD/Jaimie lead; Job Completion historical | read | _pending_ | unknown | Dustin / Megna | Lagrange code plus SME pipeline map; live dataset query pending |
| _pending discovery_ |  |  |  |  |  | unknown |  |  |

## Data-path and connection inventory

| Consumer/component | Environment | Connection type | Connection reference / data-source pointer | Gateway/semantic model/intermediate store | Technical owner | Credential owner | Status | Last verified | Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Shared/related Jobs dataset lead | Production (confirm) | Power BI semantic model/dataset | Name/id pending | RB9/Lagrange through gateway; reported source for Job Suggestions and ADB | Unknown | Unknown | reported-current; topology pending | 2026-10-20 SME report | [Architecture notes](STAR-2-power-platform-current-state-architecture.md) |
| Job Suggestions population | Production (confirm) | Power Automate | Flow name/id pending | Power BI dataset → SharePoint `VUL  Job Suggestions` | Unknown | Unknown | reported-current | 2026-10-20 SME report | [Architecture notes](STAR-2-power-platform-current-state-architecture.md) |
| ADB population | Production (confirm) | Power Automate | Flow name/id pending | Same dataset/method reported → ADB state/list pending | Unknown | Unknown | reported-current; exact path pending | 2026-10-20 SME report | [Architecture notes](STAR-2-power-platform-current-state-architecture.md) |
| Daily Jobs population | Production/historical (confirm) | Power BI + Power Automate | Dataset/flow names pending | Daily Jobs List Reference | Unknown | Unknown | stale since Dec 2025; lifecycle pending | 2026-10-20 SME report | [Architecture notes](STAR-2-power-platform-current-state-architecture.md) |
| `VUL  Job Suggestions` | Production (confirm) | SharePoint list | Capture site/list id; exact visible title has two spaces | Intermediate projection for TCB; other consumers pending | Unknown | Microsoft 365 connection owner pending | reported-current | 2026-10-20 SME plus repo evidence | [Architecture notes](STAR-2-power-platform-current-state-architecture.md) |
| Daily Jobs List Reference | Production/historical (confirm) | SharePoint list | Site/list id pending | Historical Job Completion Form projection | Unknown | Microsoft 365 connection owner pending | stale/dormant; not formally retired | 2026-10-20 SME report | [Architecture notes](STAR-2-power-platform-current-state-architecture.md) |
| _pending discovery_ |  |  |  |  |  |  | unknown |  |  |

Record identifiers or administrative pointers only when safe. Never record passwords, tokens, connection strings, or private connector URLs.

## Evidence and communication log

Use this to preserve who supplied a fact, who performed work, what was learned, and what still needs validation.

| Date | Person/team | Communication or work performed | What was learned / produced | Evidence source | Confidence | Follow-up |
| --- | --- | --- | --- | --- | --- | --- |
| 2026-07-06 | Prior investigation contributors; individual claims require source review | Power Platform to AWS investigation package prepared | Seeded ADB/OJB architecture, risk, flow-name, gateway, and Lagrange leads | `docs/power-platform-aws-investigation/` | Historical-lead | Revalidate every production claim. |
| 2026-10-14 | Atlas Workflows kickoff: Shaye, Craig, Dustin, Erik, Larry, Megna, Caitlin and others | Phase 1 Power Platform responsibilities and OJB milestone discussed | Named the candidate app list, Dustin's track, mapping collaborators, and Callisto/Lagrange questions | `pd-tech-wiki/projects/atlas-workflows/kickoff.md` | Reported-current | Confirm live assets and target-source decision. |
| 2026-10-20 | Dustin Thomason | Supplied Jira STAR-2 ticket text and requested working artifacts | Established required app inventory, table/column mapping, de-duplication, explicit gaps, Megna handoff, and migration exclusion | [Original ticket](STAR-2-original-ticket.md) | Confirmed requirement | Begin tenant and schema discovery. |
| 2026-10-20 | Documentation bootstrap | Created STAR-2 and RB9 Rules working artifacts | Converted known information into evidence-led scaffolds without asserting completeness | [Changelog](../STAR-2-changelog.md) | Verified artifact | Add live findings as discovery proceeds. |
| 2026-10-20 | Dustin Thomason | Described OJB's use of selected Jobs Notes Log categories and metadata as operational activity records | Identified a concrete OJB table dependency, an incomplete category vocabulary, last-modified incremental behavior, multi-million-row scale, and unresolved actor/completion semantics | [RB9 Problem 2](../../rb9/rb9-rules.md) | Reported-current | Extract the live OJB query and category list; confirm schema and measure the table. |
| 2026-10-20 | Dustin Thomason plus Lagrange repository review | Raised VQM task/resource relationship and one-to-one migration risk; inspected existing Lagrange implementations | Confirmed `VQM_Jobs` and `VQM_JobsTasks` as ordinary Lagrange views; confirmed lookup-derived labels and omitted raw keys in the task view; did not find SQL aggregation in the reviewed definitions | [RB9 Problem 3](../../rb9/rb9-rules.md); `lagrange-back-end` entity/migration code | Mixed: repository-confirmed definitions, consumer usage and RB9 parity pending | Extract live ADB/OJB queries, compare RB9 DDL, and identify any VQM object that truly aggregates rows. |
| 2026-10-20 | Dustin Thomason plus documentation review | Explained that direct RB9 Power App access was disabled and that legacy VQM surfaces worked around application-side filtering/lookup limitations; raised uncertainty over whether Callisto or Ops semantic models will own replacement queries | Located the query-surface ownership decision in STAR-2; confirmed shared kickoff says Power Automate/Power BI are current RB9 touchpoints; repository evidence says RB9 is MSSQL and Lagrange is PostgreSQL; connector and exact delegation behavior remain per-app evidence items | [RB9 Problem 3](../../rb9/rb9-rules.md); `pd-tech-wiki/projects/atlas-workflows/kickoff.md`; Microsoft connector/delegation docs | Mixed: reported current practice plus documented platform/repository facts | Export app/flow/model definitions and obtain Callisto's approved read-surface catalog; assign target query owner per consumer. |
| 2026-10-20 | Dustin Thomason plus repository search | Mapped the reported Job Completion, Job Suggestions/TCB, MyPD/Jaimie, LitTech supervisor, and ADB relationships | Added a current-state architecture companion; separated Daily Jobs from `VUL  Job Suggestions`; recorded Dec 2025 staleness; limited the source lead to Jobs and JobsTasks families; found repo confirmation of the exact VUL double-space title; named the C3 Lucid diagram as uninspected evidence | [Architecture notes](STAR-2-power-platform-current-state-architecture.md); Jaimie Shareplane docs | Mixed: SME-reported topology plus repo-confirmed list naming | Export Lucid, Power BI, flows, lists, and apps; obtain lifecycle decision for Job Completion. |

## Gaps and unknowns

1. Which Power Platform environments contain the complete app/flow set?
2. Does Dustin have Power Platform Administrator visibility, or only maker/owner visibility?
3. What are the names and current owners of all LitTech-built apps?
4. Which candidate apps are retired, renamed, duplicated, or disconnected?
5. Which apps currently read RB9, which read Lagrange, and which use Power BI or Power Automate as the only RB9 touchpoint?
6. Which components write data, where do they write it, and how is that state reconciled?
7. Which Power BI semantic models/dataflows are dependencies rather than reporting-only consumers?
8. Where is the existing OJB/ADB field-mapping spreadsheet, and is it current?
9. What Lagrange views already satisfy OJB, and what are their underlying tables/columns?
10. Which Callisto branch/schema revision is the mapping target?
11. What constitutes semantic equivalence beyond matching names: keys, nulls, time zones, status translations, calculated fields, and row availability?
12. Who validates each app's business behavior after data parity is established?
13. Where will the final team-visible inventory live: Confluence, shared wiki, Jira attachment/link, or a generated artifact?
14. What is the exact Jobs Notes Log physical table/view name and which columns does OJB read?
15. Which note category ids/labels currently represent OJB activities, including categories added after the original implementation?
16. Does the selected actor identify the performer, author, last editor, assigned user, or an automation identity?
17. Does last modified represent completion, and how do corrections or later edits affect historical metrics?
18. What are the measured row count, growth rate, indexes, query plan, retention, and incremental-cursor guarantees for the Jobs Notes Log?
19. Does the ADB semantic model actually use `VQM_Jobs` and `VQM_JobsTasks`, and which columns, filters, and transformations does it select?
20. Was the historical label `VQM jobs tests` a transcription error for `VQM_JobsTasks`?
21. Do live RB9 VQM definitions match Lagrange, and are any RB9 objects materialized or cached rather than ordinary views?
22. Which VQM objects or columns truly aggregate multiple rows, rather than only enriching one row with lookup values?
23. Will Callisto preserve Job → Job Task → Resource keys/cardinality and provide compatibility projections for the exact legacy columns still used?
24. What database engine and connector did each legacy connection reference actually use? Current repository evidence says RB9 MSSQL, not MySQL.
25. Which specific Power Fx/connector expressions failed delegation or lookup requirements, and were the limitations in the connector, formula shape, permissions, or data volume?
26. Is direct Power App access to Callisto PostgreSQL prohibited, merely unplanned, or an approved candidate after gateway/security/delegation validation?
27. For each app, which team owns rebuilding the query: Callisto/data, Power BI/Ops, Power Automate/API, or the app owner?
28. What Callisto base tables, views/materialized views, relationships, and read contracts will be available, on what schedule?
29. What freshness, latency, row-volume, filtering, and parity requirements must each target query surface meet?
30. What is the exact C3/Lucid document id, page, owner, revision, and reviewed export for `RB9 Replacement Power Platform`?
31. What is the shared Power BI dataset/semantic-model name, id, workspace, owner, query mode, and source connection?
32. Do Job Suggestions and ADB share one physical dataset/query connection, two queries in one model, or separate refresh paths?
33. What are the exact Power Automate flows and SharePoint destinations for Job Suggestions, ADB, and historical Daily Jobs population?
34. What are the immutable ids, schemas, grain, row counts, refresh timestamps, and owners of `VUL  Job Suggestions` and Daily Jobs List Reference?
35. Does TCB consume `VUL  Job Suggestions` directly, and which fields/formulas does it use?
36. Is the Jaimie-related consumer actually MyPD, and which of the reported old/new connections is live?
37. What LitTech supervisor app/tool consumes Job Suggestions, if any?
38. Is Job Completion Form formally retired, dormant, broken, or planned for restoration? Who owns that decision?
39. Did “job submission form” refer to Job Completion Form or the distinct AJSF/Atlas Job Submission Form?
40. Do the Power BI queries select base `Jobs`/`JobsTasks` or `VQM_Jobs`/`VQM_JobsTasks`, and which columns and filters?
41. What alerts or freshness checks should detect another silently stale SharePoint projection?

## Immediate next actions

| Order | Action | Primary | Support | Deliverable |
| --- | --- | --- | --- | --- |
| 1 | Export/admin-list apps, flows, connections, and environments; record visibility limitations. | Dustin | Power Platform admin if needed | App universe baseline. |
| 2 | Reconcile baseline with Dustin, Jamie, and LitTech; classify active/retired/unknown. | Dustin | Jamie, LitTech | Reviewed app list with explicit gaps. |
| 3 | Inventory OJB first: app, flows, SharePoint lists, gateway, Jobs Notes Log categories/fields, queries, cursors, and writes. | Dustin | Jamie/Ops | Complete OJB dependency chain and activity vocabulary. |
| 4 | Export/reconcile the C3 Lucid diagram and extract Job Suggestions, ADB, Job Completion, TCB, and MyPD app/model/flow/list definitions; identify connector, base-vs-VQM objects, columns, filters/lookups, row grain, freshness, and lifecycle. | Dustin | Jaimie/Jamie, LitTech, app/model owners | Reviewed architecture map, per-app query contracts, and lifecycle register. |
| 5 | Publish the Callisto read-surface catalog and decide, per consumer, whether the replacement query lives in Callisto SQL, a semantic model, Power Automate/API, or another governed layer. | Megna / target data owner; confirm | Dustin, Larry, Ops/BI owner, Platform/security | Signed query-surface and ownership matrix. |
| 6 | Map used objects to Callisto and record semantic differences/missing coverage against the chosen target layer. | Megna | Dustin, Larry | Old-to-new mapping. |
| 7 | De-duplicate used objects and review with Megna and business owners. | Dustin | Megna, app owners | Acceptance-ready consolidated inventory. |
| 8 | Link the reviewed artifact from STAR-2/Confluence and promote stable RB9 rules to `pd-tech-wiki`. | Dustin | Megna, wiki owner | Team-visible handoff and durable knowledge. |

## Acceptance-criteria tracker

| Criterion | Status | Evidence / blocker |
| --- | --- | --- |
| All known Power Apps listed with owner, purpose, and data source | Started | Candidate list now includes reported Job Completion, TCB, MyPD, and ADB paths; tenant completeness and owner validation remain pending. |
| Each app mapped to tables and columns | Started | Jobs Notes Log and historical ADB VQM leads are recorded; live queries and exact consumer-selected columns remain pending. |
| Consolidated old-to-new inventory and missing flags | Not started | Requires per-app extraction, a current Callisto surface catalog, and target query-layer decisions. |
| Target query surface and owner agreed per consumer | Started | Decision package and candidate layers documented; no consumer decision or owner confirmation yet. |
| Gaps and unknowns explicit | Started | Initial gap register exists above. |
| Stored/linked in team system and shared with Megna | Not started | Current artifact is in Dustin's working repo; final destination/review pending. |

## Out of scope

- Migrating or modifying Power Apps.
- Moving data into Callisto.
- Repointing connections.
- Production gateway, flow, dataset, SharePoint, RB9, Lagrange, or Callisto changes.
- Treating historical notes as current production truth without live verification.
