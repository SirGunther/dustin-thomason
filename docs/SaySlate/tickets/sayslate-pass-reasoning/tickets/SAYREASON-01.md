# SAYREASON-01 — Dispatcher sends the reasoning setting to LM Studio

**Handoff:** [sayslate-pass-reasoning-handoff.md](../sayslate-pass-reasoning-handoff.md)
**Serves:** REQ-002, REQ-003
**Depends on:** Nothing
**May run in parallel with:** Nothing
**Branch slug:** `sayreason-01-dispatcher-reasoning`
**Exclusive production ownership:** `aiProviderClient.js`, `tests/ai-provider-client.test.mjs`
**Must not change:** `openAICompatibleClient.js` (including its schema-free retry body), `aiClient.js`, `anthropicClient.js`, `aiProviderRegistry.js`, `aiProviderSettings.js`, `app.js`, `floating.js`, `CHANGELOG.md`, and the Gemini, OpenAI, and Anthropic request bodies

## Goal

`SaySlateAIProviderClient.generate` takes an optional boolean `reasoning`. A Custom (LM Studio) request sends `reasoning_effort: "medium"` when it is `true` and `"none"` otherwise, and every other provider's request is exactly what it is today (LD-003). A caller that omits `reasoning`, which is every caller today, still sends `"none"`. This ticket must not add switches, storage, or renderer wiring (SAYREASON-02). It must not change the OpenAI-compatible adapter, and it must not introduce reasoning for any other provider.

## Build checklist

- [ ] Add `reasoning = false` to `generate`'s destructured parameters (`aiProviderClient.js:52`) (LD-003).
- [ ] In the `OPENAI_CHAT_COMPLETIONS` case (`aiProviderClient.js:98-104`), compute the Custom value as `"medium"` when `reasoning === true` and `"none"` otherwise, and keep `undefined` for OpenAI profiles (LD-003).
- [ ] Keep `reasoning` out of `adapterArgs`, so the Gemini and Anthropic adapters receive the same arguments as today (LD-003).
- [ ] Add scenarios to `tests/ai-provider-client.test.mjs` using its fake `fetch` (EV-019), asserting the parsed request body:
  - [ ] **Custom, `reasoning: true`:** `reasoning_effort` is `"medium"`.
  - [ ] **Custom, `reasoning: false`:** `reasoning_effort` is `"none"`.
  - [ ] **OpenAI, `reasoning: true`:** no `reasoning_effort` field.
  - [ ] **Gemini, `reasoning: true`:** the request body has no field that the same request without `reasoning` lacks.
  - [ ] **Anthropic, `reasoning: true`:** the request body has no field that the same request without `reasoning` lacks.
  - [ ] **Custom, `reasoning: true`, HTTP 400 on the structured request:** the retry body has no `reasoning_effort` (EV-002).

## Exit gate

- [ ] `node tests/verify.mjs` exits 0.
- [ ] `node --check aiProviderClient.js` exits 0.
- [ ] `git diff --check` reports nothing.
- [ ] The existing assertions at `tests/ai-provider-client.test.mjs:93-94` (OpenAI sends no `reasoning_effort`) and `:120-121` (Custom without `reasoning` sends `"none"`) pass unmodified.
- [ ] `git diff --stat <starting commit>..HEAD` lists only the owned files.

## Out of scope

- Reasoning switches, storage, and passing the setting from either surface: SAYREASON-02.
- Reasoning for OpenAI, Gemini, or Anthropic profiles: excluded by REQ-002.

## Objectives

Complete every objective below in place, using the handoff's Compact Audit Trail Output Rule. Resolved requires implemented code, direct evidence, and focused verification; intent or partial implementation is Unresolved.

### Reasoning input on the dispatcher
**State:**
**Value:**
**Evidence:**
**Depends on:**

### Custom requests carry the setting
**State:**
**Value:**
**Evidence:**
**Depends on:**

### Other providers unchanged
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
