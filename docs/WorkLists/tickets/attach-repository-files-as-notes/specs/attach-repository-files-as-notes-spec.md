# Spec — Attach repository files as note nodes

| Field | Value |
| --- | --- |
| Project | WorkLists (personal) |
| Ticket slug | `attach-repository-files-as-notes` |
| WorkLists card | `todo-1782484871383-6b5676db` |
| Date | 2026-08-28, revised 2026-08-29 (batch and folder selection, Cairn tree port — LD-023 … LD-027) |
| Baseline | WorkLists `06b78be`, branch `main` |
| Source of truth for *what done means* | [job stories 01–05](../stories/attach-repository-files-as-notes-job-stories-index.md) — accepted |
| Source of truth for *why* | [investigation report](../investigations/attach-repository-files-as-notes-investigation.md) · [why-these-changes](../attach-repository-files-as-notes-why-these-changes.md) |
| Decisions | [locked-decisions.md](./attach-repository-files-as-notes-locked-decisions.md) — LD-001 … LD-027 |
| Test plan | [test-plan.md](../testing/attach-repository-files-as-notes-test-plan.md) |

> **Boundary.** This spec owns *how it gets built*. The job stories own *what done means* — this document cites their criteria and never restates or amends them. Where a criterion and this spec disagree, the criterion wins or the criterion changes on the record.

---

## Problem → Requirement → Solution

**Problem.** A Markdown document that already exists on disk cannot be shown or edited inside a WorkLists card without pasting a copy of it, and the copy diverges from the file the moment either is edited. The concrete case is this ticket's own artifacts: they live as files under `C:\dustin-thomason\docs\WorkLists\tickets\`, and the card tracking the ticket cannot show one of them.

**Requirement.** A note's content must be able to come from a file rather than from its own record; that file must be editable in place with the edit landing in the file; and the program must be bounded to one folder the user names, reachable in full and never exceeded.

**Solution.** Two additions and one fix.

1. A **repository root** — one absolute path, declared in Settings, enforced at a single containment chokepoint on the server.
2. A **content-source indirection** — an optional `source` on the note record. A note without one behaves exactly as it does today.
3. A **loopback bind** — `server.js` stops listening on `0.0.0.0` before any file route exists.

Everything else is reuse. The document surface, the menu seam, the concurrency shape, the settings dialog, and the failure vocabularies all already exist.

**Honest framing, stated once and not softened.** LD-001 chose a server-resolved root over Cairn's browser grant. This is a **scope declaration, not an OS permission**. The Node process already has unrestricted `node:fs` authority; the root bounds where that authority may be pointed. It is a weaker guarantee than Cairn's, chosen deliberately for the reasons in report §6, and the LD-002 loopback bind is part of what makes it acceptable.

---

## 1. Folder hierarchy

New paths under `WorkLists/`:

```text
WorkLists/
  fileRepository.js                      NEW — root resolution, containment, enumeration, read, write
  public/
    fileAttachments.js                   NEW — attach flow: browse, pick, detach; the client half
  tests/
    file-repository.test.js              NEW — containment, bounds, exclusions, failure vocabulary
    file-attachments.test.js             NEW — record shape, attach/detach, batch, source-aware save
    file-picker-tree.test.js             NEW — the ported tree: shape, counts, reach, provenance
    settings-file-repository.test.js     NEW — the Settings tab: validate, persist, read back
```

Modified:

```text
WorkLists/
  server.js         /api/files routes; loopback bind (LD-002)
  dal.js            new section; TEMP_FILE_PATTERN derived from SECTIONS (LD-015)
  openapi.js        the new routes, guarded by tests/openapi.test.js
  public/
    todolist2.js    the two indirection points, the Settings tab, the menu item, the path display
    index.html      one script tag for fileAttachments.js
  tests/
    browser-notes-smoke.js   end-to-end attach → render → edit → save → detach
```

`fileRepository.js` is a sibling of `dal.js` rather than part of it, deliberately: `dal.js` owns the app's own data directory, and the repository root is a **different root with a different authority story**. Folding them together would put the containment check inside the module that has always been allowed to write freely — and the whole point is that the new root is not.

