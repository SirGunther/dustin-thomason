# INT-138 — Audit log entries for deliverable type categorization

_Working title. The ticket was supplied as request text only, and the ClickUp title was not captured._

## Ticket

- **Ticket:** [INT-138](https://pd-product-dev.atlassian.net/browse/INT-138) (Jira)
- **Repo:** `atlas-front-end`, `europa-back-end`, `callisto-back-end` (the scope given at kickoff). Phase 1 recon will show which of them actually change.
- **Branch:** _(not cut yet; the branch step belongs to Phase 4/5)_
- **PR:** _(link when opened)_
- **Artifacts:** [INT-138/](INT-138/). This is an orchestrated ticket, and the ledger is [INT-138/orchestration.md](INT-138/orchestration.md)
- **WorkLists card:** `todo-1790172671871-1461f0f9` (supplied by the user)

---

## Requirements (verbatim)

> As an Ops manager, I want to be able to review an audit log of key actions related to Client Access, so that I can see the "who, what, when" for these critical functions.
>
> * * *
>
> ## Acceptance Criteria
>
> -   Ops can view a log in Europa for **deliverable type categorization**
> -   The log displays the following details:
>     -   file path
>     -   user info
>     -   date/time
>     -   **categorization** actions taken
> -   A new Event Type is created for this action: **Categorize**
>     -   This event type is added to the Event Type drop down in Europa
> -   Resource Type for this action is: **File**
> -   Path format:
>     -   Filepath: \[file path\]
>     -   Deliverable Type: \[deliverable type\]
>     -   Collection: if applicable, \[collection\], if not, "N/A"

---

## Context

- The ticket is run under the `orchestrate` skill (`agents/skills/orchestrate/SKILL.md`). All artifacts live under `docs/atlas/INT-138/`, which is the atlas per-ticket folder convention, not the skill's default `tickets/<slug>/`.
- At kickoff (2026-09-23), all three repos were put on `main` and fast-forwarded from `origin`. Only Europa had uncommitted work, and it was stashed. See the ledger's Kickoff record for SHAs and stash names.
- Prior tickets that touch deliverable types and collections have coverage ledgers Phase 1 must consult first: PRDV-16312, PRDV-16313, PRDV-16461. There is also `PRDV-16939` (track/collection consolidation) and the domain note `docs/system-architecture/domain-knowledge-system/domains/audit-log.md`.

---

## Plans

_No rows. The `orchestrate` skill does not keep Plans rows. The approved plans are saved in the ticket folder: `investigations/INT-138-recon-and-plan.md` at Phase 2 and `INT-138-implementation-plan.md` at Phase 5._

---

## Session log

_Newest first._

### 2026-10-02T00:35:45Z — callisto-back-end (comment audit cleanup, committed locally)

- **Summary:** applied a comment audit of the net INT-138 diffs (atlas `ad059eec…36999e87`, callisto `59b1abd3…e285f39e`). It removes 12 explanatory comments that repeat the code, revises 2, and keeps 10. AAA test scaffolding is exempt.
  - **Revised:** `ClientAccessFileAuditPort` now keeps only the `false` delivery semantics. `IsCategorizationAuditDuePredicate`'s class comment is shortened, and "neither before or after" now reads "neither before nor after".
  - **Removed:** comments on `CategorizationAuditCandidate.categorization`, `FileAttachmentCategorizationProjection`, `FileCategorizationAuditFileProjection`, the three `categorizationAudits` properties (approve, recategorize, unapprove), the four `assembleCategorizationAudits` helpers (approve, recategorize, unapprove, upload), and one unapprove spec narration line.
- **Mistake and correction:** the first pass was made in the main `callisto-back-end` / `atlas-front-end` checkouts. Both were in detached HEAD at INT-139's tip (`a90c4c40` / `2b7e1867`), not on INT-138, and 5 of the callisto files differ between the branches. Nothing was committed there.
  - Those edits were stashed in each repo as `INT-138 comment audit cleanup … (mistakenly edited on detached INT-139 commit …)`, and the callisto checkout was moved to `INT-138`.
  - The 7 files identical on both branches were restored from the stash. The 5 that differ were re-edited against INT-138's text, which matches the audit's line numbers.
  - The first pass also missed half of item 8 (it fixed the grammar but did not shorten the comment). Both parts are done now.
  - INT-139, its branches and its worktrees were not changed.
- **Atlas not committed:** PR #582 is already `APPROVED`. Audit item 2 (the `toPathSegments` comment in `SearchDataGrid.vue`) is kept only in atlas `stash@{0}`, and atlas `INT-138` still carries that comment.
- **PR status at commit time:** callisto #464 `REVIEW_REQUIRED`; atlas #582 `APPROVED`.
- **Files:** 12 callisto files under `src/granting-client-access/domain/` (ports, predicates, projections, and the approve, recategorize, unapprove and upload transaction scripts). The diff is comment-only: 3 lines added, 35 removed.
- **Commit:** `INT-138: Remove redundant audit comments` (local, not pushed).

| Gate | Command | Scope | Result | Exception / risk |
| ---- | ------- | ----- | ------ | ---------------- |
| audit | `npm audit --audit-level=high` | callisto `INT-138` | **fail**: 5 high (`@grpc/grpc-js`, `brace-expansion`, `fast-uri`, `joi`, `undici`) | Pre-existing: `git diff origin/main INT-138 -- package.json package-lock.json` is empty, and the change is comment-only. Committed locally on the user's instruction; not pushed |
| lint | `npm run lint` | callisto full repo | pass, no extra files changed | — |
| tests | `npm test -- --runInBand --silent` | callisto full suite | pass: 448 suites / 2444 tests | — |

- **Tests added/updated:** none. Comments only, with no behavior change. The existing specs for the 12 files cover them unchanged.
- **Regression impact:** isolated. The diff contains no non-comment lines (checked with `git diff -U0`), so signatures, types and runtime code are unchanged.
- **API docs:** not relevant. No route, DTO, decorator or swagger helper is in the diff.

### 2026-09-29T19:59:22Z — callisto-back-end + atlas-front-end (spec aligned, PRs updated, pushed)

- **Summary:** the Callisto spec was brought in line with the code: Callisto builds the path, Atlas shows it, Europa is unchanged. The Europa formatting part, the structured-state description, the removed port methods and `ClientAccessFileAuditParams` were taken out, and citations were updated for the files that changed after the rewrite. The descriptions of PRs #464 and #582 were corrected: Planet Summary, the prior categorization, the `requester_identity` migration and the `info` chip colour are removed. Both branches pushed. The local Europa commit is not pushed and is not part of the ticket.
- **Files:** `docs/specs/atlas-client-access/deliverable-management/8-story-INT-138-categorize-audit-events/8-story-INT-138-categorize-audit-events.md`.
- **Commit:** `INT-138: Align spec with current implementation`.

| Gate | Command | Scope | Result | Exception / risk |
| ---- | ------- | ----- | ------ | ---------------- |
| audit | `npm audit --audit-level=high` | callisto, atlas | fail | Pre-existing (`fast-uri`, `js-yaml` in callisto; atlas high advisories). Neither branch changes `package.json` or the lockfile. Pushed on the user's instruction |
| lint | `npx eslint <changed src files>`; `npm run lint` | callisto changed files; atlas | pass | — |
| tests | `npx jest --config jest-e2e.json --runInBand src/granting-client-access src/proceedings`; `npx vitest run --maxWorkers 1` | callisto Client Access + proceedings; atlas full | pass: 1,284; 1,436 (4 skipped) | Callisto full suite last run at `ac2b249a` (2,444 pass); later commits touch only Client Access services, covered by the scoped run |

### 2026-09-29T17:13:37Z — callisto-back-end + atlas-front-end (scope review: out-of-scope work removed)

- **Summary:** a review against the ticket's acceptance criteria confirmed four out-of-scope items. All four were removed from the `INT-138` branches, and the spec was rewritten to match.
  1. **Planet Summary:** 20 files restored to `main` and 5 new files removed. That drops the `file_derivation_jobs.requester_identity` column and migration, the requester snapshot, and the summary-completion dispatch. LD-012 and LD-014 are withdrawn, LD-009's path F is removed, and story criterion 9 is withdrawn.
  2. **Prior categorization:** the record no longer carries it. `oldState.path` equals `newState.path`, matching `main`'s FILE-event convention when no prior state is tracked. Removed with it: approve's `findCategorizationsByIds` read, the recategorize and approve `previous` fields, and the lookup of previous names.
     - **Kept:** unapprove's read of the ids it clears. `IsCategorizationAuditDuePredicate` needs it so the removed-categorization record (C8) is kept.
  3. **`|` → `¦` substitution:** removed. Values are written verbatim, and collection names already reject `|` (`validate-dynamic-collection-name.validator.ts:7`).
  4. **Atlas refactor:** atlas restored to `82f087c2`'s content, without the comment `fd753cd2` removed. That drops `splitPathSegments`, the const-object literals and the changed `PERMISSIONS_UPDATED` edge rendering.
- **Local database:** the `requester_identity` column the removed migration added is still in the local database. The entity no longer maps it.

| Gate | Command | Scope | Result | Exception / risk |
| ---- | ------- | ----- | ------ | ---------------- |
| lint | `npm run lint` | callisto | pass | — |
| type-check | `npm run type-check` | callisto | pass | — |
| architecture | `npx jest --config jest-e2e.json --runInBand src/__tests__/architecture.spec.ts` | callisto | pass: 1/1 | — |
| conventions | 6 find-based checks, `COMSPEC`=Git Bash | callisto | pass: 6/6, 0 path errors | — |
| tests | `npx jest --config jest-e2e.json --runInBand --silent` | callisto full suite | pass: 450 suites / 2445 tests | — |
| type-check / lint | `npm run type-check`; `npm run lint` | atlas | pass | — |
| tests | `npx vitest run --maxWorkers 1 src/europa` | atlas Europa page | pass: 4 files / 38 tests | — |
| live | Atlas `/europa-stuff`, CATEGORIZE filter, restored code | local | 7 rows; the Path shows 3 bold-labelled lines | — |

### 2026-09-29T15:18:34Z — callisto-back-end + atlas-front-end + europa-back-end (manual end-to-end test: pass)

- **Summary:** ran test plan M-1 to M-4 and M-6 locally through the full path. Callisto → SQS (`sqs-triton-sb-ue1-derrick-auditevent.fifo`) → Europa → the Atlas `/europa-stuff` page. Driven with Playwright over CDP in the user's signed-in Chrome, on job 112233, proceeding 3002.
  - **Result:** every categorization action produced one `CATEGORIZE` record per file, with the ticket's path format and the user's email, name and date.
  - **Not tested:** M-5 (Planet Summary), which can only be tested in the sandbox.
  - **Test plan:** results log rows dated 2026-09-29.
- **Trees tested:**
  - callisto `INT-138` `ef894a18`;
  - atlas `INT-138` `e5a29a4a` plus the uncommitted review fixes (7 files);
  - europa `main` `1082fda`.

  No product code changed in this session.
- **Environment issues found and resolved:**
  - **Europa returned 401 to Atlas.** Europa's `.env` Cognito pool and client (`us-east-1_JMwbd0Wn7`) differed from the ones Atlas and Callisto use (`us-east-1_otBuqDnBc`). Europa's `.env` was set to Atlas's pool and client with the user's approval.
  - **Atlas couldn't reach local Europa.** Atlas sends Europa requests to `localhost:3000` unless `EUROPA_API_URL` is set (`quasar.config.ts:7-13`). `EUROPA_API_URL=http://localhost:3006` in atlas `.env.local` is kept.
  - **Callisto `upload-start` returned 500 with `ExpiredToken`.** Old AWS credentials in the Git Bash session that starts Callisto overrode the fresh ones in `.env.local`. The user cleared them and restarted.
  - **An unnecessary `.env` edit (my error).** I changed Callisto `.env`'s audit queue on an unverified assumption. Callisto reads `.env.${NODE_ENV}` (`config.module.options.ts:7`), and `.env.local` already had Europa's queue, so the edit had no effect. It has been reverted to the original value.
- **Evidence:** `docs/atlas/INT-138/testing/screenshots/`, 01 to 04. Mapped to the criteria in the test plan's results log.
- **Spec verified against the code:** four parallel checks (header and Part A, B, C, D) found 29 inaccuracies. All are corrected in the spec, and the copy at `specs/INT-138-spec.md` is synced.
  - The one behavior finding: the Planet Summary CATEGORIZE dispatch runs inside the inbox processing transaction, before commit, not after it (`inbox.registry.ts:126-137`, `transaction-context.service.ts:17-21`). The spec now says so. The code comment at `process-proceeding-transcript-summary-completed.service.ts:108` still says the rows are committed at that point.
- **Committed to the local `INT-138` branches:** the spec and README entry (callisto); the 7 review-fix files (atlas). The full atlas suite passes, 161 files / 1447 tests.
- **Test data left in place:** 4 files on proceeding 3002: `INT138-transcript-A.pdf`, `INT138-transcript-B.pdf`, `INT138-exhibit-C.pdf` and `INT138-submission-D.pdf`. Their objects are in `s3-callisto-sb-ue1-jobs`, and their audit records are in Europa.

| Gate | Command | Scope | Result | Exception / risk |
| ---- | ------- | ----- | ------ | ---------------- |
| type-check | `npm run type-check` | atlas working tree | pass | — |
| lint | `npm run lint` | atlas working tree | pass | — |
| tests | `npx vitest run --maxWorkers 1 src/europa` | atlas Europa page | pass: 5 files / 47 tests | pre-run check; the full gates are in the 2026-09-26 entry, and no code has changed since |
| manual | M-1 to M-4, M-6, neighbors | local end-to-end | pass | M-5 not run (sandbox only) |

### 2026-09-26T03:38:08Z — callisto-back-end + atlas-front-end (convention review: fixes merged and verified)

- **Summary:** the convention review is complete.
  - **callisto:** fixes merged into `INT-138`.
    - `cee3336b`: audit core (fix `3b48af53`).
    - `bd48d219`: Planet Summary (fix `a353d761`).
    - `7fecbd77`: Client Access (fix `c98603d6`).
    - `ef894a18`: a spec assignment that pins the aggregator to the new GCA port.
  - **atlas:** the fixes in `INT-138-review-atlas` are complete and verified, but **uncommitted**. The commit rule stops commits while `npm audit` fails (11 high, pre-existing), and the user hasn't waived it yet.
  - **Spec** synced to the final code in both copies. LD-016 supersedes LD-006's wording, and the post-commit guarantee is unchanged.
- **Behavior changes introduced by the review:**
  - approve records the observed previous categorization;
  - a failed or `false` dispatch on a Client Access path is logged and no longer blocks other files' records or fails the request;
  - `|` inside a value displays as `¦`;
  - Atlas renders an unlabelled segment as plain text, and an empty path as nothing.
- **Commits:** local only. The `INT-138:` prefix conflicts with the commit rule (concern C15).
- **Gates (final):**

| Gate | Command | Scope | Result | Exception / risk |
| ---- | ------- | ----- | ------ | ---------------- |
| audit | `npm audit --audit-level=high` | callisto `INT-138` `ef894a18` | pass (1 low) | — |
| lint | `npm run lint` | callisto `INT-138` | pass, 0 files changed | — |
| type-check | `npm run type-check` | callisto `INT-138` | pass | — |
| architecture | `test:architecture` (default shell) | callisto `INT-138` | pass | — |
| conventions | 6 find-based checks, `COMSPEC`=Git Bash | callisto `INT-138` | pass | Windows false pass without it (C12) |
| tests | `npx jest --config jest-e2e.json --runInBand --silent` | callisto full suite | pass: 451 suites / 2479 tests | — |
| lint / type-check | `npm run lint`; `npm run type-check` | atlas review working tree | pass | — |
| tests | `npx vitest run --maxWorkers 1` | atlas full suite | pass: 161 files / 1447 tests | — |
| audit | `npm audit --audit-level=high` | atlas | **fail**: 11 high | pre-existing. Blocks the atlas commits pending the user's waiver. The earlier atlas commits `82f087c2` and `e5a29a4a` were made without one |

### 2026-09-26T00:40:00Z — callisto-back-end + atlas-front-end (convention review and fixes, local branches)

- **Summary:** the INT-138 implementation was reviewed against every rule set, and the findings are being fixed now. Review agents covered:
  - all 9 callisto `.cursor/rules` files;
  - all 8 atlas `.cursor/rules` files;
  - `dustin-thomason/docs/reviewers` (`pr-review-patterns.md`, `agent-self-review-checklist.md`).

  Each finding was verified against the code, then fixed by area on its own branch, cut from `INT-138`:
  - `INT-138-review-gca`
  - `INT-138-review-core` (merged as `cee3336b`)
  - `INT-138-review-summary`
  - atlas `INT-138-review-atlas`: **uncommitted**, because the pre-existing atlas `npm audit` failure (11 high) blocks commits under the commit rule until the user waives it.
- **Files:** by area, in the per-rule report once the fixes are complete.
- **Commits:** local only; `INT-138:` subjects. The prefix conflict is concern C15.
- **Notes:**
  - The two atlas commits made earlier (`82f087c2`, `e5a29a4a`) also went in while the same pre-existing audit failure stood, without an explicit waiver. This is disclosed to the user.
  - Concerns C13 to C15 were added: the write-time display string, the system-actor/PII precedent, and the commit-prefix rule gap.

### 2026-09-25T23:33:12Z — callisto-back-end + atlas-front-end (Phase 5 Implement: merged locally, gates green)

- **Summary:** all four spec parts are implemented by subagents on separate worktrees and branches. Each was reviewed and merged locally into `INT-138`.
  - **callisto `INT-138` @ `9d4ce4e9`:**
    - audit core `c0eab69f`;
    - Planet Summary `f8bf0534` + `dd86d1ff`, including migration `1790377497027-alter__add_requester_identity__file_derivation_jobs_table.ts`;
    - GCA dispatch `14ac1634` + `d794fc5d`;
    - review commit `32d51293`.
  - **atlas `INT-138` @ `e5a29a4a`:** Europa page `82f087c2`.
  - **europa:** unchanged.
  - **The spec held on behavior.** Implementation forced three corrections, all applied to both spec copies:
    - the requester converter lives in the context assembler (depcruise `services-no-converters`);
    - one warning per repository kind;
    - `Array.from` (ES5 target).
- **Plan used:** the spec's Parts A to D. Phase 4 was skipped by user direction.
- **Files:** as listed in each spec part. See `testing/INT-138-testing-implementation.md` for the scenarios and the forced changes.
- **Commits:** local only, listed above. Not pushed; no PRs.
- **Gates (final post-merge trees):**

| Gate | Command | Scope | Result | Exception / risk |
| ---- | ------- | ----- | ------ | ---------------- |
| audit | `npm audit --audit-level=high` | callisto `INT-138` | pass (1 low) | — |
| lint | `npm run lint` | callisto `INT-138` | pass, 0 files changed | — |
| type-check | `npm run type-check` | callisto `INT-138` | pass | — |
| architecture + conventions | `test:architecture` (default shell); six find-based checks with `COMSPEC`=Git Bash | callisto `INT-138` | pass | Windows false-pass without `COMSPEC` (concern C12) |
| tests | `npx jest --config jest-e2e.json --runInBand --silent` | callisto full suite | pass: 448 suites / 2455 tests (baseline 444 / 2361) | — |
| audit | `npm audit --audit-level=high` | atlas `INT-138` | **fail**: 11 high | pre-existing; no dependency change vs `origin/main` |
| lint / type-check | `npm run lint`; `npm run type-check` | atlas `INT-138` | pass | — |
| tests | `npx vitest run --maxWorkers 1` | atlas full suite | pass: 160 files / 1438 tests | — |
| manual end-to-end | test plan M-1 to M-6 | local stack | **blocked** | needs AWS credentials (Planet Portal SSO) for SQS |

- **Tests added/updated:** listed per part in the spec and the test plan's test map.
  - Red→green: the recategorize service spec, 6 of 11 failing before.
  - Mutation check on the Atlas path cell.
- **Regression impact:**
  - The shared `fetchFilesByProceedingId` select gained `file.filePath`/`file.bucket`. The GET listing's exact output keys are asserted unchanged.
  - Existing audit events and Dione outbox payloads are unchanged; their specs are green without edits.
- **API docs:** no route, DTO, status or auth change. Checked `create-summary.swagger.ts`, the recategorize/approve/unapprove/upload DTOs and actions: all unchanged.
- **Conflicts / exceptions:**
  - Spec review replaced by implementation review, by user direction.
  - Specs left uncommitted, by user direction.
  - The worktree commits ran without the husky pre-commit hook, because `.husky/_` isn't generated in worktrees. Its checks were run by hand and by the gates above.

### 2026-09-25T22:55:00Z — callisto-back-end + atlas-front-end (Phase 5 Implement, local branches)

- **Summary:** implementation of the INT-138 spec. By user direction, the spec review is replaced by an implementation review, and the specs stay uncommitted.
  - **Order:** subagents implement each spec part on its own local branch in a worktree. The lead reviews each branch and merges it into the integration branch `INT-138` in each repo.
  - **Pieces:**
    - `INT-138-audit-core` (Part A) and `INT-138-atlas` (Part D) first;
    - then `INT-138-gca-dispatch` (Part B) and `INT-138-planet-summary` (Part C), branched from integration once A is merged.
  - europa-back-end: no change.
- **Plan used:** the spec's Parts A to D. Phase 4 was skipped by user direction.
- **Files:** the ones listed in each spec part's §1 and §2.
- **Commits:** local only, one or more per piece branch, plus the merge commits into `INT-138`. Subjects are prefixed `INT-138:`. No push.
- **Notes:** the final gate results are recorded in the test plan's results log and in the closing session entry.

### 2026-09-25T22:40:25Z — callisto-back-end (local branch) + dustin-thomason (Phase 3 Probe & spec)

- **Summary:** Phase 3 decisions were locked and the spec was written, reviewed and merged on a local branch. **Not sent**: no push, no PR.
  - **LD-001 to LD-015**, all resolved from the ticket, evidence, or the user's correction. That correction came on 2026-09-23: an audit log records every change, so D1 was never a real question.
  - **Story 01 accepted** with 9 criteria and 0 open questions.
  - **Spec** written by four parallel subagents, then reviewed and merged into one file:
    - Part A: audit core;
    - Part B: GCA dispatch on upload, approve v1/v2, recategorize and unapprove;
    - Part C: Planet Summary requester capture, with one `jsonb` migration;
    - Part D: Atlas, with Europa confirmed unchanged.
  - **Merge review fixes:**
    - widened Part B's gate for collection-only categorization (LD-015);
    - no-op recategorize still emits (LD-013);
    - Planet Summary IP and user agent = `'system'`, and the requester's IP and user agent are not stored (LD-014);
    - Part C's criterion refs moved to C9;
    - every agent open item turned into a resolved position.
- **Plan used:** none (Phase 4 comes next).
- **Files:**
  - **callisto-back-end `INT-138-spec` (uncommitted):**
    - `docs/specs/atlas-client-access/deliverable-management/8-story-INT-138-categorize-audit-events/8-story-INT-138-categorize-audit-events.md` (new);
    - `docs/specs/README.md` (index +1).
  - **dustin-thomason:**
    - `INT-138/specs/INT-138-locked-decisions.md`, `INT-138/specs/INT-138-spec.md` (copy);
    - `INT-138/stories/*` (accepted), `INT-138/testing/INT-138-test-plan.md` (refined);
    - `INT-138/INT-138-future-development-concerns.md` (C7 to C11), `INT-138/investigations/INT-138-investigation.md` (§13 addendum), `INT-138/investigations/INT-138-coverage-ledger.md` (areas 9–10);
    - `INT-138/orchestration.md`; this changelog (Jira link).
- **Commits:** none.
- **Notes:**
  - WorkLists card retitled with the Jira link. Phase 2 rows are marked and the status is In Progress.
  - One subagent (Part D) ran read-only `git log` / `git branch` against the no-git instruction. Nothing changed.

### 2026-09-23T18:55:00Z — dustin-thomason (Phase 1 Recon + Phase 2 Report)

- **Summary:** Phase 1 recon was approved without edits. Phase 2 emitted the investigation package.
  - **The ticket is reclassified.** It is not a new Europa log. It is a gap in the audit events sent from existing write paths:
    - Callisto's recategorize path sends no audit at all.
    - Approve and upload send `APPROVED`/`CREATED` without the deliverable type or collection.
    - Europa's backend needs no change, because it stores and filters any type string (exact, case-sensitive match).
    - The Event Type dropdown is a hand-maintained list in `atlas-front-end`.
    - Each file needs its own event, because Europa shows only the first resource.
  - **Disposition: proceed with conditions.** D1 (which paths emit) and D2 (the literal and label) gate the spec. D3–D8 are open with owners.
  - **Story 01:** 3 questions closed by evidence, 3 split into fact and decision, OQ-10 added, and criterion 7 added (each file gets its own record).
- **Plan used:** `INT-138/investigations/INT-138-recon-and-plan.md` (approved, frozen).
- **Files:** `INT-138/investigations/` (`INT-138-recon-and-plan.md`, `-investigation.md`, `-coverage-ledger.md`, `-diagrams.md`); `INT-138/testing/INT-138-test-plan.md` (seeded); `INT-138/INT-138-why-these-changes.md`; `INT-138/INT-138-future-development-concerns.md` (C1–C6); `INT-138/INT-138-pr-draft.md` (shell); `INT-138/stories/` (reconciled); `INT-138/orchestration.md`.
- **Commits:** none. No implementation-repo file was touched. All three repos are still clean on `main`.
- **Notes:**
  - The WorkLists board is still blocked by the ticket-id guard. The card title is `# Ticket Template`, not INT-138, and nothing was written.
  - The Mermaid diagrams are hand-checked, not machine-rendered, because no renderer is installed here.

### 2026-09-23T18:05:00Z — dustin-thomason (Phase 0 Capture)

- **Summary:** Captured INT-138 under orchestration. I rewrote the user-supplied `INT-138-original-ticket.md` into the original-ticket artifact shape, with the request embedded byte-for-byte (checked with `cmp`). I drafted job story 01 (Categorization audit: 6 criteria, 9 open questions), scaffolded this changelog and the orchestration ledger, and recorded the WorkLists card id. I also put atlas-front-end, europa-back-end and callisto-back-end on `main` as instructed at kickoff.
- **Plan used:** none. Phase 0 is capture only.
- **Files:** `docs/atlas/INT-138/INT-138-original-ticket.md`, `docs/atlas/INT-138/orchestration.md`, `docs/atlas/INT-138/stories/INT-138-job-stories-index.md`, `docs/atlas/INT-138/stories/INT-138-job-story-01-categorization-audit.md`, this changelog.
- **Commits:** none.
- **Notes:** The WorkLists board write was **not made**. The ticket-id guard fired because the card title reads `Ticket Template`, not `INT-138`. `scripts/new-ticket-changelog.ps1` rejects `INT-` ids (`ValidatePattern '^PRDV-\d+$'`), so I copied this file from the template by hand.

---

## Attempt history

_None yet._

---

## Key technical learnings

1. Europa's audit backend accepts any event `type` string. There is no enum, the filter is an exact, case-sensitive match, and `newState.path` is passed through for every type except `PERMISSIONS_UPDATED`. A new audit event type needs no Europa change, but the Callisto and Atlas literals must match byte for byte.
2. Europa shows only `auditEventResources[0]` of a multi-resource event, so a batch action must send one event per file to be visible per file.
3. Callisto's recategorize path (`recategorize-deliverable-files.service.ts`) sends no audit to Europa. It writes only the Dione outbox.
4. The Europa page's Event Type options are `atlas-front-end` `src/europa/utils/constants.ts` `eventTypes`. They are raw strings with no label map. The only multi-line Path render is for `PERMISSIONS_UPDATED`.

---

## Current state (as of 2026-09-23)

**Updated 2026-09-25:** implemented and merged locally.
- callisto `INT-138` @ `9d4ce4e9` and atlas `INT-138` @ `e5a29a4a`, in worktrees under `C:\Users\dustin.thomason\wt\`.
- All automated gates are green, except atlas's pre-existing audit failure.
- **Remaining:**
  - the manual end-to-end check (needs AWS credentials);
  - pushing the branches and opening two PRs (callisto, atlas), which waits for the user;
  - Phase 6 wrap-up.
- The spec stays uncommitted on callisto `INT-138-spec`.

*Earlier state, kept for history:* Phases 0–2 are done, and Phase 3 (probe and spec) is next, in Working mode. Nothing has been built, branched or committed in any app repo, and all three repos are on `main` and clean. The investigation verdict is **proceed with conditions**: Product must settle D1 (which write paths emit Categorize) and D2 (the event literal and its label) before the spec is locked. The recommended shape is a Callisto emit per file after commit, plus the Atlas literal and path render, with Europa unchanged.
