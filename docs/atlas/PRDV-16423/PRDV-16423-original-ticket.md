# Investigate and remediate high/critical security vulnerabilities - Original Ticket

## Capture Metadata

| Field | Value |
| --- | --- |
| Project | ClickUp |
| Ticket slug / ID | PRDV-16423 |
| Captured on | 2026-08-25 |
| Source | Active ClickUp browser page |
| Formatting | Browser DOM converted to Markdown |
| URL | https://app.clickup.com/t/43227262/PRDV-16423 |

## ClickUp Location

Product Development > Master Product Backlog > MBL LIST > Tasks shared with me

## Ticket Metadata

| Field | Value |
| --- | --- |
| Created | Jul 29 |
| Status | IN PROGRESS |
| Assignees | DT Dustin Thomason |
| Dates | Today |
| Priority | High |
| Sprint points | 7 |
| Tags | tech debt |
| Project Name | Atlas Maintenance |
| 💻 Issue type | Epic |
| QA Acceptor Approved | QA Acceptor Approved |
| Technical Intake Reviewed | Technical Intake Reviewed |
| Tech Intake Request | Tech Intake Request |
| Owning Team | NASA |
| Ranking | 2 |
| UI/UX Design Approved | UI/UX Design Approved |
| Intake Requested Date | 7/29/26 |
| QA reviewed | QA reviewed |

## Omitted Fields

| Field | Reason |
| --- | --- |
| Time estimate | No visible value in the active ClickUp page |
| Track time | No visible value in the active ClickUp page |
| Targeted Release | No visible value in the active ClickUp page |
| Release Tag | No visible value in the active ClickUp page |
| Product Goal | No visible value in the active ClickUp page |
| Subject Matter Expert | No visible value in the active ClickUp page |
| Acceptor | No visible value in the active ClickUp page |
| Stakeholder Impact | No visible value in the active ClickUp page |
| Primary Stakeholder | No visible value in the active ClickUp page |
| Closed Date | No visible value in the active ClickUp page |
| Forecast | No visible value in the active ClickUp page |
| Category | No visible value in the active ClickUp page |
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

- **Comment by Kat Giangiulio** - Jul 29 at 5:14 pm
  Engineer requested Technical Story for addressing high/critical dependency security vulnerabilities identified during security auditing. cc @Dustin Thomason @Larry Adams @Shaye Lankford

- **Comment by Kat Giangiulio** - Aug 12 at 3:56 pm
  @Dustin Thomason as a high priority Technical Story - engineers can self refine and point the work - would you be able to do that here ( you will be OOO on refinement day) ? cc @Larry Adams @Derrick Dieso

- **Comment by Kat Giangiulio** - Aug 13 at 12:44 pm
  @Larry Adams cc @Dustin Thomason Work restructured & sequenced - please confirm accuracy - Thanks cc @Xavier Messado

- **Comment by Kat Giangiulio** - Aug 18 at 9:21 pm
  @Larry Adams @Derrick Dieso @Dustin Thomason - is there value in pulling some of this work into S17 for Dustin - thanks

- **Comment by Kat Giangiulio** - Aug 19 at 2:40 pm
  @Dustin Thomason @Larry Adams @Derrick Dieso - it was mentioned in the teams daily scrum "all suggestions for work assignment are solid" @Dustin Thomason can you pull one of the subtasks in from this Epic - Please confirm if there are any hierarchal considerations - thanks

- **Activity:** You changed status from Ready For Work to In Progress 1 min

- **Activity:** ClickBot (Automation - When high priority in progress, set ranking to 2) set Ranking to 2 1 min

- **Activity:** ClickBot (Automation #65 - When status changed to multiple values, then change start date) set the start date to Today 1 min

## Original Request

Recent deployment attempts for Nova, Callisto, and Europa identified high-severity security vulnerabilities that are preventing deployment to AWS through the standard process.

Temporary overrides have been used to allow deployments to continue because the findings are high severity. This ticket tracks the remediation work separately from feature and functional changes so the security effort has clear visibility across all affected systems.

#### **Acceptance Criteria****AC' s can be found in each individual Technical Story - no work is implemented in Epics - Epics are the container of work**

- No high- or critical-severity security vulnerabilities remain for 2- Nova (2), 1-Callisto (3) , or 3-Europa (2)
- All three systems can be deployed to AWS through the standard deployment process without security-related exceptions.

## Explicit Constraints In Original Request

- _Review the Original Request section above; constraints are preserved there when present._

## Context Paths In Original Request

- _Review the Original Request section above; paths and links are preserved there when present._

## Downstream Artifacts

- Investigation: Not created yet
- Spec: Not created yet
- Q and A ledger: Not created yet