`@cairn/dantalion` and `@worklists/markdown-kit` are **unchanged**. This is the premise the request rests on and it holds: the surface takes an opaque host-supplied key and never touches the filesystem (`components/document-surface/INTERFACE.md`), so a file-backed note is just another key with a different host-side source.

## 2. New classes / modules

This codebase is plain modules, not classes. Named exports:

| Export | File | Responsibility |
| --- | --- | --- |
| `getRepositoryRoot()` / `setRepositoryRoot(path)` | `fileRepository.js` | Read and validate the declared root |
| `resolveInRoot(relativePath)` | `fileRepository.js` | **The single chokepoint.** Path rules → resolve → `fs.realpath` containment. Every read and write goes through it; nothing else resolves a path |
| `listDocuments()` | `fileRepository.js` | Enumerate `.md`/`.mdc` under the root, applying every exclusion and bound |
| `readDocument(relativePath)` | `fileRepository.js` | `{ text, mtime }` or a `FILE_FAILURE` |
| `writeDocument(relativePath, text, expectedMtime)` | `fileRepository.js` | Write with precondition; `{ mtime }` or a `FILE_FAILURE` |
| `FILE_FAILURE` | `fileRepository.js` | The closed vocabulary (§9) |
| `attachDocuments(eventId, paths)` | `public/fileAttachments.js` | The batch attach call (LD-026) |
| `buildTree` / `countFiles` / `directFiles` / `visibleRows` / `ancestorPaths` | `public/fileAttachments.js` | The ported tree (§16a). Pure, so they are unit-tested without a DOM |
| `pickDocuments(documents, options)` | `public/fileAttachments.js` | The picker: tree, filter, multi-select, thresholds |

`resolveInRoot` being the only resolver is a **structural** guarantee, not a convention: the read and write functions take relative paths and call it themselves, so there is no signature in the module that accepts an already-resolved absolute path. A caller cannot bypass the check because there is nothing to call.

## 3. New entities

N/A — no ORM, no entities. The equivalent is §6.

## 4. Modified entities — the note record

`data/event-notes.json`, gaining one optional field (LD-016):

```jsonc
{
  "noteId": "…", "eventId": "todo-…", "text": "", "createdAt": "…", "lastModified": "…",
  "source": { "kind": "repository-file", "ref": "docs/WorkLists/tickets/…/spec.md" }
}
```

