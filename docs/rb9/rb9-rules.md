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
| RB9-R-012 | Resource classification | Planet Depos encodes worker classification in the Resource name text. A leading `#` denotes a current internal Planet Depos employee; a trailing `(I)` denotes an independent contractor. The encoding for an external employee or other states is not yet documented. | Identity/display text is carrying structured business meaning. Every consumer that parses or displays the name can accidentally become classification logic. | Reported-current by Dustin | Dustin Thomason, 2026-10-20; confirm exact physical table/column, syntax variants, and sample rows. |
| RB9-R-013 | Resource history | Changing the classification marker changes the live Resource name for the entire database and affected materialized views. No effective-dated/version history is currently known. | Rerunning a historical report can classify past work using the person's current relationship instead of the relationship at the time of the work. | Reported-current by Dustin | Inspect RB9 audit/history facilities, update workflow, replicated tables, and affected materialized views. |
| RB9-R-014 | Historical snapshots | The current workaround for missing Resource classification history is to snapshot a period so the table/view state at that time remains available. | Snapshots preserve evidence, but their cadence, completeness, ownership, retention, and “as of” semantics become part of metric correctness. | Reported-current by Dustin | Locate existing snapshots/jobs and record grain, timestamp, storage, owner, refresh cadence, and consumers. |
| RB9-R-015 | Workforce metrics | Internal employees and independent contractors can change relationship in either direction. Metrics must classify a person as of the relevant reporting event/date rather than from the current Resource name. | Current-value joins can materially rewrite historical employee-versus-contractor metrics and trends. | Confirmed business requirement; implementation unknown | Identify affected reports and agree which effective date governs each metric. |
| RB9-R-016 | OJB activity tracking | OJB repurposes categorized rows from the Jobs Notes Log as records of operational activities because RB9 does not provide an immediately extensible structured task/activity mechanism for these workflows. | The note log is functioning as an event/task ledger beyond its original communication purpose. Replacement architecture must recover the business activities, not merely copy notes. | Reported-current by Dustin | Dustin Thomason, 2026-10-20; inspect OJB queries, flows, formulas, and current note categories. |
| RB9-R-017 | Activity vocabulary | Specific note categories are interpreted as specific completed activities. Reported examples include checking in exhibits and finalizing a training; the complete category-to-activity mapping is unknown and likely expanded after the original approach was introduced. | Categories form an undocumented integration contract. Missing one can omit work from operations visibility and metrics. | Reported-current; incomplete | Enumerate categories from OJB source and live data; confirm “finalizing a training” wording and business meaning. |
| RB9-R-018 | Activity actor and time | OJB uses Jobs Notes Log metadata to determine who performed an activity and when it was completed, including a last-modified value. It is not yet proven that the modifying user is always the performer or that last modified is always the completion time. | Later edits or system-written rows could silently change attribution and completion metrics. Future design must separate performed-at/by from recorded/modified-at/by. | Reported behavior; semantics unverified | Identify exact fields and test create, edit, reassignment, automation, and correction cases. |
| RB9-R-019 | Log volume | The Jobs Notes Log is known to be very large—multi-million rows—but the current count is unverified. Estimates discussed range broadly and must not be treated as measurements. | Broad scans, view refreshes, backfills, and connector queries can become unsafe. Category, job, time-window, indexing, and incremental-query behavior are architectural concerns. | Reported scale; count unknown | Measure current row count, growth rate, indexes, query plans, retention, and per-category distribution. |
| RB9-R-020 | OJB incremental reads | OJB checks a last-modified value when updating from the Jobs Notes Log, consistent with its other incremental updates. The full cursor, tie-breaker, overlap, retry, and late-edit behavior are not yet documented. | A timestamp-only cursor can miss same-timestamp rows or mishandle late edits. The replacement needs an explicit, replayable incremental contract. | Reported-current; mechanics unknown | Extract the actual OJB query and cursor storage; test timestamp collisions, retries, edits, and backfill. |

