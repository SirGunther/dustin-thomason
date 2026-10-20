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

OJB, ADB, and TCB are the active engineering scope. Their records include every connected asset on the data path, even when the asset is not a Power App.

| System | Technical purpose | Reported data path | Inventory state | Next technical proof |
| --- | --- | --- | --- | --- |
| Ops Job Board (OJB) | Operations job-board workflows and activity metrics | RB9/Lagrange, including selected Jobs Notes Log activity records → gateway/Power Automate paths → SharePoint working/archive stores → OJB | Partial leads | Name every environment, gateway/connection, flow, list, query, cursor, table/column, and app connection; export definitions. |
| Automated Double Board (ADB) | Scheduling/operations double-board process | Jobs/JobsTasks family → reported shared Power BI/Power Query layer → Power Automate → ADB SharePoint/state and override layers → ADB | Partial SME map | Name the workspace/model/query, gateway/connection, flow, stores, override path, app connection, and exact source columns; prove base versus VQM. |
| Title and Contents Builder (TCB) | Presents suggested jobs that require work | Jobs/JobsTasks family → reported shared Power BI/Power Query layer → Power Automate → SharePoint `VUL  Job Suggestions` → TCB | Partial SME map | Name the workspace/model/query, gateway/connection, flow, list id/schema, app connection, and exact source/list columns; prove base versus VQM. |

### Adjacent evidence—not additional active scope

| Lead | Why it remains recorded | STAR-2 treatment |
| --- | --- | --- |
| Job Completion Form / Daily Jobs List Reference | Historical path may share the same dataset or query pattern and helps prevent Daily Jobs from being conflated with Job Suggestions | Record only the shared technical facts; no lifecycle decision is required. |
| MyPD/Jaimie and possible LitTech supervisor consumers | May consume the shared `VUL  Job Suggestions` projection | Record the downstream edge only if needed to show reuse or blast radius. |
| TUC, Certifications, Jurisdictional Requirements, OOT, Inquiries, and unidentified LitTech apps | Earlier documents named them as Power Platform leads | No active work unless evidence places one on an OJB, ADB, or TCB path. |

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

## Replacement-query engineering handoff

Direct Power App access to RB9 was reportedly removed for permissions, so the visible app is not necessarily the layer that queries the database. STAR-2 must document the current query path and required output; it does not choose the future product architecture or implementation owner.

| System | Current query path | Source-shape lead | Technical evidence still needed |
| --- | --- | --- | --- |
| OJB | Power Automate/gateway plus SharePoint projections; exact path pending | Jobs Notes Log and other queries/views pending | Flow queries, payloads, cursors, gateways/connections, stores, columns, transformations, and environments |
| ADB | Reported shared Power BI/Power Query layer → Power Automate → ADB state/override layer | Jobs and JobsTasks families; base versus VQM unresolved | Model/query, connection, selected columns, filters, joins, refresh/trigger, flow, state store, overrides, and app connection |
| TCB | Reported shared Power BI/Power Query layer → Power Automate → `VUL  Job Suggestions` → TCB | Jobs and JobsTasks families; base versus VQM unresolved | Model/query, connection, selected columns, filters, joins, refresh/trigger, flow, list contract, and app connection |

For each system, the handoff must contain:

- the complete current connection path and environment placement;
- the database engine, gateway/data source, connector, and connection reference;
- exact source objects, columns, formulas or queries, filters, joins, lookups, sorting, row grain, and freshness;
- where each transformation currently occurs: VQM object, Power Query/semantic model, flow, SharePoint, or Power Fx;
- Callisto's matching objects or explicit missing, partial, or unknown coverage;
- a representative old-versus-new technical parity case for later implementation work.

Selecting and building the replacement query layer is separate from STAR-2.

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
| 2026-10-20 | Dustin Thomason | Supplied Jira STAR-2 ticket text and requested working artifacts | Established required dependency inventory, table/column mapping, de-duplication, explicit gaps, data-team handoff, and migration exclusion | [Original ticket](STAR-2-original-ticket.md) | Confirmed requirement | Begin OJB, ADB, and TCB path and schema discovery. |
| 2026-10-20 | Documentation bootstrap | Created STAR-2 and RB9 Rules working artifacts | Converted known information into evidence-led scaffolds without asserting completeness | [Changelog](../STAR-2-changelog.md) | Verified artifact | Add live findings as discovery proceeds. |
| 2026-10-20 | Dustin Thomason | Described OJB's use of selected Jobs Notes Log categories and metadata as operational activity records | Identified a concrete OJB table dependency, an incomplete category vocabulary, last-modified incremental behavior, multi-million-row scale, and unresolved actor/completion semantics | [RB9 Problem 2](../../rb9/rb9-rules.md) | Reported-current | Extract the live OJB query and category list; confirm schema and measure the table. |
| 2026-10-20 | Dustin Thomason plus Lagrange repository review | Raised VQM task/resource relationship and one-to-one migration risk; inspected existing Lagrange implementations | Confirmed `VQM_Jobs` and `VQM_JobsTasks` as ordinary Lagrange views; confirmed lookup-derived labels and omitted raw keys in the task view; did not find SQL aggregation in the reviewed definitions | [RB9 Problem 3](../../rb9/rb9-rules.md); `lagrange-back-end` entity/migration code | Mixed: repository-confirmed definitions, consumer usage and RB9 parity pending | Extract live ADB/OJB queries, compare RB9 DDL, and identify any VQM object that truly aggregates rows. |
| 2026-10-20 | Dustin Thomason plus documentation review | Explained that direct RB9 Power App access was disabled and that legacy VQM surfaces worked around application-side filtering/lookup limitations; raised uncertainty over whether Callisto or Ops semantic models will own replacement queries | Located the query-surface ownership decision in STAR-2; confirmed shared kickoff says Power Automate/Power BI are current RB9 touchpoints; repository evidence says RB9 is MSSQL and Lagrange is PostgreSQL; connector and exact delegation behavior remain per-app evidence items | [RB9 Problem 3](../../rb9/rb9-rules.md); `pd-tech-wiki/projects/atlas-workflows/kickoff.md`; Microsoft connector/delegation docs | Mixed: reported current practice plus documented platform/repository facts | Export app/flow/model definitions and obtain Callisto's approved read-surface catalog; assign target query owner per consumer. |
| 2026-10-20 | Dustin Thomason plus repository search | Mapped the reported Job Completion, Job Suggestions/TCB, MyPD/Jaimie, LitTech supervisor, and ADB relationships | Added a current-state architecture companion; separated Daily Jobs from `VUL  Job Suggestions`; recorded Dec 2025 staleness; limited the source lead to Jobs and JobsTasks families; found repo confirmation of the exact VUL double-space title; named the C3 Lucid diagram as uninspected evidence | [Architecture notes](STAR-2-power-platform-current-state-architecture.md); Jaimie Shareplane docs | Mixed: SME-reported topology plus repo-confirmed list naming | Export and reconcile the shared Lucid, Power BI, flow, list, and app assets that sit on ADB or TCB paths. |

