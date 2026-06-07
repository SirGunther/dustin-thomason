# WorkLists App Changelog

## Purpose

Track implementation sessions and current delivery status for the WorkLists application.

## Scope

- Product and technical changes inside `WorkLists`.
- User-visible behavior changes.
- Verification executed during implementation sessions.

## Notes Initiative UI/UX Checklist

- Keep every notes-pane control fully inside the viewport at minimum, default, and user-resized widths.
- Prevent horizontal page or pane scroll caused by note content, editor chrome, toolbar controls, long words, URLs, tables, code blocks, timestamps, or action labels.
- Use vertical scrolling only where it helps the user: note list, card preview, markdown preview, visual editor, and long code/table content.
- Preserve stable pane dimensions when loading, empty, editing, saving, deleting, resizing, switching modes, and rendering markdown.
- Keep the add-note form reachable at the bottom without being pushed offscreen by long note lists.
- Keep toolbar controls wrapped, padded, and scannable without clipping or shrinking into ambiguous targets.
- Use familiar icons for compact commands when available, with accessible labels and titles.
- Keep text labels only where they improve clarity, such as mode tabs and primary submit context.
- Ensure action buttons have consistent size, spacing, alignment, hover/focus states, disabled states, and hit targets.
- Keep destructive actions visually distinct without making the pane visually noisy.
- Keep inline edit controls visually attached to the note being edited and aligned to the expected confirmation/cancel pattern.
- Ensure textarea, visual editor, and preview surfaces share coherent padding, borders, typography, focus styling, and sizing.
- Keep mode switching from causing layout jumps beyond the expected editor expansion.
- Keep empty, loading, and error states readable and aligned with the pane structure.
- Ensure markdown tables, fenced code blocks, blockquotes, lists, checkboxes, links, and headings render without breaking the pane layout.
- Ensure long card titles and note timestamps wrap or truncate safely without crowding close/edit/delete actions.
- Maintain keyboard behavior: Escape stays local to note drafts/inline edits, Ctrl+Enter submits/saves, and tab order remains sensible.
- Keep resizing behavior coherent with the editor: width clamps, persisted width, and responsive behavior must not create unreachable controls.
- Avoid nested-card visual clutter; notes may be cards, but editor controls should feel like a focused tool surface.
- Keep color usage balanced with the existing WorkLists dark UI and avoid introducing a new dominant palette.
- Bring AI note creation and note refinement to parity with card-level AI actions, including coherent placement, progress feedback, error handling, and persistence.

## Session log (newest first)

### 2026-06-07T16:51:54Z — WorkLists

- Summary: Standardized reset/filter/scheduler header controls around compact icon buttons.
- Problem: The column reset control used an ambiguous `O`/circle marker, and the top-right filter/scheduler buttons spent too much toolbar space on visible labels.
- Requirement: Column reset must use a recognizable refresh/reload icon, and the header filter/scheduler controls must remain discoverable through accessible labels/tooltips while becoming compact icon-first buttons.
- Solution:
  - Replaced the column reset text marker with a Font Awesome refresh icon plus `title` and `aria-label`.
  - Converted the filters button to an icon-only visible control with a visually hidden label for assistive technology.
  - Removed the visible Scheduler text label, kept the compact scheduled-count badge, and updated the scheduler tooltip/ARIA label to include the current count.
  - Tightened header button CSS so the controls have stable compact dimensions.
- Files/areas: `public/index.html`, `public/todolist2.js`, `public/todoliststyles2.css`, `tests/column-actions.test.js`, `tests/filter-menu.test.js`, `tests/search-scopes.test.js`, `tests/scheduler.test.js`, `docs/worklists/worklists-app-changelog.md`.
- User-visible impact:
  - Column reset now reads as a refresh/reset action instead of a confusing circle.
  - Filters and Scheduler take less room in the top-right toolbar while preserving hover tooltips and screen-reader labels.
- Tests run:

  | Gate   | Command                                                                                                                                                                                            | Scope                                           | Result          | Exception / risk                                                                                                     |
  | ------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------- | --------------- | -------------------------------------------------------------------------------------------------------------------- |
  | audit  | `npm audit --audit-level=high`                                                                                                                                                                     | WorkLists dependencies                          | pass            | Existing 3 moderate `qs`/`body-parser`/`express` advisories remain with no fix available; high/critical gate passes. |
  | syntax | `node --check public\todolist2.js`                                                                                                                                                                 | Board UI script                                 | pass            | —                                                                                                                    |
  | format | `npx prettier --write public/index.html public/todolist2.js public/todoliststyles2.css tests/column-actions.test.js tests/filter-menu.test.js tests/search-scopes.test.js tests/scheduler.test.js` | Touched UI/test files                           | pass            | Files were unchanged by formatting.                                                                                  |
  | lint   | `npm run lint`                                                                                                                                                                                     | Repo Prettier check                             | pass            | —                                                                                                                    |
  | tests  | `npm test -- tests\column-actions.test.js tests\filter-menu.test.js tests\search-scopes.test.js tests\scheduler.test.js`                                                                           | Focused column/header filter/scheduler coverage | pass, 41 tests  | —                                                                                                                    |
  | tests  | `npm test`                                                                                                                                                                                         | Full suite                                      | pass, 366 tests | —                                                                                                                    |

- Tests added/updated: Updated source-regression tests to assert the refresh reset icon, compact filter/scheduler markup, accessible labels/tooltips, and compact toolbar CSS.
- Regression impact: Column header and top navigation controls were touched; regression is bounded to button markup/styling and verified by focused source tests plus the full suite.
- API docs: Not affected; UI-only markup/styling behavior, with no HTTP route, method, request body, response shape, status, or auth contract changed.
- Tooling gates: Audit threshold, syntax check, formatting, repo-wide lint, focused tests, and full tests passed.
- Conflicts / exceptions: Worktree already contained active-board/session-storage edits in `public/todolist2.js`, `tests/board-refresh.test.js`, and this changelog; this session preserved and layered on top of them. Audit still reports existing moderate advisories below the configured gate.

### 2026-06-06T17:53:42Z — WorkLists

- Summary: Made active board selection persist per browser tab/window.
- Problem: Active board selection was stored as `localStorage.currentBoardId`, so refreshing one tab could adopt the most recently selected board from another tab and disrupt separate WorkLists contexts.
- Requirement: Each browser tab/window must restore its own active board on refresh while shared board data, pinned boards, and real-time data refreshes continue to work across tabs.
- Solution:
  - Moved active board persistence from shared `localStorage` to tab-scoped `sessionStorage`.
  - Added session-aware active-board resolution during initial load so refreshes restore the tab's board and ignore shared last-active state.
  - Validated requested boards after refreshed server data is loaded, falling back locally to an available board if the tab's saved board was deleted.
- Files/areas: `public/todolist2.js`, `tests/board-refresh.test.js`, `docs/worklists/worklists-app-changelog.md`.
- User-visible impact:
  - Multiple tabs can stay on different boards; refreshing one tab keeps that tab on its own board.
  - Switching boards in one tab no longer changes another tab's refresh target.
  - Shared board data updates still load from the server for the active tab context.
- Tests run:
  - `npm audit --audit-level=high` — pass for high/critical threshold; reports 3 moderate `qs`/`body-parser`/`express` advisories with no fix available.
  - `node --check public\todolist2.js` — pass.
  - `npx prettier --check public/todolist2.js tests/board-refresh.test.js` — pass.
  - `npm test -- tests\board-refresh.test.js` — pass, 6 tests.
  - `npm run lint` — pass.
  - `npm test` — pass, 366 tests.
- Tests added/updated: Added board-refresh regression coverage proving active board persistence uses `sessionStorage`, no longer reads/writes `localStorage.currentBoardId`, and retains refresh behavior from the fetched server snapshot.
- Regression impact: Active board selection and board refresh routing were touched; regression is bounded to `currentBoardId` resolution/storage and verified by focused board-refresh tests plus the full test suite.
- API docs: Not affected; UI/session-storage behavior only, with no HTTP route, method, request body, response shape, status, or auth contract changed.
- Tooling gates: Audit threshold, syntax check, targeted Prettier, repo-wide lint, focused tests, and full tests passed.
- Conflicts / exceptions: `npm audit` still reports existing moderate advisories with no fix available; high/critical threshold passes.

### 2026-06-05T18:45:11Z — WorkLists

- Summary: Matched the notes-pane card-description toolbar to saved-note actions.
- Problem: The notes pane now allowed copying card text, but the card-description block still had fewer actions than saved notes, making the top block feel inconsistent with the rest of the pane.
- Requirement: The notes-pane card description must expose the same action set and ordering as a saved note: edit, AI refine, copy, and delete, while reusing existing card-level behavior and feedback.
- Solution:
  - Added card-description AI refine and delete icon buttons between the existing edit/copy controls so the toolbar order matches saved notes.
  - Routed card-description AI refine through `refineCardWithGemma`, including the existing in-flight disabled/spinner state.
  - Routed card-description delete through the existing undoable card delete flow, then closed the notes pane after the card is removed.
- Files/areas: `public/todolist2.js`, `tests/context-windows.test.js`, `tests/gemma-ui.test.js`, `docs/worklists/worklists-app-changelog.md`.
- User-visible impact:
  - The notes-pane card description now has edit, AI refine, copy, and delete actions like individual notes.
  - Deleting from the card-description toolbar deletes the card and keeps the existing `Undo` toast recovery.
  - AI refine from the card-description toolbar uses the same model-backed card refine path as the board card menu.
- Tests run:
  - `npm audit --audit-level=high` — pass for high/critical threshold; reports 3 moderate `qs`/`body-parser`/`express` advisories with no fix available.
  - `node --check public\todolist2.js` — pass.
  - `npx prettier --check public/todolist2.js tests/context-windows.test.js tests/gemma-ui.test.js` — pass.
  - `npm test -- tests/context-windows.test.js tests/task-clipboard.test.js tests/markdown-renderer.test.js tests/gemma-ui.test.js` — pass, 67 tests.
  - `npm test` — pass, 365 tests.
  - `npm run lint` — blocked by pre-existing formatting warning in `prompts/gemma-classify-instructions.md`; touched files pass targeted Prettier.
- Tests added/updated: Added source regression coverage for the card-description edit/AI/copy/delete toolbar, AI refine routing, delete routing, accessible labels, and notes-pane AI in-flight sync.
- Regression impact: Notes-pane card-description action wiring and AI state sync were touched; focused context/clipboard/markdown/AI tests and full unit tests passed.
- API docs: Not affected; this is UI-only and no HTTP route, method, request body, response shape, status, or auth contract changed.
- Tooling gates: Audit threshold, syntax check, targeted Prettier, focused tests, and full tests passed; repo-wide lint remains blocked only by the existing prompt formatting warning.
- Conflicts / exceptions: Worktree contains pre-existing unrelated modifications/untracked files; this session did not revert them. Lint exception is unrelated to this session and remains in `prompts/gemma-classify-instructions.md`.

### 2026-06-05T18:37:56Z — WorkLists

- Summary: Added notes-pane copy actions and fixed notes-pane markdown code-block copy styling.
- Problem: Card descriptions and individual notes could be read from the notes pane, but users could not copy those full bodies there, and fenced-code copy controls rendered with the wrong placement because their styling was only scoped to board cards.
- Requirement: Notes-pane card descriptions, saved note bodies, and fenced code blocks must copy through the existing clipboard/toast pattern while preserving the authored markdown source. Note copy should include the note body only; timestamps remain metadata and are not prefixed into clipboard content.
- Solution:
  - Added compact copy icon buttons beside the existing notes-pane card edit action and saved-note edit/AI/delete actions.
  - Reused `copyTaskContent` with per-surface toast messages so card-description copies keep the existing toast wording and note copies show note-specific success/failure toasts.
  - Stored raw markdown on notes-pane rendered card/note bodies and bound code-block copy controls inside notes-pane markdown read surfaces.
  - Added notes-pane CSS for fenced-code copy button/status placement, hover/focus reveal, error state, and touch visibility.
