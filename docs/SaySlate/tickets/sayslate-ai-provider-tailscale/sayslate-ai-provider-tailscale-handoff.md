# SaySlate AI Provider and Tailscale Integration — Handoff

## Source documents

| Role | Document |
| --- | --- |
| Origin | [Original ticket](./sayslate-ai-provider-tailscale-original-ticket.md) |
| Requirements | [Requirements](./sayslate-ai-provider-tailscale-requirements.md) |
| Decisions | [Decisions](./sayslate-ai-provider-tailscale-decisions.md) |

## Why this work exists

SaySlate needs its existing connection control expanded from one Gemini configuration to reusable
OpenAI, Anthropic Claude, Gemini, and custom-provider profiles, including private LM Studio access
through Tailscale. Users must be able to retain provider endpoints, models, and keys, test a
connection, and request structured results where the provider supports them. The requested delivery
method is one high-reasoning orchestrator managing bounded lower-reasoning implementation agents,
with durable resolved/unresolved evidence rather than relying on chat reports. See the
[original ticket](./sayslate-ai-provider-tailscale-original-ticket.md).

## Authoring and execution boundary

This complete document set was authored as one high-reasoning activity. There is no model switch,
low-reasoning stage, or handoff between foundation analysis and ticket creation. Tiering begins only
after the complete document set is committed: the high-reasoning orchestrator then dispatches each
bounded ticket to a lower-reasoning implementation agent, independently reviews the exact result,
merges or records findings, and continues without pausing for user approval unless a true unresolved
decision or external acceptance dependency blocks progress.

## Recommended delivery order

```text
SAYAI-01
   |
   v
SAYAI-02
   |
   v
SAYAI-03
   |
   v
SAYAI-04
   |
   v
SAYAI-05
   |
   v
SAYAI-06
```

| Wave | Tickets | Parallel? | Purpose |
| --- | --- | --- | --- |
| 1 | [SAYAI-01](./tickets/SAYAI-01.md) | No | Establish independent provider-profile storage and migration. |
| 2 | [SAYAI-02](./tickets/SAYAI-02.md) | No | Define provider presets and exact-origin permissions. |
| 3 | [SAYAI-03](./tickets/SAYAI-03.md) | No | Implement provider transports and canonical structured results. |
| 4 | [SAYAI-04](./tickets/SAYAI-04.md) | No | Add non-generative provider connection diagnostics. |
| 5 | [SAYAI-05](./tickets/SAYAI-05.md) | No | Integrate profiles, connection testing, and inference into both surfaces. |
| 6 | [SAYAI-06](./tickets/SAYAI-06.md) | No | **Deferred by LD-032 — do not dispatch this session.** Prove the private Tailscale/LM Studio path once the endpoint exists. |

There are six tickets in six waves. They are sequential because adjacent tickets consume the
provider contract established by the prior wave, and settings, manifest, transport, and UI routing
must not be reconciled independently by low-reasoning agents. SAYAI-06 is deferred by LD-032: this
session is complete when SAYAI-05 is reviewed, merged, and pushed.

**Confirmed:** Dustin Thomason delegated dependency-safe ticket ordering to the author on
2026-09-22; the exact order is locked by LD-019.

## Agent dispatch and merge rules

1. **Dispatch prompt.** The orchestrating agent sends the implementation agent, verbatim, this
   handoff's *Resolved and unresolved work*, *Rules for every low-reasoning implementation agent*,
   *Required evidence for every ticket*, and *Compact Audit Trail Output Rule* sections, followed by
   the complete ticket file. The agent reads only these and the documents the ticket cites.
2. **Base.** SAYAI-01 starts from `origin/main` at
   `af9a2f3a8cbad88c22edc094767b5cdd31f1a24e` or its verified fast-forward successor containing no
   feature implementation. Every later ticket starts from `origin/main` after every prior wave has
   been reviewed and merged.
3. **Isolation.** The branch prefix is `agent` and the worktree root is
   `C:\SaySlate-worktrees`. Each ticket gets its own fresh SaySlate worktree and uses
   branch `agent/<bare-ticket-slug>` at `C:\SaySlate-worktrees\<bare-ticket-slug>`, where the ticket
   header supplies only the bare slug. It never uses `C:\SaySlate`, the orchestrating agent's
   checkout, or another ticket's worktree. A branch or worktree collision is a blocker; never
   delete, reset, or reuse it.
