# agents-skills (generated — do not edit)

Source: `agents/skills/**`. Regenerate with `.\agents\scripts\sync-rules.ps1`.

## grill-me/SKILL.md

---
name: grill-me
description: Interview the user relentlessly about a plan or design until reaching shared understanding, resolving each branch of the decision tree. Use when user wants to stress-test a plan, get grilled on their design, or mentions "grill me".
---

Interview me relentlessly about every aspect of this plan until we reach a shared understanding. Walk down each branch of the design tree, resolving dependencies between decisions one-by-one. For each question, provide your recommended answer.

Ask the questions one at a time.

If a question can be answered by exploring the codebase, explore the codebase instead.

After a question is asked, please verify if what you're asking is already a behavior of the system. Declare if it is. For that reason, you might get answers to questions as you go through this that you can confirm in line. I would like to see these decisions. The objective with this instruction is to ensure we understand the deltas, if any exist.

At a minimum, 3 sections:
1. **Question #:**
2. **Current behavior:** include if this question contains functionality already present in some way
3. **My recommended answer:**

## investigation/SKILL.md

---
name: investigate
description: The method for investigating a problem and its proposed fix before committing to it — in any domain (software, workflow, policy, process, etc.). Ground in real instances, classify the problem, lock acceptance criteria, trace why it exists, re-confirm the class, then stress-test the solution against scale, generalization, and fit. Emits an Investigation Report (see the investigation-report template): verdict, problem class, assumptions-to-test, a happy/negative validation plan, recommendation with gates, and open variables to collect. Use when scoping a change, validating assumptions, writing a spec, or when the user says "investigate".
---

Investigate this problem and any proposed solution until we understand it well enough to act on it. Work down the tree one question at a time, and for each question give your recommended answer.

Before proceeding, tell the user they need to place the agent in Plan mode first. The investigation plan must address every point in every section below. Nothing can be left out: if a point is not resolved immediately, record where and when it will be resolved, and carry it into the Investigation Report / handoff so every section remains covered when referenced later.

The steps below are ordered by dependency: each locks in something the next step needs. Getting an early step wrong creates churn in every step after it — so don't skip ahead, and when a checkpoint flips an earlier answer, go back and redo the dependents before proceeding.

## Standing disciplines (apply from the first sentence, not a later phase)

- **Evidence first.** If a question can be answered by gathering evidence yourself, do that instead of asking. Only ask me what the evidence can't tell you.
- **Maintain the coverage ledger.** Consult prior coverage ledgers before opening an investigative branch, and record coverage (area, items inspected, findings, status, commit) as you traverse — per `agents/docs/investigation-coverage-ledger.md`.
- **Every claim falsifiable.** Write each claim — including problem statements and classifications — so it could be refuted, then go look for the refutation. Log each into the assumptions ledger as you make it, not retroactively.
- **Log unknowns as they surface — and route them by how they resolve.** A **fact to be discovered** (an answer already exists in the code / source text / observed behavior) goes to the assumptions ledger and you resolve it by evidence, *now* — never park a discoverable fact as an "open variable for discussion," which quietly excuses not going to find the answer. A **decision to be made** (resolved only by an owner choosing — scope, product, ownership, a change to the current structure) goes to the open-variables list with an owner. If one item has both halves, split it: discover the fact, isolate the decision. This axis is domain-agnostic — *fact-to-discover vs decision-to-make*; on a software ticket it lands as *code vs workflow*, on policy as *source-text/precedent vs judgment call*.
- **Offer candidates cheaply, drop misses without ceremony.** Never defend a bad instance or framing.
- **Push back on my framing for real.** If I say I'm sure, probe it. Agreement-by-default wastes the exercise.

## Step 1 — Collect the raw facts (ground downward first)

Instances come before classification: they are the evidence a classification is built from. Classifying first invites finding only the instances that fit.

- Name real instances: specific people or cases, blocked right now, on real tasks. No named instance = no confirmed problem; say so.
- State the problem in one plain sentence a stranger could confirm or deny. Enumerate the distinct problems separately — don't merge them.
- Establish urgency: the date or trigger event when this bites next. "Eventually" doesn't count.
- Run the **Problem Check** lens (`agents/docs/problem-check.md`) on the problem as stated — **every investigation, not just transcripts**. It surfaces what's being **conflated** (usually several distinct problems treated as one → separate them, per the bullet above), asked-vs-answered drift, **thin** terms, and internal contradictions ("off"). Feed its findings into Step 2 (class) and the assumptions ledger / open variables. When the evidence includes a transcript or live discussion, also extract the explicit **decisions** made.

