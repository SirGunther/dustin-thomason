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

## Requirements (verbatim) — Enable copying links from ClickUp page view

> [ClickUpWideLayout](c:/Users/dktho/OneDrive/PDProjects/Browser Extensions/ClickUpWideLayout/)
> [agents](c:/dustin-thomason/agents/)
> [orchestrate](c:/dustin-thomason/agents/skills/orchestrate/)
>
> Enable copying links from ClickUp page view
>
> ---
>
> ---
> # Incident Report
> ### Observed behavior
> - The ability to copy markdown and title links is currently restricted to contextual popouts/panes.
> ### Expected behavior
> - Users should be able to copy markdown and title links directly from the full ClickUp link page view.
> ### Requested adjustment
> - Implement a mechanism to extract link data when navigating the full ClickUp page URL directly, bypassing the pane-only dependency.
> ---
>
> ### Problem
> - Current link extraction logic is tied to the context of a sidebar or popout pane, preventing users from retrieving link data when visiting the primary page view.
>
> ### Requirement
> - Provide functionality to copy title and markdown-formatted links regardless of whether the user is in a pane or on the source page.
>
> ### Solution
> - Decouple the link extraction service from the UI pane component.
> - Ensure the service can parse and return page metadata from the full browser view.
>
> ### Investigation
> - Audit the existing `copyLink` method to identify hard-coded references to the pane/sidebar component state.
> - Determine if the ClickUp metadata provider can be injected into the main page controller.
>
> ### Technical Scope
> - **Backend/API:** Evaluate if the current data model requires an endpoint to fetch page metadata independently of the pane state.
> - **Frontend:** Update the clipboard event listeners to identify page context and trigger the extraction utility.
>
> ### UI/UX Component
> - Add/Ensure a 'Copy Link' action button is present and functional in the primary header of the ClickUp page view to provide consistent user interaction.
>
> **Estimation:** 5 Sprint Points.
>
> We don't need a Heavy investigation. The defect is fairly well established. We can connect you to PlayWright to inspect the source when ready.

## Current State

- The `enable-copy-links-page-view` implementation is complete and ready for Phase 6 loaded-extension review. `content.js#getTaskMeta()` now owns active task ID/title/URL/context resolution, full-screen `/t/...` routes no longer depend on the displayed custom ID appearing in the URL, pane DOM-link behavior remains intact, and both existing popup Header copy controls delegate to the service. Automated, syntax, manifest, and authenticated live-provider gates pass; actual popup/pane interaction remains pending because the debugging Chrome session did not have the unpacked extension loaded.
- The popup uses a minimal SaySlate-inspired visual system: a 312px shell, light/dark palette, inline SVG icons, a top-right theme toggle, and separate Layout, Header, and Task action groups.
- Each action row keeps only a concise title on the left; all explanatory copy lives in hover/focus tooltips on the 32px controls. Header copy actions remain separate rows, while Task uses one `Full Markdown` row with copy and download controls side by side.
- Theme preference persists locally under `clickup-wide-layout-theme`; light mode is the safe fallback if local storage is unavailable.
- `popup.js` owns the active popup copy flow.
- Existing task copy behavior remains `id - title` plus URL when available.
- Markdown copy requires `id`, `title`, and resolved task URL; output shape is exactly `# [title - id](url)`.
- Full task Markdown copy and file export share `prepareCurrentTaskMarkdown()`, so both receive the exact output of `formatTaskExportMarkdown()`. Clipboard output is written as plain text and uses the existing in-page success/failure toast path.
- Export-to-original-ticket Markdown has draft popup code with live PRDV-14055 DOM selector proof and fast follow-ups for PRDV-style filenames, Created date, omitted fields, and Save As. First Save As manual attempt failed with no saved file; export now uses a data URL and avoids auto-closing the popup. Implementation is not complete until actual popup download retry and existing copy/toggle regressions are validated in Chrome.
- Toggle layout flow now waits for a background response before the popup closes.
- `background.js` centralizes toggle state changes and returns `{ ok, enabled }` or `{ ok, error }` for popup requests.
- `content.js` restores storage-backed enabled state only after `window.__CU_LAYOUT_API__` exists.
- No package file exists in the extension repo. Focused popup behavior coverage now runs with Node's built-in test runner from `tests/popup-markdown.test.mjs`.