## Problem 1 — Resource classification is encoded in a mutable name

### Current practice

The RB9 Resource table's name value is doing two jobs: it identifies the person and encodes the person's current relationship to Planet Depos. The exact physical table and column names still need schema confirmation.

| Classification | Name convention reported in use | Meaning | Still unknown |
| --- | --- | --- | --- |
| Current internal Planet Depos employee | **#** at the beginning of the name | The person is currently working as an internal employee. | Exact spacing/casing rules; whether the marker also encodes active status; handling of former employees. |
| Independent contractor | **(I)** at the end of the name | The person is currently treated as an independent contractor. | Exact spacing/casing variants; whether other contractor types use different suffixes. |
| External employee | Not yet documented | A distinct category was named, but its encoding and meaning have not been captured. | Marker, definition, and whether this is separate from contractor status. |
| Unmarked or other combinations | Not yet documented | Unknown. | Whether unmarked is a default category, incomplete data, inactive state, or another worker type; whether both markers can coexist. |

This is an overloaded-field workaround: display text is also a classification code. Until live values and every consumer are inspected, downstream logic must not assume the two known markers cover all valid states.

### Why historical metrics drift

**Independent contractor at Period 1 → relationship changes → current Resource name is overwritten → materialized views refresh → a historical report may classify the person's past work using the new category.**

The reverse transition creates the reverse distortion. The core issue is not merely the name formatting; it is that a current mutable value is being used to answer an effective-dated historical question.

An illustrative failure:

| Time | What happened | Current-value reporting result |
| --- | --- | --- |
| Period 1 | A person works as an independent contractor and is marked with **(I)**. | Period 1 metrics are initially contractor metrics. |
| Period 2 | The same person becomes an internal employee and the Resource name is changed to start with **#**. | The live row and refreshed views now expose the internal marker. |
| Later rerun of Period 1 | A report joins old work to the current Resource row/name. | Period 1 may be reclassified as internal even though the work occurred while the person was a contractor. |

### Current workaround: point-in-time snapshots

A snapshot preserves the table or materialized-view state for a defined period before later name changes rewrite the current representation. That makes historical reporting possible, but only if every snapshot records:

- the business “as of” time it represents;
- the extraction/load time;
- the included tables, views, rows, and columns;
- the source environment/revision;
- whether it is a full snapshot or an incremental extract;
- the owner, cadence, retention, and failure/retry behavior;
- which reports treat it as authoritative.

A snapshot is evidence of historical state, not a replacement for explicit effective-dated classification in the future system.

### Future architecture obligations

1. **Separate identity from classification.** A person's display name must not be the authoritative worker classification.
2. **Model each business concept explicitly.** Worker relationship (employee/contractor/other), active status, and internal/external status may be separate axes; do not collapse them into one enum until the business definitions are confirmed.
3. **Keep effective-dated history.** Classification changes need at least an effective start and end, or an equivalent immutable change/event history.
4. **Define the reporting date.** Each metric must state whether classification is evaluated at job date, service date, invoice date, reporting-period end, snapshot date, or another business event.
5. **Make changes auditable.** Record the old value, new value, effective date, actor/source, and recorded-at time.
6. **Preserve raw legacy evidence during migration.** Retain the original RB9 name and parsed marker result. A migration parser should attach confidence/errors rather than silently normalizing ambiguous names.
7. **Prevent refresh from rewriting history.** Materialized views may expose current state, but historical facts must join to an effective-dated record or immutable snapshot.
8. **Reconcile snapshots.** Existing snapshots must be inventoried before retirement so historical reporting does not lose its only surviving classification evidence.

### Validation checklist

