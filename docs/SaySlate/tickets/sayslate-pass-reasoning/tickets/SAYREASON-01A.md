# SAYREASON-01A — Stream Custom passes and time out on silence

**Handoff:** [sayslate-pass-reasoning-handoff.md](../sayslate-pass-reasoning-handoff.md)
**Serves:** REQ-004
**Depends on:** SAYREASON-02A merged into `origin/main` (`753a5b1`)
**May run in parallel with:** Nothing
**Branch slug:** `sayreason-01a-stream-custom-passes`
**Exclusive production ownership:** `aiProviderClient.js`, `openAICompatibleClient.js`, `tests/ai-provider-client.test.mjs`, `tests/openai-compatible-client.test.mjs`, `tests/ai-provider-ui.test.mjs` (only the `/chat/completions` branch of `createFakeFetch`), `CHANGELOG.md` (`[Unreleased]` section only)
**Must not change:** `app.js`, `floating.js`, `aiClient.js`, `anthropicClient.js`, `aiProviderRegistry.js`, every other file, the OpenAI (non-streamed) request body and its timeout behavior, the schema-free retry body, and every existing assertion in the three owned test files

## Goal

A Custom (LM Studio) pass is not reported as timed out while LM Studio is still sending its response, and it still fails after 90 s with nothing received (REQ-004, LD-007). Today the adapter sends one non-streamed request under one 90 s abort timer, so any response that takes longer than 90 s to complete is aborted even though the server finishes it (EV-025, EV-027). Reasoning makes this common, but a long answer with reasoning off hits the same limit (EV-029). Custom requests therefore stream, and the timer restarts each time data arrives. OpenAI requests stay exactly as they are. This ticket must not change the renderers, the reasoning values, or any other provider.

## Build checklist

- [ ] **Dispatcher** (`aiProviderClient.js`, `OPENAI_CHAT_COMPLETIONS` case): pass `stream: true` to `SaySlateOpenAICompatibleClient.generate` for Custom profiles, reasoning on or off, next to `reasoningEffort`. OpenAI profiles pass no `stream`. Keep `stream` out of `adapterArgs`, so Gemini and Anthropic receive the same arguments as today (LD-007).
- [ ] **Adapter** (`openAICompatibleClient.js`): add an optional `stream` parameter, default `false`.
  - [ ] When `stream` is true, the structured request body carries `stream: true`. The schema-free retry body stays `{ model, messages }` (EV-002).
  - [ ] When `stream` is true, restart the abort timer when `fetch` resolves and each time a body chunk is read, so `request_timeout` means `timeoutMs` passed with nothing received. When `stream` is false, the timer is never restarted, as today.
  - [ ] When `stream` is true and the response is `ok` with a `content-type` containing `text/event-stream`, read the body as server-sent events through `response.body.getReader()` and a `TextDecoder`:
    - [ ] Buffer across chunks and split on line breaks (`\n`, tolerating `\r\n`). Only `data:` lines count, and `data: [DONE]` ends the stream.
    - [ ] Parse each other `data:` payload as JSON. If a payload does not parse, throw `malformed_response`.
    - [ ] A payload with an `error` field throws `provider_error`. A `choices[0].delta.refusal` throws `provider_error` "The AI provider refused the request."
    - [ ] Concatenate `choices[0].delta.content`. Ignore `delta.reasoning_content` and every other field.
    - [ ] Validate the concatenated content with the existing `validateCanonicalText` and throw the existing schema `malformed_response` message when it fails.
    - [ ] An `AbortError` while reading throws `request_timeout`, and any other read failure throws `network_error`, with the existing messages.
  - [ ] When `stream` is true but the `ok` response is not `text/event-stream`, use the existing JSON path unchanged.
  - [ ] Update the `DEFAULT_TIMEOUT_MS` comment to state what the 90 s bounds in each mode: total time for a non-streamed request, and time with nothing received for a streamed one.
