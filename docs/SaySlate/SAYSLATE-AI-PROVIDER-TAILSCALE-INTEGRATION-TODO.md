# SaySlate AI Provider And Tailscale Integration Work Breakdown

**Status:** Stage 1 research and repository grounding complete; Stage 2 architecture and ticket
finalization pending

**Stage 1 starting SHA:** `8fc1ca1d8e2321264c7135171d67b6bf8916bce6`

**Implementation repository:**
`C:\Users\dktho\OneDrive\PDProjects\Browser Extensions\SaySlate`

**Authoritative planning artifact:**
`C:\dustin-thomason\docs\SaySlate\SAYSLATE-AI-PROVIDER-TAILSCALE-INTEGRATION-TODO.md`

**Reference implementation:** `C:\Argus`

**Execution model after Stage 2:** One coordinating high-reasoning model owns architecture,
dispatches narrowly bounded implementation/review subagents, integrates their evidence here, and
continues through the ordered work without pausing merely because a subagent finished.

**Evidence authority:** This artifact, not agent chat, is the durable implementation, review,
resolution, and acceptance record.

## Why this work exists

SaySlate currently has one Gemini-specific AI configuration shared by its full-page and floating
surfaces. Both surfaces read the API key from extension storage and call Gemini directly. Saving the
configuration replaces the one stored record; there is no reusable provider-profile collection,
provider activation, provider-specific connection test, or custom OpenAI-compatible endpoint.

The feature must allow SaySlate to retain and select multiple AI providers, including OpenAI,
Anthropic Claude, Gemini, and a custom OpenAI-compatible provider. The first custom deployment target
is LM Studio on another trusted device reached through Tailscale. Each profile needs its own endpoint,
model identity, authentication, connection status, and structured-output capability without deleting
other profiles or leaking credentials into ordinary UI messages, diagnostics, or request evidence.

This is not merely a settings-form change. The current request is initiated from renderer-like
extension pages, the current Gemini key is stored alongside non-secret prompt settings, and Chrome
Manifest V3 service workers have lifecycle limits that may conflict with slow local-model inference.
Stage 2 must settle those boundaries before a low-reasoning agent changes code.

## Outcome requested

The completed feature should provide:

- A provider control that can list, add, edit, test, activate, and delete reusable provider profiles.
- Profiles for OpenAI-compatible services, native Anthropic Claude, Gemini, and custom endpoints.
- A custom secure profile that reaches LM Studio over a private Tailscale path.
- Provider-scoped endpoints, model IDs, and credentials that persist independently.
- One service-worker-owned `runAI()` boundary; UI surfaces do not perform provider fetches or receive
  stored credentials.
- Bearer authentication where the provider protocol requires it, without assuming every provider
  uses the same headers or request envelope.
- Request-scoped JSON Schema output when the selected provider/model supports it, followed by local
  application validation.
- Clear connection-test results that distinguish reachability, authentication, model availability,
  request compatibility, timeout, and malformed output.
- Migration of the current Gemini configuration without silently deleting or exposing it.
- Real-work acceptance evidence through the actual full-page and floating SaySlate paths.

## Non-goals unless Stage 2 explicitly changes them

- Do not add an MCP server merely to make an inference request.
- Do not expose LM Studio with Tailscale Funnel or another public ingress.
- Do not copy Electron `safeStorage` into a browser-extension design; it is not available there.
- Do not create a provider SDK abstraction for hypothetical protocols that are not in this request.
- Do not replace SaySlate dictation or the existing Local Whisper integration.
- Do not redesign prompts, the two-pass processing workflow, or the SaySlate writing surface.
- Do not make provider failover, load balancing, parallel inference, streaming, or conversation state
  part of the first implementation.
- Do not claim a credential is OS-secure if it is persisted as plain extension storage.

## Governing execution rules

### Visible checklist and durable evidence

- [x] Stage 1 checklist was displayed and maintained in chat.
- [x] The mandatory checklist skill was read from
  `C:\dustin-thomason\agents\skills\checklist-in-chat\SKILL.md`.
- [x] The completion-notification rule was read from
  `C:\dustin-thomason\agents\rules\agent-completion-notification.md`.
- [ ] Every implementation and review agent must display its assigned checklist in chat.
- [ ] Chat must contain checklist state, blockers, branch/SHA pointers, and final disposition only.
- [ ] WHY/HOW/WHAT reasoning, production-path evidence, changed-file evidence, test evidence, review
  findings, and resolved/unresolved decisions must be written into this artifact.
