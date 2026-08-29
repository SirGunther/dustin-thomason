# Investigation Report: attach repository files as note nodes

## Metadata

- **Status:** planned
- **Disposition:** proceed with conditions
- **Date:** 2026-08-28
- **Owner:** Dustin Thomason
- **Location:** `docs/WorkLists/tickets/attach-repository-files-as-notes/investigations/attach-repository-files-as-notes-investigation.md`
- **Ticket:** [original-ticket.md](../original-ticket.md) — no ClickUp link; personal project
- **Domain:** software
- **References / evidence:** WorkLists @ `06b78be` (`server.js`, `dal.js`, `public/todolist2.js`, `public/apiService.js`, `openapi.js`, `tests/`); Cairn @ working tree (`components/dom-owner/capabilities.js`, `components/vault-source/`, `components/vault-writer/filesystem.js`); Dantalion @ working tree (`components/document-surface/INTERFACE.md`); [recon-and-plan](./attach-repository-files-as-notes-recon-and-plan.md); [coverage ledger](./attach-repository-files-as-notes-coverage-ledger.md); [diagrams](./attach-repository-files-as-notes-diagrams.md); `docs/WorkLists/features/file-system/kanban-file-system-blueprint.md`; `docs/WorkLists/tickets/onedrive-per-record-file-spike/specs/onedrive-per-record-file-spike-spec.md`

---

## 0. Verdict (bottom line up front)

The capability is viable and most of it is already built. The document surface that would normally be the hard part is done, shared, and mounted per note today; the card ellipsis menu already has a documented extension seam; and the note record already carries the optimistic-concurrency field a safe file write needs. What is genuinely missing is small and specific: a **declared root** that bounds where the program may read, and a **content-source indirection** on the note so its text can come from a file instead of from its own record. Both are additive.

One thing blocks a clean start, and it is not a technical unknown — it is a decision the request pre-answered in a direction the evidence argues against. The request says to translate Cairn's permission process into WorkLists. Cairn's permission process is machinery for holding an OS grant inside a browser tab, and every part of it exists because **Cairn has no server**. WorkLists has one, on the same machine, already reading and writing real files. Porting the mechanism costs automated test coverage (a native picker cannot be driven by the existing Playwright harness), cross-machine consistency (browser-held content cannot satisfy story 05), and browser portability (Chromium becomes a hard requirement). Not porting it means "permission" is a scope declaration rather than an OS grant — which is weaker, and must be said plainly rather than dressed up.

- **Strongest path:** server-resolved repository root declared in the existing Settings dialog, with `realpath` containment; a `source` reference on the note record; content read and written through new `/api/files` routes that refuse anything outside the root; the surface, the menu seam, and the 409 concurrency pattern all reused unchanged. Ship stories 01–04 on this; story 05 falls out of it almost free.
- **Not yet proven / not approved:** the mechanism choice is the user's and is **not** made here. Nothing has been built. The `0.0.0.0` bind with no authentication (§7, Adjacent) is a pre-existing exposure this work would widen, and no decision has been taken on it. File identity across renames is undecided, and story 05's durability depends on it.

## 1. Problem class

- **Class the request assumed:** *a missing capability, solved by porting a mechanism.* Framed that way explicitly — "we need to grant permission to a specific folder… We just need to translate the permission process from one app to the other."
- **Confirmed class:** *content-source indirection, bounded by a declared authority scope.* Two distinct absences: a note's content can only come from its own record, and the program has no bounded place it is allowed to read from.
- **Reframed?** **Yes** → from *port Cairn's permission mechanism* to *declare a scope and indirect the content source*. Triggered at **Step 4** (trace why it exists), by reading Cairn's `components/vault-source/index.js:20-70` and finding the IndexedDB handle store justified in its own comment as *"`localStorage` does not exist in a worker at all… Since the handle may only live here, the store that remembers it may only live here too."* That is not a design preference; it is a workaround for an absent server. WorkLists is not missing a server.
- **What the confirmed class implies:** the deliverable is a root + an indirection, not a handle store. The *guarantee* Cairn provides — one root, granted once, everything under it reachable, nothing outside it, failures named from a closed vocabulary — is fully portable and should be ported. The *mechanism* is where the two apps legitimately differ, because the reason for the mechanism does not exist here.

*Recorded honestly: this reframe contradicts an explicit instruction in the request. It is therefore presented as a decision for the owner (§10), not acted on. See also the assumption in §8 that names exactly what could refute it.*

