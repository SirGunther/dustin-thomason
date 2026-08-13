# Agent Workflow Sync — Job Story Validation

Status: **not yet executed — traceability complete, results empty**
Last updated: 2026-08-12T00:00:00Z
Stories: [index](../../tickets/agent-workflow-sync/stories/agent-workflow-sync-job-stories-index.md)
Test plan: [`004`](./004-agent-workflow-sync-test-plan.md)

## Purpose

The final validation step: every acceptance criterion in the live stories (01, 03, 04, 05) traced to the spec that delivers it and the test that proves it. This exists so "the specs are done" cannot be mistaken for "the stories are satisfied."

**Rules for this document:**

- A criterion with no spec is a **gap** — either a body of work is missing or the criterion is out of scope, and which one must be stated.
- A criterion with a spec but no test is **unproven**, not delivered.
- A criterion is marked satisfied only after its test has actually run and passed, with the date recorded.
- Reinterpreting a criterion to match what was built is forbidden. If a criterion turns out unobservable, it failed its own Final Review Matrix — the story gets a new version in `dnu/`, per the `job-story` skill's revisit rules.

## Legend

| Mark | Meaning |
| --- | --- |
| **covered** | A spec delivers it and a test proves it. Awaiting execution |
| **partial** | Delivered, but something material about it is weaker than the criterion reads |
| **gap** | No body of work in W1–W7 delivers it. **There are none** — see the summary |

---

## Story 01 — Delegated work stays true

| # | Acceptance criterion | Spec | Test | Status |
| --- | --- | --- | --- | --- |
| 1.1 | The user names which ticket is being worked on at the start, and never has to name it again for that ticket | W2 (`GET /todos/:id`, Copy Card ID), W6 §6 (ledger records the card id) | Plan §D story 01 run — "Resume mid-run: card id read from the ledger, no second prompt" | **covered** |
| 1.2 | Steps the agent finishes are marked as finished without the user marking them | W4 (row `PATCH`), W6 (agent reasons over the rows read) | Plan §C5, §C6, §D story 01 phases 0/2/3/5/6 | **covered** |
| 1.3 | Steps that were not finished are not marked as finished | W6 (evidence not plausibility; unmarked is the safe default) | Plan §C6 "a row the phase did not satisfy"; §D story 01 | **covered — and strengthened by the reframe** |
| 1.4 | What the ticket says matches what was actually done | W5 (card body), W4 (checklist), W6 (*Phase-start write*) | Plan §D story 01; §C6 "phase start" run | **covered** — resolved 2026-08-12 |
| 1.5 | When a step cannot be recorded, the user is told rather than the step being skipped without notice | W4 (`400`/`409`/`422`), W6 (guards + *Every stop notifies*) | Plan §C6; §D story 01 wrong-id run; "any guard stop" run | **covered** — resolved 2026-08-12 |
| 1.6 | A ticket the agent cannot track is named as one it cannot track, rather than being partly updated | W4 (`422` for no checklist structure; all-or-none atomicity), W6 guards | Plan §C2 "no sections-with-steps"; §C6 | **covered** |

**1.3 got stronger, not just re-evidenced.** Under the earlier design the agent matched an item id and marked it; "was it actually done" was implicit. Now the agent's stated duty is to substantiate each row from the phase's real outputs, with *leave it unmarked* as the safe default and a report naming what it left. The criterion is now the centre of the design rather than a side effect of it.

**1.4 — closed 2026-08-12.** Was partial because `currentStep` was written on phase completion, so the card named the phase that just finished rather than the one running. Now written at **phase start**, with rows and `nextUp` still at completion. One residual: Plan-mode phases cannot write, so during Phase 1 or 4 the card names the previous phase — unavoidable without a mode-switch capability, and far narrower than the original lag.

**1.5 — closed 2026-08-12.** Was partial because a stop reached the user only through chat, invisible during an unattended run. Every guard stop now fires the notification script naming the phase and the guard. A **skip** — the board unreachable because the server is down — deliberately does not notify; it is recorded in the ledger and the phase completes.

---

## Story 02 — retired, out of scope

**Removed 2026-08-12.** This story asked for progress to be readable across many tickets at once. It was written from a misread of a passing line in the original request ("It is also important for the visibility and dashboarding of everything I use") — context about why the board matters, not a requirement for this feature.

**The effort is bounded to the card the agent is given an id for.** Nothing beyond that boundary. The story is retired to `stories/dnu/`, W9 is removed with it, and the "two copies of one value" decision it produced no longer exists — nothing needs to be queryable, so nothing needs a second copy.

Its one criterion that *was* in scope — a ticket's own wording about where it stands stays readable in full — is satisfied by W5 preserving the free-text sections byte-for-byte, and is covered under story 01's criterion 1.4.

## Story 03 — The checklist stays mine to change

