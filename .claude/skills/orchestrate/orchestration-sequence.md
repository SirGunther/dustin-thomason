# Orchestration sequence

> **What this is:** how the lifecycle in [SKILL.md](./SKILL.md) actually operates — every artifact it produces, the phase that creates each one, and every later phase that updates it. Lifelines are named for the **document** rather than a role, so what a message touches is unambiguous. Filenames drop the `<slug>-` prefix for width, and the job-story lifeline also drops its trailing `-<short>` segment — the real names are `<slug>-job-story-<NN>-<short>.md` and `<slug>-job-stories-index.md`, per SKILL.md's folder layout.
>
> **Two actor columns, then documents.** `You` and `agent` are the only things that act; every other lifeline is a passive file. A read is a request out and a dashed return back; a write is a solid arrow into the document. Neither actor counts toward a phase's span.
>
> **Read it for the backward arrows.** Phases run forward, but artifacts come back: plan-mode writes land a phase late, the why doc and the stories stay open the whole way, and a done report is appended to rather than rewritten.
>
> **Rules of the diagram** — the philosophy it is held to. A change that breaks one of these is wrong even if it reads well:
>
> 1. **Lifelines are ordered by the order items are introduced** — not by importance, and not by how often they appear.
> 2. **Flow is linear** — arrows move forward to the adjacent lifeline. A backward or long-jump arrow needs a stated reason.
> 3. **A self-loop only where work is done and time passes** — never for a state label or a standing rule. Those are notes.
> 4. **Display only what changes how the phase is run** — bookkeeping that is true of every phase belongs in the global note, not in a band.
> 5. **Headers name the document**, so what an arrow touches is unambiguous.
> 6. **A phase note spans only the lifelines that phase touches, and never includes an actor.** The width measures how far the *data* reaches — back into artifacts already written, forward into ones not yet created. Actors are present at every phase, so counting them makes every note start at the left edge and destroys the signal. Only the opening notes span the full data width, because they genuinely govern every phase. Width reads as reach, leftmost to rightmost touched — not as how many lifelines lie in between.
> 7. **A note spans its phase's full data range, or sits over one named lifeline** — never an arbitrary subset. A note covering two of nine touched lifelines tells the reader nothing about why those two.
> 8. **Solid arrow = an actor initiating** — a request to read, or a write that lands on disk now. **Dashed arrow = a return or a deferral** — data coming back from a document, an approval coming back from `You`, or a Plan-mode write staged to land in a later phase. The unifying test: a dashed arrow never changes disk state at the moment it is drawn.
> 9. **Every action names the file that governs it** — the skill, doc, rule, or script it comes from, including the script a step actually executes. This diagram is a blueprint for the *files involved*, not only the workflow, so a reader can go to the source without guessing. Headers carry their source too: a phase band names the section that defines it, and a gate names where its evidence list lives.
>
> 10. **Actors act — documents never do.** There are exactly two actors, `You` and `agent`, and they are the only valid senders. A document is passive: it does not read, grep, decide, run a command, or push its contents anywhere. So a **read** is a pair — `agent->>DOC` asking, `DOC-->>agent` returning — and a **write** is `agent->>DOC`. If an arrow appears to be sent *by* a document, that lifeline is standing in for the actor and the arrow is wrong. Two corollaries: a self-loop on a document is almost always this error, because the work belongs to the agent and not to the file it happens to touch; and **a document never acts before it exists** — it may be the target of a staged write in an earlier phase, but it cannot send anything until the phase that creates it.
>
> **One deliberate exception to rule 5:** `implementation repo` is not a document. It earns a lifeline because Phase 5 writes source code, and without it the diagram shows code being written into `testing-implementation.md`. It also makes the docs-here / code-there boundary visible, which is one of the orchestration's load-bearing rules.
>
> **Syntax constraints inside the mermaid block** — use `—` or `·` to set off an aside instead of any of these:
>
> - **No parentheses** — LucidChart's mermaid parser rejects them.
> - **No semicolons** — mermaid reads `;` as a statement separator, so a note ends mid-sentence and the remainder is parsed as a new statement.
> - **No `#`** — it opens an HTML entity code.