## Plans

| Date | Plan | Status | Summary |
| ---- | ---- | ------ | ------- |
| 2026-08-07 | Move action details into tooltips | implemented | Remove persistent secondary descriptions and combine full-task copy/download into one `Full Markdown` row with two icon actions. |
| 2026-08-07 | Separate descriptions from icon actions | implemented | Replace text-inside-action buttons with description rows and independent Slate-style icon controls with hover/focus tooltips. |
| 2026-08-07 | SaySlate-inspired popup refresh | implemented | Restyle the popup with grouped icon actions and a persistent light/dark theme while preserving all existing button ids and behavior. |
| 2026-08-07 | Copy full ticket Markdown to clipboard | implemented | Add a popup action that copies the exact full-ticket Markdown used by file export and reports success/failure through the existing toast path. |
| 2026-07-20 | Export ClickUp ticket to original-ticket Markdown | active | Add a popup export action that captures the active ClickUp task via browser DOM, formats the original-ticket Markdown artifact, and downloads `{ticket-id}-original-ticket.md`. |
| 2026-07-14 | Fix toggle UI sync | implemented | Make popup toggle wait for background completion; centralize toggle state/apply logic; move content storage restore after API creation. |
| 2026-07-01 | Add Markdown copy button | implemented | Share popup task lookup and clipboard helpers; add Markdown heading-link copy action requiring URL. |

## Attempt History

- 2026-07-01: Changelog discovery found no prior ClickUpWideLayout or PRDV-16034 record under `C:\dustin-thomason\docs`; unrelated Markdown hits existed only in WorkLists/OtterCopy docs.
- 2026-07-01: Rejected fallback `# ${title} - ${id}` when URL is missing; requirement only supports heading link Markdown.

## Session Log

### 2026-08-11T17:09:39Z - ClickUpWideLayout

- Summary: Implemented `enable-copy-links-page-view`. Added a bounded, uncached `getTaskMeta()` service with explicit full-page/pane/unknown context and safe URL precedence; delegated popup and content copy callers; preserved all existing UI and formatter contracts; and added resolver, exact-payload, retry, feedback, and SPA-navigation coverage.
- Plan used: Phase 4 was explicitly skipped by the user as unnecessary; implementation used the accepted spec, refined test plan, and in-chat execution checklist.
- Files/areas:
  - `C:\Users\dktho\OneDrive\PDProjects\Browser Extensions\ClickUpWideLayout\content.js`
  - `C:\Users\dktho\OneDrive\PDProjects\Browser Extensions\ClickUpWideLayout\popup.js`
  - `C:\Users\dktho\OneDrive\PDProjects\Browser Extensions\ClickUpWideLayout\tests\content-links.test.mjs`
  - `C:\Users\dktho\OneDrive\PDProjects\Browser Extensions\ClickUpWideLayout\tests\popup-markdown.test.mjs`
  - `docs/ClickUpWideLayout/tickets/enable-copy-links-page-view/`
- User-visible impact: The existing `ID + title` and `Markdown link` popup actions can resolve the current URL from a directly opened full-screen task even when ClickUp's route uses an internal ID. No new ClickUp-page control was added.
- Self-review: Checked the installed diff against `docs/reviewers/pr-review-patterns.md`; named the context constants and added symmetric pane/nearby-DOM plus failure coverage before final gates.
- Tests run:

  | Gate | Command | Scope | Result | Exception / risk |
  | ---- | ------- | ----- | ------ | ---------------- |
  | package audit | `Test-Path package.json` | Extension root | not available | No `package.json` or dependency surface. |
  | package lint | `Test-Path package.json` | Extension root | not available | No configured lint command; syntax checks substitute. |
  | syntax | `node --check popup.js`; `node --check content.js`; `node --check background.js` | Popup, content, background | pass | - |
  | manifest | `Get-Content -Raw manifest.json \| ConvertFrom-Json \| Out-Null` | MV3 manifest | pass | No manifest change. |
  | tests | `node --test tests/popup-markdown.test.mjs tests/content-links.test.mjs` | Resolver, popup payload/feedback, theme/full-ticket regressions | pass - 18 tests | Layout runtime remains Phase 6. |
  | authenticated live provider | CDP evaluation of installed `content.js` on visible `PRDV-16313` | Normal custom-ID route plus temporary internal-ID mismatch route | pass | Original URL restored; zero extension-owned page controls. |
  | loaded-extension popup/pane | Authenticated Chrome on port 9222 | Actual popup click/paste and pane interaction | pending Phase 6 | Unpacked extension was not loaded in the debugging Chrome session. |
