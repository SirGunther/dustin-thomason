# Duplicate Card Option Spec

## Metadata
- **Status:** draft / ready for implementation planning
- **Date:** 2026-07-16
- **Ticket:** duplicate-card-option
- **Domain:** WorkLists
- **Investigation:** `c:\dustin-thomason\docs\WorkLists\tickets\duplicate-card-option\investigations\duplicate-card-option-investigation.md`
- **Spec:** `c:\dustin-thomason\docs\WorkLists\tickets\duplicate-card-option\specs\duplicate-card-option-spec.md`

## Problem -> Requirement -> Solution

### Problem
WorkLists users can copy card text or card-plus-notes text to the clipboard, but they do not have a direct way to create a new card from an existing card's full reusable structure. The missing behavior is not just a menu item: the system needs a new card identity, copied note identities, column-order mutation, UI refresh, and focus/reveal behavior that stays consistent with existing new-card and sorted-column rules.

### Requirement
Add `Duplicate Card` to the card ellipsis menu so a user can duplicate one persisted card into a new persisted card in the same column. The duplicate must preserve template structure, copy notes, remap all unique identifiers, refresh the board immediately after the server write, and focus/reveal the created card when it is visible in the current UI state.

### Solution
Implement a backend-owned duplicate command exposed as `POST /todos/{id}/duplicate`. The DAL clones the source todo and source notes in one atomic read/write mutation, appends the new todo to unsorted source column order, allows sorted rendering to reapply active sort, and returns the created todo, copied notes, updated column, source id, and destination index. The frontend adds a shared card action, calls the new ApiService method, blocks duplicate double-submit for the same source while in flight, refreshes/render-updates from the server result, and reuses existing visibility/focus behavior without changing search/filter or sort state.

## Locked Behavior

- Menu item: `Duplicate Card`, `id: "duplicate"`, icon `fa-clone`, placed after `Copy All` and before `Refine with Gemma`.
- Surfaces: board card action menu and notes-pane card action menu both expose the action.
- Source: duplicates persisted server state only; unsaved card or note drafts are not included.
- Card fields copied exactly: text/markdown, primary tag(s), secondary tags, status, and other reusable structure fields present on the todo.
- Workflow state reset: duplicate is incomplete, `completedDate` is blank, and scheduler membership is not inherited.
- Notes: copy all source notes in source note order, preserving `text` exactly, with new `noteId`, new `eventId`, and fresh note timestamps.
- IDs: server/DAL generates duplicate todo id and note ids.
- Timestamps: one fresh timestamp is used for the duplicate card, copied notes, touched source column, and affected board(s); source todo is not touched.
- Placement: unsorted source columns append the duplicate at bottom. Sorted columns keep active sort behavior; do not force adjacency to source.
- UI refresh: no optimistic duplicate card. Wait for `201 Created`, then update/refresh/render and reveal/focus the created card if it exists in the current DOM.
- Notes-pane origin: after duplicate succeeds from the notes-pane menu, switch the notes pane to the duplicated card and load copied notes, while respecting existing unsaved draft guards before switching.
- Board-menu origin: reveal/focus the duplicate without opening the notes pane.
- Search/filter: preserve current search/filter state. If the duplicate is hidden by current filters, show success toast and do not clear filters.
- Toasts: success `Card duplicated.`; failure `Card could not be duplicated.`; no undo action in v1.
- Atomicity: card, column insertion, notes, and timestamp touches succeed together or fail without partial writes.

## 1. Folder Hierarchy

New or modified paths under the WorkLists app repo:

```text
WorkLists/
  dal.js                         # add duplicateTodo helper and export
  server.js                      # add POST /todos/:id/duplicate route
  openapi.js                     # add duplicate path/schema
  public/
    apiService.js                # add duplicateTodo client method
    cardActions.js               # add duplicate action definition
    todolist2.js                 # wire duplicate handlers, in-flight state, refresh/reveal/focus
  tests/
    api.test.js                  # duplicate endpoint and atomicity coverage
    openapi.test.js              # duplicate path/schema assertions
    card-actions.test.js         # action definition/order/handler/notes-pane parity
    card-duplicate-ui.test.js    # new or equivalent focused UI contract test if not folded into card-actions.test.js
```

