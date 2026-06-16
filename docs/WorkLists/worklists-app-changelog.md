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

### 2026-06-16T22:48:56Z - WorkLists

- Summary: Corrected tag color behavior and added secondary-tag settings management.
- Problem: The prior color-tag settings pass colored tag labels/menus instead of only coloring cards, and legacy todo-only primary tags such as Architecture could appear in the UI without being editable API records. Secondary tags also lacked focused settings CRUD, merge, and delete reconciliation.
- Requirement: Primary tag color must apply to the card only; tag labels and chooser/filter rows stay neutral. Settings must manage secondary tags without colors, support create/rename/delete, merge duplicate tags into a target, and reconcile assigned cards on deletion by replacement or removal.
- Solution: Moved primary tag color application to card backgrounds, removed operational tag-label/menu color styling, and hydrates legacy todo tag names into editable primary tag records. Added Settings > Secondary Tags with create/rename/delete controls, replacement selection, and Squash and merge. Added `/secondary-tags/merge`, delete replacement payload support, API client methods, OpenAPI schemas, and tests.
- Files/areas: `dal.js`, `server.js`, `openapi.js`, `public/apiService.js`, `public/todolist2.js`, `public/todoliststyles2.css`, `tests/api.test.js`, `tests/openapi.test.js`, `tests/gemma-ui.test.js`, `tests/secondary-tags.test.js`, canonical changelog.
- User-visible impact: Cards now take primary tag color while the visible tag text remains neutral. Existing card tags like Architecture can be edited from Tag Colors. Settings now includes Secondary Tags management with CRUD, delete replacement/removal, and single-source merge.
- Tests run:

  | Gate | Command | Scope | Result | Exception / risk |
  | ---- | ------- | ----- | ------ | ---------------- |
  | format | `npx prettier --write dal.js server.js openapi.js public\apiService.js public\todolist2.js public\todoliststyles2.css tests\api.test.js tests\openapi.test.js tests\gemma-ui.test.js tests\secondary-tags.test.js` | Touched source/test files | pass | - |
  | syntax | `node --check dal.js`; `node --check server.js`; `node --check public\apiService.js`; `node --check public\todolist2.js` | Touched JS files | pass | - |
  | tests | `node --test tests\api.test.js tests\openapi.test.js tests\gemma-ui.test.js tests\secondary-tags.test.js` | Tag APIs, settings UI source contracts, OpenAPI, card color rendering | pass, 123 tests | - |
  | audit | `npm audit --audit-level=high` | Dependency security gate | pass, 0 vulnerabilities | - |
  | lint | `npm run lint` | WorkLists formatting gate | pass | - |
  | tests | `npm test` | Full WorkLists suite | pass, 435 tests | - |

- Tests added/updated: Added API coverage for legacy todo-only primary tag hydration, secondary delete replacement, and secondary squash-merge. Updated OpenAPI and settings UI source checks, plus card-rendering source coverage proving primary color applies to cards without coloring `.tag-label`.
- Regression impact: Touched shared tag hydration, card rendering, settings, secondary tag mutation, and atomic JSON write handling. Full suite passed; request helper now sends `Content-Length` for JSON bodies so DELETE body tests match browser/fetch behavior.
- API docs: Updated OpenAPI for `/secondary-tags/merge`, secondary delete replacement request/response, and secondary merge/delete schemas. Existing `/primary-tags` docs remain aligned with primary tag CRUD.
- Tooling gates: `npm audit --audit-level=high`, `npm run lint`, and `npm test` all passed.
- Conflicts / exceptions: Existing dirty shortcut/card-move/edit-session files were present before this task and left intact.

### 2026-06-16T22:25:00Z - WorkLists

- Summary: Added customizable color-tag settings.
- Problem: Color tags were managed from scattered chooser-local behavior and client storage, with no centralized settings surface or server-backed color customization.
- Requirement: Settings must expose tag color management with create, read, update, and delete parity, persist tag records through the API, and keep todo primary-tag assignments consistent when tags are renamed or deleted.
- Solution: Added `primaryTags` data storage and `/primary-tags` CRUD APIs with duplicate/name/color validation and todo cascade updates. Added Settings > Tag Colors with list/editor/preview controls, API client methods, server hydration for tag records, inline color rendering for card labels and chooser/filter swatches, OpenAPI coverage, example/current data files, and regression tests.
- Files/areas: `dal.js`, `server.js`, `openapi.js`, `public/apiService.js`, `public/boardData.js`, `public/todolist2.js`, `public/todoliststyles2.css`, `data/primaryTags.json`, `data/primaryTags.example.json`, `tests/api.test.js`, `tests/openapi.test.js`, `tests/gemma-ui.test.js`, `tests/board-refresh.test.js`, canonical changelog.
- User-visible impact: The side-panel Settings window now includes a Tag Colors tab where color tags can be added, renamed, recolored, and deleted. Card tag labels, tag chooser rows, and filter menu rows reflect custom colors.
- Tests run:

  | Gate | Command | Scope | Result | Exception / risk |
  | ---- | ------- | ----- | ------ | ---------------- |
  | format | `npx prettier --write dal.js server.js openapi.js public\apiService.js public\boardData.js public\todolist2.js public\todoliststyles2.css tests\api.test.js tests\openapi.test.js tests\gemma-ui.test.js tests\board-refresh.test.js data\primaryTags.json data\primaryTags.example.json` | Touched source/test/data files | pass | - |
  | syntax | `node --check dal.js`; `node --check public\todolist2.js` | Core touched JS after formatting | pass | - |
  | tests | `node --test tests\api.test.js` | Primary tag API, data migration/read/write, cascades | pass, 74 tests | - |
  | tests | `node --test tests\openapi.test.js tests\gemma-ui.test.js tests\board-refresh.test.js` | OpenAPI/settings UI/board snapshot contracts | pass, 43 tests | - |
  | audit | `npm audit --audit-level=high` | Dependency security gate | pass, 0 vulnerabilities | - |
  | lint | `npm run lint` | WorkLists formatting gate | pass | - |
  | tests | `npm test` | Full WorkLists suite | pass, 431 tests | - |

- Tests added/updated: Added API coverage for primary-tag list/create/update/delete, duplicate and invalid color rejection, and rename/delete cascades into todo primary tags. Updated OpenAPI, settings UI source, and board refresh snapshot contracts for primaryTags.
- Regression impact: Primary tag changes touch shared data hydration, `/data`, card rendering, filter menu, tag chooser, and settings. Full suite passed; secondary tag CRUD remains separate and covered by existing/new API assertions.
- API docs: Updated OpenAPI for `/primary-tags`, `/primary-tags/{id}`, `PrimaryTag` schemas, mutation responses, and `DataStore.primaryTags`.
- Tooling gates: `npm audit --audit-level=high`, `npm run lint`, and `npm test` all passed.
- Conflicts / exceptions: Local server start check initially failed due PowerShell quoting, then confirmed an existing server was already listening on `http://localhost:3010`.

### 2026-06-16T21:21:21Z - WorkLists

- Summary: Added user-rebindable shortcut settings.
- Problem: WorkLists shortcut commands had registry defaults and local override storage, but no settings surface for viewing, capturing, validating, or resetting user bindings.
- Requirement: Settings must expose all registered shortcut commands, show default/current mappings, capture replacement key combinations, reject conflicts/reserved chords, and persist overrides through the existing shortcut registry storage.
- Solution: Added a `Shortcuts` Settings tab that renders `ShortcutRegistry.list()`, captures new chords via `ShortcutController.beginCapture()`, validates modifier-only/global/plain-key/reserved/conflicting bindings, saves overrides with `setOverride()`, resets with `clearOverride()`, and stops capture on settings close. Styled the rows for the existing settings modal and extended shortcut contract tests.
- Files/areas: `public/todolist2.js`, `public/todoliststyles2.css`, `tests/shortcut-registry.test.js`, canonical changelog.
- User-visible impact: Settings now includes a Keyboard Shortcuts tab where current mappings can be viewed, rebound, persisted, and reset.
- Tests run:

  | Gate | Command | Scope | Result | Exception / risk |
  | ---- | ------- | ----- | ------ | ---------------- |
  | format | `npx prettier --write public\todolist2.js public\todoliststyles2.css tests\shortcut-registry.test.js` | Touched source/test files | pass | - |
  | syntax | `node --check public\todolist2.js`; `node --check public\shortcutRegistry.js`; `node --check tests\shortcut-registry.test.js` | Shortcut/settings JS | pass | - |
  | tests | `node --test tests\shortcut-registry.test.js` | Shortcut registry/controller/settings contract | pass, 19 tests | - |
  | audit | `npm audit --audit-level=high` | Dependency security gate | pass, 0 vulnerabilities | - |
  | lint | `npm run lint` | WorkLists formatting gate | pass | - |
  | tests | `npm test` | Full WorkLists suite | pass, 429 tests | - |

- Tests added/updated: Added `tests/shortcut-registry.test.js` coverage for override conflict rejection and source-level Settings tab wiring for capture, validation, save, reset, cleanup, and CSS rows.
- Regression impact: Shortcut registry/controller path remains shared. Existing board, search, voice, modal, task-entry, card-edit, notes-pane, scheduler, AI, and settings-toggle shortcut coverage passed full suite.
- API docs: Not relevant: client-side settings/keyboard shortcut behavior only; no route, method, request/response schema, status, auth, or OpenAPI metadata changed.
- Conflicts / exceptions: Existing dirty changes in `public/shortcutController.js`, `tests/card-move-ui.test.js`, and `tests/edit-session.test.js` were present before this session and left intact.


### 2026-06-16T21:14:50Z - WorkLists

- Summary: Made settings shortcut toggle the window.
- Problem: `Ctrl + Shift + ]` opened settings but could not close it because the settings overlay put shortcut handling into modal scope with global shortcuts suppressed.
- Requirement: The same configurable settings shortcut must close the settings window when it is already open, without weakening other modal shortcut behavior.
- Solution: Renamed the command to `settings.toggle`, made its handler close `closeModelSettingsDialog()` first and open only when nothing was closed, and let the shortcut controller keep global shortcuts available specifically for `.model-settings-overlay` while card/column move modals remain modal-only. Added regression coverage for dispatching the settings shortcut while the settings modal is already visible.
- Files/areas: `public/todolist2.js`, `public/shortcutController.js`, `tests/shortcut-registry.test.js`, canonical changelog.
- User-visible impact: `Ctrl + Shift + ]` now opens settings from the board and closes settings when pressed again while the settings window is open.
- Tests run:

  | Gate   | Command                                                                                      | Scope                    | Result          | Exception / risk |
  | ------ | -------------------------------------------------------------------------------------------- | ------------------------ | --------------- | ---------------- |
  | format | `npx prettier --write public\shortcutController.js public\todolist2.js tests\shortcut-registry.test.js` | Touched source/test files | pass            | -                |
  | syntax | `node --check public\shortcutController.js`; `node --check public\todolist2.js`; `node --check tests\shortcut-registry.test.js` | Touched JS/test files    | pass            | -                |
  | tests  | `node --test tests\shortcut-registry.test.js`                                               | Shortcut contract        | pass, 17 tests  | -                |
  | audit  | `npm audit --audit-level=high`                                                               | Dependency security gate | pass, 0 vulns   | -                |
  | lint   | `npm run lint`                                                                               | Formatting gate          | pass            | -                |
  | tests  | `npm test`                                                                                   | Full WorkLists suite     | pass, 427 tests | -                |

- Tests added/updated: Updated `tests/shortcut-registry.test.js` for `settings.toggle`, including a modal-open regression where `.model-settings-overlay` is visible and the same shortcut dispatches again.
- Regression impact: Isolated to settings shortcut scope/handler. Modal Escape priority still resolves `modal.dismiss`; card/column move overlays continue suppressing global shortcuts; search, board panel, task entry, card edit, notes-pane, voice, and AI shortcuts passed full suite.
- API docs: Not relevant: client-side keyboard shortcut only; no route, method, request/response schema, status, auth, or OpenAPI metadata changed.
- Conflicts / exceptions: None.

### 2026-06-16T21:08:28Z - WorkLists

- Summary: Added global settings shortcut.
- Problem: Settings required opening the side panel and clicking the settings button.
- Requirement: `Ctrl + Shift + ]` opens settings directly, with the binding registered through the customizable shortcut system.
- Solution: Added `settings.open` as a global ShortcutRegistry command using `createShortcutBinding("]", { code: "BracketRight", ctrlKey: true, shiftKey: true })`, wired to `openModelSettingsDialog()`. Added shortcut contract coverage for board and task-entry dispatch, command-id registration, and default binding source checks.
- Files/areas: `public/todolist2.js`, `tests/shortcut-registry.test.js`, canonical changelog.
- User-visible impact: Pressing `Ctrl + Shift + ]` opens the WorkLists settings window without using the side panel. The command remains compatible with existing shortcut override/capture seams for future user rebinding.
- Tests run:

  | Gate   | Command                                                         | Scope                    | Result          | Exception / risk |
  | ------ | --------------------------------------------------------------- | ------------------------ | --------------- | ---------------- |
  | format | `npx prettier --write public\todolist2.js tests\shortcut-registry.test.js` | Touched source/test files | pass            | -                |
  | syntax | `node --check public\todolist2.js`; `node --check tests\shortcut-registry.test.js` | Touched JS/test files    | pass            | -                |
  | tests  | `node --test tests\shortcut-registry.test.js`                  | Shortcut contract        | pass, 16 tests  | -                |
  | audit  | `npm audit --audit-level=high`                                  | Dependency security gate | pass, 0 vulns   | -                |
  | lint   | `npm run lint`                                                  | Formatting gate          | pass            | -                |
  | tests  | `npm test`                                                      | Full WorkLists suite     | pass, 426 tests | -                |

- Tests added/updated: Updated `tests/shortcut-registry.test.js` to assert `settings.open` dispatches from global board context and task-entry context, remains registered in the initial command list, and uses the required default binding.
- Regression impact: Isolated to ShortcutRegistry command registration. Existing shortcut controller ownership, scope priority, modal Escape behavior, voice/AI commands, search, board panel, task entry, card edit, and notes-pane shortcuts stayed under the same controller path and passed full suite.
- API docs: Not relevant: client-side keyboard shortcut only; no route, method, request/response schema, status, auth, or OpenAPI metadata changed.
- Conflicts / exceptions: None.

### 2026-06-16T15:00:31Z - WorkLists

- Summary: Fixed grayed-out card move destinations.
- Problem: The card move dialog disabled destination boards/columns through a board-dependent predicate while resolving columns from the current board render slice. After `loadBoard`, `columns` intentionally contains only the visible board, so every non-current board appeared to have no movable columns and rendered disabled.
- Requirement: Only the card's current source column should be unavailable; same-board sibling columns and cross-board destination columns must remain selectable while server-side board/column membership validation stays intact.
- Solution: Changed card move option rendering to disable by source column identity only, not by source-board membership. Board availability now checks whether the board contains any column other than the source column, and cross-board column lookup reads from `getFullBoardDataSnapshot().columns` before falling back to the current render slice. Added regression assertions for same-board/cross-board selectable destinations and full-snapshot column lookup.
- Files/areas: `public/todolist2.js`, `tests/card-move-ui.test.js`, canonical changelog.
- User-visible impact: The `Move card` menu now opens with valid board/column destinations enabled and selectable; only the current column is marked current/disabled.
- Tests run:

  | Gate   | Command                                                                       | Scope                                  | Result                                                                                                       | Exception / risk |
  | ------ | ----------------------------------------------------------------------------- | -------------------------------------- | ------------------------------------------------------------------------------------------------------------ | ---------------- |
  | format | `npx prettier --write public/todolist2.js tests/card-move-ui.test.js`         | Touched source/test files              | pass                                                                                                         | -                |
  | syntax | `node --check public/todolist2.js`; `node --check tests/card-move-ui.test.js` | Touched JS/test files                  | pass                                                                                                         | -                |
  | tests  | `node --test tests/card-move-ui.test.js`                                      | Card move UI contract                  | pass, 9 tests                                                                                                | -                |
  | tests  | `node --test tests/card-move-ui.test.js tests/api.test.js`                    | Card move UI plus move API permissions | initial fail from too-broad source assertion, then focused UI fixed; API move permissions passed in that run | -                |
  | tests  | `node --test tests/openapi.test.js`                                           | OpenAPI docs route/export              | pass, 3 tests                                                                                                | -                |
  | tests  | `npm test`                                                                    | Full WorkLists suite                   | pass, 425 tests                                                                                              | -                |
  | lint   | `npm run lint`                                                                | WorkLists formatting gate              | pass                                                                                                         | -                |
  | audit  | `npm audit --audit-level=high`                                                | Dependency security gate               | pass, 0 vulns                                                                                                | -                |

- Tests added/updated: Added `tests/card-move-ui.test.js` coverage proving card move option rendering disables only the current source column, does not use source-board identity as the disabled predicate, and resolves move destination columns from the full board snapshot rather than only the current render slice.
- Regression impact: Isolated to card move modal option enablement. Backend move validation and OpenAPI contract were checked unchanged; existing API tests still cover cross-board moves and destination-board/column membership rejection.
- API docs: Not relevant: no route, method, request/response schema, status, auth, or OpenAPI metadata changed; checked `/todos/{id}/move` docs via `tests/openapi.test.js`.
- Conflicts / exceptions: None.

### 2026-06-15T21:35:00Z - WorkLists

- Summary: Fixed card-edit Escape cancel leaving a blank card surface.
- Problem: After the shortcut-registry cleanup centralized card edit Escape under `cardEdit.cancel`, the handler cleared the live textarea (`textarea.value = ""`) before suppressing blur-save and asking `loadInitialBoardData()` to refresh. When the refresh gate skipped unchanged payloads, the blank textarea stayed mounted until navigation forced a render.
- Solution: `cardEdit.cancel` now suppresses blur-save, clears the active edit session, blurs the textarea, and forces `loadBoard(currentBoardId, { refresh: false })` so the card is immediately repainted from local board state. The notes pane did not share this bug because its cancel path already renders content directly.
- Files/areas: `public/todolist2.js`, `tests/edit-session.test.js`, canonical changelog.
- Tests run:

  | Gate   | Command                                                               | Scope                      | Result          | Exception / risk |
  | ------ | --------------------------------------------------------------------- | -------------------------- | --------------- | ---------------- |
  | format | `npx prettier --write public\todolist2.js tests\edit-session.test.js` | Touched files              | pass            | -                |
  | syntax | `node --check public\todolist2.js`                                    | Board script               | pass            | -                |
  | tests  | `node --test tests\edit-session.test.js`                              | Card edit/session contract | pass, 6 tests   | -                |
  | tests  | `node --test tests\shortcut-registry.test.js`                         | Shortcut registry contract | pass, 15 tests  | -                |
  | tests  | `npm test`                                                            | Full WorkLists suite       | pass, 424 tests | -                |
  | lint   | `npm run lint`                                                        | Formatting gate            | pass            | -                |
  | audit  | `npm audit --audit-level=high`                                        | Dependency security gate   | pass, 0 vulns   | -                |

- Tests added/updated: Hardened the card edit Escape regression test so `cardEdit.cancel` must not blank `textarea.value` and must force a local `loadBoard(currentBoardId, { refresh: false })` repaint.
- Regression impact: Card edit Escape only. Save, AI refine, notes-pane Escape, search Escape, and voice-session shortcuts remain on their existing registry commands.

### 2026-06-15T21:10:00Z � WorkLists

- Summary: Restored the voice-superseding AI shortcut � pressing the AI chord while voice-to-text is recording now stops dictation and immediately kicks off AI processing in every supported area.
- Problem: The shortcut refactor lost a nuance from the original June 12 capture-phase AI resolver. While voice is active, the context provider replaces the editor scopes with `voice-session` + `global`, so the scope-specific AI commands (`task.aiNormalize`/`card-edit`, `cardEdit.aiRefine`/`card-edit`, `notes.aiRun`/`notes-pane`) are no longer candidates. The result: `Ctrl/Cmd+Shift+Enter` did nothing mid-dictation, so the user could not supersede an in-flight voice operation with AI processing.
- Requirement: The AI chord must, while voice is recording, hard-stop the active voice session and run the AI action for the focused editor � in task entry, card edit, notes create, notes card edit, and inline note edit � without altering normal (non-voice) AI shortcut behavior.
- Solution: Added a global `ai.run` registry command bound to `Ctrl/Cmd+Shift+Enter` that resolves the focused editor via the existing `getGlobalAiShortcutContext` (which already covers all five areas), hard-stops voice with `stopActiveVoiceInputRecognition({ hardStop: true })`, then runs the resolved AI action. Because the controller sorts scope-specific candidates ahead of `global`, the existing per-scope AI commands still win in normal use; `ai.run` only fires when no editor scope is active � i.e., during a voice session.
- Files/areas: `public/todolist2.js` (registry registration), `tests/shortcut-registry.test.js`, `tests/gemma-ui.test.js`, canonical changelog.
- User-visible impact: During voice-to-text, the AI chord now stops recording and starts AI processing immediately in all editor areas, matching the documented intent. Non-voice AI shortcuts are unchanged.
- Tests run:

  | Gate   | Command                                                                                           | Scope                              | Result          | Exception / risk |
  | ------ | ------------------------------------------------------------------------------------------------- | ---------------------------------- | --------------- | ---------------- |
  | format | `npx prettier --write public\todolist2.js tests\shortcut-registry.test.js tests\gemma-ui.test.js` | Voice-supersede source/tests       | pass            | -                |
  | syntax | `node --check` on each touched JS/test file                                                       | Touched files                      | pass            | -                |
  | tests  | `node --test tests\shortcut-registry.test.js tests\gemma-ui.test.js`                              | Focused shortcut/voice/AI coverage | pass, 44 tests  | -                |
  | tests  | `npm test`                                                                                        | Full WorkLists suite               | pass, 424 tests | -                |
  | lint   | `npm run lint`                                                                                    | WorkLists formatting gate          | pass            | -                |
  | audit  | `npm audit --audit-level=high`                                                                    | Dependency security gate           | pass, 0 vulns   | -                |

- Tests added/updated: Added a contract test asserting that, with an active voice session (replaceScopes -> voice-session + global), the AI chord resolves the new global `ai.run` from task entry, card edit, notes create (text and visual), notes card edit, and inline note edit � and that with voice inactive the scope-specific command (`task.aiNormalize`) still wins. Added the `ai.run` command id to the initial-registration integration list and added a gemma-ui source assertion that `ai.run` is a global command that hard-stops voice before `context.run()`.
- Regression impact: Shortcut dispatch only. The global fallback is gated by `getGlobalAiShortcutContext` and sorts behind scope-specific AI commands, so normal task/card/notes AI shortcuts and Escape/voice-start behavior are unchanged; full suite, lint, and audit are green.
- API docs: Not relevant; no HTTP route, schema, method, status, auth, or OpenAPI contract changed (client-side keyboard only).
- Conflicts / exceptions: None.

### 2026-06-15T18:45:00Z � WorkLists

- Summary: Finished the shortcut-registry refactor cleanup � locked the notes-pane add-note+AI shortcut, fixed the empty-draft Escape swallow, and removed the now-redundant duplicate element-level shortcut handlers.
- Problem: CODEX's shortcut refactor was ~80% done. Task-entry, card-edit, and notes element keydown listeners still re-dispatched registry shortcuts via `isRegisteredShortcutEvent` (dead/duplicated logic superseded by the capture-phase controller), an empty create-note draft swallowed Escape because `notes.cancelDraft` was `enabled` regardless of content, and the real notes-AI create chain had no executable lock.
- Requirement: One dispatch source of truth (registry + controller); Escape with nothing to cancel must fall through to context dismiss; the notes create-area AI chord (`Ctrl/Cmd+Shift+Enter` -> `createNoteWithAiFromPane`) must be pinned across all create surfaces; and the registry/controller override + capture seams must stay intact for the future (deferred) user-rebinding feature.
- Solution:
  - Made `notes.cancelDraft.enabled` content-aware for the create editor (only enabled when `getNotesPaneEditorMarkdown().trim()` is non-empty), so empty-draft Escape now resolves `context.dismiss`.
  - Stripped the redundant `isRegisteredShortcutEvent` shortcut branches from the task-entry, card-edit, notes-create, notes-preview, notes-visual, and notes-list keydown listeners, keeping only `handleMarkdownAuthoringKeydown` duties; removed the now-unused `isRegisteredShortcutEvent` helper.
  - Verified the create editor lives inside `#notes-pane` so the controller tags the `notes-pane` scope and `notes.aiRun` resolves the create-area AI command.
  - Confirmed (no UI built) the rebinding seams stay live: `registry.list/setOverride/clearOverride/getOverrides` + `controller.beginCapture/endCapture/isCapturing`.