- Files/areas: `public/todolist2.js`, `public/todoliststyles2.css`, `tests/task-clipboard.test.js`, `tests/context-windows.test.js`, `docs/worklists/worklists-app-changelog.md`.
- User-visible impact:
  - The notes pane now lets users copy the visible card description and each individual note from their nearby action toolbar.
  - Copied card/note content preserves authored markdown and line breaks.
  - Fenced code blocks in the notes pane show the same correctly positioned copy affordance as board card markdown.
- Tests run:
  - `npm audit --audit-level=high` — pass for high/critical threshold; reports 3 moderate `qs`/`body-parser`/`express` advisories with no fix available.
  - `node --check public\todolist2.js` — pass.
  - `npx prettier --check public/todolist2.js public/todoliststyles2.css tests/task-clipboard.test.js tests/context-windows.test.js` — pass.
  - `npm test -- tests/task-clipboard.test.js tests/context-windows.test.js tests/markdown-renderer.test.js` — pass, 41 tests.
  - `npm test` — pass, 364 tests.
  - `npm run lint` — blocked by pre-existing formatting warning in `prompts/gemma-classify-instructions.md`; touched files pass targeted Prettier.
- Tests added/updated: Added source regression coverage for notes-pane copy buttons, note-specific copy toasts, raw-source attributes, notes-pane code-copy binding, and accessible copy labels.
- Regression impact: Notes-pane read rendering, copy behavior, and markdown code-block controls were touched; focused clipboard/context/markdown tests and full unit tests passed.
- API docs: Not affected; this is UI-only and no HTTP route, method, request body, response shape, status, or auth contract changed.
- Tooling gates: Audit threshold, syntax check, targeted Prettier, focused tests, and full tests passed; repo-wide lint remains blocked only by the existing prompt formatting warning.
- Conflicts / exceptions: Worktree contains pre-existing unrelated modifications/untracked files; this session did not revert them. Lint exception is unrelated to this session and remains in `prompts/gemma-classify-instructions.md`.

### 2026-06-03T16:15:21Z — WorkLists

- Summary: Added toast feedback and undo actions for card API operations.
- Problem: User-triggered API mutations could complete silently or without a nearby recovery path, especially card moves, deletes, and completion toggles.
- Requirement: API actions must give descriptive toast feedback, destructive/reversible item actions must expose `Undo`, and edit-context AI refinement must be visible and reversible through the existing AI undo toast flow.
- Solution:
  - Added an inline edit-context AI refine button that saves the draft, starts the existing AI refine job, and keeps completed refinements undoable through the existing AI toast path.
  - Added undo-capable toasts for card moves, card deletes, and card completion toggles, including note restoration for deleted-card undo.
  - Added manual add-card success/failure toast feedback and kept copy success/failure on the shared toast system.
- Files/areas: `public/todolist2.js`, `public/todoliststyles2.css`, `tests/card-actions.test.js`, `tests/card-move-ui.test.js`, `tests/task-clipboard.test.js`, `tests/edit-session.test.js`, `docs/worklists/worklists-app-changelog.md`.
- User-visible impact:
  - Moving, deleting, completing, and adding cards now produces clear bottom-right toast feedback.
  - Moved, deleted, and completed cards can be restored from the toast `Undo` action.
  - Inline card editing now includes a compact AI refine wand button in addition to the existing hotkey.
- Tests run:
  - `npm audit --audit-level=high` — pass for high/critical threshold; reports 3 moderate `qs`/`body-parser`/`express` advisories with no fix available.
  - `node --check public/todolist2.js` — pass.
  - `npm test -- tests/card-actions.test.js tests/card-move-ui.test.js tests/task-clipboard.test.js tests/edit-session.test.js tests/gemma-ui.test.js` — pass, 61 tests.
  - `npm test` — pass, 362 tests.
  - `npm run lint` — blocked by pre-existing formatting warning in `prompts/gemma-classify-instructions.md`; touched files were formatted with Prettier.
- Tests added/updated: Added source regression coverage for edit-context AI refine wiring, undo-capable delete/complete/move toasts, manual add-card toast feedback, and the shared edit refine helper.
- Regression impact: Card action feedback, inline edit AI controls, card move handling, delete handling, and completion toggling were touched; focused UI tests and the full suite passed.
- API docs: Not affected; no HTTP route, method, request body, response shape, status, or auth contract changed.
- Tooling gates: Audit threshold, syntax check, focused tests, and full tests passed; repo lint remains blocked only by the existing prompt formatting warning.
- Conflicts / exceptions: Worktree contains pre-existing unrelated modifications/untracked files; this session did not revert them. Lint exception is unrelated to this session and remains in `prompts/gemma-classify-instructions.md`.

### 2026-06-03T16:05:13Z — WorkLists

- Summary: Enhanced column counter tooltip styling.
- Problem: The column item counter exposed useful metrics through the browser's native tooltip, but the default tooltip was visually plain and hard to scan.
- Requirement: Counter metrics must remain lightweight while presenting as a styled WorkLists UI surface with clear metric grouping and keyboard access.
- Solution:
  - Replaced the native `title` tooltip with a structured `.column-metrics-tooltip` panel inside the counter.
  - Added hover/focus reveal styling, a pointer, metric tiles, date rows, and focus ring support.
  - Kept the counter position unchanged so it still sits left of the reset and column action icons.
- Files/areas: `public/todolist2.js`, `public/todoliststyles2.css`, `tests/column-actions.test.js`, `docs/worklists/worklists-app-changelog.md`.
- User-visible impact:
  - Hovering or focusing the column counter now shows a styled dark metrics panel instead of a native tooltip.
  - Metrics are grouped into open/complete/tag tiles plus compact untagged and creation-date rows.
- Tests run:
  - `node --check public/todolist2.js` — pass.
  - `npm test -- tests/column-actions.test.js` — pass, 20 tests.
  - `npm test` — pass, 358 tests.
  - `npm run lint` — blocked by pre-existing formatting warning in `prompts/gemma-classify-instructions.md`; touched files pass after targeted Prettier formatting.
- Tests added/updated: Updated column header regression coverage for the structured tooltip markup and CSS reveal rules.
- Regression impact: Column counter rendering and tooltip styling were touched; focused column tests and full unit tests passed.
- API docs: Not affected; this is UI-only and no HTTP contract changed.
- Tooling gates: Syntax check, focused tests, and full tests passed; repo lint remains blocked only by the existing prompt formatting warning.
- Conflicts / exceptions: Lint exception is unrelated to this session and remains in `prompts/gemma-classify-instructions.md`.

### 2026-06-03T16:01:05Z — WorkLists

- Summary: Added subtle column item counters with hover metrics.
- Problem: Column headers showed controls but did not provide quick at-a-glance task volume or contextual column health.
- Requirement: Each column header must show a subdued item count before the existing reset/actions icons, and hovering it must reveal useful task metrics without adding a heavy new menu.
- Solution:
  - Added a right-aligned grey `.column-item-counter` with a list/count icon and total item count.
  - Built the counter title tooltip from current column tasks, including total/open/complete counts, primary and secondary tag coverage, untagged count, and oldest/newest creation dates.
  - Expanded header title/edit spacing so the new counter does not overlap the existing reset and column action controls.
- Files/areas: `public/todolist2.js`, `public/todoliststyles2.css`, `tests/column-actions.test.js`, `docs/worklists/worklists-app-changelog.md`.
- User-visible impact:
  - Column headers now show a compact grey item counter to the left of the existing reset and ellipsis buttons.
  - Hovering the counter shows detailed column metrics using the browser tooltip.
- Tests run:
  - `node --check public/todolist2.js` — pass.
  - `npm test -- tests/column-actions.test.js` — pass, 20 tests.
  - `npm test` — pass, 358 tests.
  - `npm run lint` — blocked by pre-existing formatting warning in `prompts/gemma-classify-instructions.md`; touched files pass after targeted Prettier formatting.
- Tests added/updated: Extended column header regression coverage for counter creation, placement order, and CSS spacing.
- Regression impact: Column header rendering and spacing were touched; focused column tests and full unit tests passed.
- API docs: Not affected; this is UI-only and no HTTP contract changed.
- Tooling gates: Syntax check, focused tests, and full tests passed; repo lint remains blocked only by the existing prompt formatting warning.
- Conflicts / exceptions: Lint exception is unrelated to this session and remains in `prompts/gemma-classify-instructions.md`.

### 2026-06-01T16:33:08-04:00 — WorkLists

- Summary: Matched notes line-break rendering to card markdown rendering.
- Files/areas: `public/todoliststyles2.css`, `tests/markdown-editor.test.js`, `tests/browser-notes-smoke.js`, `docs/worklists/worklists-app-changelog.md`.
- User-visible impact:
  - Notes now give the same visible spacing to intentional blank lines that cards already get from the shared markdown renderer.
  - Single newlines in notes continue to render as visible line breaks through the shared card markdown renderer.
  - The browser smoke test now creates a multiline note and verifies both `<br>` line breaks and visible blank-line spacing in the notes pane.
- Tests run:
  - `npm test -- tests/markdown-editor.test.js tests/markdown-renderer.test.js` — pass, 25 tests.
  - `npm run test:browser` — pass, 1 browser smoke test.
  - `npm test` — pass, 358 tests.
- Tests added/updated: Added notes CSS coverage for `.markdown-blank-line` and browser coverage for notes line-break/blank-line rendering parity.
- Regression impact: Notes markdown display spacing was touched; focused markdown tests, browser smoke, and full unit tests passed.
- API docs: Not affected; no HTTP contract changed.
- Tooling gates: Focused markdown tests, browser smoke, and full unit tests passed.
- Conflicts / exceptions: Notes already used the shared card renderer; this change fills the notes-specific CSS and browser-regression gap.

### 2026-06-01T17:32:27Z — WorkLists

- Summary: Tightened voice-to-text context entry and AI refine hotkey persistence.
- Problem: Voice context added during editing could continue existing list/checklist formatting, and the `Ctrl+Shift+Enter` refine shortcut could invoke AI before the current card draft was saved to the server.
- Requirement: Voice-added context must start as a clean supplemental paragraph, the AI shortcut must refine the committed card state, and the resulting automated refinement must remain undoable.
- Solution:
  - Voice transcript composition now appends dictated context after a blank line when existing content is present.
  - Dictated transcript lines strip checklist, bullet, and numbered-list prefixes before being inserted.
  - The inline edit `Ctrl+Shift+Enter` path now saves the current textarea draft first, then invokes AI refine using the saved text; if saving fails, AI refine is not started.
  - Existing AI refinement undo behavior remains in place for completed refine results.
- Files/areas: `public/todolist2.js`, `tests/gemma-ui.test.js`, `tests/edit-session.test.js`, `docs/worklists/worklists-app-changelog.md`.
- User-visible impact:
  - Voice-to-text additions behave like clean supplemental context instead of inheriting list/checklist formatting from the existing card.
  - `Ctrl+Shift+Enter` from an inline card edit now commits the draft before starting AI refinement, reducing skipped/stale refine results.
- Tests run:
  - `npm audit --audit-level=high` — pass for high/critical threshold; reports 3 moderate `qs`/`body-parser`/`express` advisories with no fix available.
  - `node --check public/todolist2.js` — pass.
  - `npm test -- tests/gemma-ui.test.js tests/edit-session.test.js` — pass, 31 tests.
  - `npm test` — pass, 358 tests.
  - `npm run lint` — blocked by pre-existing formatting warning in `prompts/gemma-classify-instructions.md`; touched files pass after formatting.
- Tests added/updated: Added source coverage for clean voice context paragraph composition, formatting-prefix stripping, and save-before-refine hotkey behavior.
- Regression impact: Shared voice transcript composition and inline edit AI shortcut flow were touched; focused UI/edit tests and full unit tests passed.
- API docs: Not affected; no HTTP route or request/response contract changed.
- Tooling gates: Audit threshold, syntax check, focused tests, and full unit tests passed; repo lint remains blocked only by the existing prompt formatting warning.
- Conflicts / exceptions: Lint exception is unrelated to this session and remains in `prompts/gemma-classify-instructions.md`.

### 2026-06-01T17:13:06Z — WorkLists

