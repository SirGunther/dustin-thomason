# Locked Decisions - ClickUpWideLayout/export-clickup-ticket-to-markdown

## Question Gates Resolved Without Asking

### Question Gate 1

- Proposed question: Should v1 use ClickUp API/OAuth or the active browser page DOM as its primary source?
- Existing answer check: Investigation verdict and user correction favor browser-first active-page capture.
- Current behavior evidence: `popup.js` already uses `activeTab` and `chrome.scripting.executeScript` to read ClickUp task id/title/link.
- Recommendation: Lock DOM-first v1; defer API/token UI.
- Ask only if still unresolved: no.

### Question Gate 2

- Proposed question: Should comments/activity history be exported?
- Existing answer check: Original requirement names fields, descriptions, custom fields, status, and metadata; the investigation explicitly scoped comments/activity out unless separately requested.
- Current behavior evidence: Existing extension only observes the task header/link; no activity/comment collector exists.
- Recommendation: Superseded by LD-016; include visible activity/comments and threaded replies, but do not retrieve attachments/media.
- Ask only if still unresolved: no.

### Question Gate 3

- Proposed question: Should the extension add `chrome.downloads` permission now?
- Existing answer check: Investigation recommends Blob/object-URL first to avoid a new permission warning.
- Original behavior evidence: Manifest had no `downloads` permission before the fast follow-up.
- Recommendation: Superseded by LD-015; use Chrome Save As with `downloads` permission for v1.
- Ask only if still unresolved: no.

### Question Gate 4

- Proposed question: Must exact ClickUp selectors be proven before writing the spec?
- Existing answer check: Investigation records CDP unavailable; implementation can use existing proven id/title selectors plus resilient visible-DOM fallback and must validate manually.
- Current behavior evidence: Current id/title selectors are already used in `popup.js` and `content.js`; richer field selectors remain unproven.
- Recommendation: Lock selector proof as an implementation validation gate, not a blocker to writing the spec.
- Ask only if still unresolved: no.

## Locked Decision Ledger

| ID | Locked decision | Source | Supersedes or rejects | Spec destination |
| --- | --- | --- | --- | --- |
| LD-001 | The target app repo is `C:\Users\dktho\OneDrive\PDProjects\Browser Extensions\ClickUpWideLayout`; orchestration docs live in `C:\dustin-thomason\docs\ClickUpWideLayout`. | User correction; changelog correction entry | Rejects placing ticket docs inside the extension folder | Problem, Requirement, Scope notes |
| LD-002 | V1 exports from the active ClickUp browser page DOM after a popup user gesture. | Investigation §§0, 1, 7, 10 | Supersedes API-first framing | Solution, Interfaces, Data Flow |
| LD-003 | V1 must not introduce ClickUp API token/OAuth settings or recurring login prompts. | Original ticket notes; investigation §§0, 3, 6 | Rejects API-first and hybrid API in v1 | Non-goals, Security, Implementation |
| LD-004 | Add a new popup button labeled `Export Task to Markdown`. | Original ticket UI requirement | Extends existing popup buttons | UI Behavior |
| LD-005 | Existing `Toggle Extended Layout`, `Copy ID - Title`, and `Copy as Markdown` behavior must remain unchanged. | Changelog current state; investigation acceptance criteria | Rejects refactoring neighbor flows as part of v1 | Regression Constraints, Test Plan |
| LD-006 | Export filename is `{ticket-id}-original-ticket.md`; strip a leading `#` and sanitize filesystem-unsafe characters. | Original ticket requirement; investigation contract | Rejects title-based filenames | Formatter and Download |
| LD-007 | Required export fields are task id and title. URL should be captured from `getTaskHref(id)` or `window.location.href`; description and metadata are captured when visible. | Existing code; investigation §§3, 7, 8 | Rejects failing the whole export because optional metadata is hidden | Data Contract, Failure Modes |
| LD-008 | Markdown output follows the original-ticket artifact shape: title, capture metadata, optional ClickUp metadata/location, original request/description, explicit constraints/context placeholders, downstream artifacts. | Original ticket; PRDV-14055 format reference only | Rejects link-only Markdown copy as sufficient | Markdown Template |
| LD-009 | Rich text conversion supports common rendered DOM structure: headings, paragraphs, line breaks, lists, links, bold/italic, inline code. | Original ticket notes; investigation acceptance criteria | Rejects full ClickUp internal rich-text model as v1 scope | Markdown Conversion |
| LD-010 | Superseded: comments and activity history were originally out of scope for v1. | Investigation §§3, 7, 10; superseded by user fast follow-up on 2026-07-20 | Superseded by LD-016 for visible comments/activity; attachment/file retrieval remains out of scope | Historical non-goal |
| LD-011 | V1 uses Blob/object-URL anchor download from the popup and does not add `downloads` permission unless validation proves the browser blocks it. | Investigation §§6, 8, 10 | Rejects adding a new permission preemptively | Download Strategy, Risks |
| LD-012 | Exact live ClickUp selector proof remains a validation gate because no CDP browser was available during investigation. | Investigation §§0, 8, 10; coverage ledger | Accepts bounded selector risk for implementation | Risks, Test Plan |
| LD-013 | Implementation cannot be marked complete until a live ClickUp task DOM is inspected in real time and the selector/field map is validated through browser-loop/Playwright. | User correction on 2026-07-20 | Rejects treating draft DOM collector code plus blocked manual validation as complete | Acceptance Criteria, Test Plan, Phase 5 closeout |
| LD-014 | PRDV-14055 live DOM selector proof is complete: use the task id/title `data-test` selectors, `[data-test="task-view-task-content__scrollable"]` task root, Quill editor description, hero field rows, custom field row label/body pairs, and breadcrumb/list selectors observed at runtime. | Playwright/CDP inspection on 2026-07-20; coverage ledger section 5a; test plan results | Resolves LD-012/LD-013 for selector proof on the reference task; does not validate actual popup download | DOM Collection Strategy, Test Plan |
| LD-015 | Export filenames and Ticket slug / ID must prefer PRDV-style IDs when visible, include Created date when available, explicitly list visible-but-empty fields as omitted, and use Chrome Save As instead of silent Downloads auto-save. | User fast follow-up on 2026-07-20; downloaded `86adw7q7b-original-ticket.md` proved internal-ID filename issue | Supersedes Blob-only no-new-permission download decision for v1; adds `downloads` permission for `saveAs` | Filename, Metadata, Omitted Fields, Download Strategy |
| LD-016 | Visible ClickUp activity rows, comments, and visible threaded replies are in scope for the export; attachments and embedded media are explicitly not retrieved and are represented only as omitted placeholders/counts when encountered in the comment DOM. | User fast follow-up on 2026-07-20; live Playwright/CDP inspection of PRDV-14055 activity stream/thread DOM | Supersedes LD-010 for comments/activity only; keeps attachment/file retrieval out of scope | Activity And Comments, DOM Collection Strategy, Markdown Conversion, Test Plan |
