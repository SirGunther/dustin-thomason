# SAYAI-03 — Provider transports and structured results

**Handoff:** [sayslate-ai-provider-tailscale-handoff.md](../sayslate-ai-provider-tailscale-handoff.md)
**Serves:** REQ-001, REQ-005, REQ-006, REQ-007, REQ-008, REQ-009–REQ-016
**Depends on:** SAYAI-02 merged first
**May run in parallel with:** Nothing
**Branch slug:** `sayai-03-provider-transports`
**Exclusive production ownership:** `aiClient.js`, `aiProviderClient.js`, `openAICompatibleClient.js`, `anthropicClient.js`, `tests/ai-client.test.mjs`, `tests/ai-provider-client.test.mjs`, `tests/openai-compatible-client.test.mjs`, `tests/anthropic-client.test.mjs`, `tests/verify.mjs`
**Must not change:** Profile schema, manifest permissions, provider UI, connection-test UI, dictation, prompt wording, or renderer-owned request lifetime

## Goal

Implement LD-015, LD-022, LD-024, LD-025, LD-028, and LD-031 against LD-023's profile shape for REQ-001 and REQ-005–REQ-007. Preserve the
working native Gemini path, add the governed provider adapters, and return only LD-025's validated
plain-string result to the existing renderer boundary.

## Build checklist

- [x] Export LD-022's immutable canonical schema and implement LD-025's exact dispatcher signature,
  return type, and bounded error codes.
- [x] Select adapters only through LD-024's registered transport kind; never infer a transport from
  an arbitrary URL.
- [x] Preserve Gemini's native Generate Content endpoint and add its native response schema/mime
  configuration where supported.
- [x] Add EV-020/EV-014's OpenAI-compatible `/v1/chat/completions` adapter with conditional Bearer
  authentication and LD-022's strict schema.
- [x] Use the same OpenAI-compatible adapter for OpenAI and custom/LM Studio profiles without adding
  provider-specific behavior to UI code.
- [x] Add EV-021's Anthropic Messages adapter with current required authentication/version headers and
  `output_config.format` structured output; because SaySlate intentionally performs browser-direct
  calls, include Anthropic's explicit dangerous-direct-browser acknowledgement header.
- [x] Retain EV-017/LD-016's existing 90-second abort and renderer-owned request lifetime.
- [x] Enforce LD-022 and LD-025 validation/error boundaries before returning any text.
- [x] Implement LD-031's single schema-free retry after an HTTP 400 or 422 to a schema request,
  accepting only trimmed non-empty text; accept no other unvalidated free-form output.
- [x] Test each production adapter through mocked fetch at its public production entry point,
  proving the dispatcher-to-adapter path while asserting exact
  URL, headers, request schema, abort handling, valid result, malformed JSON, schema mismatch,
  authentication failure, provider error, and LD-031 retry behavior.
- [x] Prove the dispatcher returns the same plain string shape expected by the existing first- and
  second-pass call sites.

## Exit gate

- [x] Gemini still uses its native endpoint and its existing successful behavior remains covered.
- [x] OpenAI, Claude, and custom/LM Studio requests use their governed request and authentication
  shapes.
- [x] Supported providers receive the canonical schema and invalid results cannot reach UI code.
- [x] No adapter logs or returns a credential; adapter code reads only the selected profile's
  locally persisted credential at call time.
- [x] Focused adapter tests, `node tests/verify.mjs`, JavaScript syntax checks, and
  `git diff --check` pass.

## Out of scope

- Provider listing/health checks (SAYAI-04).
- Changing prompts, any retry beyond LD-031's single schema-free retry, detached/background
  inference, or adding an SDK dependency.
- Provider settings UI or live Tailscale acceptance.

## Objectives

Complete every objective below in place, using the handoff's Compact Audit Trail Output Rule.
Resolved requires implemented code, direct evidence, and focused verification; intent or partial
implementation is Unresolved.

### Provider transports honor their native contracts
**State:** Resolved
**Value:** Gemini keeps its native `:generateContent` key-in-URL request (LD-015) and sends the canonical schema as `generationConfig.responseJsonSchema` (corrected by F1 — LD-036(1); `responseSchema` is rejected by Gemini and never sent); OpenAI-compatible profiles (OpenAI, custom/LM Studio) POST `/chat/completions` with conditional Bearer auth; Anthropic POSTs `/messages` with `x-api-key`, `anthropic-version`, and the dangerous-direct-browser-access header (LD-035); the dispatcher selects the transport only via `registry.presetFor(profile.providerKind).transportKind`, never URL inference.
**Evidence:** `aiClient.js:generateStructured` (`generationConfig.responseJsonSchema`); `openAICompatibleClient.js:postChatCompletions`; `anthropicClient.js:buildHeaders,postMessages`; `aiProviderClient.js:generate` switch on `transportKinds`; `tests/ai-provider-client.test.mjs` scenarios 1-4; `tests/ai-client.test.mjs` "native schema request (responseJsonSchema)" scenario.

### Structured results are validated and normalized
**State:** Resolved
**Value:** Every adapter requests LD-022's canonical `{ type: object, properties: { text }, required: [text] }` schema (exported frozen as `aiProviderClient.js:CANONICAL_RESULT_SCHEMA`), validates the parsed JSON strictly matches `{ text: string }` before unwrapping, and implements LD-031's single schema-free retry on HTTP 400/422 accepting only trimmed non-empty text, with an empty retry reply as final `malformed_response`.
**Evidence:** `aiProviderClient.js:CANONICAL_RESULT_SCHEMA`; `openAICompatibleClient.js:validateCanonicalText`, LD-031 retry block; `anthropicClient.js:validateCanonicalText`, LD-031 retry block; `aiClient.js:validateCanonicalText`, LD-031 retry block; `tests/openai-compatible-client.test.mjs` scenarios 4, 8-9; `tests/anthropic-client.test.mjs` scenarios 4, 9-10; `tests/ai-client.test.mjs` generateStructured scenarios (schema-mismatch, LD-031 retry, empty-retry).