4. **No overlapping concurrency.** This handoff has no parallel waves. Dispatch exactly one
   implementation ticket at a time.
5. **Testing.** Before reporting, the implementation agent runs every focused command named by its
   ticket, `node tests/verify.mjs`, JavaScript syntax checks for every changed JavaScript file, the
   ticket's manual/browser gate when applicable, and `git diff --check`. It records each exact
   command and result.
6. **Manual and live checks.** SAYAI-05's implementation agent runs the loaded-extension check with
   EV-032's Playwright, from an uncommitted scratch script that calls
   `chromium.launchPersistentContext` with `--disable-extensions-except=<worktree>` and
   `--load-extension=<worktree>`, using only non-secret test values; none enter a prompt, artifact,
   commit, console, or screenshot. SAYAI-06's high-reasoning orchestrator launches the extension the
   same way in a headed window, the user types the endpoint, model, and token directly into the
   extension UI, and the orchestrator records only redacted outcomes. If that environment cannot be operated, SAYAI-06 remains Unresolved rather than being
   marked complete from automated tests.
7. **Commit and push.** The implementation agent commits only its owned SaySlate files and pushes
   its ticket branch. It never merges. Ticket checklist/objective updates are written in place to
   this canonical Dustin Thomason artifact by that ticket's sole assigned writer; the orchestrator
   validates and commits those documentation updates separately.
8. **Review and merge.** The orchestrating agent reviews the exact commit: confirms it descends from
   the wave base, inspects every changed file against exclusive ownership, traces the real production
   path, reruns the gates, validates the exit gate, writes the audit record, and merges into `main`
   only when no in-scope finding is unresolved. It then pushes `main` to `origin`, so the next
   ticket's `origin/main` base includes the merge, and confirms the next wave's prerequisite.
9. **No stacking.** Later waves start from updated `origin/main`. An implementation agent never
   builds on another ticket's unmerged branch.
10. **Collisions.** A ticket that needs a file another ticket owns stops and records the file, symbol,
   and reason. It never widens its own scope.
11. **Notification.** After pushing and before reporting, and before asking any blocking question,
    run:
    `powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\dustin-thomason\scripts\notify-agent-complete.ps1" -Status "Completed" -Message "<agent name> completed <ticket ID>"`.

## Resolved and unresolved work

- A checklist item or objective becomes **Resolved** only when the production seam exists, the
  evidence points directly to it, and verification exercises the same real failure/user path.
  For SAYAI-01 through SAYAI-04, whose modules no page loads until SAYAI-05, that path is the
  module's public `globalThis` entry point — the exact call SAYAI-05 will make — exercised through
  EV-031's harness with realistic storage, fetch, and permission fakes. For SAYAI-05 and SAYAI-06 it
  is the loaded extension's user path.
- A passing synthetic test proves only that test unless the ticket explains and demonstrates why it
  crosses the production path.
- If an in-scope review finding is correctable within the same ticket ownership, the orchestrator
  records `F<n>` in that ticket's audit, adds an empty `### F<n> — <title>` objective to the ticket,
  and redispatches the same branch. It remains unmerged.
- If a finding needs different ownership or appears after merge, the orchestrator creates the next
  lettered ticket after its cause, adds it to this order without renumbering anything, and records
  the dependency. Example: live failure from SAYAI-06 becomes SAYAI-06A.
- **Before stopping on any question** — raised by an implementation agent or by itself — the
  orchestrating agent runs this question-admission gate:
  1. Write the exact question.
  2. Search `C:\SaySlate`, the origin, requirements, decisions, and `C:\Argus` for the answer, and
     record the files, symbols, or passages inspected.
  3. If those sources answer it, the agent was only being cautious: resolve it, record the sourced
     outcome as an `EV-###` or `LD-###` item, and continue without asking the user.
  4. Only if an irreducible product, risk, or authority choice remains, add the next numbered entry
     to the decisions document's register — investigation, why user input is required, and one
     recommendation — send the completion notification, and ask the user by that number.
- If user authority or an external environment is genuinely required, the objective stays
  **Unresolved**, states exactly what it depends on, sends the completion notification, and stops
  only that blocked path. No agent invents a product decision or claims completion.
