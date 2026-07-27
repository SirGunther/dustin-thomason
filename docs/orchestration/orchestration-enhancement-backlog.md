# Orchestration enhancement backlog — candidate updates

Candidate updates to the `orchestrate` skill and its artifact set, captured 2026-07-27. **These are proposals, not adopted.** Each carries where it would land, how it relates to what already exists, and the open question that needs a decision before implementation. Prioritize/cut/merge here first, then implement the survivors in priority order (each becomes a normal source edit → sync → validate → commit).

This doc lives outside `agents/docs/` on purpose: it is planning material for the system, not operating guidance an agent should load mid-run.

Legend — **Effort:** S/M/L · **Lands as:** new artifact / phase change / new doc / standing rule.

---

## Cluster A — Implementation-reasoning & test-execution artifacts (back half of the lifecycle)

These three are the biggest cluster and overlap the existing `test-plan-artifact.md`. Decide the boundaries between them before building any (see Cross-cutting decision 1).

### A1 — "Why these changes" review artifact
- **Idea:** A standalone artifact, separate from the investigation, explaining *why* the changes were needed — what was missing from the code, was it a bug, a workflow change, something else. A review/communication doc written *after* implementation is locked, explicitly subject to updates because testing changes things. Reference shape: `PRDV-14055-why-these-changes.md`.
- **Lands as:** new artifact template `agents/docs/why-these-changes.md`; per-ticket output at `docs/<Project>/tickets/<slug>/<slug>-why-these-changes.md`; produced late in Phase 5 (implementation locked) and finalized in Phase 6.
- **Relationship:** distinct from the investigation report (that's *before* the fix, this is *after*), and distinct from the future-development-concerns doc (that's risk, this is rationale). Feeds the PR body/description.
- **Open question:** is this one doc with A2, or two? (see Cross-cutting decision 1). Also: does its "rationale" content partly already exist in report §1/§5/§7, and should it *link back* to them rather than restate?

### A2 — Testing-implementation artifact (scenario-first) — **BUILT (uncommitted, in review) 2026-07-27**
- **Objective (as refined by the user):** explain to **other devs what was addressed** — the real-world **scenarios** that were stress-tested. A test with no stated scenario is arbitrary code execution; the scenario is the stake. The doc also captures **scenarios the plan did not cover** but that testing surfaced. Code changes hang off the scenario that forced them (file + observed → expected → fix). PR-comment content, never a code comment.
- **Shipped as:** standalone, scenario-first artifact — template `agents/docs/testing-implementation-artifact.md`; per-ticket output `testing/<slug>-testing-implementation.md`; produced/maintained in orchestrate Phase 5 (step 5); wired into the folder layout, Phase 5 gate evidence, guardrails §7, README catalog, workflow-index, and the test-plan execute row (scenarios + changes recorded here, not in the test plan).
- **Correction note:** this was the substance of the user's original suggestion #3 (the "github stuff"). First wrongly deferred while only the one-line A3 rule shipped; then rebuilt change-first; **finally reframed scenario-first** per the user's stated objective (the scenario is why the test matters, not the code change). Cross-cutting decision 1 resolved: standalone, not folded into the test plan.

### A3 — "PR comment, not code comment" as a standing rule
- **Idea:** Recurring principle across A1/A2 — rationale for a change belongs in the PR conversation, never as a comment in the codebase.
- **Lands as:** a one-line standing rule, most naturally folded into `build-implementation-guardrails.md` (which already governs comment discipline) and referenced from the orchestrate Phase 5/6 artifacts.
- **Effort:** S. **Relationship:** reinforces existing comment guidance; cheap, high-leverage, do regardless of A1/A2 shape.

---

## Cluster B — PR mechanics & handoff

