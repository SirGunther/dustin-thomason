# Epic: Dependency-Topology View (Canvas)

- **Status:** ready for implementation
- **Date:** 2026-07-08
- **Parent investigation:** [001-dependency-topology-view.md](./001-dependency-topology-view.md) (disposition: proceed with conditions)
- **Target codebase:** `c:\Users\dustin.thomason\OneDrive\SCRIPTS ALL SYSTEMS\To Do List\WorkLists`
- **Stories:** [003](./003-story-1-data-model-and-api.md) · [004](./004-story-2-canvas-shell.md) · [005](./005-story-3-nodes-and-wires.md) · [006](./006-story-4-card-placement-and-parity.md) · [007](./007-story-5-reads-filters-visible-fail.md) · [008](./008-story-6-node-notes.md)

> **How to use this document (implementing agents, read this first):** This epic is the single authoritative home for every design decision, the data model, and the vocabulary. Story specs reference this document and add only their own scope, touched files, and done-when criteria. If a story appears to contradict this epic, the epic wins — flag the contradiction rather than improvising.

---

## 1. Problem → Requirement → Solution

**Problem.** Dependency data exists on the Kanban board but has no legible topology at the moment of decision. Priority collapses to whoever holds the architecture in their head; when that person is absent, the team reconstructs it by hand in a meeting. (Convening instance: a full day spent on a low-leverage task while a basic skill — the actual unblocker for other projects — sat invisible as "just an item in an epic.")

**Requirement.** With the architecture-holder absent, a dev must be able to see unaided what to pull next and what it unblocks (the **bus test**), with status that is current on render, failures that are visible rather than plausibly-stale, and authoring cost folded into thinking already being done.

**Solution.** A **canvas view** on the existing board app. Architecture elements are freestanding **nodes** placed on a zoomable canvas; the attached boards' columns render on the same canvas as live **staging**; dragging a card out of its column and onto the canvas (loose, or docked onto a node/group) **is** the act of authoring the association. Status, tags, and column membership are always derived live from board data at render time — the canvas stores only spatial/associative facts (positions, docks, wires), never copies of ticket state.

The one-line inference that makes the whole design work: **if a card is not visible in a staging column, it has been placed on the canvas.**

## 2. Vocabulary (use these terms verbatim in code, UI copy, and story discussion)

| Term | Meaning |
|---|---|
| **Canvas** | A standalone top-level entity (peer of a board): a named drawing surface with attached boards, nodes, wires, and placements. |
| **Attached board** | A board whose live columns render on the canvas as staging. A canvas attaches one or more `boardId`s. |
| **Staging strip** | The rendered columns of one attached board, mirroring live board state. Purely derived — nothing about staging is persisted per-canvas. |
| **Staged card** | A card still sitting in a staging column: it has **no placement record** for this canvas. |
| **Placed card** | A card the user has dragged out of staging: it has a placement record and no longer renders in the staging column. |
| **Node** | A freestanding architecture element: title, color, position, size, named groups. Carries **no computed semantics**. |
| **Group** | A user-named queue inside a node (e.g. "backend", "UI bugs"). Every node also has an implicit **default queue** (placements with `groupId: null`). |
| **Wire** | A user-drawn line between two nodes, optionally with an arrowhead. Purely expressive — never traversed by code. |
| **Placement** | The persisted record that a specific todo occupies a spot on a specific canvas: floating `{x,y}` or docked `{nodeId, groupId, order}`. |
| **Path / provenance** | The `columnId` recorded on a placement — where the card lived when placed. Display always uses the todo's **live** `columnId`; the stored value is traceability metadata. |
| **Broken reference** | A placement whose `todoId` no longer resolves to a live todo. Renders visibly failed, never plausibly stale. |

## 3. Resolved design decisions (locked in the grill-me session of 2026-07-08)

These were negotiated one-by-one with the owner. Do not reopen them; implement them.

