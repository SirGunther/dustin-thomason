# Make Upload Manager count up instead of down - Original Ticket

## Capture Metadata

| Field | Value |
| --- | --- |
| Project | ClickUp |
| Ticket slug / ID | PRDV-14055 |
| Captured on | 2026-07-20 |
| Source | Active ClickUp browser page |
| Formatting | Browser DOM converted to Markdown |
| URL | https://app.clickup.com/t/43227262/PRDV-14055 |

## ClickUp Location

MBL LIST

## Ticket Metadata

| Field | Value |
| --- | --- |
| Status | READY FOR WORK |
| Dates | 4 days ago |
| Priority | Normal |
| Sprint points | 2 |
| Project Name | Atlas Maintenance |
| 💻 Issue type | Story |
| QA Acceptor Approved | QA Acceptor Approved |
| Technical Intake Reviewed | Technical Intake Reviewed |
| Tech Intake Request | Tech Intake Request |
| Owning Team | NASA |
| Stakeholder Impact | 3 |
| Primary Stakeholder | Ops |
| UI/UX Design Approved | UI/UX Design Approved |
| Intake Requested Date | 6 days ago |
| QA reviewed | QA reviewed |

## Omitted Fields

| Field | Reason |
| --- | --- |
| Assignees | No visible value in the active ClickUp page |
| Time estimate | No visible value in the active ClickUp page |
| Track time | No visible value in the active ClickUp page |
| Tags | No visible value in the active ClickUp page |
| Release Tag | No visible value in the active ClickUp page |
| Subject Matter Expert | No visible value in the active ClickUp page |
| Acceptor | No visible value in the active ClickUp page |
| Ranking | No visible value in the active ClickUp page |
| Closed Date | No visible value in the active ClickUp page |
| Forecast | No visible value in the active ClickUp page |
| Category | No visible value in the active ClickUp page |
| Components & Features | No visible value in the active ClickUp page |
| Modules | No visible value in the active ClickUp page |
| Root Cause | No visible value in the active ClickUp page |
| Start | No visible value in the active ClickUp page |
| PDemail | No visible value in the active ClickUp page |
| Reopen root cause | No visible value in the active ClickUp page |
| Project status update | No visible value in the active ClickUp page |
| Risk Status | No visible value in the active ClickUp page |
| IT Email | No visible value in the active ClickUp page |
| Helpdesk Ticket Number | No visible value in the active ClickUp page |

## Activity And Comments

_Visible ClickUp activity and comments captured from the active browser page. Attachments and embedded media are not retrieved._

- **Activity:** Shaye Lankford created this task Dec 11 2025 at 12:37 pm

- **Comment by Shaye Lankford** - Jul 7 at 9:34 am
  @Anastasiya Savchuk Can you confirm this is still up-to-date?

- **Activity:** Shaye Lankford checked Tech Intake Request Jul 14 at 9:33 am

- **Activity:** ClickBot (Automation #60 - When custom field changes, then change tags, and post comment, and set custom fi...) added tag pending arch review Jul 14 at 9:33 am

- **Comment by ClickBot (Automations)** - Jul 14 at 9:33 am
  @Larry Adams @Karl Amber FYA @Misha (mykhailo dobrilovskyi)
  
  This item is staged for development and pending Technical Intake review.
  
  **Technical Intake is complete when the Technical Intake Reviewed checkbox is checked, which automatically moves the item to Ready for Refinement.**
  
  Lead devs and DevOps are tagged to review architecture, non-functional requirements, and constraints, and to identify any follow-up needed before refinement.
  
  Thank you.

- **Comment by ClickBot (Automations)** - Jul 15 at 4:08 pm
  This PBI is Ready For Refinement

- **Activity:** Anastasiya Savchuk added Anastasiya Savchuk to Acceptor Jul 16 at 11:13 am

## Original Request

As an Ops Atlas User, I want the upload manager to have the number of uploading items to count up instead of down, so that it appears like the uploads are completing successfully and not being removed from the queue as it currently does.

## Acceptance Criteria:

**Notes:** There are two numbers in the upload manager progress message

- "First number" - the "3" in "Uploading 3 of 6"
- "Second number" - the "6" in "Uploading 3 of 6"

- Users see the number of completed and in progress uploads as the first number (instead of the number of remaining uploads as it currently is)
- The first number **counts up** to the total number of uploads in the current batch as each begins uploading and is completed
- The happy-path end state should have all files uploaded with both first and second numbers equal
- The second number continues to have the total number of uploads in the current batch

## Explicit Constraints In Original Request

- _Review the Original Request section above; constraints are preserved there when present._

## Context Paths In Original Request

- _Review the Original Request section above; paths and links are preserved there when present._

## Downstream Artifacts

- Investigation: Not created yet
- Spec: Not created yet
- Q and A ledger: Not created yet