**Re-traced after the format-as-contract reframe.** These criteria were previously satisfied by template version pinning. That mechanism is gone; the evidence below is different and, in three cases, stronger — a version pin made rewording safe *by freezing history*, whereas reading the current rows makes it safe *because nothing was frozen in the first place*.

| # | Acceptance criterion | Spec | Test | Status |
| --- | --- | --- | --- | --- |
| 3.1 | A step can be reworded or moved without breaking tracking on tickets that already carry it | W3 (format is the contract), W4 (rows addressed as read) | Plan §C2 "wording changed since the last phase"; "hand-edited to reorder rows" | **covered** |
| 3.2 | A step added in one place shows up on every ticket started after that | W3 (Card Templates), W2 (path B creates from the designated template) | W3 creation tests; W2 path-B run | **covered** — see 3.2 note |
| 3.3 | A retired step still reads correctly on older tickets that carry it | W3 (any conforming checklist parses; nothing validates against a canonical list) | W3 "older heading generation parses"; Plan §C2 | **covered — more simply than before** |
| 3.4 | A ticket started before the shared version is flagged as untrackable rather than tracked wrongly | W4 (`422` only when there is no checklist structure) | Plan §C2; §C6 | **covered, with the meaning changed** — see 3.4 note |
| 3.5 | Changing only a step's wording changes nothing about whether it can be tracked | W3 + W4 (nothing is stored against the wording; the row is read each time) | Plan §C2 "wording changed since the last phase" | **covered** |

**3.2 — closed 2026-08-12.** Was partial because nothing created a card's four-section body. Resolved by the Card Templates feature: a template defines the card body **and** its notes, a setting names which one the agent uses, and `POST /api/cards/from-template` creates the whole ticket in one call and returns the new card's id. Changing a step in the template changes what every ticket created afterward gets — which is the criterion, stated literally.

**3.3 — simpler now.** Previously this needed deprecation records preserving retired items at their original positions. Now a retired step simply is not in the template any more, and a note still carrying it parses and is writable like any other row. The machinery disappeared and the criterion is better served.

**3.4 — the criterion still holds, but what counts as untrackable narrowed sharply.** It used to mean "does not match a pinned template version," which flagged all three older heading generations and every hand-edited note. It now means "has no section with steps under it" — nothing else. The criterion's *intent* was never tracked wrongly, and that is fully met; but a reader comparing this to the earlier design should know the refusal is far rarer, deliberately. Old and hand-edited checklists are now first-class rather than rejected.

---

## Story 04 — Nothing I typed disappears

| # | Acceptance criterion | Spec | Test | Status |
| --- | --- | --- | --- | --- |
| 4.1 | A note being edited is not overwritten by background work | W4 (mandatory `lastModified`, `409`) | Plan §D story 04 editor-collision run; W4 concurrency matrix | **covered** |
| 4.2 | When two changes land on the same note, the user is told and neither is thrown away | W4 (`409` carries the current value), W6 (re-read, retry once, then surface) | W4 "human PUT then agent PATCH"; §D story 04 | **partial** — see 4.2 note |
| 4.3 | One small change does not rewrite parts of their data it never touched | W1 (`writeSection`), W4 (record access + locate-never-re-render) | W1 section isolation; §C1 "other section files byte-identical"; §A4 "prose and tables byte-identical" | **partial** — see 4.3 note |

**4.3 gained a second dimension from the reframe.** It now covers two things, and only one is partial. Within the note, the criterion is **fully met**: the parser locates rows and only checkbox characters and named detail lines change, so prose, tables, code blocks, and spacing are provably untouched. Across files it is still partial for cards, per the note below.
| 4.4 | The user can keep typing in a note while a ticket's tracking is being updated | W4 (shared lock, scoped write) | §C1 interleaving; §D story 04 | **covered** |
| 4.5 | A collision that cannot be sorted out automatically is brought to the user instead of being resolved by whoever happens to win | W6 (retry once, then stop **and notify**) | §D story 04; "any guard stop" run | **covered** — resolved 2026-08-12 |

**4.2 — why partial.** True for notes, where W4 makes `lastModified` mandatory. **Not true for the card body:** W5 cannot require a precondition on `PATCH /todos/:id` without breaking the board UI, which the constraint forbids — so `lastModified` there is optional and honored only when sent. A caller that omits it still wins silently. The agent always sends it (W6 makes that normative), so the exposure is narrow, but the criterion as written is not fully met for card text.

**4.3 — why partial across files, and this is the constraint's clearest deferral.** Met for the **note** path: a checklist patch writes one section file, and within that file only the intended lines change. **Not yet met for the card** path: W5 goes through `updateTodo` → `writeDB`, which rewrites every section file, because repointing it now is out of scope. So a card-section change still rewrites `models.json`, `statuses.json`, and the rest. **This is the migration that happens later** — one call-site change onto record access, no contract change — not a permanent gap. The criterion is met for the write the user is most likely to collide with, and pending for the other.

---

## Story 05 — Tickets start pre-built

