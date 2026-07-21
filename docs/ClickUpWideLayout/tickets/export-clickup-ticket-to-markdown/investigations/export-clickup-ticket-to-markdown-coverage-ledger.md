# Coverage ledger - ClickUpWideLayout/export-clickup-ticket-to-markdown

Investigation question: Can the ClickUpWideLayout extension export the active ClickUp task as a Markdown original-ticket file without adding recurring login/API setup?
Repo(s): ClickUpWideLayout browser extension, dustin-thomason docs  -  Baseline commit: n/a, extension folder is not a git repo  -  Started: 2026-07-20

## Consulted

- `docs/ClickUpWideLayout/tickets/*/investigations/*-coverage-ledger.md` for "ClickUpWideLayout export markdown task" - none found.
- `C:\dustin-thomason\docs\ClickUpWideLayout\ClickUpWideLayout-app-changelog.md` for current extension state - reused implemented-plan notes for copy actions, toggle flow, and no test harness.
- `C:\dustin-thomason\docs\atlas\PRDV-14055\PRDV-14055-original-ticket.md` - consulted only as Markdown format reference; not reused as product scope.

## Areas examined

### 1. Extension manifest and permissions

| Field | Value |
| --- | --- |
| Inspected | `manifest.json` permissions, host permissions, action popup, background service worker |
| Findings | MV3 extension declares `scripting`, `activeTab`, `storage`, `clipboardWrite`, `downloads`, and `https://app.clickup.com/*`; `downloads` was added for the user-requested Save As prompt |
| Status | fully-inspected |
| Commit | n/a - 2026-07-20 |
| Evidence | `manifest.json` |
| Notes | `chrome.downloads.download({ saveAs: true })` opens a native save dialog but cannot force an arbitrary absolute repo folder |

### 2. Popup task lookup and copy flow

| Field | Value |
| --- | --- |
| Inspected | `popup.html` buttons; `popup.js` active tab query, content injection, `findTaskMeta`, Markdown copy formatter, status/toast helpers |
| Findings | Popup already performs user-gesture page inspection and copies `# [title - id](url)`; export can reuse active-tab, task lookup, URL resolution, status, and toast patterns |
| Status | fully-inspected |
| Commit | n/a - 2026-07-20 |
| Evidence | `popup.html`, `popup.js`; app changelog current state |
| Notes | Existing copy behavior must remain unchanged |

### 3. Content script task URL helper and layout behavior

| Field | Value |
| --- | --- |
| Inspected | `content.js` `window.__CU_LAYOUT_API__`, `getTaskHref`, layout enable/disable observers, legacy copy helper |
| Findings | Content API resolves task URLs from current URL, anchors, or task-id DOM context; layout observers are unrelated neighbors that export must not disturb |
| Status | fully-inspected |
| Commit | n/a - 2026-07-20 |
| Evidence | `content.js` |
| Notes | Neighbor protection: layout toggle and existing copy helpers are regression surfaces |

### 4. Background toggle flow

| Field | Value |
| --- | --- |
| Inspected | `background.js` storage helpers, content injection, toggle message handler, tab update injection |
| Findings | Background script is scoped to layout toggle and content pre-injection; export can stay popup-owned unless a `chrome.downloads` fallback becomes necessary |
| Status | ruled-out |
| Commit | n/a - 2026-07-20 |
| Evidence | `background.js` |
| Notes | Reopen only if implementation chooses `chrome.downloads` or background-mediated download |

### 5. Browser-loop availability

| Field | Value |
| --- | --- |
| Inspected | `C:\dustin-thomason\scripts\browser`, Node availability, CDP endpoint at `http://localhost:9222/json/version`, live PRDV-14055 ClickUp task page |
| Findings | Browser helper scripts and dependencies exist; Node and Playwright are available; CDP attach succeeded after Chrome was launched with `--remote-debugging-port=9222`; live PRDV-14055 DOM was inspected |
| Status | fully-inspected for PRDV-14055 selector proof |
| Commit | n/a - 2026-07-20 |
| Evidence | `node --version` returned `v24.11.1`; `Invoke-RestMethod http://localhost:9222/json/version` returned Chrome/CDP metadata; Playwright `chromium.connectOverCDP('http://localhost:9222')` inspected `https://app.clickup.com/t/43227262/PRDV-14055` |
| Notes | Live selector proof passed for the reference task; actual unpacked-extension popup/download validation remains separate |

### 5a. Live ClickUp DOM selector proof - PRDV-14055

