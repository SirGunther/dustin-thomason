---
description: Boundary rules for a runtime browser-observation loop (Playwright/CDP/MCP) and for any CSS/layout/interaction debugging — fix the responsible cascade rule not the symptom, explain magic constants, keep independent constants independent, treat a green check as necessary-not-sufficient, and escalate after bounded iteration instead of spiraling.
scope: always
codex: include
---
# Browser-loop guardrails (dustin-thomason)

**When this applies:** whenever you drive or observe a live browser to diagnose or verify front-end behavior (Playwright, raw Chrome DevTools Protocol, or a browser MCP), **and** more generally whenever you fix a CSS / layout / interaction defect. The observe-fix loop makes iteration faster, which also makes symptom-patching faster — these rules protect *why* a fix is correct, which verification alone cannot. Capability wiring, setup, and tooling live in the playbook [browser-loop-setup.md](../docs/browser-loop-setup.md); the authoritative spec is [runtime-browser-loop-spec-1.md](../../docs/agents/runtime-browser-loop-spec-1.md). Load these rules **before** using the loop.

These are enforced constraints, not suggestions.

1. **No specificity band-aids.** Do **not** resolve a cascade conflict by adding a higher-specificity override or `!important`. Identify the responsible rule (via matched-styles / cascade provenance) and fix or remove it. If an override is genuinely unavoidable, it **must** carry a comment naming the exact rule it intentionally beats and why removal was not possible.

2. **Magic constants must be explained.** Any numeric offset, nudge, or constant introduced to make layout line up **must** carry a comment stating the real quantity it represents and why it exists. An unexplained tuned number is not an acceptable end-state even when it works.

3. **Independent constants stay independent.** Constants addressing distinct scenarios **must** remain separate variables even if they currently share a value. Do **not** couple, deduplicate, or derive one from another because adjusting either currently moves the output the same way. (This is the specific anti-body for black-box tuning collapsing two unrelated quantities into one.)

4. **A passing check is necessary, not sufficient.** "It lines up now / the assertion is green" authorizes nothing about correctness of cause. Prefer a fix that follows from a model of *why* the bug occurred over one found by nudging until output matches. Where a tuned fix is shipped consciously, say so explicitly and record the residual risk.

5. **Fix the rule, not the symptom.** When runtime observation reveals the responsible party, address that party. Do **not** add a compensating layer that leaves the original defect in place.

6. **Bounded iteration — escalate instead of spiraling.** If repeated observe-fix cycles on the same defect fail to converge within a small fixed number of attempts (default **three**), **stop tuning** and escalate. Continuing to nudge toward a passing state past this point is the black-box spiral this setup makes *faster*; the correct output there is a structured account of the uncertainty, not another guess.

**Escalation format (rule 6).** When you hit the attempt cap, report — do not guess again:

- **Attempts:** each attempt, the change made, and what the runtime showed (geometry / matched styles / console), not just pass/fail.
- **Competing hypotheses:** the candidate causes still in play and what would distinguish them.
- **Decision needed:** the specific question or direction you need from the user.

```
Good: matched-styles shows .panel width struck through by `.layout .panel { width }`;
      remove that stale owner (the real cause) rather than adding a heavier selector.
      A 12px nudge is commented: "12 = scrollbar gutter (see .list overflow-y)".
Bad:  add `width: 600px !important` and ship because the screenshot now matches;
      or fold two separately-derived offsets into one shared constant because both
      happened to be 8px this session.
```