```mermaid
sequenceDiagram
    participant U as You
    participant AG as agent
    participant LEDGER as orchestration.md
    participant TICKET as original-ticket.md
    participant CLOG as changelog
    participant STORY as job-story-NN.md + index
    participant COV as coverage-ledger.md
    participant CODE as implementation repo
    participant WHY as why-these-changes.md
    participant PLAN as recon-and-plan.md
    participant RPT as investigation.md
    participant DIA as diagrams.md
    participant CONC as future-development-concerns.md
    participant TP as test-plan.md
    participant PR as pr-draft.md
    participant LD as locked-decisions.md
    participant SPEC as spec.md
    participant TI as testing-implementation.md

    Note over LEDGER,TI: Every phase — the ledger row and Resume footer update · a visible todo list is maintained throughout · the gate must print · a failed gate blocks the advance · every completion notifies · confidence is not a substitute for the check
    Note over LEDGER,TI: Handoffs — the block is emitted verbatim and nothing follows it · in Claude Code, EnterPlanMode may cross a Working→Plan boundary without stopping, but the block still prints

    Note over LEDGER,STORY: PHASE 0 — Capture · Working · defined in SKILL.md Phase 0
    Note over LEDGER,STORY: reads — original-ticket-artifact.md · job-story/SKILL.md · ticket-changelog rule · browser-loop-setup.md when the ticket lives in ClickUp
    U->>AG: orchestrate this ticket — an id, a project and slug, or a free brief · never synthesized into existence · SKILL.md Invocation
    AG->>LEDGER: resumed from an existing run, or scaffolded from the template — disk facts win when the two disagree · SKILL.md State ledger and resume
    AG->>TICKET: written verbatim per original-ticket-artifact.md — ClickUp capture or pasted text · no findings, no recommendations
    Note over TICKET: the Original Request is never rewritten — later phases may only append Downstream Artifacts · SKILL.md Do-not
    AG->>CLOG: resolved, or scaffolded by scripts/new-ticket-changelog.ps1 with Requirements verbatim · ticket-changelog rule, First pass
    CLOG-->>AG: Current state · Plans · Attempt history — what was already tried, rejected, or asked repeatedly
    AG->>STORY: synthesized per job-story/SKILL.md — one story per distinct problem · status draft
    Note over LEDGER,STORY: gate — no criterion names a design element · every artifact under dustin-thomason even when the code lives elsewhere · no implementation-repo file touched yet · evidence list in SKILL.md Phase 0
    AG->>U: notify via scripts/notify-agent-complete.ps1 per the agent-completion-notification rule · HANDOFF block per SKILL.md → Phase 1 requires Plan mode
    U-->>AG: "go"

    Note over TICKET,PLAN: PHASE 1 — Recon and plan · Plan mode as the method for collecting methodically · nothing lands on disk yet · defined in SKILL.md Phase 1
    Note over TICKET,PLAN: reads — investigation/SKILL.md, executed as this phase · investigation-software-gaps.md as the mandatory software lens · investigation-coverage-ledger.md for the consult protocol · Problem Check is embedded in method Step 1 and is never loaded separately · NOT investigation-question-coverage.md
    Note over COV: consult protocol per investigation-coverage-ledger.md — OTHER tickets' ledgers globbed at docs/Project/tickets/*/investigations/*-coverage-ledger.md and grepped for the subsystems in play · reuse covered ground, reopen only per the four conditions with the reason recorded
    AG->>TICKET: read the request text — Problem Check grounds every finding in a trimmed quote from it
    TICKET-->>AG: the words the framing claims must cite, not only code
    AG->>CODE: Step 7 reconcile — resolve the code-discoverable questions by tracing the evidence NOW · READ ONLY, nothing created, edited, or run there until Phases 0 and 1 both print done
    CODE-->>AG: file and line evidence · the commit each inspection is keyed to
    AG->>AG: investigation method steps 1–7 — everything but the emit · Problem Check lens · software lens · Step 7 fact-vs-decision split
    AG-->>COV: staged — the consult log line, then a coverage row per area traversed with items inspected, findings, status and commit
    AG-->>WHY: staged — the class of problem, and the Phase 1 why-log entry of obvious vs not obvious vs assumptions · per why-these-changes.md
    AG-->>STORY: staged — questions the investigation answered, criteria a finding invalidates, any story that has to split · peer input to the stories, never their source of truth
    AG-->>PLAN: staged — this recon's findings, then the emission todos · saved verbatim at Phase 2's first action
    Note over TICKET,PLAN: gate — the plan carries this recon's findings, not todos alone, so Phase 2 is executable from it with no other context · the consult results and reconcile-per-lens todos are in it · the Problem Check pass is present, and a flag may read nothing here · every open question split into a fact resolved by evidence or a decision with an owner · no code-discoverable fact parked as a decision · problem class, why-log entry and story reconcile all staged, or story movement explicitly none · SKILL.md Phase 1 gate
    AG->>U: the recon-and-plan doc — findings reached, then todos to reconcile against every point of the software lens, emit the report, materialize the coverage ledger with its consult line, produce the diagrams artifact, seed the test plan, and record any surfaced concerns
    U-->>AG: plan approved — the approval IS the handoff · the Phase 1 ledger row and its notification both fire at Phase 2's first action

    Note over LEDGER,PR: PHASE 2 — Investigation report · Working · defined in SKILL.md Phase 2
    Note over LEDGER,PR: reads — the approved plan · investigation-report.md · investigation-diagrams.md · test-plan-artifact.md · in-step — pull-request-workflow.md for the PR shell, future-development-concerns.md when the plan's todos carry a concern
    AG->>LEDGER: entry check — confirm Phases 0 and 1 both read done, or skipped with a reason
    LEDGER-->>AG: the phase rows · nothing is created, edited, or run in the implementation repo until they do · SKILL.md Entry check
    AG->>PLAN: the approved plan saved verbatim, then frozen — deviation goes to the coverage ledger's reopen reason or the why-log, never back into the plan
    AG->>WHY: materialized — the staged problem class and Phase 1 why-log entry land here
    AG->>STORY: staged reconcile applied — revised criteria, closed questions, any split · a Phase 1 Story log entry on each story touched
    AG->>RPT: written from investigation-report.md into investigations/, which OVERRIDES the template's own default location · the verdict leads the reading order and is written last · §5 links out to the diagrams artifact and never embeds it
    AG->>COV: materialized — consult line first, then every staged area entry, then the not-yet-inspected frontier
    AG->>DIA: current-vs-target, flows, sequences including race conditions and timing edges per investigation-diagrams.md · N/A lines for the kinds skipped
    AG->>CONC: created on the first concern only, per the plan's emission todos and future-development-concerns.md
    AG->>TP: seeded from report §9 per test-plan-artifact.md — each scenario names the criterion it exercises, or is flagged as coverage with no criterion behind it yet · status seeded
    AG->>PR: shell only per pull-request-workflow.md — title, ClickUp link, Description, Test Evidence, Commit hash, Checklist as empty placeholders, topped with a one-line note that it is unfilled · the body waits because scope can still move in Phases 3 and 4
    AG->>TICKET: Downstream Artifacts appended
    AG->>CLOG: Plans row added
    Note over LEDGER,PR: gate — the consult log line is present in the coverage ledger · report §5 links the diagrams rather than embedding them · report §2 Problem Check filled with quote-grounded findings, or an explicit nothing-here per flag · §1–§2 framing claims cite ticket-text quotes, not only code · §8 and §10 route facts vs decisions · every story Open Question appears in §10 or was closed with its evidence · test plan status seeded · PR shell staged with its body unfilled · evidence list in SKILL.md Phase 2
    AG->>U: notify, with the deferred Phase 1 notice batched in · gate prints, then AUTO-ADVANCE to Phase 3 — same mode, no stop

    Note over STORY,SPEC: PHASE 3 — Probe and spec · Working · defined in SKILL.md Phase 3
    Note over STORY,SPEC: reads — grill-me/SKILL.md · qa-to-spec-traceability.md · spec-writing rule, loaded automatically · write-spec/SKILL.md and wiki-spec-authoring.md when a PRDV app ticket routes to the wiki, asked once — sibling spec or wiki
    AG->>RPT: read §8 assumptions and §10 open variables
    RPT-->>AG: the assumptions and open variables as recorded at Phase 2
    AG->>STORY: read each story's remaining Open Questions
    STORY-->>AG: the open questions each story still carries
    AG->>CODE: re-run the Step 7 reconcile before grilling — trace every question the code can answer · a question bundling a fact with a decision is split, the fact answered here
    CODE-->>AG: the discoverable facts, resolved by evidence · only genuine decisions may reach grill-me
    AG->>AG: grill-me per grill-me/SKILL.md under the qa-to-spec-traceability workflow — one question at a time · question gate before each · rejected paths recorded
    AG->>LD: materialized as its own file — question gates resolved, then the full row table with source, supersedes-or-rejects, and spec destination · each answer committed before the next question · supersessions recorded, never overwritten
    AG->>CONC: a risk-accepting answer produces BOTH records, the file created on the first concern — the locked-decision row cites the concern entry
    AG->>STORY: resolved decisions folded into the criteria they affect · Open Questions closed, or one carried forward with a named owner and reason · index rows set accepted · Phase 3 Story log entry appended · a decision wins on how, the criterion still owns what done means and is rewritten to stay observable
    AG->>SPEC: written per the spec-writing rule — grill-me output INFORMS the spec and is not the spec · links locked-decisions.md rather than repeating it · N/A lines where a section does not apply · framed Problem → Requirement → Solution · cites the stories' criteria, never restates or amends them
    AG->>TP: refined — resolved variables become concrete assertions, each mapped to the criterion it proves · status refined
    Note over STORY,SPEC: gate — the spec's locked-decisions section links to a locked-decisions.md whose ledger traces every entry to a source · no locked decision left open · supersessions recorded, never a silent overwrite · every story accepted, or naming the owner of a still-open question · the spec cites the criteria rather than restating or amending them · audit per qa-to-spec-traceability.md definition of done
    AG->>U: notify · HANDOFF block per SKILL.md → Phase 4 requires Plan mode
    U-->>AG: "go"

    Note over CLOG,SPEC: PHASE 4 — Prep · Plan · no re-investigation, plan from the artifacts · defined in SKILL.md Phase 4
    Note over CLOG,SPEC: reads — the spec, report §11 and the test plan, all drawn below · in-step — new-branch-get-started.md for the branch step, build-implementation-guardrails rule for the shipping obligations
    AG->>SPEC: read the design
    SPEC-->>AG: what to build, and the locked decisions behind it
    AG->>RPT: read §11 handoff table
    RPT-->>AG: action · owner · falsifiable done-when per item
    AG->>TP: read the refined scenarios
    TP-->>AG: what must be proven, and by which assertion
    Note over CLOG,SPEC: gate — every plan step traces to spec, report, or test plan AND to an acceptance criterion · a step tracing to no criterion is a missing criterion or out of scope, and which one gets recorded · evidence list in SKILL.md Phase 4
    AG-->>CLOG: staged — a Plans row for this plan, landing at Phase 5's first action
    AG->>U: implementation plan — framed Problem → Requirement → Solution · ordered steps · branch step per new-branch-get-started.md when repo work begins · test execution mapped to the test plan · tests, regression, API docs and gates named up front per the build-implementation-guardrails rule
    U-->>AG: plan approved — the approval IS the handoff · the ledger row, the changelog Plans row and the deferred Phase 4 notification all fire at Phase 5's first action

    Note over CLOG,TI: PHASE 5 — Implement · Working · defined in SKILL.md Phase 5
    Note over CLOG,TI: reads — the approved plan · the test plan · the touched repo's own rules · in-step — testing-implementation-artifact.md, pull-request-workflow.md, git-commit-workflow rule
    AG->>CLOG: Plans row set active — the row staged at Phase 4 lands here
    AG->>TP: revised to match what was actually approved, since that can differ from what the spec proposed — after approval, before any code · a quick pass, not a rebuild · status revised post-approval
    AG->>CODE: implemented per the approved plan, inside the build-implementation-guardrails obligations — tests as part of shipping · architecture fit · graceful degradation by layer
    AG->>TP: read the scenarios to execute
    TP-->>AG: each scenario and the criterion it proves
    AG->>CODE: test-plan scenarios executed against the change
    CODE-->>AG: observed results — exact command · scope · result · serial runs
    AG->>TP: scenarios checked off and the results log filled · status complete, or blocked items carrying reason, residual risk and follow-up
    alt a criterion proves unobservable
        AG->>STORY: story moved to dnu/ and the next version written — never reinterpret a criterion to match what was built
    end
    opt any phase after 2 — later work changes a report already marked done
        AG->>RPT: numbered addendum §13+, dated and evidenced — never a rewrite of the verdict
    end
    AG->>TI: scenario first per testing-implementation-artifact.md — why each situation matters and whether it held · newly-uncovered scenarios flagged · each change hung off the scenario that forced it, as files plus observed → expected → fix · a living doc written as you go
    AG->>CLOG: session log written before every commit · ticket-changelog rule
    AG->>CODE: audit, then lint, then tests — the pre-commit gate order per the git-commit-workflow rule
    AG->>PR: the Phase 2 shell filled per pull-request-workflow.md — title · description · test evidence pasted from testing-implementation.md · commit hash · PR opened when requested
    Note over CLOG,TI: gate — test plan status complete, or blocked items carrying reason, risk and follow-up · the testing-implementation doc records each scenario in dev-legible terms with newly-uncovered ones flagged and every change hung off its scenario, assembled for the PR comment and never copied into source · session log written · gate results reported as a table · never mark this phase done on drafted code, the evidence must be an observed run, check or passing suite and not a claim · evidence list in SKILL.md Phase 5
    AG->>U: notify · HANDOFF block per SKILL.md → Phase 6 · Idle

    Note over LEDGER,TP: PHASE 6 — Manual review · Idle · defined in SKILL.md Phase 6
    Note over LEDGER,TP: reads — SKILL.md declares none for this phase · in-step — why-these-changes.md for the finalization shape, cleanup-candidates.md as the cruft-check destination, agent-completion-notification rule for the last notify
    AG->>STORY: read the accepted acceptance criteria
    STORY-->>AG: what done was defined as, before anything was built
    AG->>TP: read the results log
    TP-->>AG: what was proven, and what was blocked with what residual risk
    AG->>WHY: read the why-log
    WHY-->>AG: every phase where the why moved — confirm none went unlogged
    AG->>WHY: finalized — a headline count, then each change categorized as requested change, bug fix, workflow change, capability gap or other, with Before / After / Why per change · why it shipped together, tied to the acceptance criteria · Scope · Net · Verified as gates plus the PR link
    AG->>STORY: final Story log entry · every index row reads accepted or superseded
    AG->>CLOG: Plans row set implemented, when the work actually landed
    AG->>LEDGER: Phase 6 done · Resume complete · cruft check — findings are appended to cleanup-candidates.md, and only the clean case is noted here as nothing surfaced
    AG->>U: review summary — what to review and where, each acceptance criterion walked against what shipped, citing the test plan's results log and the Why doc · no unfalsifiable tests-passed claims · the final notify · then END, you review manually
```

