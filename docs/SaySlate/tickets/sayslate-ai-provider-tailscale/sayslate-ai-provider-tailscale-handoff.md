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
| 6 | [SAYAI-06](./tickets/SAYAI-06.md) | No | Prove the private Tailscale/LM Studio path and close the feature honestly. |

There are six tickets in six waves. They are sequential because adjacent tickets consume the
provider contract established by the prior wave, and settings, manifest, transport, and UI routing
must not be reconciled independently by low-reasoning agents.

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
   path, reruns the gates, validates the exit gate, writes the audit record, and merges only when no
   in-scope finding is unresolved. It then confirms the next wave's prerequisite.
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

### SAYAI-02 audit

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

### SAYAI-03 audit

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

### SAYAI-04 audit

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
