# sayslate-pass-reasoning — SaySlate Per-Pass Reasoning Handoff

## Source documents

| Role | Document |
| --- | --- |
| Origin | [sayslate-pass-reasoning-original-ticket.md](./sayslate-pass-reasoning-original-ticket.md) |
| Requirements | [sayslate-pass-reasoning-requirements.md](./sayslate-pass-reasoning-requirements.md) |
| Decisions | [sayslate-pass-reasoning-decisions.md](./sayslate-pass-reasoning-decisions.md) |

## Why this work exists

The user wants to choose whether each AI pass uses reasoning ([origin](./sayslate-pass-reasoning-original-ticket.md), message 1: "the ability to select 'use reasoning' when actually doing the output"). Their first pass is for grammar fixes and their second is for coherence, so they want a separate on/off toggle for each pass's prompt, with the second pass's beside its existing enable toggle. The setting applies only to LM Studio, where it can be sent in the payload, and goes on every request that goes through it ([origin](./sayslate-pass-reasoning-original-ticket.md), message 2).

## Recommended delivery order

```text
SAYREASON-01  Dispatcher sends the reasoning setting to LM Studio
     |
     v
SAYREASON-02  Per-pass reasoning switches  <--  SAYSTAT-01 (status-badge handoff) merged first
     |
     v
SAYREASON-02A  Remove the reasoning listener guards (SAYREASON-02 audit F3)
     |
     v
SAYREASON-01A  Stream Custom passes and time out on silence (REQ-004, found after merge)
```

| Wave | Tickets | Parallel? | Purpose |
| --- | --- | --- | --- |
| 1 | [SAYREASON-01](./tickets/SAYREASON-01.md) | No | Give the dispatcher a `reasoning` input that only Custom (LM Studio) requests use. |
| 2 | [SAYREASON-02](./tickets/SAYREASON-02.md) | No | Add the two switches, store them, and pass each pass's setting from both surfaces. |
| 3 | [SAYREASON-02A](./tickets/SAYREASON-02A.md) | No | Give the app-dictation fixture the four reasoning ids and remove the listener guards they forced (SAYREASON-02 audit F3). Starts from `origin/main` after SAYREASON-02 merges. |
| 4 | [SAYREASON-01A](./tickets/SAYREASON-01A.md) | No | Stream Custom passes and restart the timeout whenever data arrives, so a long reasoning pass is not reported as timed out (REQ-004, LD-007). Starts from `origin/main` at `753a5b1`. |

4 tickets in 4 waves. SAYREASON-02A was added from the SAYREASON-02 audit (F3) and depends on SAYREASON-02 merging. SAYREASON-01A was added after the user's live check (REQ-004): a reasoning pass exceeded SAYREASON-01's inherited 90 s adapter timeout. SAYREASON-02 uses SAYREASON-01's `reasoning` input (LD-003). It also waits for the status-badge handoff's SAYSTAT-01 to merge, because both change `app.js` and `CHANGELOG.md`. SAYREASON-01 shares no file with SAYSTAT-01, so it can run while SAYSTAT-01 is in flight.

**Confirmed:** Dustin Thomason, 2026-09-24. He directed the orchestrating agent to start this work in a separate worktree while SAYSTAT-01 is in flight, and to merge once SAYSTAT-01 completes.

## Agent dispatch and merge rules

1. **Dispatch prompt.** The orchestrating agent sends the implementation agent, verbatim, this handoff's *Resolved and unresolved work*, *Rules for every low-reasoning implementation agent*, *Required evidence for every ticket*, and *Compact Audit Trail Output Rule* sections, followed by the complete ticket file. The agent reads only these and the documents the ticket cites.
2. **Base.**
   - SAYREASON-01 starts from `origin/main` at `668a10fee66d513615a19972778b19019770fbc5`, or a verified fast-forward successor that contains no reasoning change. A successor that includes SAYSTAT-01's merge is acceptable.
   - SAYREASON-02 starts from `origin/main` only after both SAYREASON-01 and SAYSTAT-01 have been reviewed, merged, and pushed.
