# sayslate-status-badge — SaySlate Status Badge Handoff

## Source documents

| Role | Document |
| --- | --- |
| Origin | [sayslate-status-badge-original-ticket.md](./sayslate-status-badge-original-ticket.md) |
| Requirements | [sayslate-status-badge-requirements.md](./sayslate-status-badge-requirements.md) |
| Decisions | [sayslate-status-badge-decisions.md](./sayslate-status-badge-decisions.md) |

## Why this work exists

The user asked for SaySlate's top status badge to show the current status of the process instead of only "Ready", in simple words, so they can see that the system is working ([origin](./sayslate-status-badge-original-ticket.md), message 1). They asked for this feature alone to be set up with the `agentic-handoff` skill in the SaySlate documents area ([origin](./sayslate-status-badge-original-ticket.md), message 2).

## Recommended delivery order

```text
SAYSTAT-01  Full-page badge matches Floating Slate's pass stages
     |
     v
SAYSTAT-01A Full-page shortcuts follow their buttons during a pass

SAYSTAT-02  Withdrawn before dispatch (LD-004): no dependencies, not run
```

| Wave | Tickets | Parallel? | Purpose |
| --- | --- | --- | --- |
| 1 | [SAYSTAT-01](./tickets/SAYSTAT-01.md) | No | Make the full-page badge show each AI pass as Floating Slate does, then its result. **Merged** as `0e1b26b`, 2026-09-24. |
| 2 | [SAYSTAT-01A](./tickets/SAYSTAT-01A.md) | No | Block Ctrl+Alt+D, Ctrl+Alt+X, and Ctrl+Alt+R while a pass runs, as their buttons are blocked, and remove SAYSTAT-01's now-unreachable overlap handling (LD-008, LD-009). Added after SAYSTAT-01's merge from its audit's residual risk. |
| — | [SAYSTAT-02](./tickets/SAYSTAT-02.md) | — | Withdrawn by LD-004; Floating Slate's wording stays as it is. |

2 tickets in 2 waves. SAYSTAT-01A depends on SAYSTAT-01, which is merged. SAYSTAT-02 is withdrawn and is never dispatched.

**Confirmed:** Dustin Thomason, 2026-09-24. Answering open decisions 1 and 2 withdrew SAYSTAT-02 (LD-004), which leaves SAYSTAT-01 as the only ticket and no order left to choose.

## Agent dispatch and merge rules

1. **Dispatch prompt.** The orchestrating agent sends the implementation agent, verbatim, this handoff's *Resolved and unresolved work*, *Rules for every low-reasoning implementation agent*, *Required evidence for every ticket*, and *Compact Audit Trail Output Rule* sections, followed by the complete ticket file. The agent reads only these and the documents the ticket cites.
2. **Base.** SAYSTAT-01 starts from `origin/main` at `668a10fee66d513615a19972778b19019770fbc5`, or a verified fast-forward successor that contains no status-badge change. SAYSTAT-01A starts from `origin/main` at `753a5b10411b321e1adfa859134564d6197cb418`, which contains SAYSTAT-01's merge `0e1b26b` and the per-pass reasoning handoff's merges, or a verified fast-forward successor.
3. **Isolation.**
   - The branch prefix is `agent` and the worktree root is `C:\SaySlate-worktrees`.
   - Each ticket gets its own fresh SaySlate worktree, on branch `agent/<bare-ticket-slug>` at `C:\SaySlate-worktrees\<bare-ticket-slug>`. The ticket header supplies only the bare slug.
   - A ticket never uses `C:\SaySlate`, the orchestrating agent's checkout, or another ticket's worktree. The five `sayai-*` worktrees already under the root belong to the AI-provider handoff and are not touched.
   - A branch or worktree collision is a blocker: never delete, reset, or reuse it.
4. **No overlapping concurrency.** This handoff has no parallel waves. Dispatch exactly one implementation ticket at a time.
5. **Testing.** Before reporting, the implementation agent runs every command below and records each exact command and its result:
   - `node tests/verify.mjs`
   - `node --check <file>` for every changed `.js` and `.mjs` file
   - the ticket's exit gate
   - `git diff --check`