1. **No computed semantics anywhere.** Nodes are freestanding. There is no inheritance, gating, blocking engine, or graph traversal. "Downstream", fan-in, fan-out, and depth are read by the human from the drawing (queue counts + wires). A confidently-wrong computed graph is worse than none.
2. **Wires connect nodes to nodes only.** Never to cards or groups. Each wire has an optional arrowhead (per-wire choice, Lucid-style). Wires cascade-delete when either endpoint node is deleted.
3. **A canvas is a standalone top-level entity**, listed in its own side-panel section, cross-board by construction: placements reference todos from any attached board.
4. **Staging = the board rendered on the canvas.** Each attached board's columns render (via the same data slice the Kanban view uses) with their staged cards. New tickets created on the board appear in staging automatically — there is **no separate "add to canvas" step**. This is the authoring-cost answer: the tray *is* the board.
5. **Three placement states:** free-floating (x/y on canvas) · docked to a node's default queue · docked to a named group. Docked queues render as scrollable mini-columns reusing the board's card design, with a visible count per group and a max height.
6. **Cardinality:** a ticket may be placed on any number of canvases, but occupies exactly **one spot per canvas**. Dragging a placed card elsewhere on the same canvas is a **move**, never a copy. Placement identity keys on the `{todoId, columnId}` path; the record's positions are modeled as an array of per-path objects to future-proof the planned one-card-many-columns feature (today the array always has exactly one entry, enforced).
7. **Placement survives board workflow.** When a placed card's todo moves columns on the board, the card stays exactly where the user put it. The stored `columnId` is provenance; the card's visible status chip / column / highlight behavior derive from the **live** todo at render. **Never write to the data layer during render.**
8. **Full card parity in V1.** Staged and placed cards both carry the board card's full action set (status change, complete, edit text, notes, menus) by reusing `createTask()` — same `ApiService` write path, so no second source of truth is created.
9. **Node anatomy:** required title, accent color, x/y position, resizable width/height, zero or more named groups. No C4 types, no shapes taxonomy, no description field — node **notes** (decision 10) carry prose.
10. **Notes extend to nodes.** The existing event-notes feature (side pane, note-count icon, expand/collapse toggle — same UI as cards) attaches to nodes by using the node id as `eventId`. Verified 2026-07-08: the `/api/notes` routes (`server.js:2600–2668`) do not validate `eventId` against todos, so the server already supports this; the work is client-side.
11. **Find-it affordance:** each staging column has a highlight toggle; when on, all placed cards on the canvas whose **live** `columnId` matches that column are highlighted.
12. **Completed toggle:** a canvas-level toggle shows/hides completed cards in both staging and placements.
13. **Visible-fail defaults:**
    - Placement whose `todoId` doesn't resolve → renders as a **broken-reference card**: distinct error styling, shows the raw `todoId` and stored provenance `columnId`, never a plausible status. User can remove it manually. It must never silently disappear.
    - Attached `boardId` that doesn't resolve → renders an **error strip** in place of that staging strip (board title unknown, id shown), never silently dropped.
    - Deleting a node prompts for confirmation; its docked cards convert to free-floating at the node's position (non-destructive); its wires are deleted.

## 4. Non-goals (V1)

- Knowledge management / wiki-agent (separate effort). The future "node notes point at an internal docs repo" idea is explicitly **out**; V1 notes are plain event-notes.
- Gantt or any temporal axis.
- Sprint-planning replacement — this view is the fallback for when the plan's authors are absent.
- Decorative architecture modeling (C4 types, shapes, icons).
- Computed blocking/gating of any kind (decision 1).
- Clustering / auto-layout. V1 legibility = zoom/pan + column highlight + scrollable queues. If hairball emerges at scale, that is a follow-up.
- Board-side "add to canvas…" card action (staging makes it unnecessary for V1; revisit only if authoring friction is observed).

## 5. Data model (four new DAL sections)