- Summary: Made completed AI refinements directly reversible through timeout-based undo toasts.
- Problem: AI refine completions can overwrite or replace saved card/note data, and undo affordances were either incomplete or buried in the AI activity details.
- Requirement: Completed destructive AI refinements must surface a clear `Undo` action immediately, keep it available until the toast timeout acts as confirmation, and restore the previous saved content when invoked.
- Solution:
  - Card and note refine completions now emit a direct app toast with `Undo` for 15 seconds, in addition to the AI activity panel action.
  - Card refine undo now restores the prior text plus primary/secondary tag assignments instead of text only.
  - Multi-card replacement refine results now carry the previous card snapshot and previous notes, enabling undo to recreate the original card/notes and remove the AI-created replacement cards.
- Files/areas: `server.js`, `public/todolist2.js`, `tests/gemma-ui.test.js`, `tests/gemma-normalize.test.js`, `docs/worklists/worklists-app-changelog.md`.
- User-visible impact:
  - AI-refined cards and notes show an immediate undo toast after completion.
  - AI card replacements can be undone from the completion toast, restoring the original card content and associated notes.
  - Waiting out the toast acts as confirmation; no extra modal is added to the refinement flow.
- Tests run:
  - `npm audit --audit-level=high` — pass for high/critical threshold; reports 3 moderate `qs`/`body-parser`/`express` advisories with no fix available.
  - `node --check public/todolist2.js` — pass.
  - `node --check server.js` — pass.
  - `node --test tests/gemma-ui.test.js tests/gemma-normalize.test.js` — pass, 66 tests.
  - `npm test -- tests/gemma-ui.test.js tests/gemma-normalize.test.js` — pass, 66 tests.
  - `npm test` — pass, 358 tests.
  - `npm run lint` — blocked by pre-existing formatting warning in `prompts/gemma-classify-instructions.md`; touched files passed after formatting `tests/gemma-ui.test.js`.
- Tests added/updated: Added UI source coverage for direct timeout-based undo toasts, card replacement undo wiring, note refine undo toast emission, and server result coverage for previous card snapshots.
- Regression impact: AI job completion toast handling, card refine undo, and refine-card server result payloads were touched; focused AI tests and full unit tests passed.
- API docs: Not affected; existing `/api/gemma-normalize/jobs` response payloads were extended with undo metadata for UI recovery, but no new route or request contract was introduced.
- Tooling gates: Audit threshold, syntax checks, focused AI tests, and full unit tests passed; repo lint remains blocked only by the existing prompt formatting warning.
- Conflicts / exceptions: Lint exception is unrelated to this session and remains in `prompts/gemma-classify-instructions.md`.

### 2026-06-01T12:04:04-04:00 — WorkLists

- Summary: Restored reliable Escape-key dismissal for filters and notes context surfaces.
- Files/areas: `public/todolist2.js`, `tests/filter-menu.test.js`, `tests/context-windows.test.js`, `tests/browser-notes-smoke.js`, `docs/worklists/worklists-app-changelog.md`.
- User-visible impact:
  - Pressing plain `Escape` now closes the filters menu through a dedicated global context-surface dismissal handler.
  - Pressing plain `Escape` now closes the notes side pane even when focus is inside pane controls that could previously bypass the search shortcut listener.
  - App confirmation dialogs and active voice transcription keep priority so Escape can still cancel the dialog or stop transcription without also closing underlying context panes.
- Tests run:
  - `node --check public/todolist2.js` — pass.
  - `npm test -- tests/filter-menu.test.js tests/context-windows.test.js tests/search-shortcuts.test.js` — pass, 31 tests.
  - `npm test` — pass, 358 tests.
  - `npm run test:browser` — pass, 1 browser smoke test.
- Tests added/updated: Added regression coverage proving filters and notes close through the dedicated global Escape handler; extended the browser smoke test to press `Escape` against both the filters menu and notes pane.
- Regression impact: Global keyboard handling for context-window dismissal was touched; focused keyboard/context tests, full unit tests, and browser smoke passed.
- API docs: Not affected; no HTTP contract changed.
- Tooling gates: Focused tests, full unit tests, and browser smoke passed.
- Conflicts / exceptions: Existing notes discard confirmation behavior is preserved when closing the pane with unsaved drafts.

### 2026-05-31T17:19:31-04:00 — WorkLists

- Summary: Verified and tightened active-model usage for AI calls.
- Files/areas: `modelProviderClient.js`, `tests/gemma-normalize.test.js`, `tests/model-provider-client.test.js`, `docs/worklists/worklists-app-changelog.md`.
- User-visible impact:
  - Direct AI normalization and async AI jobs continue to resolve the active model from model settings before provider calls.
  - Async jobs record the active model id in job context when queued, so status responses expose which model was selected for the job.
  - Non-Google active models no longer silently fall back to `GEMINI_API_KEY` when no model-specific key or env var is configured.
- Tests run:
  - `node --check modelProviderClient.js` — pass.
  - `npm test -- tests/model-provider-client.test.js tests/gemma-normalize.test.js` — pass, 43 tests.
  - `npm test` — pass, 356 tests.
- Tests added/updated: Added coverage proving direct and async AI calls pass the active model id/api key into provider calls; added provider-key coverage preventing Gemini fallback for non-Google active models.
- Regression impact: Provider API-key resolution and AI model-selection tests were touched; focused backend/provider tests and full unit tests passed.
- API docs: Not affected; schemas did not change.
- Tooling gates: Focused tests and full unit tests passed.
- Conflicts / exceptions: Historical `Gemma` naming remains in routes/functions, but model selection is active-model driven.

### 2026-05-31T15:48:38-04:00 — WorkLists

- Summary: Added undo support for completed AI note refinement.
- Files/areas: `public/todolist2.js`, `tests/gemma-ui.test.js`, `docs/worklists/worklists-app-changelog.md`.
- User-visible impact:
  - Completed `refine-note` AI jobs now show an `Undo` toast action when the previous note text is available.
  - Undo restores the note through the existing notes API and refreshes the open notes pane when the restored note belongs to the active card.
  - AI note creation remains unchanged and does not show an undo refine action.
- Tests run:
  - `node --check public/todolist2.js` — pass.
  - `npm test -- tests/gemma-ui.test.js tests/context-windows.test.js` — pass, 38 tests.
  - `npm test` — pass, 353 tests.
- Tests added/updated: Added source coverage for AI note refine undo wiring, toast action creation, notes API restoration, and active-pane refresh.
- Regression impact: Note AI completion toast handling and note update API usage were touched; focused UI/context tests and full unit tests passed.
- API docs: Not affected; this uses the existing note update API.
- Tooling gates: Focused tests and full unit tests passed.
- Conflicts / exceptions: Card refine undo behavior was left unchanged.

### 2026-05-31T13:12:46-04:00 — WorkLists

- Summary: Tightened AI note generation so explicit Markdown lists are preserved as one note.
- Files/areas: `gemmaNormalize.js`, `server.js`, `tests/gemma-normalize.test.js`, `docs/worklists/worklists-app-changelog.md`.
- User-visible impact:
  - AI note creation/refinement now injects note-specific prompt constraints after the shared card instructions, telling the model to produce one complete note body and preserve every explicit list item/detail.
  - Notes force the classification directive back to one single-card-format object even if the classifier interprets a list as multiple cards.
  - Notes now extract the returned `cleaned_text` as one full note body instead of using the card task splitter, which was dropping markdown bullet content after the heading.
  - Card AI prompting and card task extraction were not changed.
- Tests run:
  - `node --check gemmaNormalize.js` — pass.
  - `node --check server.js` — pass.
  - `npm test -- tests/gemma-normalize.test.js` — pass, 40 tests.
  - `npm test` — pass, 352 tests.
- Tests added/updated: Added Alfredo-style recipe coverage proving a header plus explicit markdown bullets persists as one note, even when classification returns a multi-card count; added prompt coverage for note context injection.
- Regression impact: Note-only AI prompt/extraction logic and shared prompt option plumbing were touched; focused backend AI tests and full unit tests passed.
- API docs: Not affected; request/response schemas did not change.
- Tooling gates: Focused tests and full unit tests passed.
- Conflicts / exceptions: Existing card prompts and card extraction behavior were intentionally left unchanged.

### 2026-05-31T11:32:15-04:00 — WorkLists

- Summary: Added voice-to-text controls to note creation and note editing.
- Files/areas: `public/index.html`, `public/todolist2.js`, `public/todoliststyles2.css`, `tests/gemma-ui.test.js`, `docs/worklists/worklists-app-changelog.md`.
- User-visible impact:
  - The notes pane add-note composer now has a `Voice` action that uses the same browser speech recognition flow as card voice input.
  - Inline note editing now includes a compact `Voice` action so saved notes can be dictated or extended while editing.
  - Note voice controls can be pressed again to stop listening, and they use the same stop toast/Escape handling as card voice input.
  - Starting note AI create/refine now hard-stops any active voice transcription first so partial speech capture does not continue underneath model work.
  - Voice input normalizes the markdown editor back to Markdown mode before dictation, preserving current Visual-mode content and keeping the saved source coherent.
- Tests run:
  - `node --check public/todolist2.js` — pass.
  - `npm test -- tests/gemma-ui.test.js tests/markdown-editor.test.js tests/context-windows.test.js` — pass, 44 tests.
  - `npm test` — pass, 350 tests.
  - `npm run lint` — fails only on the existing `prompts/gemma-classify-instructions.md` Prettier warning.
- Tests added/updated: Added source coverage for note voice create/edit controls and for stopping active voice capture before note AI actions.
- Regression impact: Shared voice button state, notes editor controls, and note AI start paths were touched; focused UI/notes editor tests and full unit tests passed.
- API docs: Not affected; this is a client-side voice/editor integration.
- Tooling gates: Focused tests and full unit tests passed; lint still reports the known prompt formatting exception.
- Conflicts / exceptions: Voice support depends on browser speech recognition availability, matching existing card behavior.

### 2026-05-31T11:21:07-04:00 — WorkLists

- Summary: Added model-backed AI create/refine actions for notes.
- Files/areas: `server.js`, `openapi.js`, `public/index.html`, `public/todolist2.js`, `public/todoliststyles2.css`, `tests/gemma-normalize.test.js`, `tests/gemma-ui.test.js`, `tests/openapi.test.js`, `docs/worklists/worklists-app-changelog.md`.
- User-visible impact:
  - The notes pane add-note row now has an `AI note` action that sends the current note draft/instructions through the active AI model and creates a note on completion.
  - Each saved note now has a compact `Refine note with AI` action in the note controls.
  - Note AI jobs reuse the existing async job polling and progress toast flow, but new note-facing labels use generic `AI` naming instead of adding more model-specific Gemma copy.
  - Note AI create/refine actions disable their controls while work is in flight and refresh the active notes pane when the job completes.
- Tests run:
  - `node --check public/todolist2.js` — pass.
  - `node --check server.js` — pass.
  - `node --check openapi.js` — pass.
  - `npm test -- tests/gemma-normalize.test.js tests/gemma-ui.test.js` — pass, 60 tests.
  - `npm test -- tests/context-windows.test.js tests/markdown-editor.test.js` — pass, 20 tests.
  - `npm test -- tests/openapi.test.js tests/gemma-normalize.test.js tests/gemma-ui.test.js` — pass, 63 tests.
  - `npm test` — pass, 348 tests.
  - `npm run test:browser` — pass, 1 browser smoke test.
  - `npm run lint` — fails only on the existing `prompts/gemma-classify-instructions.md` Prettier warning.
- Tests added/updated: Added source coverage for generic AI note UI naming, pending-job tracking, note controls, and server job wiring; added persistence coverage for AI-created and AI-refined notes through the notes store; added OpenAPI coverage for note job request/status/result schemas.
- Regression impact: Shared AI/Gemma pending-job tracking, notes pane controls, and server job execution were touched; focused tests, full tests, and browser smoke passed.
- API docs: Updated OpenAPI job request/status/result schemas for the existing `/api/gemma-normalize/jobs` endpoint so `add-note` and `refine-note` are documented with note context and result payloads.
- Tooling gates: Full unit tests and browser smoke passed; lint still reports the known prompt formatting exception.
- Conflicts / exceptions: Existing card/task AI internals still use the historical `Gemma` function names; new note-facing UI copy is generic `AI` to reflect model-swappable behavior.