- Regression impact: `popup.html`, `popup.css`, `background.js`, `manifest.json`, full-ticket formatters/export, layout toggle, and theme implementation were not changed. Existing neighboring automated tests remain green.
- PR/commit: Not applicable; the ClickUpWideLayout implementation folder is not a Git repository. The populated PR draft is the review handoff body.

### 2026-08-11T16:49:19Z - ClickUpWideLayout

- Summary: Completed Phase 3 probe/spec for `enable-copy-links-page-view`. Reconciled every candidate question against existing evidence without re-asking, locked eight implementation decisions and rejected paths, accepted the single five-criterion job story, wrote the internal extension spec, and refined every test assertion against an acceptance criterion.
- Plan used: `docs/ClickUpWideLayout/tickets/enable-copy-links-page-view/investigations/enable-copy-links-page-view-recon-and-plan.md`.
- Files/areas:
  - `docs/ClickUpWideLayout/tickets/enable-copy-links-page-view/specs/enable-copy-links-page-view-locked-decisions.md`
  - `docs/ClickUpWideLayout/tickets/enable-copy-links-page-view/specs/enable-copy-links-page-view-spec.md`
  - `docs/ClickUpWideLayout/tickets/enable-copy-links-page-view/stories/`
  - `docs/ClickUpWideLayout/tickets/enable-copy-links-page-view/testing/enable-copy-links-page-view-test-plan.md`
  - `docs/ClickUpWideLayout/tickets/enable-copy-links-page-view/enable-copy-links-page-view-why-these-changes.md`
- Spec review disposition: Not applicable — ClickUpWideLayout is a personal local non-Git extension, the user is the sole product/spec owner, and the canonical spec is delivered directly through orchestration rather than a shared wiki/PR surface.
- User-visible impact: None yet; no product code or UI changed.
- Tests run: Documentation artifact checks only; implementation gates remain in the refined test plan.

### 2026-08-11T16:42:57Z - ClickUpWideLayout

- Summary: Completed the report phase for `enable-copy-links-page-view`. Recorded the reclassification from a pane-only/UI problem to a shared context-resolution defect, reconciled the draft story, created the living Why, emitted the investigation/coverage/diagram package, and seeded executable resolver, popup, regression, and loaded-extension scenarios.
- Plan used: `docs/ClickUpWideLayout/tickets/enable-copy-links-page-view/investigations/enable-copy-links-page-view-recon-and-plan.md`.
- Files/areas:
  - `docs/ClickUpWideLayout/tickets/enable-copy-links-page-view/orchestration.md`
  - `docs/ClickUpWideLayout/tickets/enable-copy-links-page-view/enable-copy-links-page-view-why-these-changes.md`
  - `docs/ClickUpWideLayout/tickets/enable-copy-links-page-view/stories/`
  - `docs/ClickUpWideLayout/tickets/enable-copy-links-page-view/investigations/`
  - `docs/ClickUpWideLayout/tickets/enable-copy-links-page-view/testing/enable-copy-links-page-view-test-plan.md`
  - `docs/ClickUpWideLayout/tickets/enable-copy-links-page-view/enable-copy-links-page-view-pr-draft.md`
