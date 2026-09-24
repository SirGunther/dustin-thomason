# whisper-model-upgrade — WhisperService Model Upgrade Handoff

## Source documents

| Role | Document |
| --- | --- |
| Origin | [whisper-model-upgrade-original-ticket.md](./whisper-model-upgrade-original-ticket.md) |
| Requirements | [whisper-model-upgrade-requirements.md](./whisper-model-upgrade-requirements.md) |
| Decisions | [whisper-model-upgrade-decisions.md](./whisper-model-upgrade-decisions.md) |

## Why this work exists

The user wants to upgrade WhisperService's model in general rather than build model selection into SaySlate. The base model works acceptably, and they want to find out whether the small model is better. They may end up with only the small model installed, or not ([origin](./whisper-model-upgrade-original-ticket.md)).

## Recommended delivery order

```text
WMODEL-01  Model catalog and `configure model`
    |
    v
WMODEL-02  Setup installs the chosen model
```

| Wave | Tickets | Parallel? | Purpose |
| --- | --- | --- | --- |
| 1 | [WMODEL-01](./tickets/WMODEL-01.md) | No | Let the service accept and switch between the two pinned models. |
| 2 | [WMODEL-02](./tickets/WMODEL-02.md) | No | Let setup download whichever model is wanted, and document the switch. |

2 tickets in 2 waves. WMODEL-02 uses WMODEL-01's `MODELS` catalog and `modelIdForConfig` (LD-003, LD-004). It also removes the legacy constants that WMODEL-01 keeps so that setup keeps working in between.

**Confirmed:** Dustin Thomason, 2026-09-24. He handed the orchestrating agent this handoff to run, with the completion notification sent when it completes, and stopped the live service for the gates.

## Agent dispatch and merge rules

1. **Dispatch prompt.** The orchestrating agent sends the implementation agent, verbatim, this handoff's *Resolved and unresolved work*, *Rules for every low-reasoning implementation agent*, *Required evidence for every ticket*, and *Compact Audit Trail Output Rule* sections, followed by the complete ticket file. The agent reads only these and the documents the ticket cites.
2. **Base.** WMODEL-01 starts from `origin/main` at `9677c12e2bfcfe3d11689c324f90281ea2b99a1e`. WMODEL-02 starts from `origin/main` after WMODEL-01 has been reviewed, merged, and pushed.
3. **Isolation.**
   - The branch prefix is `agent` and the worktree root is `C:\WhisperService-worktrees`.
   - Each ticket gets its own fresh worktree, on branch `agent/<bare-ticket-slug>` at `C:\WhisperService-worktrees\<bare-ticket-slug>`, and runs `npm ci` there first (EV-020).
   - A ticket never uses `C:\WhisperService`, which the live service runs from (EV-012), and never uses another ticket's worktree.
   - A branch or worktree collision is a blocker: never delete, reset, or reuse it.
   - **Scratch home:** every command that reads or writes a WhisperService home sets `WHISPER_SERVICE_HOME` to a scratch folder outside the worktree and outside `%LOCALAPPDATA%\WhisperService`.
   - **Live installation:** `%LOCALAPPDATA%\WhisperService` is only ever copied from, never written.
4. **No overlapping concurrency.** Dispatch exactly one ticket at a time.
5. **Testing.**
   - **Commands:** before reporting, the implementation agent runs these, in this order, and records each exact command and its result:
     1. `npm audit --audit-level=high`
     2. `npm test`
     3. `node --check <file>` for every changed `.mjs` file
     4. the ticket's exit gate
     5. `git diff --check`
   - **Port check:** before `npm test` or `npm run smoke`, confirm that nothing is listening on `127.0.0.1:8178` (`Get-NetTCPConnection -LocalPort 8178 -State Listen`).
   - **Port in use:** never stop the listening process. Record the blocker, send the notification, and stop (EV-012).
