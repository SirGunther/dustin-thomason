# SAYAI-02 — Provider registry and optional origin permissions

**Handoff:** [sayslate-ai-provider-tailscale-handoff.md](../sayslate-ai-provider-tailscale-handoff.md)
**Serves:** REQ-001, REQ-002, REQ-005, REQ-008, REQ-009–REQ-016
**Depends on:** SAYAI-01 merged first
**May run in parallel with:** Nothing
**Branch slug:** `sayai-02-provider-registry-permissions`
**Exclusive production ownership:** `aiProviderRegistry.js`, `aiProviderPermissions.js`, `manifest.json`, `tests/ai-provider-registry.test.mjs`, `tests/ai-provider-permissions.test.mjs`, `tests/verify.mjs`
**Must not change:** Provider-profile schema from SAYAI-01, `aiClient.js`, UI files, inference routing, dictation, or broad install-time host access

## Goal

Implement LD-017, LD-024, and LD-028 against LD-023's profile shape for REQ-001, REQ-002, and REQ-005. The registry and permission
seam must support editable provider presets and private HTTPS Tailscale/LM Studio origins without
granting every external host at installation.

## Build checklist

- [ ] Implement LD-024's exact provider kinds, transport kinds, preset defaults, lookup,
  normalization, discovery-strategy, and origin-pattern contract as a side-effect-free global.
- [ ] Keep Gemini native under LD-015 and map custom/LM Studio to LD-024's OpenAI-compatible
  transport without storing credentials in the registry.
- [ ] Implement LD-024's endpoint normalization exactly, including every rejection it lists; do not
  accept any endpoint LD-024 rejects.
- [ ] Add `optional_host_permissions` sufficient for runtime HTTPS-origin requests while retaining
  the existing fixed Gemini and loopback Whisper grants.
- [ ] Implement LD-024's `ensureForEndpoint` result contract and LD-017's exact-origin permission
  rule using Chrome's EV-023 runtime API.
- [ ] Do not request permission while loading, migrating, switching, or merely displaying a profile.
- [ ] Return a precise denied-permission outcome; never fall back to a broader origin.
- [ ] Test the real public registry/permission modules with a realistic Chrome permissions fake,
  proving the same production call boundary, including
  grant, denial, already granted, invalid endpoint, and no-request-on-load cases.
- [ ] Update static verification to accept the intentional optional permission while continuing to
  reject unrelated required host expansion.

## Exit gate

- [ ] Every requested provider kind resolves to one explicit preset/transport contract.
- [ ] Custom secure endpoints are editable and persist through the SAYAI-01 profile boundary.
- [ ] A user gesture requests only the exact configured HTTPS origin; load and migration request
  nothing.
- [ ] Gemini and Local Whisper retain their existing fixed access.
- [ ] `node tests/ai-provider-registry.test.mjs`, `node tests/ai-provider-permissions.test.mjs`,
  `node tests/verify.mjs`, JavaScript syntax checks, and `git diff --check` pass.

## Out of scope

- Sending provider requests or validating provider responses (SAYAI-03).
- Test Connection operations (SAYAI-04).
- Rendering or integrating provider settings UI (SAYAI-05).
- Tailscale administration, Funnel, certificate setup, or public ingress.

## Objectives

Complete every objective below in place, using the handoff's Compact Audit Trail Output Rule.
Resolved requires implemented code, direct evidence, and focused verification; intent or partial
implementation is Unresolved.

### Provider registry is explicit and editable
**State:**
**Value:**
**Evidence:**
**Depends on:**

### Optional permission is exact-origin and user initiated
**State:**
**Value:**
**Evidence:**
**Depends on:**

### Registry and permission production-boundary correctness
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