3. **Isolation.**
   - The branch prefix is `agent` and the worktree root is `C:\SaySlate-worktrees`.
   - Each ticket gets its own fresh SaySlate worktree, on branch `agent/<bare-ticket-slug>` at `C:\SaySlate-worktrees\<bare-ticket-slug>`. The ticket header supplies only the bare slug.
   - A ticket never uses `C:\SaySlate`, the orchestrating agent's checkout, or another ticket's worktree. The existing `sayai-*` and `saystat-*` worktrees belong to other handoffs and are not touched.
   - A branch or worktree collision is a blocker: never delete, reset, or reuse it.
4. **No overlapping concurrency.** This handoff has no parallel waves, and only one of its tickets runs at a time. SAYREASON-01 may run alongside the status-badge handoff's SAYSTAT-01 because their owned files do not overlap. SAYREASON-02 never runs alongside SAYSTAT-01. SAYREASON-01A may run alongside the status-badge handoff's SAYSTAT-01A: their only shared file is `CHANGELOG.md`, where each adds a line to `[Unreleased]`. If the second merge conflicts there, the orchestrating agent keeps both lines unchanged and records the resolution in the audit.
5. **Testing.** Before reporting, the implementation agent runs every command below and records each exact command and its result:
   - `node tests/verify.mjs`
   - `node --check <file>` for every changed `.js` and `.mjs` file
   - the ticket's exit gate
   - `git diff --check`
6. **Manual and live checks.**
   - **SAYREASON-01:** no manual check. It has no UI, and its scenarios read the real request body.
   - **SAYREASON-02:** the implementation agent runs the loaded-extension check with EV-024's Playwright, from an uncommitted scratch script kept outside the worktree.
     - Launch with `chromium.launchPersistentContext`, passing `--disable-extensions-except=<worktree>` and `--load-extension=<worktree>`, and open the extension's `app.html`.
     - Open the prompt panel and screenshot it in light and dark themes.
     - Turn a reasoning switch on, reload the page, confirm the switch is still on, and save the screenshots outside the repository.
     - No provider credential, endpoint, or token is entered, so the check involves no runtime secret.
   - **SAYREASON-01A:** the implementation agent runs the ticket's live check against the Chrome machine's LM Studio (`http://127.0.0.1:1234/v1`, no credential) from an uncommitted scratch script kept outside the worktree.
   - **After SAYREASON-02 merges:** the user reloads the installed extension and runs one pass with that pass's reasoning switch off and one with it on, through their Custom (LM Studio) profile.
     - The orchestrating agent records the LM Studio log's `reasoning_tokens` for each run (0 when off, above 0 when on) in the SAYREASON-02 audit record.
     - The user enters no credential into any artifact.
     - This observation does not block merge: EV-005 already establishes that LM Studio honors the field, and the ticket's scenarios prove the payload.
7. **Commit and push.** The implementation agent commits only its owned SaySlate files and pushes its ticket branch. It never merges.
   - That ticket's sole assigned writer updates its checklist and objectives in place in this `C:\dustin-thomason\docs\SaySlate\tickets\sayslate-pass-reasoning\` folder.
   - The orchestrating agent validates those documentation updates and commits them separately.
8. **Review and merge.** The orchestrating agent reviews the exact commit:
   - confirms it descends from the wave base;
   - inspects every changed file against exclusive ownership;
   - traces the real request path;
   - reruns the gates and validates the exit gate;
   - writes the audit record.

   It merges into `main` only when no in-scope finding is unresolved, then pushes `main` to `origin` and confirms the next wave's prerequisites. After SAYREASON-02 merges, it updates the "Reasoning (thinking)" section of `C:\dustin-thomason\docs\tailscale\sayslate-lmstudio-endpoint.md` to describe the per-pass switches (LD-006).