## Artifacts produced

Every file the orchestration writes, and each phase that **writes** to it. Reads are on the diagram, not in this table — a phase absent from a row never writes that artifact, but may still read it.

| Artifact | Created | Updated | Closed |
| --- | --- | --- | --- |
| `original-ticket.md` | 0 | 2 — Downstream Artifacts | Original Request never rewritten, ever |
| `orchestration.md` | 0 | every phase transition | 6 — `Resume: complete` |
| `stories/` + index | 0 — `draft` | 1 staged → 2 applied → 3 `accepted` → 4 if a plan step traces to no criterion → 5 if a criterion breaks | 6 — every row `accepted` or `superseded (see dnu/)` |
| `recon-and-plan.md` | 1 approved → 2 saved verbatim | — | frozen on write; deviation lands in the coverage ledger or the why-log |
| `why-these-changes.md` | 1 staged → 2 written | every phase the why moves | 6 — reviewer-facing finalization |
| `coverage-ledger.md` | 1 staged → 2 written | as branches are traversed | frontier left explicit |
| `investigation.md` | 2 | addendum §13+ only — never rewritten in place | verdict written last |
| `diagrams.md` | 2 | — | N/A lines for kinds skipped |
| `future-development-concerns.md` | 1–4, on the first concern only | 3 — risk-accepting answers | — |
| `locked-decisions.md` | 3 | supersessions recorded, never overwritten | 3 — no decision left open |
| `spec.md` | 3 | — | cites stories and the LD ledger rather than repeating them |
| `test-plan.md` | 2 `seeded` | 3 `refined` → 5 `revised (post-approval)` → executed | 5 `complete`, or blocked with reason and risk |
| `testing-implementation.md` | 5 | living, written as you go | assembled for the PR comment, never a source comment |
| `pr-draft.md` | 2 — shell only | 5 — body filled | — |
| changelog | pre-existing or scaffolded at 0 | 2 Plans row → 4 staged → 5 `active` + session log → 6 `implemented` | canonical record |
| `dnu/` | on first supersession | names unchanged, never deleted | — |

