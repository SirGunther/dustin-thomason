# Recon and plan — WorkLists/attach-repository-files-as-notes

> **Phase 1 output, frozen.** This is the recon's findings plus the emission todos for Phase 2. Later deviation is recorded in the why-log or the coverage ledger, never by editing this file.
>
> **Mode note.** The original request waived the plan-mode stop ("We do not need to wait for plan mode"). This document was therefore produced and written in one pass rather than approved in Plan mode first. That waiver is recorded in the ledger.

| Field | Value |
| --- | --- |
| Project | WorkLists |
| Slug | `attach-repository-files-as-notes` |
| Baseline commit | `06b78be` (WorkLists, branch `main`, dirty working tree) |
| Date | 2026-08-28 |
| Repos traversed | WorkLists, Cairn, Dantalion |

---

## 1. Consult result (`P1.consult`)

`Consulted: docs/*/tickets/*/investigations/*-coverage-ledger.md and docs/**/*coverage-ledger* for "WorkLists", "notes", "dal", "filesystem", "permission" — none found for WorkLists.`

Eleven coverage ledgers exist across the docs tree (atlas ×6, ClickUpWideLayout ×2, Jaimie, nova ×2). **None** is a WorkLists ledger, so nothing was reusable and nothing was reopened. This is the first WorkLists coverage ledger.

Adjacent prior art *was* found and read, and it is not coverage-ledger shaped:

| Artifact | What it gives this ticket |
| --- | --- |
| `docs/WorkLists/features/file-system/kanban-file-system-blueprint.md` (2026-07-09) | A pointer-layer concept for multi-provider files. Its §4.4 `StorageProvider` abstraction and its Phase 1 "simple links" MVP are the *superset* this ticket is a first slice of. It is a concept doc, not a decision. |
| `docs/WorkLists/tickets/onedrive-per-record-file-spike/specs/…-spec.md` (2026-08-12) | The evidence that `data/` lives inside OneDrive, that `atomicWrite` already retries `EBUSY`/`EPERM`/`ENOENT` five times, and that the host-scoped data files (`boards-OfficeComputer1.json` etc.) are **inert** — referenced by nothing, with no `os.hostname()` call in the app. |
| `docs/WorkLists/worklists-app-changelog.md` → Current state + four newest session logs | The Dantalion surface is already the notes editing surface; markdown-kit is already extracted to `packages/markdown-kit`. |

---

## 2. Findings (`P1.code-trace`, `P1.method` steps 1–7)

### 2.1 What a note is today — traced end to end

| Layer | Fact | Evidence |
| --- | --- | --- |
| Storage | A note is a row in a JSON array, not a file | `data/event-notes.json`, 562 records, shape `{noteId, eventId, text, createdAt, lastModified}` |
| Storage engine | Section files written by `atomicWrite` with a 5-retry `EBUSY`/`EPERM`/`ENOENT` loop, temp files kept outside the synced tree | `dal.js:59` `SECTIONS`, `dal.js` `TEMP_DIR` |
| HTTP | `GET/POST /api/notes`, `PUT/PATCH/DELETE /api/notes/:noteId` | `server.js:2836`, `:2847`, `:2872`, `:2896`, `:2923` |
| Concurrency | `PATCH` already implements optimistic concurrency: `expectedLastModified` → `409` carrying the server's current `lastModified` | `server.js:2896-2920`, `dal.patchNoteChecklistSteps` |
| Client fetch | `ApiService.fetchNotes(taskId)` → `loadTaskNotes` → `renderTaskNotes` → `createNoteItem` | `public/apiService.js:478`, `public/todolist2.js:5094`, `:5140` |
| Client render | Each note mounts a Dantalion document surface via `createWorkListsDantalionEditor`, falling back to the markdown-kit renderer when the surface is unavailable | `public/todolist2.js:5197`, `:766`, `:719` |
| Client save | `saveNoteInlineEditor` reads `controller.getMarkdown()` and calls `ApiService.updateNote(noteId, text)` | `public/todolist2.js:6166-6182` |
| Per-note menu | `.notes-pane-note-menu`, currently two items: `Show editing controls`, `Prompt Injection` | `public/todolist2.js:5181-5186`, toggled at `:3403`, `:5239` |
| Card-level ellipsis | Notes-pane header trigger `#notes-pane-card-actions` opens the shared card-action menu; **notes-pane-only items are appended through `extraActions`** | `public/todolist2.js:4700-4718` (`getNotesPaneCollapseMenuActions`), `:4690` |

