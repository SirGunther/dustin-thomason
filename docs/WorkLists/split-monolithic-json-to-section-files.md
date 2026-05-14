# Split monolithic JSON to section files

> **Status:** Spec finalized — ready for implementation
> **Date:** 2026-05-14
> **Scope:** Backend data layer restructure for WorkLists (Express + file-backed JSON)

---

## Summary

Replace the single `WorkBoardDB.json` datastore with three section files (`boards.json`, `columns.json`, `todos.json`) inside a `data/` directory. All API contracts stay identical. The change is fully encapsulated inside the DAL — no frontend modifications required.

---

## 1. Folder hierarchy

New paths under `WorkLists/`:

```
data/
  boards.json          (runtime — gitignored)
  columns.json         (runtime — gitignored)
  todos.json           (runtime — gitignored)
  boards.example.json  (committed — schema reference)
  columns.example.json (committed — schema reference)
  todos.example.json   (committed — schema reference)
tests/
  api.test.js          (integration tests — node:test)
```

## 2. New files

| File | Purpose |
|------|---------|
| `data/boards.example.json` | Schema reference: `[]` |
| `data/columns.example.json` | Schema reference: `[]` |
| `data/todos.example.json` | Schema reference: `[]` |
| `tests/api.test.js` | Integration tests covering every endpoint, migration paths, and error conditions |

## 3. Modified files

| File | Change |
|------|--------|
| `dal.js` | Replace single-file `readDB`/`writeDB` with three-file read/write behind the same signatures. Add `initialize()` for migration and cold-start seeding. Add write-then-rename atomicity. Remove `SyntaxError` retry logic. Keep `EBUSY` retry on rename. Accept `DATA_DIR` env var for test isolation. |
| `server.js` | Export `app`. Add `require.main === module` guard that calls `dal.initialize()` then `app.listen()`. Remove duplicate `PATCH /todos/:id` (dead toggle handler on lines 81–91). |
| `package.json` | Change `start-server` to `node server.js`. Add `"test": "node --test"`. Remove `ngrok` dependency. |
| `.gitignore` | Add `data/*.json`, `data-test/`, `WorkBoardDB.backup.json`. Remove old `WorkBoardDB.json` and `WorkBoardDB-*.json` entries. |
| `nodemon.json` | Rewrite to watch `.` (project root JS files), ignore `data/**/*.json` and `node_modules/**`. |

## 4. Deleted files

| File | Reason |
|------|--------|
| `WorkBoardDB.example.json` | Replaced by per-section examples in `data/` |
| `start.js` | ngrok launcher — ngrok is not in use |
| `test-ngrok.js` | ngrok test script — ngrok is not in use |
| `findPosition.js` | One-off byte-position debugger referencing the old monolith |
| `script.js` | One-off migration script with hardcoded paths to another machine |
| `todolist2backup.js` | Stale copy of `todolist2.js` — version control serves the backup role |
| `configs/nodemon.json` | Stale config referencing non-existent `New/` path |
| `configs/bs-config.json` | Stale config with wrong port, wrong paths, wrong filenames |

The `configs/` directory is removed entirely.

## 5. Data structure

No structural changes to the data itself. The three top-level keys of the monolith become three files with identical content:

| Old (single file) | New (three files) |
|---|---|
| `WorkBoardDB.json` → `{ "boards": [...], "columns": [...], "todos": [...] }` | `data/boards.json` → `[...]` |
| | `data/columns.json` → `[...]` |
| | `data/todos.json` → `[...]` |

Relational ID linkage is unchanged: boards reference columns by ID, columns reference todos by ID.

## 6. HTTP surface

**No API contract changes.** Every endpoint keeps its current method, path, request shape, and response shape.