- User-visible impact: None yet; investigation artifacts only. Product code remains untouched pending the spec and implementation-plan gates.
- Tests run: `check-steps.ps1` artifact validation is run after materialization; product tests are deferred because no implementation file changed in this phase.

### 2026-08-11T16:03:24Z - ClickUpWideLayout

- Summary: Captured the `enable-copy-links-page-view` request as an immutable original ticket, scaffolded its orchestration ledger, and drafted the job story and acceptance-criteria baseline for Phase 0.
- Plan used: Orchestration Phase 0 capture; no Plans row added because the orchestration ledger is the workflow status record.
- Files/areas:
  - `docs/ClickUpWideLayout/tickets/enable-copy-links-page-view/original-ticket.md`
  - `docs/ClickUpWideLayout/tickets/enable-copy-links-page-view/orchestration.md`
  - `docs/ClickUpWideLayout/tickets/enable-copy-links-page-view/stories/`
- User-visible impact: None yet; capture artifacts only. The ClickUpWideLayout implementation folder was not touched.
- Tests run: Not relevant — documentation-only Phase 0 capture with no product behavior change.

### 2026-08-07T20:43:23Z - ClickUpWideLayout

- Summary: Simplified the popup again by removing every persistent secondary description. Layout and Header retain concise row titles with their explanatory text moved into tooltips. Task is now one `Full Markdown` row with adjacent copy and download controls, each carrying its own accessible tooltip.
- Plan used: Plans table -> `Move action details into tooltips`.
- Files/areas:
  - `C:\Users\dktho\OneDrive\PDProjects\Browser Extensions\ClickUpWideLayout\popup.html`: removed `action-detail` text, refined tooltip language, and combined the two Task rows into one title with copy/download actions.
  - `C:\Users\dktho\OneDrive\PDProjects\Browser Extensions\ClickUpWideLayout\popup.css`: tightened rows from 56px to 50px and added a small side-by-side action-control group.
  - `C:\Users\dktho\OneDrive\PDProjects\Browser Extensions\ClickUpWideLayout\tests\popup-markdown.test.mjs`: updated contracts for tooltip-only details and the single two-action Task row.
  - `docs/ClickUpWideLayout/tickets/export-clickup-ticket-to-markdown/testing/export-clickup-ticket-to-markdown-test-plan.md`: aligned tooltip and combined-row scenarios.
- User-visible impact: The menu now shows only `Extended layout`, `ID + title`, `Markdown link`, and `Full Markdown`. Explanations appear on hover/focus, and full-ticket copy/save live together in one row.
- Tests run:

  | Gate | Command | Scope | Result | Exception / risk |
  | ---- | ------- | ----- | ------ | ---------------- |
  | tests | `node --test tests/popup-markdown.test.mjs` | Tooltip-only details, single Task row/two controls, themes, Markdown parity, clipboard failure | pass - 6 tests | Loaded-extension interaction remains recommended after reload. |
  | syntax | `node --check popup.js; node --check theme.js; node --check content.js; node --check background.js` | Popup/theme and neighboring extension scripts | pass | - |
  | manifest | `Get-Content -Raw manifest.json \| ConvertFrom-Json` | Existing extension manifest | pass | - |
- Tests added/updated: The popup structure test now proves no `action-detail` or embedded button label remains, tooltip wording contains each former explanation, and the Task section has exactly one row with two controls.
- Visual verification: Headless Edge light/dark and hovered-copy renders at 312px confirmed an unclipped 391px-high popup, one Task row, two Task controls, readable spacing, and an inward-aligned `Copy complete task contents` tooltip.
- Regression impact: Button ids/listeners and all copy/download payloads are unchanged. Theme persistence, layout toggle, Save As, status messages, and in-page toasts remain intact.
- API docs: Not relevant - browser-extension popup markup/styling only; manifest permissions and ClickUp host scope are unchanged.
- Tooling gates: `npm` lint/audit remain unavailable because the extension has no `package.json`; Node tests, syntax checks, manifest parsing, and headless visual inspection are the applicable gates.

### 2026-08-07T19:59:35Z - ClickUpWideLayout

