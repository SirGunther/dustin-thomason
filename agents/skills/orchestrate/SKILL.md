---
name: orchestrate
description: Conduct a ticket end-to-end through the seven-phase lifecycle — capture original ticket, investigate, report, probe and spec, prep for implementation, implement, manual review — with full-rigor artifacts, phase exit gates, and a standardized handoff at every mode boundary. Resumable from the per-ticket ledger. Use when the user says "orchestrate", "orchestrate PRDV-XXXXX", "run the ticket workflow", "take this ticket through the phases", or "resume/continue orchestration".
---

# Orchestrate — end-to-end ticket lifecycle

Drive one ticket through all seven phases with maximum traceability, correctness, and completeness. This is the **full-rigor, opt-in** version of ticket work: invoking it means the user wants every artifact and every gate — do **not** scale the ceremony down because the ticket looks small. The user decides whether to invoke this; you do not decide to abbreviate it.

**DO NOT PULL IN MODULES UNLESS ABSOLUTELY NECESSARY. WE WANT CONTEXT TO BE SIGNAL, NOT NOISE.**
Load only the current phase's listed inputs plus the orchestration ledger. Never preload later phases' references.

## Visible progress — maintain a running todo list

Harness step-visibility differs: Cursor's plan mode shows a checklist natively, but the Codex and Claude Code harnesses surface no step list during a working run. So **maintain an explicit todo list visible in the chat regardless of harness**, and check items off as you complete them — this is the user's window into where the run is. Use the harness's native todo tool where one exists; otherwise print the checklist inline. Keep one item in progress at a time; refresh it at every phase transition and every gate. At minimum the list carries one item per phase (0–6) plus the sub-steps of the phase currently in progress. This is a quality-of-life requirement, not optional narration.

## The ticket's Why (living doc — every phase)

The ticket carries a living **"Why" doc** (`<slug>-why-these-changes.md`, per `../../docs/why-these-changes.md`) — the overarching *why* of the whole ticket, whose heart is the **class of problem** being solved. It is **created early (Phase 1)** so the understanding is established before the work runs ahead of it, and it is **always open for update through every phase**. At each phase, check whether the why moved — the problem, the class, the bug, the code, an assumption — and if it did, **log it in the why-log, explicitly labeled with the phase and whether it's a new understanding, a course change, or a discarded path**. Capture the reasoning trail (what was obvious, what wasn't, what changed after learning more, what got us to the solution, what was noise), not just conclusions. This is high-level and distinct from the testing-implementation doc's scenarios. If nothing moved in a phase, that is fine; an *unlogged* change is not.

## The ticket's acceptance criteria (living doc — every phase)

The ticket's **job stories** (`stories/`, per `../job-story/SKILL.md`) are the yardstick the finished work gets held against — a User Story and Acceptance Criteria for each distinct problem in the request. They are **drafted at Phase 0** from the verbatim request alone (they do not wait on the investigation), **accepted at Phase 3** once their open questions close against the locked decisions, and **open for revision at every phase in between**.

Same discipline as the why-log: at each phase, check whether a story moved — a criterion added or reworded, an open question closed, a story split, a user type corrected — and if it did, append a **Story log** entry labeled with the phase. Nothing moving in a phase is fine; an *unlogged* change is not. While a story is `draft`, revise it in place; once `accepted`, move it to `dnu/` unchanged and write the next version.

The story owns *what done means*; the spec owns *how it gets built*. Investigation artifacts (Problem Check, report §8/§10) are peer inputs that inform the stories — never the authority on their criteria. Where a story and a spec disagree on what done means, the story wins or the story changes on the record — never both quietly.

## Invocation and inputs

Resolve the ticket in this order:

1. **`PRDV-XXXXX` id** → `<Project>` is the system (atlas / callisto / europa / triton / …) resolved per the `ticket-changelog` rule; the ticket changelog lives at `docs/<system>/PRDV-XXXXX-changelog.md`.
2. **Project + slug** (e.g. "orchestrate WorkLists duplicate-card-option") → `docs/<Project>/tickets/<slug>/`.
3. **Free brief, no id** → derive `<slug>` from the brief (kebab-case, at most six words); ask once for `<Project>` if it is not inferable from the working directory or branch.
4. **Nothing** → ask exactly one question: "Paste the ticket/request text (or id) and name the project." Never fabricate or paraphrase a ticket into existence.

If the ticket folder already exists, follow **State ledger and resume** below instead of starting fresh.

