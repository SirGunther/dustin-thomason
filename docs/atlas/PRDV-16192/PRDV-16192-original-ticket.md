# Europa permission change improvements - Original Ticket

## Capture Metadata

| Field | Value |
| --- | --- |
| Project | ClickUp |
| Ticket slug / ID | PRDV-16192 |
| Captured on | 2026-07-27 |
| Source | Active ClickUp browser page |
| Formatting | Browser DOM converted to Markdown |
| URL | https://app.clickup.com/t/43227262/PRDV-16192 |

## ClickUp Location

MBL LIST > Product Development

## Ticket Metadata

| Field | Value |
| --- | --- |
| Status | READY FOR WORK |
| Assignees | SP DT |
| Dates | Start Due |
| Priority | Low |
| Sprint points | 5 |
| Tags | sprint addition |
| Project Name | Atlas Maintenance |
| 💻 Issue type | Story |
| QA Acceptor Approved | QA Acceptor Approved |
| Technical Intake Reviewed | Technical Intake Reviewed |
| Tech Intake Request | Tech Intake Request |
| Owning Team | NASA |
| Primary Stakeholder | IT |
| UI/UX Design Approved | UI/UX Design Approved |
| QA reviewed | QA reviewed |

## Omitted Fields

| Field | Reason |
| --- | --- |
| Time estimate | No visible value in the active ClickUp page |
| Track time | No visible value in the active ClickUp page |
| Release Tag | No visible value in the active ClickUp page |
| Subject Matter Expert | No visible value in the active ClickUp page |
| Acceptor | No visible value in the active ClickUp page |
| Stakeholder Impact | No visible value in the active ClickUp page |
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
| Reopen root cause | No visible value in the active ClickUp page |
| Project status update | No visible value in the active ClickUp page |
| Risk Status | No visible value in the active ClickUp page |
| Days in progress Formula | No visible value in the active ClickUp page |
| Custom ID | No visible value in the active ClickUp page |
| IT Email | No visible value in the active ClickUp page |
| Helpdesk Ticket Number | No visible value in the active ClickUp page |

## Activity And Comments

_Visible ClickUp activity and comments captured from the active browser page. Attachments and embedded media are not retrieved._

