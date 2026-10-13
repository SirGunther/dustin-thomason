# INT-142 — Audit log entries for modifying client access

## Ticket

- **Ticket:** [INT-142](https://pd-product-dev.atlassian.net/browse/INT-142) (parent INT-137)
- **Repo:** `callisto-back-end`, `europa-back-end`, `atlas-front-end`
- **Branch:** `INT-142` (new, 2026-10-12), cut from `origin/main` in callisto-back-end (`9ece2f8d`) and atlas-front-end (`bb8be210`); local only, no upstream. The first `INT-142` branches were deleted with the torn-down v1 implementation
- **PR (draft, base `main`):** [callisto-back-end #481](https://github.com/planetdepos/callisto-back-end/pull/481) · [atlas-front-end #601](https://github.com/planetdepos/atlas-front-end/pull/601)
- **Artifacts:** [INT-142/](INT-142/) — [original ticket](INT-142/INT-142-original-ticket.md), [comments](INT-142/INT-142-comments.md), ticket body [INT-142.md](INT-142/INT-142.md), [locked decisions](INT-142/specs/INT-142-locked-decisions.md)

---

## Requirements (verbatim)

> # Audit log - modify access
>
> As an Ops manager, I want to be able to review an audit log of key actions related to Client Access, so that I can see the "who, what, when" for these critical functions.
>
> ---
>
> ## Acceptance Criteria
>
> - Ops can view a log in Europa for granting access
> - The log displays the following details:
>     - user info
>     - date/time
>     - **granting access** actions taken
>         - exactly which deliverable types were granted
>         - exactly which deliverable types were revoked
>         - to whom the types were granted
> - A new Event Type is created for this action: **CLIENT_ACCESS_UPDATED**
>     - This event type is added to the Event Type drop down in Europa
> - A new Resource Type for this action is created called: **Contact**
>     - This new resource type is also added to the resource type dropdown
> - Path format:
>     - Case: [case]
>     - Job: [job]
>     - Proceeding: [proceeding]
>     - Access granted: [list of deliverable types]
>     - Access revoked: [list of deliverable types]

---

## Context

- Epic siblings under INT-137, all reference work for this ticket (user direction 2026-10-12): INT-138 (`CATEGORIZE`, [INT-138-changelog.md](INT-138-changelog.md)), INT-139 (`RECATEGORIZE`, [INT-139-changelog.md](INT-139-changelog.md)), INT-140 (File Navigator proceeding creation, [INT-140-changelog.md](INT-140-changelog.md)), INT-141 (AJSF proceeding creation, open, [INT-141-changelog.md](INT-141-changelog.md)).
- INT-138's Europa and Atlas display code is on `main` now (ledger E-18), so INT-142 no longer depends on the `INT-138` branches.
- QA (Anastasiya Savchuk, 2026-09-30) wrote cases PDN-1865 to PDN-1879 from the acceptance criteria; see [comments](INT-142/INT-142-comments.md).
- **User direction (2026-09-29):** stay within the INT-142 acceptance criteria; the work extends what INT-138 began.
- **User direction (2026-10-12):** "just get up to main, that's our jumping off point. the other itckets are part of the epic, should prove useful".

---

## Plans

| Added | Plan (path or link) | Status | One-line approach |
| ----- | ------------------- | ------ | ----------------- |
| 2026-09-29 | [INT-142/specs/INT-142-locked-decisions.md](INT-142/specs/INT-142-locked-decisions.md) | `active` | Callisto save-grants computes the granted/revoked delta and sends one `CLIENT_ACCESS_UPDATED`/`CONTACT` record per save with structured state; europa-back-end builds `Case \| Job \| Proceeding \| Access granted \| Access revoked`; atlas-front-end lists the new event and resource types. Q-01 (list item format) open |
| 2026-10-12 | Spec v1, now `INT-142/dnu/INT-142-spec.md` | `superseded`. Implementation abandoned 2026-10-12 (see Attempt history) | Full-chain design; built and deleted |
| 2026-10-12 | [INT-142/specs/INT-142-spec.md](INT-142/specs/INT-142-spec.md) (spec v2) | `implemented` (approved; 2026-10-12T19:49 session log; atlas commit held) | Every change is listed against an AC line with existing-code evidence (callisto A1, A3–A15; atlas C1–C3; no europa change) and a fixed test inventory (T1–T18). Callisto builds the path text (V-07); no record for a no-change save (V-09); a missing contact or proceeding aborts the save (V-11); reuses existing reads; no aggregator, converter, new repository or `try/catch` | Implementation spec from the ledger (write-spec skill; shaped on the INT-141 spec), cited against `main`. Callisto: the save TS reads the previous grants, a new assembler builds the audit data in the transaction, `ContactsService` dispatches after commit through `CLIENT_ACCESS_CONTACT_AUDIT`, bound in a new GCA sub-domain `contact-access-audit`. Europa: one branch plus a list formatter. Atlas: three constants. Q-01 open; estimate Medium (3–5) against the ticket's 2 |

---

## Attempt history

- **2026-10-12: implementation of the spec, abandoned and deleted.**
  - **What happened:** three subagents built the spec as written, all gates passed, and two repos were committed locally.
  - **Rejected because:** the user's review found changes beyond the AC:
    - a new `ContactGrantsAuditContextRepository`, where `ContactsRepository.findActiveById` and `ProceedingRepository.findProceedingDetailById` already exist;
    - a second read of the previous grants, which the delta permission check already reads;
    - a `try/catch` around a producer that never throws;
    - tests of behaviour INT-142 doesn't change.
  - **Root cause:** the spec was not checked against the AC and existing code before implementation.
  - **Do not repeat:** build only what an AC line requires, and show for each change that no existing code already does it.

---

## Session log

### 2026-10-13T16:30:39Z — dustin-thomason (commit and push INT-142 docs)

- **User direction:** "If everything looks good, let's go ahead and commit and push."
- **App repos:** nothing to commit or push. callisto `INT-142` `94f2f8a0` and atlas `INT-142` `96a5354e` are level with `origin/INT-142` (PRs #481 and #601). callisto's working-copy `package-lock.json` change and atlas's untracked `.claude/` are not INT-142 work and are left out.
- **dustin-thomason:** commit only the INT-142 paths (`docs/atlas/INT-142/**`, `docs/atlas/INT-142-changelog.md`) with `git commit --only`, so the other sessions' staged and unstaged files (INT-139, INT-141, INT-144, INT-231, cross-harness-bridge) stay as they are. This repo has no `package.json`, so the npm pre-flight does not apply.
- **Intended commit:** `INT-142: Add spec, ledger and test evidence` on `main`, then push to `origin/main`.

### 2026-10-13T16:12:20Z — update from main and npm audit

- **User direction:** "Update the Branch to Main, resolve any conflicts, and run 'npm audit'."
- **Update from main:** after `git fetch`, `INT-142` already contains every `origin/main` commit (`git rev-list --count INT-142..origin/main` = 0): callisto `94f2f8a0` on `origin/main` `9ece2f8d`; atlas `96a5354e` on `origin/main` `bb8be210`. Nothing to merge, no conflicts, and no new commit. Both branches are level with `origin/INT-142`. europa-back-end has no INT-142 branch (V-07); its `main` checkout is level with `origin/main` `434567f`.
- **Working tree:** callisto's `package-lock.json` is modified again (+30 / −65, the same older lockfile stashed on 2026-10-13); it is not part of INT-142 and is not committed.

| Gate | Command | Scope | Result | Exception / risk |
| --- | --- | --- | --- | --- |
| audit | `npm audit --audit-level=high` | callisto `INT-142` `94f2f8a0`, committed lockfile (run on a copy, because the checkout's lockfile is modified) | pass: 21 (1 low, 20 moderate) | The modified working-copy lockfile gives the same result |
| audit | `npm audit --audit-level=high` | atlas `INT-142` `96a5354e`, committed lockfile | **fail**: 51 (11 moderate, 35 high, 5 critical; e.g. `fflate` critical; `axios`, `handlebars`, `@quasar/app-vite`, `body-parser` high) | Pre-existing: INT-142 changes no `package.json` or `package-lock.json` (`git diff --name-only origin/main..INT-142` is empty for both); same result as on 2026-10-12 |
| audit | `npm audit --audit-level=high` | europa `main` `434567f` (not changed by INT-142) | pass: 20 moderate | — |

- **Commits:** none. `npm audit fix` not run.

### 2026-10-13T16:08:01Z — PR screenshot placeholders

- **User direction:** "narrow the scope to the absolute minimum needed to satisfy the acceptance criteria … Update the PR with appropriate placeholders for the screenshots deemed required. Giving each a header."
- **Minimum set: 2 of the 9 screenshots.**
  - `07-resource-type-dropdown.png` shows, below the open Resource Type menu, both `CLIENT_ACCESS_UPDATED` rows in full: user email and name, date, Resource `Caitlin Crouse`, Resource Type `CONTACT`, and the five-line path with granted (MP4 Video › DepoView, Planet Draft) and revoked (MP4 Video › DepoView). The menu itself lists `CONTACT`.
  - `06-event-type-dropdown.png` shows `CLIENT_ACCESS_UPDATED` in the Event Type menu.
  - The other seven are supporting evidence only.
- **PRs updated** (Testing and Verification; placeholder text `_Screenshot pending: <file>_` under each header):
  - callisto-back-end #481: "Europa audit log: grant and revoke records for a contact" → 07.
  - atlas-front-end #601: "Event Type dropdown: CLIENT_ACCESS_UPDATED" → 06; "Resource Type dropdown: CONTACT, with records on five lines" → 07.
  - The "Evidence provided" box stays unchecked until the images are added.
- **Commits:** none.

### 2026-10-13T15:44:58Z — Playwright end-to-end check: pass

- **User direction:** "Run playwright to validate. We need evidence of the work. Take screenshots and place them in the Dustin Thomason repo to prove out functionality."
- **Stack:** callisto `INT-142` `94f2f8a0` on :3004 (its `dist` contains the contact-access-audit chain); europa `main` `434567f` on :3006; atlas `INT-142` `96a5354e` on :9000. The audit queue settings match (presence-only check).
- **Run:** Playwright over CDP in the signed-in Chrome, new tabs only. Proceeding 3001 (job 112233, case Smith v. Jones), contact 800002 Caitlin Crouse.
  - **Grant** MP4 Video › DepoView plus Planet Draft: `200`. Europa row: `Access granted: MP4 Video › DepoView, Planet Draft | Access revoked: N/A`, with user, date, Resource `Caitlin Crouse`, Resource Type `CONTACT`.
  - **Revoke** DepoView: `200`. New row: `Access granted: N/A | Access revoked: MP4 Video › DepoView`.
  - **Dropdowns:** Event Type lists `CLIENT_ACCESS_UPDATED`; Resource Type lists `CONTACT`; the `CONTACT` filter returns the 2 rows.
  - **No change:** Save is disabled.
- **Evidence:** [INT-142-test-evidence.md](INT-142/testing/INT-142-test-evidence.md) and 9 screenshots in `INT-142/testing/screenshots/`.
- **Test data left:** grant contact 800002 / proceeding 3001 / Planet Draft; 2 Europa records.
- **Commits:** none.

### 2026-10-13T15:32:13Z — callisto-back-end, atlas-front-end, europa-back-end (test checkout)

- **User direction:** "Before we test the implementation. Ensure that all relevant branches and repos are checked out. INT-142 … stash any other work and that every relevant worktree, if applicable, has been merged into these working branches for testing … Once completed, standby."
- **Piece worktrees verified merged, then removed:** each staged index tree (`git write-tree`) equals its commit's tree: `wt\callisto-INT-142-callisto` = `9f2df650`, `wt\callisto-INT-142-review` = `94f2f8a0`, `wt\atlas-INT-142-atlas` = `96a5354e`. Junctions were unlinked with `rmdir`; the worktrees were removed; piece branches `INT-142-callisto`, `INT-142-review` and `INT-142-atlas` were deleted (no commits of their own).
- **Integration worktrees removed:** `wt\callisto-INT-142` and `wt\atlas-INT-142`, both clean and equal to `origin/INT-142`. `git worktree prune` run.
- **Main checkouts:**
  - **callisto-back-end:** the modified `package-lock.json` (an older lockfile, +30 / −65, not part of INT-142) was stashed as `stash@{0}` "Before INT-142 test checkout 2026-10-13: …". Then `INT-142` was checked out at `94f2f8a0`, level with `origin/INT-142`. Clean.
  - **atlas-front-end:** `INT-142` checked out at `96a5354e`, level with `origin/INT-142`. Only the untracked `.claude/`. Its running dev server (:9000, started from this checkout) picks up the branch.
  - **europa-back-end:** stays on `main` `434567f`, level with `origin/main` (no INT-142 change, V-07). Clean.
- **Dependencies:** `node_modules` in all three checkouts matches their checked-out lockfiles (0 version mismatches, 0 missing, compared against `node_modules/.package-lock.json`); no `npm ci` needed.
- **Running:** Atlas :9000 yes. Callisto: no; the earlier `nest start` process (pid 46836) has exited, so it needs a start on `INT-142`. Europa: not running.
- Other tickets' worktrees were untouched. **Commits:** none.

### 2026-10-12T20:27:43Z — callisto-back-end (PR review findings R-1 to R-3)

- **Summary:** the PR review approved implementation correctness and scope, with three low-severity convention findings, worked with the finding / context / evidence method (ledger section "PR review, 2026-10-12").
  - **R-1:** casts in the new tests replaced. `as Contact` became `Object.assign(new Contact(), { … } satisfies Partial<Contact>)`. `createMockContact` couldn't be used: depcruise rule `no-cross-module-test-utility-imports` blocks a GCA spec from importing `src/contacts/test-utils`. `as unknown as jest.Mock` became `createMock<AuditConfigAccessor>` from `@golevelup/ts-jest`, as in `case-merge-audit.dispatcher.spec.ts:26`.
  - **R-2:** one `toHaveBeenCalledWith` became `toHaveBeenNthCalledWith(1, …)`.
  - **R-3:** the commit subjects keep `INT-142:`, because both repos' `main` already carry merged `INT-*` commits (for example callisto `55431e07` INT-140, atlas `cacfd124` INT-140) and inventing a PRDV number is ruled out. Recorded as the existing rule-governance debt (INT-138, INT-141).
- **Done by a subagent** in `wt\callisto-INT-142-review` (branch `INT-142-review`): 4 spec files, +22 / −20, test-only, 27 tests before and after. Reviewed, then applied to the `INT-142` integration worktree (byte-identical).
- **Done (2026-10-12T20:31:02Z):** committed `94f2f8a0` `INT-142: Use typed mocks in audit specs` and pushed (`9f2df650..94f2f8a0`). PR #481 now has 2 commits, and its commit block shows `94f2f8a0`. atlas: no change.

| Gate | Command | Scope | Result | Exception / risk |
| --- | --- | --- | --- | --- |
| audit | `npm audit --audit-level=high` | callisto `INT-142` | pass | — |
| lint | `npm run lint` | callisto | pass; `--fix` changed no file | — |
| type-check | `npm run type-check` | callisto | pass | — |
| tests | `npm test -- --runInBand --silent` | callisto: conventions (including depcruise), then the full suite | pass: 480 suites / 2,627 tests | — |
| format | `npx prettier --check <4 spec files>` | changed files | pass | — |

- **Tests added/updated:** no new cases; 4 existing INT-142 specs changed in form only (27 tests before and after).
- **Regression impact:** test-only change; no production file touched (`git diff --stat` lists 4 `__specs__` files).
- **API docs:** not relevant: no production code changed.
- **Conflicts / exceptions:** R-3. The `PRDV-X` commit rule conflicts with the INT ticket namespace. `INT-142:` is kept per the merged `INT-*` history on `main`; this is rule-governance debt, and the rule file is not edited.

### 2026-10-12T20:04:59Z — callisto-back-end, atlas-front-end (commit, push, draft PRs)

- **User direction:** "Create a draft PR of this implementation. https://github.com/planetdepos/atlas-front-end/pull/566 is an example of a good PR. We are now also using Jira … Update Cerberus with PR Details."
- **Audit waiver:** the atlas commit was held because its audit fails on issues already on `main` (51: 35 high, 5 critical; no package file changed). Following the INT-141 precedent ("That request is taken as the waiver for the held Callisto and Atlas commits", INT-141 changelog 2026-10-08T22:56:15Z), the request for a draft PR is taken as the waiver for this commit.
- **Done:**
  - Committed atlas `96a5354e` `INT-142: List client access audit types`.
  - Pushed `INT-142` to `origin` in both repos; local equals `origin/INT-142`: callisto `9f2df650`, atlas `96a5354e`.
  - Opened draft PRs against `main`, with no reviewers requested: [callisto-back-end #481](https://github.com/planetdepos/callisto-back-end/pull/481) and [atlas-front-end #601](https://github.com/planetdepos/atlas-front-end/pull/601), both titled `INT-142: Audit log - modify access`.
  - The bodies follow the INT-141 / #566 format: Jira link, description, commit block, Testing and Verification (placeholder: manual check pending, evidence box unchecked), checklist. The two PRs link to each other.
  - Sent both PR links to Cerberus `pullRequests` (records `579750bc…` and `942eabfb…`).
- **Commits:** atlas `96a5354e` (callisto `9f2df650` from the previous entry).
- **Conflicts / exceptions:** atlas audit gate waived by the draft-PR request (above); pre-existing, no package file changed.
- **Not done:** the manual end-to-end check and screenshots for Testing and Verification. Cerberus `repositories` still lists europa-back-end from earlier, and set-info can only add entries, never remove them.

### 2026-10-12T19:49:03Z — callisto-back-end, atlas-front-end (spec v2 implementation)

- **Summary:** spec v2 implemented by two subagents, each in its own worktree and branch (`wt\callisto-INT-142-callisto` / `INT-142-callisto`, `wt\atlas-INT-142-atlas` / `INT-142-atlas`). Each was limited to its inventory rows. Review checked every hunk against the change and test inventories before the piece was applied with `git apply --index`; each result is byte-identical to its piece diff. europa-back-end is untouched (V-07).
  - **callisto-back-end** (14 files, +913 / −15): rows A1, A3–A15 and tests T1–T14 only.
    - Every production hunk matches its spec block.
    - The only line removed from an existing spec file is the service spec's mocked transaction result, which the test inventory allows to change. No existing assertion was edited.
    - **Deviation:** the A10 port's one-line JSDoc was left out, because the orchestrator's prompt allowed only A12's comment. It has no behaviour.
    - **Committed `9f2df650`** `INT-142: Audit client access grant changes`.
  - **atlas-front-end** (3 files, +48 / −1): C1–C3 and T15–T18 only. The T17 title was renamed to match its four-entry assertion. **Staged, not committed:** audit fails on `main` (pre-existing); held for the user's waiver.
- **Plan used:** [INT-142-spec.md](INT-142/specs/INT-142-spec.md) (spec v2, approved)
- **Commits:** callisto `9f2df650` (local `INT-142`, not pushed). atlas staged in `wt\atlas-INT-142`.

**Tests run** (integration worktrees, final state, serial)

| Gate | Command | Scope | Result | Exception / risk |
| --- | --- | --- | --- | --- |
| audit | `npm audit --audit-level=high` | callisto `INT-142` | pass (21: 1 low, 20 moderate) | — |
| lint | `npm run lint` | callisto | pass; `--fix` changed no file | — |
| type-check | `npm run type-check` | callisto | pass | — |
| tests | `npm test -- --runInBand --silent` | callisto: `test:conventions` (pretest), then the full Jest suite | pass: 480 suites / 2,627 tests | — |
| conventions (Git Bash) | `COMSPEC=<Git bash>`, then `node node_modules/ts-node/dist/bin.js -r tsconfig-paths/register <check>` | the five `find`-based checks | pass, all 5 | Re-run through Git Bash because under `cmd.exe` they scan nothing |
| format | `npx prettier --check <changed files>` | callisto 14 / atlas 3 files | pass | — |
| audit | `npm audit --audit-level=high` | atlas `INT-142` | **fail**: 51 (11 moderate, 35 high, 5 critical) | Pre-existing; no package file changed. Commit held for a waiver |
| lint | `npm run lint` | atlas | pass | — |
| type-check | `npm run type-check` | atlas | pass | — |
| tests | `npx vitest run --maxWorkers 1` | atlas full suite | pass: 183 files / 1,645 tests (4 skipped, pre-existing) | — |

- **Tests added/updated:** exactly T1–T18 as listed in the spec.
  - Red checks: callisto, the 6 new transaction-script tests failed against unchanged code, and the service, assembler and dispatcher suites failed to load without the new files. Atlas: 4 tests failed against the unchanged constants.
  - T8 ("no dispatch when the save rejects") passes on unchanged code, because no dispatch existed; it guards the new ordering.
- **Regression impact:** the save response is still `{ selections }`; the permission-check order, the outbox write and the flag are unchanged, pinned by the existing transaction-script, service and action specs (all green). `ProceedingDetailProjection` gained an optional field only; its existing fixtures are unchanged and pass. Atlas: the existing render cases pass.
- **API docs:** not relevant. Checked: the save-grants route, its DTOs and Swagger (no file changed under `contacts/application`); `ProceedingDetailResponseDTO` and the proceeding-detail Swagger are unchanged.
- **Conflicts / exceptions:** atlas audit gate (pre-existing) holds the atlas commit. The A10 JSDoc deviation is above.

### 2026-10-12T19:27:37Z — callisto-back-end, atlas-front-end (spec v2 implementation, started)

- **User direction:** the reviewer approved spec v2 ("The spec is approved as it currently stands. It can proceed to implementation."), and the user asked: "Implement the spec on a new branch … separate worktrees … Send out subagents to work on each piece … Review and merge if applicable … The Original Ticket and A/C are your source of truth."
- **Integration worktrees:** new branch `INT-142` from `origin/main`, with no upstream: `wt\callisto-INT-142` at `9ece2f8d`, `wt\atlas-INT-142` at `bb8be210`. callisto's `origin/main` moved one commit (`9ece2f8d`, INT-232, an ECS task definition) since the spec's citation commit `43121c53`. `git diff --name-only` shows no spec-touched path changed. europa-back-end gets no worktree (V-07).
- **Pieces:** one subagent per repo, each in its own worktree and branch (`INT-142-callisto`, `INT-142-atlas`). Each is limited to its change-inventory rows and test-inventory cases. Review checks every diff hunk against an inventory row before it is applied to the integration worktree.
- **Audit (`npm audit --audit-level=high`):** callisto pass (21: 1 low, 20 moderate); atlas **fail** (51: 11 moderate, 35 high, 5 critical; pre-existing on `main`). The atlas commit is held for the user's waiver.
- **Intended commit messages:** `INT-142: Audit client access grant changes` (callisto), `INT-142: List client access audit types` (atlas).

### 2026-10-12T19:09:29Z — dustin-thomason (spec v2 review 4 resolved)

- **Summary:** R4-1. The test-inventory intro said no existing assertion is edited, contradicting T17. It now reads "Existing assertions stay unchanged, except for T17's `MULTI_PART_PATH_TYPES` exact-set assertion" (the reviewer's wording). The matching sentence in the ledger's R3-2 resolution was corrected too. The reviewer states no production-design change is required; ledger section "Spec v2 review 4, 2026-10-12".
- **Files:** `docs/atlas/INT-142/specs/INT-142-spec.md`, `docs/atlas/INT-142/specs/INT-142-locked-decisions.md`, this changelog
- **Commits:** none. No code.

### 2026-10-12T19:03:10Z — dustin-thomason (spec v2 review 3 resolved)

- **Summary:** worked the third review's findings with the finding / context / evidence method; ledger section "Spec v2 review 3, 2026-10-12".
  - **R3-1:** a missing contact or proceeding now aborts the save with the validators' existing not-found errors (V-11). Cause: `ContactsRepository` doesn't read through `TransactionContext`, so the earlier check didn't guarantee the row. Port types tightened; new test T5.
  - **R3-2:** the spec now states the three allowed edits to existing spec files, including the service fixtures gaining `audit`.
  - **R3-3:** T9 asserts `createdAt`.
  - Tests are renumbered T1–T18. Stale open-item rows in the ledger were corrected.
- **Files:** `docs/atlas/INT-142/specs/INT-142-spec.md`, `docs/atlas/INT-142/specs/INT-142-locked-decisions.md`, this changelog
- **Commits:** none. No code.

### 2026-10-12T18:51:28Z — dustin-thomason (spec v2 review resolved)

- **Summary:** worked the three findings of the spec v2 review with the finding / context / evidence method; ledger section "Spec v2 review, 2026-10-12".
  - **R2-1:** LD-006 reopened (taken from the user's forward), replaced by V-07. Callisto builds the five-part text in `path`, and europa-back-end is unchanged, because its default branch already shows `newState.path`. A2 and B1–B4 are removed; the formatting tests move to the Callisto assembler spec. V-08 revises deploy order and search: only Callisto and Atlas deploy; search matches the stored path as a side effect, with no search code added.
  - **R2-2:** A3 made optional (V-10), because two existing typed fixtures omit the field.
  - **R2-3:** a save with no change sends no record (V-09, replacing LD-010), with new test T6.
- **Files:** `docs/atlas/INT-142/specs/INT-142-spec.md`, `docs/atlas/INT-142/specs/INT-142-locked-decisions.md` (LD-006, LD-010, LD-014 and LD-015 marked superseded; new review section), this changelog
- **Commits:** none. No code.

### 2026-10-12T18:36:44Z — dustin-thomason (spec v2)

- **User direction:** "Start" (back to the spec, with the AC as the source of truth).
- **Summary:**
  - Retired spec v1 to `INT-142/dnu/` with a README.
  - Wrote spec v2. Every code change is a row in a change inventory: callisto A1–A15, europa B1–B4, atlas C1–C3. Each row names its AC line and the existing code checked, with `file:line` evidence that the existing code can't do it.
  - A fixed test inventory (T1–T16) maps each test to a change and an AC line.
  - Compared with v1, removed: the new repository, its integration spec and the seeder change; the aggregator, param file and converter; the audit assembler and delta converter classes; the save-result projection file; the service `try/catch`; registry entries; and every out-of-scope test.
  - Ledger V-01 to V-06 record the new decisions and what they supersede.
  - LD-006 is flagged as the one locked decision that costs code beyond the AC alone, for the user to keep or reopen.
- **Files:** `docs/atlas/INT-142/specs/INT-142-spec.md` (rewritten), `docs/atlas/INT-142/dnu/INT-142-spec.md` (moved), `docs/atlas/INT-142/dnu/README.md` (new), `docs/atlas/INT-142/specs/INT-142-locked-decisions.md`, this changelog
- **Commits:** none. No code.

### 2026-10-12T18:28:20Z — callisto-back-end, europa-back-end, atlas-front-end (implementation torn down)

- **User direction:** "Then tear it all down, and back to the spec, seriously, just delete the whole branch you started, we aren't going to try and patch a bunch of stuff … The AC is the source of truth, you didn't check it, we can't trust your implementation on ANYTHING."
- **Why:** the user's code review found changes beyond the acceptance criteria: a new repository where existing reads would do, a duplicate grants read, a `try/catch` around a producer that never throws, and tests outside the ticket's scope. The cause: the spec was written and implemented without checking each part against the AC and against existing code, although the implementation request said "The Original Ticket and A/C are your source of truth."
- **Removed (all local; nothing was ever pushed: `git ls-remote --heads origin 'INT-142*'` is empty in all three repos):**
  - Worktrees `wt\{callisto,europa,atlas}-INT-142` and `wt\{callisto,europa,atlas}-INT-142-{callisto,europa,atlas}`. Junctions were unlinked with `rmdir` first; `git worktree prune` was run.
  - Branches `INT-142` and `INT-142-{callisto,europa,atlas}` in all three repos: callisto `INT-142` was `3607c90d`, europa `INT-142` was `6886ec6`, atlas `INT-142` was `bb8be210` with staged changes. The two commits remain only in the local reflog.
  - Test databases `callisto_test_int142_callisto` and `callisto_test_int142_integration` were dropped from `callisto-postgres`.
- **Left as they were:** the main checkouts, on `main` (callisto `43121c53`, europa `434567f`, atlas `bb8be210`). The initiation stashes (callisto `stash@{0}`, europa `stash@{0}`) predate the implementation and are untouched.
- **Commits:** none.

### 2026-10-12T18:00:04Z — callisto-back-end, europa-back-end, atlas-front-end (implementation, since torn down)

- **Summary:** the INT-142 spec is implemented. Three subagents, one per repo, each worked in its own worktree and branch (`wt\callisto-INT-142-callisto` / `INT-142-callisto`, `wt\europa-INT-142-europa` / `INT-142-europa`, `wt\atlas-INT-142-atlas` / `INT-142-atlas`), with `node_modules` junctioned to the integration worktree. Each piece was reviewed against the original ticket, the ledger and the spec. It was then applied to its integration worktree with `git apply --index`, and the result was checked byte-identical to the piece's staged diff. The gates were run again there.
  - **europa-back-end:** the `CLIENT_ACCESS_UPDATED` branch, `toGrantListDisplay` and `toQuotedName` (LD-018), and the state types; 16 new spec cases. Approved first pass. **Committed `6886ec6`** `INT-142: Format client access updated audit path`.
  - **atlas-front-end:** the three constants; `SearchDataGrid.vue` unchanged (S-08); 6 new or updated spec cases. Approved first pass. **Staged, not committed:** the audit fails on `main` (pre-existing), so the commit is held for the user's waiver.
  - **callisto-back-end:** all of Part A, 32 files. Review sent the piece back once (R-C1): `ContactAccessAuditModule`'s JSDoc gave design rationale ("rather than in ProceedingsModule"), which belongs in the PR; it was trimmed to the constraint. **Committed `3607c90d`** `INT-142: Audit client access grant changes`.
- **Subagent findings, all resolved with evidence:**
  - Callisto: `seedCase` gained an optional `shortName` override; its existing caller still passes. Integration specs run against a separate database (`TEST_DB_NAME`), because the helper drops the schema of a shared name. Extra tests: the reads use the open transaction; the collection-check failure; a non-Error rejection.
  - Europa: test fixtures set `path` / `bucket` to `undefined` instead of making them optional in the entity (beyond B.2). One extra case: a blank type is skipped.
  - Atlas: spec blocks placed after the `RECATEGORIZE` chip block, so the merge with INT-141's open PR has 0 conflicts (simulated with `git merge-file`). No `MULTI_PART_PATH_MAX_SEGMENTS` entry is needed for `CLIENT_ACCESS_UPDATED`.
- **Plan used:** [INT-142-spec.md](INT-142/specs/INT-142-spec.md)
- **Commits:** europa `6886ec6`, callisto `3607c90d` (local `INT-142`, not pushed). atlas: staged in `wt\atlas-INT-142`, held.

**Tests run** (integration worktrees, final state, serial)

| Gate | Command | Scope | Result | Exception / risk |
| --- | --- | --- | --- | --- |
| audit | `npm audit --audit-level=high` | callisto `INT-142` | pass (21: 1 low, 20 moderate) | — |
| lint | `npm run lint` | callisto | pass; `--fix` changed no file | — |
| type-check | `npm run type-check` | callisto | pass | — |
| tests | `npm test -- --runInBand --silent` | callisto: `test:conventions` (pretest), then the full Jest suite | pass: 484 suites / 2,662 tests | — |
| conventions (Git Bash) | `COMSPEC=<Git bash>`, then `node node_modules/ts-node/dist/bin.js -r tsconfig-paths/register <check>` | the five `find`-based checks (domain-naming, dto-structure, domain-type-structure, no-util-files, exchange-ownership) | pass, all 5 | On Windows `cmd.exe` these scan nothing (INT-138 C12); re-run through Git Bash so they scan |
| integration | `TEST_DB_NAME=callisto_test_int142_integration npx jest --config jest-integration.json --runInBand src/granting-client-access/contacts/infrastructure/repositories` | callisto contacts repository integration specs, including the new one | pass: 5 suites / 41 tests | Local `callisto-postgres` container. Databases `callisto_test_int142_callisto` and `callisto_test_int142_integration` were created and can be dropped |
| format | `npx prettier --check <changed files>` | callisto 32 / europa 3 / atlas 3 files | pass | The husky hook isn't installed in worktrees; run by hand on changed files only |
| audit | `npm audit --audit-level=high` | europa `INT-142` | pass (20 moderate) | — |
| lint | `npm run lint` | europa | pass | — |
| type-check | `npm run type-check` | europa | pass | — |
| tests | `npx jest --config jest-e2e.json --runInBand --silent` | europa full suite | pass: 32 suites / 145 tests | — |
| audit | `npm audit --audit-level=high` | atlas `INT-142` | **fail**: 51 (11 moderate, 35 high, 5 critical) | Pre-existing: lockfile equals `main`'s, no package file changed. Commit held for a waiver |
| lint | `npm run lint` | atlas | pass | — |
| type-check | `npm run type-check` | atlas | pass | — |
| tests | `npx vitest run --maxWorkers 1` | atlas full suite | pass: 183 files / 1,648 tests (4 skipped, pre-existing) | — |

- **Tests added/updated:**
  - callisto: 7 new specs (aggregator, dispatcher, event assembler, converter, delta converter, audit assembler, repository integration); the service and transaction-script specs extended. 14 of the 28 service and transaction-script tests failed against `main`'s code.
  - europa: 16 cases in the transaction-script spec; 15 failed before the production change.
  - atlas: `constants.spec.ts` (4 new or updated) and `SearchDataGrid.spec.ts` (3); 6 failed against the unfixed constants. The grey-chip case passes either way, because it guards existing behaviour.
- **Regression impact:**
  - callisto: the save-grants response is still `{ selections }`, the outbox write is still flag-gated, and the permission check still runs first. These are pinned by the existing action, transaction-script and service specs, all green. No `proceedings/` or case-group file changed. `ResourceState` gained optional fields only.
  - europa: all 21 existing transaction-script cases pass.
  - atlas: the existing `CATEGORIZE`, `RECATEGORIZE`, `PERMISSIONS_UPDATED` and `CREATED` + `PROCEEDING` render cases pass.
- **API docs:** not relevant. Checked: callisto's save-grants route, request and response DTOs and `SaveContactDeliverableTypeGrantsSwagger` (`git diff` empty under `contacts/application`); europa's search DTOs. All unchanged.
- **Conflicts / exceptions:** atlas audit gate failing on pre-existing issues; commit held for the user's waiver.

### 2026-10-12T17:29:48Z — callisto-back-end, europa-back-end, atlas-front-end (implementation, started)

- **User direction:** "Implement the spec on a new branch … for all related repos, create separate worktrees for each because there are multiple agents working in this space. Send out subagents to work on each piece, having them create their own worktrees as well … Review and merge if applicable, otherwise send them out to resolve. Each piece must be completed by a sub agent … The Original Ticket and A/C are your source of truth."
- **Integration worktrees** on branch `INT-142` (all at `origin/main`): `wt\callisto-INT-142` `43121c53`, `wt\europa-INT-142` `434567f`, `wt\atlas-INT-142` `bb8be210`. Each gets its own `HUSKY=0 npm ci`, because the main checkouts' node_modules predate today's pull.
- **Pieces:** one subagent per repo, each in its own worktree and branch (`INT-142-callisto`, `INT-142-europa`, `INT-142-atlas`), changes left staged and not committed. They are reviewed against the original ticket, ledger and spec, then applied to the integration worktree, where the gates run again. This is the INT-140 / INT-141 process.
- **Audit (pre-commit gate, `npm audit --audit-level=high`):** europa pass (20 moderate); callisto pass (1 low, 20 moderate); atlas **fail** (51: 11 moderate, 35 high, 5 critical), pre-existing on `main`. The atlas commit is held for the user's waiver.
- **Intended commit messages:** `INT-142: Audit client access grant changes` (callisto), `INT-142: Format client access updated audit path` (europa), `INT-142: List client access audit types` (atlas).

### 2026-10-12T17:25:53Z — dustin-thomason (review questions locked)

- **Summary:** The reviewer chose option A for Q-01 (conditional double-quoting, with embedded quotes doubled) and Q-02 (accept and document), and accepted R-2. The user forwarded the decisions. Locked as ledger LD-018 and LD-019; R-1 and R-3 marked complete with evidence; reviewer decisions D-1 to D-4 recorded. Spec: B.2 gains `toQuotedName` and `NAME_NEEDS_QUOTING`; B.3 gains quoting cases; the quoted example and manual step 8 added; provisional markers removed; header reads "Implementation readiness: ready". The review response file gains an Outcome note.
- **Files:** `docs/atlas/INT-142/specs/INT-142-spec.md`, `docs/atlas/INT-142/specs/INT-142-locked-decisions.md`, `docs/atlas/INT-142/specs/INT-142-spec-review-response.md`, this changelog
- **Commits:** none

### 2026-10-12T17:20:13Z — dustin-thomason (spec review response)

- **Summary:** Worked the spec review's three findings using the finding / context / evidence method. R-2 (`N/A` for an empty list) is resolved by precedent plus the user's direction (spec S-09). R-1 (Q-01 list format, blocker) and R-3 (Q-02, `|` in a name) are open and written up as best-practice questions for the reviewer in [INT-142-spec-review-response.md](INT-142/specs/INT-142-spec-review-response.md). The spec marks the format as provisional and lists what it blocks. Q-01's recommendation now quotes any name containing `,` or `›`.
- **Files:** `docs/atlas/INT-142/specs/INT-142-spec.md`, `docs/atlas/INT-142/specs/INT-142-locked-decisions.md` (E-20 to E-22, Q-02, "Spec review, 2026-10-12" section), `docs/atlas/INT-142/specs/INT-142-spec-review-response.md` (new), this changelog
- **Commits:** none

### 2026-10-12T17:01:12Z — dustin-thomason (spec)

- **Summary:** Wrote [INT-142-spec.md](INT-142/specs/INT-142-spec.md) with the write-spec skill, after re-checking the ledger's evidence on `main` in all three repos (three read-only searches). Settled the ledger's open implementation items as S-01 to S-08 (chain location, resource path, where the audit data is built, the names read, post-commit error handling, Atlas list order). Ledger: two open items marked settled in the spec, E-19 added (case-group grants from INT-42; proceeding foreign key dropped), case-group grants recorded as out of scope.
- **Plan used:** spec row above
- **Files:** `docs/atlas/INT-142/specs/INT-142-spec.md` (new), `docs/atlas/INT-142/specs/INT-142-locked-decisions.md`, this changelog
- **Commits:** none
- **Notes:** Findings that differ from the 2026-09-29 ledger: the `CLIENT_ACCESS_FILE_AUDIT` binding is at `proceedings.module.ts:209-212`; `ResourceState` is not exported and has no list field; europa-back-end has no ingest allow-list; the Atlas exact-set test on `MULTI_PART_PATH_TYPES` must be updated.

### 2026-10-12T16:24:24Z — dustin-thomason (intake, branches, ledger)

- **Summary:** Ran the Cerberus intake for INT-142: wrote [INT-142-original-ticket.md](INT-142/INT-142-original-ticket.md) and [INT-142-comments.md](INT-142/INT-142-comments.md); the original ticket's title, link and Original Request match the intake record exactly. Cut `INT-142` from `origin/main` in callisto-back-end, europa-back-end and atlas-front-end. Ledger: LD-013 superseded by LD-017 (branch from `main`), evidence E-18 added, Q-01 precedent check recorded (no earlier ticket writes a list; Q-01 stays open).
- **Plan used:** ledger row above
- **Files:** `docs/atlas/INT-142/INT-142-original-ticket.md`, `docs/atlas/INT-142/INT-142-comments.md`, `docs/atlas/INT-142/specs/INT-142-locked-decisions.md`, this changelog
- **Commits:** none
- **Notes:**
  - callisto-back-end: a formatting-only change to `job-submission.service.spec.ts` left on `INT-141` since 2026-10-09 was stashed before switching (`stash@{0}`, message names INT-141). europa-back-end: `.prettierrc` and `.swcrc` show as modified with line-ending differences only; they carried over to `INT-142`.
  - Cerberus: INT-142 is not in the live data. A stale Cerberus tab, in conflict state since 16:07:33Z, takes the inbox records first and holds INT-142 only in its own memory (`Cerberus/data/conflicts/cerberus-2026-10-12T16-07-33-301Z.json`). Three intake deliveries were all taken by that tab. Its info fields (repositories, related work, ledger) are not set yet.

---

## Current state (as of 2026-10-12)

- All three regular checkouts are on `main` at `origin/main` (initiation, 2026-10-12): callisto-back-end `43121c53`, europa-back-end `434567f`, atlas-front-end `bb8be210`. Local `INT-142` branches point at the same commits, with no code changes. europa-back-end's line-ending-only `.prettierrc` / `.swcrc` changes are in `stash@{0}`; callisto-back-end's INT-141 formatting residue is in `stash@{0}`. The other agent's INT-144 work is in its own worktree (`wt/atlas-INT-144`).
- Locked-decision ledger in place; Q-01 (how each item in the granted/revoked lists is written) is the open decision.
- Spec reviewed and implementation-ready (2026-10-12): [INT-142-spec.md](INT-142/specs/INT-142-spec.md). Q-01 → LD-018, Q-02 → LD-019. Case-group grants are out of scope.
- **Implementation torn down (2026-10-12):** all INT-142 branches, worktrees and test databases are deleted; nothing was pushed. No code exists for INT-142.
- **Spec v2 approved (2026-10-12):** [INT-142-spec.md](INT-142/specs/INT-142-spec.md). Only callisto-back-end and atlas-front-end change; europa-back-end is unchanged (V-07).
- **Implemented and pushed (2026-10-12), draft PRs open:**
  - callisto `INT-142` `94f2f8a0` (2 commits; PR review fixes in the second), [#481](https://github.com/planetdepos/callisto-back-end/pull/481)
  - atlas `INT-142` `96a5354e`, [#601](https://github.com/planetdepos/atlas-front-end/pull/601)
- Piece worktrees `wt\callisto-INT-142-callisto` and `wt\atlas-INT-142-atlas` remain, with `node_modules` junctions. Unlink a junction with a non-recursive `rmdir` before removing its worktree.
- **End-to-end check passed (2026-10-13):** [INT-142-test-evidence.md](INT-142/testing/INT-142-test-evidence.md), 9 screenshots. Not done: adding the screenshots to the PRs' Testing and Verification sections.
- Cerberus: INT-142 created at 16:28:09Z (ticket `t_44e73e49…`) once no stale tab was open; repositories, related work, ledger location and ledger status set by set-info. Two malformed list entries (one comma-joined string each in Repositories and Related work, from a `powershell -File` call that passed the array as one string) remain; set-info can only add list entries, so they are removed in the Ticket info form.
