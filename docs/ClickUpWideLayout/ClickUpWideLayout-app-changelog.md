# ClickUpWideLayout App Changelog

## Purpose

Cross-session implementation memory for the ClickUpWideLayout browser extension.

## Scope

- Repo: `C:\Users\dktho\OneDrive\PDProjects\Browser Extensions\ClickUpWideLayout`
- Canonical record: `C:\dustin-thomason\docs\ClickUpWideLayout\ClickUpWideLayout-app-changelog.md`

## Requirements (verbatim)

> This ticket is specifically for [ClickUpWideLayout](c:/Users/dktho/OneDrive/PDProjects/Browser Extensions/ClickUpWideLayout/)
>
> # Add Markdown Copy Button to Selector
>
> ### Problem
> The existing UI selector only provides copy functions for titles and IDs. This limits the ability to quickly transfer data into external platforms that require specific formatting, specifically Markdown.
>
> ### Requirement
> - Add a new button to the UI selector component.
> - The button should trigger a copy action for the selected item.
> - The output format must be in Markdown.
> - The copy functionality should mirror the behavior of the current 'Copy ID' feature.
>
> ### Solution
> - Investigate the existing 'Copy ID' implementation within the selector component.
> - Create a new utility function to format the object data into the desired Markdown structure.
> - Update the UI to include a new button labeled for Markdown output.
> - Bind the button click event to the new formatting utility.
>
> ### Investigation
> - Explore the current codebase to identify where 'Copy ID' and 'Copy Title' functions are defined.
> - Evaluate existing helper functions for data serialization to ensure consistency.
>
> ### UI/UX Component
> - A new 'Copy as Markdown' button is required within the existing selector action bar.
> - Ensure the button styling matches the design language of the current copy buttons.
>
> **Notes:**
> - Reference PRDV-16034 (Reconfigure the ADB Data Source) for any potential data mapping dependencies.
>
> e.g.,
> # [Reconfigure the ADB Data Source - PRDV-16034](https://app.clickup.com/t/43227262/PRDV-16034)
>
> **Estimation:** 3 Sprint Points.
>
> To be clear, there is no additional markdown format outside of
>
> # [Reconfigure the ADB Data Source - PRDV-16034](https://app.clickup.com/t/43227262/PRDV-16034)
>
> which aligns with
> #
>
> I do'nt see where the requirement states
> without URL: # ${title} - ${id}

## Current State

- `popup.html` exposes `Toggle Extended Layout`, `Copy ID - Title`, and `Copy as Markdown`.
- `popup.js` owns the active popup copy flow.
- Existing task copy behavior remains `id - title` plus URL when available.
- Markdown copy requires `id`, `title`, and resolved task URL; output shape is exactly `# [title - id](url)`.
- Export-to-original-ticket Markdown has draft popup code with live PRDV-14055 DOM selector proof and fast follow-ups for PRDV-style filenames, Created date, omitted fields, and Save As. First Save As manual attempt failed with no saved file; export now uses a data URL and avoids auto-closing the popup. Implementation is not complete until actual popup download retry and existing copy/toggle regressions are validated in Chrome.
- Toggle layout flow now waits for a background response before the popup closes.
- `background.js` centralizes toggle state changes and returns `{ ok, enabled }` or `{ ok, error }` for popup requests.
- `content.js` restores storage-backed enabled state only after `window.__CU_LAYOUT_API__` exists.
- No package file or automated test harness exists in the extension repo.

## Plans

| Date | Plan | Status | Summary |
| ---- | ---- | ------ | ------- |
| 2026-07-20 | Export ClickUp ticket to original-ticket Markdown | active | Add a popup export action that captures the active ClickUp task via browser DOM, formats the original-ticket Markdown artifact, and downloads `{ticket-id}-original-ticket.md`. |
| 2026-07-14 | Fix toggle UI sync | implemented | Make popup toggle wait for background completion; centralize toggle state/apply logic; move content storage restore after API creation. |
| 2026-07-01 | Add Markdown copy button | implemented | Share popup task lookup and clipboard helpers; add Markdown heading-link copy action requiring URL. |

## Attempt History

- 2026-07-01: Changelog discovery found no prior ClickUpWideLayout or PRDV-16034 record under `C:\dustin-thomason\docs`; unrelated Markdown hits existed only in WorkLists/OtterCopy docs.
- 2026-07-01: Rejected fallback `# ${title} - ${id}` when URL is missing; requirement only supports heading link Markdown.