- [ ] **`tests/openai-compatible-client.test.mjs`**: add scenarios whose fake `fetch` returns `{ ok, status, headers: { get }, body }` with `body` a `ReadableStream` of SSE text, like LM Studio's (EV-028):
  - [ ] **Body:** `stream: true` puts `stream: true` in the structured body; `stream` omitted leaves no `stream` field.
  - [ ] **Reasoning then content:** `reasoning_content` chunks followed by `content` chunks return the validated text, with none of the reasoning text in it.
  - [ ] **Slow but steady:** with `timeoutMs: 50`, chunks every 20 ms for a total above 150 ms resolve.
  - [ ] **Stall:** with `timeoutMs: 50`, one chunk and then no more rejects with `request_timeout`.
  - [ ] **Error payload** mid-stream → `provider_error`. **Refusal delta** → `provider_error`. **Unparseable `data:` line** → `malformed_response`. **Content that fails the schema** → `malformed_response`.
  - [ ] **Server ignores `stream`:** `stream: true` with an `application/json` response returns the JSON path's result.
  - [ ] **HTTP 400 with `stream: true`:** the retry body is exactly `{ model, messages }`.
- [ ] **`tests/ai-provider-client.test.mjs`**: make the Custom scenarios' fakes answer `text/event-stream` as LM Studio does (EV-030), leaving their assertions unchanged. Add scenarios:
  - [ ] Custom with `reasoning: true` and with `reasoning: false`: the request body carries `stream: true`.
  - [ ] OpenAI: the request body has no `stream` field.
- [ ] **`tests/ai-provider-ui.test.mjs` `createFakeFetch`**: when the `/chat/completions` request body has `stream: true`, answer `text/event-stream` carrying the same `{"text": "custom pass result"}` content as a stream of chunks. Otherwise answer as today, adding `headers` with `application/json`. Do not change any scenario or assertion.
- [ ] **`CHANGELOG.md` `[Unreleased]`**: add one line saying Custom (LM Studio) passes now stream, and a pass times out only after 90 s with nothing received, so a long reasoning pass is no longer cut off.

## Exit gate

- [ ] `node tests/verify.mjs` exits 0.
- [ ] `node --check` exits 0 for `aiProviderClient.js`, `openAICompatibleClient.js`, and each changed test file.
- [ ] `git diff --check` reports nothing.
- [ ] Every pre-existing assertion in the three owned test files is unmodified; only the fakes listed above change.
- [ ] **Live check** (handoff dispatch rule 6): a scratch script outside the worktree loads the real `aiProviderRegistry.js`, `aiClient.js`, `openAICompatibleClient.js`, `anthropicClient.js`, and `aiProviderClient.js` into `node:vm`, as `tests/ai-provider-client.test.mjs` does, with Node's real `fetch`. It calls:
  - [ ] the dispatcher with a Custom profile (`endpoint: "http://127.0.0.1:1234/v1"`, `modelId: "google/gemma-4-12b-qat"`, blank credential), `reasoning: true`, and `timeoutMs: 5000`. It resolves with validated text after more than 5 s in total.
  - [ ] the adapter directly with the same request, `stream: false`, `reasoningEffort: "medium"`, and `timeoutMs: 5000`. It rejects with `request_timeout`.

  Report both results and the total times.
- [ ] `git diff --stat <starting commit>..HEAD` lists only the owned files.

## Out of scope

- Streaming for OpenAI, Gemini, or Anthropic profiles: REQ-002 limits this work to LM Studio.
- A cancel control for a running pass, and the renderers' timeout message text.
- The LM Studio endpoint doc's timeout row: the orchestrating agent reports it after this ticket merges.

## Objectives

Complete every objective below in place, using the handoff's Compact Audit Trail Output Rule. Resolved requires implemented code, direct evidence, and focused verification; intent or partial implementation is Unresolved.

### Custom passes stream
**State:**
**Value:**
**Evidence:**
**Depends on:**

### Timeout measures silence on streamed requests
**State:**
**Value:**
**Evidence:**
**Depends on:**

### Streamed responses validated like JSON responses
**State:**
**Value:**
**Evidence:**
**Depends on:**

### OpenAI and other providers unchanged
**State:**
**Value:**
**Evidence:**
**Depends on:**

### Live check against LM Studio
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
