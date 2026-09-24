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

- [x] **Dispatcher** (`aiProviderClient.js`, `OPENAI_CHAT_COMPLETIONS` case): pass `stream: true` to `SaySlateOpenAICompatibleClient.generate` for Custom profiles, reasoning on or off, next to `reasoningEffort`. OpenAI profiles pass no `stream`. Keep `stream` out of `adapterArgs`, so Gemini and Anthropic receive the same arguments as today (LD-007).
- [x] **Adapter** (`openAICompatibleClient.js`): add an optional `stream` parameter, default `false`.
  - [x] When `stream` is true, the structured request body carries `stream: true`. The schema-free retry body stays `{ model, messages }` (EV-002).
  - [x] When `stream` is true, restart the abort timer when `fetch` resolves and each time a body chunk is read, so `request_timeout` means `timeoutMs` passed with nothing received. When `stream` is false, the timer is never restarted, as today.
  - [x] When `stream` is true and the response is `ok` with a `content-type` containing `text/event-stream`, read the body as server-sent events through `response.body.getReader()` and a `TextDecoder`:
    - [x] Buffer across chunks and split on line breaks (`\n`, tolerating `\r\n`). Only `data:` lines count, and `data: [DONE]` ends the stream.
    - [x] Parse each other `data:` payload as JSON. If a payload does not parse, throw `malformed_response`.
    - [x] A payload with an `error` field throws `provider_error`. A `choices[0].delta.refusal` throws `provider_error` "The AI provider refused the request."
    - [x] Concatenate `choices[0].delta.content`. Ignore `delta.reasoning_content` and every other field.
    - [x] Validate the concatenated content with the existing `validateCanonicalText` and throw the existing schema `malformed_response` message when it fails.
    - [x] An `AbortError` while reading throws `request_timeout`, and any other read failure throws `network_error`, with the existing messages.
  - [x] When `stream` is true but the `ok` response is not `text/event-stream`, use the existing JSON path unchanged.
  - [x] Update the `DEFAULT_TIMEOUT_MS` comment to state what the 90 s bounds in each mode: total time for a non-streamed request, and time with nothing received for a streamed one.
- [x] **`tests/openai-compatible-client.test.mjs`**: add scenarios whose fake `fetch` returns `{ ok, status, headers: { get }, body }` with `body` a `ReadableStream` of SSE text, like LM Studio's (EV-028):
  - [x] **Body:** `stream: true` puts `stream: true` in the structured body; `stream` omitted leaves no `stream` field.
  - [x] **Reasoning then content:** `reasoning_content` chunks followed by `content` chunks return the validated text, with none of the reasoning text in it.
  - [x] **Slow but steady:** with `timeoutMs: 50`, chunks every 20 ms for a total above 150 ms resolve.
  - [x] **Stall:** with `timeoutMs: 50`, one chunk and then no more rejects with `request_timeout`.
  - [x] **Error payload** mid-stream → `provider_error`. **Refusal delta** → `provider_error`. **Unparseable `data:` line** → `malformed_response`. **Content that fails the schema** → `malformed_response`.
  - [x] **Server ignores `stream`:** `stream: true` with an `application/json` response returns the JSON path's result.
  - [x] **HTTP 400 with `stream: true`:** the retry body is exactly `{ model, messages }`.
- [x] **`tests/ai-provider-client.test.mjs`**: make the Custom scenarios' fakes answer `text/event-stream` as LM Studio does (EV-030), leaving their assertions unchanged. Add scenarios:
  - [x] Custom with `reasoning: true` and with `reasoning: false`: the request body carries `stream: true`.
  - [x] OpenAI: the request body has no `stream` field.
- [x] **`tests/ai-provider-ui.test.mjs` `createFakeFetch`**: when the `/chat/completions` request body has `stream: true`, answer `text/event-stream` carrying the same `{"text": "custom pass result"}` content as a stream of chunks. Otherwise answer as today, adding `headers` with `application/json`. Do not change any scenario or assertion.
- [x] **`CHANGELOG.md` `[Unreleased]`**: add one line saying Custom (LM Studio) passes now stream, and a pass times out only after 90 s with nothing received, so a long reasoning pass is no longer cut off.

## Exit gate

- [x] `node tests/verify.mjs` exits 0.
- [x] `node --check` exits 0 for `aiProviderClient.js`, `openAICompatibleClient.js`, and each changed test file.
- [x] `git diff --check` reports nothing.
- [x] Every pre-existing assertion in the three owned test files is unmodified; only the fakes listed above change.
- [x] **Live check** (handoff dispatch rule 6): a scratch script outside the worktree loads the real `aiProviderRegistry.js`, `aiClient.js`, `openAICompatibleClient.js`, `anthropicClient.js`, and `aiProviderClient.js` into `node:vm`, as `tests/ai-provider-client.test.mjs` does, with Node's real `fetch`. It calls:
  - [x] the dispatcher with a Custom profile (`endpoint: "http://127.0.0.1:1234/v1"`, `modelId: "google/gemma-4-12b-qat"`, blank credential), `reasoning: true`, and `timeoutMs: 5000`. It resolves with validated text after more than 5 s in total.
  - [x] the adapter directly with the same request, `stream: false`, `reasoningEffort: "medium"`, and `timeoutMs: 5000`. It rejects with `request_timeout`.

  Report both results and the total times.
- [x] `git diff --stat <starting commit>..HEAD` lists only the owned files.

## Out of scope

- Streaming for OpenAI, Gemini, or Anthropic profiles: REQ-002 limits this work to LM Studio.
- A cancel control for a running pass, and the renderers' timeout message text.
- The LM Studio endpoint doc's timeout row: the orchestrating agent reports it after this ticket merges.

