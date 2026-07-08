# Story 4: Card placement and full card parity

- **Epic:** [002-topology-view-epic.md](./002-topology-view-epic.md) — read it first; it owns all design decisions, the schema, and vocabulary.
- **Depends on:** Story 3 (nodes and wires).
- **Codebase:** `c:\Users\dustin.thomason\OneDrive\SCRIPTS ALL SYSTEMS\To Do List\WorkLists`

## Product story

As a canvas author, I drag a card out of a staging column and drop it loose on the canvas, onto a node, or onto a specific group — and that single gesture **is** the act of authoring the association (epic decision 5). Placed cards keep the full behavior of board cards, and my spatial statements outlive board workflow churn (epic decision 7).

This story is the heart of the feature: after it ships, the core authoring loop exists end-to-end.

## Scope

| In scope | Out of scope |
|---|---|
| Drag from staging → floating / node default queue / named group | Queue counts, highlight, completed toggle (story 5) |
| Rendering placed cards (floating + docked mini-columns) | Broken-reference rendering (story 5) |
| Move semantics on-canvas (float↔dock↔group, reorder in queue) | Node notes (story 6) |
| Un-place (return card to staging) | Any change to Kanban-view behavior |
| Full card parity on staged AND placed cards | New wire/node behavior |
| Placement survival of board column moves (live derive) | |

## Design

**The staged/placed partition (the load-bearing rule, epic §2):** when rendering staging strips, a card whose todo has a placement record for this canvas is **omitted from the staging column**; it renders at its placement instead. Everything else in staging mirrors live board state (story 2). The user-facing inference — *not in a column ⇒ placed* — must hold exactly.

**Drag out of staging:** cards in staging columns become draggable into the world (this supersedes story 2's drag-inert cards). Drop targets, in hit-priority order: a group section → docked to that group; a node (anywhere else on it) → docked to the default queue; empty canvas → floating at drop point. Creates the placement via `POST /canvases/:canvasId/placements` with the todo's **current live `columnId`** as the path provenance (epic §5). Zoom compensation per epic §6.

**Docked queues:** group sections and the default-queue section from story 3 now render their docked cards as scrollable mini-columns (max-height + `overflow-y: auto`), ordered by `paths[0].order`, styled like board columns' card stacks — same card DOM, narrower container. Reordering within a queue and moving between queues uses the same drag mechanics as board columns (jQuery UI `.sortable()` with `connectWith` is the established pattern — ~13 call sites in `todolist2.js` to crib from), persisted via `PUT /canvas-placements/:placementId`.

**Move semantics (epic decision 6):** dragging a placed card anywhere on the same canvas is a **move** — one placement record updated, never duplicated. Floating→node docks it; docked→empty floats it; docked→other node/group redocks it.

**Un-place:** card menu gets a canvas-only action "Return to column" → `DELETE /canvas-placements/:placementId` → card reappears in its live column's staging strip on re-render. (Dragging a card back onto a staging strip may also un-place; implement if it falls out naturally, but the menu action is the required path.)

**Full card parity (epic decision 8):** staged and placed cards are built with `createTask()` (`public/todolist2.js:12591` — signature `(id, content, completed, completedDate, creationTimestamp, columnId, tag, secondaryTagIds, status)`), passing the todo's **live** field values. All existing card behaviors (status dropdown, complete, edit, menus, note icon) must function in the canvas view. Expect and fix context assumptions in card handlers (e.g. handlers that locate the card's column DOM or call board-only re-render paths); the acceptance is behavioral, not "it renders."

**Placement survives workflow (epic decision 7):** the placement record is keyed by todo and is **not** touched when the todo's `columnId` changes on the board. On each render, card chips (status, tag, completed) come from the live todo. **Never write to the data layer during render** — the stored provenance `columnId` is updated only when the user next moves that placement (piggybacked on the user-initiated `PUT`), not by render-time reconciliation.

**Card creation on canvas:** N/A — cards are created on boards and arrive via staging (epic decision 4). No "new card" affordance in the canvas view in V1.

## Touched files

`public/canvasView.js`, `public/todolist2.js` (card-handler context fixes where needed), `public/todoliststyles2.css` (floating card, mini-columns), `public/apiService.js` (methods exist from story 1), tests under `tests/`.

## Tests

- Partition: given a snapshot + placements, the staging renderer omits exactly the placed todos (pure-function test on the partition helper).
- Live derive: a placement whose todo moved columns renders the new column/status chips while position is unchanged (pure-function test on the card-view-model helper).
- Move semantics: float→dock→group→float transitions each update the single placement record correctly (handler-level, mock ApiService).
- Provenance rule: render path performs zero writes (assert no ApiService mutation calls during a render pass).

## Done-when (falsifiable)

1. Drag a real card from staging onto empty canvas → it floats there and is gone from its staging column; reload — still true.
2. Drag it onto a node's "backend" group → it appears in that group's mini-column with correct styling; drag it to the default queue, reorder it among others; reload persists all of it.
3. On the Kanban view (other window), move that todo to another column and change its status → on the canvas after one refresh: same spot, updated status chip, still absent from BOTH old and new staging columns.
4. Change its status from the canvas card's dropdown → the Kanban view reflects it after refresh (same write path).
5. "Return to column" puts it back in its **live** column's staging strip.
6. Edit text, complete/uncomplete, and open notes on both a staged and a placed card — all behave as on the board.
7. `npm test` green.

## N/A sections

- **New API/schema** — N/A, story 1 shipped them (this story only consumes).