6. **Manual and live checks.**
   - **Both tickets:** the implementation agent runs its exit gate's scratch-home run.
     1. Create the home with `node scripts/setup.mjs --config-only`.
     2. Copy `%LOCALAPPDATA%\WhisperService\runtime\whisper-worker.exe` into `<home>\runtime\`. No CMake build is needed.
     3. Get the `small.en` file:
        - **WMODEL-01** downloads it with `curl -L -o <home>\models\ggml-small.en.bin https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.en.bin` and hashes it with `Get-FileHash -Algorithm SHA256`.
        - **WMODEL-02** gets it through setup.
     4. Time each smoke run with `Measure-Command`.
     - The scratch home's token is never printed, copied into an artifact, or committed.
   - **After WMODEL-02 merges:** the user switches the live installation, with the live service stopped:
     1. `npm run setup -- --model small.en --skip-build`
     2. `npm run configure -- model small.en`
     3. `npm start`, then dictates through SaySlate's Local Whisper and compares the result with `base.en`.
     - **Going back:** `npm run configure -- model base.en`, then a restart.
     - **The orchestrating agent** records the `runtime.modelPath` that `npm run configure -- show` prints, whether SaySlate reports Local Whisper as Available, and the user's verdict, in the WMODEL-02 audit record.
     - This observation does not block merge.
7. **Commit and push.** The implementation agent commits only its owned WhisperService files and pushes its ticket branch. It never merges.
   - That ticket's sole assigned writer updates its checklist and objectives in place in this `C:\dustin-thomason\docs\WhisperService\tickets\whisper-model-upgrade\` folder.
   - The orchestrating agent validates those documentation updates and commits them separately.
8. **Review and merge.**
   - **Review:** the orchestrating agent reviews the exact commit:
     - confirms it descends from the wave base;
     - inspects every changed file against exclusive ownership;
     - reruns the gates in the ticket's worktree with the port free, and validates the exit gate;
     - writes the audit record.
   - **Merge:** only when no in-scope finding is unresolved, the orchestrating agent merges into `main` in `C:\WhisperService`, while the live service is stopped, and pushes `main` to `origin`, where CI runs (EV-019).
   - **After the merge:** it tells the user the service can be restarted, and confirms the next wave's prerequisite.
9. **No stacking.** Later waves start from the updated `origin/main`. An implementation agent never builds on another ticket's unmerged branch.
10. **Collisions.** A ticket that needs a file another ticket owns stops and records the file, symbol, and reason. It never widens its own scope.
11. **Notification.** After pushing and before reporting, and before asking any blocking question, run:
    `powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\dustin-thomason\scripts\notify-agent-complete.ps1" -Status "Completed" -Message "<agent name> completed <ticket ID>"`.

## Resolved and unresolved work

- **Resolved** means all of the following hold:
  - the change exists in the ticket's owned file, and the evidence points to that code;
  - `npm test` exercises it through the exported functions or `cli.mjs`'s `main`;
  - the ticket's scratch-home run exercises the real path:
    - the real worker loads the selected `small.en` file through `serve`'s configuration path (`npm run smoke`);
    - for WMODEL-02, the real setup downloads that file and verifies it against the pinned hash.
- A passing test proves only what it exercises. It counts toward Resolved only when the ticket shows that it crosses the path the standard names.
- **Correctable within the ticket's ownership:** the orchestrating agent records the finding as `F<n>` in the ticket's audit record, adds an empty `### F<n> — <title>` objective to the ticket, and dispatches the same branch again. The ticket stays unmerged.
- **Needs other ownership, or found after merge:** the orchestrating agent creates the next lettered ticket after the one that caused it (for example `WMODEL-01A`), adds it to the delivery order, and records the dependency.
- **Needs user authority or an external environment:** the objective stays Unresolved and names what it depends on. This includes a live service holding `127.0.0.1:8178`. The agent sends the completion notification and stops only that path. No agent invents a decision or claims completion.
- Resolved, superseded, and rejected findings stay in their original record. They are never deleted or moved.