## Session Log

### 2026-07-20T18:19:25-04:00 - ClickUpWideLayout

- Summary: Added visible ClickUp activity/comment export support to the original-ticket Markdown flow. The exporter now captures visible stream activity, top-level comments, and visible threaded replies, nests replies under their parent comment, and replaces attachment/media DOM with omitted placeholders/counts without retrieving files.
- Plan used: Fast follow-up for `Export ClickUp ticket to original-ticket Markdown` - activity and comments.
- Files/areas:
  - `C:\Users\dktho\OneDrive\PDProjects\Browser Extensions\ClickUpWideLayout\popup.js`: added async activity/comment/thread collector, thread enter/exit handling, comment body cleanup, attachment/media scrubbing, and `## Activity And Comments` Markdown rendering.
  - `docs/ClickUpWideLayout/tickets/export-clickup-ticket-to-markdown/specs/export-clickup-ticket-to-markdown-locked-decisions.md`: added LD-016 superseding comments/activity out-of-scope while keeping attachment retrieval out of scope.
  - `docs/ClickUpWideLayout/tickets/export-clickup-ticket-to-markdown/specs/export-clickup-ticket-to-markdown-spec.md`: updated scope, data contract, DOM strategy, Markdown template, conversion rules, risks, and acceptance criteria.
  - `docs/ClickUpWideLayout/tickets/export-clickup-ticket-to-markdown/investigations/export-clickup-ticket-to-markdown-coverage-ledger.md`: recorded live activity/comment selector proof for PRDV-14055.
  - `docs/ClickUpWideLayout/tickets/export-clickup-ticket-to-markdown/testing/export-clickup-ticket-to-markdown-test-plan.md`: added activity/comment/thread/attachment cases and result rows.
  - `docs/ClickUpWideLayout/tickets/export-clickup-ticket-to-markdown/orchestration.md`: updated Phase 5 notes and resume.
- User-visible impact:
  - Exported Markdown now includes an `Activity And Comments` section from the active ClickUp page.
  - Visible threaded replies are nested beneath their parent comment.
  - Attachments/media are not downloaded or serialized as URLs; they appear as `[Attachment omitted]` placeholders with a count.
- Tests run:
  | Gate | Command | Scope | Result | Exception / risk |
  | ---- | ------- | ----- | ------ | ---------------- |
  | syntax | `node --check popup.js` | Popup export implementation after activity/comment changes | pass | - |
  | syntax | `node --check content.js` | Existing injected content API and layout behavior | pass | - |
  | syntax | `node --check background.js` | Existing background service worker | pass | - |
  | live collector proof | Playwright/CDP extracted `collectTaskExportDataFromPage()` from `popup.js` and ran it on PRDV-14055 | Activity/comment/thread data collection | pass | Returned 9 activity/comment items, including 2 nested replies; page returned to normal activity stream. |
  | formatter proof | Playwright/CDP extracted collector and formatter from `popup.js` and rendered PRDV-14055 Markdown | `Activity And Comments` section and filename | pass | Filename `PRDV-14055-original-ticket.md`; section nests replies under the parent and records 3 omitted attachment/media placeholders. |
- Tests added/updated: manual test plan now includes HP-4, HP-5, NP-6, EC-7, and EC-8.
- Regression impact: existing copy/toggle code was not intentionally changed; manual popup regression remains pending with the unpacked extension.

### 2026-07-20T02:15:00-04:00 - ClickUpWideLayout

- Summary: Fixed the ticket-id mismatch that could suggest `PRDV-14037-original-ticket.md` while the visible task was PRDV-14055. The preferred id resolver had trusted URL before visible DOM; ClickUp SPA state can leave URL/link helpers stale. The resolver now prioritizes visible task id, Custom Task ID, document title, task title, and task root text before URL, and normalizes the captured ClickUp task URL to the chosen PRDV id.
- Plan used: Plans table -> `Export ClickUp ticket to original-ticket Markdown`.
- Files/areas:
  - `C:\Users\dktho\OneDrive\PDProjects\Browser Extensions\ClickUpWideLayout\popup.js`: reordered preferred-ticket-id sources and added stale URL normalization.
  - `docs/ClickUpWideLayout/tickets/export-clickup-ticket-to-markdown/testing/export-clickup-ticket-to-markdown-test-plan.md`: added stale URL regression proof.
  - `docs/ClickUpWideLayout/tickets/export-clickup-ticket-to-markdown/orchestration.md`: updated Phase 5 note.
