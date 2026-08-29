# Implementation plan — WorkLists/attach-repository-files-as-notes

> **Phase 4 output.** Produced without the plan-mode stop, per the waiver in the original request. It governs every step of Phase 5 and is **frozen** once Phase 5 begins — later deviation goes in the why-log or the session log, never by editing this file.

| Field | Value |
| --- | --- |
| Spec | [attach-repository-files-as-notes-spec.md](./specs/attach-repository-files-as-notes-spec.md) |
| Decisions | [locked-decisions.md](./specs/attach-repository-files-as-notes-locked-decisions.md) — LD-001 … LD-022 |
| Test plan | [test-plan.md](./testing/attach-repository-files-as-notes-test-plan.md) — status `refined`, executed here |
| Repo | `C:\Users\dktho\OneDrive\SCRIPTS ALL SYSTEMS\To Do List\WorkLists` |
| Baseline | `06b78be` on `main` |

---

## Problem → Requirement → Solution

**Problem.** A Markdown document on disk cannot be shown or edited in a WorkLists card without pasting a copy that immediately diverges.

**Requirement.** A note's content can come from a file; that file is editable in place; the program is bounded to one declared folder.

**Solution.** A repository root with a single containment chokepoint, an optional `source` on the note record, and a loopback bind. Everything else reuses what exists.

---

## Step 0 — Clear the runway (blocking, and not mine to do)

**The working tree is dirty across exactly the files this ticket must edit.** At `06b78be` on `main`: 25 modified files, 2,544 insertions / 1,774 deletions uncommitted, including `dal.js`, `server.js`, `openapi.js`, and `public/todolist2.js` — plus four deleted `public/markdown*.js` files and an untracked `packages/`. That is the markdown-kit extraction and Dantalion integration work from 2026-08-27/28, not yet committed.

Implementing on top of it would produce one diff containing two unrelated changesets, on the default branch, with no way to revert this ticket's work independently. **This is the one step the agent must not take on its own** — committing or stashing someone's in-progress work is their call.

Required before Step 1, either:

- commit the existing work (its changelog entries are already written), then branch; or
- stash it, then branch; or
- explicitly accept the entanglement and say so, in which case it is recorded as a conflict in the session log.

Then: `git checkout -b attach-repository-files-as-notes` — per `git-commit-workflow`, branch first when on the default branch.

## Step 1 — Loopback bind (LD-002)

`server.js:3615` → `app.listen(port, "127.0.0.1", …)`.

First because it is the gate on everything after it, and because it is one line that is easy to lose in a larger diff later. **Test DS-1** asserts the LAN address refuses. Verify the app still loads at `http://localhost:3010` before moving on.

## Step 2 — `fileRepository.js`, containment first (spec §9)

New module. Write `resolveInRoot` and its tests **before** anything that reads a file.

1. Port the path rules from `Cairn/components/vault-writer/filesystem.js:38-66` — relative only, no `..`/`.`, no `\`, no `//`, no empty segment, no NUL, ≤ 4096 path, ≤ 255 segment.
2. Add `fs.realpath` containment on both root and target. **This is the step Cairn does not have** — a directory handle cannot be traversed upward, a Node path can. Porting the rules without it looks like parity and is a hole.
3. `FILE_FAILURE`, closed: `not-configured` · `invalid-path` · `outside-root` · `not-found` · `unreadable` · `too-large` · `conflict` · `write-failed`.
4. `listDocuments` with every exclusion and bound (LD-005, LD-013, LD-014, LD-018).
5. `readDocument` / `writeDocument` — relative paths only, each calling `resolveInRoot` itself, so no exported signature accepts an absolute path and there is nothing to bypass.

**Gate: NP-1 green, including the symlink-escape case, before Step 3.** Also EC-1, EC-2, EC-3, EC-8.

## Step 3 — Settings and the DAL section (spec §6, §10)

1. `dal.js`: add the `appSettings` section to `SECTIONS`, **and derive `TEMP_FILE_PATTERN` from `SECTIONS`** rather than extending the hand-written alternation (LD-015 / FDC-02). **Test DS-2** is red before this and green after.
2. `server.js`: `GET`/`PUT /api/settings/file-repository`, with validation — exists, is a directory, readable, does not contain or sit inside `DATA_DIR`. A refused save leaves the previous value intact.
3. `openapi.js`: document both routes.
4. `public/todolist2.js`: a ninth tab in `openModelSettingsDialog` (`:16828`) — path field, validate/save, status line.

**Tests:** HP-1, HP-2, HP-3, NP-2.

## Step 4 — Read-only attach (stories 01, 02)

