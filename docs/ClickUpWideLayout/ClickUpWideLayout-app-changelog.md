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
- Toggle layout flow now waits for a background response before the popup closes.
- `background.js` centralizes toggle state changes and returns `{ ok, enabled }` or `{ ok, error }` for popup requests.
- `content.js` restores storage-backed enabled state only after `window.__CU_LAYOUT_API__` exists.
- No package file or automated test harness exists in the extension repo.

## Plans

| Date | Plan | Status | Summary |
| ---- | ---- | ------ | ------- |
| 2026-07-14 | Fix toggle UI sync | implemented | Make popup toggle wait for background completion; centralize toggle state/apply logic; move content storage restore after API creation. |
| 2026-07-01 | Add Markdown copy button | implemented | Share popup task lookup and clipboard helpers; add Markdown heading-link copy action requiring URL. |

## Attempt History

- 2026-07-01: Changelog discovery found no prior ClickUpWideLayout or PRDV-16034 record under `C:\dustin-thomason\docs`; unrelated Markdown hits existed only in WorkLists/OtterCopy docs.
- 2026-07-01: Rejected fallback `# ${title} - ${id}` when URL is missing; requirement only supports heading link Markdown.

## Session Log

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
