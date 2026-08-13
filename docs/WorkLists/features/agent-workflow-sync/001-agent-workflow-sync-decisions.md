# Agent Workflow Sync — Problem / Solution Decision Map

Status: **draft — scope bounded to the single card given an id; design decisions resolved; two small calls open**
Last updated: 2026-08-12T00:00:00Z
Project: WorkLists (`c:\Users\dktho\OneDrive\SCRIPTS ALL SYSTEMS\To Do List\WorkLists`)
Related: [`worklists-ai-refinement-integration.md`](../ai/worklists-ai-refinement-integration.md), [`orchestrate/SKILL.md`](../../../../agents/skills/orchestrate/SKILL.md)

## Reading guide — what the codes mean

This document numbers its decisions so other documents can cite a specific one. The codes are shorthand, not jargon you need to learn — here is the whole key:

| Code | In plain terms |
| --- | --- |
| **D0** | How the data layer reaches one record instead of loading everything |
| **D1** | How the agent knows which card to write to |
| **D2** | How the checklist note is found among a card's notes |
| **D3** | How a single checklist row is identified — **the crux** |
| **D4** | How a human edit and an agent write avoid destroying each other |
| **D5** | How the four workflow values on the card body get written |
| **D6** | How the checklist itself stays maintainable as you change it |
| **D7** | How the agent actually calls any of this |

Lettered options inside a decision (`R1`, `C3`, `E2`, `A0`…) are the candidates that were weighed. **Only the ones marked as the decision matter going forward**; the rest are kept as the reasoning record. Where a spec cites one, it says what it means in plain words too.

**If you only read one thing:** the *Governing constraint* section, then the decision line inside D3 — those two shape everything else.

## Purpose

Decide how an agent updates a WorkLists ticket card and its workflow checklist as it works, so the board stays a truthful record of progress without hand-maintenance.

This document is a **decision map, not a spec**. It lays out each distinct problem, the requirement that resolves it, the candidate solutions with their trade-offs, and a recommendation. It also names the architectural shifts, because several options are structural rather than additive.

---

## The central asymmetry (read this first)

The evidence below establishes one fact that drives every other decision:

> **The seven checklist sections are stable. The checklist items are not.**

- **Sections** are fixed at seven and map one-to-one onto the `orchestrate` skill's seven phases. Nine of nine checklist notes agree.
- **Items** grew **17 → 19 → 20 → 27 → 30 → 32 → 34 → 35** over six weeks — roughly one revision per week, with items also being reworded, renested, and promoted from flat to nested.

**The conclusion drawn from this changed. The measurement did not.**

The original conclusion was: *bind the agent to stable item identity, never to item text.* That led to ids, versions, and positional addressing — all since removed. The actual answer is simpler: **the agent reads the rows as they are right now, every time, and reasons about them.** Drift stops mattering when nothing is remembered between reads, and the `lastModified` precondition guarantees "right now" really is right now.

What the measurement still tells us, and what it no longer implies:

| Still true | No longer implied |
| --- | --- |
| Item wording, count, and nesting change roughly weekly | That the agent needs a stable identifier per item |
| A design that *remembers* item text will break | That matching on item text is unsafe — it is safe when the text was just read under a precondition |
| Sections are stable and match the phases one-to-one | That the seven-section shape is the only one that can work |

This also answers "the items would ultimately need to be maintained": maintain them freely. Nothing binds to them.

---

## Evidence base

Measured against live data on 2026-08-12. Population: the 9 cards using the `### Current Step` convention, and their notes.

| Measurement | Value | Consequence |
| --- | --- | --- |
| Total cards in `data/todos.json` | 2,731 (~925 KB serialized) | The only card read today is fetch-all; a single-card `GET` is needed regardless of how the card is identified |
| Section files read per DAL read | 12 (all of them, under a global lock) | No path to one record exists — addressed in **D0** |
| Section files rewritten per DAL write | 12 (all of them) | One checkbox rewrites every section file — the defect D0 fixes |
| Sections a card write legitimately needs | 3 — todos, columns, boards | `touchColumnAndBoardForTodo` stamps the column and its boards; D0 reduces 12 to 3, not to 1 |
| `atomicWrite` rename retries | 5, on `EBUSY` / `EPERM` / `ENOENT` | Sync or antivirus lock contention already happens; relevant to D0's per-record option |
| Whole-database reads by the UI | `GET /data` on board load **and** every 20s idle refresh | The ceiling on record-level storage; see D0's replacement table |
| Total notes in `data/event-notes.json` | 515 (~792 KB) | Same |
| Cards carrying a `PRDV-` id | 45 | Lookup population is small; the corpus it hides in is not |
| …of those, actual workflow cards | 9 | 36 are link stubs, release-tracking, discussion, or pre-convention cards — see **Resolved: what counts as a workflow card** |
| Cards using the `### Current Step` convention | 9 | The convention is young; changing it now is cheap |
| Checklist item count drift over 6 weeks | 17 → 35 boxes | Item text/position is not a stable address |
| Distinct heading layouts across 9 notes | 3 (`Objective/…`, `Next Steps + 6`, `Preliminary + 6`) | A strict reader fails on older cards |
| Cards missing `Waiting On`/`Next Up`/`Work Ahead` | 2 of 9 | Writer must tolerate absent sections |
| Cards where `Current Step` value is a bare line, not a `-` bullet | 1 of 9 (`todo-1785246474470`) | Writer must normalize, not assume |
| Notes per card | 1 to 3 | The checklist note must be identified, not assumed |
| Cards where title `PRDV-` id ≠ link `PRDV-` id | 1 of 9 (`todo-1786464124416`: title 16313, link 16312) | Any text-matching lookup is unsafe — resolved by D1 taking the card id as an input instead |
| `tag` field shape | string **or** array (`todo-1784209049062` = `["Investigation","Errors"]`) | Writers must preserve shape |
| `Current Step` distinct values observed | "In QA", "QA", "Testing", "Deploy to TST", "In Backlog", "Investigation", "Approval of implementation", free prose | Writable today; unreachable by every query surface except text search |
| Non-checkbox data slots in the template | `Approved by: name`, `start testing on date @ time`, `finished testing on date @ time` | Agent must fill values, not only toggle booleans |

Two of nine notes are not workflow checklists at all (a "Ticket Description" note and a bespoke "Action Items" note), which is what rules out "the checklist is the first note".

### The board is already a query surface — observation only, no longer a driver