- User-visible impact: Save As should suggest `PRDV-14055-original-ticket.md` for the visible PRDV-14055 task even if the URL/link helper briefly reports another PRDV ticket.
- Tests run:
  | Gate | Command | Scope | Result | Exception / risk |
  | ---- | ------- | ----- | ------ | ---------------- |
  | syntax | `node --check popup.js` | Preferred id and URL normalization changes | pass | - |
  | syntax | `node --check content.js` | Existing injected content API and layout behavior | pass | - |
  | syntax | `node --check background.js` | Existing background service worker and toggle message flow | pass | - |
  | stale URL regression | Playwright/CDP forced `getTaskHref()` to `https://app.clickup.com/t/43227262/PRDV-14037` while visible DOM was PRDV-14055 | Filename and URL identity resolution | pass | Suggested filename stayed `PRDV-14055-original-ticket.md`; normalized URL became PRDV-14055. |
- Tests added/updated: refined test plan updated with stale URL regression.
- Regression impact: export identity resolution only; extension reload and actual popup Save As retry still required.

### 2026-07-20T02:05:00-04:00 - ClickUpWideLayout

- Summary: Fixed the failed Save As behavior reported from manual validation. The dialog opened and immediately closed, no file appeared in Chrome downloads, and the prior export showed a misleading success toast. The download helper now uses a self-contained `data:text/markdown` URL instead of a popup-owned Blob/object URL, does not revoke an object URL, does not auto-close the popup after export, and no longer shows a `Downloaded` toast before a file is actually saved.
- Plan used: Plans table -> `Export ClickUp ticket to original-ticket Markdown`.
- Files/areas:
  - `C:\Users\dktho\OneDrive\PDProjects\Browser Extensions\ClickUpWideLayout\popup.js`: changed Save As download lifetime behavior and export completion messaging.
  - `docs/ClickUpWideLayout/tickets/export-clickup-ticket-to-markdown/testing/export-clickup-ticket-to-markdown-test-plan.md`: recorded the failed manual Save As attempt and the follow-up fix.
  - `docs/ClickUpWideLayout/tickets/export-clickup-ticket-to-markdown/orchestration.md`: updated Phase 5 status note with the failure/fix boundary.
- User-visible impact: Export should keep the Save As flow alive longer and avoid false success messaging.
- Tests run:
  | Gate | Command | Scope | Result | Exception / risk |
  | ---- | ------- | ----- | ------ | ---------------- |
  | syntax | `node --check popup.js` | Export download helper and popup flow | pass | Actual Save As retry still required. |
  | syntax | `node --check content.js` | Existing injected content API and layout behavior | pass | - |
  | syntax | `node --check background.js` | Existing background service worker and toggle message flow | pass | - |
- Tests added/updated: refined test plan includes the failed HP-1 attempt and the new fix row.
- Regression impact: export download behavior only. Extension must be reloaded and HP-1 retried manually.

### 2026-07-20T01:55:00-04:00 - ClickUpWideLayout

- Summary: Implemented fast follow-ups from the first downloaded artifact. Export now prefers PRDV-style ticket ids for filename and capture metadata, records ClickUp internal id only when different, captures Created date, emits an Omitted Fields table for visible fields without collectable values, and opens Chrome Save As through `chrome.downloads.download({ saveAs: true })`.
- Plan used: Plans table -> `Export ClickUp ticket to original-ticket Markdown`.
- Files/areas:
  - `C:\Users\dktho\OneDrive\PDProjects\Browser Extensions\ClickUpWideLayout\manifest.json`: added `downloads` permission for Save As.
  - `C:\Users\dktho\OneDrive\PDProjects\Browser Extensions\ClickUpWideLayout\popup.js`: added preferred PRDV id resolver, Created date capture, omitted-field capture, Save As download flow, and duplicate omitted-field suppression.
  - `docs/ClickUpWideLayout/tickets/export-clickup-ticket-to-markdown/specs/export-clickup-ticket-to-markdown-locked-decisions.md`: added LD-015.
  - `docs/ClickUpWideLayout/tickets/export-clickup-ticket-to-markdown/specs/export-clickup-ticket-to-markdown-spec.md`: updated filename, metadata, omitted-field, and download strategy.
  - `docs/ClickUpWideLayout/tickets/export-clickup-ticket-to-markdown/testing/export-clickup-ticket-to-markdown-test-plan.md`: added fast-follow proof row and Save As scenarios.
  - `docs/ClickUpWideLayout/tickets/export-clickup-ticket-to-markdown/export-clickup-ticket-to-markdown-future-development-concerns.md`: replaced Blob fallback concern with Save As absolute-folder limitation.