- Files/areas: `public/todolist2.js`, `tests/shortcut-registry.test.js`, `tests/add-task-entry.test.js`, `tests/edit-session.test.js`, `tests/context-windows.test.js`, `tests/gemma-ui.test.js`, canonical changelog.
- User-visible impact: Keyboard shortcuts behave identically for task/card/notes commands but now flow through a single controller. Pressing Escape in an empty new-note draft no longer gets eaten; it dismisses active context as before. The notes create-area AI chord continues to create an AI note immediately from the textarea, visual editor, markdown editor, or form.
- Tests run:

  | Gate   | Command                                                                                                                                                                                 | Scope                            | Result          | Exception / risk |
  | ------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------- | --------------- | ---------------- |
  | format | `npx prettier --write public\todolist2.js tests\shortcut-registry.test.js tests\add-task-entry.test.js tests\edit-session.test.js tests\context-windows.test.js tests\gemma-ui.test.js` | Cleanup source/tests             | pass            | -                |
  | syntax | `node --check` on each touched JS/test file                                                                                                                                             | Touched files                    | pass            | -                |
  | tests  | `node --test tests\shortcut-registry.test.js tests\add-task-entry.test.js tests\edit-session.test.js tests\context-windows.test.js tests\gemma-ui.test.js`                              | Focused shortcut/notes/task/card | pass, 81 tests  | -                |
  | tests  | `npm test`                                                                                                                                                                              | Full WorkLists suite             | pass, 423 tests | -                |
  | lint   | `npm run lint`                                                                                                                                                                          | WorkLists formatting gate        | pass            | -                |
  | audit  | `npm audit --audit-level=high`                                                                                                                                                          | Dependency security gate         | pass, 0 vulns   | -                |

- Tests added/updated: Added contract cases dispatching the AI chord from every create-area surface (`#notes-pane-form`, `#notes-pane-md-editor`, `#notes-pane-text`, `#notes-pane-visual-editor`) regardless of draft content; added empty-vs-drafted create Escape fall-through coverage; added a capture/override seam test (`beginCapture`/`endCapture`/`setOverride`/`clearOverride`). Updated task/card/notes source assertions from element-level `isRegisteredShortcutEvent` dispatch to registry-command ownership plus a no-resurrection `doesNotMatch` guard, and the content-aware cancel-draft gate.
- Regression impact: Shortcut dispatch and notes-pane keydown only. Controller handlers already replicated every removed action (`submitTaskEntryInput`, `runGemmaNormalizationForInput`, `resetTaskEntryInput`, card save/refine/cancel, `createNoteFromPaneForm`, `saveNotesPaneTaskEditor`, `saveNoteInlineEditor`, `confirmDiscardNotesPaneDrafts`); markdown-authoring keydown handling is preserved. Full suite, lint, and audit are green.
- API docs: Not relevant; no HTTP route, schema, method, status, auth, or OpenAPI contract changed (client-side keyboard cleanup only).
- Conflicts / exceptions: None. The user-facing rebinding settings UI was explicitly deferred to future dev; this pass only keeps the codebase building toward it.

### 2026-06-15T18:12:23Z � WorkLists

- Summary: Restored notes-pane AI shortcut routing and hardened the full shortcut contract from the changelog.
- Problem: The shortcut refactor left `getGlobalAiShortcutContext` and the voice context resolver scoped too narrowly to notes textareas/visual editors. `Ctrl/Cmd+Shift+Enter` could miss notes-pane AI create/refine when focus was on composer/editor controls inside the create-note, card-text edit, or inline-note edit surfaces.
- Changelog shortcut contracts audited:
  - `Ctrl+Shift+\` starts voice from task entry, card edit, notes create, notes card edit, and notes inline note edit; the same chord and `Escape` stop active voice capture.
  - `Ctrl/Cmd+Shift+Enter` runs AI from task entry, inline card edit, notes create, notes card-text edit, and inline note edit without falling through to ordinary create/save.
  - `Ctrl/Cmd+Enter` creates cards from task entry; `Ctrl+Enter` saves inline card edits and notes-pane create/save flows where supported.
  - Plain `Escape` clears task entry, cancels card edit, cancels notes drafts/edits, cancels search, dismisses context surfaces, and prioritizes dialogs/modals/scheduler/tag chooser over board-level handlers.
  - `Ctrl+K` opens search and `Ctrl+O` toggles the board library only from board scope, not editor/notes/voice/modal scopes.
  - Create/save/refine command boundaries hard-stop active voice capture before note/card AI or create commands run.
- Solution: Expanded notes AI and voice context detection to the full notes editor surfaces (`#notes-pane-form`, `#notes-pane-md-editor`, `.notes-pane-task-edit`, `.notes-pane-edit`) while keeping shortcut dispatch scope-aware. Added a WorkLists shortcut contract matrix covering board, task, card, notes create, notes card edit, inline note edit, search, voice, app dialog, modal, scheduler, and tag chooser priority. Kept source assertions that bind the matrix to the real WorkLists selectors. Applied `npm audit fix` to patch `ws`, `qs`, and `protobufjs` transitive vulnerabilities so the audit gate is clean.
- Files/areas: `public/todolist2.js`, `tests/shortcut-registry.test.js`, `tests/gemma-ui.test.js`, `package-lock.json`, canonical changelog.
- User-visible impact: Notes-pane AI shortcuts work from the create-note area and editor controls, not just when the raw textarea/visual editor has focus. Existing task/card/search/voice/Escape shortcuts remain scope-gated and covered by regression tests.
- Tests run:

  | Gate         | Command                                                                                                                                                                                                             | Scope                                        | Result                                                               | Exception / risk                                           |
  | ------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------- | -------------------------------------------------------------------- | ---------------------------------------------------------- |
  | format       | `npx prettier --write public\todolist2.js tests\shortcut-registry.test.js tests\gemma-ui.test.js`                                                                                                                   | Shortcut fix/tests                           | pass                                                                 | -                                                          |
  | syntax       | `node --check public\todolist2.js`; `node --check tests\shortcut-registry.test.js`; `node --check tests\gemma-ui.test.js`                                                                                           | Touched JS/test files                        | pass                                                                 | -                                                          |
  | tests        | `node --test tests\shortcut-registry.test.js tests\gemma-ui.test.js`                                                                                                                                                | Focused shortcut/Gemma AI and voice coverage | pass, 40 tests                                                       | -                                                          |
  | tests        | `node --test tests\search-shortcuts.test.js tests\context-windows.test.js tests\filter-menu.test.js tests\add-task-entry.test.js tests\edit-session.test.js tests\shortcut-registry.test.js tests\gemma-ui.test.js` | Changelog shortcut-adjacent surfaces         | pass, 97 tests                                                       | -                                                          |
  | tests        | `npm test`                                                                                                                                                                                                          | Full WorkLists suite                         | pass, 420 tests                                                      | -                                                          |
  | lint         | `npm run lint`                                                                                                                                                                                                      | WorkLists formatting gate                    | pass                                                                 | -                                                          |
  | audit        | `npm audit --audit-level=high`; `npm audit fix`; `npm audit --audit-level=high`                                                                                                                                     | Dependency security gate                     | initial fail on `ws`; fix applied; final pass with 0 vulnerabilities | `package-lock.json` updated for transitive patch releases. |
  | diff hygiene | `git diff --check -- public\todolist2.js tests\shortcut-registry.test.js tests\gemma-ui.test.js`                                                                                                                    | Touched shortcut files                       | pass                                                                 | -                                                          |

- Tests added/updated: Added a shortcut contract matrix proving all changelog shortcut surfaces still dispatch the expected command and block conflicting scopes. Added context-surface Escape priority coverage. Updated Gemma source assertions to require broad notes editor selectors for AI and voice shortcut routing.
- Regression impact: Shortcut routing and notes-pane editor context detection only. The full suite, lint, and audit are green after the fix.
- API docs: Not relevant; no HTTP route, schema, method, status, auth, or OpenAPI contract changed.
- Conflicts / exceptions: None.

### 2026-06-15T17:13:02Z � WorkLists

