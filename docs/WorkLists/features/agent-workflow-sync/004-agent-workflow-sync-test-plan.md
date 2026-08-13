# Agent Workflow Sync — Overall Test Plan

Status: **refined — not yet executed**
Last updated: 2026-08-12T00:00:00Z
Parent: [`001` decisions](./001-agent-workflow-sync-decisions.md) · [`003` work breakdown](./003-agent-workflow-sync-work-breakdown.md)
Stories: [job stories index](../../tickets/agent-workflow-sync/stories/agent-workflow-sync-job-stories-index.md)

## Purpose

One plan covering W1–W7, so nothing falls between two specs. Each spec carries its own unit-level matrix; this document owns the three things no single spec can:

1. **The regression suite that proves nothing existing changed** — the additive-only constraint's evidence.
2. **The cross-body integration paths** — behavior that only exists once two bodies of work are combined.
3. **The story-level acceptance runs** — validating the yardstick rather than the units.

## Section A — Additive-only regression (the constraint's proof)

**This section is the highest-priority part of the plan.** The user's instruction was explicit: current functionality and every existing touch point stay exactly as they are. A green unit suite does not prove that; this does.

### A1 — Full existing suite, unmodified

| Check | Command | Pass condition |
| --- | --- | --- |
| Whole suite | `npm test` (`node --test`) | Same pass count as the pre-change baseline, **with no existing test file edited**. Capture the baseline count before W1 starts |
| Pre-existing failure | `tests/gemma-ui.test.js:417` | Still fails for the same documented reason (voice-session shortcut scope). Must not be "fixed" or hidden by this work |

**Editing an existing test to make it pass is a constraint violation, not a fix.** If an existing test needs changing, that means existing behavior changed — stop and escalate.

### A2 — Endpoint contract freeze

Every existing route, exercised before and after, response compared:

| Route | Assertion |
| --- | --- |
| `GET /data` | Identical shape. **One added key** (`cardTemplates`, from W3) is the only permitted difference; every pre-existing key byte-identical |
| `GET /todos` | Identical response, same record count |
| `PATCH /todos/:id` with `text` / `status` / `secondaryTagIds` / `tag` / `completed` | Byte-identical results to the pre-change fixture |
| `PATCH /todos/:id/status` | Unchanged |
| `PATCH /todos/:id/column`, `/tag`, `/secondary-tags` | Unchanged |
| `POST /todos`, `DELETE /todos/:id`, `POST /todos/:id/move`, `/duplicate` | Unchanged. `/duplicate` especially — W2's path B no longer uses it, so it must be left exactly as shipped |
| `GET`/`POST`/`PUT`/`DELETE /api/notes` | Unchanged — **`PUT` especially**, since W4 adds `PATCH` to the same path |
| `POST /data` | Unchanged, still writes the whole database |
| All board, column, tag, status, model, prompt, scheduler routes | Unchanged |

**Method:** capture a fixture of every route's response against a seeded dataset before W1, replay after each body of work, diff. A one-off script in the scratchpad, not a committed test.

### A3 — DAL behavior freeze

| Check | Assertion |
| --- | --- |
| `writeDB` | Still rewrites all 12 (then 13) section files. Explicitly asserted so a future optimization cannot silently land the deferred D0 fix |
| `readDB` | Still loads every section |
| `readNotes` / `writeNotes` | Unchanged implementations, still used by `PUT /api/notes/:noteId` |
| `updateTodo` with no new key | Result identical to the pre-change fixture |
| `updateTodo` timestamp cascade | Still stamps the card's column and its boards |

### A4 — Front-end surface freeze

| Check | Assertion |
| --- | --- |
| Existing card menu actions | All nine keep `id`, `label`, `icon`, `type`, and relative order |
| Existing settings tabs | General, Tag Colors, Secondary Tags, Statuses, Shortcuts, APIs, Prompts keep their ids, labels, icons and order; **Card Templates** is appended eighth |
| Note pane | `tests/browser-notes-smoke.js`, `tests/notes-collapse.test.js`, `tests/markdown-renderer.test.js` pass unchanged |
| `markdownRenderer.js` | **Not modified.** Asserted by diff. This is why the checklist format carries no hidden markers — HTML is escaped, so anything embedded would render as visible text |
| Board load and idle refresh | `GET /data` still drives both; no change to `loadInitialBoardData` |
| Note text after a checklist patch | Prose, tables, code blocks, blank lines and spacing byte-identical. The parser locates; it never re-renders |