### Provider HTTP production-boundary correctness
**State:** Resolved
**Value:** Each adapter is tested through mocked fetch at its real production entry point, asserting exact URL, headers, request body shape, abort/timeout, valid result, malformed JSON, schema mismatch, authentication failure (401→`authentication_failed`), generic provider error (→`provider_error`), and LD-031 retry; no test or production code path includes the fake credential, prompt text, or raw response body in a thrown message or return value.
**Evidence:** `tests/openai-compatible-client.test.mjs` (11 scenarios); `tests/anthropic-client.test.mjs` (12 scenarios, including LD-035's `stop_reason` refusal/max_tokens mapping); `tests/ai-client.test.mjs` generateStructured scenarios (9 scenarios); credential-absence assertions e.g. `tests/anthropic-client.test.mjs:!error.message.includes("test-key-anthropic")`.

### Scope and architecture compliance
**State:** Resolved
**Value:** Across both commits, only the ticket's exclusive-ownership files changed (`aiClient.js`, `aiProviderClient.js`, `openAICompatibleClient.js`, `anthropicClient.js`, and their four test files); the F1/F2 redispatch touched only `aiClient.js` and `tests/ai-client.test.mjs`, confirming the orchestrator's review that the Anthropic adapter, OpenAI-compatible adapter, dispatcher, and untouched legacy `generate` needed no change. `git diff --check` against base `a394d8317082f94890884497b920c617be728c11` is clean before and after both commits; no edits to profile schema, manifest, permissions, UI, dictation, or prompt wording; `app.js`/`floating.js` and the existing `SaySlateAIClient.generate()` contract remain untouched.
**Evidence:** `git status --short --branch` post-commit (clean, `[ahead 0]` after push); `git diff --check a394d8317082f94890884497b920c617be728c11` (clean); commits `aaed2e4d55b0677f682e1fdccfc6ce1aff065be6` and `b0b5f02a52990ca2502f30718cb361b35fd4c7f3`.

### Implementation completeness
**State:** Resolved
**Value:** All build-checklist items implemented and exit-gate conditions met, including the F1/F2 corrections: Gemini's schema now rides `generationConfig.responseJsonSchema` (not the rejected `responseSchema`), and a Gemini 400 carrying reason `API_KEY_INVALID` is `authentication_failed` with no LD-031 retry (single fetch call). `node tests/verify.mjs` passes all 22 focused test files plus static repository assertions after the fix. The OpenAI-compatible `message.refusal` → `provider_error` mapping is now Resolved per LD-036(3), which confirms the inference made in the original dispatch needed no separate decision record.
**Evidence:** `node tests/verify.mjs` full run (22 focused test files passed, post-fix); `aiClient.js:isApiKeyInvalid,generateStructured`; `tests/ai-client.test.mjs` "EV-034(b)/LD-036(2) API_KEY_INVALID mapping (no retry)" scenario (asserts `callCount === 1`); LD-036(3) for the refusal mapping.

### F1 — Gemini schema requests are always rejected
**State:** Resolved
**Value:** `aiClient.js:generateStructured` sent the canonical schema on `generationConfig.responseSchema`, which Gemini rejects with HTTP 400 because the schema's `additionalProperties` field is an unsupported keyword there (EV-034(a)); every Gemini request silently fell through the LD-031 retry into free-text acceptance instead of ever receiving a validated structured result. Fixed by sending the schema on `generationConfig.responseJsonSchema` instead, which EV-034(a) confirms accepts the identical schema (LD-036(1)).
**Evidence:** `aiClient.js:generateStructured` `schemaBody.generationConfig.responseJsonSchema` (commit `b0b5f02a52990ca2502f30718cb361b35fd4c7f3`); `tests/ai-client.test.mjs` "native schema request (responseJsonSchema)" scenario asserts the field's exact contents and that `responseSchema` is absent; retry-scenario assertion that neither field is sent on the schema-free retry.

### F2 — Invalid Gemini key is retried and misclassified
**State:** Resolved
**Value:** Every Gemini HTTP 400 was treated as a schema rejection and sent through the LD-031 schema-free retry, but an invalid API key is also HTTP 400 (`INVALID_ARGUMENT`, reason `API_KEY_INVALID`) rather than 401/403 (EV-034(b)) — so a bad key was retried once and then misclassified as a generic `provider_error`/`malformed_response` instead of `authentication_failed`. Fixed by parsing the 400 body and checking `error.details[].reason === "API_KEY_INVALID"` before attempting the retry (LD-036(2)); on that match the adapter throws `authentication_failed` immediately, making exactly one fetch call, with no key or raw response body in the thrown message. A genuine schema-rejecting 400 (no `API_KEY_INVALID` reason) still exercises the LD-031 retry unchanged, and the pre-existing 401/403 test cases are now labeled as generic HTTP-status mapping, not Gemini's actual bad-key shape.
**Evidence:** `aiClient.js:isApiKeyInvalid`, and its call site in `generateStructured` before the LD-031 retry block (commit `b0b5f02a52990ca2502f30718cb361b35fd4c7f3`); `tests/ai-client.test.mjs` "EV-034(b)/LD-036(2) API_KEY_INVALID mapping (no retry)" scenario using EV-034's exact response envelope, asserting `code === "authentication_failed"`, `callCount === 1`, and that the message excludes the credential and the raw `"API key not valid"` body text; adjacent "LD-031 schema-free retry (genuine schema rejection)" and "generic 401 status mapping" scenarios confirm the two paths stay distinct.