Ticket artifacts:

```text
c:\dustin-thomason\docs\WorkLists\tickets\duplicate-card-option\
  investigations\
    duplicate-card-option-investigation.md
  specs\
    duplicate-card-option-spec.md
```

## 2. New Classes

N/A - WorkLists uses plain JavaScript modules for this surface. No class introduction is required.

## 3. New Entities

N/A - no new persisted entity type. The feature creates new `Todo` records and copied `Note` records using existing JSON sections.

## 4. Modified Entities

N/A - no schema change to existing todo, note, column, or board records. The implementation changes mutation behavior only.

## 5. New Migrations

N/A - JSON-backed data shape is unchanged.

## 6. New Migration Classes

N/A - no migration files or migration classes are required.

## 7. New DTOs

| Name | Path | Fields |
|---|---|---|
| `TodoDuplicateResponse` | `openapi.js` components schema | `message: string`, `todo: Todo`, `column: Column`, `notes: Note[]`, `sourceTodoId: string`, `destinationIndex: number` |

Request DTO: N/A - `POST /todos/{id}/duplicate` has no request body in v1.

## 8. New Projections

N/A - no separate projection layer exists for this WorkLists surface. The API returns existing todo/column/note records directly in the response DTO.

## HTTP Surface

### `POST /todos/{id}/duplicate`

- **Type:** new route, non-breaking.
- **Request body:** none.
- **Success:** `201 Created`.
- **Response:** `TodoDuplicateResponse`.
- **Errors:**
  - `404` when the source todo does not exist.
  - `409` when the source todo references a missing or inconsistent source column.
  - `500` for unexpected failures.

Example response:

```json
{
  "message": "Card duplicated.",
  "todo": {
    "id": "todo-1784230000000-a1b2c3d4",
    "text": "Source markdown",
    "completed": false,
    "completedDate": "",
    "columnId": "col-1",
    "creationTimestamp": "2026-07-16T14:25:00.000Z",
    "tag": ["Task"],
    "secondaryTagIds": ["tag-template"],
    "status": "Ready",
    "lastModified": "2026-07-16T14:25:00.000Z"
  },
  "column": {
    "id": "col-1",
    "title": "To Do",
    "taskIds": ["todo-source", "todo-1784230000000-a1b2c3d4"],
    "lastModified": "2026-07-16T14:25:00.000Z"
  },
  "notes": [
    {
      "noteId": "7c11e9a0-1111-4444-9999-abc123def000",
      "eventId": "todo-1784230000000-a1b2c3d4",
      "text": "Source note text",
      "createdAt": "2026-07-16T14:25:00.000Z",
      "lastModified": "2026-07-16T14:25:00.000Z"
    }
  ],
  "sourceTodoId": "todo-source",
  "destinationIndex": 1
}
```

## Data-Layer Design

Add `duplicateTodo(todoId)` to `dal.js`.

Implementation requirements:

- Acquire/read/write through existing DAL locking conventions.
- Normalize and validate the source id.
- Find the source todo; throw `createDataError(404, "Card not found.")` or equivalent existing JSON error style when absent.
- Find the source column by `sourceTodo.columnId`; throw `409` when missing or the source column's `taskIds` does not include the source todo id.
- Generate a new todo id server-side. Use the existing server-side style: `todo-${Date.now()}-${crypto.randomUUID().slice(0, 8)}` or a local helper with equivalent collision avoidance.
- Clone reusable source fields. Preserve `text`, `tag`, `secondaryTagIds`, `status`, `columnId`, and other non-identity template fields that already exist on the todo.
- Reset workflow fields: `completed: false`, `completedDate: ""`, no scheduler membership changes.
- Set `creationTimestamp` and `lastModified` to the same fresh timestamp.
- Append the duplicate id to `sourceColumn.taskIds` and compute `destinationIndex` from the appended position.
- Copy notes where `eventId === sourceTodo.id` in existing order. Each copied note gets new UUID `noteId`, `eventId` set to the duplicate todo id, same `text`, and fresh `createdAt` / `lastModified`.
- Touch source column and affected board(s) with the same timestamp.
- Write once after all in-memory mutation succeeds.
- Return `{ todo, column, notes, sourceTodoId, destinationIndex }`.

