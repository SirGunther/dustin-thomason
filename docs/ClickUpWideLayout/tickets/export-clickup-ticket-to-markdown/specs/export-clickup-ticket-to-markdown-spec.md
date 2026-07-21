# Export ClickUp Ticket To Markdown Spec

## Metadata

| Field | Value |
| --- | --- |
| Project | ClickUpWideLayout |
| Ticket | export-clickup-ticket-to-markdown |
| Date | 2026-07-20 |
| Status | spec |
| Investigation | `../investigations/export-clickup-ticket-to-markdown-investigation.md` |
| Locked decisions | `./export-clickup-ticket-to-markdown-locked-decisions.md` |
| Test plan | `../testing/export-clickup-ticket-to-markdown-test-plan.md` |

## Problem

The ClickUpWideLayout extension can copy a task id/title/link, but it cannot export the active ClickUp task into the `original-ticket.md` style artifact used by the workflow. Manual copying loses task description structure and visible metadata, and it creates avoidable placement/format mistakes.

## Requirement

Add a popup-driven export action for the active ClickUp task that downloads a Markdown file named `{ticket-id}-original-ticket.md`, preferring PRDV-style IDs when visible over ClickUp internal IDs. The export must use the active ClickUp browser page as the v1 source of truth, preserve the current no-login behavior, include visible task description, metadata, activity, comments, and visible threaded replies when available, explicitly list visible-but-empty fields as omitted, omit attached files/media without retrieval, and leave the existing layout toggle and copy actions unchanged.

## Solution

Add an `Export Task to Markdown` popup button. On click, the popup disables the button, shows a loading message, injects a task collector into the active tab, formats the returned data into the original-ticket Markdown template, and opens Chrome's Save As dialog through `chrome.downloads.download({ saveAs: true })`. The implementation stays in the existing plain MV3 extension files with no build system, no framework, and no ClickUp API auth flow.

## Locked Decisions From Q and A

| Decision | Source | Implementation consequence |
| --- | --- | --- |
| DOM-first active-page capture is v1. | LD-002 | Use `chrome.scripting.executeScript`; do not call ClickUp API. |
| No token/OAuth/login setup in v1. | LD-003 | Do not add settings UI or token storage. |
| Add a fourth popup button labeled `Export Task to Markdown`. | LD-004 | `popup.html` gets one new button using existing button styling. |
| Existing popup actions are neighbors and must not change. | LD-005 | Reuse helpers carefully; regression-test all existing buttons. |
| Filename is `{ticket-id}-original-ticket.md`. | LD-006, LD-015 | Strip leading `#`; sanitize unsafe filename characters; prefer PRDV-style IDs when visible. |
| Id/title are required; URL uses helper/current page fallback; description/metadata are visible-DOM best effort. | LD-007 | Fail visibly only if id/title are missing. |
| Output uses original-ticket artifact sections. | LD-008 | Generate capture metadata, original request, constraints/context placeholders, and downstream artifact placeholders. |
| Visible comments/activity are in scope; attachments/media are not retrieved. | LD-016 | Inspect the visible activity stream, enter visible reply threads to capture replies, and scrub attachment/media DOM to omitted placeholders. |
| Use Chrome Save As for downloads. | LD-015 | Add `downloads` permission and prompt for the save location; Chrome cannot force an arbitrary absolute repo folder. |
| Live selector proof is a validation gate. | LD-012 | Build resilient fallback collectors and record manual validation results. |
| Live DOM inspection is required before completion. | LD-013 | Keep Phase 5 open until browser-loop/Playwright validates real ClickUp field locations and export behavior. |
| PRDV-14055 selector proof is complete. | LD-014 | Use the observed task root, Quill description editor, hero field rows, custom field label/body pairs, and breadcrumb selectors. |
| Fast follow-up export semantics are in v1. | LD-015 | Prefer PRDV-style IDs, capture Created, list omitted fields, and open Chrome Save As. |

## UI Behavior

- `popup.html` adds `<button id="export-task-markdown">Export Task to Markdown</button>` after the existing Markdown copy button.
- When clicked, the button text changes to `Exporting...`, the button is disabled, and a small status line says `Reading ClickUp task...`.
- On Save As launch, the popup shows `Save dialog opened for {filename}`. It must not auto-close or show a `Downloaded` toast before Chrome actually saves the file.
- On failure, the button is re-enabled with its original label and the status line shows the failure reason.
- Existing button labels and behavior remain unchanged.
- The Save As dialog opens with `{ticket-id}-original-ticket.md`; the user selects the target folder, such as `C:\dustin-thomason\docs`, because Chrome extensions cannot force an arbitrary absolute save directory.

