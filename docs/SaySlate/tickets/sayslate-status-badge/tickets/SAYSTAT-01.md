# SAYSTAT-01 — Full-page badge matches Floating Slate's pass stages

**Handoff:** [sayslate-status-badge-handoff.md](../sayslate-status-badge-handoff.md)
**Serves:** REQ-001, REQ-003
**Depends on:** Nothing
**May run in parallel with:** Nothing
**Branch slug:** `saystat-01-full-page-pass-status`
**Exclusive production ownership:** `app.js`, `app.css`, `tests/app-dictation-integration.test.mjs`, `CHANGELOG.md` (`[Unreleased]` section only)
**Must not change:** `app.html`, `floating.js`, `floating.css`, `floating.html`, `tests/floating-dictation-integration.test.mjs`, `tests/verify.mjs`, the provider modules (`aiClient.js`, `aiProvider*.js`, `openAICompatibleClient.js`, `anthropicClient.js`), the prompt text each pass sends (`app.js:712-718`), and the existing dictation labels and what triggers them ("Listening", "Retrying…", "Needs attention", "Unavailable", "Try again", "Finishing…")

## Goal

When a full-page AI pass runs, from its button, its shortcut, or the Finish workflow, the top badge shows the same stages Floating Slate shows: "Phase 1" or "Phase 2" while the pass runs (LD-003), then that pass's result, then "Ready" as LD-005 sets out, with LD-006 and LD-007 covering a discard, clear, or dictation that overlaps a pass. It must be legible in both themes. This ticket must not become a shared pass pipeline, a Floating Slate change (LD-004), new labels for the stop or copy steps, or a change to how passes run.

## Build checklist

- [x] Add one `let` beside `firstPassRunning` (`app.js:100-102`) that holds the label of the pass whose provider request is in flight: "Phase 1", "Phase 2", or `""` when no request is in flight (LD-006, LD-007).
- [x] In `runFirstPass` (`app.js:740`), after the active profile resolves and immediately before the provider request, set that label to "Phase 1" and call `setStatus("processing", "Phase 1")`. Reset the label to `""` in the pass's `finally`. The missing-profile return (EV-005) then leaves the badge and the label unchanged (LD-003, LD-005).
- [x] In `runFirstPass`, call `setStatus("complete", "Phase 1 ready")` after the result is stored, and `setStatus("error", "Phase 1 failed")` in the failure path, each only when dictation is not running. While dictation runs, "Listening" stays (LD-005, LD-007).
- [x] Apply the same label, states, and dictation condition to `runSecondPass` (`app.js:785`) with "Phase 2" (LD-003, LD-005, LD-007).
- [x] In `discardResultTranscript` (`app.js:702`), call `setStatus("idle", "Ready")` only when dictation is not running and no pass request is in flight (the label is `""`). This covers the discard button (`app.js:1389`) and `clearTranscript`, which calls it after stopping dictation (`app.js:1275`), including Finish's final clear. A discard during dictation keeps "Listening"; a discard during a pass request keeps "Phase N" (EV-003, EV-007, EV-025, LD-005, LD-006).
- [x] In `setListeningUI` (`app.js:904-917`), where dictation stopping now sets `idle` / "Ready", set `processing` with the in-flight pass label instead when a pass request is in flight. The existing `error` check stays as it is (EV-026, LD-007).
- [x] Add `.status-pill[data-state="processing"]` and `.status-pill[data-state="complete"]` rules, with their `.status-dot` variants, beside the existing states at `app.css:655-686`. Use `#5b7fa3` for processing and the accent color for complete (EV-013, LD-005).
- [x] Add dark-theme variants of both states beside `app.css:1207-1219` (EV-008, LD-005). Note (corrected per F1): every pill's *background* in dark theme comes from `html[data-theme="dark"] .status-pill` (`app.css:1215-1218`, specificity 0,2,1), which outranks each `[data-state=...]` rule's own background (0,2,0) — true for `processing` and `complete` alike, same as `listening`/`error`. "complete" needed no override because its border-color and color are `var(--accent)`, which `:root`'s dark block already redefines. "processing" got a dark override for border-color and color only, since its light rule uses the fixed, non-variable `#5b7fa3` hue; `#9fbcdb` is a lighter tint of that hue for contrast on the dark surface. The `app.css` comment above the dark `processing` rule now states this cascade explicitly.
- [x] Add scenarios to `tests/app-dictation-integration.test.mjs` that drive the real click handlers through `buildContext` (EV-018), with an `aiResponder` whose promise the test settles. Assert `elements.statusPill.dataset.state` and `elements.statusText.textContent` at each point:
  - [x] **First pass:** `processing` / "Phase 1" while in flight, then `complete` / "Phase 1 ready".
  - [x] **Second pass:** `processing` / "Phase 2" while in flight, then `complete` / "Phase 2 ready".
  - [x] **Failure:** a rejected pass ends at `error` / "Phase 1 failed", with the transcript and any prior result preserved.
  - [x] **No active profile:** the badge still reads "Ready" and no provider request is sent.
  - [x] **Finish, second pass enabled:** "Phase 1", then "Phase 2", observed while each is in flight, then `idle` / "Ready" after the final clear.
  - [x] **Finish, second pass fails:** ends at `error` / "Phase 2 failed", and the transcript is not cleared.
  - [x] **Discard:** discarding after "Phase 2 ready" gives "Ready"; discarding while dictating keeps "Listening".
  - [x] **Discard during a pass:** with a prior result shown, clicking discard while "Phase 1" is in flight keeps `processing` / "Phase 1"; when the pass settles, `complete` / "Phase 1 ready" (EV-025, LD-006).
  - [x] **Dictation during a pass:** a Ctrl+Alt+D keydown while "Phase 1" is in flight gives "Listening" (EV-026). Then, in one scenario, settling the pass while dictating keeps "Listening", and stopping dictation afterwards gives "Ready". In another, stopping dictation while the pass is still in flight gives `processing` / "Phase 1", then `complete` / "Phase 1 ready" when it settles (LD-007).