Atomicity requirement: do not write before todo, column, and notes are all prepared. Any validation or clone failure must leave `todos`, `columns`, `event-notes`, boards, and `schedulerTaskIds` unchanged.

## Server Design

Add an Express route in `server.js` near the existing todo mutation routes:

```text
POST /todos/:id/duplicate
```

Route requirements:

- Call `dal.duplicateTodo(req.params.id)`.
- Return `201` with `{ message: "Card duplicated.", ...result }`.
- Preserve existing data-error behavior for `statusCode`-bearing DAL errors.
- Log unexpected errors consistently with nearby todo routes.

## Client API Design

Add `ApiService.duplicateTodo(todoId)` in `public/apiService.js`.

Requirements:

- POST to `/todos/${encodeURIComponent(todoId)}/duplicate`.
- No request body.
- Parse JSON response.
- Throw a useful error message from the server response when the status is not OK.
- Return the response object as the authoritative created-card payload.

## Frontend Design

### Card Action Definition

Add the action to `public/cardActions.js`:

```js
{
  id: "duplicate",
  label: "Duplicate Card",
  icon: "fa-clone",
  type: "action",
}
```

Place it immediately after `copy-all` and before `refine-gemma`.

### Board Card Handler

In `public/todolist2.js`, wire the board card handler map with `duplicate: () => duplicateTask(id, { origin: "board" })` or equivalent.

Handler requirements:

- Close the action menu on activation through existing CardActions behavior.
- Guard against a second in-flight duplicate for the same source id.
- Call `ApiService.duplicateTodo(id)`.
- Integrate the returned `todo`, `column`, and `notes` into client state or trigger the existing refresh path used by authoritative server mutations.
- Preserve active search/filter/sort state.
- Show `Card duplicated.` after success.
- Reveal/focus the new card if it is rendered under current filters.
- If hidden by current search/filter, do not clear filters; success toast is sufficient.
- On failure, log and show `Card could not be duplicated.`.

### Notes-Pane Handler

Add duplicate handling to `getNotesPaneCardActionHandlers`.

Requirements:

- Before switching cards, respect existing unsaved note/card draft guards.
- Call the same duplicate service path with `origin: "notes-pane"`.
- After success, switch the notes pane to the duplicate todo id and render copied notes from the returned `notes` payload or through the existing note load path.
- Keep board state refreshed and reveal/focus the duplicate card if visible.

### In-Flight State

Track duplicate requests by source todo id in a narrow state container such as `duplicateCardRequestByTodoId` / `duplicateCardRequests`.

Requirements:

- Add id before API call.
- Remove id in `finally`.
- `getTaskCardActionState` and notes-pane state should mark `duplicate` as disabled/running if the same source id is in flight. If `CardActions` lacks disabled support, extend it minimally and cover with tests.

### Focus And Reveal

Reuse `TaskVisibility.revealTaskCard` or a narrow wrapper that preserves existing behavior.

Requirements:

- Do not override active sort order.
- Do not clear active filters/search.
- For unsorted columns, reveal the bottom-appended duplicate.
- For sorted columns, reveal the duplicate wherever the active sort places it.
- For hidden duplicates, do not force-render or filter-toggle.
- Focus the duplicate card element or its ellipsis trigger without entering edit mode.

## Cross-Cutting

- **Parent epic:** N/A - no parent epic id was provided.
- **Feature flag:** N/A - this is a direct WorkLists feature addition with no feature flag requested.
- **Companion artifacts:** investigation report in this ticket folder.
- **Changelog:** after implementation, update canonical `c:\dustin-thomason\docs\WorkLists\worklists-app-changelog.md` with endpoint, UI, tests, and scroll/reveal validation evidence.
- **Backwards compatibility:** existing copy, copy-all, move, edit-notes, delete, note cleanup, status/tag rendering, scheduler, search/filter, and notes-pane extra actions must remain unchanged.

## Optional Callouts