| Method | Path | DAL function | Sections touched |
|--------|------|-------------|-----------------|
| `GET` | `/data` | `readDB` | boards, columns, todos (read all, merge, return combined object) |
| `POST` | `/data` | `writeDB` | boards, columns, todos (decompose body, write all) |
| `POST` | `/boards` | `createBoard` | boards |
| `DELETE` | `/boards/:boardId` | `deleteBoard` | boards, columns, todos (cascade) |
| `PATCH` | `/boards/:boardId/title` | `renameBoard` | boards |
| `PUT` | `/boards/:boardId` | `updateBoardColumnIds` | boards, columns (validation) |
| `POST` | `/columns` | `addColumn` | columns, boards |
| `DELETE` | `/columns/:id` | `deleteColumn` | columns, todos, boards |
| `PUT` | `/columns` | `updateColumnsOrder` | columns |
| `POST` | `/todos` | `addTodo` | todos, columns |
| `DELETE` | `/todos/:id` | `deleteTodo` | todos, columns |
| `PATCH` | `/todos/:id` | `updateTodo` | todos |
| `PATCH` | `/todos/:id/column` | `updateTaskColumn` | todos |
| `PATCH` | `/todos/:id/tag` | `updateTaskTag` | todos |
| `PATCH` | `/todos` | `updateMultipleTodos` | todos |
| `PUT` | `/tasksOrder` | `updateTasksOrder` | columns |

The dead duplicate `PATCH /todos/:id` handler (toggle — lines 81–91 in current `server.js`) is removed. It was unreachable due to Express route shadowing.

## 7. DAL internals

### `readDB`

1. Acquire lock.
2. Read `boards.json`, `columns.json`, `todos.json` in parallel (`Promise.all`).
3. Parse each. On `SyntaxError` in any file: fail immediately with an error identifying the corrupt file (no retries — atomic writes prevent partial-file states).
4. Return `{ boards, columns, todos }`.
5. Release lock.

### `writeDB(data)`

1. Acquire lock.
2. Destructure `data` into `{ boards, columns, todos }`.
3. Stringify each section.
4. Write each to a temp file (`boards.tmp.json`, `columns.tmp.json`, `todos.tmp.json`).
5. Rename each temp file onto the target file (atomic per file).
6. On `EBUSY` during rename: retry up to 5 times with 1-second delay (OneDrive file-lock mitigation).
7. Release lock.

### `initialize()`

Startup logic called before `app.listen()`:

1. If `data/` directory does not exist, create it.
2. **Migration path:** If `WorkBoardDB.json` exists at project root:
   - Read and parse the monolith.
   - Write `boards.json`, `columns.json`, `todos.json` into `data/`.
   - Rename `WorkBoardDB.json` to `WorkBoardDB.backup.json`.
   - Log: `Migrated WorkBoardDB.json → data/{boards,columns,todos}.json (backup at WorkBoardDB.backup.json)`.
3. **Cold-start path:** If no monolith and section files don't exist:
   - Seed each missing file with `[]`.
   - Log: `Initialized empty data files.`
4. **Already migrated:** All three files exist, no monolith — no-op.

### Environment variable

`DATA_DIR` — overrides the default `data/` path. Used by tests to isolate to `data-test/`. The DAL resolves all file paths from `process.env.DATA_DIR || path.join(__dirname, 'data')`.

## 8. Server startup (`server.js`)

```
const app = express();
// ... middleware, routes ...
module.exports = app;

if (require.main === module) {
  dal.initialize().then(() => {
    app.listen(port, () => { ... });
  });
}
```

When imported by tests: exports `app` without listening.
When run directly (`node server.js`): initializes data layer, then listens.

## 9. Test coverage

**Framework:** `node:test` (built-in, zero dependencies).
**Runner:** `npm test` → `node --test`.
**Isolation:** `DATA_DIR=data-test/` — each suite seeds fixtures and tears down.

### Test matrix

**Category 1 — Migration**

| Scenario | Assertion |
|----------|-----------|
| Existing `WorkBoardDB.json` with data | Three files created in `data/`, content matches original sections, backup exists |
| Fresh install (no files) | Three files seeded with `[]` |
| Already migrated (files exist, no monolith) | No-op, data untouched |

**Category 2 — Read path**