**The seam the request asks for already exists.** `getNotesPaneCollapseMenuActions()` is a precedent for adding a notes-pane-only item to the card ellipsis menu without touching the shared board-card action definitions. An "Attach document" item goes there, in the same shape.

### 2.2 What Cairn's permission process actually is

| Element | Cairn | Evidence |
| --- | --- | --- |
| Grant | `window.showDirectoryPicker({mode:'read'\|'readwrite'})` under a user gesture, on the main thread only | `components/dom-owner/capabilities.js:26-45` |
| Hand-off | The handle is never returned to the caller; it is passed straight into a kernel grant and the local reference nulled in the same statement | `capabilities.js:48-57` |
| Persistence | The handle is stored in IndexedDB (`cairn-vault` / `roots`), because `localStorage` does not exist in a worker and the handle may only live with its holder | `components/vault-source/index.js:20-70` |
| Re-permission | On recall, `handle.queryPermission({mode:'read'})`; not-granted emits `vault.permission-required` rather than prompting at the call site | `components/vault-source/sources.js:108-112`, `vault-source/index.js:180` |
| Scope | One or more roots; everything under a root is reachable; `.`-prefixed entries and `node_modules`/`dist`/`build`/`out`/`coverage`/`.git` skipped; depth ≤ 12, ≤ 5000 files, ≤ 2 MB per document | `sources.js:20-45`, `:80-100` |
| Write safety | Vault-relative paths only; no `..`, no `\`, no `//`, no empty segments, ≤ 4096 path / ≤ 255 name; existing entries never silently replaced; copy-before-move | `components/vault-writer/filesystem.js:38-100` |
| Platform | Chromium desktop only, feature-detected and disabled elsewhere | `Cairn/README.md`, `capabilities.js:26-31` |

**The load-bearing observation:** every one of the first four rows exists because **Cairn has no server**. It is a `file://`-free, served-static, worker-based browser app whose only route to a real folder is the File System Access API. The IndexedDB handle store, the kernel grant, the `permission-required` vocabulary — all of it is machinery for holding an OS grant inside a browser tab, because there is nowhere else to hold it.

WorkLists is not that. It is an Express server on the same machine (`server.js:24`, port 3010) that already reads and writes real files with `node:fs` on every board mutation.

### 2.3 The reclassification (the report's load-bearing finding)

- **Class the request assumes:** *a missing capability* — "we need to grant permission to a specific folder… translate the permission process from one app to the other." Framed as porting a mechanism.
- **Class the evidence supports:** *a missing scope declaration and a missing content-source indirection.* WorkLists already has unrestricted filesystem authority; what it lacks is (a) a declared root that bounds where that authority may be pointed, and (b) any way for a note's content to come from somewhere other than its own `text` column.
- **What flips it:** Cairn's permission machinery is a workaround for an absent server. Porting it into an app that *has* a server would import the constraint without the reason — and would cost the three things below.

**What the confirmed class implies:** the deliverable is a bounded root + a content-source indirection on the note record, not a handle store. "Translate the permission *process*" is still satisfied — one root, granted once, everything under it reachable, nothing outside it, failures named from a closed vocabulary. The *mechanism* is where the two apps legitimately differ.

**This is the decision the user must make, not the agent.** It is recorded as an open variable with the evidence on both sides, because the request explicitly asked for the mechanism to be translated, and a reclassification that contradicts an explicit instruction is a proposal, not a finding to act on unilaterally.

### 2.4 What the browser-mechanism option costs, measured

