# SAYAI-01 — Provider profile storage and migration

**Handoff:** [sayslate-ai-provider-tailscale-handoff.md](../sayslate-ai-provider-tailscale-handoff.md)
**Serves:** REQ-002, REQ-003, REQ-009–REQ-016
**Depends on:** Nothing
**May run in parallel with:** Nothing
**Branch slug:** `sayai-01-provider-profiles`
**Exclusive production ownership:** `aiProviderSettings.js`, `tests/ai-provider-settings.test.mjs`, `tests/verify.mjs`
**Must not change:** `app.js`, `floating.js`, HTML/CSS, `manifest.json`, provider transports, dictation, prompts, or the legacy setting before migration is invoked

## Goal

Implement the provider-state boundary fixed by LD-014, LD-023, LD-028, and LD-030 for REQ-002 and REQ-003.
Multiple profiles must survive switching independently, while EV-002's legacy Gemini configuration
remains migratable without rewriting UI or network behavior in this ticket.

## Build checklist

- [x] Implement LD-023's exact version-1 record and `SaySlateAIProviderSettings` public operations as
  a classic global module following EV-025 and LD-028.
- [x] Enforce LD-014's installation-local, provider-scoped persistence boundary without sync or a
  native credential host.
- [x] Implement LD-023's explicit `retain`, `replace`, and `clear` credential actions and active-
  profile behavior.
- [x] Implement LD-023's migration from EV-002's `sayslate-grammar-config` Gemini key/model fields
  into one profile with LD-030's move semantics, without changing prompt fields.
- [x] Reject unsupported or malformed stored versions without overwriting the stored record, as
  fixed by LD-023.
- [x] Test the production module through a realistic `chrome.storage.local` fake: create at least two
  profiles, switch repeatedly, reload, replace one key, clear one key, and prove the other profile is
  byte-for-byte unchanged.
- [x] Test migration twice and prove it creates exactly one Gemini profile and preserves legacy
  prompts.
- [x] Prove LD-030: after migration the legacy record holds no `apiKey` or `model`; deleting the
  migrated profile, or clearing its credential, then reloading and migrating again recreates nothing.
- [x] Add the focused test through EV-026's discovery harness without dependencies, per LD-028.

## Exit gate

- [x] Switching or saving one provider cannot erase another provider's endpoint, model, or key.
- [x] Reloading the settings module from storage restores every profile and the active-profile ID.
- [x] Legacy Gemini settings migrate once without changing prompt content.
- [x] A deleted or credential-cleared migrated profile is never recreated, and no legacy copy of the
  key remains (LD-030).
- [x] Credentials remain only in `chrome.storage.local`; no log, sync, DOM, or native-host path is
  introduced.
- [x] `node tests/ai-provider-settings.test.mjs`, `node tests/verify.mjs`, JavaScript syntax checks,
  and `git diff --check` pass.

## Out of scope

- Provider presets and origin permissions (SAYAI-02).
- HTTP requests, structured output, connection testing, or provider UI.
- Encrypting browser-local credentials or introducing a native credential host.

## Objectives

Complete every objective below in place, using the handoff's Compact Audit Trail Output Rule.
Resolved requires implemented code, direct evidence, and focused verification; intent or partial
implementation is Unresolved.

### Provider profiles persist independently
**State:** Resolved
**Value:** Creating, switching, replacing a credential, and clearing a credential on one profile never mutates another profile's endpoint, model, or key, and a full module reload from storage restores every profile plus the active-profile ID; deleting the active profile leaves no active profile. Review 1 (`d9a7303`) had this refuted by F3 (an implicit credential action silently erased a key) and F4 (a second module instance's stale in-memory read could erase a concurrently-written profile); both are fixed in `fdff8f0` — every mutator now re-reads and validates storage immediately before computing its write, and `credentialAction` is always explicit.
**Evidence:** `aiProviderSettings.js:upsertProfile`, `activateProfile`, `deleteProfile`, `clearCredential`, `fetchValidatedState`; `tests/ai-provider-settings.test.mjs` Scenario 1 (byte-for-byte isolation across replace/clear, reload restores both profiles and active ID, delete-active leaves `activeProfileId: null`), Scenario 2 (retain leaves an unrelated field edit's credential untouched), Scenario 7 (F3 — missing/unknown/blank-replace `credentialAction` all reject with zero `chrome.storage.local.set` calls and the stored profile unchanged), and Scenario 8 (F4 — two module instances sharing one storage fake, interleaved writes in both directions, neither erases the other's profile or active selection).