| Scenario | Assertion |
|----------|-----------|
| `GET /data` | Returns `{ boards, columns, todos }` matching file contents |
| One section file missing | Server returns error, not a partial object |
| One section file has invalid JSON | Fails with error identifying the corrupt file |

**Category 3 — Write path (every mutation endpoint)**

| Endpoint | Assertion |
|----------|-----------|
| `POST /data` | Writes all three files; subsequent `GET /data` returns new data |
| `POST /boards` | Board appears in `boards.json` |
| `DELETE /boards/:boardId` | Board, its columns, and their todos removed across all three files |
| `PATCH /boards/:boardId/title` | Board title updated in `boards.json` |
| `PUT /boards/:boardId` | Board `columnIds` updated; invalid IDs rejected |
| `POST /columns` | Column in `columns.json`, board's `columnIds` updated in `boards.json` |
| `DELETE /columns/:id` | Column removed, todos removed, board `columnIds` updated |
| `PUT /columns` | Column order updated in `columns.json` |
| `POST /todos` | Todo in `todos.json`, column `taskIds` updated in `columns.json` |
| `DELETE /todos/:id` | Todo removed, column `taskIds` updated |
| `PATCH /todos/:id` | Todo fields merged in `todos.json` |
| `PATCH /todos/:id/column` | Todo `columnId` updated |
| `PATCH /todos/:id/tag` | Todo `tag` updated |
| `PATCH /todos` (batch) | Multiple todos updated in `todos.json` |
| `PUT /tasksOrder` | Column `taskIds` reordered in `columns.json` |

**Category 4 — Cross-section consistency**

| Scenario | Assertion |
|----------|-----------|
| Delete board | Cascades remove columns and todos from their respective files |
| Delete column | Cascades remove todos, updates board `columnIds` |
| Add todo | Appears in `todos.json` and column `taskIds` in `columns.json` |

**Category 5 — Atomic writes**

| Scenario | Assertion |
|----------|-----------|
| After successful write | No `*.tmp.json` files remain in `data/` |

## 10. Configuration changes

### `package.json`

```json
{
  "dependencies": {
    "body-parser": "^1.20.2",
    "cors": "^2.8.5",
    "express": "^4.18.2"
  },
  "scripts": {
    "start-server": "node server.js",
    "test": "node --test"
  }
}
```

`ngrok` dependency removed.

### `nodemon.json`

```json
{
  "watch": ["."],
  "ext": "js",
  "ignore": ["data/**/*.json", "data-test/**", "node_modules/**"]
}
```

### `.gitignore` additions

```
data/*.json
!data/*.example.json
data-test/
WorkBoardDB.backup.json
```

Old entries for `WorkBoardDB.json` and `WorkBoardDB-*.json` removed.

## 11. Files not modified (confirmed safe)

| File | Reason |
|------|--------|
| `public/apiService.js` | Consumes HTTP only — contract unchanged |
| `public/todolist2.js` | Consumes HTTP only — contract unchanged |
| `public/index.html` | Loads the same scripts |
| `public/todoliststyles2.css` | No data dependency |
| `code.js` | localStorage-only prototype — no server interaction |
| `exportboard.js` | localStorage-only — commented out in `index.html` |

## Cross-cutting

- **Parent story:** This spec covers the full user story for splitting the monolithic JSON datastore.
- **Risk:** High — many DAL functions depend on the read/write path being changed. Mitigated by keeping all API contracts and DAL function signatures identical, isolating the change to file I/O internals.
- **Rollback:** Rename `WorkBoardDB.backup.json` back to `WorkBoardDB.json`, revert code. The backup created by auto-migration enables rollback without data loss.
- **Delivery order:** DAL changes first (with migration), then server.js updates, then file deletions, then tests. Tests validate the final state.

## Optional callouts

- **Domain exceptions** — `initialize()` should throw (not swallow) if migration reads a corrupt monolith. The server should not start with bad data.
- **Spec tests** — `tests/api.test.js` covers all categories above. No deferred tests.
- **Authorization** — N/A, no auth layer exists.
- **Breaking changes** — None. All HTTP contracts preserved.