## Step 2 — Classify the problem (provisional, from the instances)

The highest-leverage call in the investigation — everything downstream is checked against it — but it stays *provisional* until Step 4 confirms it against root-cause evidence.

- Note the class the request *assumes* — the category implied by how it was framed.
- Derive the class from the instances in Step 1, not from the request's framing. Are we looking at the class, or a symptom of a different class?
- If they differ, **stop and flag it loudly** — a reclassification is a major finding, not a footnote. (Example: a request framed as "data access — who can reach which systems" may really be a knowledge-management problem — where the data lives and how people discover it. Same symptoms, different class, completely different solution.)
- State what the class implies for the solution space.
- Only now find the wedge: the smallest issue *within the class* that forces the space open and stays reusable. A theme is not a project. The wedge depends on the class — if the class later flips, the wedge is redone.

## Step 3 — Lock the contract before any solutioning

Acceptance criteria are part of the problem definition, not the solution. Define what "done" is judged against before proposing anything, or the stress-test has no target.

- List the acceptance criteria — each one checkable.
- List the non-goals: what this explicitly does *not* cover. This is what prevents scope churn later.
- Note any framing drift beyond the class — other ways the question has shifted from the original ask.

## Step 4 — Trace why it exists, then re-check the class

- Trace the problem to its origin. Gather evidence from the primary source before asking me. Confirm or revise each assumption against that evidence, not against what the request claims.
- **Checkpoint:** re-confirm the classification against the root-cause evidence. Reclassifications most often emerge *here*, not at first glance. If the class flips, go back and redo the wedge and acceptance criteria before proceeding — that redo is cheap now and churn everywhere after.

## Step 5 — Propose, compare, and stress-test the solution

Propose a solution if there isn't one. Record the alternatives you considered and why each was rejected — future discussions will ask "why didn't we just X?" and this report should already answer it. Then test the chosen solution against:

- **The confirmed class** — does it solve the class of problem (not the assumed class, not just this occurrence)?
- **The acceptance criteria** — cover each: covered / needs proof / documented / gap, and what closes it.
- **Scale** — will it hold up as scope, volume, or the number of people and cases involved grows?
- **Generalization** — should this be abstracted, or is that overreach? The fix must be no simpler than it needs to be and no more complex than it needs to be.
- **Fit** — does it follow established practice and integrate cleanly with the existing system, its conventions, and its philosophy?
- **Adjacent issues** — if you surface related problems, is it lower effort to resolve them now or to spin off a follow-up? State the tradeoff.
- **Sufficiency** — does it cover the pain that convened this, or only a corner of it?
- **Feedback speed** — how fast will reality tell us we're wrong? Flag slow-feedback work.
- **Actor / action / moment** — for any capability, who is asking what, and when. Kill vague capabilities.
- **The flip side** — narrate the 30-second happy-path story of the solved world: who does what, and without whom.

## Step 6 — Build the validation plan

- **Happy path:** the sequence that should work, step by step.
- **Negative / inferred paths:** prove the problem isn't leaking in from, or out to, somewhere we haven't modeled. What must fail *visibly* instead of corrupting silently; limit and threshold breaches; removed dependencies proven non-required; timing/latency bounds that must hold.

## Step 7 — Reconcile open questions against the evidence (facts resolved, decisions isolated)

Before emitting, take every open question the investigation surfaced and run it back through the evidence one more time. This is the ambiguity re-check: a question is only allowed to stay open if it is a genuine decision, not an un-investigated fact. It comes *after* the prime investigation because you now know which questions actually survived.

- **Classify each open question** on the fact-vs-decision axis (Standing disciplines): is the answer discoverable in the evidence (code / source / observed behavior), or is it a decision for an owner? An item with both halves is split.
- **Resolve the discoverable ones now** — trace the code, read the source, observe the behavior — and move each to the assumptions ledger with its finding. Do not carry a fact you could have found into the handoff as a question, and do not bring it to me to "decide" when the codebase already answers it.
- **For a question the current structure genuinely cannot answer, prove it** — cite the specific code or structure that shows *why* it is unanswerable as-is: the missing seam, the absent field, the state the system cannot distinguish. "We don't know" is not acceptable; "here is the evidence that the current implementation cannot tell us, so this is a decision or a change, not a lookup" is.
- **What remains in open variables after this pass is only true decisions**, each with an owner.