- Resolved, superseded, and rejected findings remain in their original record for posterity; they
  are never deleted or moved to make the work appear cleaner.

## Rules for every low-reasoning implementation agent

- [ ] Read the complete dispatch prompt and the target repo's agent instructions before editing.
- [ ] Display the ticket's checklist in chat before editing, and update it as work proceeds.
- [ ] Confirm the assigned branch, worktree, starting commit, clean tracked state, and the exact files the ticket owns.
- [ ] Make no remote change beyond the dispatch rules' push policy.
- [ ] Make no architectural decision the ticket omits. Stop and report the exact missing decision instead of improvising.
- [ ] Change only the ticket's owned files. If another file is required, stop and record the file, symbol, and reason.
- [ ] Follow the implementation conventions in requirements EV-015, EV-025–EV-028, and EV-031.
- [ ] Record any material departure from the requirements' evidence, and the constraint that forced it. Make no unrequested improvements.
- [ ] Avoid formatting churn, dependency changes, broad cleanup, and speculative abstractions.
- [ ] Run the dispatch rules' gate commands and `git diff --check`.
- [ ] Inspect the complete diff for unrelated edits, debug output, dead code, and duplicate mechanisms.
- [ ] Check a checklist item, exit-gate condition, or objective only with evidence. Otherwise leave it unchecked and write the reason after it.
- [ ] Commit only the ticket's owned files, and confirm the worktree is clean afterwards.
- [ ] Send the completion notification per the dispatch rules.
- [ ] Stop after the commit and report. The orchestrating agent reviews and merges.

## Required evidence for every ticket

- Starting commit (full SHA)
- Branch and worktree path
- Final commit (full SHA)
- WHY: the exact ticket requirement the change addresses
- HOW: the seam changed, and why it is the narrowest allowed one
- WHAT: the resulting behavior, and the behavior explicitly preserved
- One changed-file row per file: file | owning evidence | exact reason | resulting behavior
- Exact verification commands and results
- Manual or browser check result, or the honest reason it is pending
- Final `git status --short --branch`
- Confirmation that no remote operation happened beyond the push policy

## Compact Audit Trail Output Rule

For each required objective, update only:

```md
### <Objective>
**State:** Resolved | Unresolved
**Value:** <one concise statement of what is established or still open>
**Evidence:** <direct pointer(s) only>
**Depends on:** <only if unresolved>
```

Output rules:

* `Value` should normally be one sentence.
* `Evidence` should contain pointers, not explanations of the evidence.
* Prefer `file:symbol`, `file:lines`, test name, route, commit, or artifact reference.
* Do not restate implementation history, verification procedure, reasoning, or unaffected code.
* Omit `Depends on` when resolved unless the dependency is essential to understanding the state.
* The objective should contain only enough information for a reviewer to understand the conclusion and inspect its source.

## Audit records

### SAYAI-01 audit

- **Status:** Merged
- **Reviewed commit:** `fdff8f09d3db90947d6c9d867c0272fd8158a746` (review 2); review 1 was `d9a7303e1fcd11e4e03538d37d11eb663c710631`
- **Required evidence:** Complete in both implementation reports; starting commit `af9a2f3a8cbad88c22edc094767b5cdd31f1a24e`, branch `agent/sayai-01-provider-profiles`, worktree `C:\SaySlate-worktrees\sayai-01-provider-profiles`
- **Independent verification:** Review 1: `git merge-base --is-ancestor af9a2f3 d9a7303` true; the orchestrator probe `probe01.mjs` reproduced F3 and F4. Review 2: `fdff8f0` fast-forwards `d9a7303`. Probe `probe01b.mjs` showed: no-action and blank-replace edits reject with 0 writes, key intact; interleaved writes from two instances keep `G,O,C` and the active selection; migration yields the preset endpoint, is active, and leaves only prompt keys in the legacy record; a malformed record is rejected with 0 writes; with no `chrome.storage` the module rejects. Reran `node tests/ai-provider-settings.test.mjs` (pass), `node tests/verify.mjs` (17 focused files, pass), `node --check` on both files, and `git diff --check af9a2f3 HEAD` (clean). After the merge, `node tests/verify.mjs` on `main` passed
- **Scope verdict:** Pass — only `aiProviderSettings.js` and `tests/ai-provider-settings.test.mjs` changed
- **Correctness verdict:** Pass. Residual risk: `chrome.storage.local` has no transactions, so a narrow window between read and write remains open across concurrent instances. SAYAI-05 must invoke `migrateLegacyConfig` from the full-page surface only (LD-027), so two surfaces never migrate at the same time
- **Merge verdict:** Merged — F1–F5 resolved
- **Merged commit:** `3d2ab41f17d6bcaaa14a80fe8a3b8fbe04e0d3e4` (`--no-ff` into `main`, pushed to `origin/main`)