> **Scope note added 2026-08-12.** This section was written to justify making the workflow values queryable, which turned out to be **outside this effort's scope**. The effort is bounded to the card the agent is given an id for; nothing needs to be filterable or sortable. The observation below is accurate and worth keeping as background about the app — it just no longer decides anything here. The job story it produced is retired to `stories/dnu/`.

This was originally written up as a question for the user — *is the board read, or queried?* That was wrong to ask: it is a fact the application answers.

| Query capability already built | Where | Dimensions |
| --- | --- | --- |
| Search scopes | `WorkLists/public/searchScopes.js:8` | Tags, Completion status, Card contents, Column titles |
| Column sort | `WorkLists/public/columnSort.js:20` | Date created, Completion date, Primary tag, Secondary tags — each with direction |
| Server-side filter | `dal.findTodos` | Secondary tags with `any`/`all` match modes |
| Status taxonomy | `data/statuses.json` | 8 records, each with color + explicit `order` |
| Conditional status visibility | `data/statusVisibility.json`, `getVisibleStatusesForTodo` | Which statuses appear per primary tag |
| Board scoping | `data/pinnedBoardIds.json`, boards + columns | Pinned boards, 2,731 cards across many columns |

Nobody builds `secondaryTagMode: "all" | "any"`, per-primary-tag status visibility rules, and four sort dimensions for a surface they read linearly. **The board is queried.**

The detail that mattered at the time: every progress dimension promoted to a field is filterable, sortable, and colored, while the four workflow sections are prose. That was read as a gap to close. **It is not one for this effort** — the agent reads and writes one card it was handed, and prose is entirely adequate for that. Whether those values should ever become fields is a separate question for a separate day.

**Scope note:** an earlier draft used this to resolve D3 and D5. D3 was later resolved differently (the checklist format is the contract), and D5's queryable half was removed as out of scope. What survives is D5's decision that the four workflow values are written by the server rather than by every caller.

---

## Problem → Requirement → Solution

Framed per [`problem-requirement-solution`](../../../../agents/rules/problem-requirement-solution.md).

**Problem.** Ticket progress lives in two places that only a human keeps in sync: the ClickUp ticket, and a WorkLists card whose body carries the current step and whose note carries a 35-item workflow checklist. When an agent does the work, the board goes stale immediately, so the board stops being usable for visibility or dashboarding — which is the only reason it exists.

**Requirement.** An agent completing a unit of ticket work must be able to (a) know which card it is working on and verify it, (b) locate that card's workflow checklist, (c) mark specific checklist items and fill their data slots, (d) set the card's current step and status, and (e) do all of it without destroying a concurrent human edit — and each of these must survive the checklist template being revised.

**Solution.** Determined by the seven decisions below.

---

## Governing constraint — additive only

Stated by the user on 2026-08-12, after the decisions below were drafted. **It overrides anything in this document that conflicts with it.**

> "please ensure that the current functionality and all existing touch points remain exactly as they are. We are not changing anything, and I believe we should not touch any of the current API points. We want to continue using the system as it is, even after this is implemented. This addition should be a secondary feature that is simply tacked on, rather than something that has any bearing on our current functionality."

### The rule this resolves to

There is a tension to name: the user also asked (message 6) that the workflow values ride on the existing `PATCH /todos/:id` rather than a purpose-named route. Both instructions hold under one distinction:

| Permitted — additive | Forbidden — altering |
| --- | --- |
| A new route on a new path (`GET /todos/:id`) | Changing an existing route's behavior for an input it already accepts |
| A new verb on an existing path, leaving existing verbs untouched (`PATCH` beside the notes `PUT`) | Removing or replacing an existing route |
| **New optional keys** on an existing endpoint, ignored when absent | Changing an existing key's meaning, validation, or response shape |
| New DAL functions beside the existing ones | Repointing existing DAL functions at a new path |
| New data sections and new record properties | Changing or relocating existing stored values |

**The test for every change in every spec below:** with the new feature unused, is the existing code path byte-for-byte the one that runs today? If not, it is out of scope.

### What this constraint defers

**Deferred, not abandoned.** The user's phrasing was *"we were going to eventually replace it — eventually, not immediately."* Replacement stays the destination; the constraint is about sequencing. Build the adjacent thing, prove it in real use, then migrate onto it deliberately.

An earlier draft of this section called these "losses" and marked the replacement work "void" and "blocked." That was wrong, and it mattered: *blocked* says the door is closed, while *deferred* says build alongside first. The whole reason the record-level interface exists is that migrating existing callers onto it later needs no caller change — so the design already assumes the migration happens.

1. **The app-wide write fix is postponed.** Section-scoped writes originally repointed `updateTodo`, `writeNotes`, and `updateTaskStatus`, so every mutation stopped rewriting 12 files. For now the existing functions stay untouched and only the new paths get scoped writes. **The migration is a later, separate change** — one call-site swap per function, no contract change, once the new path has been running long enough to trust.
2. **`GET /data`, `POST /data`, and `GET /todos` stay for now.** Nothing is replaced yet. Each remains a candidate for replacement once something better exists beside it and has proven itself — which is what makes per-record storage reachable later rather than never.
3. ~~Story 02 (dashboarding)~~ — **no longer applicable.** That story was retired as out of scope on 2026-08-12: the effort is bounded to the card the agent is given an id for, so no workflow value needs to be queryable and no mirror property is needed. The tension this item described does not exist.

**The constraint is the right call for a tool used daily.** Containment now, migration later, with the migration path designed in rather than hoped for.

---

## API shape principle (applies to every decision below)

**Patch the resource, not the representation. Actions get endpoints; field updates do not.**

The existing surface already shows what happens without this rule. `PATCH /todos/:id` accepts arbitrary fields — and then `/status`, `/column`, `/tag`, and `/secondary-tags` were each added alongside it, four endpoints doing what the generic one already did. Adding `/sections` and `/checklist` would extend a proliferation that should not have started, and would bake today's storage choice into the URL.

The distinction worth keeping:

| Shape | When | Existing examples |
| --- | --- | --- |
| **`PATCH /resource/:id`** with named keys | Setting or updating values on an existing thing | `PATCH /todos/:id`, `PUT /api/notes/:noteId` |
| **`POST /resource/:id/<action>`** | An operation with effects beyond the record — creates, reorders, cascades | `POST /todos/:id/move` (reorders a column), `POST /todos/:id/duplicate` (creates an entity + notes) |

`move` and `duplicate` earn their endpoints. `status` and `tag` did not.

