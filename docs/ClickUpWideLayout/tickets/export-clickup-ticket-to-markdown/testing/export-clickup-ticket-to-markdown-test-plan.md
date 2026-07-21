# Test plan - ClickUpWideLayout/export-clickup-ticket-to-markdown

> Seeded from [export-clickup-ticket-to-markdown-investigation.md](../investigations/export-clickup-ticket-to-markdown-investigation.md) Section 9 on 2026-07-20. Refined by spec: [export-clickup-ticket-to-markdown-spec.md](../specs/export-clickup-ticket-to-markdown-spec.md).

Status: in execution

Live ClickUp DOM inspection passed for PRDV-14055 after Chrome was launched with CDP on port `9222`. Implementation is not complete until the unpacked extension popup is reloaded in Chrome and the manual scenarios below pass against the real page.

## Scope and surfaces under test

- Popup export action, active ClickUp task DOM collection, original-ticket Markdown formatting, PRDV-style filename generation, Save As download prompt, omitted-field reporting, visible activity/comment/threaded-reply capture, attachment/media omission, and regression coverage for existing popup copy/toggle actions.

## Happy path

- [ ] HP-1: Open a ClickUp task with id, title, URL, description, and visible metadata -> click `Export Task to Markdown` in popup -> Chrome opens Save As with `{ticket-id}-original-ticket.md`.
- [ ] HP-2: Save to `C:\dustin-thomason\docs` or the target ticket docs folder -> open downloaded file -> title, capture metadata, Created date, original request, optional ClickUp metadata/location, omitted fields, explicit constraints placeholder, context paths placeholder, and downstream artifact placeholders are present.
- [ ] HP-3: Task id renders with leading `#` -> exported filename strips the `#` and still ends with `-original-ticket.md`.
- [ ] HP-4: Task has visible activity and comments -> generated Markdown includes `## Activity And Comments` with visible activity rows, top-level comments, author/timestamp labels, and readable comment body Markdown.
- [ ] HP-5: Task has visible threaded replies -> export opens the visible thread, captures replies as nested bullets under the parent comment, then returns the ClickUp page to the normal activity stream.

## Negative paths

- [ ] NP-1: Active tab is not a ClickUp task -> popup shows `Could not find task details.` and downloads nothing.
- [ ] NP-2: Task id or title cannot be found -> popup shows `Could not find task details.` and downloads nothing.
- [ ] NP-3: Task description is empty -> export succeeds with `_No description text found in the active ClickUp page._`.
- [ ] NP-4: Metadata/custom fields are not visible -> export succeeds and omits the empty metadata table.
- [ ] NP-5: Download helper throws, Chrome blocks Save As, or user cancels -> popup shows a visible error and no misleading success message.
- [ ] NP-6: Activity stream is hidden or absent -> export succeeds with the no-visible-activity placeholder.

## Edge cases

- [ ] EC-1: Description includes headings, lists, links, emphasis, inline code, and line breaks -> Markdown remains readable and structured.
- [ ] EC-2: Task title or id contains filesystem-unsafe characters -> filename is sanitized while preserving the task id enough to recognize the ticket.
- [ ] EC-2a: ClickUp renders an internal id but the URL/page exposes a PRDV-style id -> filename and Ticket slug / ID use the PRDV-style id.
- [ ] EC-3: Existing `Copy ID - Title` button still copies the existing payload.
- [ ] EC-4: Existing `Copy as Markdown` button still emits exactly `# [title - id](url)`.
- [ ] EC-5: Layout toggle still applies and updates badge/popup state.
- [ ] EC-6: Live ClickUp task with custom fields visible -> visible custom field labels/values appear in Ticket Metadata, or missing fields are recorded as validation risk.
- [ ] EC-7: Comment contains attachments/images/video -> exported comment keeps text but replaces attachment/media DOM with `[Attachment omitted]`; no attachment URL/file bytes are fetched or downloaded.
- [ ] EC-8: Comment mentions render as ClickUp JavaScript links -> exported Markdown keeps visible mention text and does not emit `javascript:` links.

## Test map

| Repo | Suite | Asserts |
| --- | --- | --- |
| ClickUpWideLayout | manual live Chrome validation | export button, generated file, task field parity, existing popup actions |
| ClickUpWideLayout | `node --check popup.js` | popup script syntax |
| ClickUpWideLayout | `node --check content.js` | injected content script syntax |
| ClickUpWideLayout | `node --check background.js` | background service worker syntax |
| ClickUpWideLayout | generated Markdown file inspection | original-ticket template shape and visible field preservation |

## Gates

| Gate | Command |
| --- | --- |
| syntax | `node --check popup.js` |
| syntax | `node --check content.js` |
| syntax | `node --check background.js` |
| manual | Reload unpacked extension in Chrome and validate on a live ClickUp task |

## Results log (filled at execution)