- [ ] A substantive completion or blocker must invoke the required completion notification.

### Evidence standard

Agents must provide evidence that implementations are correct. A passing test proves only that the
test passes. It does not prove that the test represents the real work failure point.

For every change, this artifact must record:

1. **WHY:** the real user path, failure, or capability gap that required the change.
2. **HOW:** the production symbols and data path that own that behavior.
3. **WHAT:** the smallest behavior change that resolves it and the behavior intentionally preserved.
4. **REAL-WORK PROOF:** evidence that the same production path works in the extension, not only in a
   synthetic module test.
5. **FILE EVIDENCE:** every changed file, why it owned part of the behavior, and why the change was
   necessary.
6. **UNRESOLVED WORK:** anything not proved, including live provider acceptance that the agent could
   not perform.

A review must reject a ticket when its primary evidence is merely a mocked test, when the test
bypasses the production path named in WHY, when evidence is absent from this artifact, or when files
outside the authorized scope changed without an explicit escalation record.

### Orchestration and reasoning tiers

- The coordinating high-reasoning model owns architectural decisions, security claims, ticket
  boundaries, dependency ordering, review verdicts, merge order, and unresolved-work triage.
- Low-reasoning implementation agents receive one mechanically verifiable behavior, an exact file
  boundary, explicit invariants, and an exit gate. They do not invent architecture.
- Independent review agents compare the exact implementation SHA with the ticket, production path,
  and this artifact. They do not rely on the implementer's summary.
- Subagent completion is not a pause point. The coordinator records evidence, reviews, merges or
  rejects, and dispatches the next dependency when safe.
- A genuine blocker is recorded in the unresolved register and escalated. It is never hidden by
  checking off a weaker test.
- Each ticket uses an isolated branch/worktree. Implementation agents never merge `main`.
- The coordinator must preserve unrelated user work and compare the final diff to the ticket's
  authorized files before merge.

## Stage 1 — Research and current-state grounding

### Stage 1 checklist

- [x] Ingest the three governing Argus planning artifacts in full.
- [x] Ingest SCRIBE-05A and its asynchronous/lifecycle evidence expectations.
- [x] Inspect the current SaySlate manifest, AI client, full-page UI, floating UI, service worker,
  tests, roadmap, and existing Whisper integration plan.
- [x] Inspect Argus provider configuration, credential scoping, provider testing, OpenAI-compatible
  transport, structured output, and response validation as reference behavior.
- [x] Research official Chrome extension network, permission, storage, messaging, and service-worker
  lifecycle constraints.
- [x] Research official Tailscale Serve, HTTPS, MagicDNS, Services, and access-control behavior.
- [x] Research official LM Studio authentication, server, REST, OpenAI-compatible, and Anthropic-
  compatible surfaces.
- [x] Research official OpenAI, Gemini, and Anthropic request/authentication/structured-output
  differences.
- [x] Separate confirmed requirements from Stage 2 architectural decisions.
- [x] Create the authoritative evidence and unresolved-decision structure in this artifact.
- [ ] Obtain user authorization to begin Stage 2 with the higher-reasoning model.

### Governing artifacts ingested

- `C:\Argus\docs\plans\SCRIBE-PIPELINE-INTEGRATION-TODO.md`
- `C:\Argus\docs\plans\ARGUS-ISOLATED-TICKET-HANDOFF.md`
- `C:\Argus\docs\plans\SCRIBE-STATELESS-REQUEST-HARDENING-TODO.md`
- `C:\dustin-thomason\docs\SaySlate\WHISPER-SERVICE-INTEGRATION-TODO.md`
- `C:\dustin-thomason\docs\reviewers\pr-review-patterns.md`
- `C:\Users\dktho\OneDrive\PDProjects\Browser Extensions\SaySlate\README.md`
- `C:\Users\dktho\OneDrive\PDProjects\Browser Extensions\SaySlate\ROADMAP.md`

### Current SaySlate production path

