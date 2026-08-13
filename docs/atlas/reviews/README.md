# PR reviews

Per-PR review artifacts for PlanetDepos repos. One file per PR reviewed.

## Purpose

These are **outbound** reviews — the record of reviewing someone else's PR, as distinct from
[`docs/reviewers/pr-review-patterns.md`](../../reviewers/pr-review-patterns.md), which is the
**inbound** record of what reviewers ask *us* to change.

The two feed each other. A review written here runs the `pr-review-patterns` checklist as one of its
passes, so the classes we've been asked to fix become the classes we check for. When a review here
surfaces a genuinely new class of change, it gets promoted back into `pr-review-patterns.md` as a new
Pattern.

## Naming

`PRDV-XXXXX-<repo>-<pr-number>-review.md`

Example: `PRDV-16310-callisto-403-review.md`

When a PR spans two tickets, use the lower/primary ticket number and name both inside the doc.

## Method

Every review in this folder follows the same three passes, in order. The order matters — the
checklist pass is worth little until the implementation is actually understood.

| Pass | What it does | Evidence required |
| --- | --- | --- |
| **1. Documentation** | Read the PR body, linked tickets, and the contracts/conventions the change claims to follow. Establish what the PR says it does. | Links to the real artifacts — ticket, contract package, repo `.cursor/rules/`. |
| **2. Implementation** | Read the actual diff against the surrounding code. Compare to the established sibling pattern in the same repo. Run the gates. | Exact commands + results. Claims about type behavior, test outcomes, or compile behavior must be **run**, not reasoned about. |
| **3. Checklist** | Walk [`pr-review-patterns.md`](../../reviewers/pr-review-patterns.md) Classes A–H against the diff and record each as hit / clean / not-applicable. | Per-class verdict, including the clean ones — an absent class is verified, not assumed. |

## Evidence standard

Same standard as the shipping checklist in `ticket-changelog`:

- A finding states **where** (file:line), **why it matters**, and **what would change**.
- A claim that something compiles, passes, or breaks is **verified by running it**, and the review
  records the command. "This cast is unnecessary" is an assertion; "removed the cast, `npx tsc
  --noEmit` exit 0" is a finding.
- **Read comparison code out of a branch ref, never the working tree.** `git show <ref>:<path>` or
  `git grep <ref>`, not `cat`. A working tree carries uncommitted local work, and code read that way
  will look exactly like established repo precedent while existing on no branch the PR author has
  ever seen. This cost the first draft of the #403 review three findings — see the correction note
  in that file.
- **Clean is a result.** A class with no instances gets recorded as clean, not omitted — otherwise a
  reader can't tell the difference between "checked and fine" and "never looked."
- Findings are ranked and each carries an explicit **blocking / non-blocking** call, so the author
  knows what actually gates the merge.

## Index

| Review | Repo / PR | Ticket(s) | Author | Verdict |
| --- | --- | --- | --- | --- |
| [PRDV-16310-callisto-403-review.md](PRDV-16310-callisto-403-review.md) | [callisto-back-end #403](https://github.com/planetdepos/callisto-back-end/pull/403) | PRDV-16310 | midnjerry | Approve with non-blocking cleanups |
| [PRDV-16315-callisto-410-review.md](PRDV-16315-callisto-410-review.md) | [callisto-back-end #410](https://github.com/planetdepos/callisto-back-end/pull/410) | PRDV-16315 / PRDV-16316 | midnjerry | Approve with cleanups |

### Draft comments

[pr-comments-draft-403-410.md](pr-comments-draft-403-410.md) — categorized draft comments for both PRs
(architecture / code / docs / tests / process), plus the killed-candidate list and the recommended
minimum set to post. **Nothing posted to GitHub.**

### Cross-PR items

These span both reviews and should be handled together rather than per-PR:

| Item | Where | Action |
| --- | --- | --- |
| `as unknown as Record<string, unknown>` in outbox converters | #403 F1 (1 site), #410 G1 (2 sites) | One-line deletion at each of the 3 sites; verified `tsc --noEmit` exit 0. Fixing #403 alone leaves two behind. |
| Widen `pr-review-patterns` Pattern 3 | `docs/reviewers/pr-review-patterns.md` | 3 production instances across 2 PRs now meet the 2+ promotion rule — rescope from "test-mock casts" to "any cast that erases a contract type." Do it once the PRs merge. |
| No test that a failing outbox write rolls back | #403 F3, #410 G4 | Same six-line rejection test on each transaction script. |
| Merge collision | both | `FEATURE_FLAG_NAMES` + `GrantingClientAccessModule.imports`; second to land rebases two lines. |
