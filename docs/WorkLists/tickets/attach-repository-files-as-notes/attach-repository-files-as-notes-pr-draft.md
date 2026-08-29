# PR draft — WorkLists/attach-repository-files-as-notes

Filled at Phase 5. Branch `attach-repository-files-as-notes`, off `049d73f`.

## Title

`Attach repository files as note nodes`

## Ticket link

Personal project — no ClickUp ticket. Canonical artifacts: `dustin-thomason/docs/WorkLists/tickets/attach-repository-files-as-notes/`.
WorkLists card: `todo-1782484871383-6b5676db`.

## Description

**Problem.** A Markdown document that already exists on disk could not be shown or edited inside a WorkLists card without pasting a copy of it, and the copy diverged from the file the moment either was edited. The concrete case is this ticket's own artifacts: they live as files under `C:\dustin-thomason\docs\WorkLists\tickets\`, and the card tracking the ticket could not show one of them.

**Requirement.** A note's content must be able to come from a file rather than from its own record; that file must be editable in place with the edit landing in the file; and the program must be bounded to one folder the user names, reachable in full and never exceeded.

**Solution.** Two additions and one fix.

1. **A repository root** — one absolute path, declared in a new Settings tab, enforced at a single server-side chokepoint (`fileRepository.resolveInRoot`). Every read and write passes through it; no exported function accepts an already-resolved path, so there is nothing to bypass.
2. **A content-source indirection** — an optional `source` on the note record. A note without one behaves exactly as it did. A note with one reads and writes through the file, and its own `text` stays empty.
3. **A loopback bind** — `server.js` stops listening on `0.0.0.0` before any file route exists.

Everything else is reuse: the Dantalion document surface, the card ellipsis `extraActions` seam, the `expectedLastModified` → `409` concurrency shape, the settings dialog's tab structure, and Cairn's path rules and failure vocabularies.

### The decision worth reviewing

The request asked to port Cairn's `showDirectoryPicker` + IndexedDB permission machinery. That machinery exists because **Cairn has no server** — its own source comments justify the IndexedDB handle store by `localStorage` not existing in a worker. WorkLists has a server on the same machine already reading and writing real files, so the port would have bought a stronger OS-level guarantee at three measured costs: a native picker is an OS dialog Playwright cannot drive (every attach/read/write criterion loses automated coverage); browser-held content renders differently in a browser that was never granted the folder (failing the multi-place criterion on a second machine); and Chromium becomes a permanent hard requirement.

We took the server-resolved root and ported the **guarantee** rather than the mechanism — one root, everything under it reachable, nothing outside it, failures from a closed vocabulary — plus Cairn's path rules, with `realpath` containment **added** because a Node path can be walked out of through a symlink and a `FileSystemDirectoryHandle` cannot.

**This is a scope declaration, not an OS permission.** The Node process already has unrestricted `node:fs` authority; the root bounds where it may be pointed. The code says so where it matters, and the loopback bind is part of what makes it acceptable.

### Also in this diff, deliberately

- **`server.js` binds `127.0.0.1`** (overridable via `WORKLISTS_HOST`). It bound `0.0.0.0` with no authentication and unrestricted CORS; these routes widen what that reaches from "the board" to "any file under the root". Decided as a gate before the first file route, not discovered afterwards.
- **`dal.js` derives `TEMP_FILE_PATTERN` from `SECTIONS`** instead of duplicating the thirteen section names as a literal regex alternation. This is the first ticket to add a section since that duplication existed, so it is the first that could have silently broken the orphan sweep.

### Not built, deliberately

Attachment inventory ("where else is this document used") — drafted as job story 06 and left out of scope on the owner's reasoning that a pointer's consumer list is not a precondition of updating what it points at.

## Test evidence

Full scenario-first write-up: [`testing/attach-repository-files-as-notes-testing-implementation.md`](./testing/attach-repository-files-as-notes-testing-implementation.md). Thirteen scenarios stress-tested; two defects found by testing and fixed.

| Gate | Command | Scope | Result | Exception / risk |
| ---- | ------- | ----- | ------ | ---------------- |
| audit | `npm audit --audit-level=high` | WorkLists | **pass** (exit 0; 1 low + 1 moderate below threshold) | — |
| lint | `npm run lint` | WorkLists, whole tree | **pass** | — |
| tests | `npm test` (`node --test tests/*.test.js`) | WorkLists, 137 suites | **781 tests: 778 pass / 3 fail** | The three pre-existing card-action/Gemma failures, byte-identical to the pre-branch baseline |
| browser | `npm run test:browser` | notes-pane smoke, real Chromium | **14 pass / 0 fail** | — |

**Baseline:** before the branch, 708 tests / 705 pass / 3 fail. After: 781 / 778 / 3. **73 tests added, zero new failures.**

### Two defects found by testing, not by review

1. **The Files settings panel was registered but never mounted.** `panels.set("files", filesPanel)` is what tab switching reads; `body.appendChild` is what puts it on screen. Every source-contract assertion passed while the tab opened onto nothing. Fixed, and a guard added — but the reusable lesson is that source-contract coverage of a UI surface needs one real render behind it.
2. **The document picker closed the notes pane it was opened from.** The attach returned `201` and the toast said it worked, while the list went empty — every signal said success. The picker is a body-level overlay, so the pane's outside-click dismissal read it as a click outside. `isNotesPaneOpenTarget` already carried a comment describing this exact failure for the card-action menu; the picker was a second instance of a known problem.

A third worth noting: the first browser fixture put its repository root inside the server's `DATA_DIR` and was correctly refused by the overlap validation — a guard written for a hypothetical caught a real mistake within an hour of existing.

## Commit hash

```text
1bc302b0ddcdbbf0eb3a6de35764818aa7a5bdb0
```

## Checklist

- [x] Tests added/updated — 3 new suites (`file-repository`, `file-attachments`, `settings-file-repository`), an end-to-end browser scenario, and 3 existing assertions updated for shapes this change legitimately altered
- [x] Tests run — exact commands, scopes and results in the table above; final post-change state
- [x] Regression impact — **not claimed as isolated.** Shared infrastructure touched: `dal.js` `SECTIONS`, the note record, the notes render and save paths, `cardActions.js`. Eight named neighbour checks (PN-1…PN-8); `tests/note-checklist-patch.test.js` passes **with no edits to it**
- [x] API docs — five new routes plus `NoteSource` and four schemas in `openapi.js`, guarded by `tests/openapi.test.js`
- [x] Tooling gates — audit → lint → tests, in that order
- [x] Changelog session log appended before the commit
- [x] Conflicts / exceptions recorded

## Reviewers

**None requested** — personal project, and `git-commit-workflow` forbids requesting a reviewer unless asked in the moment.