| Area | Production evidence | Stage 1 conclusion |
| --- | --- | --- |
| Extension permissions | `manifest.json` permits Google Gemini and loopback Whisper hosts only | A Tailscale/custom origin requires a deliberate host-permission strategy |
| Full-page AI call | `app.js` loads `sayslate-grammar-config` and calls `SaySlateAIClient.generate()` | The full-page UI currently owns provider input and dispatch |
| Floating AI call | `floating.js` loads the same record and calls `SaySlateAIClient.generate()` | Both surfaces duplicate the same direct network boundary |
| Gemini transport | `aiClient.js` calls Gemini `generateContent` with the key in the query string | Current transport is provider-specific and cannot represent Claude or OpenAI-compatible profiles safely |
| Stored configuration | One record combines API key, model, prompts, toggle, and schema version | Saving one configuration cannot preserve multiple independent providers |
| Service worker precedent | `background.js` owns Local Whisper token use and returns redacted status | New AI transport should follow this existing worker-owned secret/network boundary |
| Verification | `tests/verify.mjs` hard-codes the current host-permission allow-list and Gemini assumptions | Provider work must change the security assertions intentionally, not bypass them |
| Repository state | SaySlate currently has no `.git` metadata in its implementation folder | Stage 2 must decide the branch/worktree home before dispatch; agents must not pretend isolation exists |

### Argus reference findings

Argus is a reference, not a library to copy blindly.

| Reference behavior | Useful lesson | Do not copy blindly |
| --- | --- | --- |
| Provider kind, endpoint, model, and credential are validated independently | Preserve protocol and security boundaries | Argus currently models one active configuration rather than a reusable profile collection |
| Credentials are bound to provider and canonical endpoint | Changing endpoints must not silently reuse a token | Electron `safeStorage` is unavailable to a Chrome extension |
| Provider requests are made outside the renderer | UI should not receive persisted keys | Electron process lifetime differs from Manifest V3 service-worker lifetime |
| OpenAI-compatible transport sends Bearer auth and request-scoped structured output | LM Studio, OpenAI, and Gemini compatibility can share a bounded adapter | Anthropic native Messages has a different URL, headers, body, response, and structured-output field |
| Responses are validated after provider return | Provider-side schema enforcement is not sufficient | Do not treat absence from the first model-list response as definitive model unavailability |

### Official research findings

#### Chrome extension constraints

