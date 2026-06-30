# PRDV-15619 — Refresh existing Proceedings on the AJSF

## Ticket

- **ClickUp:** [PRDV-15619](https://app.clickup.com/t/43227262/PRDV-15619)
- **Repo:** `atlas-front-end` (implementation, future) · `larry-adams` (specs)
- **Branch:** `PRDV-15619` (larry-adams, specs)
- **PR (implementation):** [atlas-front-end#524](https://github.com/planetdepos/atlas-front-end/pull/524) — commit `aa942a0575ec118084dfccb662ab35bd3d2d9d1d`
- **PR (specs):** [larry-adams#8](https://github.com/planetdepos/larry-adams/pull/8) (specs for review)

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

### 2026-06-30T16:33:00Z — atlas-front-end + dustin-thomason (PR #524 review responses)

- **Summary:** Addressed the three review comments on PR #524 from p-lana. Two were change requests (move `console.error` string to `common.json`; readability refactor of `handleRefresh`) and one was a question (why the `fetchJobProceedings` try/catch was removed). The prior pass had already applied the code edits but left **two Prettier `--max-warnings 0` violations** in `FileUploadSectionCore.vue` that would fail the Atlas lint gate — auto-fixed them this session. No deeper refactor needed.
- **Refactor verdict:** edits are behaviorally correct. try/catch removal is intentional — errors now propagate to Vue Query (preserves last-good cache, exposes `proceedingsError`) and to `handleRefresh`'s catch (error toast), instead of being swallowed into `[]` which blanked the list. `Set<number>` (not the reviewer's `Set<string>`) is correct since `ProceedingData.id` is numeric.
- **Doc added:** `docs/atlas/PRDV-15619-pr-review-responses.md` — paste-ready PR replies for each comment + rationale + the i18n console.error nuance (sibling `addProceedingsFailed` exists but its console.error still hardcodes the string).
- **Files touched:** `useJobSubmissionJobProceedings.ts` (comment), `FileUploadSectionCore.vue` (refactor + i18n + prettier), `common.json` (`refreshProceedingsFailed`), `FileUploadSectionCore.spec.ts` (i18n mock key).

#### Shipping checklist

- **Tests run** — `npx vitest run --no-file-parallelism FileUploadSectionCore.spec.ts` → 6/6 pass; `npx eslint <4 changed files>` → 0 errors/0 warnings. Full-repo audit→lint→tests sweep to be re-run at commit time.
- **Tests added/updated** — i18n mock key added to `FileUploadSectionCore.spec.ts` to cover the new `refreshProceedingsFailed` usage; existing refresh-scenario specs (new/up-to-date/error) still pass.
- **Regression impact** — isolated: changes confined to the refresh path in one composable + one section component and their i18n keys; sibling `handleAddProceedings` and the `useQuery` contract unchanged.
- **API docs** — not relevant: front-end only, no HTTP contract change.
- **Tooling gates** — lint + targeted tests run (above); not yet committed, so full gate sweep pending commit.

### 2026-06-27T02:30:00Z — dustin-thomason (demo runbook) + screenshot re-validation

- **Summary:** Re-ran the live validation against the still-running local stack to capture PR screenshots (all four toasts: 1-new, 3-new, error, up-to-date), then authored a standalone solo-demo runbook so the session can be reproduced without agent help. No app code touched.
- **Doc added:** `dustin-thomason/docs/atlas/local/refresh-proceedings-demo.md` — prerequisites, terminal types, the DEV-pool env values that fix login, Callisto-on-3004 + Windows `dev:watch` workaround, the three one-time DB seeds (`resources`/`SQLScript`, `video_transcodes`, `AJSF_PROCEEDINGS` ALLOW), baseline reset, the four demo scenarios with exact `proceedings` INSERTs + permission DENY/ALLOW toggles, cleanup, a "tables touched" table, and troubleshooting. Linked from `full-stack-local-setup.md` and `dev-testing-prerequisites.md`.
- **DB during this session (local only, all reverted to demo-ready):** reset `proceedings` for job `899999996` to a single baseline; inserted 1 then 3 demo proceedings; toggled `AJSF_PROCEEDINGS` DENY→ALLOW for the error shot; restored ALLOW and reset proceedings to baseline at the end.
- **Stack state confirmed:** Docker (`callisto-postgres`, `callisto-rabbitmq`) up; Atlas `:9000` and Callisto `:3004` healthy; the Atlas-console `/triton` `/europa` ECONNREFUSED lines are harmless (services not running, not needed).

#### Shipping checklist

- **Tests run** — not relevant: docs-only change in `dustin-thomason`; no code/lint/test gates in that repo. (Feature gates already green in the prior entry.)
- **Tests added/updated** — not relevant: no production code changed.
- **Regression impact** — isolated: one new markdown runbook + two additive cross-links; no existing doc content altered beyond the link lines. App code untouched.
- **API docs** — not relevant: no HTTP contract change.
- **Tooling gates** — not relevant: `dustin-thomason` docs have no package.json/lint/test gates.

### 2026-06-27T02:05:00Z — atlas-front-end (pre-PR gate sweep + audit waiver)

- **Summary:** Ran the full pre-commit gate sweep on branch `PRDV-15619` in order (audit → lint → tests) to prep the PR. Lint and the full-repo test suite pass clean. `npm audit` fails on **pre-existing** transitive-dependency advisories that are **not** introduced by this branch (no `package.json`/dependency changes in the feature); user **waived** the audit gate for this PR.
- **Feature code:** untouched this session — verification only.
- **Audit detail:** 15 vulns (3 critical, 5 high, 7 moderate) in `vite`, `vitest`/`@vitest/ui`/`@vitest/coverage-v8`, `undici`, `dompurify`, `form-data`, `js-cookie`, `qs`, `tar`, `ws`, `brace-expansion`, `@sigstore/core`, bundled `npm`. Same baseline present on `main`; the local `package-lock.json` diff is from the earlier rebase `npm install`, not new deps. `npm audit fix` deliberately **not** run (out of scope for this ticket; would change the lockfile and warrant its own validation).

#### Shipping checklist

- **Tests run** — see verification table below.
- **Tests added/updated** — not relevant: no production code changed this session (gate run only).
- **Regression impact** — not relevant: no code edits.
- **API docs** — not relevant: no HTTP contract change.
- **Tooling gates** — full sweep run; audit waived (see table + risk note).
- **Conflicts / exceptions** — **audit waived by user.** Trigger present (high/critical findings → normal STOP-before-commit), action not taken: findings are pre-existing deps unrelated to PRDV-15619 (zero dependency changes on the branch). Residual risk: branch inherits the repo's existing dependency advisories; follow-up: dependency remediation tracked separately, outside this ticket.

| Gate | Command | Scope | Result | Exception / risk |
| ---- | ------- | ----- | ------ | ---------------- |
| audit | `npm audit --audit-level=high` | atlas-front-end | **fail (exit 1)** — 15 vulns (3 crit / 5 high / 7 mod) | **waived**: all pre-existing transitive deps, none from this branch; remediation out of scope |
| lint | `npm run lint` (`eslint . --max-warnings 0`) | atlas-front-end (full repo) | pass | — |
| tests | `npx vitest run --no-file-parallelism` | atlas-front-end (full repo) | pass — 98 files, 846 passed / 4 skipped | `--maxWorkers 1` conflicts with repo vitest pool config; used `--no-file-parallelism` to serialize |

### 2026-06-27T01:56:00Z — atlas-front-end + callisto-back-end (local validation)

- **Summary:** Brought up the full local stack (Atlas dev server `:9000`, Callisto `:3004`, Postgres/RabbitMQ via Docker) on the Cognito **DEV** pool and manually validated the refresh button end-to-end against the running AJSF step-5 panel for job `899999996`. All three scenarios pass:
  - **Test 1 (1 new):** inserted 1 proceeding via DB → clicked Refresh → toast **"1 new proceeding(s) found"** → row appeared; proceeding then selectable for upload.
  - **Test 2 (3 new):** inserted 3 proceedings → Refresh → toast **"3 new proceeding(s) found"** → all 3 rows rendered (4 total); ID-diff count correct (excluded the existing 1).
  - **Test 3 (error path):** revoked `AJSF_PROCEEDINGS` read in DB so the fetch returns 403 → Refresh → **"Couldn't refresh, try again"** error toast, cached list **stayed intact** (no blanking). Permission restored to ALLOW; recovery Refresh returns **"Proceedings up to date"**.
- **Feature code:** untouched this session — validation only.
- **Local-env seed gaps closed (NOT part of PRDV-15619; local DB only, no repo changes):**
  - Seeded the empty `callisto.video_transcodes` reference table (6 rows incl. empty-string `NONE`). It was blocking `fetch-or-create-job-submission-form` (500 → null `jobId` → `/job-detail/NaN/proceedings`).
  - Granted `AJSF_PROCEEDINGS` permissions (flipped 96 rows DENY→ALLOW, mirroring `PROCEEDINGS`). The resource key existed but had zero ALLOW grants, so every proceedings read 403'd regardless of role.
  - Assigned `job_id 5001` to `resource_id 999999997` via a `jobs_tasks` insert (alternate test job with a pre-existing form).
- **Notes:** Both seed gaps are pre-existing local-environment issues, unrelated to the refresh-button change; they are documented here so the next local setup can seed them up front. Still uncommitted; full-repo lint + broader test sweep remain before a commit.

#### Shipping checklist

- **Tests run** — manual end-to-end browser validation of the 3 scenarios against the live stack (results above); confirmed server-side via Callisto request logs (200 on success refresh, 403 on the simulated failure). Automated unit specs (10 passing) unchanged from the implementation session; not re-run this session.
- **Tests added/updated** — not relevant: no production code changed this session.
- **Regression impact** — not relevant: validation-only session; no code edits. DB changes were local seed data, reverted where temporary (permission restored to ALLOW).
- **API docs** — not relevant: no HTTP contract change; exercised existing `GET /callisto/proceeding-job-submission/job-detail/{jobId}/proceedings`.
- **Tooling gates** — not relevant this session: no code change to lint/test; pre-commit gate sweep still deferred per Current state.

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

## Current state (as of 2026-06-27)

Button approach implemented in `atlas-front-end` (uncommitted) and **validated locally end-to-end** — all three scenarios (1 new / 3 new / fetch-error preserves list) pass against the running DEV-pool stack. Code: `RefreshProceedingsButton.vue` + fail-fast `manualRefreshProceedings`, error-swallow fix, toasts, i18n, and specs (10 passing). **Pre-PR gate sweep complete:** full-repo `npm run lint` pass, full vitest suite pass (98 files / 846 tests), `npm audit` **waived** (pre-existing deps, not from this branch). **Committed (`aa942a0`) and pushed; PR opened: [atlas-front-end#524](https://github.com/planetdepos/atlas-front-end/pull/524)** (base `main`). Awaiting review; screenshots still to be attached to the PR. Polling alternative remains deferred to a future websockets effort.

**Local setup note:** running the AJSF locally requires two reference seeds that were missing in a fresh local DB (not part of this ticket): a populated `callisto.video_transcodes` table (incl. empty-string `NONE`), and `AJSF_PROCEEDINGS` ALLOW grants in `permissions`. Full solo-demo runbook (env, commands, seeds, scenario SQL, cleanup): `docs/atlas/local/refresh-proceedings-demo.md`.
