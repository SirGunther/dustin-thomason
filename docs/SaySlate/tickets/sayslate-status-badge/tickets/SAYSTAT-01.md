# SAYSTAT-01 — Full-page badge matches Floating Slate's pass stages

**Handoff:** [sayslate-status-badge-handoff.md](../sayslate-status-badge-handoff.md)
**Serves:** REQ-001, REQ-003
**Depends on:** Nothing
**May run in parallel with:** Nothing
**Branch slug:** `saystat-01-full-page-pass-status`
**Exclusive production ownership:** `app.js`, `app.css`, `tests/app-dictation-integration.test.mjs`, `CHANGELOG.md` (`[Unreleased]` section only)
**Must not change:** `app.html`, `floating.js`, `floating.css`, `floating.html`, `tests/floating-dictation-integration.test.mjs`, `tests/verify.mjs`, the provider modules (`aiClient.js`, `aiProvider*.js`, `openAICompatibleClient.js`, `anthropicClient.js`), the prompt text each pass sends (`app.js:712-718`), and the existing dictation labels and what triggers them ("Listening", "Retrying…", "Needs attention", "Unavailable", "Try again", "Finishing…")

## Goal

When a full-page AI pass runs, from its button, its shortcut, or the Finish workflow, the top badge shows the same stages Floating Slate shows: "Phase 1" or "Phase 2" while the pass runs (LD-003), then that pass's result, then "Ready" as LD-005 sets out. It must be legible in both themes. This ticket must not become a shared pass pipeline, a Floating Slate change (LD-004), new labels for the stop or copy steps, or a change to how passes run.

## Build checklist

- [ ] In `runFirstPass` (`app.js:740`), call `setStatus("processing", "Phase 1")` after the active profile resolves and immediately before the provider request. The missing-profile return (EV-005) then leaves the badge unchanged (LD-003, LD-005).
- [ ] In `runFirstPass`, call `setStatus("complete", "Phase 1 ready")` after the result is stored, and `setStatus("error", "Phase 1 failed")` in the failure path (LD-005).
- [ ] Apply the same three states to `runSecondPass` (`app.js:785`) with "Phase 2" (LD-003, LD-005).
- [ ] In `discardResultTranscript` (`app.js:702`), call `setStatus("idle", "Ready")` only when dictation is not running. This covers the discard button (`app.js:1389`) and `clearTranscript`, which calls it after stopping dictation (`app.js:1275`). A discard during dictation keeps "Listening" (EV-003, EV-007, LD-005).
- [ ] Add `.status-pill[data-state="processing"]` and `.status-pill[data-state="complete"]` rules, with their `.status-dot` variants, beside the existing states at `app.css:655-686`. Use `#5b7fa3` for processing and the accent color for complete (EV-013, LD-005).
- [ ] Add dark-theme variants of both states beside `app.css:1207-1219` (EV-008, LD-005).
- [ ] Add scenarios to `tests/app-dictation-integration.test.mjs` that drive the real click handlers through `buildContext` (EV-018), with an `aiResponder` whose promise the test settles. Assert `elements.statusPill.dataset.state` and `elements.statusText.textContent` at each point:
  - [ ] **First pass:** `processing` / "Phase 1" while in flight, then `complete` / "Phase 1 ready".
  - [ ] **Second pass:** `processing` / "Phase 2" while in flight, then `complete` / "Phase 2 ready".
  - [ ] **Failure:** a rejected pass ends at `error` / "Phase 1 failed", with the transcript and any prior result preserved.
  - [ ] **No active profile:** the badge still reads "Ready" and no provider request is sent.
  - [ ] **Finish, second pass enabled:** "Phase 1", then "Phase 2", observed while each is in flight, then `idle` / "Ready" after the final clear.
  - [ ] **Finish, second pass fails:** ends at `error` / "Phase 2 failed", and the transcript is not cleared.
  - [ ] **Discard:** discarding after "Phase 2 ready" gives "Ready"; discarding while dictating keeps "Listening".
- [ ] Add one line under `CHANGELOG.md` `[Unreleased]` stating that the full-page status badge now shows each AI pass as it runs, matching Floating Slate (EV-023).

## Exit gate

- [ ] `node tests/verify.mjs` exits 0.
- [ ] `node --check app.js` exits 0.
- [ ] `git diff --check` reports nothing.
- [ ] The six pass labels in `app.js` are exactly the ones Floating Slate uses: "Phase 1", "Phase 1 ready", "Phase 1 failed", "Phase 2", "Phase 2 ready", "Phase 2 failed" (EV-010).
- [ ] Every new badge assertion follows a real user action (a dispatched click). No test calls `setStatus` or replaces a pass function.
- [ ] The existing prompt-construction assertions at `tests/app-dictation-integration.test.mjs:666-675` pass unmodified.
- [ ] Loaded-extension check (handoff dispatch rule 6): screenshots of the full-page badge in `idle`, `processing`, `complete`, and `error`, in light and dark themes, show each state legibly and distinct from `idle`. Screenshot paths are reported.
- [ ] `git diff --stat <starting commit>..HEAD` lists only the owned files.

## Out of scope

- Floating Slate's badge, which stays unchanged per LD-004.
- `README.md` and `ROADMAP.md` updates: read-only in the requirements' scope boundary.
- Whisper model selection, a reasoning option, and a reconcile pass: excluded by the requirements' scope boundary.

## Objectives

Complete every objective below in place, using the handoff's Compact Audit Trail Output Rule. Resolved requires implemented code, direct evidence, and focused verification; intent or partial implementation is Unresolved.

### Pass labels while a pass runs
**State:**
**Value:**
**Evidence:**
**Depends on:**

### Result states and return to Ready
**State:**
**Value:**
**Evidence:**
**Depends on:**

### Badge styling in both themes
**State:**
**Value:**
**Evidence:**
**Depends on:**

### Tests through the real click paths
**State:**
**Value:**
**Evidence:**
**Depends on:**

### Scope and architecture compliance
**State:**
**Value:**
**Evidence:**
**Depends on:**

### Implementation completeness
**State:**
**Value:**
**Evidence:**
**Depends on:**
