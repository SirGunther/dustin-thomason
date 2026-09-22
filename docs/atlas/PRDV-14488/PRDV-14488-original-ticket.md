# AJSF Move users to top of next page on "Done" - Original Ticket

## Capture Metadata

| Field | Value |
| --- | --- |
| Project | ClickUp |
| Ticket slug / ID | PRDV-14488 |
| Captured on | 2026-09-16 |
| Source | Active ClickUp browser page |
| Formatting | Browser DOM converted to Markdown |
| URL | https://app.clickup.com/t/43227262/PRDV-14488 |

## ClickUp Location

MBL LIST

## Ticket Metadata

| Field | Value |
| --- | --- |
| Status | PRODUCT BACKLOG |
| Assignees | DT Dustin Thomason |
| Dates | Start Due |
| Priority | Normal |
| Sprint points | 1 |
| Tags | pending arch review |
| Stakeholder Impact | 3 |
| Primary Stakeholder | Lit Tech |
| Project Name | Atlas Maintenance |
| 💻 Issue type | Story |
| QA Acceptor Approved | QA Acceptor Approved |
| Technical Intake Reviewed | Technical Intake Reviewed |
| Tech Intake Request | Tech Intake Request |

## Omitted Fields

| Field | Reason |
| --- | --- |
| Time estimate | No visible value in the active ClickUp page |
| Track time | No visible value in the active ClickUp page |
| Scope Size | No visible value in the active ClickUp page |
| IT Email | No visible value in the active ClickUp page |
| Helpdesk Ticket Number | No visible value in the active ClickUp page |
| User Story ID | No visible value in the active ClickUp page |
| Custom ID | No visible value in the active ClickUp page |
| Targeted Release | No visible value in the active ClickUp page |
| Release Tag | No visible value in the active ClickUp page |
| Product Goal | No visible value in the active ClickUp page |

## Activity And Comments

_ClickUp activity and comments captured from the active browser page, including collapsed history and reply threads. Attachments and embedded media are not retrieved._

- **Activity:** Shaye Lankford created this task Jan 12 at 1:27 pm

- **Activity:** Shaye Lankford set 💻 Issue type to Story Jan 12 at 1:27 pm

- **Activity:** Shaye Lankford set Stakeholder Impact to 3 Jan 12 at 1:28 pm

- **Activity:** Shaye Lankford set Primary Stakeholder to Lit Tech Jan 12 at 1:28 pm

- **Activity:** Shaye Lankford set Project Name to Atlas Maintenance Jan 14 at 2:02 pm

- **Activity:** Shaye Lankford set priority to Low Jan 14 at 2:02 pm

- **Activity:** Kat Giangiulio also added task to MBL LIST Mar 19 at 8:37 am

- **Activity:** Kat Giangiulio also added task to (DELETED) Mar 19 at 8:38 am

- **Activity:** Kat Giangiulio set Owning Team to NASA Mar 26 at 3:31 pm

- **Activity:** Rollover task was updated Apr 20 at 6:47 pm

- **Activity:** Rollover task was updated Apr 21 at 1:09 pm

- **Activity:** Shaye Lankford also added task to Atlas Product Backlog Apr 21 at 3:16 pm

- **Activity:** Shaye Lankford changed the home List from Atlas Product Backlog to MBL LIST Apr 21 at 3:16 pm

- **Activity:** Shaye Lankford removed task from MBL LIST Apr 21 at 3:16 pm

- **Activity:** Shaye Lankford added Atlas Job Submission Form (AJSF) to Modules Jul 8 at 9:42 am

- **Comment by Shaye Lankford** - Sep 11 at 11:37 am
  [Attachment omitted]
  - _1 attachment/media item(s) omitted._

- **Activity:** You assigned to: You Sep 11 at 11:59 am

- **Activity:** You added follower: You Sep 11 at 11:59 am

- **Activity:** You changed Sprint Points to 1 for You Sep 11 at 11:59 am

- **Activity:** Shaye Lankford checked Tech Intake Request 2 hours ago

- **Activity:** ClickBot (Automation #60 - When custom field changes, then change tags, and post comment, and set custom fi...) added tag pending arch review 2 hours ago

- **Comment by ClickBot (Automations)** - 2 hours ago
  @Larry Adams @Karl Amber FYA @Misha (mykhailo dobrilovskyi)
  
  This item is staged for development and pending Technical Intake review.
  
  **Technical Intake is complete when the Technical Intake Reviewed checkbox is checked, which automatically moves the item to Ready for Refinement.**
  
  Lead devs and DevOps are tagged to review architecture, non-functional requirements, and constraints, and to identify any follow-up needed before refinement.
  
  Thank you.

- **Activity:** ClickBot (Automation #60 - When custom field changes, then change tags, and post comment, and set custom fi...) set Intake Requested Date to Today 2 hours ago

- **Activity:** Shaye Lankford changed priority from Low to Normal 2 hours ago

## Original Request

# Incident Report

### Observed behavior

- When a user completes a section of the AJSF form and clicks the "Done" button, the application navigates to the next page but positions the viewport at the very bottom of that page.
- This forces the user to manually scroll back up to the top every time they move to a new section to begin their work, creating friction in the workflow.

### Expected behavior

**Simple Solution (Always Scroll to Top)**

- Upon clicking "Done," the application should automatically position the user at the very top of the subsequent page regardless of whether they have visited that page before.

### User Story

An Ops Atlas user doesn’t want to have to manually scroll to find where they left off. While moving from one section of the AJSF form to another, they want to see the start of the next section immediately. Except that the content remains at the bottom of the new page when navigating, so they want to land at the top of the new section page. Now they’ll be able to continue their work without manual adjustments.

### Acceptance Criteria

- The "Done" action triggers a transition to the next form section.
- The content automatically moves to the top of the new section.
- The user can see the start of the new section immediately upon completion of the previous one.

## Dev Notes

## Explicit Constraints In Original Request

- _Review the Original Request section above; constraints are preserved there when present._

## Context Paths In Original Request

- _Review the Original Request section above; paths and links are preserved there when present._

## Downstream Artifacts

- Investigation: Not created yet
- Spec: Not created yet
- Q and A ledger: Not created yet
