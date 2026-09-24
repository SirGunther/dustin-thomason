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

- [x] Add `reasoning = false` to `generate`'s destructured parameters (`aiProviderClient.js:52`) (LD-003).
- [x] In the `OPENAI_CHAT_COMPLETIONS` case (`aiProviderClient.js:98-104`), compute the Custom value as `"medium"` when `reasoning === true` and `"none"` otherwise, and keep `undefined` for OpenAI profiles (LD-003).
- [x] Keep `reasoning` out of `adapterArgs`, so the Gemini and Anthropic adapters receive the same arguments as today (LD-003).
- [x] Add scenarios to `tests/ai-provider-client.test.mjs` using its fake `fetch` (EV-019), asserting the parsed request body:
  - [x] **Custom, `reasoning: true`:** `reasoning_effort` is `"medium"`. (Scenario 7)
  - [x] **Custom, `reasoning: false`:** `reasoning_effort` is `"none"`. (Scenario 8)
  - [x] **OpenAI, `reasoning: true`:** no `reasoning_effort` field. (Scenario 9)
  - [x] **Gemini, `reasoning: true`:** the request body has no field that the same request without `reasoning` lacks. (Scenario 10)
  - [x] **Anthropic, `reasoning: true`:** the request body has no field that the same request without `reasoning` lacks. (Scenario 11)
  - [x] **Custom, `reasoning: true`, HTTP 400 on the structured request:** the retry body has no `reasoning_effort` (EV-002). (Scenario 12)

## Exit gate

- [x] `node tests/verify.mjs` exits 0.
- [x] `node --check aiProviderClient.js` exits 0.
- [x] `git diff --check` reports nothing.
- [x] The existing assertions at `tests/ai-provider-client.test.mjs:93-94` (OpenAI sends no `reasoning_effort`) and `:120-121` (Custom without `reasoning` sends `"none"`) pass unmodified — both printed as "Dispatcher openai-chat-completions routing verified." and "Dispatcher custom/LM Studio routing without a credential verified." in the passing `verify.mjs` run.
- [x] `git diff --stat <starting commit>..HEAD` lists only the owned files (`aiProviderClient.js`, `tests/ai-provider-client.test.mjs`).

## Out of scope

- Reasoning switches, storage, and passing the setting from either surface: SAYREASON-02.
- Reasoning for OpenAI, Gemini, or Anthropic profiles: excluded by REQ-002.

## Objectives

Complete every objective below in place, using the handoff's Compact Audit Trail Output Rule. Resolved requires implemented code, direct evidence, and focused verification; intent or partial implementation is Unresolved.

### Reasoning input on the dispatcher
**State:** Resolved
**Value:** `generate` accepts an optional `reasoning` parameter, defaulting to `false` so every existing caller keeps sending `"none"`.
**Evidence:** `aiProviderClient.js:52`

### Custom requests carry the setting
**State:** Resolved
**Value:** A Custom (LM Studio) request sends `reasoning_effort: "medium"` when `reasoning === true` and `"none"` otherwise, including the default/omitted case.
**Evidence:** `aiProviderClient.js:100-105`; `tests/ai-provider-client.test.mjs` Scenarios 3, 7, 8, 12 (all pass in `node tests/verify.mjs`)

### Other providers unchanged
**State:** Resolved
**Value:** `reasoning` is never placed on `adapterArgs`, so the OpenAI, Gemini, and Anthropic adapters receive the same arguments as without it: OpenAI sends no `reasoning_effort`, and Gemini and Anthropic bodies gain no field.
**Evidence:** `aiProviderClient.js:78-88` (adapterArgs construction excludes `reasoning`); `tests/ai-provider-client.test.mjs` Scenarios 9, 10, 11 (all pass)

### Scope and architecture compliance
**State:** Resolved
**Value:** Only the two owned files changed; no switches, storage, or renderer wiring were added; `openAICompatibleClient.js` and the other adapters/request bodies are untouched.
**Evidence:** `git diff --stat 668a10fee66d513615a19972778b19019770fbc5..HEAD` on branch `agent/sayreason-01-dispatcher-reasoning` lists only `aiProviderClient.js` and `tests/ai-provider-client.test.mjs`

### Implementation completeness
**State:** Resolved
**Value:** All build-checklist items and exit-gate conditions are satisfied.
**Evidence:** Commit `75555e3` on `agent/sayreason-01-dispatcher-reasoning`, pushed to `origin/agent/sayreason-01-dispatcher-reasoning`
