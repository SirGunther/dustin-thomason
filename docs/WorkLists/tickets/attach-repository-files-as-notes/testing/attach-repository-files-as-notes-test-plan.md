# Test plan — WorkLists/attach-repository-files-as-notes

> Seeded from [the investigation report](../investigations/attach-repository-files-as-notes-investigation.md) §9 on 2026-08-28. **Refined 2026-08-28 against [locked-decisions.md](../specs/attach-repository-files-as-notes-locked-decisions.md) (LD-001 … LD-022) and [the spec](../specs/attach-repository-files-as-notes-spec.md).**

Status: **complete** — executed 2026-08-28 on branch `attach-repository-files-as-notes`

**What refinement changed.** The seed was written conditional on the mechanism decision, and every scenario carried an `[auto]` marker flagging that a browser-grant outcome would make it unexecutable. LD-001 chose the server-resolved root, so that condition is gone and every scenario below is automatable — the markers are removed rather than left as noise. Three substantive changes came out of the decisions: **NP-7 was rewritten, not reinterpreted** (LD-006 inverted what it asserts), and two new groups were added for exclusions (LD-005, LD-014, LD-018) and for the decisions that created new observable behaviour (LD-002, LD-015, LD-021, LD-022).

Criterion references are to the accepted job stories: **S01–S05**, criteria numbered in the order they appear in each story's Acceptance Criteria list. Story 06 is out of scope and has no scenarios.

## Scope and surfaces under test

- **Server:** loopback bind; `fileRepository.js` (`resolveInRoot`, `listDocuments`, `readDocument`, `writeDocument`); the five `/api/files` and `/api/settings/file-repository` routes; the new DAL section; the derived `TEMP_FILE_PATTERN`.
- **Client:** the Settings tab; the card-ellipsis attach item; file-backed note rendering and the path display; save routing; the relabelled detach control.
- **Data:** `data/event-notes.json` records with and without `source`; `data/appSettings.json`; the file on disk.
- **Explicitly also under test — the unchanged neighbours** (§16 of the spec): ordinary notes, both existing per-note menu items, the collapse-all item, focus-exit autosave, the checkbox `409` path, and the markdown-kit fallback renderer.

## Happy path

- [x] **HP-1** *(S01-5)* No root configured → open a card's ellipsis → the attach item is disabled **and** states that naming a folder is what unlocks it. Every `/api/files` route answers `422 not-configured`.
- [x] **HP-2** *(S01-1)* Settings → new tab → set the root to a temp folder containing `notes/spec.md` → save → reopen Settings → the saved value is shown. `data/appSettings.json` holds it.
- [x] **HP-3** *(S01-2)* Reload → the root is still in effect, nothing asks for re-confirmation. Restart the server → still in effect. *(Under a server root there is no grant to lapse — this asserts that.)*
- [x] **HP-4** *(S01-3)* A file nested three levels deep appears in the list; a file one level above the root does not.
- [x] **HP-5** *(S02-1)* Card ellipsis → Attach document → the list shows the root's Markdown files → pick `notes/spec.md` → a note appears in the notes list.
- [x] **HP-6** *(S02-2)* Assert the **same control set** is present on the file-backed note and on an ordinary note beside it — not merely that it rendered. Per LD-021 the meta row differs in content (path vs timestamp); the controls do not.
- [x] **HP-7** *(S02-3)* Change the file on disk between two loads of the same card → the second load shows the new content. *(Read-through, not a snapshot. This is also what stands in for a watcher under LD-011.)*
- [x] **HP-8** *(S02-4)* Reload → still attached, no second pick.
- [x] **HP-9** *(S03-1, S03-2)* **The red→green pair.** Edit a line → focus out → read the file from disk: it contains the edit. Read the note record: `text` is still `""`. *Fails before the change: the record's own empty `text` renders and no file is written.*
- [x] **HP-10** *(S05-1, S05-2, S03-6)* Attach the same file to a second card → open it → it shows the content edited in HP-9.
- [x] **HP-11** *(S04-1, S04-2, S04-3)* Remove from the first card → gone from that card; the file's bytes and mtime unchanged; the second card still shows it.
- [x] **HP-12** *(S04-5)* Re-attach to the first card → the same content returns.