1. `server.js` + `openapi.js`: `GET /api/files`, `GET /api/files/content`.
2. `server.js`: `POST /api/notes` accepts `source`; refuse any `kind` other than `repository-file` (NP-9); refuse a duplicate on the same card.
3. `public/fileAttachments.js`: browse, pick, attach (LD-020 — no typed paths).
4. `public/todolist2.js`: the ellipsis item via the existing `extraActions` seam (`:4700`), and the `source` branch in `renderNoteItemContent` (`:5152`), including the path display (LD-021) and the in-body `not-found` state.
5. `public/index.html`: one script tag.

**Tests:** HP-4…HP-8, NP-3, NP-6, EC-4, EC-6, EC-7, DS-3, DS-5.

**Do not proceed to Step 5 until this slice is green.** A read-only slice is provable and reversible; a write slice is neither.

## Step 5 — Edit and save (story 03)

1. `server.js` + `openapi.js`: `PUT /api/files/content` with the `expectedMtime` precondition → `409` + current mtime. Mirror `server.js:2896-2920`; re-read `tests/note-checklist-patch.test.js` first and follow its assertion shape.
2. `public/todolist2.js`: the `source` branch in `saveNoteInlineEditor` (`:6166`). Autosave inherited unchanged (LD-006). The note's own `text` is never written.
3. The fallback renderer's checkbox path (`persistRenderedMarkdownNoteCheckboxChange`, `:5210`) must route to the file too, or a checkbox toggle silently diverges from the document.
4. **Block the AI paths (LD-010)** — `undoAiNoteRefine`, the refine-job apply, the server-side Gemma job, and the checklist `PATCH` — each refused for a `source` note.

**Tests:** HP-9 (the red→green pair), HP-10, NP-4, NP-5, NP-7, EC-5, PN-7.

## Step 6 — Detach (story 04)

`public/todolist2.js`: relabel the existing per-note delete control for a `source` note and adjust its confirmation wording (LD-022). No new menu item. The handler already does the right thing — it removes the record and nothing else.

**Tests:** HP-11, HP-12, DS-4.

## Step 7 — Neighbours and the full sweep

Run PN-1…PN-8. `tests/note-checklist-patch.test.js` must pass **with no edits to it**; an edit there is itself a finding. Extend `tests/browser-notes-smoke.js` with the end-to-end attach → render → edit → save → detach path.

## Step 8 — Self-review, then ship

1. Self-review the diff against `docs/reviewers/pr-review-patterns.md` — **after the code, before the tests are shaped around it.**
2. Maintain `testing/…-testing-implementation.md` as you go, scenario-first: each situation stress-tested, why it matters, and any code change hung off the scenario that forced it. PR-comment content, never a source comment.
3. Fill `…-pr-draft.md`.
4. Changelog session log, then **audit → lint → tests**, then commit and push.

---

## Shipping-checklist obligations, named up front

| Heading | Commitment |
| --- | --- |
| **Tests run** | `npm audit --audit-level=high` → `npm run lint` → `npm test` → `npm run test:browser`, in that order, reported with exact command + scope + result, final post-change state only. Baseline is **705 passed / 3 failed**; a fourth failure is a finding, and three is acceptable only if they are the same three. |
| **Tests added/updated** | Three new suites (`file-repository`, `file-attachments`, `settings-file-repository`) plus browser-smoke extensions. Two red→green pairs: HP-9 (content-source indirection) and DS-2 (derived `TEMP_FILE_PATTERN`). |
| **Regression impact** | Not claimed as isolated. Shared infrastructure is touched — `dal.js` `SECTIONS`, the note record, the notes render and save paths. PN-1…PN-8 are the named neighbour checks; §16 of the spec is the surface list. |
| **API docs** | Five new routes in `openapi.js`, guarded by `tests/openapi.test.js`. Not optional and not deferrable. |
| **Tooling gates** | All four apply; none is out of scope. |
| **Conflicts / exceptions** | Step 0's resolution; FDC-02 pulled into scope with its reason; the card's `currentStep`/`nextUp` still unwritable; the card title still naming a rejected model. |

## Risks this plan carries

- **`public/todolist2.js` is 720 KB.** Four separate edit sites in one file. Mitigation: they are at known line numbers, each is a branch on one field, and the client half of the attach flow lives in a new file rather than being appended to this one.
- **FDC-04 and FDC-05 ship as accepted risk.** Autosave writes a real file; a rename breaks every reference at once. Both are tolerable only because the root is a git repo — that dependency is stated in the concerns doc, not assumed.
- **The three known test failures.** If they change shape during this work, that must be investigated rather than absorbed into the baseline.