- **Optional.** Absent on all 562 existing records and never written to them. No migration, no backfill.
- **`text` on a file-backed note is `""` and stays `""`.** The file is the content. Two copies of the truth is the thing this ticket exists to remove; writing a cached copy into the record would reintroduce it one release later.
- **`kind` exists for one reason:** so a second source can be added without changing the shape. Exactly one kind exists now; anything else is refused.
- **`ref` is root-relative, forward-slashed** (LD-009). Never absolute, never `\`-separated — normalized on write, validated on read.

## 5. New migrations

N/A — JSON section files, no schema migrations. The additive field needs none (§4).

## 6. Data model / new DAL section

A new section holds the setting (LD-015):

```jsonc
// data/appSettings.json
{ "fileRepositoryRoot": "C:\\dustin-thomason" }
```

**`TEMP_FILE_PATTERN` must be derived from `SECTIONS` in the same change.** `dal.js:59` keeps the section list twice — an array, and the same names as a literal alternation in a regex. Adding a section to one and not the other silently breaks the orphan sweep for it. This ticket is the first to add a section since the duplication existed, so it is the first that can break it. Recorded as FDC-02; fixed here rather than deferred, because deferring it means shipping the exact bug the concern predicts.

**Cross-machine (closes story 01 Q2).** `data/` is OneDrive-synced, so the value follows the person. `C:\dustin-thomason` is a git clone present on each machine, so the same absolute path resolves on both. A machine without the clone gets the visible unreadable-root state (NP-8) — a named failure, not silence.

## 7. New DTOs / HTTP surface

| Method | Path | Request | Response |
| --- | --- | --- | --- |
| `GET` | `/api/files` | — | `{ root, configured, documents: [{ path, bytes, mtime }] }` |
| `GET` | `/api/files/content` | `?path=` | `{ path, text, mtime }` |
| `PUT` | `/api/files/content` | `{ path, text, expectedMtime }` | `{ path, mtime }` |
| `POST` | `/api/files/attach` | `{ eventId, paths[] }` | `{ attached[], skipped[{path, reason, message}], notes[] }` |
| `GET` | `/api/settings/file-repository` | — | `{ root, configured, valid, reason? }` |
| `PUT` | `/api/settings/file-repository` | `{ root }` | `{ root, configured, valid, reason? }` |

Status codes: `200`; `400` invalid path or failed root validation; `404` file not found; `409` mtime mismatch, carrying the current `mtime`; `422` root not configured; `500` unexpected.

**`openapi.js` is hand-authored and guarded by `tests/openapi.test.js`.** Every route above is documented there in the same change, or that gate fails.

## 8. Projections / domain inputs

N/A — no projection layer.

---

## Behaviour

### 9. The authority boundary

`resolveInRoot` does three independent jobs, in order. All three must pass.

1. **Path rules**, ported from `Cairn/components/vault-writer/filesystem.js:38-66`: relative only; no leading or trailing `/`; no `\`; no `//`; no empty segment; no `.` or `..` segment; no NUL; ≤ 4096 path; ≤ 255 per segment.
2. **Resolution and containment**: join to the root, then `fs.realpath` both and confirm the resolved file is inside the resolved root. **This step is the one Cairn does not have and does not need** — a `FileSystemDirectoryHandle` cannot be traversed upward at all, while a Node path can be walked out of through a symlink. Porting the path rules without this would look like parity and be a hole.
3. **Bounds** (LD-013), Cairn's declared limits ported unchanged: ≤ 5000 files enumerated, depth ≤ 12, ≤ 2 MB per document. Measured non-binding at the chosen root (450 files, depth 7, largest 600 KB) and kept anyway — they are the guard for a root pointed somewhere pathological later.

**Exclusions from enumeration:** dot-prefixed entries (LD-005); `node_modules`, `dist`, `build`, `out`, `coverage`, `.git`; any directory named `dnu` (LD-018); anything not `.md` or `.mdc` (LD-014).

**Why the dot rule is kept rather than relaxed** — this is the spec's most load-bearing exclusion and the reason is not obvious. `.claude/rules`, `.cursor/rules`, `.agents` and `.github` under the chosen root contain **generated** copies of files authored at `agents/rules/*.md`; `.claude/rules/worklists-card-sync.md` says so in its own header. The authored sources sit on a non-dot path and stay fully reachable. So the exclusion makes the `personal-methodology` prohibition on editing generated output **unbreakable by construction**: a generated file cannot be attached, therefore cannot be edited through a card. It stops being a style choice and becomes a guard.

**Failure vocabulary — closed, mirroring Cairn's two enums:**

`not-configured` · `invalid-path` · `outside-root` · `not-found` · `unreadable` · `too-large` · `conflict` · `write-failed`

Closed on purpose, and the reason is Cairn's: a failure nobody named is a failure nobody can respond to. There is deliberately no `other`. Every one of these is surfaced to the person as a distinct message — story 03's fifth criterion requires the *reason*, not a generic failure.

### 10. Settings

A ninth tab in `openModelSettingsDialog` (`public/todolist2.js:16828`), holding one path field, a Validate/Save action, and a status line.