**Why this matters more here than as a style preference.** The workflow sections and the checklist are markdown substrings today and become fields/records in stage 3. If the API is `PATCH /todos/:id { currentStep: "Investigation" }`, then **the request body is identical before and after that migration** — the caller never learns whether it wrote to a markdown section or a real record field. A `/sections` endpoint, by contrast, names the current storage in its URL and becomes a lie the moment the storage changes.

**Wording note:** throughout this document, "field" means a property on the card record (`todo.currentStep`). It never means a kanban column — those are `columns.json` and `columns.taskIds`, and nothing in this feature moves cards between them.

**Mechanism — a field-handler registry, not new routes.** `dal.updateTodo` already does per-key work before writing: it validates `secondaryTagIds` and `status`, then spreads the rest onto the record. Extensibility comes from adding keys to that seam, not endpoints to the server:

- A handler claims a key, transforms it (for now: markdown surgery on `text`), and **consumes** it so it is not spread onto the record as a stray property.
- Unhandled keys keep today's pass-through behavior, so nothing existing changes.
- Stage 3 swaps a handler's implementation from "write into `todo.text`" to "write `todo.currentStep`". No route change, no caller change, no API-docs change.

Adding a new workflow section later is then one registry entry, which is the extensibility being asked for.

---

## D0 — Record-level data access (foundational)

This decision was added after the others and **supersedes the workarounds they originally contained.** An earlier draft measured the whole-database read/write, accepted it as a constraint, and told the agent to batch around it. That was solving the wrong problem: the sweeping read/write *is* the defect, and it is a defect the whole app carries, not just the agent path.

**Problem.** There is no path to one record. Every read loads all 12 section files under a global lock (`dal.readDB`, `dal.js:494`). Every write rewrites all 12 atomically (`dal.writeDB`, `dal.js:578`) — `writeNotes` and `updateTodo` each do a read **and** a write. Toggling one checkbox rewrites `boards.json`, `columns.json`, `todos.json`, `statuses.json`, `models.json`, and everything else. The UI compounds it: `ApiService.fetchBoardData()` calls `GET /data`, pulling the entire database on board load and again on every 20-second idle refresh.

**Requirement.** Read one record without loading the database. Write one record without rewriting unrelated data. The interface must not change when the storage does.

| Option | How | Trade-offs |
| --- | --- | --- |
| **R1. Section-scoped read/write** | `readSection(name)` / `writeSection(name, data)` beside the existing whole-DB pair | 12 files → 1 on both sides, immediately, for every caller. No migration, no format change, no ordering risk. Cheapest real fix available. Still parses and re-serializes the full 925 KB section per card write |
| **R2. Record-level DAL interface** | `getRecord(section, id)` / `patchRecord(section, id, partial)` / `putRecord` | The interface described in this decision: go in, take one record, change it, put it back. Storage can stay section-files at first, so this is cheap. **Its real value is that R3 becomes invisible to callers** — same argument as the field-handler registry in the API shape principle |
| **R3. Per-record files** | `data/todos/{id}.json`, one file per card | True surgical access: read one small file, write one small file, no 925 KB parse, no cross-record lock contention. Requires a migration, an explicit ordering key, and `GET /data`'s replacement (see constraints below) |
| **R4. Embedded database (SQLite)** | Replace JSON files with a single DB file | Solves reads, writes, *and* the stage-3 query goal properly — indexes, real filtering, transactions. But: adds a native dependency, gives up human-readable and hand-editable data files, and a binary DB file inside OneDrive synced across machines risks lock contention and corruption. The host-scoped files (`todos-OfficeComputer1.json`) indicate multi-machine use, which is exactly the case that hurts. **Recorded and rejected** — but it is the honest answer if querying ever outgrows JSON |

**Decision: the record-level interface (R2) with section-scoped storage (R1), both added additively. Per-record files (R3) deferred behind the `GET /data` migration. An embedded database (R4) rejected, with reasons recorded.**

`readSection` / `writeSection` / `getRecord` / `patchRecord` are added **beside** `readDB` / `writeDB`, which keep their current implementations and current callers. Only the new endpoints use the new functions. Existing endpoints continue to read and rewrite every section exactly as they do today.

The win is narrower now than originally written — new paths avoid the amplification, existing paths keep it. **The point of the record-level interface is that it makes the later migration cheap:** moving `updateTodo` onto it is a one-line call-site change with no contract change, whenever the new path has earned that trust. See **What this constraint defers**.

R1 alone removes the sweeping write today, and it is small enough to land with the agent work rather than ahead of it.

**How many sections a write actually touches** — traced, because "one file instead of twelve" was too generous:

| Operation | Sections written | Why |
| --- | --- | --- |
| Note update (`writeNotes`) | **1** — `event-notes.json` | Touches only the notes it was handed |
| Card update (`updateTodo`) | **3** — `todos.json`, `columns.json`, `boards.json` | `touchColumnAndBoardForTodo` stamps `lastModified` on the card's column and on every board containing that column (`dal.js:1055`) |

So R1 takes card writes from 12 sections to 3, and note writes from 12 to 1. The timestamp cascade is deliberate existing behavior — the UI uses those `lastModified` values — so it stays. It is recorded here so the win is stated accurately rather than optimistically. R2 makes the eventual move to R3 a storage swap behind an unchanged interface. Taken together they are the same pattern used everywhere else in this document: **the caller's contract is the final one from the start; only what sits behind it changes.**

### Constraints on R3, found by tracing

1. **Card ordering is safe.** Board order lives in `columns.taskIds` (`updateTasksOrder` writes the column, not the todos array), so splitting cards into files does not disturb board layout.
2. **But array order is load-bearing for sorting.** `findTodos` builds `originalIndex` from the `db.todos` array position and uses it as the deterministic tiebreaker in `compareOriginalTodoOrder`. Directory read order is not a stable substitute, so R3 needs an explicit ordering key — `creationTimestamp` is the obvious candidate and already present on every card.
3. **`GET /data` must be replaced, not kept.** Under R3 it would read 2,731 files on every board load and every idle refresh. This is the endpoint the user's "new endpoints may replace the current ones" applies to most directly.
4. **OneDrive is a real variable, not a hypothetical.** `atomicWrite` already retries `EBUSY` / `EPERM` / `ENOENT` five times with a one-second delay — that retry loop exists because rename contention against sync or antivirus already happens. Note the direction of the effect is not obviously bad: per-record writes touch **one small file** instead of twelve large ones, which is *less* churn per operation. What is untested is the one-time file-count explosion and steady-state sync behavior across machines. Temp files are already written outside the synced tree (`os.tmpdir()`), which helps.

