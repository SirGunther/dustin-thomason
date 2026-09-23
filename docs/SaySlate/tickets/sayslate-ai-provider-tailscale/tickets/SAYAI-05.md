# SAYAI-05 — Provider settings UI and runtime integration

**Handoff:** [sayslate-ai-provider-tailscale-handoff.md](../sayslate-ai-provider-tailscale-handoff.md)
**Serves:** REQ-001–REQ-005, REQ-009–REQ-016
**Depends on:** SAYAI-04 merged first
**May run in parallel with:** Nothing
**Branch slug:** `sayai-05-provider-ui-integration`
**Exclusive production ownership:** `app.html`, `app.css`, `app.js`, `floating.html`, `floating.css`, `floating.js`, `tests/app-dictation-integration.test.mjs`, `tests/floating-dictation-integration.test.mjs`, `tests/ai-provider-ui.test.mjs`, `tests/verify.mjs`
**Must not change:** Provider/profile/permission/transport module contracts, dictation behavior, prompt content, background/offscreen runtime, extension icons, or unrelated layout

## Goal

Integrate LD-023–LD-027 into SaySlate's existing connection settings and both renderer-owned AI pass
surfaces for REQ-001–REQ-005. The result must implement LD-027's management surface without losing
another profile, while preserving EV-003/EV-004's processing flows and existing dictation/prompts.

## Build checklist

- [x] Load the LD-023–LD-026 global modules before their consumers in both HTML surfaces, following
  EV-025 and LD-028.
- [x] Replace the single Gemini-only connection form with a compact provider-profile control under
  the existing connection icon; preserve the current visual system rather than redesigning it.
- [x] Implement exactly LD-027's full-page provider controls and floating-surface ownership.
- [x] Use preset endpoints as editable starting values; never overwrite a user's saved endpoint when
  switching away and back.
- [x] Enforce LD-023/LD-027 credential retain, clear, and non-reveal behavior.
- [x] Request an optional origin permission only from the user-triggered Save or Test action when the
  endpoint requires it, and surface denial without changing the active profile.
- [x] Wire LD-026's Test Connection result to the disabled/in-progress state, inline status, and
  LD-018 transient notification behavior.
- [x] Route first and second pass through LD-025's dispatcher in both full-page and floating surfaces.
- [x] Preserve the source text and last completed result on provider error; show a bounded useful
  error without secrets or raw response bodies.
- [x] Preserve both prompt fields, optional second pass, shortcuts, copy/discard, dictation, and the
  current renderer-owned request lifetime.
- [x] Invoke LD-030's migration on first load and prove the user can run the same Gemini path
  without re-entering the key, and that a deleted Gemini profile stays deleted after reload.
- [x] Test the production UI controllers with realistic DOM/storage/fetch/permissions fakes: create
  Gemini and custom profiles, switch both directions, reload, test each, run both passes, delete one,
  and prove the survivor remains unchanged.
- [x] As assigned by handoff rule 6, load the unpacked extension in local Chrome or Edge Developer
  Mode and inspect the real settings surface, focus order,
  masked credential behavior, status/toast states, and full/floating processing controls. My own
  first attempt at this stalled with no outbound network reachability in that shell; the orchestrator
  ran the same script (and its two added F1/F3/F2 probes) in an environment with working network and
  it completed. See "Integrated renderer production-path correctness" below for the full result.

## Exit gate

- [x] OpenAI, Claude, Gemini, and custom provider profiles can be selected and configured from the
  existing connection surface.
- [x] Switching, editing, testing, or deleting one profile never erases another. (Confirmed after the
  F1 fix: Clear Credential no longer corrupts the in-memory provider state for later controller calls.)
- [x] Both AI passes on both surfaces route through the active profile and return validated text. (The
  F3 fix confirmed via `check05.mjs`: a synchronous double trigger produces exactly one
  `:generateContent` request, not two.)
- [x] Connection status is specific and non-generative; inference errors preserve user work.
- [x] Dictation, prompts, shortcuts, copy/discard, and legacy Gemini migration still work. (The F2 fix
  confirmed via `race05.mjs`: an old-schema legacy record still yields exactly one migrated profile
  with the key intact, in both the old- and current-schema cases.)