## Section B — Per-body unit coverage

Owned by each spec; listed here as a completeness index only.

| Body | Test file | Happy | Failure | Edge | Graceful |
| --- | --- | --- | --- | --- | --- |
| W1 | `tests/dal-record-access.test.js` | ✔ | ✔ | ✔ section isolation, interleaving | ✔ 400/404/409 via `createDataError` |
| W2 | `api.test.js`, `openapi.test.js`, `card-actions.test.js` | ✔ | ✔ 404 | ✔ compound ids, array `tag` | ✔ |
| W3 | `tests/checklist-format.test.js`, `tests/card-templates.test.js` | ✔ | ✔ | ✔ three heading generations, hand-edited notes, prose/tables/code, note ordering | ✔ 400/404/409 |
| W4 | `tests/note-checklist-patch.test.js`, `api.test.js`, `openapi.test.js` | ✔ | ✔ | ✔ concurrency, atomicity, ambiguity | ✔ 400/404/409/422 |
| W5 | `tests/card-section-fields.test.js` | ✔ | ✔ | ✔ byte-equality, insertion order, bare-line | ✔ 400/409 |
| W6 | none — no harness | manual | manual | manual | manual |
| W7 | none — measurement only | n/a | n/a | n/a | n/a |

**W6's gap is a documented test exception**, per `build-implementation-guardrails` §1: no runnable harness exists for `dustin-thomason` skill/rule markdown. Risk: a guard is documented but not honored. Mitigation: Section C's live runs plus `steps.csv` `done` conditions.

## Section C — Cross-body integration

Behavior that exists only once bodies are combined. **These are the tests no single spec owns**, and the reason this document exists.

### C1 — W1 + W4: scoped write under the shared lock

| Scenario | Expected |
| --- | --- |
| `PATCH /api/notes/:noteId` while a `POST /data` runs | Both land; neither lost. Proves `patchRecord` shares `acquireLock` |
| Note `PATCH` writes | `event-notes.json` only; other 12 files byte-identical, mtimes unchanged |
| Note `PATCH` then `GET /data` | The change is visible through the whole-DB read |

### C2 — W3 + W4: the parser driving the patch

Rewritten for format-as-contract. There is no template resolution to test — the parser reads whatever is there, and the precondition guarantees the caller's view is current.

| Scenario | Expected |
| --- | --- |
| Patch a row read moments earlier | Applies to that row only |
| Patch a row on a checklist whose wording changed since the last phase | Applies — nothing was stored to go stale |
| **Note hand-edited to add a row** | **Writable.** The row is read and addressable like any other — the case the earlier design refused |
| Note hand-edited to reorder rows | Writable; addressing is by name, not position |
| Note carrying an older heading generation | Writable |
| Note carrying a different checklist shape entirely | Writable — **job story 03's extensibility case** |
| Row reworded between the read and the write | `409` first, because the note's `lastModified` moved; after a re-read, the new label works |
| Row label that no longer exists | `400` naming the row, nothing written |
| Two rows with identical labels in one section | `400` ambiguous, nothing written |
| Note with prose and a table alongside the checklist | Checklist updated; prose and table byte-identical |
| Note with no sections-with-steps | `422` |

### C3 — W2 + W5: read-then-write round trip

| Scenario | Expected |
| --- | --- |
| `GET /todos/:id`, then `PATCH /todos/:id` with the returned `lastModified` | `200`; new `lastModified` returned |
| Same, but a `PATCH /todos/:id/status` intervenes | `409`; card unchanged |
| `GET` a card whose `tag` is an array, `PATCH` a section key | `tag` still an array afterward |

### C4 — W5 + W3: a card must have structure before it can be written to

| Scenario | Expected |
| --- | --- |
| Section key sent to a card with no progress headings | `400`; card byte-identical |
| A card created by plain `POST /todos` | Has no workflow body — W5 correctly refuses it |
| A card created from a Card Template | **Has the progress sections, so W5 accepts it.** This is the pairing that closes what was an open gap |
| A template whose `cardText` lacks a progress heading | Rejected at template-save time, so it can never produce a card W5 would refuse |

### C5 — Full-stack agent path (W2 + W3 + W4 + W5 + W6)

Against a **duplicated** card, never a live one.

| Step | Expected |
| --- | --- |
| Read card, guard on ticket id | Passes |
| Read notes, identify the checklist **by structure** | One note identified |
| Agent reasons over the rows | Marks only rows the phase substantiated; names the rest |
| Patch eight rows plus two detail values in one request | All applied, one write |
| Patch `currentStep` + `nextUp` + `status` in one request | All applied, other sections of the card body byte-identical |
| Board idle refresh | Changes appear without a manual reload |
| Total requests for one phase | **Four** — one card read, one notes read, one note patch, one card patch |