| Date | Gate/Scenario | Command | Scope | Result | Exception / risk |
| --- | --- | --- | --- | --- | --- |
| 2026-07-20 | syntax | `node --check popup.js` | Popup export implementation, existing copy/toggle wiring | pass | - |
| 2026-07-20 | syntax | `node --check content.js` | Existing injected content API and layout behavior | pass | - |
| 2026-07-20 | syntax | `node --check background.js` | Existing background service worker and toggle message flow | pass | - |
| 2026-07-20 | manifest permission check | `Get-Content manifest.json \| ConvertFrom-Json` | Confirm Save As follow-up intentionally adds `downloads` while preserving existing permissions | pass | Manifest declares `scripting`, `storage`, `activeTab`, `clipboardWrite`, `downloads`, and ClickUp host permissions. |
| 2026-07-20 | live DOM selector proof | `chromium.connectOverCDP('http://localhost:9222')` via Playwright | PRDV-14055 live ClickUp task DOM | pass | Confirmed id/title selectors, task root, Quill description editor, hero field rows, custom field rows, and breadcrumb/location selectors. |
| 2026-07-20 | runtime collector proof | Inject patched `collectTaskExportDataFromPage()` into PRDV-14055 through Playwright | Active task data collection | pass | Returned id `PRDV-14055`, title, URL, location `Product Development > Master Product Backlog > MBL LIST`, readable description Markdown, and 15 metadata rows including Status, Project Name, Issue type, Owning Team. |
| 2026-07-20 | generated Markdown inspection | Extract patched collector and formatter from `popup.js`; render PRDV-14055 data | Filename and Markdown template | pass | Filename `PRDV-14055-original-ticket.md`; title, capture metadata, location, ticket metadata, and original request are present; leading `#` is absent from filename. |
| 2026-07-20 | fast-follow generated Markdown inspection | Extract patched collector and formatter from `popup.js`; render PRDV-14055 data | PRDV filename, Created date, omitted fields | pass | Filename `PRDV-14055-original-ticket.md`; Created captured as `Dec 11 2025`; Omitted Fields contains 21 visible empty/placeholder labels and does not duplicate captured `Project Name`. |
| 2026-07-20 | HP-1 Save As manual attempt | User clicked `Export Task to Markdown` in reloaded extension | Actual popup Save As behavior | fail | Save dialog opened and immediately closed; toast appeared, but Chrome download manager showed no saved file. Root cause likely popup-owned Blob URL lifetime plus premature popup close/Object URL revoke. |
| 2026-07-20 | Save As lifetime fix | `node --check popup.js`; source inspection | Export download helper and popup completion behavior | pass | Replaced Blob/object URL with self-contained `data:text/markdown` URL, removed export auto-close, removed premature `Downloaded` toast, and leaves status at `Save dialog opened for {filename}`. Requires another manual popup attempt. |
| 2026-07-20 | stale URL ticket-id regression | Playwright/CDP injected patched collector with `getTaskHref()` forced to `https://app.clickup.com/t/43227262/PRDV-14037` while visible task DOM was PRDV-14055 | Filename and URL identity resolution | pass | Resolver now prioritizes visible task id/custom id/document title/root text before URL; suggested filename stayed `PRDV-14055-original-ticket.md` and normalized URL became `https://app.clickup.com/t/43227262/PRDV-14055`. |
| 2026-07-20 | activity/comment DOM selector proof | Playwright/CDP inspected PRDV-14055 activity stream and expanded the visible reply thread | Activity rows, top-level comments, threaded replies, attachment/media markers | pass | Confirmed `cu-task-activity-stream`, `cu-task-activity-stream-item-wrapper`, `task-activity-stream-item__item-generic`, `task-activity-stream-item__comment`, `comment-number-*`, `task-comment__reply-has-thread`, `cu-task-comment-thread`, `cu-threaded-comment`, and attachment/media selectors. |
| 2026-07-20 | live activity/comment collector proof | Extract patched `collectTaskExportDataFromPage()` from `popup.js`; execute in PRDV-14055 via Playwright/CDP | Runtime activity/comment export data | pass | Returned 9 activity/comment items: 4 generic activity rows, 3 top-level comments, and 2 nested replies; page returned to normal activity stream after thread capture. |
| 2026-07-20 | generated Activity And Comments Markdown inspection | Extract patched collector and formatter from `popup.js`; render PRDV-14055 data | Activity/comment Markdown section | pass | Filename `PRDV-14055-original-ticket.md`; section includes parent comment plus two nested replies; Anastasiya reply records 3 omitted attachment/media placeholders and emits no attachment file URLs. |
| 2026-07-20 | syntax | `node --check popup.js` | Popup export implementation after activity/comment changes | pass | - |
| 2026-07-20 | syntax | `node --check content.js` | Existing injected content API and layout behavior after activity/comment changes | pass | - |
| 2026-07-20 | syntax | `node --check background.js` | Existing background service worker after activity/comment changes | pass | - |
| 2026-07-20 | HP-1..HP-5, NP-1..NP-6, EC-3..EC-8 | Reload unpacked extension in Chrome and use popup | Actual popup download, activity/comment output, attachment omission, and existing button regression | pending | Live DOM and formatter gates passed, but actual popup click/download behavior and existing copy/toggle regression still require manual validation in Chrome with the unpacked extension loaded. |
