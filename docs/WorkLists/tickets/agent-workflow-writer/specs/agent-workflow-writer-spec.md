# W6 — Agent workflow writer — Spec

| Field | Value |
| --- | --- |
| Project | WorkLists |
| Ticket slug | `agent-workflow-writer` |
| Body of work | W6 of [`003-agent-workflow-sync-work-breakdown.md`](../../../features/agent-workflow-sync/003-agent-workflow-sync-work-breakdown.md) |
| Governing decisions | [`001`](../../../features/agent-workflow-sync/001-agent-workflow-sync-decisions.md) → how the agent calls this (D7, curl + OpenAPI), how it knows which card (D1, the id is supplied), and the additive-only constraint |
| Serves job stories | [01 — Delegated work stays true](../../agent-workflow-sync/stories/agent-workflow-sync-job-story-01-delegated-work-stays-true.md), [05 — Tickets start pre-built](../../agent-workflow-sync/stories/agent-workflow-sync-job-story-05-tickets-start-pre-built.md) (path B) |
| Depends on | W2, W3, W4, W5 |
| Repo touched | **`dustin-thomason` only** — no WorkLists code |
| Date | 2026-08-12 |

## Problem → Requirement → Solution

**Problem.** W2–W5 give the board a surface an agent can write to, but nothing tells an agent when to write, what to write, or when to stop. Without that, the endpoints are capability with no behavior.

**Requirement.** An agent running the `orchestrate` lifecycle must record each phase's completed steps on the right card, using facts the phase already produced, and must refuse rather than guess when it cannot do so safely.

**Solution.** Wire the card id into the ticket's captured inputs and the ledger, define how the agent reasons about which steps its phase completed, and define the write sequence with its guards. Delivered as skill and rule content — no product code.

## The agent's core duty is judgement, not lookup

**This is the centre of the body of work, and an earlier draft understated it as a mapping exercise.**

There is no stored identifier tying a checklist step to a phase. The format is the contract (see W3), so what the agent receives is **the checklist's current rows as written**, and what it must do is *reason*: read each row, decide whether the work that row describes was actually completed by this phase, and mark only those.

That has three consequences the rest of this spec builds on:

1. **The checklist is an input to be read, not a schema to be matched.** Rows may be reworded, reordered, added by hand, or belong to a checklist shape the agent has never seen. All of that is normal and workable.
2. **Extensibility is inherent.** Any checklist following the format works — a ticket workflow, a spike checklist, a bug-fix checklist, one invented next month. The agent is not tied to a fixed set of steps, and nothing needs updating when the steps change.
3. **The bar for marking a row is evidence, not plausibility.** A row is marked only when the phase produced something that satisfies it. "This phase usually does that" is not evidence.

### How the agent decides

For each row in the sections its phase covers:

| Question | Answer source |
| --- | --- |
| What does this row ask for? | The row's own text |
| Did this phase produce it? | The phase's actual outputs — artifacts on disk, gate results, the ledger, the test plan's results log |
| Can I point to what satisfies it? | If not, **leave it unmarked** |

**Leaving a row unmarked is always safe. Marking one wrongly is not.** When a row's meaning is genuinely unclear, or the evidence is partial, the agent leaves it and says so in its report rather than deciding for the user.

**A row it cannot interpret is not an error.** The agent skips it, notes it, and continues with the rows it can substantiate. Only a note with no recognizable checklist structure at all stops the write (`422`).

## Additive-only compliance

Trivially satisfied: **this body of work touches no WorkLists file.** It adds instructions to `dustin-thomason` skills and consumes only the endpoints W2–W5 added. If the agent is never run, nothing about WorkLists behaves differently.

One `orchestrate` consideration: the ledger gains a field and Phase 0 gains a capture step. Existing ticket folders without that field must keep working — a resumed run with no card id recorded falls back to asking once, and never blocks a phase that does not need the board.

## 1. Folder hierarchy

