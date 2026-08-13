# W1 — Record-level data access — Spec

| Field | Value |
| --- | --- |
| Project | WorkLists |
| Ticket slug | `record-level-data-access` |
| Body of work | W1 of [`003-agent-workflow-sync-work-breakdown.md`](../../../features/agent-workflow-sync/003-agent-workflow-sync-work-breakdown.md) |
| Governing decisions | [`001`](../../../features/agent-workflow-sync/001-agent-workflow-sync-decisions.md) → record-level data access (D0, section-scoped storage behind a record-level interface) and the additive-only constraint |
| Serves job story | [04 — Nothing I typed disappears](../../agent-workflow-sync/stories/agent-workflow-sync-job-story-04-nothing-i-typed-disappears.md) |
| Repo | `WorkLists` (`c:\Users\dktho\OneDrive\SCRIPTS ALL SYSTEMS\To Do List\WorkLists`) |
| Date | 2026-08-12 |

## Problem → Requirement → Solution

**Problem.** The DAL has no path to one record. `readDB` loads all 12 section files under a global lock; `writeDB` rewrites all 12 atomically. Any new endpoint that wants one card or one note must therefore load and rewrite the entire database, which makes a per-item agent write disproportionate to what it changes.

**Requirement.** A caller must be able to read one record and write one record, touching only the section that record lives in, without altering how any existing caller behaves.

**Solution.** Add four functions beside the existing pair — `readSection`, `writeSection`, `getRecord`, `patchRecord` — sharing the existing lock. Change no existing function and no existing caller.

## Additive-only compliance

**The test:** with the new functions never called, the code path that runs today is the code path that still runs.

| Guarantee | How it is met |
| --- | --- |
| No existing DAL function changes | `readDB`, `readDBUnlocked`, `writeDB`, `writeDBUnlocked`, `readNotes`, `writeNotes`, `updateTodo`, `updateTaskStatus`, and every other export keep their current bodies. Verified by diff — this spec adds lines, it does not edit them |
| No existing caller is repointed | No call site of `readDB` / `writeDB` is modified. `updateTodo` continues to rewrite all 12 sections |
| No API surface change | This body of work adds no route and modifies none. `openapi.js` is untouched |
| No data-format change | Section files keep their exact current shape and serialization (`JSON.stringify(data, null, 2)`) |
| No new dependency | Uses `node:fs/promises`, `path`, and `crypto`, all already required |

**Consumers of the new functions** — named so the value of this body of work is not overstated:

| Consumer | Uses | Why not the others |
| --- | --- | --- |
| W2 `GET /todos/:id` | `getRecord` | New route, so free to use the new path |
| W4 `PATCH /api/notes/:noteId` | `getRecord`, `patchRecord` | New verb on an existing path; the existing `PUT` keeps using `writeNotes` |
| W5 `PATCH /todos/:id` | **none** | It extends an existing endpoint that runs through `updateTodo`, which must keep its current behavior. Card writes continue to rewrite 12 sections |

So this work makes the **new** paths surgical. Existing paths keep the amplification, by instruction. See `001` → *What this constraint costs*.

## 1. Folder hierarchy

No new folders. All changes land in existing files:

```text
WorkLists/
  dal.js                      additions only
  tests/
    dal-record-access.test.js  new
    api.test.js                unchanged — serves as the regression proof
```

## 2. New functions

Adding to `dal.js`. Names chosen to read as record operations rather than file operations, per D0/R2.

| Function | Signature | Behavior |
| --- | --- | --- |
| `readSection` | `async readSection(section) -> Array` | Reads and parses exactly one section file. Applies the same missing-file defaults `readDBUnlocked` applies (see §4). Acquires the shared lock. |
| `writeSection` | `async writeSection(section, data) -> void` | Atomically writes exactly one section file via the existing `atomicWrite`. Rejects a non-array `data`. Acquires the shared lock. |
| `getRecord` | `async getRecord(section, id) -> object \| null` | `readSection`, then locate by that section's id key (§3). Returns `null` when absent. Never throws for a missing record. |
| `patchRecord` | `async patchRecord(section, id, partial, options) -> object` | Read-modify-write within one lock acquisition: read the section, locate the record, shallow-merge `partial`, stamp `lastModified`, write the section, return the updated record. |

### `patchRecord` options and errors

```text
options = {
  expectedLastModified?: string   // when present, enforced as a precondition
}
```

| Condition | Behavior |
| --- | --- |
| Section name not recognized | throw `createDataError(400, ...)` |
| Record not found | throw `createDataError(404, ...)` |
| `expectedLastModified` present and does not equal the stored value | throw `createDataError(409, ...)`, with the current `lastModified` on the error. **Nothing is written.** |
| `partial` is not a plain object | throw `createDataError(400, ...)` |
| Success | stamp a fresh `lastModified` via the existing `getTimestamp`, write, return the record |

`createDataError` already exists (`dal.js:613`) and `server.js`'s `sendDalError` already maps `statusCode` to the response — so the 404/409/400 mapping needs no server change here.

### Locking — the correctness requirement

`patchRecord` and `writeSection` **must** acquire the same module-level lock via the existing `acquireLock`, and must perform their read and write inside **one** acquisition.

**Why this is not optional.** If a section write interleaves with a `writeDB` that is holding a stale full-database snapshot, `writeDB` rewrites all 12 files from that snapshot and the section write is silently lost. Sharing the lock is what makes the additive path safe to run beside the existing whole-database path. A second lock, or no lock, reintroduces exactly the data-loss class job story 04 exists to prevent.

Internal unlocked variants (`readSectionUnlocked`, `writeSectionUnlocked`) are private and used only so `patchRecord` can do read-modify-write in one acquisition without recursive locking — the same shape `readDBUnlocked` / `readDB` already use.

