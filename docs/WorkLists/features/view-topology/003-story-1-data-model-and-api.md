# Story 1: Canvas data model and API

- **Epic:** [002-topology-view-epic.md](./002-topology-view-epic.md) — read it first; it owns all design decisions, the schema, and vocabulary.
- **Depends on:** nothing (first story).
- **Codebase:** `c:\Users\dustin.thomason\OneDrive\SCRIPTS ALL SYSTEMS\To Do List\WorkLists`

## Product story

As the owner of the topology feature, I need the four canvas data sections persisted and served through the same DAL/API machinery as boards and columns, so every later story builds on storage that already has atomic writes, locking, OneDrive-sync `lastModified` semantics, and a tested HTTP contract.

## Scope

| In scope | Out of scope |
|---|---|
| Four new DAL sections + normalization + CRUD | Any UI or rendering (stories 2–5) |
| Express routes, `ApiService` methods, `openapi.js` entries | Notes on nodes (story 6 — server already supports it) |
| Data-level validation and cascade rules | Broken-reference *rendering* (story 5; this story only guarantees the data survives) |
| Tests for DAL + HTTP surface | Migration of any existing data (there is none) |

## Data sections

Implement exactly the schema in **epic §5** (`canvases`, `canvasNodes`, `canvasWires`, `canvasPlacements`). Key mechanics:

1. Append all four names to `SECTIONS` (`dal.js:59`) **and** to `TEMP_FILE_PATTERN` (`dal.js:73`) — the temp-file cleanup regex enumerates section names and will not match new sections otherwise.
2. Follow the existing per-section normalization pattern in `dal.js` (see how boards/columns normalize ids, arrays, and `lastModified` via `touchEntity`). Normalizers must tolerate missing files (empty array) like other sections.
3. Id generation follows the `<type>-<epochMs>` convention: `canvas-`, `canvasnode-`, `canvaswire-`, `canvasplacement-`, `nodegroup-`.

## Validation and cascade rules (data layer)

- `canvases.boardIds`: non-empty array; each id must resolve to an existing board **on write** (attach/detach). A board deleted later leaves a dangling id — that is intentional (visible-fail is a render concern, story 5). Do not auto-prune.
- `canvasNodes`: `title` required non-empty after trim; `canvasId` must resolve; `groups[].name` required; group ids unique within the node.
- `canvasWires`: `fromNodeId`/`toNodeId` must resolve to nodes **on the same canvas**; reject self-wires; `arrow` ∈ {`none`, `forward`}.
- `canvasPlacements`: enforce at most one record per `(canvasId, todoId)` and **exactly one entry in `paths`** (V1 invariant, epic §5). `todoId` must resolve to an existing todo **on create** (a todo deleted later leaves a broken reference — do not auto-prune). Docked paths: `nodeId` must resolve on the same canvas; non-null `groupId` must exist in that node's `groups`.
- **Cascades:**
  - Delete node → delete its wires; convert placements docked to it to `state: "floating"` at the node's `x`/`y` (epic decision 13). Done atomically inside one lock acquisition.
  - Delete canvas → delete its nodes, wires, and placements.
  - Delete a group (via node update) → placements docked to that group move to the node's default queue (`groupId: null`), appended in existing order.

## HTTP surface (new routes in `server.js`, mirroring boards/columns patterns)

| Method + path | Purpose |
|---|---|
| `GET /canvases` | List canvases |
| `POST /canvases` | Create (title, optional boardIds) |
| `PUT /canvases/:canvasId` | Rename / set `boardIds` / set `showCompleted` |
| `DELETE /canvases/:canvasId` | Delete + cascades |
| `GET /canvases/:canvasId/graph` | One-shot fetch: the canvas + its nodes, wires, placements (the shell's load call) |
| `POST /canvases/:canvasId/nodes` · `PUT /canvas-nodes/:nodeId` · `DELETE /canvas-nodes/:nodeId` | Node CRUD (update covers title/color/x/y/size/groups) |
| `POST /canvases/:canvasId/wires` · `PUT /canvas-wires/:wireId` · `DELETE /canvas-wires/:wireId` | Wire CRUD (update covers `arrow`) |
| `POST /canvases/:canvasId/placements` · `PUT /canvas-placements/:placementId` · `DELETE /canvas-placements/:placementId` | Placement create (float or dock), move/redock, remove |

Also:
- `GET /data` (`server.js:2701`) must include the four new sections in its snapshot — the client render loop and refresh checks read from it.
- `ApiService` (`public/apiService.js`): one method per route above, following the existing fetch-wrapper style.
- `openapi.js`: schema + path entries for every route (the repo keeps its OpenAPI spec current; `tests/openapi.test.js` exists).

## Touched files

`dal.js`, `server.js`, `public/apiService.js`, `openapi.js`, new tests under `tests/` (suggest `tests/canvas-api.test.js`, `tests/canvas-dal.test.js`), fixtures under `data-test/` if the existing tests use them.

## Tests (must ship with the story)

- DAL: CRUD round-trips per section; each validation rule above rejects; each cascade behaves (node delete → wires gone, docked placements floated at node position; canvas delete → full cascade; group delete → default-queue fallback).
- Invariants: second placement for the same `(canvasId, todoId)` rejected; `paths.length !== 1` rejected.
- HTTP: status codes for happy path + each rejection; `GET /data` contains the new sections; OpenAPI test stays green.
- Dangling references (deleted board, deleted todo) are **preserved**, not pruned.

## Done-when (falsifiable)

1. `npm test` passes with the new tests included.
2. `curl` (or the test suite) can create a canvas with an attached board, add two nodes, wire them with `arrow: "forward"`, dock a real todo into a named group, and read it all back via `GET /canvases/:id/graph`.
3. Deleting that node returns a response after which the wire is gone and the placement is floating at the node's former coordinates.
4. Deleting the todo's JSON entry by hand and re-reading the graph still returns the placement (dangling, not pruned).

## N/A sections

- **Frontend rendering** — N/A, stories 2–5.
- **Feature flags** — N/A, single-user app; the view is simply unreachable until story 2 ships.