9. **No stacking.** Later waves start from the updated `origin/main`. An implementation agent never builds on another ticket's unmerged branch.
10. **Collisions.** A ticket that needs a file another ticket owns stops and records the file, symbol, and reason. It never widens its own scope.
11. **Notification.** After pushing and before reporting, and before asking any blocking question, run:
    `powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\dustin-thomason\scripts\notify-agent-complete.ps1" -Status "Completed" -Message "<agent name> completed <ticket ID>"`.

## Resolved and unresolved work

- **Resolved** means all of the following hold:
  - the change exists in the ticket's owned production file, and the evidence points to that code;
  - verification exercises the real `aiProviderClient.js` dispatcher and the real OpenAI-compatible adapter (or, in the Floating Slate test, the adapter-boundary fake that EV-019 describes), started from a real user action or storage change on the surface being tested;
  - that verification asserts the `reasoning_effort` the request actually carries.

  The switches' appearance and persistence are Resolved only with SAYREASON-02's loaded-extension screenshots.
- A passing test proves only what it exercises. It counts toward Resolved only when the ticket shows that it crosses the path the standard names.
- **Correctable within the ticket's ownership:** the orchestrating agent records the finding as `F<n>` in the ticket's audit record, adds an empty `### F<n> — <title>` objective to the ticket, and dispatches the same branch again. The ticket stays unmerged.
- **Needs other ownership, or found after merge:** the orchestrating agent creates the next lettered ticket after the one that caused it (for example `SAYREASON-01A`), adds it to the delivery order, and records the dependency.
- **Needs user authority or an external environment:** the objective stays Unresolved and names what it depends on. The agent sends the completion notification and stops only that path. No agent invents a decision or claims completion.
- Resolved, superseded, and rejected findings stay in their original record. They are never deleted or moved.

## Rules for every low-reasoning implementation agent

- [ ] Read the complete dispatch prompt and the target repo's agent instructions before editing. SaySlate has no repository-local instruction file (EV-022).
- [ ] Display the ticket's checklist in chat before editing, and update it as work proceeds.
- [ ] Confirm the assigned branch, worktree, starting commit, clean tracked state, and the exact files the ticket owns.
- [ ] Make no remote change beyond pushing the ticket branch (dispatch rule 7).
- [ ] Make no architectural decision the ticket omits. Stop and report the exact missing decision instead of improvising.
- [ ] Change only the ticket's owned files. If another file is required, stop and record the file, symbol, and reason.
- [ ] Follow the implementation conventions in requirements EV-017 through EV-023.
- [ ] Record any material departure from the requirements' evidence, and the constraint that forced it. Make no unrequested improvements.
- [ ] Avoid formatting churn, dependency changes, broad cleanup, and speculative abstractions.
- [ ] Run the dispatch rules' gate commands and `git diff --check`.
- [ ] Inspect the complete diff for unrelated edits, debug output, dead code, and duplicate mechanisms.
- [ ] Check a checklist item, exit-gate condition, or objective only with evidence. Otherwise leave it unchecked and write the reason after it.
- [ ] Commit only the ticket's owned files, and confirm the worktree is clean afterwards.
- [ ] Send the completion notification per dispatch rule 11.
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

### SAYREASON-01 audit