## Data Contract

The injected collector returns:

| Field | Required | Source |
| --- | --- | --- |
| `id` | yes | `[data-test="task-view-task-label__taskid-button"]`; strip leading `#` |
| `title` | yes | `[data-test="task-title__text-area"]` value/text |
| `url` | no | `window.__CU_LAYOUT_API__?.getTaskHref(id)` then `window.location.href` |
| `capturedOn` | yes | local date as `YYYY-MM-DD` |
| `descriptionMarkdown` | no | visible description DOM converted to Markdown |
| `metadata` | no | visible field rows/labels such as status, assignee, priority, dates, tags, sprint, points, list/folder/space/custom fields |
| `omittedFields` | no | visible field labels whose values are empty, placeholders, or dashes |
| `activityItems` | no | visible `cu-task-activity-stream` rows, `cu-task-comment` comments, and visible `cu-task-comment-thread` replies |
| `location` | no | visible breadcrumbs or task hierarchy when available |

If `id` or `title` is missing, the export fails visibly and downloads nothing. Missing description, metadata, activity/comments, or location does not fail the export.

## DOM Collection Strategy

- Reuse the current id/title selectors already proven by `popup.js` and `content.js`.
- Resolve the task root from the title element's closest task-view container, then fall back to `document.body`.
- Description lookup uses ordered candidates: task-description `data-test` selectors, visible `[contenteditable="true"]` under description containers, `aria-label` containing Description, and a final visible-region fallback near an exact `Description` label.
- Metadata lookup scans visible label/value rows for known field labels and custom-field-like rows; duplicate labels are de-duped by normalized label.
- Activity lookup scans visible `cu-task-activity-stream-item-wrapper` rows. Generic activity rows are exported as activity text; `cu-task-comment` rows are exported with author, timestamp, and Markdown body.
- Threaded comment lookup enters visible `task-comment__reply-has-thread` threads, waits for `cu-threaded-comment` reply rows, captures those replies at nested depth, then exits back to the normal activity stream.
- Attachment and embedded-media nodes under comments are scrubbed from cloned DOM only. The exporter must not click, fetch, download, or serialize attachment URLs.
- Collection must only read visible page data plus visible reply threads. It must not switch tabs, call APIs, or mutate ClickUp task data.

## Markdown Template

The downloaded file content is:

```markdown
# <title> - Original Ticket

## Capture Metadata

| Field | Value |
| --- | --- |
| Project | ClickUp |
| Ticket slug / ID | <preferred PRDV-style id or ClickUp id> |
| Captured on | <YYYY-MM-DD> |
| Source | Active ClickUp browser page |
| Formatting | Browser DOM converted to Markdown |
| URL | <url> |
| ClickUp internal ID | <internal id, only when different from preferred id> |

## ClickUp Location

<breadcrumbs or omitted>

## Ticket Metadata

| Field | Value |
| --- | --- |
| <field> | <value> |

## Omitted Fields

| Field | Reason |
| --- | --- |
| <field> | No visible value in the active ClickUp page |

## Activity And Comments

_Visible ClickUp activity and comments captured from the active browser page. Attachments and embedded media are not retrieved._

- **Activity:** <visible activity row>

- **Comment by <author>** - <timestamp>
  <comment Markdown>
  - _<n> attachment/media item(s) omitted._

  - **Comment by <reply author>** - <timestamp>
    <reply Markdown>

## Original Request

<descriptionMarkdown or "_No description text found in the active ClickUp page._">

## Explicit Constraints In Original Request

- _Review the Original Request section above; constraints are preserved there when present._

## Context Paths In Original Request

- _Review the Original Request section above; paths and links are preserved there when present._

## Downstream Artifacts

- Investigation: Not created yet
- Spec: Not created yet
- Q and A ledger: Not created yet
```

Omit optional sections only when there are no rows. Visible-but-empty metadata fields should appear in `Omitted Fields`.

## Markdown Conversion

- Convert headings, paragraphs/div blocks, line breaks, unordered/ordered list items, links, bold/italic, and inline code.
- Normalize whitespace, collapse three or more blank lines to two, and trim leading/trailing whitespace.
- Escape Markdown table pipes in metadata values.
- Preserve link hrefs as `[text](href)` when text and href are present.
- Ignore `javascript:` links emitted by ClickUp mention controls.
- Strip comment controls such as reactions, `Like this comment`, reply buttons, and action buttons.
- Serialize visible comments/activity and visible threaded replies only.
- Replace attachment/media DOM with `[Attachment omitted]` placeholders and an omitted count; do not retrieve attachment URLs or file bytes.