### 2026-05-31T11:12:49-04:00 — WorkLists

- Summary: Moved notes-pane draft discard prompts onto the in-app dialog flow and added AI notes parity to the initiative checklist.
- Files/areas: `docs/worklists/worklists-app-changelog.md`, `public/todolist2.js`, `tests/context-windows.test.js`.
- User-visible impact:
  - Discarding unsaved note, note-edit, or card-text drafts from the notes pane now uses the styled WorkLists confirmation dialog.
  - Notes-pane close, cancel, Escape, edit-switch, and card-switch guard paths now await the same dialog confirmation flow.
  - The initiative checklist now explicitly requires AI note creation and AI note refinement parity with card-level AI actions.
- Tests run:
  - `node --check public/todolist2.js` — pass.
  - `npm test -- tests/context-windows.test.js tests/card-actions.test.js tests/markdown-editor.test.js` — pass, 33 tests.
  - `npm test` — pass, 344 tests.
  - `npm run test:browser` — pass, 1 browser smoke test.
  - `npm run lint` — fails only on the existing `prompts/gemma-classify-instructions.md` Prettier warning.
- Tests added/updated: Updated context-window coverage for async discard prompts, in-app dialog usage, and async notes-pane close behavior.
- Regression impact: Notes-pane close/cancel/Escape/edit-switch timing was touched; focused tests, full tests, and browser smoke passed.
- API docs: Not relevant — no HTTP contract or OpenAPI surface changed.
- Tooling gates: Full unit tests and browser smoke passed; lint still reports the known prompt formatting exception.
- Conflicts / exceptions: Shared context-window closer remains synchronous for non-notes callers; it now safely fires the async notes close path without forcing a broad app-wide async refactor.

### 2026-05-31T11:07:28-04:00 — WorkLists

- Summary: Added the Countdowns-style in-app dialog helper and used it for note deletion confirmation.
- Files/areas: `public/dialogs.js`, `public/index.html`, `public/todolist2.js`, `public/todoliststyles2.css`, `tests/context-windows.test.js`.
- User-visible impact:
  - Deleting a note now opens a styled WorkLists modal confirmation instead of the native browser confirm.
  - The dialog supports Countdowns-parity cancel behavior through the backdrop and `Escape`.
  - The destructive confirm action uses a distinct danger style while preserving keyboard focus behavior.
- Tests run:
  - `npm test -- tests/context-windows.test.js tests/markdown-editor.test.js` — pass.
  - `npm test` — pass, 344 tests.
  - `npm run test:browser` — pass, 1 browser smoke test.
  - `npm run lint` — fails only on the existing `prompts/gemma-classify-instructions.md` Prettier warning.
- Tests added/updated: Updated context-window coverage for the dialog script order, dialog API, backdrop/Escape cancellation, and danger styling.
- Regression impact: Notes delete confirmation now matches the Countdowns app pattern without changing the notes pane layout or backend API.
- API docs: Not relevant — no HTTP contract or OpenAPI surface changed.
- Tooling gates: Full unit tests and browser smoke passed; lint still reports the known prompt formatting exception.
- Conflicts / exceptions: Draft-discard prompts still use the native sync confirm until the broader async context-window close flow is refactored.

### 2026-05-31T14:56:00Z — WorkLists

- Summary: Added a Playwright browser smoke test for the notes pane and card note indicators.
- Files/areas: `package.json`, `package-lock.json`, `tests/browser-notes-smoke.js`, `docs/worklists/worklists-app-changelog.md`.
- User-visible impact:
  - Added `npm run test:browser` for an isolated Chromium smoke pass against temporary WorkLists data.
  - The smoke test opens the real app, verifies the note-count indicator, opens the notes pane, edits the original card text, adds a note, and checks the pane remains inside desktop and mobile viewports.
  - Browser testing uses a temporary `DATA_DIR`, so it does not touch the user's real WorkLists data.
- Tests run:
  - `npm run test:browser` — pass, 1 browser smoke test.
  - `npm test` — pass, 343 tests.
  - `npx prettier --check package.json tests\browser-notes-smoke.js` — pass.
- Tests added/updated: Added `tests/browser-notes-smoke.js` and a `test:browser` package script.
- Regression impact: Browser smoke coverage now exercises the notes pane, note-count indicator, card text edit path, add-note path, and desktop/mobile viewport fit.
- API docs: Not relevant — no HTTP contract or OpenAPI surface changed.
- Tooling gates: Full `npm test` passed; browser smoke passed; targeted Prettier passed.
- Conflicts / exceptions: Installed Playwright as a dev dependency and downloaded Chromium locally for the browser run; worktree had many pre-existing dirty files before this session; no unrelated changes were reverted.

### 2026-05-31T14:39:37Z — WorkLists

- Summary: Added card-level notes count indicators.
- Files/areas: `public/todolist2.js`, `public/todoliststyles2.css`, `tests/card-actions.test.js`.
- User-visible impact:
  - Cards with notes now show a compact note-count pill in the card action row.
  - The note-count pill opens the notes pane for that card.
  - The card action menu now shows the note count beside `Edit Notes` when notes exist.
  - Counts are seeded from the existing `event-notes` data and refresh when the active notes pane reloads after create/delete.
- Tests run:
  - `node --check public\todolist2.js` — pass.
  - `node --test tests\card-actions.test.js tests\context-windows.test.js` — pass, 25 tests.
  - `npx prettier --check public\todolist2.js public\todoliststyles2.css tests\card-actions.test.js` — pass.
  - `npm test` — pass, 343 tests.
- Tests added/updated: Extended card action integration assertions for notes count state, card-level indicator rendering, menu status text, data seeding from `event-notes`, and indicator refresh after note loads.
- Regression impact: Card render/action row and card action state were touched; focused card/context tests and the full suite passed.
- API docs: Not relevant — reused existing notes data and APIs without changing HTTP contracts or OpenAPI.
- Tooling gates: Full `npm test` passed; targeted Prettier passed.
- Conflicts / exceptions: Worktree had many pre-existing dirty files before this session; no unrelated changes were reverted.

### 2026-05-31T13:27:05Z — WorkLists

- Summary: Added unsaved-change protection for notes pane editing surfaces.
- Files/areas: `public/todolist2.js`, `tests/context-windows.test.js`.
- User-visible impact:
  - Closing the notes pane now asks before discarding unsaved changes.
  - Canceling an edited card text, edited note, or draft note asks before throwing away changed text.
  - Starting another notes-pane edit checks for unsaved text in the other pane surfaces first.
  - Opening notes for another card now preserves the current pane when the user declines to discard unsaved changes.
- Tests run:
  - `node --check public\todolist2.js` — pass.
  - `node --test tests\context-windows.test.js tests\markdown-editor.test.js` — pass, 19 tests.
  - `npx prettier --check public\todolist2.js tests\context-windows.test.js` — pass.
  - `npm test` — pass, 342 tests.
- Tests added/updated: Extended context-window assertions for notes pane draft detection, discard confirmation, and guarded cancel/close/switch paths.
- Regression impact: Notes pane close, cancel, edit-switch, and open-card flows were touched; focused context/editor tests and the full suite passed.
- API docs: Not relevant — no HTTP contract or OpenAPI surface changed.
- Tooling gates: Full `npm test` passed; targeted Prettier passed.
- Conflicts / exceptions: Worktree had many pre-existing dirty files before this session; no unrelated changes were reverted.

### 2026-05-31T01:29:39Z — WorkLists

- Summary: Added in-pane editing for the original card text from the notes side pane.
- Files/areas: `public/todolist2.js`, `public/todoliststyles2.css`, `tests/context-windows.test.js`, `tests/markdown-editor.test.js`.
- User-visible impact:
  - The notes pane now shows a minimal `Card text` section above the notes list with an edit icon.
  - Users can edit the card's original text directly in the notes pane using the same Visual, Markdown, and Preview editor controls as notes.
  - Saving updates the card text through the existing todo API, refreshes the board, and updates the pane title/content without closing the pane.
  - The card text area has more room than the previous compact preview while keeping overflow contained inside the side pane.
- Tests run:
  - `node --check public\todolist2.js` — pass.
  - `node --test tests\context-windows.test.js tests\markdown-editor.test.js` — pass, 18 tests.
  - `npx prettier --check public\todolist2.js public\todoliststyles2.css tests\context-windows.test.js tests\markdown-editor.test.js` — pass.
  - `npm test` — pass, 341 tests.
- Tests added/updated: Extended notes pane context and markdown editor integration assertions for original card text editing, shared editor wiring, save behavior, accessible labels, and pane overflow sizing.
- Regression impact: Notes pane card preview/editing, task text persistence, and pane sizing were touched; focused context/editor tests and the full suite passed.
- API docs: Not relevant — reused the existing todo update API and did not change the HTTP contract or OpenAPI surface.
- Tooling gates: Full `npm test` passed; targeted Prettier passed.
- Conflicts / exceptions: Worktree had many pre-existing dirty files before this session; no unrelated changes were reverted.

### 2026-05-31T01:20:51Z — WorkLists

- Summary: Added a guarded delete path and accessible compact note actions for the notes pane.
- Files/areas: `public/todolist2.js`, `tests/context-windows.test.js`.
- User-visible impact:
  - Deleting a note from the side pane now asks for confirmation before removing it.
  - Compact edit and delete icon buttons now expose explicit accessible labels while retaining their visual layout.
- Tests run:
  - `node --check public\todolist2.js` — pass.
  - `node --test tests\context-windows.test.js` — pass, 10 tests.
  - `npx prettier --check public\todolist2.js tests\context-windows.test.js` — pass.
  - `npm test` — pass, 340 tests.
- Tests added/updated: Extended context-window assertions for note delete confirmation and accessible compact note actions.
- Regression impact: Notes pane delete clicks and note action markup were touched; focused context tests and the full suite passed.
- API docs: Not relevant — no HTTP contract or OpenAPI surface changed; existing `/api/notes` contract was unchanged.
- Tooling gates: Full `npm test` passed; targeted Prettier passed.
- Conflicts / exceptions: Worktree had many pre-existing dirty files before this session; no unrelated changes were reverted.

### 2026-05-31T01:18:20Z — WorkLists

- Summary: Improved notes pane accessibility and focus continuity.
- Files/areas: `public/index.html`, `public/todolist2.js`, `tests/context-windows.test.js`, `tests/card-actions.test.js`.
- User-visible impact:
  - The notes side pane now exposes dialog semantics with `aria-labelledby` tied to the pane title.
  - Opening notes from a card action records the triggering ellipsis button as the return-focus target.
  - Closing the notes pane restores focus to the opener when it still exists, keeping keyboard users oriented after the side pane closes.
- Tests run:
  - `node --check public\todolist2.js` — pass.
  - `node --test tests\context-windows.test.js tests\card-actions.test.js` — pass, 21 tests.
  - `npx prettier --check public\index.html public\todolist2.js tests\context-windows.test.js tests\card-actions.test.js` — pass.
  - `npm test` — pass, 339 tests.
- Tests added/updated: Extended context-window and card-action integration assertions for notes pane dialog semantics, opener tracking, and focus restoration.
- Regression impact: Notes pane close behavior and card action notes wiring were touched; focused context/card-action tests and the full suite passed.
- API docs: Not relevant — no HTTP contract or OpenAPI surface changed; existing `/api/notes` contract was unchanged.
- Tooling gates: Full `npm test` passed; targeted Prettier passed.
- Conflicts / exceptions: Worktree had many pre-existing dirty files before this session; no unrelated changes were reverted.

### 2026-05-31T01:14:44Z — WorkLists

