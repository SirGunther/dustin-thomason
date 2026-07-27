# PRDV-14055 - Make Upload Manager count up instead of down

## Ticket

- **ClickUp:** [PRDV-14055](https://app.clickup.com/t/43227262/PRDV-14055)
- **Repo:** `atlas-front-end`
- **Branch:** `PRDV-14055`
- **PR:** [atlas-front-end #548](https://github.com/planetdepos/atlas-front-end/pull/548) (no reviewer; awaiting video evidence + per-file comments)

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
| 2026-07-21 | `investigations/PRDV-14055-investigation.md` (Phase 2 report) | `implemented` | Root cause: first number = `activeUploadsCount` (remaining, counts down) in two parallel impls (Callisto store + Triton local). Fix = new "started-or-done" display computed feeding the title; leave neighbors untouched. Disposition: proceed with conditions (semantics + scope locked in Phase 3). |
| 2026-07-21 | Story spec → [larry-adams PR #26](https://github.com/planetdepos/larry-adams/pull/26) (`systems/neptune/callisto/maintenance/upload-manager-count-up/PRDV-14055-upload-manager-count-up.md`); copy in `docs/atlas/PRDV-14055/specs/` | `active` | Callisto-only; add store computed `isComplete \|\| error \|\| isCancelled \|\| percentCompleted > 0`, feed the title, leave neighbors unchanged; mark failures terminal so they count, toast, and resolve the batch. User-approved implementation began on `PRDV-14055`. |

---

## PR #26 review thread (resolved — folded in)

- **midnjerry:** "I like the idea of counting error files too... how will this handle 0 byte files? Those cannot be uploaded and will error out, but they won't go over 0% completed."
- **dthomason-pd:** "NVM, folding it in, because it's a feature and will make errors known/testable." → failure handling **in scope**.
- **midnjerry:** "0-byte is an easily testable known issue. I would also like AC criteria against offline mode mid upload. if yo upload 20 files at 10MB each and in process you turn off network, what should expected result be?"
- **Resolution (2026-07-21):** fold failure handling into this ticket — mark failed uploads terminal so they're counted, toasted, and resolve the batch; add an offline/interruption AC (expected: fail gracefully — mark failed, count up, resolve, toast; not retry). Spec updated + pushed (larry-adams `f4f4dab`).

## Contingencies (not scheduled)

- **DRY / config refactor** — if a PR #548 reviewer flags the repeated terminal/active predicate in `uploadManagerStore.ts` (or the scattered upload constants), execute `PRDV-14055-dry-refactor-contingency.md`. Pure cleanup, no behavior change; do not do proactively.

## Session log

### 2026-07-23 - PR #548 Lana review fixes validated + responded

- **Summary:** Codex implemented the Lana (p-lana) review fixes per `PRDV-14055-lana-review-fixes-plan.md` and pushed to origin `PRDV-14055` (`18a6bf05`). Validated the diff against the plan: i18n for all 4 user-facing strings in `useUploadItem.ts` (2 new `common.json` keys + reused `uploadFailedTxt`), `PROMISE_STATUS` in global `@globalUtils/constants.ts` used at the `rejected` check, error-name literals left alone, spec updated with `vue-i18n` identity mock + key-form assertions.
- **Verified:** `npm run lint` clean; focused serial Vitest 6 files / 51 tests pass; type-check enforced by the pre-push hook that landed `18a6bf05`.
- **Responded on PR #548:** in-thread replies to her 4 comments (3 i18n = short "done + key"; the constants one flags the nearby `CanceledError`/`AbortError` names as an FYI + offer, no taxonomy verdict) + 1 general comment noting the extra cancel-string localization.
- **Nothing pushed** (already on origin); no code changed this session.

### 2026-07-22 - Implementation reviewed + narrowed; opening PR (atlas-front-end)

- **Summary:** Reviewed Codex's implementation. It had expanded beyond the approved Callisto-only spec (10s upload watchdog + axios request `timeout` + a guarded global `apiClient`/`useApiRequest` change). Recommended and planned a narrowing: keep the abort-based watchdog (the real mechanism; aborted requests reject `ERR_CANCELED`, not in the retryable list), drop the redundant axios-timeout belt + global changes. Codex executed the narrowing plan.
- **Verified (final state):** `globalApi/apiClient.ts` + `useApiRequest.ts` reverted to main; `useUploadChunk.ts` back to main; new chunk timeout-spec deleted; `useUploadComplete.spec.ts` back to main. Kept: watchdog, `completedOrActiveUploadsCount`, all-failed closeout fix, `constants.ts`, `types.ts` `signal?`, `useUploadComplete` `signal`. Diff is now entirely `src/callisto/`.
- **Gates:** `npm run lint` pass; `npx vitest run --maxWorkers 1` over store/title/manager/upload-item/request specs — 6 files, 51 tests pass. `npm audit --audit-level=high` unchanged pre-existing blocker (93 vulns, no deps changed).
- **PR:** opening on `atlas-front-end` `PRDV-14055` → main (no reviewer); body from `PRDV-14055-pr-draft.md` with per-scenario video headers. Per-file "why" comments to be posted on GitHub Files-changed tab (not in code).

### 2026-07-22 - Deduplicate failed-upload notifications

- **Summary:** Within PRDV-14055's failure-visibility scope, changed terminal upload failure notifications to name the failed file and use `multiple: false`, preventing mass offline failures from stacking identical toasts. No retry, resume, cancellation, or upload-flow behavior changed.
- **Verification:** `npm run lint` passed; focused `useUploadItem` Vitest suite passed (3 tests).
- **Commits:** none yet.

### 2026-07-21 - Implementation started

- **Summary:** User approved the Phase 3 Callisto-only spec and Phase 4 plan. Refined the test plan to cover terminal failure handling, zero-byte completion failures, and offline interruption. Updated `main` from `origin/main` and created `PRDV-14055`.
- **Scope decision:** The current approved plan includes setting the queue-visible error flag on failure. This supersedes the earlier local-only session note that deferred that behavior.
- **Commits:** none yet.

### 2026-07-21 - Callisto Upload Manager implementation

- **Summary:** Added `completedOrActiveUploadsCount` (`isComplete || error || isCancelled || percentCompleted > 0`) and wired the title to it. Upload chunk and completion failures now set a queue-visible error and show failure feedback, allowing the existing terminal-state behavior to resolve the batch.
- **Files:** `uploadManagerStore.ts`, `UploadManager.vue`, `useUploadItem.ts`, and focused store/title/upload-item specs.
- **Verification:** lint passed; focused serial Upload Manager suites passed (47 tests). `npm audit --audit-level=high` remains blocked by 93 existing dependency vulnerabilities (90 high), with no fix available for affected paths; no dependencies changed.
- **API docs:** not relevant — checked the Callisto Upload Manager UI/store/composable surfaces; no HTTP route, DTO, auth, or OpenAPI surface changed.
- **Commits:** none yet.

### 2026-07-21T03:30:00Z - Scope decision on the 0-byte review (spec re-scoped locally, not pushed)

- **Summary:** User decided the silent-failure/hang fix (failures set only a component-local `isFailed`, never a queue terminal flag) is **out of scope** for PRDV-14055 and gets its **own ticket** with a cross-system survey (Triton likely affected) — same treatment as the Triton deferral. Re-scoped the spec: kept the terminal-inclusive count formula `isComplete || error || isCancelled || percentCompleted > 0` (so a 0-byte file rejected at upload-**start** is counted), removed the `useUploadItem` change, added a "Known limitation" section, back to Small (2 pts). Recorded LD-004 and future-development-concerns Concern 3.
- **Files (dustin-thomason, local only):** spec copy, locked-decisions (LD-001 refined + LD-004), future-development-concerns (Concern 3), orchestration ledger, this changelog. **Not pushed.**
- **Notes:** Reviewer response revised to reflect the deferral; awaiting user go-ahead to post + push to PR #26.

### 2026-07-21T03:00:00Z - PR #26 review response (spec updated locally, not pushed)

- **Summary:** Reviewer midnjerry requested changes on PR #26 with one concern: how does the count handle 0-byte files (error out but never exceed 0%)? Verified in code: no client-side 0-byte guard; `partsCount = ceil(0/CHUNK_SIZE) = 0` → `uploadComplete` called with 0 parts. Fails-at-start sets queue `error` (visible); fails-at-complete sets only local `isFailed` (invisible to store — pre-existing gap). Updated the spec: count formula now `isComplete || error || isCancelled || percentCompleted > 0`, plus a `useUploadItem` change to set a queue-visible `error` on failure so 0-byte/mid-upload failures are counted and batches complete. LD-001 refined accordingly.
- **Files (dustin-thomason, local only):** `specs/PRDV-14055-upload-manager-count-up.md` (copy), `specs/PRDV-14055-locked-decisions.md`, orchestration ledger, this changelog. **Not pushed** — larry-adams PR #26 unchanged pending user go-ahead.
- **Commits:** none. Response drafted for the reviewer, awaiting user approval to post + push.
- **Notes:** point range bumped to Small (2–3) — the useUploadItem terminal-flag change touches shared upload behavior; flagged as an open scope question to the reviewer (this ticket vs companion).

### 2026-07-21T02:00:00Z - larry-adams (spec PR) + dustin-thomason

- **Summary:** Phase 3 probe & spec. Grill-me locked three decisions: LD-001 failures stay counted (Product: "should not drop back"), LD-002 Callisto-only scope, LD-003 Triton deferred. Authored the story spec in the larry-adams wiki format (PRDV-12264 maintenance shape, frontmatter, no personal P→R→S framing) and PR'd it for Larry Adams review.
- **Spec:** `larry-adams` `systems/neptune/callisto/maintenance/upload-manager-count-up/PRDV-14055-upload-manager-count-up.md`, indexed in `systems/README.md` Maintenance. Copy retained in `docs/atlas/PRDV-14055/specs/`.
- **PR:** [larry-adams #26](https://github.com/planetdepos/larry-adams/pull/26) — no reviewer tagged.
- **Files (dustin-thomason):** locked-decisions ledger, future-development-concerns (Triton follow-up + Product future-context note), spec copy, diagrams (LD-001/scope), orchestration ledger, this changelog.
- **Commits:** larry-adams `15ecc4c` (spec). No atlas-front-end code.
- **Notes:** Paused for further instruction — implementation (Phases 4–5) and Phase 3e test-plan refine wait for spec approval. larry-adams left on branch `PRDV-14055-upload-manager-count-up` (was on `PRDV-16216-callisto-lookup-display`).

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

Phases 0–4 complete and Phase 5 implementation is code-complete on `atlas-front-end` branch `PRDV-14055` (from `origin/main` at `b92d74a5`). The Callisto count now rises using terminal-or-active status, and failed uploads become queue-visible terminal errors. Focused automated tests and lint pass; audit is blocked by pre-existing dependency vulnerabilities. Manual browser upload validation remains for Phase 6; no atlas-front-end commit or PR has been created yet.

---

## New code introduced

_Not applicable yet._