| Cost | Evidence |
| --- | --- |
| Untestable by the existing harness | `tests/browser-notes-smoke.js` spawns the real server on a random port with a temp `DATA_DIR` and drives real Chromium. A native `showDirectoryPicker` dialog is an OS window Playwright cannot drive. Every acceptance criterion touching attach/read/write would lose automated coverage. |
| Content becomes browser-local | Notes are rendered from `ApiService.fetchNotes` (`todolist2.js:5094`). A file-backed note whose content only the browser can read renders differently in a browser that has not been granted the folder — including on the second machine the OneDrive-synced `data/` implies. Directly contradicts story 05's "each place shows the same content". |
| Chromium-only, permanently | `capabilities.js:26-31` feature-detects and disables. Acceptable in Cairn (stated in its README); a new hard browser constraint on WorkLists is a new fact. |

### 2.5 What the server-side option costs, measured

| Cost | Evidence |
| --- | --- |
| "Permission" becomes nominal | The server already has full `node:fs` authority. A configured root is a *scope declaration*, not an OS grant. Honest framing required in the spec; it is not the same guarantee Cairn gives. |
| Widens an already-open surface | `server.js:3615` is `app.listen(port)` with **no host** → binds `0.0.0.0`. `app.use(cors())` with no origin restriction, and there is **no authentication middleware anywhere** in `server.js`. Any device on the LAN can already read and write the board. Adding read/write of arbitrary files under a root widens that from "his board" to "his documents folder". Mitigation exists and is cheap (bind `127.0.0.1`), but it is a real change in blast radius and must be named. |
| Path containment becomes load-bearing | Cairn's `normalizePath` (`filesystem.js:38-66`) is the right shape but is written for vault-relative browser handles. A Node port additionally needs `fs.realpath` containment to defeat symlink escape, which Cairn never needed because a `FileSystemDirectoryHandle` cannot be traversed upward at all. |

### 2.6 Software lens (mandatory reconcile)

| Lens point | Finding |
| --- | --- |
| **Contract / source of truth** | Two authorities, and they must be kept mirrored. (1) `dal.js:59` `SECTIONS` **and** `dal.js` `TEMP_FILE_PATTERN` — a hand-maintained regex listing the same section names. Any new section must be added to **both**, or its temp files are not recognised. (2) `openapi.js` is hand-authored and guarded by `tests/openapi.test.js`; a new endpoint that is not documented there fails that gate. Drift risk is high on the `SECTIONS`/`TEMP_FILE_PATTERN` pair specifically — it is literal duplication. |
| **Surface enumeration (blast radius)** | Everything that reads or writes note text: `saveNoteInlineEditor` (`:6166`), `undoAiNoteRefine` (`:6227`), the AI refine job result path (`:11052`), `persistRenderedMarkdownNoteCheckboxChange` (fallback renderer path, `:5210`), `deleteTaskNote` (`:6184`), `PATCH /api/notes/:noteId` checklist steps (`server.js:2896`), the Gemma refine job (`server.js:2262-2295`), `POST /api/notes` (`server.js:2847`), and note creation inside `POST /api/cards/from-template` (`server.js:2183`, `:2247`). **Completeness established by** grepping `ApiService.updateNote|readNotes\(\)|writeNotes\(` across `public/` and the server, which yields exactly this list. Every one of these must either understand a file-backed note or be proven unable to reach one. |
| **Protect the neighbours** | On the shared path and must not move: the collapse-all menu item (`getNotesPaneCollapseMenuActions`), the per-note `Show editing controls` / `Prompt Injection` items, focus-exit autosave and its editing-boundary logic, `fitNoteEditorToViewport`, the checkbox-toggle `PATCH` concurrency path with its 409, and the markdown-kit fallback renderer when Dantalion is absent. Each needs a named check that it is unchanged. |
| **Detection gap** | Not a bug — this is new capability, so there is no net that "missed" anything. The relevant gap is prospective: there is currently **no test anywhere** that asserts a note's content can come from outside `event-notes.json`, because nothing has ever done so. The regression test that closes it is a red→green pair on the content-source indirection. |
| **Red→green test** | Fails before: a note record carrying a `source` reference renders its own (empty) `text`. Passes after: it renders the file's bytes, and a save writes those bytes back to the file with `text` untouched. |
| **Repro recipe / preconditions** | Server on `localhost:3010` with a configured repository root; a `.md` file inside it; a card with the notes pane open. No feature flag, no role, no external service. |

