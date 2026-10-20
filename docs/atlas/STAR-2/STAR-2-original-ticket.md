# STAR-2 — Inventory OJB and the Lagrange tables/columns they use — Original Ticket

## Capture metadata

| Field | Value |
| --- | --- |
| System | Jira |
| Ticket | STAR-2 |
| Captured on | 2026-10-20 |
| Source | Ticket text supplied directly by Dustin Thomason |
| URL | https://pd-product-dev.atlassian.net/browse/STAR-2 |
| Formatting | Headings and lists normalized to Markdown; wording preserved |

## Description

### User Story

As a member of the Starfleet team replacing RB9, I want a complete inventory of the Power Apps and the database tables and columns they depend on, so that we know exactly what data must be brought into Callisto for the read replica and can plan the Lagrange-to-Callisto migration without pulling unnecessary data.

### Background

RB9 is being replaced; Callisto becomes the long-term source of truth and a Callisto read replica will replace direct RB9/Lagrange connections for reporting users and Power Apps.

Power Apps currently read from RB9/Lagrange (Pascal-case names). Some were built by Dustin, some by Jamie, and some by LitTech, so no single complete list exists.

Users should only have to retool once, so all required data must be in Callisto before cutover.

### Requirements

**Inventory of Power Apps**

Identify every Power App that reads from RB9 or Lagrange, including those built by LitTech.

For each app record: name, owner/builder, business purpose and users, and data source(s) and connection type.

**Inventory of tables and columns in use**

For each Power App, list every table and column it uses (read and write) in RB9/Lagrange.

Note whether each table/column already exists in Callisto, and the Callisto equivalent where it does.

Consolidate into a single de-duplicated list of tables and columns.

### Acceptance Criteria

A documented list of all known Power Apps with owner, purpose, and data source.

Each Power App is mapped to the tables and columns it uses.

A consolidated table/column inventory exists, with an old (Lagrange) to new (Callisto) mapping and a flag for items not yet in Callisto.

Gaps and unknowns (e.g. apps with no identified owner) are listed explicitly.

The inventory is stored in Confluence (or linked from this ticket) and shared with Megna so she can plan the Lagrange-to-Callisto data work.

### Notes

Dependencies: RB9/Lagrange database access, and input from Dustin and Jamie, who know where the Power Apps live.

Out of scope: migrating the Power Apps or moving data into Callisto.

## Downstream artifacts

- [Ticket changelog](../STAR-2-changelog.md)
- [Power Platform dependency inventory](STAR-2-power-platform-dependency-inventory.md)
- [RB9 rules](../../rb9/rb9-rules.md)
