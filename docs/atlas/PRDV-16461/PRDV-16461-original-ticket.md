# Default collections for client deliverables - Original Ticket

## Capture Metadata

| Field | Value |
| --- | --- |
| Project | ClickUp |
| Ticket slug / ID | PRDV-16461 |
| Captured on | 2026-09-02 |
| Source | Active ClickUp browser page |
| Formatting | Browser DOM converted to Markdown |
| URL | https://app.clickup.com/t/43227262/PRDV-16461 |

## ClickUp Location

Product Development > Master Product Backlog > MBL LIST

## Ticket Metadata

| Field | Value |
| --- | --- |
| Created | Aug 3 |
| Status | IN PROGRESS |
| Assignees | DT Dustin Thomason |
| Dates | Today |
| Priority | High |
| Sprint points | 3 |
| Project Name | Atlas Client Access |
| 💻 Issue type | Story |
| QA Acceptor Approved | QA Acceptor Approved |
| Technical Intake Reviewed | Technical Intake Reviewed |
| Tech Intake Request | Tech Intake Request |
| Product Goal | 1 |
| Owning Team | NASA |
| Primary Stakeholder | Product |
| Ranking | 2 |
| UI/UX Design Approved | UI/UX Design Approved |
| Intake Requested Date | 8/18/26 |
| Modules | Atlas Deliverable Type Manager |
| QA reviewed | QA reviewed |

## Omitted Fields

| Field | Reason |
| --- | --- |
| Time estimate | No visible value in the active ClickUp page |
| Track time | No visible value in the active ClickUp page |
| Tags | No visible value in the active ClickUp page |
| Targeted Release | No visible value in the active ClickUp page |
| Release Tag | No visible value in the active ClickUp page |
| Subject Matter Expert | No visible value in the active ClickUp page |
| Acceptor | No visible value in the active ClickUp page |
| Stakeholder Impact | No visible value in the active ClickUp page |
| Closed Date | No visible value in the active ClickUp page |
| Forecast | No visible value in the active ClickUp page |
| Category | No visible value in the active ClickUp page |
| Components & Features | No visible value in the active ClickUp page |
| Root Cause | No visible value in the active ClickUp page |
| Start | No visible value in the active ClickUp page |
| PDemail | No visible value in the active ClickUp page |
| Project status update | No visible value in the active ClickUp page |
| Risk Status | No visible value in the active ClickUp page |
| Days in progress Formula | No visible value in the active ClickUp page |
| Custom ID | No visible value in the active ClickUp page |
| IT Email | No visible value in the active ClickUp page |
| Helpdesk Ticket Number | No visible value in the active ClickUp page |

## Activity And Comments

_ClickUp activity and comments captured from the active browser page, including collapsed history and reply threads. Attachments and embedded media are not retrieved._

- **Activity:** Shaye Lankford created this task Aug 3 at 1:33 pm

- **Activity:** Shaye Lankford set 💻 Issue type to Story Aug 3 at 1:33 pm

- **Activity:** Shaye Lankford set Project Name to Atlas Client Access Aug 3 at 1:33 pm

- **Activity:** Shaye Lankford set Product Goal to 1 Aug 3 at 1:33 pm

- **Activity:** Shaye Lankford set priority to Normal Aug 3 at 1:33 pm

- **Activity:** Shaye Lankford changed name: Default collections for client deliverable uploads Aug 3 at 1:35 pm

- **Comment by Shaye Lankford** - Aug 3 at 1:38 pm
  @Anastasiya Savchuk Can you take a look at these AC for any questions?

- **Activity:** Shaye Lankford set Owning Team to NASA Aug 3 at 1:39 pm

- **Activity:** Shaye Lankford set Primary Stakeholder to Product Aug 3 at 1:39 pm

