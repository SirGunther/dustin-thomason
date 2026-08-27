# PRDV-16595 — 1-Callisto remediate high/critical security vulnerabilities

## START HERE

_Everything below this section is background. This is the whole of what is outstanding as of 2026-08-25T18:40Z._

### 1. Pathfinder bump verified green — awaiting your go to land it

Ran 2026-08-25. Branch `PRDV-16595-otel-bump` in `pathfinder-observability-pkg`, uncommitted.

| Gate | Result |
| --- | --- |
| `npm audit --audit-level=high` | **0** — zero vulnerabilities at any severity |
| `npm run build` | **0** — compiles on the `0.221` line |
| `npm run lint` | **0** |
| `npm test -- --runInBand` | **0** |

Resolved versions: `sdk-node 0.221.0`, `auto-instrumentations-node 0.79.0`, **`propagator-jaeger 2.10.0`**, `exporter-trace-otlp-http 0.221.0`, `js-yaml 5.4.0`, `brace-expansion 5.0.9`.

`propagator-jaeger 2.10.0` is the point of the whole ticket — GHSA-45rx-2jwx-cxfr required ≥ 2.9.0. It is gone from Pathfinder.

**The build passing is the real result.** The one substantive risk was that `0.219 → 0.221` inside a `0.x` line would break Pathfinder's own code. It does not.