## Ticket folder layout

Every artifact this skill produces lives in one canonical layout, rooted at **`C:\dustin-thomason\docs\<Project>\tickets\<slug>\`** — organized, obvious by filename:

```text
docs/<Project>/tickets/<slug>/            (always under the dustin-thomason repo — see Repo boundary below)
  original-ticket.md                              Phase 0
  orchestration.md                                phase-state ledger (Phase 0 scaffolds)
  <slug>-why-these-changes.md                     Phase 1 created → updated every phase (why-log) → Phase 6 finalized
  <slug>-future-development-concerns.md           Phases 1–4, created on first concern only
  <slug>-pr-draft.md                              Phase 2 shell (empty template) → Phase 5 filled
  stories/
    <slug>-job-stories-index.md                   Phase 0 created → updated whenever a story moves
    <slug>-job-story-<NN>-<short>.md              Phase 0 draft → revised Phases 1–2 → accepted Phase 3
  investigations/
    <slug>-recon-and-plan.md                      Phase 1 approved → saved verbatim at Phase 2's first action, then frozen
    <slug>-investigation.md                       Phase 2 (§13+ addenda appended, never rewritten — see Phase 2)
    <slug>-coverage-ledger.md                     Phases 1–2
    <slug>-diagrams.md                            Phase 2
  specs/
    <slug>-spec.md                                Phase 3
    <slug>-locked-decisions.md                    Phase 3 — standard once decisions exceed a handful (see Phase 3)
  testing/
    <slug>-test-plan.md                           Phase 2 seed → Phase 3 refine → Phase 5 revise (after approval, before impl) → execute
    <slug>-testing-implementation.md              Phase 5 — scenarios stress-tested (+ any change hung off each), for the PR comment
  dnu/                                            superseded artifacts move here, names unchanged
