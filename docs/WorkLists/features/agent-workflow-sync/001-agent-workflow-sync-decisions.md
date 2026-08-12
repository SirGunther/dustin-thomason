# Agent Workflow Sync — Problem / Solution Decision Map

Status: **draft — decisions open**
Last updated: 2026-08-12T00:00:00Z
Project: WorkLists (`c:\Users\dktho\OneDrive\SCRIPTS ALL SYSTEMS\To Do List\WorkLists`)
Related: [`worklists-ai-refinement-integration.md`](../ai/worklists-ai-refinement-integration.md), [`orchestrate/SKILL.md`](../../../../agents/skills/orchestrate/SKILL.md)

## Purpose

Decide how an agent updates a WorkLists ticket card and its workflow checklist as it works, so the board stays a truthful record of progress without hand-maintenance.

This document is a **decision map, not a spec**. It lays out each distinct problem, the requirement that resolves it, the candidate solutions with their trade-offs, and a recommendation. It also names the architectural shifts, because several options are structural rather than additive.

---

## The central asymmetry (read this first)

The evidence below establishes one fact that drives every other decision:

> **The seven checklist sections are stable. The checklist items are not.**

- **Sections** are fixed at seven and map one-to-one onto the `orchestrate` skill's seven phases. Nine of nine checklist notes agree.
- **Items** grew **17 → 19 → 20 → 27 → 30 → 32 → 34 → 35** over six weeks — roughly one revision per week, with items also being reworded, renested, and promoted from flat to nested.

**Therefore: bind the agent to sections plus stable item identity — never to item text and never to item position.** Any design that matches on item wording will break about weekly, and its failure mode is silent (it checks the wrong box, or nothing, and reports success either way).

This is also the answer to "the items would ultimately need to be maintained": maintenance is fine and expected, but it has to happen in **one** place that both card creation and the agent read from, rather than being re-typed per card.

---

## Evidence base

Measured against live data on 2026-08-12. Population: the 9 cards using the `### Current Step` convention, and their notes.

| Measurement | Value | Consequence |
| --- | --- | --- |
| Total cards in `data/todos.json` | 2,731 (~925 KB serialized) | Fetch-all lookup is untenable in an agent loop |
| Total notes in `data/event-notes.json` | 515 (~792 KB) | Same |
| Cards carrying a `PRDV-` id | 45 | Lookup population is small; the corpus it hides in is not |
| Cards using the `### Current Step` convention | 9 | The convention is young; changing it now is cheap |
| Checklist item count drift over 6 weeks | 17 → 35 boxes | Item text/position is not a stable address |
| Distinct heading layouts across 9 notes | 3 (`Objective/…`, `Next Steps + 6`, `Preliminary + 6`) | A strict reader fails on older cards |
| Cards missing `Waiting On`/`Next Up`/`Work Ahead` | 2 of 9 | Writer must tolerate absent sections |
| Cards where `Current Step` value is a bare line, not a `-` bullet | 1 of 9 (`todo-1785246474470`) | Writer must normalize, not assume |
| Notes per card | 1 to 3 | The checklist note must be identified, not assumed |
| Cards where title `PRDV-` id ≠ link `PRDV-` id | 1 of 9 (`todo-1786464124416`: title 16313, link 16312) | Resolution must not key on the URL |
| `tag` field shape | string **or** array (`todo-1784209049062` = `["Investigation","Errors"]`) | Writers must preserve shape |
| `Current Step` distinct values observed | "In QA", "QA", "Testing", "Deploy to TST", "In Backlog", "Investigation", "Approval of implementation", free prose | Writable field; **not** a readable state machine |
| Non-checkbox data slots in the template | `Approved by: name`, `start testing on date @ time`, `finished testing on date @ time` | Agent must fill values, not only toggle booleans |

Two of nine notes are not workflow checklists at all (a "Ticket Description" note and a bespoke "Action Items" note), which is what rules out "the checklist is the first note".

---

## Problem → Requirement → Solution

Framed per [`problem-requirement-solution`](../../../../agents/rules/problem-requirement-solution.md).

