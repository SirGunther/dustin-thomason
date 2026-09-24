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

- [ ] Add `firstPassReasoning: false` and `secondPassReasoning: false` to `DEFAULT_PROCESSING_CONFIG` in `app.js`. Add both to `normalizeProcessingConfig`, each reading `value.<field> === true`, and keep `PROMPT_SCHEMA_VERSION` at 3 (LD-002).
- [ ] In `app.html`'s prompt panel, apply LD-004's markup:
  - [ ] Move the "First-pass prompt" label into a `.pass-setting-header` row holding the `firstPassReasoningState` / `firstPassReasoningInput` switch.
  - [ ] Add the `secondPassReasoningState` / `secondPassReasoningInput` switch to the second-pass header, beside its Enabled switch.
  - [ ] End both help lines with "Reasoning applies only to Custom (LM Studio) connections."
- [ ] In `app.css`, add only the rules needed to place two `.pass-toggle` switches in one header row, beside the existing switch rules (EV-011, LD-004).
- [ ] In `app.js`, apply LD-004's switch behavior:
  - [ ] Query the four new elements.
  - [ ] Set both switches and their state words in `openPromptSettings`.
  - [ ] Include both values in `savePromptSettings`.
  - [ ] Give each switch a `change` listener that saves at once, following `saveSecondPassToggle`: state word, toast, and restore-on-failure message.
- [ ] Pass `reasoning: processingConfig.firstPassReasoning` in `runFirstPass`'s `generate` call and `reasoning: processingConfig.secondPassReasoning` in `runSecondPass`'s (EV-012, LD-003).
- [ ] In `floating.js`, add both fields to `normalizeConfig` with the same `=== true` reading, and pass the matching `reasoning` value in both `generate` calls (EV-013, LD-005).
- [ ] Add scenarios to `tests/ai-provider-ui.test.mjs` with the Custom profile active, reading `reasoning_effort` from the recorded `/chat/completions` calls of its fake `fetch` (EV-019):
  - [ ] **Defaults:** with both switches off, the first-pass and second-pass requests both carry `"none"`.
  - [ ] **First on, second off:** `"medium"`, then `"none"`.
  - [ ] **First off, second on:** `"none"`, then `"medium"`.
  - [ ] **Reload:** after a switch changes, a fresh `buildInstance` over the same storage shows the saved switch state and sends the saved value.
  - [ ] **Second pass off:** turning it off keeps `secondPassReasoning` stored, and turning it back on sends the kept value.
  - [ ] **Failed save:** when a switch's save fails, the switch shows its previous value.
  - [ ] **Gemini:** with the Gemini profile active and both switches on, its requests carry no `reasoning_effort`.
- [ ] In `tests/floating-dictation-integration.test.mjs`, add a fake `SaySlateOpenAICompatibleClient.generate` to the context that records `reasoningEffort`, next to the existing Gemini fake (EV-019). Then add scenarios with a seeded Custom profile:
  - [ ] **Finish:** with `firstPassReasoning: true`, `secondPassReasoning: false`, and the second pass enabled, Finish sends `"medium"` for pass 1 and `"none"` for pass 2.
  - [ ] **Live update:** a storage change that turns `secondPassReasoning` on makes the next second pass send `"medium"`.
- [ ] In `CHANGELOG.md` `[Unreleased]`, rewrite the line at `:30` so it describes the per-pass reasoning switches, off by default, for Custom profiles (LD-006, EV-015).
- [ ] In `README.md`, add one sentence after the second-pass toggle paragraph (`:40`) describing the two reasoning switches and that they apply only to Custom (LM Studio) connections (LD-006).

## Exit gate

- [ ] `node tests/verify.mjs` exits 0.
- [ ] `node --check app.js` and `node --check floating.js` exit 0.
- [ ] `git diff --check` reports nothing.
- [ ] The existing second-pass switch checks in `tests/verify.mjs:383-392` and every existing scenario in the two owned test files pass unmodified.
- [ ] Every new assertion follows a real user action (a dispatched click, `change`, or form `submit`) or a storage change. No test calls `generate` directly or replaces a pass function.
- [ ] Loaded-extension check (handoff dispatch rule 6): the prompt panel shows both reasoning switches, in light and dark themes, and a switch turned on is still on after the page reloads. Screenshot paths are reported.
- [ ] `git diff --stat <starting commit>..HEAD` lists only the owned files.

## Out of scope

- The dispatcher's `reasoning` input: SAYREASON-01.
- Reasoning for OpenAI, Gemini, or Anthropic profiles: excluded by REQ-002.
- The reconcile pass and Whisper model selection: excluded by the requirements' scope boundary.
- The LM Studio endpoint doc's "Reasoning (thinking)" section: the orchestrating agent updates it after this ticket merges (LD-006).

## Objectives

Complete every objective below in place, using the handoff's Compact Audit Trail Output Rule. Resolved requires implemented code, direct evidence, and focused verification; intent or partial implementation is Unresolved.

### Per-pass reasoning stored and off by default
**State:**
**Value:**
**Evidence:**
**Depends on:**

### Reasoning switches in the prompt panel
**State:**
**Value:**
**Evidence:**
**Depends on:**

### Full-page passes send their setting
**State:**
**Value:**
**Evidence:**
**Depends on:**

### Floating Slate passes send their setting
**State:**
**Value:**
**Evidence:**
**Depends on:**

### Documentation matches the behavior
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

### F1 — Full-page reasoning assertions read a shared call log
**State:**
**Value:**
**Evidence:**
**Depends on:**

### F2 — Ticket file not updated in place
**State:**
**Value:**
**Evidence:**
**Depends on:**