- Summary: Fixed voice shortcut stop regression from the shortcut registry refactor.
- Problem: The refactor put active voice capture into a replacement `voice-session` scope with `allowGlobal: false`; `Ctrl+Shift+\` remained a `global` command, so the documented June 12 stop behavior could not dispatch while recording.
- Requirement: `Ctrl+Shift+\` must start voice-to-text in supported editors and stop active voice-to-text across task entry, card edit, and notes pane. `Escape` must still stop active voice through `voice.session.stop`.
- Solution: Allowed active voice context to include global shortcuts, explicitly blocked board-level global shortcuts while `voice-session` is active, and added regression tests for the active-voice scope transition.
- Files/areas: `public/todolist2.js`, `tests/shortcut-registry.test.js`, `tests/gemma-ui.test.js`.
- User-visible impact: The configured voice shortcut again toggles active dictation off while recording; unrelated board globals such as search/panel shortcuts stay suppressed during voice capture.
- Tests run:

  | Gate         | Command                                                                                                                   | Scope                           | Result                  | Exception / risk                                                                          |
  | ------------ | ------------------------------------------------------------------------------------------------------------------------- | ------------------------------- | ----------------------- | ----------------------------------------------------------------------------------------- |
  | format       | `npx prettier --write public\todolist2.js tests\shortcut-registry.test.js tests\gemma-ui.test.js`                         | Voice shortcut fix/tests        | pass                    | -                                                                                         |
  | syntax       | `node --check public\todolist2.js`; `node --check tests\shortcut-registry.test.js`; `node --check tests\gemma-ui.test.js` | Touched JS/test files           | pass                    | -                                                                                         |
  | tests        | `node --test tests\shortcut-registry.test.js tests\gemma-ui.test.js`                                                      | Focused shortcut/voice coverage | pass, 38 tests          | -                                                                                         |
  | tests        | `npm test`                                                                                                                | Full WorkLists suite            | pass, 418 tests         | -                                                                                         |
  | lint         | `npm run lint`                                                                                                            | WorkLists formatting gate       | pass                    | -                                                                                         |
  | audit        | `npm audit --audit-level=high`                                                                                            | WorkLists dependencies          | pass for high threshold | Existing 3 moderate `qs`/`body-parser`/`express` advisories remain with no fix available. |
  | diff hygiene | `git diff --check -- public\todolist2.js tests\shortcut-registry.test.js tests\gemma-ui.test.js`                          | Touched files                   | pass                    | -                                                                                         |

- Tests added/updated: Added an executable controller regression proving `Ctrl+Shift+\` still dispatches `voice.global.start` inside active `voice-session` scope, while non-voice board globals remain blocked. Hardened source assertions so WorkLists cannot reintroduce `allowGlobal: false` for active voice sessions without test failure.
- Regression impact: Keyboard shortcut scope logic only; active voice start/stop paths are now pinned by focused tests and the full suite.
- API docs: Not relevant; no HTTP route, schema, method, status, or auth contract changed.
- Conflicts / exceptions: None.

### 2026-06-15T16:55:29Z � WorkLists

- Summary: Centralized keyboard shortcut registration and dispatch.
- Problem: Keyboard shortcut behavior was split across document-level listeners and feature-owned key matching, blocking future rebinding and command reuse.
- Requirement: Define shortcuts as listable commands with default bindings, localStorage overrides, scope-aware matching, and one document-level shortcut dispatcher.
- Solution: Added `shortcutRegistry.js` and `shortcutController.js`, loaded them before `todolist2.js`, registered existing voice/search/context/task/card/notes/modal shortcuts from app bootstrap, moved key matching into the registry, and routed dialog/tag/scheduler/modal Escape through scoped commands. Removed stale commented reset-card shortcut code and aligned source assertions with the current board snapshot and active-note CSS.
- Files/areas: `public/shortcutRegistry.js`, `public/shortcutController.js`, `public/todolist2.js`, `public/dialogs.js`, `public/index.html`, shortcut/search/task/edit/context/Gemma/card/API-source tests.
- User-visible impact: Existing shortcuts remain available while definitions are now data-driven and listable; future settings UI can rebind commands through `ShortcutRegistry` without adding feature-owned document listeners.
- Tests run:

  | Gate         | Command                                                                                                                                                                                                                                                                                                                                                                                                                                  | Scope                                                                                 | Result                         | Exception / risk                                                                          |
  | ------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------- | ------------------------------ | ----------------------------------------------------------------------------------------- |
  | format       | `npx prettier --write public\shortcutRegistry.js public\shortcutController.js public\dialogs.js public\index.html public\todolist2.js tests\shortcut-registry.test.js tests\search-shortcuts.test.js tests\add-task-entry.test.js tests\edit-session.test.js tests\context-windows.test.js tests\filter-menu.test.js tests\gemma-ui.test.js tests\secondary-tags.test.js tests\api-client-resilience.test.js tests\card-actions.test.js` | Touched shortcut and assertion files                                                  | pass                           | -                                                                                         |
  | syntax       | `node --check public\shortcutRegistry.js`; `node --check public\shortcutController.js`; `node --check public\dialogs.js`; `node --check public\todolist2.js`; `node --check tests\shortcut-registry.test.js`                                                                                                                                                                                                                             | New/changed JS entry points                                                           | pass                           | -                                                                                         |
  | tests        | `node --test tests\shortcut-registry.test.js tests\search-shortcuts.test.js tests\add-task-entry.test.js tests\edit-session.test.js tests\context-windows.test.js tests\filter-menu.test.js tests\gemma-ui.test.js`                                                                                                                                                                                                                      | Shortcut registry/controller plus affected search/task/edit/context/Gemma UI surfaces | pass, 93 tests                 | -                                                                                         |
  | tests        | `node --test tests\api-client-resilience.test.js tests\secondary-tags.test.js`; `node --test tests\card-actions.test.js tests\column-actions.test.js`                                                                                                                                                                                                                                                                                    | Source assertions touched while restoring full-suite signal                           | pass, 20 tests; pass, 37 tests | -                                                                                         |
  | tests        | `npm test`                                                                                                                                                                                                                                                                                                                                                                                                                               | Full WorkLists suite                                                                  | pass, 416 tests                | -                                                                                         |
  | lint         | `npm run lint`                                                                                                                                                                                                                                                                                                                                                                                                                           | WorkLists formatting gate                                                             | pass                           | -                                                                                         |
  | audit        | `npm audit --audit-level=high`                                                                                                                                                                                                                                                                                                                                                                                                           | WorkLists dependencies                                                                | pass for high threshold        | Existing 3 moderate `qs`/`body-parser`/`express` advisories remain with no fix available. |
  | diff hygiene | `git diff --check -- public\shortcutRegistry.js public\shortcutController.js public\dialogs.js public\index.html public\todolist2.js tests\shortcut-registry.test.js tests\search-shortcuts.test.js tests\add-task-entry.test.js tests\edit-session.test.js tests\context-windows.test.js tests\filter-menu.test.js tests\gemma-ui.test.js tests\secondary-tags.test.js tests\api-client-resilience.test.js tests\card-actions.test.js`  | Touched files                                                                         | pass                           | -                                                                                         |

- Tests added/updated: Added `tests/shortcut-registry.test.js` for registry persistence/conflict matching, controller single-listener dispatch, and shortcut integration. Updated existing source assertions for registry-owned commands and current live code paths.
- Regression impact: Cross-cutting keyboard behavior now flows through one controller; task entry, card edit, notes pane, search, context dismissals, dialogs, tag chooser, scheduler, voice, and AI shortcuts were covered by focused tests plus full suite.
- API docs: Not relevant; no HTTP route, schema, method, status, or auth contract changed.
- Conflicts / exceptions: Canonical changelog restored from tracked Git HEAD before this entry; local history search did not recover newer uncommitted changelog entries that may have existed after 2026-06-12.

### 2026-06-12T20:10:00Z � WorkLists

- Summary: Fixed voice shortcut stop in editors.
- Problem: Active voice-to-text stopped with `Escape`, but the configured voice shortcut could be swallowed while focus was inside new-task or card-edit textareas.
- Requirement: The standard voice shortcut must stop active recording consistently across notes, new-task entry, and card editing states.
- Solution:
  - Bound the global voice shortcut in capture phase so task/card edit key handlers cannot intercept it first.
  - Routed the shortcut to stop an already-active voice session before resolving a new context start.
  - Added focused source assertions for active-session stop behavior and capture-phase shortcut binding.
- Files/areas: `public/todolist2.js`, `tests/gemma-ui.test.js`.
- User-visible impact: `Ctrl+Shift+Backslash` now stops active voice-to-text while creating a new task or editing a card, matching the existing Escape stop behavior.
- Tests run:

  | Gate   | Command                                                                   | Scope                           | Result          | Exception / risk                                                                                                                                                                       |
  | ------ | ------------------------------------------------------------------------- | ------------------------------- | --------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
  | format | `npx prettier --write public/todolist2.js tests/gemma-ui.test.js`         | Touched UI/test files           | pass, unchanged | �                                                                                                                                                                                      |
  | syntax | `node --check public/todolist2.js`; `node --check tests/gemma-ui.test.js` | Touched JS/test files           | pass            | �                                                                                                                                                                                      |
  | audit  | `npm audit --audit-level=high`                                            | WorkLists dependencies          | pass            | Existing 3 moderate `qs`/`body-parser`/`express` advisories remain with no fix available; high/critical gate passes.                                                                   |
  | lint   | `npm run lint`                                                            | WorkLists formatting gate       | pass            | �                                                                                                                                                                                      |
  | tests  | `node --test tests/gemma-ui.test.js`                                      | Focused voice shortcut coverage | pass, 29 tests  | �                                                                                                                                                                                      |
  | tests  | `npm test`                                                                | Full WorkLists suite            | fail            | Unrelated existing failures remain in `tests/card-actions.test.js` note-count active-card CSS expectation and `tests/column-actions.test.js` legacy commented `toggleTodoFromUI` text. |

- Tests added/updated: Extended `tests/gemma-ui.test.js` source assertions for active voice shortcut stop and capture-phase global binding.
- Regression impact: Isolated to global voice shortcut dispatch; context-specific start routing is unchanged, and active-session handling returns before starting a new recording.
- API docs: Not affected; checked surface is client-side keyboard shortcut dispatch only, with no route, request, response schema, status, auth, or OpenAPI metadata changed.
- Tooling gates: Format, syntax, high audit, lint, and focused voice tests passed; full suite remains blocked by known unrelated assertion failures.
- Conflicts / exceptions: Preserved pre-existing dirty WorkLists changes outside the touched shortcut/test lines.

### 2026-06-12T19:35:00Z � WorkLists

- Summary: Added board object modification timestamps.
- Problem: Boards and related records had no consistent freshness marker for sync verification.
- Requirement: Persist `lastModified` on board data objects without adding UI clutter, and keep API consumers able to display it later.
- Solution:
  - Added DAL helpers to backfill and persist `lastModified` for boards, columns, todos, notes, and secondary tags.
  - Touched affected entities during create/update/delete/move/order/tag/note operations, including parent board/column containers when membership changes.
  - Added note creation/update timestamps for direct note APIs and Gemma-created notes.
  - Updated OpenAPI schemas to expose `lastModified` on tracked object schemas.
  - Added API/OpenAPI coverage for timestamp hydration, entity touch propagation, and documented schema fields.
- Files/areas: `dal.js`, `server.js`, `openapi.js`, `tests/api.test.js`, `tests/openapi.test.js`.
- User-visible impact: Board data responses now include freshness metadata for tracked objects; no visible UI changes.
- Safety/data integrity: No bulk production data migration or destructive batch action was run. Existing atomic write and test cleanup paths were preserved.
- Tests run:

  | Gate   | Command                                                                                                                                            | Scope                              | Result          | Exception / risk                                                                                                                                                                       |
  | ------ | -------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------- | --------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
  | format | `npx prettier --write dal.js server.js openapi.js tests\api.test.js tests\openapi.test.js`                                                         | Touched backend/test files         | pass, unchanged | �                                                                                                                                                                                      |
  | syntax | `node --check dal.js`; `node --check server.js`; `node --check openapi.js`; `node --check tests\api.test.js`; `node --check tests\openapi.test.js` | Touched JS/test files              | pass            | �                                                                                                                                                                                      |
  | audit  | `npm audit --audit-level=high`                                                                                                                     | WorkLists dependencies             | pass            | Existing 3 moderate `qs`/`body-parser`/`express` advisories remain with no fix available; high/critical gate passes.                                                                   |
  | lint   | `npm run lint`                                                                                                                                     | WorkLists formatting gate          | pass            | �                                                                                                                                                                                      |
  | tests  | `node --test tests\api.test.js tests\openapi.test.js`                                                                                              | API and OpenAPI timestamp coverage | pass, 71 tests  | �                                                                                                                                                                                      |
  | tests  | `npm test`                                                                                                                                         | Full WorkLists suite               | fail            | Unrelated existing failures remain in `tests/card-actions.test.js` note-count active-card CSS expectation and `tests/column-actions.test.js` legacy commented `toggleTodoFromUI` text. |

- Tests added/updated: Extended `tests/api.test.js` for `lastModified` hydration and mutation propagation; extended `tests/openapi.test.js` for schema exposure.
- Regression impact: Shared DAL write/read paths touched; focused API coverage verifies legacy equality still holds with timestamp metadata stripped, timestamps hydrate on reads, direct mutations touch affected entities, and invalid move paths avoid partial changes.
- API docs: Updated `Board`, `Column`, `Todo`, `Note`, and `SecondaryTag` OpenAPI schemas with required `lastModified` date-time fields.
- Tooling gates: Format, syntax, high audit, lint, and focused API/OpenAPI tests passed; full suite remains blocked by known unrelated source/CSS assertion failures.
- Conflicts / exceptions: Preserved pre-existing dirty WorkLists changes in `public/markdownRenderer.js`, `public/todolist2.js`, `tests/add-task-entry.test.js`, `tests/context-windows.test.js`, `tests/gemma-ui.test.js`, `tests/markdown-renderer.test.js`, `tests/search-shortcuts.test.js`, and `tests/task-clipboard.test.js`.

### 2026-06-12T18:19:48Z � WorkLists

- Summary: Refreshed rendered checkbox card surfaces.
- Problem: Markdown checkbox toggles updated stored card text but did not force the card read surface to render from the new source.
- Requirement: Checkbox toggles outside primary markdown edit mode must immediately refresh visible card content without waiting for a manual save or full board rebuild.
- Solution:
  - Added `refreshRenderedTaskContentForTask` to update the main card content, active notes-pane card preview, and notes-pane title from one markdown source update.
  - Routed rendered markdown card checkbox persistence through that refresh helper on optimistic update and rollback.
  - Added focused source coverage proving checkbox saves refresh rendered card surfaces instead of only mutating `data-raw-content`.
- Files/areas: `public/todolist2.js`, `tests/markdown-renderer.test.js`.
- User-visible impact: Toggling a rendered markdown checkbox in card read mode or the notes-pane card preview immediately updates the visible card read surface from the saved markdown state.
- Tests run:

  | Gate   | Command                                                                                                  | Scope                                           | Result         | Exception / risk                                                                                                                                                            |
  | ------ | -------------------------------------------------------------------------------------------------------- | ----------------------------------------------- | -------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
  | format | `npx prettier --write public/todolist2.js tests/markdown-renderer.test.js`                               | Touched UI/test files                           | pass           | �                                                                                                                                                                           |
  | syntax | `node --check public/todolist2.js`                                                                       | Board UI script                                 | pass           | �                                                                                                                                                                           |
  | syntax | `node --check tests/markdown-renderer.test.js`                                                           | Markdown renderer test file                     | pass           | �                                                                                                                                                                           |
  | tests  | `node --test tests/markdown-renderer.test.js tests/task-clipboard.test.js tests/context-windows.test.js` | Focused markdown checkbox/card surface coverage | pass, 56 tests | �                                                                                                                                                                           |
  | audit  | `npm audit --audit-level=high`                                                                           | WorkLists dependencies                          | pass           | Existing 3 moderate `qs`/`body-parser`/`express` advisories remain with no fix available; high/critical gate passes.                                                        |
  | lint   | `npm run lint`                                                                                           | WorkLists formatting gate                       | pass           | �                                                                                                                                                                           |
  | tests  | `npm test`                                                                                               | Full WorkLists suite                            | fail           | Unrelated existing failures remain in `tests/card-actions.test.js` active-card CSS expectation and `tests/column-actions.test.js` legacy commented `toggleTodoFromUI` text. |

- Tests added/updated: Extended `tests/markdown-renderer.test.js` for rendered card surface refresh after inline markdown checkbox saves.
- Regression impact: Isolated to rendered markdown checkbox persistence for card text; helper targets only the matching card ID and active notes preview, leaving full board render and editor save flows unchanged.
- API docs: Not affected; checked surface is client-side card markdown rendering/persistence only, with no route, request, response schema, status, auth, or OpenAPI metadata changed.
- Tooling gates: Formatting, syntax, focused tests, high audit, and lint passed; full suite remains blocked by known unrelated source/CSS assertion failures.
- Conflicts / exceptions: Preserved pre-existing dirty WorkLists changes in `public/markdownRenderer.js`, `public/todolist2.js`, `tests/add-task-entry.test.js`, `tests/context-windows.test.js`, `tests/gemma-ui.test.js`, `tests/markdown-renderer.test.js`, `tests/search-shortcuts.test.js`, and `tests/task-clipboard.test.js`.

### 2026-06-12T16:20:00Z � WorkLists

- Summary: Stopped voice capture on card/note commands.
- Problem: Active voice-to-text could keep listening after notes-pane create/save paths or card creation/refine commands executed.
- Requirement: Executing a create-card/create-note/refine-card command must immediately terminate the active voice recording session.
- Solution:
  - Added hard-stop voice termination at `submitTaskEntryInput` so add-card button and `Ctrl/Cmd+Enter` routes share the stop behavior.
  - Added hard-stop voice termination at `createNoteFromPaneForm` for notes-pane note creation.
  - Added hard-stop voice termination at central `refineCardWithGemma` so top-card and notes-pane card refine routes stop recording through one command boundary.
  - Added focused source assertions for the card-create, note-create, and card-refine command boundaries.
- Files/areas: `public/todolist2.js`, `tests/add-task-entry.test.js`, `tests/gemma-ui.test.js`.
- User-visible impact: Voice-to-text recording stops as soon as the user creates a card/note or starts card AI refinement, including notes-pane command routes.
- Tests run:

  | Gate   | Command                                                                                        | Scope                                | Result         | Exception / risk                                                                                                                                                            |
  | ------ | ---------------------------------------------------------------------------------------------- | ------------------------------------ | -------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
  | format | `npx prettier --write public\todolist2.js tests\add-task-entry.test.js tests\gemma-ui.test.js` | Touched UI/test files                | pass           | �                                                                                                                                                                           |
  | syntax | `node --check public\todolist2.js`                                                             | Board UI script                      | pass           | �                                                                                                                                                                           |
  | syntax | `node --check tests\add-task-entry.test.js`                                                    | Add-task test file                   | pass           | �                                                                                                                                                                           |
  | syntax | `node --check tests\gemma-ui.test.js`                                                          | Gemma UI test file                   | pass           | �                                                                                                                                                                           |
  | tests  | `node --test tests\add-task-entry.test.js tests\gemma-ui.test.js`                              | Focused voice/create/refine coverage | pass, 37 tests | �                                                                                                                                                                           |
  | lint   | `npm run lint`                                                                                 | WorkLists formatting gate            | pass           | �                                                                                                                                                                           |
  | audit  | `npm audit --audit-level=high`                                                                 | WorkLists dependencies               | pass           | Existing 3 moderate `qs`/`body-parser`/`express` advisories remain with no fix available; high/critical gate passes.                                                        |
  | tests  | `npm test`                                                                                     | Full WorkLists suite                 | fail           | Unrelated existing failures remain in `tests/card-actions.test.js` active-card CSS expectation and `tests/column-actions.test.js` legacy commented `toggleTodoFromUI` text. |

- Tests added/updated: Extended `tests/add-task-entry.test.js` and `tests/gemma-ui.test.js` source assertions for voice-stop command boundaries.
- Regression impact: Shared command boundaries touched; focused coverage proves add-card create, notes-pane note create, and central card refine all hard-stop active voice capture. Existing AI note create/refine stop assertions remain intact.
- API docs: Not affected; checked surface is client-side keyboard/button command dispatch only, with no route, request, response schema, status, auth, or OpenAPI metadata changed.
- Tooling gates: Formatting, syntax, focused tests, lint, and high audit passed; full suite remains blocked by known unrelated assertion failures.
- Conflicts / exceptions: Preserved pre-existing dirty WorkLists changes in `public/markdownRenderer.js`, `public/todolist2.js`, `tests/context-windows.test.js`, `tests/gemma-ui.test.js`, `tests/markdown-renderer.test.js`, `tests/search-shortcuts.test.js`, and `tests/task-clipboard.test.js`.

### 2026-06-12T15:58:14Z � WorkLists

- Summary: Expanded AI shortcuts into notes pane.
- Problem: `Ctrl/Cmd+Shift+Enter` AI commands were scoped to task entry/card edit flows and notes-pane `Ctrl+Enter` handlers could intercept the AI chord as ordinary create/save.
- Requirement: The same AI chord must work from focused note creation, existing note editing, notes-pane card editing, add-task entry, and inline card editing.
- Solution:
  - Added a capture-phase global AI shortcut resolver for `Ctrl/Cmd+Shift+Enter`.
  - Routed notes-pane create focus to AI note creation.
  - Routed inline saved-note edit focus through save-then-AI-refine for that note.
  - Routed notes-pane card edit focus through save-then-card-refine.
  - Kept task-entry and inline-card contexts mapped to existing AI flows.
  - Added focused source coverage for the notes-pane shortcut routes and capture-phase binding.
- Files/areas: `public/todolist2.js`, `tests/gemma-ui.test.js`.
- User-visible impact: AI note creation/refinement shortcuts now work while typing in the Notes pane, without converting the AI chord into a plain note create/save.
- Tests run:

  | Gate   | Command                                                                                      | Scope                                           | Result          | Exception / risk                                                                                                                                                            |
  | ------ | -------------------------------------------------------------------------------------------- | ----------------------------------------------- | --------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
  | audit  | `npm audit --audit-level=high`                                                               | WorkLists dependencies                          | pass            | Existing 3 moderate `qs`/`body-parser`/`express` advisories remain with no fix available; high/critical gate passes.                                                        |
  | format | `npx prettier --write public\todolist2.js tests\gemma-ui.test.js`                            | Touched UI/test files                           | pass, unchanged | �                                                                                                                                                                           |
  | syntax | `node --check public\todolist2.js`                                                           | Board UI script                                 | pass            | �                                                                                                                                                                           |
  | syntax | `node --check tests\gemma-ui.test.js`                                                        | Gemma UI test file                              | pass            | �                                                                                                                                                                           |
  | tests  | `node --test tests\gemma-ui.test.js tests\add-task-entry.test.js tests\edit-session.test.js` | Focused AI shortcut/add-task/card-edit coverage | pass, 43 tests  | �                                                                                                                                                                           |
  | lint   | `npm run lint`                                                                               | WorkLists formatting gate                       | pass            | �                                                                                                                                                                           |
  | tests  | `npm test`                                                                                   | Full WorkLists suite                            | fail            | Unrelated existing failures remain in `tests/card-actions.test.js` active-card CSS expectation and `tests/column-actions.test.js` legacy commented `toggleTodoFromUI` text. |

- Tests added/updated: Extended `tests/gemma-ui.test.js` for global AI shortcut notes-pane create/refine/card-edit routing.
- Regression impact: Shared AI shortcut dispatch touched; focused tests cover notes-pane create/edit routes plus existing task-entry and inline-card shortcut suites. Ordinary `Ctrl+Enter` note create/save remains local because only `Ctrl/Cmd+Shift+Enter` is captured globally.
- API docs: Not affected; checked surface is client-side keyboard dispatch only, with no route, request, response schema, status, auth, or OpenAPI metadata changed.
- Tooling gates: Audit, formatting, syntax, focused tests, and lint passed; full suite remains blocked by known unrelated source/CSS assertion failures.
- Conflicts / exceptions: Preserved pre-existing dirty WorkLists changes in `public/markdownRenderer.js`, `public/todolist2.js`, `tests/context-windows.test.js`, `tests/markdown-renderer.test.js`, `tests/search-shortcuts.test.js`, and `tests/task-clipboard.test.js`.

### 2026-06-11T22:00:41Z � WorkLists

- Summary: Stopped notes checklist clicks from editing.
- Problem: Clicking rendered markdown checklist controls in the notes pane bubbled into the note/card click-to-edit handlers.
- Requirement: Notes-pane markdown controls must behave like card markdown controls: checkbox/code-copy clicks update or copy without opening inline edit.
- Solution:
  - Added the existing rendered-markdown interactive-target guard before notes-pane card text enters edit.
  - Added the same guard before saved note content enters edit.
  - Added focused source coverage proving markdown controls return before discard/autosave/edit transitions.
- Files/areas: `public/todolist2.js`, `tests/context-windows.test.js`.
- User-visible impact: Clicking a checklist checkbox in the notes pane toggles/persists it instead of opening the editor.
- Tests run:

  | Gate   | Command                                                                                                  | Scope                                        | Result          | Exception / risk |
  | ------ | -------------------------------------------------------------------------------------------------------- | -------------------------------------------- | --------------- | ---------------- |
  | format | `npx prettier --write public\todolist2.js tests\context-windows.test.js`                                 | Touched UI/test files                        | pass, unchanged | �                |
  | syntax | `node --check public\todolist2.js`                                                                       | Board UI script                              | pass            | �                |
  | syntax | `node --check tests\context-windows.test.js`                                                             | Context-window test file                     | pass            | �                |
  | tests  | `node --test tests\context-windows.test.js tests\markdown-renderer.test.js tests\task-clipboard.test.js` | Focused notes-pane markdown/control coverage | pass, 55 tests  | �                |
  | lint   | `npm run lint`                                                                                           | WorkLists formatting gate                    | pass            | �                |

- Tests added/updated: Extended `tests/context-windows.test.js` to assert notes-pane markdown controls are guarded before inline edit flows.
- Regression impact: Isolated to notes-pane click handling for rendered markdown controls; ordinary note/card content clicks still enter existing inline editors.
- API docs: Not affected; checked surface is client-side notes-pane click behavior only, with no route, request, response schema, status, auth, or OpenAPI metadata changed.
- Tooling gates: Formatting, syntax, focused tests, and lint passed.
- Conflicts / exceptions: Preserved pre-existing dirty WorkLists changes and known unrelated full-suite failures; did not rerun full suite for this click-guard-only follow-up after focused gates passed.

### 2026-06-11T21:42:54Z � WorkLists

- Summary: Fixed nested markdown lists and notes checkboxes.
- Problem: Rendered markdown flattened indented bullet lists, and markdown task checkboxes inside the notes pane did not persist when clicked.
- Requirement: Multi-level bullet/ordered/task lists must preserve indentation in note-card rendering, and rendered checkboxes must work consistently for card text, notes-pane card text, and saved notes.
- Solution:
  - Replaced the single-list markdown renderer state with an indentation-aware list stack that emits nested `<ul>` / `<ol>` structures and keeps task-checkbox source line indexes intact.
  - Generalized rendered markdown interaction binding so each surface supplies its own checkbox persistence callback.
  - Wired notes-pane card preview checkboxes through the existing card text save path.
  - Added saved-note checkbox persistence through `ApiService.updateNote`, with rollback/toast handling on failure.
  - Added focused source/renderer tests for nested list output and notes-pane checkbox wiring.
- Files/areas: `public/markdownRenderer.js`, `public/todolist2.js`, `tests/markdown-renderer.test.js`, `tests/task-clipboard.test.js`.
- User-visible impact: Nested markdown lists now render as real nested lists in cards/notes, and clicking markdown checkboxes in the notes pane updates the underlying card text or saved note instead of acting as a dead control.
- Tests run:

  | Gate   | Command                                                                                                                            | Scope                                                    | Result         | Exception / risk                                                                                                                                                            |
  | ------ | ---------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------- | -------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
  | audit  | `npm audit --audit-level=high`                                                                                                     | WorkLists dependencies                                   | pass           | Existing 3 moderate `qs`/`body-parser`/`express` advisories remain with no fix available; high/critical gate passes.                                                        |
  | format | `npx prettier --write public\markdownRenderer.js public\todolist2.js tests\markdown-renderer.test.js tests\task-clipboard.test.js` | Touched renderer/UI/test files                           | pass           | �                                                                                                                                                                           |
  | syntax | `node --check public\markdownRenderer.js`                                                                                          | Markdown renderer                                        | pass           | �                                                                                                                                                                           |
  | syntax | `node --check public\todolist2.js`                                                                                                 | Board UI script                                          | pass           | �                                                                                                                                                                           |
  | syntax | `node --check tests\markdown-renderer.test.js`                                                                                     | Markdown renderer tests                                  | pass           | �                                                                                                                                                                           |
  | syntax | `node --check tests\task-clipboard.test.js`                                                                                        | Clipboard source tests                                   | pass           | �                                                                                                                                                                           |
  | tests  | `node --test tests\markdown-renderer.test.js tests\task-clipboard.test.js tests\context-windows.test.js`                           | Focused markdown, notes-pane, clipboard/context coverage | pass, 54 tests | �                                                                                                                                                                           |
  | lint   | `npm run lint`                                                                                                                     | WorkLists formatting gate                                | pass           | �                                                                                                                                                                           |
  | tests  | `npm test`                                                                                                                         | Full WorkLists suite                                     | fail           | Unrelated existing failures remain in `tests/card-actions.test.js` active-card CSS expectation and `tests/column-actions.test.js` legacy commented `toggleTodoFromUI` text. |

- Tests added/updated: Extended `tests/markdown-renderer.test.js` for nested unordered/ordered/task lists and notes-pane checkbox wiring; updated `tests/task-clipboard.test.js` for notes-pane checkbox persistence binding.
- Regression impact: Shared markdown renderer touched; focused tests cover existing inline formatting, blank lines, tables, task checkboxes, code blocks, links, nested lists, and notes-pane/card checkbox binding. Interaction binding is isolated by explicit per-surface checkbox callbacks.
- API docs: Not affected; checked surface is client-side markdown rendering and notes-pane note update usage only, with no route, request, response schema, status, auth, or OpenAPI metadata changed.
- Tooling gates: Audit, formatting, syntax, focused tests, and lint passed; full suite remains blocked by unrelated existing source assertion failures noted above.
- Conflicts / exceptions: Preserved pre-existing dirty WorkLists changes in `public/todolist2.js`, `tests/context-windows.test.js`, and `tests/search-shortcuts.test.js`; did not alter unrelated full-suite failures.

### 2026-06-12T00:38:00Z � WorkLists

- Summary: Hardened global Escape search dismissal.
- Problem: Escape could close a focused context surface, such as Filters, without also canceling an active Ctrl+K search, leaving the search bar/results stuck open after focus moved through filter controls.
- Requirement: Escape must stay globally reliable for active context/search dismissal while preserving focused editor Escape behavior for add-task, card edit, and notes-pane discard/cancel flows.
- Solution:
  - Moved search cancellation into the capture-phase global Escape resolver after context-window dismissal.
  - Added focused-editor ownership checks so task inputs, inline card edits, column rename, and notes-pane editors keep their local Escape cancel/discard behavior.
  - Added `window.__escapeKeyDiagnostics` ring-buffer logging plus opt-in `window.__WORKLISTS_ESCAPE_DEBUG__` console output for blocked/handled Escape tracing.
  - Added focused source coverage for global Escape search cancellation, diagnostics, and editor deferral.
- Files/areas: `public/todolist2.js`, `tests/search-shortcuts.test.js`, `tests/context-windows.test.js`.
- User-visible impact: Pressing Escape while search is active now closes open context surfaces and cancels search from the shared global handler instead of leaving search open after filter/menu focus changes. Escape in active task/card/note editors still runs the local discard/cancel path.
- Tests run:

  | Gate   | Command                                                                                                                                                      | Scope                                         | Result         | Exception / risk                                                                                                                                                            |
  | ------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------ | --------------------------------------------- | -------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
  | audit  | `npm audit --audit-level=high`                                                                                                                               | WorkLists dependencies                        | pass           | Existing 3 moderate `qs`/`body-parser`/`express` advisories remain with no fix available; high/critical gate passes.                                                        |
  | format | `npx prettier --write public\todolist2.js tests\search-shortcuts.test.js tests\context-windows.test.js`                                                      | Touched UI/test files                         | pass           | �                                                                                                                                                                           |
  | syntax | `node --check public\todolist2.js`                                                                                                                           | Board UI script                               | pass           | �                                                                                                                                                                           |
  | syntax | `node --check tests\search-shortcuts.test.js`                                                                                                                | Search shortcut test file                     | pass           | �                                                                                                                                                                           |
  | syntax | `node --check tests\context-windows.test.js`                                                                                                                 | Context-window test file                      | pass           | �                                                                                                                                                                           |
  | tests  | `node --test tests\search-shortcuts.test.js tests\context-windows.test.js tests\filter-menu.test.js tests\add-task-entry.test.js tests\edit-session.test.js` | Focused Escape/search/context/editor coverage | pass, 56 tests | �                                                                                                                                                                           |
  | lint   | `npm run lint`                                                                                                                                               | WorkLists formatting gate                     | pass           | �                                                                                                                                                                           |
  | tests  | `npm test`                                                                                                                                                   | Full WorkLists suite                          | fail           | Unrelated existing failures remain in `tests/card-actions.test.js` active-card CSS expectation and `tests/column-actions.test.js` legacy commented `toggleTodoFromUI` text. |

- Tests added/updated: Extended `tests/search-shortcuts.test.js` and `tests/context-windows.test.js` for global Escape search cancel, diagnostics, and focused-editor deferral.
- Regression impact: Shared Escape infrastructure touched; focused tests cover search, filters, context windows, add-task Escape, inline card edit Escape, and notes-pane editor deferral. Local editor Escape paths remain isolated by `shouldFocusedElementOwnEscape`.
- API docs: Not affected; checked surface is client-side keyboard/context behavior only, with no route, request, response schema, status, auth, or OpenAPI metadata changed.
- Tooling gates: Audit, formatting, syntax, focused tests, and lint passed; full suite remains blocked by unrelated existing source assertion failures noted above.
- Conflicts / exceptions: Preserved pre-existing dirty notes-pane changes in `public/todolist2.js` and `tests/context-windows.test.js`; did not alter unrelated full-suite failures.

### 2026-06-11T20:12:32Z � WorkLists

- Summary: Kept note undo actions pane-local.
- Problem: Clicking the AI note refine Undo toast while a card notes pane was open counted as an outside click and closed the notes context window.
- Requirement: Note undo must restore note data without changing notes-pane visibility.
- Solution:
  - Marked AI note refine Undo toast actions with a notes-pane-preserving flag.
  - Propagated that flag to toast action buttons as `data-preserve-notes-pane`.
  - Expanded the notes-pane outside-click guard so marked note undo actions do not dismiss the pane.
  - Added focused context-window source coverage for the preserve marker and note Undo wiring.
- Files/areas: `public/todolist2.js`, `tests/context-windows.test.js`.
- User-visible impact: Undoing an AI note refinement from the toast now keeps the notes pane open and reloads the restored note content when it belongs to the active card.
- Tests run:

  | Gate   | Command                                                                  | Scope                                      | Result          | Exception / risk                                                                                                                                                            |
  | ------ | ------------------------------------------------------------------------ | ------------------------------------------ | --------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
  | format | `npx prettier --write public\todolist2.js tests\context-windows.test.js` | Touched UI/test files                      | pass, unchanged | �                                                                                                                                                                           |
  | syntax | `node --check public\todolist2.js`                                       | Board UI script                            | pass            | �                                                                                                                                                                           |
  | syntax | `node --check tests\context-windows.test.js`                             | Focused context-window test file           | pass            | �                                                                                                                                                                           |
  | tests  | `node --test tests\context-windows.test.js`                              | Focused notes-pane/context source coverage | pass, 22 tests  | �                                                                                                                                                                           |
  | lint   | `npm run lint`                                                           | WorkLists formatting gate                  | pass            | �                                                                                                                                                                           |
  | tests  | `npm test`                                                               | Full WorkLists suite                       | fail            | Unrelated existing failures remain in `tests/card-actions.test.js` active-card CSS expectation and `tests/column-actions.test.js` legacy commented `toggleTodoFromUI` text. |

- Tests added/updated: Extended `tests/context-windows.test.js` to assert note Undo toast actions preserve notes-pane visibility.
- Regression impact: Isolated to AI note refine Undo toast actions and notes-pane outside-click target classification; ordinary outside clicks and unmarked toast actions still use existing dismissal behavior.
- API docs: Not affected; checked surface is client-side notes-pane/toast behavior only, with no route, request, response schema, status, auth, or OpenAPI metadata changed.
- Tooling gates: Formatting, syntax, focused context-window tests, and lint passed; full suite remains blocked by unrelated existing source assertion failures noted above.
- Conflicts / exceptions: Preserved pre-existing dirty same-card notes-pane toggle changes in `public/todolist2.js` and `tests/context-windows.test.js`; did not alter unrelated failing assertions or CSS.

### 2026-06-11T19:11:47Z � WorkLists

- Summary: Restored notes-pane icon toggle close.
- Problem: Clicking a card's notes icon while that same card's notes pane was already open re-entered the open/load flow instead of closing the pane.
- Requirement: The notes icon must toggle same-card pane visibility while preserving existing discard-confirm and autosave safeguards.
- Solution:
  - Added a same-card open-state branch in `openTaskNotesPane` that routes through `closeNotesPane()`.
  - Updated the return-focus target before same-card close so the clicked notes action remains the focus destination.
  - Added focused context-window source coverage for the same-card toggle path and card action wiring.
- Files/areas: `public/todolist2.js`, `tests/context-windows.test.js`.
- User-visible impact: Clicking the notes icon a second time now closes the open notes pane for that card.
- Tests run:

  | Gate   | Command                                                                  | Scope                                      | Result          | Exception / risk                                                                                                                                                            |
  | ------ | ------------------------------------------------------------------------ | ------------------------------------------ | --------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
  | format | `npx prettier --write public\todolist2.js tests\context-windows.test.js` | Touched UI/test files                      | pass, unchanged | �                                                                                                                                                                           |
  | syntax | `node --check public\todolist2.js`                                       | Board UI script                            | pass            | �                                                                                                                                                                           |
  | syntax | `node --check tests\context-windows.test.js`                             | Focused context-window test file           | pass            | �                                                                                                                                                                           |
  | tests  | `node --test tests\context-windows.test.js`                              | Focused notes-pane/context source coverage | pass, 21 tests  | �                                                                                                                                                                           |
  | lint   | `npm run lint`                                                           | WorkLists formatting gate                  | pass            | �                                                                                                                                                                           |
  | tests  | `npm test`                                                               | Full WorkLists suite                       | fail            | Unrelated existing failures remain in `tests/card-actions.test.js` active-card CSS expectation and `tests/column-actions.test.js` legacy commented `toggleTodoFromUI` text. |

- Tests added/updated: Extended `tests/context-windows.test.js` to assert same-card notes icon activation closes the already-open pane.
- Regression impact: UI-only notes-pane opener path; same-card activation now uses the established `closeNotesPane()` path, while different-card switching still uses the existing close-before-switch branch.
- API docs: Not affected; checked surface is client-side notes-pane/card action behavior only, with no route, request, response schema, status, auth, or OpenAPI metadata changed.
- Tooling gates: Focused syntax/context-window tests and lint passed; full suite remains blocked by unrelated existing source assertion failures noted above.
- Conflicts / exceptions: Preserved unrelated dirty-state failures; did not change `tests/card-actions.test.js`, `tests/column-actions.test.js`, or CSS unrelated to the toggle bug.

### 2026-06-11T19:05:48Z � WorkLists

- Summary: Prevented notes-pane link clicks from editing.
- Problem: Clicking rendered hyperlinks in notes-pane card text or saved notes could trigger the notes-pane click-to-edit handlers instead of leaving the link navigation alone.
- Requirement: Hyperlinks inside notes-pane rendered markdown must remain clickable without starting inline card or note editing.
- Solution:
  - Added a rendered-markdown link target guard scoped to the clicked markdown container.
  - Applied the guard before notes-pane card-preview and saved-note content enter discard-confirm/autosave/editor flows.
  - Added focused source coverage proving link guards run before inline editor creation.
- Files/areas: `public/todolist2.js`, `tests/context-windows.test.js`.
- User-visible impact: Clicking a hyperlink in the notes pane now follows the link normally and does not open the card or note edit interface.
- Tests run:

  | Gate   | Command                                      | Scope                                      | Result         | Exception / risk                                                                                                         |
  | ------ | -------------------------------------------- | ------------------------------------------ | -------------- | ------------------------------------------------------------------------------------------------------------------------ |
  | syntax | `node --check public\todolist2.js`           | Board UI script                            | pass           | �                                                                                                                        |
  | syntax | `node --check tests\context-windows.test.js` | Focused context-window test file           | pass           | �                                                                                                                        |
  | tests  | `node --test tests\context-windows.test.js`  | Focused notes-pane/context source coverage | pass, 20 tests | �                                                                                                                        |
  | lint   | `npm run lint`                               | WorkLists lint gate                        | exception      | Skipped by explicit user directive; residual risk is formatting/lint issues outside the focused syntax and source tests. |

- Tests added/updated: Extended `tests/context-windows.test.js` to assert notes-pane markdown link clicks are guarded before discard prompts and inline editor creation.
- Regression impact: UI-only notes-pane click handling isolated to rendered card-preview and saved-note markdown content; action buttons, code-copy controls, and editor save flows are unchanged.
- API docs: Not affected; checked touched surface is client-side notes-pane click handling only, with no route, request, response schema, status, auth, or OpenAPI metadata changed.
- Tooling gates: Focused syntax and context-window tests passed; lint skipped by explicit directive.
- Conflicts / exceptions: Skipped linting per user directive. Preserved unrelated dirty WorkLists state and did not run full-suite gates.

### 2026-06-10T18:16:40Z � WorkLists

- Summary: Hid notes-pane action icons until hover.
- Problem: Card-text and saved-note action icons in the notes pane were always visible, adding visual noise around note content.
- Requirement: Notes-pane action icons should stay hidden by default and reveal only when the user hovers or keyboard-focuses the relevant card-text preview or note item.
- Solution:
  - Added CSS that hides notes-pane card-preview icon buttons and saved-note action groups by default.
  - Revealed card-text actions on `.notes-pane-card-preview:hover` / `:focus-within` and note actions on `.notes-pane-note:hover` / `:focus-within`.
  - Added focused source coverage for the hover/focus reveal contract.
- Files/areas: `public/todoliststyles2.css`, `tests/context-windows.test.js`.
- User-visible impact: Notes pane content now reads cleaner; card-text and note-specific actions appear only when interacting with that specific element.
- Tests run:

  | Gate   | Command                                                                         | Scope                                      | Result         | Exception / risk                                                                                                                                                         |
  | ------ | ------------------------------------------------------------------------------- | ------------------------------------------ | -------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
  | audit  | `npm audit --audit-level=high`                                                  | WorkLists dependencies                     | pass           | Existing 3 moderate `qs`/`body-parser`/`express` advisories remain with no fix available; high/critical gate passes.                                                     |
  | format | `npx prettier --write public\todoliststyles2.css tests\context-windows.test.js` | Touched CSS/test files                     | pass           | �                                                                                                                                                                        |
  | syntax | `node --check tests\context-windows.test.js`                                    | Focused context-window test file           | pass           | �                                                                                                                                                                        |
  | tests  | `node --test tests\context-windows.test.js`                                     | Focused notes-pane/context source coverage | pass, 19 tests | �                                                                                                                                                                        |
  | lint   | `npm run lint`                                                                  | WorkLists formatting gate                  | fail           | Unrelated dirty `tests/task-clipboard.test.js` is not Prettier-formatted; not touched for this notes icon visibility change.                                             |
  | tests  | `npm test`                                                                      | Full WorkLists suite                       | fail           | Unrelated dirty failures remain in `tests/card-actions.test.js` active-card CSS expectation and `tests/column-actions.test.js` legacy commented `toggleTodoFromUI` text. |

- Tests added/updated: Extended `tests/context-windows.test.js` to assert notes-pane card-preview and saved-note action icons are hidden by default and revealed by their own hover/focus context.
- Regression impact: UI-only CSS visibility change isolated to notes-pane card-preview buttons and saved-note action groups; existing click handlers and button DOM remain unchanged.
- API docs: Not affected; checked touched surface is notes-pane CSS/source coverage only, with no route, request, response schema, status, auth, or OpenAPI metadata changed.
- Tooling gates: Audit, formatting, syntax, and focused context-window tests passed; repo lint/full tests remain blocked by unrelated dirty-state issues noted above.
- Conflicts / exceptions: Preserved unrelated dirty WorkLists changes already present in `public/todoliststyles2.css`, `tests/context-windows.test.js`, and other files; did not format or alter unrelated failing test files.

### 2026-06-10T17:55:44Z � WorkLists

- Summary: Streamlined notes-pane inline editing.
- Problem: Editing existing note and card text inside the notes pane required explicit edit/save/cancel steps and reused discard confirmation prompts intended for unsaved drafts.
- Requirement: Existing notes-pane content should click directly into editing, save automatically when focus leaves or the pane closes, confirm with a toast, and reserve discard confirmation for new unsaved notes.
- Solution:
  - Added click-to-edit behavior for rendered notes-pane card text and saved note bodies.
  - Added autosave-on-focus-exit for notes-pane card and note inline editors.
  - Added shared existing-edit autosave handling before pane close, outside-click dismissal, card switching, and note-refine/edit transitions.
  - Limited discard confirmation detection to the new-note composer and kept existing edit cancellation local/no-prompt.
  - Added success toasts for saved card-text and note edits.
  - Extended focused context-window source coverage for click-to-edit, autosave, existing-edit save helpers, and new-note-only discard prompts.
- Files/areas: public/todolist2.js, ests/context-windows.test.js.
- User-visible impact: In the notes pane, clicking existing card text or a saved note opens the inline editor immediately; clicking away saves edits automatically and shows a confirmation toast. Discard prompts now remain for new unsaved notes only.
- Tests run:

  | Gate                                                                    | Command                                    | Scope          | Result                                                                                                                                                                             | Exception / risk |
  | ----------------------------------------------------------------------- | ------------------------------------------ | -------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------- |
  | audit                                                                   |
  | pm audit --audit-level=high                                             | WorkLists dependencies                     | pass           | Existing 3 moderate qs/ody-parser/xpress advisories remain with no fix available; high/critical gate passes.                                                                       |
  | format                                                                  |
  | px prettier --write public\\todolist2.js tests\\context-windows.test.js | Touched UI/test files                      | pass           | �                                                                                                                                                                                  |
  | syntax                                                                  |
  | ode --check public\\todolist2.js                                        | Board UI script                            | pass           | �                                                                                                                                                                                  |
  | syntax                                                                  |
  | ode --check tests\\context-windows.test.js                              | Focused context-window test file           | pass           | �                                                                                                                                                                                  |
  | tests                                                                   |
  | ode --test tests\\context-windows.test.js                               | Focused notes-pane/context source coverage | pass, 18 tests | �                                                                                                                                                                                  |
  | lint                                                                    |
  | pm run lint                                                             | WorkLists formatting gate                  | fail           | Unrelated dirty ests/task-clipboard.test.js is not Prettier-formatted; not touched for this notes editing change.                                                                  |
  | tests                                                                   |
  | pm test                                                                 | Full WorkLists suite                       | fail           | Same unrelated dirty failures remain: active-card CSS/test mismatch in ests/card-actions.test.js and legacy commented oggleTodoFromUI text matched by ests/column-actions.test.js. |

- Tests added/updated: Updated ests/context-windows.test.js coverage for new-note-only discard prompts, existing-edit autosave helpers, click-to-edit card/note content, and save toasts.
- Regression impact: UI-only notes-pane editing behavior; risk is bounded to notes-pane card and saved-note inline editors, with failed autosaves preventing pane close/switch so unsaved existing edits are not silently discarded.
- API docs: Not affected; no route, request, response schema, status, auth, or OpenAPI metadata changed.
- Tooling gates: Audit, touched-file formatting, syntax, and focused context-window tests passed; repo lint/full tests remain blocked by unrelated dirty-state issues noted above.
- Conflicts / exceptions: Preserved unrelated dirty WorkLists changes in public/todolist2.js and other files; did not format or alter ests/task-clipboard.test.js, active-card CSS expectations, or legacy commented column-action text.

### 2026-06-10T17:41:18Z � WorkLists

- Summary: Collapsed inactive add-note composer.
- Problem: The notes-pane add-note composer still consumed multi-line space while inactive because the textarea kept its multi-row height and the action row remained visible even though markdown controls were collapsed.
- Requirement: The add-note input should default to a single-line field and expand only after note text entry begins, revealing the editing tools and create actions when they are useful.
- Solution:
  - Added an expansion-state callback to the shared markdown editor controller.
  - Wired the notes-pane create form to mirror that state with collapsed/expanded form classes.
  - Hid the add-note action row while collapsed and pinned the collapsed textarea to a true 42px single-line height.
  - Extended focused markdown editor source coverage for the collapsed composer contract.
- Files/areas: `public/markdownEditor.js`, `public/index.html`, `public/todolist2.js`, `public/todoliststyles2.css`, `tests/markdown-editor.test.js`.
- User-visible impact: Opening a card's notes pane now shows a compact one-line "Add a note" field by default; typing note text expands the composer to show markdown modes, toolbar controls, voice/AI actions, and the submit button.
- Tests run:

  | Gate   | Command                                                                                                                                        | Scope                                   | Result        | Exception / risk                                                                                                                                                                            |
  | ------ | ---------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------- | ------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
  | audit  | `npm audit --audit-level=high`                                                                                                                 | WorkLists dependencies                  | pass          | Existing 3 moderate `qs`/`body-parser`/`express` advisories remain with no fix available; high/critical gate passes.                                                                        |
  | format | `npx prettier --write public/markdownEditor.js public/index.html public/todolist2.js public/todoliststyles2.css tests/markdown-editor.test.js` | Touched UI/test files                   | pass          | �                                                                                                                                                                                           |
  | syntax | `node --check public\markdownEditor.js`                                                                                                        | Shared markdown editor script           | pass          | �                                                                                                                                                                                           |
  | syntax | `node --check public\todolist2.js`                                                                                                             | Board UI script                         | pass          | �                                                                                                                                                                                           |
  | tests  | `node --test tests\markdown-editor.test.js`                                                                                                    | Focused markdown editor/source coverage | pass, 7 tests | �                                                                                                                                                                                           |
  | lint   | `npm run lint`                                                                                                                                 | WorkLists formatting gate               | fail          | Unrelated dirty `tests/task-clipboard.test.js` is not Prettier-formatted; not touched for this notes composer change.                                                                       |
  | tests  | `npm test`                                                                                                                                     | Full WorkLists suite                    | fail          | Same unrelated dirty failures remain: active-card CSS/test mismatch in `tests/card-actions.test.js` and legacy commented `toggleTodoFromUI` text matched by `tests/column-actions.test.js`. |

- Tests added/updated: Extended `tests/markdown-editor.test.js` source coverage for the collapsed notes-pane form class, expansion-state wiring, hidden collapsed actions, and single-line collapsed textarea height.
- Regression impact: UI-only notes create composer behavior; change is isolated to the shared editor expansion notification and the notes-pane create form classes/CSS. Inline note and card editors continue using the same markdown editor without the form-class callback.
- API docs: Not affected; no route, request, response schema, status, auth, or OpenAPI metadata changed.
- Tooling gates: Audit, touched-file formatting, syntax, and focused markdown editor tests passed; repo lint/full tests remain blocked by unrelated dirty-state issues noted above.
- Conflicts / exceptions: Preserved unrelated dirty WorkLists changes and did not format or alter `tests/task-clipboard.test.js`, active-card CSS expectations, or legacy commented column-action text.

### 2026-06-10T17:14:37Z � WorkLists

- Summary: Opened notes for new-card child notes.
- Problem: Notes-pane reveal worked for explicit AI note jobs and card refinement, but not for a new AI-created card that also generated a child note.
- Requirement: When add-task AI creates a parent card plus a generated child note, the newly created parent card's notes pane should open after the board refresh.
- Solution:
  - Updated `handleCompletedGemmaAddTaskJob` to detect `createdNoteIds` on add-task results.
  - Resolved the target card id from `childNote.eventId` / `childNote.parentTodoId`, with a fallback to the first `createdTodoIds` entry.
  - Reused `revealAiUpdatedNotesPane` after `loadInitialBoardData()` so the newly rendered card exists before the pane opens.
  - Extended focused Gemma UI coverage to assert the add-task child-note reveal path.
- Files/areas: `public/todolist2.js`, `tests/gemma-ui.test.js`.
- User-visible impact: AI-created new cards with generated child notes now automatically open the new card's notes pane when the background job completes.
- Tests run:

  | Gate   | Command                                                           | Scope                            | Result         | Exception / risk                                                                                                                                                                            |
  | ------ | ----------------------------------------------------------------- | -------------------------------- | -------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
  | audit  | `npm audit --audit-level=high`                                    | WorkLists dependencies           | pass           | Existing 3 moderate `qs`/`body-parser`/`express` advisories remain with no fix available; high/critical gate passes.                                                                        |
  | format | `npx prettier --write public/todolist2.js tests/gemma-ui.test.js` | Touched UI/test files            | pass           | �                                                                                                                                                                                           |
  | syntax | `node --check public\todolist2.js`                                | Board UI script                  | pass           | �                                                                                                                                                                                           |
  | syntax | `node --check tests\gemma-ui.test.js`                             | Focused Gemma UI test file       | pass           | �                                                                                                                                                                                           |
  | tests  | `node --test tests\gemma-ui.test.js`                              | Focused Gemma UI source coverage | pass, 28 tests | �                                                                                                                                                                                           |
  | lint   | `npm run lint`                                                    | WorkLists formatting gate        | fail           | Unrelated dirty `tests/task-clipboard.test.js` is not Prettier-formatted; not touched for this add-task reveal fix.                                                                         |
  | tests  | `npm test`                                                        | Full WorkLists suite             | fail           | Same unrelated dirty failures remain: active-card CSS/test mismatch in `tests/card-actions.test.js` and legacy commented `toggleTodoFromUI` text matched by `tests/column-actions.test.js`. |

- Tests added/updated: Extended `tests/gemma-ui.test.js` source coverage for add-task results with generated child notes opening the parent card's notes pane.
- Regression impact: UI-only add-task completion behavior; reveal only runs when the add-task result reports created notes, and it waits until the board has reloaded so the new card can be found.
- API docs: Not affected; no route, request, response schema, status, auth, or OpenAPI metadata changed.
- Tooling gates: Audit, touched-file formatting, syntax, and focused UI tests passed; repo lint/full tests remain blocked by unrelated dirty-state issues noted above.
- Conflicts / exceptions: Preserved unrelated dirty WorkLists changes and did not format or alter `tests/task-clipboard.test.js`, active-card CSS expectations, or legacy commented column-action text.

### 2026-06-10T17:10:18Z � WorkLists

- Summary: Preserved AI note reveal after reloads.
- Problem: The notes pane auto-open behavior worked during a fresh in-memory session, but could fail after browser reload or server restart because restored note-refine jobs lost their card id and missing in-memory server job results skipped the reveal path.
- Requirement: AI note reveal targets must survive local pending-job restore, and a restarted server/missing job result should still refresh/open the relevant notes pane when persisted note data may already exist.
- Solution:
  - Persisted `eventId` for `refine-note` pending jobs during creation and localStorage restore.
  - Added missing-job recovery reveals for `add-note`, `refine-note`, and `refine-card` pending jobs using their local card/task context.
  - Extended focused Gemma UI source coverage for reload persistence and missing server job-result recovery.
- Files/areas: `public/todolist2.js`, `tests/gemma-ui.test.js`.
- User-visible impact: After reloading the browser or restarting the server, pending AI note/card-refine jobs retain enough local context to open or refresh the relevant notes pane when note updates may have landed.
- Tests run:

  | Gate   | Command                                                           | Scope                            | Result         | Exception / risk                                                                                                                                                                            |
  | ------ | ----------------------------------------------------------------- | -------------------------------- | -------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
  | audit  | `npm audit --audit-level=high`                                    | WorkLists dependencies           | pass           | Existing 3 moderate `qs`/`body-parser`/`express` advisories remain with no fix available; high/critical gate passes.                                                                        |
  | format | `npx prettier --write public/todolist2.js tests/gemma-ui.test.js` | Touched UI/test files            | pass           | �                                                                                                                                                                                           |
  | syntax | `node --check public\todolist2.js`                                | Board UI script                  | pass           | �                                                                                                                                                                                           |
  | syntax | `node --check tests\gemma-ui.test.js`                             | Focused Gemma UI test file       | pass           | �                                                                                                                                                                                           |
  | tests  | `node --test tests\gemma-ui.test.js`                              | Focused Gemma UI source coverage | pass, 28 tests | �                                                                                                                                                                                           |
  | lint   | `npm run lint`                                                    | WorkLists formatting gate        | fail           | Unrelated dirty `tests/task-clipboard.test.js` is not Prettier-formatted; not touched for this persistence fix.                                                                             |
  | tests  | `npm test`                                                        | Full WorkLists suite             | fail           | Same unrelated dirty failures remain: active-card CSS/test mismatch in `tests/card-actions.test.js` and legacy commented `toggleTodoFromUI` text matched by `tests/column-actions.test.js`. |

- Tests added/updated: Added `tests/gemma-ui.test.js` source coverage for persisted `eventId` on restored `refine-note` jobs and notes-pane reveal recovery when server job polling returns 404.
- Regression impact: UI-only pending-job restore and recovery behavior; risk is bounded to note-capable Gemma jobs and uses existing card/task ids already persisted for the job indicators.
- API docs: Not affected; no route, request, response schema, status, auth, or OpenAPI metadata changed.
- Tooling gates: Audit, touched-file formatting, syntax, and focused UI tests passed; repo lint/full tests remain blocked by unrelated dirty-state issues noted above.
- Conflicts / exceptions: Preserved unrelated dirty WorkLists changes and did not format or alter `tests/task-clipboard.test.js`, active-card CSS expectations, or legacy commented column-action text.

### 2026-06-10T16:56:43Z � WorkLists

- Summary: Auto-opened notes after AI note updates.
- Problem: AI-created or AI-refined notes could complete in the background while the notes pane stayed closed or focused elsewhere, hiding the generated note content from the user.
- Requirement: Successful AI note creation/refinement and generated child-note creation from card refinement should make the card notes pane visible immediately.
- Solution:
  - Added a shared `revealAiUpdatedNotesPane` helper that refreshes the active notes pane when it is already on the target card, or opens the target card's notes pane when it is closed or inactive.
  - Called the helper after successful `add-note` and changed `refine-note` job completions.
  - Called the helper after card-refine completions that report generated `createdNoteIds`, covering the parent-card plus generated child-note flow.
  - Left skipped and unchanged note jobs as toast-only so focus is not moved when there is no new note content to inspect.
- Files/areas: `public/todolist2.js`, `tests/gemma-ui.test.js`.
- User-visible impact: When AI creates/appends a note or successfully refines a note, the relevant card's notes pane opens or refreshes so the generated update is immediately visible.
- Tests run:

  | Gate   | Command                                                           | Scope                            | Result         | Exception / risk                                                                                                                                                                            |
  | ------ | ----------------------------------------------------------------- | -------------------------------- | -------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
  | audit  | `npm audit --audit-level=high`                                    | WorkLists dependencies           | pass           | Existing 3 moderate `qs`/`body-parser`/`express` advisories remain with no fix available; high/critical gate passes.                                                                        |
  | format | `npx prettier --write public/todolist2.js tests/gemma-ui.test.js` | Touched UI/test files            | pass           | �                                                                                                                                                                                           |
  | syntax | `node --check public\todolist2.js`                                | Board UI script                  | pass           | �                                                                                                                                                                                           |
  | syntax | `node --check tests\gemma-ui.test.js`                             | Focused Gemma UI test file       | pass           | �                                                                                                                                                                                           |
  | tests  | `node --test tests\gemma-ui.test.js`                              | Focused Gemma UI source coverage | pass, 27 tests | �                                                                                                                                                                                           |
  | lint   | `npm run lint`                                                    | WorkLists formatting gate        | fail           | Unrelated dirty `tests/task-clipboard.test.js` is not Prettier-formatted; not touched for this notes-pane change.                                                                           |
  | tests  | `npm test`                                                        | Full WorkLists suite             | fail           | Same unrelated dirty failures remain: active-card CSS/test mismatch in `tests/card-actions.test.js` and legacy commented `toggleTodoFromUI` text matched by `tests/column-actions.test.js`. |

- Tests added/updated: Added `tests/gemma-ui.test.js` source coverage for the notes-pane reveal helper and the successful AI note/card-refine child-note completion triggers.
- Regression impact: UI-only job-completion behavior; regression is bounded to successful note-affecting completions by early returns for skipped/unchanged jobs and by checking `createdNoteIds` before opening the pane from card refinement.
- API docs: Not affected; no route, request, response schema, status, auth, or OpenAPI metadata changed.
- Tooling gates: Audit, touched-file formatting, syntax, and focused UI tests passed; repo lint/full tests remain blocked by unrelated dirty-state issues noted above.
- Conflicts / exceptions: Preserved unrelated dirty WorkLists changes and did not format or alter `tests/task-clipboard.test.js`, active-card CSS expectations, or legacy commented column-action text.

### 2026-06-10T16:41:40Z � WorkLists

- Summary: Added a global voice-to-text keyboard shortcut.
- Problem: Starting voice-to-text required mouse interaction across task entry, card editing, and notes-pane editing surfaces.
- Requirement: `Ctrl+Shift+\` should start the existing voice-to-text flow only when a supported edit/input surface is active, and the shortcut should be centralized for future configurability.
- Solution:
  - Added a configurable `GLOBAL_VOICE_INPUT_SHORTCUT` binding and one document-level keydown listener.
  - Added context routing for task-entry textareas, inline card edit textareas, notes-pane note create/edit surfaces, and the notes-pane card-text editor.
  - Reused the existing `startVoiceInputForElement`, note voice, and card voice paths instead of creating a separate speech-recognition flow.
  - Accounted for browser `Shift+\` key reporting by matching `KeyboardEvent.code === "Backslash"` with a key fallback.
- Files/areas: `public/todolist2.js`, `tests/gemma-ui.test.js`.
- User-visible impact: With focus in a card edit box, task input, or notes-pane editor, pressing `Ctrl+Shift+\` immediately starts voice-to-text for that field.
- Tests run:

  | Gate   | Command                                                           | Scope                                  | Result         | Exception / risk                                                                                                                                                                            |
  | ------ | ----------------------------------------------------------------- | -------------------------------------- | -------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
  | audit  | `npm audit --audit-level=high`                                    | WorkLists dependencies                 | pass           | Existing 3 moderate `qs`/`body-parser`/`express` advisories remain with no fix available; high/critical gate passes.                                                                        |
  | format | `npx prettier --write public/todolist2.js tests/gemma-ui.test.js` | Touched UI/test files                  | pass           | �                                                                                                                                                                                           |
  | syntax | `node --check public\todolist2.js`                                | Board UI script                        | pass           | �                                                                                                                                                                                           |
  | tests  | `node --test tests\gemma-ui.test.js`                              | Focused voice/Gemma UI source coverage | pass, 26 tests | �                                                                                                                                                                                           |
  | lint   | `npm run lint`                                                    | WorkLists formatting gate              | fail           | Unrelated dirty `tests/task-clipboard.test.js` is not Prettier-formatted; not touched for this shortcut change.                                                                             |
  | tests  | `npm test`                                                        | Full WorkLists suite                   | fail           | Same unrelated dirty failures remain: active-card CSS/test mismatch in `tests/card-actions.test.js` and legacy commented `toggleTodoFromUI` text matched by `tests/column-actions.test.js`. |

- Tests added/updated: Added `tests/gemma-ui.test.js` source coverage for the configurable shortcut binding, global listener, and context routing across task, card, and notes-pane voice targets.
- Regression impact: UI-only keyboard shortcut layer; regression is bounded by reusing existing voice-input start functions and by focused source coverage for each supported active-editor context. No shared speech-recognition internals were changed.
- API docs: Not affected; no route, request, response schema, status, auth, or OpenAPI metadata changed.
- Tooling gates: Audit, touched-file formatting, syntax, and focused UI tests passed; repo lint/full tests remain blocked by unrelated dirty-state issues noted above.
- Conflicts / exceptions: Preserved unrelated dirty WorkLists changes and did not format or alter `tests/task-clipboard.test.js`, active-card CSS expectations, or legacy commented column-action text.

### 2026-06-10T16:07:37Z � WorkLists

- Summary: Kept the card notes icon visible for zero-note cards.
- Problem: Cards without saved notes hid the notes affordance, blocking direct access to the notes pane and its editing flow.
- Requirement: Every card must show the notes icon, anchored in the right-side action cluster next to the completion control without overlapping completion dates or other card metadata.
- Solution:
  - Removed the zero-count hidden state from `createTaskNotesIndicatorElement`, so every rendered card keeps an actionable notes button.
  - Assigned explicit action-grid columns so completion dates sit left of the notes button and the completion circle remains the far-right control.
  - Updated card-action source coverage to reject the hidden zero-note state and assert the right-side grid placement.
- Files/areas: `public/todolist2.js`, `public/todoliststyles2.css`, `tests/card-actions.test.js`.
- User-visible impact: Users can open the notes pane from any card, even before a sub-note exists; zero-note cards now show the notes icon beside the completion button.
- Tests run:

  | Gate   | Command                                                                                          | Scope                                | Result              | Exception / risk                                                                                                                                                                                                                                                                              |
  | ------ | ------------------------------------------------------------------------------------------------ | ------------------------------------ | ------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
  | syntax | `node --check public\todolist2.js`                                                               | Board UI script                      | pass                | �                                                                                                                                                                                                                                                                                             |
  | format | `npx prettier --write public/todolist2.js public/todoliststyles2.css tests/card-actions.test.js` | Touched UI/test files                | pass                | �                                                                                                                                                                                                                                                                                             |
  | lint   | `npm run lint`                                                                                   | WorkLists formatting gate            | pass                | �                                                                                                                                                                                                                                                                                             |
  | tests  | `node --test tests\card-actions.test.js`                                                         | Focused card actions/source coverage | fail, 14 of 15 pass | Existing dirty active-card CSS/test mismatch remains: `tests/card-actions.test.js` expects `.card.notes-pane-active-card::after` border `2px`, while dirty `public/todoliststyles2.css` currently has `3px`. The new notes-icon assertions were added before that existing failing assertion. |
  | tests  | `npm test`                                                                                       | Full WorkLists suite                 | fail                | Same two known dirty failures remain: the active-card `2px` vs `3px` CSS/test mismatch and `tests/column-actions.test.js` matching legacy commented `toggleTodoFromUI` text.                                                                                                                  |

- Tests added/updated: Updated `tests/card-actions.test.js` to prove the notes indicator is no longer hidden at zero count and that notes/date/completion controls use distinct right-side grid columns.
- Regression impact: UI-only card action-row behavior; change is isolated to the notes indicator render path and card action CSS columns, with focused source coverage for the placement contract. Existing active-card highlight mismatch remains unrelated and unmodified.
- API docs: Not affected; no route, request, response schema, status, auth, or OpenAPI metadata changed.
- Tooling gates: Syntax, formatting, and repo lint passed; focused and full test runs remain blocked by pre-existing dirty UI/source-regression assertions.
- Conflicts / exceptions: Preserved the existing dirty WorkLists files and did not change the unrelated active-card border mismatch.

### 2026-06-09T16:29:38Z � WorkLists

- Summary: Removed generated child-note title headings before persistence.
- Problem: The nested child-note prompt was close, but Gemma could still start the note with a renamed `#` title such as `# Enable Cross-Board Column Data Association` before the actual `## Problem` body.
- Requirement: Child notes should start with the detailed body content, not a duplicate or paraphrased parent-card title, even when the model ignores the prompt.
- Solution:
  - Tightened `gemma-child-note-directive-template.md` to require the first non-empty line to be a body section/body paragraph and to omit generated title lines entirely.
  - Added a child-note-only sanitizer in `server.js` that strips a leading generated title when it resembles the parent card title or appears before body sections such as `## Problem`.
  - Left fallback note capture untouched so a failed child-note generation still preserves the full original user text.
  - Updated the refine-card nested-note test to reproduce the reported `# Enable Cross-Board Column Data Association` output and assert the persisted note starts at `## Problem`.
