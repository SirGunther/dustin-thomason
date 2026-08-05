# Testing-implementation artifact — the scenarios stress-tested

Use this to explain, **for other devs, what was addressed** — the real-world **scenarios** that were stress-tested for this ticket, and what came of each. A test with no stated scenario is arbitrary code execution; the scenario is the stake that makes the test meaningful. This doc is the scenario-level record: it says *why* each test mattered, whether the code held, and — when testing surfaces a **scenario the plan did not cover** — it captures that gap, which is often what drives a change.

Its content is meant to be posted as a **GitHub PR comment**, **NOT** left as a comment in the codebase.

It is the companion to the test plan. The **test plan** lists the scenarios to run and logs pass/fail; **this doc** explains, for a reviewing dev, the scenarios that were actually stress-tested — including the ones found only by testing — and hangs any resulting code change off the scenario that forced it. It is a **living doc**: written as you test, updated as new scenarios surface.

## Output location

```text
docs/<Project>/tickets/<ticket-slug>/testing/<ticket-slug>-testing-implementation.md
```

## When produced

During and after **Phase 5** test execution. Start it as testing begins; add scenarios as they are exercised or discovered; finalize before filling the PR.

## Core rules

- **Scenario-first.** Every entry names the real situation being stress-tested, in terms another dev understands — not "ran `popup.js`" but "user exports a task whose title contains a `#`." No scenario = no meaningful test.
- **Newly-uncovered scenarios are flagged as such.** If testing reveals a situation the plan did not cover, that discovery *is* the point — record it, and note whether it drove a code change or a follow-up.
- **Code changes hang off a scenario.** Each change records the file(s) + observed → expected → implemented fix, under the scenario that forced it — never a change with no scenario behind it.
- **PR-comment content.** Paste it into the GitHub PR; never copy it into the source as a code comment (see `build-implementation-guardrails` §7).
- **Living, not frozen.** Update it as new scenarios surface; the last state before the PR is the one that ships.

## Artifact template

```markdown
# Testing implementation — <Project>/<ticket-slug>

> Companion to [<ticket-slug>-test-plan.md](./<ticket-slug>-test-plan.md). The scenarios stress-tested and what came of each — for other devs. PR-comment content; never a code comment. Living doc.

## Scenarios stress-tested

### Scenario 1 — <the real situation, in a dev's terms>
- **Why it matters:** <the stake — what breaks in the real world if this isn't handled>
- **Covered by the plan?** yes | no — newly uncovered during testing
- **Result:** held | failed → fixed (see change) | follow-up filed
- **Change (if any):** <file(s)> — observed → expected → implemented fix

### Scenario 2 — ...

## PR comment (ready to paste)

<the scenarios above, assembled as the comment/description to post on the GitHub PR>
```

## Definition of done

- Every test maps to a **named scenario** a reviewer can understand — no arbitrary or unexplained test execution.
- **Newly-uncovered scenarios are flagged**, each noted as driving a change or a follow-up.
- Every code change **hangs off its scenario** with file(s) + observed → expected → implemented fix.
- The PR-comment block is assembled and ready to paste; nothing in this doc was copied into the codebase as a code comment.