- [x] Focused UI/integration tests, `node tests/verify.mjs`, JavaScript syntax checks,
  `git diff --check`, and the loaded-extension browser check all pass.

## Out of scope

- New provider contracts, fallback/failover, retry policy, background inference, or a credential host.
- Tailscale/LM Studio environment administration and live remote acceptance (SAYAI-06).
- General visual redesign or unrelated UI cleanup.

## Objectives

Complete every objective below in place, using the handoff's Compact Audit Trail Output Rule.
Resolved requires implemented code, direct evidence, and focused verification; intent or partial
implementation is Unresolved.

### Provider profiles are manageable without destructive switching
**State:** Resolved
**Value:** Save upserts-then-activates, Clear Credential and Delete touch only the selected profile, and switching profiles via the dropdown never mutates another profile's endpoint/model/credential. F1 (Clear Credential leaving `providerState` corrupted, breaking every controller call after it) was found in review and is fixed.
**Evidence:** `app.js:saveApiSettings,handleProfileSelectChange,clearCredentialHandler,deleteProfileHandler`; `tests/ai-provider-ui.test.mjs` ("Create a custom … profile: … never erases the Gemini profile", "Clear Credential blanks only …", the F1 regression block, "Delete removes only …"); real loaded-extension confirmation via `check05.mjs` ("Clear Credential inline error: (no error)").

### Both SaySlate surfaces use the active provider
**State:** Resolved
**Value:** Both `app.js` and `floating.js` resolve the active profile from storage at the start of each AI pass (`resolveActiveProfile`) and call `SaySlateAIProviderClient.generate({ profile, userPrompt })`; the floating surface reads but never manages profiles (no Save/Test/Delete controls or calls there). F3 (a synchronous double trigger issuing two real requests, on both surfaces) was found in review and is fixed by claiming the running-state guard synchronously, before the `await resolveActiveProfile()` call, and releasing it in `finally` on every path.
**Evidence:** `app.js:runFirstPass,runSecondPass`; `floating.js:runFirstPass,runSecondPass`; the F3 regression blocks in `tests/ai-provider-ui.test.mjs` and `tests/floating-dictation-integration.test.mjs`; real loaded-extension confirmation via `check05.mjs` ("generateContent requests from one double-trigger: 1").

### Existing workflows remain intact
**State:** Resolved
**Value:** Dictation (browser + Local Whisper), both prompt fields, the second-pass toggle, shortcuts, copy/discard, and the finish workflow are unchanged; `tests/app-dictation-integration.test.mjs` and `tests/floating-dictation-integration.test.mjs` pass unmodified in behavior (only the AI-call seam was updated). F2 (the startup migration race that could silently drop the legacy Gemini key on an old-schema record) was found in review and is fixed by sequencing `loadProcessingConfig` strictly after migration completes.
**Evidence:** `node tests/app-dictation-integration.test.mjs` and `node tests/floating-dictation-integration.test.mjs` both pass; the F2 regression block in `tests/ai-provider-ui.test.mjs`; real loaded-extension confirmation via `race05.mjs` (both old- and current-schema cases show exactly one migrated profile with the key present).

### Integrated renderer production-path correctness
**State:** Resolved
**Value:** `tests/ai-provider-ui.test.mjs` drives the real Save/Test/Clear/Delete handlers against the real `aiProviderRegistry.js`/`aiProviderPermissions.js`/`aiProviderSettings.js`/`aiProviderClient.js`/`aiProviderConnectionTest.js`/`openAICompatibleClient.js`/`aiClient.js` modules (only `fetch` is faked), proving profile creation, cross-profile isolation, reload persistence, Test Connection, both AI passes, and the F1/F2/F3 fixes. The equivalent real-browser proof completed via the orchestrator's `check05.mjs`/`race05.mjs`: all 13 LD-027 controls present in a logical focus order, Gemini Save → Configured, Test Connection and the first pass both correctly reported `authentication_failed` against the real Google API with a fake key (source text preserved), the custom-profile Save correctly stayed pending on the permission prompt with the page still usable, reload retained endpoint/model with a blank credential input, and no credential leaked into the DOM or console.
**Evidence:** `tests/ai-provider-ui.test.mjs` (all scenarios, including F1/F2/F3 regressions, pass); `check05.mjs` and `race05.mjs` output (see Required evidence below).