- Files/areas: `server.js`, `prompts/gemma-child-note-directive-template.md`, `tests/gemma-normalize.test.js`.
- User-visible impact: Nested child notes generated from card refinement should no longer show a duplicate/renamed title above the note body; the note body should begin with useful content like `## Problem`.
- Tests run:

  | Gate   | Command                                                                                                       | Scope                                                 | Result         | Exception / risk                                                                                                                                                                                                                                                                                             |
  | ------ | ------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------- | -------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
  | syntax | `node --check server.js`                                                                                      | Server job pipeline and child-note sanitizer          | pass           | �                                                                                                                                                                                                                                                                                                            |
  | syntax | `node --check tests\gemma-normalize.test.js`                                                                  | Focused Gemma test file                               | pass           | �                                                                                                                                                                                                                                                                                                            |
  | format | `npx prettier --write server.js tests/gemma-normalize.test.js prompts/gemma-child-note-directive-template.md` | Touched server/test/prompt files                      | pass           | �                                                                                                                                                                                                                                                                                                            |
  | tests  | `node --test tests\gemma-normalize.test.js`                                                                   | Focused Gemma nested-note prompt and persistence flow | pass, 49 tests | �                                                                                                                                                                                                                                                                                                            |
  | audit  | `npm audit --audit-level=high`                                                                                | WorkLists dependencies                                | pass           | Existing 3 moderate `qs`/`body-parser`/`express` advisories remain with no fix available; high/critical gate passes.                                                                                                                                                                                         |
  | lint   | `npm run lint`                                                                                                | Repo Prettier check                                   | pass           | �                                                                                                                                                                                                                                                                                                            |
  | tests  | `npm test`                                                                                                    | Full WorkLists suite                                  | fail           | Same unrelated dirty UI/source-regression failures remain: `tests/card-actions.test.js` expects `.card.notes-pane-active-card::after` CSS absent from dirty `public/todoliststyles2.css`; `tests/column-actions.test.js` still sees commented legacy `toggleTodoFromUI` text in dirty `public/todolist2.js`. |

