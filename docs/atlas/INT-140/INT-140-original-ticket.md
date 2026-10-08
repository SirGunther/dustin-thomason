# INT-140 - Original Ticket

## Capture Metadata

| Field | Value |
| --- | --- |
| Project | atlas |
| Ticket slug / ID | INT-140 |
| Title | Audit log - create a proceeding (file navigator) |
| Link | https://pd-product-dev.atlassian.net/browse/INT-140 |
| Type | Story |
| Status | Ready For Work |
| Story points | 2 |
| Reporter | Shaye Lankford |
| Assignee | Dustin Thomason |
| Captured on | 2026-10-05 |
| Source | Jira read through its API by the Cerberus intake script on PDLP-D362HS3 |
| Formatting | Jira's rendered description converted to Markdown; the wording is unchanged |

## Original Request

As an Ops manager, I want to be able to review an audit log of key actions related to Client Access, so that I can see the "who, what, when" for these critical functions.

---

## Acceptance Criteria

- Ops can view a log in Europa for proceeding creation
- The log displays the following details:
    - user info
    - date/time
    - **File Navigator proceeding creation** action taken
- Event Type for this action is: **Created**
- The **Proceeding** Resource type is added to the Resource Type drop down in Europa
    - (this should already exist, it's just not visible)
- Path format:
    - Path: [path] (date/job ID/proceeding ID)
    - Proceeding Name: [proceeding name]

**Dev Note:**

Two endpoints exist for this.

**AJSF** - jobSubmissionService.createProceedings

**File Navigator** - proceedingsService.createProceedings (use this one for this ticket)

## Explicit Constraints In Original Request

The ticket states none apart from what is in the Original Request above.

## Context Paths In Original Request

- Original ticket: `C:\dustin-thomason\docs\atlas\INT-140\INT-140-original-ticket.md`
- Comments and updates: `C:\dustin-thomason\docs\atlas\INT-140\INT-140-comments.md`
- Ticket: <https://pd-product-dev.atlassian.net/browse/INT-140>
- parent INT-137: Audit Client Access Actions: <https://pd-product-dev.atlassian.net/browse/INT-137>