### B1 — Boilerplate PR, drafted early
- **Idea:** As part of the initial investigation, create the boilerplate PR for the real codebase (to be filled in after testing) — get a head start on the scaffold.
- **Lands as:** a Phase 1 or Phase 2 todo that stages a PR skeleton (title, sections, empty evidence slots) per `pull-request-workflow.md`; filled in during Phase 5, opened when work lands.
- **Open question:** where does the draft *live* before the PR exists — a `pr/` file in the ticket folder, or just staged in the plan? And does "early" risk drift if scope changes in Phase 3/4? (Guard: draft the shell, not the content.)

### B2 — Reviewer PR-patterns working doc
- **Idea:** A working doc (renameable) capturing a specific reviewer's expectations, so what we build lines up with other devs' expectations for refactors/updates/PRs. Reference shape: `docs/reviewers/lana-pr-review-patterns.md`.
- **Lands as:** a durable `docs/reviewers/<name>-pr-review-patterns.md` (per reviewer), consulted in Phase 4 (prep) and Phase 5 (implementation) so the build pre-empts known review asks.
- **Relationship:** a new reference class — not per-ticket, but per-reviewer/team, reused across tickets. Analogous to how repo `.cursor/rules` encode conventions; this encodes a *person's* review conventions.
- **Open question:** is this in scope for `orchestrate` to *consult automatically*, or a manual reference the user @-mentions? And where do these live — `docs/reviewers/` (not synced) seems right.

### B3 — Handoff plans to Codex for implementation
- **Idea:** Produce implementation plans in chat that can be handed to Codex to execute — saves Claude tokens, ensures a scoped plan. Must include: a pointer to `notify-agent-complete.ps1` so a "done" notification fires; and an explicit instruction that **Codex must NOT push — Claude reviews first.**
- **Lands as:** a Phase 4 output variant — a self-contained "implementation handoff" plan doc (`<slug>-implementation-handoff.md`) written so a fresh Codex agent can execute it without Claude's context.
- **Relationship:** interacts with the mode/harness model — this is Claude planning, Codex implementing, Claude reviewing. Pairs naturally with B1 (Codex fills the boilerplate PR) and the no-push guardrail.
- **Open question:** does this become the *default* Phase 4→5 handoff, or an opt-in branch ("orchestrate ... --handoff")? The no-push + Claude-reviews-first rule should be explicit in the handoff doc's own header, not just the skill.

---

## Cluster C — Visual & delta analysis