## Negative paths

Each must fail **visibly** — a named reason from the closed vocabulary, never a blank, a silent no-op, or a raw stack.

- [x] **NP-1** *(S01-3)* **Containment — the load-bearing case.** `resolveInRoot` refuses each of: `../` traversal · an absolute path · a UNC path · a `\`-separated path · a path with an empty segment · a path with a `.` or `..` segment · **a symlink inside the root resolving outside it**. The symlink case is the one a path-string check alone passes, and the one Cairn never needed — it is why `fs.realpath` is in the chokepoint.
- [x] **NP-2** *(S01-1)* Root save refused, **previous value preserved**, for: nonexistent · a file not a directory · unreadable · a path containing `DATA_DIR` · a path inside `DATA_DIR`.
- [x] **NP-3** *(S01-4, S02-6, S04-6)* File deleted after attach → the note body states `not-found`. **Assert the record survives** — the note must not vanish and must not render blank.
- [x] **NP-4** *(S03-4)* File modified on disk after load → save refused with `409` + current mtime, **and the user's text is still in the editor afterwards.** The second half is the half that gets dropped.
- [x] **NP-5** *(S03-5)* File read-only → the save names *that* reason (`write-failed`, distinguished from `not-found` and `outside-root`); the draft survives.
- [x] **NP-6** *(S02-5)* Attach a file already on **that card** → refused with a message, note count unchanged. Attaching the same file to a **different** card succeeds — the two must not be conflated.
- [x] **NP-7** *(S03-3)* **Rewritten at refinement — LD-006 inverted the seed's assertion.** The seed asserted "abandoning an edit leaves the file untouched", which autosave makes false. What is asserted now: **opening a file-backed note, scrolling it, switching modes, and moving away without typing writes nothing** — the file's mtime is unchanged. Then: typing one character and moving away **does** write. Both halves are required; the first is the criterion, the second proves the test can tell the difference.
- [x] **NP-8** *(S01-4)* Root becomes unreachable while notes are open → each affected note says so and offers a route back to the setting; unaffected notes untouched. *(Also the second-machine-without-the-clone case from LD-015.)*
- [x] **NP-9** *(spec §7)* `PUT /api/files/content` with a `source.kind` other than `repository-file` is refused rather than treated as the known kind.

## Edge cases

- [x] **EC-1** A file at exactly 2 MB succeeds; one byte over is refused as `too-large`.
- [x] **EC-2** A tree deeper than 12 and a tree with more than 5000 files are each refused with their **own** named reason — not one shared "too big".
- [x] **EC-3** *(LD-005, LD-013, LD-018)* Exclusions hold: dot-prefixed files and directories · `node_modules`, `dist`, `build`, `out`, `coverage`, `.git` · any directory named `dnu`. **Specifically assert that a file under `.claude/rules/` is absent from the list** — that is the case LD-005 turned from a style choice into a guard, and a regression there would let a generated file be edited through a card.
- [x] **EC-4** An empty file attaches and renders as an empty document, not as an error.
- [x] **EC-5** A CRLF file round-trips a save **without a whole-file diff.** WorkLists is Windows-first and the root is a git repo — a silent EOL rewrite would show as every line changed in real history.
- [x] **EC-6** Names with spaces, `#`, and non-ASCII characters attach, render, and save.
- [x] **EC-7** An empty root → the list says so rather than showing an empty box.
- [x] **EC-8** *(LD-014)* A `.txt` and a `.docx` under the root are absent from the list. The root holds 45 `.txt` and 9 `.docx`, so this is a live case, not hypothetical.

## Decision-specific behaviour

