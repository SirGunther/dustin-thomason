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

- [x] In `tests/app-dictation-integration.test.mjs`, add `"firstPassReasoningInput"`, `"firstPassReasoningState"`, `"secondPassReasoningInput"`, and `"secondPassReasoningState"` to `ELEMENT_IDS`, with a one-line `// SAYREASON-02: …` comment like the existing `// SAYAI-05: …` one.
- [x] In `app.js`'s listener wiring, replace `if (firstPassReasoningInput) firstPassReasoningInput.addEventListener(…)` and `if (secondPassReasoningInput) secondPassReasoningInput.addEventListener(…)` with the same `addEventListener` calls, unguarded.

## Exit gate

- [x] `node tests/verify.mjs` exits 0.
- [x] `node --check app.js` and `node --check tests/app-dictation-integration.test.mjs` exit 0.
- [x] `git diff --check` reports nothing.
- [x] `git grep -n "if (firstPassReasoningInput)\|if (secondPassReasoningInput)" -- app.js` returns nothing.
- [x] `git diff <starting commit>..HEAD -- tests/app-dictation-integration.test.mjs` changes only `ELEMENT_IDS`, and every existing scenario in that file passes unmodified.
- [x] `git diff --stat <starting commit>..HEAD` lists only `app.js` and `tests/app-dictation-integration.test.mjs`.

## Out of scope

- Any other change to the reasoning switches, their saving, or the requests they affect: SAYREASON-02.

## Objectives

Complete every objective below in place, using the handoff's Compact Audit Trail Output Rule. Resolved requires implemented code, direct evidence, and focused verification; intent or partial implementation is Unresolved.

### Fixture carries the reasoning ids
**State:** Resolved
**Value:** `ELEMENT_IDS` now includes the four reasoning-switch ids, so the fake DOM builds them exactly like the real `app.html` page (EV-016).
**Evidence:** tests/app-dictation-integration.test.mjs:34-35 (`SAYREASON-02` comment + four ids)

### Reasoning listeners wired unguarded
**State:** Resolved
**Value:** Both reasoning-switch listeners are now unconditional `addEventListener` calls, matching every other listener in the wiring block.
**Evidence:** app.js:1473-1474

### Scope and architecture compliance
**State:** Resolved
**Value:** The commit touches only the two guarded lines in `app.js` and the `ELEMENT_IDS` list in the test file; no other line, scenario, or assertion changed.
**Evidence:** `git diff --stat` (working tree, pre-commit): `app.js | 4 ++--`, `tests/app-dictation-integration.test.mjs | 4 ++-` — 2 files changed, 5 insertions(+), 3 deletions(-)

### Implementation completeness
**State:** Resolved
**Value:** All build-checklist and exit-gate items verified; branch pushed to origin.
**Evidence:** commit 807e2e821803c09f6830c462f03eacbdbfe4c791 on `agent/sayreason-02a-reasoning-listener-guards`, pushed to `origin/agent/sayreason-02a-reasoning-listener-guards`; `node tests/verify.mjs` exit 0 (24 focused test files passed); `git grep` for the guard pattern returns nothing