## Folder Hierarchy

New extension source paths: N/A - this is a single-file popup enhancement plus one popup HTML button.

New workflow/spec paths:

```text
docs/ClickUpWideLayout/tickets/export-clickup-ticket-to-markdown/
  specs/export-clickup-ticket-to-markdown-locked-decisions.md
  specs/export-clickup-ticket-to-markdown-spec.md
  export-clickup-ticket-to-markdown-future-development-concerns.md
```

## New Classes

N/A - plain JavaScript extension, no classes.

Expected new helper functions in `popup.js`:

| Helper | Responsibility |
| --- | --- |
| `exportCurrentTaskMarkdown()` | Button handler and status flow |
| `findTaskExportData(tabId)` | Retry wrapper around page collector |
| `collectTaskExportDataFromPage()` | Injected DOM collector |
| `formatTaskExportMarkdown(taskData)` | Original-ticket Markdown renderer |
| `downloadTextFile(filename, text)` | Self-contained `data:text/markdown` URL plus Chrome `downloads` Save As prompt |
| `safeFileName(value)` | Strip `#`, prefer PRDV-style IDs, and sanitize filename |
| `markdownFromNode(node)` or equivalent | Common rich-text DOM conversion |
| `findActivityItems(document)` or equivalent | Visible activity/comment/threaded-reply collector that omits attachments/media |

## New Entities

N/A - browser extension only.

## Modified Entities

N/A - browser extension only.

## New Migrations

N/A - browser extension only.

## New Migration Classes

N/A - browser extension only.

## New DTOs

N/A - no HTTP/API surface in v1.

## New Projections

N/A - no backend/domain projection.

## HTTP Surface

N/A - v1 does not call ClickUp API or introduce any app API.

## Authorization

The export reads only the active ClickUp page after the user clicks the extension popup. No new ClickUp auth scope, API token, OAuth flow, or recurring login prompt is introduced.

## Failure Modes

- No active tab: show `No active tab found.`
- Not a ClickUp task / id/title missing: show `Could not find task details.`
- Description missing: export succeeds with the no-description placeholder.
- Metadata hidden or absent: export succeeds without that metadata.
- Download blocked or Save As canceled: show `Could not download Markdown file.` or the Chrome-provided error.

## Risks And Future Concerns

- Live ClickUp selector proof was not available during investigation; implementation must inspect a real ClickUp task DOM and manually validate the export before Phase 5 is complete.
- DOM capture may omit hidden/custom fields or activity not visible/loadable on the active page. API-backed completion remains a future option, not v1.
- Thread expansion briefly changes the activity pane to ClickUp's thread view and returns it to the normal stream. Validation must confirm the page is not left inside a thread after export.
- Comment attachments/media are intentionally represented as omitted placeholders/counts. The extension must not fetch or download attachment files in this scope.
- `downloads` permission is now intentional so Chrome can show a Save As dialog. Chrome does not allow the extension to force `C:\dustin-thomason\docs` as an absolute destination; the user chooses that folder in the dialog.
- The Save As path uses a data URL to avoid popup-owned Blob URL lifetime issues when the native dialog takes focus.

## Acceptance Criteria

- Popup includes `Export Task to Markdown`.
- Export from an active ClickUp task downloads `{ticket-id}-original-ticket.md`.
- Filename prefers PRDV-style IDs when visible and does not fall back to an internal ClickUp id if a PRDV-style id is present.
- Generated Markdown includes required original-ticket sections and visible ClickUp fields.
- Generated Markdown includes Created date when visible and an Omitted Fields table for visible fields without collectable values.
- Generated Markdown includes visible activity rows, top-level comments, and visible threaded replies under their parent comment.
- Generated Markdown omits attachment/media retrieval and records omitted attachment/media placeholders/counts when comment DOM contains them.
- Missing optional fields do not block export.
- Existing popup copy/toggle actions retain their current behavior.
- No ClickUp API login/token prompt is introduced.
- Live ClickUp DOM inspection identifies and validates the real field locations used for title, id, description, visible metadata, location/breadcrumb data, activity rows, comments, and threaded replies.

## Spec Tests

- `node --check popup.js`
- `node --check content.js`
- `node --check background.js`
- Manual live Chrome validation per `../testing/export-clickup-ticket-to-markdown-test-plan.md`.
- Browser-loop/Playwright inspection of a live ClickUp task DOM before marking implementation complete.
