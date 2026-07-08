# Story 3: Node and wire authoring

- **Epic:** [002-topology-view-epic.md](./002-topology-view-epic.md) — read it first; it owns all design decisions, the schema, and vocabulary.
- **Depends on:** Story 2 (canvas shell).
- **Codebase:** `c:\Users\dustin.thomason\OneDrive\SCRIPTS ALL SYSTEMS\To Do List\WorkLists`

## Product story

As a canvas author, I can place named architecture nodes on the canvas, size and color them, give them named groups, and draw optional-arrow wires between them — so the drawing itself carries the architecture and its associations, with no computed semantics anywhere (epic decision 1).

## Scope

| In scope | Out of scope |
|---|---|
| Node create / rename / recolor / move / resize / delete | Docking cards into nodes/groups (story 4) |
| Named groups: add / rename / reorder / delete on a node | Queue counts and highlight reads (story 5) |
| Wire draw / delete / toggle arrowhead; SVG overlay | Node notes (story 6) |
| Delete cascades surfaced in UI (confirm dialogs) | Any new data rules (story 1 owns them) |

## Design

**Node element:** an absolutely-positioned div inside `.canvas-world` at the node's persisted `x/y/width/height`. Structure: header (color accent + title), then one section per group in `groups[].order`, then the implicit default-queue section (epic §5 — the default queue is not a `groups` member). Group sections render header (name) and an empty scrollable body in this story; cards arrive in story 4.

**Authoring gestures:**
- Create: double-click empty canvas (and/or a toolbar button) → node created at that world position with a title prompt. Empty title cancels.
- Move: drag the node header. Resize: drag a corner/edge handle. Both **divide pointer deltas by the current zoom** (`CanvasView.getZoom()` from story 2 — epic §6 gotcha). Persist on drop via `PUT /canvas-nodes/:nodeId`; no writes during the drag.
- Rename / recolor: click title to edit inline; color from a small swatch picker reusing the primary-tag palette colors (`primaryTags.json` colors as suggestions; free hex acceptable).
- Groups: node menu → add group (name prompt); group header menu → rename / delete. Deleting a group is safe in this story (no docked cards can exist yet) but must go through story 1's API, which handles the default-queue fallback.
- Delete node: node menu → confirm dialog stating consequences ("wires attached to this node will be deleted; any docked cards will float where the node was"). The API (story 1) performs the cascade; the client just re-renders.

**Wires (SVG overlay):**
- One `<svg>` layer inside `.canvas-world`, full world size, `pointer-events: none` except on wire hit-targets; nodes/cards remain DOM elements above/below as appropriate.
- Draw: a small port affordance on node hover; drag from port to another node creates the wire (`POST /canvases/:canvasId/wires`, `arrow: "none"` by default). Drop on empty space cancels. Self-wires are rejected by the API — the UI should also not offer them.
- Each wire renders as a path between node edge anchor points, recomputed on node move/resize. Arrowhead (SVG marker at the `toNodeId` end) toggles via wire click → mini-menu: *toggle arrow / delete*.
- Wires are decoration in the strict sense: no code may ever traverse them for status, ordering, or gating (epic decision 1). Keep the render function free of any graph logic beyond drawing lines.

**Rendering constraint:** node drag/resize and wire redraw should update transforms/attributes directly during the gesture (no full `renderCanvasView()` per mousemove); a full re-render on drop is fine and matches the app's teardown-and-rebuild style.

## Touched files

`public/canvasView.js` (bulk of the work), `public/todoliststyles2.css` (node, groups, handles, ports, wires), `public/apiService.js` (methods exist from story 1), tests under `tests/`.

## Tests

- Anchor-point math: given two node rects, wire endpoints land on facing edges (pure-function test — keep the math in an exported helper).
- Zoom compensation: a drag of N screen-pixels at zoom z persists a move of N/z world units (pure-function test on the delta helper).
- Cascade UX wiring: deleting a node calls the delete API and re-renders without the node or its wires (handler-level test; the data cascade itself is story 1's tested behavior).

## Done-when (falsifiable)

1. On a real canvas: create three nodes, name/color them, resize one, add groups "backend" and "UI bugs" to one node — reload the page and everything is exactly where it was.
2. Draw wires A→B (arrow) and B–C (plain); move node B and both wires follow; toggle C's wire to arrowed and back.
3. Delete node B after the confirm dialog: both wires disappear; A and C untouched; reload confirms persistence.
4. All of the above at zoom 0.5 and 2.0 — no drift between cursor and dragged node.
5. `npm test` green.

## N/A sections

- **New API routes** — N/A, story 1 shipped them.
- **Refresh integration** — N/A, story 2 shipped it (canvas sections already in the relevance check).