- [ ] Confirm the exact RB9 table and column names.
- [ ] Collect sanitized examples of each valid marker and spacing/casing variant.
- [ ] Define “internal employee,” “external employee,” “independent contractor,” active, and inactive as separate business concepts.
- [ ] Determine what an unmarked name means and whether multiple markers can appear together.
- [ ] Identify who can change the name, the operational procedure, and whether an audit trail exists anywhere.
- [ ] Identify all tables, views, materialized views, queries, apps, and reports that parse or depend on these markers.
- [ ] Locate every current snapshot process and record its owner, cadence, grain, storage, retention, and consumers.
- [ ] Determine whether RB9 has other Resource fields that partially duplicate worker classification or status.
- [ ] List the metrics affected and choose the correct “as of” date for each.
- [ ] Test both transitions: contractor → internal and internal → contractor.

### Discovery and communication record

| Date | Communicator | What was learned | Evidence state | Follow-up |
| --- | --- | --- | --- | --- |
| 2026-10-20 | Dustin Thomason | Resource names currently encode worker classification with a leading **#** for a current internal employee and trailing **(I)** for an independent contractor. Updating the live name changes database-wide/current-view output; no version history is known. Point-in-time snapshots are used to preserve historical reporting, and worker relationship can change in either direction. | Current SME report; live/schema evidence pending | Validate syntax and categories, inspect affected views/reports, and inventory snapshot processes. |

## Problem 2 — OJB uses the Jobs Notes Log as an activity ledger

### Distilled statement

RB9 does not provide OJB with a flexible, structured way to introduce a new operational task or record that somebody completed an activity. To close that gap, Planet Depos uses selected categories in the Jobs Notes Log as activity types. OJB pulls those rows and uses their metadata to answer questions such as:

- What operational activity happened?
- Which job did it happen on?
- Who performed or recorded it?
- When was it completed or last changed?

The method was quick to extend and gave Operations the visibility and metrics it needed, but it turned a large, flexible communication log into an undocumented activity/event system.

### Current data path

The exact physical object and column names must be confirmed from the schema and OJB definitions.

| Needed meaning | Reported source in Jobs Notes Log | Current interpretation | Validation needed |
| --- | --- | --- | --- |
| Job | Job association/key on the note row | Associates the activity with an RB9 job. | Exact key, joins, orphan behavior. |
| Activity type | Note category | Selected categories represent specific operational tasks or completions. | Complete category list, ids versus labels, retired/renamed categories, effective dates. |
| Performer | User/resource metadata associated with the note or modification | Used to report who did the work. | Whether this is author, last editor, assigned user, automation account, or true performer. |
| Completion time | Last-modified timestamp or related note timestamp | Used to report when the activity was completed/updated. | Whether later edits rewrite the apparent completion time; timezone and timestamp choice. |
| Details | Note text or other fields, where used | May carry context beyond the category. | Which fields OJB actually reads and whether any text parsing occurs. |
| Incremental cursor | Last-modified value | Selects new or changed rows for OJB updates. | Exact predicate, tie-breaker, overlap window, retry, deletion, and backfill behavior. |

### Activity types currently remembered

These are discovery leads, not a complete or verified vocabulary:

- checking in exhibits;
- finalizing a training — wording and exact business activity still need confirmation;
- additional categories introduced after the approach began.

The authoritative list must be derived from the current OJB app/flow/query definitions and reconciled with live category usage and business-owner confirmation.

### Why the workaround is risky

1. **A communication log became a task/event ledger.** The data shape was not designed to guarantee activity semantics.
2. **The activity vocabulary can grow informally.** A new category may become production behavior without entering a central contract or inventory.
3. **Attribution may be ambiguous.** The row author, last editor, automation identity, and actual performer may not be the same person.
4. **Modification time may not equal completion time.** A correction can potentially rewrite the time used by a metric.
5. **The source is extremely large.** It is known to contain millions of rows, but the present count and growth rate are not verified.
6. **Incremental correctness is unclear.** Last-modified polling needs deterministic ordering, overlap/replay behavior, and a tie-breaker.
7. **Historical meaning may drift.** Renaming or repurposing a category can change how older rows are interpreted unless the mapping is versioned.

### Future architecture obligations