- User-visible impact: Export should now prompt for a save location with `PRDV-#####-original-ticket.md` when a PRDV-style id is visible, include Created date, and explicitly report empty visible fields.
- Tests run:
  | Gate | Command | Scope | Result | Exception / risk |
  | ---- | ------- | ----- | ------ | ---------------- |
  | syntax | `node --check popup.js` | Popup export implementation and existing popup actions | pass | - |
  | syntax | `node --check content.js` | Existing injected content API and layout behavior | pass | - |
  | syntax | `node --check background.js` | Existing background service worker and toggle message flow | pass | - |
  | manifest permission check | `Get-Content manifest.json | ConvertFrom-Json` | Confirm `downloads` permission is present for Save As | pass | Permission added intentionally; extension reload required. |
  | fast-follow runtime proof | Playwright/CDP injected patched collector/formatter into PRDV-14055 | Filename, Created, omitted fields | pass | Produced `PRDV-14055-original-ticket.md`, Created `Dec 11 2025`, and 21 omitted fields without duplicating captured `Project Name`. |
- Tests added/updated: no automated harness exists; refined test plan updated.
- Regression impact: export path now requires `downloads` permission and an extension reload. Existing copy/toggle code was syntax-checked but still needs live popup regression validation.

### 2026-07-20T01:35:00-04:00 - ClickUpWideLayout

- Summary: Completed live ClickUp DOM inspection for PRDV-14055 through Playwright/CDP and updated the export collector to match actual rendered structures. Confirmed id/title selectors, task content root, Quill description editor, hero field rows, custom field label/body rows, and breadcrumb/list location selectors. Formatter proof generated `PRDV-14055-original-ticket.md` with readable description Markdown and visible metadata.
- Plan used: Plans table -> `Export ClickUp ticket to original-ticket Markdown`.
- Files/areas:
  - `C:\Users\dktho\OneDrive\PDProjects\Browser Extensions\ClickUpWideLayout\popup.js`: updated task root scoping, description selectors, hero metadata extraction, custom field extraction, breadcrumb collection, field-value cleanup, and Markdown spacing cleanup.
  - `docs/ClickUpWideLayout/tickets/export-clickup-ticket-to-markdown/investigations/export-clickup-ticket-to-markdown-coverage-ledger.md`: recorded live selector proof.
  - `docs/ClickUpWideLayout/tickets/export-clickup-ticket-to-markdown/testing/export-clickup-ticket-to-markdown-test-plan.md`: added live DOM, collector, and formatter results.
  - `docs/ClickUpWideLayout/tickets/export-clickup-ticket-to-markdown/orchestration.md`: Phase 5 remains in progress; next action is actual unpacked-extension popup validation.
  - `docs/ClickUpWideLayout/tickets/export-clickup-ticket-to-markdown/export-clickup-ticket-to-markdown-future-development-concerns.md`: live DOM blocker resolved for PRDV-14055, with variant/hidden-field risk retained.
- User-visible impact: The draft export action now targets the actual ClickUp DOM rendered for PRDV-14055 instead of broad fallback guesses.
- Tests run:
  | Gate | Command | Scope | Result | Exception / risk |
  | ---- | ------- | ----- | ------ | ---------------- |
  | syntax | `node --check popup.js` | Popup export implementation and existing popup actions | pass | - |
  | syntax | `node --check content.js` | Existing injected content API and layout behavior | pass | - |
  | syntax | `node --check background.js` | Existing background service worker and toggle message flow | pass | - |
  | live DOM selector proof | Playwright `chromium.connectOverCDP('http://localhost:9222')` | PRDV-14055 ClickUp task page | pass | Actual popup/download validation still pending. |
  | runtime collector proof | Inject patched `collectTaskExportDataFromPage()` into PRDV-14055 | Active task DOM data collection | pass | Returned id/title/location/description and 15 metadata rows. |
  | generated Markdown inspection | Extract patched collector/formatter from `popup.js` and render PRDV-14055 | Filename and artifact content | pass | Produced `PRDV-14055-original-ticket.md` preview with expected sections. |
