# PR draft — PRDV-16398

> **⚠ UNFILLED SHELL — staged in Phase 2, body written in Phase 5.**
> Headings and placeholders only. Do not fill the Description or Test Evidence before the change is implemented and verified: scope can still move in Phases 3–4, and the Test Evidence block is assembled from `testing/PRDV-16398-testing-implementation.md` after the scenarios actually run.
> Template source: `agents/docs/pull-request-workflow.md`.

---

## Title

`PRDV-16398: <short imperative description>`

## Clickup

https://app.clickup.com/t/43227262/PRDV-16398

## Description

_Pending Phase 5. Assemble from `PRDV-16398-why-these-changes.md` (categorized change breakdown + why it shipped together) and the changelog's latest session log. Do not paste the whole changelog._

_Per `build-implementation-guardrails` §7: change rationale (observed → expected → fix) belongs here, never as a source comment._

### Commit

```
<forty-character hash from `git rev-parse HEAD` after push>
```

## Test Evidence

_Pending Phase 5. Paste the assembled block from `testing/PRDV-16398-testing-implementation.md` — scenario-first, each change hung off the scenario that forced it._

_Must include, per the test plan:_

- _the red→green proof (the new step spec fails on `02b56c0`, passes after)_
- _`ffprobe` output for the Video Mix run vs. the Standard run of the same clip — the only evidence that closes AC 1 and AC 2_
- _the gate table (audit → lint → tests) with exact command, scope, and result_

## Checklist

- [ ] _Pending — from the target repo's `.github/pull_request_template.md` if present_

---

## Reviewer notes to remember (staged, not PR content yet)

- **No reviewer is to be requested** on this PR unless Dustin explicitly asks in the moment (`git-commit-workflow` — absolute prohibition).
- The bundle includes vocabulary/doc/fixture changes that are **not** scope creep — `PRDV-16398-why-these-changes.md` → "Why it shipped together" carries that argument, tied to acceptance criteria 7 and 8.
- Out-of-scope risks were recorded, not ignored: link `PRDV-16398-future-development-concerns.md` (fallbacks are invisible downstream of Nova).