Validated on save; refused with a named reason for: nonexistent; not a directory; unreadable; contains `DATA_DIR`; inside `DATA_DIR`. **A refused save leaves the previous value intact** (story 01's fourth criterion — "can point at it again without losing anything").

Until a root is configured, the attach item is disabled with the reason shown (story 01's fifth criterion), and every `/api/files` route answers `422 not-configured`.

### 11. Attach

One item on the card ellipsis menu, added through the existing `extraActions` seam — the same mechanism `getNotesPaneCollapseMenuActions` uses (`public/todolist2.js:4700`). No change to shared board-card action definitions, so the item cannot leak onto ordinary cards.

Choosing it opens the picker: a filter box above **Cairn's folder tree** (§16a), with a checkbox on every row.

- **Files** are selected individually (LD-020 — browse, never a typed path; a typed path would be a second route to the filesystem for the chokepoint to defend, for no gain).
- **A folder's checkbox selects the documents sitting directly inside it** (LD-023, LD-024). It is a selection shortcut, not an attachment of its own: a folder never becomes a note, because the document surface renders one Markdown document and a folder is not one.
- **The folder row's count is recursive; its checkbox is not.** The count orients (Cairn's behaviour); the reach is bounded so one click on a top-level folder cannot select the ~300 documents under `docs`. The two numbers differ on purpose, and a test asserts both together so a later change cannot quietly make one follow the other.
- **Already-attached and over-size documents are shown disabled with the reason**, not hidden. A missing row reads as a missing document.
- **The filter opens every folder holding a match**, so results are never left behind a collapsed folder the person did not close.
- **The footer states the count** and the Attach button names it. Above `attachWarnAbove` (10) the count is called out; above `attachMaxBatch` (25) Attach is disabled with an instruction to clear some (LD-025). Both numbers arrive with the listing rather than being written into the client, so there is one copy.

Confirming sends the whole selection to `POST /api/files/attach` — **one request, one write** (LD-026). The notes section is a single ~900 KB JSON file in the OneDrive-synced tree where `dal.atomicWrite` already retries `EBUSY`/`EPERM`, so a per-document loop would rewrite it once per document. Each path is validated and read individually, so a bad path is reported against itself in `skipped` while the rest still attach, and the toast names both halves.

**Scope note.** Multi-select is a fair reading of the request's plural *"attach files"*. Folder-selection is **new scope**, added by the owner on 2026-08-29 after seeing the built feature; the request's three uses of "folder" all refer to the permissioned root. Recorded in LD-023 rather than back-read into the original request.

### 12. Rendering

`renderNoteItemContent` (`public/todolist2.js:5152`) gains one branch: with `source`, the content comes from `GET /api/files/content` instead of `dataset.rawText`. Everything after that is the existing path — same Dantalion surface, same controls, same fallback to the markdown-kit renderer when the surface is unavailable.

Read-through on every render (story 02's third criterion). No watcher (LD-011): a file changing under an open note is caught at save by the precondition, not by polling. `fs.watch` is unreliable on Windows and worse under OneDrive, and read-through already delivers "current content, not a snapshot".

**The path is displayed where an ordinary note shows its timestamp** (LD-021). This is a safety requirement created by LD-006, not decoration: autosave writes a real file, so a person must be able to tell which notes do that. It is the smallest disclosure that achieves it and it occupies a slot that already exists.

`not-found` renders **in the note body as a stated failure**. The record survives; the note must never render blank (story 02's sixth criterion, test NP-3).

### 13. Editing and save

Editable by default, autosaving on focus exit — inherited unchanged from ordinary notes (LD-006). `saveNoteInlineEditor` (`public/todolist2.js:6166`) gains the mirror branch: with `source`, it calls `PUT /api/files/content` instead of `ApiService.updateNote`. The note's own `text` is never written.

The save carries the `mtime` read at load. Mismatch → `409` with the current value, the person is told, **and the draft stays in the editor** (LD-017; story 03's fourth criterion). Same shape as `PATCH /api/notes/:noteId`'s `expectedLastModified` (`server.js:2896-2920`) — mirrored rather than invented, so `tests/note-checklist-patch.test.js` remains the reference implementation.

Autosave is what makes the precondition load-bearing rather than defensive: two cards open on the same document, both autosaving on focus exit, is now a reachable state. Accepted risk: FDC-04.

### 14. Detach

The existing per-note delete control **is** detach for a file-backed note (LD-022): it removes the record and nothing else. Label and confirmation wording change; no new menu item.

There is no path from WorkLists to deleting a file (LD-007). Story 04's "the two are separate actions" is satisfied by the destructive one not existing — the strongest available form.

### 15. Blast radius — every surface that touches note text

Enumerated in report §7; completeness established by grepping `ApiService.updateNote|readNotes\(\)|writeNotes\(` across `public/` and the server.

| Surface | Disposition |
| --- | --- |
| `saveNoteInlineEditor` (`:6166`) | **Taught** — routes by `source` (§13) |
| `renderNoteItemContent` (`:5152`) | **Taught** — reads by `source` (§12) |
| `deleteTaskNote` (`:6184`) | **Taught** — relabelled; behaviour already correct (§14) |
| `persistRenderedMarkdownNoteCheckboxChange` (`:5210`) | **Taught** — the fallback renderer's checkbox path must route to the file too, or a checkbox toggle silently diverges from the document |
| `undoAiNoteRefine` (`:6227`) | **Blocked** — LD-010 |
| AI refine result apply (`:11052`) | **Blocked** — LD-010 |
| Gemma refine job (`server.js:2262`) | **Blocked** — LD-010, server-side |
| `PATCH /api/notes/:noteId` checklist steps (`server.js:2896`) | **Blocked** for `source` notes — the file's own path owns checklist state |
| `POST /api/notes` (`server.js:2847`) | **Extended** — accepts `source` |
| Template note creation (`server.js:2183`, `:2247`) | **Unchanged** — templates never produce a `source`; proven by test, not assumed |

**Blocked means proven unreachable by a test, not asserted** (test PN-7). LD-010's reason is specific: the chosen root contains `agents/rules/*.md` — the fifteen authored rule files governing every agent in this workspace. A refine reaching a file-backed note would let a model rewrite them, and the rewrite would be a real commit in a real repo.

### 16a. Provenance — what was ported from Cairn, and from where

The picker's tree is Cairn's explorer. Every borrowed piece names its origin in the code as well as here, so a later reader can diff against the original rather than guess, and a test asserts each pointer is still present.

| Cairn | WorkLists | What it does |
| --- | --- | --- |
| `app.js:941` `buildTree()` | `public/fileAttachments.js` `buildTree()` | Nests a flat node list; folders before files, then natural-order by name |
| `app.js:964` `countFiles()` | `public/fileAttachments.js` `countFiles()` | Recursive file count shown on a folder row |
| `app.js:1147` `renderTree()` | `public/fileAttachments.js` `visibleRows()` + `render()` | Flattens to visible rows; indents by `8 + depth * 13` px |
| `index.html:345` `treeFileTemplate` | `public/fileAttachments.js` `fileRow()` | File row shape |
| `index.html:359` `treeFolderTemplate` | `public/fileAttachments.js` `folderRow()` | Folder row shape |
| `styles.css:761-952` `.tree-*` | `public/todoliststyles2.css` `.tree-*` | Row, indent, chevron, label, child count |

**Deliberately not ported**, because they serve Cairn's editor rather than a picker: dirty and checked-out status codes, inline create and rename, drag, workspace-root removal. Cairn drives its colours from CSS custom properties; WorkLists has no equivalent token set on this surface, so the same rules are expressed against the literal colours the notes pane already uses.

**Added here and absent there:** selection. Cairn opens one document; this chooses a set.

### 16. Unchanged surfaces (verified, not assumed)

Named here with the check that proves each; executed as PN-1…PN-7 in the test plan.

Collapse-all menu item · `Show editing controls` and `Prompt Injection` per-note items · focus-exit autosave for ordinary notes · `fitNoteEditorToViewport` geometry · the checkbox-toggle `409` path (`tests/note-checklist-patch.test.js` must pass **with no edits to it** — an edit to that file is itself a finding) · the markdown-kit fallback renderer · `@cairn/dantalion` and `@worklists/markdown-kit` package contents.

---

## Cross-cutting

### Sequencing and gates

1. **Loopback bind (LD-002).** Before anything else. `app.listen(port, "127.0.0.1")`.
2. **`fileRepository.js` + containment tests.** Nothing reads a file until NP-1 is green, **including the symlink-escape case**.
3. **Settings + the DAL section + the `TEMP_FILE_PATTERN` derivation.**
4. **Read-only attach** — stories 01, 02.
5. **Edit and save with the precondition** — story 03.
6. **Detach** — story 04. Story 05 falls out of 4–5.

**Do not ship write before read.** A read-only slice is provable and reversible; a write slice is neither.

### Non-goals

Non-Markdown files · multiple roots · cloud providers (the 2026-07-09 blueprint's `StorageProvider` is its own Phase 3, behind a simple MVP — this is that MVP) · creating files from inside WorkLists · in-app file history (LD-012 — the root is a git repo) · live file watching (LD-011) · deleting files (LD-007) · attachment inventory (LD-008 → [story 06](../stories/attach-repository-files-as-notes-job-story-06-see-what-is-attached-where.md), drafted, **not built**).

### Authorization

N/A — WorkLists has no authentication and no roles. That absence is precisely why LD-002 exists; recorded rather than omitted.

### Registries / module wiring

N/A — no DI container. One script tag in `index.html`; `require` in `server.js`.

### Domain events / outbox

N/A — none in this codebase.

### API docs

`openapi.js` gains all five routes (§7). Guarded by `tests/openapi.test.js`.

### Spec tests

`tests/file-repository.test.js` · `tests/file-attachments.test.js` · `tests/settings-file-repository.test.js` · extensions to `tests/browser-notes-smoke.js`. Scenario-by-scenario mapping in the [test plan](../testing/attach-repository-files-as-notes-test-plan.md).

### Rollback

Additive throughout. Removing the routes, the Settings tab, and the two `source` branches restores prior behaviour exactly; existing records are untouched because none of them gains a field. Two exceptions that persist by design: the loopback bind, and the `TEMP_FILE_PATTERN` derivation — both are independent improvements and neither should be reverted with the feature.

---

## Locked Decisions From Q and A

Summary; the full ledger with sources, rejected paths and spec destinations is [locked-decisions.md](./attach-repository-files-as-notes-locked-decisions.md).

| # | Decision | Source |
| --- | --- | --- |
| LD-001 | Server-resolved root, **not** Cairn's browser grant | user |
| LD-002 | Bind `127.0.0.1` before any file route | user |
| LD-003 | Root is `C:\dustin-thomason` | user |
| LD-004 | Card `todo-1782484871383-6b5676db`, user-supplied | user |
| LD-005 | Keep Cairn's dot-entry skip — dot-folders hold generated output | **user-corrected** |
| LD-006 | Inherit autosave on focus exit | user |
| LD-007 | Detach only; the app never deletes a file | user |
| LD-008 | Usage visibility is not a gate → story 06, out of scope | user |
| LD-009 | Identity is the root-relative path | evidence |
| LD-010 | AI paths cannot reach a file-backed note | evidence |
| LD-011 | No live watcher; read-through on open | evidence |
| LD-012 | No in-app history — the root is a git repo | evidence |
| LD-013 | Cairn's bounds ported unchanged | evidence |
| LD-014 | `.md` and `.mdc` only | evidence |
| LD-015 | DAL section for the setting; derive `TEMP_FILE_PATTERN` | evidence |
| LD-016 | Optional `source` on the note record | evidence |
| LD-017 | Mirror the `expectedLastModified` → `409` shape | evidence |
| LD-018 | Exclude `dnu` directories | evidence |
| LD-019 | Non-goals confirmed | both |
| LD-020 | Browse to pick; no typed paths | evidence |
| LD-021 | Show the path where the timestamp goes | evidence |
| LD-022 | Detach reuses the delete control | evidence |

**Two of the agent's recommendations were overturned, and both improved the design.** LD-005 — the agent proposed including dot-folders on the premise they held frequently-edited docs; the owner supplied the fact that they hold generated output, which turned an exclusion into a guard. LD-006 — the agent proposed explicit-save-only; the owner chose parity, which cost one story-03 criterion (replaced on the record, not reinterpreted) and forced LD-021 as compensation. Recorded because a spec that hides where it was wrong teaches nothing.

## Reviewer

**Not applicable — personal project, no second reviewer.** Recorded explicitly rather than omitted: `orchestrate` Phase 3 requires a spec be submitted to whoever owns the design. Here the owner and the reviewer are the same person, and the spec is delivered in the conversation that commissioned it. There is no team wiki, no principal dev, and no spec PR to open.