**Problem.** Ticket progress lives in two places that only a human keeps in sync: the ClickUp ticket, and a WorkLists card whose body carries the current step and whose note carries a 35-item workflow checklist. When an agent does the work, the board goes stale immediately, so the board stops being usable for visibility or dashboarding — which is the only reason it exists.

**Requirement.** An agent completing a unit of ticket work must be able to (a) resolve the right card from a ticket id, (b) locate that card's workflow checklist, (c) mark specific checklist items and fill their data slots, (d) set the card's current step and status, and (e) do all of it without destroying a concurrent human edit — and each of these must survive the checklist template being revised.

**Solution.** Determined by the seven decisions below.

---

## D1 — Resolving a ticket id to a card

**Problem.** There is no lookup. `GET /todos` returns all 2,731 cards. The only ticket identity is text inside `todo.text`, and on one card the title id and the link id disagree.

**Requirement.** Given `PRDV-16313`, return exactly one card id, or an explicit ambiguity error — in a payload small enough to sit in an agent's context repeatedly.

| Option | How | Trade-offs |
| --- | --- | --- |
| **A1. Server-side text query** `GET /todos?q=PRDV-16313` | Filter in `dal.findTodos` on `text` | ~30 LOC, reuses existing read path, no schema change, no migration. O(n) per call but n=2,731 is trivial server-side. Still string matching — inherits the title-vs-link ambiguity unless it scans the title line only |
| **A2. Ticket index file** `data/ticketIndex.json` | Maintain `PRDV-id → todoId` on write | O(1) lookup. New derived state that can drift from the source; needs rebuild-on-boot and invalidation on every card edit. Buys speed the app does not need |
| **A3. First-class `ticketId` field on the card** | Parse on create/edit, store explicitly | Removes the ambiguity **class** rather than working around it; makes the id filterable, groupable, and dashboardable. Requires a backfill for 45 cards and a UI decision about whether the field is user-editable or always derived from the title |
| **A4. Agent fetches all and filters** | No server change | Zero build. 925 KB into agent context per lookup; unusable in a loop. Rejected |

**Recommendation: A1 now, A3 as the structural shift.** A1 is the interface an agent calls; A3 is what that interface should eventually match on. Ship A1 scoped to the **first line** of `text` so the wrong-link case resolves correctly today, and keep A3 for when the dashboarding work needs `ticketId` as a real field anyway.

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

**Recommendation: B3, with B2 as the durable form.** The version marker is the part that earns its place — it lets a reader know which template generation a card was created from, which is exactly the drift problem. If notes gain a `kind` field later, the marker becomes redundant and can be dropped.

---

## D3 — Addressing a checklist item (the crux)

**Problem.** Items drift weekly in wording, nesting, and count. The note is one markdown blob.

**Requirement.** "Mark *Run grill-me session* complete" must resolve to the same line before and after a template revision, or fail loudly.

| Option | How | Trade-offs |
| --- | --- | --- |
| **C1. Exact text match** | Match the literal string | Simplest. Demonstrably broken: `Generate Artifacts` vs `Generate Investigation Report to validate the Spec to be written` are the same intent across generations. Rejected on evidence |
| **C2. Normalized / fuzzy match** | Lowercase, strip punctuation, token-overlap threshold | No schema change, tolerant of the current drift, works today. **Failure mode is silent mis-match** — the near-identical pairs above are exactly what fuzzy matching confuses. Acceptable only with a confidence floor and a hard fail below it |
| **C3. Stable ids embedded in markdown** | `- [ ] Run grill-me session <!--id:spec.grill-->` | Deterministic; survives rewording, renesting, and reordering; notes stay human-editable and human-readable; pairs naturally with the D6 template registry. Requires template regeneration and a backfill for existing cards; ids must be assigned once and never reused |
| **C4. Section + ordinal** | "3rd item under Development" | No schema change. Breaks on insertion, and the evidence shows insertion is the dominant drift mode. Rejected |
| **C5. Checklist as structured data** | `checklist: [{id, section, label, checked, slots}]` on the card or a new entity; markdown becomes a rendered projection | Best possible agent contract; makes per-item progress genuinely queryable (real dashboards, "which tickets are stuck in Project Spec"); removes parsing entirely. Largest lift: new entity, migration, and the note editor must be rebuilt or the checklist moved out of the note pane. Loses free-hand mid-checklist editing unless deliberately re-added |
| **C6. Let the model rewrite the note** | Send note text + intent, model returns new text | Already precedented by the Gemma refine path. Tolerant of anything. Non-deterministic, unauditable, and rewrites the whole blob — the worst option for clobber safety |

