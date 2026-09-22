# SaySlate AI Provider and Tailscale Integration — Requirements

Origin: [Original ticket](./sayslate-ai-provider-tailscale-original-ticket.md)

## Requirements

| ID | Condition that must be true | Source | Served by |
| --- | --- | --- | --- |
| REQ-001 | SaySlate's connection control supports OpenAI, Anthropic Claude, Gemini, and a custom provider. | [Original ticket](./sayslate-ai-provider-tailscale-original-ticket.md), “multiple types of apis” | Pending confirmed ticket order |
| REQ-002 | Each provider configuration can hold the endpoint/base URL, model ID, and authentication value required by that provider. | [Original ticket](./sayslate-ai-provider-tailscale-original-ticket.md), rough MVP settings and “all the various keys, model ids” | Pending confirmed ticket order |
| REQ-003 | Within one installed extension/browser profile, multiple provider configurations persist locally and independently; saving or selecting one does not erase another provider's endpoint, model ID, or key. Configuration is not synchronized between installations, and no native credential host is introduced. | Dustin Thomason, 2026-09-22 clarification; LD-014 | Pending confirmed ticket order |
| REQ-004 | A user can test a configured provider connection and receive a useful outcome. | [Original ticket](./sayslate-ai-provider-tailscale-original-ticket.md), “be able to test the connection” | Pending confirmed ticket order |
| REQ-005 | A custom provider can reach LM Studio through a private Tailscale network path. | [Original ticket](./sayslate-ai-provider-tailscale-original-ticket.md), paragraphs 1–2 | Pending confirmed ticket order |
| REQ-006 | The Tailscale/LM Studio request path supports Bearer-token authentication when the endpoint requires it. | [Original ticket](./sayslate-ai-provider-tailscale-original-ticket.md), rough MVP authentication | Pending confirmed ticket order |
| REQ-007 | AI requests ask for JSON Schema-constrained output whenever the selected provider and model support it, and SaySlate validates the returned result. | [Original ticket](./sayslate-ai-provider-tailscale-original-ticket.md), “JSON schema whenever possible” | Pending confirmed ticket order |
| REQ-008 | Argus's existing LM Studio integration is treated as read-only reference evidence rather than copied without reconciling Electron and browser-extension differences. | [Original ticket](./sayslate-ai-provider-tailscale-original-ticket.md), paragraph 1; EV-009–EV-010 | Pending confirmed ticket order |
| REQ-009 | The high-reasoning orchestrator owns architecture, sequencing, review, merge decisions, and unresolved-work triage; bounded low-reasoning agents implement individual tickets. | [Original ticket](./sayslate-ai-provider-tailscale-original-ticket.md), orchestration paragraphs | Pending confirmed ticket order |
| REQ-010 | Subagent completion does not pause the orchestration; the main model reviews the result and continues or records a blocker. | [Original ticket](./sayslate-ai-provider-tailscale-original-ticket.md), “ignore the pause portion” | Pending confirmed ticket order |
| REQ-011 | Every agent displays and maintains its assigned checklist in chat. | [Original ticket](./sayslate-ai-provider-tailscale-original-ticket.md), mandatory checklist passages | Pending confirmed ticket order |
| REQ-012 | Every substantive completion or blocker sends the required completion notification. | [Original ticket](./sayslate-ai-provider-tailscale-original-ticket.md), notification-rule path | Pending confirmed ticket order |
| REQ-013 | Origin, requirements, decisions, handoff, ticket files, and audit records live under one nested ticket folder. | Dustin Thomason, 2026-09-22 clarification invoking `agentic-handoff` | Pending confirmed ticket order |
| REQ-014 | Ticket objectives and findings use the compact `State` / `Value` / `Evidence` / `Depends on` audit format. | Dustin Thomason, 2026-09-22 clarification citing `PRDV-16936-CASE-DETAIL-PROTOTYPE-TODO.md` | Pending confirmed ticket order |
| REQ-015 | Correctness evidence traces the real production failure or user path; test success alone is not sufficient evidence. | Dustin Thomason, 2026-09-22 clarification on real-work failure points | Pending confirmed ticket order |

## Evidence

