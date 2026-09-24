# SAYSTAT-01A — Full-page shortcuts follow their buttons during a pass

**Handoff:** [sayslate-status-badge-handoff.md](../sayslate-status-badge-handoff.md)
**Serves:** REQ-001, REQ-004
**Depends on:** SAYSTAT-01 (merged, `0e1b26bdb201da9a52c1ce04b761d730a799b79b`)
**May run in parallel with:** Nothing
**Branch slug:** `saystat-01a-shortcuts-during-pass`
**Exclusive production ownership:** `app.js`, `tests/app-dictation-integration.test.mjs`, `CHANGELOG.md` (`[Unreleased]` section only)
**Must not change:** `app.css`, `app.html`, `README.md`, `ROADMAP.md`, `floating.js`, `floating.css`, `floating.html`, `tests/floating-dictation-integration.test.mjs`, `tests/verify.mjs`, every other test file, the provider modules, the per-pass reasoning code and controls, the prompt text each pass sends, any button's `disabled` condition, the Ctrl+Alt+C, Ctrl+Alt+G, Ctrl+Alt+E, and Ctrl+Alt+F shortcuts, the existing "Finish workflow is still running" check, and SAYSTAT-01's LD-005 and LD-006 badge behavior

## Goal

While a full-page AI pass runs, Ctrl+Alt+D and Ctrl+Alt+X behave as their disabled buttons do and have no effect, and Ctrl+Alt+R behaves the same while the second pass runs. Each says why with the existing toast "AI processing is already running" (LD-008). With no remaining way for dictation to overlap a pass, SAYSTAT-01's LD-007 branches are removed (LD-009). This ticket must not change any other shortcut, any button's enablement, dictation outside a pass, or how passes run.

## Build checklist

- [x] In `handleShortcut` (`app.js:1420`), after the existing `finishWorkflowRunning` check and before the key dispatch, call `showToast("AI processing is already running")` and return when either holds: the key is `"d"` or `"x"` and `firstPassRunning || secondPassRunning`; or the key is `"r"` and `secondPassRunning` (LD-008; EV-025, EV-026, EV-027, EV-028).
- [x] Make the four pass result `setStatus` calls unconditional by removing their `if (!isListening)` conditions and the `LD-007` comments above them (`app.js:845,849,904,908`) (LD-009).
- [x] In `setListeningUI` (`app.js:986`), restore the dictation-stop branch to `setStatus("idle", "Ready");` by removing the `activePassLabel` branch and its `LD-007` comment. The function must read exactly as it did at `668a10fee66d513615a19972778b19019770fbc5` (LD-009).
- [x] Keep `activePassLabel` and `discardResultTranscript`'s condition. Reword the comment above `activePassLabel` (`app.js:109-111`) so it names only the discard and clear case it still serves (LD-006, LD-009).
- [x] In `tests/app-dictation-integration.test.mjs`, delete the two SAYSTAT-01 scenarios headed "Dictation during a pass" (`:962` and `:1000`). They drive the overlap LD-008 removes. Add a call counter to the harness's `navigator.clipboard.writeText` stub (`:270`), returned from `buildContext`. Then add scenarios that dispatch real README-shortcut `keydown` events through `document.dispatch("keydown", …)`, asserting the badge, the toast text (`elements.toastMessage.textContent`), and the effect:
  - [x] **Ctrl+Alt+D during "Phase 1":** `speech.__calls.start` is unchanged, the badge stays `processing` / "Phase 1", and the toast reads "AI processing is already running". After the pass settles ("Phase 1 ready"), Ctrl+Alt+D starts dictation ("Listening").
  - [x] **Ctrl+Alt+X during "Phase 1":** with a prior result shown, the transcript and the result are unchanged, the badge stays `processing` / "Phase 1", and the toast reads "AI processing is already running".
  - [x] **Ctrl+Alt+D and Ctrl+Alt+R during "Phase 2":** no dictation start, no clipboard write, the badge stays `processing` / "Phase 2", and each shows the toast. After "Phase 2 ready", Ctrl+Alt+R writes to the clipboard exactly once.
- [x] Add one line under `CHANGELOG.md` `[Unreleased]` → `### Fixed`: on the full page, Ctrl+Alt+D and Ctrl+Alt+X no longer act while an AI pass runs, and Ctrl+Alt+R no longer copies while the second pass runs, matching their buttons (EV-023).

## Exit gate

