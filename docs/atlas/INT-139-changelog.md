# INT-139 — Audit log entries for deliverable type recategorization

## Ticket

- **Ticket:** [INT-139](https://pd-product-dev.atlassian.net/browse/INT-139)
- **Repo:** `callisto-back-end`, `europa-back-end`, `atlas-front-end`
- **Branch:** `INT-139` pushed in all three repos; cut from `INT-138` (LD-013)
- **PR:** [Callisto #468](https://github.com/planetdepos/callisto-back-end/pull/468), [Europa #72](https://github.com/planetdepos/europa-back-end/pull/72), [Atlas #584](https://github.com/planetdepos/atlas-front-end/pull/584)
- **Artifacts:** [INT-139/](INT-139/) — ticket body [INT-139.md](INT-139/INT-139.md), [locked decisions](INT-139/specs/INT-139-locked-decisions.md), [spec](INT-139/specs/INT-139-spec.md)

---

## Requirements (verbatim)

> # Audit log - re-categorize deliverable type
>
> As an Ops manager, I want to be able to review an audit log of key actions related to Client Access, so that I can see the "who, what, when" for these critical functions.
>
> Acceptance Criteria
>
> Ops can view a log in Europa for deliverable type recategorization
>
> The log displays the following details:
>
> file path
>
> user info
>
> date/time
>
> recategorization actions taken
>
> A new Event Type is created for this action: Recategorize
>
> This event type is added to the Event Type drop down in Europa
>
> Resource Type for this action is: File
>
> Path format:
>
> Filepath: [file path]
>
> Deliverable Type: [old deliverable type] → [new deliverable type]
>
> Collection: (old collection if applicable, [collection], if not, "N/A") → (new collection if applicable, [collection], if not, "N/A")

---

## Context

- Builds on INT-138 (`CATEGORIZE` audit records); INT-139 changes code on the `INT-138` branch. See [INT-138-changelog.md](INT-138-changelog.md).
- **User direction (2026-09-29):** ignore docs in the other repos; code is the source of truth.
- **User direction (2026-09-29):** the question of which service builds the path text is settled from current code, rules, tickets and precedent only, without commit history or timing.

---

## Plans

| Added | Plan (path or link) | Status | One-line approach |
| ----- | ------------------- | ------ | ----------------- |
| 2026-09-29 | [INT-139/specs/INT-139-spec.md](INT-139/specs/INT-139-spec.md) + [locked decisions](INT-139/specs/INT-139-locked-decisions.md) | `implemented` (pushed; three PRs open) | Recategorize sends `RECATEGORIZE` with old names in `oldState` and new in `newState`; europa-back-end builds `old → new` path; atlas-front-end lists the type |

---

## Session log

_Newest first._

### 2026-10-01T14:05:00Z — pushed and PRs opened

- **Commits pushed:** Callisto `a90c4c401da2b2ed667c02bfdc04fb3f4f9116ad`; Europa `f76bb4afcea4f09a41f3ab9caa84ddc52d2a0d14`; Atlas `2b7e1867077f6e086403f59d52296914e1be1311`. Each local tip equals `origin/INT-139`, and each worktree is clean.
- **PRs:** [Callisto #468](https://github.com/planetdepos/callisto-back-end/pull/468) targets `INT-138`; [Europa #72](https://github.com/planetdepos/europa-back-end/pull/72) targets `main` because Europa has no remote INT-138 branch/PR; [Atlas #584](https://github.com/planetdepos/atlas-front-end/pull/584) targets `INT-138`. All are open, non-draft, cross-linked, and have no reviewer requests.
- **PR format:** matches the INT-138 house structure (`Clickup`, `Description`, `Test Evidence`, `Checklist`). Evidence names point to the internal INT-139 package. The screenshots were not published to this public docs repository or added to application branches because they contain internal data; the available Chrome session is not GitHub-authenticated for direct PR attachment upload.
- **CI:** Callisto and Atlas are mergeable/clean and report no GitHub checks on these stacked branches; Atlas's pre-push hook reran the unit suite successfully. Europa is mergeable but branch-protected pending review and has one failed dependency-security job: CI reports 5 high and 2 moderate advisories, while lint, type-checking, tests, build-output analysis, package analysis and feedback pass. The Europa PR changes no package or lock file.
- **Status:** implementation is ready for review. The only release note remains the observed legacy CATEGORIZE doubled-label risk documented below and in Europa PR #72.

### 2026-10-01T13:48:00Z — final review and PR preparation

- **Summary:** final review confirmed the end-to-end evidence and all three application diffs. The previous Europa cast follow-up had moved six call-site assertions into one helper but had not removed the assertion; the helper now uses the repository's typed `createMock<AuditEvent>()` factory and assigns the audit fixture fields into it, leaving the INT-139-added test path with no `as` cast.
- **Branch plan:** Callisto and Atlas PRs are stacked on their existing remote `INT-138` branches so reviewers see only INT-139. Europa has no remote `INT-138` branch or PR, so its INT-139 PR targets `main` and includes the three-file CATEGORIZE/RECATEGORIZE formatter stack required by the approved prerequisite.
- **Verification correction:** directly constructing `new AuditEvent()` passed TypeScript but failed the six RECATEGORIZE cases because the entity extends Mongoose `Document` without a bound schema. Replaced it with the repository's existing typed mock factory, then reran the final gates.
- **Final gates:** `npm audit --audit-level=high` fails on dependency-only advisories (34 high, 1 moderate; no INT-139 package-file change and npm reports no fix available); `npm run lint` passes without changing the diff; `npm run type-check` passes; `npx jest --config jest-e2e.json --runInBand --silent` passes 32/32 suites and 126/126 tests.
- **Status:** superseded by the pushed/PR-open entry above.

### 2026-10-01T13:45:00Z — local stack (Playwright end-to-end test: pass)

- **Summary:** with the user's go-ahead, Callisto's `.env` `SQS_AUDIT_EVENT_URL_OUTBOUND` was set to the `.env.local` value (the queue Europa reads); the user restarted Callisto. A probe upload's CREATED and CATEGORIZE reached Europa within a second, CATEGORIZE on one set of labels. Then B was recategorized into Redacted, and A and B together into Full Transcript (one collection unchanged, one changed): Europa shows one RECATEGORIZE per file with `old → new` type and collection, user, date and resource type FILE, and no CATEGORIZE from either recategorize.
- **Evidence:** `INT-139/testing/INT-139-test-evidence.md` → "Final run"; screenshots 04, 08 and 09 (the rest retired to `screenshots/dnu/` on 2026-10-02).
- **Observed risk:** the 2026-09-29 INT-138 CATEGORIZE records (labelled-path format) render with doubled labels under INT-139's Europa.
- **Commits:** none. The `.env` change is local config (gitignored).

### 2026-09-30T23:05:00Z — local stack (Playwright end-to-end test: partial, blocked)

- **Summary:** the running services were `INT-138` code. The three main checkouts were switched to `git switch --detach INT-139`. Europa (`--watch`) and Atlas (`quasar dev`) reloaded, and Callisto was restarted with the environment of the process it replaced. Two test files were uploaded to proceeding 3002 and recategorized through the UI (200, both files moved).
- **Blocked:** every audit send failed at SQS (`InvalidAddress`). Callisto runs without `NODE_ENV`, so it uses `.env`'s `…/audit-event` queue, not the `…/sqs-triton-sb-ue1-derrick-auditevent.fifo` queue Europa reads (Callisto `.env.local`). Restarting Callisto with `NODE_ENV=local` needs the AWS session from the user's shell, and the agent's restart attempts were denied by the permission classifier.
- **Evidence:** `INT-139/testing/INT-139-test-evidence.md` and 8 screenshots. The Event Type dropdown criterion is evidenced; the Europa row criteria are not yet.
- **Commits:** none.

### 2026-09-30T16:27:51Z — europa-back-end + dustin-thomason (implementation review follow-ups)

- **Summary:** an implementation review approved the runtime behavior (LD-001–LD-015 confirmed) and raised four follow-ups, all applied:
  1. The six INT-139 RECATEGORIZE tests in europa's paginated search spec cast fixtures with `as AuditEvent` at the call site, against the self-review checklist ("No hand-rolled type casts in test mocks", `docs/reviewers/pr-review-patterns.md:11`). A subagent replaced them with one spec-local typed factory (branch `INT-139-europa-casts`).
  2. The commit-prefix exception is now recorded (previous entry, Conflicts / exceptions).
  3. The spec's changed-file tree now lists `recategorize-deliverable-files.projection.ts` (comment only).
  4. The Branch line and the Plans status above are current.
- **Not changed:** the 11 other `as AuditEvent` casts in the same spec file (3 predate INT-138, 8 came with INT-138). They belong to the INT-138 PR.
- **Helper:** `createMockTypedAuditEvent(override: Partial<AuditEvent> = {}): AuditEvent` holds the one remaining conversion, because `AuditEvent` extends mongoose `Document` and a plain object can't satisfy it without one.
- **Commits** (local, not pushed): europa `INT-139`: `1f5cc28` Type RECATEGORIZE test audit fixtures → merge `b03f5e6`.

| Gate | Command | Scope | Result | Exception / risk |
| ---- | ------- | ----- | ------ | ---------------- |
| audit | `npm audit --audit-level=high` | europa | fail (3 high, predates INT-139) | waived by the user for local INT-139 commits |
| lint | `npm run lint` | europa `INT-139` | pass, no files changed | — |
| type-check | `npm run type-check` | europa `INT-139` | pass | — |
| tests | `npx jest --config jest-e2e.json --runInBand --silent` | europa full suite | pass: 32 suites / 126 tests | — |

### 2026-09-29T20:40:00Z — callisto-back-end + europa-back-end + atlas-front-end (implementation, local branches)

- **Summary:** implementing the approved spec with one subagent per piece, each in its own worktree and branch off the `INT-139` integration branch. The lead reviews each piece, commits it on its branch and merges it into `INT-139`. Nothing is pushed.
- **Integration worktrees:** `C:\Users\dustin.thomason\wt\callisto-INT-139`, `europa-INT-139`, `atlas-INT-139`, each branch `INT-139` cut from `INT-138` (callisto `e285f39e`, europa `d9fb272`, atlas `36999e87`).
- **Pieces:** A callisto Prerequisite (`INT-139-prereq`); C europa RECATEGORIZE branch (`INT-139-europa`); D atlas event type (`INT-139-atlas`); B callisto RECATEGORIZE (`INT-139-recategorize`, after A merges).
- **Audit gate:** `npm audit --audit-level=high` fails on all three repos before any INT-139 change (callisto 1 high, europa 3 high, atlas 11 high). The user waived it for the local INT-139 commits and merges (2026-09-29).
- **Commits** (local only, not pushed; no Co-Authored-By trailer):
  - callisto `INT-139`: `b67f7d8c` Send structured categorization audit state (Prerequisite, own commit) → merge `74e386bd`; `2a375ce3` Send RECATEGORIZE audit on recategorize → merge `a90c4c40`.
  - europa `INT-139`: `fd3a0ca` Format RECATEGORIZE audit path → merge `828cab2`.
  - atlas `INT-139`: `9d660926` Add RECATEGORIZE to Europa audit page → merge `2b7e1867`.
- **Conflicts / exceptions:** commit subjects use the `INT-139:` prefix, not the literal `PRDV-X:` that `.cursor/rules/git-commit-messages.mdc:11-17` requires in all three repos. The ticket is INT-139 and has no PRDV number, so the rule's ticket-ID prefix is followed with the ticket's own ID, as INT-138 did. No commits were rewritten.
- **Review changes:** europa piece sent back once to add the `newState`-missing fallback test. Atlas piece renamed the exact-contents `MULTI_PART_PATH_TYPES` test (it pinned the old two-entry set).
- **Environment:** the shared `atlas-front-end\node_modules` in the main checkout was found damaged (`.bin`, `@babel/*`, `.package-lock.json` and 65 top-level packages missing; last written 5:07:25 PM, before either INT-139 atlas junction existed). Left untouched. `wt\atlas-INT-139` got its own `npm ci` install, and the atlas piece worktree was pointed at it.

| Gate | Command | Scope | Result | Exception / risk |
| ---- | ------- | ----- | ------ | ---------------- |
| audit | `npm audit --audit-level=high` | all three repos | fail (callisto 1 high, europa 3 high, atlas 11 high; present on `INT-138` before any INT-139 change) | waived by the user for local INT-139 commits and merges |
| lint | `npm run lint` | callisto `INT-139` | pass, no files changed | — |
| type-check | `npm run type-check` | callisto `INT-139` | pass | — |
| architecture | `npx jest src/__tests__/architecture.spec.ts` | callisto | pass 1/1 | run from the default shell; under Git Bash depcruise loses the path backslashes |
| conventions | `COMSPEC=<Git bash.exe> npm run test:{naming,dto-structure,type-structure,migration-naming,no-util-files,exchange-ownership}` | callisto | all 6 pass, 0 path errors | under cmd.exe these checks print path errors and may check nothing |
| tests | `npx jest --config jest-e2e.json --runInBand --silent` | callisto full suite | pass: 448 suites / 2466 tests | — |
| lint | `npm run lint` | europa `INT-139` | pass, no files changed | — |
| type-check | `npm run type-check` | europa `INT-139` | pass | — |
| tests | `npx jest --config jest-e2e.json --runInBand --silent` | europa full suite | pass: 32 suites / 126 tests | — |
| lint | `npm run lint` | atlas `INT-139` | pass | — |
| type-check | `npm run type-check` | atlas `INT-139` | pass | — |
| tests | `npx vitest run --maxWorkers 1` | atlas full suite | pass: 160 files / 1440 tests (4 skipped) | — |
| manual | spec "Manual end-to-end" | local stack | not run | needs Callisto, Europa, SQS and AWS credentials running; the stored-field check (ledger E6) is still open |

### 2026-09-29T20:04:35Z — dustin-thomason (investigation, locked decisions, spec)

- **Summary:** investigated INT-139 against the INT-138 branches. Settled where the path text is built (Callisto sends structured state; europa-back-end builds the text) from code evidence E1–E10. Wrote the locked-decision ledger (LD-001 to LD-015) and the spec. The ledger is out for review.
- **Plan used:** none before this session; the spec row above is new.
- **Files:** `docs/atlas/INT-139/specs/INT-139-locked-decisions.md`, `docs/atlas/INT-139/specs/INT-139-spec.md`, this changelog.
- **Commits:** none. No app-repo code changed.
- **Notes:** the INT-138 branches disagree on the `CATEGORIZE` path (ledger E1). The spec's Prerequisite section carries the Callisto change that resolves it (LD-002).
- **Review reconciled:** a code-only review confirmed LD-001 to LD-015 with no decision reopened. Applied to the ledger and spec: E9 withdrawn (it can't show that no records exist in deployed storage); E10's search-field list corrected; LD-015 narrowed to deliverable-type and collection names; the LD-002 prerequisite made an explicit part of the INT-139 change list; a new open item to check deployed Europa for labelled-string `CATEGORIZE` records.
- **Spec review applied:** the scope table now says the other `CATEGORIZE` paths keep their triggers and event type but get structured state through the Prerequisite. The Prerequisite is marked as a scope extension authorized by LD-001/LD-002 and lands as its own commit. `createdAt` was added to the record contract, the manual test now checks User Email, User Name and Date, and an acceptance-criteria trace was added.

---

## Current state (as of 2026-10-01)

- Spec and locked decisions approved after two review passes.
- `INT-139` implemented and merged locally in callisto, europa and atlas (integration worktrees under `C:\Users\dustin.thomason\wt\`); all automated gates green. Not pushed, no PRs.
- Branched from `INT-138` at callisto `e285f39e`, europa `d9fb272`, atlas `36999e87`. `INT-138` is still receiving commits from other sessions, so `INT-139` will need later `INT-138` commits merged in.
- **Manual end-to-end: pass (2026-10-01 13:37–13:42Z).** Acceptance criteria evidenced in `INT-139/testing/INT-139-test-evidence.md` with three screenshots (04, 08, 09); the `N/A` rule by the europa-back-end search spec only, since every collection in the run was set. The deployment blocker recorded earlier on 2026-10-01 is lifted.
- **What blocked the earlier runs:** Callisto's audit queue comes from `.env` regardless of `NODE_ENV`. `AuditConfigModule` calls `ConfigModule.forRoot` with no `envFilePath` (`src/audits/config/audit-config.module.ts:8-10`), so `@nestjs/config` reads `.env` first (`config.module.js:76`) and later loads never overwrite it (`config.module.js:198-203`). `.env` pointed at `…/audit-event` in another AWS account. It now holds the `.env.local` value, the queue Europa reads. Whether the 2026-09-29 INT-138 run delivered because of that day's `.env` edit is consistent with the record but not proven.
- **Local state left behind:** main checkouts of all three repos detached at `INT-139` (undo: `git switch INT-138`); Callisto `.env` audit-queue line changed (gitignored; previous line in the session scratchpad); test files `INT139-transcript-A/B/C/D.pdf` on proceeding 3002.
- **Residual rollout risk, seen locally:** CATEGORIZE records stored by INT-138's earlier labelled-path format render with doubled labels under INT-139's Europa. Check deployed Europa environments for such records before release (spec Rollout).
- Remaining: push and PRs on the user's go-ahead.
