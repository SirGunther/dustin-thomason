# Coverage ledger — WorkLists/attach-repository-files-as-notes

Investigation question: can a Markdown file on disk become a note node — read, edited, saved back, attached in several places — and where is the program allowed to look for it?
Repo(s): WorkLists, Cairn, Dantalion · Baseline commit: `06b78be` (WorkLists) · Started: 2026-08-28

## Consulted

- `docs/*/tickets/*/investigations/*-coverage-ledger.md` and `docs/**/*coverage-ledger*` for "WorkLists", "notes", "dal", "filesystem", "permission" — **none found for WorkLists**. Eleven ledgers exist (atlas ×6, ClickUpWideLayout ×2, Jaimie ×1, nova ×2); none covers this project or subsystem. Nothing reused, nothing reopened. This is the first WorkLists coverage ledger.
- `docs/WorkLists/features/` and `docs/WorkLists/tickets/` for prior file-system work — **found, non-ledger, read and used**: `features/file-system/kanban-file-system-blueprint.md` (2026-07-09) and `tickets/onedrive-per-record-file-spike/specs/onedrive-per-record-file-spike-spec.md` (2026-08-12). Both cited in the report; the spike's findings on `atomicWrite` contention and inert host-scoped files were **reused rather than re-derived**.
- `docs/WorkLists/worklists-app-changelog.md` — Current state (line 3927) plus the four newest session-log entries. Reused for the Dantalion-surface and markdown-kit-extraction facts.

## Areas examined

### 1. WorkLists note storage — `dal.js`, `data/event-notes.json`

| Field | Value |
| --- | --- |
| Inspected | `SECTIONS` array, `TEMP_FILE_PATTERN` regex, `DATA_DIR`/`LEGACY_DIR` resolution, `sectionPath`, `readNotes`/`writeNotes` call sites, the record shape of all 562 notes |
| Findings | A note is `{noteId, eventId, text, createdAt, lastModified}` — content is the record's own `text`, with no concept of an external source. `DATA_DIR` (`dal.js:9-13`) is the app's only filesystem root, env-overridable, defaulting to `<repo>/data`. `SECTIONS` (`dal.js:59`) and `TEMP_FILE_PATTERN` duplicate the same section names in an array and a literal regex — a drift pair. |
| Status | fully-inspected |
| Commit | `06b78be` · 2026-08-28 |
| Evidence | `dal.js:9-13`, `dal.js:59-77`, `data/event-notes.json` (first record + key union over the first 500) |
| Notes | The `SECTIONS`/`TEMP_FILE_PATTERN` duplication is the highest drift risk if a new DAL section is ever added for this feature. The recommended design avoids adding one. |

### 2. WorkLists notes HTTP surface — `server.js`

| Field | Value |
| --- | --- |
| Inspected | `GET/POST /api/notes`, `PUT/PATCH/DELETE /api/notes/:noteId`, the Gemma refine-note job, note creation inside `POST /api/cards/from-template`, `sendDalError` |
| Findings | `PATCH` already implements optimistic concurrency — `expectedLastModified` in, `409` out carrying the server's current `lastModified` — which is a directly reusable shape for a file write with an mtime precondition. `PUT` overwrites unconditionally. `DELETE` removes the row and nothing else. |
| Status | contributing |
| Commit | `06b78be` · 2026-08-28 |
| Evidence | `server.js:2836`, `:2847`, `:2872`, `:2896-2920`, `:2923-2940`, `:2262-2295`, `:2183`, `:2247` |
| Notes | — |

### 3. WorkLists notes client — `public/todolist2.js`, `public/apiService.js`

| Field | Value |
| --- | --- |
| Inspected | `loadTaskNotes`, `renderTaskNotes`, `createNoteItem`, `renderNoteItemContent`, `createWorkListsDantalionEditor`, `saveNoteInlineEditor`, `deleteTaskNote`, `undoAiNoteRefine`, `toggleNoteActionMenu`, `setNoteEditingControlsVisible`, `fitNoteEditorToViewport`, `getNotesPaneCollapseMenuActions`, `getNotesPaneCardActionMenuOptions`, `ApiService` note methods |
| Findings | Content enters at exactly one place (`createNoteItem` → `dataset.rawText` ← `note.text`) and leaves at exactly one place (`saveNoteInlineEditor` → `ApiService.updateNote`). Both are unbranched. The card ellipsis menu takes notes-pane-only items through an existing `extraActions` seam. The per-note menu (`.notes-pane-note-menu`) and the destructive action row are already separate DOM surfaces. |
| Status | contributing |
| Commit | `06b78be` · 2026-08-28 |
| Evidence | `todolist2.js:5094`, `:5140`, `:5152-5215`, `:6166-6182`, `:6184`, `:6227`, `:5219-5260`, `:5262-5285`, `:4700-4718`, `:719`, `:766`, `:792`; `apiService.js:478-515` |
| Notes | The two unbranched points are the indirection sites. Blast-radius enumeration (report §7) was derived from a grep of `ApiService.updateNote\|readNotes()\|writeNotes(` across `public/` and the server. |