| Finding | File and symbol/line evidence | Required disposition | Resolution |
| --- | --- | --- | --- |
| F1 — Migrated Gemini profile has no endpoint | `aiProviderSettings.js:migrateLegacyConfig` (`endpoint: ""`, line 233) | Set LD-033's Gemini preset endpoint and prove it | Resolved in `fdff8f0` — `migrateLegacyConfig` writes `GEMINI_PRESET_ENDPOINT`; test Scenario 4; probe01b |
| F2 — Migration leaves no active profile | `aiProviderSettings.js:migrateLegacyConfig` (`activeProfileId: currentState.activeProfileId`, line 240) | Activate the migrated profile in the same write when none is active (LD-033), and prove it | Resolved in `fdff8f0` — `activeProfileId: state.activeProfileId \|\| newProfile.id`; tests Scenario 4, 6; probe01b |
| F3 — Missing credential action silently erases the key | `aiProviderSettings.js:upsertProfile` line 150 defaults to `replace`; line 157 accepts blank; probe: edit `{ id, modelId }` → credential `""` | Require an explicit LD-023 action; `replace` requires a non-empty credential; reject otherwise without writing (LD-023 rejects implicit blank-key deletion) | Resolved in `fdff8f0` — explicit-action and non-empty `replace` guards before any write; test Scenario 7; probe01b (0 writes, key intact) |
| F4 — Stale in-memory cache overwrites other writers | `aiProviderSettings.js:currentState`, `persistState`, every mutator; `background.js:6-7` opens a new app tab per click; probe: tab B `activateProfile` erased tab A's profile | Each mutation reads and validates the stored record immediately before writing; prove two module instances cannot erase each other's profiles (exit gate 1) | Resolved in `fdff8f0` — `fetchValidatedState` before every mutation; test Scenario 8; probe01b (`G,O,C` retained) |
| F5 — `localStorage` fallback is a second credential store | `aiProviderSettings.js:storageGet` lines 28-33, `storageSetEntries` lines 49-56 (write errors swallowed) | Remove the fallback; fail when `chrome.storage.local` is absent (exit gate 5) | Resolved in `fdff8f0` — fallback removed, rejects without `chrome.storage.local`; test Scenario 9; probe01b |

### SAYAI-02 audit

- **Status:** Merged
- **Reviewed commit:** `16e03fa4ed1c0fcb50900d8f7ea0d9a9f02db285` (review 2); review 1 was `31e671f2d52ca9f22c4fbbc8240d129f5acacf17`
- **Required evidence:** Complete in both implementation reports. Starting commit `3d2ab41f17d6bcaaa14a80fe8a3b8fbe04e0d3e4`, branch `agent/sayai-02-provider-registry-permissions`, worktree `C:\SaySlate-worktrees\sayai-02-provider-registry-permissions`. The review 2 report gave the final SHA in short form; the orchestrator resolved it with `git rev-parse`
- **Independent verification:** Review 1: `git merge-base --is-ancestor 3d2ab41 31e671f` true. Reran all gates; all passed. Loaded-extension gesture probe (scratch `gesture-probe.mjs`, EV-032 Playwright, headless Chromium with the worktree unpacked): a gesture-free timer request rejects `This function must be called during a user gesture`; production `ensureForEndpoint` called from a real click, which awaits `contains` and then requests, passes the gesture check and reaches the permission prompt. The suspected gesture-loss defect was refuted. Review 2: `16e03fa` fast-forwards `31e671f`, and `git diff --quiet 31e671f 16e03fa -- aiProviderRegistry.js aiProviderPermissions.js manifest.json` confirms they are unchanged. Adding an uncalled stray `chrome.permissions.request(` to a scratch `git archive` export makes `node tests/verify.mjs` exit 1 with `chrome.permissions.request must be called only from inside requestOrigin.` Reran both focused tests, `node tests/verify.mjs` (19 files), `node --check` on the changed tests, and `git diff --check 3d2ab41 HEAD`; all passed. After the merge, `node tests/verify.mjs` on `main` passed
- **Scope verdict:** Pass — all changed files are owned; `host_permissions` unchanged; one `optional_host_permissions: ["https://*/*"]` entry added
- **Correctness verdict:** Pass. Carry-forward constraint: transient user activation is time-limited, so SAYAI-05 must call `ensureForEndpoint` at the start of its Save/Test click handlers, before any storage or network await
- **Merge verdict:** Merged — F1–F2 resolved
- **Merged commit:** `a394d8317082f94890884497b920c617be728c11` (`--no-ff` into `main`, pushed to `origin/main`)