**Recommendation: C3, with C2 as an explicitly temporary bridge and C5 as the end state if dashboarding becomes the priority.**

C3 is the smallest change that makes the agent's writes deterministic. It also settles the maintenance question: the id is the contract, the wording is free to change, and the `orchestrate` phase steps can map to ids directly (`P3.grill` → `spec.grill`).

The honest case for C5: every "which tickets are blocked in Testing & Validation" question you would want a dashboard to answer requires parsing 35 markdown lines per card under C3. If dashboards are the actual goal rather than a side benefit, C5 is where this lands eventually and C3 is a way station. **This is the biggest open call in the document.**

---

## D4 — Write safety

**Problem.** `PUT /api/notes/:noteId` replaces the entire note body, takes no precondition, and the board background-refreshes on a 20-second idle timer. An agent write during an open editor session silently wins or loses depending on order.

**Requirement.** A concurrent human edit and agent write must never silently discard either one.

| Option | How | Trade-offs |
| --- | --- | --- |
| **D4a. `lastModified` precondition** | Client sends the `lastModified` it read; server 409s on mismatch | Standard optimistic concurrency, ~15 LOC, correct. Makes the agent handle a retry — which is the right place for that burden |
| **D4b. Granular item PATCH** | `PATCH …/checklist` toggling one item server-side | Shrinks the read-modify-write window to near zero and keeps the markdown surgery in one place. Reduces collision probability; does not eliminate it alone |
| **D4c. Field-level merge / CRDT** | Structural merge of note bodies | Eliminates collisions. Wildly disproportionate for a single-user local app |
| **D4d. Editor lease / lock** | UI claims the note while open | Prevents the collision at the source. Needs presence tracking and a stale-lock story; new failure mode where a crashed tab holds a lock |

**Recommendation: D4a + D4b together.** They are complementary — D4b makes collisions rare, D4a makes the rare case safe. Neither is optional: D4b alone still clobbers, and D4a alone forces the agent to resend a 3 KB blob on every checkbox.

---

## D5 — Writing the card's workflow sections

**Problem.** `Current Step`, `Waiting On`, `Next Up`, `Work Ahead` exist nowhere in the codebase — they are a markdown convention in `todo.text`, and 2 of 9 cards have only the first one.

**Requirement.** Set any of the four sections without disturbing the title, the `---` rule, or the sections not being written; create a missing section in the right position.

| Option | How | Trade-offs |
| --- | --- | --- |
| **E1. Agent does the markdown surgery** | Agent reads `text`, rewrites, `PATCH /todos/:id` | Zero server change, available today. The format convention gets re-encoded in every prompt and every agent; the structural variance must be handled by each one. Guaranteed to drift |
| **E2. Server-owned section PATCH** | `PATCH /todos/:id/sections` with `{currentStep, waitingOn, nextUp, workAhead}` | One owner for the format; normalizes the bare-line and missing-section cases centrally; the convention becomes testable. Still markdown underneath, so still unqueryable |
| **E3. Promote the four to real card fields** | `currentStep`, `waitingOn`, `nextUp`, `workAhead` on the todo record, rendered into the card view | This is what actually unlocks the dashboard: filter the board by "Waiting On is non-empty", group by current step, surface stalled cards. Requires card-render work, an editing UI, backfill of the 9 cards, and a decision on whether the markdown body remains the source of truth during transition |

**Recommendation: E2 now, E3 when dashboarding is the active goal.** Note that E3 and C5 are the same architectural move applied to two different surfaces — if you take one, take both, in one pass.

---

## D6 — Maintaining the checklist template

**Problem.** There is no template. Each card's checklist was pasted and then hand-edited, which is why there are three generations and eight distinct item sets.

**Requirement.** One source of truth for sections, items, item ids, and data slots, that both new-card creation and the agent read from — and that you can revise without breaking existing cards.