## Step 8 — Emit the Investigation Report

Record everything into an Investigation Report (copy the template to `docs/investigations/<id>-<slug>.md`). The report is the deliverable — the results of investigating, not a plan to investigate. Its reading order leads with the verdict; you write the verdict last.

- **Verdict (bottom line up front)** — disposition (proceed / proceed with conditions / blocked / rejected / needs more investigation), one-paragraph summary, the strongest path forward, and — explicitly — what this is *not* yet (e.g. "viable, but not a production approval").
- **Problem class** — assumed class, confirmed class, whether it was reframed and at which step. The load-bearing finding.
- **Problem statement, acceptance criteria, non-goals** — from Steps 1 and 3.
- **What changed** — how the question shifted since the request was created; a reclassification is the most important kind of shift, so lead with it if it happened.
- **Why it exists** — origin and evidence, plus the class re-check outcome.
- **Alternatives considered** — each rejected option and the reason.
- **Solution & stress-test** — including the acceptance-criteria coverage table.
- **Assumptions ledger** — every falsifiable claim with status (open / confirmed / confirmed directionally / revised / refuted) and how to confirm or revise it. "Confirmed directionally" still owes proof of performance, accuracy, and parity.
- **Validation plan** — happy path and negative paths, from Step 6.
- **Decisions and recommendation with gates** — what we settled; what to do in order; what proceeds first and what stays gated behind which proof or artifact.
- **Open variables to collect** — the unknowns logged along the way, each with an owner where possible.
- **Handoff table** — action / owner / done-when, each done-when falsifiable.

Don't finish until you can answer all of these: the confirmed problem class (and any reframing from the original ask, with the step where it flipped), the problem in one plain sentence, a named blocked instance, the date it bites next, the wedge and why it's reusable, the acceptance criteria and non-goals, the 30-second happy-path story, the metric that proves it works and how fast it arrives, the verdict and disposition, owners for the open variables, and the tracked action with a falsifiable done-when.

---

## Contextual branches

This procedure is domain-agnostic. "Gather evidence from the primary source" resolves differently by context — follow the branch that fits:

- **Software** — search the codebase for evidence and trace the defect to its origin in code. Add a frontend lens where relevant: should we change how it behaves, how it looks, or both?
- **Workflow / process** — read the process as documented, talk to the people who actually run it, and watch where it breaks in practice.
- **Policy** — read the source text and precedent; check how it's applied versus how it's written.

Other domains plug in their own evidence source the same way.

## orchestrate/SKILL.md

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
  investigations/
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
| 0 | Capture | Working | `original-ticket.md`, `orchestration.md` | gate → HANDOFF (Plan) |
| 1 | Investigate | Plan | approved investigation plan (staged coverage rows) | gate → plan approval |
| 2 | Report | Working | investigation report, coverage ledger, diagrams, test-plan seed | gate → AUTO-ADVANCE to 3 |
| 3 | Probe & spec | Working | locked-decision ledger, spec, refined test plan | gate → HANDOFF (Plan) |
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
| 1 Investigate | pending | | | |
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

