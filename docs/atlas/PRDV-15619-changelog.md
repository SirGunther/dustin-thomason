# PRDV-15619 — Refresh existing Proceedings on the AJSF

## Ticket

- **ClickUp:** [PRDV-15619](https://app.clickup.com/t/43227262/PRDV-15619)
- **Repo:** `atlas-front-end` (implementation, future) · `larry-adams` (specs)
- **Branch:** `PRDV-15619` (larry-adams, specs)
- **PR:** [larry-adams#8](https://github.com/planetdepos/larry-adams/pull/8) (specs for review)

---

## Requirements (verbatim)

> As an LTR, I want the ability to manually refresh the existing Proceedings, so that I can confirm there are no other similarly-named Proceedings already created without having to save, close, and re-open.
>
> Acceptance Criteria
> Users can click a button in the AJSF upload page to refresh and see if new proceedings have been added without having to refresh entire browser page
> Users don't lose any unsaved AJSF form data when clicking the button
> There are no formal designs for this.
>
> Additional Info
> Alternatively! If the Proceedings could update to other AJSFs for the same job as they are created, that would work as well. Product is assuming the button path is easier.
>
> LTRs will often open the AJSF at the beginning of their job, which can mean the form may be open for hours. They fill in information as the job progresses. It's common that over that time other LTRs assigned to the same job may already have created the Proceedings needed for the final file upload. A refresh button would allow them to view any newly-created Proceedings without having to save, leave, and return to the form.

---

## Context

- Surface: AJSF = Pending Job Submission Form, step 5 "File upload" (`PendingJobSubmissionPage`), route `/callisto-stuff/pending-job-submission-form/:jobTaskId`.
- Access gated by `NEPTUNE_LITTECH_MEMBERS` role; per-env + per-account.
- Two philosophies requested: manual refresh button vs. automatic polling. Both specced for review before any implementation.
- Access/discovery reference written: `dustin-thomason/docs/atlas/accessing-atlas-features-by-environment.md`.

---

## Plans

| Added | Plan (path or link) | Status | One-line approach |
| ----- | ------------------- | ------ | ----------------- |
| 2026-06-12 | `.cursor/plans/refresh-proceedings-specs_f7f38aeb.plan.md` | `implemented` | Author button + polling specs (frontend-only, reuse `useJobSubmissionJobProceedings`), comparison + recommendation, port to larry-adams wiki |
| 2026-06-12 | `larry-adams/systems/neptune/refresh-proceedings/PRDV-15619-button-refresh` (read-only link) | `active` | Recommended v1: wire existing `refetchProceedings` to a refresh icon + feedback |
| 2026-06-12 | `larry-adams/systems/neptune/refresh-proceedings/PRDV-15619-polling-refresh` (read-only link) | `active` | Alternative: gated `refetchInterval` polling, append-only + freshness cue |

---

## Session log

### 2026-06-16T21:55:00Z — atlas-front-end (implementation)

- **Summary:** Implemented the button approach (frontend-only). Added a refresh icon to the AJSF step-5 proceedings panel that refetches only the job-level proceedings list and surfaces feedback. Fixed the error-swallowing in `fetchJobProceedings` so a failed fetch preserves the cached list instead of blanking it. To avoid the manual refresh hanging on the query's `retryDelay: 2min`, the button uses a new **fail-fast** one-shot `manualRefreshProceedings` (single `apiClient.get` → `queryClient.setQueryData(['jobProceedings', jobId])`) instead of `query.refetch`; the query's automatic retry config is left unchanged (per user decision). Precise "N new" count computed via proceeding-ID diff (per user decision). Never touches the `['jobSubmissionForm', jobTaskId]` query.
- **Plan used:** `larry-adams/systems/neptune/refresh-proceedings/PRDV-15619-button-refresh`
- **Files:**
  - `atlas-front-end/src/callisto/pages/JobSubmissionPages/composables/useJobSubmissionJobProceedings.ts` (stop swallowing errors; add fail-fast `manualRefreshProceedings`)
  - `atlas-front-end/src/callisto/pages/JobSubmissionPages/sections/FileUploadSection/components/RefreshProceedingsButton.vue` (new)
  - `atlas-front-end/src/callisto/pages/JobSubmissionPages/sections/FileUploadSection/FileUploadSectionCore.vue` (stable header + button + `handleRefresh` + toasts)
  - `atlas-front-end/src/i18n/en-US/common.json` (refresh label + 3 toast strings)
  - `.../components/__specs__/RefreshProceedingsButton.spec.ts` (new), `.../composables/__specs__/useJobSubmissionJobProceedings.spec.ts` (new), `.../FileUploadSection/__specs__/FileUploadSectionCore.spec.ts` (extended)
- **Notes:** Deviation from spec's literal "wire `refetchProceedings`" — used a dedicated fail-fast fetch to dodge the 2-minute retry trap on a failed manual refresh; `refetchProceedings` is still used by the add-proceeding and upload-complete flows. No commit performed in this session.

#### Shipping checklist

- **Tests run** — see verification table below; 10 passing across 3 specs.
- **Tests added/updated** — added `RefreshProceedingsButton.spec.ts` (renders/emits/disabled-while-refreshing), `useJobSubmissionJobProceedings.spec.ts` (manual-refresh success writes cache; failure propagates and does not write); extended `FileUploadSectionCore.spec.ts` (new-found count toast, up-to-date toast, error toast + list preserved).
- **Regression impact** — touched the shared `useJobSubmissionJobProceedings` query fn (removed error swallow). The add-proceeding and upload-complete flows still call `refetchProceedings`; `FileUploadSectionCore` specs (add 409/non-409/success paths) still pass, confirming no regression to those callers. Error now surfaces via `proceedingsError` rather than a silent `[]`.
- **API docs** — not relevant: no HTTP contract change; reuses `GET /callisto/proceeding-job-submission/job-detail/{jobId}/proceedings` (path, method, response shape unchanged).
- **Tooling gates** — lint (scoped eslint --fix, clean) + vitest (3 specs) run; see table.

| Gate | Command | Scope | Result | Exception / risk |
| ---- | ------- | ----- | ------ | ---------------- |
| lint | `npx eslint --fix <6 changed files> --max-warnings 0` | changed files | pass | full-repo `npm run lint` not run this session (pre-commit deferred) |
| tests | `npx vitest run --no-file-parallelism <3 specs>` | refresh button/composable/core | pass (10) | `--maxWorkers 1` conflicts with repo vitest pool config; used `--no-file-parallelism` to serialize |

### 2026-06-12T21:03:00Z — larry-adams (specs)

- **Summary:** Grilled the design (scope, button feedback, failure handling, polling conditions, surfacing, Quasar-migration posture) and authored four spec docs in the larry-adams Obsidian wiki under `systems/neptune/refresh-proceedings/`: overview + recommendation, button approach, polling approach, and a dev note. Wired all four into `systems/README.md`. Frontend-only; both approaches reuse the existing job-proceedings query and `GET .../job-detail/{jobId}/proceedings` endpoint. Opening a PR for Larry's review.
- **Plan used:** `.cursor/plans/refresh-proceedings-specs_f7f38aeb.plan.md`
- **Files:**
  - `larry-adams/systems/neptune/refresh-proceedings/PRDV-15619-refresh-proceedings-overview.md`
  - `larry-adams/systems/neptune/refresh-proceedings/PRDV-15619-button-refresh.md`
  - `larry-adams/systems/neptune/refresh-proceedings/PRDV-15619-polling-refresh.md`
  - `larry-adams/systems/neptune/refresh-proceedings/PRDV-15619-dev-note.md`
  - `larry-adams/systems/README.md` (index entries)
  - `dustin-thomason/docs/atlas/accessing-atlas-features-by-environment.md` (access reference)
- **Commits:** larry-adams `dd65bfe` (branch `PRDV-15619`); PR [larry-adams#8](https://github.com/planetdepos/larry-adams/pull/8)
- **Notes:** Docs-only PR; no app code changed. The "shared code fix" (stop swallowing fetch errors to `[]`) is described in the specs as required implementation, not performed in this work.

#### Shipping checklist

- **Tests run** — not relevant: docs-only change to the larry-adams Obsidian wiki and dustin-thomason docs; no code, no test/lint/audit gates in these repos.
- **Tests added/updated** — not relevant: no production code touched.
- **Regression impact** — isolated: only new markdown files plus additive index entries in `systems/README.md`; no existing spec content changed.
- **API docs** — not relevant: no HTTP contract changed; specs reuse the existing `GET .../job-detail/{jobId}/proceedings` endpoint.
- **Tooling gates** — not relevant: larry-adams (docs vault) and dustin-thomason (docs) have no package.json / lint / test gates for this work.

---

## Current state (as of 2026-06-16)

Button approach implemented in `atlas-front-end` (uncommitted): `RefreshProceedingsButton.vue` + fail-fast `manualRefreshProceedings`, error-swallow fix, toasts, i18n, and specs (10 passing). Not yet committed/pushed; full-repo `npm run lint` and broader test sweep still to run before a commit. Polling alternative remains deferred to a future websockets effort.