- Summary: Added the notes initiative UI/UX checklist and polished notes pane controls/layout.
- Files/areas: `docs/worklists/worklists-app-changelog.md`, `public/markdownEditor.js`, `public/index.html`, `public/todolist2.js`, `public/todoliststyles2.css`, `tests/markdown-editor.test.js`.
- User-visible impact:
  - The notes initiative now has a standing checklist for viewport fit, overflow, wrapping, padding, scrolling, button placement, icon usage, keyboard behavior, and markdown rendering layout.
  - Add-note, save-note, and cancel-edit controls now use coherent icon+label button treatments with consistent sizing and focus/hover behavior.
  - Markdown toolbar commands use compact icons where familiar icons exist, while preserving text symbols for heading/bold/italic/quote.
  - Notes pane content now guards horizontal overflow across pane, cards, timestamps, editor surfaces, toolbar rows, markdown code blocks, tables, and narrow mobile widths.
- Tests run:
  - `node --check public\markdownEditor.js` — pass.
  - `node --check public\todolist2.js` — pass.
  - `node --test tests\markdown-editor.test.js tests\context-windows.test.js` — pass, 15 tests.
  - `npx prettier --check docs\worklists\worklists-app-changelog.md public\markdownEditor.js public\index.html public\todolist2.js public\todoliststyles2.css tests\markdown-editor.test.js tests\context-windows.test.js` — pass.
  - `npm test` — pass, 338 tests.
- Tests added/updated: Extended markdown editor tests for toolbar icon metadata and notes-pane layout/overflow/style guardrails.
- Regression impact: Notes pane layout, editor toolbar rendering, and note edit action markup were touched; focused editor/context tests and the full suite passed.
- API docs: Not relevant — no HTTP contract or OpenAPI surface changed; existing `/api/notes` contract was unchanged.
- Tooling gates: Full `npm test` passed; targeted Prettier passed.
- Conflicts / exceptions: Worktree had many pre-existing dirty files before this session; no unrelated changes were reverted.

### 2026-05-30T18:26:00Z — WorkLists

- Summary: Ported Countdowns-style markdown editor modes and toolbar controls into WorkLists notes.
- Files/areas: `public/markdownEditor.js`, `public/index.html`, `public/todolist2.js`, `public/todoliststyles2.css`, `tests/markdown-editor.test.js`, `tests/markdown-authoring.test.js`, `tests/context-windows.test.js`.
- User-visible impact:
  - The add-note editor now expands from the compact empty state into Visual, Markdown, and Preview modes.
  - Notes now have toolbar controls for headings, bold, italic, links, lists, quotes, inline code, code blocks, and tables.
  - Inline note edits use the same tabbed editor modes and toolbar controls as the add-note editor.
  - Visual and Preview modes use the existing WorkLists markdown renderer so authored notes stay aligned with card markdown behavior.
- Tests run:
  - `node --check public\markdownEditor.js` — pass.
  - `node --check public\todolist2.js` — pass.
  - `node --test tests\markdown-editor.test.js tests\markdown-authoring.test.js tests\context-windows.test.js` — pass, 20 tests.
  - `npx prettier --check public\markdownEditor.js public\index.html public\todolist2.js public\todoliststyles2.css tests\markdown-editor.test.js tests\markdown-authoring.test.js tests\context-windows.test.js` — pass.
  - `npm test` — pass, 336 tests.
- Tests added/updated: Added `tests/markdown-editor.test.js` for toolbar syntax helpers and notes editor integration; extended markdown authoring and context-window assertions for the new editor helper and keyboard paths.
- Regression impact: Shared notes pane editing behavior and script ordering were touched; focused editor/context tests and the full suite passed.
- API docs: Not relevant — no HTTP contract or OpenAPI surface changed; existing `/api/notes` contract was unchanged.
- Tooling gates: Full `npm test` passed; targeted Prettier passed.
- Conflicts / exceptions: Worktree had many pre-existing dirty files before this session; no unrelated changes were reverted.

### 2026-05-30T18:13:15Z — WorkLists

- Summary: Added persisted resizing for the notes side pane.
- Files/areas: `public/index.html`, `public/todolist2.js`, `public/todoliststyles2.css`, `tests/context-windows.test.js`.
- User-visible impact:
  - The notes pane now has a left-edge resize handle so users can widen or narrow the side popout.
  - The chosen pane width is saved in `localStorage` and restored when reopening the pane.
  - Width is clamped to sensible desktop and viewport bounds so the pane stays usable on smaller screens.
- Tests run:
  - `node --check public\todolist2.js` — pass.
  - `node --test tests\context-windows.test.js` — pass, 8 tests.
  - `npx prettier --check public\index.html public\todolist2.js public\todoliststyles2.css tests\context-windows.test.js` — pass.
  - `npm test` — pass, 331 tests.
- Tests added/updated: Extended context-window source/CSS assertions to cover the notes pane resize handle, persisted width key, pointer drag behavior, and resizing styles.
- Regression impact: Notes pane layout and window resize behavior were touched; focused context tests and the full suite passed.
- API docs: Not relevant — no HTTP contract or OpenAPI surface changed.
- Tooling gates: Full `npm test` passed; targeted Prettier passed.
- Conflicts / exceptions: Worktree had many pre-existing dirty files before this session; no unrelated changes were reverted.

### 2026-05-30T18:00:06Z — WorkLists

- Summary: Added lifecycle cleanup for notes associated to deleted cards.
- Files/areas: `dal.js`, `tests/api.test.js`.
- User-visible impact:
  - Notes tied to a card are now removed when that card is deleted directly.
  - Notes tied to cards removed by deleting a column or board are now removed with the same cascade.
  - Notes associated to unrelated card IDs are preserved.
- Tests run:
  - `node --check dal.js` — pass.
  - `node --test tests\api.test.js` — pass, 67 tests.
  - `npx prettier --check dal.js tests/api.test.js` — pass.
  - `npm test` — pass, 330 tests.
  - `npm run lint` — blocked: repo-wide Prettier check still reports pre-existing formatting in `prompts/gemma-classify-instructions.md`; touched notes cleanup files passed targeted Prettier check.
- Tests added/updated: Extended delete board/column/todo API assertions to verify associated notes are removed and unrelated notes remain.
- Regression impact: Delete cascades were touched; focused API tests and the full suite passed.
- API docs: Not relevant — no HTTP contract or OpenAPI surface changed.
- Tooling gates: Full `npm test` passed; full `npm run lint` remains blocked by the pre-existing `prompts/gemma-classify-instructions.md` formatting warning.
- Conflicts / exceptions: Worktree had many pre-existing dirty files before this session; no unrelated changes were reverted.

### 2026-05-30T17:46:35Z — WorkLists

- Summary: Improved notes pane keyboard and markdown authoring interactions.
- Files/areas: `public/todolist2.js`, `tests/markdown-authoring.test.js`, `tests/context-windows.test.js`.
- User-visible impact:
  - The add-note textarea and inline note edit textarea now use the existing markdown list authoring behavior.
  - `Ctrl+Enter` submits a new note or saves an inline note edit.
  - `Escape` clears a draft note with text or cancels an inline note edit without collapsing the notes pane.
- Tests run:
  - `node --check public\todolist2.js` — pass.
  - `node --test tests\markdown-authoring.test.js tests\context-windows.test.js` — pass, 14 tests.
  - `npx prettier --check public/todolist2.js tests/markdown-authoring.test.js tests/context-windows.test.js` — pass.
  - `npm test` — pass, 330 tests.
  - `npm run lint` — blocked: repo-wide Prettier check still reports pre-existing formatting in `prompts/gemma-classify-instructions.md`; touched notes interaction files passed targeted Prettier check.
- Tests added/updated: Extended markdown authoring integration assertions for notes textareas and context-window assertions for note pane keyboard containment.
- Regression impact: Shared keyboard/context behavior was touched; focused context/markdown tests and the full suite passed.
- API docs: Not relevant — no HTTP contract or OpenAPI surface changed.
- Tooling gates: Full `npm test` passed; full `npm run lint` remains blocked by the pre-existing `prompts/gemma-classify-instructions.md` formatting warning.
- Conflicts / exceptions: Worktree had many pre-existing dirty files before this session; no unrelated changes were reverted.

### 2026-05-30T17:35:25Z — WorkLists

- Summary: Added the first UI integration for notes by wiring card actions to a notes side popout.
- Files/areas: `public/apiService.js`, `public/cardActions.js`, `public/index.html`, `public/todolist2.js`, `public/todoliststyles2.css`, `tests/api-client-resilience.test.js`, `tests/card-actions.test.js`, `tests/context-windows.test.js`.
- User-visible impact:
  - Card ellipsis menus now include `Edit Notes`.
  - Selecting `Edit Notes` opens a right-side notes pane for the card, loads existing notes through `/api/notes?eventId=<cardId>`, renders note content with existing markdown rendering, and supports add/edit/delete note flows.
  - The notes pane participates in the shared context-window close behavior and can be closed with its header close button or the existing Escape context close path.
- Tests run:
  - `node --check public\apiService.js`, `node --check public\cardActions.js`, `node --check public\todolist2.js` — pass.
  - `node --test tests\card-actions.test.js tests\context-windows.test.js tests\api-client-resilience.test.js` — pass, 25 tests.
  - `npx prettier --check public/apiService.js public/cardActions.js public/todolist2.js public/todoliststyles2.css public/index.html tests/card-actions.test.js tests/context-windows.test.js tests/api-client-resilience.test.js` — pass.
  - `npm test` — pass, 329 tests.
  - `npm run lint` — blocked: repo-wide Prettier check still reports pre-existing formatting in `prompts/gemma-classify-instructions.md`; notes UI files passed targeted Prettier check.
- Tests added/updated: Added card action coverage for `Edit Notes`, context-pane source/CSS assertions, and API client notes helper assertions.
- Regression impact: Shared card action and context close surfaces were touched; focused card action/context tests and the full suite passed.
- API docs: Not relevant for this UI/client slice; the `/api/notes` OpenAPI contract was already added in the prior backend slice and was not changed here.
- Tooling gates: Full `npm test` passed; full `npm run lint` remains blocked by the pre-existing `prompts/gemma-classify-instructions.md` formatting warning.
- Conflicts / exceptions: Worktree had many pre-existing dirty files before this session; no unrelated changes were reverted.

### 2026-05-30T16:34:36Z — WorkLists

- Summary: Ported the Countdowns notes API into WorkLists as the first backend step for card notes.
- Files/areas: `dal.js`, `server.js`, `openapi.js`, `data/event-notes.json`, `data/event-notes.example.json`, `tests/api.test.js`, `tests/openapi.test.js`.
- User-visible impact:
  - WorkLists now exposes the Countdowns-compatible `/api/notes` API for listing, filtering by `eventId`, creating, updating, and deleting notes.
  - Notes persist to `data/event-notes.json` with `noteId`, `eventId`, `text`, and `createdAt`.
- Tests run:
  - `node --check server.js`, `node --check dal.js`, `node --check openapi.js` — pass.
  - `node --test tests\api.test.js tests\openapi.test.js` — pass, 70 tests.
  - `npx prettier --check dal.js server.js openapi.js tests/api.test.js tests/openapi.test.js data/event-notes.json data/event-notes.example.json` — pass.
  - `npm test` — pass, 326 tests.
  - `npm run lint` — blocked: repo-wide Prettier check still reports pre-existing formatting in `prompts/gemma-classify-instructions.md`; notes API files passed targeted Prettier check.
- Tests added/updated: Added notes API coverage in `tests/api.test.js` for list/filter/create/validation/update/not-found/delete and updated OpenAPI assertions in `tests/openapi.test.js`.
- Regression impact: Isolated to the new `event-notes` data section and `/api/notes` routes; existing data migration/read/write paths were updated and verified by full API tests.
- API docs: Updated `openapi.js` with `/api/notes`, `/api/notes/{noteId}`, note schemas, `NoteId` parameter, and `event-notes` on `DataStore`.
- Tooling gates: Full `npm test` passed; full `npm run lint` blocked by the pre-existing `prompts/gemma-classify-instructions.md` formatting warning noted above.
- Conflicts / exceptions: Worktree had many pre-existing dirty files before this session; no unrelated changes were reverted.

### 2026-05-28