## Objectives

Complete every objective below in place, using the handoff's Compact Audit Trail Output Rule. Resolved requires implemented code, direct evidence, and focused verification; intent or partial implementation is Unresolved.

### Custom passes stream

**State:** Resolved
**Value:** The dispatcher sends `stream: true` for every Custom (LM Studio) profile, reasoning on or off; OpenAI never sends it; the adapter carries `stream: true` in the structured body only.
**Evidence:** `aiProviderClient.js:97-107` (OPENAI_CHAT_COMPLETIONS case); `openAICompatibleClient.js:101` (`if (stream) schemaBody.stream = true;`); `tests/ai-provider-client.test.mjs` scenarios "reasoning:true sends reasoning_effort medium"/"reasoning:false" (stream:true assertions) and "OpenAI stream field absent"; `tests/openai-compatible-client.test.mjs` "stream:true present in structured body"/"stream field absent by default".

### Timeout measures silence on streamed requests

**State:** Resolved
**Value:** A streamed request's abort timer restarts when `fetch` resolves and on every body-chunk read, so `request_timeout` fires only after `timeoutMs` with nothing received; a non-streamed request keeps its single total-time timer unchanged.
**Evidence:** `openAICompatibleClient.js:159-171` (`restartTimeout`, called after fetch resolves and in `readEventStream`'s read loop); `tests/openai-compatible-client.test.mjs` "slow-but-steady stream resolves past the per-chunk timeout" (20 ms chunks, 50 ms timer, >150 ms total) and "stalled stream times out" (one chunk then silence rejects `request_timeout` at 50 ms); live check adapter-direct call (`stream:false`, `timeoutMs:5000`) rejected at 5002 ms while the streamed dispatcher call with the same prompt resolved at 22068 ms.

### Streamed responses validated like JSON responses

**State:** Resolved
**Value:** SSE `data:` lines are buffered/split on `\n` (tolerating `\r\n`), `[DONE]` ends the stream, `choices[0].delta.content` is concatenated (ignoring `reasoning_content`), and the result is validated with the same `validateCanonicalText`/`malformed_response` path as the non-streamed JSON response; an `error` field or `delta.refusal` throws `provider_error`, an unparseable payload throws `malformed_response`, and a read failure maps to `request_timeout`/`network_error` exactly as the non-streamed path does.
**Evidence:** `openAICompatibleClient.js:57-92` (`isEventStream`, `readEventStream`); `tests/openai-compatible-client.test.mjs` "reasoning_content ignored, content returned", "mid-stream error payload", "refusal delta", "unparseable data line", "schema-mismatch streamed content", "server-ignores-stream JSON-path fallback", "stream:true HTTP 400 schema-free retry body".

### OpenAI and other providers unchanged

**State:** Resolved
**Value:** OpenAI's non-streamed request body and timeout behavior, the schema-free retry body, Gemini, and Anthropic are untouched; `stream` never reaches `adapterArgs`, so the Gemini and Anthropic adapters receive the same arguments as before.
**Evidence:** `aiProviderClient.js:106-113` (Gemini/Anthropic cases pass plain `adapterArgs`, no `stream` key added); `tests/ai-provider-client.test.mjs` "OpenAI stream field absent", "Gemini reasoning:true adds no request field", "Anthropic reasoning:true adds no request field" (all pre-existing, unmodified); every pre-existing assertion in the three owned test files is unchanged (only fakes/new scenarios were added, confirmed by reviewing the full diff).

### Live check against LM Studio

**State:** Resolved
**Value:** Against the real, already-running LM Studio (`google/gemma-4-12b-qat`), the dispatcher (Custom, `reasoning:true`, `timeoutMs:5000`) resolved with validated text after 22068 ms; the adapter called directly with `stream:false`, `reasoningEffort:"medium"`, `timeoutMs:5000` rejected with `request_timeout` after 5002 ms - both on the first attempt, no rerun needed.
**Evidence:** Scratch script `.../scratchpad/sayreason-01a-live/live-check.mjs` (outside the worktree, not committed); run output: `[dispatcher] resolved in 22068ms ...`, `[adapter direct, stream:false] rejected in 5002ms with code=request_timeout`.

### Scope and architecture compliance

**State:** Resolved
**Value:** Only the six owned files changed (`aiProviderClient.js`, `openAICompatibleClient.js`, `CHANGELOG.md`, and the three owned test files); no other file was touched; `app.js`, `floating.js`, `aiClient.js`, `anthropicClient.js`, and `aiProviderRegistry.js` are untouched.
**Evidence:** `git diff --stat 753a5b1..HEAD` lists exactly `CHANGELOG.md`, `aiProviderClient.js`, `openAICompatibleClient.js`, `tests/ai-provider-client.test.mjs`, `tests/ai-provider-ui.test.mjs`, `tests/openai-compatible-client.test.mjs`.

### Implementation completeness

**State:** Resolved
**Value:** Every build-checklist and exit-gate item is implemented and verified; `node tests/verify.mjs` exits 0 (24 focused test files, including all new SAYREASON-01A scenarios), `node --check` passes on every changed `.js`/`.mjs` file, and `git diff --check` reports nothing.
**Evidence:** `node tests/verify.mjs` → exit 0, log line "SAYREASON-01A streaming scenarios verified." plus "24 focused test files passed."; `node --check` on `aiProviderClient.js`, `openAICompatibleClient.js`, and the three changed test files → no output/exit 0; `git diff --check` → no output/exit 0.