```text
dustin-thomason/
  agents/
    rules/
      worklists-card-sync.md               new — the write contract and guards
    skills/
      orchestrate/
        SKILL.md                           Phase 0 capture + per-phase write step
        steps.csv                          new step rows, one per phase
  docs/WorkLists/features/agent-workflow-sync/
    004-agent-workflow-sync-test-plan.md   (separate deliverable)
```

Generated outputs (`.claude/rules/`, `.cursor/rules/`, `AGENTS.md`) are produced by `.gents/scripts/sync-rules.ps1` and **must not be hand-edited** — authoritative source is `agents/rules/`.

## 2. Phase → checklist-section map

The seven-section ticket workflow happens to match the seven phases one-to-one, which narrows **where** the agent looks. It does not tell it **which rows** to mark — that is the judgement above.

**This map is a convenience for the default checklist, not a requirement.** A checklist with different sections still works: the agent reads the section names present and reasons about which relate to the phase it just finished. If none do, it marks nothing and says so.

| `orchestrate` phase | Section in the default checklist | Written when |
| --- | --- | --- |
| 0 Capture | Preliminary | Ticket folder, `original-ticket.md`, and draft job stories exist |
| 1 Recon and plan | Investigation | Deferred — plan mode cannot write. Lands at Phase 2's first action |
| 2 Report | Investigation | Report, coverage ledger, diagrams, test-plan seed emitted |
| 3 Probe & spec | Project Spec | Locked decisions, accepted stories, spec written and submitted |
| 4 Prep | Development | Deferred — plan mode. Lands at Phase 5's first action |
| 5 Implement | Development, Testing & Validation, Deploy & PR | Branch created; tests executed; audit/lint/tests, push, PR |
| 6 Wrap up | Ticket Closeout | ClickUp updated, review summary produced |

**Plan-mode phases defer their writes**, using the pattern `orchestrate` already applies to ledger writes and notifications (`deferred (plan mode)`). This inherits an existing convention rather than inventing one, and it sidesteps the skill's own open question about whether tool calls run in Plan mode.

### Card body values per phase

`currentStep` is written **at the start** of the phase named; `nextUp` at its completion. See *Phase-start write*.