- [x] **DS-1** *(LD-002)* The server accepts connections on `127.0.0.1` and **refuses them on the machine's LAN address.** This is the gate on every file route; assert it directly rather than trusting the argument was passed.
- [x] **DS-2** *(LD-015)* `TEMP_FILE_PATTERN` is derived from `SECTIONS`: adding a section name to the array causes the pattern to match that section's temp files, with no second edit. **Red→green in its own right** — the pre-change hand-written regex fails this.
- [x] **DS-3** *(LD-021)* A file-backed note shows its root-relative path in the meta row; an ordinary note shows its timestamp. Both, side by side, in one assertion.
- [x] **DS-4** *(LD-022)* The per-note delete control on a file-backed note is relabelled, and activating it removes the record while leaving the file's bytes and mtime unchanged. No `Detach` item was added to the per-note menu.
- [x] **DS-5** *(LD-016)* All 562 existing note records are byte-identical after the change ships — no `source` field written, no default, no migration.

## Protect-the-neighbours

- [x] **PN-1** An ordinary note still autosaves on focus exit.
- [x] **PN-2** `Show editing controls` and `Prompt Injection` are present on **both** an ordinary and a file-backed note.
- [x] **PN-3** The collapse-all item still appears on the card ellipsis alongside the new attach item.
- [x] **PN-4** `tests/note-checklist-patch.test.js` passes **with no edits to it.** An edit to that file is itself a finding.
- [x] **PN-5** With Dantalion unavailable, an ordinary note still falls back to the markdown-kit renderer — and a file-backed note does too, with its content still coming from the file.
- [x] **PN-6** `fitNoteEditorToViewport` geometry for an ordinary note is unchanged against the existing browser-smoke measurements.
- [x] **PN-7** *(LD-010)* **Unreachability, proven — not asserted.** For `undoAiNoteRefine`, the refine-job apply path, the server-side Gemma refine job, and `PATCH /api/notes/:noteId` checklist steps: each, invoked against a note carrying `source`, is refused. *A test that merely never invokes them does not satisfy this row.* The stake is concrete: the root contains `agents/rules/*.md`, the fifteen authored files governing every agent in this workspace.
- [x] **PN-8** Template-created notes never carry a `source` — `POST /api/cards/from-template` output asserted, not assumed.

## Manual verification

**Before / after**

| | Before | After |
| --- | --- | --- |
| Settings dialog | Eight tabs | Nine; the new one holds a path field, a validate/save action, a status line |
| Card ellipsis | Existing items only | One more, disabled until a root is set |
| A file-backed note | Impossible | Same surface and controls as any note; meta row shows the path instead of the timestamp |
| An ordinary note | — | **Identical.** Any visible difference is a regression |
| The file on disk | Untouched by WorkLists | Rewritten on focus exit after an edit — **the only place the edit is durable** |
| Server reachability | Any LAN device | `127.0.0.1` only |

> **The evidence for HP-9 is not on screen.** The note looks the same whether the write landed or not. Read the file, or read `git status` in `C:\dustin-thomason`. Do not screenshot the note.

**Preconditions**

- `npm run start-server`; Chromium-based browser at `http://localhost:3010`.
- A scratch root **outside** `WorkLists/data` containing: `notes/spec.md`; a file three levels deep; an empty file; a CRLF file; a `.txt`; a dot-directory holding a `.md`; a `dnu/` holding a `.md`; a symlink pointing outside the root.
- Baseline before acting: `git status` in the scratch root if it is a repo, plus `mtime` and byte count of `notes/spec.md`.

**Steps**

1. Settings (`#model-settings-btn`) → the new tab → paste the scratch root → Save. Expect the value echoed and a valid status.
2. Reload `http://localhost:3010`. Reopen Settings; the value persists. *(HP-2, HP-3)*
3. Open any card's notes pane → header ellipsis → **Attach document**. Expect the list to contain `notes/spec.md` and the deep file, and to **exclude** the dot-directory file, the `dnu/` file, and the `.txt`. *(HP-4, EC-3, EC-8)*
4. Pick `notes/spec.md`. Compare it side by side with an ordinary note on the same card: same controls, meta row shows the path. *(HP-5, HP-6, DS-3)*
5. Edit one line. Click a different note. Read the file from disk — the edit is there. Read `data/event-notes.json` — the record's `text` is `""`. *(HP-9)*
6. Open the note again, scroll it, switch preview/source, click away **without typing**. `mtime` is unchanged. *(NP-7, first half)*
7. Edit the file in another editor while the note is open, then type in the note and click away. Expect the conflict message and **your text still in the editor**. *(NP-4)*
8. Attach the same file to a second card; confirm it shows step 5's edit. *(HP-10)*
9. Remove it from the first card. `git status` in the scratch root shows no deletion; the second card still has it. *(HP-11, DS-4)*
10. From another device on the network, `curl http://<lan-ip>:3010/` — expect connection refused. *(DS-1)*

