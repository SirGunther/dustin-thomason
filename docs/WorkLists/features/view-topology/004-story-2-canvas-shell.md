# Story 2: Canvas view shell — entry, pan/zoom, staging strips

- **Epic:** [002-topology-view-epic.md](./002-topology-view-epic.md) — read it first; it owns all design decisions, the schema, and vocabulary.
- **Depends on:** Story 1 (data model + API).
- **Codebase:** `c:\Users\dustin.thomason\OneDrive\SCRIPTS ALL SYSTEMS\To Do List\WorkLists`

## Product story

As a board user, I can create a named canvas, attach boards to it, open it from the side panel, and see a zoomable surface where each attached board's columns appear exactly like the Kanban board I already know — so the canvas is familiar on first open and every ticket is already "in the tray" with zero add-steps.

## Scope

| In scope | Out of scope |
|---|---|
| CANVASES side-panel section (list/create/rename/delete/open) | Nodes, wires (story 3) |
| Attach/detach boards UI on the canvas | Dragging cards out of staging (story 4) |
| View-mode branch + enter/exit | Column highlight, completed toggle, visible-fail rendering (story 5) |
| Pan/zoom container | Notes (story 6) |
| Staging strips rendering attached boards' live columns/cards | Any canvas-data writes besides canvas CRUD/attach |
| Background-refresh integration for the canvas view | |

## Design

**View mode (follow the scheduler precedent exactly):**
- Module-level `canvasViewActive` flag + `currentCanvasId` (scheduler reference: `schedulerWorkspaceActive` at `public/todolist2.js:91`).
- Branch in `updateAndRenderUI()` (`public/todolist2.js:19792`): when active, call `renderCanvasView()` instead of `renderBoard()`.
- `renderCanvasView()` renders into `#board`, adds an `is-canvas-view` class (see how `renderSchedulerWorkspace()` at line 11422 adds `is-scheduler-workspace`, and how `renderBoard()` removes it at ~17590 — remove `is-canvas-view` there too).
- Exiting the canvas returns to the previously-open board. Persist `currentCanvasId` in `sessionStorage` alongside the existing `currentBoardId` convention (`public/todolist2.js:47`).

**Side panel:** a CANVASES section mirroring the boards list markup/behavior (`#side-panel-board-list` as reference). Create prompts for a title; open sets the flag and renders; rename/delete via the same interaction patterns boards use. Delete confirms (cascade warning: nodes/wires/placements go with it).

**Attach boards:** on-canvas control listing attached boards with add/remove (add = pick from existing boards). Writes via story 1's `PUT /canvases/:canvasId` (`boardIds`).

**Pan/zoom container:** inside `#board`, one `.canvas-viewport` element whose child `.canvas-world` gets `transform: translate(panX, panY) scale(zoom)`. Wheel/pinch zooms about the cursor; drag on empty surface pans; zoom clamped (suggest 0.25–2.0). Viewport state lives in memory + `sessionStorage` per canvas — **not** in the data layer. Expose `CanvasView.getZoom()` (or equivalent) — story 3/4 drag code must divide pointer deltas by it (epic §6 gotcha).

**Staging strips:** for each attached board in `boardIds` order, render a strip inside the world: board title header + that board's columns with cards, sourced from `BoardData.getCurrentBoardData(fullBoardDataSnapshot, boardId)` (`public/boardData.js:81`) — do not reimplement the slice. Cards render via `createTask()` (`public/todolist2.js:12591`) so they look and act like board cards (full parity hardening is story 4; in this story cards render but may remain drag-inert). Strips are collapsible per board (collapsed state in `sessionStorage`).

In this story **all cards are staged** (placements exist in data but nothing renders them yet — story 4 note: until then, a placed card would appear in staging; acceptable, since placements can't be created through the UI before story 4).

**Background refresh:** the refresh loop (`setInterval` near `public/todolist2.js:1240`) must work while the canvas view is active: when `canvasViewActive`, the newer-data check must consider (a) the entities of **all attached boards** (reuse `BoardData.getRelevantBoardRefreshEntities` per attached board id, `public/boardData.js:38`) and (b) the four canvas sections. On newer data, re-render the canvas view preserving pan/zoom and scroll. A card created on a board in another window must appear in staging within one refresh interval.

## Touched files

`public/todolist2.js` (flag, branch, render, side panel), `public/boardData.js` (refresh relevance extension), new `public/canvasView.js` (recommended — follow the `scheduler.js` companion-module pattern rather than growing todolist2.js), `public/apiService.js` (already has methods from story 1), `public/index.html` (script tag), `public/todoliststyles2.css` (`.is-canvas-view`, viewport/world, strips), tests under `tests/`.

## Tests

- Refresh relevance: unit-test the extended relevance function — a todo change on an attached board flags newer data for the canvas; a change on an unattached board does not; a canvas-section change flags it.
- View branch: `updateAndRenderUI` routes to canvas render when the flag is set (match the style of existing UI tests, e.g. `tests/column-move-ui.test.js`).
- Canvas CRUD UI wiring can be covered by the existing Playwright smoke-test pattern if present for boards; otherwise test the underlying handlers.

## Done-when (falsifiable)

1. From the side panel: create canvas "Test topology", attach two real boards, open it — both boards' columns render with their live cards, looking like the Kanban board.
2. Wheel-zoom and drag-pan work; zoom about cursor; reload restores the same canvas via sessionStorage.
3. In a second browser window, add a card to an attached board on the Kanban view; within one refresh interval it appears in the canvas staging strip without user action.
4. Exit returns to the previously open board; `is-canvas-view` class is gone; the Kanban board renders normally.
5. `npm test` green.

## N/A sections

- **New data sections / API** — N/A, story 1 shipped them.
- **Schema changes** — N/A.
