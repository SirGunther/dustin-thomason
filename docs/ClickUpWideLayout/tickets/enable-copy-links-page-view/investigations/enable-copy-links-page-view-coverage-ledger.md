# Coverage ledger — ClickUpWideLayout/enable-copy-links-page-view

Investigation question: Why can the existing ID/title and Markdown-link controls lose task links on a directly opened ClickUp task, and how can both contexts share one metadata contract?
Repo(s): ClickUpWideLayout browser extension, dustin-thomason docs · Baseline commit: n/a — extension folder is not a Git repository · Started: 2026-08-11

## Consulted

- `docs/ClickUpWideLayout/tickets/*/investigations/*-coverage-ledger.md` for “copy”, “Markdown”, “task URL”, “popup”, “pane”, “header”, `popup.js`, and `content.js` — found `export-clickup-ticket-to-markdown`; reused its proven task selectors, active-tab permissions, and existing copy/export neighbor notes. Reopened popup/content/background because code changed after its 2026-07-20 `n/a` baseline and this ticket concerns link-copy context rather than export.

## Areas examined

### 1. Existing popup copy entry points and payloads

| Field | Value |
| --- | --- |
| Inspected | `popup.html` Header controls; `popup.js` listeners, `copyCurrentTask`, `findTaskMeta`, `formatTaskCopy`, `formatTaskMarkdown`, `copyPayload`, toast flow |
| Findings | Exactly two relevant existing controls call one popup workflow; plain output is `ID - title` plus URL and Markdown is `# [title - ID](url)`; popup owns ID/title selectors while content API owns URL resolution |
| Status | contributing |
| Commit | n/a · 2026-08-11 |
| Evidence | `popup.html:67-105`; `popup.js:36-90`; `popup.js:180-203`; `popup.js:962-975`; `popup.js:1095-1117`; repository-wide `rg` enumeration |
| Notes | Reopened for a different behavior and post-July popup changes; both controls and all formatter/copy callers were enumerated |

### 2. Content metadata and task URL resolution

| Field | Value |
| --- | --- |
| Inspected | `window.__CU_LAYOUT_API__`, `copyIdAndTitle`, `getTaskHref`, current-URL test, anchor scan, DOM-context scan, retry/toast behavior |
| Findings | ID/title extraction is duplicated; current URL is accepted only when it contains the displayed ID; otherwise resolver depends on anchors/nearby DOM and can return `null` on a direct internal-ID route; content API is the existing shared seam |
| Status | contributing |
| Commit | n/a · 2026-08-11 |
| Evidence | `content.js:98-151`; `content.js:303-385`; `rg` found no live callers of `copyIdAndTitle` outside its definition |
| Notes | Reopened because the current question is context selection, not the prior export behavior |

### 3. Content injection, permissions, and backend boundary

| Field | Value |
| --- | --- |
| Inspected | `background.js` content pre-injection and toggle injection; `manifest.json` permissions and ClickUp host scope; popup `ensureContentScript` |
| Findings | Background injects `content.js` after ClickUp tab completion and popup ensures it before copying; `activeTab`, `scripting`, `clipboardWrite`, and ClickUp host permissions already cover the fix; no HTTP/API surface exists or is required |
| Status | ruled-out |
| Commit | n/a · 2026-08-11 |
| Evidence | `background.js:63-97`; `background.js:127-134`; `popup.js:62-64`; `popup.js:173-178`; `manifest.json` |
| Notes | Reopened because source-page availability depends on injection; no changes are expected in background or manifest |

### 4. Existing automated detection net

| Field | Value |
| --- | --- |
| Inspected | `tests/popup-markdown.test.mjs` VM harness, popup structure assertions, theme tests, full-ticket copy/export tests |
| Findings | No runtime assertion exercises `copy-task`, `copy-task-markdown`, `findTaskMeta`, `getTaskHref`, full-page route mismatch, or pane URL resolution |
| Status | contributing |
| Commit | n/a · 2026-08-11 |
| Evidence | `tests/popup-markdown.test.mjs`; search for copy IDs and resolver symbols |
| Notes | Detection failure directly defines the required red→green resolver and exact-payload tests |

### 5. Authenticated full-screen ClickUp DOM — PRDV-16313

| Field | Value |
| --- | --- |
| Inspected | Current URL/title; ID/title selectors and values; full-screen mode/container markers; task header candidates; visible copy/link controls |
| Findings | URL is `https://app.clickup.com/t/43227262/PRDV-16313`; ID selector returns `PRDV-16313`; title selector is a visible textarea; `[data-test="task-view__mode--full-screen"]` and full-screen container are present; ClickUp exposes native Copy Task ID only, not the extension’s two payloads |
| Status | fully-inspected |
| Commit | n/a · 2026-08-11 |
| Evidence | Playwright `chromium.connectOverCDP('http://localhost:9222')` read-only DOM evaluation against authenticated Chrome |
| Notes | This is a positive-control URL because its route already contains the custom ID; it grounds selectors/context but does not reproduce the internal-route mismatch |

## Not yet inspected (frontier)

- Loaded unpacked-extension behavior after implementation — both current popup controls must be exercised on full-page and pane tasks.
- A live direct task URL whose route uses an internal ID while the rendered task displays a custom ID — the red→green unit fixture is mandatory even if a live variant is unavailable.
- Clipboard payload readback and failure feedback in the reloaded user profile — required manual proof after code changes.