- **Reads:** `../../docs/original-ticket-artifact.md`; the canonical changelog per the `ticket-changelog` rule (task-start alignment — resolve or scaffold it; personal projects use `docs/<project>/`'s project changelog). For ClickUp-backed tickets, also read `../../docs/browser-loop-setup.md` and load the browser-loop guardrails before using Playwright/browser observation.
- **Do:**
  1. Create the ticket folder in the canonical layout.
  2. For ClickUp-backed tickets, use Playwright/browser observation as the preferred capture path: open the active ClickUp ticket page, identify the visible ticket fields and metadata from the rendered UI, and export the captured ticket to Markdown as `{ticket-id}-original-ticket.md`. Use API access only as a fallback or cross-check, not as the default source of truth. **ClickUp requires an authenticated session** — a freshly Playwright-launched browser context has no login and cannot see the page. Attach to a real, already-logged-in Chrome instead, per browser-loop-setup.md's "Attaching to an authenticated browser session" recipe; do not attempt a fresh headless/incognito launch against ClickUp and fall back to guessing selectors when it fails to load — that already happened once and cost a manual recovery.
  3. Create `original-ticket.md` (or `{ticket-id}-original-ticket.md` for PRDV tickets) per the artifact doc — the request **verbatim**, capture metadata, explicit constraints, context paths. No findings, no recommendations.
  4. Scaffold `orchestration.md` from the template above; mark Phase 0 `done`.
  5. Align with the changelog's Current state / Plans / Attempt history before anything downstream.
- **Gate evidence:** original-ticket artifact Original Request section is verbatim; ClickUp capture path or user-provided source is named; changelog named; no implementation-repo file has been touched yet.
- **Advance:** notify (Progress notifications), then handoff → Phase 1 (Plan).

## Phase 1 — Investigation (Plan)

- **Reads:** `../investigation/SKILL.md` (execute it — this phase IS that method, run inside this orchestration); `../../docs/investigation-software-gaps.md` (**mandatory software lens** for software-domain tickets: contract alignment, surface enumeration, protect-the-neighbors, detection gap, red→green test, repro recipe); `../../docs/investigation-coverage-ledger.md` (the consult protocol). Problem Check is already embedded in the method's Step 1 — do not load it separately. Do **not** load `investigation-question-coverage.md` (meta-audit, not an operational input).
- **Do:**
  1. **Consult prior coverage ledgers FIRST** — before opening any investigative branch, run the consult protocol (grep `docs/<Project>/tickets/*/investigations/*-coverage-ledger.md` for the subsystems in play). Reuse covered ground; reopen only per the four reopen conditions, with the reason recorded. Stage the mandatory consult log line for the ledger.
  2. Execute the investigation method steps 1–7 on the ticket (everything but the emit). Two disciplines this phase must not skip: (a) the **Problem Check lens** (method Step 1) — its Asked / Answered / Should-ask + Conflation / Thin / Off findings, each grounded in a trimmed quote from the ticket text ("nothing here" is a valid flag, silence is not), carry into report §2; (b) the **Step 7 reconcile** — classify every open question on the fact-vs-decision axis, resolve the code-discoverable ones by tracing the evidence *now*, and for any question the current structure genuinely can't answer, capture the code evidence that proves why. Stage coverage rows (area, items inspected, findings, status, commit) as you traverse — they become the coverage ledger in Phase 2.
  3. Build the investigation plan. It must include todos to: reconcile against every point of the software lens; emit the report per the template; materialize the coverage ledger (with the consult line); produce the diagrams artifact per `../../docs/investigation-diagrams.md`; seed the test plan per `../../docs/test-plan-artifact.md`; record any surfaced concerns per `../../docs/future-development-concerns.md`.
  4. **Surface the ticket's Why early.** Establish the **class of problem** and the high-level problems we're solving, and stage the Phase 1 why-log entry (obvious / not obvious / assumptions) for `<slug>-why-these-changes.md` (per `../../docs/why-these-changes.md`). This is the heart of the Why doc — get it on the record before the work runs ahead of the understanding. Plan mode can't write, so the file is materialized at Phase 2's first action.
- **Gate evidence:** the plan contains the consult results and the reconcile-per-lens todos; the Problem Check pass is present (flags may read "nothing here"); every open question is split into facts (resolved via evidence) vs decisions (owner) — no code-discoverable fact left parked as a decision; open variables have owners; the problem class and Phase 1 why-log entry are staged for the Why doc.
- **Advance:** plan approval (this is the handoff). Ledger row updates and the deferred Phase 1 notification both fire at Phase 2's first action.

## Phase 2 — Investigation report (Working)

- **Reads:** the approved plan; `../../docs/investigation-report.md` (template); `../../docs/investigation-diagrams.md`; `../../docs/test-plan-artifact.md`.
- **Do:**
  1. Update the ledger (Phase 1 `done`, Phase 2 `in-progress`), and materialize the deferred Phase 1 write: create `<slug>-why-these-changes.md` (problem class + Phase 1 why-log entry) per `../../docs/why-these-changes.md`.
  2. Write `investigations/<slug>-investigation.md` from the template — this path **overrides** the template's default `docs/investigations/` location for orchestrated tickets. The report **links out** to the diagrams artifact from §5; do not embed large diagrams inline.
  3. Materialize `investigations/<slug>-coverage-ledger.md` — Consulted line first, then every staged area entry, then the Not-yet-inspected frontier.
  4. Produce `investigations/<slug>-diagrams.md` — current-vs-target, flows, sequences (race conditions and timing edge cases) as applicable; N/A lines for kinds skipped.
  5. Seed `testing/<slug>-test-plan.md` from report §9.
  6. **Stage the PR draft shell** `<slug>-pr-draft.md` — headings and empty placeholders only, from the PR template in `../../docs/pull-request-workflow.md` (title, ClickUp link, Description, Test Evidence, Commit hash, Checklist). Get the head start, but **draft the shell, not the content**: the body is filled in Phase 5 after testing, because scope can still move in Phases 3–4. Leave a one-line note at the top that it is an unfilled shell.
  7. Update `original-ticket.md` Downstream Artifacts; add a Plans row to the changelog.
- **Gate evidence:** consult log line present in the coverage ledger; report §5 links (not embeds) the diagrams; report §2 Problem Check subsection is filled with quote-grounded findings (or explicit "nothing here" per flag) and the §1–§2 framing claims cite ticket-text quotes, not only code; §8/§10 route facts vs decisions per Step 7; test plan status `seeded`; PR draft shell staged (shell only, body unfilled).
- **Advance:** notify (Progress notifications; deferred Phase 1 notice batches in here too), AUTO-ADVANCE to Phase 3 (same mode) — print the gate, keep going.
- **Reopening a "done" report:** if later work (a fast-follow answer, a live-DOM proof, a corrected assumption) needs to change this report after it's marked done, **append a numbered addendum section** (e.g. "§13. Post-Investigation Addendum — <what>") dated and evidenced — never rewrite the verdict or earlier sections in place. This preserves the original reasoning trail the same way the coverage ledger and locked-decision ledger already do.

## Phase 3 — Probe and spec (Working)

- **Reads:** report §8 (assumptions) + §10 (open variables); `../grill-me/SKILL.md`; `../../docs/qa-to-spec-traceability.md`; the `spec-writing` rule (loads automatically; PRDV app tickets may route through `../write-spec/SKILL.md` and the wiki conventions — ask once: sibling spec or wiki).
- **Do:**
  1. **Before grilling, re-run the Step 7 reconcile on the current open variables.** Any question whose answer is discoverable in the code/source — trace it and resolve it yourself via evidence; do not bring a fact to the user to "decide" when the codebase already answers it. Where a question bundles a discoverable fact with a decision, split it: you answer the fact, the user decides the rest. Only genuine decisions reach grill-me.
  2. Run grill-me against the report's remaining open variables and assumptions — **under the qa-to-spec-traceability workflow**: question gate before each question, one question at a time, each answer committed to the locked-decision ledger before the next, rejected paths recorded.
  3. Risk-accepting answers produce BOTH records: the locked-decision row and a concern entry in `<slug>-future-development-concerns.md` (create on first concern); the row cites the entry.
  4. Materialize the locked-decision ledger as its own file, `specs/<slug>-locked-decisions.md` (question gates resolved + the full `LD-###` table with source / supersedes-or-rejects / spec destination) — the standard from the first real run, once decisions run past a handful the way they will on any non-trivial ticket. Write `specs/<slug>-spec.md`: grill-me output **informs** the spec, it is not the spec. Its required `Locked Decisions From Q and A` section (per `spec-writing` / `qa-to-spec-traceability`) becomes a short summary table that **links to** `<slug>-locked-decisions.md` for the full ledger, rather than repeating it — satisfy the spec-writing rule's sections (N/A lines where a section does not apply); frame Problem → Requirement → Solution.
  5. Refine the test plan — resolved variables become concrete assertions; status `refined`.
- **Gate evidence:** spec's locked-decisions section links to a `<slug>-locked-decisions.md` whose ledger traces every entry to a source; no locked decision remains open; supersessions are recorded (never a silent overwrite); audit per the traceability doc's definition of done.
- **Advance:** notify (Progress notifications), then handoff → Phase 4 (Plan).

## Phase 4 — Prep for implementation (Plan)

- **Reads:** the spec; report §11 (handoff table); the test plan. **No re-investigation** — plan from the artifacts.
- **Do:** build a brief implementation plan: Problem → Requirement → Solution framing; ordered steps; branch step per `../../docs/new-branch-get-started.md` when repo work begins; test execution mapped to the test plan; the shipping checklist obligations (tests, regression, API docs, gates) named up front per the `build-implementation-guardrails` rule.
- **Gate evidence:** every plan step traces to spec/report/test-plan; a Plans row for this plan is staged for the changelog.
- **Advance:** plan approval (this is the handoff). Ledger + changelog Plans row update, and the deferred Phase 4 notification, all fire at Phase 5's first action.

## Phase 5 — Implement (Working)

- **Reads:** the approved plan; the test plan; repo-specific rules of the touched repo.
- **Do:**
  1. Update the ledger; add the changelog Plans row (`active`).
  2. **Revise the test plan — after approval, before implementation.** The implementation plan is approved (Phase 4) but no code is written yet; at this junction do a quick revision/refinement of the test plan (`testing/<slug>-test-plan.md`) so it matches what was actually approved — the approved plan can differ from what the spec proposed. Test plan only; a quick pass, not a rebuild. Set status `revised (post-approval)`.
  3. Implement per the plan, inside the `build-implementation-guardrails` obligations (tests as part of shipping, architecture fit, graceful degradation by layer).
  4. Execute `testing/<slug>-test-plan.md`: check off scenarios, fill the results log with exact command + scope + result (serial runs).
  5. **Maintain the testing-implementation doc** `testing/<slug>-testing-implementation.md` per `../../docs/testing-implementation-artifact.md` — **scenario-first**: each real situation stress-tested (why it matters, whether it held), newly-uncovered scenarios flagged, and any code change hung off the scenario that forced it (file(s) + observed → expected → fix). This is the artifact that explains to other devs *what was addressed* — a test with no scenario is arbitrary execution. Write it as you go; living doc. PR-comment content, never a source comment (guardrails §7).
  6. If a PR draft shell was staged in Phase 2, fill it now (title, description, test evidence, commit hash) per `../../docs/pull-request-workflow.md` — paste the testing-implementation doc's assembled block as the PR comment / test-evidence. Before every commit: changelog session log, then audit → lint → tests per the `git-commit-workflow` rule. PR per `../../docs/pull-request-workflow.md` when requested.
- **Gate evidence:** test plan status `complete` (or blocked items carry reason + residual risk + follow-up); testing-implementation doc records the scenarios stress-tested (each in dev-legible terms, newly-uncovered ones flagged) with any change hung off its scenario, assembled for the PR comment and not copied into source; session log written; gate results reported as a table. **Do not mark this phase `done` on drafted-but-unproven code** — the evidence must be an actual observed result (a run, a manual check, a passing suite), not a claim of what should happen.
- **Advance:** notify (Progress notifications), then handoff → Phase 6 (Idle).

## Phase 6 — Manual review (Idle)

- **Do:**
  1. **Finalize the Why doc:** complete the reviewer-facing review in `<slug>-why-these-changes.md` — the **categorized change breakdown** (requested change / bug fix / workflow change / capability gap / other, with a headline count and Before / After / Why per change), **"why it shipped together"** tied to the acceptance criteria, **Scope**, **Net**, and **Verified** (gates + PR link). Confirm the why-log captured every phase where the why moved.
  2. Produce the review summary: what to review, where, citing the test plan's results log and the Why doc — no unfalsifiable "tests passed" claims.
  3. **Cruft check:** did this run surface outdated references, superseded docs, or dead weight? Append findings to `../../docs/cleanup-candidates.md`; write "cruft check: nothing surfaced" in the ledger notes if clean.
  4. Close the ledger: Phase 6 `done`, `Resume: complete`; set the changelog Plans row to `implemented` when the work landed.
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
- Do not rewrite `original-ticket.md`'s Original Request, ever.
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

## workflow-housekeeping/SKILL.md

---
name: workflow-housekeeping
description: Audit dustin-thomason workflow docs, rules, and index for drift, duplicates, and missing entries. Use when user asks to housekeeping workflows, sync workflow-index, validate personal Cursor setup, or after adding a new playbook or rule.
---

# Workflow housekeeping

Run in **`dustin-thomason`** only.

## Steps

1. Run **`.\scripts\validate-workflows.ps1`** from repo root. Capture all warnings/errors.

2. Inventory and compare to [docs/workflow-index.md](../../docs/workflow-index.md):
   - `.cursor/rules/*.mdc` — note `alwaysApply` and `globs`
   - `.cursor/docs/*.md` — playbooks (exclude README)
   - `docs/ticket-changelog-workflow.md`, `docs/_templates/`, `scripts/new-ticket-changelog.ps1`
   - Flag ticket changelogs under `.cursor/docs/` (should not exist)

3. Fix drift:
   - Update **workflow-index** tables
   - Fix broken relative links in index and README
   - Remove duplicate stubs; keep `.github/` as one-line pointers only

4. Report to user:
   - What was out of date
   - What you changed
   - Anything they must decide manually (e.g. new workflow type with no playbook yet)

Do not modify app-repo workspaces (atlas-front-end, callisto-back-end, etc.) unless the user explicitly asks.

## write-spec/SKILL.md

---
name: write-spec
description: Create or update epic/story specs and dev notes for Callisto/Atlas. Use when the user asks to write a spec, author PRDV ticket documentation, create a dev note for estimation, or extend specs under a systems/ wiki tree.
---

# Write spec

Guided workflow for authoring PRDV specs. Pair with **grill-me** (`.cursor/skills/grill-me/SKILL.md`) when design decisions are unresolved — grill first, then write with resolved decisions and open-questions tables.

## Canonical references (read before writing)

| Topic | Source |
| ----- | ------ |
| Naming, frontmatter, Obsidian wiring, dev notes, author checklist | [docs/wiki-spec-authoring.md](../../docs/wiki-spec-authoring.md) |
| Spec sections 1–8, cross-cutting callouts | [spec-writing.mdc](../../rules/spec-writing.mdc) |
| Problem → Requirement → Solution framing | [problem-requirement-solution.mdc](../../rules/problem-requirement-solution.mdc) |
| Ticket memory, Plans, session log | `docs/<system>/PRDV-XXXXX-changelog.md` |

## When to use

- User provides a PRDV ticket and wants a story or epic spec
- User asks for a dev note for refinement/estimation
- User asks to update an existing spec to match implementation or conventions
- User says "write the spec" for wiki (`systems/`) or app-repo spec folders

## Workflow

1. **Read [docs/wiki-spec-authoring.md](../../docs/wiki-spec-authoring.md)** — naming, frontmatter, Obsidian checklist, dev note template, author checklist.
2. **Read [spec-writing.mdc](../../rules/spec-writing.mdc)** — sections 1–8 and optional callouts.
3. **Resolve changelog** — read `docs/<system>/PRDV-XXXXX-changelog.md` when the ticket is active; add or refresh a **Plans** row with the spec path when done.
4. **Gather inputs** — ClickUp/product description, acceptance criteria, scope boundaries, companion tickets.
5. **Explore codebase** when the spec must reflect as-built architecture (do not assume outdated wiki content).
6. **Confirm target path** — wiki specs go under `systems/{platform}/{feature-folder}/`; app-repo specs follow that repo's folder convention. If unclear, ask once.
7. **Pick a reference spec** — search the workspace for a comparable `PRDV-*` story under `systems/` and match complexity/style (narrative + companions, full sections + open questions, or as-built correction).
8. **Write the spec** at `systems/{platform}/{feature-folder}/PRDV-#####-{description}.md` (or the confirmed app-repo path).
9. **Complete Obsidian wiring** per wiki-spec-authoring — tags, wiki-links, `systems/README.md` index, bidirectional companion links.
10. **Write dev note** (`PRDV-#####-dev-note.md`) when estimation is needed; link spec ↔ dev note.
11. **Update changelog** — **Plans** row with spec path; session log when this session also ships app-repo changes.
12. **Run the author checklist** in wiki-spec-authoring before finishing.

## Spec structure reminders

- Product story + acceptance criteria at the top
- Summary with scope table (in / out of scope)
- Problem → Requirement → Solution narrative
- Resolved decisions + open questions tables when design was negotiated
- Sections 1–8 from spec-writing (N/A with reason when not applicable)
- Cross-cutting: HTTP surface, registries, ports, spec tests, complexity flags, point estimate

## Dev note reminders

- High-level only — enough for refinement, not a duplicate of the full spec
- Link to full spec with wiki-link
- Estimate band (Small / Medium / Large) with one-sentence justification

## Do not

- Depend on another workspace repo for conventions — everything above lives in **dustin-thomason**
- Use relative markdown paths for internal vault links — use Obsidian wiki-links
- Skip `systems/README.md` index entries for new specs or dev notes
- Put ticket changelogs under `systems/` — changelogs stay in `docs/<system>/` only
