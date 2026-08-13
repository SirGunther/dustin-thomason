# W2 — Single card read and id handoff — Spec

| Field | Value |
| --- | --- |
| Project | WorkLists |
| Ticket slug | `single-card-read-and-id-handoff` |
| Body of work | W2 of [`003-agent-workflow-sync-work-breakdown.md`](../../../features/agent-workflow-sync/003-agent-workflow-sync-work-breakdown.md) |
| Governing decisions | [`001`](../../../features/agent-workflow-sync/001-agent-workflow-sync-decisions.md) → how the agent knows which card (D1, the id is supplied not searched) and the additive-only constraint |
| Serves job story | [01 — Delegated work stays true](../../agent-workflow-sync/stories/agent-workflow-sync-job-story-01-delegated-work-stays-true.md) |
| Depends on | W1 (`getRecord`); W3 for path B's creation route |
| Serves job stories | 01 (path A), 05 (path B) |
| Date | 2026-08-12 |

## Problem → Requirement → Solution

**Problem.** An agent told to work on a ticket has no way to fetch that one card. The only card reads are `GET /todos` (all 2,731 records, ~925 KB) and `GET /data` (the whole database). And the user has no way to hand over which card it is: the id exists in the DOM as `dataset.taskId` but no card action surfaces it.

**Requirement.** Given a card id, return that one card. Give the user a one-click way to obtain the id so handing it over is not a JSON dig.

**Solution.** A new `GET /todos/:id` route over W1's `getRecord`, and a **Copy card id** entry in the existing card ellipsis menu.

**Explicitly not a lookup.** Per D1, the card id is an input, not a search result. This body of work adds no text search, no ticket-id resolution, and no `?q=` parameter. The title-vs-link id mismatch on `todo-1786464124416` is why: any text match is unsafe, and being told the id removes the problem rather than working around it.

## Two entry paths — and only one of them needs you to supply an id

An earlier draft said the user always supplies the card id. That is only true for one of the two ways a run starts, and the difference must be explicit so you know when you are expected to hand one over.

### Path A — the ticket's card already exists

You supply the card id. Copy Card ID puts it on the clipboard; you paste it at kickoff; the agent records it in the ledger and never asks again.

### Path B — the ticket has no card yet, so the agent creates it

The agent **creates the card from a Card Template and obtains the new id from the response.** You supply nothing.

| Step | Detail |
| --- | --- |
| 1. Which template | The designated template, from the setting in W3. The agent does not choose or guess. It may be given an explicit `templateId` instead |
| 2. Create the ticket | `POST /api/cards/from-template` with the target `columnId` and the real ticket title. **One call creates the card body and every note the template defines** |
| 3. Get the new id | The response carries `todo`, including its `id`. **This is what makes path B work** — a create that does not return what it created leaves the caller stranded |
| 4. Record it | Written to the ledger exactly as a user-supplied id would be, so every later phase and any resumed run reads it from there |

**Superseded: an earlier draft used `POST /todos/:id/duplicate` against a designated template card.** Duplication returned the new id, which was the part that worked. What it could not do was define what the shape *should* be — it copied whatever an existing card happened to have, drift included. A template says what the shape is, and the create route hands back the id just the same. See [job story 05](../../agent-workflow-sync/stories/agent-workflow-sync-job-story-05-tickets-start-pre-built.md).

**The obligation this creates:** the agent must state which path it took, and on path B must report the id it created. Otherwise you cannot tell whether a card appeared because you asked for it or because the agent invented one.

**Why the template is named by a setting rather than chosen by the agent:** the setting is the one place that says where the structure comes from. Letting the agent pick by inspection is the same class of mistake as letting it search for the target card — it can pick wrong, and wrong here builds a ticket from the wrong shape.

## Additive-only compliance

| Guarantee | How it is met |
| --- | --- |
| `GET /todos` unchanged | New route registered at a distinct path. `app.get("/todos")` keeps its handler and its `findTodos` call verbatim |
| No existing route touched | `GET /data`, `PATCH /todos/:id`, `DELETE /todos/:id` and every other route are unmodified |
| Existing menu actions unchanged | One entry appended to `ACTION_DEFINITIONS`; the nine existing definitions keep their `id`, `label`, `icon`, `type`, and order |
| No shared handler modified | The new action uses its own handler key; no existing handler's behavior changes |
| No response shape changed | The new route's shape is new; nothing existing is reshaped |