| Phase | `currentStep` (written at start) | `nextUp` (written at completion) |
| --- | --- | --- |
| 0 | `Capture` | `Investigation` |
| 1 | `Investigation` — deferred to Phase 2's first action | — |
| 2 | *(already set by Phase 1's deferred write)* | `Project Spec` |
| 3 | `Project Spec` | `Implementation` |
| 4 | `Development` — deferred to Phase 5's first action | — |
| 5 | *(already set by Phase 4's deferred write)*, then `Testing`, then `Deploy & PR` | next in sequence |
| 6 | `Closeout` | cleared |

`waitingOn` is written when a phase begins or becomes blocked — Phase 5's spec-response gate is the clear case, becoming something like `Spec review from <reviewer>`. `workAhead` is left to the user; the agent never writes it.

**These values are free text** (W5 §Open questions 2), so they are a convention, not validated input. They are listed here so the agent is consistent rather than inventive.

## 3. Detail lines per phase

Indented non-checkbox lines under a step are fill-in values. The agent recognizes them by reading them, the same way it reads the steps:

| Detail line as written | Filled from |
| --- | --- |
| `Approved by: name` | The reviewer recorded at Phase 5's spec-response gate |
| `start testing on date @ time` | Test-plan execution start, UTC, from the results log |
| `finished testing on date @ time` | Test-plan execution finish |

**A detail line whose fact does not exist is left unwritten.** The agent never invents a plausible value — a fabricated timestamp is worse than a blank one, because a blank is visibly incomplete and a fabrication is not.

**These three are examples, not an allowlist.** A checklist with different detail lines works the same way: read the line, decide whether the phase produced something that fills it, fill it or leave it.

## 4. The write sequence

Normative order per phase. Matches [`002-agent-workflow-sync-sequence.mmd`](../../../features/agent-workflow-sync/002-agent-workflow-sync-sequence.mmd).

0. **Establish the card id — one of two ways, and say which.**
   - **Path A, the card exists:** read the id from the ledger. If it is not there, ask once and record it. **Never search for it.**
   - **Path B, no card yet:** `POST /api/cards/from-template` with the target column and the real ticket title, using the designated template. Take the new card's `id` from the response and record it in the ledger. **Report the id created.** The user supplies nothing in this path.
   Both paths end the same way: the id is in the ledger, and every later phase and any resumed run reads it from there.
1. **Confirm the path taken** in the phase's report, so a card that appeared is never mistaken for one that was already there.
1b. **Write `currentStep` for the phase now starting** — see *Phase-start write* below.
2. **`GET /todos/{id}`** — read the card and its `lastModified`.
3. **Guard:** the card's first line must contain the expected ticket id. On mismatch or `404`, **stop and report**. Never write.
4. **`GET /api/notes?eventId={id}`** — read the notes and their `lastModified` values.
5. **Identify the checklist note by its structure** — the note containing section headings with steps under them. If a card has more than one, name the `noteId` explicitly rather than picking. If none has checklist structure, **stop and report**.
6. **Read the rows and reason** — for each row in the relevant sections, decide from the phase's actual outputs whether it is satisfied. Mark only substantiated rows; leave the rest and note them.
7. **`PATCH /api/notes/{noteId}`** — one request carrying every row being marked, addressed by section name and label **exactly as read in step 4**, plus any detail values, plus the `lastModified` from step 4.
8. **`PATCH /todos/{id}`** — one request carrying `currentStep`, `nextUp`, any `waitingOn`, `status` if the phase changes it, and the card's `lastModified`.

**One request per resource per phase.** Not one per checklist row. Both endpoints accept batches for this reason.

### Phase-start write — approved 2026-08-12

**`currentStep` is written when a phase *starts*, not when it finishes.** Checklist rows and `nextUp` are still written on completion.

The reason is what the field is for: `Current Step` should say what is happening now. Writing it only on completion meant that during Phase 3 the card still read `Investigation` — accurate about finished work, wrong about current work, and wrong in exactly the way a reader of that field would be misled by.

| Moment | Written |
| --- | --- |
| Phase start | `currentStep` for the phase now beginning; `waitingOn` if it begins blocked |
| Phase completion | Checklist rows, detail lines, `nextUp`, `status` if the phase changes it |

**Cost:** one extra small request per phase — a `PATCH /todos/{id}` carrying `currentStep` alone. Accepted deliberately; the alternative is a field that is reliably one phase stale.

**Plan-mode phases (1 and 4) cannot write.** Their phase-start write is deferred to the next Working phase's first action, batched with that phase's own writes — the same deferral pattern already used for their ledger entries and notifications. The consequence is that during a Plan phase the card names the previous phase. That is unavoidable without a mode-switch capability, and it is narrower than the problem this decision fixes.

**Steps 4 and 7 must be one exchange.** The labels sent in step 7 are the labels read in step 4, and the `lastModified` from step 4 is what proves nothing moved between them. Reusing labels read in an earlier phase, or from memory, breaks that guarantee — re-read before every write.

### Guards — all four are stop conditions, not warnings

| Guard | Trigger | Behavior |
| --- | --- | --- |
| Ticket-id mismatch | Card title's ticket id ≠ expected | Stop, report both values, write nothing |
| Card not found | `404` | Stop, report the id, write nothing |
| No checklist structure | `422` from the note `PATCH`, or no note with sections and steps | Stop, report, write nothing to the note |
| Row not found or ambiguous | `400` | Stop, report which row. Means the agent's read and the stored note disagree — re-read rather than retrying the same body |
| Conflict | `409` from either endpoint | Re-read once, retry once. On a second `409`, **stop and report** — do not loop |

**Retry-once, then surface.** A retry loop that keeps going until it wins is indistinguishable from a clobber, which is what job story 04 forbids.

### Every stop notifies — approved 2026-08-12

**A guard stop calls the notification script**, not only a phase completion:

```powershell
& "<dustin-thomason>\scripts\notify-agent-complete.ps1" -Status "Completed" -Message "<Project>/<slug>: STOPPED at Phase <N> — <guard>"
```

The problem this fixes: the agent reports a stop in chat, and during an unattended run that lives only in the transcript. "The user is told" was true only if the user happened to be watching — which, given the whole point is delegating the work, is exactly when they are not.

| Rule | Detail |
| --- | --- |
| When | Any of the five guards firing, and any second `409` after the one retry |
| Message | Names the phase and which guard, so the notification is actionable without opening the transcript |
| Not on | A row left unmarked. That is normal and belongs in the phase report, not a notification — otherwise every phase notifies and the signal is worthless |
| Board write unavailable | Server not running is a **skip, not a stop** — recorded in the ledger, no notification, the phase still completes |

The distinction between *stop* and *skip* is what keeps this from becoming noise: a stop means work needs a decision from you, a skip means the board lagged and the ticket work carried on.

## 5. Permission boundaries

| Action | Permitted | Rule |
| --- | --- | --- |
| Mark a row complete | Yes | Only with evidence the phase produced what the row asks for |
| **Leave a row unmarked** | Yes, always safe | The default when evidence is absent, partial, or the row is uninterpretable. Reported, not silently skipped |
| **Un-mark a row** | **Yes, with a recorded reason** | Resolves job story 01's first open question. Un-marking is how a failed verification is recorded honestly — but never as a side effect of a re-run. A re-run over an already-complete phase is a no-op |
| Fill a detail line | Yes | Only from a fact the phase recorded. Never fabricated |
| **Add or remove a row** | **No** | The checklist's contents are the user's. The agent changes state, never structure |
| Set `currentStep` | Yes | At **phase start**, per *Phase-start write* |
| Set `nextUp` | Yes | At phase completion |
| Set `waitingOn` | Yes | Only when the phase is genuinely blocked |
| Set `workAhead` | **No** | The user's field |
| Set card `status` | **Yes, but only these transitions** | See below |
| Move the card between columns | **No** | Columns are sprint-based, not phase-based (`001` evidence). A phase transition implies nothing about which sprint a card belongs to |
| Create or delete a card or note | **No** | Out of scope for the writer |

### Status transitions

Resolves job story 01's second open question. The agent sets `status` only where the mapping is unambiguous:

| Phase | Sets status to |
| --- | --- |
| 2 (report emitted) | `In Progress` — only if the current status is `Unrefined` or `Ready` |
| 5 (PR opened) | `In Review` |
| 6 (closeout) | leaves it alone — `Ready for QA` is a ClickUp state, and the WorkLists vocabulary has no equivalent |

The agent **never** sets `Done`, `Blocked`, or `Icebox`. Those encode the user's judgement, not a phase fact.

## 6. Ledger and capture changes

**`orchestration.md` gains one row** in its metadata, not its phase table:

```markdown
| WorkLists card | todo-1786464124416 |
```

Recorded at Phase 0 alongside the ClickUp link and context paths, so a resumed run reads it rather than asking again. `original-ticket.md`'s Context Paths also carries it, since it is a context path present in the request.

**`steps.csv` gains one step per writing phase**, each with a `done` condition naming the observable result — e.g. `P2.board` with `done` = *note PATCH returned 200, the card's Current Step reads Investigation, and any row left unmarked is named in the report*. Sourcing them from `steps.csv` is what makes a skipped board write visible as a missing id rather than silently absent.

The `done` condition deliberately includes the unmarked rows. Since leaving a row unmarked is the safe default, a phase that marked nothing would otherwise look identical to a phase that wrote correctly.

## 7. Transport

Per D7's decision: **`curl` against `localhost:3010`, documented in the new rule.** No CLI, no MCP server. `GET /openapi.json` is the live contract, so the rule points at it rather than restating request shapes that could drift.

**Precondition on availability:** if the server is not running, the agent reports it and continues the phase without the board write, recording the skip in the ledger. A board write failing must never block ticket work — the board reflects the work, it does not gate it.

## 8. New DTOs / entities / migrations / projections

N/A across all four — this body of work adds no code and no stored shape.

## Spec tests

There is no test harness for skill content, so verification is behavioral and manual. Recorded per the guardrails' test-exception path: **blocked — no runnable harness exists for `dustin-thomason` skill/rule markdown**; risk is that a guard is documented but not honored; the mitigation is the live-ticket validation below plus `steps.csv` `done` conditions making each write auditable.

### Live-ticket validation

Run against one real ticket, with a card duplicated first so a failure cannot damage a live one.

| Scenario | Expected |
| --- | --- |
| Phase 0 completes | Preliminary items checked; `currentStep` = `Capture`; card id recorded in the ledger |
| Phase 2 completes | Investigation items checked; `currentStep` = `Investigation`; status `In Progress` if it was `Unrefined` |
| Phase 3 completes | Project Spec items checked |
| Phase 5 completes | Development, Testing & Validation, Deploy & PR rows checked; testing detail lines carry real UTC timestamps; status `In Review` |
| Phase 6 completes | Ticket Closeout rows checked; status unchanged |
| Resume mid-run | Card id read from the ledger; no second prompt |
| Path B: no card yet | Ticket created from the designated template; the new id reported and recorded; the card carries the four progress sections and the checklist note |
| Phase start | `currentStep` names the phase now beginning, not the one just finished |
| Any guard stop | Notification fires naming the phase and the guard |
| Server not running | Skip recorded, **no** notification, phase completes |
| Card id wrong | Guard stops the run; nothing written |
| Note has no checklist structure | Reported; nothing written |
| Human edits the note during a phase | `409`, one re-read and retry, then reported; the human's edit survives |
| Server not running | Skip recorded in the ledger; the phase still completes |
| Re-run a completed phase | No-op; nothing un-marked |

### Reasoning and extensibility — the runs that prove the reframe

| Scenario | Expected |
| --- | --- |
| A row the phase did **not** satisfy | Left unmarked and named in the report — not marked because it usually would be |
| A hand-added row the agent has never seen | Read and reasoned about like any other; marked only with evidence |
| A row reworded since the last phase | Marked correctly — nothing was stored to go stale |
| A **different checklist shape** (the `Investigation Spike` template) | Works with no change to the agent. The proof that this is not hardwired to the seven-section workflow |
| A checklist with no section matching the phase | Nothing marked; reported plainly |
| A row whose meaning is genuinely ambiguous | Left unmarked, surfaced to the user for a decision |
| A detail line whose fact does not exist | Left blank, not fabricated |

## Cross-cutting

- **Risk:** Medium. No code risk, but the highest behavioral risk of the seven, because this is where a misconfigured guard could write to the wrong card. The duplicate-card precaution in validation exists for that reason.
- **Rollback:** Revert the rule and skill edits, re-run `sync-rules.ps1`. No data to unwind — though board writes already made stay made.
- **Delivery order:** Last of the seven. Depends on W2, W3, W4, W5. **No longer blocked** — W3's card-template creation route builds the card body and its notes, so path B can start a ticket from nothing.
- **API docs:** N/A — consumes endpoints documented by W2, W4, W5; adds none.
- **Tooling gates:** `dustin-thomason` has no `package.json`, so `npm audit`, `lint`, and `test` are **not applicable — repo has no npm workspace**. `sync-rules.ps1` must be run after editing `agents/rules/`.

## Open questions

1. **Does the agent write on phase *start* as well as completion?** As specified it writes only on completion, so `currentStep` lags by one phase — during Phase 3 the card still reads `Investigation` until Phase 3 finishes. Writing `currentStep` at phase start and checklist items at completion would fix it at the cost of two writes per phase. Recommendation: write `currentStep` at phase start, items at completion — the field's whole purpose is saying what is happening *now*.
2. **How does the user see a reported stop?** The agent surfaces it in chat, but a stop during an unattended run is only visible in the transcript. The `agent-completion-notification` script is the obvious carrier and would cost one line.
3. **Which reviewer name goes in the `Approved by` slot** when the spec is approved by PR merge rather than a named person? Recommendation: record the merging identity, and leave the slot unwritten if there is none.
