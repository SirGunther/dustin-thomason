# [BE] endpoint-upload-complete-file-created - Original Ticket

## Capture Metadata

| Field | Value |
| --- | --- |
| Project | ClickUp |
| Ticket slug / ID | PRDV-16312 |
| Captured on | 2026-08-05 |
| Source | Active ClickUp browser page |
| Formatting | Browser DOM converted to Markdown |
| URL | https://app.clickup.com/t/43227262/PRDV-16312 |

## ClickUp Location

MBL LIST > Sprint 2026-16 (8/5-8/18)

## Ticket Metadata

| Field | Value |
| --- | --- |
| Status | IN PROGRESS |
| Assignees | DT Dustin Thomason |
| Dates | Today |
| Priority | High |
| Sprint points | 3 |

## Omitted Fields

| Field | Reason |
| --- | --- |
| Time estimate | No visible value in the active ClickUp page |
| Track time | No visible value in the active ClickUp page |
| Tags | No visible value in the active ClickUp page |

## Activity And Comments

_Visible ClickUp activity and comments captured from the active browser page. Attachments and embedded media are not retrieved._

- **Activity:** Larry Adams created this task Jul 20 at 12:40 pm

- **Activity:** ClickBot (Automation #18 - When status changed to undefined, then change start date) set the start date to Today 9:34 am

## Original Request

**Parent:** PRDV-15736 — Make Atlas metadata available to Planet Portal

**Prerequisites:**

- PRDV-16293 (outbox + dispatcher foundation) merged

## Summary

When a file is uploaded directly into client deliverables via `POST /upload-complete`, emit:

- `callisto.client-access.collection.created.v1` — if a new dynamic collection was created (find-or-create returns a new row)
- `callisto.client-access.file.created.v1` — always, representing the new deliverable file

This gives Dione the data it needs to display the file under the correct track → collection → deliverable type hierarchy.

## Acceptance Criteria

- When `POST /upload-complete` succeeds for a client deliverable file, an outbox row is written with routekey `callisto.client-access.file.created.v1`
- Payload matches `CallistoClientAccessFileCreatedV1Data`
- If a new dynamic collection was created during the flow, an additional outbox row is written with routekey `callisto.client-access.collection.created.v1`
- If the dynamic collection already existed (find-or-create returned existing), no `collection.created.v1` event is emitted
- Unit tests on the transaction script prove both outbox writes occur in the 2-event case
- Messages visible in the dev RabbitMQ queue

## Wiki

`systems/neptune/callisto/granting-client-acess/emit-grant-events/PRDV-16312-endpoint-upload-complete-file-created.md`

Dev Note: RabbitMQ Config

## Explicit Constraints In Original Request

- _Review the Original Request section above; constraints are preserved there when present._

## Context Paths In Original Request

- _Review the Original Request section above; paths and links are preserved there when present._

## Downstream Artifacts

- Investigation: Not created yet
- Spec: Not created yet
- Q and A ledger: Not created yet