### Endpoints this replaces — eventually, not now

Every existing endpoint stays exactly as it is **in this spec set**. Replacement remains the intent; it happens later, once the adjacent path has proven itself.

| Existing | Now | Eventually |
| --- | --- | --- |
| `GET /data` | Untouched. Still reads the whole database on load and every 20s refresh | Replaced by scoped board reads, once something scoped exists and the board has been moved onto it |
| `POST /data` | Untouched | Removed — no caller should be able to overwrite the whole database in one request |
| `GET /todos` (all cards) | Untouched. `GET /todos/{id}` is added **beside** it | Superseded, once callers have moved to scoped reads |

**What this means for per-record storage.** It needs `GET /data` to stop reading everything, so it waits on that replacement rather than being impossible. **W10 is deferred behind the `GET /data` migration**, and the OneDrive spike (W7) is what tells us whether it is worth pursuing when the time comes. Order: prove the adjacent path → migrate the board's read → then reconsider storage.

---

## D1 — Knowing which card to write to

**Problem.** Originally framed as "the agent must search for the card." That framing was wrong, and it imported the hardest problems in the document: a text search over 2,731 cards, ambiguity handling, and the title-vs-link id mismatch.

**Reframed.** *Which card* is not a fact the agent should discover. It is the **starting point of the process**, known by the person kicking it off. The requirement is not search — it is capture, verification, and persistence.

**Requirement.** The card id is supplied once at the start of a run, recorded where a resumed run can find it, verified before the first write, and cheap to read without pulling the whole board.

| Option | How | Trade-offs |
| --- | --- | --- |
| **A0. Caller supplies the card id** | Handed over at kickoff; recorded in `original-ticket.md` Context Paths + the `orchestration.md` ledger | **Exact** — no matching, no ambiguity, no heuristic. Kills the title/link mismatch class outright rather than working around it. Recorded once per ticket and free on resume, since the ledger already persists run state. Cost: one manual hand-over per ticket, and it needs a way to obtain the id (see below) |
| **A1. Server-side text query** `GET /todos?q=PRDV-16313` | Filter `dal.findTodos` on `text` | ~30 LOC, no schema change. But it is string matching against 2,731 cards, so it inherits every ambiguity: 36 of 45 `PRDV-` cards are not workflow cards, and one card's title and link disagree. Solves a problem A0 does not have |
| **A2. Ticket index file** | Maintain `PRDV-id → todoId` on write | O(1) lookup. New derived state that drifts; needs rebuild and invalidation. Buys speed nothing needed |
| **A3. `ticketId` field on the card** | Parse on create/edit, store explicitly | No longer needed for resolution under A0. Still worth having in stage 3 for **dashboards** — grouping and filtering by ticket — but that is its own justification, not this one |
| **A4. Agent fetches all and filters** | No server change | 925 KB per lookup. Rejected |

**Decision: A0 — the card id is an input, not a search result.**

This is the right trade. Search was solving a problem created by not being told the answer, and it was solving it worse: matching on text can silently resolve to one of the 36 non-workflow cards, and a wrong resolution is a write to the wrong card. An id supplied by the person starting the work cannot be wrong in that way.

It also fits the existing machinery rather than adding to it. The `orchestrate` skill already captures a ClickUp link and implementation paths at Phase 0 and already persists run state in `orchestration.md` for resume. The card id becomes one more captured input alongside them — recorded once, available to every later phase and every resumed session.

**Two small things A0 still needs**, both far cheaper than the search endpoint it replaces:

1. **`GET /todos/:id`** — does not exist today. Only `GET /todos` (all 2,731, 925 KB) and `GET /data` (everything). Without it, "read the card" means pulling the whole board into agent context. Note what this does and does not save: the **response** shrinks to one record, but the DAL still loads all 12 section files to produce it (see **Write amplification** under D4). The win is payload and context, not disk. Notes are already scoped at the response level: `GET /api/notes?eventId=` filters server-side.
2. **A way to obtain the id from the UI.** The id is in the DOM as `dataset.taskId` (`WorkLists/public/cardActions.js:216`), but no card action surfaces it — Copy, Copy All, Move, Edit Notes, Delete, and Duplicate all exist and none yield the id. A **Copy card id** entry in the existing ellipsis menu makes the hand-over one click. Without it, A0's "one manual step" means digging through JSON, which is the kind of friction that gets a workflow abandoned.

**Verify before writing.** Once `GET /todos/:id` exists, the agent reads the card and confirms its title carries the expected ticket id before its first write. This is a guard against a stale or mistyped id — a copied card, a deleted card, a transposed digit — and it costs one read, not a search. If the check fails, stop and ask rather than write.

---

## D2 — Identifying the workflow checklist note

**Problem.** Notes have no type. A card can carry 1–3 notes, and prose notes ("Ticket Description", "Ai Sessions") sit alongside the checklist.

**Requirement.** Given a card id, return the one note that is the workflow checklist, or an explicit "none / more than one" answer. Never guess.

| Option | How | Trade-offs |
| --- | --- | --- |
| **B1. Heuristic detection** | Note has `- [ ]` boxes **and** ≥3 known section headings | No schema change, works on all 9 today. Ambiguous the first time a card has two checklist-shaped notes; the heuristic is duplicated in every consumer |
| **B2. `kind` field on the note record** | `kind: "workflow-checklist" \| "freeform"` | Unambiguous, queryable, and the note pane could badge it. Schema addition + backfill + `POST /api/notes` contract change. Invisible to a human reading the markdown |
| **B3. Marker line inside the note text** | `<!-- worklists:checklist v3 -->` as line 1 | No schema change, survives the existing `PUT` API untouched, renders invisibly, **and carries the template version** — which D6 needs anyway. Lives in user-editable text, so it can be deleted by accident |
| **B4. Convention: first note is the checklist** | Order by `createdAt` | Free. Already false in the live data. Rejected |

**Decision (revised): identify the checklist note by its structure.** A note is the checklist note if it contains a section heading with checkbox rows under it — nothing stored, nothing embedded. All four options below are superseded: B1's heuristic is now the *definition* rather than a guess, B3's marker line cannot exist (markdown escapes it into visible text), and B2's `kind` field is unnecessary since structure already answers the question. Where a card has more than one checklist-shaped note, the caller names which one — the note patch takes a `noteId` in its path anyway. See [W3 — checklist format](../../tickets/workflow-checklist-template-registry/specs/workflow-checklist-template-registry-spec.md) → *What makes a note a checklist note*.

---

## D3 — Addressing a checklist item (the crux)

