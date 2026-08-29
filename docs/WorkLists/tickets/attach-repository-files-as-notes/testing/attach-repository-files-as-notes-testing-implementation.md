# Testing implementation — WorkLists/attach-repository-files-as-notes

> Companion to [the test plan](./attach-repository-files-as-notes-test-plan.md). The scenarios stress-tested and what came of each. PR-comment content; never a code comment.

Branch `attach-repository-files-as-notes`, off `049d73f`. Revised 2026-08-29 when batch and folder selection were added.

---

## Scenarios stress-tested

### Scenario 1 — Someone points the app at a folder and expects it to reach everything inside, and nothing outside

- **Why it matters:** this is the security boundary. Everything else in the ticket assumes it holds. The app is a Node process with unrestricted `node:fs` authority, so "the root" is the *only* thing standing between a document picker and the rest of the disk.
- **Covered by the plan?** Yes — NP-1, NP-2, EC-1/2/3/8.
- **Result:** held. `resolveInRoot` refuses `..` traversal, absolute paths, UNC paths, backslash separators, empty and `.`/`..` segments, and — the one that matters — **a symlink inside the root that resolves outside it**.
- **Note on the symlink case:** it is the reason `fs.realpath` is in the chokepoint at all. Every string rule ported from Cairn passes that input happily. Cairn never needed the check because a `FileSystemDirectoryHandle` cannot be traversed upward; a Node path can. The test creates a real junction and asserts the refusal, and it skips loudly (rather than passing quietly) on a host where symlink creation needs elevation.

### Scenario 2 — Someone edits an attached document and clicks away, and expects the real file to change

- **Why it matters:** the whole point of the feature. If the write lands anywhere but the file, the app has silently reintroduced the divergent copy it exists to remove.
- **Covered by the plan?** Yes — HP-9, the red→green pair.
- **Result:** held, and proven in a real browser rather than only at the API. The Playwright scenario types into the mounted surface, clicks another note, then reads the file from disk and asserts the edit is there **and** that the note record's own `text` is still `""`.

### Scenario 3 — Two cards hold the same document, and one of them saves over a change it never saw

- **Why it matters:** LD-006 inherited focus-exit autosave, which makes this reachable by accident rather than by malice. Without a precondition the second card's stray autosave silently destroys the first card's edit.
- **Covered by the plan?** Yes — NP-4.
- **Result:** held. The write carries the mtime read at load; a mismatch answers `409` with the current value, nothing is written, and the person's text stays in the editor. The client's conflict branch deliberately does **not** re-render, because re-rendering would rebuild the surface from stored text and take the unsaved words with it — asserted directly by a test that reads the branch and fails if `renderNoteItemContent` appears in it.

### Scenario 4 — Someone clears a finished card and expects the document to survive

- **Why it matters:** removing something has always meant destroying it. Getting this wrong destroys a real file in a real repo.
- **Covered by the plan?** Yes — HP-11, DS-4.
- **Result:** held. Detach removes the record only. The browser test stats the file before and after and asserts **both** the bytes and the mtime are unchanged — mtime because a byte-identical rewrite would still be a write, and would still show up in `git status`.

### Scenario 5 — A model is pointed at a note whose content is one of the workspace's own agent rules

- **Why it matters:** the chosen root is `C:\dustin-thomason`, which contains `agents/rules/*.md` — the fifteen authored files governing how every agent in this workspace behaves. An AI refine reaching a file-backed note would let a model rewrite them, and the rewrite would be a real commit.
- **Covered by the plan?** Yes — PN-7, and it explicitly demands proof of unreachability rather than a promise.
- **Result:** held, at three layers. `PUT /api/notes/:noteId` and the checklist `PATCH` refuse a file-backed note with `409 file-backed-note`; both Gemma note jobs refuse at the job level; and the client does not render the AI controls on a file-backed note at all. The test asserts the guard is present in **both** Gemma paths by count, so adding a third job without a guard fails it.

### Scenario 6 — A document is renamed or deleted outside the app while a card still points at it

- **Why it matters:** a blank note looks like an empty document. The person needs to know the difference between "this file has nothing in it" and "this file is gone".
- **Covered by the plan?** Yes — NP-3.
- **Result:** held. The note renders a stated `not-found` in its own body and **the record survives**, so re-attaching is a repair rather than a re-creation.

### Scenario 7 — Someone attaches a document that is already on that card

- **Why it matters:** two identical notes on one card is the kind of mess that is easy to create and annoying to clean up.
- **Covered by the plan?** Yes — NP-6.
- **Result:** held, in two places. The server refuses with `409 already-attached`, and the picker shows an already-attached document **disabled with a reason** rather than hiding it — a missing row would look like the document had vanished.

### Scenario 8 — A `.md` file in a dot-folder is offered for attachment