### 2.7 Step 7 reconcile — facts resolved by evidence, decisions isolated

Resolved here rather than carried to the user:

| Question that could have been asked | Resolved by | Answer |
| --- | --- | --- |
| Where does the folder setting go? | `todolist2.js:16828` `openModelSettingsDialog` | A real tabbed Settings dialog already exists with eight tabs (General, Tag Colors, Secondary Tags, Statuses, Shortcuts, APIs, Prompts, Card Templates). A ninth tab is the fit; no new surface is needed. Story 01 Q3 is answered by code. |
| Is there an existing optimistic-concurrency precedent for the "file changed underneath you" criterion? | `server.js:2896-2920` | Yes — `expectedLastModified` → `409` + current `lastModified`. Story 03's concurrency criterion has a precedent to mirror rather than a design to invent. |
| Does WorkLists persist app settings client-side or server-side? | `theme.js:140`, `shortcutRegistry.js:19`, `todolist2.js:3890` vs. `data/models.json`, `data/pinnedBoardIds.json`, `data/cardTemplates.json` | **Both**, split by kind: view state (theme, pane width, shortcuts) is `localStorage`; anything the server must act on (models, pinned boards, card templates) is a DAL section. A repository root the server must resolve is therefore server-side by the app's own convention. |
| Is the FS Access API even available to WorkLists' page? | `server.js:24`, page served from `http://localhost:3010` | Yes — `localhost` is a secure context, so the browser option is technically open. It is not ruled out by availability; it is ruled against on cost (§2.4). |
| Can the same file be attached in several places without duplicating content? | `data/event-notes.json` shape; `eventId` is the card link | Yes — several note rows can carry the same source reference. Identity of the *file* is the open decision (§ below), not whether the shape allows it. |
| Does the request's "one main folder" conflict with anything existing? | `dal.js:9-13` `DATA_DIR` | No. `DATA_DIR` is separately configurable via env and defaults to `<repo>/data`. A repository root is an independent second root. They must be prevented from nesting, but they do not collide by design. |

Genuinely undecidable from the code — these are decisions, with the evidence that proves the structure cannot answer them:

1. **Browser grant vs. server-configured root.** Both are constructible; the code cannot choose between a stronger guarantee that is untestable and a weaker guarantee that is testable. Owner: user. *(§2.3, §2.4, §2.5)*
2. **Which folder is the repository.** No candidate exists in the code. Owner: user.
3. **File identity — path or content-addressed.** The structure cannot answer it because nothing today references a file at all; there is no existing field, no existing resolver, and therefore no precedent to mirror. Owner: user. *(Story 05 Q2)*
4. **Whether the WorkLists card for this ticket may be created, and in which column.** `POST /api/cards/from-template` requires `columnId` and `worklists-card-sync` forbids the agent choosing a column. Owner: user.
5. **Whether the server should be bound to `127.0.0.1` as part of this work.** A pre-existing exposure this ticket widens; fixing it is adjacent scope. Owner: user. *(§2.5)*

### 2.8 The class of problem (why-log seed)

**Class:** *content-source indirection with a bounded authority scope.* Not "file attachment", which is the request's surface framing and would suggest blobs, uploads, and a storage tier. Every hard part of this ticket is one of two things: deciding where a piece of content is allowed to come from, and bounding where the program may look for it. The document surface — the part that would be hard in most systems — is already solved and shared, which is precisely what makes the request possible now and what the request itself observes ("Previously, the system could not represent the same editing surface area, but now it can").

---

## 3. Emission todos for Phase 2