- Tests added/updated: no automated harness exists; results were added to the refined test plan.
- Regression impact: `popup.js` export helper changed only. Existing copy/toggle code was syntax-checked but still needs live popup regression validation.

### 2026-07-20T01:15:00-04:00 - ClickUpWideLayout

- Summary: Corrected Phase 5 status after user clarification. The export code remains a draft, but the task is not implemented until real-time ClickUp DOM inspection confirms the field locations and live browser validation passes.
- Plan used: Plans table -> `Export ClickUp ticket to original-ticket Markdown`.
- Files/areas:
  - `docs/ClickUpWideLayout/tickets/export-clickup-ticket-to-markdown/orchestration.md`: Phase 5 restored to in-progress with live DOM inspection as the next action.
  - `docs/ClickUpWideLayout/tickets/export-clickup-ticket-to-markdown/testing/export-clickup-ticket-to-markdown-test-plan.md`: status restored to in-execution; blocked live validation recorded as a completion blocker.
  - `docs/ClickUpWideLayout/tickets/export-clickup-ticket-to-markdown/specs/export-clickup-ticket-to-markdown-locked-decisions.md`: added LD-013 requiring live DOM inspection before completion.
  - `docs/ClickUpWideLayout/tickets/export-clickup-ticket-to-markdown/specs/export-clickup-ticket-to-markdown-spec.md`: acceptance criteria and tests now explicitly require browser-loop/Playwright DOM inspection.
  - `docs/ClickUpWideLayout/tickets/export-clickup-ticket-to-markdown/export-clickup-ticket-to-markdown-future-development-concerns.md`: changed DOM capture from accepted residual risk to completion blocker until inspection validates it.
- User-visible impact: no extension behavior changed in this correction; status now reflects that implementation is incomplete.
- Tests run: not applicable for status/docs correction.

### 2026-07-20T01:00:00-04:00 - ClickUpWideLayout

- Summary: Drafted the DOM-first ClickUp task Markdown export in the extension popup. Added `Export Task to Markdown`, active-tab DOM collection for task id/title/link/visible description/metadata/location, original-ticket Markdown formatting, filename sanitization, Blob/object-URL download, loading/success/error status, and success toast. This is not complete because live ClickUp DOM inspection and manual browser validation did not run. No ClickUp API auth/token flow, no OAuth, and no `chrome.downloads` permission were added.
- Plan used: Plans table -> `Export ClickUp ticket to original-ticket Markdown`.
- Files/areas:
  - `C:\Users\dktho\OneDrive\PDProjects\Browser Extensions\ClickUpWideLayout\popup.html`: added export button.
  - `C:\Users\dktho\OneDrive\PDProjects\Browser Extensions\ClickUpWideLayout\popup.js`: added export flow, DOM collector, Markdown formatter, filename sanitizer, and Blob download helper.
  - `docs/ClickUpWideLayout/tickets/export-clickup-ticket-to-markdown/testing/export-clickup-ticket-to-markdown-test-plan.md`: syntax results logged; live validation blocked.
  - `docs/ClickUpWideLayout/tickets/export-clickup-ticket-to-markdown/orchestration.md`: Phase 5 was prematurely marked done and was corrected in the next log entry.
- User-visible impact: Draft popup code offers `Export Task to Markdown`; it must be validated against a real ClickUp task before being considered working.
- Tests run:
  | Gate | Command | Scope | Result | Exception / risk |
  | ---- | ------- | ----- | ------ | ---------------- |
  | syntax | `node --check popup.js` | Popup export implementation and existing popup actions | pass | - |
  | syntax | `node --check content.js` | Existing injected content API and layout behavior | pass | - |
  | syntax | `node --check background.js` | Existing background service worker and toggle message flow | pass | - |
  | manifest permission check | `Select-String manifest.json -Pattern 'downloads\|activeTab\|scripting\|host_permissions'` | Confirm no `chrome.downloads` permission added | pass | Manifest still has existing permissions only. |
  | live browser validation availability | `Invoke-RestMethod http://localhost:9222/json/version` | CDP attach check for live ClickUp/browser-loop validation | blocked | No attachable browser endpoint; manual reload/validation of the unpacked extension remains required. |
