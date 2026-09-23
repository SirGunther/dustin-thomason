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

- [x] Implement LD-024's exact provider kinds, transport kinds, preset defaults, lookup,
  normalization, discovery-strategy, and origin-pattern contract as a side-effect-free global.
- [x] Keep Gemini native under LD-015 and map custom/LM Studio to LD-024's OpenAI-compatible
  transport without storing credentials in the registry.
- [x] Implement LD-024's endpoint normalization exactly, including every rejection it lists; do not
  accept any endpoint LD-024 rejects.
- [x] Add `optional_host_permissions` sufficient for runtime HTTPS-origin requests while retaining
  the existing fixed Gemini and loopback Whisper grants.
- [x] Implement LD-024's `ensureForEndpoint` result contract and LD-017's exact-origin permission
  rule using Chrome's EV-023 runtime API.
- [x] Do not request permission while loading, migrating, switching, or merely displaying a profile.
- [x] Return a precise denied-permission outcome; never fall back to a broader origin.
- [x] Test the real public registry/permission modules with a realistic Chrome permissions fake,
  proving the same production call boundary, including
  grant, denial, already granted, invalid endpoint, and no-request-on-load cases.
- [x] Update static verification to accept the intentional optional permission while continuing to
  reject unrelated required host expansion.

## Exit gate

- [x] Every requested provider kind resolves to one explicit preset/transport contract.
- [x] Custom secure endpoints are editable and persist through the SAYAI-01 profile boundary.
- [x] A user gesture requests only the exact configured HTTPS origin; load and migration request
  nothing.
- [x] Gemini and Local Whisper retain their existing fixed access.
- [x] `node tests/ai-provider-registry.test.mjs`, `node tests/ai-provider-permissions.test.mjs`,
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
**State:** Resolved
**Value:** `SaySlateAIProviderRegistry` resolves `gemini`/`openai`/`anthropic`/`custom` to one explicit preset (transport kind, editable default endpoint, discovery strategy) and normalizes any endpoint per LD-024's exact rejection list, as a side-effect-free global with no credential field.
**Evidence:** `aiProviderRegistry.js:PRESETS,presetFor,normalizeEndpoint,originPatternForEndpoint`; `tests/ai-provider-registry.test.mjs` (Scenarios 1–4)

### Optional permission is exact-origin and user initiated
**State:** Resolved
**Value:** `ensureForEndpoint` checks `chrome.permissions.contains` first and requests only the exact normalized origin when absent (never broadening on decline/rejection); `hasForEndpoint` never calls `chrome.permissions.request`; `manifest.json` declares only `optional_host_permissions: ["https://*/*"]` alongside the unchanged fixed `host_permissions`.
**Evidence:** `aiProviderPermissions.js:ensureForEndpoint,hasForEndpoint`; `manifest.json` `optional_host_permissions`; `tests/ai-provider-permissions.test.mjs` (Scenarios 1–6, incl. no-request-on-load)

### Registry and permission production-boundary correctness
**State:** Resolved
**Value:** Focused tests load the real `aiProviderRegistry.js`/`aiProviderPermissions.js` `globalThis` modules via `node:vm` (EV-031 pattern) against a realistic callback-style `chrome.permissions` fake covering grant, decline, API-rejection, already-granted, invalid-endpoint, and repeated-read (no-request) cases, and (post-F1) load the real registry together with the real SAYAI-01 `aiProviderSettings.js` against a shared `chrome.storage.local` fake to prove normalization survives the profile-persistence boundary — the same call boundary SAYAI-04/SAYAI-05 will use.
**Evidence:** `tests/ai-provider-registry.test.mjs` (Scenario 5); `tests/ai-provider-permissions.test.mjs`; both discovered and run by `tests/verify.mjs`

### Scope and architecture compliance
**State:** Resolved
**Value:** Only the ticket's owned files changed — `aiProviderRegistry.js` and `aiProviderPermissions.js` are new; `manifest.json` and `tests/verify.mjs` were edited; `aiProviderSettings.js`, `aiClient.js`, and every UI file are untouched; `host_permissions` is byte-identical to SAYAI-01's merged state, with exactly one `optional_host_permissions` entry added.
**Evidence:** commit `31e671f2d52ca9f22c4fbbc8240d129f5acacf17` (`git show --stat`); `manifest.json` diff limited to the one added line

### Implementation completeness
**State:** Resolved
**Value:** Every build-checklist and exit-gate item is checked; `node tests/ai-provider-registry.test.mjs`, `node tests/ai-provider-permissions.test.mjs`, `node tests/verify.mjs` (19 focused test files), `node --check` on every changed `.js`/`.mjs` file, and `git diff --check` against `3d2ab41f` all pass.
**Evidence:** branch `agent/sayai-02-provider-registry-permissions`, commit `31e671f2d52ca9f22c4fbbc8240d129f5acacf17`, pushed to `origin`

### F1 — Exit gate 2 checked without evidence
**State:** Resolved
**Value:** Added a scenario loading the real `aiProviderRegistry.js` and `aiProviderSettings.js` together against a shared `chrome.storage.local` fake: a custom endpoint normalized through `normalizeEndpoint` persists via `upsertProfile`, survives a fresh-context reload with the identical stored value and origin pattern, and editing it afterward leaves an unrelated Gemini-preset profile's endpoint/credential untouched.
**Evidence:** `tests/ai-provider-registry.test.mjs` Scenario 5 ("Custom endpoint normalization persisting through the SAYAI-01 profile boundary (F1)")

### F2 — Static assertion enforces nothing
**State:** Resolved
**Value:** Replaced the tautological guard in `tests/verify.mjs` with a structural check that `chrome.permissions.request(` appears only inside `requestOrigin`'s body and `requestOrigin(` is called only inside `ensureForEndpoint`'s body; confirmed in a scratch (uncommitted) copy that the real file passes and two injected violating copies each fail with the expected message.
**Evidence:** `tests/verify.mjs` (the `requestOriginFunction`/`permissionsWithoutRequestOriginBody`/`ensureForEndpointFunction`/`permissionsWithoutEnsureForEndpointBody` checks); proof run against real file + 2 injected violations, both failing as expected (not committed)