## 2. Problem statement

- **Named instances:** the requester, right now. The concrete case is the one the request describes and this very ticket demonstrates: the ticket's own documentation lives as Markdown files under `C:\dustin-thomason\docs\WorkLists\tickets\…`, and the WorkLists card that tracks the ticket cannot show any of it. Today the only way to get that content onto the card is to paste a copy, which begins drifting from the file the moment either is edited.
- **One sentence:** *A Markdown document that already exists on disk cannot be shown or edited inside a WorkLists card without pasting a copy of it, and the copy immediately diverges from the file.*
- **Distinct problems** (five, kept apart — one job story each):
  1. There is no bounded folder the program is allowed to read from. (Story 01)
  2. A document that already exists cannot be brought next to the work it explains. (Story 02)
  3. Content brought in from a file cannot be edited back into that file. (Story 03)
  4. Removing something from a card has only ever meant destroying it. (Story 04)
  5. The same document cannot be present in two places without becoming two copies. (Story 05)
- **Urgency:** no external date. The trigger is the one that already fired — the shared document surface landed on 2026-08-27/28 (changelog: "Dantalion notes-pane surface integration", "Dantalion note editing controls and viewport fit"), which is what made this possible. It bites next each time a ticket's documentation has to be duplicated onto its card by hand.
- **Wedge:** **one note whose text comes from a file inside one declared root.** It is the smallest thing that opens the space because it forces every hard question at once — where may we read, how is the file identified, what happens on save, what happens when it is gone — while being reusable: the same indirection serves any future content source (a second root, a URL, a provider) without redesign, and the same root serves any future consumer of files.

### Problem Check

- **Asked:** how to attach local files to cards. *Evidence:* "I want to find a way to attach files."
- **Answered:** how to make a note's content come from somewhere other than its own record, within a bounded scope. The drift is real but small, and the request half-names it itself. *Evidence:* "The goal is to treat an attached file as one of the nodes in the system" — a node, not an attachment. And: "The main challenge involves how information is saved," which is a storage-indirection statement, not an attachment statement.
- **Should-ask:** *"where is a note's content allowed to come from, and where is the program allowed to look?"* — sharper than "how do we attach files" because it decides the record shape and the security boundary in one, and because it makes the multi-place requirement (story 05) fall out rather than needing separate machinery.
- **Conflation:** **yes, and it matters.** Three things are treated as one under "permission": (a) *scope* — which folder the program may read; (b) *authority* — whether the program is technically permitted by the OS to read it; (c) *durability* — whether that survives a reload. Cairn fuses all three into one artifact (the persisted handle), which is why "translate the permission process" reads as a single portable thing. In WorkLists they come apart: authority already exists unconditionally, scope does not exist at all, and durability is trivial. Solving scope does not touch authority — which is exactly the finding that reframed the class. *Evidence:* "we need to grant permission to a specific folder… This would allow everything within that folder to have permissions throughout the entire system."
- **Thin:** **yes, two terms.** *"Permission"* — never defined; §Conflation shows it is three things. *"Remains perpetually saved"* — undefined between three readings: the reference survives, the content survives, or the OS grant survives. They imply different work. *Evidence:* "It remains perpetually saved, and we can attach it to other places as well." A third, milder one: *"remove them from the specific file that was loaded"* is ambiguous between detaching a file from a card and deleting the file — carried as story 04 Q1 rather than resolved by guess.
- **Off:** **nothing here.** No internal contradiction. The closest thing is that "translate the permission process from one app to the other" sits in tension with "one file repository… everything within that folder has permissions throughout the entire system" — the first names a mechanism, the second names a guarantee — but that is under-specification, not contradiction, and both are satisfiable by the recommended path.

## 3. The contract

### Acceptance criteria

Owned by the job stories, not restated here. Coverage of the recommended solution against them:

| Criterion (story) | Status | What's needed to close it |
| --- | --- | --- |
| 01 — folder named once, still in effect next open | covered | Server-side setting; the app's own convention for server-acted settings (§5) |
| 01 — allowed once, stays allowed until changed | covered | Trivial under a server root; **gap** under a browser grant (lapses, needs re-confirm) |
| 01 — everything inside reachable, nothing outside | needs-proof | `realpath` containment test, including a symlink-escape negative case |
| 01 — lapsed/missing folder told plainly | needs-proof | Closed failure vocabulary mirrored from Cairn's `FAILURE` / `OPERATION_FAILURE` enums |
| 01 — nothing offered before a folder is named | covered | Menu item hidden or disabled with a reason, mirroring `syncNotesPaneActionMenuTrigger` |
| 02 — pick a document, it appears with the work | covered | New ellipsis item via the existing `extraActions` seam |
| 02 — looks and behaves like anything else there | covered | Same Dantalion surface, already mounted per note |
| 02 — shows current file content, not a snapshot | needs-proof | Read-through on render; assert against a file mutated between two loads |
| 02 — still there next open, without re-picking | covered | The reference is a note record; persistence is existing behaviour |
| 02 — already-attached is refused, not duplicated | needs-proof | Duplicate check on attach |
| 02 — moved/renamed/deleted file says so | needs-proof | `not-found` surfaced in the note body, not a blank |
| 03 — edit like anything else in that spot | covered | `setEditable` on the existing surface |
| 03 — save writes the actual file | needs-proof | New write route + red→green test |
| 03 — nothing written until save | needs-proof | **Depends on story 03 Q2** — the surface autosaves on focus exit today |
| 03 — told when the file changed underneath | needs-proof | Mirror `expectedLastModified` → 409 with file mtime |
| 03 — unwritable file names the reason, typing not lost | needs-proof | Failure vocabulary + draft retention |
| 03 / 05 — a change shows everywhere it is used | covered | Falls out of one-source-many-references |
| 04 — take off one place only | covered | Delete the reference row |
| 04 — file untouched by taking it off | needs-proof | Assert file bytes and mtime unchanged |
| 04 — other places unaffected | covered | Rows are independent |
| 04 — detach and delete are visibly separate | needs-proof | **Depends on story 04 Q1** |
| 04 — re-attach gives the same content | covered | Read-through |
| 04 — deleted-elsewhere file says so in each place | needs-proof | Same `not-found` path as 02 |
| 05 — same document in more than one place | covered | Several rows, one source |
| 05 — each place shows the same content | covered under a server root; **gap** under a browser grant | §7 Alternatives |
| 05 — find out where else it is used | gap | **Depends on story 05 Q1** — nothing today indexes references |
| 05 — taking off one leaves the others | covered | Rows are independent |

### Non-goals

- **Non-Markdown files.** PDFs, images, Office documents. The surface renders Markdown; anything else is a different feature. *(Bounds story 01 Q4.)*
- **Multiple roots.** The request is explicit: "By creating one file repository, we avoid dealing with multiple locations."
- **Cloud providers.** Box, OneDrive-as-API, GitHub — the `StorageProvider` abstraction in the 2026-07-09 blueprint is its Phase 3, behind a simple MVP. Building it now crosses the "no more complex than it needs to be" line on the first slice.
- **Creating new files from inside WorkLists.** The request is about pulling in documents that already exist.
- **File version history.** The file's own history (OneDrive, git) is the recourse. *(Story 03 Q4.)*
- **Fixing the pre-existing `0.0.0.0` bind.** Named as an adjacent issue (§7) with a recommendation; not assumed into scope.

## 4. What changed since the request was created

- **Shifted from:** "port Cairn's folder-permission mechanism into WorkLists" → **to:** "declare a bounded root and indirect the note's content source; port Cairn's *guarantee*, not its machinery."
- **What that buys us:** the whole feature stays inside the existing automated test harness; content is identical in every browser and on every machine, which is what story 05 actually requires; no new hard browser requirement.
- **What it still needs to prove:** that a configured root plus `realpath` containment is an acceptable substitute for an OS grant **in the requester's own judgement** — it is a genuinely weaker guarantee, and the request asked for the stronger one. That is §10's first decision.

## 5. Why it exists