- **Comment by Anastasiya Savchuk** - Aug 5 at 8:06 am
  @Shaye Lankford I don`t entirely understand the steps for this flow. We have a mapping for collections that should be triggered automatically, does this one cover the files that do not have a match with auto set collection?

  - **Comment by Shaye Lankford** - Aug 17 at 3:18 pm
    @Anastasiya Savchuk, thanks - I updated the AC. Do they make more sense now? This may have changed, but last I checked the AC from this ticket was not the current behavior.

- **Activity:** Shaye Lankford changed Product Goal from 1 to 2.5 Aug 17 at 10:47 am

- **Comment by Anastasiya Savchuk** - Aug 18 at 11:02 am
  @Shaye Lankford I have some questions, they are rather nice to have than a blocker. Could you answer when haev some time?
  
  QUESTION 1
  
  AC2 names 3 entry points (drag-and-drop, direct upload, approval from submission files) that open the DTM. Recategorize also opens the same DTM and can show a blank collection today . Does the new default also apply there?
  
  **a)** Default applies to Recategorize too, same as the 3 listed flows (recommended — existing deliverable-* type* pre-fill already applies uniformly across upload/approval/recategorize per PDN-1378, so a collection default that skips Recategorize would be an odd asymmetry)
  
  **b)** Recategorize is deliberately excluded — blank collections there stay manual
  
  QUESTION 2
  
  Deliverable-*type* pre-fill (already done) only evaluates once a collection is selected in the DTM. Every existing pre-fill test selects the collection manually first. Once collection selection itself defaults, does type pre-fill now fire automatically on DTM open (no user click at all) for Transcript/Video?
  
   **a) Yes**— collection default + existing type pre-fill compose, so DTM opens fully pre-filled for base-case files (recommended — this is the natural consequence of AC1, and is the actual time-saving value the story's "so that" clause describes)
  
   **b) No** — collection defaults, but type pre-fill still requires the user to first interact with the collection field
  
  QUESTION 3
  
  AC says users can override the default "when necessary" but doesn't say whether the override sticks. If a user picks "Redacted" for one file, does the *next* DTM open (new upload/approval) still default to "Full Transcript", or does it remember the last choice for that track/proceeding?
  
   a) Always re-defaults to the fixed base-case collection on every DTM open — override is a one-time, per-session choice (recommended — nothing else in the DTM persists a user's track/collection choice across separate open/close cycles;
  
   b) Last-used collection is remembered per track for the proceeding

  - **Comment by Shaye Lankford** - Aug 18 at 12:23 pm
    @Anastasiya Savchuk Great questions!
    
    Question 1
    
    C*) For recategorize, the track/collection should **not** change by default. Whatever existing track/collection should remain unless manually changed by the user.
    
    added to the AC.
    
    Question 2
    
    A) Yes, collection default + existing type pre-fill compose, so DTM opens fully pre-filled for base-case files (recommended — this is the natural consequence of AC1, and is the actual time-saving value the story's "so that" clause describes)
    
    added to the AC.
    
    Question 3
    
    A) Always re-defaults to the fixed base-case collection on every DTM open — override is a one-time, per-session choice (recommended — nothing else in the DTM persists a user's track/collection choice across separate open/close cycles;
    
    added to the AC.

- **Activity:** Shaye Lankford checked Tech Intake Request Aug 18 at 12:30 pm

- **Activity:** ClickBot (Automation #60 - When custom field changes, then change tags, and post comment, and set custom fi...) added tag pending arch review Aug 18 at 12:30 pm

- **Comment by ClickBot (Automations)** - Aug 18 at 12:30 pm
  @Larry Adams @Karl Amber FYA @Misha (mykhailo dobrilovskyi)
  
  This item is staged for development and pending Technical Intake review.
  
  **Technical Intake is complete when the Technical Intake Reviewed checkbox is checked, which automatically moves the item to Ready for Refinement.**
  
  Lead devs and DevOps are tagged to review architecture, non-functional requirements, and constraints, and to identify any follow-up needed before refinement.
  
  Thank you.

- **Activity:** ClickBot (Automation #60 - When custom field changes, then change tags, and post comment, and set custom fi...) set Intake Requested Date to 8/18/26 Aug 18 at 12:30 pm

- **Activity:** Shaye Lankford changed Product Goal from 2.5 to 1 Aug 18 at 2:23 pm

- **Activity:** Shaye Lankford added Atlas Deliverable Type Manager to Modules Aug 18 at 2:24 pm

- **Activity:** Shaye Lankford changed priority from Normal to High Aug 18 at 2:30 pm

- **Comment by Kat Giangiulio** - Aug 20 at 11:00 am
  SoS shed some additional light on the Product request to Engineering to fast-track this work through Intake. @Shaye Lankford , can you please provide the current delivery expectation or targeted release date, if one has been established?
  
  I’d like to make sure the work and any associated impact to the existing commitments are accurately reflected in our planning and reporting. Thank you
  
  cc @Jim Valentine @Alexander Godziela @Derrick Dieso

  - **Comment by Shaye Lankford** - Aug 20 at 4:40 pm
    Sure thing! It would be considered a win, but **not a requirement** to have this as part of the "9/30" body of work. Thanks!

- **Activity:** Derrick Dieso removed tag pending arch review Aug 20 at 11:35 am

- **Activity:** Derrick Dieso checked Technical Intake Reviewed Aug 20 at 11:35 am

- **Activity:** ClickBot (Automation #59 - When custom field changes, then change status, and post comment, and change tags) changed status from Product Backlog to Ready For Refinement Aug 20 at 11:35 am

- **Comment by ClickBot (Automations)** - Aug 20 at 11:35 am
  This PBI is Ready For Refinement

- **Comment by Shaye Lankford** - Aug 20 at 4:34 pm
  Hey @Derrick Dieso - I noticed the AC for this one were overwritten. Was that intentional or did the agent just get a little trigger happy?
  
  My concerns are just that if it's intentional (and desired going forward), I'd have to read and compare all of the new AC with the old to sign off on them and ensure that everything is accounted for.

- **Comment by Derrick Dieso** - Aug 21 at 8:53 am
  Hey @Shaye Lankford yeah I was refining some of the ACs during intake but noted for workflow. Might need to focus on additive changes such that things don't get lost

- **Comment by Kat Giangiulio** - Aug 21 at 9:01 am
  From a workflow/visibility perspective, additive changes make sense to me as well.
  
  We already have the**practice of QA highlighting questions in the ACs for Product consideration,** so ** retaining the original Product ACs and making Engineering/QA additions or questions visible** would preserve the original intent while giving us a clear trail of what still needs Product review/clarification, can we carry that practice forward as part of the established workflow @Derrick Dieso cc @Shaye Lankford fya @Anastasiya Savchuk

- **Comment by Kat Giangiulio** - Aug 27 at 11:09 am
  @Dustin Thomason please describe the user behavior you were questionig cc @Shaye Lankford

  - **Comment by Dustin Thomason** - Aug 27 at 11:12 am
    UI/UX consideration, the collections will show automatically which will be useful, the simple quality of life idea here is someway notating that the collection was chosen for them. I've seen this before as a '*' or '(default)' in the drop down or similar so that the user is aware that this is something that can be adjusted and has been predetermined for them. Basically a heads up is all.

  - **Comment by Kat Giangiulio** - Aug 27 at 3:11 pm
    fresh thread for @Shaye Lankford
    
    [Attachment omitted]
    - _1 attachment/media item(s) omitted._

  - **Comment by Kat Giangiulio** - Aug 27 at 3:12 pm
    tagged pending product feedback

  - **Comment by Shaye Lankford** - Yesterday at 12:21 pm
    @Dustin Thomason - I agree, do you have a suggestion for how you'd prefer to handle this.

- **Activity:** Kat Giangiulio changed status from Ready For Refinement to Ready For Work Aug 27 at 11:10 am

- **Activity:** Kat Giangiulio changed Sprint Points to 3 Aug 27 at 11:11 am

- **Activity:** Kat Giangiulio added tag pending product feedback Aug 27 at 3:12 pm

- **Activity:** Kat Giangiulio removed tag pending product feedback Yesterday at 2:10 pm

- **Activity:** Kat Giangiulio assigned to: You Yesterday at 2:10 pm

- **Activity:** Kat Giangiulio added follower: You Yesterday at 2:10 pm

- **Activity:** Kat Giangiulio also added task to Sprint 2026-18 (9/2-9/15) Yesterday at 2:10 pm

- **Activity:** You changed status from Ready For Work to In Progress 2 hours ago

- **Activity:** ClickBot (Automation - When high priority in progress, set ranking to 2) set Ranking to 2 2 hours ago

- **Activity:** ClickBot (Automation #18 - When status changed to undefined, then change start date) set the start date to Today 2 hours ago

## Original Request

As an Ops Atlas user, I want there to be default collections for files added to the client deliverables file set, so that I don't have to manually set collections for the most common, base-case workflows.

## Acceptance Criteria

### Default collection behavior

- When adding files to the Client Deliverables file set (GCA-enabled flow only), the collection selector in the upload/approve modal is **pre-selected** to the base-case collection for the file's track:
- **Transcript Track** → default collection ** Full Transcript**
- **Video Track** → default collection ** MP4 Video**
- The default is always the **static** base-case collection — never a dynamic collection (Excerpt / Trial Edit).
- **Exhibits** and ** MVC** tracks are unaffected — no collection selector exists for them today, and they continue to resolve to no collection.
- Users can **manually override** the pre-selected default in the modal before submitting.

### Where the default is defined

- Defaults are defined as a **front-end track → default-collection mapping** (Option A). No backend or Deliverable Type Manager configuration is in scope for this ticket.
- The mapping matches the collection by its known value; if a matching collection is **not present** for a track in a given proceeding/environment, the modal falls back to the ** current behavior** (no pre-selected collection) and must not error.

### Paths where the default applies ("File Additions")

- **Drag-and-drop uploads:** because the track is chosen inside the modal, the default collection auto-populates ** reactively once the user selects a track** in the DnD modal.
- **Direct uploads** (per-track Upload button): track is locked to the clicked track; the default collection is pre-selected on modal open.
- **File approvals** (approving submission files into deliverables): track is locked to the submission's track; the default collection is pre-selected on modal open.

### Reset semantics

- The default is applied to **every new file-add action** — it is ** not sticky** to a user's previous choice. Reopening the modal (a new add/approve action) always re-applies the base-case default rather than remembering the last-used collection.
- "Session" here means a single modal-open / add action; there is no cross-session persistence of a user's last-selected collection.

### Recategorize (guardrail — no change to current behavior)

- Recategorize does **not** apply these defaults. Each file's existing track/collection is preserved and remains unchanged unless the user manually changes it in the recategorize modal.

### Deliverable type pre-fill

- Deliverable-type pre-fill continues to run against the **defaulted collection's** eligible-types catalog, so that both the collection and the deliverable type are effectively pre-filled when the collection defaults.
- When no auto-match rule matches a file (e.g. filename/extension doesn't match a rule for that collection), the deliverable type is left **blank** for the user to select manually — this is expected, not an error.
- Pre-fill re-evaluates if the user changes the collection away from the default (existing behavior).

### Scope

- GCA-enabled flow only. Non-GCA upload/approve paths (which send no collection) are **out of scope** and unchanged.

## Open items to confirm before/at dev

- Verify **"Full Transcript"** and **"MP4 Video"** are the exact production static-collection values on the Transcript and Video tracks (they currently appear only in test fixtures on the FE side).
- Confirm those base-case collections have eligible deliverable types configured, so type pre-fill actually resolves.

## Explicit Constraints In Original Request

- _Review the Original Request section above; constraints are preserved there when present._

## Context Paths In Original Request

- _Review the Original Request section above; paths and links are preserved there when present._

## Downstream Artifacts

- Investigation: Not created yet
- Spec: Not created yet
- Q and A ledger: Not created yet
