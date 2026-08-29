# Why these changes — WorkLists/attach-repository-files-as-notes

> The living "Why" of this ticket. Created Phase 1, updated every phase, finalized at close. High-level — scenarios live in the testing-implementation doc; point-in-time classification lives in the investigation report.

## Problem class (the core — what are we actually solving?)

**Content-source indirection, bounded by a declared authority scope.**

Not "file attachment". That is the request's surface framing, and it points at the wrong solution space — blobs, uploads, a storage tier, a provider abstraction. Every genuinely hard part of this ticket is one of exactly two things:

1. **Where is a piece of content allowed to come from?** Today a note's content is the note record's own `text`. There is no other answer the system can give. The ticket asks for a second answer: *a file, and the file is the truth.*
2. **Where is the program allowed to look for it?** Today the program looks nowhere, because it has never looked outside its own data directory. The ticket asks it to look in a folder the user names, and only there.

The part that would be hard in most systems — rendering and editing a Markdown document with real fidelity — is already solved and already shared between the two apps. That is exactly what makes the request possible now, and the request says so itself: *"Previously, the system could not represent the same editing surface area, but now it can."*

Full classification and the reframe evidence: [investigation report §1](./investigations/attach-repository-files-as-notes-investigation.md).

## The code at the root (what/where is the problem)

There is no defect here — this is a capability gap, so "root cause" means *the specific place the capability is absent*:

- **`WorkLists/public/todolist2.js:5140` `createNoteItem` / `:5197` `renderNoteItemContent`** — a note's content is read from `item.dataset.rawText`, which comes from the note record's `text` and from nowhere else. This is the single point where a content source could be indirected.
- **`WorkLists/public/todolist2.js:6166` `saveNoteInlineEditor`** — the reciprocal write. It calls `ApiService.updateNote(noteId, text)` unconditionally. There is no branch for "this content belongs somewhere else".
- **`WorkLists/server.js` `/api/notes` routes + `WorkLists/dal.js:59` `SECTIONS`** — the storage authority. A note is a row in `data/event-notes.json`; the shape has no concept of an external source.
- **Nowhere at all** — there is no repository-root setting, no path resolver, and no containment check anywhere in WorkLists. `dal.js:9-13` `DATA_DIR` is the only filesystem root the app knows, and it is the app's own data directory.

Full trace: [investigation report §5](./investigations/attach-repository-files-as-notes-investigation.md).

## The problems we're solving

1. A document that already exists cannot be brought next to the work it explains without copying it — and a copy immediately starts drifting from the original.
2. There is no bounded place the program is allowed to read from, so "let it read a file" currently means "let it read anything".
3. The same document cannot be present in two places at once, because everything added to a card is its own separate copy.
4. Removing something has only ever meant destroying it, so there is no safe way to take a document off a card.

## Why-log (append per phase; label each entry)

### Phase 1 — 2026-08-28 — new understanding