- Summary: Corrected the manual dependency scheduler into a column-selection picker that loads selected columns into a board-space linear sequence.
- Files/areas: `dal.js`, `server.js`, `openapi.js`, `public/apiService.js`, `public/columnActions.js`, `public/scheduler.js`, `public/index.html`, `public/todolist2.js`, `public/todoliststyles2.css`, `data/schedulerTaskIds.example.json`, `tests/api.test.js`, `tests/column-actions.test.js`, `tests/openapi.test.js`, `tests/scheduler.test.js`.
- User-visible impact:
  - The top scheduler button now opens a compact context picker for selecting columns from the current board.
  - `Load selected` defines which tasks are present in the scheduler; card-level scheduler checkboxes, board-wide intake, and column action menu scheduler shortcuts were removed.
  - The dependency sequence renders in the same main board workspace instead of a modal dialog.
  - Users can manually move tasks earlier/later, select tasks inside the sequence, and batch remove selected tasks.
  - Loading columns preserves the existing manual order for tasks that remain selected, appends newly loaded tasks, and removes tasks outside the selected column set.
  - Scheduled tasks show a description preview, full description on hover, primary tags, secondary tags, and source color cues.
  - The saved scheduler sequence reopens in the same manual order and stays separate from board/column sorting.
  - Missing external dependencies, incomplete dependency data, conflicts, and circular relationships are not automatically included or resolved.
- API docs check: Updated — added `/scheduler` GET/PUT, scheduler request/response schemas, and `schedulerTaskIds` on the shared `DataStore` schema.
- Verification:
  - `node --check public/todolist2.js`, `node --check public/columnActions.js` (pass).
  - `node --test tests/scheduler.test.js tests/column-actions.test.js tests/context-windows.test.js tests/filter-menu.test.js tests/gemma-ui.test.js` (pass).
  - `npm test` (pass).
  - `npx prettier --check public/todolist2.js public/todoliststyles2.css public/columnActions.js tests/column-actions.test.js tests/scheduler.test.js` (pass).
  - `npm run lint` (fails due pre-existing formatting warning in `prompts/gemma-classify-instructions.md`, not touched in this session).

### 2026-05-27

- Summary: Made rendered task markdown stay usable with structured tables, inline task checkboxes, and copyable fenced code blocks.
- Files/areas: `public/markdownRenderer.js`, `public/todolist2.js`, `public/todoliststyles2.css`, `public/taskClipboard.js`, `tests/markdown-renderer.test.js`, `tests/task-clipboard.test.js`, `tests/api.test.js`.
- User-visible impact:
  - Markdown tables now render as scan-friendly table markup in displayed task content.
  - Markdown checklist items render as focusable checkboxes that update the stored markdown source through the existing task save endpoint.
  - Fenced code blocks now show a code-block copy control with immediate inline copied/failure feedback.
  - Card-level copy continues to preserve raw markdown while ignoring rendered code-copy controls when raw source is unavailable.
- API docs check: N/A — reused existing `PATCH /todos/:id` task update contract; no new HTTP/OpenAPI surface.
- Verification:
  - `node --check public/markdownRenderer.js`, `node --check public/taskClipboard.js`, `node --check public/todolist2.js` (pass).
  - `npm test -- tests/markdown-renderer.test.js tests/task-clipboard.test.js tests/api.test.js` (pass).
  - `npm test` (pass).
  - `npx prettier --check public/markdownRenderer.js public/taskClipboard.js public/todolist2.js public/todoliststyles2.css tests/markdown-renderer.test.js tests/task-clipboard.test.js tests/api.test.js docs/worklists/worklists-app-changelog.md` (pass).
  - `npm run lint` (fails due pre-existing formatting warnings in `prompts/gemma-classify-instructions.md` and `tests/column-actions.test.js`, not touched in this session).

### 2026-05-27

- Summary: Folded primary/secondary tag determination into the existing Gemma create/refine workflow so formatting, content refinement, final review, and tag decisions return together without a dedicated tagging AI pass.
- Files/areas: `gemmaNormalize.js`, `server.js`, `openapi.js`, `prompts/gemma-normalize-instructions.md`, `public/todolist2.js`, `tests/gemma-normalize.test.js`, `tests/gemma-ui.test.js`, `tests/openapi.test.js`.
- User-visible impact:
  - Gemma add-task and refine-card jobs now send current primary and secondary tag inventories as context.
  - Completed jobs return structured primary/secondary tag outcomes with none/keep/add/change/remove/multi-tag semantics.
  - Existing cards can keep, change, expand, or remove tag assignments during refinement; create flows can apply zero, one, or multiple tags.
  - Proposed new secondary tags are persisted only when no existing tag name/id matches; matched existing tags are reused even if the model labels them as new.
  - Gemma process toasts now include lightweight tag-review notes for primary tags, secondary tags, and proposed new tags.
- API docs check: Updated — added Gemma tag context/decision/result schemas, documented tagging on normalize responses and job results, and added `tagContext` to normalize job request bodies.
- Verification:
  - `node --check server.js`, `node --check gemmaNormalize.js`, `node --check public/todolist2.js`, `node --check openapi.js` (pass).
  - `node --test tests/gemma-normalize.test.js tests/gemma-ui.test.js tests/openapi.test.js` (pass).
  - `npx prettier --check gemmaNormalize.js server.js public/todolist2.js openapi.js tests/gemma-normalize.test.js tests/gemma-ui.test.js tests/openapi.test.js prompts/gemma-normalize-instructions.md` (pass).
  - `npm run lint` (fails due pre-existing formatting warnings in `prompts/gemma-classify-instructions.md` and `tests/column-actions.test.js`, not touched in this session).

### 2026-05-27

- Summary: Added a column-level `Remove sorting` action so active sort metadata can be cleared without changing current card order.
- Files/areas: `public/columnActions.js`, `public/columnSort.js`, `public/todolist2.js`, `tests/column-actions.test.js`, `tests/column-sort.test.js`.
- User-visible impact:
  - The `Sort` submenu now includes `Remove sorting`.
  - Removing sorting clears the column `sortState` so future card updates no longer auto-reapply that sort.
  - The current visible card order is kept as-is when sorting is removed.
  - The sort submenu now marks `Remove sorting` as selected when no sort is active.
- API docs check: N/A — UI behavior change only; no HTTP/OpenAPI surface change.
- Verification:
  - `node --test tests/column-sort.test.js tests/column-actions.test.js` (pass).

### 2026-05-26

- Summary: Added structured voice-to-text diagnostics for permission checks, start/stop lifecycle, recognition errors, and unexpected stop conditions.
- Files/areas: `public/todolist2.js`.
- User-visible impact:
  - Voice capture now reports specific failure reasons (for example `no-speech`, `audio-capture`, `network`, and permission blocks) instead of only generic failure messaging.
  - When listening starts and then ends without transcript capture, the app now surfaces a clearer stop toast and emits detailed diagnostic context.
  - Browser diagnostics are now available as `[VoiceInput]` console entries and in-memory `window.__voiceInputDiagnostics` logs.
- API docs check: N/A — browser-side diagnostics only; no HTTP/OpenAPI contract change.
- Verification:
  - `node --check public/todolist2.js` (pass).
  - `node --test tests/gemma-ui.test.js` (pass).

### 2026-05-26

- Summary: Fixed add-task Gemma over-splitting so `card_count: 1` inputs normalize once from the full source text instead of once per pre-split candidate line.
- Files/areas: `server.js`, `tests/gemma-normalize.test.js`.
- User-visible impact:
  - Long multiline normalize requests with explicit single-card intent now create one normalized card instead of multiple fragmented cards.
  - Classification still runs first, but add-task normalization now uses the full input in one pass when `input` is present.
  - Existing multi-card extraction behavior remains available from a single normalization result via classified `items`/text extraction.
- API docs check: N/A — no new endpoint or schema change in this follow-up fix.
- Verification:
  - `npm test -- tests/gemma-normalize.test.js` (pass).
  - `npm test -- tests/openapi.test.js` (pass).
  - `npm run lint` (fails due pre-existing formatting issue in `prompts/gemma-classify-instructions.md`, unrelated to this session’s code changes).

### 2026-05-26

- Summary: Added a standardized Gemma final-review payload so parsed responses always resolve to either updated output or the original output fallback.
- Files/areas: `server.js`, `openapi.js`, `tests/gemma-normalize.test.js`.
- User-visible impact:
  - `POST /api/gemma-normalize` now returns `finalReview` with a resolved `output`, `originalOutput`, `updatedOutput`, and fallback flags.
  - Completed `refine-card` job results now include a standardized `finalReview` payload even when the underlying job executor returns legacy fields.
  - Refine multi-card replacements now carry `createdTaskTexts` so final-review output can represent updated multi-output cases.
- API docs check: Updated — added `GemmaFinalReviewPayload`, documented `finalReview` on direct normalize responses and refine job results, and aligned refine-result required fields with replacement scenarios where `nextText` can be absent.
- Verification:
  - `npm test -- tests/gemma-normalize.test.js` (pass).
  - `npm test -- tests/openapi.test.js` (pass).
  - `npm run lint` (fails due pre-existing formatting issue in `prompts/gemma-classify-instructions.md`, unrelated to this session’s code changes).

### 2026-05-26

- Summary: Implemented persistent server-backed pinned-board storage for top toolbar pins, added pinned-board sync APIs, and wired frontend pin/unpin/reorder flows to synchronize across devices with local fallback bootstrap.
- Files/areas: `dal.js`, `server.js`, `openapi.js`, `public/apiService.js`, `public/todolist2.js`, `tests/api.test.js`, `tests/openapi.test.js`, `tests/pinned-board-sync.test.js`.
- User-visible impact:
  - Top toolbar pinned boards now persist in shared server storage instead of device-local-only storage.
  - Pin, unpin, and pinned-order changes now sync to the server so they appear consistently across devices connected to the same WorkLists backend.
  - Existing local pinned boards automatically bootstrap to server storage when server-side pinned state is empty.
  - Invalid/stale pinned IDs are normalized and filtered against existing boards during sync.
- API docs check: Updated — added `/boards/pinned` GET/PUT, new pinned-board request/response schemas, and expanded `DataStore` schema with `pinnedBoardIds`.
- Verification:
  - `node --test tests/api.test.js tests/openapi.test.js tests/pinned-board-sync.test.js` (pass).
  - `npm run lint` (fails due pre-existing formatting issue in `prompts/gemma-classify-instructions.md`, unrelated to this session’s code changes).
  - `npm test` (fails in pre-existing `tests/gemma-normalize.test.js` model expectation mismatch, unrelated to this session’s pinned-board sync changes).

### 2026-05-26

- Summary: Simplified search filters by removing scope toggles (`Tags`, `Completion`, `Card contents`, `Column titles`) and keeping only `Current board only`; search now ignores tag metadata and only matches card text/column titles.
- Files/areas: `public/index.html`, `public/todolist2.js`, `public/todoliststyles2.css`, `tests/filter-menu.test.js`, `tests/search-scopes.test.js`.
- User-visible impact:
  - Search filter controls no longer show `All`/`Clear` or scope checkboxes.
  - `Search filters` section now only contains `Current board only`.
  - Typing a tag name in search no longer matches cards by tag assignment; tag filtering now occurs only through the color/secondary tag filter sections.
  - `Show completed`, color tag filters, and secondary tag filters remain unchanged.
- API docs check: N/A — UI/search behavior only; no HTTP or OpenAPI contract changes.
- Verification:
  - `node --test tests/filter-menu.test.js tests/search-scopes.test.js tests/secondary-tags.test.js tests/context-windows.test.js` (pass).
  - `npm run lint` (fails due pre-existing formatting issue in `prompts/gemma-classify-instructions.md`, unrelated to this session’s code changes).

### 2026-05-26

- Summary: Consolidated tag/completion filtering into the existing top-right `Filters` dropdown so search scope and tag filters share one multi-section menu.
- Files/areas: `public/index.html`, `public/todoliststyles2.css`, `public/todolist2.js`, `tests/filter-menu.test.js`.
- User-visible impact:
  - The separate tag filter trigger/menu was removed from the top nav.
  - The existing `Filters` dropdown now contains multiple sections: search filters, completion toggle, color tag filters, and secondary tag filters.
  - `Select all` / `Clear all` actions for color and secondary tags remain available inside this consolidated menu.
