# Investigation method — question coverage checklist

> **What this is:** the loose questions/principles collected for the investigation method, deduped and checked against what the method **currently** captures. Every "present" item carries a **verbatim quote** from the source so this reads as an audit, not a claim — no lookup required.
> **Sources quoted:** `SK` = `agents/skills/investigation/SKILL.md` (line refs); `RT` = `agents/docs/investigation-report.md`.
> **Scope:** built from *Questions to answer*, *Guiding principles*, the *Problem→Requirement→Solution* note, and *Transcript Analysis Tasks*. **Excludes** Jim's Question Battery and the Pre-meeting self-grill.
> **Legend:** `[x]` = present, with quote · `[ ]` = gap / handled elsewhere (explained inline). Net-new software questions live in [investigation-software-gaps.md](./investigation-software-gaps.md).

## Questions to answer

- [x] **Solve the class, not just the instance**
  > SK Step 5: *"**The confirmed class** — does it solve the class of problem (not the assumed class, not just this occurrence)?"*
- [x] **Will it scale?**
  > SK Step 5: *"**Scale** — will it hold up as scope, volume, or the number of people and cases involved grows?"*
- [x] **Can/should it be abstracted?**
  > SK Step 5: *"**Generalization** — should this be abstracted, or is that overreach?"*
- [x] **Follows best practices / fits architecture & philosophy**
  > SK Step 5: *"**Fit** — does it follow established practice and integrate cleanly with the existing system, its conventions, and its philosophy?"*
- [x] **Leaks: fix now vs. follow-up + effort tradeoff**
  > SK Step 5: *"**Adjacent issues** — if you surface related problems, is it lower effort to resolve them now or to spin off a follow-up? State the tradeoff."*
- [x] **Front-end: change behavior, appearance, or both?**
  > SK software branch (line 94): *"Add a frontend lens where relevant: should we change how it behaves, how it looks, or both?"*

## Guiding principles

- [x] **No simpler / no more complex than it needs to be**
  > SK Step 5, inside Generalization: *"The fix must be no simpler than it needs to be and no more complex than it needs to be."*
  > *(Note: currently embedded in the Generalization bullet, not a standalone principle.)*
- [x] **Every claim written to be refuted**
  > SK standing disciplines: *"**Every claim falsifiable.** Write each claim — including problem statements and classifications — so it could be refuted, then go look for the refutation."*
- [x] **Confirm/revise each claim against evidence**
  > SK Step 4: *"Confirm or revise each assumption against that evidence, not against what the request claims."*
  > RT §8 assumptions ledger status: *"open | confirmed | confirmed directionally | revised | refuted"*.
- [x] **Test happy path AND negative/inferred paths (defect not leaking in from / out to unmodeled areas)**
  > SK Step 6: *"**Negative / inferred paths:** prove the problem isn't leaking in from, or out to, somewhere we haven't modeled."*

## Root cause in code

- [x] **Understand the code and *why* the problem exists**
  > SK Step 4: *"Trace the problem to its origin. Gather evidence from the primary source before asking me."*
  > SK software branch (line 94): *"search the codebase for evidence and trace the defect to its origin in code."*

## Validation & recommendation (always-on outputs, present)

The four *Transcript Analysis Tasks* split **2 + 2**: two are always-on outputs the method already emits on every investigation (here); the other two are transcript-triggered lenses (next section). The always-on two are **not** transcript-gated.

- [x] **Testing strategies / how to validate** — this is the validation plan; the behavioral "how we test" *is* the happy + negative paths.
  > SK Step 6: *"**Happy path:** the sequence that should work, step by step."* and *"**Negative / inferred paths:** prove the problem isn't leaking in from, or out to, somewhere we haven't modeled."*
  > *(One software-specific sharpening — the automated red→green test that encodes the defect — is logged in [investigation-software-gaps.md](./investigation-software-gaps.md); the general behavioral coverage is here.)*
- [x] **Recommendations (how to proceed)** — a core emit at the **end of every investigation**, not transcript-gated.
  > SK Step 7: *"**Decisions and recommendation with gates** — what we settled; what to do in order; what proceeds first and what stays gated behind which proof or artifact."*
  > RT §10: *"- **Recommendation** (what to do, in order):"*

## Identify uncertainties → Problem Check (always-run, present)

- [x] **Run Problem Check on every investigation** — wired into `SK Step 1`, **not** contextual. The always-on disciplines only catch a **known blank** (a missing value):
  > SK standing disciplines: *"**Log unknowns as they surface.** Any value, mapping, threshold, owner, or boundary you can't pin down goes into the open-variables list the moment you notice it."*
  Problem Check catches the **ambiguity** they don't: asked-vs-answered drift, and above all **conflation** — usually *several* distinct problems treated as one, which split into branches — plus *thin* terms and *off* (internal contradictions). Now wired at:
  > SK Step 1: *"Run the **Problem Check** lens … **every investigation, not just transcripts**."*
  Tool: [problem-check.md](./problem-check.md).

## Identify decisions → context-triggered pointer (present)

- [x] **Extract decisions when a transcript / live discussion is present** — the one genuinely conditional item (you can't mine decisions from a discussion that isn't there). Home in the report when they exist:
  > RT §10: *"- **Decisions** (settled):"*
  Wired as a rider on the same Step 1 Problem Check line: *"When the evidence includes a transcript or live discussion, also extract the explicit decisions made."*

## Not this method's job (parked)

- [ ] **Problem → Requirement → Solution as an explicit ordered narrative** — this belongs to **ticket generation**, not investigation. It's the fast framing used when *writing a ticket* ("here's the problem, the requirement, the solution we'll implement"), which falls out of the investigation's own outputs (problem in SK Step 1, acceptance criteria ≈ requirement in SK Step 3, solution in SK Step 5). Revisit it as a note on how tickets are built, not as an investigation step.

---

## Summary

Against the collected questions, the redundancy you felt is confirmed — everything under *Questions to answer*, *Guiding principles*, and *root cause* is **present with a verbatim quote above**. The four *Transcript Analysis Tasks* resolve as **2 always-on + 2 triggered**:

- **Testing strategies** → present; the behavioral "how we test" is the happy/negative validation plan (SK Step 6). Automated-test sharpening logged in software-gaps.
- **Recommendations** → present; a core end-of-investigation emit (SK Step 7 / RT §10), not transcript-gated.
- **Identify uncertainties** → now an **always-run** lens (Problem Check, wired into SK Step 1) — conflation-detection is its core.
- **Identify decisions** → a **context-triggered pointer**: when a transcript is present, extract decisions (already have a report home; rides the same Step 1 line).

And separately: **P→R→S** → not this method's job; a ticket-framing note for later.

Software-specific questions the method doesn't ask at all are tracked separately in [investigation-software-gaps.md](./investigation-software-gaps.md).