1. **Create a first-class job activity model.** At minimum, preserve a stable activity id, job id, activity type, performed-by identity, performed-at time, recorded-by identity, recorded-at time, source, and source-row id.
2. **Separate execution from recording.** The person who did the work and the person/system that entered or edited the record must be independent fields.
3. **Separate completion from modification.** A later correction must not silently rewrite the original completion time.
4. **Make the activity vocabulary explicit and governed.** Activity types need stable identifiers, definitions, owners, lifecycle state, and mapping from legacy note categories.
5. **Retain legacy traceability.** Migrated activities should retain the original Jobs Notes Log row id and raw category/value needed for audit or reconciliation.
6. **Design for scale.** Consumers should read a bounded activity projection/API with appropriate indexes rather than repeatedly scanning the full notes log.
7. **Define incremental guarantees.** Use a deterministic cursor such as modified time plus a stable id, with documented overlap, retry, replay, deletion/correction, and backfill behavior.
8. **Reconcile counts and meaning.** Migration and ongoing sync need per-category count checks, late-arrival checks, and business validation.
9. **Preserve historical category meaning.** If category mappings change, reports must still interpret an older row using the mapping applicable to that row or migration decision.

### Discovery checklist

- [ ] Confirm the exact RB9/Lagrange table and physical column names.
- [ ] Extract every OJB query, flow, formula, dataset, or view that reads the Jobs Notes Log.
- [ ] Enumerate all selected category ids and labels from code/config, not memory.
- [ ] Compare selected categories with live row counts and recently used categories.
- [ ] Ask OJB business owners what activity each category represents and when it is considered complete.
- [ ] Confirm which field identifies the performer and what happens for automated/system-created notes.
- [ ] Confirm which timestamp is used and what happens when a note is edited later.
- [ ] Measure row count, growth rate, date range, indexes, query duration, and category distribution.
- [ ] Document the incremental predicate, cursor storage, tie-breaker, overlap, retry, and backfill behavior.
- [ ] Identify categories added after the original methodology and who approved/implemented them.
- [ ] Determine whether note text is parsed or whether category alone drives behavior.
- [ ] Test corrections, deleted/voided activities, duplicate notes, same-timestamp rows, and category renames.

### Discovery and communication record

| Date | Communicator | What was learned | Evidence state | Follow-up |
| --- | --- | --- | --- | --- |
| 2026-10-20 | Dustin Thomason | OJB uses selected Jobs Notes Log categories and row metadata to represent operational activities, identify who did work, and derive when it was completed/updated. The log is multi-million-row scale, exact count unknown, and additional categories likely accumulated after the original method was introduced. | Current SME report; live query/schema evidence pending | Inventory categories and fields from OJB, validate actor/time semantics, and measure the table. |

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
- Separate Resource display names from worker classification and preserve effective-dated relationship history.
- Require historical metrics to state which business date controls worker classification.
- Replace Jobs Notes Log category parsing with a governed, first-class job activity model while retaining legacy traceability.
- Distinguish activity performer/completion from row author/modification metadata.

## Source trail

- Jira STAR-2, supplied by Dustin Thomason on 2026-10-20.
- `pd-tech-wiki/catalog/systems-map.md`, reviewed 2026-10-20.
- `pd-tech-wiki/projects/atlas-workflows/kickoff.md`, kickoff dated 2026-10-14.
- `pd-tech-wiki/standards/data/rb9-replicated-timestamps.md`.
- `docs/power-platform-aws-investigation/`, prepared 2026-07-06 from internal notes and vendor documentation.
- Dustin Thomason's description of current Resource naming, history, snapshots, and reporting impact, 2026-10-20.
- Dustin Thomason's description of OJB use of the Jobs Notes Log for categorized activity tracking and metrics, 2026-10-20.

When a rule becomes stable cross-system knowledge, promote it to `pd-tech-wiki` with provenance and leave a link here. Do not maintain competing canonical versions.
