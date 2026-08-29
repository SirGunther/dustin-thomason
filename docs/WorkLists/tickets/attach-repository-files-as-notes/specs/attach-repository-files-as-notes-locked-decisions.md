# Locked decisions — WorkLists/attach-repository-files-as-notes

Phase 3 output. Every decision that resolved an open variable, an assumption, or a story question, with its source and where it lands in the spec. Rejected paths are recorded, not deleted.

Source vocabulary: **user** (decided by the owner) · **evidence** (resolved by tracing code or measuring, per the Step 7 reconcile — never brought to the user as a decision) · **user-corrected** (the agent proposed one thing, the owner supplied a fact that changed it).

---

## Question gates resolved

| # | Gate | Resolved |
| --- | --- | --- |
| G1 | Is the mechanism the agent's to choose? | **No.** The investigation's reframe contradicted an explicit instruction in the request. Asked. → LD-001 |
| G2 | Is the repository root discoverable in code? | **No.** No candidate exists anywhere. Asked. → LD-003 |
| G3 | Is the dot-folder question a decision or a fact? | **It was a fact the agent did not have.** The agent recommended including dot-folders on the premise they held frequently-edited docs. The owner supplied the missing fact: they hold generated output. → LD-005 |
| G4 | Is "where else is this attached" a real criterion? | **The criterion as written was rejected by the owner**, and a different, useful requirement was surfaced in its place. → LD-008 |
| G5 | Are file identity, AI-refine reach, live refresh, and file history decisions? | **Identity and refresh are; refine-reach and history are not** — refine-reach is settled by what the chosen root contains, history by the root being a git repo. Resolved by evidence rather than asked. → LD-009 to LD-012 |

---

## Decision ledger

### LD-001 — Mechanism: server-resolved repository root

**Decision.** WorkLists resolves the repository root server-side. The browser never holds a filesystem handle.
**Source:** user.
**Supersedes / rejects:** rejects porting Cairn's `showDirectoryPicker` + IndexedDB handle + `queryPermission` machinery, which is what the original request asked for verbatim ("we just need to translate the permission process from one app to the other").
**Why the request's own instruction was set aside:** report §1 and §6 — Cairn's machinery exists because Cairn has no server, and its own source comments say so. Porting it was measured to cost automated coverage (a native picker is an OS dialog Playwright cannot drive), cross-machine content consistency, and browser portability.
**What is still ported:** the *guarantee* — one root, granted once, everything under it reachable, nothing outside it, failures named from a closed vocabulary — plus Cairn's path rules and both failure enums.
**Honest framing required in the spec:** this is a **scope declaration, not an OS grant.** The server already has unrestricted `node:fs` authority; the root bounds where that authority may be pointed. It is a weaker guarantee than Cairn's and the spec says so plainly.
**Spec destination:** §Architecture, §Authority boundary.

### LD-002 — Bind `127.0.0.1` before any file route ships

**Decision.** `server.js` binds loopback only. This lands **before** the first file route, as a gate.
**Source:** user.
**Why:** `server.js:3615` is `app.listen(port)` with no host → `0.0.0.0`; `app.use(cors())` is unrestricted; there is no authentication middleware anywhere. Today the LAN-reachable surface is the board. File routes would widen it to every file under the root.
**Accepted cost:** any deliberate cross-device access to the board breaks. The pinned-board sync feature suggests that may have been intended.
**Spec destination:** §Sequencing and gates. **Concern:** FDC-01 updated from "recommended" to "decided".

### LD-003 — Repository root is `C:\dustin-thomason`