> **Superseded 2026-08-12. The answer is the format, not an identifier.**
>
> Everything below treats this as a problem of giving each checklist item a permanent identifier. Two mechanisms were tried and both failed:
>
> 1. **Ids hidden in the note text** (C3, and the marker line in D2/B3) — unimplementable. `public/markdownRenderer.js:155` escapes all inline HTML, so an `<!--id:...-->` marker renders as literal visible text beside every item. Making the renderer strip comments would change existing rendering, which the additive-only constraint forbids.
> 2. **Ids on a template record, with items addressed by position within a pinned version** — implementable but wrong-shaped. It made one template the authority on checklist contents, which forecloses having different checklists for different kinds of work, and it treated a hand-edited note as a fault to refuse rather than as normal use.
>
> **The actual decision: the format is the contract, not the template.** Any checklist following the documented shape — headings, checkbox rows, nested detail lines — is readable and writable. The agent reads the current rows, reasons about whether each step was genuinely completed by the phase, and marks only what it can substantiate. Identity is resolved at read time by reasoning; nothing is stored, so nothing can go stale.
>
> **Why matching on row text is safe here, having rejected fuzzy matching earlier:** the caller sends back labels it read moments ago, together with the `lastModified` it read. If the note moved in between, the write is rejected before any matching happens. Text matching is unsafe when the text is remembered; it is safe when the text was just read and the read is verified.
>
> Full mechanism: [W3 — checklist format and starter templates](../../tickets/workflow-checklist-template-registry/specs/workflow-checklist-template-registry-spec.md). Write contract: [W4](../../tickets/note-checklist-patch-and-concurrency/specs/note-checklist-patch-and-concurrency-spec.md). The agent's judgement duty: [W6](../../tickets/agent-workflow-writer/specs/agent-workflow-writer-spec.md).
>
> The options table below is kept as the reasoning record. Read it knowing that C1–C6 all framed the question as "how do we address an item," and the resolution was to change the question.

**Problem.** Items drift weekly in wording, nesting, and count. The note is one markdown blob.

**Requirement.** "Mark *Run grill-me session* complete" must resolve to the same line before and after a template revision, or fail loudly.

| Option | How | Trade-offs |
| --- | --- | --- |
| **C1. Exact text match** | Match the literal string | Simplest. Demonstrably broken: `Generate Artifacts` vs `Generate Investigation Report to validate the Spec to be written` are the same intent across generations. Rejected on evidence |
| **C2. Normalized / fuzzy match** | Lowercase, strip punctuation, token-overlap threshold | No schema change, tolerant of the current drift, works today. **Failure mode is silent mis-match** — the near-identical pairs above are exactly what it confuses. **Rejected** — see the decision below; a standard is the answer, not tolerance for the lack of one |
| **C3. Stable ids embedded in markdown** | `- [ ] Run grill-me session <!--id:spec.grill-->` | Deterministic; survives rewording, renesting, and reordering; notes stay human-editable and human-readable; pairs naturally with the D6 template registry. Requires template regeneration and a backfill for existing cards; ids must be assigned once and never reused |
| **C4. Section + ordinal** | "3rd item under Development" | No schema change. Breaks on insertion, and the evidence shows insertion is the dominant drift mode. Rejected |
| **C5. Checklist as structured data** | `checklist: [{id, section, label, checked, slots}]` on the card or a new entity; markdown becomes a rendered projection | Best possible agent contract; makes per-item progress genuinely queryable (real dashboards, "which tickets are stuck in Project Spec"); removes parsing entirely. Largest lift: new entity, migration, and the note editor must be rebuilt or the checklist moved out of the note pane. Loses free-hand mid-checklist editing unless deliberately re-added |
| **C6. Let the model rewrite the note** | Send note text + intent, model returns new text | Already precedented by the Gemma refine path. Tolerant of anything. Non-deterministic, unauditable, and rewrites the whole blob — the worst option for clobber safety |

**Decision: C5 — structured checklist records. C3 is the migration step, not the destination. C2 is rejected outright.**

**C2 (fuzzy matching) was in an earlier draft of stage 1 and is now removed.** The reasoning that killed it: fuzzy matching exists *only* because no checklist standard exists. If the checklist is a first-class thing — and it is, it is the spine of the whole workflow — then the answer is to standardize it, not to pattern-match a nonstandard thing and hope. Its failure mode is silent: a near-miss checks the wrong box and reports success, and the drift evidence contains exactly the confusable pairs that would trigger it (`Generate Artifacts` vs `Generate Investigation Report to validate the Spec to be written`).

> **The paragraphs below are the reasoning record, superseded by the format-as-contract note at the top of this decision.** They correctly rejected fuzzy matching and correctly moved the checklist standard earlier — but they reached for stable ids as the mechanism, and that is what changed. The rejection of fuzzy matching still stands; what replaced it is exact matching on rows just read, made safe by the precondition.

So the template registry (D6) and stable ids (C3) move **into stage 1**, and there is no fuzzy fallback at any stage. The consequences are deliberate:

- **Cards created from the template carry ids from birth.** New tickets are agent-ready immediately.
- **A card without ids is explicitly not agent-ready.** The agent says so and stops, rather than guessing. That is the correct behavior for a card whose checklist predates the standard.
- **Old cards are normalized on first touch** (or in one pass — the remaining open call), which is what makes them addressable.
- **No throwaway work.** C2 was the only piece of the plan that was going to be built and then deleted.

Resolved by the query-surface evidence above, not by preference. Under C3 the checklist stays markdown, so "which tickets are stalled in Testing & Validation" means parsing 35 lines per card at read time — the same dead end `Current Step` is already in. The board's whole existing design says progress state belongs in fields.

C3 is still worth doing, as the **migration mechanism**: assigning stable ids inside the markdown is how existing notes become machine-addressable, which is how they get converted without hand-retyping. Sequence it as ids first, then lift the id-bearing markdown into records.

Two consequences to accept deliberately:

- **The markdown becomes a projection.** The note pane renders from records rather than storing them. Free-hand mid-checklist editing has to be re-added on purpose (an "add ad-hoc item" affordance), or it is lost — see Open questions.
- **The bespoke notes stay markdown.** "Ticket Description" and "Action Items" notes are not workflow checklists and should not be forced into the schema. Only the workflow checklist becomes structured.

The id remains the contract either way, which is what settles the maintenance question: wording is free to change, and `orchestrate` phase steps map to ids directly (`P3.grill` → `spec.grill`).

---

## D4 — Write safety