- [x] `node tests/verify.mjs` exits 0.
- [x] `node --check app.js` and `node --check tests/app-dictation-integration.test.mjs` exit 0.
- [x] `git diff --check` reports nothing.
- [x] `git grep -n -e "isListening) setStatus" -e "LD-007" -- app.js` returns no matches.
- [x] `setListeningUI` in `app.js` is identical to its form at `668a10fee66d513615a19972778b19019770fbc5`.
- [x] Apart from the two deleted "Dictation during a pass" scenarios and the clipboard counter, `git diff <starting commit>..HEAD -- tests/app-dictation-integration.test.mjs` removes no existing lines, and every other existing scenario passes unmodified.
- [x] Every new assertion follows a real user action: a dispatched `keydown` for a README shortcut, or a dispatched click on a control the page has enabled at that moment. No test calls `setStatus`, `handleShortcut`, or a pass function directly.
- [x] `git diff --stat <starting commit>..HEAD` lists only the owned files.

## Out of scope

- The other shortcuts and every button's enablement: unchanged per the ticket header.
- Floating Slate, which stays unchanged per LD-004.
- `README.md`: read-only in the requirements' scope boundary. Its shortcut descriptions stay accurate, since each still performs its button's action.

## Objectives

Complete every objective below in place, using the handoff's Compact Audit Trail Output Rule. Resolved requires implemented code, direct evidence, and focused verification; intent or partial implementation is Unresolved.

### Shortcuts blocked while a pass runs
**State:** Resolved
**Value:** Ctrl+Alt+D and Ctrl+Alt+X do nothing while either pass runs, and Ctrl+Alt+R does nothing while the second pass runs, each showing "AI processing is already running" (LD-008).
**Evidence:** `app.js:handleShortcut` (new guard after the `finishWorkflowRunning` check, before the key dispatch); `tests/app-dictation-integration.test.mjs` scenarios "Shortcuts during a pass: Ctrl+Alt+D…", "…Ctrl+Alt+X…", "…Ctrl+Alt+D and Ctrl+Alt+R…" (`node tests/verify.mjs` exit 0)

### LD-007 overlap handling removed
**State:** Resolved
**Value:** The four pass-result `setStatus` calls are unconditional, `setListeningUI` is textually identical to `668a10fee66d513615a19972778b19019770fbc5`, and no `LD-007` marker or `isListening) setStatus` remains in `app.js`.
**Evidence:** `app.js:runFirstPass`/`runSecondPass` (`setStatus("complete"/"error", …)` calls); `app.js:setListeningUI`; `git grep -n -e "isListening) setStatus" -e "LD-007" -- app.js` → no matches; `diff <(git show 668a10f:app.js | awk …) <(awk … app.js)` → identical

### Tests through real shortcut keydowns
**State:** Resolved
**Value:** Every new assertion follows a dispatched `document.dispatch("keydown", …)` for a README shortcut or a dispatched click on a currently-enabled control; no test calls `setStatus`, `handleShortcut`, or a pass function directly.
**Evidence:** `tests/app-dictation-integration.test.mjs` new scenarios (lines added after "Discard during a pass…", before the closing `console.log`); `node tests/verify.mjs` exit 0

### Scope and architecture compliance
**State:** Resolved
**Value:** Only the three owned files changed (`app.js`, `tests/app-dictation-integration.test.mjs`, `CHANGELOG.md`); no other shortcut, button-disabled condition, Floating Slate file, or `README.md`/`ROADMAP.md`/`tests/verify.mjs` was touched.
**Evidence:** `git diff --stat 753a5b10411b321e1adfa859134564d6197cb418..9301fd99700bc1400f800478e4fa7cdc5bd8fc3e` → `app.js`, `tests/app-dictation-integration.test.mjs`, `CHANGELOG.md` only

### Implementation completeness
**State:** Resolved
**Value:** All build-checklist items and exit-gate conditions are implemented and verified, including F1's fix; the branch is committed and pushed with a clean worktree.
**Evidence:** Commit `bbfba0d9397aa87f080dbc61d4ae5babe44478f2` on `agent/saystat-01a-shortcuts-during-pass`, pushed to `origin` (fast-forward of `9301fd99700bc1400f800478e4fa7cdc5bd8fc3e`); `git status --short --branch` clean post-commit

### F1 — The Ctrl+Alt+R toast assertion cannot fail
**State:** Resolved
**Value:** `elements.toastMessage.textContent` is cleared immediately before the Ctrl+Alt+R keydown in the "Ctrl+Alt+D and Ctrl+Alt+R during Phase 2" scenario, so the following assertion can only pass if that keydown itself set the toast; the mutant that removes `showToast` from the `key === "r"` branch now fails the suite.
**Evidence:** `tests/app-dictation-integration.test.mjs:1073` (`elements.toastMessage.textContent = "";` before the Ctrl+Alt+R `document.dispatch`); mutation probe — scratch export at `...\scratchpad\saystat-01a-mutant\` via `git archive HEAD` from commit `bbfba0d9397aa87f080dbc61d4ae5babe44478f2`, `key === "r"` branch's `showToast` line deleted, `node tests/app-dictation-integration.test.mjs` → exit 1 (`AssertionError: expected '' to equal 'AI processing is already running'` at test line 1079)