### C1 — Code-flow diagram (linear/branching process)
- **Idea:** Beyond the current before/after delta diagram, lay out the **linear or branching flow of the code being touched** — the functions, classes, variables — so the process is obvious the way Microsoft Flow makes a process obvious. Pull the process out into a visual.
- **Lands as:** a third diagram kind in `investigation-diagrams.md` (already houses current-vs-target, flows, sequences) — this is a more granular *code-level* flow than the existing system-level "flows" entry, so either a sharpened definition of that entry or a new "code walk" kind.
- **Relationship:** extends the diagrams artifact; complements (doesn't replace) the delta diagram. Reference: the PRDV-14055 diagrams file.
- **Open question:** is this a distinct diagram kind, or guidance to make the existing "flows" entry go down to function/variable granularity? Mermaid can do it; the risk is over-detail — needs a "collapse unchanged plumbing" rule like the delta convention has.

### C2 — Delta discussion / blast-radius review step
- **Idea:** A chat-discussion step: "here's how the system functions now, here's how we could change it to do X." Talking through it — *why* make these changes, how involved, what's changing, where else it touches — surfaces downstream effects that a flat question misses. In a real plan session this uncovered a blast radius the questions alone wouldn't have.
- **Lands as:** either a new lightweight phase between investigation and spec, or an explicit sub-step of Phase 1/Phase 3 that forces a "delta walk" before locking questions. Branch-able (a discussion that can fork).
- **Relationship:** this is close to the investigation method's surface-enumeration lens (`investigation-software-gaps.md` Candidate 2, blast radius) — but as a *conversational* delta walk rather than a written enumeration. The value observed was that discussion beat interrogation because the deltas had downstream effects.
- **Open question:** is this a genuinely new step, or is it Phase 3's grill-me done right (delta-first questions)? Possibly the fix is to make grill-me/Phase 3 open each question with its delta and blast radius, rather than adding a phase. Decide: new step vs. sharpen existing.

---

## Cluster D — Test plan lifecycle

### D1 — Post-approval test-plan revision pass
- **Idea:** After the implementation plan is approved, do a quick revision/refinement of the test plan at that junction — don't treat the Phase 2 seed / Phase 3 refine as final.
- **Lands as:** a small addition to Phase 5's first action (or the Phase 4→5 boundary): re-open the test plan and refine against the approved plan before executing.
- **Effort:** S. **Relationship:** the test plan already has seed (P2) → refine (P3) → execute (P5); this inserts a *post-approval* refine tick so the plan reflects what was actually approved, not just what the spec proposed.
- **Open question:** none major — this is a cheap, obvious tightening. Candidate for "just do it."

---

## Cross-cutting decisions (resolve before building the cluster)

1. **A1 vs A2 vs the existing test plan — how many docs?** Three plausible shapes: (a) one "PR communication pack" combining why-these-changes + testing-implementation; (b) two docs (rationale vs test-execution) both feeding the PR; (c) fold A2 into the test plan's results log and keep A1 standalone. Recommendation to pressure-test: **(c)** — A2 is test-execution data (belongs with the test plan), A1 is rationale (genuinely standalone and communication-facing). Decide this first; it determines three of the eight items.

2. **Who implements — Claude or Codex?** B1, B3, and A2's "changes during testing" all assume an implementer. If Codex is the default implementer (B3), then Phase 5 is really "Claude authors handoff → Codex implements → Claude reviews → Claude pushes," and the boilerplate PR (B1) and no-push rule live in the handoff. If Claude implements, B3 becomes an opt-in branch. This routing decision shapes Phase 4–6.

3. **New phases vs. sharpened existing phases.** C2 (delta discussion) and C1 (code-flow) both *could* be new steps, but both might be better as sharpenings of existing ones (C2 → grill-me opens with deltas; C1 → the diagrams "flows" entry goes to function granularity). Bias: sharpen before adding, to protect the "signal not noise" constraint — every new phase is context every run pays for.

4. **Reference-doc class (B2 reviewer patterns).** New idea: docs keyed to a *person/team's* review expectations, reused across tickets, living in `docs/reviewers/`. Confirm this is a class worth formalizing (vs. a one-off), and whether orchestrate consults it automatically or on @-mention.

---

## Quick-win candidates (low effort, low controversy — could ship first)

- **A2** — testing-implementation artifact (the "github stuff": what was tested + mid-test code changes for the PR comment). **BUILT (uncommitted, in review)** → `testing-implementation-artifact.md` template; orchestrate folder layout + Phase 5 step 5 + gate evidence; guardrails §7; test-plan execute row.
- **A3** — "PR comment not code comment" standing rule (the principle behind A2). **SHIPPED 2026-07-27** → `build-implementation-guardrails.md` §7 + orchestrate Phase 5 / Do-not.
- **D1** — post-approval test-plan revision tick. **EDITED (uncommitted, in review)** → `test-plan-artifact.md` lifecycle + status; orchestrate Phase 5 step 2. Placement per user evidence "after approval, MEANING before implementation": the revision runs at the **start of Phase 5, after the plan is approved but before any code is written** — a quick pass so the test plan matches what was approved. (Note: an earlier edit wrongly moved this to post-implementation; corrected back.)
- **B1 (shell only)** — stage the PR skeleton early, content later. **SHIPPED 2026-07-27** → orchestrate folder layout + Phase 2 step 6 + Phase 5 step 6; `pull-request-workflow.md` early-shell note.

## Needs-a-decision-first (don't build until the cross-cutting call is made)

- **A1** — "why these changes" rationale artifact (gated on decision 1; A2 now built standalone, so A1 stays a separate open question).
- **B3** — gated on decision 2 (implementer routing).
- **C1 / C2** — gated on decision 3 (new step vs. sharpen).
- **B2** — gated on decision 4 (reference-doc class).
