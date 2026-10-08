# INT-140 — Audit log entries for proceeding creation (File Navigator)

## Ticket

- **Ticket:** [INT-140](https://pd-product-dev.atlassian.net/browse/INT-140) (Jira; Story, 2 points, Ready For Work; parent [INT-137](https://pd-product-dev.atlassian.net/browse/INT-137))
- **Repo:** `callisto-back-end`, `europa-back-end`, `atlas-front-end`
- **Branch:** `INT-140` (pushed; worktrees `C:\Users\dustin.thomason\wt\{callisto,europa,atlas}-INT-140`). callisto from `origin/main` @ `11a3f684`; europa-back-end from `origin/main` @ `1082fda`; atlas-front-end from `origin/main` @ `9c184231` (LD-014)
- **PR:** drafts: [callisto #474](https://github.com/planetdepos/callisto-back-end/pull/474), [europa #74](https://github.com/planetdepos/europa-back-end/pull/74), [atlas #590](https://github.com/planetdepos/atlas-front-end/pull/590)
- **Artifacts:** [INT-140/](INT-140/): ticket body [INT-140.md](INT-140/INT-140.md), [original ticket](INT-140/INT-140-original-ticket.md) and [comments](INT-140/INT-140-comments.md) from the Cerberus intake (2026-10-05), [locked decisions](INT-140/specs/INT-140-locked-decisions.md), [spec](INT-140/specs/INT-140-spec.md)

---

## Requirements (verbatim)

> # Audit log - create a proceeding (file navigator)
>
> As an Ops manager, I want to be able to review an audit log of key actions related to Client Access, so that I can see the "who, what, when" for these critical functions.
>
> * * *
>
> ## Acceptance Criteria
>
> -   Ops can view a log in Europa for proceeding creation
> -   The log displays the following details:
>     -   user info
>     -   date/time
>     -   **File Navigator proceeding creation** action taken
> -   Event Type for this action is: **Created**
> -   The **Proceeding** Resource type is added to the Resource Type drop down in Europa
>     -   (this should already exist, it's just not visible)
> -   Path format:
>     -   Path: \[path\] (date/job ID/proceeding ID)
>     -   Proceeding Name: \[proceeding name\]
> **Dev Note:**
>
> Two endpoints exist for this.
>
> **AJSF** - jobSubmissionService.createProceedings
>
> **File Navigator** - proceedingsService.createProceedings (use this one for this ticket)

---

## Context

- Builds on INT-138's Atlas multi-part path rendering (`origin/INT-138`, PR #582). The label owner is settled on INT-140's own evidence (ledger F-20), and it agrees with INT-139 LD-001 without depending on it. See [INT-138-changelog.md](INT-138-changelog.md) and [INT-139-changelog.md](INT-139-changelog.md).
- **User direction (2026-09-29):** stay within scope on the assessment. The work extends existing audit code.
- **User direction (2026-09-29):** each finding is written as a checklist item, checked against context, and marked complete only with evidence shown in chat.

---

## Plans

| Added | Plan (path or link) | Status | One-line approach |
| ----- | ------------------- | ------ | ----------------- |
| 2026-09-29 | [INT-140/specs/INT-140-spec.md](INT-140/specs/INT-140-spec.md) | `active` | Implementation spec built from the ledger (LD-001 to LD-021): a typed `applyCreated` chain in the proceeding audit sub-domain, a service dispatch after commit whose errors propagate as they do for rename, a europa-back-end `CREATED`+`PROCEEDING` branch, an Atlas resource-scoped split, specs and a manual check |
| 2026-09-29 | [INT-140/specs/INT-140-locked-decisions.md](INT-140/specs/INT-140-locked-decisions.md) | `active` | `ProceedingService.createProceedings` sends one `CREATED`/`PROCEEDING` event per proceeding with `{ path: MMYYYY/jobId/proceedingId, value: name }`; europa-back-end builds `Path \| Proceeding Name` for `CREATED`+`PROCEEDING`; atlas-front-end adds `PROCEEDING` and splits only that pair; the job date is read before the create, and dispatch errors propagate as they do for rename (LD-017) |

---

## Session log

_Newest first._

### 2026-10-08T21:15:53Z — update branches to main and npm audit: done

- **Summary:** user direction: "Update the Branch to Main, resolve any conflicts, and run npm audit".
  - **Already level with `main`:** callisto `55431e07` on `8f31f933` and europa `8f70b22` on `0473ae8`, behind by 0.
  - **Behind:** atlas by 3 (`3827e027`, INT-45 contact-drawer fixes, #589). No package changes and no conflicts (`git merge-tree`).
  - **Merge, not rebase:** `origin/main` is merged into atlas `INT-140`, because the branch is pushed with an open PR; this avoids a force push. Intended subject: `INT-140: Merge main into INT-140`.
- **Result:** atlas `INT-140` @ `1c87d940`, a clean merge with no conflicts, pushed without force (`cacfd124..1c87d940`). PR #590's commit block was updated in place; its screenshot placeholder is kept and the body had no attachments. The INT-140 diff against `main` is unchanged (4 files, +100/−5). callisto and europa had nothing to merge.

| Gate | Command | Scope | Result | Exception / risk |
| ---- | ------- | ----- | ------ | ---------------- |
| audit | `npm audit --audit-level=high` | callisto `55431e07` | **fail**: 22 (1 low, 20 moderate, **1 critical**: `handlebars`) | Newly published. The lockfile equals `main`'s, and INT-140 changes no package file. This was a pass on 2026-10-07. Covered by the user's 2026-10-05 waiver |
| audit | `npm audit --audit-level=high` | europa `8f70b22` | pass (20 moderate) | — |
| audit | `npm audit --audit-level=high` | atlas `1c87d940` | fail: 51 (11 moderate, 35 high, **5 critical**: `handlebars`, `proxy-addr`, `quasar`, `tinypool`) | Already on `main`; waived |
| lint | `npm run lint` | atlas | pass | — |
| type-check | `npm run type-check` | atlas | pass | — |
| tests | `npx vitest run --maxWorkers 1` | atlas full | pass: 176 files / 1578 tests (4 skipped, already there) | — |

### 2026-10-08T21:07:34Z — PR screenshot placeholders

- **Summary:** each required screenshot in the PR bodies now has a header and a visible placeholder line ("Screenshot placeholder: drop `<file>` here, then delete this line"), replacing the earlier italic slots.
  - callisto #474: `#### File Navigator: proceedings created` (02) and `#### Europa: proceeding creation logged` (04).
  - europa #74 and atlas #590: `#### Europa: proceeding creation logged` (04).
- **Before editing:** the live bodies were re-read; they had no attachments.

### 2026-10-08T19:19:24Z — evidence narrowed to the acceptance criteria

- **Summary:** user direction: narrow the screenshots to the absolute minimum that satisfies the original ticket's acceptance criteria. Two remain:
  - `02-file-navigator-proceedings-created.png`: the File Navigator creation action.
  - `04-europa-resource-type-dropdown-lists-proceeding.png`: the Europa log, user info, date/time, Created, PROCEEDING in the Resource Type dropdown, and the path format, all in one view.
- **Retired** to `testing/screenshots/dnu/`, with a README:
  - `01`: covered by 02.
  - `03`: its rows are in 04.
  - `05`: a regression check, not an acceptance criterion; covered by specs.
- **PR screenshot slots:** callisto #474 has 02 and 04; europa #74 has 04; atlas #590 has 04. The live bodies were re-read first; they had no attachments or other changes.
- **Files:** `INT-140/testing/INT-140-test-evidence.md` (Screenshots section), `INT-140/testing/screenshots/dnu/README.md`.

### 2026-10-07T19:45:00Z — draft PRs opened

- **Summary:** user direction: "Create a draft PR of this implementation", modelled on atlas #566, with Jira replacing ClickUp.
  - **Europa first:** `origin/main` moved 2 commits (`0473ae8`, INT-231 npm audit remediation; no conflicts), so europa `INT-140` is rebased and its integration worktree reinstalled (`HUSKY=0 npm ci`) before the push. callisto (`8f31f933`) and atlas (`c15c22e3`) are current.
  - **Push:** each repo's `INT-140` is pushed and opened as a draft PR against `main`, with no reviewers requested.
  - **Cerberus:** PR links are recorded on INT-140. The pasted `-Ticket NEW-1` is the Template-maker ticket.
- **Result:**
  - **PRs:** three drafts, cross-linked, with no reviewers requested. All titled `INT-140: Audit log - create a proceeding (file navigator)`, following the #566 shape: a Jira link, the story and why, scope, the commit hash, evidence and a checklist.
    - callisto [#474](https://github.com/planetdepos/callisto-back-end/pull/474) @ `55431e07`
    - europa [#74](https://github.com/planetdepos/europa-back-end/pull/74) @ `8f70b22c`, rebased onto INT-231
    - atlas [#590](https://github.com/planetdepos/atlas-front-end/pull/590) @ `cacfd124`
  - **Screenshots:** the PR bodies name each screenshot to attach. `gh` can't upload images, so the PNGs from `INT-140/testing/screenshots/` need to be dragged in, and "Evidence provided" is left unchecked until then.
  - **No attribution footer:** none, following #566 and INT-138's record.
  - **Cerberus:** `pullRequests` set on INT-140 (exit 0).
  - **Europa after the rebase:** the audit now **passes** (INT-231), lint and type-check pass, and the full suite passes (32 / 129). callisto's audit passes. atlas still fails (35 high, 4 critical; waived).
  - **Playwright evidence:** taken on europa `9fbc0bb`. `8f70b22c` has the same INT-140 change, rebased onto INT-231's dependency update.

### 2026-10-07T19:28:35Z — Playwright end-to-end check: pass

- **Summary:** after the main checkouts were switched to `INT-140` (`git switch --detach INT-140`; callisto `55431e07`, europa `9fbc0bb`, atlas `cacfd124`) and the user restarted Callisto and Europa, the spec §Manual check was run with Playwright over CDP. **All acceptance criteria are shown.** Details: [INT-140/testing/INT-140-test-evidence.md](INT-140/testing/INT-140-test-evidence.md).
  - **Create:** two proceedings were created from File Navigator in one request, `201`, ids 2 and 3.
  - **Europa rows:** two CREATED / PROCEEDING rows with user, date, `Path: 052024/112233/<id>` / `Proceeding Name: <name>`, and a blank bucket.
  - **Dropdown:** the Resource Type dropdown lists PROCEEDING.
  - **Regression:** CREATED / FILE rows are unchanged.
- **Screenshots:** 5, in `INT-140/testing/screenshots/`.
- **Closed residual risk:** the `JOB_DATE_READER` binding resolved when Callisto booted.
- **Not run:** the AJSF negative check, because it needs a pending job-submission form; the code-level evidence is F-02 and LD-002.
- **Process miss (the user's correction):** the services were started before the checkouts were on `INT-140`. The branches should have been switched before the user brought the stack up, and the blocker should have been stated plainly: "we're not on the right branch yet".

### 2026-10-07T19:13:26Z — Playwright end-to-end check: blocked, the stack runs pre-INT-140 code

- **Summary:** the user started the stack ("Now we're ready"). The pasted prompt named `NEW-1`, which is Cerberus's "Template-maker" ticket, with no repos or code; this was read as INT-140. Before any browser step, the stack was checked:
  - **Running:** Callisto :3004 (`rm -rf dist && nest start`, not watch mode), Europa :3006 (`nest start --watch`), Atlas :9000 (`quasar dev`), the CDP Chrome :9222 (`C:/temp/atlas-cdp`), Postgres :5432 (Docker) and Mongo :27017.
  - **Code under test is not INT-140:** all three services run from the main checkouts, and none contains the INT-140 tip. callisto is on `INT-138` @ `fadb63db`; europa is detached at `b03f5e6` (INT-139); atlas is detached at `2b7e1867` (INT-139).
  - **Confirmed in the built code:** Callisto's `dist` has no `ProceedingCreationToAuditEventResourceConverter`, Europa's `dist` has no `Proceeding Name:`, and Atlas's source has no `MULTI_PART_PATH_RESOURCE_TYPES`.
- **Not done:** no checkout was switched and no process was restarted.
  - Callisto isn't in watch mode, so it needs the user's restart, with their credentials, and `npm ci` for INT-228's lockfile.
  - The main checkouts hold uncommitted files that belong to others: callisto `.swcrc` and `notification-template-preview.html`; atlas `.claude/`.
- **Notification sent.**

### 2026-10-07T17:44:49Z — Playwright end-to-end check: blocked, the stack isn't running

- **Summary:** user direction: run Playwright to validate INT-140 and save screenshot evidence in dustin-thomason ("the system is up and running … if you run into any issues, let me know"). Before any browser step, the stack was checked and is not available:
  - **Ports:** nothing is listening on 3004 (Callisto), 3006 (Europa), 9000 (Atlas) or 9222 (the CDP Chrome INT-139 used, profile `C:/temp/atlas-cdp`).
  - **Processes:** the node processes running belong to other tools (Cerberus on 3040, and services on 3000, 3010, 8178 and 8790). The Docker daemon isn't running, and Callisto's Postgres runs in Docker.
  - **Code:** none of the services' checkouts contain INT-140. callisto is on `INT-138` @ `fadb63db` with 2 uncommitted files that belong to another agent; europa is detached at `b03f5e6` (INT-139); atlas is detached at `2b7e1867` (INT-139) with 1 uncommitted file. INT-140 exists only in `wt\{callisto,europa,atlas}-INT-140`, which have no `.env` files.
- **Not done:** nothing was started, switched or copied. Following INT-139's precedent, restarting Callisto needs the user's shell credentials.
- **Notification sent:** "INT-140 Playwright blocked: stack not running".

### 2026-10-07T04:53:07Z — callisto-back-end + europa-back-end + atlas-front-end (updated to main: done)

- **Summary:** user direction: "There were some updates, especially for security. Get up to date with main." The local `INT-140` branches are rebased onto the current `origin/main`. They are unpushed, so the rebase rewrites only local commits.

  | Repo | Behind | Notable on `main` | Conflicts (`git merge-tree`) |
  | --- | --- | --- | --- |
  | callisto | 36 commits, `origin/main` `8f31f933` | INT-228 npm audit remediation (#472, changes `package.json` and the lockfile); INT-139 (#468); INT-195 (case-insensitive proceeding uniqueness) | none |
  | europa | 7 commits, `e5ff3be` | INT-139 (#72), including `d9fb272` | all 3 INT-140 files |
  | atlas | 21 commits, `c15c22e3` | INT-139 (#584); case-group work | none |

- **Europa:** the conflict is resolved by a subagent in its own worktree, keeping both sides. The INT-140 test cases move onto INT-139's cast-free `createMockTypedAuditEvent` helper (LD-023).
- **Callisto node_modules:** the integration worktree gets its own `HUSKY=0 npm ci` in place of the junction. The main checkout's lockfile predates INT-228, so the junction would test against the wrong dependencies.
- **Result:** all three rebased; local branches only, nothing pushed.
  - callisto `INT-140`: `02afcce2`, `46aa7822`, `55431e07` on `8f31f933`. Auto-merged, no conflicts; `proceedings.module.ts` merged cleanly.
  - atlas `INT-140`: `cacfd124` on `c15c22e3`. Auto-merged; the diff is unchanged (4 files, +100/−5).
  - europa `INT-140`: `9fbc0bb` on `e5ff3be`. The subagent resolved the conflicts in `wt\europa-INT-140-europa-rebase`, keeping both sides; it removes 0 lines of `main`. The 3 INT-140 spec cases now use INT-139's cast-free `createMockTypedAuditEvent` and `arrangeSearchResult`, so no ` as ` casts remain in them (LD-023). After review, `INT-140` was moved to that commit with `reset --hard` in the clean integration worktree; the old `394c454` is in the reflog.
- **Callisto install:** `HUSKY=0 npm ci` added 1277 packages; husky was skipped and `core.hooksPath` is unchanged (`.husky/_`).

| Gate | Command | Scope | Result | Exception / risk |
| ---- | ------- | ----- | ------ | ---------------- |
| audit | `npm audit --audit-level=high` | callisto | **pass** (21: 1 low, 20 moderate) | INT-228 fixed the highs |
| audit | `npm audit --audit-level=high` | europa / atlas | fail: 36 high + 1 critical / 34 high + 3 critical | Waived by the user 2026-10-05. No package file changed in these repos; the count grew from newly published advisories |
| lint | `npm run lint` | callisto / europa / atlas | pass / pass / pass | — |
| type-check | `npm run type-check` | callisto / europa / atlas | pass / pass / pass | — |
| architecture | `architecture.spec.ts`; `npm run test:conventions` | callisto | pass; pass | — |
| tests | `npx jest --config jest-e2e.json --runInBand --silent` | callisto full | pass: 472 suites / 2592 tests | Uses the worktree's own `npm ci` install |
| tests | `npx jest --config jest-e2e.json --runInBand` | europa full | pass: 32 suites / 129 tests | — |
| tests | `npx vitest run --maxWorkers 1` | atlas full | pass: 176 files / 1577 tests (4 skipped, already there) | — |

### 2026-10-05T22:00:39Z — europa-back-end + atlas-front-end (commit after audit waiver)

- **Summary:** the user waived the audit gate for INT-140: "if it's just about the security vulnerabilities, that's totally fine for now … we're going to rectify in another ticket." The verified Europa and Atlas integration changes are being committed on their local `INT-140` branches.
  - No push and no PR.
  - Both repos are still on their original bases (europa `1082fda`, atlas `9c184231`). Atlas's `origin/main` has since moved to `9cd9a82a`; rebase before a PR.
- **Pre-commit hook:** europa-back-end's `.husky/pre-commit` runs `prettier --write .`, but husky isn't installed in worktrees (`.husky/_` is absent). Its formatting is applied by hand to the 3 changed files only. A repo-wide write would reformat unrelated files. atlas-front-end has no pre-commit hook.
- **Intended commit subjects:**
  - europa: `INT-140: Format proceeding created audit path`
  - atlas: `INT-140: Show proceeding resource type in audit log`
- **Committed (local, not pushed):** europa `394c454f` `INT-140: Format proceeding created audit path`; atlas `7dd691b0` `INT-140: Show proceeding resource type in audit log`. Both worktrees are clean. Prettier reformatting moved the europa spec from +164 to +166 lines.

| Gate | Command | Scope | Result | Exception / risk |
| ---- | ------- | ----- | ------ | ---------------- |
| audit | `npm audit --audit-level=high` | europa / atlas | fail (pre-existing: 5 / 15 high) | **Waived by the user 2026-10-05**; to be fixed in a separate ticket |
| format | `npx prettier --write` then `--check` on the changed files | europa (3 files) / atlas (4 files) | pass / pass | Run by hand because the husky hook isn't installed in worktrees |
| lint | `npm run lint` | europa / atlas | pass / pass | — |
| type-check | `npm run type-check` | europa / atlas | pass / pass | — |
| tests | `npx jest --config jest-e2e.json --runInBand` | europa full | pass: 32 suites / 115 tests | — |
| tests | `npx vitest run --maxWorkers 1` | atlas full | pass: 169 files / 1522 tests (4 skipped, already there) | — |

### 2026-10-05T21:43:11Z — dustin-thomason + Cerberus (backfill: ticket intake)

- **Summary:** ran the Cerberus intake for INT-140, which exited 0.
  - **Written:** `INT-140/INT-140-original-ticket.md` and `INT-140/INT-140-comments.md`. The existing folder was updated in place. Cerberus record `9763cedd-d61b-46df-8911-75d4f5f697b4`.
  - **Checked:** the original ticket's title, link and Original Request match the JSON record exactly (the Original Request is 864/864 characters, identical). The earlier `INT-140.md` has the same wording in different Markdown.
- **Cerberus fields set** with `set-info`, all exit 0:

  | Field | Value |
  | --- | --- |
  | `repositories` | the 3 GitHub repos |
  | `relatedWork` | INT-137 (parent), INT-138, INT-139, INT-141 (the AJSF sibling); callisto #464 and atlas #582; the spec; this changelog |
  | `ledgerLocation` | `INT-140/specs/INT-140-locked-decisions.md` |
  | `ledgerStatus` | `created` |

  `pullRequests` is left empty: no INT-140 PR and no remote `INT-140` branch exist (checked with `gh pr list` and `git branch -r`).
- **New from Jira:**
  - Story points: 2.
  - A QA comment (Anastasiya Savchuk, 2026-09-30) lists cases PDN-1848 to PDN-1855.
  - PDN-1854 asks whether a multi-proceeding create should produce one Created event per proceeding, and is "[NEEDS CLARIFICATION] … pending PO reply". INT-140 implements one event per proceeding (LD-006).
  - PDN-1852/1853 (Resource Type = Proceeding) overlap INT-141.
- **Drift seen:** `origin/main` has moved since the `INT-140` branches were cut. callisto `11a3f684` → `adf466df`; atlas `9c184231` → `9cd9a82a`; europa unchanged. Rebase before any PR.

### 2026-10-02T22:20:00Z — callisto-back-end + europa-back-end + atlas-front-end (code review fixes: done, merged locally)

- **Result:** all three code findings are fixed, reviewed and merged.
  - **Callisto:** `e56706b6 INT-140: Read job date through a port`, fast-forwarded into `INT-140`.
  - **Europa and Atlas:** the updated diffs were re-applied, uncommitted, to their integration worktrees. Each is byte-identical to its piece diff.
- **Policy items, resolved from evidence with no code change** (ledger F-35 and F-36):
  - The `INT-140:` prefix is kept. Merged history has 28 `INT-*:` subjects in callisto and 9 in atlas, and INT-138's mistakes doc (`:85`) already settled it.
  - The europa-back-end labels stay inline. europa-back-end has no i18n, and `PERMISSIONS_UPDATED` already builds its text inline.
- **Raised by the subagents and resolved:**
  - The europa `}) as AuditEvent` casts on the output of `createMockAuditEvent` are kept. The factory returns `Partial<AuditEvent>`, the same pattern already exists at `:71,156,212`, and changing it would touch the shared `test-utils.ts`.
  - The Atlas `// Arrange|Act|Assert` markers are kept, because they are required by `.cursor/rules/planetdepos.mdc:24`.
- **Residual risk:** the `JOB_DATE_READER` binding is checked only by Nest DI at app start. The repo has no module-wiring spec pattern, so the manual end-to-end check covers it.

| Gate | Command | Scope | Result | Exception / risk |
| ---- | ------- | ----- | ------ | ---------------- |
| lint | `npm run lint` | callisto / europa / atlas integration worktrees | pass / pass / pass | — |
| type-check | `npm run type-check` | callisto / europa / atlas | pass / pass / pass | — |
| architecture | `architecture.spec.ts`; `npm run test:conventions` | callisto | pass; pass | — |
| tests | `npx jest --config jest-e2e.json --runInBand --silent` | callisto full suite | pass: 457 suites / 2505 tests | — |
| tests | `npx jest --config jest-e2e.json --runInBand` | europa full suite | pass: 32 suites / 115 tests | — |
| tests | `npx vitest run --maxWorkers 1` | atlas full suite | pass: 169 files / 1522 tests (4 skipped, pre-existing) | — |
| audit | `npm audit --audit-level=high` | europa / atlas | fail (pre-existing) | Commits still held for the user's waiver |

- **Original text of this entry, written before the commit:** fixing the findings from the user-pasted code review, with one subagent per piece working in the existing piece worktrees. All three findings are confirmed:

  | Repo | Finding | Fix |
  | --- | --- | --- |
  | callisto | `ProceedingService` injected `JobAggregator` directly, against `.cursor/rules/architecture-patterns.mdc:1280` | A proceedings-domain port bound with `useExisting: JobAggregator`, the same as INT-138's merged `CLIENT_ACCESS_FILE_AUDIT` |
  | europa | Specs used `as unknown as` casts, against `docs/reviewers/pr-review-patterns.md:14` | Remove the casts |
  | atlas | Two explanatory comments in `constants.ts`, against `pr-review-patterns.md:7` | Remove them |

- **Intended callisto commit subject:** `INT-140: Read job date through a port`.

### 2026-10-02T21:55:37Z — callisto-back-end + europa-back-end + atlas-front-end (implementation: built, reviewed, merged locally)

- **Summary:** the INT-140 spec is implemented. Three subagents, one per repo, each worked in its own worktree (`wt\{callisto-INT-140-callisto, europa-INT-140-europa, atlas-INT-140-atlas}`, branches `INT-140-{callisto,europa,atlas}`). Each piece was reviewed against the ticket, ledger and spec, then merged into its integration worktree.
- **Callisto:** fast-forwarded `INT-140` to `c87bb1d6`, with commits `bb13fbda INT-140: Add proceeding created audit chain` and `c87bb1d6 INT-140: Audit File Navigator proceeding creation`. These are subject-only, with no Co-Authored-By trailer, following INT-138's mistakes §5.
- **Europa and Atlas:** each diff was applied, uncommitted, to its integration worktree; the result is byte-identical to the piece diff. Both wait for the user's audit waiver.
- **Deviations:** none in production code.
  - The Europa specs use `as unknown as AuditEventResource[...]` casts for payloads the declared types don't describe. This is intentional under LD-011, and the repo already uses the same pattern.
  - The Callisto aggregator and dispatcher specs build mocks with `createMock({ apply, applyCreated })`, the same as INT-138's `proceeding-file-audit.aggregator.spec.ts:26-30`.
- **Not run:**
  - The local end-to-end check from spec §Manual: it needs the local Callisto, SQS, Europa and Atlas stack with AWS credentials.
  - The Callisto husky pre-commit hook: `.husky/_` doesn't exist in the worktree, so git had no hook to call. The subagent ran the hook's steps by hand instead: `npm run test:conventions` (pass) and prettier on the 13 changed files.
- **Files:** callisto, 13 files (+687/−17); europa, 3 files (+176); atlas, 4 files (+102/−5).

| Gate | Command | Scope | Result | Exception / risk |
| ---- | ------- | ----- | ------ | ---------------- |
| audit | `npm audit --audit-level=high` | callisto `origin/main` lockfile | pass | — |
| audit | `npm audit --audit-level=high` | europa | fail: 5 high | Pre-existing; INT-140 changes no package file. Commit held for a waiver |
| audit | `npm audit --audit-level=high` | atlas | fail: 15 high | Pre-existing; commit held for a waiver |
| lint | `npm run lint` | callisto / europa / atlas integration worktrees | pass / pass / pass | — |
| type-check | `npm run type-check` | callisto / europa / atlas | pass / pass / pass | — |
| architecture | `npx jest --config jest-e2e.json --runInBand src/__tests__/architecture.spec.ts`; `npm run test:conventions` | callisto | pass 1/1; pass | — |
| tests | `npx jest --config jest-e2e.json --runInBand --silent` | callisto full suite | pass: 457 suites / 2505 tests | node_modules is a junction to the main checkout, whose lockfile differs from `origin/main` by patch-level security bumps only |
| tests | `npx jest --config jest-e2e.json --runInBand` | europa full suite | pass: 32 suites / 115 tests | — |
| tests | `npx vitest run --maxWorkers 1` | atlas full suite | pass: 169 files / 1522 tests (4 skipped, pre-existing) | — |

**Shipping checklist**
- **Tests added:**
  - callisto: a new converter spec, plus additions to the service, aggregator, dispatcher and assembler specs;
  - europa: three cases in the search TS spec;
  - atlas: constants and SearchDataGrid cases.

  Each piece's subagent confirmed its key test fails against the base code.
- **Regression impact:** file `CREATED` rows and `RENAMED` proceeding rows are pinned unchanged by the europa and atlas specs. `renameProceeding` and its specs are unchanged. AJSF (`JobSubmissionService`, `ProceedingAggregator`, `CreateProceedingsTS`) is untouched.
- **API docs:** not relevant.
  - `CreateProceedingsAction` route, method, DTOs and `CreateProceedingsSwagger` are unchanged.
  - europa-back-end's request and response DTOs and Swagger are unchanged.
- **Conflicts / exceptions:**
  - Europa and Atlas commits are held under the audit gate.
  - No Co-Authored-By line, per the INT-138 record.
  - The husky hook was run by hand rather than by git.
- **Earlier text of this entry, written at 2026-10-02T21:05:00Z before any commit:** implementing the INT-140 spec, with one subagent per repo, each in its own worktree. Pieces are reviewed and merged into the integration worktrees.
- **Integration worktrees:** all on branch `INT-140`, all with node_modules junctions to the main checkouts.

  | Worktree | Base |
  | --- | --- |
  | `C:\Users\dustin.thomason\wt\callisto-INT-140` | `origin/main` @ `11a3f684` |
  | `wt\europa-INT-140` | `origin/main` @ `1082fda` |
  | `wt\atlas-INT-140` | `origin/main` @ `9c184231` |

- **Bases moved:** INT-138's PRs #464 (callisto) and #582 (atlas) have merged to `main`.
- **Audit:**

  | Repo | `npm audit --audit-level=high` | Commits |
  | --- | --- | --- |
  | callisto-back-end | pass | allowed |
  | europa-back-end | fail, 5 high (`brace-expansion`, `fast-uri`, `joi`, `multer`) | held, pending a user waiver |
  | atlas-front-end | fail, 15 high (`axios`, `brace-expansion`, `browserslist`, `immutable`, `ip-address`, `js-yaml`, `nanoid`, `node-forge`, `postcss`, `tar`, `undici`) | held, pending a user waiver |

  INT-140 changes no `package.json` or lockfile.
- **Intended commit subjects (callisto):** `INT-140: Add proceeding created audit chain`, `INT-140: Audit File Navigator proceeding creation`.

### 2026-10-02T20:45:43Z — dustin-thomason (final spec review: approved with one correction)

- **Summary:** the user-pasted final spec review approved the spec with one P3. `value?: string` was declared on `oldState` as well as `newState`, but the new europa-back-end branch reads only `newState.value`. Accepted: LD-011 and the spec's entity change are narrowed to `newState.value?: string`, and `oldState` is unchanged.
- **Files:** `docs/atlas/INT-140/specs/INT-140-spec.md` (`modified` set to 2026-10-02), `docs/atlas/INT-140/specs/INT-140-locked-decisions.md`, this changelog.
- **Commits:** none. No app-repo code changed.

### 2026-09-29T21:37:42Z — dustin-thomason (spec review reconciled)

- **Summary:** reconciled the user-pasted spec review (P1, P2, P3, all on scope) using the checklist-and-evidence method. All three were accepted:
  - **P1, LD-017 revised:** the service has no catch, no logger and no continue-on-error. Dispatch errors propagate as they do for rename. The job-date read before the create stays. Evidence F-29: no step after commit is known to throw.
  - **P2, LD-011 narrowed and LD-019 withdrawn:** LD-011 is now `value?: string` only. LD-019 (Callisto's declared `oldState`) is withdrawn. The pre-existing declared-type mismatches are out of scope.
  - **P3, LD-021 revised:** the converter takes a `Date` only, and the string-date test is removed. Evidence F-30: `pg-types` 2.2.0 turns a `date` column into a `Date`, and no parser override exists.
- **Conflict with the earlier ledger review:** P1 and P2 reverse the failure isolation and the full type correction that the ledger review asked for. The reversals follow the user's scope direction. The ledger review's test requirement still holds: a rejected read and a rejected dispatch are tested.
- **Files:** `docs/atlas/INT-140/specs/INT-140-spec.md`, `docs/atlas/INT-140/specs/INT-140-locked-decisions.md`, this changelog.
- **Commits:** none. No app-repo code changed. The only commands run in app repos were read-only `node -e` checks of `pg-types` in callisto-back-end.

### 2026-09-29T21:27:30Z — dustin-thomason (spec)

- **Summary:** wrote the INT-140 implementation spec with the `write-spec` skill (`agents/skills/write-spec/SKILL.md`), using INT-139's spec as the reference for shape.
- **Spec contents:**
  - sections 1 to 8;
  - the record contract and failure behavior;
  - exact code for the new param, converter, assembler, dispatcher, port, aggregator and service, the europa-back-end branch and entity type, and the Atlas constant and check;
  - the spec-test matrix, manual end-to-end steps, verification gates, an acceptance-criteria trace, rollout, branches, complexity flags and an estimate (Small).
- **Ledger additions:** LD-019 (Callisto's declared `oldState` is nullable), LD-020 (a typed creation chain separate from rename), and LD-021 (a private month-year formatter plus a parity spec), each with evidence F-26 to F-28.
- **Not done:**
  - **No `systems/` wiki wiring:** the only `systems/` tree is in `larry-adams`, which is read-only. This is the same as INT-139.
  - **No dev note:** no estimation was requested.
- **Files:** `docs/atlas/INT-140/specs/INT-140-spec.md` (new), `docs/atlas/INT-140/specs/INT-140-locked-decisions.md`, this changelog.
- **Commits:** none. No app-repo code changed.

### 2026-09-29T20:58:24Z — dustin-thomason (ledger review reconciled)

- **Summary:** reconciled the user-pasted ledger review (two P1, two P2, one P3) using the checklist-and-evidence method. The changes to the ledger:
  - **LD-008:** now locked on INT-140's own evidence (F-20: the `PERMISSIONS_UPDATED` precedent and the proceeding audit sub-domain's raw-value state), with the INT-139 fallback removed.
  - **LD-017 (new):** the job date is read before the create; each dispatch after commit is isolated and logged, following the `CaseMergeService` precedent; the create returns the committed proceedings.
  - **LD-018 (new):** the who and when contract, with assertions and a manual check.
  - **LD-014:** branch bases are now published SHAs. europa-back-end branches from `origin/main` @ `1082fdad` without the unpushed `d9fb272`, and LD-009 no longer uses `toDisplayValue`.
  - **LD-011:** the europa-back-end state type is corrected.
  - **LD-015:** the deploy-order constraint is corrected.
- **Refuted:** the review's claim that retries create duplicates. The unique constraint on `(value, job_id)` returns 409 (F-21).
- **Files:** `docs/atlas/INT-140/specs/INT-140-locked-decisions.md`, this changelog.
- **Commits:** none. No app-repo code changed. The only commands run in app repos were read-only `git` checks, plus `git fetch origin INT-138` in atlas-front-end to confirm the published SHA.

### 2026-09-29T20:41:09Z — dustin-thomason (investigation, locked decisions)

- **Summary:** investigated INT-140 against the checked-out `INT-138` branches and callisto `main`. Wrote findings F-01 to F-19, each with code evidence, and locked decisions LD-001 to LD-016.
- **Correction:** the first report's claim that `oldState` can't be `null` was withdrawn. Validating europa-back-end's real schema showed that `null` is accepted and stored (F-13).
- **Plan used:** none before this session. The ledger row above is new.
- **Files:** `docs/atlas/INT-140/specs/INT-140-locked-decisions.md`, this changelog.
- **Commits:** none. No app-repo code changed. The only thing run was a read-only schema check with ts-node against europa-back-end, from the session scratchpad.

---

## Current state (as of 2026-10-02, after implementation)

- Locked decisions LD-001 to LD-021 are written, with LD-019 withdrawn. The spec is written, and the final review approved it once the LD-011 correction was applied ([INT-140-spec.md](INT-140/specs/INT-140-spec.md)).
- **Implemented and updated to main (2026-10-07):** callisto `INT-140` @ `55431e07` (on `origin/main` `8f31f933`); europa `INT-140` @ `9fbc0bb` (on `e5ff3be`); atlas `INT-140` @ `cacfd124` (on `c15c22e3`). All committed locally; nothing pushed; no PRs.
- **Verified end to end (2026-10-07):** Playwright run passed (see testing/INT-140-test-evidence.md).
- **PRs (draft):** callisto #474 @ `55431e07`, europa #74 @ `8f70b22c`, atlas #590 @ `1c87d940`. All level with `main` as of 2026-10-08.
- **Remaining:** attach the screenshots to the PRs, mark them ready for review, and request reviewers (the user's call).
- INT-140 does not depend on INT-139's LD-001 review (LD-008, F-20).