- API docs check: N/A — UI-only menu/layout consolidation; no HTTP or OpenAPI contract changes.
- Verification:
  - `node --test tests/filter-menu.test.js tests/search-scopes.test.js tests/secondary-tags.test.js tests/context-windows.test.js` (pass).
  - `npm run lint` (fails due pre-existing formatting issue in `prompts/gemma-classify-instructions.md`, unrelated to this session’s code changes).

### 2026-05-26

- Summary: Moved card filtering to a top-nav dropdown, added secondary-tag filtering with `Select all`/`Clear all`, and removed the legacy bottom-right filter UI.
- Files/areas: `public/index.html`, `public/todoliststyles2.css`, `public/todolist2.js`, `tests/filter-menu.test.js`, `tests/secondary-tags.test.js`.
- User-visible impact:
  - Filter controls now live in the top-right navigation area as a context-style dropdown.
  - The filter menu now includes both color-tag and secondary-tag sections with independent multi-select checkboxes.
  - Each tag section includes `Select all` and `Clear all` actions for faster filtering workflows.
  - Legacy fixed bottom-right filter controls were removed.
- API docs check: N/A — UI-only filtering/menu updates; no HTTP or OpenAPI contract changes.
- Verification:
  - `node --test tests/filter-menu.test.js tests/secondary-tags.test.js tests/context-windows.test.js` (pass).
  - `npm run lint` (fails due pre-existing formatting issue in `prompts/gemma-classify-instructions.md`, unrelated to this session’s code changes).
  - `npm test` (fails in pre-existing `tests/gemma-normalize.test.js` model expectation, unrelated to this session’s filter changes).

### 2026-05-25

- Summary: Added provider-switchable model management with persistent storage, new model CRUD/activate APIs, and a side-panel settings experience for viewing/adding/editing/deleting active normalization models.
- Files/areas: `dal.js`, `server.js`, `modelProviderClient.js`, `gemmaNormalize.js`, `openapi.js`, `public/index.html`, `public/apiService.js`, `public/todolist2.js`, `public/todoliststyles2.css`, `data/models.json`, `data/models.example.json`, `tests/api.test.js`, `tests/gemma-normalize.test.js`, `tests/gemma-ui.test.js`, `tests/openapi.test.js`.
- User-visible impact:
  - Side panel now includes `Model settings` below `Create board`.
  - Users can view configured models, add new models, edit model metadata, delete models, and activate a model from the new settings dialog.
  - Normalization and background normalize jobs now run against the active model configuration rather than a hardcoded model.
  - Provider adapter support now includes `google-genai` and `openai-compatible`, with schema paths prepared for additional providers.
- API docs check: Updated — added `/api/models`, `/api/models/{modelId}`, `/api/models/{modelId}/activate`, expanded normalization response schemas with model metadata, and updated `DataStore` schema to include `models`.
- Verification:
  - `npm test` (pass).
  - `npm run lint` (fails due pre-existing formatting issue in `prompts/gemma-classify-instructions.md`, unrelated to this session’s code changes).

### 2026-05-25

- Summary: Tightened column action menu edge awareness by adding right-edge left-shift behavior for the root menu and viewport-clamped fixed positioning for the Sort submenu.
- Files/areas: `public/columnActions.js`, `public/todoliststyles2.css`, `tests/column-actions.test.js`.
- User-visible impact:
  - Column context menu now shifts left of the trigger near the right screen edge instead of clipping off-screen.
  - Sort submenu now repositions leftward when needed and clamps within viewport boundaries (including bottom edge).
  - Root column menu width is reduced while keeping long sort labels in the wider submenu.
- API docs check: N/A — UI behavior and styling only; no HTTP/OpenAPI contract change.
- Verification:
  - `node --test tests/column-actions.test.js tests/context-windows.test.js` (pass).
  - `npm test` (pass).

### 2026-05-25

- Summary: Fixed context window behavior across card/column/board/tag/search/filter surfaces by making opens mutually exclusive, adding viewport-aware positioning, and stabilizing edit-to-tag chooser handoff.
- Files/areas: `public/todolist2.js`, `public/cardActions.js`, `public/columnActions.js`, `public/secondaryTags.js`, `public/todoliststyles2.css`, `tests/card-actions.test.js`, `tests/column-actions.test.js`, `tests/context-windows.test.js`.
- User-visible impact:
  - Opening one context surface (card actions, column actions, board menu, tag chooser, search scope, filter menu) now closes other open context windows for a consistent single-open experience.
  - Card, column, and board context menus now reposition near viewport edges so they are not clipped off-screen near the bottom.
  - Tag chooser open flow now closes active inline edit state first, preventing stuck/orphaned tag context windows when transitioning from edit mode.
  - Context/menu text now stays on one line with wider menu surfaces instead of wrapping.
- API docs check: N/A — UI behavior and styling only; no HTTP/OpenAPI contract change.
- Verification:
  - `npm test` (pass).

### 2026-05-24

- Summary: Centralized all Gemma response-shaping prompt instructions into `prompts/gemma-normalize-instructions.md` and removed in-code prompt/schema instruction injection.
- Files/areas: `prompts/gemma-normalize-instructions.md`, `gemmaNormalize.js`, `tests/gemma-normalize.test.js`.
- User-visible impact:
  - Gemma normalization behavior is now driven by a single editable prompt file without additional in-code schema/system prompt instructions.
  - Missing/empty Gemma prompt instruction files now return a clear configuration error instead of silently falling back to hardcoded instructions.
- API docs check: N/A — no HTTP surface change.
- Verification:
  - `npm run lint` (pass).
  - `npm test -- tests/gemma-normalize.test.js` (pass).
  - `npm test -- tests/gemma-ui.test.js tests/openapi.test.js` (pass).

### 2026-05-24

- Summary: Added Gemma no-response timeouts and verbatim fallback wiring so voice-captured task text is preserved when normalization jobs fail.
- Files/areas: `gemmaNormalize.js`, `server.js`, `openapi.js`, `public/todolist2.js`, `tests/gemma-normalize.test.js`, `tests/gemma-ui.test.js`.
- User-visible impact:
  - Gemma normalization now returns a deterministic timeout failure when the model does not respond, instead of waiting indefinitely.
  - Add-task Gemma fallback now prioritizes server-returned `verbatimInput` for failed candidates so original wording from task entry (including voice-to-text phrasing) is preserved more accurately.
  - When Gemma background jobs fail or time out, fallback task creation continues to save original task text verbatim.
- API docs check: Updated — documented `504` for `/api/gemma-normalize`, optional `verbatimCandidates` in Gemma add-task job start payload, and expanded add-task failure item fields (`candidateIndex`, `verbatimInput`).
- Verification:
  - `npm run lint` (pass).
  - `npm test -- tests/gemma-normalize.test.js` (pass).
  - `npm test -- tests/gemma-ui.test.js tests/openapi.test.js` (pass).

### 2026-05-24

- Summary: Reduced Gemma process toast collapsed state to a single minimal message and moved all status detail behind expansion.
- Files/areas: `public/todolist2.js`, `public/todoliststyles2.css`, `tests/gemma-ui.test.js`.
- User-visible impact:
  - Collapsed Gemma process toast now shows only `Gemma normalization running in background...` while processing.
  - Sent/processing/received chips, per-item rows, dismiss controls, fallback details, and refine undo actions are only visible after expanding the toast.
  - Terminal Gemma states remain minimal in the collapsed toast while fallback details stay available inside the expanded panel.
- API docs check: N/A — UI-only toast behavior; no HTTP or OpenAPI contract change.
- Verification:
  - `npm run lint` (pass).
  - `node --test tests\gemma-ui.test.js` (pass).
  - `npm test` (pass).

### 2026-05-23

- Summary: Added server-backed async Gemma jobs with refresh-resilient UI indicators for add-task normalization and card refine.
- Files/areas: `server.js`, `openapi.js`, `public/apiService.js`, `public/todolist2.js`, `tests/gemma-normalize.test.js`, `tests/gemma-ui.test.js`, `tests/openapi.test.js`.
- User-visible impact:
  - `Normalize with Gemma` for add-task now runs as a background job and no longer depends on the page staying open through a synchronous request.
  - Card `Refine with Gemma` now runs as a background job with the same non-blocking behavior.
  - Add-task and card-level `Gemma running...` states now persist through UI rerenders and full page refreshes, then clear automatically when the job reaches a terminal status.
  - Completed background jobs refresh board data and emit completion/failure toasts without echoing full task content.
- API docs check: Updated — added documented Gemma background job endpoints and schemas (`/api/gemma-normalize/jobs`, `/api/gemma-normalize/jobs/{jobId}`).
- Verification:
  - `npm test -- tests/gemma-ui.test.js tests/gemma-normalize.test.js tests/openapi.test.js` (pass).
  - `npm test -- tests/add-task-entry.test.js tests/edit-session.test.js tests/card-actions.test.js tests/search-shortcuts.test.js` (pass).

### 2026-05-23

- Summary: Simplified task-entry Gemma success toasts and made Normalize operations stop active voice-to-text before executing.
- Files/areas: `public/todolist2.js`, `tests/gemma-ui.test.js`.
- User-visible impact:
  - Task-entry `Normalize with Gemma` success notifications no longer echo full task text.
  - Normalize now force-stops active voice-to-text and still runs in the same button press/hotkey action.
  - Card-edit Gemma normalize hotkey now stops active voice capture before refinement runs.
- API docs check: N/A — no HTTP or OpenAPI contract change.
- Verification:
  - `npm test -- tests/gemma-ui.test.js` (pass).
  - `npm test -- tests/add-task-entry.test.js tests/search-shortcuts.test.js` (pass).

### 2026-05-23

- Summary: Fixed voice-to-text repetition after pauses and enabled live in-progress transcript rendering during continuous speech.
- Files/areas: `public/todolist2.js`, `tests/gemma-ui.test.js`.
- User-visible impact:
  - Voice-to-text no longer re-appends previously recognized phrases after each pause.
  - In-progress speech now appears in the input immediately (interim transcript updates) instead of waiting for a long pause.
  - Finalized chunks continue to settle into the same input stream without duplicating already-committed sections.
- API docs check: N/A — no HTTP or OpenAPI contract change.
- Verification:
  - `npm run lint` (pass).
  - `npm test -- tests/gemma-ui.test.js tests/add-task-entry.test.js tests/board-refresh.test.js` (pass).
  - `npm test` (pass).

### 2026-05-23

- Summary: Prevented unsent new-task draft loss during board refresh/rerender and hardened voice-to-text continuity during refresh cycles.
- Files/areas: `public/todolist2.js`, `tests/add-task-entry.test.js`, `tests/board-refresh.test.js`, `tests/gemma-ui.test.js`.
- User-visible impact:
  - New-task text in each column now persists across board re-renders and full page refresh lifecycle events (`beforeunload`/`pagehide`) until the draft is intentionally submitted or cleared.
  - Task-entry drafts are now restored after UI refreshes by board/column context, preventing idle refresh from wiping in-progress work.
  - Idle/background board refresh now pauses while voice-to-text is actively listening, avoiding dictation interruption.
  - Active voice-to-text control state is reattached after board rerenders so `Stop Listening` remains available on the recreated controls.
- API docs check: N/A — no HTTP or OpenAPI contract change.
- Verification:
  - `npm run lint` (pass).
  - `npm test -- tests/add-task-entry.test.js tests/board-refresh.test.js tests/gemma-ui.test.js` (pass).
  - `npm test` (pass).

### 2026-05-23

- Summary: Fixed multi-card Gemma creation reliability, improved voice-to-text stop/permission UX, and added persistent card-level Gemma async indicators.
- Files/areas: `public/todolist2.js`, `public/todoliststyles2.css`, `gemmaNormalize.js`, `openapi.js`, `prompts/gemma-normalize-instructions.md`, `tests/gemma-ui.test.js`, `tests/gemma-normalize.test.js`, `tests/openapi.test.js`.
- User-visible impact:
  - Multi-card Gemma creation now reliably creates every requested card even after the board re-renders during sequential inserts.
  - Gemma result parsing now supports multi-item payload shapes (`items`, `tasks`, `cards`, array payloads) and creates one card per normalized item.
  - Voice-to-text now has an intuitive stop flow: add-task voice button toggles to `Stop Listening`, toast includes `Stop`, and `Esc` stops active recording.
  - Voice-to-text now primes microphone permission once with `getUserMedia` and caches the grant for the page session before starting SpeechRecognition, reducing repeated browser permission prompts.
  - Voice permission-denied loops are reduced with a short cooldown and clearer guidance toast when microphone access is blocked.
  - Card-level `Gemma running...` indicators now render while refine is in progress and persist correctly across UI refresh/re-render cycles.
  - Card action menu now marks `Refine with Gemma` as running while refinement is active.