- Summary: Refined the popup interaction model so descriptive content and actions are visually separate. Every Layout/Header/Task item is now a full-width description row with title/detail text on the left and an independent toolbar-style icon button on the right. The three copy operations share the familiar Slate copy glyph; save and layout remain visually distinct. All action and theme controls expose custom hover/focus tooltips.
- Plan used: Plans table -> `Separate descriptions from icon actions`.
- Files/areas:
  - `C:\Users\dktho\OneDrive\PDProjects\Browser Extensions\ClickUpWideLayout\popup.html`: converted compact text buttons into semantic description rows with separate icon-only actions, accessible labels, and tooltip text.
  - `C:\Users\dktho\OneDrive\PDProjects\Browser Extensions\ClickUpWideLayout\popup.css`: replaced button-grid styling with spaced rows, separators, 32px toolbar controls, and viewport-safe custom tooltips.
  - `C:\Users\dktho\OneDrive\PDProjects\Browser Extensions\ClickUpWideLayout\popup.js`: keeps the theme tooltip synchronized with the active mode.
  - `C:\Users\dktho\OneDrive\PDProjects\Browser Extensions\ClickUpWideLayout\tests\popup-markdown.test.mjs`: updated structural/accessibility assertions for description-before-action ordering, shared copy glyphs, tooltips, and unchanged behavior.
  - `docs/ClickUpWideLayout/tickets/export-clickup-ticket-to-markdown/testing/export-clickup-ticket-to-markdown-test-plan.md`: added row/action separation and tooltip validation.
- User-visible impact: Users now read what each item represents on the left, then click a small, clearly separate action on the right. The interface has more breathing room without hiding meaning inside buttons.
- Tests run:

  | Gate | Command | Scope | Result | Exception / risk |
  | ---- | ------- | ----- | ------ | ---------------- |
  | tests | `node --test tests/popup-markdown.test.mjs` | Description/action separation, icon/tooltips, themes, exact Markdown parity, clipboard failure | pass - 6 tests | Loaded-extension interaction remains recommended after reload. |
  | syntax | `node --check popup.js; node --check theme.js; node --check content.js; node --check background.js` | Popup/theme logic and neighboring extension scripts | pass | - |
  | manifest | `Get-Content -Raw manifest.json \| ConvertFrom-Json` | Existing extension manifest | pass | - |
- Tests added/updated: Reworked the popup structure test to prove each description precedes its icon action, all three copy controls use the shared glyph, no visible label is embedded inside an action button, and tooltips appear for hover and keyboard focus.
- Visual verification: Headless Edge renders at the final 312px width confirmed 56px rows, 32px controls, complete unclipped light/dark layouts, correct row separators, and an inward-aligned `Copy ID + title` hover tooltip. Total content height is 471px, within Chrome's popup limit.
- Regression impact: Button ids/listeners, clipboard payloads, shared full-ticket formatter, Save As flow, layout toggle, theme persistence, status messages, and in-page toasts are unchanged.
- API docs: Not relevant - browser-extension popup markup and styling only; manifest permissions and host scope are unchanged.
- Tooling gates: `npm` lint/audit remain unavailable because the extension has no `package.json`; Node tests, syntax checks, manifest parsing, and headless visual inspection are the applicable gates.

### 2026-08-07T17:55:34Z - ClickUpWideLayout