### 4. WorkLists settings surface — `public/todolist2.js:16828+`, `public/index.html`

| Field | Value |
| --- | --- |
| Inspected | `openModelSettingsDialog`, its tab construction, `#model-settings-btn` wiring |
| Findings | A full tabbed Settings dialog already exists with eight tabs (General, Tag Colors, Secondary Tags, Statuses, Shortcuts, APIs, Prompts, Card Templates), built from a plain array with a `getModelSettingsTabsWithGeneralFirst` ordering helper. Adding a ninth is additive. Closes story 01 Q3. |
| Status | ruled-out (as a gap — the surface exists, so nothing new is needed here) |
| Commit | `06b78be` · 2026-08-28 |
| Evidence | `todolist2.js:16828-16910`, `todolist2.js:1375-1382`, `public/index.html:177-181` |
| Notes | Panel bodies below the tab list were not read in detail — only the tab framework, which is what the question needed. **Partial in that narrow sense**; re-read the panel construction before writing the new tab's body. |

### 5. WorkLists settings persistence conventions

| Field | Value |
| --- | --- |
| Inspected | `theme.js`, `shortcutRegistry.js`, `persistNotesPaneWidth`, `data/models.json`, `data/pinnedBoardIds.json`, `data/cardTemplates.json` |
| Findings | A consistent two-way split: view state → `localStorage`; anything the server must act on → a DAL section. No counter-example found in either direction. A repository root the server must resolve is therefore server-side by the app's own convention. |
| Status | fully-inspected |
| Commit | `06b78be` · 2026-08-28 |
| Evidence | `theme.js:140`, `shortcutRegistry.js:19`, `todolist2.js:3885-3900`, `dal.js:59` |
| Notes | — |

### 6. WorkLists server exposure — `server.js` bind, CORS, auth

| Field | Value |
| --- | --- |
| Inspected | `app.listen` call, `cors()` usage, a grep for authentication middleware across `server.js` |
| Findings | `app.listen(port)` with no host → binds `0.0.0.0`. `app.use(cors())` with no options. **No authentication middleware anywhere.** Any LAN device can already read and write the board; file routes would widen that to the documents root. |
| Status | contributing |
| Commit | `06b78be` · 2026-08-28 |
| Evidence | `server.js:3610-3620`, `server.js:39`, grep for `authenticate\|authorization\|Bearer\|passport` returning only Gemini `apiKey` config hits |
| Notes | Recorded as a future-development concern and as a recommended gate, not assumed into scope. |

### 7. WorkLists test harness — `tests/`

| Field | Value |
| --- | --- |
| Inspected | Directory listing (46 files), `browser-notes-smoke.js` setup, `openapi.test.js` guard, presence of `note-checklist-patch.test.js`, `markdown-kit-package.test.js` |
| Findings | Browser tests spawn the real server on a random port against a temp `DATA_DIR` and drive real Chromium via Playwright — so a native OS folder picker is undrivable. `openapi.js` is hand-authored and guarded, so any new route must be documented there. `markdown-kit-package.test.js` enforces a no-duplicate-copies rule on the package's files. |
| Status | contributing |
| Commit | `06b78be` · 2026-08-28 |
| Evidence | `tests/browser-notes-smoke.js:1-60`, `tests/openapi.test.js:58-63`, `tests/` listing |
| Notes | Individual test bodies beyond the harness setup were not read. **Partial:** re-read `note-checklist-patch.test.js` before mirroring its 409 shape. |

### 8. Cairn permission path