## Technical gaps and unknowns

### OJB

1. Which Power Platform environment contains OJB and its flows?
2. What are the exact app, flow, gateway/data-source, connection-reference, and SharePoint list names and stable ids?
3. Which Jobs Notes Log table, columns, categories, filters, actor/time fields, and incremental cursor are used?
4. What other RB9/Lagrange objects, writes, reconciliation paths, and archive behaviors are part of OJB?

### ADB

5. Which environment, workspace, semantic model/dataset, Power Query/native query, gateway/data source, connection, flow, and stores form the active path?
6. Does ADB select `Jobs`/`JobsTasks` or `VQM_Jobs`/`VQM_JobsTasks`, and which columns, filters, joins, and transformations are used?
7. How do the materialized state path and SharePoint override path join, and what does the app read or write?

### TCB

8. Which environment, workspace, semantic model/dataset, Power Query/native query, gateway/data source, connection, and flow populate `VUL  Job Suggestions`?
9. What are the immutable SharePoint list id, site, schema, keys, refresh/trigger behavior, and exact producer columns?
10. Which list fields, formulas, and connection references does TCB consume?

### Shared and target facts

11. Do ADB and TCB share one physical dataset/query/connection or only a similar methodology?
12. Which expected components currently exist, are only reported, are inaccessible, or have not been created?
13. What Callisto objects match each used RB9/Lagrange table and column, and where are semantics partial or missing?
14. What environment-aware Lucid pages and evidence exports are still absent?

## Immediate next actions

| Order | Engineering action | Output |
| --- | --- | --- |
| 1 | Inventory OJB end to end and extract every named component, environment, connection, query, table/column, cursor, store, and app edge. | Verified OJB dependency record |
| 2 | Inventory ADB end to end, including its Power BI/Power Query path, gateway/connections, flow, state store, override path, and app edge. | Verified ADB dependency record |
| 3 | Inventory TCB end to end, including its shared query path, Job Suggestions flow, `VUL  Job Suggestions` contract, and app edge. | Verified TCB dependency record |
| 4 | Create or reconcile one Lucid page for OJB, ADB, and TCB using environment/platform swimlanes and per-node existence states. | Three current-state diagrams |
| 5 | Consolidate the RB9/Lagrange tables and columns and map each to Callisto as exact, partial, missing, or unknown. | De-duplicated old-to-new mapping |
| 6 | Link the inventory, diagrams, and sanitized evidence from STAR-2/Confluence and provide the technical handoff to the data team. | Ticket-ready engineering handoff |

## Acceptance-criteria tracker

| Engineering criterion | Status | Evidence / blocker |
| --- | --- | --- |
| OJB, ADB, and TCB have bounded end-to-end dependency records | Started | Reported paths exist; exact named assets and environments remain incomplete. |
| Every connected component is named, typed, environment-located, and existence-marked | Started | Scaffolding exists; live ids and exports remain pending. |
| Each system is mapped to exact RB9/Lagrange tables and columns | Started | Jobs Notes Log and Jobs/JobsTasks/VQM leads are recorded; exact live queries and selected columns remain pending. |
| Consolidated old-to-new inventory has Callisto mappings and missing flags | Not started | Requires exact source extraction and Callisto comparison. |
| One environment-aware Lucid page exists for OJB, ADB, and TCB | Not started | Page requirements and visual convention are documented. |
| Technical gaps and unknowns are explicit | Started | System-specific gap register exists above. |
| Owner/builder, purpose, and users are recorded from evidence or marked unknown | Started | These are metadata fields, not engineering scope decisions. |
| Artifact is linked and handed to the data team | Not started | Current artifact remains in Dustin's working repository. |

## Out of scope

- Migrating or modifying Power Apps.
- Moving data into Callisto.
- Repointing connections.
- Production gateway, flow, dataset, SharePoint, RB9, Lagrange, or Callisto changes.
- Building or testing replacement connections or environments.
- Stakeholder relevance, product scope, lifecycle, prioritization, or target-architecture decisions.
- Tenant-wide discovery unrelated to OJB, ADB, or TCB.
- Treating historical notes as current production truth without live verification.