### Scope and architecture compliance
**State:** Resolved
**Value:** Only the ticket's owned files changed (`app.html`, `app.js`, `floating.html`, `floating.js`, `tests/app-dictation-integration.test.mjs`, `tests/floating-dictation-integration.test.mjs`, `tests/verify.mjs`, and the new `tests/ai-provider-ui.test.mjs`); no provider/profile/permission/transport module contract, manifest, background/offscreen file, icon, or unrelated layout was touched. Classic-script load order follows EV-025/LD-028 in both HTML surfaces.
**Evidence:** `git diff --stat ab937280076977f82286797192d3df1e98780b74` (only the eight listed files); `tests/verify.mjs` SAYAI-05 load-order assertions.

### Implementation completeness
**State:** Resolved
**Value:** Every build-checklist item and exit-gate condition is implemented and verified, including the loaded-extension browser check and the F1/F2/F3 fixes from the orchestrator's review of the first commit.
**Evidence:** Build checklist and Exit gate sections above; `node tests/verify.mjs` (24 focused test files + all static assertions pass); `check05.mjs`/`race05.mjs` real-browser confirmation.

### F1 — Clear Credential corrupts renderer state
**State:** Resolved
**Value:** `clearCredentialHandler` assigned `providerState` directly from `SaySlateAIProviderSettings.clearCredential()`'s return value, which is the updated PROFILE (per LD-023), not the `{ version, activeProfileId, profiles }` state - every later read of `providerState.profiles.find(...)` then threw. Fixed by awaiting `clearCredential()` for its effect only and reloading the real state via a separate `load()` call.
**Evidence:** `app.js:clearCredentialHandler`; `tests/ai-provider-ui.test.mjs` F1 regression block (no error, correct placeholder, and a working select/Save/Test afterward); real loaded-extension confirmation via `check05.mjs` ("Clear Credential inline error: (no error)").

### F2 — Startup race destroys the legacy key
**State:** Resolved
**Value:** `app.js` called `void loadProcessingConfig()` before, and concurrently with, the LD-038 migration IIFE; when the stored `promptSchemaVersion` was already behind `PROMPT_SCHEMA_VERSION`, `loadProcessingConfig`'s own write raced ahead of `migrateLegacyConfig`'s read and stripped `apiKey`/`model` from the legacy record before they were ever copied into a profile. Fixed by moving `loadProcessingConfig()` inside the same async IIFE, strictly after migration completes. `floating.js:loadConfig` was already correctly sequenced and is unchanged.
**Evidence:** `app.js` startup IIFE (single sequenced `await` chain); `tests/ai-provider-ui.test.mjs` F2 regression block (old-schema legacy record → exactly one migrated profile with the key, legacy record ends with no `apiKey`/`model`, prompt-schema upgrade still applies); real loaded-extension confirmation via `race05.mjs` (both old- and current-schema cases: 1 profile, migrated key present, no `apiKey`/`model` in legacy keys).

### F3 — A double trigger issues two AI requests
**State:** Resolved
**Value:** `runFirstPass`/`runSecondPass` on both surfaces awaited `resolveActiveProfile()` before claiming their running-state guard (`firstPassRunning`/`secondPassRunning` in app.js, `processing` in floating.js — which had no top-of-function reentry check at all), so a second trigger landing before that await resolved passed the guard and issued a second real request. Fixed by claiming the guard synchronously as the first statement, before any `await`, and releasing it in `finally` on every path (missing profile, error, or success).
**Evidence:** `app.js:runFirstPass,runSecondPass`; `floating.js:runFirstPass,runSecondPass` (now also guards on `processing` at entry); the F3 regression blocks in `tests/ai-provider-ui.test.mjs` and `tests/floating-dictation-integration.test.mjs`; real loaded-extension confirmation via `check05.mjs` ("generateContent requests from one double-trigger: 1").