All four are appended to `SECTIONS` (`dal.js:59`) **and** `TEMP_FILE_PATTERN` (`dal.js:73`) so they inherit atomic writes, the async write lock, and `lastModified`-based OneDrive sync. Every entity carries `lastModified` (ISO string) maintained by the DAL's `touchEntity` convention. Id patterns follow the existing `<type>-<epochMs>` convention.

### `canvases` (`data/canvases.json`)

```json
{
  "id": "canvas-1783441994585",
  "title": "Platform topology",
  "boardIds": ["board-22", "board-3"],
  "showCompleted": false,
  "lastModified": "2026-07-08T00:00:00.000Z"
}
```

- `boardIds`: ordered; each must reference an existing board **at attach time** (later disappearance is a visible-fail render case, not a data error).
- `showCompleted`: the canvas-level completed toggle (decision 12), persisted so the reading is stable across sessions/machines.

### `canvasNodes` (`data/canvasNodes.json`)

```json
{
  "id": "canvasnode-1783442000001",
  "canvasId": "canvas-1783441994585",
  "title": "Auth Service",
  "color": "#0a4c88",
  "x": 120, "y": 340,
  "width": 280, "height": 320,
  "groups": [
    { "id": "nodegroup-1783442000002", "name": "backend", "order": 1 },
    { "id": "nodegroup-1783442000003", "name": "UI bugs", "order": 2 }
  ],
  "lastModified": "..."
}
```

- `title` required, non-empty after trim. `color` optional hex; default styling when absent.
- The default queue is **implicit** — it is not a member of `groups`.

### `canvasWires` (`data/canvasWires.json`)

```json
{
  "id": "canvaswire-1783442000004",
  "canvasId": "canvas-1783441994585",
  "fromNodeId": "canvasnode-...",
  "toNodeId": "canvasnode-...",
  "arrow": "none",
  "lastModified": "..."
}
```

- `arrow`: `"none" | "forward"` (`"forward"` renders an arrowhead at the `toNodeId` end). Self-wires (`fromNodeId === toNodeId`) rejected.

### `canvasPlacements` (`data/canvasPlacements.json`)

```json
{
  "id": "canvasplacement-1783442000005",
  "canvasId": "canvas-1783441994585",
  "todoId": "todo-1783367779259-361ec996",
  "paths": [
    {
      "columnId": "column-1783441979778",
      "state": "floating",
      "x": 900, "y": 200,
      "nodeId": null,
      "groupId": null,
      "order": null
    }
  ],
  "lastModified": "..."
}
```

- **Invariant:** at most one record per `(canvasId, todoId)`; **V1 enforces `paths.length === 1`.** The array shape exists solely so the planned one-card-many-columns feature can add per-path entries without a migration.
- Path fields: `columnId` = provenance at placement time (decision 7 — display never uses it for state). `state`: `"floating"` (uses `x`/`y`) or `"docked"` (uses `nodeId`, `groupId` — `null` for the default queue — and `order` within that queue).
- A docked path's `nodeId` must reference a node on the same canvas; `groupId`, when non-null, must exist in that node's `groups`.

### Derived at render (never persisted)

Staged-vs-placed partition, live status/tag/column chips, queue counts, highlight matches, broken references. Rule of thumb: **the canvas sections persist only what the user drew** — everything about ticket state is read from the board snapshot.

## 6. Architecture constants (how this plugs into the app)

