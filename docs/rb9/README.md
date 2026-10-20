# RB9 Working Knowledge

Status: Working documentation  
Owner: Dustin Thomason  
Started: 2026-10-20

This folder is Dustin's working area for facts about how Planet Depos actually uses OMTI's ReporterBase 9 (RB9), especially behavior that future Atlas and Callisto architecture must preserve or intentionally replace.

This is the staging area before stable, cross-system knowledge is promoted to the shared `pd-tech-wiki`. It is not a substitute for the RB9 vendor manuals, the live Power Platform configuration, or database schemas.

## Contents

- [RB9 rules](rb9-rules.md): observed business rules, operating constraints, workarounds, oddities, conflicts, and future-architecture obligations.
- [STAR-2 changelog](../atlas/STAR-2-changelog.md): canonical working memory for the current Jira inventory ticket.
- [STAR-2 Power Platform dependency inventory](../atlas/STAR-2/STAR-2-power-platform-dependency-inventory.md): apps, flows, data sources, table/column mappings, gaps, evidence, and communications.
- [Power Platform to AWS investigation](../power-platform-aws-investigation/README.md): earlier ADB/OJB recovery and Lagrange connectivity research prepared in July 2026.

## Boundaries

- Record how RB9 is used, not just what the vendor says RB9 can do.
- Separate a confirmed fact from a report, inference, or open question.
- Cite the source and the date last verified.
- Never store credentials, connector secrets, private URLs, or personal access tokens.
- Keep ticket progress in the ticket changelog. Keep reusable RB9 knowledge in [RB9 rules](rb9-rules.md).
- Promote stable cross-system facts to `pd-tech-wiki`; link back to the promoted page rather than maintaining two canonical copies.