| Finding | File and symbol/line evidence | Required disposition | Resolution |
| --- | --- | --- | --- |
| F1 — Exit gate 2 checked without evidence | Ticket exit gate "Custom secure endpoints are editable and persist through the SAYAI-01 profile boundary" is `[x]`; no test loads `aiProviderSettings.js` with the registry | Add a focused test that normalizes a custom HTTPS endpoint through the real registry, persists it with `SaySlateAIProviderSettings.upsertProfile`, reloads from storage, and derives the identical exact origin pattern; edit it again and prove the other profile is unchanged | Resolved in `16e03fa` — `tests/ai-provider-registry.test.mjs` Scenario 5 |
| F2 — Static assertion enforces nothing | `tests/verify.mjs` "Only ensureForEndpoint may call chrome.permissions.request" — condition `includes("chrome.permissions.request") && !includes("async function ensureForEndpoint")` is always false while `ensureForEndpoint` exists | Replace it with an assertion that fails when `chrome.permissions.request` is reachable from anything but `ensureForEndpoint`'s request helper, or remove it; misleading guards are not allowed | Resolved in `16e03fa` — `tests/verify.mjs` requestOrigin/ensureForEndpoint call-site guards; orchestrator violation probe exits 1 |

### SAYAI-03 audit

- **Status:** Merged
- **Reviewed commit:** `b0b5f02a52990ca2502f30718cb361b35fd4c7f3` (review 2); review 1 was `aaed2e4d55b0677f682e1fdccfc6ce1aff065be6`
- **Required evidence:** Complete in both implementation reports; starting commit `a394d8317082f94890884497b920c617be728c11`, branch `agent/sayai-03-provider-transports`, worktree `C:\SaySlate-worktrees\sayai-03-provider-transports`
- **Independent verification:** Review 1: `git merge-base --is-ancestor a394d83 aaed2e4` true. All 8 changed files are owned. Reran all gates; all passed. Read every adapter against LD-022, LD-025, LD-031, LD-035, and EV-033. The Gemini probe (EV-034) disproved the Gemini request and error assumptions that the green tests encoded. Review 2: `b0b5f02` fast-forwards `aaed2e4` and changes only `aiClient.js` and `tests/ai-client.test.mjs`. `git diff --quiet aaed2e4 b0b5f02 -- aiProviderClient.js openAICompatibleClient.js anthropicClient.js` confirms those are unchanged. Reran the 4 focused tests, `node tests/verify.mjs` (22 files), `node --check` on the 2 changed files, and `git diff --check a394d83 HEAD`; all passed. After the merge, `node tests/verify.mjs` on `main` passed
- **Scope verdict:** Pass — only owned files changed
- **Correctness verdict:** Pass. Residual risk: EV-034 proves Gemini accepts `responseJsonSchema` at payload validation, but a live schema-constrained Gemini generation with a real key was not exercised; the first real proof is the user's own Gemini pass after SAYAI-05
- **Merge verdict:** Merged — F1–F2 resolved
- **Merged commit:** `17f64484de236613a1958aadf03e2fb21b0371c5` (`--no-ff` into `main`, pushed to `origin/main`)