- **Obvious:** the Dantalion document surface is already mounted per note (`todolist2.js:5197`) and already does view/edit/source/preview with real Markdown fidelity. Showing a file through it is not the hard part. The card ellipsis menu already has a documented extension seam (`getNotesPaneCollapseMenuActions`, `todolist2.js:4700`) — the request's "use the ellipsis on a specific card" lands in an existing slot.
- **Not obvious — and this is the finding of the phase:** the request's central instruction is *"we just need to translate the permission process from one app to the other."* Tracing Cairn's permission process showed that it is machinery for holding an OS-level grant inside a browser tab — `showDirectoryPicker` on the main thread, the handle handed to a worker through a kernel grant and immediately dropped, the handle persisted in IndexedDB because `localStorage` does not exist in a worker, `queryPermission` on recall, `vault.permission-required` when it lapsed. **Every one of those pieces exists because Cairn has no server.** WorkLists has one, running on the same machine, already reading and writing real files on every board mutation. Porting the mechanism would import a constraint without its reason.
- **What that costs, measured, not asserted:** the existing Playwright harness (`tests/browser-notes-smoke.js`) spawns the real server and drives real Chromium; a native folder picker is an OS dialog Playwright cannot drive, so every attach/read/write criterion would lose automated coverage. Notes render from `ApiService.fetchNotes`, so browser-held content would render differently in a browser that had not been granted the folder — which directly contradicts story 05's "each place shows the same content". And it makes Chromium a permanent hard requirement of WorkLists, which it is not today.
- **Assumptions logged:** (a) that the user wants the *guarantee* — one root, granted once, everything under it reachable, nothing outside it, failures named from a closed vocabulary — rather than the *mechanism*; (b) that "perpetually saved" means the reference survives, not that an OS grant survives. Both are recorded as assumptions precisely because the request's words point the other way, and a reclassification that contradicts an explicit instruction is a **proposal to the user, not a finding to act on**.
- **What was noise / discarded early:** reading this as an upload or attachment-storage feature. The request is explicit that the file stays where it is, that the attachment is a reference, and that the same file can be attached in several places — none of which is compatible with an upload model. Also discarded: reaching for the `StorageProvider` abstraction in the 2026-07-09 file-system blueprint. That blueprint's own phasing puts a provider abstraction at Phase 3, behind a simple-links MVP; building it now would be the "no more complex than it needs to be" line crossed on the first slice.
- **Still open (decisions, not lookups):** which of the two mechanisms; which folder; how a file is identified across renames; whether the pre-existing `0.0.0.0` bind is fixed as part of this work.

### Phase 3 — 2026-08-28 — [COURSE CHANGE] ×2

**The class held.** Twenty-two decisions later, the problem is still content-source indirection bounded by a declared scope. Nothing in the grill moved it. What moved were two assumptions the agent was carrying, and both were mine to be wrong about.

- **Course change 1 — the dot-folder exclusion inverted, and got better for it.** The agent measured 113 `.md` and 15 `.mdc` files under `.claude/`, `.cursor/`, `.agents/`, `.github/` at the chosen root and recommended making them reachable, on the assumption they were frequently-edited documents. The owner supplied the fact that changed it: those are **generated output**, produced from `agents/rules/*.md` by `scripts/sync-rules.ps1`. The authored sources sit on a non-dot path and were reachable all along.
  **Why this changes the solution, not just a setting:** keeping Cairn's dot-skip stops being parity-for-its-own-sake and becomes a **structural guard**. The standing rule "never edit generated output" is enforced by the browse list rather than by an agent remembering it — a generated file cannot be attached, therefore cannot be edited through a card. An exclusion the agent was about to remove for being arbitrary turned out to be load-bearing for a reason neither app had written down.
  **What this says about the recon:** the measurement was right and the inference from it was wrong. 128 files existing said nothing about who writes them. Counting is not knowing.

- **Course change 2 — autosave was chosen over safety, and the safety had to be rebuilt elsewhere.** The agent recommended explicit-save-only for a file-backed note, reasoning that autosaving into a real file is a different class of accident from autosaving into a database row. The owner chose parity with ordinary notes.
  **Why the owner is right:** story 02's criterion is that a pulled-in document behaves like anything else in that spot. A second save gesture bends the very criterion the feature exists to satisfy. And the recovery path the agent was protecting against already exists — the root is a git repo, so a stray write is visible in `git status` and reverts in one command.
  **What it cost, recorded rather than smoothed over:** it **invalidated a story-03 acceptance criterion** — "nothing is written to the file until the person saves". That criterion was replaced, not reworded to fit what was decided; reinterpreting it would have been the exact failure job stories exist to prevent. And it **forced a new decision**: LD-021, showing the file's path where an ordinary note shows its timestamp, because a person who cannot tell which notes write to disk cannot avoid the accident autosave accepts. A safety property was removed from the save gesture and had to reappear as disclosure.