- Extension pages and service workers may perform cross-origin `fetch()` only for origins granted by
  host permissions. Content-script requests remain constrained by the page origin. See
  [Cross-origin network requests](https://developer.chrome.com/docs/extensions/develop/concepts/network-requests).
- Runtime-discovered hosts can use optional host permissions and request a specific origin from a
  user gesture. See [Permissions API](https://developer.chrome.com/docs/extensions/reference/api/permissions).
- `chrome.storage.local` persists across browser restarts and can be restricted from content-script
  access, but it is not an OS-backed secret vault. `chrome.storage.session` is memory-only and is not
  exposed to content scripts by default. See
  [Storage API](https://developer.chrome.com/docs/extensions/reference/api/storage).
- Manifest V3 workers are short-lived. Chrome normally terminates a worker when a fetch response
  takes more than 30 seconds to arrive, while local LM Studio inference may exceed that duration. See
  [Extension service-worker lifecycle](https://developer.chrome.com/docs/extensions/develop/concepts/service-workers/lifecycle)
  and [service-worker migration guidance](https://developer.chrome.com/docs/extensions/develop/migrate/to-service-workers).
- Async message responses should use the broadly compatible `return true` plus `sendResponse`
  pattern unless the extension's minimum Chrome version safely permits direct Promise responses.
  See [Message passing](https://developer.chrome.com/docs/extensions/develop/concepts/messaging).

#### Tailscale and LM Studio constraints

- Tailscale Serve can publish a tailnet-only HTTPS URL and reverse proxy it to an application bound
  to loopback. Tailscale Funnel is public and is outside this feature's accepted boundary. See
  [Tailscale Serve](https://tailscale.com/docs/features/tailscale-serve) and
  [Serve CLI](https://tailscale.com/docs/reference/tailscale-cli/serve).
- MagicDNS and Tailscale-issued HTTPS certificates provide a stable `.ts.net` name suitable for an
  extension origin permission. See [MagicDNS](https://tailscale.com/docs/features/magicdns) and
  [HTTPS certificates](https://tailscale.com/docs/how-to/set-up-https-certificates).
- Tailnet access must still be restricted by explicit grants to the serving device/service and
  HTTPS port. Network membership alone is not the complete authorization policy. See
  [Tailscale grants](https://tailscale.com/docs/features/access-control/grants).
- LM Studio supports `/v1/chat/completions`, `/v1/models`, Bearer-token authentication, and native
  OpenAI-compatible and Anthropic-compatible APIs. See
  [OpenAI compatibility](https://lmstudio.ai/docs/developer/openai-compat),
  [authentication](https://lmstudio.ai/docs/developer/core/authentication), and
  [REST API overview](https://lmstudio.ai/docs/developer/rest).

#### Provider protocol constraints

- OpenAI structured output is requested per call with `response_format` and a JSON Schema; local
  validation remains required. See
  [OpenAI Structured Outputs](https://developers.openai.com/api/docs/guides/structured-outputs).
- Gemini exposes an OpenAI-compatible endpoint using Bearer authentication, as well as its native
  API. See [Gemini OpenAI compatibility](https://ai.google.dev/gemini-api/docs/openai) and
  [structured output](https://ai.google.dev/gemini-api/docs/structured-output).
- Anthropic's native Messages API uses `/v1/messages`, requires an Anthropic API version, has its own
  response envelope, and expresses structured output through `output_config.format`. See
  [Anthropic API overview](https://platform.claude.com/docs/en/api/overview),
  [Messages](https://platform.claude.com/docs/en/api/messages/create), and
  [structured outputs](https://platform.claude.com/docs/en/build-with-claude/structured-outputs).

### Confirmed Stage 1 requirements

- [x] Tailscale is the private network transport, not a new AI provider protocol.
- [x] The Tailscale/LM Studio profile should use an OpenAI-compatible adapter unless live provider
  evidence proves that boundary incompatible.
- [x] No API key may be sent from the service worker to the full-page or floating UI.
- [x] Saving or activating one profile must not delete or mutate another profile.
- [x] A credential must be scoped to its profile and canonical provider endpoint.
- [x] Endpoint mutation must not silently transmit an existing credential to the new origin.
- [x] Structured output is a provider/model capability and a per-request behavior, not a global LM
  Studio or Tailscale switch.
- [x] Provider output must be validated locally even when a provider promises schema enforcement.
- [x] Connection testing must report separate reachability, authentication, model, protocol, and
  response-validation outcomes.
- [x] Both SaySlate surfaces must call one worker-owned inference boundary.
- [x] Real acceptance must cover both the full-page and floating production paths.
- [x] Slow LM Studio inference must be tested against the actual Manifest V3 lifetime behavior.

## Stage 2 — High-reasoning architecture and dispatch design

**Status:** Not started. This section is the required entry point after the model switch.

The coordinating model must complete Stage 2 itself. These decisions must not be delegated to a
low-reasoning implementation agent.

### Stage 2 checklist

- [ ] Confirm the exact SaySlate source-control/worktree location before defining branch commands.
- [ ] Choose and document the extension credential threat model.
- [ ] Decide persistent versus per-browser-session credential handling for each provider type.
- [ ] Define the versioned provider-profile schema, active-profile reference, and migration from
  `sayslate-grammar-config`.
- [ ] Define canonical endpoint normalization and credential-binding rules.
- [ ] Choose required versus optional host permissions and the user gesture that grants a custom
  origin.
- [ ] Define provider-adapter interfaces and decide Gemini native versus Gemini OpenAI-compatible
  migration.
- [ ] Define the Anthropic-native adapter boundary without forcing it through an inaccurate
  OpenAI-compatible shape.
- [ ] Define one worker-owned `runAI()` command and renderer-safe request/response messages.
- [ ] Resolve the greater-than-30-second service-worker fetch risk with official-platform evidence
  and a real slow-inference proof plan.
- [ ] Define connection-test semantics for every supported provider family.
- [ ] Define JSON Schema capability negotiation, fallback, validation, and user-visible failure
  categories.
- [ ] Define the private Tailscale Serve topology, HTTPS origin, LM Studio binding/authentication,
  and tailnet grant requirements.
- [ ] Reduce the provisional ticket list below to the smallest independent branch chain.
- [ ] Assign exact authorized files, dependencies, test seams, production acceptance, and evidence
  ledger sections to each ticket.
- [ ] Mark the finalized tickets `Ready for dispatch` and leave all others non-dispatchable.

### Decisions requiring high reasoning

| ID | Decision | Why it cannot be guessed | Stage 2 disposition |
| --- | --- | --- | --- |
| D-01 | Credential persistence | Chrome storage is not Electron `safeStorage`; convenience and real secret-at-rest claims conflict | Pending |
| D-02 | Profile/migration schema | A destructive migration could lose the existing Gemini key, prompts, or selected model | Pending |
| D-03 | Provider protocol families | OpenAI-compatible and Anthropic-native boundaries are materially different | Pending |
| D-04 | Gemini transport | Native Gemini exists today; compatibility mode could simplify adapters but changes request behavior | Pending |
| D-05 | Custom-host permissions | Broad required HTTPS access is easy but excessive; optional origins need a user-grant flow | Pending |
| D-06 | Long inference lifetime | A 30+ second LM Studio response can cross Chrome's documented worker-fetch limit | Pending |
| D-07 | Connection testing | Model-list checks alone can produce false negatives and do not prove structured completion | Pending |
| D-08 | Structured output | Provider/model capability, schema dialect, refusals, and fallback behavior differ | Pending |
| D-09 | Tailscale topology | Serve URL, TLS, LM Studio loopback binding, token auth, and tailnet grants must agree | Pending |
| D-10 | Acceptance/security claims | Live provider testing and storage inspection determine what can honestly be called secure | Pending |

### Stage 2 resolution record template

| Decision | Resolved choice | Alternatives rejected | Production evidence | Consequence for tickets |
| --- | --- | --- | --- | --- |
| Pending | Pending | Pending | Pending | Pending |

## Provisional ticket decomposition

**Not dispatchable until Stage 2 replaces provisional text with exact scope.** The purpose of this
list is to prevent one large agent from mixing storage, transport, UI, network, and live acceptance.

### PROVIDER-01 — Profile store and non-destructive migration

- **Reasoning tier:** Low after D-01 and D-02 are resolved.
- **Intent:** Add a versioned multi-profile record, active-profile ID, and migration from the current
  single Gemini configuration without deleting prompts or credentials.
- **Primary proof:** Existing users retain their current Gemini behavior; saving a second profile
  leaves the first byte-for-byte intact except for explicit migration metadata.
- **Status:** Awaiting Stage 2 specification.

### PROVIDER-02 — Worker-owned inference command and secret boundary

- **Reasoning tier:** Low after D-01, D-03, and D-06 are resolved.
- **Intent:** Move inference ownership behind one background-worker command and remove direct provider
  fetches from both UI surfaces.
- **Primary proof:** Both real surfaces complete the same request while neither receives the stored
  credential; a slow endpoint completes or fails according to the chosen lifecycle policy.
- **Status:** Awaiting Stage 2 specification.

### PROVIDER-03 — OpenAI-compatible and Tailscale/LM Studio adapter

- **Reasoning tier:** Low after D-05, D-06, D-08, and D-09 are resolved.
- **Intent:** Implement the bounded `/v1/chat/completions` path, Bearer auth, schema request, response
  extraction, validation, and sanitized failures for OpenAI-compatible profiles.
- **Primary proof:** A real SaySlate request reaches LM Studio through the approved Tailscale HTTPS
  origin and returns validated output without public exposure or UI-visible credentials.
- **Status:** Awaiting Stage 2 specification.

### PROVIDER-04 — Native provider adapters

- **Reasoning tier:** Low only after D-03, D-04, and D-08 are resolved.
- **Intent:** Preserve or migrate Gemini correctly and add Anthropic Messages without pretending the
  providers share identical request/response contracts.
- **Primary proof:** Real minimal structured requests succeed for the configured provider/model and
  retain the current SaySlate two-pass semantics.
- **Status:** Awaiting Stage 2 specification.

### PROVIDER-05 — Provider profile UI and connection diagnostics

- **Reasoning tier:** Low after storage, permission, and connection-test contracts are fixed.
- **Intent:** Add profile list/add/edit/test/activate/delete behavior to the connection control while
  preserving other profiles and redacting credentials.
- **Primary proof:** UI actions operate through the production worker path; failures distinguish
  reachability, auth, model, protocol, timeout, and response validation.
- **Status:** Awaiting Stage 2 specification.

### PROVIDER-06 — Integrated production acceptance and security review

- **Reasoning tier:** High-reasoning coordinator plus bounded verification subagents.
- **Intent:** Review exact merged SHAs, run full-page/floating/provider/Tailscale acceptance, inspect
  persisted and messaged state for secrets, reconcile documentation, and resolve or ticket every
  remaining failure.
- **Primary proof:** Real calls through the configured providers and the Tailscale-hosted LM Studio
  endpoint, not mocked transports alone.
- **Status:** Awaiting prior ticket completion.

## Per-ticket execution template

Every finalized ticket must include this structure in its own section.

### `<TICKET-ID> — <single outcome>`

- **Status:** Proposed / Ready / Dispatched / Implemented / Reviewed / Merged / Accepted / Blocked
- **Reasoning tier:** High / Low
- **Depends on:** Exact ticket/SHA
- **Branch:** Exact branch
- **Starting SHA:** Pending
- **Authorized production files:** Exact list
- **Authorized tests:** Exact list
- **Out of scope:** Exact exclusions

#### Agent checklist

- [ ] Restate the ticket checklist in chat.
- [ ] Record WHY/HOW/WHAT and the real production path here before editing.
- [ ] Make only the authorized change.
- [ ] Record evidence for every changed file here.
- [ ] Prove the regression exercises the production failure path.
- [ ] Record tests as supporting evidence, not as the correctness claim.
- [ ] Record unresolved live acceptance honestly.
- [ ] Commit and push the isolated branch; do not merge `main`.
- [ ] Notify completion or blocker.

#### Implementation evidence

- **WHY — real behavior or failure:** Pending
- **HOW — owning production symbols:** Pending
- **WHAT — smallest resolution:** Pending
- **Preserved behavior:** Pending
- **Real-work acceptance:** Pending
- **Unresolved evidence:** Pending

| Changed file | Why this file owned the behavior | Exact change | Resulting production behavior |
| --- | --- | --- | --- |
| Pending | Pending | Pending | Pending |

| Verification | Production path exercised | Result | Limitation |
| --- | --- | --- | --- |
| Pending | Pending | Pending | Pending |

#### Independent review

- **Reviewed full SHA:** Pending
- **Ticket fidelity:** Pending
- **Scope verdict:** Pending
- **Security verdict:** Pending
- **Production-path correctness verdict:** Pending
- **Test-relevance verdict:** Pending

| Finding | File/symbol evidence | Required disposition | Resolution |
| --- | --- | --- | --- |
| Pending | Pending | Pending | Pending |

- **Merge verdict:** Pending
- **Merged SHA:** Pending

## Resolved and unresolved request register

This register is mandatory. A request is resolved only when its production behavior and evidence are
recorded; a test or code commit alone does not resolve it.

### Resolved

| Request | Resolution | Evidence | Ticket/SHA |
| --- | --- | --- | --- |
| Stage 1 research and repository grounding | Current paths, platform limits, provider differences, and architecture decisions are identified | Stage 1 sections above | Planning only |

### Unresolved

| Request or risk | Why unresolved | Required resolver | Blocks |
| --- | --- | --- | --- |
| Credential-at-rest guarantee | Browser-extension threat model not selected | Stage 2 D-01 | Profile store and UI claims |
| SaySlate branch/worktree workflow | Implementation directory currently lacks Git metadata | Stage 2 coordinator | All implementation dispatch |
| Slow LM Studio request survival | Chrome documents a 30-second fetch-response lifecycle limit; the final mechanism is unproved | Stage 2 D-06 plus live acceptance | Worker transport |
| Custom-origin permission UX | Required versus optional origin access not selected | Stage 2 D-05 | Tailscale/custom endpoint |
| Provider adapter boundaries | Gemini native/compatibility and Anthropic-native decisions remain | Stage 2 D-03/D-04 | Adapter tickets |
| Structured-output fallback | Capability negotiation and failure policy not selected | Stage 2 D-08 | All provider adapters |
| Tailscale deployment procedure | Actual host name, grants, Serve target, LM Studio auth, and live model remain environment-specific | Stage 2 D-09 and acceptance | Tailscale production claim |
| Real provider acceptance | No implementation exists yet | PROVIDER-06 | Definition of done |

## Final definition of done

This feature is complete only when:

- Multiple provider profiles persist independently and activating one never deletes another.
- Credentials follow the Stage 2 threat model and never cross into renderer-visible messages, logs,
  diagnostics, evidence artifacts, or non-secret exports.
- Full-page and floating SaySlate processing use the same worker-owned request path.
- OpenAI-compatible, Gemini, and Anthropic profiles pass their defined live connection and processing
  checks.
- A custom LM Studio profile works through private Tailscale HTTPS, Bearer authentication, and the
  approved tailnet grant without public ingress.
- Structured output is requested only where supported and every response is validated locally.
- Slow-model behavior is proven against the actual Manifest V3 lifecycle rather than only a mocked
  fetch.
- The existing Gemini configuration migrates without data loss.
- Every implementation SHA has an independent scope/correctness review recorded here.
- Every unresolved request is either resolved with production evidence or remains explicitly open;
  nothing is implied complete by omission.

## Stage 1 handoff

Stage 1 is complete. Do not dispatch the provisional implementation tickets yet. Resume with the
higher-reasoning model at **Stage 2 — High-reasoning architecture and dispatch design**, resolve
D-01 through D-10, convert the smallest necessary ticket chain to `Ready for dispatch`, and preserve
this file as the sole durable execution record.
