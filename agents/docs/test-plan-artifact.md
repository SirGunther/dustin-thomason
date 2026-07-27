# Test plan artifact — how to test the implementation

Use this instruction to make "how we will prove it works" a durable artifact of its own, **built in from the investigation step** — not reconstructed at implementation time. The investigation report's validation plan (§9) already produces the content; this artifact makes it executable and trackable through implementation and review.

## Output location

```text
docs/<Project>/tickets/<ticket-slug>/testing/<ticket-slug>-test-plan.md
```

## Lifecycle

| Phase | Action |
| --- | --- |
| Investigation report (Phase 2) | **Seed** the test plan from report §9: happy path, negative paths, test map, gates |
| Probe & spec (Phase 3) | **Refine** as locked decisions land — resolved open variables become concrete assertions |
| After approval, before implementation (Phase 5 start) | **Revise.** The implementation plan is approved but no code is written yet; do a quick revision/refinement of **this test plan** so it matches what was actually approved — the approved plan can differ from what the spec proposed. Test plan only; a quick pass, not a rebuild. |
| Implementation (Phase 5) | **Execute.** Check off scenarios, fill the results log with exact command + scope + result. The **scenarios** actually stress-tested — and any code change they force — are explained for other devs in the **testing-implementation artifact** (scenario-first; file(s) + observed → expected → fix, for the PR comment — never a code comment), not here. |
| Manual review (Phase 6) | **Cite**: the review summary references this file's results, not a prose claim of "tests passed" |

## Core rules

- Scenarios are **falsifiable**: each states the setup, the action, and the observable outcome that passes or fails it.
- Negative paths are first-class — what must fail **visibly** instead of corrupting silently (invalid input, unauthorized caller, concurrent actors, boundary values).
- The results log follows the verification-gate reporting standard (see the `ticket-changelog` rule): exact gate command, scope, result. "Tests passed" by itself is not sufficient. Gates run serially (`--runInBand` / `--maxWorkers 1`) and are reported for the **final post-change state only**.
- If a scenario cannot be executed, record it as **blocked** with the reason, residual risk, and follow-up — never silently drop it.

## Artifact template

```markdown
# Test plan — <Project>/<ticket-slug>

> Seeded from [<ticket-slug>-investigation.md](../investigations/<ticket-slug>-investigation.md) §9 on YYYY-MM-DD. Refined by spec: <link or "pending">.

Status: seeded / refined / revised (post-approval) / in-execution / complete

## Scope and surfaces under test

- <the behavior being proven, and the surfaces (components, endpoints, tables) it renders/executes on>

## Happy path

- [ ] HP-1: <setup> → <action> → <observable outcome>

## Negative paths

- [ ] NP-1: <invalid input / unauthorized / concurrent case> → <the visible failure required>

## Edge cases

- [ ] EC-1: <boundary / empty / extreme> → <expected behavior>

## Test map

| Repo | Suite | Asserts |
| --- | --- | --- |
| <repo> | <spec file or suite path> | <what it proves> |

## Gates

| Gate | Command |
| --- | --- |
| audit | `npm audit --audit-level=high` |
| lint | `npm run lint` |
| tests | `<repo's serial test command>` |

## Results log (filled at execution)

| Date | Gate/Scenario | Command | Scope | Result | Exception / risk |
| --- | --- | --- | --- | --- | --- |
```

## Definition of done

The test plan is done when every scenario is checked off or explicitly blocked-with-reason, the results log holds the final post-change gate runs, and the manual review can cite this file instead of restating evidence.