- [x] Add one line under `CHANGELOG.md` `[Unreleased]` stating that the full-page status badge now shows each AI pass as it runs, matching Floating Slate (EV-023).

## Exit gate

- [x] `node tests/verify.mjs` exits 0.
- [x] `node --check app.js` exits 0.
- [x] `git diff --check` reports nothing.
- [x] The six pass labels in `app.js` are exactly the ones Floating Slate uses: "Phase 1", "Phase 1 ready", "Phase 1 failed", "Phase 2", "Phase 2 ready", "Phase 2 failed" (EV-010).
- [x] Every new badge assertion follows a real user action: a dispatched click on a control the page has enabled at that moment, or a dispatched `keydown` for a README shortcut (EV-026). No test calls `setStatus` or replaces a pass function. Corrected per F2: the "stopping dictation while still in flight" scenario clicked `startButton` while it was disabled (`app.js:878`, firstPassRunning true) — replaced with the same Ctrl+Alt+D keydown used to start dictation, the real path available while that button is disabled. An explicit `disabled === false` assertion was added before every remaining `startButton` click in the two dictation-during-a-pass scenarios and the discard-while-dictating scenario.
- [x] The existing prompt-construction assertions at `tests/app-dictation-integration.test.mjs:666-675` pass unmodified (content unchanged; the assertions now sit later in the file after the new scenarios were inserted above them near the end of the file).
- [x] Loaded-extension check (handoff dispatch rule 6): screenshots of the full-page badge in `idle`, `processing`, `complete`, and `error`, in light and dark themes, show each state legibly and distinct from `idle`. Screenshot paths are reported below.
- [x] `git diff --stat <starting commit>..HEAD` lists only the owned files.

## Out of scope

- Floating Slate's badge, which stays unchanged per LD-004.
- `README.md` and `ROADMAP.md` updates: read-only in the requirements' scope boundary.
- Whisper model selection, a reasoning option, and a reconcile pass: excluded by the requirements' scope boundary.

## Objectives

Complete every objective below in place, using the handoff's Compact Audit Trail Output Rule. Resolved requires implemented code, direct evidence, and focused verification; intent or partial implementation is Unresolved.

### Pass labels while a pass runs
**State:** Resolved
**Value:** Both passes set `activePassLabel` and call `setStatus("processing", "Phase N")` right before the provider request, and clear the label in `finally`; a missing profile returns before either fires.
**Evidence:** `app.js:101-104` (`activePassLabel`); `app.js:773-776,792-793` (`runFirstPass`); `app.js:832-835,851-852` (`runSecondPass`)

### Result states and return to Ready
**State:** Resolved
**Value:** Each pass reports `complete`/"Phase N ready" or `error`/"Phase N failed" only when dictation is not running; `discardResultTranscript` and `setListeningUI` return the badge to `idle`/"Ready" only when dictation is off and no pass request is in flight, otherwise they preserve "Listening" or "Phase N" (LD-005, LD-006, LD-007).
**Evidence:** `app.js:786-791,845-850` (result states); `app.js:703-711` (`discardResultTranscript`); `app.js:918-928` (`setListeningUI`)