- **Why it matters:** at the chosen root, `.claude/rules`, `.cursor/rules`, `.agents` and `.github` hold **generated** copies of files authored under `agents/rules/`. The standing rule is that generated output is never hand-edited. If those were attachable, the rule would depend on someone remembering it.
- **Covered by the plan?** Yes — EC-3.
- **Result:** held, and enforced structurally. Keeping Cairn's dot-skip means a generated file cannot be attached, therefore cannot be edited through a card. The browser scenario seeds a `.generated/hidden.md` under the test root and asserts the picker offers exactly one document.

### Scenario 9 — Someone opens an attached document, scrolls it, switches modes, and leaves without typing

- **Why it matters:** with autosave inherited, "did merely looking at it write to my repo?" is a fair question, and the answer must be no. A file whose mtime moves every time it is read is a file that pollutes `git status` on every visit.
- **Covered by the plan?** Yes — NP-7, which was **rewritten at refinement** rather than reinterpreted: LD-006 inverted what the seeded version asserted.
- **Result:** held.

### Scenario 10 — An ordinary note goes on behaving exactly as it did

- **Why it matters:** 562 existing notes. The feature is additive or it is a regression.
- **Covered by the plan?** Yes — PN-1…PN-8, DS-5.
- **Result:** held. Ordinary notes still autosave on focus exit, still carry both per-note menu items, still fall back to the markdown-kit renderer, and `tests/note-checklist-patch.test.js` passes **with no edits to it**. No `source` field is written to any existing record.

---

## Newly uncovered during testing — and the two defects they found

### Scenario 11 — The Files tab is clicked and its panel has to actually be on screen

- **Covered by the plan?** **No — surfaced only by the end-to-end browser run.**
- **Why it matters:** this is the plainest possible failure, and every unit test missed it.
- **Result:** **failed → fixed.**
- **Change:** `public/todolist2.js` — the Files panel was created and registered with `panels.set("files", filesPanel)`, which is what tab switching reads, but it was **never appended to the dialog body**. Observed: clicking the Files tab showed nothing; the root input did not exist in the DOM. Expected: the panel renders like the other eight. Fix: `body.appendChild(filesPanel)` alongside the others.
- **Why the unit tests could not catch it:** they are source-contract tests. Every assertion about the tab — that it is registered, that it has an id, that it distinguishes three states — was true of source that produced an invisible panel. Registering a panel and mounting it are two different acts, and only a real render can tell them apart. A guard was added to `tests/settings-file-repository.test.js` asserting the `appendChild` call, so the *specific* miss is now cheap to catch; the general lesson is that source-contract coverage of a UI surface needs one real render behind it.

### Scenario 12 — The document picker opens, and the notes pane it was opened from has to still be there

- **Covered by the plan?** **No — surfaced only by the end-to-end browser run.**
- **Why it matters:** the attach silently half-worked. The POST returned `201`, the toast said "Attached attached.md", and the notes list was empty — the most confusing possible outcome, because every signal said success.
- **Result:** **failed → fixed.**
- **Change:** `public/todolist2.js` `isNotesPaneOpenTarget` — the picker is an overlay on `document.body`, so the pane's outside-click dismissal read the picker click as a click outside the pane and closed it. `activeNotesTaskId` became `null`, so the reload that follows the attach hit its own guard and rendered nothing. Observed: attach succeeds server-side, notes list empties. Expected: the pane stays open and shows the new note. Fix: exempt `.file-picker-overlay`, alongside the card-action menu that was already exempted **for exactly this reason** — the existing comment in that function describes the same failure.
- **Worth saying plainly:** this was not a new class of bug. The codebase already knew about it and had already written down why. The fix took one selector; finding it took a live probe, because nothing in the source looked wrong.

### Scenario 13 — A repository root is chosen that sits inside the app's own data directory

- **Covered by the plan?** Yes — NP-2 — but it was **the test fixture that violated it**, which is its own kind of evidence.
- **Result:** held. The first version of the browser scenario put its test repository inside the server's `DATA_DIR`, and the save was correctly refused with "That folder overlaps the WorkLists data directory." The fixture was moved to a sibling temp directory. A guard written for a hypothetical caught a real mistake within an hour of existing.

## Added 2026-08-29 — batch and folder selection

### Scenario 14 — Someone wants a folder's worth of documents on a card, not one at a time

- **Why it matters:** the first cut let one document be picked from a flat list. A person whose related documents sit together in a folder had to repeat the whole flow once per file, and had no way to see the group they were assembling.
- **Covered by the plan?** No. Raised by the owner while reviewing the built feature.
- **Result:** held after the change. A folder's checkbox selects the documents directly inside it; the footer states the count; individual files can be unticked before committing. Proven end-to-end in a real browser: the scenario ticks a folder, unticks one file, and asserts the trimmed set is what attaches.
- **Change:** `public/fileAttachments.js`, `public/todoliststyles2.css`, `server.js` — observed: only one document could be chosen, from a flat list with no folder structure. Expected: several documents, or a folder's worth, chosen together with the count visible before committing. Fix: ported Cairn's folder tree into the picker, added a checkbox per row, and added `POST /api/files/attach` for the batch.