- Tests added/updated: Updated the refine-card nested-note regression to include a generated leading `#` title and assert the stored child note strips it while retaining `## Problem`, `## Requirement`, and `## Proposed Solution` body sections.
- Regression impact: The sanitizer is scoped to generated nested child notes only; ordinary note create/refine and fallback detail capture are not sanitized. Focused Gemma coverage verifies body section headings are preserved and generated title headings are removed.
- API docs: Not affected; no route, request, response schema, status, auth, or OpenAPI metadata changed in this follow-up.
- Tooling gates: Syntax, formatting, focused Gemma tests, audit threshold, and lint passed; full suite remains blocked by unrelated dirty UI/source-regression failures.
- Conflicts / exceptions: Pre-existing dirty UI/test files were preserved and not reverted; their unrelated failures are still present in the full suite.

### 2026-06-09T15:20:27Z � WorkLists

- Summary: Tightened v1 nested-note prompts and extended the split-card flow to AI card refinement.
- Problem: Substantial one-card AI requests could still produce detailed Markdown on the parent card, and child notes could repeat the parent title as their first heading; the same parent/child split also needed to work from card refinement while remaining disabled for note creation/refinement.
- Requirement: When `child_note` is true, parent normalization must receive only short-card instructions, child-note generation must avoid duplicating the parent title, refine-card jobs must create one child note, and add-note/refine-note jobs must always force nested-note behavior off.
- Solution:
  - Suppressed generic Markdown classification directives during parent-card normalization when `child_note` is true, so the parent-child directive owns parent formatting.
  - Strengthened the parent directive to require a one-line compact parent title/objective and explicitly exclude Problem/Requirement/Solution sections, steps, lists, tables, and long Markdown bodies.
  - Strengthened the child-note directive to omit title/objective headings and treat original `# title/header/objective` requests as satisfied by the parent card.
  - Wired refine-card jobs to create one nested child note after parent-card normalization and to include the child-note generation call in refine prompt traces.
  - Added tests proving note create/refine prompts do not receive nested-note directives even when classification asks for `child_note`.
  - Updated OpenAPI assertions for refine-card `createdNoteIds` and nullable `childNote` result metadata.
- Files/areas: `gemmaNormalize.js`, `server.js`, `openapi.js`, `prompts/gemma-parent-child-note-directive-template.md`, `prompts/gemma-child-note-directive-template.md`, `tests/gemma-normalize.test.js`, `tests/openapi.test.js`.
- User-visible impact: A substantial single-card AI refinement can now keep the existing card short and persist the detailed generated body as one nested note; generated child notes should start with useful body sections instead of a duplicate title. AI note creation/refinement remains a single-note flow and will not create nested notes.
- Tests run:

  | Gate   | Command                                                                                                                                                                                                                | Scope                                                                                                     | Result         | Exception / risk                                                                                                                                                                                                                                                                                             |
  | ------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------- | -------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
  | audit  | `npm audit --audit-level=high`                                                                                                                                                                                         | WorkLists dependencies                                                                                    | pass           | Existing 3 moderate `qs`/`body-parser`/`express` advisories remain with no fix available; high/critical gate passes.                                                                                                                                                                                         |
  | syntax | `node --check gemmaNormalize.js`                                                                                                                                                                                       | Gemma prompt/pipeline module                                                                              | pass           | �                                                                                                                                                                                                                                                                                                            |
  | syntax | `node --check server.js`                                                                                                                                                                                               | Server job pipeline                                                                                       | pass           | �                                                                                                                                                                                                                                                                                                            |
  | syntax | `node --check openapi.js`                                                                                                                                                                                              | OpenAPI module                                                                                            | pass           | �                                                                                                                                                                                                                                                                                                            |
  | syntax | `node --check tests\gemma-normalize.test.js`                                                                                                                                                                           | Focused Gemma test file                                                                                   | pass           | �                                                                                                                                                                                                                                                                                                            |
  | format | `npx prettier --write gemmaNormalize.js server.js openapi.js tests/gemma-normalize.test.js tests/openapi.test.js prompts/gemma-parent-child-note-directive-template.md prompts/gemma-child-note-directive-template.md` | Touched Gemma/OpenAPI/prompt/test files                                                                   | pass           | �                                                                                                                                                                                                                                                                                                            |
  | lint   | `npm run lint`                                                                                                                                                                                                         | Repo Prettier check                                                                                       | pass           | �                                                                                                                                                                                                                                                                                                            |
  | tests  | `node --test tests\gemma-normalize.test.js`                                                                                                                                                                            | Focused Gemma classification, prompt ownership, add-task/refine-card nested-note flow, note-job exclusion | pass, 49 tests | �                                                                                                                                                                                                                                                                                                            |
  | tests  | `node --test tests\openapi.test.js`                                                                                                                                                                                    | OpenAPI schema coverage                                                                                   | pass, 3 tests  | �                                                                                                                                                                                                                                                                                                            |
  | tests  | `npm test`                                                                                                                                                                                                             | Full WorkLists suite                                                                                      | fail           | Same unrelated dirty UI/source-regression failures remain: `tests/card-actions.test.js` expects `.card.notes-pane-active-card::after` CSS absent from dirty `public/todoliststyles2.css`; `tests/column-actions.test.js` still sees commented legacy `toggleTodoFromUI` text in dirty `public/todolist2.js`. |

- Tests added/updated: Added focused coverage for parent prompt directive ownership, child-note title/body rules, refine-card nested-note creation and prompt trace stages, note-job nested-note exclusion, and refine-card OpenAPI child-note metadata.
- Regression impact: Gemma prompt assembly, add-task nested-note persistence, refine-card normalization, and note-job prompt routing were touched; regression is bounded by focused async job tests, prompt unit tests, syntax checks, OpenAPI coverage, and repo lint. Full-suite verification remains blocked by unrelated dirty UI/source-regression failures.
- API docs: Updated; `/api/gemma-normalize/jobs` refine-card results now document `createdNoteIds` and nullable `childNote` metadata. No new route, method, request body, status, auth, or note storage contract was added.
- Tooling gates: Audit threshold, syntax checks, formatting, repo lint, and focused Gemma/OpenAPI tests passed; full suite failed only on unrelated pre-existing dirty UI/source-regression tests.
- Conflicts / exceptions: Pre-existing dirty UI/test files were preserved and not reverted; their unrelated failures are still present in the full suite.

### 2026-06-09T14:53:38Z � WorkLists

- Summary: Implemented v1 nested note creation for substantial single-card AI add-task requests.
- Problem: AI-generated cards could either keep long generated detail on the top-level card or require separate manual note creation, leaving no first-class path for a short parent card plus one detailed child note.
- Requirement: Classification must return `child_note`, only single-card requests may use it, parent normalization must stay short, child note generation must use note rules, and note-generation failure must still preserve the full user detail in a nested note.
- Solution:
  - Extended Gemma classification parsing and prompt instructions with `child_note`, defaulting invalid or missing values to `false` and forcing it to `false` when `card_count > 1`.
  - Added file-backed parent-card and child-note directives under `prompts/`, with child-note prompting carrying parent card ID/text, original user text, markdown, and markdown hint.
  - Wired add-task jobs to create the parent card first, then run one child-note generation call for single-card `child_note` requests, persisting the note against the parent card ID.
  - Added fallback persistence so child-note generation errors save the original user detail as the nested note body while the parent card job still completes.
  - Updated OpenAPI add-task job result schemas for `createdNoteIds` and `childNote` metadata.
- Files/areas: `gemmaNormalize.js`, `server.js`, `openapi.js`, `prompts/gemma-classify-instructions.md`, `prompts/gemma-note-directive-template.md`, `prompts/gemma-parent-child-note-directive-template.md`, `prompts/gemma-child-note-directive-template.md`, `tests/gemma-normalize.test.js`, `tests/openapi.test.js`, plus formatting-only cleanup in pre-existing dirty `tests/column-actions.test.js`.
- User-visible impact: A substantial one-card AI request can now create a short card with the generated detail saved as one nested note; if the note call fails, the original detailed request is preserved in that child note for rerun/recovery.
- Tests run:

  | Gate   | Command                                                                                                                                                                                                                                                                                                | Scope                                                                      | Result             | Exception / risk                                                                                                                                                                                                                               |
  | ------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | -------------------------------------------------------------------------- | ------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
  | audit  | `npm audit --audit-level=high`                                                                                                                                                                                                                                                                         | WorkLists dependencies                                                     | pass               | Existing 3 moderate `qs`/`body-parser`/`express` advisories remain with no fix available; high/critical gate passes.                                                                                                                           |
  | syntax | `node --check gemmaNormalize.js`                                                                                                                                                                                                                                                                       | Gemma prompt/pipeline module                                               | pass               | �                                                                                                                                                                                                                                              |
  | syntax | `node --check server.js`                                                                                                                                                                                                                                                                               | Server job pipeline                                                        | pass               | �                                                                                                                                                                                                                                              |
  | format | `npx prettier --write gemmaNormalize.js server.js openapi.js tests/gemma-normalize.test.js tests/openapi.test.js prompts/gemma-classify-instructions.md prompts/gemma-note-directive-template.md prompts/gemma-parent-child-note-directive-template.md prompts/gemma-child-note-directive-template.md` | Touched Gemma/OpenAPI/prompt/test files                                    | pass               | �                                                                                                                                                                                                                                              |
  | format | `npx prettier --write tests\column-actions.test.js`                                                                                                                                                                                                                                                    | Pre-existing dirty test file blocking repo lint                            | pass               | Formatting-only cleanup; assertions unchanged.                                                                                                                                                                                                 |
  | lint   | `npm run lint`                                                                                                                                                                                                                                                                                         | Repo Prettier check                                                        | pass               | �                                                                                                                                                                                                                                              |
  | tests  | `node --test tests\gemma-normalize.test.js`                                                                                                                                                                                                                                                            | Focused Gemma classification, nested-note flow, fallback, prompt ownership | pass, 48 tests     | �                                                                                                                                                                                                                                              |
  | tests  | `node --test tests\openapi.test.js`                                                                                                                                                                                                                                                                    | OpenAPI schema coverage                                                    | pass, 3 tests      | �                                                                                                                                                                                                                                              |
  | tests  | `node --test tests\card-actions.test.js tests\column-actions.test.js`                                                                                                                                                                                                                                  | Pre-existing dirty UI/source-regression tests                              | fail, 2 of 36 fail | Existing dirty `tests/card-actions.test.js` expects `.card.notes-pane-active-card::after` CSS not present in dirty `public/todoliststyles2.css`; existing dirty `tests/column-actions.test.js` scans commented legacy `toggleTodoFromUI` code. |
  | tests  | `npm test`                                                                                                                                                                                                                                                                                             | Full WorkLists suite                                                       | fail               | Same two unrelated pre-existing failures above; focused Gemma/OpenAPI coverage passed after the implementation.                                                                                                                                |

- Tests added/updated: Added focused coverage for `child_note` parsing/defaulting, parent/child directive injection, successful nested-note persistence, and fallback note persistence when the child-note model call fails; updated OpenAPI schema assertions.
- Regression impact: Gemma add-task job execution and prompt assembly were touched; regression is bounded by focused async job tests, prompt ownership tests, syntax checks, OpenAPI tests, and repo lint. Full-suite verification is currently blocked by unrelated dirty UI/source-regression failures noted above.
- API docs: Updated; `/api/gemma-normalize/jobs` add-task result now documents `createdNoteIds` and nullable `childNote` metadata. No new route, method, request body, status, auth, or note storage contract was added.
- Tooling gates: Audit, syntax, formatting, lint, and focused Gemma/OpenAPI tests passed; full suite failed only on unrelated pre-existing dirty UI/source-regression tests.
- Conflicts / exceptions: Worktree already contained uncommitted UI/test/prompt logging changes before this task; those were preserved. `tests/column-actions.test.js` received formatting-only cleanup to unblock `npm run lint`.

### 2026-06-08T16:37:53Z � WorkLists

- Summary: Moved the active notes-card visual from internal section rings to one full-card perimeter highlight.
- Problem: The prior border-only correction still highlighted the card text section and bottom action bar as separate internal regions, so the selection looked like an active text box rather than the card itself.
- Requirement: The notes-pane active state must indicate the whole card is selected, including the lower action bar, without adding internal section borders or repainting tag/background colors.
- Solution:
  - Replaced internal `.task-content` and `.actions` active rings with a single `.card.notes-pane-active-card::after` perimeter overlay.
  - Kept the existing active-card state sync and `aria-current="true"` behavior unchanged.
  - Updated source tests to require the full-card pseudo-element border and reject active rules targeting `.task-content` or `.actions`.
  - Updated browser smoke coverage to verify surface background and internal shadow styles remain unchanged while the card-level pseudo-element border is active.
- Files/areas: `public/todoliststyles2.css`, `tests/card-actions.test.js`, `tests/browser-notes-smoke.js`, `docs/WorkLists/worklists-app-changelog.md`.
- User-visible impact: The active notes-pane card now reads as one selected card with a perimeter highlight around the full rounded card, not around the text block or lower bar separately.
- Tests run:

  | Gate   | Command                                                                                                   | Scope                               | Result          | Exception / risk                                                                                                     |
  | ------ | --------------------------------------------------------------------------------------------------------- | ----------------------------------- | --------------- | -------------------------------------------------------------------------------------------------------------------- |
  | audit  | `npm audit --audit-level=high`                                                                            | WorkLists dependencies              | pass            | Existing 3 moderate `qs`/`body-parser`/`express` advisories remain with no fix available; high/critical gate passes. |
  | syntax | `node --check public\todolist2.js`                                                                        | Board UI script                     | pass            | �                                                                                                                    |
  | format | `npx prettier --write public/todoliststyles2.css tests/card-actions.test.js tests/browser-notes-smoke.js` | Touched style/test files            | pass            | �                                                                                                                    |
  | lint   | `npm run lint`                                                                                            | Repo Prettier check                 | pass            | �                                                                                                                    |
  | tests  | `node --test tests\card-actions.test.js`                                                                  | Focused card action/source coverage | pass, 15 tests  | �                                                                                                                    |
  | tests  | `npm run test:browser`                                                                                    | Notes pane browser smoke            | pass, 1 test    | �                                                                                                                    |
  | tests  | `npm test`                                                                                                | Full WorkLists suite                | pass, 370 tests | �                                                                                                                    |

- Tests added/updated: Updated active-card source/style assertions and browser smoke computed-style checks to prove the highlight is card-level only, with no internal section highlight rules.
- Regression impact: Visual styling only; regression is bounded to notes-pane active-card selection chrome and verified by source, browser smoke, and full-suite coverage.
- API docs: Not affected; UI-only CSS/test correction, with no HTTP route, method, request body, response shape, status, auth contract, or OpenAPI metadata changed.
- Tooling gates: Audit threshold, syntax check, formatting, repo-wide lint, focused tests, browser smoke, and full tests passed.
- Conflicts / exceptions: Pre-existing uncommitted Gemma prompt/code/test changes remain present and untouched.

### 2026-06-08T16:35:21Z � WorkLists

- Summary: Corrected active notes-card styling to use border/perimeter highlights instead of changing card fill colors.
- Problem: The first active-card highlight changed the whole card and note indicator background, which obscured the card's tag-color context.
- Requirement: The selected notes-pane card must preserve existing card, text-area, and bottom action-bar background colors while still showing a clear active perimeter highlight.
- Solution:
  - Replaced active-card background overrides with a blue outline and glow on the card perimeter.
  - Added inset perimeter rings around `.task-content` and the bottom `.actions` bar without changing their fills.
  - Updated source assertions to prevent active-card background-color rules and require text/action-bar perimeter styling.
  - Expanded browser smoke coverage to compare card, text, and action-bar computed background colors before and after activation while verifying active perimeter shadows exist.
- Files/areas: `public/todoliststyles2.css`, `tests/card-actions.test.js`, `tests/browser-notes-smoke.js`, `docs/WorkLists/worklists-app-changelog.md`.
- User-visible impact: The notes-pane active card now reads like a focused/selected card via blue perimeter rings while preserving tag/background color context.
- Tests run:

  | Gate   | Command                                                                                                   | Scope                               | Result          | Exception / risk                                                                                                     |
  | ------ | --------------------------------------------------------------------------------------------------------- | ----------------------------------- | --------------- | -------------------------------------------------------------------------------------------------------------------- |
  | audit  | `npm audit --audit-level=high`                                                                            | WorkLists dependencies              | pass            | Existing 3 moderate `qs`/`body-parser`/`express` advisories remain with no fix available; high/critical gate passes. |
  | syntax | `node --check public\todolist2.js`                                                                        | Board UI script                     | pass            | �                                                                                                                    |
  | format | `npx prettier --write tests/card-actions.test.js tests/browser-notes-smoke.js public/todoliststyles2.css` | Touched style/test files            | pass            | �                                                                                                                    |
  | lint   | `npm run lint`                                                                                            | Repo Prettier check                 | pass            | �                                                                                                                    |
  | tests  | `node --test tests\card-actions.test.js`                                                                  | Focused card action/source coverage | pass, 15 tests  | �                                                                                                                    |
  | tests  | `npm run test:browser`                                                                                    | Notes pane browser smoke            | pass, 1 test    | �                                                                                                                    |
  | tests  | `npm test`                                                                                                | Full WorkLists suite                | pass, 370 tests | �                                                                                                                    |