- **Status:** Merged
- **Reviewed commit:** `75555e3ae19516eac8ef10eefcb9d1f73a19535e` (review 1)
- **Required evidence:** Complete in the implementation report; starting commit `668a10fee66d513615a19972778b19019770fbc5`, branch `agent/sayreason-01-dispatcher-reasoning`, worktree `C:\SaySlate-worktrees\sayreason-01-dispatcher-reasoning`, pushed to `origin/agent/sayreason-01-dispatcher-reasoning`
- **Independent verification:** `git merge-base --is-ancestor 668a10f 75555e3` true; one commit. Traced the request path: `generate` gains `reasoning = false` (`aiProviderClient.js:52`), used only in the `OPENAI_CHAT_COMPLETIONS` case to choose `"medium"`/`"none"` for Custom and `undefined` for OpenAI (`:100-105`); `adapterArgs` (`:78-88`) is unchanged, so the Gemini and Anthropic adapters receive the same arguments. The six new scenarios run the real registry, adapters, and dispatcher in `node:vm` against a fake `fetch` and assert the parsed request body. The test diff removes no line, so the existing assertions are unmodified. Running the new test file against the base `aiProviderClient.js` (scratch copy) fails at scenario 7 (`actual: 'none'`, `expected: 'medium'`), so the scenarios detect the change. Reran `node tests/verify.mjs` (exit 0), `node --check aiProviderClient.js`, `node --check tests/ai-provider-client.test.mjs`, and `git diff --check 668a10f..HEAD`; all passed
- **Scope verdict:** Pass. Only `aiProviderClient.js` (+6/−3) and `tests/ai-provider-client.test.mjs` (+172) changed, both owned. The ticket's "Other providers unchanged" Value claimed byte-for-byte identical requests, which is more than the scenarios assert; the orchestrator corrected it to the asserted fact
- **Correctness verdict:** Pass. Residual risk: the Gemini and Anthropic scenarios assert only that no field is added, not full body equality; the unchanged `adapterArgs` covers the rest by construction
- **Merge verdict:** Merged — no in-scope findings. Held, per the user's direction (Confirmed line), until SAYSTAT-01's merge `0e1b26bdb201da9a52c1ce04b761d730a799b79b` reached `origin/main`, then merged on top of it. After the merge, `node tests/verify.mjs` and `node --check aiProviderClient.js` on `main` passed
- **Merged commit:** `a1688338cee39aa536be12d9e56daa204e9fe40e` (`--no-ff` into `main`, pushed to `origin/main`)

| Finding | File and symbol/line evidence | Required disposition | Resolution |
| --- | --- | --- | --- |

### SAYREASON-02 audit

- **Status:** Merged
- **Reviewed commit:** `542fa4a113fc9598b4279e71b8c2b9fd23e9b0db` (review 2); review 1 was `05090dd588960cf79211b9ff03409b61afc60697`
- **Required evidence:** Complete in the review 1 report; starting commit `a1688338cee39aa536be12d9e56daa204e9fe40e`, branch `agent/sayreason-02-pass-reasoning-switches`, worktree `C:\SaySlate-worktrees\sayreason-02-pass-reasoning-switches`, pushed to `origin`. The report records one departure, the listener guards (F3). The ticket's checklist and objectives were not updated in place (F2)
- **Independent verification:** Review 1: `git merge-base --is-ancestor a168833 05090dd` true; one commit. `git diff --stat a168833..HEAD` lists the 8 owned files; `aiProviderClient.js`, `openAICompatibleClient.js`, `floating.html`, `floating.css`, `tests/verify.mjs`, and `tests/app-dictation-integration.test.mjs` are unchanged. The owned test diffs remove only harness lines (the full-page fixture's id list, Floating Slate's no-op `onChanged`, and its `buildEnvironment` return), no assertion. Traced both surfaces: `runFirstPass`/`runSecondPass` pass `processingConfig.<pass>Reasoning` and Floating Slate's two `generate` calls pass `config.<pass>Reasoning`; these are Floating Slate's only `generate` calls, so Finish and the ChatGPT send use them. Orchestrator probes (scratch copies of the worktree): replacing `runFirstPass`'s `reasoning` with `false` fails `tests/ai-provider-ui.test.mjs`; replacing Floating Slate's second-pass `reasoning` with `false`, or dropping `firstPassReasoning` from its `normalizeConfig`, fails `tests/floating-dictation-integration.test.mjs`. Removing the pass clicks from the full-page Reload and Second-pass-off scenarios leaves both passing (F1). Read all 4 screenshots: both switches show in light and dark themes, and "Reasoning on" for the first pass survives the reload. Reran `node tests/verify.mjs` (exit 0), `node --check` on the 4 changed `.js`/`.mjs` files, and `git diff --check a168833..HEAD`; all passed. Review 2: `542fa4a` fast-forwards `05090dd` and changes only `tests/ai-provider-ui.test.mjs`. `lastChatCompletionsBody` is gone; `reasoningEffortForNextChatCompletion` asserts exactly one new `/chat/completions` call per action and reads that call. Rerunning the review 1 probes (Reload first-pass click removed; Second-pass-off second-pass click removed) now fails both with `this action must issue exactly one new /chat/completions request`. The ticket file's checklist, exit gate, and objectives are filled; the orchestrator compacted the F1 Value to one sentence. Reran `node tests/verify.mjs` (exit 0), `node --check` on the 4 changed files, and `git diff --check a168833..HEAD`; all passed. After the merge, `node tests/verify.mjs`, `node --check app.js`, and `node --check floating.js` on `main` passed
- **Scope verdict:** Pass — only owned files changed. The guards (F3) are in an owned file but exist only because a file outside the ownership lacks the new ids
- **Correctness verdict:** Pass. Production behavior matches LD-002 through LD-006. Residual risk: LM Studio's handling of `"medium"` is proven by EV-005, not yet by a SaySlate run with a switch on (the post-merge user check in dispatch rule 6)
- **Merge verdict:** Merged — F1 and F2 resolved; F3 routed to SAYREASON-02A, which does not block this merge
- **Merged commit:** `d99088446df2239dbb19aacff1180065e875a9e1` (`--no-ff` into `main`, pushed to `origin/main`)
- **Post-merge user validation:** Pending — one Custom (LM Studio) pass with its reasoning switch off and one with it on; record each run's `reasoning_tokens`