- Verification:
  - `npm run lint` (pass).
  - `npm test -- tests/gemma-ui.test.js tests/gemma-normalize.test.js tests/card-actions.test.js tests/add-task-entry.test.js tests/edit-session.test.js tests/openapi.test.js tests/task-clipboard.test.js tests/search-shortcuts.test.js` (pass).
  - `npm test` (pass).

### 2026-05-23

- Summary: Extended Gemma and task authoring UX with card refine + undo, multi-card add, voice-to-text, and normalization hotkeys.
- Files/areas: `public/todolist2.js`, `public/cardActions.js`, `public/todoliststyles2.css`, `tests/gemma-ui.test.js`, `tests/card-actions.test.js`, `tests/add-task-entry.test.js`, `tests/edit-session.test.js`.
- User-visible impact:
  - Card action menu now includes `Refine with Gemma` and `Voice to Text`.
  - `Refine with Gemma` updates the card text and shows an `Undo` action in the shared bottom-right toast.
  - Add-task Gemma input now supports multi-line multi-card entry and can create multiple cards in one run.
  - Voice-to-text is now available for add-task entry and inline card edit.
  - `Ctrl/Cmd + Shift + Enter` now runs Gemma normalization from add-task and inline card edit contexts.
  - Add-task action row remains visible while voice capture is active, preventing premature collapse during listening.
- Verification:
  - `npm run lint` (pass).
  - `npm test -- tests/gemma-ui.test.js tests/card-actions.test.js tests/add-task-entry.test.js tests/edit-session.test.js tests/task-clipboard.test.js tests/search-shortcuts.test.js` (pass).
  - `npm test` (pass).

### 2026-05-23

- Summary: Added copy-to-clipboard toast feedback for card descriptions and generalized toast timing options for broader component reuse.
- Files/areas: `public/todolist2.js`, `tests/task-clipboard.test.js`.
- User-visible impact:
  - Copying a card description now shows a bottom-right toast confirmation.
  - Clipboard copy failures now show a bottom-right error toast.
  - Shared app toast API now accepts configurable timeout options to support varied component flows (including undo-style actions).
- Verification:
  - `npm test -- tests/task-clipboard.test.js tests/card-actions.test.js tests/column-move-ui.test.js` (pass).

### 2026-05-23

- Summary: Added `Esc` cancellation for new task entry and inline card editing while keeping active search state intact.
- Files/areas: `public/todolist2.js`, `tests/add-task-entry.test.js`, `tests/edit-session.test.js`, `tests/search-shortcuts.test.js`.
- User-visible impact:
  - Pressing `Esc` in the add-task textarea now clears draft text and exits focus.
  - Pressing `Esc` while editing a card now clears the edit draft and exits edit mode without saving.
  - `Esc` cancellation for add/edit no longer cascades into search cancellation.
- Verification:
  - `npm test -- tests/add-task-entry.test.js tests/edit-session.test.js tests/search-shortcuts.test.js` (pass).

### 2026-05-23

- Summary: Removed Gemma result payload rendering under task entry and moved normalization feedback to toast-only messaging.
- Files/areas: `public/todolist2.js`, `public/todoliststyles2.css`, `tests/gemma-ui.test.js`.
- User-visible impact:
  - Running `Normalize with Gemma` no longer shows any JSON/result box under `Add Task`.
  - Success/error details now appear through the app toast flow only.
  - Empty-input guidance for Gemma remains toast-driven and keeps focus on task entry.
- Verification:
  - `npm test -- tests/gemma-ui.test.js` (pass).
  - `npm test -- tests/add-task-entry.test.js tests/gemma-ui.test.js` (pass).

### 2026-05-22

- Summary: Extended card move to support cross-board destinations while preserving the existing unified card action menu pattern.
- Files/areas: `public/todolist2.js`, `public/apiService.js`, `server.js`, `dal.js`, `openapi.js`, `tests/api.test.js`, `tests/openapi.test.js`, `tests/card-move-ui.test.js`, `JOB_STORIES_CONTEXT.md`.
- User-visible impact:
  - Card `Move` now supports selecting a destination board and then a destination column.
  - Placement selection is still available and defaults to end-of-column placement.
  - Move behavior aligns with the column move dialog pattern (search/filter + placement).
- Data safety:
  - Existing backup retained at `data-backups/20260522-000757/`.
- Verification:
  - `node --test tests/card-move-ui.test.js tests/openapi.test.js tests/api.test.js` (pass).

### 2026-05-22

- Summary: Implemented Move Card from one column to another through the card action menu, using a column-move-style dialog and an atomic backend move endpoint.
- Files/areas:
  - `dal.js`
  - `server.js`
  - `openapi.js`
  - `public/apiService.js`
  - `public/cardActions.js`
  - `public/todolist2.js`
  - `public/todoliststyles2.css`
  - `.prettierignore`
  - `tests/api.test.js`
  - `tests/openapi.test.js`
  - `tests/card-actions.test.js`
  - `tests/card-move-ui.test.js`
- User-visible impact:
  - Card action menu now supports `Move` as an active action.
  - Move opens a destination/placement dialog with the same interaction pattern and layout family as column move.
  - Moving a card updates source and destination column ordering while preserving the card's details and tags.
- Safety/data integrity:
  - Created backup before integration work: `data-backups/20260522-000757/`.
- Verification run:
  - `npm test`
  - `npm run lint:fix`
  - `npm run lint`
  - `npm test` (post-format verification)
- API docs check:
  - Updated OpenAPI contract for `POST /todos/{id}/move` with request/response schemas and coverage.

### 2026-05-22

- Summary: Consolidated card-level copy and delete controls into a single hover-revealed ellipsis menu and added a visible Move placeholder for upcoming board-to-board card moves.
- Files/areas:
  - `public/cardActions.js`
  - `public/todolist2.js`
  - `public/todoliststyles2.css`
  - `public/taskClipboard.js`
  - `public/index.html`
  - `tests/card-actions.test.js`
  - `tests/task-clipboard.test.js`
- User-visible impact:
  - Card actions are now available from one consistent ellipsis menu on each card.
  - Copy and Delete remain functional from the new menu.
  - Move is visible as a non-destructive placeholder labeled as coming soon.
  - Hover-based action discovery is preserved.
- Verification run:
  - `npm test`
  - `npm run lint`
- API docs check:
  - N/A - no HTTP API contract change in this session.

### 2026-05-22

- Summary: Implemented deferred post-edit reordering for tag-based sorts so cards do not move while the user is still making tag selections.
- Files/areas:
  - `public/todolist2.js`
  - `tests/secondary-tags.test.js`
- User-visible impact:
  - Tag-based sorting now waits until tag editing is finished (Done, outside click, Escape, chooser close).
  - New untagged items remain at the bottom when active tag sort is applied.
  - Repeated tag edits reapply sort consistently after completion.
- Verification run:
  - `node --test tests/secondary-tags.test.js tests/column-sort.test.js tests/edit-session.test.js`
  - `npm run lint`
- API docs check:
  - N/A - no HTTP API contract change in this session.

## Current state

- Full regression and formatting checks are passing.

- Active sort reapply remains enforced after add/create for sorted columns.

- Deferred tag-sort flush logic remains implemented and wired to tag chooser completion events.

- Voice-to-text now emits structured `[VoiceInput]` diagnostics for permission checks, start/stop lifecycle events, recognition errors, and unexpected silent stops, with buffered client-side traces accessible via `window.__voiceInputDiagnostics`.
- Gemma create/refine workflows now carry current primary and secondary tag inventories into the normalization pass, return structured tagging outcomes with content/final review, and persist proposed new secondary tags only when no existing tag matches.
- Add-task Gemma jobs now run single-pass normalization from full `input` text when provided, preventing line-by-line card fragmentation for explicit single-card requests.
- Gemma normalize API and refine-card job results now include a standardized `finalReview` payload that always resolves an `output` by preferring updated output and falling back to original output when no changes are produced.
- Top toolbar pinned boards now persist as shared server data (`pinnedBoardIds`) and synchronize across devices through `/boards/pinned` GET/PUT APIs, with local fallback/bootstrap behavior.
- The existing top-right `Filters` dropdown is now a consolidated multi-section menu containing search filters plus card visibility/tag filters (completion, color tags, and secondary tags with section-level `Select all`/`Clear all` actions).
- The top-right Filters and Scheduler controls now use compact icon-first buttons with descriptive tooltips/ARIA labels; Scheduler keeps a small scheduled-count badge.
- Column reset now uses a refresh icon with a descriptive tooltip/ARIA label.
- Search filters now only expose `Current board only`; search scope toggles were removed and search no longer uses tag metadata as an implicit match source.
- The legacy fixed bottom-right filter controls have been removed.
- Context windows now follow a shared exclusivity model: opening one closes the others across card actions, column actions, board menu, tag chooser, search scope, and filters.
- Card, column, and board context menus now use viewport-aware placement to avoid bottom-edge clipping.
- Column root context menu now shifts left near the right viewport edge, and the Sort submenu now uses fixed viewport-aware positioning with left-flip/clamping so labels remain visible.
- Column `Sort` submenu now includes `Remove sorting`, which clears persisted sort metadata and stops automatic re-sorting for that column while preserving the current card order.
- Tag chooser now closes active inline edit context before opening, preventing stuck context windows during edit-to-tag transitions.
- Context/menu surfaces were widened and set to non-wrapping labels to preserve single-line action text.
- All Gemma response-shaping prompt instructions now live in `prompts/gemma-normalize-instructions.md`; in-code instruction/schema prompt injection has been removed.
- Gemma no-response cases now time out deterministically and return a timeout error path that feeds existing fallback handling.
- Add-task Gemma failure metadata now carries candidate index and verbatim fallback text so voice-derived wording is preserved when per-item normalization fails.
- Voice-to-text now streams interim text into inputs live during continuous speech and avoids repeated chunk duplication across pauses.
- New-task drafts persist across board rerenders and page refresh lifecycle events, scoped by board/column.
- Idle/background refresh pauses while task-entry voice-to-text is actively listening.
- Voice-to-text listening controls are reattached after rerender so stop-state remains visible and actionable.
- Gemma normalization feedback is toast-only; no JSON payload or message panel renders beneath task entry.
- Task-entry Gemma success toasts use count-based summaries and do not include normalized task contents.
- Copying card descriptions now emits shared bottom-right toast feedback for success and failure.
- Shared toast helper supports configurable timeout options for reuse across UI components.
- `Esc` now cancels add-task drafts and inline card edits without interrupting active search state.
- Card actions are unified under one ellipsis menu with `Copy`, `Refine with Gemma`, `Voice to Text`, `Move`, and `Delete`.
- Gemma refine supports inline undo via shared toast actions.
- Add-task Gemma normalization supports single-card and multi-card creation flows, including multi-item response payload parsing.
- Voice-to-text is available for both new-card entry and inline card editing, with stop controls (`Stop Listening`, toast `Stop`, and `Esc`).
- Voice permission denied states now use cooldown protection to reduce repetitive permission prompts.
- Card-level Gemma async running indicators persist across refresh/re-render cycles.
- `Ctrl/Cmd + Shift + Enter` triggers Gemma normalization in add-task and card-edit textareas, and now stops active voice-to-text first.
- Gemma add-task and card refine execution now runs through server-side background jobs with client polling so work continues through page refreshes.
- Card move supports same-board and cross-board destinations using board-aware validation.
- API contract includes board-aware card move request/response metadata (`sourceBoardId`, `destinationBoardId`, `sourceBoard`, `destinationBoard`).
