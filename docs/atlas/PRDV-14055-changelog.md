# PRDV-14055 - Make Upload Manager count up instead of down

## Ticket

- **ClickUp:** [PRDV-14055](https://app.clickup.com/t/43227262/PRDV-14055)
- **Repo:** `atlas-front-end`
- **Branch:** `PRDV-14055`
- **PR:** _(link when opened)_

---

## Requirements (verbatim)

> As an Ops Atlas User, I want the upload manager to have the number of uploading items to count up instead of down, so that it appears like the uploads are completing successfully and not being removed from the queue as it currently does.
>
> Acceptance Criteria:
> **Notes:** There are two numbers in the upload manager progress message
> "First number" - the "3" in "Uploading 3 of 6"
> "Second number" - the "6" in "Uploading 3 of 6"
>
> Users see the number of completed and in progress uploads as the first number (instead of the number of remaining uploads as it currently is)
> The first number **counts up** to the total number of uploads in the current batch as each begins uploading and is completed
> The happy-path end state should have all files uploaded with both first and second numbers equal
> The second number continues to have the total number of uploads in the current batch

---

## Context

- User redirected the ticket away from the earlier API-first framing.
- Current investigation direction is browser-based: use Playwright and `agents/docs/browser-loop-setup.md` to observe the Upload Manager UI and identify runtime fields/behavior.
- Browser-loop guardrails apply before using Playwright/CDP observation.

---

## Plans

| Added | Plan (path or link) | Status | One-line approach |
| ----- | ------------------- | ------ | ----------------- |
| 2026-07-20 | Orchestration Phase 1 investigation plan | `active` | Investigate Upload Manager runtime behavior with Playwright/browser-loop before writing the implementation spec. |

---

## Session log

### 2026-07-20 - dustin-thomason

- **Summary:** Reviewed the saved ClickUp export artifact and normalized `PRDV-14055-original-ticket.md` to the orchestrate Phase 0 `original-ticket` format. Removed richer export-only sections from the canonical Atlas Phase 0 artifact, kept the original request together, and retained only minimal capture metadata, explicit constraints, context link, and downstream artifact placeholders.
- **Plan used:** Orchestration Phase 0 capture artifact correction.
- **Files:** `docs/atlas/PRDV-14055/PRDV-14055-original-ticket.md`, `docs/atlas/PRDV-14055/orchestration.md`, `docs/atlas/PRDV-14055-changelog.md`
- **Commits:** Not committed.
- **Notes:** The browser extension may still export richer ClickUp metadata for its own feature validation; the Atlas Phase 0 artifact is intentionally stricter.

### 2026-07-20 - dustin-thomason

- **Summary:** Started orchestration for PRDV-14055. Captured the original ticket artifact and scaffolded the orchestration ledger. Recorded the user direction to replace the API-first lens with a browser-based Playwright investigation using `browser-loop-setup.md`.
- **Plan used:** Orchestration Phase 0 capture.
- **Files:** `docs/atlas/PRDV-14055/PRDV-14055-original-ticket.md`, `docs/atlas/PRDV-14055/orchestration.md`, `docs/atlas/PRDV-14055-changelog.md`
- **Commits:** Not committed.
- **Notes:** Next phase is Plan mode investigation planning.

---

## Root cause analysis

_Not started._

---

## Attempt history

### Prior API-first framing

**What:** The ticket had previously been considered through an API-oriented lens.

**Result:** Superseded by user direction on 2026-07-20 to use a browser-based Playwright approach for field identification and runtime behavior discovery.

---

## Key technical learnings

1. Pending browser-loop investigation.

---

## Current state (as of 2026-07-20)

Phase 0 capture is complete. Phase 1 should plan a browser-based investigation of the Upload Manager UI using Playwright and the browser-loop setup/guardrails.

---

## New code introduced

_Not applicable yet._
