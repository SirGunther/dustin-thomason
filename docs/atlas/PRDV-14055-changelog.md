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
| 2026-07-20 | Orchestration Phase 1 investigation plan | `implemented` | Investigate Upload Manager runtime behavior before writing the implementation spec. |
| 2026-07-21 | `investigations/PRDV-14055-investigation.md` (Phase 2 report) | `active` | Root cause: first number = `activeUploadsCount` (remaining, counts down) in two parallel impls (Callisto store + Triton local). Fix = new "started-or-done" display computed feeding the title; leave neighbors untouched. Disposition: proceed with conditions (semantics + scope locked in Phase 3). |

---

## Session log

### 2026-07-21T00:00:00Z - dustin-thomason (atlas-front-end)

- **Summary:** Orchestration Phases 1–2. Investigated the Upload Manager count defect from source (not Playwright — the count is a pure computed with no runtime unknown; deviation from the recorded browser-loop direction, browser confirmation deferred to Phase 5). Root-caused to `activeUploadsCount` (remaining count) in two parallel implementations. Emitted the investigation report, coverage ledger, diagrams, and seeded test plan. Verdict: proceed with conditions.
- **Plan used:** `~/.claude/plans/mellow-knitting-cloud.md` (approved Phase 1 investigation plan).
- **Files:** `docs/atlas/PRDV-14055/investigations/PRDV-14055-investigation.md`, `.../PRDV-14055-coverage-ledger.md`, `.../PRDV-14055-diagrams.md`, `docs/atlas/PRDV-14055/testing/PRDV-14055-test-plan.md`, `orchestration.md`, `PRDV-14055-original-ticket.md`, this changelog. No atlas-front-end code touched.
- **Commits:** Not committed.
- **Notes:** Two user-flagged audit corrections to the report (dated addenda, not rewrites): §13 adds the mandated Step-1 **Problem Check** lens (evidence-cited; Thin finding = "in progress"/failure handling undefined; Conflation = nothing here); §14 reclassifies uncertainties on a **workflow-vs-code** axis and resolves the code halves evidence-first — concurrency gating is wired so `percentCompleted > 0` is the only clean "in progress" signal (open var #1 code half); both Callisto (App.vue `isCallistoRoute`) and Triton (TritonAppContainer) managers are live in separate apps (open var #2 code half); Triton i18n reuses existing `common.*` keys (open var #3 code half). Remaining Phase 3 grill-me decisions narrowed to: (Q1) mid-batch error/cancel count treatment; (Q2) which app(s) in scope; (Q3) Triton i18n now vs defer.

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

The first number in "Uploading N of M files" is `activeUploadsCount = uploadQueue.filter(f => !f.isComplete && !f.isCancelled && !f.error).length` — a count of **remaining (non-terminal)** files, so it **decreases** as uploads finish. Present in two independent implementations: Callisto (`src/callisto/stores/uploadManagerStore.ts:43-48`, rendered via i18n `uploadingProgressTxt`) and Triton (`src/triton/layouts/MainLayout/FileUploadWrapper/shared/UploadManager/UploadManager.vue:244-248`, rendered as a hardcoded string). Fix = feed the title a "started-or-done" count (`isComplete || percentCompleted > 0`) that rises to the total; leave `activeUploadsCount`/`hasActiveUploads`/`totalProgress` untouched. Detection gap: existing Callisto specs assert the down-behavior; Triton has no spec. Full detail in `docs/atlas/PRDV-14055/investigations/PRDV-14055-investigation.md`.

---

## Attempt history

### Prior API-first framing

**What:** The ticket had previously been considered through an API-oriented lens.

**Result:** Superseded by user direction on 2026-07-20 to use a browser-based Playwright approach for field identification and runtime behavior discovery.

---

## Key technical learnings

1. Pending browser-loop investigation.

---

## Current state (as of 2026-07-21)

Phases 0–2 complete. Root cause confirmed in source: the first number is a "remaining" count (`activeUploadsCount`) in two parallel implementations (Callisto store + Triton local). Investigation report, coverage ledger, diagrams, and seeded test plan are on disk under `docs/atlas/PRDV-14055/`. Next: Phase 3 (probe & spec) — resolve 4 open variables via grill-me, then write the spec. No atlas-front-end code changed yet; branch `PRDV-14055` not yet created (repo currently on `PRDV-16047` @ `ef217844`).

---

## New code introduced

_Not applicable yet._