- Tests added/updated: Updated active-card source/style assertions and browser smoke computed-style checks to prove active highlighting does not repaint semantic card/action backgrounds.
- Regression impact: Visual styling only; regression is bounded to active notes-pane card selection chrome and verified by source, browser smoke, and full-suite coverage.
- API docs: Not affected; UI-only CSS/test correction, with no HTTP route, method, request body, response shape, status, auth contract, or OpenAPI metadata changed.
- Tooling gates: Audit threshold, syntax check, formatting, repo-wide lint, focused tests, browser smoke, and full tests passed.
- Conflicts / exceptions: Pre-existing uncommitted Gemma prompt/code/test changes remain present and untouched.

### 2026-06-08T16:19:58Z � WorkLists

- Summary: Added active-card highlighting for the card currently open in the notes pane.
- Problem: When the notes sidebar is open, the board did not visually identify which card the pane belongs to, making navigation across nearby cards harder to track.
- Requirement: The active notes-pane card must show a clear selected state while the pane is open, move the selected state when switching cards, survive card rerenders/indicator refreshes, and clear when the pane closes.
- Solution:
  - Added `syncActiveNotesCardHighlight()` to project `activeNotesTaskId` onto rendered card DOM state with `.notes-pane-active-card` and `aria-current="true"`.
  - Synced the highlight when opening/closing the notes pane, refreshing note indicators, and creating/re-rendering cards.
  - Added a blue-accent selected-card style that preserves completed-card distinction and emphasizes the note indicator on the active card.
  - Expanded source and browser smoke coverage for open, close, card switching, and post-edit active-card persistence.
- Files/areas: `public/todolist2.js`, `public/todoliststyles2.css`, `tests/card-actions.test.js`, `tests/browser-notes-smoke.js`, `docs/WorkLists/worklists-app-changelog.md`.
- User-visible impact: Opening a card's notes now adds a bluish highlighted state to that card; switching notes moves the highlight; closing the pane removes it.
- Tests run:

  | Gate   | Command                                                                                                                       | Scope                               | Result          | Exception / risk                                                                                                     |
  | ------ | ----------------------------------------------------------------------------------------------------------------------------- | ----------------------------------- | --------------- | -------------------------------------------------------------------------------------------------------------------- |
  | audit  | `npm audit --audit-level=high`                                                                                                | WorkLists dependencies              | pass            | Existing 3 moderate `qs`/`body-parser`/`express` advisories remain with no fix available; high/critical gate passes. |
  | syntax | `node --check public\todolist2.js`                                                                                            | Board UI script                     | pass            | �                                                                                                                    |
  | format | `npx prettier --write public/todolist2.js public/todoliststyles2.css tests/card-actions.test.js tests/browser-notes-smoke.js` | Touched UI/test files               | pass            | �                                                                                                                    |
  | lint   | `npm run lint`                                                                                                                | Repo Prettier check                 | pass            | �                                                                                                                    |
  | tests  | `node --test tests\card-actions.test.js`                                                                                      | Focused card action/source coverage | pass, 15 tests  | �                                                                                                                    |
  | tests  | `npm run test:browser`                                                                                                        | Notes pane browser smoke            | pass, 1 test    | �                                                                                                                    |
  | tests  | `npm test`                                                                                                                    | Full WorkLists suite                | pass, 370 tests | �                                                                                                                    |

- Tests added/updated: Updated card action source assertions for active-card sync/style and expanded the notes browser smoke test for selected-card behavior across open, close, switch, and edit flows.
- Regression impact: Notes-pane state syncing and card render refresh paths were touched; regression is bounded to card DOM selection state and verified by focused source tests, browser smoke coverage, and the full suite.
- API docs: Not affected; UI-only notes/card selection state, with no HTTP route, method, request body, response shape, status, auth contract, or OpenAPI metadata changed.
- Tooling gates: Audit threshold, syntax check, formatting, repo-wide lint, focused tests, browser smoke, and full tests passed.
- Conflicts / exceptions: Pre-existing uncommitted Gemma prompt/code/test changes were present in the app repo and were preserved; this session only modified notes-card highlight files.

### 2026-06-08T14:03:36Z � WorkLists

- Summary: Moved remaining AI directive prompt copy into prompt-folder templates.
- Problem: Dynamic classification, tagging, note-context, and user-text prompt fragments were still embedded in `gemmaNormalize.js`, leaving AI-facing instruction text mixed into infrastructure code.
- Requirement: Prompt wording must live under `WorkLists/prompts/`, with infrastructure limited to reading, rendering, and passing data variables into templates.
- Solution:
  - Added prompt templates for classification context, tagging context, note context, and the `User text:` label.
  - Added a small template renderer for conditional blocks and variable substitution in `gemmaNormalize.js`.
  - Updated classification/tagging/note directive builders to render file-backed templates instead of assembling instruction strings inline.
  - Added regression coverage proving directive copy remains in prompt-folder files and out of `gemmaNormalize.js`.
  - Updated `docs/WorkLists/worklists-ai-refinement-integration.md` with the new prompt inventory and remaining abstraction targets.
- Files/areas: `gemmaNormalize.js`, `prompts/gemma-classification-directive-template.md`, `prompts/gemma-tagging-directive-template.md`, `prompts/gemma-note-directive-template.md`, `prompts/gemma-user-text-label.md`, `tests/gemma-normalize.test.js`, `docs/WorkLists/worklists-ai-refinement-integration.md`, `docs/WorkLists/worklists-app-changelog.md`.
- User-visible impact: No intended UI change; AI prompt behavior should remain the same while prompt wording is now easier to inspect and edit from the prompt folder.
- Tests run:

  | Gate   | Command                                                                                                                                                                                                                                                     | Scope                                    | Result          | Exception / risk                                                                                                     |
  | ------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------- | --------------- | -------------------------------------------------------------------------------------------------------------------- |
  | audit  | `npm audit --audit-level=high`                                                                                                                                                                                                                              | WorkLists dependencies                   | pass            | Existing 3 moderate `qs`/`body-parser`/`express` advisories remain with no fix available; high/critical gate passes. |
  | format | `npx prettier --write .\gemmaNormalize.js .\tests\gemma-normalize.test.js .\prompts\gemma-classification-directive-template.md .\prompts\gemma-tagging-directive-template.md .\prompts\gemma-note-directive-template.md .\prompts\gemma-user-text-label.md` | Touched prompt/code/test files           | pass            | �                                                                                                                    |
  | lint   | `npm run lint`                                                                                                                                                                                                                                              | Repo Prettier check                      | pass            | �                                                                                                                    |
  | tests  | `node --test .\tests\gemma-normalize.test.js`                                                                                                                                                                                                               | Focused Gemma prompt/refinement coverage | pass, 42 tests  | �                                                                                                                    |
  | tests  | `npm test`                                                                                                                                                                                                                                                  | Full WorkLists suite                     | pass, 369 tests | �                                                                                                                    |

- Tests added/updated: Added Gemma prompt-file regression coverage for directive template ownership.
- Regression impact: Prompt assembly infrastructure was touched; regression is bounded to Gemma classification/tagging/note directive rendering and verified with focused Gemma tests plus the full suite.
- API docs: Not affected; no HTTP route, method, request body, response shape, status, auth contract, or OpenAPI metadata changed.
- Tooling gates: Audit threshold, targeted formatting, repo-wide lint, focused Gemma tests, and full tests passed.
- Conflicts / exceptions: WorkLists app repo already had active uncommitted UI/test changes from earlier notes-pane work and prompt-trace changes; this session preserved them.

### 2026-06-08T06:00:47Z � WorkLists

- Summary: Documented WorkLists AI refinement prompt locations and model-call integration.
- Problem: AI refinement behavior had accumulated across prompt files, hard-coded directives, async job routing, note-specific constraints, tagging context, and final-review result shaping, making it hard to remember whether refinement currently uses two model calls or an intended third verifier pass.
- Requirement: Keep a durable WorkLists reference in the Dustin Thomason repo that identifies prompt files, hard-coded prompt text, current call counts, card-vs-note differences, and the gap between current `finalReview` response shaping and any future third model call.
- Solution:
  - Added `docs/WorkLists/worklists-ai-refinement-integration.md` as the reference for AI refinement prompt inventory and call flow.
  - Captured current model-call counts for direct normalize, add-task, card refine, note create, note refine, and source-changed skips.
  - Documented which prompt pieces are file-based versus hard-coded in `gemmaNormalize.js`, including classification, tagging, note context, and `User text:` assembly.
  - Recorded that current `finalReview` is server-side result shaping, not a third model call, and named the future abstraction path for a verifier pass if that behavior is restored.
- Files/areas: `docs/WorkLists/worklists-ai-refinement-integration.md`, `docs/WorkLists/worklists-app-changelog.md`.
- User-visible impact: No app UI changes; future WorkLists AI/refinement work now has a canonical prompt and call-flow map.
- Tests run: Not run; docs-only Dustin repo update with no executable WorkLists app code changed in this documentation step.
- Tests added/updated: Not relevant; documentation-only update.
- Regression impact: Not relevant; no app code or behavior changed in this documentation step.
- API docs: Not affected; no HTTP route, method, request body, response shape, status, auth contract, or OpenAPI metadata changed.
- Tooling gates: Not run; Dustin repo documentation-only update, outside app package tooling scope.
- Conflicts / exceptions: WorkLists app repo already had active uncommitted app/test changes from the prompt-trace investigation; this documentation step did not modify those app files.

### 2026-06-08T05:25:51Z � WorkLists

- Summary: Added active-edit discard confirmation for notes pane dismissal.
- Problem: The outside-click notes pane closer could dismiss or transition away from an active notes-pane edit surface without treating that active edit state as confirm-worthy unless text had already changed.
- Requirement: Any active notes-pane edit surface must prompt before dismissal or card-to-card notes switching; choosing Cancel must leave the user in the edit state, and choosing Discard must close/switch while preserving the one-click outside action flow.
- Solution:
  - Extended notes-pane draft detection with `includeActiveState` so card-text and saved-note inline editors are guarded even before text changes.
  - Routed pane close and notes-pane re-open/switch paths through active-state discard confirmation while leaving internal cancel controls on the existing changed-text-only guard.
  - Updated outside-click dismissal to pause actionable outside clicks when confirmation is required, then replay the clicked action after the user chooses Discard.
  - Expanded browser smoke coverage to assert Cancel keeps the active edit open and Discard closes the pane then opens the outside card action menu.
- Files/areas: `public/todolist2.js`, `tests/context-windows.test.js`, `tests/browser-notes-smoke.js`.
- User-visible impact:
  - Active note/card edit surfaces in the notes pane now ask before being discarded by outside clicks, Escape/context dismissal, close, or switching to another card's notes.
  - Cancel returns the user to the active edit state.
  - Discard closes the pane and continues the originally clicked outside action without needing another click.
- Tests run:

  | Gate   | Command                                                                                               | Scope                                  | Result          | Exception / risk                                                                                                     |
  | ------ | ----------------------------------------------------------------------------------------------------- | -------------------------------------- | --------------- | -------------------------------------------------------------------------------------------------------------------- |
  | audit  | `npm audit --audit-level=high`                                                                        | WorkLists dependencies                 | pass            | Existing 3 moderate `qs`/`body-parser`/`express` advisories remain with no fix available; high/critical gate passes. |
  | syntax | `node --check public\todolist2.js`                                                                    | Board UI script                        | pass            | �                                                                                                                    |
  | format | `npx prettier --write public/todolist2.js tests/context-windows.test.js tests/browser-notes-smoke.js` | Touched UI/test files                  | pass            | �                                                                                                                    |
  | lint   | `npm run lint`                                                                                        | Repo Prettier check                    | pass            | �                                                                                                                    |
  | tests  | `npm test -- tests\context-windows.test.js`                                                           | Focused context-window source coverage | pass, 17 tests  | �                                                                                                                    |
  | tests  | `npm run test:browser`                                                                                | Notes pane browser smoke               | pass, 1 test    | �                                                                                                                    |
  | tests  | `npm test`                                                                                            | Full unit suite                        | pass, 368 tests | �                                                                                                                    |

- Tests added/updated: Updated context-window source assertions for active-state discard detection and outside-action replay; expanded the notes browser smoke test for Cancel and Discard behavior while an edit surface is active.
- Regression impact: Notes-pane dismissal, active edit guard behavior, card action menu click sequencing, and note-to-note switching were touched; regression is bounded to notes pane context-window behavior and verified by focused source tests, browser smoke coverage, and the full suite.
- API docs: Not affected; UI-only event handling, with no HTTP route, method, request body, response shape, status, auth contract, or OpenAPI metadata changed.
- Tooling gates: Audit threshold, syntax check, formatting, repo-wide lint, focused tests, browser smoke, and full tests passed.
- Conflicts / exceptions: No unrelated app-repo worktree changes were present. Audit still reports existing moderate advisories below the configured high/critical gate.

### 2026-06-08T05:16:21Z � WorkLists

- Summary: Fixed notes pane blur dismissal and note-to-note switching.
- Problem: The notes pane stayed open after outside clicks, and switching from one card's notes to another did not explicitly close the current context pane first.
- Requirement: Outside clicks must dismiss the notes pane without swallowing the clicked outside action, and clicking another notes opener must immediately show that card's notes in the same click sequence.
- Solution:
  - Added a capture-phase notes-pane outside-click listener that closes the pane with `restoreFocus: false` while letting the original click continue to its target.
  - Exempted notes-opening targets from the global outside-click closer so note icons and the card action menu's `Edit Notes` item route through `openTaskNotesPane` without an async close race.
  - Updated `openTaskNotesPane` to close an already-open pane before opening another card's notes, preserving draft-discard confirmation.
  - Extended source and browser smoke coverage for outside-click dismissal, first-click card menu action, and note-to-note pane switching.
- Files/areas: `public/todolist2.js`, `tests/context-windows.test.js`, `tests/browser-notes-smoke.js`.
- User-visible impact:
  - Clicking outside the notes pane now closes it.
  - Clicking a visible outside card/menu control acts on the first click while also dismissing the notes pane.
  - Clicking a different notes icon now transitions directly to the new card's notes with clear updated content.
- Tests run:

  | Gate   | Command                                                                                               | Scope                                  | Result          | Exception / risk                                                                                                     |
  | ------ | ----------------------------------------------------------------------------------------------------- | -------------------------------------- | --------------- | -------------------------------------------------------------------------------------------------------------------- |
  | audit  | `npm audit --audit-level=high`                                                                        | WorkLists dependencies                 | pass            | Existing 3 moderate `qs`/`body-parser`/`express` advisories remain with no fix available; high/critical gate passes. |
  | syntax | `node --check public\todolist2.js`                                                                    | Board UI script                        | pass            | �                                                                                                                    |
  | format | `npx prettier --write public/todolist2.js tests/context-windows.test.js tests/browser-notes-smoke.js` | Touched UI/test files                  | pass            | �                                                                                                                    |
  | lint   | `npm run lint`                                                                                        | Repo Prettier check                    | pass            | �                                                                                                                    |
  | tests  | `npm test -- tests\context-windows.test.js`                                                           | Focused context-window source coverage | pass, 17 tests  | �                                                                                                                    |
  | tests  | `npm run test:browser`                                                                                | Notes pane browser smoke               | pass, 1 test    | �                                                                                                                    |
  | tests  | `npm test`                                                                                            | Full unit suite                        | pass, 368 tests | �                                                                                                                    |

- Tests added/updated: Added context-window source assertions for outside-click dismissal and close-before-switch behavior; expanded the notes browser smoke test with a second noted card, first-click card-menu dismissal, and note-to-note switching.
- Regression impact: Notes-pane context-window behavior and card action menu interaction were touched; regression is bounded to notes pane open/close sequencing and verified by focused source tests, browser smoke coverage, and the full suite.
- API docs: Not affected; UI-only event handling, with no HTTP route, method, request body, response shape, status, auth contract, or OpenAPI metadata changed.
- Tooling gates: Audit threshold, syntax check, formatting, repo-wide lint, focused tests, browser smoke, and full tests passed.
- Conflicts / exceptions: No unrelated worktree changes were present. Audit still reports existing moderate advisories below the configured high/critical gate.

### 2026-06-07T16:51:54Z � WorkLists

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
  | syntax | `node --check public\todolist2.js`                                                                                                                                                                 | Board UI script                                 | pass            | �                                                                                                                    |
  | format | `npx prettier --write public/index.html public/todolist2.js public/todoliststyles2.css tests/column-actions.test.js tests/filter-menu.test.js tests/search-scopes.test.js tests/scheduler.test.js` | Touched UI/test files                           | pass            | Files were unchanged by formatting.                                                                                  |
  | lint   | `npm run lint`                                                                                                                                                                                     | Repo Prettier check                             | pass            | �                                                                                                                    |
  | tests  | `npm test -- tests\column-actions.test.js tests\filter-menu.test.js tests\search-scopes.test.js tests\scheduler.test.js`                                                                           | Focused column/header filter/scheduler coverage | pass, 41 tests  | �                                                                                                                    |
  | tests  | `npm test`                                                                                                                                                                                         | Full suite                                      | pass, 366 tests | �                                                                                                                    |

- Tests added/updated: Updated source-regression tests to assert the refresh reset icon, compact filter/scheduler markup, accessible labels/tooltips, and compact toolbar CSS.
- Regression impact: Column header and top navigation controls were touched; regression is bounded to button markup/styling and verified by focused source tests plus the full suite.
- API docs: Not affected; UI-only markup/styling behavior, with no HTTP route, method, request body, response shape, status, or auth contract changed.
- Tooling gates: Audit threshold, syntax check, formatting, repo-wide lint, focused tests, and full tests passed.
- Conflicts / exceptions: Worktree already contained active-board/session-storage edits in `public/todolist2.js`, `tests/board-refresh.test.js`, and this changelog; this session preserved and layered on top of them. Audit still reports existing moderate advisories below the configured gate.

### 2026-06-06T17:53:42Z � WorkLists

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
  - `npm audit --audit-level=high` � pass for high/critical threshold; reports 3 moderate `qs`/`body-parser`/`express` advisories with no fix available.
  - `node --check public\todolist2.js` � pass.
  - `npx prettier --check public/todolist2.js tests/board-refresh.test.js` � pass.
  - `npm test -- tests\board-refresh.test.js` � pass, 6 tests.
  - `npm run lint` � pass.
  - `npm test` � pass, 366 tests.
- Tests added/updated: Added board-refresh regression coverage proving active board persistence uses `sessionStorage`, no longer reads/writes `localStorage.currentBoardId`, and retains refresh behavior from the fetched server snapshot.
- Regression impact: Active board selection and board refresh routing were touched; regression is bounded to `currentBoardId` resolution/storage and verified by focused board-refresh tests plus the full test suite.
- API docs: Not affected; UI/session-storage behavior only, with no HTTP route, method, request body, response shape, status, or auth contract changed.
- Tooling gates: Audit threshold, syntax check, targeted Prettier, repo-wide lint, focused tests, and full tests passed.
- Conflicts / exceptions: `npm audit` still reports existing moderate advisories with no fix available; high/critical threshold passes.

### 2026-06-05T18:45:11Z � WorkLists

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
  - `npm audit --audit-level=high` � pass for high/critical threshold; reports 3 moderate `qs`/`body-parser`/`express` advisories with no fix available.
  - `node --check public\todolist2.js` � pass.
  - `npx prettier --check public/todolist2.js tests/context-windows.test.js tests/gemma-ui.test.js` � pass.
  - `npm test -- tests/context-windows.test.js tests/task-clipboard.test.js tests/markdown-renderer.test.js tests/gemma-ui.test.js` � pass, 67 tests.
  - `npm test` � pass, 365 tests.
  - `npm run lint` � blocked by pre-existing formatting warning in `prompts/gemma-classify-instructions.md`; touched files pass targeted Prettier.
- Tests added/updated: Added source regression coverage for the card-description edit/AI/copy/delete toolbar, AI refine routing, delete routing, accessible labels, and notes-pane AI in-flight sync.
- Regression impact: Notes-pane card-description action wiring and AI state sync were touched; focused context/clipboard/markdown/AI tests and full unit tests passed.
- API docs: Not affected; this is UI-only and no HTTP route, method, request body, response shape, status, or auth contract changed.
- Tooling gates: Audit threshold, syntax check, targeted Prettier, focused tests, and full tests passed; repo-wide lint remains blocked only by the existing prompt formatting warning.
- Conflicts / exceptions: Worktree contains pre-existing unrelated modifications/untracked files; this session did not revert them. Lint exception is unrelated to this session and remains in `prompts/gemma-classify-instructions.md`.

### 2026-06-05T18:37:56Z � WorkLists

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
  - `npm audit --audit-level=high` � pass for high/critical threshold; reports 3 moderate `qs`/`body-parser`/`express` advisories with no fix available.
  - `node --check public\todolist2.js` � pass.
  - `npx prettier --check public/todolist2.js public/todoliststyles2.css tests/task-clipboard.test.js tests/context-windows.test.js` � pass.
  - `npm test -- tests/task-clipboard.test.js tests/context-windows.test.js tests/markdown-renderer.test.js` � pass, 41 tests.
  - `npm test` � pass, 364 tests.
  - `npm run lint` � blocked by pre-existing formatting warning in `prompts/gemma-classify-instructions.md`; touched files pass targeted Prettier.
- Tests added/updated: Added source regression coverage for notes-pane copy buttons, note-specific copy toasts, raw-source attributes, notes-pane code-copy binding, and accessible copy labels.
- Regression impact: Notes-pane read rendering, copy behavior, and markdown code-block controls were touched; focused clipboard/context/markdown tests and full unit tests passed.
- API docs: Not affected; this is UI-only and no HTTP route, method, request body, response shape, status, or auth contract changed.
- Tooling gates: Audit threshold, syntax check, targeted Prettier, focused tests, and full tests passed; repo-wide lint remains blocked only by the existing prompt formatting warning.
- Conflicts / exceptions: Worktree contains pre-existing unrelated modifications/untracked files; this session did not revert them. Lint exception is unrelated to this session and remains in `prompts/gemma-classify-instructions.md`.

### 2026-06-03T16:15:21Z � WorkLists

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
  - `npm audit --audit-level=high` � pass for high/critical threshold; reports 3 moderate `qs`/`body-parser`/`express` advisories with no fix available.
  - `node --check public/todolist2.js` � pass.
  - `npm test -- tests/card-actions.test.js tests/card-move-ui.test.js tests/task-clipboard.test.js tests/edit-session.test.js tests/gemma-ui.test.js` � pass, 61 tests.
  - `npm test` � pass, 362 tests.
  - `npm run lint` � blocked by pre-existing formatting warning in `prompts/gemma-classify-instructions.md`; touched files were formatted with Prettier.
- Tests added/updated: Added source regression coverage for edit-context AI refine wiring, undo-capable delete/complete/move toasts, manual add-card toast feedback, and the shared edit refine helper.
- Regression impact: Card action feedback, inline edit AI controls, card move handling, delete handling, and completion toggling were touched; focused UI tests and the full suite passed.
- API docs: Not affected; no HTTP route, method, request body, response shape, status, or auth contract changed.
- Tooling gates: Audit threshold, syntax check, focused tests, and full tests passed; repo lint remains blocked only by the existing prompt formatting warning.
- Conflicts / exceptions: Worktree contains pre-existing unrelated modifications/untracked files; this session did not revert them. Lint exception is unrelated to this session and remains in `prompts/gemma-classify-instructions.md`.

### 2026-06-03T16:05:13Z � WorkLists

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
  - `node --check public/todolist2.js` � pass.
  - `npm test -- tests/column-actions.test.js` � pass, 20 tests.
  - `npm test` � pass, 358 tests.
  - `npm run lint` � blocked by pre-existing formatting warning in `prompts/gemma-classify-instructions.md`; touched files pass after targeted Prettier formatting.
- Tests added/updated: Updated column header regression coverage for the structured tooltip markup and CSS reveal rules.
- Regression impact: Column counter rendering and tooltip styling were touched; focused column tests and full unit tests passed.
- API docs: Not affected; this is UI-only and no HTTP contract changed.
- Tooling gates: Syntax check, focused tests, and full tests passed; repo lint remains blocked only by the existing prompt formatting warning.
- Conflicts / exceptions: Lint exception is unrelated to this session and remains in `prompts/gemma-classify-instructions.md`.