- [ ] Save this document verbatim as the recon-and-plan; freeze it.
- [ ] Update the ledger: Phase 1 `done`, Phase 2 `in-progress`.
- [ ] Create `<slug>-why-these-changes.md` with the class of problem (§2.8) and the Phase 1 why-log entry.
- [ ] Apply the staged story reconcile (§4) with a Phase 1 Story log entry on each story touched.
- [ ] Write `investigations/<slug>-investigation.md` from the report template, §§0–11, reconciled against every point of the software lens (§2.6). Link out to the diagrams artifact from §5.
- [ ] Materialize `investigations/<slug>-coverage-ledger.md` — Consulted line (§1) first, then one row per area traversed (§5), then the frontier.
- [ ] Produce `investigations/<slug>-diagrams.md` — current-vs-target for the note content path, the attach flow, and the save-with-concurrency sequence; N/A lines for kinds skipped.
- [ ] Seed `testing/<slug>-test-plan.md` from report §9, each scenario naming the acceptance criterion it exercises.
- [ ] Stage the PR draft shell `<slug>-pr-draft.md` — headings only.
- [ ] Record the §2.5 LAN-exposure finding in `<slug>-future-development-concerns.md`.
- [ ] Append a changelog session log entry for Phase 2.

## 4. Staged story reconcile (`P1.stage-story`)

| Story | Movement staged | Why |
| --- | --- | --- |
| 01 | Q3 (where the setting lives) **closes** — answered by evidence, `openModelSettingsDialog` has a tab structure. Q2 (per-person vs per-machine) **sharpens** — the spike spec proves the host-scoped files are inert, so there is no existing multi-machine mechanism to inherit. | §2.7 |
| 02 | No criteria invalidated. Add nothing; Q4 (live refresh) is confirmed as a genuine decision, not a lookup. | §2.7 |
| 03 | Concurrency criterion **strengthens** — a precedent exists (`expectedLastModified` → 409) so "told before their version replaces it" is now a mirror, not an invention. Q2 (autosave vs explicit save) is confirmed a decision and gains weight: the existing surface autosaves on focus exit, which would mean autosaving into a real file. | §2.1, §2.7 |
| 04 | No criteria invalidated. Q2 (shared removal control) sharpens: the per-note action row and the `.notes-pane-note-menu` are separate surfaces, so the two meanings *can* be separated without breaking "looks like any other note". | §2.1 |
| 05 | Q2 (path vs durable identity) confirmed undecidable from code, with the evidence recorded. | §2.7 |
| — | **No story splits. No story superseded.** Five stories still map one-to-one onto five distinct problems. | |

## 5. Staged coverage rows (`P1.stage-coverage`)

Areas traversed, to be materialized in the ledger at commit `06b78be`: WorkLists notes storage (`dal.js`, `data/event-notes.json`); WorkLists notes HTTP surface (`server.js`); WorkLists notes client (`public/todolist2.js`, `public/apiService.js`); WorkLists settings dialog (`public/todolist2.js:16828+`); WorkLists settings persistence conventions (`theme.js`, `shortcutRegistry.js`, DAL sections); WorkLists server exposure (`server.js:3615`, cors, auth); WorkLists test harness (`tests/`); Cairn permission path (`dom-owner/capabilities.js`, `vault-source/`, `vault-writer/filesystem.js`); Dantalion document-surface contract (`components/document-surface/INTERFACE.md`); markdown-kit package boundary.

## 6. Staged why-log entry (`P1.stage-why`)

Phase 1 — new understanding. **Obvious going in:** the note surface is already shared, so a file could be shown through it. **Not obvious:** that the request's central instruction — translate the permission process — describes machinery that exists only because Cairn has no server, and that importing it costs automated test coverage, cross-machine consistency, and browser portability. **Assumption to test:** that the user wants the *guarantee* (bounded scope, granted once, named failures) rather than the *mechanism* (an OS grant held in a browser tab). **Discarded early:** treating this as an upload/attachment feature; the request is explicit that the file stays where it is and that the attachment is a reference.
