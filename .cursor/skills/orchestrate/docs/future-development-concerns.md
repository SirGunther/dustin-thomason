# Future-development concerns — the risk record artifact

Use this instruction when work on a ticket surfaces a concern that will NOT be resolved in scope: a decision that cuts against best practice, a risk consciously accepted, or a gap deliberately deferred. The concerns file is a **dated, evidence-backed record that the risk was identified and raised** — kept out of the report and spec so they stay lean, but findable when the risk lands.

Reference shape: `docs/atlas/16216/PRDV-16216-future-development-concerns.md`.

## Output location

```text
docs/<Project>/tickets/<ticket-slug>/<ticket-slug>-future-development-concerns.md
```

Create the file on the **first** concern; append after that. Many tickets never need one — do not create it empty.

## When to record a concern

During investigation, grill-me / Q and A, spec writing, or spec review, whenever:

- a chosen direction goes against best practice and is being shipped anyway;
- a risk is consciously scoped out ("future companion ticket", "accepted for now");
- a locked decision accepts a failure mode someone may later ask "was this known?" about;
- a proposed change contradicts a documented prior rejection.

## Relationship to the locked-decision ledger

A risk-accepting answer produces **both** records: a locked-decision row per [qa-to-spec-traceability.md](../../../docs/qa-to-spec-traceability.md) (the **what**: decision, source, spec destination) and a concern entry here (the **why**: risk rationale, evidence, escalation context). The locked-decision row cites the concern entry. Neither substitutes for the other.

## Core rules

- **Dated and code-verified.** Every factual claim about system behavior carries file:line evidence and the date it was verified. An unverified worry is labeled as such.
- **Framed around where the system is headed**, not just what ships in this story — the record exists for the future reader deciding whether the risk has now matured.
- **Escalation-ready.** The executive summary must stand alone for a reader with authority but no context: the vulnerability, why it matters (fallout, not probability), and the decision being requested with explicit options.
- **Concerns are not blockers.** Recording one does not stop the work; it prevents "why wasn't this considered?" later. If the concern SHOULD block, say so in the summary and route it to the person with authority to own it.
- **Never let it bloat the report or spec** — they link here.

## Artifact template

```markdown
---
ticket: <PRDV-XXXXX or slug>
tags: [<system>, <area>, concerns]
author: <name>
created: YYYY-MM-DD
modified: YYYY-MM-DD
---

# <Ticket> — Future-development concerns (<short subject>)

> **Context:** <what decision/direction these concerns attach to, one or two sentences>
> **Purpose of this document:** a dated, code-verified record that these risks were identified and raised — for team discussion and, where needed, escalation.
> **Constructive path forward:** <if one exists, name it and link the artifact; else "none identified yet">

## Executive summary (for escalation)

<The vulnerability in plain language. Why it matters even if rare — fallout, not probability.
The decision being requested, from someone with authority to own it, with explicit options (a) / (b) / (c).>

## Concern 1 — <one-line title>

<What the concern is. Why the current direction makes it worse or leaves it open.>

- **Evidence (verified YYYY-MM-DD):** <file:line refs, config, contract fields>
- **What would resolve it:** <the smallest change or companion ticket that closes it>

## Concern 2 — ...

## Decision history

<Dated chronology of how the direction got here — proposals, rejections, reversals — each step pointing at a dated artifact, not memory.>

## Open questions to settle

1. <question> — owner: <who>
```

## Definition of done

An entry is done when a future reader can answer: what was the risk, who raised it and when, what evidence supported it, what decision was made (or requested) in response, and what would resolve it.
