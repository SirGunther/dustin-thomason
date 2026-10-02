# INT-140 — Audit log entries for proceeding creation (File Navigator)

## Ticket

- **Ticket:** INT-140 _(link not captured)_
- **Repo:** `callisto-back-end`, `europa-back-end`, `atlas-front-end`
- **Branch:** `INT-140` _(not cut yet. callisto from `origin/main` @ `59b1abd3`; europa-back-end from `origin/main` @ `1082fdad`; atlas-front-end from `origin/INT-138` @ `36999e87`; LD-014)_
- **PR:** _(link when opened)_
- **Artifacts:** [INT-140/](INT-140/): ticket body [INT-140.md](INT-140/INT-140.md), [locked decisions](INT-140/specs/INT-140-locked-decisions.md), [spec](INT-140/specs/INT-140-spec.md)

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

### 2026-10-02T21:05:00Z — callisto-back-end + europa-back-end + atlas-front-end (implementation, in progress)

- **Summary:** implementing the INT-140 spec, with one subagent per repo, each in its own worktree. Pieces are reviewed and merged into the integration worktrees.
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

## Current state (as of 2026-10-02)

- Locked decisions LD-001 to LD-021 are written, with LD-019 withdrawn. The spec is written, and the final review approved it once the LD-011 correction was applied ([INT-140-spec.md](INT-140/specs/INT-140-spec.md)).
- No `INT-140` branch in any repo, and no code written. Branch bases are in LD-014.
- INT-140 does not depend on INT-139's LD-001 review (LD-008, F-20).