**Problem.** `PUT /api/notes/:noteId` replaces the entire note body, takes no precondition, and the board background-refreshes on a 20-second idle timer. An agent write during an open editor session silently wins or loses depending on order.

**Requirement.** A concurrent human edit and agent write must never silently discard either one.

| Option | How | Trade-offs |
| --- | --- | --- |
| **D4a. `lastModified` precondition** | Client sends the `lastModified` it read; server 409s on mismatch **and returns the current value**; every successful write returns the new one | Standard optimistic concurrency, ~15 LOC, correct. Makes the agent handle a retry — the right place for that burden. Returning the fresh `lastModified` on both the 200 and the 409 lets the agent chain writes or retry without a separate read |
| **D4b. Granular item update on the note resource** | `PATCH /api/notes/:noteId { items: [{ id, checked, slot }] }` — not a `/checklist` sub-route, per the API shape principle | Keeps the markdown surgery in one server-owned place and lets the agent send a whole phase's items in **one** request. Same body works in stage 3 when items are records instead of lines. Shrinks the agent's read-modify-write round trip; see the write-amplification note below for what it does *not* shrink |
| **D4c. Field-level merge / CRDT** | Structural merge of note bodies | Eliminates collisions. Wildly disproportionate for a single-user local app |
| **D4d. Editor lease / lock** | UI claims the note while open | Prevents the collision at the source. Needs presence tracking and a stale-lock story; new failure mode where a crashed tab holds a lock |

**Decision: D4a + D4b together.** They are complementary — D4b makes collisions rare, D4a makes the rare case safe. Neither is optional: D4b alone still clobbers, and D4a alone forces the agent to resend a 3 KB blob on every checkbox.

Note that D4b adds a `PATCH` verb to the notes resource, which today only has `PUT` (full replace). That is the correct split: `PUT` replaces the representation, `PATCH` updates named parts of it. Existing `PUT` callers are untouched.

### Write amplification — fixed by D0, not worked around

The whole-database read/write behind these endpoints is measured and addressed in **D0**. It is recorded here only because this is where it was found, and because an earlier draft of this section got the response wrong.

**What that draft said, and why it was wrong.** It accepted the twelve-file rewrite as fixed, told the agent to batch its calls to avoid triggering it repeatedly, and filed per-section writes as an out-of-scope future optimization. That inverted the problem. The sweeping write is a defect in the data layer that affects every mutation in the app — the agent path merely made it visible. Designing the agent to tiptoe around it would have left the defect in place and added a constraint to every future caller.

**What survives from it:**

- **Batching by phase is still right**, now for an ordinary reason: one round trip instead of thirty-five. D4b's `items` array carries a whole phase's updates. It is no longer load-bearing against a storage defect.
- **Card status rides in the `PATCH /todos/:id` body** rather than a separate `/status` call — one request instead of two, and `updateTodo` already validates `status`.
- **D4b's benefit is correctness and ownership, not write size.** The earlier claim that it "shrinks the write window to near zero" was false at the storage layer. What it shrinks is the *agent's* read-modify-write round trip, which is where collision risk actually lives.

---

## D5 — Writing the card's workflow sections

**Problem.** `Current Step`, `Waiting On`, `Next Up`, `Work Ahead` exist nowhere in the codebase — they are a markdown convention in `todo.text`, and 2 of 9 cards have only the first one.

**Requirement.** Set any of the four sections without disturbing the title, the `---` rule, or the sections not being written; create a missing section in the right position.

| Option | How | Trade-offs |
| --- | --- | --- |
| **E1. Agent does the markdown surgery** | Agent reads `text`, rewrites, `PATCH /todos/:id { text }` | Zero server change, available today. The format convention gets re-encoded in every prompt and every agent; the structural variance must be handled by each one. Guaranteed to drift |
| **E2. Server-owned section keys on the existing PATCH** | `PATCH /todos/:id { currentStep, waitingOn, nextUp, workAhead }`, handled by the field-handler registry | One owner for the format; normalizes the bare-line and missing-section cases centrally; testable; **no new endpoint**. The request body is already the stage-3 body, so the caller never changes. Still markdown underneath, so still unqueryable until stage 3 |
| **E3. Promote the four to real card fields** | `currentStep`, `waitingOn`, `nextUp`, `workAhead` on the todo record, rendered into the card view | This is what actually unlocks the dashboard: filter the board by "Waiting On is non-empty", group by current step, surface stalled cards. Requires card-render work, an editing UI, backfill of the 9 cards, and a decision on whether the markdown body remains the source of truth during transition |

**Decision: E3 — the four sections become card fields. E2 is the same API, backed by markdown until then.**

Same evidence, same reasoning as D3. These four sections are the only progress state on a card that no filter, sort, or grouping can reach, and they are the state most worth reaching: "what is waiting on someone else" and "what is stalled" are the questions a board of 2,731 cards exists to answer.

E2 is not a transitional *interface* — it is the **final** interface with a transitional implementation. `PATCH /todos/:id { currentStep }` is the call in stage 1 and the call in stage 3; only the handler behind it changes, from markdown surgery on `todo.text` to setting `todo.currentStep` directly. That is the whole point of the field-handler registry: the migration is invisible above the DAL. E1 is what has to be thrown away, because surgery written into agent prompts cannot be swapped out centrally.

E3 and C5 are the same architectural move on two surfaces. Take them in one pass — a card whose checklist is queryable but whose current step is not, or the reverse, only answers half of any dashboard question.

**`currentStep` needs two parts, not one.** The observed values split cleanly into state ("In QA", "Testing", "In Backlog") and detail ("Investigating the necessity of alerts from AWS"). A single free-text field cannot be grouped; a single enum would throw away the detail that is clearly deliberate. So: a controlled `currentStep` (queryable, colorable, groupable — mirroring how `statuses` is already modeled) plus a free-text `currentStepDetail` beside it. `waitingOn`, `nextUp`, and `workAhead` stay free text, since their query value is "empty or not" rather than which value.

---

## D6 — Maintaining the checklist template

**Problem.** There is no template. Each card's checklist was pasted and then hand-edited, which is why there are three generations and eight distinct item sets.

**Requirement (revised by the format-as-contract reframe).** A defined **format** that makes any conforming checklist readable, plus a way to start a new checklist from a saved one so steps are not retyped. Accommodating more than one checklist is part of the requirement, not a nice-to-have — different kinds of work need different steps. Note what is *not* required any more: a single source of truth for item identity, since nothing stores an item reference between reads.