| Option | How | Trade-offs |
| --- | --- | --- |
| **F1. Template file in WorkLists** | `templates/ticket-checklist.md`, versioned | Simple, diffable in git, easy to hand-edit. Not editable in the app; needs a loader; version bumps are manual |
| **F2. Template in dustin-thomason** | Beside the `orchestrate` skill, since the phases originate there | Keeps workflow authority in one repo and the phase→section mapping adjacent to its owner. Makes WorkLists depend on a sibling repo path — fragile across machines |
| **F3. Template as a WorkLists data record** | `data/checklistTemplates.json`, edited in-app | Matches the **existing precedent** of `data/classificationPrompts.json` and `data/models.json` — same read/write/normalize machinery, same UI patterns. Editable where you work. Adds a section to the DAL |

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
| 1. Card identity | Ticket id buried in markdown → `ticketId` field | Exact resolution; grouping and filtering by ticket | Backfill 45 cards; UI decision on derived vs editable |
| 2. Note role | Untyped notes → note `kind` (or version marker) | Unambiguous checklist location; per-kind UI treatment | Backfill; `POST /api/notes` contract change |
| 3. Checklist addressability | Prose lines → stable ids (→ structured records) | Deterministic agent writes; template revision without breakage | Template regeneration + backfill (ids); note-editor rework (structured) |
| 4. Workflow sections | Markdown prose → card fields | **Real dashboards**: filter/group/sort by step, waiting-on, blocked | Card render + edit UI; backfill |
| 5. Write contract | Last-writer-wins → optimistic concurrency | Safe concurrent human + agent editing | Small; `409` handling in clients |

Shifts 3 and 4 are the same decision seen twice. Shifts 1, 2, and 5 are small and independent — they can land in any order.

---

## Phasing

**Tier 0 — works today, no schema change, no migration.** Proves the loop is worth building before paying for it.
`A1` card query · `B3` version marker · `C2` fuzzy match with a confidence floor and hard fail · `D4a` precondition · `E2` section PATCH · `G1` curl recipes.
Endpoints added: 3. Fields added: 0. Migrations: 0.

**Tier 1 — makes the agent deterministic.**
`C3` stable item ids · `F3` template registry · `D4b` granular checklist PATCH · backfill the 9 existing cards to the current template generation.
This is the tier where the weekly template revision stops being a threat.

**Tier 2 — makes the board a dashboard.**
`A3` `ticketId` field · `B2` note `kind` · `C5` structured checklist · `E3` section fields, plus the render/edit UI for both.
Only worth starting once you know from Tier 0/1 whether the agent loop is something you actually use.

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

1. **D3 — the crux.** Stable ids in markdown (C3), or structured checklist records (C5)? Framed as a question about goals: *is the board primarily a place you read, or a thing you want to query?* If querying, C5 + E3 and skip the way station.
2. **D5/E3 timing.** Do the four workflow sections become real card fields in this effort, or is that a follow-on? They are the single highest-value change for dashboarding and the most UI work.
3. **Template backfill scope.** Normalize all 9 existing cards to the current generation, or only cards touched from here forward? (Tolerant reader either way; this is about whether old cards become addressable.)
4. **Tier 0 as a proving run.** Build Tier 0 against one live ticket first, or commit to Tier 1 up front given the template revision rate?

## Open questions

- Does `Current Step` need a controlled vocabulary, or does it stay free text? The observed values suggest free text is intentional and useful — but that means it can never drive automation, only display. If it should be readable, it needs to become an enum with a free-text companion.
- Should the agent be permitted to *uncheck* an item, or is that human-only? Unchecking is how a failed verification is recorded, but it is also how an agent could silently erase progress.
- What happens when an agent's write conflicts with a human's on the same item — surface a toast, log it, or fail silently and retry?
- Two of nine notes are not checklists at all. Does the new template coexist with bespoke notes on the same card, or does the checklist get its own reserved slot?

## Not yet inspected

- The note-pane editor code path (`public/todolist2.js` note rendering) — how much of C5/E3 is UI rework has not been measured.
- Whether `data/todos-OfficeComputer1.json` and the other host-scoped data files imply multi-machine sync that a write contract would need to account for.
- The `POST /api/gemma-normalize` note-refine path as a possible existing vehicle for note writes (D3/C6) rather than a new endpoint.