- **View mode:** follow the scheduler precedent — a module-level `canvasViewActive` flag, a branch in `updateAndRenderUI()` (`public/todolist2.js:19792`), a `renderCanvasView()` that renders into `#board` with an `is-canvas-view` class (scheduler reference: `renderSchedulerWorkspace()` at `public/todolist2.js:11422`, flag at line 91).
- **Side panel:** a CANVASES list mirroring the boards list (create / rename / delete / open).
- **Data slice for staging:** `BoardData.getCurrentBoardData(snapshot, boardId)` (`public/boardData.js:81`) per attached board — do not reimplement the slice.
- **Rendering tech (greenfield):** absolutely-positioned DOM divs for nodes and cards inside a CSS-transform pan/zoom container, plus **one SVG overlay** for wires. jQuery UI `.draggable()`/`.sortable()` are already loaded; **known gotcha:** jQuery UI does not compensate for CSS `scale()` — drag deltas must be divided by the current zoom factor.
- **Refresh:** the background refresh loop (`setInterval` near `public/todolist2.js:1240`) must, when the canvas view is active, include the four canvas sections in its newer-data relevance check (extend or parallel `BoardData.getRelevantBoardRefreshEntities`, `public/boardData.js:38`).
- **API:** new Express routes in `server.js`, DAL functions in `dal.js`, client methods in `public/apiService.js`, and `openapi.js` entries — all mirroring the existing CRUD patterns for boards/columns.
- **Tests:** Node built-in test runner under `tests/` (see `tests/api.test.js`, `tests/board-refresh.test.js` for conventions).

## 7. Story map and sequencing

| # | Spec | Scope (one line) | Depends on |
|---|------|------------------|------------|
| 1 | [003-story-1-data-model-and-api.md](./003-story-1-data-model-and-api.md) | Four DAL sections + normalization + Express/ApiService/OpenAPI CRUD + data-level fail rules | — |
| 2 | [004-story-2-canvas-shell.md](./004-story-2-canvas-shell.md) | Canvas entity UI, side-panel list, view-mode branch, pan/zoom, staging strips, refresh integration | 1 |
| 3 | [005-story-3-nodes-and-wires.md](./005-story-3-nodes-and-wires.md) | Node authoring (create/rename/resize/color/delete/groups) + wire drawing with SVG overlay | 2 |
| 4 | [006-story-4-card-placement-and-parity.md](./006-story-4-card-placement-and-parity.md) | Drag from staging → float/dock/group, move semantics, full card parity | 3 |
| 5 | [007-story-5-reads-filters-visible-fail.md](./007-story-5-reads-filters-visible-fail.md) | Queue counts, column highlight, completed toggle, broken-reference + missing-board rendering | 4 |
| 6 | [008-story-6-node-notes.md](./008-story-6-node-notes.md) | Notes pane on nodes, count icon/toggle | 3 |

Sequential: 1 → 2 → 3 → 4. Stories 5 and 6 can run in parallel once their dependencies land (6 needs only story 3).

Each story = one agent session, one branch, one PR, per the repo's existing workflow. Every story must leave `npm test` green and ship its own tests.

## 8. Acceptance (epic-level — inherited from the investigation contract)

| Criterion | Where it lands |
|---|---|
| **Bus test:** with the architecture-holder absent, a dev sees unaided what to pull next and what it unblocks | Staged after all six stories ship — one real planning session; not a dev story |
| **Freshness:** status current on render, parity with board refresh | Stories 2 (refresh relevance) and 4 (live derive) |
| **Visible-fail:** unresolvable references fail visibly, never plausibly stale | Story 1 (data rules) + Story 5 (rendering) |
| **Topology legibility:** counts, fan-out, depth readable at a glance from the drawing | Stories 3 and 5 |
| **Authoring cost:** association folded into existing thinking | Staging design (Stories 2 and 4); measured over ≥2 sprints post-ship |

## 9. Open-variables ledger (carried from the investigation — not closed by this epic)

- **Node-placement upkeep economics** (highest risk): does keeping the drawing truthful stay cheaper than its payoff? Measure drift over ≥2 sprints after ship.
- **Behavior change:** does the rabbit-hole rate actually drop, or is leverage seen-and-ignored?
- **Legibility at scale:** clustering/filtering thresholds deferred; watch for the hairball point.

Gates from the investigation stand: no architecture-lens or progress-over-time extensions until the bus test passes once; no temporal/Gantt work until upkeep economics prove out over ≥2 sprints.