| Field | Value |
| --- | --- |
| Inspected | `components/dom-owner/capabilities.js` `requestVaultFolder`, `components/vault-source/index.js` IndexedDB persistence + root attach/recall, `components/vault-source/sources.js` `directoryRoot`/`sampleRoot`/`FAILURE`/bounds, `components/vault-writer/filesystem.js` `normalizePath`/`OPERATION_FAILURE`/write+copy, `components/vault-source/component.json` authority declaration, `Cairn/README.md`, `Cairn/package.json` |
| Findings | The permission process is: picker under a user gesture on the main thread → handle handed to a worker via a kernel grant and the local reference dropped in the same statement → handle persisted in IndexedDB → `queryPermission` on recall → `vault.permission-required` when not granted. **Its own source comments justify the IndexedDB store by `localStorage` not existing in a worker** — i.e. the machinery exists because Cairn has no server. Path rules and the two closed failure vocabularies are cleanly portable; the handle machinery is not, and would not buy anything WorkLists lacks. |
| Status | contributing (this is the reframe evidence) |
| Commit | working tree, 2026-08-28 (Cairn is a separate repo; no SHA taken — see frontier) |
| Evidence | `capabilities.js:18-60`, `capabilities.js:100-104`, `vault-source/index.js:20-70`, `vault-source/index.js:128-235`, `sources.js:15-45`, `sources.js:78-115`, `vault-writer/filesystem.js:9-100`, `vault-source/component.json` |
| Notes | Cairn's kernel/graph/contract layer was **not** inspected — irrelevant to this question, since WorkLists has no kernel to port into. |

### 9. Dantalion document-surface contract

| Field | Value |
| --- | --- |
| Inspected | `components/document-surface/INTERFACE.md`, `package.json` exports, the WorkLists mount shim |
| Findings | The surface takes an **opaque host-supplied `key`** and explicitly never interprets it as a path, never reads the filesystem, and never derives identity from DOM location. It exposes `present`/`show`/`load`/`setEditable`/`accept`/`commit`/`isDirty`/`markdown`/`close`. **It already does everything this ticket needs and requires no change** — a file-backed note is just another opaque key with a different host-side source. |
| Status | ruled-out (as a place needing change) |
| Commit | working tree, 2026-08-28 |
| Evidence | `components/document-surface/INTERFACE.md`, `Dantalion/package.json` exports, `WorkLists/public/worklists-dantalion.js`, `WorkLists/server.js:36-38` |
| Notes | The `onIntent` kinds (`toggle-task`, `replace-text`, `save`, `request-source`) are the host-work seam; the WorkLists mapping of them was not traced in full. **Partial:** trace `createWorkListsDantalionEditor`'s intent mapping (`todolist2.js:766-830`) before wiring a file-backed save. |

### 10. markdown-kit package boundary

| Field | Value |
| --- | --- |
| Inspected | `packages/markdown-kit/package.json`, `index.js`, `README.md`, the static mount in `server.js` |
| Findings | Four UMD modules served at `/markdown-kit/<file>.js` and required in Node; a one-copy rule enforced by `tests/markdown-kit-package.test.js`. This is the fallback renderer path when Dantalion is unavailable — a neighbour to protect, not a place to change. |
| Status | ruled-out (as a place needing change) |
| Commit | `06b78be` · 2026-08-28 |
| Evidence | `packages/markdown-kit/package.json`, `packages/markdown-kit/README.md`, `server.js:32-34` |
| Notes | — |

## Not yet inspected (frontier)

- **`openapi.js` route-definition style** — the new `/api/files` routes must be documented there to pass `tests/openapi.test.js`. Only the guard was confirmed, not the authoring pattern to follow. *Answers: what shape a new route entry must take.*
- **`dal.js` write/atomic-write internals** — `atomicWrite`, its retry loop, and `TEMP_DIR` were read about in the spike spec but not read in code at `06b78be`. *Answers: whether a file write outside `DATA_DIR` should reuse the same atomic-write helper or deliberately not.*
- **`createWorkListsDantalionEditor` intent mapping** (`todolist2.js:766-830`) — the surface's `save` / `replace-text` / `request-source` intents and how WorkLists currently handles them. *Answers: where a file-backed save hooks in, and whether autosave is driven from the intent or from focus exit.*
- **`tests/note-checklist-patch.test.js` body** — the exact 409 assertions to mirror. *Answers: the concurrency contract's tested shape.*
- **The Settings dialog's panel bodies** (`todolist2.js:16910+`) — only the tab framework was read. *Answers: how a panel body is constructed and validated, for the new tab.*
- **Cairn repo commit SHA** — Cairn was read at working-tree state without recording a SHA. *Answers: whether a later reader can tell if the permission-path findings still hold.*
- **`data/cardTemplates.json` / card-template note creation** — read only enough to find the designated template. *Answers: whether template-created notes could ever carry a source reference.*
- **Whether any other WorkLists surface renders note text** outside the notes pane (card previews, search results, exports). *Answers: whether the blast radius in report §7 is complete for* rendering *as well as for* writing *— the grep covered writes thoroughly and reads less so.*
