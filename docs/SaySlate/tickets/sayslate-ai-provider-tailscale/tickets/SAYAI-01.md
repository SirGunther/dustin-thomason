# SAYAI-01 — Provider profile storage and migration

**Handoff:** [sayslate-ai-provider-tailscale-handoff.md](../sayslate-ai-provider-tailscale-handoff.md)
**Serves:** REQ-002, REQ-003, REQ-009–REQ-016
**Depends on:** Nothing
**May run in parallel with:** Nothing
**Branch slug:** `sayai-01-provider-profiles`
**Exclusive production ownership:** `aiProviderSettings.js`, `tests/ai-provider-settings.test.mjs`, `tests/verify.mjs`
**Must not change:** `app.js`, `floating.js`, HTML/CSS, `manifest.json`, provider transports, dictation, prompts, or the legacy setting before migration is invoked

## Goal

Implement the provider-state boundary fixed by LD-014, LD-023, LD-028, and LD-030 for REQ-002 and REQ-003.
Multiple profiles must survive switching independently, while EV-002's legacy Gemini configuration
remains migratable without rewriting UI or network behavior in this ticket.

## Build checklist

- [ ] Implement LD-023's exact version-1 record and `SaySlateAIProviderSettings` public operations as
  a classic global module following EV-025 and LD-028.
- [ ] Enforce LD-014's installation-local, provider-scoped persistence boundary without sync or a
  native credential host.
- [ ] Implement LD-023's explicit `retain`, `replace`, and `clear` credential actions and active-
  profile behavior.
- [ ] Implement LD-023's migration from EV-002's `sayslate-grammar-config` Gemini key/model fields
  into one profile with LD-030's move semantics, without changing prompt fields.
- [ ] Reject unsupported or malformed stored versions without overwriting the stored record, as
  fixed by LD-023.
- [ ] Test the production module through a realistic `chrome.storage.local` fake: create at least two
  profiles, switch repeatedly, reload, replace one key, clear one key, and prove the other profile is
  byte-for-byte unchanged.
- [ ] Test migration twice and prove it creates exactly one Gemini profile and preserves legacy
  prompts.
- [ ] Prove LD-030: after migration the legacy record holds no `apiKey` or `model`; deleting the
  migrated profile, or clearing its credential, then reloading and migrating again recreates nothing.
- [ ] Add the focused test through EV-026's discovery harness without dependencies, per LD-028.

## Exit gate

- [ ] Switching or saving one provider cannot erase another provider's endpoint, model, or key.
- [ ] Reloading the settings module from storage restores every profile and the active-profile ID.
- [ ] Legacy Gemini settings migrate once without changing prompt content.
- [ ] A deleted or credential-cleared migrated profile is never recreated, and no legacy copy of the
  key remains (LD-030).
- [ ] Credentials remain only in `chrome.storage.local`; no log, sync, DOM, or native-host path is
  introduced.
- [ ] `node tests/ai-provider-settings.test.mjs`, `node tests/verify.mjs`, JavaScript syntax checks,
  and `git diff --check` pass.

## Out of scope

- Provider presets and origin permissions (SAYAI-02).
- HTTP requests, structured output, connection testing, or provider UI.
- Encrypting browser-local credentials or introducing a native credential host.

## Objectives

Complete every objective below in place, using the handoff's Compact Audit Trail Output Rule.
Resolved requires implemented code, direct evidence, and focused verification; intent or partial
implementation is Unresolved.

### Provider profiles persist independently
**State:**
**Value:**
**Evidence:**
**Depends on:**

### Legacy Gemini configuration migrates safely
**State:**
**Value:**
**Evidence:**
**Depends on:**

### Public storage boundary correctness
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
