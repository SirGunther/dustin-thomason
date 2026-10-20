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

Dustin is not expected to migrate the apps in STAR-2. His deliverable is the verified dependency and gap inventory, plus enough provenance that Megna and the migration team can trust it.

---

## Plans

| Added | Plan (path or link) | Status | One-line approach |
| --- | --- | --- | --- |
| 2026-10-20 | [STAR-2 Power Platform dependency inventory](STAR-2/STAR-2-power-platform-dependency-inventory.md) | active | Build the app universe, trace each live dependency chain, extract used RB9/Lagrange objects, map to Callisto, de-duplicate, and validate gaps. |
| 2026-10-20 | [RB9 rules](../rb9/rb9-rules.md) | active companion | Capture reusable RB9 behavior and workaround obligations discovered during STAR-2 before promoting stable facts to the shared wiki. |
| 2026-07-06 | [Power Platform to AWS investigation](../power-platform-aws-investigation/README.md) | prior research; revalidate | Use earlier OJB/ADB architecture, risks, and interview leads as evidence leads rather than current truth. |

---

## Session log

_Newest first._

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

## Current state (as of 2026-10-20)

- Ticket requirements are captured verbatim.
- The working inventory structure exists.
- Known candidate apps and OJB flow names are seeded as unverified leads.
- No live tenant export, app source, flow definition, Power BI metadata, Lagrange query, or Callisto mapping has yet been recorded in the STAR-2 artifact.
- No claim of inventory completeness has been made.
- Migration remains out of scope.

## Attempt history

None yet.