### Legacy Gemini configuration migrates safely
**State:** Resolved
**Value:** `migrateLegacyConfig` moves (not copies) `sayslate-grammar-config`'s `apiKey`/`model` into one new Gemini profile in a single `chrome.storage.local.set` alongside the rewritten legacy record, leaves every prompt field unchanged, is a no-op on a second call, and never recreates the profile after it is deleted or its credential is cleared. Review 1 (`d9a7303`) had this refuted by F1 (blank endpoint) and F2 (no activation); both are fixed in `fdff8f0` — the migrated profile carries LD-024/LD-033's Gemini preset endpoint, and becomes the active profile in that same write only when no profile was already active.
**Evidence:** `aiProviderSettings.js:migrateLegacyConfig` (`GEMINI_PRESET_ENDPOINT`, `activeProfileId: state.activeProfileId || newProfile.id`); `tests/ai-provider-settings.test.mjs` Scenario 4 (single-write move, F1 preset-endpoint assertion, F2 activation-when-none-active assertion, idempotent second call, prompts unchanged, post-delete non-recreation), Scenario 5 (post-clear-credential non-recreation), and Scenario 6 (F2 — migration leaves an already-active profile's selection untouched).

### Public storage boundary correctness
**State:** Resolved
**Value:** State only ever persists as `{ version: 1, activeProfileId, profiles }` with each profile `{ id, name, providerKind, endpoint, modelId, credential }`; a stored record that isn't that exact version-1 shape is rejected by `load()`/every mutator's `fetchValidatedState()` without any `chrome.storage.local.set` call, so a malformed/unsupported version is never overwritten. Review 1 (`d9a7303`) had exit gate 5 refuted by F5 (a `localStorage` fallback was a second, error-swallowing credential store); fixed in `fdff8f0` — `storageGet`/`storageSetEntries` now reject outright when `chrome.storage.local` is absent, with no fallback store of any kind.
**Evidence:** `aiProviderSettings.js:isValidState`, `isValidProfile`, `load`, `fetchValidatedState`, `storageGet`, `storageSetEntries`; `tests/ai-provider-settings.test.mjs` Scenario 3 (`version: 2` record rejects with zero `set` calls and the stored record unchanged) and Scenario 9 (F5 — a context with no `chrome.storage.local` rejects `load()`; the test also asserts the module source contains no `localStorage` reference).

### Scope and architecture compliance
**State:** Resolved
**Value:** Only the ticket's owned files changed across both commits (`aiProviderSettings.js`, `tests/ai-provider-settings.test.mjs`); `app.js`, `floating.js`, HTML/CSS, `manifest.json`, provider transports, dictation, and prompt fields are untouched; the module remains a dependency-free classic `globalThis` script matching `aiClient.js`/`dictationSettings.js` conventions, and its test is discovered by `tests/verify.mjs` with no added dependency.
**Evidence:** `git diff --stat af9a2f3a8cbad88c22edc094767b5cdd31f1a24e` on the final tree (two files changed, zero others touched); `aiProviderSettings.js:1` (IIFE) and its final line (`globalThis.SaySlateAIProviderSettings`); `tests/verify.mjs` run log listing `tests/ai-provider-settings.test.mjs` among 17 passed test files, both before and after the F1–F5 fix commit.

### Implementation completeness
**State:** Resolved
**Value:** Every build-checklist and exit-gate item is implemented and verified on the final tree; all four required gate commands pass. Review 1's F1–F5 findings are fixed in a second commit on the same branch/worktree (not amended), re-verified by the same four gates plus five new/expanded test scenarios covering exactly the refuted behavior.
**Evidence:** Commits `d9a7303e1fcd11e4e03538d37d11eb663c710631` (review 1, findings pending) and `fdff8f09d3db90947d6c9d867c0272fd8158a746` (F1–F5 fixed, final) on branch `agent/sayai-01-provider-profiles`, fast-forward pushed (`d9a7303..fdff8f0`); `node tests/ai-provider-settings.test.mjs` (9 scenarios pass on the final tree); `node tests/verify.mjs` (17 focused test files + manifest/asset checks pass); `node --check aiProviderSettings.js` and `node --check tests/ai-provider-settings.test.mjs` (both clean); `git diff --check af9a2f3a8cbad88c22edc094767b5cdd31f1a24e` (exit 0, before and after the fix commit).

### F1 — Migrated Gemini profile has no endpoint
**State:** Resolved
**Value:** `migrateLegacyConfig` now sets the migrated Gemini profile's `endpoint` to LD-024/LD-033's preset base URL `https://generativelanguage.googleapis.com/v1beta` instead of `""`.
**Evidence:** `aiProviderSettings.js:migrateLegacyConfig` (`endpoint: GEMINI_PRESET_ENDPOINT`), `GEMINI_PRESET_ENDPOINT` constant declaration; `tests/ai-provider-settings.test.mjs` Scenario 4, `assert.equal(firstMigration.endpoint, GEMINI_PRESET_ENDPOINT)`.

### F2 — Migration leaves no active profile
**State:** Resolved
**Value:** `migrateLegacyConfig` sets `activeProfileId` to the migrated profile in the same `chrome.storage.local.set` call only when no profile was already active (`state.activeProfileId || newProfile.id`); an existing active selection is left untouched.
**Evidence:** `aiProviderSettings.js:migrateLegacyConfig`; `tests/ai-provider-settings.test.mjs` Scenario 4 (`activeProfileId === firstMigration.id` when none was active) and Scenario 6 (`activeProfileId` stays the pre-existing OpenAI profile's ID after migration).

### F3 — Missing credential action silently erases the key
**State:** Resolved
**Value:** `upsertProfile` now requires `credentialAction` to be exactly `retain`, `replace`, or `clear`; a missing or unknown action, or a `replace` with an empty/whitespace-only credential, throws before any storage read-for-write or `chrome.storage.local.set` call. Only `clear` (directly, or via `clearCredential`) blanks a credential.
**Evidence:** `aiProviderSettings.js:upsertProfile` (`CREDENTIAL_ACTION_VALUES.has` guard, `replace` non-empty-after-trim guard, both ahead of `fetchValidatedState()`/`persistState()`); `tests/ai-provider-settings.test.mjs` Scenario 7 (five rejected calls — missing action, unknown action, empty replace, whitespace-only replace, missing action on a new profile — `storage.setCalls.length` unchanged across all of them, and the original credential/model survive).

### F4 — Stale in-memory cache overwrites other writers
**State:** Resolved
**Value:** The module no longer keeps a module-level `currentState` as the source of truth for mutations. Every mutator (`upsertProfile`, `activateProfile`, `deleteProfile`, `clearCredential`, `migrateLegacyConfig`) calls `fetchValidatedState()` — a fresh `chrome.storage.local.get` plus shape validation — immediately before computing the state it writes, so a second concurrently-open module instance (matching `background.js`'s per-click new-tab pattern) can never overwrite profiles or the active selection that another instance already persisted.
**Evidence:** `aiProviderSettings.js:fetchValidatedState` (used by every mutator in place of a cached state) and removal of the former module-level `currentState` variable; `tests/ai-provider-settings.test.mjs` Scenario 8, reproducing the orchestrator's probe shape (two `createModule` instances sharing one storage fake, interleaved `upsertProfile`/`activateProfile` calls from both sides) and asserting neither instance's write drops the other's profile or active selection.

### F5 — localStorage fallback is a second credential store
**State:** Resolved
**Value:** `storageGet` and `storageSetEntries` no longer fall back to `localStorage`; when `chrome.storage.local` is unavailable, both reject outright instead of silently persisting (and potentially losing, since the old fallback swallowed write errors) a second, unauthorized credential store.
**Evidence:** `aiProviderSettings.js:storageGet`, `storageSetEntries` (both now open with a `chrome.storage.local` presence check that rejects); `tests/ai-provider-settings.test.mjs` Scenario 9 (`load()` rejects in a context with no `chrome.storage.local`) plus a module-source assertion (`!source.includes("localStorage")`) run before any scenario executes.
