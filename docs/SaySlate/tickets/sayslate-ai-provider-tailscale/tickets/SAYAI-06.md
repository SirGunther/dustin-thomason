# SAYAI-06 — Live Tailscale/LM Studio acceptance and closure

**Handoff:** [sayslate-ai-provider-tailscale-handoff.md](../sayslate-ai-provider-tailscale-handoff.md)
**Serves:** REQ-004–REQ-007, REQ-009–REQ-016
**Depends on:** SAYAI-05 merged first
**May run in parallel with:** Nothing
**Branch slug:** `sayai-06-live-acceptance`
**Exclusive production ownership:** `docs/review/ai-provider-tailscale-validation-review.md`, `README.md`, `CHANGELOG.md`, `ROADMAP.md`
**Must not change:** JavaScript, HTML, CSS, manifest, tests, credentials, hostnames, Tailscale configuration, LM Studio configuration, or any implementation behavior

## Goal

Prove REQ-004–REQ-007 and LD-002, LD-012, LD-016–LD-018, and LD-022–LD-029 through the actual loaded
extension and a private Tailscale/LM Studio endpoint, then record an honest release verdict. This
ticket must not repair defects: the handoff's unresolved-work route governs every failed path.

## Build checklist

- [ ] The high-reasoning orchestrator starts from the exact merged SAYAI-05 commit and loads that
  unpacked extension in local Chrome or Edge Developer Mode under handoff rule 6.
- [ ] Confirm the user-provided Tailscale Serve HTTPS endpoint reaches LM Studio privately; never
  record the hostname, token, model credentials, or transcript content in an artifact.
- [ ] Enter the user-provided endpoint, model ID, and Bearer token directly into the extension UI,
  grant only its exact origin, and never copy those values into a prompt, artifact, log, screenshot,
  or commit.
- [ ] Run Test Connection and record its visible status/toast and the non-generative network route.
- [ ] Run first and second pass with representative non-secret text and confirm the returned result
  was schema-validated and rendered on the initiating surface.
- [ ] Repeat one processing pass from Floating Slate.
- [ ] Configure or use a Gemini profile, switch away from custom and back, reload the extension, and
  confirm both profiles retain endpoint/model/credential state without revealing stored keys.
- [ ] Verify closing a surface cancels its in-flight request without losing source text or the last
  completed result.
- [ ] Inspect browser console/network evidence for duplicate calls, broad origin grants, credential
  leakage, raw response logging, or requests to the wrong provider.
- [ ] Run `node tests/verify.mjs` and `git diff --check` against the merged implementation.
- [ ] Write the validation review with exact merged SHA, environment shape without secrets,
  production actions/results, automated gates, limitations, and final verdict.
- [ ] Update project summary files only for capabilities actually proven in this acceptance pass.
- [ ] If any production failure appears, leave the affected objective Unresolved, capture the exact
  failure path and evidence, notify the orchestrator, and stop without changing production code.

## Exit gate

- [ ] The loaded extension reaches private LM Studio through Tailscale and authenticates with its
  configured Bearer token.
- [ ] Test Connection is non-generative and reports the exact model as available.
- [ ] Full-page first/second passes and one Floating Slate pass return validated structured text.
- [ ] Custom and Gemini profiles survive switching and reload without credential disclosure.
- [ ] The extension holds only the exact granted custom origin and emits no secret-bearing log.
- [ ] The validation review and project summaries state only directly observed behavior.
- [ ] No production file changed in this acceptance ticket.

## Out of scope

- Fixing a failure discovered during acceptance.
- Tailscale Funnel/public ingress, provider fallback, retries, background inference, or credential
  synchronization.
- Recording real endpoints, tokens, prompts, transcripts, or model responses in source control.

## Objectives

Complete every objective below in place, using the handoff's Compact Audit Trail Output Rule.
Resolved requires implemented code, direct evidence, and focused verification; intent or partial
implementation is Unresolved.

### Private Tailscale/LM Studio path works end to end
**State:**
**Value:**
**Evidence:**
**Depends on:**

### Provider switching preserves every profile
**State:**
**Value:**
**Evidence:**
**Depends on:**

### Structured output and connection semantics match the decisions
**State:**
**Value:**
**Evidence:**
**Depends on:**

### Live loaded-extension production-path correctness
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