| Finding | File and symbol/line evidence | Required disposition | Resolution |
| --- | --- | --- | --- |
| F1 — Full-page reasoning assertions read a shared call log | `tests/ai-provider-ui.test.mjs` `lastChatCompletionsBody` reads the last `/chat/completions` call in `fetchImpl.__calls`, which every scenario shares. With the pass clicks removed, the Reload and Second-pass-off scenarios still pass (orchestrator probe) | Correctable within ownership: before each pass action in the new full-page reasoning scenarios, record the call count; afterwards assert exactly one new `/chat/completions` call and read `reasoning_effort` from that call | Resolved in `542fa4a` (review 2 probes fail as required) |
| F2 — Ticket file not updated in place | `tickets/SAYREASON-02.md`: every checkbox is unchecked and every objective is blank at review 1; the objectives appear only in the report | Correctable within ownership: update the ticket's checklist, exit gate, and objectives in place (dispatch rule 7), including the F1 objective | Resolved at review 2 |
| F3 — Reasoning listeners guarded for an out-of-ownership fixture | `app.js` listener wiring: `if (firstPassReasoningInput)` / `if (secondPassReasoningInput)`. No other listener in `app.js` is guarded, and `openPromptSettings`/`savePromptSettings` use the same elements unguarded. The guards exist because the `ELEMENT_IDS` fixture in `tests/app-dictation-integration.test.mjs` lacks the four new ids, and SAYREASON-02 must not change that file | Needs other ownership: [SAYREASON-02A](./tickets/SAYREASON-02A.md) adds the ids to that fixture and removes both guards, after SAYREASON-02 merges | Resolved by SAYREASON-02A, merged `753a5b1` |

### SAYREASON-02A audit

