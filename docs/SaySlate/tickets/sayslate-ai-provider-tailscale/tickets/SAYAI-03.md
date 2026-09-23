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

- [ ] Export LD-022's immutable canonical schema and implement LD-025's exact dispatcher signature,
  return type, and bounded error codes.
- [ ] Select adapters only through LD-024's registered transport kind; never infer a transport from
  an arbitrary URL.
- [ ] Preserve Gemini's native Generate Content endpoint and add its native response schema/mime
  configuration where supported.
- [ ] Add EV-020/EV-014's OpenAI-compatible `/v1/chat/completions` adapter with conditional Bearer
  authentication and LD-022's strict schema.
- [ ] Use the same OpenAI-compatible adapter for OpenAI and custom/LM Studio profiles without adding
  provider-specific behavior to UI code.
- [ ] Add EV-021's Anthropic Messages adapter with current required authentication/version headers and
  `output_config.format` structured output; because SaySlate intentionally performs browser-direct
  calls, include Anthropic's explicit dangerous-direct-browser acknowledgement header.
- [ ] Retain EV-017/LD-016's existing 90-second abort and renderer-owned request lifetime.
- [ ] Enforce LD-022 and LD-025 validation/error boundaries before returning any text.
- [ ] Implement LD-031's single schema-free retry after an HTTP 400 or 422 to a schema request,
  accepting only trimmed non-empty text; accept no other unvalidated free-form output.
- [ ] Test each production adapter through mocked fetch at its public production entry point,
  proving the dispatcher-to-adapter path while asserting exact
  URL, headers, request schema, abort handling, valid result, malformed JSON, schema mismatch,
  authentication failure, provider error, and LD-031 retry behavior.
- [ ] Prove the dispatcher returns the same plain string shape expected by the existing first- and
  second-pass call sites.

## Exit gate

- [ ] Gemini still uses its native endpoint and its existing successful behavior remains covered.
- [ ] OpenAI, Claude, and custom/LM Studio requests use their governed request and authentication
  shapes.
- [ ] Supported providers receive the canonical schema and invalid results cannot reach UI code.
- [ ] No adapter logs or returns a credential; adapter code reads only the selected profile's
  locally persisted credential at call time.
- [ ] Focused adapter tests, `node tests/verify.mjs`, JavaScript syntax checks, and
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
**State:**
**Value:**
**Evidence:**
**Depends on:**

### Structured results are validated and normalized
**State:**
**Value:**
**Evidence:**
**Depends on:**

### Provider HTTP production-boundary correctness
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
