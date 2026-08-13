# Agent Workflow Sync — Work Breakdown

Status: **draft — scope bounded to the single card given an id; seven bodies of work specified**
Last updated: 2026-08-12T00:00:00Z
Parent: [`001-agent-workflow-sync-decisions.md`](./001-agent-workflow-sync-decisions.md) · [`002-agent-workflow-sync-sequence.mmd`](./002-agent-workflow-sync-sequence.mmd)

## Governing constraint

**Additive only, for now** — see [`001`](./001-agent-workflow-sync-decisions.md) → *Governing constraint*. Existing functionality and every existing API touch point stay exactly as they are in this spec set. Every body of work below is scoped so that, with the new feature unused, the code path that runs today is the code path that still runs.

**Replacement is the eventual destination, not a rejected option.** Build the adjacent path, prove it in real use, then migrate onto it as a separate deliberate change. Two consequences applied here: **W1 no longer repoints existing DAL functions** (that becomes a later migration), and **W10 is deferred behind the `GET /data` migration** rather than gated on a spike.

## Reframe applied 2026-08-12 — the format is the contract

The checklist's shape is the contract, not a template. Any checklist following it is readable and writable; the agent reads the current rows and reasons about which its phase satisfied. **W3, W4, and W6 were rewritten on this basis.** What went away: per-item ids, template versions, positional addressing, deprecation records, the strict drift refusal, and the two new note properties. What arrived: a format spec, plural starter templates, row addressing by section and label as read, and the agent's judgement as the core duty.

## Purpose

Split the agent-workflow-sync effort into independently specifiable, independently shippable bodies of work. Each one gets its own ticket folder and its own spec, so no piece rides along inside another piece's scope.

The decision map (001) settles *what* and *why*. This document settles *what ships separately*.

## Proposed structure

One feature folder (this one) as the parent record. **One ticket folder per body of work**, matching the existing `docs/WorkLists/tickets/<slug>/` precedent (`duplicate-card-option`, `prompt-injection-note-refinement`) rather than stuffing everything into one slug with many stories.

## The bodies of work

| # | Slug | Layer | Governing decisions | Depends on | Ready to spec |
| --- | --- | --- | --- | --- | --- |
| W1 | `record-level-data-access` | DAL only | record-level access, added beside the existing reads | — | **Yes** |
| W2 | `single-card-read-and-id-handoff` | Server + UI | card id supplied (path A) or created from a template (path B) | W1, W3 | **Yes** |
| W3 | `card-templates-and-checklist-format` | DAL + data + settings UI | checklist format contract, Card Templates feature | — | **Yes** |
| W4 | `note-checklist-patch-and-concurrency` | Server + DAL | write safety (precondition + row patch) | W1, W3 | **Yes** |
| W5 | `card-workflow-section-fields` | Server + DAL | workflow values via optional keys on the existing card patch | W1 | **Yes** |
| W6 | `agent-workflow-writer` | dustin-thomason only | agent judgement, curl transport | W2, W4, W5 | **Yes** |
| W7 | `onedrive-per-record-file-spike` | Spike, no product code | per-record storage, measured | — | **Yes** |
| W8 | `normalize-existing-workflow-cards` | Content only | — | W3 | Optional; largely dissolved |
| W10 | `per-record-storage` | DAL + front-end | per-record storage | `GET /data` migration, W7 | **Deferred — do not spec yet** |

---

### W1 — `record-level-data-access`

**Scope.** `readSection` / `writeSection` / `getRecord` / `patchRecord` added **beside** `readDB` / `writeDB`. New exports, new code paths, no existing caller repointed.

**Out of scope.** Per-record files (W10 — deferred). Any API change. Any data-format change. **Repointing `updateTodo`, `writeNotes`, or `updateTaskStatus`** — that is the later migration; for now they keep their current implementations and keep rewriting every section.

**Files.** `dal.js` (additions only), `tests/api.test.js`.

**Why it still goes first.** The new endpoints in W2, W4, and W5 need a scoped path to sit on. It no longer fixes anything app-wide — that benefit is deferred by the constraint and recorded in `001`.

**Test obligation.** The existing suite is the regression proof: every endpoint must behave identically, because none of their code changed. New tests cover the new functions directly, plus an explicit assertion that `readDB` and `writeDB` are untouched in behavior.

**Acceptance seed.** A write through `writeSection` touches exactly the named section file and leaves the other 11 files' contents and mtimes unchanged. Every existing endpoint's request and response shape is identical, and no existing DAL function's implementation changed.

