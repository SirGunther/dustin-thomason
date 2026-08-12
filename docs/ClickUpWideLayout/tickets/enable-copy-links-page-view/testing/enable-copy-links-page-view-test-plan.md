# Test plan — ClickUpWideLayout/enable-copy-links-page-view

> Seeded from [enable-copy-links-page-view-investigation.md](../investigations/enable-copy-links-page-view-investigation.md) §9 on 2026-08-11. Refined by [spec](../specs/enable-copy-links-page-view-spec.md) on 2026-08-11.

Status: implementation verified; loaded-extension manual review pending

## Scope and surfaces under test

- Context-aware task metadata from `content.js`, delegation from the two existing popup Header copy controls, exact plain/Markdown payloads, safe failure, and regressions around pane resolution, full-ticket Markdown, layout toggle, and theme.
- No new ClickUp-page UI or backend/API surface is expected; unchanged UI is part of the proof.

## Happy path

- [ ] HP-1 `[AC-1, AC-3, AC-5]`: with visible ID `PRDV-12345`, title `Direct task`, full-page marker, and URL `https://app.clickup.com/t/43227262/86abc123` → choose `ID + title` → clipboard plain text is exactly `PRDV-12345 - Direct task\nhttps://app.clickup.com/t/43227262/86abc123` and the existing success toast appears.
- [ ] HP-2 `[AC-2, AC-3, AC-5]`: use the same direct full-page task → choose `Markdown link` → clipboard plain text is exactly `# [Direct task - PRDV-12345](https://app.clickup.com/t/43227262/86abc123)` and the existing Markdown success toast appears.
- [ ] HP-3 `[AC-3, AC-4]`: render the task in an existing pane/sidebar variant with a matching task anchor → choose both existing formats → the anchor URL and established payloads are unchanged.

## Negative paths

- [ ] NP-1 `[AC-3]`: ID or title remains unavailable through the bounded retry window → choose either copy action → no clipboard write occurs and the existing task-details error is visible.
- [ ] NP-2 `[AC-3]`: run metadata resolution on a non-task ClickUp page with no matching task anchor → resolver returns no unrelated current URL.
- [ ] NP-3 `[AC-5]`: reject rich and plain clipboard writes → existing clipboard-blocked toast appears and the popup closes through the established path.

## Edge cases

- [ ] EC-1 `[AC-1, AC-2]`: full-page URL already contains the visible custom ID → context-aware provider returns the current URL exactly as before.
- [ ] EC-2 `[AC-1, AC-2, AC-3]`: ID/title appears during the existing retry window → exactly one active-task payload is copied; no stale metadata is cached between task navigations.
- [ ] EC-3 `[AC-4]`: pane task changes through ClickUp SPA navigation → the next click resolves the newly active task rather than the prior task.
- [ ] EC-4 `[AC-4]`: run existing full-ticket copy/export, theme, layout-toggle, syntax, and manifest checks → all remain unchanged while pane copy remains available.

## Locked assertions from Phase 3

- `getTaskMeta()` returns `{ id, title, url, context }` or `null`, with context limited to `full-page`, `pane`, or `unknown`.
- The metadata provider performs at most eight reads separated by 150 ms and stores no task metadata between clicks.
- A rendered full-page task on an `https://app.clickup.com/t/...` route uses the current URL even when the displayed custom ID is absent from the route.
- Pane and unknown contexts never receive an unconditional current-URL fallback.
- No visible popup or ClickUp-page UI, payload formatter, toast, full-ticket export, theme, layout, background, or manifest behavior changes.

## Manual verification

Phase 5 automated and live-provider execution passed. The authenticated Chrome page was available through CDP, but that Chrome instance did not have the unpacked extension loaded (`window.__CU_LAYOUT_API__` was initially absent), so popup clicking/pasting and pane interaction remain the explicit Phase 6 manual-review scope.

Written so someone who did not build the change can execute it without asking a follow-up question.

**Before / after**

| | Before | After |
| --- | --- | --- |
| ClickUp page UI | No extension-owned copy control in the page | Identical; no new page control is added |
| Extension popup Header | Existing `ID + title` and `Markdown link` controls | Identical labels, order, and interaction |
| Direct full-page URL with a route ID different from displayed ID | Link lookup can return no URL | Both existing controls copy the active task’s current `/t/...` URL |
| Pane task | Existing anchor/DOM URL resolution | Identical output and feedback |

**Preconditions**

- Chrome launched with remote debugging on port 9222 and authenticated to ClickUp.
- The unpacked extension reloaded from `C:\Users\dktho\OneDrive\PDProjects\Browser Extensions\ClickUpWideLayout` after implementation.
- One task opened directly at its own `/t/...` URL and one task available in a pane/sidebar context.
- A plain-text editor available for exact clipboard inspection.

**Steps**