## 3. Section id keys

Records are identified by different property names per section. A lookup map, not a guess:

| Section | Id property |
| --- | --- |
| `todos` | `id` |
| `event-notes` | `noteId` |
| `boards` | `id` |
| `columns` | `id` |
| `primaryTags` | `id` |
| `secondaryTags` | `id` |
| `statuses` | `id` |
| `models` | `id` |
| `classificationPrompts` | `id` |
| `statusVisibility` | not a record collection — `getRecord` / `patchRecord` reject it |
| `pinnedBoardIds` | not a record collection — reject |
| `schedulerTaskIds` | not a record collection — reject |

Id comparison uses the existing `normalizeId` so behavior matches how every current lookup compares ids.

## 4. Missing-file defaults

`readDBUnlocked` returns defaults instead of throwing when a section file is absent, but **only** for `schedulerTaskIds`, `classificationPrompts`, `statuses`, and `statusVisibility` (`dal.js:502-510`). `readSection` reproduces that behavior exactly, including which four sections it applies to, so a caller cannot observe a difference between reading a section through the new function and through `readDB`.

For any other section, a missing file throws the same `Failed to read section file` error, with the same message shape.

Corrupt JSON keeps the existing behavior too: log the file path, log a surrounding snippet on `SyntaxError`, rethrow.

## 5–8. Entities, migrations, DTOs, projections

- **New entities** — N/A. No new stored shape.
- **Modified entities** — N/A. No stored shape changes.
- **New migrations** — N/A. No data is moved, renamed, or reformatted.
- **New DTOs** — N/A. No HTTP surface in this body of work.
- **New projections** — N/A.

## HTTP surface

**N/A — no route added, changed, or removed.** `server.js` and `openapi.js` are untouched by W1. The routes that consume these functions arrive in W2, W4.

## Spec tests

New file `tests/dal-record-access.test.js`, following the existing `node:test` + `DATA_DIR` isolation pattern used by `tests/api.test.js`.

### Happy path

| Scenario | Assertion |
| --- | --- |
| `readSection('todos')` | Returns the array from `todos.json` only |
| `getRecord('todos', id)` | Returns exactly the one matching record |
| `getRecord('event-notes', noteId)` | Locates by `noteId`, not `id` |
| `patchRecord('todos', id, {...})` | Returns the merged record with a fresh `lastModified` |
| `writeSection('todos', arr)` | `todos.json` contains `arr`; serialization matches the existing 2-space format |

### Failure paths

| Scenario | Assertion |
| --- | --- |
| `getRecord` with unknown id | Returns `null`, does not throw |
| `patchRecord` with unknown id | Throws with `statusCode` 404; **no file is written** |
| `patchRecord` with stale `expectedLastModified` | Throws with `statusCode` 409, carries the current value; **no file is written** |
| `patchRecord` on `pinnedBoardIds` | Throws with `statusCode` 400 |
| `writeSection` with a non-array | Throws with `statusCode` 400; file unchanged |
| `readSection` on a missing non-defaulted file | Throws the same error `readDB` throws |
| `readSection` on a missing defaulted file (`statuses`) | Returns the default records, matching `readDB` |
| `readSection` on corrupt JSON | Throws; error identifies the file |

### Section isolation — the core assertion of this body of work

| Scenario | Assertion |
| --- | --- |
| `writeSection('event-notes', ...)` | `event-notes.json` changes; the other 11 files are byte-identical and their mtimes are unchanged |
| `patchRecord('todos', ...)` | `todos.json` changes; the other 11 files unchanged — including `columns.json` and `boards.json`, because `patchRecord` does **not** replicate `updateTodo`'s timestamp cascade |

**Note the deliberate difference:** `updateTodo` stamps the card's column and boards via `touchColumnAndBoardForTodo`. `patchRecord` does not, because it is a generic record operation with no knowledge of card semantics. Any caller needing the cascade must use `updateTodo`. This is called out in W4's spec because notes have no cascade, so it does not arise there — but it is a trap for any future caller patching a card directly.

### Additive-only regression proof

| Scenario | Assertion |
| --- | --- |
| Full existing suite | `node --test` passes unchanged, no test edited |
| `readDB` / `writeDB` behavior | A `writeDB` still rewrites all 12 files — asserted explicitly, so a future well-meaning optimization cannot silently change it without failing a test |
| Interleaving | A `patchRecord` and a `writeDB` issued concurrently both land; neither is lost. Proves the shared lock |

## Cross-cutting

- **Parent feature:** `docs/WorkLists/features/agent-workflow-sync/`.
- **Risk:** Low. Purely additive, no existing line edited, and the existing suite is a full regression net. The one real risk is the lock: a private unlocked helper called from a locked context would deadlock, which the interleaving test is designed to catch.
- **Rollback:** Delete the added functions and the new test file. No data or contract to revert.
- **Delivery order:** First of the seven. W2 and W4 depend on it.
- **Authorization:** N/A — no auth layer exists in this app.
- **API docs:** N/A — no HTTP surface. Named explicitly rather than omitted, per the shipping checklist.
- **Tooling gates:** `npm run lint` (prettier) and `node --test` both apply. `npm audit --audit-level=high` applies; no dependency changes.

## Open questions

- Should `putRecord` (whole-record replace) exist now, or be added when something needs it? Nothing in W2–W7 needs it. Recommendation: leave it out; adding an unused export invites a caller to reach for the wrong tool.
- Should `patchRecord` support a section-level append (adding a record rather than merging one)? W3 will need to create checklist template records. Recommendation: decide in W3, so the shape is driven by a real caller rather than guessed here.