- Summary: Refreshed the ClickUpWideLayout popup using SaySlate's minimal visual language. Added a compact brand header, persistent sun/moon theme toggle, light and Cursor-inspired dark palettes, inline SVG action icons, and distinct Layout, Header, and Task groups. Repeated subject prefixes moved into section headings so the individual actions remain concise.
- Plan used: Plans table -> `SaySlate-inspired popup refresh`.
- Files/areas:
  - `C:\Users\dktho\OneDrive\PDProjects\Browser Extensions\ClickUpWideLayout\popup.html`: replaced the flat button list with the grouped, accessible icon-led popup structure.
  - `C:\Users\dktho\OneDrive\PDProjects\Browser Extensions\ClickUpWideLayout\popup.css`: added the SaySlate-derived light/dark tokens, compact card/button styling, focus states, and reduced-motion handling.
  - `C:\Users\dktho\OneDrive\PDProjects\Browser Extensions\ClickUpWideLayout\theme.js`: added pre-render theme restoration with a safe light fallback.
  - `C:\Users\dktho\OneDrive\PDProjects\Browser Extensions\ClickUpWideLayout\popup.js`: added theme toggle/persistence logic, preserved SVG button contents during async operations, and routed popup status through themed classes.
  - `C:\Users\dktho\OneDrive\PDProjects\Browser Extensions\ClickUpWideLayout\tests\popup-markdown.test.mjs`: added grouped-markup, palette, theme persistence/bootstrap, and storage-failure coverage while retaining copy/export contracts.
  - `docs/ClickUpWideLayout/tickets/export-clickup-ticket-to-markdown/testing/export-clickup-ticket-to-markdown-test-plan.md`: added the theme and grouped-action scenarios/results.
- User-visible impact: The popup now presents three small sections with icon-led actions, a clearer visual hierarchy, and a top-right sun/moon control. Light mode uses the SaySlate off-white/green palette; dark mode uses its `#181818`/blue-gray palette and reopens in the last selected mode.
- Tests run:

  | Gate | Command | Scope | Result | Exception / risk |
  | ---- | ------- | ----- | ------ | ---------------- |
  | tests | `node --test tests/popup-markdown.test.mjs` | Grouped icon UI, theme tokens/toggle/bootstrap/fallback, exact Markdown parity, clipboard failure | pass - 6 tests | Loaded-extension visual review remains recommended after reload. |
  | syntax | `node --check popup.js; node --check theme.js; node --check content.js; node --check background.js` | New theme bootstrap, changed popup logic, neighboring scripts | pass | - |
  | manifest | `Get-Content -Raw manifest.json \| ConvertFrom-Json` | Existing popup permissions and extension manifest | pass | - |
- Tests added/updated: Extended the Node VM harness to cover theme persistence, saved-theme restoration before render, local-storage failure fallback, exact palette tokens, native-button appearance reset, grouping, icons, and all existing full-task Markdown behavior.
- Visual verification: Headless Edge rendered the popup at its 296px content width in both modes. Light and settled dark screenshots were inspected; grouping, wrapping, spacing, icon contrast, and the final dark button colors were correct. An initial screenshot taken during the 140ms theme transition briefly showed intermediate button colors; a settled render confirmed the responsible CSS rule resolves to dark surface `rgb(29, 31, 29)` and muted light text.
- Regression impact: Existing button ids and listeners are unchanged. Header/task clipboard payloads, shared full-ticket formatter, Save As flow, layout toggle messaging, and in-page toasts remain behaviorally identical. The manifest needs no new permissions.
- API docs: Not relevant - MV3 popup presentation and local theme preference only; manifest permissions and ClickUp host scope are unchanged.
- Tooling gates: `npm` lint/audit remain unavailable because the extension has no `package.json`; Node tests, syntax checks, manifest parsing, and headless visual inspection are the applicable gates.

### 2026-08-07T17:43:06Z - ClickUpWideLayout

- Summary: Cleaned up the popup action labels so each operation leads with the content it affects. Header-only copies now start with `Header:` and full-ticket operations start with `Task:`, making the distinction visible before the repeated Copy/Markdown wording.
- Plan used: Follow-up UI clarity cleanup for the implemented full-ticket Markdown copy action.
- Files/areas:
  - `C:\Users\dktho\OneDrive\PDProjects\Browser Extensions\ClickUpWideLayout\popup.html`: renamed the four copy/save actions with subject-first labels.
  - `C:\Users\dktho\OneDrive\PDProjects\Browser Extensions\ClickUpWideLayout\tests\popup-markdown.test.mjs`: extended popup markup coverage to lock the four labels and their task copy/save ordering.
