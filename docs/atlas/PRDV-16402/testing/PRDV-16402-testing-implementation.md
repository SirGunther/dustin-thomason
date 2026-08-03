# Testing implementation — atlas/PRDV-16402

> Companion to [PRDV-16402-test-plan.md](./PRDV-16402-test-plan.md). PR-comment content; never a code comment.

## In one paragraph

The conversion preset is chosen **once on the job submission form**, by the Video-role person filling out the AJSF. Until now, only *submitting* the form asked for videos to be converted — so any video uploaded to a job **after** it was submitted was stored and then silently never converted. This change makes the post-submit upload path read the form's saved preset and ask for that file to be converted too, using the same eligibility rule and the same event the submit path already uses. Nova's side — actually applying the chosen preset — shipped in PRDV-16398.

## Status of this review

**Implemented by Larry Adams**, branch `origin/PRDV-16402`, commit `d97b1c4e`. It merged to `main` as PR #397 and was reverted 7 minutes later by PR #398, in his words: *"I should not have merged before. I was moving too fast. I thought it was a different PR. Sorry."* **No technical objection was raised; CI was clean.**

**Reviewed 2026-07-29. Nothing requires changing. Recommend re-landing as-is** — done on branch `PRDV-16402-reland` (cherry-pick of `d97b1c4e`, authorship preserved).

## What was verified

| Check | Result |
| --- | --- |
| 29 tests across 5 suites, serial | pass — incl. Larry's 6 new transaction-script tests and 3 new service tests |
| Submit path unchanged | pass — its 7 existing tests green, assertions unmodified |
| Pending upload path still does not request conversion | pass — asserted in the new service spec |
| Nova applies the selected preset | verified in source: `resolveTranscodePreset('Video Mix')` → `vidMixPreset`, Nova `main` `4128419` |
| Eligibility rule has one definition, not two | verified — the new single-file lookup shares `buildVideoTranscodeOutboxQuery` with the submit path rather than restating the conditions |
| lint | pass, no files mutated |
| audit | **fails, pre-existing and unrelated** — 68 high; the change touches no dependency file and `package-lock.json` is byte-identical to `main`, so this is `main`'s existing state, not something introduced here |

## Optional follow-ups — none required

None of these is a defect; the system works without all of them.

1. **No test covers the SQL eligibility conditions.** Because eligibility lives in the shared query, unit tests can't reach it — with a mocked repository, "ineligible" and "returned nothing" look identical. A future change to that shared query could make the two paths disagree with every test still passing. Behaviour-neutral today. Deliberately not added, since eligibility rules are expected to change.
2. **`findById` loads the whole job record plus 14 relations** once per upload to read three fields. Perf wart.
3. **~6 unrelated blank lines removed**, which makes the diff look wider than the change.
4. **`jobDate` arrives as a `'YYYY-MM-DD'` string but the writer port declares `Date`.** Pre-existing mislabel, now at two call sites; works because the converter accepts both.
5. **Ordering:** the conversion request is the last step and is awaited un-guarded, so a failure returns a 500 after the file already exists and the outbound SQS message has been published. **What that costs depends on what consumes that queue, which lives outside this repo and was not verified** — flagged as a question, not a finding.

## Corrections to earlier versions of this document

- An earlier draft claimed the completed-upload path "emails the team," and built a duplicate-email/double-conversion scenario on it. **That was never verified** — the dispatcher publishes to an outbound SQS queue whose consumer is outside this repo. Removed; see item 5 for what is actually known.
- An earlier draft claimed PRDV-16398 was unshipped and that the acceptance criterion was therefore unverifiable. **It shipped** (Nova `main` `4128419`). The AC is fully verifiable.
- Root-cause analysis of both errors, and the proposed rule changes: [`../PRDV-16402-investigation-failure-analysis.md`](../PRDV-16402-investigation-failure-analysis.md).

## Not in scope — risks noticed while reviewing

Recorded in [`../PRDV-16402-future-development-concerns.md`](../PRDV-16402-future-development-concerns.md); neither is caused or widened by this change. `PATCH /job-submission-form` has no auth guard, no ownership check, and no status precondition, and can rewrite the conversion preset **and** the submission status on an already-submitted form. And nothing snapshots the preset at submit time, so a preset changed after submit silently applies to later uploads.

## PR comment (ready to paste)

> Re-lands #397, which was reverted by #398 because it had been merged before review by mistake — not for any technical reason. CI was clean and no objection was raised. Cherry-picked from `d97b1c4e` with Larry's authorship preserved.
>
> **What it does.** The conversion preset is chosen once on the job submission form. Previously only *submitting* the form asked for videos to be converted, so any video uploaded to a job after submission was stored and then silently never converted. This makes the post-submit upload path read the form's saved preset and request conversion for that file, reusing the submit path's eligibility rule and event. Nova's half — applying the selected preset — shipped in PRDV-16398.
>
> **Reviewed, nothing required changing.** Worth calling out one decision: rather than restating the eligibility conditions for the new path, it extracts the existing query into a shared builder so the single-file lookup inherits them. One definition of the rule, not two.
>
> **Verified:** 29 tests across 5 suites pass serially, including 9 new ones and the first spec this service has ever had; the submit path's 7 existing tests are green with assertions unmodified; the pending upload path is asserted to still make no request. lint clean. `npm audit` fails with 68 pre-existing high advisories — this change touches no dependency file and `package-lock.json` is identical to `main`, so that is `main`'s existing state.
>
> **Optional, not done here:** no test covers the SQL eligibility conditions (unit tests can't reach them once the rule lives in the shared query — behaviour-neutral, and eligibility is expected to change anyway); `findById` loads 14 relations per upload for three fields; a few unrelated blank-line deletions widen the diff; and `jobDate` is a string typed as `Date`, a pre-existing mislabel now at two call sites.
