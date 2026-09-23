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

- [ ] Implement LD-026's exact `SaySlateAIProviderConnectionTest.test` input and result contract.
- [ ] Fail before network access when endpoint, model, credential, or host permission is missing for
  the selected provider.
- [ ] Use LD-024's discovery strategies and EV-020/EV-021 provider model operations; no UI code may
  construct a discovery URL.
- [ ] Verify the exact configured model ID is present or retrievable; distinguish an unavailable
  model from an unreachable service.
- [ ] Return only LD-026's fixed codes/shape and bounded message; never include a credential, full
  response body, prompt, or transcript.
- [ ] Apply LD-026's 15-second default timeout and prove it aborts cleanly.
- [ ] Test production code with realistic provider response envelopes and HTTP status codes,
  including 401/403 and a reachable endpoint whose selected model is absent.
- [ ] Assert no connection-test case calls a generation endpoint or includes transcript text.

## Exit gate

- [ ] A correct configuration can be confirmed without inference.
- [ ] Reachability, authentication, permission, and selected-model failures are distinguishable.
- [ ] No test-connection request contains user content or generates model output.
- [ ] The result contains no secret or unbounded provider response.
- [ ] `node tests/ai-provider-connection-test.test.mjs`, `node tests/verify.mjs`, JavaScript syntax
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
**State:**
**Value:**
**Evidence:**
**Depends on:**

### Secrets and user content stay outside diagnostics
**State:**
**Value:**
**Evidence:**
**Depends on:**

### Provider discovery production-boundary correctness
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