### 2026-06-03T16:01:05Z � WorkLists

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
  - `node --check public/todolist2.js` � pass.
  - `npm test -- tests/column-actions.test.js` � pass, 20 tests.
  - `npm test` � pass, 358 tests.
  - `npm run lint` � blocked by pre-existing formatting warning in `prompts/gemma-classify-instructions.md`; touched files pass after targeted Prettier formatting.
- Tests added/updated: Extended column header regression coverage for counter creation, placement order, and CSS spacing.
- Regression impact: Column header rendering and spacing were touched; focused column tests and full unit tests passed.
- API docs: Not affected; this is UI-only and no HTTP contract changed.
- Tooling gates: Syntax check, focused tests, and full tests passed; repo lint remains blocked only by the existing prompt formatting warning.
- Conflicts / exceptions: Lint exception is unrelated to this session and remains in `prompts/gemma-classify-instructions.md`.

### 2026-06-01T16:33:08-04:00 � WorkLists

- Summary: Matched notes line-break rendering to card markdown rendering.
- Files/areas: `public/todoliststyles2.css`, `tests/markdown-editor.test.js`, `tests/browser-notes-smoke.js`, `docs/worklists/worklists-app-changelog.md`.
- User-visible impact:
  - Notes now give the same visible spacing to intentional blank lines that cards already get from the shared markdown renderer.
  - Single newlines in notes continue to render as visible line breaks through the shared card markdown renderer.
  - The browser smoke test now creates a multiline note and verifies both `<br>` line breaks and visible blank-line spacing in the notes pane.
- Tests run:
  - `npm test -- tests/markdown-editor.test.js tests/markdown-renderer.test.js` � pass, 25 tests.
  - `npm run test:browser` � pass, 1 browser smoke test.
  - `npm test` � pass, 358 tests.
- Tests added/updated: Added notes CSS coverage for `.markdown-blank-line` and browser coverage for notes line-break/blank-line rendering parity.
- Regression impact: Notes markdown display spacing was touched; focused markdown tests, browser smoke, and full unit tests passed.
- API docs: Not affected; no HTTP contract changed.
- Tooling gates: Focused markdown tests, browser smoke, and full unit tests passed.
- Conflicts / exceptions: Notes already used the shared card renderer; this change fills the notes-specific CSS and browser-regression gap.

### 2026-06-01T17:32:27Z � WorkLists

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
  - `npm audit --audit-level=high` � pass for high/critical threshold; reports 3 moderate `qs`/`body-parser`/`express` advisories with no fix available.
  - `node --check public/todolist2.js` � pass.
  - `npm test -- tests/gemma-ui.test.js tests/edit-session.test.js` � pass, 31 tests.
  - `npm test` � pass, 358 tests.
  - `npm run lint` � blocked by pre-existing formatting warning in `prompts/gemma-classify-instructions.md`; touched files pass after formatting.
- Tests added/updated: Added source coverage for clean voice context paragraph composition, formatting-prefix stripping, and save-before-refine hotkey behavior.
- Regression impact: Shared voice transcript composition and inline edit AI shortcut flow were touched; focused UI/edit tests and full unit tests passed.
- API docs: Not affected; no HTTP route or request/response contract changed.
- Tooling gates: Audit threshold, syntax check, focused tests, and full unit tests passed; repo lint remains blocked only by the existing prompt formatting warning.
- Conflicts / exceptions: Lint exception is unrelated to this session and remains in `prompts/gemma-classify-instructions.md`.

### 2026-06-01T17:13:06Z � WorkLists

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
  - `npm audit --audit-level=high` � pass for high/critical threshold; reports 3 moderate `qs`/`body-parser`/`express` advisories with no fix available.
  - `node --check public/todolist2.js` � pass.
  - `node --check server.js` � pass.
  - `node --test tests/gemma-ui.test.js tests/gemma-normalize.test.js` � pass, 66 tests.
  - `npm test -- tests/gemma-ui.test.js tests/gemma-normalize.test.js` � pass, 66 tests.
  - `npm test` � pass, 358 tests.
  - `npm run lint` � blocked by pre-existing formatting warning in `prompts/gemma-classify-instructions.md`; touched files passed after formatting `tests/gemma-ui.test.js`.
- Tests added/updated: Added UI source coverage for direct timeout-based undo toasts, card replacement undo wiring, note refine undo toast emission, and server result coverage for previous card snapshots.
- Regression impact: AI job completion toast handling, card refine undo, and refine-card server result payloads were touched; focused AI tests and full unit tests passed.
- API docs: Not affected; existing `/api/gemma-normalize/jobs` response payloads were extended with undo metadata for UI recovery, but no new route or request contract was introduced.
- Tooling gates: Audit threshold, syntax checks, focused AI tests, and full unit tests passed; repo lint remains blocked only by the existing prompt formatting warning.
- Conflicts / exceptions: Lint exception is unrelated to this session and remains in `prompts/gemma-classify-instructions.md`.

### 2026-06-01T12:04:04-04:00 � WorkLists

- Summary: Restored reliable Escape-key dismissal for filters and notes context surfaces.
- Files/areas: `public/todolist2.js`, `tests/filter-menu.test.js`, `tests/context-windows.test.js`, `tests/browser-notes-smoke.js`, `docs/worklists/worklists-app-changelog.md`.
- User-visible impact:
  - Pressing plain `Escape` now closes the filters menu through a dedicated global context-surface dismissal handler.
  - Pressing plain `Escape` now closes the notes side pane even when focus is inside pane controls that could previously bypass the search shortcut listener.
  - App confirmation dialogs and active voice transcription keep priority so Escape can still cancel the dialog or stop transcription without also closing underlying context panes.
- Tests run:
  - `node --check public/todolist2.js` � pass.
  - `npm test -- tests/filter-menu.test.js tests/context-windows.test.js tests/search-shortcuts.test.js` � pass, 31 tests.
  - `npm test` � pass, 358 tests.
  - `npm run test:browser` � pass, 1 browser smoke test.
- Tests added/updated: Added regression coverage proving filters and notes close through the dedicated global Escape handler; extended the browser smoke test to press `Escape` against both the filters menu and notes pane.
- Regression impact: Global keyboard handling for context-window dismissal was touched; focused keyboard/context tests, full unit tests, and browser smoke passed.
- API docs: Not affected; no HTTP contract changed.
- Tooling gates: Focused tests, full unit tests, and browser smoke passed.
- Conflicts / exceptions: Existing notes discard confirmation behavior is preserved when closing the pane with unsaved drafts.

### 2026-05-31T17:19:31-04:00 � WorkLists

- Summary: Verified and tightened active-model usage for AI calls.
- Files/areas: `modelProviderClient.js`, `tests/gemma-normalize.test.js`, `tests/model-provider-client.test.js`, `docs/worklists/worklists-app-changelog.md`.
- User-visible impact:
  - Direct AI normalization and async AI jobs continue to resolve the active model from model settings before provider calls.
  - Async jobs record the active model id in job context when queued, so status responses expose which model was selected for the job.
  - Non-Google active models no longer silently fall back to `GEMINI_API_KEY` when no model-specific key or env var is configured.
- Tests run:
  - `node --check modelProviderClient.js` � pass.
  - `npm test -- tests/model-provider-client.test.js tests/gemma-normalize.test.js` � pass, 43 tests.
  - `npm test` � pass, 356 tests.
- Tests added/updated: Added coverage proving direct and async AI calls pass the active model id/api key into provider calls; added provider-key coverage preventing Gemini fallback for non-Google active models.
- Regression impact: Provider API-key resolution and AI model-selection tests were touched; focused backend/provider tests and full unit tests passed.
- API docs: Not affected; schemas did not change.
- Tooling gates: Focused tests and full unit tests passed.
- Conflicts / exceptions: Historical `Gemma` naming remains in routes/functions, but model selection is active-model driven.

### 2026-05-31T15:48:38-04:00 � WorkLists

- Summary: Added undo support for completed AI note refinement.
- Files/areas: `public/todolist2.js`, `tests/gemma-ui.test.js`, `docs/worklists/worklists-app-changelog.md`.
- User-visible impact:
  - Completed `refine-note` AI jobs now show an `Undo` toast action when the previous note text is available.
  - Undo restores the note through the existing notes API and refreshes the open notes pane when the restored note belongs to the active card.
  - AI note creation remains unchanged and does not show an undo refine action.
- Tests run:
  - `node --check public/todolist2.js` � pass.
  - `npm test -- tests/gemma-ui.test.js tests/context-windows.test.js` � pass, 38 tests.
  - `npm test` � pass, 353 tests.
- Tests added/updated: Added source coverage for AI note refine undo wiring, toast action creation, notes API restoration, and active-pane refresh.
- Regression impact: Note AI completion toast handling and note update API usage were touched; focused UI/context tests and full unit tests passed.
- API docs: Not affected; this uses the existing note update API.
- Tooling gates: Focused tests and full unit tests passed.
- Conflicts / exceptions: Card refine undo behavior was left unchanged.

### 2026-05-31T13:12:46-04:00 � WorkLists

- Summary: Tightened AI note generation so explicit Markdown lists are preserved as one note.
- Files/areas: `gemmaNormalize.js`, `server.js`, `tests/gemma-normalize.test.js`, `docs/worklists/worklists-app-changelog.md`.
- User-visible impact:
  - AI note creation/refinement now injects note-specific prompt constraints after the shared card instructions, telling the model to produce one complete note body and preserve every explicit list item/detail.
  - Notes force the classification directive back to one single-card-format object even if the classifier interprets a list as multiple cards.
  - Notes now extract the returned `cleaned_text` as one full note body instead of using the card task splitter, which was dropping markdown bullet content after the heading.
  - Card AI prompting and card task extraction were not changed.
- Tests run:
  - `node --check gemmaNormalize.js` � pass.
  - `node --check server.js` � pass.
  - `npm test -- tests/gemma-normalize.test.js` � pass, 40 tests.
  - `npm test` � pass, 352 tests.
- Tests added/updated: Added Alfredo-style recipe coverage proving a header plus explicit markdown bullets persists as one note, even when classification returns a multi-card count; added prompt coverage for note context injection.
- Regression impact: Note-only AI prompt/extraction logic and shared prompt option plumbing were touched; focused backend AI tests and full unit tests passed.
- API docs: Not affected; request/response schemas did not change.
- Tooling gates: Focused tests and full unit tests passed.
- Conflicts / exceptions: Existing card prompts and card extraction behavior were intentionally left unchanged.

### 2026-05-31T11:32:15-04:00 � WorkLists

- Summary: Added voice-to-text controls to note creation and note editing.
- Files/areas: `public/index.html`, `public/todolist2.js`, `public/todoliststyles2.css`, `tests/gemma-ui.test.js`, `docs/worklists/worklists-app-changelog.md`.
- User-visible impact:
  - The notes pane add-note composer now has a `Voice` action that uses the same browser speech recognition flow as card voice input.
  - Inline note editing now includes a compact `Voice` action so saved notes can be dictated or extended while editing.
  - Note voice controls can be pressed again to stop listening, and they use the same stop toast/Escape handling as card voice input.
  - Starting note AI create/refine now hard-stops any active voice transcription first so partial speech capture does not continue underneath model work.
  - Voice input normalizes the markdown editor back to Markdown mode before dictation, preserving current Visual-mode content and keeping the saved source coherent.
- Tests run:
  - `node --check public/todolist2.js` � pass.
  - `npm test -- tests/gemma-ui.test.js tests/markdown-editor.test.js tests/context-windows.test.js` � pass, 44 tests.
  - `npm test` � pass, 350 tests.
  - `npm run lint` � fails only on the existing `prompts/gemma-classify-instructions.md` Prettier warning.
- Tests added/updated: Added source coverage for note voice create/edit controls and for stopping active voice capture before note AI actions.
- Regression impact: Shared voice button state, notes editor controls, and note AI start paths were touched; focused UI/notes editor tests and full unit tests passed.
- API docs: Not affected; this is a client-side voice/editor integration.
- Tooling gates: Focused tests and full unit tests passed; lint still reports the known prompt formatting exception.
- Conflicts / exceptions: Voice support depends on browser speech recognition availability, matching existing card behavior.

### 2026-05-31T11:21:07-04:00 � WorkLists

- Summary: Added model-backed AI create/refine actions for notes.
- Files/areas: `server.js`, `openapi.js`, `public/index.html`, `public/todolist2.js`, `public/todoliststyles2.css`, `tests/gemma-normalize.test.js`, `tests/gemma-ui.test.js`, `tests/openapi.test.js`, `docs/worklists/worklists-app-changelog.md`.
- User-visible impact:
  - The notes pane add-note row now has an `AI note` action that sends the current note draft/instructions through the active AI model and creates a note on completion.
  - Each saved note now has a compact `Refine note with AI` action in the note controls.
  - Note AI jobs reuse the existing async job polling and progress toast flow, but new note-facing labels use generic `AI` naming instead of adding more model-specific Gemma copy.
  - Note AI create/refine actions disable their controls while work is in flight and refresh the active notes pane when the job completes.
- Tests run:
  - `node --check public/todolist2.js` � pass.
  - `node --check server.js` � pass.
  - `node --check openapi.js` � pass.
  - `npm test -- tests/gemma-normalize.test.js tests/gemma-ui.test.js` � pass, 60 tests.
  - `npm test -- tests/context-windows.test.js tests/markdown-editor.test.js` � pass, 20 tests.
  - `npm test -- tests/openapi.test.js tests/gemma-normalize.test.js tests/gemma-ui.test.js` � pass, 63 tests.
  - `npm test` � pass, 348 tests.
  - `npm run test:browser` � pass, 1 browser smoke test.
  - `npm run lint` � fails only on the existing `prompts/gemma-classify-instructions.md` Prettier warning.
- Tests added/updated: Added source coverage for generic AI note UI naming, pending-job tracking, note controls, and server job wiring; added persistence coverage for AI-created and AI-refined notes through the notes store; added OpenAPI coverage for note job request/status/result schemas.
- Regression impact: Shared AI/Gemma pending-job tracking, notes pane controls, and server job execution were touched; focused tests, full tests, and browser smoke passed.
- API docs: Updated OpenAPI job request/status/result schemas for the existing `/api/gemma-normalize/jobs` endpoint so `add-note` and `refine-note` are documented with note context and result payloads.
- Tooling gates: Full unit tests and browser smoke passed; lint still reports the known prompt formatting exception.
- Conflicts / exceptions: Existing card/task AI internals still use the historical `Gemma` function names; new note-facing UI copy is generic `AI` to reflect model-swappable behavior.

### 2026-05-31T11:12:49-04:00 � WorkLists

- Summary: Moved notes-pane draft discard prompts onto the in-app dialog flow and added AI notes parity to the initiative checklist.
- Files/areas: `docs/worklists/worklists-app-changelog.md`, `public/todolist2.js`, `tests/context-windows.test.js`.
- User-visible impact:
  - Discarding unsaved note, note-edit, or card-text drafts from the notes pane now uses the styled WorkLists confirmation dialog.
  - Notes-pane close, cancel, Escape, edit-switch, and card-switch guard paths now await the same dialog confirmation flow.
  - The initiative checklist now explicitly requires AI note creation and AI note refinement parity with card-level AI actions.
- Tests run:
  - `node --check public/todolist2.js` � pass.
  - `npm test -- tests/context-windows.test.js tests/card-actions.test.js tests/markdown-editor.test.js` � pass, 33 tests.
  - `npm test` � pass, 344 tests.
  - `npm run test:browser` � pass, 1 browser smoke test.
  - `npm run lint` � fails only on the existing `prompts/gemma-classify-instructions.md` Prettier warning.
- Tests added/updated: Updated context-window coverage for async discard prompts, in-app dialog usage, and async notes-pane close behavior.
- Regression impact: Notes-pane close/cancel/Escape/edit-switch timing was touched; focused tests, full tests, and browser smoke passed.
- API docs: Not relevant � no HTTP contract or OpenAPI surface changed.
- Tooling gates: Full unit tests and browser smoke passed; lint still reports the known prompt formatting exception.
- Conflicts / exceptions: Shared context-window closer remains synchronous for non-notes callers; it now safely fires the async notes close path without forcing a broad app-wide async refactor.

### 2026-05-31T11:07:28-04:00 � WorkLists

- Summary: Added the Countdowns-style in-app dialog helper and used it for note deletion confirmation.
- Files/areas: `public/dialogs.js`, `public/index.html`, `public/todolist2.js`, `public/todoliststyles2.css`, `tests/context-windows.test.js`.
- User-visible impact:
  - Deleting a note now opens a styled WorkLists modal confirmation instead of the native browser confirm.
  - The dialog supports Countdowns-parity cancel behavior through the backdrop and `Escape`.
  - The destructive confirm action uses a distinct danger style while preserving keyboard focus behavior.
- Tests run:
  - `npm test -- tests/context-windows.test.js tests/markdown-editor.test.js` � pass.
  - `npm test` � pass, 344 tests.
  - `npm run test:browser` � pass, 1 browser smoke test.
  - `npm run lint` � fails only on the existing `prompts/gemma-classify-instructions.md` Prettier warning.
- Tests added/updated: Updated context-window coverage for the dialog script order, dialog API, backdrop/Escape cancellation, and danger styling.
- Regression impact: Notes delete confirmation now matches the Countdowns app pattern without changing the notes pane layout or backend API.
- API docs: Not relevant � no HTTP contract or OpenAPI surface changed.
- Tooling gates: Full unit tests and browser smoke passed; lint still reports the known prompt formatting exception.
- Conflicts / exceptions: Draft-discard prompts still use the native sync confirm until the broader async context-window close flow is refactored.

### 2026-05-31T14:56:00Z � WorkLists

- Summary: Added a Playwright browser smoke test for the notes pane and card note indicators.
- Files/areas: `package.json`, `package-lock.json`, `tests/browser-notes-smoke.js`, `docs/worklists/worklists-app-changelog.md`.
- User-visible impact:
  - Added `npm run test:browser` for an isolated Chromium smoke pass against temporary WorkLists data.
  - The smoke test opens the real app, verifies the note-count indicator, opens the notes pane, edits the original card text, adds a note, and checks the pane remains inside desktop and mobile viewports.
  - Browser testing uses a temporary `DATA_DIR`, so it does not touch the user's real WorkLists data.
- Tests run:
  - `npm run test:browser` � pass, 1 browser smoke test.
  - `npm test` � pass, 343 tests.
  - `npx prettier --check package.json tests\browser-notes-smoke.js` � pass.
- Tests added/updated: Added `tests/browser-notes-smoke.js` and a `test:browser` package script.
- Regression impact: Browser smoke coverage now exercises the notes pane, note-count indicator, card text edit path, add-note path, and desktop/mobile viewport fit.
- API docs: Not relevant � no HTTP contract or OpenAPI surface changed.
- Tooling gates: Full `npm test` passed; browser smoke passed; targeted Prettier passed.
- Conflicts / exceptions: Installed Playwright as a dev dependency and downloaded Chromium locally for the browser run; worktree had many pre-existing dirty files before this session; no unrelated changes were reverted.

### 2026-05-31T14:39:37Z � WorkLists

- Summary: Added card-level notes count indicators.
- Files/areas: `public/todolist2.js`, `public/todoliststyles2.css`, `tests/card-actions.test.js`.
- User-visible impact:
  - Cards with notes now show a compact note-count pill in the card action row.
  - The note-count pill opens the notes pane for that card.
  - The card action menu now shows the note count beside `Edit Notes` when notes exist.
  - Counts are seeded from the existing `event-notes` data and refresh when the active notes pane reloads after create/delete.
- Tests run:
  - `node --check public\todolist2.js` � pass.
  - `node --test tests\card-actions.test.js tests\context-windows.test.js` � pass, 25 tests.
  - `npx prettier --check public\todolist2.js public\todoliststyles2.css tests\card-actions.test.js` � pass.
  - `npm test` � pass, 343 tests.
- Tests added/updated: Extended card action integration assertions for notes count state, card-level indicator rendering, menu status text, data seeding from `event-notes`, and indicator refresh after note loads.
- Regression impact: Card render/action row and card action state were touched; focused card/context tests and the full suite passed.
- API docs: Not relevant � reused existing notes data and APIs without changing HTTP contracts or OpenAPI.
- Tooling gates: Full `npm test` passed; targeted Prettier passed.
- Conflicts / exceptions: Worktree had many pre-existing dirty files before this session; no unrelated changes were reverted.

### 2026-05-31T13:27:05Z � WorkLists

- Summary: Added unsaved-change protection for notes pane editing surfaces.
- Files/areas: `public/todolist2.js`, `tests/context-windows.test.js`.
- User-visible impact:
  - Closing the notes pane now asks before discarding unsaved changes.
  - Canceling an edited card text, edited note, or draft note asks before throwing away changed text.
  - Starting another notes-pane edit checks for unsaved text in the other pane surfaces first.
  - Opening notes for another card now preserves the current pane when the user declines to discard unsaved changes.
- Tests run:
  - `node --check public\todolist2.js` � pass.
  - `node --test tests\context-windows.test.js tests\markdown-editor.test.js` � pass, 19 tests.
  - `npx prettier --check public\todolist2.js tests\context-windows.test.js` � pass.
  - `npm test` � pass, 342 tests.
- Tests added/updated: Extended context-window assertions for notes pane draft detection, discard confirmation, and guarded cancel/close/switch paths.
- Regression impact: Notes pane close, cancel, edit-switch, and open-card flows were touched; focused context/editor tests and the full suite passed.
- API docs: Not relevant � no HTTP contract or OpenAPI surface changed.
- Tooling gates: Full `npm test` passed; targeted Prettier passed.
- Conflicts / exceptions: Worktree had many pre-existing dirty files before this session; no unrelated changes were reverted.

### 2026-05-31T01:29:39Z � WorkLists

- Summary: Added in-pane editing for the original card text from the notes side pane.
- Files/areas: `public/todolist2.js`, `public/todoliststyles2.css`, `tests/context-windows.test.js`, `tests/markdown-editor.test.js`.
- User-visible impact:
  - The notes pane now shows a minimal `Card text` section above the notes list with an edit icon.
  - Users can edit the card's original text directly in the notes pane using the same Visual, Markdown, and Preview editor controls as notes.
  - Saving updates the card text through the existing todo API, refreshes the board, and updates the pane title/content without closing the pane.
  - The card text area has more room than the previous compact preview while keeping overflow contained inside the side pane.
- Tests run:
  - `node --check public\todolist2.js` � pass.
  - `node --test tests\context-windows.test.js tests\markdown-editor.test.js` � pass, 18 tests.
  - `npx prettier --check public\todolist2.js public\todoliststyles2.css tests\context-windows.test.js tests\markdown-editor.test.js` � pass.
  - `npm test` � pass, 341 tests.
- Tests added/updated: Extended notes pane context and markdown editor integration assertions for original card text editing, shared editor wiring, save behavior, accessible labels, and pane overflow sizing.
- Regression impact: Notes pane card preview/editing, task text persistence, and pane sizing were touched; focused context/editor tests and the full suite passed.
- API docs: Not relevant � reused the existing todo update API and did not change the HTTP contract or OpenAPI surface.
- Tooling gates: Full `npm test` passed; targeted Prettier passed.
- Conflicts / exceptions: Worktree had many pre-existing dirty files before this session; no unrelated changes were reverted.

### 2026-05-31T01:20:51Z � WorkLists

- Summary: Added a guarded delete path and accessible compact note actions for the notes pane.
- Files/areas: `public/todolist2.js`, `tests/context-windows.test.js`.
- User-visible impact:
  - Deleting a note from the side pane now asks for confirmation before removing it.
  - Compact edit and delete icon buttons now expose explicit accessible labels while retaining their visual layout.
- Tests run:
  - `node --check public\todolist2.js` � pass.
  - `node --test tests\context-windows.test.js` � pass, 10 tests.
  - `npx prettier --check public\todolist2.js tests\context-windows.test.js` � pass.
  - `npm test` � pass, 340 tests.