1. Open a full-screen ClickUp task directly and record the visible task ID, title, and browser URL.
2. Open the extension popup, choose `ID + title`, paste into the editor, and compare both lines with the active task.
3. Repeat with `Markdown link` and compare the entire heading-link string.
4. Confirm the ClickUp page gained no new extension-owned copy button or menu.
5. Open a task as a pane/sidebar, repeat Steps 2–3, and compare its payload with that pane’s active task.
6. Navigate to a non-task ClickUp page or test missing metadata, invoke a copy action, and confirm visible failure with no stale clipboard payload.
7. Exercise full-ticket copy/save, theme toggle, and layout toggle once each.

**Evidence**

```powershell
node --test tests/popup-markdown.test.mjs tests/content-links.test.mjs
node --check popup.js
node --check content.js
node --check background.js
Get-Content -Raw manifest.json | ConvertFrom-Json | Out-Null
```

Capture one screenshot containing the full-screen ClickUp URL/task identity and the unchanged extension popup, plus pasted plain and Markdown payload text. Capture a second screenshot for the pane payload if its context is not obvious in the first.

**Pass / fail**

| Step | Passes | Fails |
| --- | --- | --- |
| M-1 | Recorded ID/title/URL all describe the same active task | Any value belongs to another task or cannot be identified |
| M-2 | Plain payload matches exact two-line contract and current URL | URL missing, stale, or belongs to another context |
| M-3 | Markdown payload matches exact heading-link contract | Missing/incorrect URL, title, ID, or punctuation |
| M-4 | ClickUp page UI is unchanged | Any extra extension-owned page control appears |
| M-5 | Pane outputs remain byte-for-byte compatible | Existing pane copy behavior regresses |
| M-6 | Failure is visible and no stale value is copied | Silent failure or unrelated current-page URL copied |
| M-7 | Neighbor behaviors still complete normally | Export, theme, or layout toggle changes unexpectedly |

M-2 is load-bearing because a missing/wrong URL on the direct full-page route is the exact defect returning.

## Test map

| Repo | Suite | Asserts |
| --- | --- | --- |
| ClickUpWideLayout | `tests/content-links.test.mjs` | Context detection, internal-route mismatch, custom-ID URL, pane anchor fallback, unknown-page safety, retries |
| ClickUpWideLayout | `tests/popup-markdown.test.mjs` | Both existing popup payloads, clipboard/toast behavior, unchanged popup/full-ticket/theme contracts |
| ClickUpWideLayout | authenticated Chrome manual loop | Loaded-extension parity across full-page and pane tasks with no new page UI |

## Gates

| Gate | Command |
| --- | --- |
| tests | `node --test tests/popup-markdown.test.mjs tests/content-links.test.mjs` |
| syntax | `node --check popup.js`; `node --check content.js`; `node --check background.js` |
| manifest | `Get-Content -Raw manifest.json | ConvertFrom-Json | Out-Null` |

The extension has no `package.json`, so package audit and lint gates are not available. Node tests, syntax checks, manifest parsing, and loaded-extension manual proof are the applicable gates.

## Results log (filled at execution)

| Date | Gate/Scenario | Command | Scope | Result | Exception / risk |
| --- | --- | --- | --- | --- | --- |
| 2026-08-11 | package audit availability | `Test-Path package.json` | Extension root | not available | No `package.json`; no package dependency surface to audit. |
| 2026-08-11 | package lint availability | `Test-Path package.json` | Extension root | not available | No configured lint command; syntax and focused tests are the applicable substitutes. |
| 2026-08-11 | self-review | `git diff --no-index` plus `docs/reviewers/pr-review-patterns.md` | `content.js`, `popup.js`, focused tests | pass | Context magic strings were promoted to named constants; nearby-DOM and failure coverage were added before the final gate. |
| 2026-08-11 | syntax | `node --check popup.js`; `node --check content.js`; `node --check background.js` | Popup, content API, neighboring background worker | pass | No syntax errors. |
| 2026-08-11 | manifest | `Get-Content -Raw manifest.json \| ConvertFrom-Json \| Out-Null` | Existing MV3 manifest | pass | No manifest or permission change. |
| 2026-08-11 | HP-1 through HP-3, NP-1 through NP-3, EC-1 through EC-3, full-ticket/theme regression | `node --test tests/popup-markdown.test.mjs tests/content-links.test.mjs` | Resolver, exact popup payloads, feedback, retry/no-cache, pane navigation, neighboring popup behavior | pass — 18 tests | Layout-toggle runtime interaction remains in Phase 6; its source and manifest were unchanged. |
| 2026-08-11 | live full-page provider proof | Authenticated Chrome CDP evaluation of installed `content.js` | Visible `PRDV-16313`; original custom-ID URL and temporary internal-ID mismatch route | pass | Returned `{ id, title, url, context: "full-page" }` in both cases; original URL restored; zero extension-owned page copy controls. |
| 2026-08-11 | loaded-extension popup/pane loop | Authenticated Chrome on port 9222 | Exact clipboard paste, popup controls, pane, layout toggle | pending Phase 6 | Chrome was authenticated but the unpacked extension was not loaded, so actual popup interaction could not be claimed. |
