# Investigation method — question coverage checklist

> **What this is:** the loose questions/principles collected for the investigation method, deduped and checked against what the method **currently** captures. Every "present" item carries a **verbatim quote** from the source so this reads as an audit, not a claim — no lookup required.
> **Sources quoted:** `SK` = `agents/skills/investigation/SKILL.md` (line refs); `RT` = `agents/docs/investigation-report.md`.
> **Scope:** built from *Questions to answer*, *Guiding principles*, the *Problem→Requirement→Solution* note, and *Transcript Analysis Tasks*. **Excludes** Jim's Question Battery and the Pre-meeting self-grill.
> **Legend:** `[x]` = present, with quote · `[ ]` = gap / not this method's job (explained inline). Net-new software questions live in [investigation-software-gaps.md](./investigation-software-gaps.md).

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
  > SK Step, software branch (line 94): *"Add a frontend lens where relevant: should we change how it behaves, how it looks, or both?"*

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

## Items that are NOT this method's job (parked, not gaps)

- [ ] **Problem → Requirement → Solution as an explicit ordered narrative** — **out of scope for the investigation method.** This is a *ticket-framing* concern — how each ticket is built/structured — not something the investigation itself must emit. Park as a possible note on ticket construction; revisit there, not here. (The raw pieces still exist in the method: problem in SK Step 1, acceptance criteria in SK Step 3, solution in SK Step 5 — but forcing the P→R→S ordering belongs to ticketing.)
- [ ] **Identify decisions** — **not the explicit thing to pull out here, and largely transcript-geared.** Settled decisions *are* recorded when they exist —
  > RT §10: *"- **Decisions** (settled):"*
  — but "extract the decisions from a discussion" is a meeting/transcript activity, not a core investigation requirement. At most, a small note on capturing concrete decision language when the evidence source is a live discussion. Low priority.

## Genuine gap — worth adding

- [ ] **Identify uncertainties (ambiguity / lack of clarity)** — **this one jumps out.** The method captures *unpinnable values* but not *ambiguity in understanding*. What's there today:
  > SK standing disciplines: *"**Log unknowns as they surface.** Any value, mapping, threshold, owner, or boundary you can't pin down goes into the open-variables list the moment you notice it."*
  That covers a **missing value/mapping/threshold/owner/boundary** — a concrete blank to fill. It does **not** cover an **uncertainty**: a place where the framing itself is unclear, signals conflict, or we don't yet understand what we're looking at. Those are different (a known blank vs. an unclear picture), and only the first has a home. Worth adding an explicit "surface the uncertainties/ambiguities" prompt — candidate for promotion into [investigation-software-gaps.md](./investigation-software-gaps.md) (or a general-method addition).

---

## Summary

Against the collected questions, the redundancy you felt is confirmed: everything under *Questions to answer*, *Guiding principles*, and *root cause* is **present with a verbatim quote above**. Of the leftovers:

- **P→R→S** → not this method's job; a ticket-framing note for later.
- **Identify decisions** → recorded when present (RT §10), but transcript-geared and not the explicit ask; low priority.
- **Identify uncertainties** → **real gap.** Open-variables covers missing *values*, not *ambiguity*. This is the one to carry forward.

Software-specific questions the method doesn't ask at all are tracked separately in [investigation-software-gaps.md](./investigation-software-gaps.md).