- **Status:** Merged
- **Reviewed commit:** `807e2e821803c09f6830c462f03eacbdbfe4c791` (review 1)
- **Required evidence:** Complete in the implementation report; starting commit `d99088446df2239dbb19aacff1180065e875a9e1`, branch `agent/sayreason-02a-reasoning-listener-guards`, worktree `C:\SaySlate-worktrees\sayreason-02a-reasoning-listener-guards`, pushed to `origin`
- **Independent verification:** `git merge-base --is-ancestor d990884 807e2e8` true; one commit. The diff changes exactly the two guarded lines in `app.js`, now unguarded `addEventListener` calls, and appends the four ids with a `// SAYREASON-02:` comment to `ELEMENT_IDS` in `tests/app-dictation-integration.test.mjs`; no other line changes. `node tests/verify.mjs` passes with the guards removed, so the fixture now supplies the elements `app.js` wires. `git grep` for the guard pattern in `app.js` returns nothing. Reran `node tests/verify.mjs` (exit 0), `node --check app.js`, `node --check tests/app-dictation-integration.test.mjs`, and `git diff --check d990884..HEAD`; all passed. After the merge, `node tests/verify.mjs` and `node --check app.js` on `main` passed
- **Scope verdict:** Pass — only the owned lines changed
- **Correctness verdict:** Pass — resolves SAYREASON-02 audit F3
- **Merge verdict:** Merged — no in-scope findings
- **Merged commit:** `753a5b10411b321e1adfa859134564d6197cb418` (`--no-ff` into `main`, pushed to `origin/main`)

| Finding | File and symbol/line evidence | Required disposition | Resolution |
| --- | --- | --- | --- |

### SAYREASON-01A audit

- **Status:** Merged
- **Reviewed commit:** `8b9c8dad8bab34ebe9da84552696478153940385` (review 1)
- **Required evidence:** Complete in the implementation report; starting commit `753a5b10411b321e1adfa859134564d6197cb418`, branch `agent/sayreason-01a-stream-custom-passes`, worktree `C:\SaySlate-worktrees\sayreason-01a-stream-custom-passes`, pushed to `origin`
- **Independent verification:** `git merge-base --is-ancestor 753a5b1 8b9c8da` true; one commit; `git diff --stat` lists the 6 owned files. The test diffs remove only the three dispatcher Custom fakes (now SSE, as EV-030 required) and one fake comment; no assertion. Traced the path: the dispatcher adds `stream: true` for Custom only, outside `adapterArgs`; the adapter adds `stream: true` to the structured body only, restarts the timer after `fetch` resolves and after every `reader.read()`, reads SSE only when `content-type` is `text/event-stream`, and otherwise uses the unchanged JSON path. The retry body is unchanged. Orchestrator probes (scratch copies): removing the per-chunk timer restart fails the slow-but-steady scenario with `request_timeout`; removing the dispatcher's `stream` fails `tests/ai-provider-client.test.mjs`. Reran the live check against the Chrome machine's LM Studio (`google/gemma-4-12b-qat`, 5 s limit): the streamed dispatcher call resolved with validated text after 37.0 s, and the same request non-streamed rejected with `request_timeout` after 5.0 s. Reran `node tests/verify.mjs` (exit 0), `node --check` on the 5 changed `.js`/`.mjs` files, and `git diff --check 753a5b1..HEAD`; all passed
- **Scope verdict:** Pass — only owned files changed
- **Correctness verdict:** Pass. Accepted without a finding: `isEventStream` tolerates a response without `headers.get`. No test depends on it (the suite passes with it removed), and it only routes such a response to the existing JSON path. Residual risk: streaming through Tailscale Serve to the LM Studio host is not yet observed; if Serve buffered the stream, a pass over 90 s would still time out. The user's rerun of a long reasoning pass covers it
- **Merge verdict:** Merged — no in-scope findings. SAYSTAT-01A had merged first (`7e3e7b9`); `git merge-tree` showed no conflict, and both `[Unreleased]` lines are present in the merged `CHANGELOG.md`. After the merge, `node tests/verify.mjs`, `node --check aiProviderClient.js`, and `node --check openAICompatibleClient.js` on `main` passed
- **Merged commit:** `cd0a82a22afd6c8ac92507c4c35b754fa7770ae3` (`--no-ff` into `main`, pushed to `origin/main`)
- **Post-merge user validation:** Pending — rerun, through the installed extension and the LM Studio host, a pass with reasoning on that previously timed out

| Finding | File and symbol/line evidence | Required disposition | Resolution |
| --- | --- | --- | --- |