## Rules for every low-reasoning implementation agent

- [ ] Read the complete dispatch prompt and the target repo's agent instructions before editing. WhisperService has no repository-local instruction file (EV-021).
- [ ] Display the ticket's checklist in chat before editing, and update it as work proceeds.
- [ ] Confirm the assigned branch, worktree, starting commit, clean tracked state, and the exact files the ticket owns.
- [ ] Make no remote change beyond pushing the ticket branch (dispatch rule 7).
- [ ] Make no architectural decision the ticket omits. Stop and report the exact missing decision instead of improvising.
- [ ] Change only the ticket's owned files. If another file is required, stop and record the file, symbol, and reason.
- [ ] Follow the implementation conventions in requirements EV-017 through EV-021.
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

### WMODEL-01 audit

- **Status:** Accepted and merged
- **Reviewed commit:** `06adb8d85953b481a71c902f181b0842a934a35a` (review 1)
- **Required evidence:** Complete in the implementation report; starting commit `9677c12e2bfcfe3d11689c324f90281ea2b99a1e`, branch `agent/wmodel-01-model-catalog`, worktree `C:\WhisperService-worktrees\wmodel-01-model-catalog`, pushed to `origin/agent/wmodel-01-model-catalog`; no departures reported. The scratch-home run reports `small.en` hashing to EV-010's value, `configure model` refusing an absent file and keeping `small.en` selected, and two smoke runs with `"ok":true,"modelInitializations":1` (127,914 ms on `small.en`, 122,662 ms on `base.en`)
- **Independent verification:** `git merge-base --is-ancestor 9677c12 06adb8d` true; one commit; `git diff --stat 9677c12..06adb8d` lists exactly the 8 owned files. Read the full diff: `modelIdForConfig` matches file name and lowercased hash against `MODELS`, `validateConfig` calls it, `selectModel` checks id, presence, and hash with the now-exported `sha256` and returns a copy, and the `configure model` branch saves only after `selectModel` resolves. With `127.0.0.1:8178` free, reran `npm audit --audit-level=high` (0 vulnerabilities), `npm test` (26 pass, 0 fail), `node --check` on the 8 changed `.mjs` files, and `git diff --check 9677c12..HEAD`; all passed. Mutation probes, each restored afterwards: reverting health's fallback to the hard-coded name fails `tests/service.test.mjs`; removing the `modelIdForConfig` call from `validateConfig`, skipping `selectModel`'s hash check, and making `selectModel` mutate its input each fail `tests/config.test.mjs`; saving before `selectModel` fails `tests/cli.test.mjs`. `%LOCALAPPDATA%\WhisperService\config.json` SHA-256 is `65DF91E9…AFEE392`, matching the report, and its models folder still holds only `ggml-base.en.bin`. The ticket file changes only checkboxes and objectives; its line pointers did not match the reviewed commit, and the orchestrator corrected them to `constants.mjs:8-23`, `config.mjs:10-27`/`:29-55`/`:114`/`:118-128`/`:130-143`, `cli.mjs:19`/`:52-57`, and `service.mjs:74`. The scratch-home smoke runs were not repeated. After the merge, `npm test` on `main` passed (26 pass, 0 fail)
- **Scope verdict:** Pass. Only owned files changed; `scripts/setup.mjs` still imports the legacy constants, which WMODEL-02 removes
- **Correctness verdict:** Pass. Residual risk: the first `tests/cli.test.mjs` case asserts that `configure model small.en` rejects and leaves `config.json` unchanged, but not the rejection's message; the missing-file message is asserted directly on `selectModel` in `tests/config.test.mjs`
- **Merge verdict:** Merged. No in-scope findings
- **Merged commit:** `bcc5049e9fd149ba19706a7afe1003c3f7d70174` (`--no-ff` into `main`, pushed to `origin/main`)

| Finding | File and symbol/line evidence | Required disposition | Resolution |
| --- | --- | --- | --- |

### WMODEL-02 audit

Pending