---

### W2 — `single-card-read-and-id-handoff`

**Scope.** `GET /todos/:id` over `getRecord`, returning one record with its `lastModified`, `404` on unknown id. A **Copy card id** entry in the existing card ellipsis menu. Plus the two documented entry paths: **A** you supply the id; **B** the agent creates the ticket from the designated Card Template and takes the new id from the response.

**Out of scope.** Any text search or ticket-id lookup — the card id is an input, not a search result (D1).

**Files.** `server.js`, `openapi.js`, `public/apiService.js`, `public/cardActions.js`, `tests/api.test.js`, `tests/openapi.test.js`, `tests/card-actions.test.js`.

**Acceptance seed.** Given a card id, one record comes back and nothing else. Given an unknown id, `404`. The menu action puts the id on the clipboard.

**Note.** Server and UI are kept in one body deliberately — the endpoint is unusable without a way to obtain the id, and the menu entry is pointless without the endpoint.

---

### W3 — `card-templates-and-checklist-format`

*(Folder kept as `workflow-checklist-template-registry`; scope renamed twice — see the spec's *Scope history*.)*

**Scope.** Two parts. **(1)** A documented checklist **format** plus a parser (`parseChecklist`, `findChecklistStep`, `isChecklistNote`). **(2)** A **Card Templates** feature: a `cardTemplates` DAL section where one template defines a whole ticket — its card body and an ordered list of notes — a new settings-dialog tab to author them, a setting naming which template the agent creates from, and `POST /api/cards/from-template` which creates the card and its notes and **returns the new card's id**.

**Out of scope.** Per-item ids, versions, deprecation records, positional addressing — all removed by the reframe. Any new note or card property. Making anything queryable across cards — out of scope.

**Files.** `dal.js`, `server.js`, `openapi.js`, `data/cardTemplates.example.json`, `public/apiService.js`, `public/todolist2.js` (one settings tab), new spec tests. **No change to `markdownRenderer.js`.**

**Why it still matters most.** The parser is what makes any checklist readable. The drift evidence — 17 → 35 items over six weeks, three heading generations — is now the argument *for* format-tolerance rather than for a rigid template.

**Acceptance seed.** The real 35-row note parses into seven sections with correct checked states; older-generation and hand-edited checklists parse too; a note with no sections-with-steps reports unrecognized. Creating from a template yields a card with the four progress sections plus every note the template defines, in order, and the response carries the new card's id. Two starter templates seeded. The seven existing settings tabs are unchanged.

---

### W4 — `note-checklist-patch-and-concurrency`

**Scope.** `PATCH /api/notes/:noteId` accepting `{ steps: [{ section, label, checked, details }], lastModified }`. Rows addressed by **section name and label as read in the same exchange**. Mandatory precondition returning `409` **with the current `lastModified`**; `200` returns the new one. Existing `PUT` untouched.

**Out of scope.** Template ids and version pinning — removed by the reframe. Fuzzy or normalized matching: matching is exact after trimming, made safe by the precondition rather than by tolerance.

**Files.** `dal.js`, `server.js`, `openapi.js`, `public/apiService.js`, `tests/api.test.js`, `tests/openapi.test.js`.

**Acceptance seed.** A batch of rows toggles in one request. A stale `lastModified` returns `409` and changes nothing. An unknown section or label fails loudly and applies none of the batch. A hand-edited or older-generation checklist is writable. Only a note with no checklist structure returns `422`.

---

### W5 — `card-workflow-section-fields`

**Scope.** The field-handler registry seam in `updateTodo`: a handler claims a key, transforms it, and **consumes** it so it is not spread onto the record. Handlers for `currentStep`, `waitingOn`, `nextUp`, `workAhead` writing into `todo.text` markdown. Normalizes the missing-section and bare-line variants. `status` continues through existing validation in the same body.

**Out of scope.** Promoting the four to real record properties — out of scope for this effort. Any new route — this extends `PATCH /todos/:id` per the API shape principle.

**Files.** `dal.js`, `openapi.js`, `tests/api.test.js`.

**Acceptance seed.** `PATCH /todos/:id { currentStep }` updates only that section and leaves the title, the `---` rule, and unwritten sections byte-identical. A card missing `Waiting On` gets it created in the right position. Unhandled keys keep existing pass-through behavior.

---

### W6 — `agent-workflow-writer`

**Scope.** No WorkLists code. **The agent's judgement is the core deliverable**: read the checklist's current rows, decide from the phase's actual outputs which rows are satisfied, mark only those, and name the ones left unmarked. Plus the `orchestrate` wiring — where the card id is captured and recorded, which sections a phase looks at, the pre-write guards, batching per phase, and `409` handling.

**Out of scope.** Any endpoint. Any MCP server. Adding or removing checklist rows — the agent changes state, never structure.

**Files.** `agents/rules/worklists-card-sync.md`, `agents/skills/orchestrate/SKILL.md`, `steps.csv`.

**Acceptance seed.** A phase completion produces the intended card and checklist state on a real ticket. A row the phase did not satisfy is left unmarked and named. **A different checklist shape works with no change to the agent.** A card with no checklist structure produces a clear stop. A `409` is surfaced, not retried into a clobber. A missing fact leaves a detail line blank rather than fabricated.

---

### W7 — `onedrive-per-record-file-spike`

**Scope.** Measure whether ~2,731 small files in the OneDrive-synced `data/` tree behave. Record sync latency, lock/`EBUSY` frequency against the existing 5-retry `atomicWrite`, and cross-machine behavior given the host-scoped files.

**Out of scope.** Any implementation. This produces a finding, not code.

**Deliverable.** A written result that says go / no-go for W10, with numbers.

**Why it is its own body.** It gates W10 and it is cheap. Running it early means W10 is either scheduled on evidence or dropped on evidence.

---

### W8 — `normalize-existing-workflow-cards` — largely dissolved by the reframe

**Mostly no longer needed.** This body of work existed because the old design refused any note that did not match a pinned template version, so the nine existing cards had to be normalized to become addressable. Under format-as-contract they are **already addressable** — all three heading generations parse, and hand-edited checklists are valid.

**What remains, optional:** bringing older cards onto the current step set so they carry the steps the user now uses. That is a content preference, not a technical requirement, and it can happen whenever a card is next worked on.

**Depends on** W3. **No longer blocks W6.**

---

### W9 — removed, out of scope

**Removed 2026-08-12.** This body of work made the workflow values queryable across cards. That was never asked for — the effort is bounded to the card the agent is given an id for. The job story behind it is retired to `stories/dnu/`, and the "two copies of one value" decision it produced is gone with it.

Nothing needs the workflow values to be filterable or sortable, so nothing needs them stored a second time outside `todo.text`.

---

### W10 — `per-record-storage` — deferred behind two predecessors

**Deferred, not blocked.** Per-record files need `GET /data` to stop reading the whole database first. That replacement is itself deferred until the adjacent scoped-read path has proven itself — *eventually, not immediately*. So the order is: prove record-level access (W1) in real use → migrate the board's read off `GET /data` → then reconsider storage.

**Do not spec it yet.** It has two predecessors and one open measurement (W7) in front of it. Kept in the list so the sequence and reasoning stay findable.

**Scope when it comes.** `data/todos/{id}.json`, an explicit ordering key replacing the `db.todos` array-index tiebreaker in `compareOriginalTodoOrder`, `GET /data` replaced by scoped board reads, `POST /data` removed, and the front end no longer loading the whole database per refresh.

---

## Suggested order

**Now:** W1 → W2 → W3 → (W4, W5 in either order) → W6. W7 can run at any point in parallel; it blocks nothing.

**Then:** W8 is optional content work whenever a card is next touched. Nothing else is queued.

**Eventually, as separate deliberate changes:** migrate existing DAL callers onto record access; migrate the board's read off `GET /data`; then reconsider per-record storage (W10). Each one waits on the adjacent path having earned trust in real use — that is what "eventually, not immediately" means in practice.

W1 through W6 is the complete working agent loop. Everything after it is either migration, a data-model upgrade, or a storage change.

## Open decisions

The consolidated, actionable list lives in [`007-open-decisions.md`](./007-open-decisions.md). Summary of the blocking ones:

| # | Decision | Blocks |
| --- | --- | --- |
| 1 | Write `currentStep` at phase start or completion | Nothing; improves accuracy |
| 2 | Notify the user on an agent stop | Nothing; closes two partial criteria |

Card-body templating is **settled**: a system-level setting names the workflow-card template, and the agent creates a new ticket's card by duplicating it — the duplicate response returns the new id, so on that path you supply nothing.

## Not yet inspected

- Nothing outstanding. The note-pane render path was the largest unsized item; both the reframe (no checklist re-render) and the scope correction (no new read surfaces) removed the need to size it.
- Whether a template-editing UI, if wanted, can reuse the existing `classificationPrompts` settings surface.