### Scenario 15 — A folder's row count and its checkbox mean different things

- **Why it matters:** a folder row shows how many documents lie beneath it, recursively, because that is what orients someone browsing. Its checkbox reaches only the documents directly inside it, because at the chosen root `docs` holds roughly 300 documents in its subtree and a recursive checkbox would let one click select all of them. The two numbers differ, and the difference is invisible until acted on.
- **Covered by the plan?** No. It emerged from the depth decision (LD-024) rather than being anticipated.
- **Result:** held. Ticking `agents` selects nothing, because `agents` holds no documents directly, while its row still reads 3.
- **Change:** none needed; the behaviour was built this way. What was added is a test asserting **both numbers on the same node at once**, so a later change cannot quietly make the checkbox follow the count. A tidy-up that unified them would look like a simplification and would be a scope change.

### Scenario 16 — Half a selection cannot be attached

- **Why it matters:** a batch is where partial failure lives. Reporting "attached 8" while two were dropped is the shape of report that makes a wrong count believable, and the person only finds out later that something they expected is missing.
- **Covered by the plan?** No. It follows from batching, which the plan did not cover.
- **Result:** held. The route attaches the good paths and returns each bad one with its own reason, so one missing file does not cost the rest. A path already on the card, a path that no longer exists, and a path outside the root each come back named. The toast states both halves.
- **Change:** `server.js`, `public/todolist2.js` — observed: n/a, built this way. Expected: partial success reported as partial. Recorded here because the test that proves it (`attaches the good paths and reports the bad ones against themselves`) is the one worth keeping if the route is ever refactored.

### Scenario 17 — Twenty-five documents attached at once, into a synced JSON file

- **Why it matters:** `data/event-notes.json` is a single file of roughly 900 KB inside the OneDrive-synced tree, and `dal.atomicWrite` already retries `EBUSY`/`EPERM` there. That contention is measured, not hypothetical: it is what the per-record-storage spike recorded. A per-document loop would rewrite that file twenty-five times back to back.
- **Covered by the plan?** No. The plan predated batching.
- **Result:** held. The batch is one request and one write. A test asserts the section's modification time moves once for a two-document batch and that both notes exist afterwards.
- **Change:** `server.js` — the route was written as a batch from the start for this reason, rather than as a loop that was later optimised.

### Scenario 18 — A ported UI becomes anonymous code six months later

- **Why it matters:** the owner asked for Cairn's look and feel *and* for pointers back to where each piece came from. Without those, the port is unverifiable: nobody can tell what was copied, what was changed, or what was deliberately left behind, so nobody can diff it against the original when Cairn moves.
- **Covered by the plan?** No. It is a maintainability requirement rather than a behaviour.
- **Result:** held. Each ported function names its Cairn file and symbol in a header comment, the CSS block names the source line range, and the spec carries a provenance table. What was deliberately not ported is named too, which is the half usually lost.
- **Change:** `public/fileAttachments.js`, `public/todoliststyles2.css`, spec §16a — plus a test asserting every provenance pointer is still present, so the port cannot become anonymous by attrition.

---

## PR comment (ready to paste)

**What this adds.** A note's content can now come from a Markdown file in one declared folder, instead of only from its own record. Attach from the card ellipsis, edit it in place, and the edit lands in the real file. Detach removes the reference and never the file.

**The decision worth reviewing.** The request asked to port Cairn's `showDirectoryPicker` + IndexedDB permission machinery. That machinery exists because Cairn has no server — its own source comments say so. WorkLists has one, so the port would have bought a stronger OS-level guarantee at the cost of automated coverage (a native picker is an OS dialog Playwright cannot drive), cross-machine consistency, and Chromium portability. We took the server-resolved root instead and ported the *guarantee* — one root, everything under it reachable, nothing outside it, failures from a closed vocabulary — plus Cairn's path rules, with `realpath` containment added because a Node path can be walked out of through a symlink and a directory handle cannot. **This is a scope declaration, not an OS permission**, and the code says so where it matters.

**Two things found by testing, not by review:** the Files settings panel was registered but never mounted, and the document picker closed the notes pane it was opened from. Both are written up above with the observed → expected → fix.

**Also in this diff, deliberately:** `server.js` now binds `127.0.0.1` (it bound `0.0.0.0` with no authentication, and these routes widen what that reaches from "the board" to "any file under the root"), and `dal.js` derives `TEMP_FILE_PATTERN` from `SECTIONS` instead of duplicating the list — this is the first ticket to add a section since that duplication existed, so it is the first that could have hit it.

**Gates:** `npm audit --audit-level=high` pass · `npm run lint` pass · `npm test` **801 pass / 3 fail** (the same three pre-existing card-action/Gemma failures as before the branch) · `npm run test:browser` **14 pass / 0 fail**, including a full attach → edit → save-to-disk → detach run.