- **A simplification fell out that the recon had got wrong.** Phase 1 sketched a separate `Detach` item on the per-note menu, reasoning that detach needed visible separation from delete. Once LD-007 established the app can never delete a file, there was nothing left to separate from — deleting the note record *is* detaching. Two controls for one action would have been worse and would have broken story 02. LD-022 supersedes the sketch. **Discarded path, logged:** the separate menu item.

- **Scope moved once, on the owner's initiative.** Story 05's pre-change visibility criterion was rejected outright — *"All that attachment really says is that it is a pointer… we do not need to know where else it actually touches."* The mental model is a package: publishing an update does not require enumerating consumers. What survived was a different requirement — inventory and duplicate visibility for management — and it became story 06, drafted and deliberately left out of this slice.

- **What was noise:** the agent's worry that "looks and functions like any other note" and "show the path" were in conflict. They are not; the control set is identical and one existing field shows different content. Named in story 02's log so a reviewer who spots the tension sees it was decided rather than missed.

### Phase 5 — 2026-08-28 — implementation

- **The why did not move.** Content-source indirection bounded by a declared scope is what got built, at exactly the two points Phase 1 predicted: `createNoteItem`/`renderNoteItemContent` for content in, `saveNoteInlineEditor` for content out. A prediction made before the code was written and still true after it is worth recording as such.
- **What testing changed, and it was not the design.** Two defects, both found only by the end-to-end browser run, neither visible in source review:
  - The Files settings panel was **registered but never mounted**. Every source-contract assertion about it passed while the tab opened onto nothing. Registering a panel and putting it in the DOM are two different acts, and only a real render tells them apart.
  - The document picker **closed the notes pane it was opened from**. The attach returned `201`, the toast said it worked, and the list went empty — the worst shape of failure, because every signal said success. The cause was already documented in the codebase: `isNotesPaneOpenTarget` carries a comment explaining this exact failure for the card-action menu. The picker was the same case; the fix was one selector.
  - **What both say about the work:** the unit tests were not weak, they were the wrong instrument. Neither defect is expressible as a source contract. The lesson recorded rather than the fix: a UI surface needs at least one real render behind its source assertions.
- **A guard caught its author.** The first browser fixture put its repository root inside the server's `DATA_DIR`, and the overlap validation refused it. A check written for a hypothetical caught a real mistake within an hour of existing.
- **Two changes shipped alongside, both deliberate, both stated in the spec before the code:** the loopback bind (`server.js` bound `0.0.0.0` with no authentication, and these routes widen what that reaches), and deriving `TEMP_FILE_PATTERN` from `SECTIONS` (this is the first ticket to add a section since that duplication existed, so it is the first that could have hit it).
- **What was noise:** worrying whether the path display would break story 02's "same controls in the same places". The browser test compares the two control sets directly and they differ by exactly the withheld AI action, which was already a deliberate decision.

## Changes made — categorized

Count: **4 requested changes · 1 capability gap · 2 bug fixes · 2 workflow changes**

### The file repository and its authority boundary — requested change

- **Before:** WorkLists knew exactly one filesystem root, its own `data/` directory. Nothing else on disk was reachable.
- **After:** one declared root, resolved server-side, with a single chokepoint (`resolveInRoot`) that every read and write passes through — path rules ported from Cairn, plus `realpath` containment that Cairn does not need and Node does.
- **Why:** the request's first requirement. Framed as "grant permission to a folder"; what it actually needs is a bounded scope, because the authority already exists.
- **Files:** `fileRepository.js` (new), `server.js`, `openapi.js`.

### Content-source indirection on the note record — capability gap

- **Before:** a note's content was its own `text`, at one unbranched read point and one unbranched write point.
- **After:** an optional `source` on the record. Absent on all 562 existing notes and never written to them; present, and the file is the content and the record's `text` stays empty.
- **Why:** the heart of the ticket. Two copies of one document is the divergence the whole feature exists to remove, so the record deliberately holds no cached copy.
- **Files:** `public/todolist2.js`, `server.js`, `dal.js`, `openapi.js`.

