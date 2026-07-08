# Story 6: Notes on architecture nodes

- **Epic:** [002-topology-view-epic.md](./002-topology-view-epic.md) — read it first; it owns all design decisions, the schema, and vocabulary.
- **Depends on:** Story 3 (nodes exist). Independent of stories 4–5; may run in parallel with them.
- **Codebase:** `c:\Users\dustin.thomason\OneDrive\SCRIPTS ALL SYSTEMS\To Do List\WorkLists`

## Product story

As a canvas author, I keep discussions, investigations, and build context attached to the architecture node itself — the node acts like a folder for its feature's working notes — using the exact notes UI I already use on cards (epic decision 10). This replaces a node "description" field entirely (epic decision 9).

## Scope

| In scope | Out of scope |
|---|---|
| Note-count icon + expand/collapse toggle on nodes (same UI as cards) | Notes → internal docs-repo pointers (explicit future non-goal, epic §4) |
| Notes side pane working for node ids | Any change to card notes behavior |
| Note cleanup on node delete (see decision below) | Server/API changes (verified unnecessary) |

## Verified foundation (2026-07-08, do not re-litigate)

The notes API stores notes as `{ noteId (UUID), eventId, text, createdAt, lastModified }` in `data/event-notes.json` and **performs no validation of `eventId` against todos** — `GET/POST /api/notes` (`server.js:2600–2634`) accept any id string. Passing a `canvasnode-*` id as `eventId` works today, server-side. This story is client-side.

One server-adjacent check IS required: `BoardData.getRelevantBoardRefreshEntities` (`public/boardData.js:44`) filters notes to current-board todo ids for refresh relevance. The canvas-view relevance check (extended in story 2) must also treat notes whose `eventId` is a node id of the open canvas as relevant, so a note edit syncs across machines while the canvas is open. Extend the canvas branch accordingly.

## Design

- **Node UI:** the node header gets the same note icon used on cards — shows the count of notes for `eventId === node.id`, functions as expand/collapse toggle for the notes pane. Reuse the existing icon/count markup and handlers rather than re-implementing (find the card note-icon implementation in `public/todolist2.js` and factor/parameterize as needed — it currently assumes a todo id).
- **Notes pane:** the existing side pane opens against the node id: list, create, edit, delete notes exactly as for cards, markdown rendering included (`public/markdownRenderer.js` etc. come along for free if reuse is faithful). Pane title shows the node title.
- **Node delete:** when a node is deleted, delete its notes as part of the flow (extend story 1's cascade in `dal.js` — this is the one data-layer touch in this story, mirroring how the cascade already handles wires/placements; if the implementing agent finds notes are intentionally kept elsewhere on entity deletion — check how card deletion treats notes — match the app's existing convention instead and record which convention was found in the PR description).

## Touched files

`public/canvasView.js`, `public/todolist2.js` (factoring the note icon/pane helpers to accept node ids), `dal.js` (cascade addition), `public/todoliststyles2.css` (minor), tests under `tests/`.

## Tests

- Note CRUD against a node id round-trips through the existing `/api/notes` routes (API-level test with a `canvasnode-*` eventId).
- Refresh relevance: a note whose `eventId` is a node on the open canvas flags newer data; a note for an unrelated node does not.
- Cascade (or the discovered convention): node deletion handles its notes per the convention chosen above, with a test asserting it.

## Done-when (falsifiable)

1. On a real canvas node: create two notes with markdown; the node's note icon shows "2"; toggle opens/closes the pane; reload persists.
2. Edit a note on machine A (or a second window); with the canvas open on machine B, the count/content updates within one refresh interval.
3. Card notes are demonstrably unaffected (open a card's notes before/after — identical behavior).
4. Deleting the node handles its notes per the implemented convention, verified by test.
5. `npm test` green.

## N/A sections

- **New API routes** — N/A, verified above.
- **New data sections** — N/A (notes stay in `event-notes`).