- Tests added/updated: no automated harness exists in this extension repo; refined test plan results log updated with syntax passes and manual validation blocker.
- Regression impact: intended source changes are confined to popup UI/export helpers. Existing `Copy ID - Title`, `Copy as Markdown`, `content.js`, `background.js`, and manifest permissions are unchanged; live browser regression remains to be manually verified.
- API docs: not relevant: v1 adds no HTTP/API surface and no ClickUp API call.

### 2026-07-20T00:45:00-04:00 - ClickUpWideLayout

- Summary: Accepted the Phase 4 implementation plan for the ClickUp task Markdown export and moved orchestration into Phase 5 implementation. Confirmed the extension folder has no `.git`, so branch creation is skipped for this local unpacked-extension project.
- Plan used: Plans table -> `Export ClickUp ticket to original-ticket Markdown`.
- Files/areas:
  - `docs/ClickUpWideLayout/tickets/export-clickup-ticket-to-markdown/orchestration.md`: Phase 4 marked done, Phase 5 marked in progress.
  - `docs/ClickUpWideLayout/ClickUpWideLayout-app-changelog.md`: current state moved from specified to implementation.
- User-visible impact: none yet; prep-to-implementation transition only.
- Tests run: not applicable for phase transition docs. Implementation gates remain in the refined test plan.

### 2026-07-20T00:30:00-04:00 - ClickUpWideLayout

- Summary: Completed Phase 3 probe/spec for the ClickUp ticket Markdown export. Locked DOM-first v1 decisions, documented rejected API/token and `chrome.downloads` paths for now, wrote the implementation spec, refined the test plan, and recorded future concerns for live selector proof and Blob download validation.
- Plan used: Plans table -> `Export ClickUp ticket to original-ticket Markdown`.
- Files/areas:
  - `docs/ClickUpWideLayout/tickets/export-clickup-ticket-to-markdown/specs/export-clickup-ticket-to-markdown-locked-decisions.md`: locked-decision ledger.
  - `docs/ClickUpWideLayout/tickets/export-clickup-ticket-to-markdown/specs/export-clickup-ticket-to-markdown-spec.md`: implementation spec.
  - `docs/ClickUpWideLayout/tickets/export-clickup-ticket-to-markdown/testing/export-clickup-ticket-to-markdown-test-plan.md`: refined test plan.
  - `docs/ClickUpWideLayout/tickets/export-clickup-ticket-to-markdown/export-clickup-ticket-to-markdown-future-development-concerns.md`: selector/download validation concerns.
- User-visible impact: none yet; spec/docs only. Extension source files remain unchanged.
- Tests run: not applicable for docs/spec-only phase; implementation syntax and manual validation gates are now in the refined test plan.

### 2026-07-20T00:15:00-04:00 - ClickUpWideLayout

- Summary: Corrected the ticket artifact location for the export-to-Markdown workflow. The orchestration docs now live under the canonical `dustin-thomason/docs/ClickUpWideLayout/tickets/...` tree instead of inside the browser extension folder.
- Plan used: Location correction for `Export ClickUp ticket to original-ticket Markdown`.
- Files/areas:
  - `docs/ClickUpWideLayout/tickets/export-clickup-ticket-to-markdown/`: original ticket, orchestration ledger, investigation report, coverage ledger, diagrams, and seeded test plan relocated here.
  - `C:\Users\dktho\OneDrive\PDProjects\Browser Extensions\ClickUpWideLayout\docs\...`: mistaken copied artifacts removed after verifying matching hashes.
- User-visible impact: none; documentation placement only. Extension source files remain in the extension folder.
- Tests run: not applicable; docs relocation only.

### 2026-07-20T00:00:00-04:00 - ClickUpWideLayout