### Attach, edit, detach — requested change

- **Before:** the only way to get content beside a card was to type it there.
- **After:** an attach item on the card ellipsis (through the existing `extraActions` seam), a browse-only picker, in-place editing that autosaves to the real file, and a detach that reuses the existing delete control with wording that says which of the two is happening.
- **Why:** the request's other three requirements.
- **Files:** `public/fileAttachments.js` (new), `public/todolist2.js`, `public/cardActions.js`, `public/index.html`, `public/todoliststyles2.css`.

### The path shown where the timestamp goes — requested change (consequence of LD-006)

- **Before:** every note shows its created-at time.
- **After:** a file-backed note shows its root-relative path instead.
- **Why:** not decoration. Autosave writes a real file, so a person must be able to tell which notes do that. It is the smallest disclosure that achieves it, in a slot that already existed.
- **Files:** `public/todolist2.js`, `public/todoliststyles2.css`.

### The Files settings panel was never mounted — bug fix

- **Before:** the Files tab existed and switched to a panel that was not in the DOM.
- **After:** `body.appendChild(filesPanel)`, alongside the other eight.
- **Why:** written during this ticket and caught by its own end-to-end test. Recorded as a bug fix rather than folded into the feature, because the distinction between "registered" and "mounted" is the reusable lesson.
- **Files:** `public/todolist2.js`.

### The picker closed the notes pane — bug fix

- **Before:** choosing a document dismissed the pane, so the attach succeeded server-side and rendered nowhere.
- **After:** `.file-picker-overlay` is exempt from outside-click dismissal, like the card-action menu already was.
- **Why:** a body-level overlay opened from the pane's own menu reads as a click outside it. The codebase already knew this failure and had written down why; the picker was a second instance.
- **Files:** `public/todolist2.js`.

### Loopback bind — workflow change

- **Before:** `app.listen(port)` with no host → `0.0.0.0`, no authentication, unrestricted CORS.
- **After:** `127.0.0.1`, overridable by `WORKLISTS_HOST` so a deliberate cross-device setup has a supported way in rather than a code edit.
- **Why:** pre-existing, and this feature widens what it exposes from "the board" to "any file under the root". Decided as a gate before the first file route (LD-002), not discovered afterwards.
- **Files:** `server.js`.

### `TEMP_FILE_PATTERN` derived from `SECTIONS` — workflow change

- **Before:** the thirteen section names existed twice in `dal.js` — an array and a literal regex alternation.
- **After:** the pattern is built from the array.
- **Why:** this ticket adds the first new section since the duplication existed, so it is the first that could have silently broken the orphan sweep. Recorded as FDC-02 with "fix it when someone next adds a section"; this was that moment.
- **Files:** `dal.js`.

## Why it shipped together

Everything here traces to one of the five accepted criteria sets, or to a gate one of them required. The two that look like scope creep are not: the loopback bind is the security precondition for shipping a filesystem read route at all (story 01's "nothing outside that folder can" is hollow if anything on the LAN can call the route), and the `TEMP_FILE_PATTERN` derivation is forced by story 01's setting needing a DAL section. Neither could be deferred without shipping a known defect.

Story 06 (attachment inventory) was drafted and deliberately **not** built — the one place scope could have widened, and did not.

## Scope

Confined to WorkLists. `@cairn/dantalion` and `@worklists/markdown-kit` are consumed **unchanged** — the premise the request rested on, and it held: the document surface takes an opaque key and never touches the filesystem, so a file-backed note is just another key with a different host-side source.

Narrowed during implementation: nothing. Widened: nothing.

Spun off: story 06; FDC-04 (autosave writes a real file — tolerable only because the root is version-controlled, so a follow-up should warn when the chosen root is not a git repo); FDC-05 (a rename breaks every reference at once).

## Net

The app can now show and edit a document that lives somewhere else, and the file stays the only copy.