- **Registries and module wiring:** N/A - no framework registry. Export `duplicateTodo` from `dal.js` if exports are explicit.
- **Ports:** N/A - no port abstraction in this app surface.
- **Domain events / dispatchers / outbox:** N/A - no domain event system involved.
- **Domain exceptions:** use existing DAL `createDataError(statusCode, message)` style for `404` and `409`.
- **Authorization:** N/A - existing local WorkLists routes do not expose auth guards in this surface.
- **Spec tests:** see validation plan below.

## Validation Plan

### API Tests (`tests/api.test.js`)

- `POST /todos/:id/duplicate` duplicates a card with markdown, primary tag(s), secondary tags, and status.
- Duplicate receives new id, new `creationTimestamp`, new `lastModified`, `completed: false`, and `completedDate: ""`.
- Source todo is unchanged.
- Source column appends duplicate id for unsorted order and returns expected `destinationIndex`.
- Affected column and board `lastModified` values change.
- Source notes are copied in order with new `noteId`s, duplicate `eventId`, exact `text`, and fresh timestamps.
- `schedulerTaskIds` does not include the duplicate unless independently added later.
- Missing source returns `404` with no writes.
- Missing/inconsistent source column returns `409` with no writes.
- Simulated clone/write preparation failure does not leave partial todo or notes. If hard to simulate without intrusive hooks, cover the validation-failure no-partial cases and document remaining residual risk.

### OpenAPI Tests (`tests/openapi.test.js`)

- Expected path list includes `/todos/{id}/duplicate`.
- `POST /todos/{id}/duplicate` has no request body.
- Responses include `201`, `404`, `409`, and `500`.
- Components include `TodoDuplicateResponse` with `todo`, `column`, `notes`, `sourceTodoId`, and `destinationIndex`.

### Card Action / UI Contract Tests

- `CardActions.getCardActionDefinitions()` returns action order: `copy`, `copy-all`, `duplicate`, `refine-gemma`, `voice-edit`, `move`, `edit-notes`, `delete`.
- Duplicate action label and icon are `Duplicate Card` and `fa-clone`.
- Board card `createTask` wires duplicate handler to the card action trigger.
- Notes-pane card action handler includes duplicate and preserves existing notes-pane extra action behavior.
- Duplicate action invokes the duplicate handler once and closes the menu.
- In-flight duplicate state prevents double-submit for the same source card if the menu is reopened.
- Success path calls refresh/render and reveal/focus behavior without opening notes pane from board origin.
- Notes-pane origin switches pane to the duplicate and loads copied notes.
- Existing Copy, Copy All, Move, Edit Notes, Delete, status/tag rendering, active search/filter rendering, and notes-pane menu behavior remain unchanged.

### Manual Validation

- Duplicate a markdown-rich card with tags, secondary tags, status, and notes from an unsorted column; verify duplicate appears at bottom, is focused/revealed, and copied notes show immediately.
- Duplicate the same kind of card from a sorted column; verify sort persists and the duplicate is focused/revealed at its sorted position.
- Duplicate while a search/filter hides the duplicate; verify search/filter remains unchanged and success toast appears without forcing visibility.
- Duplicate from the notes-pane menu; verify the pane switches to the duplicate and copied notes are loaded.
- Refresh the page; verify duplicate card and copied notes persist.

## Implementation Sequence

1. Add red API tests for duplicate endpoint, notes copy, placement, and error/no-partial cases.
2. Implement `dal.duplicateTodo` and export it.
3. Add `POST /todos/:id/duplicate` route in `server.js`.
4. Add `ApiService.duplicateTodo`.
5. Add OpenAPI path/schema and tests.
6. Add card action definition/order test, then update `public/cardActions.js`.
7. Wire board and notes-pane handlers in `public/todolist2.js` with in-flight state.
8. Reuse or wrap `TaskVisibility.revealTaskCard` for duplicate reveal/focus.
9. Add/extend focused UI contract tests.
10. Run targeted tests, then manual browser validation for scroll/reveal and notes-pane behavior.
11. Update canonical changelog after implementation is verified.

## Non-Goals

- Cross-board duplicate destination selection.
- Batch or multi-select duplicate.
- Undo duplicate in v1.
- Clipboard behavior changes for `Copy` or `Copy All`.
- Deep-copying arbitrary board/card hierarchies beyond the source card and its notes.
- Clearing or overriding active search/filter/sort state to force visibility.
