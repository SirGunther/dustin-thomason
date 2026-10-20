# STAR-2 — Power Platform and RB9/Lagrange Dependency Inventory

Status: Discovery scaffold; not complete  
Owner: Dustin Thomason  
Started: 2026-10-20  
Last updated: 2026-10-20  
Jira: [STAR-2](https://pd-product-dev.atlassian.net/browse/STAR-2)

## Outcome

Produce a verified inventory of every Power App that depends on RB9 or Lagrange, the complete set of tables and columns each app uses, and the corresponding Callisto objects or confirmed gaps.

This document is the working evidence artifact. It must distinguish live evidence from historical leads. “Known app” does not mean “dependency verified,” and an empty mapping cell means unknown—not absent.

## Definition of complete

- [ ] The Power App universe has been checked through tenant/admin inventory plus Dustin, Jamie, and LitTech input.
- [ ] Every in-scope app has a confirmed owner or an explicit “owner unknown” gap.
- [ ] Business purpose and user group are confirmed for every app.
- [ ] Every app's complete dependency chain is traced through flows, semantic models, gateways, connections, and intermediate stores.
- [ ] Every RB9/Lagrange table and column read or written is recorded per app.
- [ ] Each old object has a verified Callisto equivalent or an explicit missing flag.
- [ ] A de-duplicated object list is produced.
- [ ] Conflicts, inaccessible assets, and unknowns are explicit.
- [ ] Megna has reviewed the inventory for Lagrange-to-Callisto planning.
- [ ] The artifact is linked from Jira or Confluence.

## Evidence levels

| Level | Meaning |
| --- | --- |
| Verified-live | Observed in the current tenant, exported source, flow definition, query, schema, or owner-confirmed screen share. |
| Verified-schema | Confirmed in current Lagrange or Callisto schema/code but not yet tied to a live app reference. |
| Reported-current | Current owner/team states it is true; primary technical evidence still needed. |
| Historical-lead | Prior note or document that may no longer reflect production. |
| Unknown | No reliable evidence yet. |

## Discovery method

1. **Establish the app universe**
   - Pull the Power Platform admin inventory across relevant environments.
   - Reconcile it with Dustin's, Jamie's, and LitTech's lists.
   - Record inaccessible, orphaned, renamed, duplicate, and retired assets.
2. **Trace each app's dependency chain**
   - Inspect canvas app source/formulas.
   - Inspect solution and non-solution Power Automate definitions.
   - Inspect Power BI semantic models, reports, dataflows, and refresh configuration where used.
   - Record connection references, gateway/data-source identities, and SharePoint/intermediate stores without copying secrets.
3. **Extract data usage**
   - Capture source query text or formula evidence.
   - Expand views and stored procedures when needed to identify underlying objects.
   - Separate reads, writes, filters, joins, sort keys, high-water marks, and override/reconciliation fields.
4. **Map to Callisto**
   - Verify names, keys, types, nullability, semantics, relationships, and timestamp behavior.
   - Mark absent and semantically different objects explicitly.
5. **Consolidate and validate**
   - De-duplicate the used objects.
   - Review with Megna and relevant app/business owners.
   - Link supporting exports or sanitized evidence.

## Candidate application inventory

This is a lead list assembled from STAR-2, the 2026-10-14 Atlas Workflows kickoff, the older systems map, and the July Power Platform investigation. Rows are not confirmed in scope until live evidence shows an RB9/Lagrange dependency.

| Asset | Type | Owner / builder | Business purpose / users | Reported data path | Dependency state | Inventory state | Evidence / next action |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Ops Job Board (OJB) | Power App plus flow family | Unknown; Dustin is current investigation lead | Operations job-board workflows and activity metrics; exact user groups to confirm | Historical lead: RB9 via Power Automate/gateway → SharePoint working/archive lists → app. Current SME lead: selected Jobs Notes Log categories supply operational activity records and who/when metrics. | Reported-current dependency plus historical architecture leads | Priority; partial leads only | Export app and all related flows; verify environment, owners, lists, connection references, Jobs Notes Log queries/categories, and current production state. |
| Automated Double Board (ADB) | Power App with Power BI/Power Automate and SharePoint leads | Unknown; Dustin/Jamie are knowledge sources | Scheduling/operations double-board process; exact users to confirm | Historical lead: Power BI semantic model as base plus SharePoint manual overrides | Historical-lead | Not inventoried | Inspect app formulas, semantic model, flows, override list, owners, refresh, and reconciliation. |
| True Up Calendar (TUC) | Power App | Unknown | Calendar/operations process; confirm | Older systems map says SharePoint-backed; RB9/Lagrange dependency not proven | Unknown | Not inventoried | Locate live app and connections; ask Dustin/Jamie and business owner. |
| Job Completion Form | Power App | Unknown | Confirm purpose and users | RB9/Lagrange dependency reported by kickoff only | Reported-current | Not inventoried | Locate app, owner, source, formulas, flows, and query objects. |
| Certifications app | Power App | Unknown | Confirm purpose and users | RB9/Lagrange dependency reported by kickoff only | Reported-current | Not inventoried | Locate app and dependency chain. |
| MyPD | Power App | Unknown | Confirm purpose and users | RB9/Lagrange dependency reported by kickoff only | Reported-current | Not inventoried | Resolve exact app identity and dependency chain. |
| Title and Contents Builder (TCB) | Power App | Unknown | Title/contents workflow; exact users to confirm | RB9/Lagrange dependency reported by kickoff only | Reported-current | Not inventoried | Locate app, flows, source objects, writes, and owner. |
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
| ADB | Historical lead: Power BI semantic model | `VQM_Jobs` and likely `VQM_JobsTasks` | Callisto compatibility view, rebuilt semantic-model query, or both | Dustin + Megna + semantic-model/Ops owner; confirm | Blocking: export model schema, Power Query/native SQL/DAX, selected columns, refresh, and owner |
| Title and Contents Builder (TCB) | Unknown | Unknown | TBD after app/flow inspection | Dustin + app owner + Megna; confirm | Blocking: export app/flows/connections and identify any VQM/list-table logic |
| OJB | Historical/current leads: Power Automate plus SharePoint projections | Jobs Notes Log and other queries/views pending | Purpose-built Callisto view/API/flow query; decide | Dustin + Megna + OJB/Ops owner; confirm | Blocking: extract every flow query, payload, cursor, and required output |
| Other Power Platform consumers | Unknown | Unknown | Per-consumer decision | App owner + Dustin + data owner | Blocking: complete tenant inventory and trace every connection |

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
| `lagrange.VQM_Jobs` | Ordinary view | Actual ADB-selected subset pending | ADB semantic model (historical lead) | read | _pending_ | unknown | Dustin / Megna | Lagrange code; live consumer query pending |
| `lagrange.VQM_JobsTasks` | Ordinary view | Actual ADB-selected subset pending | ADB semantic model (historical lead) | read | _pending_ | unknown | Dustin / Megna | Lagrange code; live consumer query pending |
| _pending discovery_ |  |  |  |  |  | unknown |  |  |

## Data-path and connection inventory

| Consumer/component | Environment | Connection type | Connection reference / data-source pointer | Gateway/semantic model/intermediate store | Technical owner | Credential owner | Status | Last verified | Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
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

## Immediate next actions

| Order | Action | Primary | Support | Deliverable |
| --- | --- | --- | --- | --- |
| 1 | Export/admin-list apps, flows, connections, and environments; record visibility limitations. | Dustin | Power Platform admin if needed | App universe baseline. |
| 2 | Reconcile baseline with Dustin, Jamie, and LitTech; classify active/retired/unknown. | Dustin | Jamie, LitTech | Reviewed app list with explicit gaps. |
| 3 | Inventory OJB first: app, flows, SharePoint lists, gateway, Jobs Notes Log categories/fields, queries, cursors, and writes. | Dustin | Jamie/Ops | Complete OJB dependency chain and activity vocabulary. |
| 4 | Extract OJB, ADB, TCB, and other source definitions; identify connector, exact VQM names, selected columns, filters/lookups, row grain, and the layer currently performing each transformation. | Dustin | Jamie, app/model owners | Per-app query contract and VQM lineage. |
| 5 | Publish the Callisto read-surface catalog and decide, per consumer, whether the replacement query lives in Callisto SQL, a semantic model, Power Automate/API, or another governed layer. | Megna / target data owner; confirm | Dustin, Larry, Ops/BI owner, Platform/security | Signed query-surface and ownership matrix. |
| 6 | Map used objects to Callisto and record semantic differences/missing coverage against the chosen target layer. | Megna | Dustin, Larry | Old-to-new mapping. |
| 7 | De-duplicate used objects and review with Megna and business owners. | Dustin | Megna, app owners | Acceptance-ready consolidated inventory. |
| 8 | Link the reviewed artifact from STAR-2/Confluence and promote stable RB9 rules to `pd-tech-wiki`. | Dustin | Megna, wiki owner | Team-visible handoff and durable knowledge. |

## Acceptance-criteria tracker

| Criterion | Status | Evidence / blocker |
| --- | --- | --- |
| All known Power Apps listed with owner, purpose, and data source | Not started | Candidate lead list only; no tenant export or owner validation. |
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