| Finding | File and symbol/line evidence | Required disposition | Resolution |
| --- | --- | --- | --- |
| F1 — Gemini schema requests are always rejected | `aiClient.js:generateStructured` sends `generationConfig.responseSchema: schema`; the canonical schema carries `additionalProperties: false`; EV-034 shows that returns 400, so every Gemini request falls through LD-031 to free text | Send `responseJsonSchema` per LD-036(1); the test asserts the exact field and the canonical schema | Resolved in `b0b5f02` — `aiClient.js:generateStructured` `responseJsonSchema`; `tests/ai-client.test.mjs` native-schema scenario |
| F2 — Invalid Gemini key is retried and misclassified | `aiClient.js:generateStructured` treats every 400 as a schema rejection; EV-034's real invalid-key envelope is 400 `API_KEY_INVALID`; `tests/ai-client.test.mjs:155` fakes auth failure as 401, a shape Gemini does not return for a bad key | Per LD-036(2), map `API_KEY_INVALID` to `authentication_failed` with no retry; test with EV-034's envelope and prove exactly one request | Resolved in `b0b5f02` — `aiClient.js:isApiKeyInvalid`; `tests/ai-client.test.mjs` `API_KEY_INVALID` scenario (`callCount === 1`) |

### SAYAI-04 audit

- **Status:** Merged
- **Reviewed commit:** `67f557e05c7bce67b200c85da52c0b46e55142bd` (review 1)
- **Required evidence:** Complete in the implementation report; starting commit `17f64484de236613a1958aadf03e2fb21b0371c5`, branch `agent/sayai-04-provider-connection-tests`, worktree `C:\SaySlate-worktrees\sayai-04-provider-connection-tests`
- **Independent verification:** `git merge-base --is-ancestor 17f6448 67f557e` true; only `aiProviderConnectionTest.js` and its focused test were added, both owned. Read the module against LD-026, LD-034, and LD-037: check order, per-kind credential requirement, read-only `hasForEndpoint`, discovery URLs and headers, Anthropic `after_id` pagination with a 10-page cap, and the status → code mapping all match. Live-endpoint probe (scratch `probe04.mjs`: the real registry, permissions, and connection-test modules in `node:vm` with real `fetch`, placeholder key `fake-probe-key`, no real credentials): Gemini, OpenAI, and Anthropic bad keys → `authentication_failed`; an unresolvable custom tailnet host → `network_error`; all 4 requests were body-less `GET`s; no message contained the key. Reran `node tests/ai-provider-connection-test.test.mjs` (pass), `node tests/verify.mjs` (23 files), `node --check` on both files, and `git diff --check 17f6448 HEAD`; all passed. After the merge, `node tests/verify.mjs` on `main` passed
- **Scope verdict:** Pass — two owned files added; `tests/verify.mjs` untouched (auto-discovery). The ticket's "Scope and architecture compliance" Value says "three owned files changed" while listing the two that did; the two-file fact is what the diff shows
- **Correctness verdict:** Pass. The agent's unpinned choice, an exhausted 10-page Anthropic cap → `model_unavailable` and `has_more` without `last_id` → `malformed_response`, is consistent with LD-026 and LD-037's mapping of "a valid list without the ID"; accepted. Residual risk: a successful discovery with a real key was not exercised live
- **Merge verdict:** Merged — no in-scope findings
- **Merged commit:** `ab937280076977f82286797192d3df1e98780b74` (`--no-ff` into `main`, pushed to `origin/main`)

| Finding | File and symbol/line evidence | Required disposition | Resolution |
| --- | --- | --- | --- |

### SAYAI-05 audit

- **Status:** Pending
- **Reviewed commit:** Pending
- **Required evidence:** Pending
- **Independent verification:** Pending
- **Scope verdict:** Pending
- **Correctness verdict:** Pending
- **Merge verdict:** Held — pending implementation and review
- **Merged commit:** Pending

| Finding | File and symbol/line evidence | Required disposition | Resolution |
| --- | --- | --- | --- |

### SAYAI-06 audit

- **Status:** Deferred by LD-032 — not dispatched this session
- **Reviewed commit:** Pending
- **Required evidence:** Pending
- **Independent verification:** Pending
- **Scope verdict:** Pending
- **Correctness verdict:** Pending
- **Merge verdict:** Held — deferred by LD-032 until the private endpoint exists
- **Merged commit:** Pending

| Finding | File and symbol/line evidence | Required disposition | Resolution |
| --- | --- | --- | --- |
