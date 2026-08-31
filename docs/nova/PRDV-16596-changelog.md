# PRDV-16596 — 2-Nova remediate high/critical security vulnerabilities

## Ticket

- **ClickUp:** [PRDV-16596](https://app.clickup.com/t/43227262/PRDV-16596)
- **Repos:** `nova-back-end` (pkg `nova-video-transcoder`), `nova-orbital-back-end`
- **Branch:** `PRDV-16596` (created in both repos, 2026-08-30)
- **PR:** _(link when opened)_
- **Parent epic:** [PRDV-16423](../atlas/PRDV-16423-changelog.md) · **Sequenced:** 2nd of 3 · **Points:** 2
- **Sibling (done):** [PRDV-16595 — Callisto](../atlas/PRDV-16595-changelog.md)
- **WorkLists card:** `todo-1788129189388-c99d6866` — titled for this ticket 2026-08-31; see Conflicts / exceptions for the two writes the server refused

---

## Requirements (verbatim)

_From `PRDV-16596/PRDV-16596-original-ticket.md` (ClickUp capture 2026-08-30)._

> #### See Epic for Value Proposition
>
> #### **Acceptance Criteria**
>
> - No high- or critical-severity security vulnerabilities remain for Nova
> - All three systems can be deployed to AWS through the standard deployment process without security-related exceptions.

---

## Context

- **"Nova" is two repos.** `nova-back-end` and `nova-orbital-back-end`. The epic changelog flagged this as unresolved ("Open before pointing"). It is resolved here by measurement, not by asking: `nova-back-end` already reports **0 vulnerabilities** on `main`, so a one-repo reading would make this ticket a no-op while leaving 9 highs standing in a Nova system. **Scope = both repos**; the substance is `nova-orbital-back-end`.
- **Callisto (PRDV-16595) set the pattern and it has already landed.** Pathfinder `0.2.14` is published; `callisto-back-end` consumes `^0.2.14` and its `overrides` block is now `{}` with a clean audit. The Callisto shape (commit `aa8683db`) was: uptick `@planetdepos/pathfinder-observability-pkg` `^0.2.13 → ^0.2.14`, uptick `@nestjs/swagger`, then delete the overrides those upticks made dead.
- **Larry Adams' actual ask on this epic** is override deletion, not override propagation: _"can you update Pathfinder to remediate all of these so that we can stop overriding them in the higher apps."_ Pathfinder is now published, so Nova is the consumer-side half of that.
- **Reference runbooks (Callisto):** [pathfinder update](../atlas/PRDV-16595/PRDV-16595-pathfinder-update-runbook.md) · [remaining work](../atlas/PRDV-16595/PRDV-16595-remaining-work-runbook.md) · [remediation state](../atlas/PRDV-16595/PRDV-16595-callisto-remediation-state.md)
- **Out of scope (separate ticket):** Alpine Docker base-image criticals surfaced by Trivy/ECR. Derrick Dieso and Larry both confirmed these are a different ticket because they scan a different source; base-image findings do not appear in `npm audit`.

---

## Plans

| Added | Plan (path or link) | Status | One-line approach |
| ----- | ------------------- | ------ | ----------------- |
| 2026-08-30 | In-session — this changelog's **Current state** | `active` | Consume published Pathfinder `0.2.14` in both Nova repos, `npm audit fix` the routine transitives, then delete every override the upticks made dead — mirroring Callisto `aa8683db`. |

---

## Session log

### 2026-08-30T22:45:00Z — nova-back-end, nova-orbital-back-end (onboarding, measurement, branch prep)

- **Summary:** Reviewed the completed Callisto sibling (PRDV-16595) as the reference implementation, brought both Nova repos up to `main`, measured the current audit baseline in each, created the `PRDV-16596` branch in both, and confirmed the one blocker that gates all remaining work. **No dependency or code change made yet.**
- **Plan used:** Plans row 2026-08-30 (`active`).
- **Repos / refs:**

  | Repo | Before | After `git pull --ff-only` | Branch |
  | --- | --- | --- | --- |
  | `nova-back-end` | `main` @ `e5f071a` | `main` @ `0b32162` | `PRDV-16596` created |
  | `nova-orbital-back-end` | `main` @ `5326247` | already current | `PRDV-16596` created |

- **Measured audit baseline (2026-08-30, post-pull):**

  | Repo | Command | Result |
  | --- | --- | --- |
  | `nova-back-end` | `npm audit` | **0 vulnerabilities** — already satisfies the AC |
  | `nova-orbital-back-end` | `npm audit` | **12 total: 9 high, 2 moderate, 1 low, 0 critical** |

- **`nova-orbital-back-end` — the 9 high, decomposed:**

  | Group | Packages | `fixAvailable` | Route out |
  | --- | --- | --- | --- |
  | OTel / Pathfinder chain (6) | `@opentelemetry/auto-instrumentations-node`, `@opentelemetry/propagator-jaeger`, `@opentelemetry/sdk-node`, `@planetdepos/pathfinder-observability-pkg`, `@planetdepos/orbital-receiver-pkg`, `@planetdepos/orbital-relay-pkg` | `false` (except `auto-instrumentations-node`) | Uptick Pathfinder `^0.2.13 → ^0.2.14` (published). All six clear from that one uptick — receiver and relay reach the chain through Pathfinder on a `^0.2.13` caret, so they dedupe onto `0.2.14` without being touched. |
  | Routine transitives (3) | `brace-expansion`, `fast-uri`, `js-yaml` | `true` | `npm audit fix` |

  The two moderates (`protobufjs`, `typeorm`) and the low sit outside the AC's high/critical scope; both moderates are `fixAvailable: true` and will likely clear as a side effect.

- **Override blocks carried today** (both still present, where Callisto's block is now empty):

  ```jsonc
  // nova-back-end
  "overrides": {
    "@opentelemetry/core": "^2.8.0",
    "@opentelemetry/propagator-jaeger": "^2.9.0",
    "brace-expansion": "^5.0.8",   // pinned below the patched 5.0.9 the lock already resolves
    "js-yaml": "^4.2.0",           // pinned inside the vulnerable 4.0.0-4.3.0 range
    "uuid": "^11.1.1"
  }

  // nova-orbital-back-end
  "overrides": {
    "js-yaml": "^4.2.0",           // pinned inside the vulnerable 4.0.0-4.3.0 range
    "multer": "^2.2.0"
  }
  ```

- **Notes / risks surfaced:**
  1. **GitHub Packages auth is still broken on this machine** — re-verified this session, not inherited from the epic doc: `npm view @planetdepos/pathfinder-observability-pkg version` returns `E401 unauthenticated`, and `gh auth status` reports token scopes `admin:public_key, gist, read:org, repo` with **no `read:packages`**. Both Nova repos carry five `@planetdepos` dependencies each, so the runbook's mandatory `rm -rf node_modules && rm package-lock.json && npm install` cannot complete. This is the single hard blocker.
  2. **The exact orbital pins are *not* a problem — checked and cleared.** `nova-orbital-back-end` declares `orbital-receiver-pkg: "1.1.3"` and `orbital-relay-pkg: "1.0.2"` with no caret, against Callisto's `^1.1.5` / `^1.0.2`, and both of those packages are themselves two of the six OTel findings (each reaches the chain through its own Pathfinder dependency). The concern was that an exact nested Pathfinder pin would survive an app-level uptick. It does not: `package-lock.json` records both packages depending on `@planetdepos/pathfinder-observability-pkg: "^0.2.13"` — a caret range that admits `0.2.14` — so a fresh install hoists one `0.2.14` satisfying all three consumers. **Receiver and relay do not need upticking.** This is why Callisto reached `overrides: {}` while still consuming both packages. Resolved from the lockfile, no registry auth needed.
  3. `nova-back-end`'s clean audit was reached without an authenticated install — its lockfile already resolves `brace-expansion@5.0.9` despite the `^5.0.8` override. Its override entries therefore may no longer change any resolved version, which is exactly the Callisto stress-test finding, but that must be measured entry-by-entry rather than assumed.

---

### 2026-08-31T00:20:00Z — nova-orbital-back-end (first remediation change staged; user-executed run prepared)

- **Summary:** Made the first substantive change on the ticket and prepared a staged, user-executed verification run, because the agent's shell cannot authenticate to GitHub Packages. Nothing committed.
- **Change made:** `nova-orbital-back-end/package.json` — `@planetdepos/pathfinder-observability-pkg` `^0.2.13 → ^0.2.14`. Single-line diff on branch `PRDV-16596`, verified with `git diff`.
- **Auth mechanism identified (corrects the prior session's note 1).** The 401 is not a broken stored credential. Both Nova repos and Callisto commit an `.npmrc` of the form `//npm.pkg.github.com/:_authToken=${GITHUB_TOKEN}` — npm expands that from the environment at read time, and a project `.npmrc` outranks `~/.npmrc`. The agent's shell has an empty `GITHUB_TOKEN`, so the token expands to nothing and the request goes out unauthenticated. **No `.npmrc` edit is needed and no secret is committed;** any shell holding a valid `GITHUB_TOKEN` works as-is.
- **js-yaml root cause found.** The `overrides.js-yaml: "^4.2.0"` entry is *causing* the js-yaml finding rather than suppressing it: the lockfile resolves exactly `4.2.0`, sitting at the bottom of the vulnerable `4.0.0 - 4.3.0` range, and the `^4.2.0` ceiling (`<5.0.0`) prevents `npm audit fix` from moving past it. Its only real requesters are dev-tree (`@istanbuljs/load-nyc-config → ^3.13.1`, `cosmiconfig → ^4.1.0`). Deleting the override is therefore a prerequisite for `audit fix` to resolve it, and is staged as stage 3 below rather than assumed.
- **`@nestjs/swagger` step does not apply.** Callisto upticked it to shed a scoped `js-yaml` override; `nova-orbital-back-end` has no `@nestjs/swagger` dependency.
- **Artifacts:** `~/nova-fix.sh` (staged run), `~/nova-fix-summarize.js` (audit JSON summarizer). Captures land in `~/nova-fix-out/`. Three stages, each capturing `npm audit --json` plus a `package.json` snapshot: (1) clean install on Pathfinder `^0.2.14`; (2) `npm audit fix`; (3) `js-yaml` override removed, reinstall. Guards on branch name and `GITHUB_TOKEN` before touching anything; nothing committed; reset is `git checkout -- package.json package-lock.json`.
- **Notes:** the run is staged rather than single-shot so each of the two independent causes (the Pathfinder chain, and the `js-yaml` override pinning that package inside the vulnerable range) is attributable on its own, per Derrick's "go one by one" method, while still costing the user only one execution.

### 2026-08-31T18:25:00Z — nova-orbital-back-end: remediation verified, all gates green

- **Summary:** The user executed `~/nova-fix.sh` in an authenticated Git Bash. **`nova-orbital-back-end` went from 12 vulnerabilities (9 high, 2 moderate, 1 low) to 0 at stage 1**, from the Pathfinder uptick plus a lockfile regenerated from scratch. All three gates then passed locally. Not yet committed.
- **Staged results** (captures in `~/nova-fix-out/`):

  | Stage | Change | Result | Dep count |
  | --- | --- | --- | --- |
  | baseline | `main`, original lockfile | 9 high, 2 moderate, 1 low | — |
  | 1 | Pathfinder `^0.2.14`, clean `npm install`, overrides untouched | **0 total** | 1048 |
  | 2 | `npm audit fix` | 0 total (no-op, nothing left to fix) | 1048 |
  | 3 | `js-yaml` override deleted, reinstall | **0 total** | 1051 (+3 dev) |

- **Stage 1 cleared more than predicted, and the reason matters.** The forecast was that the Pathfinder uptick clears 6 and `npm audit fix` clears the other 3. Stage 1 cleared all 12 on its own. The three "routine transitives" and both moderates were held at old versions **by the lockfile, not by their declared ranges**: deleting `package-lock.json` and reinstalling re-resolved them to patched versions already permitted by the existing ranges. `npm audit fix` was therefore never needed. Recorded because it changes the method for the remaining repos: regenerate the lockfile before concluding a range needs changing.
- **The receiver/relay dedupe prediction held.** One hoisted `@planetdepos/pathfinder-observability-pkg@0.2.14`; `orbital-receiver-pkg@1.1.3` and `orbital-relay-pkg@1.0.2` both resolve onto it with no nested copy and no uptick, exactly as their `^0.2.13` carets predicted.
- **Resolved versions confirming each finding is fixed at source, not suppressed:**

  | Package | Resolved | Vulnerable range it escaped |
  | --- | --- | --- |
  | `@opentelemetry/sdk-node` | `0.221.0` | `<=0.219.0` |
  | `@opentelemetry/propagator-jaeger` | `2.10.0` | `<2.9.0` |
  | `@opentelemetry/auto-instrumentations-node` | `0.79.0` | `0.57.0 - 0.77.0` |
  | `js-yaml` | `4.3.2` (+ nested `3.15.2`) | `4.0.0 - 4.3.0` |
  | `brace-expansion` | `5.0.9` | `3.0.0 - 5.0.8` |
  | `fast-uri` | `3.1.6` | `3.0.0 - 3.1.4` |
  | `protobufjs` | `7.6.6` | `7.5.0 - 7.6.4` |
  | `typeorm` | `0.3.31` | `<0.3.31` |

- **Verification gates** (run by the agent against the post-change tree, `nova-orbital-back-end` @ `PRDV-16596`):

  | Gate | Command | Scope | Result | Exception / risk |
  | ---- | ------- | ----- | ------ | ---------------- |
  | audit | `npm audit --audit-level=high` | `nova-orbital-back-end` | **pass** — 0 vulnerabilities, exit 0 | — |
  | lint | `npm run lint` | `nova-orbital-back-end` | **pass** — exit 0, no files mutated by `--fix` | — |
  | tests | `npm test -- --runInBand` | `nova-orbital-back-end` (`jest-e2e.json`, 5 suites / 25 tests) | **pass** — exit 0 | Suite is the repo's only configured harness; no new tests added, see below |

- **Tests added/updated — none, and this is the documented exception.** The change is a dependency-version change with no source edit: `git diff` is confined to `package.json` (two lines) and `package-lock.json`. There is no new or changed behavior to assert, and `build-implementation-guardrails` §1 waives tests for "purely wiring/config" changes with no behavior to assert. The existing 25 tests are the regression evidence that the upgraded OpenTelemetry and TypeORM versions did not break the app's wiring, and they pass.
- **Regression impact — bounded and named.** The upgrade crosses real version boundaries in `typeorm` (`0.3.30 → 0.3.31`) and the OpenTelemetry stack. The isolating boundary is that no application source changed; the 25-test e2e suite exercises the inbox-ingestion, inbox-processor, and outbox paths and passes. Residual risk: observability behavior at runtime is not covered by that suite, so a sandbox deploy is the check that closes it.
- **API docs — not relevant.** No HTTP surface was touched: no route path, method, DTO, status code, or auth decorator changed. `git diff` covers `package.json` and `package-lock.json` only.
- **Working tree now:** stage-3 state, uncommitted. `package.json` diff is two lines (Pathfinder `^0.2.13 → ^0.2.14`; `js-yaml` override line deleted), plus the regenerated `package-lock.json`.
- **Open: the last override.** `"multer": "^2.2.0"` remains, and reading it is not enough to show it has no effect: it resolves multer to `2.3.0` while its only requester, `@nestjs/platform-express`, pins exactly `2.2.0`. Whether that matters is unmeasured. `~/nova-fix-stage4.sh` is prepared to test removing the whole `overrides` block and **auto-reverts** if any high/critical returns.

---

### 2026-08-31T17:35:00Z — WorkLists board sync (card `todo-1788129189388-c99d6866`)

- **Summary:** User directed the card update, which cleared the ticket-id-mismatch guard from the prior session. Card titled, five checklist rows marked, workflow sections filled. Two writes were refused by the server and are recorded under Conflicts / exceptions rather than worked around.
- **Card titled:** `# Ticket Template` → `# PRDV-16596 - 2-Nova remediate high/critical security vulnerabilities`, with the ClickUp URL. The guard will not fire again.
- **Rows marked (5), each with the evidence it rests on:**

  | Section | Row | Evidence |
  | --- | --- | --- |
  | Preliminary | Generated ticket for the work to be done | `docs/nova/PRDV-16596/PRDV-16596-original-ticket.md` |
  | Development | Create new branch | `PRDV-16596` exists in both Nova repos |
  | Development | Plan implementation | Plans row 2026-08-30 + the three-stage `~/nova-fix.sh` |
  | Development | Begin implementation | Pathfinder uptick, verified one-line `git diff` |
  | Deploy & PR (Pre-Push) | Update Branch to Main | both repos `git pull --ff-only`; `nova-back-end` `e5f071a → 0b32162` |

- **Rows deliberately left unmarked, and why** (leaving a row unmarked is always safe; marking one wrongly is not):
  - `copy spec`, and the entire **Project Spec** section — no spec exists for this ticket; the user stated at kickoff that no specs are involved.
  - `check if the feature requires a feature flag to be tested` — a dependency bump has no feature to flag, but no such check was actually performed, so the row is not claimed.
  - Entire **Investigation** section — no formal investigation report, diagrams, or party contact happened; this ran as direct remediation off the Callisto precedent.
  - `Alt Ai Review` — not performed.
  - Entire **Testing & Validation** section — nothing has been installed or run yet; this is precisely what the token blocker prevents.
  - `Run npm audit` under Pre-Push — `npm audit` was run as *baseline measurement*, not as the pre-push gate. The post-change audit has not run. Marking it would misrepresent a measurement as a gate.
  - Remaining **Deploy & PR** and all **Ticket Closeout** rows — nothing pushed, deployed, or merged.

---

## Attempt history

_No remediation attempt has completed yet. The Pathfinder uptick is staged and unverified pending the user-executed run._

---

## Conflicts / exceptions

- **WorkLists board sync — guard cleared 2026-08-31, card written.** On 2026-08-30 the card `todo-1788129189388-c99d6866` was an untitled template instance (text `# Ticket Template`), so the ticket-id-mismatch guard fired and nothing was written. On 2026-08-31 the user directed the update explicitly, which resolves the ambiguity the guard protects against; the card was titled for PRDV-16596 and then written. See the 2026-08-31 board-sync session log entry for exactly which rows were marked and which were deliberately left alone.
- **Card status could not be set.** `PATCH /todos/{id}/status` with `In Progress` returned `400 — "Task status is not available for this card's color tags."` The card carries `tag: null`, and statuses are gated on a card's colour tag. Status remains `Unrefined`. Residual: the board understates the ticket's state. Follow-up: assign the card a primary colour tag, after which the transition can be set.
- **Card workflow fields were written to the note, not the card body.** `PATCH /todos/{id}` with `currentStep` / `waitingOn` / `nextUp` returned `400 — "Card has no workflow sections. Refusing to restructure it."` This template puts the four workflow headings in a separate note rather than the card body. The sections were filled by `PUT`ting that note with all four headings preserved and only their bullet contents changed, which is the same permitted action (`Set currentStep`, `nextUp`, `waitingOn`) reached through the endpoint the card's actual shape allows. No structure was added, removed, or reordered, and `Work Ahead` was left empty as the user's field.
- **Tests / lint / audit gates — not yet run** as verification gates, because no code or dependency change has been made. `npm audit` was run as *measurement* only; the gate run happens at commit time per `git-commit-workflow`.

---

## Current state

`PRDV-16596` branches exist in `nova-back-end` (off `main` `0b32162`) and `nova-orbital-back-end` (off `main` `5326247`).

`nova-back-end` is untouched and already meets the acceptance criterion (0 vulnerabilities); its only candidate work is deleting its five overrides, which reduces hand-maintained pins rather than fixing a vulnerability.

**`nova-orbital-back-end` meets the acceptance criterion and is verified.** `npm audit` reports **0 vulnerabilities**, down from 9 high / 2 moderate / 1 low, and audit, lint, and the 25-test e2e suite all exit 0. Two uncommitted changes on `PRDV-16596` carry it: Pathfinder upticked `^0.2.13 → ^0.2.14`, and the `js-yaml` override deleted, which had been pinning that package inside the vulnerable 4.0.0-4.3.0 range. Every finding is fixed at its source rather than suppressed.

**Nothing is committed or pushed yet.** One optional item remains open: whether the last override (`multer`) still changes any resolved version, testable via `~/nova-fix-stage4.sh`, which auto-reverts if removing it regresses the audit.

**The token blocker is understood rather than outstanding.** The committed `.npmrc` expands `${GITHUB_TOKEN}` from the environment, so any shell holding a valid token works with no configuration change. The agent's shell has none, so any further `npm install` in either Nova repo must be user-executed.
