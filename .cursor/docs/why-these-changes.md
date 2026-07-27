# Why these changes — the living "Why" of the whole ticket

Use this to hold the **overarching "Why" of the entire ticket** — surfaced **early** and kept **living** across every phase. Its heart is the **class of problem**: what are we actually trying to solve? Establishing that at the start, and tracking how the understanding moves, is the point. It ends as the review that explains, to anyone, *why the changes we made were needed* — what was missing from the code, whether it was a bug, a workflow change, or something else.

This is deliberately **high-level** and distinct from the scenario detail in the testing-implementation artifact: that doc holds the specific situations stress-tested; this doc holds the ticket's reasoning arc. It is also distinct from the investigation report (a point-in-time classification in Phase 2) — this is the **running why-thread** that spans Phase 1 through close, link the report rather than restate it.

**It is a communication artifact.** Its finalized form is the reviewer-facing narrative of the ticket — it reads the way the reference (`PRDV-14055-why-these-changes.md`) reads, and its content feeds the PR. The spine of that finalized form is a **categorized breakdown of every change**: each change classified (requested change / bug fix / workflow change / capability gap / other), counted in a headline, and given a **Before / After / Why**.

## Output location

```text
docs/<Project>/tickets/<ticket-slug>/<ticket-slug>-why-these-changes.md
```

## When produced / updated

- **Created early — as early as Phase 1**, off the first investigation, to establish the problem class and the problems we're solving before the work runs ahead of the understanding.
- **A living doc:** revisited at **every phase**. It must **always be updatable through each phase, if required** — and when the "why" moves (the problem, the class, the bug, the code, an assumption), that change is **logged, explicitly labeled** with the phase.
- **Finalized at Phase 6** as the "why these changes" review.

## Core rules

- **The class of problem is the core.** Lead with it; keep it high-level (not the specific scenarios — those live in the testing-implementation doc).
- **Name the code that is the problem.** Beyond the class, pin the specific file / function / symbol that is the root cause — the actual piece of code at the heart of it — and update it if investigation re-traces the cause. Link the report's §5 root-cause trace rather than restate the full evidence.
- **Log the reasoning trail as you go** — per phase: what was **obvious**, what **wasn't**, what **changed after learning more**, what **got us to the solution**, and what turned out to be **noise**.
- **Label every entry.** Each logged item names its phase and whether it is a new understanding, a **course change**, or a discarded path. Silence is not a log — if nothing moved this phase, that can be stated, but a change that went unlogged is a failure of the doc.
- **Reference, don't restate.** Link the report's problem class / root cause and other artifacts; this doc's job is the evolving *why*, not the investigation detail.
- **If the why changes, log it — always.** The bug, the code, the class, an assumption: a shift in any of these is exactly what this doc exists to capture.
- **Categorize every change (the finalized spine).** As implementation locks, classify each change — requested change / bug fix / workflow change / capability gap / other — give a **headline count**, and a **Before / After / Why** per change. This is what the artifact primarily represents to a reviewer.
- **Say why it shipped together.** Explain why the bundle of changes is coherent — not scope creep — tying it to the acceptance criteria.
- **State scope.** What the change is confined to, anything narrowed during implementation, and any follow-ups spun off.
- **Code changes and their why are logged here too.** As changes land (especially Phase 5), record *why* each was needed in the ticket's reasoning — a bug, a workflow change, missing code, or something else — not just that it happened. This is the **reasoning behind** the change. The **mechanics** of a change (file + observed → expected → fix, tied to the scenario that forced it) live in the testing-implementation doc; this doc says *why the ticket needed that change at all*. When the code moves the why, the why-log says so.

## Artifact template

```markdown
# Why these changes — <Project>/<ticket-slug>

> The living "Why" of this ticket. Created Phase 1, updated every phase, finalized at close. High-level — scenarios live in the testing-implementation doc; point-in-time classification lives in the investigation report.

## Problem class (the core — what are we actually solving?)
<high-level class of problem; link investigation report §1 once it exists>

## The code at the root (what/where is the problem)
<the specific file / function / symbol that is the problem — the root-cause location; link report §5 for the full trace. Update if the cause is re-traced.>

## The problems we're solving
<the distinct problems, high-level — not scenarios>

## Why-log (append per phase; label each entry)
### Phase 1 — <date>
- Obvious: <…>
- Not obvious / still open: <…>
- Assumptions logged: <…>

### Phase <N> — <date> — [COURSE CHANGE] (label only when the why moved)
- What changed after learning more: <…>
- What was noise / discarded: <…>
- Code change + why: <what changed, and why the ticket needed it — bug / workflow / missing code / other>
- Why this changes the solution: <…>

## Changes made — categorized (filled as implementation locks; subject to update)
> Headline count, then one entry per change. Classify each: requested change / bug fix / workflow change / capability gap / other.

Count: <e.g. 1 requested change · 2 bug fixes · 1 capability gap>

### <change title> — <type>
- **Before:** <what it did>
- **After:** <what it does now>
- **Why:** <the reasoning — deliberate requested/UX change? latent bug? missing capability? workflow?>
- **Files:** <where> (the change mechanics + the scenario that forced it live in the testing-implementation doc)

## Why it shipped together
<why the bundle is coherent, not scope creep — tie to the acceptance criteria>

## Scope
<what it's confined to; anything narrowed during implementation; follow-ups spun off>

## Net
<one-line summary of what the ticket turned out to be>

## Verified
<gates (lint / type / tests) + manual evidence + PR link — sourced from the test plan / testing-implementation doc>
```

## Definition of done

- The **problem class** is stated and current (not contradicted by later phases without a logged reason).
- The **why-log has an entry for each phase where the why moved**, explicitly labeled, including course changes.
- The reasoning trail (obvious / not / changed / solution / noise) is captured, not just conclusions.
- The finalized review **categorizes every change** (requested change / bug fix / workflow change / capability gap / other) with a headline count and a Before / After / Why each.
- **"Why it shipped together"** justifies the bundle against the acceptance criteria (not scope creep); **Scope**, **Net**, and **Verified** (gates + PR link) are present.
- The whole reads as reviewer-facing communication — the shape of the reference `PRDV-14055-why-these-changes.md`.