- Tests added/updated: Extended context-window assertions for note delete confirmation and accessible compact note actions.
- Regression impact: Notes pane delete clicks and note action markup were touched; focused context tests and the full suite passed.
- API docs: Not relevant � no HTTP contract or OpenAPI surface changed; existing `/api/notes` contract was unchanged.
- Tooling gates: Full `npm test` passed; targeted Prettier passed.
- Conflicts / exceptions: Worktree had many pre-existing dirty files before this session; no unrelated changes were reverted.

### 2026-05-31T01:18:20Z � WorkLists

- Summary: Improved notes pane accessibility and focus continuity.
- Files/areas: `public/index.html`, `public/todolist2.js`, `tests/context-windows.test.js`, `tests/card-actions.test.js`.
- User-visible impact:
  - The notes side pane now exposes dialog semantics with `aria-labelledby` tied to the pane title.
  - Opening notes from a card action records the triggering ellipsis button as the return-focus target.
  - Closing the notes pane restores focus to the opener when it still exists, keeping keyboard users oriented after the side pane closes.
- Tests run:
  - `node --check public\todolist2.js` � pass.
  - `node --test tests\context-windows.test.js tests\card-actions.test.js` � pass, 21 tests.
  - `npx prettier --check public\index.html public\todolist2.js tests\context-windows.test.js tests\card-actions.test.js` � pass.
  - `npm test` � pass, 339 tests.
- Tests added/updated: Extended context-window and card-action integration assertions for notes pane dialog semantics, opener tracking, and focus restoration.
- Regression impact: Notes pane close behavior and card action notes wiring were touched; focused context/card-action tests and the full suite passed.
- API docs: Not relevant � no HTTP contract or OpenAPI surface changed; existing `/api/notes` contract was unchanged.
- Tooling gates: Full `npm test` passed; targeted Prettier passed.
- Conflicts / exceptions: Worktree had many pre-existing dirty files before this session; no unrelated changes were reverted.

### 2026-05-31T01:14:44Z � WorkLists

- Summary: Added the notes initiative UI/UX checklist and polished notes pane controls/layout.
- Files/areas: `docs/worklists/worklists-app-changelog.md`, `public/markdownEditor.js`, `public/index.html`, `public/todolist2.js`, `public/todoliststyles2.css`, `tests/markdown-editor.test.js`.
- User-visible impact:
  - The notes initiative now has a standing checklist for viewport fit, overflow, wrapping, padding, scrolling, button placement, icon usage, keyboard behavior, and markdown rendering layout.
  - Add-note, save-note, and cancel-edit controls now use coherent icon+label button treatments with consistent sizing and focus/hover behavior.
  - Markdown toolbar commands use compact icons where familiar icons exist, while preserving text symbols for heading/bold/italic/quote.
  - Notes pane content now guards horizontal overflow across pane, cards, timestamps, editor surfaces, toolbar rows, markdown code blocks, tables, and narrow mobile widths.
- Tests run:
  - `node --check public\markdownEditor.js` � pass.
  - `node --check public\todolist2.js` � pass.
  - `node --test tests\markdown-editor.test.js tests\context-windows.test.js` � pass, 15 tests.
  - `npx prettier --check docs\worklists\worklists-app-changelog.md public\markdownEditor.js public\index.html public\todolist2.js public\todoliststyles2.css tests\markdown-editor.test.js tests\context-windows.test.js` � pass.
  - `npm test` � pass, 338 tests.
- Tests added/updated: Extended markdown editor tests for toolbar icon metadata and notes-pane layout/overflow/style guardrails.
- Regression impact: Notes pane layout, editor toolbar rendering, and note edit action markup were touched; focused editor/context tests and the full suite passed.
- API docs: Not relevant � no HTTP contract or OpenAPI surface changed; existing `/api/notes` contract was unchanged.
- Tooling gates: Full `npm test` passed; targeted Prettier passed.
- Conflicts / exceptions: Worktree had many pre-existing dirty files before this session; no unrelated changes were reverted.

### 2026-05-30T18:26:00Z � WorkLists

- Summary: Ported Countdowns-style markdown editor modes and toolbar controls into WorkLists notes.
- Files/areas: `public/markdownEditor.js`, `public/index.html`, `public/todolist2.js`, `public/todoliststyles2.css`, `tests/markdown-editor.test.js`, `tests/markdown-authoring.test.js`, `tests/context-windows.test.js`.
- User-visible impact:
  - The add-note editor now expands from the compact empty state into Visual, Markdown, and Preview modes.
  - Notes now have toolbar controls for headings, bold, italic, links, lists, quotes, inline code, code blocks, and tables.
  - Inline note edits use the same tabbed editor modes and toolbar controls as the add-note editor.
  - Visual and Preview modes use the existing WorkLists markdown renderer so authored notes stay aligned with card markdown behavior.
- Tests run:
  - `node --check public\markdownEditor.js` � pass.
  - `node --check public\todolist2.js` � pass.
  - `node --test tests\markdown-editor.test.js tests\markdown-authoring.test.js tests\context-windows.test.js` � pass, 20 tests.
  - `npx prettier --check public\markdownEditor.js public\index.html public\todolist2.js public\todoliststyles2.css tests\markdown-editor.test.js tests\markdown-authoring.test.js tests\context-windows.test.js` � pass.
  - `npm test` � pass, 336 tests.
- Tests added/updated: Added `tests/markdown-editor.test.js` for toolbar syntax helpers and notes editor integration; extended markdown authoring and context-window assertions for the new editor helper and keyboard paths.
- Regression impact: Shared notes pane editing behavior and script ordering were touched; focused editor/context tests and the full suite passed.
- API docs: Not relevant � no HTTP contract or OpenAPI surface changed; existing `/api/notes` contract was unchanged.
- Tooling gates: Full `npm test` passed; targeted Prettier passed.
- Conflicts / exceptions: Worktree had many pre-existing dirty files before this session; no unrelated changes were reverted.

### 2026-05-30T18:13:15Z � WorkLists

- Summary: Added persisted resizing for the notes side pane.
- Files/areas: `public/index.html`, `public/todolist2.js`, `public/todoliststyles2.css`, `tests/context-windows.test.js`.
- User-visible impact:
  - The notes pane now has a left-edge resize handle so users can widen or narrow the side popout.
  - The chosen pane width is saved in `localStorage` and restored when reopening the pane.
  - Width is clamped to sensible desktop and viewport bounds so the pane stays usable on smaller screens.
- Tests run:
  - `node --check public\todolist2.js` � pass.
  - `node --test tests\context-windows.test.js` � pass, 8 tests.
  - `npx prettier --check public\index.html public\todolist2.js public\todoliststyles2.css tests\context-windows.test.js` � pass.
  - `npm test` � pass, 331 tests.
- Tests added/updated: Extended context-window source/CSS assertions to cover the notes pane resize handle, persisted width key, pointer drag behavior, and resizing styles.
- Regression impact: Notes pane layout and window resize behavior were touched; focused context tests and the full suite passed.
- API docs: Not relevant � no HTTP contract or OpenAPI surface changed.
- Tooling gates: Full `npm test` passed; targeted Prettier passed.
- Conflicts / exceptions: Worktree had many pre-existing dirty files before this session; no unrelated changes were reverted.

### 2026-05-30T18:00:06Z � WorkLists

- Summary: Added lifecycle cleanup for notes associated to deleted cards.
- Files/areas: `dal.js`, `tests/api.test.js`.
- User-visible impact:
  - Notes tied to a card are now removed when that card is deleted directly.
  - Notes tied to cards removed by deleting a column or board are now removed with the same cascade.
  - Notes associated to unrelated card IDs are preserved.
- Tests run:
  - `node --check dal.js` � pass.
  - `node --test tests\api.test.js` � pass, 67 tests.
  - `npx prettier --check dal.js tests/api.test.js` � pass.
  - `npm test` � pass, 330 tests.
  - `npm run lint` � blocked: repo-wide Prettier check still reports pre-existing formatting in `prompts/gemma-classify-instructions.md`; touched notes cleanup files passed targeted Prettier check.
- Tests added/updated: Extended delete board/column/todo API assertions to verify associated notes are removed and unrelated notes remain.
- Regression impact: Delete cascades were touched; focused API tests and the full suite passed.
- API docs: Not relevant � no HTTP contract or OpenAPI surface changed.
- Tooling gates: Full `npm test` passed; full `npm run lint` remains blocked by the pre-existing `prompts/gemma-classify-instructions.md` formatting warning.
- Conflicts / exceptions: Worktree had many pre-existing dirty files before this session; no unrelated changes were reverted.

### 2026-05-30T17:46:35Z � WorkLists

- Summary: Improved notes pane keyboard and markdown authoring interactions.
- Files/areas: `public/todolist2.js`, `tests/markdown-authoring.test.js`, `tests/context-windows.test.js`.
- User-visible impact:
  - The add-note textarea and inline note edit textarea now use the existing markdown list authoring behavior.
  - `Ctrl+Enter` submits a new note or saves an inline note edit.
  - `Escape` clears a draft note with text or cancels an inline note edit without collapsing the notes pane.
- Tests run:
  - `node --check public\todolist2.js` � pass.
  - `node --test tests\markdown-authoring.test.js tests\context-windows.test.js` � pass, 14 tests.
  - `npx prettier --check public/todolist2.js tests/markdown-authoring.test.js tests/context-windows.test.js` � pass.
  - `npm test` � pass, 330 tests.
  - `npm run lint` � blocked: repo-wide Prettier check still reports pre-existing formatting in `prompts/gemma-classify-instructions.md`; touched notes interaction files passed targeted Prettier check.
- Tests added/updated: Extended markdown authoring integration assertions for notes textareas and context-window assertions for note pane keyboard containment.
- Regression impact: Shared keyboard/context behavior was touched; focused context/markdown tests and the full suite passed.
- API docs: Not relevant � no HTTP contract or OpenAPI surface changed.
- Tooling gates: Full `npm test` passed; full `npm run lint` remains blocked by the pre-existing `prompts/gemma-classify-instructions.md` formatting warning.
- Conflicts / exceptions: Worktree had many pre-existing dirty files before this session; no unrelated changes were reverted.

### 2026-05-30T17:35:25Z � WorkLists

- Summary: Added the first UI integration for notes by wiring card actions to a notes side popout.
- Files/areas: `public/apiService.js`, `public/cardActions.js`, `public/index.html`, `public/todolist2.js`, `public/todoliststyles2.css`, `tests/api-client-resilience.test.js`, `tests/card-actions.test.js`, `tests/context-windows.test.js`.
- User-visible impact:
  - Card ellipsis menus now include `Edit Notes`.
  - Selecting `Edit Notes` opens a right-side notes pane for the card, loads existing notes through `/api/notes?eventId=<cardId>`, renders note content with existing markdown rendering, and supports add/edit/delete note flows.
  - The notes pane participates in the shared context-window close behavior and can be closed with its header close button or the existing Escape context close path.
- Tests run:
  - `node --check public\apiService.js`, `node --check public\cardActions.js`, `node --check public\todolist2.js` � pass.
  - `node --test tests\card-actions.test.js tests\context-windows.test.js tests\api-client-resilience.test.js` � pass, 25 tests.
  - `npx prettier --check public/apiService.js public/cardActions.js public/todolist2.js public/todoliststyles2.css public/index.html tests/card-actions.test.js tests/context-windows.test.js tests/api-client-resilience.test.js` � pass.
  - `npm test` � pass, 329 tests.
  - `npm run lint` � blocked: repo-wide Prettier check still reports pre-existing formatting in `prompts/gemma-classify-instructions.md`; notes UI files passed targeted Prettier check.
- Tests added/updated: Added card action coverage for `Edit Notes`, context-pane source/CSS assertions, and API client notes helper assertions.
- Regression impact: Shared card action and context close surfaces were touched; focused card action/context tests and the full suite passed.
- API docs: Not relevant for this UI/client slice; the `/api/notes` OpenAPI contract was already added in the prior backend slice and was not changed here.
- Tooling gates: Full `npm test` passed; full `npm run lint` remains blocked by the pre-existing `prompts/gemma-classify-instructions.md` formatting warning.
- Conflicts / exceptions: Worktree had many pre-existing dirty files before this session; no unrelated changes were reverted.

### 2026-05-30T16:34:36Z � WorkLists

- Summary: Ported the Countdowns notes API into WorkLists as the first backend step for card notes.
- Files/areas: `dal.js`, `server.js`, `openapi.js`, `data/event-notes.json`, `data/event-notes.example.json`, `tests/api.test.js`, `tests/openapi.test.js`.
- User-visible impact:
  - WorkLists now exposes the Countdowns-compatible `/api/notes` API for listing, filtering by `eventId`, creating, updating, and deleting notes.
  - Notes persist to `data/event-notes.json` with `noteId`, `eventId`, `text`, and `createdAt`.
- Tests run:
  - `node --check server.js`, `node --check dal.js`, `node --check openapi.js` � pass.
  - `node --test tests\api.test.js tests\openapi.test.js` � pass, 70 tests.
  - `npx prettier --check dal.js server.js openapi.js tests/api.test.js tests/openapi.test.js data/event-notes.json data/event-notes.example.json` � pass.
  - `npm test` � pass, 326 tests.
  - `npm run lint` � blocked: repo-wide Prettier check still reports pre-existing formatting in `prompts/gemma-classify-instructions.md`; notes API files passed targeted Prettier check.
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
- API docs check: Updated � added `/scheduler` GET/PUT, scheduler request/response schemas, and `schedulerTaskIds` on the shared `DataStore` schema.
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
- API docs check: N/A � reused existing `PATCH /todos/:id` task update contract; no new HTTP/OpenAPI surface.
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
- API docs check: Updated � added Gemma tag context/decision/result schemas, documented tagging on normalize responses and job results, and added `tagContext` to normalize job request bodies.
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
- API docs check: N/A � UI behavior change only; no HTTP/OpenAPI surface change.
- Verification:
  - `node --test tests/column-sort.test.js tests/column-actions.test.js` (pass).

### 2026-05-26

- Summary: Added structured voice-to-text diagnostics for permission checks, start/stop lifecycle, recognition errors, and unexpected stop conditions.
- Files/areas: `public/todolist2.js`.
- User-visible impact:
  - Voice capture now reports specific failure reasons (for example `no-speech`, `audio-capture`, `network`, and permission blocks) instead of only generic failure messaging.
  - When listening starts and then ends without transcript capture, the app now surfaces a clearer stop toast and emits detailed diagnostic context.
  - Browser diagnostics are now available as `[VoiceInput]` console entries and in-memory `window.__voiceInputDiagnostics` logs.
- API docs check: N/A � browser-side diagnostics only; no HTTP/OpenAPI contract change.
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
- API docs check: N/A � no new endpoint or schema change in this follow-up fix.
- Verification:
  - `npm test -- tests/gemma-normalize.test.js` (pass).
  - `npm test -- tests/openapi.test.js` (pass).
  - `npm run lint` (fails due pre-existing formatting issue in `prompts/gemma-classify-instructions.md`, unrelated to this session�s code changes).

### 2026-05-26

- Summary: Added a standardized Gemma final-review payload so parsed responses always resolve to either updated output or the original output fallback.
- Files/areas: `server.js`, `openapi.js`, `tests/gemma-normalize.test.js`.
- User-visible impact:
  - `POST /api/gemma-normalize` now returns `finalReview` with a resolved `output`, `originalOutput`, `updatedOutput`, and fallback flags.
  - Completed `refine-card` job results now include a standardized `finalReview` payload even when the underlying job executor returns legacy fields.
  - Refine multi-card replacements now carry `createdTaskTexts` so final-review output can represent updated multi-output cases.
- API docs check: Updated � added `GemmaFinalReviewPayload`, documented `finalReview` on direct normalize responses and refine job results, and aligned refine-result required fields with replacement scenarios where `nextText` can be absent.
- Verification:
  - `npm test -- tests/gemma-normalize.test.js` (pass).
  - `npm test -- tests/openapi.test.js` (pass).
  - `npm run lint` (fails due pre-existing formatting issue in `prompts/gemma-classify-instructions.md`, unrelated to this session�s code changes).

### 2026-05-26

- Summary: Implemented persistent server-backed pinned-board storage for top toolbar pins, added pinned-board sync APIs, and wired frontend pin/unpin/reorder flows to synchronize across devices with local fallback bootstrap.
- Files/areas: `dal.js`, `server.js`, `openapi.js`, `public/apiService.js`, `public/todolist2.js`, `tests/api.test.js`, `tests/openapi.test.js`, `tests/pinned-board-sync.test.js`.
- User-visible impact:
  - Top toolbar pinned boards now persist in shared server storage instead of device-local-only storage.
  - Pin, unpin, and pinned-order changes now sync to the server so they appear consistently across devices connected to the same WorkLists backend.
  - Existing local pinned boards automatically bootstrap to server storage when server-side pinned state is empty.
  - Invalid/stale pinned IDs are normalized and filtered against existing boards during sync.
- API docs check: Updated � added `/boards/pinned` GET/PUT, new pinned-board request/response schemas, and expanded `DataStore` schema with `pinnedBoardIds`.
- Verification:
  - `node --test tests/api.test.js tests/openapi.test.js tests/pinned-board-sync.test.js` (pass).
  - `npm run lint` (fails due pre-existing formatting issue in `prompts/gemma-classify-instructions.md`, unrelated to this session�s code changes).
  - `npm test` (fails in pre-existing `tests/gemma-normalize.test.js` model expectation mismatch, unrelated to this session�s pinned-board sync changes).

### 2026-05-26

- Summary: Simplified search filters by removing scope toggles (`Tags`, `Completion`, `Card contents`, `Column titles`) and keeping only `Current board only`; search now ignores tag metadata and only matches card text/column titles.
- Files/areas: `public/index.html`, `public/todolist2.js`, `public/todoliststyles2.css`, `tests/filter-menu.test.js`, `tests/search-scopes.test.js`.
- User-visible impact:
  - Search filter controls no longer show `All`/`Clear` or scope checkboxes.
  - `Search filters` section now only contains `Current board only`.
  - Typing a tag name in search no longer matches cards by tag assignment; tag filtering now occurs only through the color/secondary tag filter sections.
  - `Show completed`, color tag filters, and secondary tag filters remain unchanged.
- API docs check: N/A � UI/search behavior only; no HTTP or OpenAPI contract changes.
- Verification:
  - `node --test tests/filter-menu.test.js tests/search-scopes.test.js tests/secondary-tags.test.js tests/context-windows.test.js` (pass).
  - `npm run lint` (fails due pre-existing formatting issue in `prompts/gemma-classify-instructions.md`, unrelated to this session�s code changes).

### 2026-05-26

- Summary: Consolidated tag/completion filtering into the existing top-right `Filters` dropdown so search scope and tag filters share one multi-section menu.
- Files/areas: `public/index.html`, `public/todoliststyles2.css`, `public/todolist2.js`, `tests/filter-menu.test.js`.
- User-visible impact:
  - The separate tag filter trigger/menu was removed from the top nav.
  - The existing `Filters` dropdown now contains multiple sections: search filters, completion toggle, color tag filters, and secondary tag filters.
  - `Select all` / `Clear all` actions for color and secondary tags remain available inside this consolidated menu.
- API docs check: N/A � UI-only menu/layout consolidation; no HTTP or OpenAPI contract changes.
- Verification:
  - `node --test tests/filter-menu.test.js tests/search-scopes.test.js tests/secondary-tags.test.js tests/context-windows.test.js` (pass).
  - `npm run lint` (fails due pre-existing formatting issue in `prompts/gemma-classify-instructions.md`, unrelated to this session�s code changes).

### 2026-05-26

- Summary: Moved card filtering to a top-nav dropdown, added secondary-tag filtering with `Select all`/`Clear all`, and removed the legacy bottom-right filter UI.
- Files/areas: `public/index.html`, `public/todoliststyles2.css`, `public/todolist2.js`, `tests/filter-menu.test.js`, `tests/secondary-tags.test.js`.
- User-visible impact:
  - Filter controls now live in the top-right navigation area as a context-style dropdown.
  - The filter menu now includes both color-tag and secondary-tag sections with independent multi-select checkboxes.
  - Each tag section includes `Select all` and `Clear all` actions for faster filtering workflows.
  - Legacy fixed bottom-right filter controls were removed.
- API docs check: N/A � UI-only filtering/menu updates; no HTTP or OpenAPI contract changes.
- Verification:
  - `node --test tests/filter-menu.test.js tests/secondary-tags.test.js tests/context-windows.test.js` (pass).
  - `npm run lint` (fails due pre-existing formatting issue in `prompts/gemma-classify-instructions.md`, unrelated to this session�s code changes).
  - `npm test` (fails in pre-existing `tests/gemma-normalize.test.js` model expectation, unrelated to this session�s filter changes).

### 2026-05-25

- Summary: Added provider-switchable model management with persistent storage, new model CRUD/activate APIs, and a side-panel settings experience for viewing/adding/editing/deleting active normalization models.
- Files/areas: `dal.js`, `server.js`, `modelProviderClient.js`, `gemmaNormalize.js`, `openapi.js`, `public/index.html`, `public/apiService.js`, `public/todolist2.js`, `public/todoliststyles2.css`, `data/models.json`, `data/models.example.json`, `tests/api.test.js`, `tests/gemma-normalize.test.js`, `tests/gemma-ui.test.js`, `tests/openapi.test.js`.
- User-visible impact:
  - Side panel now includes `Model settings` below `Create board`.
  - Users can view configured models, add new models, edit model metadata, delete models, and activate a model from the new settings dialog.
  - Normalization and background normalize jobs now run against the active model configuration rather than a hardcoded model.
  - Provider adapter support now includes `google-genai` and `openai-compatible`, with schema paths prepared for additional providers.
- API docs check: Updated � added `/api/models`, `/api/models/{modelId}`, `/api/models/{modelId}/activate`, expanded normalization response schemas with model metadata, and updated `DataStore` schema to include `models`.
- Verification:
  - `npm test` (pass).
  - `npm run lint` (fails due pre-existing formatting issue in `prompts/gemma-classify-instructions.md`, unrelated to this session�s code changes).

### 2026-05-25

- Summary: Tightened column action menu edge awareness by adding right-edge left-shift behavior for the root menu and viewport-clamped fixed positioning for the Sort submenu.
- Files/areas: `public/columnActions.js`, `public/todoliststyles2.css`, `tests/column-actions.test.js`.
- User-visible impact:
  - Column context menu now shifts left of the trigger near the right screen edge instead of clipping off-screen.
  - Sort submenu now repositions leftward when needed and clamps within viewport boundaries (including bottom edge).
  - Root column menu width is reduced while keeping long sort labels in the wider submenu.
- API docs check: N/A � UI behavior and styling only; no HTTP/OpenAPI contract change.
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
- API docs check: N/A � UI behavior and styling only; no HTTP/OpenAPI contract change.
- Verification:
  - `npm test` (pass).

### 2026-05-24

- Summary: Centralized all Gemma response-shaping prompt instructions into `prompts/gemma-normalize-instructions.md` and removed in-code prompt/schema instruction injection.
- Files/areas: `prompts/gemma-normalize-instructions.md`, `gemmaNormalize.js`, `tests/gemma-normalize.test.js`.
- User-visible impact:
  - Gemma normalization behavior is now driven by a single editable prompt file without additional in-code schema/system prompt instructions.
  - Missing/empty Gemma prompt instruction files now return a clear configuration error instead of silently falling back to hardcoded instructions.
- API docs check: N/A � no HTTP surface change.
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
- API docs check: Updated � documented `504` for `/api/gemma-normalize`, optional `verbatimCandidates` in Gemma add-task job start payload, and expanded add-task failure item fields (`candidateIndex`, `verbatimInput`).
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
- API docs check: N/A � UI-only toast behavior; no HTTP or OpenAPI contract change.
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
- API docs check: Updated � added documented Gemma background job endpoints and schemas (`/api/gemma-normalize/jobs`, `/api/gemma-normalize/jobs/{jobId}`).
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
- API docs check: N/A � no HTTP or OpenAPI contract change.
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
- API docs check: N/A � no HTTP or OpenAPI contract change.
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
- API docs check: N/A � no HTTP or OpenAPI contract change.
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

- Boards, columns, todos, notes, and secondary tags now carry `lastModified` metadata through read/write and mutation paths; OpenAPI documents the field for future display/sync use.

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

