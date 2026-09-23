# SAYAI-05 — Provider settings UI and runtime integration

**Handoff:** [sayslate-ai-provider-tailscale-handoff.md](../sayslate-ai-provider-tailscale-handoff.md)
**Serves:** REQ-001–REQ-005, REQ-009–REQ-016
**Depends on:** SAYAI-04 merged first
**May run in parallel with:** Nothing
**Branch slug:** `sayai-05-provider-ui-integration`
**Exclusive production ownership:** `app.html`, `app.css`, `app.js`, `floating.html`, `floating.css`, `floating.js`, `tests/app-dictation-integration.test.mjs`, `tests/floating-dictation-integration.test.mjs`, `tests/ai-provider-ui.test.mjs`, `tests/verify.mjs`
**Must not change:** Provider/profile/permission/transport module contracts, dictation behavior, prompt content, background/offscreen runtime, extension icons, or unrelated layout

## Goal

Integrate LD-023–LD-027 into SaySlate's existing connection settings and both renderer-owned AI pass
surfaces for REQ-001–REQ-005. The result must implement LD-027's management surface without losing
another profile, while preserving EV-003/EV-004's processing flows and existing dictation/prompts.

## Build checklist

- [ ] Load the LD-023–LD-026 global modules before their consumers in both HTML surfaces, following
  EV-025 and LD-028.
- [ ] Replace the single Gemini-only connection form with a compact provider-profile control under
  the existing connection icon; preserve the current visual system rather than redesigning it.
- [ ] Implement exactly LD-027's full-page provider controls and floating-surface ownership.
- [ ] Use preset endpoints as editable starting values; never overwrite a user's saved endpoint when
  switching away and back.
- [ ] Enforce LD-023/LD-027 credential retain, clear, and non-reveal behavior.
- [ ] Request an optional origin permission only from the user-triggered Save or Test action when the
  endpoint requires it, and surface denial without changing the active profile.
- [ ] Wire LD-026's Test Connection result to the disabled/in-progress state, inline status, and
  LD-018 transient notification behavior.
- [ ] Route first and second pass through LD-025's dispatcher in both full-page and floating surfaces.
- [ ] Preserve the source text and last completed result on provider error; show a bounded useful
  error without secrets or raw response bodies.
- [ ] Preserve both prompt fields, optional second pass, shortcuts, copy/discard, dictation, and the
  current renderer-owned request lifetime.
- [ ] Invoke LD-030's migration on first load and prove the user can run the same Gemini path
  without re-entering the key, and that a deleted Gemini profile stays deleted after reload.
- [ ] Test the production UI controllers with realistic DOM/storage/fetch/permissions fakes: create
  Gemini and custom profiles, switch both directions, reload, test each, run both passes, delete one,
  and prove the survivor remains unchanged.
- [ ] As assigned by handoff rule 6, load the unpacked extension in local Chrome or Edge Developer
  Mode and inspect the real settings surface, focus order,
  masked credential behavior, status/toast states, and full/floating processing controls.

## Exit gate

- [ ] OpenAI, Claude, Gemini, and custom provider profiles can be selected and configured from the
  existing connection surface.
- [ ] Switching, editing, testing, or deleting one profile never erases another.
- [ ] Both AI passes on both surfaces route through the active profile and return validated text.
- [ ] Connection status is specific and non-generative; inference errors preserve user work.
- [ ] Dictation, prompts, shortcuts, copy/discard, and legacy Gemini migration still work.
- [ ] Focused UI/integration tests, `node tests/verify.mjs`, JavaScript syntax checks,
  `git diff --check`, and the loaded-extension browser check pass.

## Out of scope

- New provider contracts, fallback/failover, retry policy, background inference, or a credential host.
- Tailscale/LM Studio environment administration and live remote acceptance (SAYAI-06).
- General visual redesign or unrelated UI cleanup.

## Objectives

Complete every objective below in place, using the handoff's Compact Audit Trail Output Rule.
Resolved requires implemented code, direct evidence, and focused verification; intent or partial
implementation is Unresolved.

### Provider profiles are manageable without destructive switching
**State:**
**Value:**
**Evidence:**
**Depends on:**

### Both SaySlate surfaces use the active provider
**State:**
**Value:**
**Evidence:**
**Depends on:**

### Existing workflows remain intact
**State:**
**Value:**
**Evidence:**
**Depends on:**

### Integrated renderer production-path correctness
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