| Field | Selector / structure | Runtime value observed |
| --- | --- | --- |
| Task ID | `[data-test="task-view-task-label__taskid-button"]` | `PRDV-14055` |
| Title | `[data-test="task-title__text-area"]` | `Make Upload Manager count up instead of down` |
| Task root | `[data-test="task-view-task-content__scrollable"]` from title ancestor | Contains hero fields, description editor, and custom fields |
| Description | `[data-test="task-editor-wrapper"] .ql-editor` / `[data-test="task-editor"]` | Original request and acceptance criteria rendered as Quill blocks/lists |
| Hero metadata | `[data-test^="task-field-label-icon__container-"]` closest `.cu-task-fields__row` | Status, Dates, Priority, Sprint points, etc. |
| Custom fields | `[data-test="task-custom-fields__row"]` with `.cu-task-custom-fields__row-type` and `.cu-task-custom-fields__row-body` | Project Name, Issue type, Owning Team, Stakeholder Impact, Primary Stakeholder, etc. |
| Location | `[data-test="task-view-breadcrumbs__timl-list-item"]`; `[data-test="location-editable__location-title"]` | `Product Development > Master Product Backlog > MBL LIST` |

### 5b. Live ClickUp activity/comment selector proof - PRDV-14055

| Field | Selector / structure | Runtime value observed |
| --- | --- | --- |
| Activity root | `cu-task-view-task-activity-lazy`; `cu-task-activity-stream`; `.cu-task-activity-stream__container` | Activity sidebar rendered with `Activity 8`, watcher/filter controls, and visible stream rows |
| Stream row wrapper | `cu-task-activity-stream-item-wrapper` | 10 visible wrappers on PRDV-14055 during inspection |
| Generic activity row | `[data-test="task-activity-stream-item__item-generic"]` under a wrapper | Examples: task created, Tech Intake checked, tag added, Acceptor assignment |
| Comment row | `[data-test="task-activity-stream-item__comment"]`; `[data-test^="comment-number-"]`; `cu-task-comment` | Top-level comments from Shaye Lankford and ClickBot captured with author/date/body |
| Comment author | `.cu-comment__author`; `[data-test="task-comment__meta-left"]` | `Shaye Lankford`, `ClickBot (Automations)`, `Anastasiya Savchuk` |
| Comment timestamp | `.cu-comment__date`; `.cu-comment__ts-brain-label` | Examples: `Jul 7 at 9:34 am`, `Jul 14 at 9:33 am`, `Jul 15 at 4:08 pm` |
| Comment body | `[data-test="comment-viewer-content"]`; `.cu-comment-viewer-content`; fallback `[data-test="task-comment__body-container"]` | Markdown-compatible body text including mentions, paragraphs, and bold text |
| Thread entry | `[data-test="task-comment__reply-has-thread"]` | `2 replies` visible on the Jul 7 parent comment |
| Thread view | `[data-test="task-activity-stream__comment-thread"]`; `cu-task-comment-thread`; `[data-test="task-comment-thread-banner__exit-thread"]` | Clicking the thread button opens a dedicated thread panel; exporter exits it after capture |
| Thread parent | `[data-test="thread-comments__parent"]`; `.cu-thread-comments__parent` | Parent comment by Shaye Lankford: `Can you confirm this is still up-to-date?` |
| Thread replies | `cu-threaded-comment`; `[data-test^="thread-comments__comment"]`; nested `[data-test^="comment-number-"]` | Two replies captured at nested depth: Anastasiya Savchuk and Shaye Lankford |
| Attachment/media markers | `cu-attachment-dynamic`; `cu-comment-attachment`; `cu-frame-embed-dynamic`; `[data-test*="attachment"]`; `[data-test*="comment-frame"]` | Comment reply contained image/video DOM; exporter replaces with `[Attachment omitted]` and does not retrieve files |

### 6. Official API and browser extension docs

| Field | Value |
| --- | --- |
| Inspected | ClickUp Tasks/Get Task docs; Chrome `activeTab`, `scripting`, and `downloads` docs |
| Findings | ClickUp Get Task supports task details, custom fields, attachments, and `include_markdown_description`; Chrome `activeTab` and `scripting` match current extension design; `chrome.downloads` requires a manifest permission |
| Status | fully-inspected |
| Commit | n/a - 2026-07-20 |
| Evidence | https://developer.clickup.com/docs/tasks, https://developer.clickup.com/reference/gettask, https://developer.chrome.com/docs/extensions/develop/concepts/activeTab, https://developer.chrome.com/docs/extensions/reference/api/scripting, https://developer.chrome.com/docs/extensions/reference/api/downloads |
| Notes | API remains fallback due auth/token/workspace scope |

## Not yet inspected (frontier)

- Browser download behavior from popup - whether `chrome.downloads.download({ saveAs: true })` opens and completes as expected in the user's Chrome setup.
- Rich text edge cases beyond PRDV-14055 - ClickUp nested lists, links, code, mentions, and checklists in rendered DOM.
- Activity/comment edge cases beyond PRDV-14055 - additional thread layouts, collapsed history beyond visible `Show more`, deleted comments, resolved comments, and comments with attachment-only bodies.
- Manual regression - existing copy/toggle flows after implementation.