## Where the returns are

| Return | Trigger | What happens |
| --- | --- | --- |
| Plan phase → next Working phase | Phases 1 and 4 cannot write to disk | the approved recon-and-plan doc, staged why-log entries, story reconciles, coverage rows, ledger rows, the Phase 4 changelog Plans row, and the deferred notification all land as the next Working phase's first action |
| `why-these-changes.md` ← every phase | the why moved | why-log entry labeled with the phase and whether it is new understanding, a course change, or a discarded path; unchanged is fine, unlogged is not |
| `stories/` ← Phases 1–2 | the investigation answers a question or invalidates a criterion | revise in place while `draft`, with a Story log entry naming what moved |
| `stories/` ← Phase 5 | a criterion proves unobservable in practice | the story moves to `dnu/` and the next version is written — never reinterpret a criterion to match what was built |
| `investigation.md` ← after done | a fast-follow answer, a live-DOM proof, a corrected assumption | append a numbered addendum §13+, dated and evidenced; never rewrite the verdict or earlier sections in place |
| `test-plan.md` ← Phase 5 | the approved plan differs from what the spec proposed | quick revision before implementation; status `revised (post-approval)` |
| `locked-decisions.md` ← Phase 3 | an approach replaces an earlier one | the old row is marked superseded and the new one added — never a silent overwrite |
| Earlier phase ← entry check | a prior phase row does not read `done` or `skipped (reason)` | stop and close the gap before doing any work in Phase 2 or later |
| `orchestration.md` ← resume | the ledger disagrees with what is on disk | disk facts win — flag the discrepancy, correct the ledger, continue from the corrected state |
| `stories/` ← Phase 4 | a plan step traces to no acceptance criterion | either a criterion is missing or the step is out of scope — record which, staged for the Story log if the story has to move |
| Any phase ← you | "redo phase N" or "skip to phase X" | the override is recorded in the ledger notes; orchestration continues from the adjusted state |
| A phase ← a deliberate skip | you explicitly instruct it | ledger records `skipped (<your reason>)` **and** names the downstream inputs now missing — skipping Phase 1 leaves the spec uninvestigated, skipping Phase 3 leaves implementation without locked decisions |
| An existing artifact ← re-invocation | the ticket folder already holds that artifact | exactly three options offered — reuse as-is, refresh in place, or move to `dnu/` and redo; `original-ticket.md`'s Original Request is never rewritten regardless of choice |
| `orchestration.md` ← a pre-skill ticket | artifacts exist but no ledger does | reconstruct the ledger from disk, show it, and get your confirmation before proceeding |
| Advance blocked ← gate | a required artifact, ledger row, or evidence is missing | state what is missing and complete it before advancing |