```

PRDV tickets may prefix artifact filenames with `PRDV-XXXXX-` instead of the slug; personal projects use the slug. Superseded or redone artifacts **move to `dnu/`** — never deleted, never renamed.

## Repo boundary (docs vs implementation)

**Every orchestration artifact lives in `dustin-thomason`, always — never inside the implementation repo or folder, regardless of where `<Project>`'s actual code lives.** This mirrors the `ticket-changelog` rule's boundary ("all changelog and Plans data stays in this repo"). A ticket whose code lives at `C:\Users\<user>\...\Browser Extensions\<Project>\` or in an app repo like `atlas-front-end` still gets its `original-ticket.md`, ledger, report, spec, and every other artifact under `C:\dustin-thomason\docs\<Project>\tickets\<slug>\`.

The implementation location is **recorded**, not used as a docs root: capture it in `original-ticket.md`'s Context Paths and in the orchestration ledger's Artifacts column (Phase 5 onward) when code changes land there. If the target repo has no `.git` (e.g. a loose extension folder), say so in the ledger notes and skip the branch step — do not relocate docs there instead.

If this boundary is ever unclear at invocation (a free brief naming a folder that could be mistaken for the docs root), ask once before creating anything — this was reached only by a live user correction in a prior run, not caught by the skill itself.

## The phase map

| Phase | Name | Mode | Output artifacts | Advance |
| --- | --- | --- | --- | --- |
| 0 | Capture | Working | `original-ticket.md`, `orchestration.md`, job stories (draft) + index | gate → HANDOFF (Plan) |
| 1 | Recon and plan | Plan | approved recon-and-plan doc (findings + emission todos + staged coverage rows) | gate → plan approval |
| 2 | Report | Working | investigation report, coverage ledger, diagrams, test-plan seed | gate → AUTO-ADVANCE to 3 |
| 3 | Probe & spec | Working | locked-decision ledger, accepted job stories, spec, refined test plan | gate → HANDOFF (Plan) |
| 4 | Prep | Plan | approved implementation plan | gate → plan approval |
| 5 | Implement | Working | code, executed test plan, session log, PR | gate → HANDOFF (Idle) |
| 6 | Manual review | Idle | review summary, cruft check, closed ledger | END |

## Mode handling (harness-agnostic)

- **Never assume you can switch Plan/Working modes.** Cursor and Codex have no agent-callable switch; mode is the user's.
- **Claude Code exception:** if a plan-mode tool (EnterPlanMode) is available in the session, you MAY use it to cross a Working→Plan boundary without stopping — but still print the handoff block first, so the ledger and the user stay synchronized.
- Handoff boundaries: 0→1, 3→4, 5→6. The 1→2 and 4→5 boundaries are crossed by **plan approval** itself (approving the plan is the handoff) — print the phase gate at the start of the following phase instead.
- Same-mode boundary 2→3: **auto-advance, no stop** — but the Phase 2 exit gate still prints.
- **Open, untested assumption — whether scripts/messages can run *while in* Plan mode at all** (some harnesses restrict non-readonly tool calls, including shell/Bash, during Plan mode). Status: open. Confirm/revise by: attempt a script call while genuinely in Plan mode in each harness in use and record the observed result (allowed / blocked / silently no-op) as a coverage-ledger or ledger-notes entry. Until confirmed either way, the design below never depends on running anything during a Plan phase — see Progress notifications.

## Progress notifications

**Because handoffs stop and wait, and the user may not be watching, every phase completion sends a push notification** — not only Phase 6 — per the `agent-completion-notification` rule. This directly works around the open Plan-mode question above rather than resolving it: notifications are sent only from **Working**-mode moments, never attempted from inside a Plan phase.

- **Working-phase completions (0, 2, 3, 5, 6) notify immediately**, before printing that phase's handoff block (or, for the auto-advancing Phase 2, alongside its printed gate).
- **Plan-phase completions (1, 4) defer their notification** to the first action of the next Working phase, batched with that phase's own "starting" notice — the same deferred pattern already used for their ledger writes (`deferred (plan mode)`).
- Resolve the dustin-thomason repo root the same way `agent-completion-notification` does, then run (adjust for cwd):

  ```powershell
  # from the dustin-thomason repo root
  .\scripts\notify-agent-complete.ps1 -Status "Completed" -Message "<Project>/<slug>: Phase <N> done, next is Phase <M> (<mode>)"

  # from elsewhere in the workspace (e.g. the implementation repo)
  & "<dustin-thomason>\scripts\notify-agent-complete.ps1" -Status "Completed" -Message "<Project>/<slug>: Phase <N> done, next is Phase <M> (<mode>)"
  ```

## The handoff block

At each handoff boundary, emit this block verbatim with values filled, **then stop — output nothing after it**:

```text
==================== ORCHESTRATION HANDOFF ====================
Ticket:        <Project>/<slug>
Phase done:    Phase <N> — <name>
Artifacts:     <repo-relative paths | n/a>
Ledger:        docs/<Project>/tickets/<slug>/orchestration.md (updated)
Next phase:    Phase <M> — <name>
Required mode: <Plan | Working | Idle>
Your move:     Switch to <mode> mode and say "go".
               Already in <mode>? Just say "go".
               Also accepted: "skip to phase <X>" | "redo phase <N>"
===============================================================
```

## Phase exit gates (stop-gaps — every phase, including auto-advance)

Agents deprioritize instructions they judge redundant. These gates exist to stop that. Before advancing out of ANY phase, verify and **print** a gate check:

```text
Phase <N> gate:
- Artifacts on disk: <each required path — exists / MISSING>
- Ledger row updated: <yes / deferred (plan mode) / MISSING>
- Why-log: <updated this phase, labeled | unchanged this phase | deferred (plan mode)>
- Story log: <moved this phase, labeled | unchanged this phase | deferred (plan mode)>
- Phase evidence: <the phase-specific proof named below>
```

A failed gate blocks the advance — state what is missing and complete it first. Confidence is not a substitute for the check. Plan-mode phases (1, 4) cannot write files; their ledger rows and file outputs are written as the **first action** of the next Working phase, and the gate says `deferred (plan mode)`.

**Entry check — before touching anything, not just before leaving.** A prior orchestrated run edited implementation-repo files during Phase 0/1, before capture and investigation existed, and was only caught because the user noticed and reverted it — the gate above didn't stop it, because it only checks a phase on the way *out*. Before doing **any** work in Phase 2 or later, confirm every earlier phase's ledger row reads `done` or `skipped (reason)` — if it does not, stop and close the gap first. Concretely: do not create, edit, or run anything in the target implementation repo/folder until Phase 0 and Phase 1's gates have both printed `done`. Do not mark a phase `done` in the ledger — especially Phase 5 — on the strength of drafted code or an unproven claim; `done` means the phase's own gate evidence is real, not pending (this was also missed once: implementation was nearly called complete before live proof existed, per Phase 5's own evidence requirement below).

## State ledger and resume

`orchestration.md` is scaffolded at Phase 0 from this template:

```markdown
# Orchestration — <Project>/<slug>

