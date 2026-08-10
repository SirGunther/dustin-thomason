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
- **Every manual scenario states the before/after contrast and where the change is observable — including when the answer is "nowhere in the UI".** A falsifiable assertion is not the same as a runnable procedure. A plan can name the right assertion and still be unexecutable by the person holding the keyboard, because it never said what the old behavior was, what the new behavior looks like, or which surface to look at. That gap is worst on backend-only work: the UI is byte-for-byte identical, so an operator told to "upload a file and verify the event" reasonably screenshots the screen that did not change. State it plainly — *"nothing changes in the UI; the evidence is the row in table X"* — and give the **exact command or query** that produces it, ready to paste. If a reviewer expects a screenshot, the plan says what is in frame.
- Negative paths are first-class — what must fail **visibly** instead of corrupting silently (invalid input, unauthorized caller, concurrent actors, boundary values).
- The results log follows the verification-gate reporting standard (see the `ticket-changelog` rule): exact gate command, scope, result. "Tests passed" by itself is not sufficient. Gates run serially (`--runInBand` / `--maxWorkers 1`) and are reported for the **final post-change state only**.
- If a scenario cannot be executed, record it as **blocked** with the reason, residual risk, and follow-up — never silently drop it.

## Artifact template

```markdown
# Test plan — <Project>/<ticket-slug>

> Seeded from [<ticket-slug>-investigation.md](../investigations/<ticket-slug>-investigation.md) §9 on YYYY-MM-DD. Refined by spec: <link or "pending">.

Status: seeded / refined / in-execution / complete

## Scope and surfaces under test

- <the behavior being proven, and the surfaces (components, endpoints, tables) it renders/executes on>

## Happy path

- [ ] HP-1: <setup> → <action> → <observable outcome>

## Negative paths

- [ ] NP-1: <invalid input / unauthorized / concurrent case> → <the visible failure required>

## Edge cases

- [ ] EC-1: <boundary / empty / extreme> → <expected behavior>

## Manual verification (required whenever a human runs a step)

Written so someone who did not build the change can execute it without asking a follow-up question.

**Before / after** — say what changes and, just as importantly, what does not:

| | Before | After |
| --- | --- | --- |
| <the user-facing surface> | <old behavior> | <new behavior, or **identical**> |
| <where the change is actually observable> | <old state> | <new state> |

> If the change is invisible in the UI, say so in one blunt sentence and name the surface that does hold the evidence (a table, a log, a queue, a file). Otherwise the operator screenshots the unchanged screen.

**Preconditions** — services, credentials, seed data, one-time environment setup, and the baseline reading to take *before* acting.

**Steps** — numbered, with the exact URL/route, and any choice that matters called out (which track, which record, which option).

**Evidence** — the exact command or query, paste-ready, plus what should be in frame if a screenshot is expected:

```sql
-- or shell/HTTP; whatever produces the evidence
```

**Pass / fail** — per step, both columns:

| Step | Passes | Fails |
| --- | --- | --- |
| M-1 | <observed result> | <the specific wrong result, and what it would mean> |

Name which step is load-bearing and why — the one whose failure means the defect is back.

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