- User-visible impact: The popup now reads `Header: Copy ID + Title`, `Header: Copy Markdown Link`, `Task: Copy Markdown`, and `Task: Save Markdown`, so users can distinguish header snippets from the complete task before reading the operation.
- Tests run:

  | Gate | Command | Scope | Result | Exception / risk |
  | ---- | ------- | ----- | ------ | ---------------- |
  | tests | `node --test tests/popup-markdown.test.mjs` | Subject-first labels, action ordering, exact download/copy parity, and clipboard toasts | pass - 3 tests | Live visual review still requires reloading the unpacked extension. |
  | syntax | `node --check popup.js; node --check content.js; node --check background.js` | Popup and neighboring extension scripts | pass | - |
  | manifest | `Get-Content -Raw manifest.json \| ConvertFrom-Json` | Existing extension manifest | pass | - |
- Tests added/updated: Extended the existing popup action test with exact label assertions; no new test case was needed because behavior is unchanged.
- Regression impact: Button ids, event bindings, clipboard payloads, formatter sharing, download behavior, and toast messages are unchanged; only user-visible labels changed.
- API docs: Not relevant - label-only browser-extension UI change; manifest permissions and host scope are unchanged.
- Tooling gates: `npm` lint/audit remain unavailable because the extension has no `package.json`; Node tests and syntax checks are the available executable gates.

### 2026-08-07T17:36:00Z - ClickUpWideLayout

- Summary: Added `Copy Task Markdown` to the popup. The copy and download actions now share one task collection/formatting helper, and the new action writes the full original-ticket Markdown as plain text so clipboard content is byte-for-byte identical to the saved document.
- Plan used: Plans table -> `Copy full ticket Markdown to clipboard`, implemented as a narrow follow-up to the active export plan.
- Files/areas:
  - `C:\Users\dktho\OneDrive\PDProjects\Browser Extensions\ClickUpWideLayout\popup.html`: added the new popup action beside the existing Markdown operations.
  - `C:\Users\dktho\OneDrive\PDProjects\Browser Extensions\ClickUpWideLayout\popup.js`: added the copy coordinator, shared `prepareCurrentTaskMarkdown()` path, plain-text clipboard handling, and success/failure toast messages.
  - `C:\Users\dktho\OneDrive\PDProjects\Browser Extensions\ClickUpWideLayout\tests\popup-markdown.test.mjs`: added focused success and clipboard-denial regression coverage.
  - `docs/ClickUpWideLayout/tickets/export-clickup-ticket-to-markdown/testing/export-clickup-ticket-to-markdown-test-plan.md`: added the full-ticket clipboard scenarios and automated results.
- User-visible impact: A task's complete exported Markdown can now be copied directly from the popup without downloading and reopening the file. Success shows `Copied task Markdown.`; clipboard denial shows the existing `Clipboard blocked. Try again.` toast.
- Tests run:

  | Gate | Command | Scope | Result | Exception / risk |
  | ---- | ------- | ----- | ------ | ---------------- |
  | tests | `node --test tests/popup-markdown.test.mjs` | Popup action wiring, exact download/copy parity, plain-text clipboard behavior, success toast, clipboard-denial toast | pass - 3 tests | Live popup clipboard permission behavior still requires a loaded-extension check. |
  | syntax | `node --check popup.js; node --check content.js; node --check background.js` | Changed popup plus neighboring content/background scripts | pass | - |
  | manifest | `Get-Content -Raw manifest.json \| ConvertFrom-Json` | Existing extension manifest and clipboard/download permissions | pass | - |
- Tests added/updated: Added a Node VM popup harness that clicks both real popup handlers and asserts decoded download text equals clipboard text exactly; it also asserts the shared clipboard failure toast.
- Regression impact: Existing `Copy ID - Title` and heading-link `Copy as Markdown` still use rich-plus-plain clipboard payloads. Only the new full-ticket action takes the plain-text-only branch; download formatting, DOM collection, layout toggling, and manifest permissions are unchanged.
- API docs: Not relevant - this is an MV3 popup-only change; `manifest.json` permissions and ClickUp host permission were checked and are unchanged.
- Tooling gates: `npm` lint/audit are not applicable because the extension has no `package.json`; Node syntax and built-in tests are the available executable gates.

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
