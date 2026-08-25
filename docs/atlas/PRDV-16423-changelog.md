# PRDV-16423 — Investigate and remediate high/critical security vulnerabilities

## Ticket

- **ClickUp:** [PRDV-16423](https://app.clickup.com/t/43227262/PRDV-16423) — Epic, Priority High, 7 points, tag `tech debt`, Owning Team NASA
- **Repos:** `nova-back-end`, `nova-orbital-back-end` (scope TBC), `callisto-back-end`, `europa-back-end`
- **Branch:** _(none yet — no code changes made)_
- **PR:** _(none yet)_
- **WorkLists card:** `todo-1785358880857-f4721f87` (id supplied by user; title verified to carry PRDV-16423)

---

## Requirements (verbatim)

Captured verbatim in `docs/atlas/PRDV-16423/PRDV-16423-original-ticket.md` (ClickUp browser capture, 2026-08-25). Reproduced here unchanged:

**Original Request**

> Recent deployment attempts for Nova, Callisto, and Europa identified high-severity security vulnerabilities that are preventing deployment to AWS through the standard process.
>
> Temporary overrides have been used to allow deployments to continue because the findings are high severity. This ticket tracks the remediation work separately from feature and functional changes so the security effort has clear visibility across all affected systems.

**Acceptance Criteria** — _AC's can be found in each individual Technical Story - no work is implemented in Epics - Epics are the container of work_

> - No high- or critical-severity security vulnerabilities remain for 2- Nova (2), 1-Callisto (3) , or 3-Europa (2)
> - All three systems can be deployed to AWS through the standard deployment process without security-related exceptions.

---

## Context

- **This is an Epic.** Per the AC text, no work is implemented at this level — the remediation lands in child Technical Stories. This changelog tracks the epic-level triage that sizes those children.
- **The deploy gate is `npm audit --audit-level=high`**, not ECR image scanning. It lives in the DevOps-managed reusable workflow `planetdepos/actions/.github/workflows/node-service-ci.yml@main` (version `2026-04-02.1`), and the ECR push job depends on it. Dev dependencies are in scope because the step runs a plain full-tree audit after `npm install`.
- **"Nova" is ambiguous.** Two repos in the workspace answer to it — `nova-back-end` (package name `nova-video-transcoder`) and `nova-orbital-back-end`. The trivial repo and the only hard repo are both "Nova", so the ticket's size depends entirely on which the subtasks mean.
- **Local blocker:** GitHub Packages npm auth is broken on this machine (`~/.npmrc` token → 401; `gh auth token` → 403, missing `read:packages`). Blocks all `@planetdepos`-scoped resolution, which blocks `nova-orbital-back-end` entirely.

---

## Plans

| Added | Plan (path or link) | Status | One-line approach |
| ----- | ------------------- | ------ | ----------------- |
| 2026-08-25 | `docs/atlas/PRDV-16423/PRDV-16423-baseline-audit.md` | `active` | Clean-slate audit of all four repos to separate "clears with plain `npm audit fix`" from "needs engineering", then size the child stories off that split. |

**Status:** **active** — current direction · **implemented** — shipped · **superseded** — replaced · **abandoned** — see Attempt history

---

## Current state

Triage complete; **no code changed and no branch created.** All four repos sit on pristine `main` at the HEADs recorded below.

The remediation splits cleanly three ways:

| Bucket | Repos | What it takes |
| --- | --- | --- |
| **Clears with plain `npm audit fix`** | `nova-back-end` (2 high → 0), `europa-back-end` (7 high + 5 mod + 2 low → 0) | Lockfile-only. `package.json` untouched in both. Europa's diff is wide (381/235, `axios` + Nest platform layer) so it needs the test suite and a sandbox deploy; Nova's is 93/36 and near-zero risk. |
| **Already passing** | `callisto-back-end` | 0 high, 0 critical today. Residual 5 low + 2 moderate are all `aws-sdk` → `uuid` and would need `npm audit fix --force` installing `aws-sdk@1.18.0` — not warranted, and not gate-blocking. |
| **Real engineering** | `nova-orbital-back-end` | 9 high. Three are routine transitives; the other six are one root cause — `@planetdepos/pathfinder-observability-pkg@^0.2.13` → `@opentelemetry/sdk-node <=0.219.0` → `@opentelemetry/propagator-jaeger <2.9.0` (GHSA-45rx-2jwx-cxfr). |

The nova-orbital chain reports `fixAvailable: false`, but that is not an upstream block: `sdk-node@0.221.0` already depends on the patched `propagator-jaeger@2.10.0`, and the repo already carries an `overrides` block (`js-yaml`, `multer`) that is exactly the mechanism needed. Preferred remedy is bumping the internal observability package; `overrides` is the fallback. **Neither could be evaluated locally** because of the auth blocker.

**Open before pointing:** does "Nova" in the subtasks mean one repo or two? If one, this epic is two lockfile commits. If two, there is one genuine engineering story on the OTel chain.

---

## Attempt history

_None yet — no implementation attempted._

---

## Session log

### 2026-08-25T05:45:00Z — nova-back-end, nova-orbital-back-end, callisto-back-end, europa-back-end (read-only triage)

**Summary.** Clean-slate sweep and vulnerability sizing for the epic. No production code touched, no branch created, no commit made.

**Clean slate.** Stashed `callisto-back-end`'s two dirty files (`.swcrc`, `notification-template-preview.html`) as `PRDV-16423: pre-clean-slate WIP 2026-08-25`; the four pre-existing Callisto stashes and one Europa stash were left untouched. Moved all four repos to `main`, `fetch --prune`, `pull --ff-only`. Final state, all clean:

| Repo | Was on | Now |
| --- | --- | --- |
| `nova-back-end` | `PRDV-16398` | `main` @ `e5f071a` |
| `nova-orbital-back-end` | `main` | `main` @ `5326247` |
| `callisto-back-end` | `PRDV-16403` (dirty) | `main` @ `56eead71` |
| `europa-back-end` | `PRDV-16192` | `main` @ `34da474` |

**Gate identified.** Read `planetdepos/actions/.github/workflows/node-service-ci.yml@main` via `gh api`. The deploy blocker is `npm audit --audit-level=high` on the full tree after `npm install` — dev dependencies included. This corrected an initial assumption that ECR image scanning was the gate, and it means `--omit=dev` figures are not the target.

**Measurement method.** Per repo: `npm audit --json` for the baseline, then `npm audit fix --package-lock-only` to get a true post-fix number without touching `node_modules`, then `git checkout -- package.json package-lock.json` to revert. Findings written up in `docs/atlas/PRDV-16423/PRDV-16423-baseline-audit.md`.

**Result.** Nova and Europa clear to zero with plain `npm audit fix`, lockfile-only. Callisto already passes. Nova-orbital is the only repo needing engineering, and could not be fully assessed locally.

**Blocker found.** GitHub Packages auth is dead on this machine — `~/.npmrc` token returns 401 (expired/revoked), `gh auth token` returns 403 for missing `read:packages`. The repo `.npmrc` uses `${GITHUB_TOKEN}`, which shadows the user-level token when unset. Needs a PAT with `read:packages`. CI is unaffected (it injects `secrets.GITHUB_TOKEN`).

**Files/areas:** `docs/atlas/PRDV-16423-changelog.md` (new), `docs/atlas/PRDV-16423/PRDV-16423-baseline-audit.md` (new). No app-repo files changed.

**WorkLists card `todo-1785358880857-f4721f87`:**
- Guard passed — card title carries PRDV-16423.
- Marked **1 row**: Preliminary → "Generated ticket for the work to be done" (evidence: `PRDV-16423-original-ticket.md` on disk).
- **Left unmarked, all other rows.** Notably Deploy & PR → Pre-Push → "Run `npm audit`" — audits were run, but that row belongs to pre-push of implemented work, not to triage. Investigation → "Investigation Report" left unmarked: the baseline artifact is a triage writeup, not the Investigation Report the row asks for.
- Set `currentStep` (investigation sweep), `nextUp` (scope decision), `waitingOn` (the auth blocker). Status left at `Unrefined` — no Investigation Report emitted, so the `In Progress` transition does not apply.

#### Shipping checklist

- **Tests run** — not relevant: read-only triage session. No production code, config, or test file was modified in any of the four repos; every lockfile mutation was made with `--package-lock-only` and reverted, verified by `git status --porcelain` returning empty on all four repos.
- **Tests added/updated** — not relevant: no behavior changed.
- **Regression impact** — isolated: the only writes were to `dustin-thomason/docs/`. All four app repos verified at clean `main` (`git status --porcelain` empty, HEADs recorded above).
- **API docs** — not relevant: no HTTP surface touched. No route, DTO, or decorator in any repo was read or modified.
- **Tooling gates** — not applicable: `dustin-thomason` has no root `package.json`, so audit/lint/test gates do not exist for the changed files (docs only). The app-repo audits run this session were *measurements for the ticket*, not commit gates, and none of those repos is being committed.
- **Conflicts / exceptions** — the WorkLists server was unreachable at the start of the session (`localhost:3010` connection refused); per `worklists-card-sync`, a skip is not a stop. The user restarted it mid-session and the card writes completed normally, so no skip was ultimately recorded.

---

### 2026-08-25T16:55:00Z — nova-orbital-back-end, auth-gated measurements (user-executed)

**Summary.** The one repo in the epic that could not be measured is now measured. Dustin ran `~/pf-check.sh` in a Git Bash shell holding a valid `GITHUB_TOKEN` (the agent's shell has no auth — its environment was fixed when `claude.exe` spawned under an explorer-launched Cursor). Raw JSON evidence: `C:\Users\dustin.thomason\pf-check\`. All stages reverted; `nova-orbital-back-end` remains clean at `main` `5326247`.

**Pathfinder has no newer release.** Published versions are `0.2.1 … 0.2.13`; **`0.2.13` is latest**, and its published manifest matches the default branch. So no consumer can fix the OTel chain by bumping the dependency — **an override is the only option available today, in every app that consumes Pathfinder.** Larry's "stop overriding in the higher apps" strictly requires a new Pathfinder release. That makes the Pathfinder bump the epic's critical path.

**Four-stage audit on nova-orbital:**

| Stage | Change | Result |
| --- | --- | --- |
| 1 | baseline (first resolve with real auth) | **9 high**, 12 total |
| 2 | `npm audit fix` only | **6 high**, 6 total |
| 3 | Callisto-style scoped OTel override + `js-yaml ^5.2.3` | **2 high**, 4 total |
| 4 | override **+** `npm audit fix` | **1 high**, 1 total |

**Three claims confirmed, one prediction validated in both directions:**

- **The 9-high baseline was accurate**, not an artifact of a stale lockfile — it reproduced on a genuine authenticated resolve.
- **`npm audit fix` cannot reach the OTel chain.** Stage 2 cleared the 3 routine transitives (`brace-expansion`, `fast-uri`, `js-yaml`) plus every moderate and low, and left all 6 OTel/`@planetdepos` findings standing. Previously inferred from `fixAvailable: false` flags; now measured.
- **Callisto's scoped pathfinder override does port to nova-orbital** — stage 3 eliminated all 6 OTel/`@planetdepos` findings. This is the *opposite* of the Europa result, and it is what the tree-shape explanation predicted: nova-orbital declares the identical `@planetdepos/pathfinder-observability-pkg@^0.2.13` parent, so the scoped entry matches; Europa's parents differ, so it missed. The corrected rule is **"a scoped override ports only where the parent chain matches,"** not "scoped overrides never port."

**Unresolved — one residual, and a non-additive interaction.** Stage 4 leaves a single `brace-expansion` high (`fixAvailable: true`). Note that stage 2's `audit fix` *did* clear `brace-expansion`, but stage 4's did not — pinning the OTel subtree evidently re-parents `brace-expansion` under something `audit fix` will not bump. The likely completion is adding `brace-expansion: ^5.0.9` to the override set (`5.0.9` is the patched release, verified published; Callisto pins exactly it). **Not verified** — it needs one more authenticated run.

**Corrected per-repo direction for the epic:**

| Repo | Remedy | Verified |
| --- | --- | --- |
| `callisto-back-end` | none — 0 high; delete 5 dead override entries | ✅ |
| `nova-back-end` | plain `npm audit fix` | ✅ → 0 |
| `europa-back-end` | plain `npm audit fix`; do **not** port the block | ✅ → 0 |
| `nova-orbital-back-end` | scoped OTel override (ports from Callisto) + `audit fix` | ✅ 9 → 1; final entry unverified |
| `pathfinder-observability-pkg` | new release: `auto-instrumentations-node ^0.79.0`, `sdk-node ^0.221.0`, `exporter-trace-otlp-http ^0.221.0`, own `js-yaml` floor | ❌ not started |

**Tooling gates** — not applicable: `dustin-thomason` has no root `package.json` (docs-only change). The npm audits recorded here are ticket measurements, not commit gates; no app repo is being committed.
