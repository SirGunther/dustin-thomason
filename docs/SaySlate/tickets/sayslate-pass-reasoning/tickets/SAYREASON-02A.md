# SAYREASON-02A — Remove the reasoning listener guards

**Handoff:** [sayslate-pass-reasoning-handoff.md](../sayslate-pass-reasoning-handoff.md)
**Serves:** REQ-001 (SAYREASON-02 audit F3)
**Depends on:** SAYREASON-02 merged into `origin/main`
**May run in parallel with:** Nothing
**Branch slug:** `sayreason-02a-reasoning-listener-guards`
**Exclusive production ownership:** `app.js` (only the two guarded reasoning-listener lines in its listener wiring), `tests/app-dictation-integration.test.mjs` (only its `ELEMENT_IDS` list)
**Must not change:** every other line of `app.js` and `tests/app-dictation-integration.test.mjs`, and every other file

## Goal

SAYREASON-02 wires the two reasoning switches with `if (firstPassReasoningInput) …` and `if (secondPassReasoningInput) …`. No other listener in `app.js` is guarded, and `openPromptSettings` and `savePromptSettings` use the same elements unguarded. The guards exist only because the fake DOM in `tests/app-dictation-integration.test.mjs` builds elements from an `ELEMENT_IDS` list that lacks the four new ids. `tests/verify.mjs` already requires every `#id` that `app.js` queries to exist in `app.html` (EV-016), so the real page always has them. This ticket adds the four ids to that list, following the SAYAI-05 precedent in the same list, and removes both guards so the reasoning listeners are wired like every other listener. It must not change any scenario, assertion, or other behavior.

## Build checklist

- [ ] In `tests/app-dictation-integration.test.mjs`, add `"firstPassReasoningInput"`, `"firstPassReasoningState"`, `"secondPassReasoningInput"`, and `"secondPassReasoningState"` to `ELEMENT_IDS`, with a one-line `// SAYREASON-02: …` comment like the existing `// SAYAI-05: …` one.
- [ ] In `app.js`'s listener wiring, replace `if (firstPassReasoningInput) firstPassReasoningInput.addEventListener(…)` and `if (secondPassReasoningInput) secondPassReasoningInput.addEventListener(…)` with the same `addEventListener` calls, unguarded.

## Exit gate

- [ ] `node tests/verify.mjs` exits 0.
- [ ] `node --check app.js` and `node --check tests/app-dictation-integration.test.mjs` exit 0.
- [ ] `git diff --check` reports nothing.
- [ ] `git grep -n "if (firstPassReasoningInput)\|if (secondPassReasoningInput)" -- app.js` returns nothing.
- [ ] `git diff <starting commit>..HEAD -- tests/app-dictation-integration.test.mjs` changes only `ELEMENT_IDS`, and every existing scenario in that file passes unmodified.
- [ ] `git diff --stat <starting commit>..HEAD` lists only `app.js` and `tests/app-dictation-integration.test.mjs`.

## Out of scope

- Any other change to the reasoning switches, their saving, or the requests they affect: SAYREASON-02.

## Objectives

Complete every objective below in place, using the handoff's Compact Audit Trail Output Rule. Resolved requires implemented code, direct evidence, and focused verification; intent or partial implementation is Unresolved.

### Fixture carries the reasoning ids
**State:**
**Value:**
**Evidence:**
**Depends on:**

### Reasoning listeners wired unguarded
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
