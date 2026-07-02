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
- No package file or automated test harness exists in the extension repo.

## Plans

| Date | Plan | Status | Summary |
| ---- | ---- | ------ | ------- |
| 2026-07-01 | Add Markdown copy button | implemented | Share popup task lookup and clipboard helpers; add Markdown heading-link copy action requiring URL. |

## Attempt History

- 2026-07-01: Changelog discovery found no prior ClickUpWideLayout or PRDV-16034 record under `C:\dustin-thomason\docs`; unrelated Markdown hits existed only in WorkLists/OtterCopy docs.
- 2026-07-01: Rejected fallback `# ${title} - ${id}` when URL is missing; requirement only supports heading link Markdown.

## Session Log

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
