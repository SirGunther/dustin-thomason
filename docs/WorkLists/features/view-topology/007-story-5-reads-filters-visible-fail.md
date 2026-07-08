# Story 5: Reads, filters, and visible-fail rendering

- **Epic:** [002-topology-view-epic.md](./002-topology-view-epic.md) — read it first; it owns all design decisions, the schema, and vocabulary.
- **Depends on:** Story 4 (card placement).
- **Codebase:** `c:\Users\dustin.thomason\OneDrive\SCRIPTS ALL SYSTEMS\To Do List\WorkLists`

## Product story

As a dev planning without the architecture-holder, I can read the topology at a glance — which node has the biggest pile, split by group — find where a column's cards went, hide finished work, and **trust** the drawing because anything broken announces itself instead of showing plausibly-stale state (epic decision 13; investigation visible-fail criterion).

## Scope

| In scope | Out of scope |
|---|---|
| Queue counts per group + per node | Any computed topology (fan-out math, path depth, gating) — epic decision 1: reads are visual |
| Column highlight toggle | Clustering/auto-layout (epic non-goal) |
| Canvas-level completed toggle (persisted `showCompleted`) | New failure *data* rules (story 1 owns them) |
| Broken-reference card rendering | Search integration |
| Missing-board error strip | |

## Design

**Queue counts:** each group header (and the default-queue header) shows its docked-card count; the node header shows the total. Counts are counts of **distinct visible cards** (post completed-filter), computed at render from placements — never persisted (epic §5 "derived at render").

**Column highlight (epic decision 11):** each staging column header gets a highlight toggle. When on, every placed card on the canvas whose **live** `todo.columnId` matches that column gets a highlight treatment (glow/outline; also highlight the containing node section so docked matches are findable when a queue is scrolled/collapsed). Multiple columns can be highlighted at once (distinct treatments not required — one highlight style is fine). Toggle state is per-session, not persisted.

**Completed toggle (epic decision 12):** a canvas-toolbar control bound to the persisted `canvases.showCompleted` (write via `PUT /canvases/:canvasId`). When off: completed cards are hidden in staging strips **and** in placements (a floating completed card disappears; queue counts shrink). When on: completed cards render with the board's existing completed styling. This is the "body of work chewed through" read from the investigation (validation-plan step 5).

**Broken-reference card (epic decision 13):** at render, any placement whose `todoId` is absent from the snapshot renders as a broken-reference card in its recorded spot (floating x/y or its queue): unmistakable error styling (distinct from every normal card state), showing the raw `todoId`, stored provenance `columnId` (with column title if it still resolves), and a remove action (`DELETE /canvas-placements/:placementId`). It must never render a status chip, never be silently skipped, and must be excluded from queue counts' "work" reading only by being visually distinct — it still occupies its spot until removed. The completed filter never hides it.

**Missing-board error strip (epic decision 13):** an attached `boardId` that doesn't resolve renders an error strip in the staging area — "Attached board not found: <id>" — with a detach action. Never silently dropped from the strip sequence.

**Placement-drift guard (investigation negative path):** no automation — but note in UI copy or docs that staging IS the drift detector: cards still sitting in staging columns are, by definition, the not-yet-placed backlog of the drawing. No code beyond what exists.

## Touched files

`public/canvasView.js`, `public/todoliststyles2.css` (counts, highlight, broken card, error strip, completed-in-canvas), `public/apiService.js` (existing methods), tests under `tests/`.

## Tests

- Counts: given placements + a completed filter state, group/node counts equal distinct visible cards (pure-function).
- Highlight: match set = placed todos whose live `columnId` equals the toggled column — stored provenance must NOT be used (pure-function; this is the regression trap).
- Broken reference: a placement with an unresolvable todo yields a broken-card view-model — flagged, no status, not dropped (pure-function).
- Completed toggle: hides/shows in both staging and placements; `showCompleted` round-trips through the API.
- Missing board: unresolvable boardId yields an error-strip entry in the staging sequence, not an omission.

## Done-when (falsifiable)

1. A node with 3 cards in "backend", 1 in "UI bugs", 2 in default shows counts 3 / 1 / 2 and node total 6; completing one backend card with the completed toggle off changes it to 2 / 1 / 2, total 5.
2. Toggling highlight on a staging column lights up exactly the placed cards that live in that column on the board right now — including one docked inside a scrolled queue (its node section is findable).
3. Delete a placed card's todo from the board (or by hand in `data/todos.json`): the canvas shows a visibly broken card at its spot with the id and provenance — not a normal card, not an empty gap. Removing it via its action deletes the placement.
4. Detach-proof: hand-edit a canvas's `boardIds` to include a nonexistent board id — the canvas renders an error strip for it; detaching from the strip repairs the canvas.
5. Completed toggle state survives reload and (via `lastModified` sync) other machines.
6. `npm test` green.

## N/A sections

- **New API/schema** — N/A (consumes story 1; `showCompleted` already in the canvas entity).
- **New view modes** — N/A.
