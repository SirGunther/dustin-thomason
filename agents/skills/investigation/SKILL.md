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