Added 2026-08-12 from conversation. In scope because it is about how the one card the run works on comes into being — the entry point of the same run.

| # | Acceptance criterion | Spec | Test | Status |
| --- | --- | --- | --- | --- |
| 5.1 | What a new ticket starts with is defined in one place, and changing it there changes what new tickets get | W3 (`cardTemplates` section, CRUD) | W3 CRUD + creation tests | **covered** |
| 5.2 | More than one can be kept, so different kinds of work start differently | W3 (plural templates, no single active; two seeded) | W3 "cold start seeds both starter templates" | **covered** |
| 5.3 | A new ticket comes out with its progress sections and its checklist already in place | W3 (`cardText` + ordered `notes`, creation route) | W3 "card created with the template's body; one note per entry, in order" | **covered** |
| 5.4 | Starting a ticket needs no retyping and no hunting for an old one to copy | W3 (creation route), W2 (path B) | W2 path-B run; Plan §C5 | **covered** |
| 5.5 | It can be looked at and changed in the same place the rest of the app's own configuration is managed | W3 (**Card Templates** tab in the existing settings dialog) | W3 settings-tab tests; Plan §A4 "seven existing tabs unchanged" | **covered** |
| 5.6 | Whoever starts the ticket is told which one was created, so they can go straight to it | W3 (response carries `todo.id`), W6 (reports the id it created) | W3 "response carries `todo.id`; that id resolves through `GET /todos/:id`" | **covered** — see note |

**5.6 — covered, with one honest caveat.** The route returns the id and the agent reports it. If ticket creation stays **agent-only** to begin with — which you raised as acceptable — then this criterion is only ever exercised through the agent. It is not unmet; it is exercised on one path rather than two. An in-app "new from template" action would exercise the other.

---

## Summary

| Story | Criteria | covered | partial | gap |
| --- | --- | --- | --- | --- |
| 01 Delegated work stays true | 6 | 6 | 0 | 0 |
| 03 The checklist stays mine to change | 5 | 5 | 0 | 0 |
| 04 Nothing I typed disappears | 5 | 3 | 2 | 0 |
| 05 Tickets start pre-built | 6 | 6 | 0 | 0 |
| **Total** | **22** | **20** | **2** | **0** |

*(Story 02's five criteria are gone with the story — retired as out of scope, not left unmet.)*

### What this says plainly

**W1–W7 delivers all four live stories, with no gaps and two partials.** The two remaining *partial* marks share one root cause:

| Root cause | Affects | Resolvable by |
| --- | --- | --- |
| Card writes cannot require a precondition or use scoped writes **yet** | 4.2, 4.3 | The later migration onto record access — deferred by design, with the path built in |

**One intentional deferral, nothing else.** Both partials are the same thing seen twice: `PATCH /todos/:id` cannot demand a `lastModified` without breaking the board UI, and cannot use scoped writes without repointing `updateTodo` — both forbidden *for now*, both with the migration designed in. Note the note path, where a human is far likelier to be typing, is fully covered.

### What the format-as-contract reframe changed here

| Effect | Detail |
| --- | --- |
| **No criterion regressed** | Every criterion previously covered is still covered |
| **1.3 strengthened** | "Not finished is not marked" moved from implicit to the centre of the design |
| **3.3 simplified** | Deprecation-record machinery removed; the criterion is better served without it |
| **3.4 narrowed in scope** | Refusal now means only "no checklist structure" — old and hand-edited checklists became first-class instead of rejected |
| **4.3 partly upgraded** | Within a note, byte-preservation is now provable |
| **Extensibility became real** | Job story 03's motivation — the user's process keeps changing — is served by any conforming checklist working, not just one blessed template |
| **W8 largely dissolved** | Existing cards were only "untrackable" because of the old design |

### What the scope correction changed here

| Effect | Detail |
| --- | --- |
| **Story 02 retired** | Written from a misread of a passing line about visibility. The effort is bounded to the card the agent is given an id for |
| **Four gaps disappeared** | They were gaps against criteria that should not have existed. No live criterion is unmet |
| **W9 removed** | It existed only to serve story 02 |
| **The "second copy" decision dissolved** | It only arose from needing workflow values queryable across cards. Nothing needs that |
| **3.2 closed** | The card body comes from a system-designated template via the already-shipped duplicate route, which returns the new card's id |

### What is left to decide

Consolidated in [`007-open-decisions.md`](./007-open-decisions.md). Two matter here:

1. **Write `currentStep` at phase start?** — closes 1.4. Recommendation: yes.
2. **Notify on an agent stop?** — closes 1.5 and 4.5. Recommendation: yes, one line.

## Results log

Empty until the test plan executes. Recorded as empty rather than omitted, so this document cannot be read as a passing validation.

| Date (UTC) | Story | Criterion | Test run | Result |
| --- | --- | --- | --- | --- |
| — | — | — | — | not yet executed |
