# PRDV-16402 — PR draft

> **STILL AN UNFILLED SHELL for Description / Testing / Commit** — staged at Phase 2 (2026-07-29) from the PR template in `docs/pull-request-workflow.md`. Those three sections stay empty until the change is re-landed and verified.
>
> **What changed 2026-07-29:** the **Review findings to address** section below was added at Dustin's request, because the implementation already exists on `origin/PRDV-16402` and these are the comments we intend to make on the PR. That section is review content, not verified-outcome content — the distinction that keeps the shell honest.
>
> When filling the rest: paste the assembled block from [`testing/PRDV-16402-testing-implementation.md`](testing/PRDV-16402-testing-implementation.md) as the Testing and Verification content. Summarize the changelog's Requirements / Current state / latest Session log into Description — do **not** paste the whole changelog. **Never request a reviewer.**

---

## ⚠ SUPERSEDED 2026-07-29 — review concluded: nothing requires changing

**Outcome: re-land as-is.** Branch `PRDV-16402-reland` (cherry-pick of `d97b1c4e`, Larry's authorship preserved), gates run, PR opened.

Two findings below are **withdrawn as wrong**:
- **F1 was built on a fabricated premise.** It claimed the path "emails the team," which was never verified — the dispatcher publishes to an outbound SQS queue whose consumer is outside this repo. What remains is only a question: the conversion request is the last step and is awaited un-guarded, so a failure 500s after the file exists and the SQS message is sent; the cost of that depends on the consumer. Not a finding.
- **F6 was based on stale data.** PRDV-16398 **shipped** (Nova `main` `4128419`) — Nova resolves `'Video Mix'` → `vidMixPreset`. The acceptance criterion is fully verifiable end to end. Nothing to raise with Product.

**F2 is downgraded** from "change before re-landing" to optional: it is a test, it changes no behaviour, and eligibility rules are expected to change anyway. F3–F5 remain cosmetic/perf nits.

Root cause of both errors and the proposed rule changes: [`PRDV-16402-investigation-failure-analysis.md`](PRDV-16402-investigation-failure-analysis.md). Current, correct version: [`testing/PRDV-16402-testing-implementation.md`](testing/PRDV-16402-testing-implementation.md).

<details>
<summary>Original findings list, kept for the record</summary>

## Review findings to address (added 2026-07-29 — post-review, pre-re-land)

**Prior history this PR must not lose:** implemented by Larry Adams as `d97b1c4e` on `origin/PRDV-16402`; merged to `main` via **PR #397**; reverted 7 minutes later by **PR #398** with the stated reason *"I should not have merged before. I was moving too fast. I thought it was a different PR. Sorry."* **No technical objection was raised and CI was clean** (ESLint, Prettier, type-check). The branch re-applies onto current `main` with no conflict. Whoever opens the next PR should say this explicitly, so the revert is not mistaken for a rejection.

**Full plain-language scenarios for every item below — observed → expected → why the current implementation won't get us there — are in [`testing/PRDV-16402-testing-implementation.md`](testing/PRDV-16402-testing-implementation.md), which also carries a ready-to-paste PR comment.**

### Change before re-landing

- [ ] **F1 — Move the conversion request ahead of the audit write and the SQS notification.** It is currently the last step, so a failure returns "file failed to upload" *after* the team has been emailed; the user's retry then sends a second email, creates a duplicate file-attachment record, and requests the conversion again as a separate request — the video converts twice. Moving it to immediately after `createProceedingFile` makes a failure cheap. There is no background sweeper for missed requests, so failing loudly is right — it just needs to fail earlier. *(File: `multi-part-upload-proceeding-job-submission-file-complete-upload.service.ts`. Scenario 1.)*
- [ ] **F2 — Add a repository-level test for `findVideoFileForVideoTranscodeOutboxByFileId`.** The change's best decision — reusing the existing eligibility query instead of restating it — is also the reason unit tests can't verify eligibility: with a mocked repository, "not eligible" and "returned nothing" are the same thing. Nothing at any level currently proves the new lookup still filters on proceeding attachment, Video track, and video MIME type, or still refuses a file belonging to a different job. One test against a real database closes it. *(File: `job-submission-form-file-attachment.repository.ts`. Scenario 2.)*

### PR comments — not blockers

- [ ] **F3 — `findById` loads the whole job record plus 14 relations, once per upload,** to read three fields; one of those relations is the list of every file already attached, so the cost grows with uploads per form. A narrow lookup is better; the eligibility check would need to accept a simpler shape. *(Scenario 3.)*
- [ ] **F4 — Restore ~6 blank lines the diff removes** in methods it doesn't otherwise change, including the pending-upload path and the shared file-creation helper, so the diff shows only the intended change. *(Scenario 4.)*
- [ ] **F5 — `form.jobDate` arrives as a `'YYYY-MM-DD'` string but the writer port declares `Date`.** Pre-existing mislabel, now at two call sites; works only because the converter accepts both. Widen the port type and use the string form in fixtures — the existing submit-path spec's `new Date(...)` fixture does not exercise production shape. *(Scenario 5.)*

### Call out in the PR, but do not try to fix here

- [ ] **F6 — The ticket's acceptance criterion cannot be signed off on this PR.** It says files are "transcoded matching the specs of the initial job submission," but Nova ignores `videoTranscodeValue` and applies Standard to everything until **PRDV-16398** ships (unshipped, blocked on the Video Mix encoder settings from ops). A tester will see the file come back converted **with the wrong settings** — "it worked" and "it's wrong" both true. State the provable bar instead: *the correct request was made, carrying the job's stored setting.* Larry's original PR test plan already used that bar. Recommend splitting the AC with Product. *(Scenario 6.)*
- [ ] **F7 — Link the accepted risks** recorded in [`PRDV-16402-future-development-concerns.md`](PRDV-16402-future-development-concerns.md) rather than restating them. Two are worth naming in the PR body: `PATCH /job-submission-form` has no auth guard, no ownership check, and no status precondition, and can rewrite the conversion setting **and** the submission status on an already-submitted form; and nothing snapshots the conversion setting at submit, so "the initial submission" is not something the data model can record. Neither is caused or widened by this change.

</details>

---

## Title

`PRDV-16402: <short imperative description>`

## Clickup

### [Clickup - PRDV-16402 - Transcode additional video uploads to submitted AJSFs](https://app.clickup.com/t/43227262/PRDV-16402)

## Description

_(Phase 5 — bullets: what changed and why. Frame Problem → Requirement → Solution. Placeholders for the points already known to belong here:)_

- _<the gap that was closed>_
- _<why the eligibility rule was reused rather than re-expressed>_
- _<the divergences from the coworker spec, and why>_
- _<the AC8 / PRDV-16398 gate, stated explicitly so QA is not handed an unverifiable criterion>_
- _<accepted residual risks, linking `PRDV-16402-future-development-concerns.md`>_

## Commit

```
<40-character hash from `git rev-parse HEAD` after push — pwsh: `git rev-parse HEAD | Set-Clipboard` first>
```

## Testing and Verification

_(Phase 5 — the assembled block from `testing/PRDV-16402-testing-implementation.md`, scenario-first. Screenshots are the primary evidence bar; name automated suites only where they matter. Keep this heading even if the body is short.)_

- _<manual verification: submitted AJSF upload → asserted `outbox_events` row with the form's preset>_
- _<gate results table: exact command + scope + result, final post-change state only>_
- _<blocked scenario: HP-7 end-to-end preset match, gated on PRDV-16398>_

## Checklist

- [ ] Description provided
- [ ] Clickup link
- [ ] Evidence provided