## Gates

| Gate | Command | Scope |
| --- | --- | --- |
| audit | `npm audit --audit-level=high` | WorkLists |
| lint | `npm run lint` | WorkLists |
| tests | `npm test` | WorkLists (`node --test tests/*.test.js`) |
| browser | `npm run test:browser` | notes-pane smoke, real Chromium |

Order is audit → lint → tests; lint may rewrite files, so tests run against the post-lint tree.

**Known baseline: 705 passed / 3 failed** — three pre-existing card-action/Gemma assertion failures unrelated to this work (changelog, 2026-08-28). A fourth failure is a finding, and three failures is acceptable **only** if they are the same three.

## Results log

Executed 2026-08-28, branch `attach-repository-files-as-notes` off `049d73f`. Final post-change state.

| Gate | Command | Scope | Result | Exception / risk |
| ---- | ------- | ----- | ------ | ---------------- |
| audit | `npm audit --audit-level=high` | WorkLists | **pass** (exit 0; 1 low + 1 moderate, both below threshold) | — |
| lint | `npm run lint` | WorkLists, whole tree | **pass** | The repo-wide gate now passes; the untracked staging trees were added to `.prettierignore` in the preceding snapshot commit |
| tests | `npm test` (`node --test tests/*.test.js`) | WorkLists, 137 suites | **781 tests: 778 pass / 3 fail** | The three pre-existing card-action/Gemma failures, unchanged and unrelated — see below |
| browser | `npm run test:browser` | notes-pane smoke, real Chromium | **14 pass / 0 fail** | — |

**Baseline comparison.** Before the branch: 708 tests, 705 pass / 3 fail. After: 781 tests, 778 pass / 3 fail. **73 tests added, zero new failures.** The three failures are byte-for-byte the same ones: `keeps all card actions in one menu definition`, `keeps AI note reveal targets across reload and missing server job results`, and `wires Ctrl+Shift+Backslash as a context-aware global voice shortcut`.

### Scenario outcomes

| Group | Result |
| --- | --- |
| **HP-1 … HP-12** | All covered. HP-9 (the red→green pair) and HP-11 are proven end-to-end in a real browser as well as at the API. |
| **NP-1 … NP-9** | All pass. NP-1's symlink-escape case ran for real — the host allows junction creation, so the decisive assertion executed rather than skipping. |
| **EC-1 … EC-8** | All pass. |
| **DS-1 … DS-5** | All pass. |
| **PN-1 … PN-8** | All pass. `tests/note-checklist-patch.test.js` was **not edited** and still passes. |

### Three existing tests were updated, and why

Each asserted a source shape that this change legitimately altered. None was weakened to fit — each still protects what it was protecting:

| Test | What changed, and what it still guards |
| --- | --- |
| `card-templates-settings.test.js` — "appends new tabs without disturbing the existing ones or their order" | A ninth tab exists. Still asserts the **whole ordered list**, so a tab inserted mid-list still fails. |
| `context-windows.test.js` — "labels compact note action icon buttons accessibly" | The delete control's label is now conditional. Now asserts **both branches**, so neither can lose its label. |
| `notes-collapse.test.js` — "offers Collapse-all/Expand-all inside the notes-pane dropdown" | The attach item joined `extraActions`. Now asserts the collapse actions are **spread into** it rather than being its only contents. |

### Two defects found by testing

Both were caught only by the end-to-end browser run, and both are written up in [the testing-implementation doc](./attach-repository-files-as-notes-testing-implementation.md), scenarios 11 and 12: the Files settings panel was registered but never mounted, and the document picker closed the notes pane it was opened from. Each is fixed and now has a test.
