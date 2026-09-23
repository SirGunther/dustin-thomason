# SAYAI-04 — Non-generative provider connection tests

**Handoff:** [sayslate-ai-provider-tailscale-handoff.md](../sayslate-ai-provider-tailscale-handoff.md)
**Serves:** REQ-004, REQ-008, REQ-009–REQ-016
**Depends on:** SAYAI-03 merged first
**May run in parallel with:** Nothing
**Branch slug:** `sayai-04-provider-connection-tests`
**Exclusive production ownership:** `aiProviderConnectionTest.js`, `tests/ai-provider-connection-test.test.mjs`, `tests/verify.mjs`
**Must not change:** Generation adapters, profile schema, manifest permissions, UI, prompts, dictation, or perform inference during connection testing

## Goal

Implement LD-018, LD-024, LD-026, and LD-028 against LD-023's profile shape for REQ-004 and REQ-008. The callable boundary must
distinguish governed provider-diagnostic outcomes without sending user content or consuming a model
generation request; SAYAI-05 owns its UI wiring.

## Build checklist

- [x] Implement LD-026's exact `SaySlateAIProviderConnectionTest.test` input and result contract.
- [x] Fail before network access when endpoint, model, credential, or host permission is missing for
  the selected provider.
- [x] Use LD-024's discovery strategies and EV-020/EV-021 provider model operations; no UI code may
  construct a discovery URL.
- [x] Verify the exact configured model ID is present or retrievable; distinguish an unavailable
  model from an unreachable service.
- [x] Return only LD-026's fixed codes/shape and bounded message; never include a credential, full
  response body, prompt, or transcript.
- [x] Apply LD-026's 15-second default timeout and prove it aborts cleanly.
- [x] Test production code with realistic provider response envelopes and HTTP status codes,
  including 401/403 and a reachable endpoint whose selected model is absent.
- [x] Assert no connection-test case calls a generation endpoint or includes transcript text.

## Exit gate

- [x] A correct configuration can be confirmed without inference.
- [x] Reachability, authentication, permission, and selected-model failures are distinguishable.
- [x] No test-connection request contains user content or generates model output.
- [x] The result contains no secret or unbounded provider response.
- [x] `node tests/ai-provider-connection-test.test.mjs`, `node tests/verify.mjs`, JavaScript syntax
  checks, and `git diff --check` pass.

## Out of scope

- Provider-settings UI, toast rendering, or runtime adapter selection (SAYAI-05).
- Proving structured inference; that belongs to real generation and SAYAI-06 acceptance.
- Retry, fallback, provider failover, or health monitoring.

## Objectives

Complete every objective below in place, using the handoff's Compact Audit Trail Output Rule.
Resolved requires implemented code, direct evidence, and focused verification; intent or partial
implementation is Unresolved.

### Connection diagnostics are non-generative and specific
**State:** Resolved
**Value:** `SaySlateAIProviderConnectionTest.test` performs only LD-024 model-discovery reads (Gemini exact-model retrieval; OpenAI-compatible/Anthropic exact-ID list match) and maps their outcomes to LD-026's nine fixed codes, distinguishing reachability, authentication, permission, and selected-model-absent failures without any generation call.
**Evidence:** `C:\SaySlate-worktrees\sayai-04-provider-connection-tests\aiProviderConnectionTest.js:test,testGemini,testOpenAICompatible,testAnthropic`; `tests\ai-provider-connection-test.test.mjs` scenarios 6–21 (per-code mapping) and scenario 21 ("no connection-test case calls a generation endpoint, sends a body, or uses a non-GET method")

### Secrets and user content stay outside diagnostics
**State:** Resolved
**Value:** No discovery request carries a body, transcript, or prompt (GET-only, credential sent only in the URL key param or an auth header), and no returned `message` ever contains the configured credential or a raw provider response body.
**Evidence:** `aiProviderConnectionTest.js:outcome` (fixed message strings only); `tests\ai-provider-connection-test.test.mjs` scenario 21 (no body/non-GET assertion) and scenario 22 ("no result message leaks a credential across authentication/provider-error outcomes")

### Provider discovery production-boundary correctness
**State:** Resolved
**Value:** Discovery requests match LD-037 exactly: Gemini `GET <endpoint>/models/<modelId>?key=<credential>` with EV-034's bad-key envelope (`error.details[].reason === "API_KEY_INVALID"`) mapped to `authentication_failed`; OpenAI-compatible `GET <endpoint>/models` with conditional Bearer; Anthropic `GET <endpoint>/models?limit=1000` with `x-api-key`/`anthropic-version`/`anthropic-dangerous-direct-browser-access`, following `after_id=<last_id>` while `has_more` is true, capped at 10 pages.
**Evidence:** `aiProviderConnectionTest.js:testGemini:76-110,testOpenAICompatible:111-135,testAnthropic:147-189`; `tests\ai-provider-connection-test.test.mjs` scenario 8 (EV-034 envelope, no retry) and scenario 13 (multi-page: model found only on page 2, `after_id` asserted equal to page 1's `last_id`)

### Scope and architecture compliance
**State:** Resolved
**Value:** Only the three owned files changed (`aiProviderConnectionTest.js`, `tests/ai-provider-connection-test.test.mjs`); `tests/verify.mjs` needed no edit because its existing `tests/*.test.mjs` auto-discovery already picked up the new file. No generation adapter, profile schema, manifest, UI, prompt, or dictation file was touched; no chrome API call beyond the existing read-only `SaySlateAIProviderPermissions.hasForEndpoint`.
**Evidence:** `git show --stat 67f557e05c7bce67b200c85da52c0b46e55142bd` (2 files changed: `aiProviderConnectionTest.js`, `tests/ai-provider-connection-test.test.mjs`); `node tests/verify.mjs` output line "23 focused test files passed." includes the new test with no `verify.mjs` edit

### Implementation completeness
**State:** Resolved
**Value:** All three required gates pass on the final committed and pushed tree: `node tests/ai-provider-connection-test.test.mjs`, `node tests/verify.mjs`, `node --check` on both changed `.js`/`.mjs` files, and `git diff --check` against the wave base.
**Evidence:** Branch `agent/sayai-04-provider-connection-tests`, commit `67f557e05c7bce67b200c85da52c0b46e55142bd`, pushed to `origin`; all four gate commands exited 0 against that commit
