# PRDV-16597 — 3-Europa remediate high/critical security vulnerabilities

## Ticket

- **ClickUp:** [PRDV-16597](https://app.clickup.com/t/43227262/PRDV-16597) — Sprint points 2, status READY FOR WORK (ClickUp internal id `86ak0cauf`)
- **Parent epic:** PRDV-16423 — sequenced **3rd of 3** (`1-Callisto`, `2-Nova`, `3-Europa`)
- **Repo:** `europa-back-end`
- **Branch:** `PRDV-16597`
- **PR:** [#70](https://github.com/planetdepos/europa-back-end/pull/70) (merged) — first fix; [#71](https://github.com/planetdepos/europa-back-end/pull/71) — browserslist follow-up, no reviewers assigned
- **WorkLists card:** `todo-1788192471082-1b249a03`

---

## Requirements (verbatim)

Captured verbatim in `docs/atlas/PRDV-16597/PRDV-16597-original-ticket.md` (ClickUp browser capture, 2026-08-31). Reproduced unchanged:

> #### See Epic for Value Proposition
>
> #### **Acceptance Criteria**
>
> - No high- or critical-severity security vulnerabilities remain for Europa
> - All three systems can be deployed to AWS through the standard deployment process without security-related exceptions.

AC line 2 is epic-scoped, not Europa-scoped (mirrors PRDV-16595's framing) — Europa alone cannot satisfy it; it closes when all three child stories close.

---

## Context

- **Precedent:** PRDV-16595 (`docs/atlas/PRDV-16595-changelog.md`, Callisto — 1st of 3) already directly measured Europa as part of its epic-level cross-repo comparison. On 2026-08-25, against `europa-back-end` @ `main` `34da474`: porting Callisto's scoped `overrides` block got 7 high → 5 high (two entries missed because Europa's dependency tree shape differs — it reaches `brace-expansion` via eslint/jest parents and `js-yaml` via `@istanbuljs/load-nyc-config`, not via Callisto's `minimatch@10` / `@nestjs/swagger` parents); a plain `npm audit fix`, lockfile-only, got 7 high → **0**, `package.json` untouched. Conclusion recorded there: **do not port the override block to Europa** — the transferable asset is the technique, not the JSON. Europa was also confirmed to have no `@planetdepos/pathfinder-observability-pkg` dependency, so none of Callisto's Pathfinder-publish chain (D4/D6 in PRDV-16595) applies here.
- **User direction (2026-08-31):** Pathfinder is understood to be on track for the next release (not yet live in prod, per other devs) — treated as resolved/non-blocking for Europa, which doesn't depend on it anyway. Directed to take the simplest route: update the flagged versions, confirm nothing load-bearing breaks, and proceed if clean.
- **The gate:** same as PRDV-16595 — `npm audit --audit-level=high` in the DevOps-managed reusable workflow, run after `npm install` on the full tree; dev dependencies count.

---

## Plans

| Added | Plan (path or link) | Status | One-line approach |
| ----- | ------------------- | ------ | ----------------- |
| 2026-08-31 | This changelog | `implemented` | Re-verify the 2026-08-25 `npm audit fix` measurement fresh, apply it on branch `PRDV-16597`, verify full gate (audit/lint/test), ship — no override, no manifest changes. |

---

## Current state

**`npm audit --audit-level=high` on `europa-back-end` branch `PRDV-16597` now reports 0 vulnerabilities at every severity** (not just high/critical — the fix also cleared 5 moderate + 2 low that were present at baseline).

Fresh baseline taken 2026-08-31 on `main` @ `34da474` (unchanged since the 2026-08-25 measurement — repo was clean and up to date with `origin/main`): **14 vulnerabilities — 7 high, 5 moderate, 2 low, 0 critical.** All 14 carried `fix available via npm audit fix` (none required `--force`, none `fixAvailable: false`), so this is a compatible-range resolution, not a forced/breaking one.

`npm audit fix` (no `--force`) took it to **0 vulnerabilities**. `package.json` is byte-for-byte unchanged — `git diff package.json` is empty. Only `package-lock.json` changed (381 insertions, 235 deletions), confirming this is a lockfile-only re-resolution within the ranges `package.json` already permits, not a manifest edit.

**Resolved-version deltas for the flagged packages** (all transitive except `joi`, which is a direct dependency already covered by its existing `^17.13.3` range):

| Package | Before | After | Notes |
| --- | --- | --- | --- |
| `axios` | 1.15.2 | 1.20.0 | transitive; direct dep range is `^1.8.3` |
| `multer` | 2.1.1 | 2.2.0 | transitive via `@nestjs/platform-express` |
| `form-data` | 4.0.5 | 4.0.6 | transitive via `axios` |
| `js-yaml` | 4.1.1 | 4.3.2 (top-level); nested copy under `@nestjs/swagger` now resolves `5.3.0` | transitive; `@nestjs/swagger` itself only moved `11.4.1 → 11.4.7` (patch, within `^11.2.3`) |
| `mongoose` | 9.6.1 | 9.9.4 | transitive via `@nestjs/mongoose` |
| `typeorm` | 0.3.28 | 0.3.31 | transitive via `@nestjs/typeorm` |
| `qs` | 6.15.1 | 6.16.0 | transitive |
| `joi` | 17.13.3 | 17.13.6 | direct dependency, within declared `^17.13.3` |

No package crossed a major version. Every change is a patch or minor bump inside a range already permitted by an existing declared dependency — the same signal PRDV-16595 used to call its Pathfinder bump low-risk.

**Verified no functional discrepancy:** full test suite green post-fix (see gate table below), including `configure-swagger.spec.ts` (relevant since `@nestjs/swagger`'s nested `js-yaml` moved to the 5.x line, same major-version crossing Callisto made deliberately for the same advisory).

**No override needed, none added.** Matches the 2026-08-25 finding exactly — this is the "simplest and cheapest" path the user asked to confirm and take.

---

## Attempt history

_None — the `npm audit fix` approach was measured once (2026-08-25, PRDV-16595 session) and re-verified once (2026-08-31, this ticket) with the same outcome both times. No alternative approach was attempted._

---

## Session log

### 2026-08-31T16:30:00Z — europa-back-end — npm audit fix applied, full gate green

**Summary.** Re-verified PRDV-16595's cross-repo measurement of Europa fresh (6 days later, same commit), then applied the already-proven `npm audit fix` remedy for real on branch `PRDV-16597` (no override, no manifest edit). Full gate green.

**What was done:**
1. Confirmed `europa-back-end` was already on `main`, clean, up to date with `origin/main` @ `34da474` — no update-to-main step was needed.
2. Branched `PRDV-16597` off `main`.
3. Ran `npm audit fix` (no `--force`) — 14 findings (7 high, 5 moderate, 2 low) → 0. `package.json` unchanged; only `package-lock.json` touched.
4. `npm install` to sync `node_modules` to the new lockfile — confirmed 0 vulnerabilities again post-sync.
5. `npm run lint` — clean, zero file changes beyond the lockfile (confirmed via `git status --porcelain`).
6. `npx jest --config jest-e2e.json --runInBand` — 32 suites / 112 tests, all passing.
7. Final `npm audit --audit-level=high` — 0 vulnerabilities.

#### Shipping checklist

- **Tests run** — all gates green against the post-fix tree: audit, lint, full test suite. See table below.
- **Tests added/updated** — not relevant: no application logic changed, no new behavior introduced. The dependency change is a lockfile-only re-resolution within existing `package.json` ranges; the existing 112 tests are the regression surface and all pass, including the Swagger config spec relevant to the one nested major-version crossing (`js-yaml` under `@nestjs/swagger`, 4.x → 5.x).
- **Regression impact** — isolated, boundary named: `git diff --stat` confirms only `package-lock.json` changed (381 insertions, 235 deletions); `package.json` is byte-identical to `main`. Every resolved-version delta is a patch/minor bump inside a range the manifest already declared — no direct dependency crossed a major version, and the one nested major crossing (`js-yaml` 4.x→5.x under `@nestjs/swagger`) is the same jump Callisto's team made deliberately for the same advisory (PRDV-16595).
- **API docs** — not relevant: no HTTP surface, route, DTO, or Swagger decorator was touched. `@nestjs/swagger` itself moved only `11.4.1 → 11.4.7` (patch); its config spec passed.
- **Tooling gates** — audit, lint, and tests all run and green (table below).
- **Conflicts / exceptions** — none.

| Gate | Command | Scope | Result | Exception / risk |
| ---- | ------- | ----- | ------ | ---------------- |
| audit | `npm audit --audit-level=high` | europa-back-end | pass — 0 vulnerabilities at any severity | — |
| lint | `npm run lint` | europa-back-end | pass (exit 0) | script includes `--fix`; `git status` confirmed it rewrote nothing beyond the lockfile |
| tests | `npx jest --config jest-e2e.json --runInBand` | europa-back-end | pass — 32 suites, 112 tests | — |

**Committed and pushed.** Commit `e34e64c84e6006a970f79acbc7ea38d4c51bb49b` on branch `PRDV-16597`, pushed to `origin`. The repo's own `pre-push` hook independently re-ran the full test suite (32/32 suites, 112/112 tests) before allowing the push — a second, hook-driven confirmation beyond the manual run above.

**PR opened per user go-ahead (2026-08-31).** [#70](https://github.com/planetdepos/europa-back-end/pull/70), base `main`, no reviewers assigned per explicit instruction. Kept deliberately minimal per the user's request — repo's actual `.github/pull_request_template.md` filled in plainly (Clickup link, one-paragraph description, the three verification commands and their results, checklist), no commit-hash section, no elaboration beyond what the template asks for.

### 2026-09-02T13:45:00Z — europa-back-end — new advisory landed, re-fixed

**Summary.** Two days after PR #70 shipped clean, a recurring CI scan (`Building 6958771f7f503015e84eb5b3a1828edd850d3b74`, run `33636909883`, triggered 2026-09-02T13:37:59Z) re-audited the **same, unchanged commit** `e34e64c` and failed: a brand-new high-severity advisory pair for `browserslist` (GHSA-c83g-rgw3-j3cx, GHSA-73wf-gq98-2v4g, range `<=4.28.6`) had been published in the interim. This is the exact "advisory DB moves" risk flagged generically in PRDV-16595's remaining-work runbook, now observed directly on this ticket — nothing in our diff caused it; the vulnerable version was already in the tree, unflagged, when we shipped.

**Confirmed, not assumed.** Ran `npm audit --audit-level=high` locally on the current branch before touching anything — output matched the user-pasted CI failure verbatim (same advisory ids, same `1 high severity vulnerability`). `browserslist@4.28.1` is a transitive dev/build dependency only — via `@nestjs/cli` → `webpack` and via `jest` → `@babel/core`, never a runtime dependency, never shipped in the running service.

**Fix applied the same way.** `npm audit fix` → 0 vulnerabilities, `package.json` unchanged (only `package-lock.json`), `browserslist` resolved `4.28.1 → 4.28.8` — a patch bump inside the same minor line, no major crossing. Lint clean, full suite 32/32 suites and 112/112 tests passing. Committed `73e94fc810fa5da55dab02c53a9f16f44a5a3806`, pushed to `PRDV-16597` — the repo's own pre-push hook independently re-ran the full suite again (112/112) before allowing the push.

**Correction — this was a post-merge build failure, not a stale re-scan.** User confirmed: PR #70 was already merged to `main` (merge commit `6958771`, `mergedAt` 2026-09-02T13:37:55Z); the `Building ...` run (`33636909883`, created 13:37:59Z — 4 seconds later) is `main`'s post-merge build pipeline, and that is what caught the new advisory. The earlier framing in this entry ("recurring scan against the branch tip") was wrong — corrected here rather than edited away, per the addendum convention.

**PR #70 cannot be reopened** — confirmed via `gh pr reopen 70`: *"can't be reopened because it was already merged"* (GitHub's merged state is terminal). Opened a **new** PR, [#71](https://github.com/planetdepos/europa-back-end/pull/71), from the same `PRDV-16597` branch. Diff verified clean before opening: `git diff origin/main origin/PRDV-16597 --stat` shows exactly the one browserslist commit (`package-lock.json`, 39 insertions/27 deletions) — none of the already-merged work reappears, since the branch's history (minus its own merge commit, which it doesn't need) is equivalent to `main` plus this one new commit.

#### Shipping checklist

- **Tests run** — audit, lint, full test suite all green against the post-fix tree (table below).
- **Tests added/updated** — not relevant: same rationale as the first fix — no application logic changed, existing 112 tests are the regression surface and all pass.
- **Regression impact** — isolated, boundary named: `git diff --stat` shows only `package-lock.json` changed; `browserslist` is transitive build/test tooling (webpack, babel), never executed in the running service; version delta is a patch bump with no major crossing.
- **API docs** — not relevant: no HTTP surface touched.
- **Tooling gates** — audit, lint, tests all run and green; the repo's own pre-push hook independently reconfirmed tests before the push was allowed.
- **Conflicts / exceptions** — none. Two uncommitted, content-identical `.prettierrc`/`.swcrc` line-ending normalizations (LF→CRLF, a Windows/git `autocrlf` artifact from the husky pre-commit hook's `prettier --write .` pass) remain in the working tree; `git diff` confirms no actual content change, left as-is, unrelated to this fix.

| Gate | Command | Scope | Result | Exception / risk |
| ---- | ------- | ----- | ------ | ---------------- |
| audit | `npm audit --audit-level=high` | europa-back-end | pass — 0 vulnerabilities | — |
| lint | `npm run lint` | europa-back-end | pass (exit 0) | — |
| tests | `npx jest --config jest-e2e.json --runInBand` | europa-back-end | pass — 32 suites, 112 tests | — |

**WorkLists card updated** (`todo-1788192471082-1b249a03`). Card arrived as a bare template (`# Ticket Template\n\nEuropa`, no ticket id, no workflow headings) — same situation PRDV-16595's card hit. Wrote the title (now carries `PRDV-16597`) and the workflow scaffold first, on a fresh precondition, then set `currentStep` / `nextUp` on a second precondition once the headings existed. Marked 8 rows with evidence: Preliminary → ticket generated; Development → branch created, implementation begun; Testing & Validation → tested locally (with real start/finish times from the test run logs), artifact referenced (this changelog); Deploy & PR → `npm audit` run, branch already based on current main, pushed to GitHub. Left unmarked: `copy spec` / feature-flag check (not applicable, no spec on this ticket), all of Investigation and Project Spec (no formal Investigation Report or spec was produced — this changelog is analysis, not that artifact), `Plan implementation` (ambiguous fit, left conservative), `Alt Ai Review` (not performed), `Open PR` onward (not yet done).