## Coverage of `agents/docs`

Every playbook in `agents/docs/`, and where the orchestration uses it. Rows marked **out** are deliberate, not oversights.

| Doc | Role | Phase |
| --- | --- | --- |
| `original-ticket-artifact.md` | template for the verbatim capture | 0 |
| `browser-loop-setup.md` | authenticated-session recipe for ClickUp capture | 0 |
| `problem-check.md` | framing lens, embedded in method Step 1 | 1 |
| `investigation-software-gaps.md` | mandatory software lens | 1 |
| `investigation-coverage-ledger.md` | consult protocol + ledger shape | 1–2 |
| `investigation-report.md` | report template | 2 |
| `investigation-diagrams.md` | standalone diagrams artifact | 2 |
| `current-vs-target-diagram.md` | the delta-diagram convention, reached through `investigation-diagrams.md` rather than loaded directly | 2 |
| `test-plan-artifact.md` | test-plan shape and status vocabulary | 2 |
| `future-development-concerns.md` | risk-record artifact | 1–4 |
| `qa-to-spec-traceability.md` | question-gate workflow for grill-me | 3 |
| `wiki-spec-authoring.md` | naming and vault wiring when a PRDV spec routes to the wiki | 3 |
| `new-branch-get-started.md` | branch step | 4 |
| `testing-implementation-artifact.md` | scenario-first record for the PR comment | 5 |
| `pull-request-workflow.md` | PR shell at 2, filled body and commit-hash block at 5 | 2, 5 |
| `ticket-changelog-workflow.md` | changelog paths, Plans rows, session log | 0, 2, 5, 6 |
| `why-these-changes.md` | the living why doc | 1–6 |
| `cleanup-candidates.md` | cruft-check destination | 6 |
| `investigation-question-coverage.md` | **out** — meta-audit of the method, not an operational input | — |
| `ticket-orchestration.md` | **out** — superseded pointer to this skill | — |
| `session-start.md` | **out** — optional human opener, not an agent input | — |
| `workflow-index.md`, `README.md` | **out** — navigation indexes | — |