**Route-shadowing check.** Express matches in registration order. `GET /todos` and `GET /todos/:id` are distinct paths and do not shadow each other. `express.static("public")` is registered first but only serves files that exist, so it cannot intercept `/todos/<id>`. The new route must nonetheless be registered **beside the other `/todos/:id` routes** rather than before `GET /todos`, so the file reads in a predictable order — this is a placement convention, not a correctness requirement.

## 1. Folder hierarchy

No new folders.

```text
WorkLists/
  server.js                    one route added
  openapi.js                   one path + one schema added
  public/
    apiService.js              one helper added
    cardActions.js             one ACTION_DEFINITIONS entry added
    todolist2.js               one handler wired
  tests/
    api.test.js                cases added
    openapi.test.js            cases added
    card-actions.test.js       cases added
```

## 2. New functions

| Name | File | Purpose |
| --- | --- | --- |
| route handler for `GET /todos/:id` | `server.js` | Calls `dal.getRecord("todos", req.params.id)`; 200 with the record, 404 when `null` |
| `ApiService.fetchTodoById(todoId)` | `public/apiService.js` | Thin fetch helper, matching the existing helper style (`encodeURIComponent` on the id, throw on non-ok) |
| `copy-card-id` action definition | `public/cardActions.js` | Appended to `ACTION_DEFINITIONS` |
| `copyCardIdToClipboard(taskId)` | `public/todolist2.js` | Writes the id to the clipboard and shows the existing toast feedback |

No new DAL function — `getRecord` arrives in W1.

## 3. HTTP surface

**New route. No existing route modified.**

| Method | Path | Request | Success | Errors |
| --- | --- | --- | --- | --- |
| `GET` | `/todos/:id` | none | `200` — `{ todo }` | `404` when no card has that id; `500` on a read failure |

### Response shape

```json
{
  "todo": {
    "id": "todo-1786464124416",
    "text": "# [BE - endpoint-file-renamed - PRDV-16313](...)\n---\n### Current Step\n...",
    "completed": false,
    "completedDate": "",
    "creationTimestamp": "2026-08-11T16:02:04.416Z",
    "columnId": "column-1785764605417",
    "tag": "Task",
    "status": "In Progress",
    "secondaryTagIds": [],
    "lastModified": "2026-08-11T16:11:43.705Z"
  }
}
```

**The record is returned verbatim** — whatever properties the stored card carries, wrapped in `{ todo }`. No filtering, no reshaping, no derived values.

Two properties matter to the agent and are called out so they are not accidentally stripped by a future change:

- **`text`** — the guard in W6 reads the ticket id out of the first line.
- **`lastModified`** — the precondition value the agent carries into its writes (W4).

**Why `{ todo }` and not the bare record.** It matches the existing envelope on `PATCH /todos/:id` (`{ message, todo }`) and `POST /todos` (`{ message, todo }`), so a caller reading this app's endpoints sees one consistent shape. The bare record would be the only unwrapped card response in the API.

**`tag` shape warning.** `tag` is a string on most cards and an array on some (`todo-1784209049062` carries `["Investigation","Errors"]`). This route passes it through untouched and must not normalize it. Any consumer must tolerate both.

## 4. Modified files — nature of each change

| File | Change | Existing behavior affected |
| --- | --- | --- |
| `server.js` | Add one `app.get("/todos/:id", ...)` handler | None |
| `openapi.js` | Add `/todos/{id}` `get` operation and a `TodoByIdResponse` schema | None — additive document entries |
| `public/apiService.js` | Add `fetchTodoById`, export it | None |
| `public/cardActions.js` | Append one entry to `ACTION_DEFINITIONS` | Menu gains one row. Existing rows keep their order and behavior |
| `public/todolist2.js` | Add the clipboard handler and register it in the card-menu handler map | None |

## 5–8. Entities, migrations, DTOs, projections