- **Origin traced to:** the absence is by construction, not by defect. A note has always been a row whose `text` *is* the content (`data/event-notes.json`; `dal.js:59` `SECTIONS`), and WorkLists has never had a filesystem root other than its own `DATA_DIR` (`dal.js:9-13`). Nothing was broken; a capability was never built, and could not usefully have been built before the shared document surface existed.
- **Evidence:**
  - Content in: `public/todolist2.js:5140` `createNoteItem` sets `item.dataset.rawText = note.text`; `:5197` `renderNoteItemContent` reads it and mounts the surface. One source, no branch.
  - Content out: `public/todolist2.js:6166` `saveNoteInlineEditor` → `ApiService.updateNote(noteId, text)` unconditionally.
  - Storage: `server.js:2836-2940` (`/api/notes` GET/POST/PUT/PATCH/DELETE) over `dal.readNotes()` / `dal.writeNotes()`.
  - Root: `dal.js:9-13` — `DATA_DIR` is the only root, env-overridable, defaulting to `<repo>/data`.
  - The enabling change: changelog entries 2026-08-27 "Dantalion notes-pane surface integration" and 2026-08-28 "Dantalion note editing controls and viewport fit" — the surface the request depends on landed one day before the request.
- **Contract alignment (software lens 1).** Two authorities that a change here must mirror, both hand-maintained and therefore drift-prone:
  1. `dal.js:59` `SECTIONS` **and** `dal.js` `TEMP_FILE_PATTERN` list the same section names in two places — an array and a literal regex. A new DAL section added to one and not the other leaves its temp files unrecognised by the orphan sweep. **Highest drift risk in this change.**
  2. `openapi.js` is hand-authored and guarded by `tests/openapi.test.js`. Any new route must be documented there or the gate fails. (This is a *healthy* pairing — the guard exists; it is named so nobody is surprised by it.)
- **Detection gap (software lens 4).** Not a bug, so nothing "missed" it. The prospective gap: **no test anywhere asserts that a note's content can come from outside `event-notes.json`**, because nothing has ever done so. That is what the red→green pair in §9 closes.
- **Class re-check:** **held, and strengthened.** Root-cause evidence is the absence of a branch at exactly the two points the class predicts (content in, content out) plus the absence of any second root. The class named those before the trace found them.

## 6. Alternatives considered

| Alternative | Rejected because |
| --- | --- |
| **Port Cairn's mechanism verbatim** (`showDirectoryPicker` + IndexedDB handle + `queryPermission`) | Costs three measured things: (a) untestable — `tests/browser-notes-smoke.js` drives real Chromium via Playwright, and a native folder picker is an OS dialog Playwright cannot drive, so every attach/read/write criterion loses automated coverage; (b) content becomes browser-local, so a browser that has not been granted the folder renders nothing — which fails story 05's "each place shows the same content"; (c) Chromium becomes a permanent hard requirement of WorkLists, which it is not today. **Not rejected outright — it is the stronger guarantee, and it is §10 decision 1 for the owner.** |
| **Copy the file's content into the note on attach** (import, not reference) | Fails the request's own words on three counts: the copy is not "perpetually saved" to the file, editing it does not change the document, and "attach it to other places" produces divergent copies — the exact thing story 05 exists to prevent. |
| **Store attached content as a new DAL section** (`attachedFiles`) | Adds a section to the `SECTIONS`/`TEMP_FILE_PATTERN` pair (§5 drift risk) to hold a duplicate of data that already exists on disk. The file is the truth; a second copy in the synced `data/` tree is the problem restated. |
| **One file per note on disk** (per-record storage) | Already investigated and deliberately deferred: `docs/WorkLists/tickets/onedrive-per-record-file-spike/specs/…-spec.md` sequences per-record storage behind two predecessors and records live `EBUSY`/`EPERM` contention in the OneDrive-synced tree. Reopening it here would be relitigating a recorded decision, and it does not serve this ticket anyway. |
| **Build the `StorageProvider` abstraction from the 2026-07-09 blueprint now** | That blueprint's own phasing puts the provider abstraction at Phase 3, behind a Phase 1 simple MVP. One local root does not need a provider interface; adding one now is generalization ahead of a second case. Recorded as the natural extension point, not built. |
| **A symlink or junction from `data/` into the documents folder** | Invisible in the UI, invisible to the record, and it puts arbitrary documents inside the OneDrive-synced `data/` tree that `atomicWrite` and the orphan sweep operate on. Actively dangerous. |

## 7. Solution & stress-test

**Proposed solution** (recommended; conditional on §10 decision 1):