### C5b — Ticket creation, path B (W3 + W2 + W6)

| Scenario | Expected |
| --- | --- |
| Agent starts a run with no card | Creates from the designated template; reports the new id; records it in the ledger |
| The created card | Carries the template's progress sections, with the real ticket title on line one |
| The created notes | One per template entry, in order, each bound to the new card |
| The primary note | Parses as a checklist, so the very next phase can write to it |
| New id round-trips | `GET /todos/:id` with the returned id returns that card |
| No template designated, none given | `400`; nothing created |
| Path stated | The report says path B and names the created id — never ambiguous with path A |

### C6 — Judgement and extensibility (W6 over W3 + W4)

The runs that prove the reframe, and the ones no unit test can cover.

| Scenario | Expected |
| --- | --- |
| A row the phase did not satisfy | Left unmarked **and named in the report** |
| A row the agent cannot interpret | Skipped, noted, other rows still applied |
| A detail line whose fact does not exist | Left blank, never fabricated |
| The `Investigation Spike` template's shape | Handled with no change to the agent |
| A checklist with no section relating to the phase | Nothing marked; reported plainly |
| Re-run of an already-complete phase | No-op; nothing un-marked |
| Phase start | `currentStep` names the phase now beginning; a Plan-mode phase's write lands at the next Working phase |
| Any guard stop | Notification fires naming the phase and the guard |
| Server unreachable | Skip recorded in the ledger, **no** notification, phase completes |

## Section D — Story acceptance runs

The yardstick. Full traceability lives in [`006-job-story-validation.md`](./006-job-story-validation.md); this section is the executable half.

| Story | Run | Pass condition |
| --- | --- | --- |
| 01 | Take one duplicated ticket through phases 0, 2, 3, 5, 6 with the agent | Every substantiated step marked, no unsubstantiated step marked, card body matches reality at each phase |
| 01 | Hand a deliberately wrong card id | Stops and reports; nothing written |
| 03 | Reword a step, then have the agent mark it on the next phase | Works — nothing stored to break |
| 03 | Add a step by hand, then run a phase | The hand-added step is read and addressable |
| 03 | Run against a differently-shaped checklist | Works with no change to the agent |
| 03 | Change a step in a template, then create a new ticket | The new ticket carries the change; existing tickets are untouched |
| 05 | Create a ticket from a template with nothing supplied but a column and a title | Card and all its notes created; id returned and reported |
| 05 | Author a template in the settings tab, then create from it | The created ticket matches what was authored |
| 04 | Open the note editor, type, let the agent patch the same note | `409`; typed text survives; user is told |
| 04 | Single checklist patch | One section file written, not all of them |
| **02** | — | **Cannot be run. No body of work in W1–W7 delivers any criterion for story 02** |

**Story 02 has no executable acceptance run in this scope.** That is the phasing consequence recorded in the story index and in `001` → *What this constraint costs*, restated here so a green test plan is not mistaken for a satisfied story set.

## Section E — Gates

Run at the end of each body of work, reported per `ticket-changelog` → *Verification-gate reporting*.

| Gate | Command | Scope |
| --- | --- | --- |
| audit | `npm audit --audit-level=high` | WorkLists |
| lint | `npm run lint` (prettier check) | WorkLists |
| tests | `node --test` | WorkLists, full suite |

`dustin-thomason` has no `package.json`, so for W6 all three are **not applicable — repo has no npm workspace**; `sync-rules.ps1` must run instead.

**Order:** audit → lint → tests, tests last against the post-lint tree.

## Execution order

1. Capture the **pre-change baseline** — full suite pass count, and the A2 route-fixture set. **Before W1 starts.** Without it, Section A cannot prove anything.
2. Per body of work: unit tests → Section A replay → gates.
3. After W5: Sections C1–C4.
4. After W6: Sections C5, C5b and C6, then Section D.
5. W7 independently, any time.

## Results log

To be filled during execution, with exact command, scope, and result per the reporting standard. Empty until then — recorded as empty rather than omitted, so an unexecuted plan is not mistaken for a passing one.

| Date (UTC) | Body | Gate / test | Command | Scope | Result |
| --- | --- | --- | --- | --- | --- |
| — | — | — | — | — | not yet executed |