- **New entities** — N/A.
- **Modified entities** — N/A. The card record is read, never written, by this work.
- **New migrations** — N/A.
- **New DTOs** — N/A for this repo's conventions; the response shape is documented in §3 and in `openapi.js`.
- **New projections** — N/A.

## Menu action detail

Appended to `ACTION_DEFINITIONS` in `public/cardActions.js`:

```js
{
  id: "copy-card-id",
  label: "Copy Card ID",
  icon: "fa-fingerprint",
  type: "action",
}
```

| Decision | Value | Reason |
| --- | --- | --- |
| Position | After `copy-all`, before `duplicate` | Groups with the other copy actions rather than landing among the destructive ones |
| Icon | `fa-fingerprint` | Distinct from `fa-copy`, which both existing copy actions already use, so the row is scannable |
| Label | `Copy Card ID` | Says exactly what lands on the clipboard |
| Clipboard content | The raw id only, e.g. `todo-1786464124416` | No prefix, no label, no JSON — it gets pasted into an agent prompt |
| Feedback | The existing toast mechanism used by `Copy` / `Copy All` | Reuses what is there rather than adding a second feedback path |

The action appears in both the board card menu and the notes-pane card menu, because both render from `ACTION_DEFINITIONS` — this is inherited, not new wiring.

## Spec tests

### `tests/api.test.js` — additions

| Scenario | Assertion |
| --- | --- |
| `GET /todos/:id` with a known id | `200`, `body.todo.id` matches, full record returned |
| Record carries `text` and `lastModified` | Both present and byte-identical to the stored values |
| Card whose `tag` is an array | `tag` comes back as an array, not coerced to a string |
| `GET /todos/:id` with an unknown id | `404` |
| `GET /todos/:id` with a url-encoded id containing a hyphen suffix (`todo-1785358880857-f4721f87`) | `200` — proves ids with extra segments resolve |
| **`GET /todos` still returns every card** | Unchanged response shape and count — the regression guard for the new sibling route |

### `tests/openapi.test.js` — additions

| Scenario | Assertion |
| --- | --- |
| `/todos/{id}` `get` documented | Path present with `200` and `404` responses |
| `TodoByIdResponse` schema | Declares `todo` |
| Existing paths untouched | The documented path list still contains every path it contained before, with the same operations |

### `tests/card-actions.test.js` — additions

| Scenario | Assertion |
| --- | --- |
| Action list contains `copy-card-id` | Present with the expected label and icon |
| Action order | `copy`, `copy-all`, `copy-card-id`, `duplicate`, … — the existing relative order of the nine current actions is unchanged |
| Handler wiring | The menu button invokes the clipboard handler with the card's `taskId` |
| Notes-pane menu | The action renders there too |
| **Existing actions unchanged** | All nine prior definitions keep their `id`, `label`, `icon`, and `type` |

### Manual check

| Step | Expected |
| --- | --- |
| Open a card menu, click Copy Card ID, paste | The raw card id, nothing else |
| `curl localhost:3010/todos/todo-1786464124416` | One card, not 2,731 |

## Cross-cutting

- **Risk:** Low. One additive route, one additive menu row.
- **Rollback:** Remove the route, the OpenAPI entries, the helper, the action definition, and the handler. No data or migration involved.
- **Delivery order:** Second. Depends on W1's `getRecord`. W6 depends on this.
- **Authorization:** N/A — no auth layer exists. Worth noting the app already exposes unauthenticated read and write on localhost; this route adds a read of data already fully readable via `GET /data`, so it changes nothing about exposure.
- **API docs:** **Required and in scope** — `openapi.js` gains the path and schema, with a test asserting it.
- **Tooling gates:** `npm run lint`, `node --test`, `npm audit --audit-level=high`. No dependency changes.

## Open questions

- Should the response include the card's notes so the agent gets everything in one call? Recommendation: no. Notes are already scoped at `GET /api/notes?eventId=`, and bundling them makes this route's shape depend on two sections. Two small calls beat one compound one here.
- Should `Copy Card ID` be hidden on cards that are not workflow cards? It is harmless everywhere and hiding it needs a definition of "workflow card" in the front end, which W3 owns. Recommendation: show it on every card.
