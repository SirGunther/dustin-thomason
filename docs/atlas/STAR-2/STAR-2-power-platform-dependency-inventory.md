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
| Ops Job Board (OJB) | Power App plus flow family | Unknown; Dustin is current investigation lead | Operations job-board workflows; exact user groups to confirm | Historical lead: RB9 via Power Automate/gateway → SharePoint working/archive lists → app | Historical-lead | Priority; partial leads only | Export app and all related flows; verify environment, owners, lists, connection references, queries, and current production state. |
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

## Per-app dependency mapping

Add one row per source object usage. Do not combine columns whose behavior differs.

| App | Component/query evidence | Direction | Lagrange/RB9 schema | Table/view/procedure | Column | Usage (select/filter/join/sort/write/cursor) | Callisto object | Mapping state | Semantic difference / transform | Last verified | Evidence link |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| OJB | _pending_ | _read/write_ | _pending_ | _pending_ | _pending_ | _pending_ | _pending_ | unknown | _pending_ | _pending_ | _pending_ |

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

## Immediate next actions

| Order | Action | Primary | Support | Deliverable |
| --- | --- | --- | --- | --- |
| 1 | Export/admin-list apps, flows, connections, and environments; record visibility limitations. | Dustin | Power Platform admin if needed | App universe baseline. |
| 2 | Reconcile baseline with Dustin, Jamie, and LitTech; classify active/retired/unknown. | Dustin | Jamie, LitTech | Reviewed app list with explicit gaps. |
| 3 | Inventory OJB first: app, flows, SharePoint lists, gateway, queries, cursors, and writes. | Dustin | Jamie/Ops | Complete OJB dependency chain. |
| 4 | Extract OJB tables/columns and compare with current Lagrange views. | Dustin | Megna, Larry | Per-app object map and Lagrange gaps. |
| 5 | Map used objects to Callisto and record semantic differences/missing coverage. | Megna | Dustin, Larry | Old-to-new mapping. |
| 6 | De-duplicate used objects and review with Megna and business owners. | Dustin | Megna, app owners | Acceptance-ready consolidated inventory. |
| 7 | Link the reviewed artifact from STAR-2/Confluence and promote stable RB9 rules to `pd-tech-wiki`. | Dustin | Megna, wiki owner | Team-visible handoff and durable knowledge. |

## Acceptance-criteria tracker

| Criterion | Status | Evidence / blocker |
| --- | --- | --- |
| All known Power Apps listed with owner, purpose, and data source | Not started | Candidate lead list only; no tenant export or owner validation. |
| Each app mapped to tables and columns | Not started | Mapping table is empty. |
| Consolidated old-to-new inventory and missing flags | Not started | Requires per-app extraction and current Callisto schema. |
| Gaps and unknowns explicit | Started | Initial gap register exists above. |
| Stored/linked in team system and shared with Megna | Not started | Current artifact is in Dustin's working repo; final destination/review pending. |

## Out of scope

- Migrating or modifying Power Apps.
- Moving data into Callisto.
- Repointing connections.
- Production gateway, flow, dataset, SharePoint, RB9, Lagrange, or Callisto changes.
- Treating historical notes as current production truth without live verification.
