# SAYREASON-02 — Per-pass reasoning switches

**Handoff:** [sayslate-pass-reasoning-handoff.md](../sayslate-pass-reasoning-handoff.md)
**Serves:** REQ-001, REQ-002, REQ-003
**Depends on:** SAYREASON-01; SAYSTAT-01 from the [status-badge handoff](../../sayslate-status-badge/sayslate-status-badge-handoff.md)
**May run in parallel with:** Nothing
**Branch slug:** `sayreason-02-pass-reasoning-switches`
**Exclusive production ownership:** `app.html`, `app.js`, `app.css`, `floating.js`, `tests/ai-provider-ui.test.mjs`, `tests/floating-dictation-integration.test.mjs`, `CHANGELOG.md` (`[Unreleased]` section only), `README.md` ("Two user-defined passes" section only)
**Must not change:** `aiProviderClient.js`, `openAICompatibleClient.js`, the other provider modules, `floating.html`, `floating.css`, `tests/verify.mjs`, `tests/app-dictation-integration.test.mjs`, the prompt text each pass builds (`buildFirstPassPrompt` and `buildSecondPassPrompt` in `app.js`, and the inline prompts in `floating.js`'s pass functions), the second-pass Enabled switch's behavior, and the status-badge behavior SAYSTAT-01 added

Line numbers below are from `668a10f`. SAYSTAT-01 shifts `app.js`, so locate each change by the symbol named.

## Goal

The prompt panel has an independent reasoning switch for each pass (LD-004). Each switch is saved per pass in `sayslate-grammar-config` and is off by default (LD-002). Every pass on both surfaces passes its saved setting to `generate` as `reasoning` (LD-003, LD-005): the full page's buttons, shortcuts, and Finish, and Floating Slate's passes, Finish, and ChatGPT send. With both switches off, every request is identical to today's. This ticket must not change the dispatcher or adapters (SAYREASON-01), add controls to Floating Slate, add reasoning levels, or add a third pass.

## Build checklist

- [x] Add `firstPassReasoning: false` and `secondPassReasoning: false` to `DEFAULT_PROCESSING_CONFIG` in `app.js`. Add both to `normalizeProcessingConfig`, each reading `value.<field> === true`, and keep `PROMPT_SCHEMA_VERSION` at 3 (LD-002). — `app.js:13-20`, `app.js:214-221`.
- [x] In `app.html`'s prompt panel, apply LD-004's markup:
  - [x] Move the "First-pass prompt" label into a `.pass-setting-header` row holding the `firstPassReasoningState` / `firstPassReasoningInput` switch. — `app.html:177-186`.
  - [x] Add the `secondPassReasoningState` / `secondPassReasoningInput` switch to the second-pass header, beside its Enabled switch. — `app.html:194-210`.
  - [x] End both help lines with "Reasoning applies only to Custom (LM Studio) connections." — `app.html:191`, `app.html:216`.
- [x] In `app.css`, add only the rules needed to place two `.pass-toggle` switches in one header row, beside the existing switch rules (EV-011, LD-004). — `app.css` `.pass-toggle-group` (added directly above the existing `.pass-toggle` rule).
- [x] In `app.js`, apply LD-004's switch behavior:
  - [x] Query the four new elements. — `app.js:69-72`.
  - [x] Set both switches and their state words in `openPromptSettings`. — `app.js:590-593`.
  - [x] Include both values in `savePromptSettings`. — `app.js:629-630`, `app.js:648-651`.
  - [x] Give each switch a `change` listener that saves at once, following `saveSecondPassToggle`: state word, toast, and restore-on-failure message. — `app.js` `saveFirstPassReasoningToggle`/`saveSecondPassReasoningToggle`, wired at `app.js:1475-1476` (guarded; see Implementation completeness).
- [x] Pass `reasoning: processingConfig.firstPassReasoning` in `runFirstPass`'s `generate` call and `reasoning: processingConfig.secondPassReasoning` in `runSecondPass`'s (EV-012, LD-003). — `app.js` `runFirstPass`/`runSecondPass` generate calls.
- [x] In `floating.js`, add both fields to `normalizeConfig` with the same `=== true` reading, and pass the matching `reasoning` value in both `generate` calls (EV-013, LD-005). — `floating.js:45-52`, `floating.js:256-259`, `floating.js:292-299`.
- [x] Add scenarios to `tests/ai-provider-ui.test.mjs` with the Custom profile active, reading `reasoning_effort` from the recorded `/chat/completions` calls of its fake `fetch` (EV-019):
  - [x] **Defaults:** with both switches off, the first-pass and second-pass requests both carry `"none"`. — "Defaults" scenario.
  - [x] **First on, second off:** `"medium"`, then `"none"`. — "First pass on, second pass off" scenario.
  - [x] **First off, second on:** `"none"`, then `"medium"`. — "First pass off, second pass on" scenario.
  - [x] **Reload:** after a switch changes, a fresh `buildInstance` over the same storage shows the saved switch state and sends the saved value. — "Reload" scenario.
  - [x] **Second pass off:** turning it off keeps `secondPassReasoning` stored, and turning it back on sends the kept value. — "Second pass off" scenario.
  - [x] **Failed save:** when a switch's save fails, the switch shows its previous value. — "Failed save" scenario.
  - [x] **Gemini:** with the Gemini profile active and both switches on, its requests carry no `reasoning_effort`. — "Gemini" scenario.
- [x] In `tests/floating-dictation-integration.test.mjs`, add a fake `SaySlateOpenAICompatibleClient.generate` to the context that records `reasoningEffort`, next to the existing Gemini fake (EV-019). Then add scenarios with a seeded Custom profile:
  - [x] **Finish:** with `firstPassReasoning: true`, `secondPassReasoning: false`, and the second pass enabled, Finish sends `"medium"` for pass 1 and `"none"` for pass 2. — "SAYREASON-02: Finish sends each pass's own saved reasoning setting on a Custom profile" scenario.
  - [x] **Live update:** a storage change that turns `secondPassReasoning` on makes the next second pass send `"medium"`. — "SAYREASON-02: a live storage change to secondPassReasoning is used by the next second pass" scenario (added a real `chrome.storage.onChanged` listener registry + `fireStorageChange` helper to the fixture, replacing its prior no-op stub, so the scenario can actually trigger floating.js's live-update path).
- [x] In `CHANGELOG.md` `[Unreleased]`, rewrite the line at `:30` so it describes the per-pass reasoning switches, off by default, for Custom profiles (LD-006, EV-015). — `CHANGELOG.md` (rewritten `[Unreleased]` line).
- [x] In `README.md`, add one sentence after the second-pass toggle paragraph (`:40`) describing the two reasoning switches and that they apply only to Custom (LM Studio) connections (LD-006). — `README.md` (added sentence).

## Exit gate

- [x] `node tests/verify.mjs` exits 0. — run at worktree root, 24 focused test files passed.
- [x] `node --check app.js` and `node --check floating.js` exit 0.
- [x] `git diff --check` reports nothing.
- [x] The existing second-pass switch checks in `tests/verify.mjs:383-392` and every existing scenario in the two owned test files pass unmodified. — full `node tests/verify.mjs` run green; no pre-existing scenario removed or altered.
- [x] Every new assertion follows a real user action (a dispatched click, `change`, or form `submit`) or a storage change. No test calls `generate` directly or replaces a pass function. — confirmed on review 1 (F1 fix additionally binds each reasoning assertion to the exact `/chat/completions` call its own action caused, rather than the shared call log's last entry).
- [x] Loaded-extension check (handoff dispatch rule 6): the prompt panel shows both reasoning switches, in light and dark themes, and a switch turned on is still on after the page reloads. Screenshot paths are reported. — Playwright 1.61.1, `chromium.launchPersistentContext` with `--load-extension`; screenshots at `C:\Users\dktho\AppData\Local\Temp\claude\c--Users-dktho-OneDrive-SCRIPTS-ALL-SYSTEMS-To-Do-List-WorkLists\594133fd-fcf1-4098-bee6-bc488597d0a1\scratchpad\sayreason-02-browser\prompt-panel-light.png`, `...-dark.png`, `...-toggled-on.png`, `...-after-reload.png`.
- [x] `git diff --stat <starting commit>..HEAD` lists only the owned files. — 8 files (`app.html`, `app.css`, `app.js`, `floating.js`, `tests/ai-provider-ui.test.mjs`, `tests/floating-dictation-integration.test.mjs`, `CHANGELOG.md`, `README.md`), all within ownership.

## Out of scope

- The dispatcher's `reasoning` input: SAYREASON-01.
- Reasoning for OpenAI, Gemini, or Anthropic profiles: excluded by REQ-002.
- The reconcile pass and Whisper model selection: excluded by the requirements' scope boundary.
- The LM Studio endpoint doc's "Reasoning (thinking)" section: the orchestrating agent updates it after this ticket merges (LD-006).

## Objectives

Complete every objective below in place, using the handoff's Compact Audit Trail Output Rule. Resolved requires implemented code, direct evidence, and focused verification; intent or partial implementation is Unresolved.

### Per-pass reasoning stored and off by default
**State:** Resolved
**Value:** `firstPassReasoning`/`secondPassReasoning` are booleans in `sayslate-grammar-config`, default off, `=== true`-gated in both normalizers, no schema-version change.
**Evidence:** `app.js:13-20` (`DEFAULT_PROCESSING_CONFIG`), `app.js:214-221` (`normalizeProcessingConfig`); `floating.js:7-13` (`DEFAULT_CONFIG`), `floating.js:45-52` (`normalizeConfig`); `tests/ai-provider-ui.test.mjs` "Defaults" scenario.

### Reasoning switches in the prompt panel
**State:** Resolved
**Value:** Both switches render, labeled "Reasoning on/off", in light and dark themes, and each saves immediately on change with toast/restore-on-failure parity to the existing second-pass switch.
**Evidence:** `app.html:177-217`; `app.css` `.pass-toggle-group`; `app.js` `saveFirstPassReasoningToggle`/`saveSecondPassReasoningToggle`; screenshots `prompt-panel-light.png`/`prompt-panel-dark.png`/`prompt-panel-toggled-on.png` in the scratch path named in the exit gate; `tests/ai-provider-ui.test.mjs` "Failed save" scenario.

### Full-page passes send their setting
**State:** Resolved
**Value:** `runFirstPass`/`runSecondPass` pass `reasoning: processingConfig.<field>` into the real dispatcher; verified per-switch-combination against the exact `/chat/completions` call each action caused (bound via `reasoningEffortForNextChatCompletion` after the F1 fix).
**Evidence:** `app.js` `runFirstPass`/`runSecondPass` generate calls; `tests/ai-provider-ui.test.mjs` "Defaults"/"First pass on…"/"First pass off…"/"Reload"/"Second pass off"/"Gemini" scenarios.

### Floating Slate passes send their setting
**State:** Resolved
**Value:** Floating Slate's first/second pass, Finish, and (by the same shared pass functions) ChatGPT send all apply the saved per-pass switch; a live storage change reaches the next second pass via the real `chrome.storage.onChanged` listener path.
**Evidence:** `floating.js:253-259, 292-299`; `tests/floating-dictation-integration.test.mjs` "SAYREASON-02: Finish…" and "…live storage change…" scenarios.

### Documentation matches the behavior
**State:** Resolved
**Value:** `CHANGELOG.md`'s `[Unreleased]` entry and `README.md`'s second-pass-toggle paragraph both now describe the per-pass reasoning switches and their Custom (LM Studio)-only scope.
**Evidence:** `CHANGELOG.md` (rewritten `[Unreleased]` line); `README.md` (added sentence after the second-pass toggle paragraph).

### Scope and architecture compliance
**State:** Resolved
**Value:** No change to the dispatcher/adapters, no new Floating Slate controls, no reasoning levels, no third pass; only the ticket's owned files were touched across both commits.
**Evidence:** `git diff --stat a1688338..542fa4a` (8 files, all owned); `aiProviderClient.js`/`openAICompatibleClient.js`/`floating.html`/`floating.css` untouched.

### Implementation completeness
**State:** Resolved
**Value:** Every build-checklist and exit-gate item is implemented and verified, with one documented, narrowly-scoped departure: two listener-wiring lines in `app.js` are guarded (`if (firstPassReasoningInput) …`, `if (secondPassReasoningInput) …`) because `tests/app-dictation-integration.test.mjs` is out of this ticket's ownership and its `ELEMENT_IDS` fixture predates the four new ids, so the unconditional form threw inside that file. `openPromptSettings`/`savePromptSettings` use the same elements unguarded elsewhere in `app.js`, since that file's scenarios never reach those code paths. This departure is routed as its own finding (handoff audit F3) to [SAYREASON-02A](./SAYREASON-02A.md), which adds the ids to that fixture and removes both guards after this ticket merges; it does not block this ticket.
**Evidence:** `app.js:1475-1476` (guarded wiring); handoff `sayslate-pass-reasoning-handoff.md` F3 row; full `node tests/verify.mjs` run (24 files, 0 exit) at both `05090dd` and `542fa4a`.

### F1 — Full-page reasoning assertions read a shared call log
**State:** Resolved
**Value:** Each new full-page reasoning assertion reads `reasoning_effort` from the one `/chat/completions` call its own action caused, and fails when that action sends no request.
**Evidence:** `tests/ai-provider-ui.test.mjs` `reasoningEffortForNextChatCompletion`; commit `542fa4a113fc9598b4279e71b8c2b9fd23e9b0db`; binding probe (Reload first-pass click removed) → exit 1, `this action must issue exactly one new /chat/completions request (0 !== 1)`.

### F2 — Ticket file not updated in place
**State:** Resolved
**Value:** This file's build-checklist and exit-gate boxes are now checked with evidence, and all 7 original objectives plus F1 and F2 are filled in place, matching the review 1 report.
**Evidence:** This file (`SAYREASON-02.md`), Build checklist and Exit gate sections above.