Two runs were needed: the first left a single `brace-expansion` high (Pathfinder's `overrides` block carries only `js-yaml`, no `brace-expansion` entry — the same stale-floor pattern as every other repo in the epic). A plain `npm audit fix` cleared it to zero, touching the lockfile only; `package.json` remains the original 4-line bump. All four gates were then re-run against the post-fix tree — the pre-fix greens are not cited.

**Not committed. Not pushed. No PR.** Per explicit instruction: nothing opens until the ticket is done. Say the word and it commits.

### 2. Decide this (only you can)

The `tar` override in Callisto is masking **1 critical** (`sqlite3` → `node-gyp` → `cacache`/`make-fetch-happen` → `tar`) — the only critical in the epic. `sqlite3` is in `dependencies` but its sole consumer is `src/test-utils/test-database.module.ts`.

| Option | Clears the audit gate? | Off the prod image? | Risk |
| --- | --- | --- | --- |
| Keep the override | yes | no | masks a critical indefinitely |
| Move `sqlite3` → `devDependencies` | no (gate audits dev too) | **yes** | low — confirm `test-utils` is excluded from the prod build |
| Upgrade `sqlite3@6.x` | yes | no | breaking major |

### 3. Ask the team this

Does the Pathfinder change belong on PRDV-16595, or its own ticket? Larry put the ask here; the ticket is titled `1-Callisto`; Pathfinder is a different repo; Derrick split the Docker work off for being a different source. Precedent points both ways.

### Not outstanding

- **D1, D2** — closed, measured.
- **D3** — code shipped on branch `PRDV-16595`, commit `7d9a6926`. PR #432 closed deliberately. Only residual: its test gate needs an authenticated `npm install` in Callisto (that one *does* need the PAT).
- **Nova, Europa** — plain `npm audit fix` clears both to zero. Measured. Not this ticket.

---

## Ticket

- **ClickUp:** [PRDV-16595](https://app.clickup.com/t/43227262/PRDV-16595) — Technical Story, 3 points, Owning Team NASA, status IN PROGRESS (ClickUp internal id `86ak0c9p7`)
- **Parent epic:** [PRDV-16423](https://app.clickup.com/t/43227262/PRDV-16423) — sequenced **1st of 3** (`1-Callisto`, `2-Nova`, `3-Europa`)
- **Repo:** `callisto-back-end`
- **Branch:** _(none — no code change required, see Current state)_
- **PR:** _(none)_
- **WorkLists card:** `todo-1787666748649-710ac783`

---

## Requirements (verbatim)

Captured verbatim in `docs/atlas/PRDV-16595/PRDV-16595-original-ticket.md` (ClickUp browser capture, 2026-08-25). Reproduced unchanged:

> #### See Epic for Value Proposition
>
> #### **Acceptance Criteria**
>
> - No high- or critical-severity security vulnerabilities remain for Callisto
> - All three systems can be deployed to AWS through the standard deployment process without security-related exceptions.

The ticket body then carries an `overrides` JSON block. **That block is Callisto's current `package.json` state, not a proposal** — see Current state.

---

## Context

- **The gate** (established under PRDV-16423): `npm audit --audit-level=high` in the DevOps-managed reusable workflow `planetdepos/actions/.github/workflows/node-service-ci.yml@main`, run after `npm install` on the full tree. Dev dependencies count. The ECR push job depends on it.
- **URL discrepancy in the kickoff message.** The card title supplied by the user read `... - PRDV-16595` but the pasted link pointed at `/t/43227262/PRDV-16423` (the epic). The original-ticket artifact is authoritative and gives `https://app.clickup.com/t/43227262/PRDV-16595`; the card was written with that. This is the exact title-vs-link hazard `worklists-card-sync` warns about, resolved from the source artifact rather than by guessing.
- **AC line 2 is epic-scoped**, not Callisto-scoped ("All three systems can be deployed"). Callisto alone cannot satisfy it; it closes when all three child stories close.

---

## Plans

| Added | Plan (path or link) | Status | One-line approach |
| ----- | ------------------- | ------ | ----------------- |
| 2026-08-25 | `docs/atlas/PRDV-16595/PRDV-16595-callisto-remediation-state.md` | `active` | Establish that Callisto is already remediated, ratify its `overrides` block as the epic's canonical pattern, document the accepted `aws-sdk` residual. |
| 2026-08-25 | `docs/atlas/PRDV-16423/PRDV-16423-baseline-audit.md` (epic) | `superseded in part` | Epic triage. Its nova-orbital recommendation (derive the OTel override, raise `js-yaml` to `^4.3.1`) is superseded — Callisto's block already solves it, scoped, at `js-yaml ^5.2.3`. |

---

## Current state

**Callisto already satisfies AC line 1.** `npm audit` on `main` @ `56eead71` reports **0 high, 0 critical**. No code change is required in `callisto-back-end`.

The `overrides` block in the ticket body is Callisto's committed `package.json` state, verbatim. Every version it pins was verified to exist on the public registry. It was not authored for this ticket — `git log -S` shows it accumulating across PRDV-14641, PRDV-14699, PRDV-15850, PRDV-16081, PRDV-16288 and PRDV-16391, paid for piecemeal by whoever was blocked at the time.

**This story is ratification, not remediation** — which is why it is sequenced first and still worth 3 points. Its deliverable is the pattern the other two stories consume.

**The epic-reframing finding.** All four repos already carry `overrides` blocks, and each repo's audit failures correspond exactly to what its block is missing or has let go stale. Callisto's is complete; nova-back-end's is partially stale (`brace-expansion ^5.0.8` vs patched `5.0.9`; `js-yaml ^4.2.0` inside a range vulnerable through `4.3.0`); nova-orbital has no OTel entries at all and takes six findings for it; europa lacks js-yaml/brace-expansion/multer/fast-uri entries and is flagged for precisely those. The correspondence holds in both directions — nova-back-end's OTel overrides *are* current and it reports zero OTel findings against the same internal `pathfinder-observability-pkg` dependency that gives nova-orbital six.

So PRDV-16423 is one overrides block developed in Callisto and never propagated, plus floor drift where it was partially copied.

**But propagating the block is not the remedy — measured, not assumed.** Ported to Europa (lockfile-only, reverted), Callisto's applicable entries took 7 high → **5**; plain `npm audit fix` takes it → **0** with `package.json` untouched. Callisto's overrides are *scoped*, which makes them precise to Callisto's tree shape and therefore non-portable: Europa reaches `brace-expansion` via eslint/jest parents rather than `minimatch@10`, and `js-yaml` via `@istanbuljs/load-nyc-config` rather than `@nestjs/swagger`, so both entries miss. Three of Europa's seven (`axios`, `form-data`, `fast-uri`) have no entry in the block at all.

Corrected direction: **`npm audit fix` for Nova and Europa** (both measured to 0); **override needed only for nova-orbital**, whose 6 OTel findings are `fixAvailable: false` so `audit fix` cannot reach them. Callisto's scoped pathfinder entry is the leading candidate there because nova-orbital declares the *identical* parent `@planetdepos/pathfinder-observability-pkg@^0.2.13` — same tree shape, the one case where a scoped override should transfer. **That is unverified**: the GitHub Packages auth gap blocks every `@planetdepos` resolution locally.

**Accepted residual:** 5 low + 2 moderate, all `aws-sdk` → bundled `uuid`. npm offers only `--force` installing `aws-sdk@1.18.0` (downgrade-shaped major). Outside AC scope, not gate-blocking. Accept and document.

**Re-pointing recommendation — WITHDRAWN 2026-08-25T15:05Z.** The earlier recommendation (3 → 1, on the grounds that no Callisto code change was required) is retracted. Derrick's "freebie" remark at standup referred only to the Callisto vulnerability *check*; Larry Adams then added the Pathfinder remediation ask and explicitly stated the ticket *"doesn't actually have everything you need."* **3 points stands** — the work is real, it is just in `planetdepos/pathfinder-observability-pkg` rather than in `callisto-back-end`.

---

## Reframed by standup — 2026-08-25

**The ask is Pathfinder, not Callisto.** Larry Adams, verbatim: *"can you update Pathfinder to remediate all of these so that we can stop overriding them in the higher apps? Because that's really what I'm trying to get at here. We have a lot of overrides here."* Earlier in the same exchange: *"you can get away with override, but at some point we got to kind of stop, you know, kind of nip it."*

The overrides are the symptom; `@planetdepos/pathfinder-observability-pkg` is the cause. The objective is to **delete** overrides, not propagate them — which also retires the porting question from the prior session entirely.

**Method given by Derrick Dieso:** *"stress test those, like one at a time, remove, yeah, like remove like the FDIR, PICO match override, and then MPM audit, see if that works."* Executed — results below.

**Explicitly out of scope — separate ticket.** Karl Amber raised critical vulnerabilities in the Alpine Docker base image and has wired Trivy into a quality check so ECR scan results surface locally rather than requiring a trip to AWS. Derrick: *"those would be two different tickets, because they're looking at for vulnerabilities in two different sources."* Larry agreed; Derrick confirmed a ticket was cut. Karl also confirmed base-image findings do not appear in `npm audit`, which independently corroborates the gate identified under PRDV-16423.

**Requested hygiene.** Larry asked that the `package.json` overrides block be posted in each ticket before work starts — he did it for Callisto himself (*"I just put it in that ticket right there"*) and asked for the same before Nova and Europa: *"show the package JSON, let other developers know this is what you're tackling."*

**Sprint context (not scope).** Derrick flagged that three PRs in Callisto and three in Atlas have no reviewers, and that getting reviews moved to QA for the 9/30 release outranks pulling in new work; Larry showed a plateauing burndown. Recorded because it affects sequencing, not because it changes this ticket.

---

## Validation review

| Version | Artifact | Overall status |
| --- | --- | --- |
| `v0.1.0` | [Callisto Dependency Remediation v0.1.0 — validation review](PRDV-16595/review/v0.1.0-PRDV-16595-callisto-remediate-high-critical-vulnerabilities-validation-review.md) | `Mixed` |

Status distribution: **D1** Callisto meets the AC — Passed (measured). **D2** load-bearing overrides identified — Passed (all eight entries tested). **D3** delete the five inert entries — Pending (measured zero-impact, not yet performed). **D4** Pathfinder release retires the OTel override — **Blocked**. **D5** override-suppressed critical escalated — Pending.

**D4 is the epic critical path.** Pathfinder `0.2.13` is the latest published release, so no consumer can remove its OpenTelemetry override until a new version ships. `Mixed` is used because these outcomes differ materially and no single release-level result describes the review.

---

## Next steps — agreed state as of 2026-08-25T18:20Z

**Nothing on this ticket is claimed ready.** PR #432 was closed (not merged) to keep the review queue clear; branch `PRDV-16595` and commit `7d9a6926` are preserved on `origin`.

| Id | Objective | Status | Blocked on | Owner of next move |
| -- | --- | --- | --- | --- |
| D1 | Callisto meets vulnerability AC | Passed | — | closed |
| D2 | Load-bearing overrides identified | Passed | — | closed |
| D3 | Inert override entries removed | Passed (code) | **test gate** — needs authenticated `npm install` | agent, once a PAT is in the environment |
| D4 | Consumers pass without the OTel override | **Blocked** | **D6** — no release above `0.2.13` exists | downstream of D6 |
| D5 | Override-suppressed critical escalated | Pending | **nothing** — actionable now | Dustin (raise with Larry/Derrick) |
| D6 | Pathfinder declares patched OTel versions | Pending | nothing technical; scope question open | Dustin + agent |

### Correction to the earlier framing

D4 and D5 were previously described together as blocked. That was wrong. **Only D4 is Blocked**, and only because the release it validates does not exist yet — the blocker is removable by us, not by a third party. **D5 is Pending, not blocked**, and is the one item that can start immediately.

### D6 — unblocking D4 (the ticket's real ask)

Sequence, all mechanically confirmed this session:

1. Clone `planetdepos/pathfinder-observability-pkg` (private; access verified as `push: true`, `triage: true`, `admin: false`, `maintain: false`).
2. Branch and bump: `auto-instrumentations-node ^0.77.0 → ^0.79.0`, `sdk-node ^0.219.0 → ^0.221.0`, `exporter-trace-otlp-http ^0.219.0 → ^0.221.0`, and raise or drop its own `overrides: {"js-yaml": "^4.2.0"}`.
3. Run the package's own audit / lint / test gates. Its `src/` is small — `index.ts` plus an `observability/` directory — so OTel surface area is limited, but a `0.219 → 0.221` move inside a `0.x` line can still break.
4. PR, merge to `main`, tag via `semver-tag-commit.yml`.
5. Trigger `pkg-publish-npm.yml` by **workflow dispatch** against that tag with **`dry_run: true`** first, then publish for real.
6. Then in Callisto and nova-orbital: bump the dependency and **delete** the pathfinder-scoped override. That closes D4 and satisfies Larry's ask.

**Prerequisite for any of it:** a GitHub PAT with `read:packages` in the environment `claude.exe` inherits, plus SSO authorization for `planetdepos` if enforced. Publishing additionally needs `write:packages`, which the workflow supplies itself via `packages: write`.

**Open question — scope.** Larry put the Pathfinder ask on this ticket (*"the ask here is... can you update Pathfinder"*), but PRDV-16595 is titled `1-Callisto`, and Derrick's precedent from the same standup was to split the Docker base-image work onto its own ticket for being a different source. Pathfinder is a different **repository**. Whether D6 belongs here or on its own ticket is a team call, and the precedent points both ways. **Not resolved by the agent.**

### D5 — starting now (not blocked)

New evidence that reframes the conversation: **`sqlite3` is declared in `dependencies` (`^5.1.7`), but its only consumer in the codebase is `src/test-utils/test-database.module.ts`** — a test utility. So the vulnerable chain (`sqlite3` → `node-gyp` → `make-fetch-happen` → `http-proxy-agent` → `@tootallnate/once`) is install-time and build-time native-module tooling, not code that executes in the running service — yet it still ships in the production image because it sits in `dependencies`.

That yields three distinct options to put in front of Larry and Derrick, rather than one scary number:

| Option | Clears the npm audit gate? | Removes it from the prod image? | Risk |
| --- | --- | --- | --- |
| Keep the `tar` override (status quo) | yes | no | none; masks a critical indefinitely |
| Move `sqlite3` to `devDependencies` | **no** — the gate audits the full tree including dev | **yes** | low; confirm `test-utils` is excluded from the production build |
| Upgrade to `sqlite3@6.x` | yes | no | breaking major; `npm audit fix --force` proposes `sqlite3@6.0.1` |

The move-to-devDependencies option is the one not previously on the table, and it is the only one that addresses production exposure. It does **not** replace the override, because the gate counts dev dependencies — a point worth making explicitly so the two concerns do not get conflated.

**Next move:** Dustin raises this with Larry and Derrick using the table above and gets a disposition. No code change until then.

### D3 — residual

Code is shipped and audit + lint verified. The **test gate never ran**, so D3 is done but not fully verified. Re-run `npm test -- --runInBand` against a synced `node_modules` once a PAT is available, then reopen the PR. Until that happens D3 should not be described as complete.

## Attempt history

_None — no implementation attempted or required._

---

## Session log

### 2026-08-25T20:30:00Z — pathfinder-observability-pkg — Pathfinder 0.2.14 — clean rebuild, validated, PR opened

**Summary.** Rebuilt the OpenTelemetry bump using Derrick Dieso's prescribed method after discovering the first attempt used the wrong one, captured the baseline that was previously missing, and opened the enabling PR.

**Baseline captured (was missing).** The first pass cloned, branched and bumped without ever auditing `main`, so there was no "before" to prove the change fixed anything. Clean `main`, `rm -rf node_modules && rm package-lock.json && npm install`: **3 high** — `@opentelemetry/auto-instrumentations-node` (0.77.0), `@opentelemetry/propagator-jaeger` (2.8.0), `@opentelemetry/sdk-node` (0.219.0).

**Method corrected.** The first build used `npm install` against the clone's existing lockfile, then patched it with `npm audit fix`. Derrick's rule is to delete `node_modules` **and** `package-lock.json` first — *"if you update the package JSON, but you don't update the package lock and you do the npm install, things can sometimes get misaligned, and we'll catch that in the quality report."* Rebuilt from scratch with all five edits (four dependency ranges plus `version` → `0.2.14`) applied **before** the lockfile was generated, per his ordering rule and the publish workflow's version check.

**The method change altered the result.** The first build left a `brace-expansion` high that needed an `npm audit fix` step. On a from-scratch rebuild that finding does not exist — `brace-expansion` resolves to `5.0.9` unaided. It was an artifact of patching an existing lockfile, not a real defect. The lockfile also shrank: 999 insertions, 2525 deletions.

| Package | `main` | `0.2.14` |
| --- | --- | --- |
| `@opentelemetry/sdk-node` | 0.219.0 — high | 0.221.0 |
| `@opentelemetry/propagator-jaeger` | 2.8.0 — high | **2.10.0** |
| `@opentelemetry/auto-instrumentations-node` | 0.77.0 — high | 0.79.0 |
| `@opentelemetry/exporter-trace-otlp-http` | 0.219.0 | 0.221.0 |
| `js-yaml` (override floor) | ^4.2.0 | ^5.2.3 → resolves 5.4.0 |
| **Audit total** | **3 high** | **0 at any severity** |

`propagator-jaeger 2.10.0` clears GHSA-45rx-2jwx-cxfr, the advisory this epic traces back to.

| Gate | Command | Scope | Result | Exception / risk |
| ---- | ------- | ----- | ------ | ---------------- |
| audit | `npm audit --audit-level=high` | pathfinder-observability-pkg | **pass** (exit 0) | Zero findings at any severity, no `audit fix` required |
| lint | `npm run lint` | pathfinder-observability-pkg | **pass** (exit 0) | — |
| tests | `npm test -- --runInBand` | pathfinder-observability-pkg | **pass** (exit 0) | 4 suites, 20 tests |
| build | `npm run build` | pathfinder-observability-pkg | **pass** (exit 0) | The substantive risk — `0.219 → 0.221` inside a `0.x` line — does not break the package |

**Scope — no separate ticket.** Derrick: *"we don't want to open up a new ticket for this because the effort to fix the dependencies in Calisto needs the effort for the Pathfinder observability package."* Package problems surface through the services that consume them, so the fix rides PRDV-16595. This is why the ticket is three points.

**PR framing** follows his instruction that the PR explain itself: it enables PRDV-16595 rather than closing it.

#### Shipping checklist

- **Tests run** — all four gates green against the clean rebuild; the pre-rebuild results are not cited.
- **Tests added/updated** — not relevant: dependency-range change only, no source modified. The existing 20 tests are the regression surface and all pass.
- **Regression impact** — the package is consumed by Callisto and Triton, and possibly Dione and others. Existing published versions remain available, so no consumer is affected until it upticks deliberately. Verified `package.json` diff is 5 lines and touches no source file.
- **API docs** — not relevant: no HTTP surface in this package; it is a NestJS observability module.
- **Tooling gates** — audit, lint, build and tests all run and green.
- **Conflicts / exceptions** — the standing "no PRs" instruction conflicts with Derrick's process, which requires a PR merged to `main` before a tag can be published. Raised and cleared explicitly before opening.


### 2026-08-25T17:45:00Z — callisto-back-end — D3: remove inert override entries

**Summary.** First code change on this ticket. Removed the five `overrides` entries that the D2 stress-test proved inert, on branch `PRDV-16595` from `main` @ `56eead71`. Audit and lint green; the test gate is **blocked** (see the gate table).

**Removed:** `dependency-cruiser`→`picomatch`, `@angular-devkit/core`→`picomatch`, `fdir`→`picomatch`, `minimatch@10`→`brace-expansion`, `multer`.

**Retained:** `@planetdepos/pathfinder-observability-pkg` (6 high), `@nestjs/swagger`→`js-yaml` (2 high), `tar` (4 high + 1 critical).

**Two self-inflicted errors, both caught before commit:**

1. The first edit used a 2-space `JSON.stringify` and reformatted the whole manifest — `package.json` uses **tabs** — producing a 335-line diff plus 42,605 lines of cascaded lockfile churn. Reverted; verified a tab-indented round-trip is byte-identical to the original, then re-applied. Final diff: **1 insertion, 14 deletions** in `package.json`, 39 insertions in `package-lock.json`.
2. Ran a full `npm install` to sync `node_modules` for the test gate, which **E401'd** on the `@planetdepos/orbital-docking-protocol` tarball and ran a partial cleanup. Predictable and avoidable — the auth gap was already documented this session, and every prior measurement deliberately used `--package-lock-only` for exactly this reason. Damage assessed: all key runtime packages (`@planetdepos/*`, `@nestjs/core`, `@nestjs/platform-express`, `typeorm`, `sqlite3`, `multer`, `aws-sdk`) verified present; cleanup touched only nested `@opentelemetry/exporter-logs-otlp-http` directories. A reinstall with a valid token is advisable, but nothing is known-broken.

**What the change actually resolves to.** The entire lockfile delta is three added nested entries, all `picomatch@4.0.4`, under `@angular-devkit/core`, `@nestjs/schematics`, and `dependency-cruiser` — all **dev tooling**. No runtime dependency changed version; `multer`, `brace-expansion`, and `tar` are untouched in the lock. This confirms the removed overrides were redundant: the tree resolves to the same versions without them.

| Gate | Command | Scope | Result | Exception / risk |
| ---- | ------- | ----- | ------ | ---------------- |
| audit | `npm audit --audit-level=high` | callisto-back-end | **pass** (exit 0) | 7 findings remain (5 low, 2 moderate), identical to baseline — `aws-sdk`→`uuid` and the `@tootallnate/once` chain, all below the AC threshold |
| lint | `npm run lint` | callisto-back-end | **pass** (exit 0) | Script includes `--fix`; `git status` confirmed it rewrote nothing beyond the two files already changed |
| tests | `npm test -- --runInBand` | callisto-back-end (`jest-e2e.json`) | **blocked** | `npm install` cannot complete without GitHub Packages auth, so `node_modules` cannot be synced to the new lockfile and the suite would exercise the stale tree. **Residual risk: low and bounded** — the only resolution change is `picomatch` under three dev-tooling parents; no runtime dependency version moved. **Follow-up:** re-run once a `read:packages` PAT is in the environment |

**PR timing — opened prematurely (flagged by user 2026-08-25T18:10Z).**

Opening [PR #432](https://github.com/planetdepos/callisto-back-end/pull/432) was a step too early. Three reasons, all of which were known before I did it:

1. **Queue pressure.** Derrick asked at standup for the existing review backlog to be drained before new work was added — *"let's clean up what we got before we start pulling more stuff in."* Callisto had five open PRs awaiting review; mine made six, all but one `REVIEW_REQUIRED`. I had raised this exact conflict with the user one turn earlier and then proceeded anyway.
2. **Its own gate was not green.** The test gate is blocked on GitHub Packages auth. A PR whose verification is incomplete pushes that verification onto the reviewer.
3. **A requested precursor was skipped.** Larry asked that the `package.json` overrides block be posted in the ticket for visibility before the work lands — *"let other developers know this is what you're tackling."* That was recorded in these artifacts, not in ClickUp where he asked for it.

**Cause:** I read "go for D3" as authorising the full chain through PR creation, because my own D3 next-step text said "open a PR." The user answered "do D3," not "and put it on the board."

**Not a container for the ticket.** PR #432 cannot absorb the rest of PRDV-16595. D4 (delete the pathfinder override) is blocked on a Pathfinder release with no ETA, so holding #432 open as its vessel would leave it stale against `main` for an unknown period. D3 is independently mergeable on its own merit — which is exactly why it should have waited for its own test gate rather than been bundled forward.

**Disposition:** left open pending the user's call. Recommended converting to **draft** — removes it from the review queue Derrick is protecting, preserves commit `7d9a6926`, and reverses with one command once tests run with auth. No action taken on the PR unilaterally.

#### Shipping checklist

- **Tests run** — blocked, per the gate table. Not skipped for convenience: the required dependency (an authenticated `npm install`) is unavailable, the residual risk is stated, and the follow-up is named.
- **Tests added/updated** — not relevant: no application logic changed. The change is dependency-resolution metadata in `package.json` / `package-lock.json`; there is no unit under test.
- **Regression impact** — isolated, boundary named: the lockfile delta is confined to `picomatch` under `@angular-devkit/core`, `@nestjs/schematics`, and `dependency-cruiser` — build and lint tooling that does not execute in the running service. Verified by enumerating every changed lockfile path; no runtime entry changed version.
- **API docs** — not relevant: no HTTP surface touched. No route, DTO, controller, or Swagger decorator was read or modified; only `package.json` and `package-lock.json` changed.
- **Tooling gates** — audit and lint run and green; tests blocked as recorded above.
- **Conflicts / exceptions** — the two self-inflicted errors above, both caught pre-commit. Recorded rather than quietly corrected, because the second one altered local state the user may want to repair.



### 2026-08-25T14:10:00Z — callisto-back-end (read-only analysis) + WorkLists card scaffold

**Summary.** Narrowed from the PRDV-16423 epic to its first sequenced child story. Established that Callisto is already remediated and identified why the epic's other three repos are not. No production code touched, no branch created, no commit made.

**What the ticket body turned out to be.** The `overrides` JSON in the ClickUp description read initially as a proposed remediation. Compared it field-by-field against `callisto-back-end/package.json` on `main`: it is the committed block, verbatim. Verified every pinned version resolves on the public registry (`js-yaml@5.2.3`, `auto-instrumentations-node@0.79.0`, `sdk-node@0.221.0`, `propagator-jaeger@2.10.0`, `picomatch@4.0.4`, `brace-expansion@5.0.9`, `tar@7.5.7`, `multer@2.2.0`) — nothing aspirational in it.

**Provenance traced.** `git log -S'pathfinder-observability-pkg'` and `-S'propagator-jaeger'` on `package.json`, plus `log -L` over the overrides range, attribute the block to six prior tickets (PRDV-14641, PRDV-14699, PRDV-15850, PRDV-16081, PRDV-16288, PRDV-16391). Notably `a8761489 PRDV-14699: Resolve npm audit via OpenTelemetry overrides` and `f75dd4e0 PRDV-15850: Fixed high level vulnerabilities`.

**Cross-repo comparison — the finding.** Dumped `overrides` from all four epic repos and mapped them against the PRDV-16423 audit results. Every flagged package corresponds to a missing or stale override; every current override corresponds to an absent finding. Recorded as a matrix in the artifact.

**Two corrections to my own PRDV-16423 triage**, both material to stories 2 and 3:
- I reported `js-yaml`'s patched release as `4.3.1` after filtering only the 4.x line. A 5.x line exists (latest `5.4.0`), and Callisto deliberately pins `^5.2.3`. The 5.x jump is the proven answer, not a 4.x floor bump.
- I recommended designing nova-orbital's OTel override from scratch. Unnecessary — Callisto's scoped block already covers that exact chain and is deployed.

**Files/areas:** `docs/atlas/PRDV-16595-changelog.md` (new), `docs/atlas/PRDV-16595/PRDV-16595-callisto-remediation-state.md` (new). No app-repo files changed; `callisto-back-end` verified clean at `main` `56eead71`.

**WorkLists card `todo-1787666748649-710ac783`:**
- Card arrived as a bare template (body was the single line `# Ticket Template`, no workflow headings, so `currentStep` would have 400'd). Wrote the title + workflow scaffold first, then set fields on a fresh precondition — two exchanges, each re-read immediately before its write.
- Ticket-id guard: the supplied title carried PRDV-16595 while the supplied link pointed at the epic PRDV-16423. Resolved from the original-ticket artifact (authoritative), which gives the PRDV-16595 URL; card written with that. No ambiguity about which ticket the card is for — the template was blank, so there was no competing id to confuse.
- Marked **1 row**: Preliminary → "Generated ticket for the work to be done" (evidence: `PRDV-16595-original-ticket.md` on disk).
- **Left unmarked, everything else.** Deploy & PR → Pre-Push → "Run `npm audit`": audits were run and are clean, but that row belongs to pre-push of implemented work. Investigation → "Investigation Report": the state artifact is analysis, not that report.
- Set `currentStep` and `nextUp`; left `waitingOn` empty (nothing blocks this story — the GitHub Packages PAT gap from the epic session affects nova-orbital only). Status left `Unrefined`: no Investigation Report emitted, so the `In Progress` transition does not apply. `workAhead` left untouched — user's field.

### 2026-08-25T14:22:00Z — europa-back-end (measurement, reverted)

**Summary.** Tested the "port Callisto's overrides block" direction I had recorded earlier the same session. **It failed the test**, and the direction has been corrected in this changelog, in the state artifact, and on the epic card.

**Why the test.** The cross-repo correspondence matrix explains *why* each repo fails, but says nothing about whether porting is the right *remedy*. I had extrapolated one to the other and written the extrapolation onto the epic card, where it would have steered stories 2 and 3. It needed measuring.

**Method.** `europa-back-end` was confirmed to have no `@planetdepos` dependencies, so the auth gap did not interfere. Two runs, each `--package-lock-only` and reverted via `git checkout -- package.json package-lock.json`:

| Run | Change | Result |
| --- | --- | --- |
| A | Added Callisto's applicable entries (`minimatch@10`→`brace-expansion ^5.0.9`, `@nestjs/swagger`→`js-yaml ^5.2.3`, `multer ^2.2.0`) | 7 high → **5 high** |
| B | Plain `npm audit fix`, no manifest change | 7 high → **0** |

**Root cause of the failure.** Callisto's overrides are *scoped* — precise to Callisto's tree shape, and therefore not portable. Europa reaches `brace-expansion` through `@eslint/config-array`, `@eslint/eslintrc`, `@jest/reporters`, `eslint` and root, not `minimatch@10`; and `js-yaml` through `@istanbuljs/load-nyc-config` and root, not `@nestjs/swagger`. Both scoped entries missed. Only `multer` cleared (taking `@nestjs/platform-express` with it, since that finding was purely via multer). `axios`, `form-data` and `fast-uri` were never addressable — no entry exists for them.

**Conclusion.** The transferable asset is the *technique*, not the JSON. Corrected per-repo direction recorded in Current state.

**Nova-orbital remains unverified.** Its 6 OTel findings are `fixAvailable: false`, so `audit fix` cannot reach them and an override genuinely is required. Callisto's scoped pathfinder entry is the leading candidate because nova-orbital declares the identical parent spec `@planetdepos/pathfinder-observability-pkg@^0.2.13`. Confirmed the specs match; **could not test the fix** — auth gap. Not presented as verified.

**Files/areas:** `docs/atlas/PRDV-16595-changelog.md`, `docs/atlas/PRDV-16595/PRDV-16595-callisto-remediation-state.md`. `europa-back-end` verified back at clean `main` `34da474` (`git status --porcelain` empty).

### 2026-08-25T15:05:00Z — callisto-back-end override stress-test + Pathfinder specification

**Summary.** Standup reframed the ticket from "remediate Callisto" to "remediate Pathfinder so the apps can stop overriding." Executed Derrick's one-at-a-time stress-test on Callisto's eight override entries and derived the exact Pathfinder change set. No code committed; all runs reverted.

**Stress-test.** Each entry deleted individually, `npm install --package-lock-only`, `npm audit`, revert. Callisto re-resolves despite the dead GitHub Packages token (the pathfinder tarball is already pinned in the lockfile), so **all eight entries were testable** — no gaps. Baseline all-present: H0 C0 M2 L5.

| Removed | Result | Verdict |
| --- | --- | --- |
| `@planetdepos/pathfinder-observability-pkg` | **H6** | load-bearing — Larry's target |
| `tar` → `>=7.5.7` | **H4 + C1** | load-bearing — app-level |
| `@nestjs/swagger` → `js-yaml` | **H2** | load-bearing — app-level |
| `dependency-cruiser` / `@angular-devkit/core` / `fdir` → `picomatch` | H0 ×3 | **deletable** |
| `minimatch@10` → `brace-expansion` | H0 | **deletable** |
| `multer` | H0 | **deletable** |
| all removed | **H12 C1** | total suppressed exposure |

**Five of eight entries are dead weight** — deletable today with zero audit impact. Individual results sum exactly to the all-removed total (6+2+4=12 high), so there are no interaction effects.

**Critical found, currently override-suppressed.** Removing the `tar` override exposes **1 critical** plus 4 high via `sqlite3` → `node-gyp` → `cacache`/`make-fetch-happen` → `tar`. This is the only critical-severity finding anywhere in the epic, and Callisto satisfies the AC today only because an override is holding it back. Flagged for escalation — exactly the fragility Larry described.

**Pathfinder specification derived.** Read `planetdepos/pathfinder-observability-pkg` `package.json` via `gh api` (repo is private; the contents API worked where the npm registry did not). Published `0.2.13` declares `@opentelemetry/auto-instrumentations-node: ^0.77.0` (vulnerable range is `0.57.0–0.77.0`, so it resolves *inside* it), `@opentelemetry/sdk-node: ^0.219.0` (pulls `propagator-jaeger@2.8.0`; `0.220.0` is the first with patched `2.9.0`), `@opentelemetry/exporter-trace-otlp-http: ^0.219.0`, and its own stale `overrides: {"js-yaml": "^4.2.0"}`. Callisto's override block pins precisely the corrected versions — **the override is the specification for the upstream fix**. Full change set in the artifact.

**Secondary design finding.** Callisto's `"@nestjs/common": "$@nestjs/common"` entry is peer-alignment, not a security pin. Pathfinder declares `@nestjs/common: ^11.0.0` as a hard dependency with an empty `peerDependencies`, which is what forces consumers to align it by hand. Moving it to a peerDependency upstream would retire that entry too. Not a vulnerability, so not gating.

**Files/areas:** `docs/atlas/PRDV-16595-changelog.md`, `docs/atlas/PRDV-16595/PRDV-16595-callisto-remediation-state.md`. `callisto-back-end` verified back at clean `main` `56eead71`. Nova and Europa untouched this session.

#### Shipping checklist

- **Tests run** — not relevant: read-only analysis. No production code, config, or test file modified in `callisto-back-end`; `git status --porcelain` empty at `main` `56eead71`. The `npm audit` runs this session were measurements for the ticket, not commit gates.
- **Tests added/updated** — not relevant: no behavior changed.
- **Regression impact** — isolated: the only writes were to `dustin-thomason/docs/` and the WorkLists card. `callisto-back-end` verified untouched.
- **API docs** — not relevant: no HTTP surface read or modified. No route, DTO, or decorator touched.
- **Tooling gates** — not applicable: `dustin-thomason` has no root `package.json`, so audit/lint/test gates do not exist for the changed files (docs only).
- **Conflicts / exceptions** — none. The card's ticket-id guard resolved cleanly from the source artifact rather than by inference; recorded above.