| Phase | Status | Artifacts | Date | Notes |
| --- | --- | --- | --- | --- |
| 0 Capture | pending | | | |
| 1 Recon and plan | pending | | | |
| 2 Report | pending | | | |
| 3 Probe & spec | pending | | | |
| 4 Prep | pending | | | |
| 5 Implement | pending | | | |
| 6 Manual review | pending | | | |

Resume: Phase 0 — Working mode
```

Status vocabulary: `pending` / `in-progress` / `done` / `skipped (reason)` / `redone (see dnu/)`. Update the row and the `Resume:` footer at every phase transition (deferred to the next Working action for plan-mode phases).

**Resume protocol** — when invoked and the ticket folder already exists:

1. Read `orchestration.md`; **verify against disk** (do the listed artifacts exist?). Disk facts win — flag any discrepancy, correct the ledger, continue from the corrected state.
2. Announce a one-line status ("Phases 0–2 done; next: Phase 3, Working mode") and emit the handoff block for the next phase.
3. Ledger missing but ticket artifacts exist (pre-skill ticket): reconstruct the ledger from disk, show it, get the user's confirmation before proceeding.
4. Neither exists: fresh Phase 0.

---

## Phase 0 — Capture the original ticket (Working)

- **Reads:** `../../docs/original-ticket-artifact.md`; `../job-story/SKILL.md` (execute it for the job stories below); the canonical changelog per the `ticket-changelog` rule (task-start alignment — resolve or scaffold it; personal projects use `docs/<project>/`'s project changelog). For ClickUp-backed tickets, also read `../../docs/browser-loop-setup.md` and load the browser-loop guardrails before using Playwright/browser observation.
- **Do:**
  1. Create the ticket folder in the canonical layout.
  2. For ClickUp-backed tickets, use Playwright/browser observation as the preferred capture path: open the active ClickUp ticket page, identify the visible ticket fields and metadata from the rendered UI, and export the captured ticket to Markdown as `{ticket-id}-original-ticket.md`. Use API access only as a fallback or cross-check, not as the default source of truth. **ClickUp requires an authenticated session** — a freshly Playwright-launched browser context has no login and cannot see the page. Attach to a real, already-logged-in Chrome instead, per browser-loop-setup.md's "Attaching to an authenticated browser session" recipe; do not attempt a fresh headless/incognito launch against ClickUp and fall back to guessing selectors when it fails to load — that already happened once and cost a manual recovery.
  3. Create `original-ticket.md` (or `{ticket-id}-original-ticket.md` for PRDV tickets) per the artifact doc — the request **verbatim**, capture metadata, explicit constraints, context paths. No findings, no recommendations.
  4. **Draft the job stories** per `../job-story/SKILL.md` — synthesize the verbatim request, split it into one story per distinct problem, run the full sequence, and write `stories/` plus its index with each story `draft`. Anything the request left undecided becomes that story's Open Questions; do not decide it here. This is the acceptance-criteria baseline every later phase is measured against, and it is established **before** the investigation so the investigation cannot quietly define what done means.
  5. Scaffold `orchestration.md` from the template above; mark Phase 0 `done`.
  6. Align with the changelog's Current state / Plans / Attempt history before anything downstream.
- **Gate evidence:** original-ticket artifact Original Request section is verbatim; ClickUp capture path or user-provided source is named; at least one job story exists at `draft` with its index row, and no criterion names a design element; changelog named; no implementation-repo file has been touched yet.
- **Advance:** notify (Progress notifications), then handoff → Phase 1 (Plan).

## Phase 1 — Recon and plan (Plan)

**What this phase is.** Not planning where to look — **recon**. Plan mode is used as the operative method for collecting methodically: the agent reads the ticket text and traces the code, reaches its findings, and emits them as a written plan you approve. The name matters because it sets the right expectation — by the time you see the plan, the looking is done, and what you are approving is a set of findings plus the plan to record them. That is deliberate: the approval sits at the last moment before any durable artifact is written, and the first moment there is something substantive to judge. A misdirected recon costs one pass and leaves nothing wrong on disk; a misdirected write-up costs every artifact downstream that cites it.

**The plan is the durable carrier.** Plan mode's output is a written document, not working memory — that is what makes this phase's findings survivable. It must carry the **findings**, not just the emission todos, so Phase 2 is re-derivable from it if context is lost. It is saved verbatim as `investigations/<slug>-recon-and-plan.md` at Phase 2's first action and **frozen** thereafter, the same way `original-ticket.md`'s Original Request is: later deviation is recorded where deviation belongs — a coverage-ledger reopen reason, or a why-log course change — never by editing the approved plan.

- **Reads:** `../investigation/SKILL.md` (execute it — this phase IS that method, run inside this orchestration); `../../docs/investigation-software-gaps.md` (**mandatory software lens** for software-domain tickets: contract alignment, surface enumeration, protect-the-neighbors, detection gap, red→green test, repro recipe); `../../docs/investigation-coverage-ledger.md` (the consult protocol). Problem Check is already embedded in the method's Step 1 — do not load it separately. Do **not** load `investigation-question-coverage.md` (meta-audit, not an operational input).
- **Do:**
  1. **Consult prior coverage ledgers FIRST** — before opening any investigative branch, run the consult protocol (grep `docs/<Project>/tickets/*/investigations/*-coverage-ledger.md` for the subsystems in play). Reuse covered ground; reopen only per the four reopen conditions, with the reason recorded. Stage the mandatory consult log line for the ledger.
  2. Execute the investigation method steps 1–7 on the ticket (everything but the emit). Two disciplines this phase must not skip: (a) the **Problem Check lens** (method Step 1) — its Asked / Answered / Should-ask + Conflation / Thin / Off findings, each grounded in a trimmed quote from the ticket text ("nothing here" is a valid flag, silence is not), carry into report §2; (b) the **Step 7 reconcile** — classify every open question on the fact-vs-decision axis, resolve the code-discoverable ones by tracing the evidence *now*, and for any question the current structure genuinely can't answer, capture the code evidence that proves why. Stage coverage rows (area, items inspected, findings, status, commit) as you traverse — they become the coverage ledger in Phase 2.
  3. Build the recon-and-plan doc. It records **the findings this recon reached** — problem class, what was inspected and ruled out, the facts resolved by evidence, the decisions left open with owners — and then the todos to: reconcile against every point of the software lens; emit the report per the template; materialize the coverage ledger (with the consult line); produce the diagrams artifact per `../../docs/investigation-diagrams.md`; seed the test plan per `../../docs/test-plan-artifact.md`; record any surfaced concerns per `../../docs/future-development-concerns.md`. Findings-plus-todos, not todos alone — a plan a later agent could execute after losing all context.
  4. **Surface the ticket's Why early.** Establish the **class of problem** and the high-level problems we're solving, and stage the Phase 1 why-log entry (obvious / not obvious / assumptions) for `<slug>-why-these-changes.md` (per `../../docs/why-these-changes.md`). This is the heart of the Why doc — get it on the record before the work runs ahead of the understanding. Plan mode can't write, so the file is materialized at Phase 2's first action.
  5. **Reconcile the job stories against what the investigation surfaced.** Problem Check's Thin and Conflation flags and the Step 7 fact-vs-decision split are peer inputs to the stories, not their source of truth. Stage: open questions the investigation answered, criteria a finding invalidates, and any story that has to split. Plan mode can't write, so these land at Phase 2's first action.
- **Gate evidence:** the plan carries this recon's findings — not todos alone — such that Phase 2 could be executed from it with no other context; the plan contains the consult results and the reconcile-per-lens todos; the Problem Check pass is present (flags may read "nothing here"); every open question is split into facts (resolved via evidence) vs decisions (owner) — no code-discoverable fact left parked as a decision; open variables have owners; the problem class and Phase 1 why-log entry are staged for the Why doc; the job-story reconcile is staged (or explicitly "no story movement this phase").
- **Advance:** plan approval (this is the handoff). Ledger row updates and the deferred Phase 1 notification both fire at Phase 2's first action.

## Phase 2 — Investigation report (Working)

- **Reads:** the approved plan; `../../docs/investigation-report.md` (template); `../../docs/investigation-diagrams.md`; `../../docs/test-plan-artifact.md`.
- **Do:**
  1. Update the ledger (Phase 1 `done`, Phase 2 `in-progress`), and materialize the deferred Phase 1 writes: save the approved plan verbatim as `investigations/<slug>-recon-and-plan.md` (frozen once written — see Phase 1); create `<slug>-why-these-changes.md` (problem class + Phase 1 why-log entry) per `../../docs/why-these-changes.md`, and apply the staged job-story reconcile — revised criteria, closed questions, any split — with a Phase 1 Story log entry on each story touched.
  2. Write `investigations/<slug>-investigation.md` from the template — this path **overrides** the template's default `docs/investigations/` location for orchestrated tickets. The report **links out** to the diagrams artifact from §5; do not embed large diagrams inline.
  3. Materialize `investigations/<slug>-coverage-ledger.md` — Consulted line first, then every staged area entry, then the Not-yet-inspected frontier.
  4. Produce `investigations/<slug>-diagrams.md` — current-vs-target, flows, sequences (race conditions and timing edge cases) as applicable; N/A lines for kinds skipped.
  5. Seed `testing/<slug>-test-plan.md` from report §9 — each seeded scenario names the acceptance criterion it exercises, or is flagged as coverage with no criterion behind it yet.
  6. **Stage the PR draft shell** `<slug>-pr-draft.md` — headings and empty placeholders only, from the PR template in `../../docs/pull-request-workflow.md` (title, ClickUp link, Description, Test Evidence, Commit hash, Checklist). Get the head start, but **draft the shell, not the content**: the body is filled in Phase 5 after testing, because scope can still move in Phases 3–4. Leave a one-line note at the top that it is an unfilled shell.
  7. Add a Plans row to the changelog. Do **not** touch `original-ticket.md` — it is immutable once captured, and the files this phase produced are recorded in the ledger's **Artifacts** column instead.
- **Gate evidence:** consult log line present in the coverage ledger; report §5 links (not embeds) the diagrams; report §2 Problem Check subsection is filled with quote-grounded findings (or explicit "nothing here" per flag) and the §1–§2 framing claims cite ticket-text quotes, not only code; §8/§10 route facts vs decisions per Step 7; every story Open Question appears in §10 or was closed with the evidence that closed it; test plan status `seeded`; PR draft shell staged (shell only, body unfilled).
- **Advance:** notify (Progress notifications; deferred Phase 1 notice batches in here too), AUTO-ADVANCE to Phase 3 (same mode) — print the gate, keep going.
- **Reopening a "done" report:** if later work (a fast-follow answer, a live-DOM proof, a corrected assumption) needs to change this report after it's marked done, **append a numbered addendum section** (e.g. "§13. Post-Investigation Addendum — <what>") dated and evidenced — never rewrite the verdict or earlier sections in place. This preserves the original reasoning trail the same way the coverage ledger and locked-decision ledger already do.

## Phase 3 — Probe and spec (Working)

- **Reads:** report §8 (assumptions) + §10 (open variables); the job stories' Open Questions (`../job-story/SKILL.md`); `../grill-me/SKILL.md`; `../../docs/qa-to-spec-traceability.md`; the `spec-writing` rule (loads automatically; PRDV app tickets may route through `../write-spec/SKILL.md` and the wiki conventions — ask once: sibling spec or wiki).
- **Do:**
  1. **Before grilling, re-run the Step 7 reconcile on the current open variables.** Any question whose answer is discoverable in the code/source — trace it and resolve it yourself via evidence; do not bring a fact to the user to "decide" when the codebase already answers it. Where a question bundles a discoverable fact with a decision, split it: you answer the fact, the user decides the rest. Only genuine decisions reach grill-me.
  2. Run grill-me against the report's remaining open variables and assumptions **and every job story's Open Questions** — **under the qa-to-spec-traceability workflow**: question gate before each question, one question at a time, each answer committed to the locked-decision ledger before the next, rejected paths recorded.
  3. Risk-accepting answers produce BOTH records: the locked-decision row and a concern entry in `<slug>-future-development-concerns.md` (create on first concern); the row cites the entry.
  4. **Accept the job stories.** Fold every resolved decision into the criteria it affects, close each story's Open Questions (or carry one forward with a named owner and the reason), set the index rows to `accepted`, and append the Phase 3 Story log entry. A decision wins on *how*; the criterion still owns *what done means* — rewrite it to stay observable rather than importing the design word the decision introduced.
  5. Materialize the locked-decision ledger as its own file, `specs/<slug>-locked-decisions.md` (question gates resolved + the full `LD-###` table with source / supersedes-or-rejects / spec destination) — the standard from the first real run, once decisions run past a handful the way they will on any non-trivial ticket. Write `specs/<slug>-spec.md`: grill-me output **informs** the spec, it is not the spec. Its required `Locked Decisions From Q and A` section (per `spec-writing` / `qa-to-spec-traceability`) becomes a short summary table that **links to** `<slug>-locked-decisions.md` for the full ledger, rather than repeating it — satisfy the spec-writing rule's sections (N/A lines where a section does not apply); frame Problem → Requirement → Solution.
  6. Refine the test plan — resolved variables become concrete assertions, each mapped to the acceptance criterion it proves; status `refined`.
- **Gate evidence:** spec's locked-decisions section links to a `<slug>-locked-decisions.md` whose ledger traces every entry to a source; no locked decision remains open; supersessions are recorded (never a silent overwrite); every job story is `accepted` (or names the owner of a still-open question) and the spec **cites** the stories' acceptance criteria rather than restating or amending them; audit per the traceability doc's definition of done.
- **Advance:** notify (Progress notifications), then handoff → Phase 4 (Plan).

## Phase 4 — Prep for implementation (Plan)

- **Reads:** the spec; report §11 (handoff table); the test plan. **No re-investigation** — plan from the artifacts.
- **Do:** build a brief implementation plan: Problem → Requirement → Solution framing; ordered steps; branch step per `../../docs/new-branch-get-started.md` when repo work begins; test execution mapped to the test plan; the shipping checklist obligations (tests, regression, API docs, gates) named up front per the `build-implementation-guardrails` rule.
- **Gate evidence:** every plan step traces to spec/report/test-plan **and to an acceptance criterion** — a step tracing to no criterion is either a missing criterion or out of scope, and which one it is gets recorded (staged for the Story log when the story has to move); a Plans row for this plan is staged for the changelog.
- **Advance:** plan approval (this is the handoff). Ledger + changelog Plans row update, and the deferred Phase 4 notification, all fire at Phase 5's first action.

## Phase 5 — Implement (Working)

- **Reads:** the approved plan; the test plan; repo-specific rules of the touched repo.
- **Do:**
  1. Update the ledger; add the changelog Plans row (`active`).
  2. **Revise the test plan — after approval, before implementation.** The implementation plan is approved (Phase 4) but no code is written yet; at this junction do a quick revision/refinement of the test plan (`testing/<slug>-test-plan.md`) so it matches what was actually approved — the approved plan can differ from what the spec proposed. Test plan only; a quick pass, not a rebuild. Set status `revised (post-approval)`.
  3. Implement per the plan, inside the `build-implementation-guardrails` obligations (tests as part of shipping, architecture fit, graceful degradation by layer).
  4. Execute `testing/<slug>-test-plan.md`: check off scenarios, fill the results log with exact command + scope + result (serial runs). A criterion that turns out to be unobservable in practice failed its own review — move that story to `dnu/`, write the next version, and log it; never reinterpret a criterion to match what was built.
  5. **Maintain the testing-implementation doc** `testing/<slug>-testing-implementation.md` per `../../docs/testing-implementation-artifact.md` — **scenario-first**: each real situation stress-tested (why it matters, whether it held), newly-uncovered scenarios flagged, and any code change hung off the scenario that forced it (file(s) + observed → expected → fix). This is the artifact that explains to other devs *what was addressed* — a test with no scenario is arbitrary execution. Write it as you go; living doc. PR-comment content, never a source comment (guardrails §7).
  6. If a PR draft shell was staged in Phase 2, fill it now (title, description, test evidence, commit hash) per `../../docs/pull-request-workflow.md` — paste the testing-implementation doc's assembled block as the PR comment / test-evidence. Before every commit: changelog session log, then audit → lint → tests per the `git-commit-workflow` rule. PR per `../../docs/pull-request-workflow.md` when requested.
- **Gate evidence:** test plan status `complete` (or blocked items carry reason + residual risk + follow-up); testing-implementation doc records the scenarios stress-tested (each in dev-legible terms, newly-uncovered ones flagged) with any change hung off its scenario, assembled for the PR comment and not copied into source; session log written; gate results reported as a table. **Do not mark this phase `done` on drafted-but-unproven code** — the evidence must be an actual observed result (a run, a manual check, a passing suite), not a claim of what should happen.
- **Advance:** notify (Progress notifications), then handoff → Phase 6 (Idle).

## Phase 6 — Manual review (Idle)

- **Do:**
  1. **Finalize the Why doc:** complete the reviewer-facing review in `<slug>-why-these-changes.md` — the **categorized change breakdown** (requested change / bug fix / workflow change / capability gap / other, with a headline count and Before / After / Why per change), **"why it shipped together"** tied to the acceptance criteria, **Scope**, **Net**, and **Verified** (gates + PR link). Confirm the why-log captured every phase where the why moved.
  2. Produce the review summary: what to review, where, **walking each acceptance criterion against what shipped**, citing the test plan's results log and the Why doc — no unfalsifiable "tests passed" claims.
  3. **Cruft check:** did this run surface outdated references, superseded docs, or dead weight? Append findings to `../../docs/cleanup-candidates.md`; write "cruft check: nothing surfaced" in the ledger notes if clean.
  4. Close the ledger: Phase 6 `done`, `Resume: complete`; set the changelog Plans row to `implemented` when the work landed; append each story's final Story log entry and confirm every index row reads `accepted` or `superseded (see dnu/)`.
  5. Notify per Progress notifications — this is the final one, matching the standard `agent-completion-notification` rule usage.
- **Advance:** END. The user reviews manually; you are done.

---

## Edge cases

- **Personal projects (WorkLists, Countdowns, OtterCopy, …):** `<Project>` = the `docs/<project>/` folder name; changelog = that project's changelog per the `ticket-changelog` rule; the spec stays the sibling `specs/<slug>-spec.md` (wiki routing is PRDV-only). If `docs/<Project>/` does not exist, ask once, then create it at Phase 0.
- **No ticket text at invocation:** Phase 0 blocks on the verbatim request — ask the one question; never synthesize the request.
- **Deliberate skip:** only on the user's explicit instruction. Record `skipped (<user's reason>)` in the ledger AND name the downstream inputs now missing (skipping Phase 1 leaves the spec uninvestigated; skipping Phase 3 leaves implementation without locked decisions). Never skip on your own initiative, never silently.
- **Artifact already exists:** compare the ledger status and dates, then offer exactly three options — **reuse** as-is, **refresh** in place, or **move to `dnu/`** and redo. `original-ticket.md`'s Original Request section is never rewritten regardless of choice.
- **Conflicting instructions mid-flow:** the user can always override a phase's course — record the override in the ledger notes; the orchestration continues from the adjusted state.

## Do not

- Do not assume you can switch modes; do not proceed past a handoff block.
- Do not skip a phase, a gate, or an artifact silently — the ledger records everything, including waivers.
- Do not scale artifacts down because the ticket seems small — invocation of this skill IS the request for full rigor.
- Do not load later phases' docs early, and do not reload docs already embedded in a method you are executing.
- Do not modify `original-ticket.md` after Phase 0 captures it — not the Original Request, not any other section. Files the run produces are recorded in the ledger's Artifacts column.
- Do not edit `investigations/<slug>-recon-and-plan.md` once it is saved — it records what was approved; deviation goes in the coverage ledger's reopen reason or the why-log, not into the plan.
- Do not leave Phase 0 without at least one drafted job story — the acceptance-criteria baseline is set before the investigation, not derived from it.
- Do not treat an investigation artifact as the authority on acceptance criteria; the job story owns what done means, and the spec cites it rather than amending it.
- Do not reinterpret a criterion to match what was built — move the story to `dnu/` and write the next version.
- Do not let a story move without a Story log entry naming what changed.
- Do not put the orchestration ledger anywhere except the ticket folder.
- Do not emit anything after a handoff block.
- Do not put any orchestration artifact outside `C:\dustin-thomason\docs\<Project>\tickets\<slug>\`, even when the implementation lives in a different repo or folder — see Repo boundary.
- Do not touch implementation-repo files before Phase 0 and Phase 1 both show `done` in the ledger.
- Do not mark a phase `done` — Phase 5 especially — on a claim or drafted code; the gate evidence must be an observed result.
- Do not rewrite a "done" investigation report to incorporate later findings; append a dated addendum section instead.
- Do not assume a notification or script can run while genuinely in Plan mode; use the deferred-to-next-Working-action pattern in Progress notifications instead.
- Do not skip the Problem Check pass or leave its framing claims ungrounded — cite the ticket's words; "nothing here" per flag is fine, silence is not.
- Do not park a code-discoverable fact as an open-variable "for discussion," and do not bring it to the user to decide — trace it and resolve it via evidence (§8); only genuine decisions go to the user.
- Do not run without a visible, checked-off todo list where the harness does not surface one.
- Do not fill the PR draft body before Phase 5 — Phase 2 stages the shell only; content waits until the change is implemented and verified.
- Do not put change rationale (observed → expected → fix) in a source comment; it is PR-comment content (guardrails §7).