1. **Repository root** — one absolute path, stored server-side because the server must resolve it (the app's own convention, §8). Set from a new tab in the existing Settings dialog (`public/todolist2.js:16828`). Validated on save: exists, is a directory, is readable, and does not contain or sit inside `DATA_DIR`.
2. **Containment** — every path resolved against the root and checked with `fs.realpath` before any read or write. Cairn's `normalizePath` (`components/vault-writer/filesystem.js:38-66`) is the right shape and its rules port directly (no `..`, no `\`, no `//`, no empty segments, bounded length); `realpath` is the one thing it does not need and Node does, because a browser directory handle cannot be traversed upward at all while a Node path can.
3. **Content-source indirection** — the note record gains an optional `source` (kind + reference). A note without one behaves exactly as today; a note with one reads and writes through the file. Additive, no migration.
4. **Routes** — list, read, write under `/api/files`, each refusing anything the containment check rejects, each answering from a closed failure vocabulary mirrored from Cairn's `FAILURE` / `OPERATION_FAILURE`. Write takes an expected-mtime precondition and answers `409` with the current value — the same shape `PATCH /api/notes/:noteId` already uses.
5. **UI** — one new item on the card ellipsis menu through the existing `extraActions` seam (`getNotesPaneCollapseMenuActions`, `public/todolist2.js:4700`); a detach item on the per-note menu (`.notes-pane-note-menu`), which is already the non-destructive surface, kept distinct from the destructive `data-delete-note` control in the action row.

- **Solves the confirmed class?** Yes, both halves: scope is declared once and enforced at one chokepoint; content source is indirected at the two points that own it. It solves the class rather than the instance — the same indirection admits any later source, and the same root admits any later consumer.
- **Scale:** the bounded quantity is files under the root, not notes. Cairn's own bounds are the reference point (≤ 5000 files, depth ≤ 12, ≤ 2 MB per document, skip `node_modules`/`dist`/`build`/`out`/`coverage`/`.git` and dot-entries) and they port directly. Note count is unaffected — a reference is smaller than the text it replaces.
- **Generalization:** deliberately stopped one level short of the blueprint's provider interface. One local root, one source kind. The `source` field is shaped so a second kind is additive, which is the right amount of forward allowance for a case that does not exist yet.
- **Fit:** strong, and this is the argument for the whole approach. Every piece reuses something already established — the settings dialog's tab structure, the `extraActions` menu seam, the 409 concurrency shape, the Dantalion surface, the hand-authored-OpenAPI-plus-guard convention, and the server-side-for-server-acted-settings split. The only genuinely new concept is the root and its containment check.
- **Adjacent issues:** **one, and it must not be silent.** `server.js:3615` is `app.listen(port)` with no host, so the server binds `0.0.0.0`; `app.use(cors())` has no origin restriction; and there is **no authentication middleware anywhere** in `server.js`. Any device on the LAN can already read and write the board. This change would widen that from "his board" to "read and write any file under his documents root". The fix is one argument — `app.listen(port, "127.0.0.1")` — and is far cheaper now than after. Recommended as a gate on shipping the file routes; recorded as a concern either way. *(Tradeoff: doing it now costs minutes and breaks any deliberate cross-device access to the board, which the pinned-board sync feature suggests might exist. Doing it later costs a window of real exposure.)*
- **Sufficiency:** covers all five distinct problems. Story 05's "find out where else it is used" is the one criterion not covered by the base solution and is flagged as a gap pending its own decision.
- **Feedback speed:** fast. Every criterion except the cross-machine ones is provable by an automated test in the existing harness on the first run. The slow-feedback item is cross-machine behaviour, which no test covers and which depends on decision 3 (file identity) — flagged.
- **Protect the neighbours (software lens 3).** On the shared path and required to be unchanged, each with the check that proves it: the collapse-all menu item (assert it still appears alongside the new one); `Show editing controls` / `Prompt Injection` per-note items (assert both still present on a file-backed note); focus-exit autosave and its editing-boundary logic (assert an ordinary note still autosaves); `fitNoteEditorToViewport` (assert geometry unchanged for an ordinary note); the checkbox-toggle `PATCH` 409 path (`tests/note-checklist-patch.test.js` must stay green untouched); the markdown-kit fallback renderer when Dantalion is absent (assert an ordinary note still falls back).
- **Surface enumeration (software lens 2).** Everything that reads or writes note text, and therefore everything that must either understand a file-backed note or be proven unable to reach one: `saveNoteInlineEditor` (`:6166`), `undoAiNoteRefine` (`:6227`), the AI-refine result apply (`:11052`), `persistRenderedMarkdownNoteCheckboxChange` (`:5210`, fallback path), `deleteTaskNote` (`:6184`), `PATCH /api/notes/:noteId` (`server.js:2896`), the Gemma refine job (`server.js:2262`), `POST /api/notes` (`server.js:2847`), and note creation inside `POST /api/cards/from-template` (`server.js:2183`, `:2247`). **Completeness established by** grepping `ApiService.updateNote|readNotes\(\)|writeNotes\(` across `public/` and the server, which returns exactly this set. *The AI-refine paths are the sharpest: refining a file-backed note would rewrite a real document through a model. That must be a deliberate decision, not a default inherited by silence.*
- **Happy-path story (30 seconds):** Dustin opens Settings, picks his documents folder once, and closes it. On a card, he opens the ellipsis, chooses Attach document, and picks a spec from the folder. It appears in the notes list looking exactly like every other note — same surface, same controls. He spots a stale line, edits it in place, saves; the file on disk now has the correction, and so does the other card he attached it to. Later he takes it off that card and the file is untouched. **Without whom:** without a browser extension, without an upload, without a copy, and without leaving the board.

## 8. Assumptions ledger

- **Claim:** WorkLists' page can use the File System Access API, so the browser mechanism is technically available and is being judged on cost rather than availability.
  - **Status:** confirmed
  - **Confirm/revise by:** `server.js:24` serves on `localhost:3010`; `localhost` is a secure context, which is the API's only origin requirement.
- **Claim:** A native directory picker cannot be driven by the existing automated tests.
  - **Status:** confirmed
  - **Confirm/revise by:** `tests/browser-notes-smoke.js` spawns the real server on a random port with a temp `DATA_DIR` and drives real Chromium through Playwright. The picker is an OS-level dialog outside the page. Refutable by demonstrating a Playwright path that grants a directory handle without the dialog — if one exists, alternative 1's strongest objection falls.
- **Claim:** Settings the server must act on are stored server-side in this app; view state is stored in `localStorage`.
  - **Status:** confirmed
  - **Confirm/revise by:** server-side — `data/models.json`, `data/pinnedBoardIds.json`, `data/cardTemplates.json`; client-side — `theme.js:140`, `shortcutRegistry.js:19`, `todolist2.js:3890` (pane width). The split holds in both directions with no counter-example.
- **Claim:** A settings surface already exists and needs extending, not creating.
  - **Status:** confirmed
  - **Confirm/revise by:** `public/todolist2.js:16828` `openModelSettingsDialog` — a tabbed dialog with eight tabs.
- **Claim:** The card ellipsis menu can take a new notes-pane-only item without touching shared board-card actions.
  - **Status:** confirmed
  - **Confirm/revise by:** `getNotesPaneCollapseMenuActions` (`todolist2.js:4700`) does exactly this today through `extraActions`.
- **Claim:** An optimistic-concurrency precedent exists that a file write can mirror.
  - **Status:** confirmed
  - **Confirm/revise by:** `server.js:2896-2920` — `expectedLastModified` → `409` carrying the server's current value; `tests/note-checklist-patch.test.js` exercises it.
- **Claim:** The server has no authentication and binds all interfaces.
  - **Status:** confirmed
  - **Confirm/revise by:** `server.js:3615` `app.listen(port)` with no host; `app.use(cors())` with no options; no auth middleware anywhere in `server.js`.
- **Claim:** The host-scoped data files imply no code-level multi-machine mechanism, so cross-machine behaviour is about the *person* moving machines, not the app syncing.
  - **Status:** confirmed (inherited)
  - **Confirm/revise by:** recorded in `onedrive-per-record-file-spike-spec.md` — those files are absent from `SECTIONS` and no `os.hostname()` call exists. Spot-checked against `dal.js:59` and found to still hold at `06b78be`.
- **Claim:** The requester wants the *guarantee* (bounded scope, granted once, named failures) rather than the *mechanism* (an OS grant held in a browser tab).
  - **Status:** **open — this is the one that matters**
  - **Confirm/revise by:** ask. The request's words point the other way ("translate the permission process from one app to the other"), which is precisely why this is not resolved by inference. Refuted if the requester wants a real OS-level grant, in which case alternative 1 is the path and the three costs in §6 are accepted knowingly.
- **Claim:** No cloud-provider or non-Markdown support is wanted in this slice.
  - **Status:** confirmed directionally
  - **Confirm/revise by:** the request names only local files and the Markdown surface; the blueprint independently sequences providers later. Owed: explicit confirmation at Phase 3, since "directionally" is not the same as asked.

## 9. Validation plan

**Happy path**

1. With no root configured, open a card's ellipsis — the attach item is absent or disabled with a stated reason.
2. Open Settings, set the root to a folder containing `notes/spec.md`, save. Reopen Settings — the value persists.
3. Reload the page. The value still persists and no re-confirmation is asked for.
4. On a card, ellipsis → Attach document → choose `notes/spec.md`. It appears in the notes list.
5. It renders through the same surface as every other note, with the same controls in the same places.
6. Edit a line, save. Read the file directly from disk — it contains the edit. Read the note record — its own `text` is unchanged.
7. Attach the same file to a second card. Open the second card — it shows the edited content.
8. Detach from the first card. The file is byte-identical and still attached to the second.
9. Re-attach to the first card — same content returns.

**Negative paths** (each must fail *visibly*)

- **Containment — the load-bearing one.** A reference resolving outside the root is refused: `../` traversal, an absolute path, a UNC path, a `\`-separated path, and **a symlink inside the root pointing outside it** (the case `realpath` exists for, and the one Cairn never had to handle because a directory handle cannot be traversed upward).
- **Root itself invalid** — nonexistent, a file rather than a directory, unreadable, or nested with `DATA_DIR` in either direction: refused at save with a named reason, and the previous value is not lost.
- **File vanished between attach and render** — the note says `not-found` in its body; it does not render blank and does not throw.
- **File changed underneath an edit** — save is refused with `409` and the current mtime; the user's text is still in the editor afterwards.
- **File unwritable** (read-only, locked, permission lapsed) — the specific reason is named; the draft survives.
- **Duplicate attach** — refused with a message; no second row.
- **Bounds** — a file over the size limit, a folder over the file-count limit, a tree over the depth limit: each refused with its own named reason, not a generic failure.
- **Neighbours unchanged** — an ordinary note still autosaves on focus exit, still shows both existing per-note menu items, still falls back to the markdown-kit renderer when Dantalion is absent, and `tests/note-checklist-patch.test.js` stays green with no edits.
- **Unreachable-by-construction proof** — for each surface in §7's enumeration that is *not* taught about file-backed notes, a test proving it cannot reach one (rather than a claim that it will not).

**Red→green pair**

- *Fails before:* a note record carrying a `source` reference renders its own (empty) `text`.
- *Passes after:* it renders the file's bytes, and a save writes those bytes to the file while leaving `text` untouched.

**Metric that proves it works, and how fast it arrives:** the full suite green with the new red→green pair included, on the first run after implementation — minutes. The one slow-feedback item is cross-machine behaviour, which no automated test covers.

## 10. Decisions, recommendation & open variables

**Decisions (settled by evidence, not open):**

- The setting lives in the existing Settings dialog as a further tab — a tabbed dialog already exists.
- If server-side, the setting is a server-stored value, not `localStorage` — the app's own split for settings the server must act on.
- The concurrency shape is `expectedLastModified` → `409`, mirrored from the existing note-checklist patch rather than invented.
- The attach entry point is the existing `extraActions` seam on the card ellipsis menu.
- Detach lives on the per-note menu; the destructive delete stays in the action row. They are already separate DOM surfaces.
- Cairn's path rules and its closed failure vocabularies are ported regardless of mechanism.
- Non-Markdown files, multiple roots, cloud providers, file creation, and file version history are out of scope.

**Recommendation, in order:**

1. Resolve decision 1 below. Everything else is downstream of it.
2. Ship the root + containment first, alone, with the containment negative paths green. It is the security boundary; nothing should read a file before it is proven.
3. Then read-only attach (stories 01, 02).
4. Then edit-and-save with the 409 precondition (story 03).
5. Then detach (story 04). Story 05 falls out of 2–4 except its "where else is it used" criterion.

**Sequencing & gates:**

- **Do not ship any file route until** the containment tests are green, including the symlink-escape case.
- **Do not ship write before read** — a read-only slice is provable and reversible; a write slice is neither.
- **Do not teach the AI-refine paths about file-backed notes by default.** Either explicitly decide they may rewrite a real document, or explicitly prove they cannot reach one. Silence here is how a model ends up rewriting a spec.
- **Recommended gate on the LAN exposure:** bind `127.0.0.1` before the file routes ship, or record an explicit acceptance of the widened surface.

### Open variables to collect

- [ ] **1. Mechanism: browser OS grant (Cairn's, as the request asks) or server-resolved configured root (the evidence's recommendation)?** *Why the structure cannot answer it:* both are constructible; the code cannot weigh a stronger guarantee that forfeits automated coverage and cross-machine consistency against a weaker one that keeps both. §6 has the measured costs of each. — **owner: user. Blocks everything.**
- [ ] **2. Which folder is the repository root?** No candidate exists in the code. — owner: user.
- [ ] **3. How is a file identified — by path, or by something that survives a rename?** *Why the structure cannot answer it:* nothing in WorkLists references a file at all; there is no field, no resolver, and no precedent to mirror. Story 05's durability depends on the answer. — owner: user.
- [ ] **4. Autosave or explicit save for a file-backed note?** The surface autosaves on focus exit today; inheriting that means autosaving into a real document. — owner: user. *(Story 03 Q2.)*
- [ ] **5. Does the app offer to delete the file itself, or only to detach?** The request's "remove them from the specific file that was loaded" is ambiguous between the two. — owner: user. *(Story 04 Q1.)*
- [ ] **6. Is "where else is this used" in this slice?** Currently a gap against a story-05 criterion. — owner: user.
- [ ] **7. Do the AI-refine paths apply to file-backed notes?** — owner: user.
- [ ] **8. Bind `127.0.0.1` as part of this work, or accept the widened LAN surface explicitly?** — owner: user. *(Recorded in the concerns doc either way.)*
- [ ] **9. Live refresh while a file changes on disk with the note open?** — owner: user. *(Story 02 Q4.)*
- [ ] **10. WorkLists card for this ticket — create it, and in which column?** `POST /api/cards/from-template` requires `columnId`, and `worklists-card-sync` forbids the agent choosing one. — owner: user.

---

## 11. Plan — Next steps

### Handoff table

| Action | Owner | Done-when (falsifiable) |
| --- | --- | --- |
| Resolve open variable 1 (mechanism) | user | A locked-decision row names one mechanism and the rejected one |
| Resolve open variables 2–9 | user | Each has an `LD-###` row in `specs/…-locked-decisions.md` |
| Supply or authorise the WorkLists card (variable 10) | user | A card id is in the ledger, or `skipped (user declined)` is |
| Run grill-me over variables 1–9 | agent | Every variable has a locked decision or a named carry-forward owner |
| Accept the job stories | agent | All five index rows read `accepted` |
| Write the spec | agent | `specs/…-spec.md` exists, every `spec-writing` section present or N/A with a reason |
| Refine the test plan | agent | Every scenario maps to an acceptance criterion; status `refined` |
| Implement | agent | Red→green pair green; containment negative paths green; every §7 neighbour check green |

### Checklist

#### Investigation

- [x] This report (Sections 0–10)
- [x] Coverage ledger
- [x] Diagrams
- [x] Test-plan seed

#### Project Spec

- [ ] Grill-me over the open variables
- [ ] Locked-decision ledger
- [ ] Accept the job stories
- [ ] Create the spec

#### Development

- [ ] Create new branch
- [ ] Begin implementation

#### Testing & Validation

- [ ] Execute the test plan locally

#### Deploy & PR

- [ ] Push
- [ ] Open PR

#### Ticket Closeout

- [ ] Finalize the why doc
- [ ] Close the ledger

---

## 12. Definition of done (investigation gate)

- [x] Class derived from instances, re-confirmed against root cause; "reframed?" answered **yes**, with the step and the evidence that flipped it (§1)
- [x] Problem Check pass recorded (§2) — every flag grounded in a trimmed quote or an explicit "nothing here"
- [x] Problem in one plain sentence (§2)
- [x] Named blocked instance (§2)
- [x] Date it bites next (§2 — trigger-based, stated as such)
- [x] Wedge + why it's reusable within the confirmed class (§2)
- [x] Acceptance criteria + non-goals locked before the solution was proposed (§3, written before §7)
- [x] Alternatives recorded with rejection reasons (§6)
- [x] 30-second happy-path story (§7)
- [x] Metric that proves it works + how fast it arrives (§9)
- [x] Verdict + disposition stated (§0, Metadata)
- [x] Every open question reconciled: discoverable facts resolved in §8, only genuine decisions in §10, each with an owner and — where the structure cannot answer it — the evidence that proves so
- [x] Tracked action with a falsifiable done-when (§11)