**Decision.** One root, absolute, `C:\dustin-thomason`.
**Source:** user.
**Rejects:** `C:\dustin-thomason\docs` (narrower, was the agent's recommendation) and `C:\Users\dktho\OneDrive\PDProjects` (inside OneDrive, so every write would be a synced write — the per-record spike recorded live `EBUSY`/`EPERM` contention in that tree).
**Measured against the ported bounds (LD-013), and non-binding:** 450 files after the skip rules, 363 `.md` + 6 `.mdc`, max depth 7, largest Markdown 600 KB (`worklists-app-changelog.md`), zero symlinks.
**Consequence to carry:** the root is a **git repo**, which is what makes LD-006's autosave and LD-009's path identity acceptable — git is the recovery path for both.
**Spec destination:** §Settings, §Bounds.

### LD-004 — WorkLists card: `todo-1782484871383-6b5676db`

**Decision.** Card supplied by the user — path A of `worklists-card-sync`. No card was created.
**Source:** user.
**Guard note, recorded rather than silently passed:** the rule's ticket-id-mismatch guard could not be applied — the card title is "Implement File Upload for System Repository" and personal projects carry no ticket id. The guard exists to stop a *text match* reaching the wrong card; identification here was a user-supplied id, which is the case the guard was written to make unnecessary. The card's own body describes this work.
**Consequence recorded:** the card predates the request (2026-06-26) and frames the work as **upload with backend storage** — "Create a backend storage strategy for persistent file management". That is the model report §6 rejected (alternative 2). The 2026-08-28 request is the authority for this ticket; the card's older framing is prior thinking, not a requirement. The card's third bullet ("parse and utilize file content … for system context") is an *additional consumer*, not a contradiction — a reference model serves it equally well — and is out of scope here.
**`currentStep` / `nextUp` could not be written:** the card carries no workflow section headings, so `PATCH /todos/{id}` answers `400 — Card has no workflow sections. Refusing to restructure it`. Attempted once and recorded; the agent may not add sections. Checklist rows were written successfully.
**Spec destination:** n/a — ledger only.

### LD-005 — Keep Cairn's dot-entry skip

**Decision.** Dot-prefixed files and directories are excluded from the browse list, exactly as Cairn does. `SKIP_DIRECTORIES` is ported unchanged and gains `dnu` (LD-018).
**Source:** **user-corrected.** The agent recommended the opposite, on the premise that `.claude/rules`, `.cursor/rules` and `.agents` hold frequently-edited documents. The owner supplied the fact that changed it: *"all of those folders you are mentioning are only populated of the C:\dustin-thomason\agents folder, they are not to be edited anyway by a human, they are updated via scripts."*
**Verified after the correction:** authored rule sources live at `C:\dustin-thomason\agents\rules\*.md` — fifteen files on a **non-dot** path, fully reachable. The 113 `.md` and 15 `.mdc` under dot-folders are generated copies; `.claude/rules/worklists-card-sync.md` carries the header *"generated from rules/worklists-card-sync.md by scripts/sync-rules.ps1; edit the source, not this file"*.
**Why this is now the better rule, not merely the requested one:** it makes the `personal-methodology` prohibition on editing generated output **unbreakable by construction** rather than by discipline. A generated file cannot be attached, so it cannot be edited through a card.
**Spec destination:** §Bounds and exclusions.

### LD-006 — Inherit autosave on focus exit

**Decision.** A file-backed note behaves exactly like an ordinary note: focus exit commits. No separate save gesture, no read-only-until-unlocked step.
**Source:** user.
**Rejects:** explicit-save-only (the agent's recommendation) and autosave-after-unlock.
**Why the owner's call holds:** story 02's criterion is that a pulled-in document *behaves the same as anything else in that spot*. A different save gesture bends that criterion, and the root being a git repo (LD-003) means a stray write is visible in `git status` and revertible — the recovery path the agent's recommendation was protecting against already exists.
**Risk accepted:** a stray focus exit writes a real file. → **FDC-04.**
**Spec destination:** §Editing and save. **Test consequence:** NP-7 is rewritten, not reinterpreted — see the test plan.

### LD-007 — Detach only; the app never deletes a file

**Decision.** Taking a document off a card removes the reference. There is no path from WorkLists to deleting a file. Not deferred — closed.
**Source:** user.
**Clarifies the original request, which is preserved unaltered:** the request's *"remove them from the specific file that was loaded"* read as ambiguous between detaching and deleting. The owner identified this as a summarization artifact: *"this may have been a misinterpretation from the agent that summarized the request, we are to detach files from the 'card'. That is all that we're talking about here."* Per the original-ticket artifact rule, `original-ticket.md` is **not** edited; the clarification lives here.
**Consequence:** story 04's criterion "the two are separate actions" is satisfied by one of them not existing, which is the strongest possible form of it.
**Spec destination:** §Detach.

### LD-008 — Usage visibility is not a precondition; it becomes its own story

**Decision.** Two parts.
1. Story 05's criterion *"The person can find out where else a document has been pulled in before they change or remove it"* is **rejected** and rewritten out.
2. The useful requirement underneath it — an inventory of which files are loaded into the system and which cards hold them — becomes **story 06**, drafted now, **out of scope for this slice**.
**Source:** user.
**The owner's reasoning, recorded because it is the design principle, not just a preference:** *"Whenever you change something, the point is that it only touches one file… All that attachment really says is that it is a pointer… It can be updated from any one of the locations, and we do not need to know where else it actually touches."* The mental model is a package: update the package, downstream consumers get it. Knowing the consumer list is not a precondition of publishing.
**And what survives:** *"being able to manage it in some way and have visibility of where it is located and how many instances exist is very useful"* — management and duplicate-detection, not a pre-change gate.
**Spec destination:** §Non-goals (with a pointer to story 06).

### LD-009 — File identity is the path relative to the root

**Decision.** A `source` reference stores the root-relative path. A rename breaks the reference; the note says `not-found` and re-attaching is the repair.
**Source:** evidence (Step 7 reconcile — resolved rather than asked).
**Rejects:** (a) injecting a front-matter id into the user's files — it mutates documents the app does not own and would appear in every git diff in his workflow repo; (b) a sidecar index mapping ids to paths — a second source of truth for something the filesystem already answers, which has to be kept correct through renames the app never sees.
**Why the structure supports this:** nothing in WorkLists references a file today, so there is no identity scheme to mirror and no migration to honour. The root is a git repo (LD-003), so a rename is recoverable and visible.
**Risk accepted:** renaming or moving a file outside the app breaks every reference to it at once. → **FDC-05.**
**Spec destination:** §Record shape.

### LD-010 — AI paths must not reach a file-backed note

**Decision.** `undoAiNoteRefine`, the refine-job apply path, and the server-side Gemma refine job must be **unable** to operate on a note that carries a `source`. Proven by test, not asserted.
**Source:** evidence.
**Why LD-003 makes this decisive rather than cautious:** the chosen root contains `agents/rules/*.md` — the fifteen authored rule files that govern how every agent in this workspace behaves. A refine reaching a file-backed note would let a model rewrite them, and the rewrite would be a real commit in a real repo.
**Spec destination:** §Blast radius. **Test:** PN-7 — a test proving unreachability, not a claim that it will not happen.

### LD-011 — No live file watcher in this slice

**Decision.** Content is read through on card open. A file changing on disk while a note is open is not detected until the next open; a save in that state is caught by the mtime precondition (LD-017), so nothing is silently lost.
**Source:** evidence.
**Why:** `fs.watch` is unreliable on Windows and worse under OneDrive; read-through already satisfies story 02's "current content, not a snapshot" (test HP-7). Adding a watcher buys detection between opens and costs a whole reliability surface.
**Spec destination:** §Non-goals. Closes story 02 Q4.

### LD-012 — No in-app file history

**Decision.** WorkLists keeps no history of file edits.
**Source:** evidence — `C:\dustin-thomason\.git` exists; the root is a git repo, so every write is already versioned and revertible by the tooling the owner uses daily.
**Spec destination:** §Non-goals. Closes story 03 Q4.

### LD-013 — Cairn's declared bounds are ported unchanged

**Decision.** ≤ 5000 files enumerated, depth ≤ 12, ≤ 2 MB per document; `SKIP_DIRECTORIES` = `node_modules`, `dist`, `build`, `out`, `coverage`, `.git`, plus `dnu` (LD-018); dot-entries skipped (LD-005).
**Source:** evidence — ported from `Cairn/components/vault-source/sources.js:20-45`.
**Measured non-binding at the chosen root** (450 / 7 / 600 KB, LD-003). They are kept anyway because they are the guard for a root pointed somewhere pathological later — declared limits, not measurements.
**Spec destination:** §Bounds and exclusions.

### LD-014 — Attachable kinds: Markdown only (`.md`, `.mdc`)

**Decision.** Only `.md` and `.mdc` appear in the browse list.
**Source:** evidence + the request's own framing ("read and interacted with as a markdown document"). The surface renders Markdown; nothing else has a rendering path.
**Spec destination:** §Bounds and exclusions. Closes story 01 Q4.

### LD-015 — The setting is a DAL section, and `TEMP_FILE_PATTERN` gets derived

**Decision.** The root is stored server-side as a new DAL section. **As part of the same change, `TEMP_FILE_PATTERN` is derived from `SECTIONS` rather than hand-written.**
**Source:** evidence.
**Why the second half is in scope rather than deferred:** `dal.js:59` keeps the section list twice — once as an array, once as a literal alternation inside a regex. This ticket is the first to add a section, so it is the first to be able to break the pair, and the failure is silent (unrecognised temp files accumulate). FDC-02 recorded it as "fix it when someone next adds a section". This is that moment.
**Cross-machine note:** the setting lives in the OneDrive-synced `data/` tree, so the value syncs. `C:\dustin-thomason` is a git clone present on each machine, so the same absolute path resolves on both; a machine without the clone gets the visible unreadable-root state (NP-8), not a silent failure. Closes story 01 Q2.
**Spec destination:** §Settings, §Data model.

### LD-016 — The note record gains an optional `source`

**Decision.** `{noteId, eventId, text, createdAt, lastModified, source?}`. A note without `source` behaves exactly as today — no migration, no backfill, no default value written to 562 existing records.
**Source:** evidence. `source` is shaped `{kind, ref}` so a second kind is additive; only one kind exists now.
**Spec destination:** §Record shape.

### LD-017 — Concurrency mirrors the existing note-checklist precondition

**Decision.** A file write carries the mtime read at load; the server compares and answers `409` with the current value on mismatch. Same shape as `PATCH /api/notes/:noteId`'s `expectedLastModified`.
**Source:** evidence — `server.js:2896-2920`, exercised by `tests/note-checklist-patch.test.js`.
**Interaction with LD-006:** autosave makes this load-bearing rather than defensive. Two cards open on the same document, both autosaving on focus exit, is now a reachable state; the precondition is what stops the second one silently overwriting the first.
**Spec destination:** §Editing and save.

### LD-018 — `dnu` directories are excluded from the browse list

**Decision.** Any directory named `dnu` is excluded, alongside `SKIP_DIRECTORIES`.
**Source:** evidence — the standing `dnu-folders` rule: *"Never pull a `dnu/` folder into context… a superseded file reads exactly like a current one."* An attached retired document would be read by every later agent as current.
**Residual:** attaching a retired document deliberately is not possible without changing the exclusion list. Judged the correct trade — the rule's own stated exception is an explicit instruction, and changing a list is an explicit instruction.
**Spec destination:** §Bounds and exclusions.

### LD-020 — The document is chosen by browsing the root, not by typing a path

**Decision.** The attach action lists Markdown files under the root (after the LD-005/LD-013/LD-018 exclusions) and the person picks one. No free-text path entry.
**Source:** evidence.
**Why:** a typed path is a second way to reach the filesystem and therefore a second thing the containment check has to defend, for no gain — the browse list is already the containment boundary made visible. It also makes NP-1's traversal cases unreachable from the UI, so the containment tests defend against a compromised or scripted caller rather than against ordinary use.
**Spec destination:** §Attach flow. Closes story 02 Q1.

### LD-021 — A file-backed note shows its path where an ordinary note shows its timestamp

**Decision.** A file-backed note displays its root-relative path in the note's meta row, in place of the created-at timestamp an ordinary note shows there. Nothing else about it differs.
**Source:** evidence, forced by LD-006.
**Why this is a safety decision, not a styling one:** story 02's criterion asks that a pulled-in document look and behave like any other note, which read alone argues for *no* distinction. LD-006 changes that calculus — autosave on focus exit now writes a real file in a git repo. A person who cannot tell which notes write to disk cannot avoid the one accident LD-006 accepts. The path is the smallest disclosure that fixes it, and it occupies a slot that already exists rather than adding chrome.
**Interaction recorded:** story 02's criterion is satisfied in substance — same surface, same controls, same places — with one field showing different content. Called out here so nobody later reads it as a violation.
**Spec destination:** §Rendering. Closes story 02 Q3.

### LD-022 — Detach reuses the existing delete control; no new menu item

**Decision.** For a file-backed note, the existing per-note delete control **is** detach: it removes the reference row and nothing else. Its label and confirmation wording change for file-backed notes ("Remove from card"); no `Detach` item is added to the per-note menu.
**Source:** evidence, following from LD-007.
**Why this is simpler than the Phase 1 sketch:** the recon staged a separate detach item on `.notes-pane-note-menu`, reasoning that detach and delete needed visible separation. LD-007 removed the thing it needed separating from — since the app can never delete a file, deleting the note record *is* detaching. Two controls for one action would be worse than one, and would break story 02's "same controls in the same places".
**Story 04's criterion survives intact:** "the person can tell whether they are taking it off this work or getting rid of the file, and the two are separate actions" is satisfied by the second action not existing — the strongest available form. The relabel plus confirmation wording is what makes it *tellable*.
**Spec destination:** §Detach. Closes story 04 Q2. Supersedes the Phase 1 recon's §5 UI sketch — recorded here rather than by editing the frozen recon doc.

### LD-023 — Selecting a folder ticks its direct files; it does not become a node

**Decision.** A folder row in the picker has a checkbox that selects the Markdown files sitting **directly** in it. The person sees the count, can untick individual files, then attaches. A folder never becomes a note.
**Source:** user (2026-08-29).
**Rejects:** (a) attaching a folder immediately as N notes without a review step; (b) a folder becoming one note that renders an index of its files.
**Why (b) was rejected and this matters:** the document surface renders one Markdown document. A folder is not one, so a folder node would need a different rendering, which breaks story 02's accepted criterion that a pulled-in document looks and behaves like anything else in that spot. It would also collide with LD-011 (no watcher): a folder node implies the folder's *current* contents, and without a watcher it would silently mean the contents as of attach time.
**Source-truth note.** The verbatim request does not ask for folder attachment. Its three uses of "folder" are all about the permissioned root — *"grant permission to a specific folder"*, *"designate one main folder that becomes permissioned"*, *"the settings location for choosing a folder to be permissioned"*. What it does say, in the plural, is *"attach files"* and *"pull items from the ellipse menu to attach files"*, which supports multi-select. Folder-selection is **new scope added by the owner**, recorded as such rather than back-read into the original request.
**Spec destination:** §Attach flow.

### LD-024 — Direct children only, never recursive

**Decision.** A folder's checkbox reaches the files immediately inside it. Subfolders are selected on their own rows.
**Source:** user (2026-08-29).
**Why:** at the chosen root, `docs` holds roughly 300 Markdown files across its subtree. A recursive checkbox would let one click on a top-level folder select all of them, and the difference between the row's recursive count and its non-recursive reach is exactly the thing a person cannot see before clicking.
**Consequence kept visible:** a folder row shows the **recursive** count (Cairn's behaviour, useful for orientation) while its checkbox selects **direct children only**. The two numbers differ on purpose. A regression test asserts both at once so a later change cannot quietly make one follow the other.
**Spec destination:** §Attach flow.

### LD-025 — Warn above ten, refuse above twenty-five

**Decision.** Above ten selected documents the picker states the count and what it will do; above twenty-five the Attach button is disabled and says to clear some. The server enforces the same ceiling independently and answers `400 too-many`.
**Source:** user (2026-08-29).
**Why the server enforces it too:** the client limit is a usability guard; the server limit is what stops a scripted or repeated call filling a card. The numbers are served with the listing (`attachMaxBatch`, `attachWarnAbove`) rather than written into the client, so there is one copy — the same duplication class as FDC-02.
**Spec destination:** §Attach flow, §Bounds.

### LD-026 — Attaching a batch is one request and one write

**Decision.** `POST /api/files/attach` takes the whole selection, validates and reads each path individually, and writes the notes section once. A path that fails is reported in `skipped` with its own reason; the rest still attach.
**Source:** evidence.
**Why:** `data/event-notes.json` is a single ~900 KB file in the OneDrive-synced tree, and `dal.atomicWrite` already retries `EBUSY`/`EPERM` there — the contention the per-record-storage spike measured. Looping the single-note route twenty-five times would rewrite that file twenty-five times in a row.
**Reporting consequence:** a batch can partly succeed, so the toast names both halves. "Attached 8" while two were silently dropped is the report shape that makes a wrong count believable.
**Spec destination:** §HTTP surface, §Attach flow.

### LD-027 — Cairn's explorer is ported, with pointers back to it

**Decision.** The picker uses Cairn's folder tree — nesting, folders-above-files with natural-order names, recursive child counts, `8 + depth * 13` indentation, chevron rotation on expand. Every ported piece names the Cairn file and symbol it came from, in the code and in the spec.
**Source:** user (2026-08-29), who asked for Cairn's look and feel and for pointers to where the pieces were copied from.
**Ported:** `app.js:941 buildTree`, `app.js:964 countFiles`, `app.js:1147 renderTree`, `index.html:345/359` row templates, `styles.css:761-952` `.tree-*` rules.
**Deliberately not ported:** dirty and checked-out status codes, inline create and rename, drag, workspace-root removal. Those serve Cairn's editor, not a picker.
**Added here and absent there:** selection. Cairn opens one document; this chooses a set.
**Enforcement:** a test asserts each provenance pointer is present, so the port stays auditable rather than becoming anonymous code.
**Spec destination:** §Provenance.

### LD-019 — Non-goals confirmed

Non-Markdown files, multiple roots, cloud providers, creating files from inside WorkLists, in-app file history, live watching, deleting files, and usage-visibility (→ story 06). **Source:** report §3 plus LD-007, LD-008, LD-011, LD-012.

---

## Open, carried forward

| # | Item | Owner | Why it is carried rather than closed |
| --- | --- | --- | --- |
| C1 | Story 06 (attachment inventory) scope and delivery | user | Drafted at Phase 3 on the owner's suggestion; deliberately not implemented in this slice. Its index row reads `draft`, not `accepted`. |
| C2 | Whether the card's title should stop saying "File Upload" | user | The agent may not restructure a card. The title now names a model the ticket rejected, which will mislead a future reader. |
