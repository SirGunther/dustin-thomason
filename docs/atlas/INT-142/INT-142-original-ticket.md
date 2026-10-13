# INT-142 - Original Ticket

## Capture Metadata

| Field | Value |
| --- | --- |
| Project | atlas |
| Ticket slug / ID | INT-142 |
| Title | Audit log - modify access |
| Link | https://pd-product-dev.atlassian.net/browse/INT-142 |
| Type | Story |
| Status | Ready For Work |
| Story points | 2 |
| Reporter | Shaye Lankford |
| Assignee | Dustin Thomason |
| Captured on | 2026-10-12 |
| Source | Jira read through its API by the Cerberus intake script on PDLP-D362HS3 |
| Formatting | Jira's rendered description converted to Markdown; the wording is unchanged |

## Original Request

As an Ops manager, I want to be able to review an audit log of key actions related to Client Access, so that I can see the "who, what, when" for these critical functions.

---

## Acceptance Criteria

- Ops can view a log in Europa for granting access
- The log displays the following details:
    - user info
    - date/time
    - **granting access** actions taken
        - exactly which deliverable types were granted
        - exactly which deliverable types were revoked
        - to whom the types were granted
- A new Event Type is created for this action: **CLIENT_ACCESS_UPDATED**
    - This event type is added to the Event Type drop down in Europa
- A new Resource Type for this action is created called: **Contact**
    - This new resource type is also added to the resource type dropdown
- Path format:
    - Case: [case]
    - Job: [job]
    - Proceeding: [proceeding]
    - Access granted: [list of deliverable types]
    - Access revoked: [list of deliverable types]

## Explicit Constraints In Original Request

The ticket states none apart from what is in the Original Request above.

## Context Paths In Original Request

- Original ticket: `C:\dustin-thomason\docs\atlas\INT-142\INT-142-original-ticket.md`
- Comments and updates: `C:\dustin-thomason\docs\atlas\INT-142\INT-142-comments.md`
- Ticket: <https://pd-product-dev.atlassian.net/browse/INT-142>
- parent INT-137: Audit Client Access Actions: <https://pd-product-dev.atlassian.net/browse/INT-137>