| ID | Fact about what exists | Direct pointer |
| --- | --- | --- |
| EV-001 | SaySlate is a Manifest V3 extension whose background worker is `background.js`; current hosts are Google Gemini and loopback Whisper only. | `SaySlate/manifest.json:2,8,12-14` — `"manifest_version": 3`, `"service_worker": "background.js"` |
| EV-002 | The full-page surface stores one combined processing record under `sayslate-grammar-config`. | `SaySlate/app.js:6,252-267,343-354` — `PROCESSING_CONFIG_KEY = "sayslate-grammar-config"` |
| EV-003 | The full-page surface passes the stored key and model directly to the Gemini client for both processing passes. | `SaySlate/app.js:525-527,574-576` — `SaySlateAIClient.generate({ apiKey, model, ... })` |
| EV-004 | The floating surface reads the same combined record and also calls the Gemini client directly. | `SaySlate/floating.js:4,55-58,221-223,254-256` |
| EV-005 | The current AI client is Gemini-native and places the API key in the request URL. | `SaySlate/aiClient.js:4,22-35` — `generateContent?key=...` |
| EV-006 | The existing service worker already owns asynchronous Local Whisper requests and preserves the message channel with `return true`. | `SaySlate/background.js:218-256` |
| EV-007 | Static verification currently enforces exactly two hosts and requires the Gemini-native client. | `SaySlate/tests/verify.mjs:36-40,340-342` |
| EV-008 | Before repository migration, the original SaySlate implementation directory had no Git worktree or repository metadata. | `git -C "C:\Users\dktho\OneDrive\PDProjects\Browser Extensions\SaySlate" rev-parse --show-toplevel` → `fatal: not a git repository` on 2026-09-22; superseded operationally by EV-016 |
| EV-009 | Argus models local LM Studio and external OpenAI-compatible endpoints as non-secret configuration. | `C:\Argus\runtime\model-provider-settings.mjs:20-36,43-80` |
| EV-010 | Argus's credential store is Electron-specific and uses `safeStorage`; that mechanism is not available to a Chrome extension. | `C:\Argus\runtime\model-provider-settings.mjs:180-222` — `createSafeStorageCredentialStore` |
| EV-011 | Chrome documents worker termination when “a fetch() response takes more than 30 seconds to arrive.” | [Chrome extension service-worker lifecycle](https://developer.chrome.com/docs/extensions/develop/concepts/service-workers/lifecycle) |
| EV-012 | Extension service workers need host permission for cross-origin requests. | [Chrome cross-origin network requests](https://developer.chrome.com/docs/extensions/develop/concepts/network-requests) |
| EV-013 | Tailscale Serve can proxy tailnet traffic to a local service without using public Funnel ingress. | [Tailscale Serve](https://tailscale.com/docs/features/tailscale-serve) |
| EV-014 | LM Studio exposes OpenAI-compatible `/v1/chat/completions` and supports Bearer-token authentication. | [LM Studio OpenAI compatibility](https://lmstudio.ai/docs/developer/openai-compat); [authentication](https://lmstudio.ai/docs/developer/core/authentication) |
| EV-015 | SaySlate's existing full verification entry point is `node tests/verify.mjs`. | `SaySlate/docs/review/v1.12.0-whisperservice-local-dictation-validation-review.md:39,61-62` |
| EV-016 | SaySlate now has a canonical Git worktree at `C:\SaySlate`, remote `SirGunther/SaySlate`, with the audited original source committed and pushed on `main`. | `C:\SaySlate`; commit `af9a2f3a8cbad88c22edc094767b5cdd31f1a24e`; local and `origin/main` verified equal on 2026-09-22 |

`SaySlate/...` pointers above are relative to
`C:\Users\dktho\OneDrive\PDProjects\Browser Extensions\SaySlate`.

## Scope Boundary

| Repository or path | Access | Basis |
| --- | --- | --- |
| `C:\dustin-thomason\docs\SaySlate\tickets\sayslate-ai-provider-tailscale\` | Writable by the document author/orchestrator under the one-writer rules | REQ-013 |
| `C:\SaySlate` | Writable implementation repository through isolated ticket branches/worktrees | EV-016; LD-013 |
| `C:\Users\dktho\OneDrive\PDProjects\Browser Extensions\SaySlate` | Read-only preserved import source | EV-008 and EV-016; canonical work moved to `C:\SaySlate` |
| `C:\Argus` | Read-only reference | REQ-008 |
| `C:\dustin-thomason\docs\SaySlate\SAYSLATE-AI-PROVIDER-TAILSCALE-INTEGRATION-TODO.md` | Read-only comparison artifact | User requested a rewrite for comparison, not deletion |
| `C:\dustin-thomason\docs\SaySlate\WHISPER-SERVICE-INTEGRATION-TODO.md` | Read-only precedent | Existing SaySlate handoff evidence |
| Any `dnu\` folder | Excluded | `agentic-handoff` rule |

## Readiness

| Prerequisite | Status | Evidence or blocker |
| --- | --- | --- |
| Immutable origin | Met | [Original ticket](./sayslate-ai-provider-tailscale-original-ticket.md) |
| Requirements and current-state evidence | Met for foundation; ticket coverage pending | REQ-001–REQ-015 and EV-001–EV-015 above |
| Sourced decisions ledger | Partially met | [Decisions](./sayslate-ai-provider-tailscale-decisions.md); open decisions remain |
| SaySlate Git base | Met | EV-016; `main` at `af9a2f3a8cbad88c22edc094767b5cdd31f1a24e` in `C:\SaySlate` and `origin/main` |
| Provider persistence boundary | Met | LD-014; provider-scoped `chrome.storage.local`, no sync and no native credential host |
| Gemini transport direction | Met | LD-015; retain the working native adapter unless a demonstrated incompatibility requires change |
| Ticket branch and worktree convention | Ready to define after delivery-order confirmation | Canonical repository and base are now known; exact ticket slugs depend on the confirmed order |
| Delivery order confirmation | Unmet | No exact ticket/wave order has been confirmed by the user |
| Gate command | Met | EV-015; `node tests/verify.mjs` |
| Live Tailscale/LM Studio acceptance environment | Deferred, not a planning blocker | Hostname, grant, LM Studio token, and model are intentionally not recorded in planning artifacts |