- Summary: Completed the investigation/report package for exporting the active ClickUp task as an original-ticket Markdown file. The report recommends a DOM-first v1 using the active ClickUp page and defers ClickUp API auth/token work unless live browser evidence proves DOM capture insufficient.
- Plan used: Plans table -> `Export ClickUp ticket to original-ticket Markdown`.
- Files/areas:
  - `docs/ClickUpWideLayout/tickets/export-clickup-ticket-to-markdown/original-ticket.md`: downstream artifact links updated.
  - `docs/ClickUpWideLayout/tickets/export-clickup-ticket-to-markdown/orchestration.md`: Phase 1 and Phase 2 marked done; resume moved to Phase 3.
  - `docs/ClickUpWideLayout/tickets/export-clickup-ticket-to-markdown/investigations/`: investigation report, coverage ledger, and diagrams added.
  - `docs/ClickUpWideLayout/tickets/export-clickup-ticket-to-markdown/testing/`: seeded test plan added.
- User-visible impact: none yet; documentation/investigation only. Export button is not implemented in the extension yet.
- Tests run:
  | Gate | Command | Scope | Result | Exception / risk |
  | ---- | ------- | ----- | ------ | ---------------- |
  | browser-loop availability | `Invoke-RestMethod http://localhost:9222/json/version` | CDP attach check | blocked | No attachable browser endpoint; live ClickUp DOM selector proof remains open. |
- Tests added/updated: seeded test plan only; no code test harness exists.
- Regression impact: no extension code intentionally changed in this phase.
- API docs: reviewed ClickUp Get Task / Tasks docs and Chrome `activeTab`, `scripting`, and `downloads` docs to choose DOM-first v1 with API as fallback.

### 2026-07-14T00:00:00-04:00 - ClickUpWideLayout

- Summary: Fixed first-click toggle UI synchronization for the ClickUp layout extension.
- Files/areas:
  - `popup.js`: toggle click now queries the active tab, sends `{ action: "toggle-layout", tabId }`, waits for the background response, disables the button while pending, and shows status on failure.
  - `background.js`: centralized toggle state changes through one async path shared by popup messages and action clicks; script/storage failures now return `{ ok: false, error }` to the popup.
  - `content.js`: moved storage restore and live sync listeners after `window.__CU_LAYOUT_API__` is assigned so first-load restore can call `enable()` immediately.
- User-visible impact:
  - The popup no longer closes before the layout toggle finishes applying.
  - First-click enabled/disabled state should immediately match the ClickUp pane layout and extension badge state.
  - Existing `Copy ID - Title` and `Copy as Markdown` popup actions were not intentionally changed.
- Tests run:
  | Gate | Command | Scope | Result | Exception / risk |
  | ---- | ------- | ----- | ------ | ---------------- |
  | syntax | `node --check popup.js` | popup toggle and copy wiring | pass | - |
  | syntax | `node --check background.js` | background toggle/message flow | pass | - |
  | syntax | `node --check content.js` | injected layout API and storage sync | pass | - |
- Manual validation: not run in this agent session; requires reloading the unpacked extension in Chrome and exercising a live ClickUp task page.
- Tests added/updated: not added; repo has no package/test harness and the fix is native MV3 extension wiring.
- Regression impact: intended to affect only the layout toggle path; copy flows and manifest permissions unchanged.

### 2026-07-01T16:28:25Z - ClickUpWideLayout

- Summary: Added Markdown copy action to popup selector.
- Files/areas:
  - `popup.html`: added `Copy as Markdown` button with existing button styling.
  - `popup.js`: extracted shared task lookup, clipboard payload copy, task formatting, Markdown formatting, and toast message helpers.
- User-visible impact:
  - Popup now includes `Copy as Markdown`.
  - Markdown copy emits `# [title - id](url)` only when a task link is available.
  - Existing `Copy ID - Title` behavior remains available.
- Tests run:
  | Gate | Command | Scope | Result | Exception / risk |
  | ---- | ------- | ----- | ------ | ---------------- |
  | syntax | `node --check popup.js` | edited popup copy logic | pass | - |
  | syntax | `node --check content.js` | injected task URL helper surface | pass | - |
  | syntax | `node --check background.js` | extension background script | pass | - |
- Tests added/updated: not added; repo has no package/test harness and change is browser-extension popup wiring.
- Regression impact: isolated to popup selector actions; background layout toggle and content layout observers unchanged.
- API docs: not relevant; extension has no HTTP/API contract surface.
- Tooling gates: package lint/test/audit not available; repo has no `package.json`. Syntax gates above passed.