- **Comment by Anastasiya Savchuk** - Jul 2 at 5:13 am
  FYI @Shaye Lankford @Larry Adams this was created as future improvement to [[BE] Publish permission change to Europa and Permissions page updatedeployed to prodS](https://app.clickup.com/t/43227262/PRDV-15840)

- **Activity:** ClickBot (Automation #59 - When custom field changes, then change status, and post comment, and change tags) changed status from Product Backlog to Ready For Refinement Jul 2 at 10:14 am

- **Comment by ClickBot (Automations)** - Jul 2 at 10:14 am
  This PBI is Ready For Refinement

- **Comment by Kat Giangiulio** - Jul 16 at 11:35 am
  The solution may need to be discussed with IT @Anastasiya Savchuk @Shaye Lankford cc @Larry Adams

- **Comment by Kat Giangiulio** - Jul 21 at 8:39 pm
  @Larry Adams this is unassigned in the active Sprint 15 - another option for assigning

- **Comment by Kat Giangiulio** - 1:51 pm
  The team identified this as sprint addition - assigned to @Dustin Thomason & @Svitlana Pshenychna to co-engineer until Lana is out of PTO July 3 through August 3 - cc @Larry Adams

## Original Request

## Description:

1. ****Path column**** doesn't clearly show old/new permission state per resource key (behavior was described in dev notes but never formally AC'd).

2. ****No resource key indicator**** — when multiple resource keys change in one save (e.g., transcript track + video track), the audit entry doesn't tell you ** which** resource key changed. The `resourceName` is set to the role name, not the resource key.

3. ****Empty state on full removal**** — when all CRUD permissions are removed from a resource key, `newState.path` is empty string, which renders as blank in Europa. UX-wise it should say something meaningful.

## QA Notes:

- PERMISSIONS_UPDATED event Path column shows correct old and new permission state for each changed resource key

There is no explicit AC that states this. It comes entirely from the dev notes:

From the event shape example in the dev notes:

- `"oldState": { "path": "read" }` and `"newState": { "path": "read, update, delete" }`

And from the field descriptions:

- `"oldState.path = comma-separated actions the resource key had before this save"` and `"newState.path = comma-separated actions the resource key has after this save"`

This is exactly the pattern the AC review prompt is designed to catch — the story has almost no user-facing ACs at all. The entire testable behaviour is described in the dev notes and design decisions section, not in formal ACs. The "Goals" section mentions `"oldState / newState as human-readable action lists (e.g. "read" → "read, update, delete")"` which is the closest thing to an AC, but it's written as a technical goal, not a user-facing acceptance criterion.

2. there is no indicator of what exact module permissions was updated. If you added some permissions to transcript track and video track - you still see this: I would recommend adding some info about changed module or *Changing multiple resource keys in one save produces one PERMISSIONS_UPDATED event with one entry per changed resource key*

3. When removing all CRUD there is no info - from UX perspective it is better to say something like 'removed create-read'

## Dev Note:

## Explicit Constraints In Original Request

- None stated as a constraint in the Description / QA Notes text. The request states three defects and, for item 3, a directional UX preference only ("from UX perspective it is better to say something like 'removed create-read'") — wording is illustrative, not mandated.
- Item 2 offers two alternative directions in the request's own words: "adding some info about changed module" **or** "Changing multiple resource keys in one save produces one PERMISSIONS_UPDATED event with one entry per changed resource key". The request does not pick between them.
- Recorded from Activity (not the Description): "The solution may need to be discussed with IT" — Kat Giangiulio, Jul 16.

## Context Paths In Original Request

- No file paths or repository references appear in the Description / QA Notes.
- Named identifiers appearing in the request text: `PERMISSIONS_UPDATED` event, `resourceName`, `oldState.path`, `newState.path`, Path column, resource key.
- Related ticket link captured under Activity And Comments: [PRDV-15840 — [BE] Publish permission change to Europa and Permissions page update](https://app.clickup.com/t/43227262/PRDV-15840) (stated origin of this improvement ticket).

## Capture Gaps

_Factual gaps in this capture — to be closed in Phase 1, not filled by inference._

| Gap | What was captured | Why it matters |
| --- | --- | --- |
| `## Dev Note:` | Heading present in the captured Description with no body text beneath it. | The QA Notes state the entire testable behaviour "comes entirely from the dev notes" and quote the event shape (`"oldState": { "path": "read" }`) from them. Whether those dev notes live on this ticket or on PRDV-15840 is unresolved. |

## Downstream Artifacts

- Orchestration ledger: [`orchestration.md`](./orchestration.md)
- Changelog: [`docs/atlas/PRDV-16192-changelog.md`](../PRDV-16192-changelog.md)
- Why these changes: [`PRDV-16192-why-these-changes.md`](./PRDV-16192-why-these-changes.md)
- Investigation report: [`investigations/PRDV-16192-investigation.md`](./investigations/PRDV-16192-investigation.md)
- Coverage ledger: [`investigations/PRDV-16192-coverage-ledger.md`](./investigations/PRDV-16192-coverage-ledger.md)
- Diagrams: [`investigations/PRDV-16192-diagrams.md`](./investigations/PRDV-16192-diagrams.md)
- Test plan: [`testing/PRDV-16192-test-plan.md`](./testing/PRDV-16192-test-plan.md) (seeded)
- Future-development concerns: [`PRDV-16192-future-development-concerns.md`](./PRDV-16192-future-development-concerns.md)
- PR draft: [`PRDV-16192-pr-draft.md`](./PRDV-16192-pr-draft.md) (unfilled shell)
- Spec: Not created yet (Phase 3)
- Q and A / locked-decision ledger: Not created yet (Phase 3)

### Capture gap resolution

The `Dev Note:` gap recorded above was **closed by code evidence** during Phase 1: the behaviour the QA Notes attribute to the dev notes (`oldState.path` = comma-separated prior actions, `newState.path` = comma-separated resulting actions) matches the shipped emitter exactly (`callisto-back-end .../permissions-to-audit-event.assembler.ts:22-23`). The missing body is informational only; no requirement was lost.