### Badge styling in both themes
**State:** Resolved
**Value:** Light-theme `processing`/`complete` rules match Floating Slate's hues exactly (EV-013). In dark theme, background comes from the existing `html[data-theme="dark"] .status-pill` rule for every state alike (corrected per F1, not from each state's own background); `processing` additionally gets a dark border-color/color override since its hue is fixed rather than variable-driven, while `complete` needs none since its border-color/color are `var(--accent)`. Verified in the browser in both themes.
**Evidence:** `app.css:686-706` (light rules); `app.css:1243-1259` (dark rules + corrected comment); loaded-extension screenshots: `C:\Users\dktho\AppData\Local\Temp\claude\c--Users-dktho-OneDrive-SCRIPTS-ALL-SYSTEMS-To-Do-List-WorkLists\e91f5e96-c4aa-4cb8-8a72-de207439bc80\scratchpad\saystat-01\badge-{light,dark}-{idle,processing,complete,error}.png`

### Tests through the real click paths
**State:** Resolved
**Value:** All 9 required scenarios were added, each driving `buildContext`'s real click handlers or a Ctrl+Alt+D `keydown` (never `setStatus` or a pass function directly), with a deferred `aiResponder` observing the in-flight state before settling it.
**Evidence:** `tests/app-dictation-integration.test.mjs:697-960` (new scenarios, "SAYSTAT-01" section); run: `node tests/app-dictation-integration.test.mjs` — passes

### Scope and architecture compliance
**State:** Resolved
**Value:** Only the four owned files changed; `floating.js`/`floating.css`/`floating.html`/`app.html`/`tests/floating-dictation-integration.test.mjs`/`tests/verify.mjs`/provider modules/prompt text/existing dictation labels are untouched.
**Evidence:** `git diff --stat 668a10fee66d513615a19972778b19019770fbc5..HEAD` in `C:\SaySlate-worktrees\saystat-01-full-page-pass-status` lists exactly `CHANGELOG.md`, `app.css`, `app.js`, `tests/app-dictation-integration.test.mjs`

### Implementation completeness
**State:** Resolved
**Value:** Every build-checklist and exit-gate item is implemented and verified; `node tests/verify.mjs`, `node --check app.js`, and `git diff --check` all exit 0, and the six Floating-Slate-matching labels are exact.
**Evidence:** final commit `88284c6b6944fb3c2f168648ecd1272b0fe3d236` on `agent/saystat-01-full-page-pass-status` (supersedes `58bb47517fe4efe4ad2e5457bc30437c00910c9a`, held for F1/F2)

### F1 — Dark-theme CSS comment misstates the cascade
**State:** Resolved
**Value:** Rewrote the comment above the dark `processing` rule to state the real cascade: `html[data-theme="dark"] .status-pill` (0,2,1) supplies every state's background, outranking each `[data-state=...]` rule's own background (0,2,0), for `processing` and `complete` alike; only border-color/color are left for a state rule, and `complete`'s come from `var(--accent)` (redefined by the dark palette) while `processing`'s are a dedicated dark-only override. Also states what `#9fbcdb` is: a lighter tint of `#5b7fa3` for contrast on the dark surface. Comment-only change; no rule or value changed.
**Evidence:** `app.css:1243-1251` (rewritten comment, commit `88284c6`)

### F2 — In-flight dictation stop clicks a disabled button
**State:** Resolved
**Value:** The "stopping dictation while still in flight" scenario now stops dictation with the same Ctrl+Alt+D keydown used to start it, instead of a `startButton` click while that button is disabled (`app.js:878`, firstPassRunning true) — the real path a user has at that moment. Added `assert.equal(elements.startButton.disabled, false, ...)` before each of the two remaining real `startButton` clicks (the settled-during-dictation stop, and the discard-while-dictating start).
**Evidence:** `tests/app-dictation-integration.test.mjs` — "Dictation during a pass: stopping dictation while it is still in flight..." scenario (second keydown replaces the disabled click); enabled-assertions added before the `startButton` clicks in the "Ctrl+Alt+D while Phase 1 is in flight" and "Discard: ... discarding while dictating" scenarios; run: `node tests/app-dictation-integration.test.mjs` — passes; commit `88284c6`
