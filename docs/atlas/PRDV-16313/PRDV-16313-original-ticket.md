# [BE] endpoint-file-renamed - Original Ticket

## Capture Metadata

| Field | Value |
| --- | --- |
| Project | ClickUp |
| Ticket slug / ID | PRDV-16313 |
| Captured on | 2026-08-11 |
| Source | Active ClickUp browser page |
| Formatting | Browser DOM converted to Markdown |
| URL | https://app.clickup.com/t/43227262/PRDV-16313 |

## ClickUp Location

Product Development > Master Product Backlog > MBL LIST

## Ticket Metadata

| Field | Value |
| --- | --- |
| Created | Jul 20 |
| Status | READY FOR WORK |
| Assignees | DT Dustin Thomason |
| Dates | Start Due |
| Priority | High |
| Sprint points | 2 |
| Project Name | Atlas Client Access |
| 💻 Issue type | Technical Story |
| QA Acceptor Approved | QA Acceptor Approved |
| Technical Intake Reviewed | Technical Intake Reviewed |
| Tech Intake Request | Tech Intake Request |
| Owning Team | NASA |
| UI/UX Design Approved | UI/UX Design Approved |
| QA reviewed | QA reviewed |

## Omitted Fields

| Field | Reason |
| --- | --- |
| Time estimate | No visible value in the active ClickUp page |
| Track time | No visible value in the active ClickUp page |
| Tags | No visible value in the active ClickUp page |
| Release Tag | No visible value in the active ClickUp page |
| Subject Matter Expert | No visible value in the active ClickUp page |
| Acceptor | No visible value in the active ClickUp page |
| Stakeholder Impact | No visible value in the active ClickUp page |
| Primary Stakeholder | No visible value in the active ClickUp page |
| Ranking | No visible value in the active ClickUp page |
| Closed Date | No visible value in the active ClickUp page |
| Forecast | No visible value in the active ClickUp page |
| Category | No visible value in the active ClickUp page |
| Intake Requested Date | No visible value in the active ClickUp page |
| Components & Features | No visible value in the active ClickUp page |
| Modules | No visible value in the active ClickUp page |
| Root Cause | No visible value in the active ClickUp page |
| Start | No visible value in the active ClickUp page |
| PDemail | No visible value in the active ClickUp page |
| Project status update | No visible value in the active ClickUp page |
| Risk Status | No visible value in the active ClickUp page |
| IT Email | No visible value in the active ClickUp page |
| Helpdesk Ticket Number | No visible value in the active ClickUp page |

## Activity And Comments

_Visible ClickUp activity and comments captured from the active browser page. Attachments and embedded media are not retrieved._

- **Activity:** Larry Adams created this task Jul 20 at 12:41 pm

- **Activity:** This task is unblocked by \[BE\] infra-outbox-dispatcher-foundation Aug 2 at 4:41 pm

- **Activity:** You assigned to: You Just now

- **Activity:** You added follower: You Just now

## Original Request

**Parent:** PRDV-15736 — Make Atlas metadata available to Planet Portal

**Prerequisites:**

- PRDV-16293 (outbox + dispatcher foundation) merged

## Summary

When an ops user renames a deliverable file via `PATCH /file/:fileId`, emit `callisto.client-access.file.renamed.v1`. Dione uses this to keep the displayed filename in sync with Callisto.

## Acceptance Criteria

- When `PATCH /file/:fileId` succeeds for a client deliverable file, an outbox row is written with routekey `callisto.client-access.file.renamed.v1`
- Payload matches `CallistoClientAccessFileRenamedV1Data`
- Only emitted for files that have the `CLIENT_DELIVERABLE` tag (non-deliverable file renames do not emit)
- Unit tests prove outbox write occurs with correct payload

## Wiki

`systems/neptune/callisto/granting-client-acess/emit-grant-events/PRDV-16313-endpoint-file-renamed.md`

Dev Note: RabbitMQ Config

## Explicit Constraints In Original Request

- _Review the Original Request section above; constraints are preserved there when present._

## Context Paths In Original Request

- _Review the Original Request section above; paths and links are preserved there when present._

## Downstream Artifacts

- Investigation: Not created yet
- Spec: Not created yet
- Q and A ledger: Not created yet