| Option | How | Trade-offs |
| --- | --- | --- |
| **F1. Template file in WorkLists** | `templates/ticket-checklist.md`, versioned | Simple, diffable in git, easy to hand-edit. Not editable in the app; needs a loader; version bumps are manual |
| **F2. Template in dustin-thomason** | Beside the `orchestrate` skill, since the phases originate there | Keeps workflow authority in one repo and the phase→section mapping adjacent to its owner. Makes WorkLists depend on a sibling repo path — fragile across machines |
| **F3. Template as a WorkLists data record** | `data/cardTemplates.json`, edited in-app | Matches the **existing precedent** of `data/classificationPrompts.json` and `data/models.json` — same read/write/normalize machinery, same UI patterns. Editable where you work. Adds a section to the DAL. **This is the chosen option, and it grew:** a template now defines a whole ticket — card body plus ordered notes — authored in a new **Card Templates** settings tab. See [W3](../../tickets/workflow-checklist-template-registry/specs/workflow-checklist-template-registry-spec.md) → *Part 2* |

**Recommendation: F3.** The precedent is already in the repo and the DAL already has the section-file plumbing for it. Two rules the template must carry regardless of option: **ids are assigned once and never reused**, and **a removed item is marked deprecated rather than deleted**, so old cards remain interpretable.

---

## D7 — How the agent actually calls this

**Requirement.** A subagent mid-implementation can update a card in one or two calls, without a bespoke harness.

| Option | How | Trade-offs |
| --- | --- | --- |
| **G1. curl against `localhost:3010` + a skill doc** | Documented recipes | Works today, no build, no config, harness-agnostic. Verbose at the call site; the recipes are prose that can drift from the API |
| **G2. Small CLI** | `node worklists.js check --ticket PRDV-16313 --item spec.grill` | Clean call sites, scriptable, testable. One more surface to maintain and version |
| **G3. MCP server** | Tools exposed to the agent directly | Best ergonomics and self-discovery; the agent sees typed tools instead of reading a doc. Most build cost, per-harness config, and the server must be running |

**Recommendation: G1 now, G3 if the loop proves out.** The `/openapi.json` document already exists, which makes G1 far less prose-dependent than it sounds — the agent can read the real contract. Revisit G3 only after the endpoints have settled, because an MCP server built on an unstable contract is churn.

---

## Architectural shifts named

Ordered by how much they change, and what each one unlocks.

| Shift | From → To | Unlocks | Cost |
| --- | --- | --- | --- |
| **0. Data access granularity** | Whole-database read + whole-database rewrite → section-scoped, then record-scoped | Every mutation in the app stops rewriting unrelated data; makes record-level storage possible later without touching callers | R1+R2 small and immediate; R3 needs a migration, an ordering key, and `GET /data`'s replacement |
| 1. Card identity *(optional)* | Ticket id buried in markdown → `ticketId` field | Grouping and filtering by ticket on dashboards. **No longer needed for resolution** — D1 takes the card id as an input | Backfill 9 workflow cards; UI decision on derived vs editable |
| 2. Note role | Untyped notes → note `kind` (or version marker) | Unambiguous checklist location; per-kind UI treatment | Backfill; `POST /api/notes` contract change |
| 3. Checklist addressability | Prose lines → **a defined format plus a parser** | Any conforming checklist is readable and writable; revising steps breaks nothing; different checklists for different work | A parser and a format spec. **No migration, no ids, no versions, no note-pane change** — the reframe removed all of it |
| 4. Workflow sections | Markdown prose → card fields | **Real dashboards**: filter/group/sort by step, waiting-on, stalled | Card render + edit UI; backfill |
| 5. Write contract | Last-writer-wins → optimistic concurrency | Safe concurrent human + agent editing | Small; `409` handling in clients |

Shift 0 is **foundational** — it sits under everything else and benefits the whole app rather than only the agent path. Shifts 3 and 4 are **the decided direction**, not options; they are the same move on two surfaces and land together. Shifts 1, 2, and 5 are small and independent.

**Why this is the larger lift you sensed.** Two separate data-model changes stack here:

- **Shift 0** moves *how* data is reached — from "load and rewrite everything" to "take one record, change it, put it back." Its end state (R3) requires replacing `GET /data`, which means the board UI stops loading the whole database on every refresh.
- **Shifts 3 and 4** move *where the workflow state lives* — out of `todo.text` and `note.text` markdown and into fields and records.

Neither alternative was ever cheaper. Shift 0's alternative was leaving a defect that makes every mutation rewrite unrelated data. Shifts 3 and 4's alternative was keeping progress state somewhere no query can reach — the problem this whole document exists to solve.

They also reinforce each other: record-level access (0) and record-level checklist items (3) are the same idea at two depths, and both become far more valuable once the state is queryable rather than parsed out of prose.

---

## Phasing

Four stages toward a decided destination (record-level access, structured checklist, section fields). Each stage is independently useful, and none of it is thrown away by the next.

**Stage 0 — stop the sweeping read and write.** *(new — comes first)*
`R1` `readSection` / `writeSection` beside the existing whole-DB pair · `R2` `getRecord` / `patchRecord` record-level DAL interface · repoint `updateTodo`, `writeNotes`, and `updateTaskStatus` at the section-scoped path.

No API change, no migration, no data-format change — this is entirely inside the DAL, exactly as the 2026-05-14 section-split spec was ("fully encapsulated inside the DAL — no frontend modifications required"). A card update rewrites 3 sections instead of 12 and a note update rewrites 1 instead of 12 — for every existing caller, not just the agent. See D0's table for why a card write is 3 and not 1.

It comes first because it is small, it benefits the whole app immediately, and it means the agent work never has to be designed around a defect.

**Stage 1 — the checklist gets a standard, and the agent loop works deterministically.**
Card id supplied at kickoff · `GET /todos/:id` over `getRecord` · **Copy card id** menu action · the checklist **format spec and parser**, plus starter templates · the mandatory `lastModified` precondition and the row-level `PATCH` on the notes resource · workflow-value keys via the field-handler registry on the existing `PATCH /todos/:id` · curl recipes against the live OpenAPI document.

**New routes added: one** — `GET /todos/:id`. Everything else extends an endpoint that already exists. Fields added: 0. Migrations: 0. UI added: one menu entry.

The template registry moved here from a later stage, and the fuzzy match is gone. There is now **no throwaway work in the plan** — every piece is the final form of itself, with only its backing storage changing later. A card created from the template is agent-ready immediately; a card without ids is explicitly out of scope until normalized, and the agent reports that rather than guessing.