6. **Manual and live checks.**
   - **SAYSTAT-01:** the implementation agent runs the loaded-extension check with EV-024's Playwright, from an uncommitted scratch script kept outside the worktree.
     - Launch with `chromium.launchPersistentContext`, passing `--disable-extensions-except=<worktree>` and `--load-extension=<worktree>`, and open the extension's `app.html`.
     - Under the light theme and then the dark theme (switched with the page's theme toggle), set `#statusPill`'s `data-state` and `#statusText` in the page to each state.
     - Save one screenshot per state and theme outside the repository.
     - This check covers styling only; the ticket's `node:vm` scenarios prove the state sequence.
     - No provider credential, endpoint, or token is entered, so the check involves no runtime secret.
   - **SAYSTAT-01A:** none. It changes no style or markup, and its `node:vm` scenarios drive the real `handleShortcut` with dispatched `keydown` events.
7. **Commit and push.** The implementation agent commits only its owned SaySlate files and pushes its ticket branch. It never merges.
   - That ticket's sole assigned writer updates its checklist and objectives in place in this `C:\dustin-thomason\docs\SaySlate\tickets\sayslate-status-badge\` folder.
   - The orchestrating agent validates those documentation updates and commits them separately.
8. **Review and merge.** The orchestrating agent reviews the exact commit:
   - confirms it descends from the wave base;
   - inspects every changed file against exclusive ownership;
   - traces the real user path;
   - reruns the gates and validates the exit gate;
   - writes the audit record.

   It merges into `main` only when no in-scope finding is unresolved. It then pushes `main` to `origin`, so the next ticket's `origin/main` base includes the merge, and confirms the next wave's prerequisite.
9. **No stacking.** Later waves start from the updated `origin/main`. An implementation agent never builds on another ticket's unmerged branch.
10. **Collisions.** A ticket that needs a file another ticket owns stops and records the file, symbol, and reason. It never widens its own scope.
11. **Notification.** After pushing and before reporting, and before asking any blocking question, run:
    `powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\dustin-thomason\scripts\notify-agent-complete.ps1" -Status "Completed" -Message "<agent name> completed <ticket ID>"`.

## Resolved and unresolved work

- **Resolved** means all of the following hold:
  - the change exists in the ticket's owned production file, and the evidence points to that code;
  - verification drives the real `app.js` through a real user action, a dispatched click on its button, in the repository's `node:vm` integration harness with the real provider modules loaded (EV-018);
  - that verification asserts the badge's `data-state` and label at each stage.

  Full-page styling is Resolved only with SAYSTAT-01's loaded-extension screenshots in both themes.
- A passing test proves only what it exercises. It counts toward Resolved only when the ticket shows that it crosses the path the standard names.
- **Correctable within the ticket's ownership:** the orchestrating agent records the finding as `F<n>` in the ticket's audit record, adds an empty `### F<n> — <title>` objective to the ticket, and dispatches the same branch again. The ticket stays unmerged.
- **Needs other ownership, or found after merge:** the orchestrating agent creates the next lettered ticket after the one that caused it (for example `SAYSTAT-01A`), adds it to the delivery order, and records the dependency.
- **Needs user authority or an external environment:** the objective stays Unresolved and names what it depends on. The agent sends the completion notification and stops only that path. No agent invents a decision or claims completion.
- Resolved, superseded, and rejected findings stay in their original record. They are never deleted or moved.

## Rules for every low-reasoning implementation agent

- [ ] Read the complete dispatch prompt and the target repo's agent instructions before editing. SaySlate has no repository-local instruction file (EV-022).
- [ ] Display the ticket's checklist in chat before editing, and update it as work proceeds.
- [ ] Confirm the assigned branch, worktree, starting commit, clean tracked state, and the exact files the ticket owns.
- [ ] Make no remote change beyond pushing the ticket branch (dispatch rule 7).
- [ ] Make no architectural decision the ticket omits. Stop and report the exact missing decision instead of improvising.
- [ ] Change only the ticket's owned files. If another file is required, stop and record the file, symbol, and reason.
- [ ] Follow the implementation conventions in requirements EV-016 through EV-023.
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

### SAYSTAT-01 audit

- **Status:** Accepted and merged
- **Reviewed commit:** `88284c6b6944fb3c2f168648ecd1272b0fe3d236` (review 2); review 1 was `58bb47517fe4efe4ad2e5457bc30437c00910c9a`
- **Required evidence:** Complete in the review 1 report. Starting commit `668a10fee66d513615a19972778b19019770fbc5`, branch `agent/saystat-01-full-page-pass-status`, worktree `C:\SaySlate-worktrees\saystat-01-full-page-pass-status`, pushed to `origin`. The report states no departure, but the dark-theme `complete` variant was omitted (see F1). The review 2 report is complete; final commit `88284c6b6944fb3c2f168648ecd1272b0fe3d236`, pushed as a fast-forward of `58bb475`
- **Independent verification:** Review 1: `git merge-base --is-ancestor 668a10f 58bb475` true; `git diff --name-only 668a10f 58bb475` lists only `CHANGELOG.md`, `app.css`, `app.js`, `tests/app-dictation-integration.test.mjs`. Reran `node tests/verify.mjs` (exit 0), `node --check` on both changed `.js`/`.mjs` files (exit 0), and `git diff --check 668a10f HEAD` (clean). The only removed test line is the closing `console.log`, so the prompt-construction assertions are unmodified. Orchestrator probes (scratch copies of the test file run against the worktree): `startButton.disabled` is `true` at the scenario's in-flight dictation-stop click (F2). Stopping with a real Ctrl+Alt+D keydown instead gives `processing` / "Phase 1", then "Phase 1 ready". Ctrl+Alt+X during a pass keeps `processing` / "Phase 1". A pass that fails during dictation keeps "Listening", then "Ready" on stop. Read all 8 screenshots: each state is legible and distinct from `idle` in both themes. Review 2: `git merge-base --is-ancestor 58bb475 88284c6` true. `git diff --quiet 58bb475 88284c6 -- app.js CHANGELOG.md` confirms production logic is unchanged; the diff is the `app.css` comment and `tests/app-dictation-integration.test.mjs` only. Every `startButton` click in the dictation scenarios is now preceded by a `disabled === false` assertion, and the in-flight stop uses the Ctrl+Alt+D keydown. Reran `node tests/verify.mjs` (exit 0), `node --check` on both changed files (exit 0), and `git diff --check 668a10f HEAD` (clean). Screenshots were not retaken because F1 is comment-only. After the merge, `node tests/verify.mjs` on `main` passed
- **Scope verdict:** Pass — only the four owned files changed
- **Correctness verdict:** Pass. Residual risk: Ctrl+Alt+D and Ctrl+Alt+X still act during a pass while their buttons are disabled (EV-025, EV-026). The badge now reports those overlaps correctly (LD-006, LD-007), but dictation during a first pass can still add text that the running pass does not see. Closing the shortcuts changes dictation behavior and is outside this handoff
- **Merge verdict:** Merged — F1–F2 resolved
- **Merged commit:** `0e1b26bdb201da9a52c1ce04b761d730a799b79b` (`--no-ff` into `main`, pushed to `origin/main`)

| Finding | File and symbol/line evidence | Required disposition | Resolution |
| --- | --- | --- | --- |
| F1 — Dark-theme CSS comment misstates the cascade | `app.css` comment above `html[data-theme="dark"] .status-pill[data-state="processing"]` says `complete`'s background resolves through `var(--accent-pale)` in dark. `html[data-theme="dark"] .status-pill` (`app.css:1193-1196`, specificity 0,2,1) overrides the background of every `.status-pill[data-state=…]` rule (0,2,0), for `processing` and `complete` alike, as it already does for `listening` and `error`. `#9fbcdb` carries no statement of what it is | Keep the rules. They render correctly (screenshots), and omitting a dark `complete` rule is accepted: its border and text use `var(--accent)`, which the dark palette redefines. Rewrite the comment so it states the actual cascade (border and text from the state rules; background from the dark `.status-pill` rule, as for `listening` and `error`) and what `#9fbcdb` is: a lighter tint of `#5b7fa3` for contrast on the dark surface | Resolved in `88284c6` — the comment above the dark `processing` rule is rewritten; no rule or value changed |
| F2 — In-flight dictation stop clicks a disabled button | `tests/app-dictation-integration.test.mjs`, scenario "Dictation during a pass: stopping dictation while it is still in flight shows that pass instead": `elements.startButton.dispatch("click")` while `startButton.disabled === true` (`app.js:878` via `updateTextControls`, called from `setListeningUI`; orchestrator probe). The exit-gate item "a dispatched click on a control the page has enabled at that moment" is checked without evidence | Stop dictation in that scenario with the Ctrl+Alt+D keydown (`README.md:11`), the path a user has while the button is disabled. Before each `startButton` click in the two dictation-during-a-pass scenarios and the discard-while-dictating scenario, assert that the button is enabled | Resolved in `88284c6` — the in-flight stop uses the Ctrl+Alt+D keydown; enabled assertions precede both remaining `startButton` clicks |

### SAYSTAT-01A audit

Pending

### SAYSTAT-02 audit

Withdrawn before dispatch (LD-004). No review is required.