**Stage 2 — bring the existing cards in.**
Normalize the 9 existing workflow cards to the current template generation, one pass or on first touch (the remaining open call) · deprecation handling for retired template items so old cards stay interpretable.
Split from stage 1 deliberately: the standard and the loop can be proven on new tickets before touching a card with real history on it.

**Stage 3 — the state moves into fields.**
`C5` structured checklist records · `E3` `currentStep` (+ detail) / `waitingOn` / `nextUp` / `workAhead` fields · `B2` note `kind` · `A3` `ticketId` (optional, for dashboard grouping only), plus note-pane render-from-records and the card edit UI.
This is the dashboard. It is also the only stage with real UI work in it, which is why it is worth doing after the agent loop has shaped what the fields actually need to hold.

**Stage 4 — record-level storage.** *(the destination, gated)*
`R3` per-record files · explicit ordering key replacing the `db.todos` array-index tiebreaker · `GET /data` replaced by scoped board reads · `POST /data` removed.

Gated on two things, neither of which needs answering yet: whether per-record files behave under OneDrive sync across machines, and the front-end work to stop loading the whole database on every refresh. Stage 0's `getRecord` / `patchRecord` interface means this stage changes storage without changing a single caller above the DAL.

**Sequencing rationale.** Stage 0 comes first because it is cheap, it fixes a defect rather than accommodating one, and it keeps the agent work honest. Stage 1 now carries the checklist standard rather than deferring it, so nothing in the plan gets built to be deleted. Stage 3 still trails the loop deliberately: a few weeks of stage-1 writes will show which items the agent actually touches, whether it ever needs to uncheck, and what the data slots really contain — all inputs to the record shape. Stage 4 is last because it is the only stage with an unanswered environmental question in front of it.

---

## Where the agent hooks in

The seven sections map one-to-one onto the `orchestrate` phases, which is what makes this tractable — the agent never has to infer which section it is in.

| Checklist section | `orchestrate` phase | Trigger for the write |
| --- | --- | --- |
| Preliminary | 0 Capture | Ticket folder + job stories created |
| Investigation | 1 Recon and plan, 2 Report | Report, coverage ledger, diagrams emitted |
| Project Spec | 3 Probe & spec | Locked decisions, spec written, spec submitted |
| Development | 4 Prep, 5 Implement | Branch created; implementation complete |
| Testing & Validation | 5 Implement | Test plan executed; data slots filled with real timestamps |
| Deploy & PR | 5 Implement | Audit/lint/tests, push, PR opened |
| Ticket Closeout | 6 Wrap up | ClickUp updated, status set |

The phase transitions in `orchestration.md` already know exactly what completed. No new judgment is required of the agent — only a writer. The data slots (`start testing on date @ time`, `Approved by: name`) are filled from facts the phase already recorded.

---

## Decisions needed from you

One remains. D3, D5, the `Current Step` vocabulary question, and the scope question were all resolved from the application's own data and design.

1. **Backfill timing.** Normalize the 9 existing workflow cards to the current template generation in one pass, or on first touch? The reader is tolerant either way, so this is a cost/preference call rather than a design one: one pass makes all 9 addressable immediately; on-first-touch nets out the same within a few weeks with no migration, at the price of a card being silently un-agentable until touched. Recommending **one pass**, because 9 cards is not a migration and "silently un-agentable" is the failure mode this whole document exists to avoid.

### Resolved: what counts as a workflow card

Originally asked as "does this apply to all 45 `PRDV-` cards or only the active sprints." The data answers it: **45 is the wrong denominator.** Of the 45 cards mentioning a `PRDV-` id, most are not ticket cards at all — bare `ClickUp` link cards (5 in Sprint 18 alone), release-tracking cards in `Meta` (`Release …|Initiate client email - PRDV-9914|`), discussion cards (`Need to meet up with Larry…`, `Ask about the following ticket`, `Get evidence for Outbox ticket`), and older-format ticket cards predating the convention (`PRDV-14699 - Sort files in ASC alphabetical order`).

So a workflow card is identified by its **structure**, not by containing a ticket id: an H1 title, a `---` rule, and a `### Current Step` section. That is 9 cards today, all in Sprint 14/15/16 and Upcoming Work, and going forward it is exactly what the template registry creates. `ticketId` backfill follows the same rule — it is not applied to the 36 cards that merely mention a ticket.

## Open questions

Design questions the code cannot answer, deferred to stage 2 rather than blocking stage 1.

- **Should the agent be permitted to *uncheck* an item?** Unchecking is how a failed verification gets recorded honestly, but it is also how an agent could silently erase real progress. Leaning toward: allowed, but only with a reason recorded, and never as a side effect of a re-run.
- **How does a write conflict surface?** `D4a` returns a 409; the question is what the agent does with it and whether you ever see it. A conflict that is silently retried is indistinguishable from a clobber. Leaning toward: retry once on fresh state, then surface it rather than resolve it.
- **Does an ad-hoc item survive C5?** Under structured records, a hand-typed mid-checklist item needs an explicit affordance or it is lost. The `Action Items` note on `todo-1782923499636` shows you do write bespoke checklists — so the answer is likely yes, as unowned items with generated ids.
- **Does the agent write `completed` / `status` too, or only the workflow sections?** Setting card `status` from a phase transition is easy and validated server-side, but it overlaps with your own judgment about when something is really In Review.

## Not yet inspected

- The note-pane editor code path (`public/todolist2.js` note rendering) — how much of stage 3 is UI rework has not been measured. This is the largest unsized item in the plan and should be measured before stage 3 is scheduled.
- **How the mirror-property drift risk is handled** (new, from the additive-only constraint). If `todo.currentStep` mirrors a value that also lives in `todo.text` markdown, a hand edit to the markdown makes the two disagree. Options not yet weighed: derive the property on every write and accept staleness after manual edits; re-derive on read; or treat the property as authoritative and the markdown as generated. The third is the cleanest and the closest to what the constraint forbids, so this needs a decision before W9.
- **Whether per-record files survive OneDrive sync across machines** — was the gate on stage 4. The host-scoped files (`data/todos-OfficeComputer1.json`, `data/boards-PDLP-D362HS3.json`) imply multi-machine use, and `atomicWrite`'s existing 5-retry `EBUSY` loop proves lock contention is already real. Measurable cheaply: write 2,731 small files into a synced folder and observe. Do this before scheduling stage 4, not during it.
- The `POST /api/gemma-normalize` note-refine path as a possible existing vehicle for note writes (D3/C6) rather than a new endpoint.
