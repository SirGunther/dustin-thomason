# SaySlate AI Provider and Tailscale Integration — Requirements

Origin: [Original ticket](./sayslate-ai-provider-tailscale-original-ticket.md)

## Requirements

| ID | Condition that must be true | Source |
| --- | --- | --- |
| REQ-001 | SaySlate's connection control supports OpenAI, Anthropic Claude, Gemini, and a custom provider. | [Original ticket](./sayslate-ai-provider-tailscale-original-ticket.md), “multiple types of apis” |
| REQ-002 | Each provider configuration can hold the endpoint/base URL, model ID, and authentication value required by that provider. | [Original ticket](./sayslate-ai-provider-tailscale-original-ticket.md), rough MVP settings and “all the various keys, model ids” |
| REQ-003 | Within one installed extension/browser profile, multiple provider configurations persist locally and independently; saving or selecting one does not erase another provider's endpoint, model ID, or key. Configuration is not synchronized between installations, and no native credential host is introduced. | Dustin Thomason, 2026-09-22 clarification |
| REQ-004 | A user can test a configured provider connection and receive a useful outcome. | [Original ticket](./sayslate-ai-provider-tailscale-original-ticket.md), “be able to test the connection” |
| REQ-005 | A custom provider can reach LM Studio through a private Tailscale network path. | [Original ticket](./sayslate-ai-provider-tailscale-original-ticket.md), paragraphs 1–2 |
| REQ-006 | The Tailscale/LM Studio request path supports Bearer-token authentication when the endpoint requires it. | [Original ticket](./sayslate-ai-provider-tailscale-original-ticket.md), rough MVP authentication |
| REQ-007 | AI requests ask for JSON Schema-constrained output whenever the selected provider and model support it, and SaySlate validates the returned result. | [Original ticket](./sayslate-ai-provider-tailscale-original-ticket.md), “JSON schema whenever possible” |
| REQ-008 | Argus's existing LM Studio integration is treated as read-only reference evidence rather than copied without reconciling Electron and browser-extension differences. | [Original ticket](./sayslate-ai-provider-tailscale-original-ticket.md), paragraph 1 |
| REQ-009 | The high-reasoning orchestrator owns architecture, sequencing, review, merge decisions, and unresolved-work triage; bounded low-reasoning agents implement individual tickets. | [Original ticket](./sayslate-ai-provider-tailscale-original-ticket.md), orchestration paragraphs |
| REQ-010 | Subagent completion does not pause the orchestration; the main model reviews the result and continues or records a blocker. | [Original ticket](./sayslate-ai-provider-tailscale-original-ticket.md), “ignore the pause portion” |
| REQ-011 | Every agent displays and maintains its assigned checklist in chat. | [Original ticket](./sayslate-ai-provider-tailscale-original-ticket.md), mandatory checklist passages |
| REQ-012 | Every substantive completion or blocker sends the required completion notification. | [Original ticket](./sayslate-ai-provider-tailscale-original-ticket.md), notification-rule path |
| REQ-013 | Origin, requirements, decisions, handoff, ticket files, and audit records live under one nested ticket folder. | Dustin Thomason, 2026-09-22 clarification invoking `agentic-handoff` |
| REQ-014 | Ticket objectives and findings use the compact `State` / `Value` / `Evidence` / `Depends on` audit format. | Dustin Thomason, 2026-09-22 clarification citing `PRDV-16936-CASE-DETAIL-PROTOTYPE-TODO.md` |
| REQ-015 | Correctness evidence traces the real production failure or user path; test success alone is not sufficient evidence. | Dustin Thomason, 2026-09-22 clarification on real-work failure points |
| REQ-016 | The author completes the foundation, ticket decomposition, ticket files, and handoff as one high-reasoning authoring process. Model tiering begins only after that complete handoff reaches a high-reasoning orchestrator, which dispatches bounded tickets to lower-reasoning implementation agents. | Dustin Thomason, 2026-09-22 clarification |

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
| EV-017 | Current Gemini inference is owned by the initiating full-page or floating renderer, not the service worker, and the client applies a 90-second timeout. Closing or destroying that renderer would also destroy its in-flight request. | `C:\SaySlate\aiClient.js:5,22-69`; `C:\SaySlate\app.js:525-529`; `C:\SaySlate\floating.js:213-239,242-272`; `C:\SaySlate\background.js:218-282` contains no AI-inference route |
| EV-018 | SaySlate currently declares exactly two fixed host permissions, and static verification rejects any different host list. It does not declare `optional_host_permissions` or call `chrome.permissions.request`. | `C:\SaySlate\manifest.json:7-8`; `C:\SaySlate\tests\verify.mjs:32-40`; repository search on 2026-09-22 found no `optional_host_permissions` or `permissions.request` |
| EV-019 | SaySlate has a concrete Local Whisper health check but no corresponding AI-provider connection test. Its Gemini client exposes only the real generation call. | `C:\SaySlate\app.js:800-819`; `C:\SaySlate\whisperServiceClient.js:547-574`; `C:\SaySlate\aiClient.js:22-73` |
| EV-020 | OpenAI exposes `GET /v1/models` with Bearer authentication, and its Responses/Chat APIs can request JSON Schema-constrained output. | [OpenAI Models API](https://platform.openai.com/docs/api-reference/models/object?lang=curl); [OpenAI Structured Outputs](https://platform.openai.com/docs/guides/structured-outputs) |
| EV-021 | Anthropic exposes `GET /v1/models`, accepts Bearer API-key authentication with the required `anthropic-version` header, and uses `output_config.format` for JSON Schema output. (Authentication clause corrected by EV-033: API keys use `x-api-key`.) | [Claude API overview](https://platform.claude.com/docs/en/api/overview); [Claude Models API](https://platform.claude.com/docs/en/api/models); [Claude structured outputs](https://platform.claude.com/docs/en/build-with-claude/structured-outputs) |
| EV-022 | Gemini's native Generate Content API supports schema-constrained JSON output, allowing the existing native adapter to remain in place. | [Gemini structured outputs](https://ai.google.dev/gemini-api/docs/structured-output); [Gemini Generate Content API](https://ai.google.dev/api/generate-content) |
| EV-023 | Chrome extensions can declare broad optional origin capability but request only a specific origin at runtime; cross-origin extension requests still require a granted host permission. | [Chrome permissions API](https://developer.chrome.com/docs/extensions/reference/api/permissions); [Chrome cross-origin requests](https://developer.chrome.com/docs/extensions/develop/concepts/network-requests) |
| EV-024 | Anthropic's official TypeScript client disables browser use by default because client-side credentials are extractable; explicitly enabled browser requests add the `anthropic-dangerous-direct-browser-access` acknowledgement. | [Anthropic TypeScript client browser guard](https://github.com/anthropics/anthropic-sdk-typescript/blob/main/src/client.ts) |
| EV-025 | SaySlate uses classic browser scripts in declared order, and modules expose browser globals rather than ES-module imports. | `C:\SaySlate\app.html:370-375`; `C:\SaySlate\floating.html:64-68`; `C:\SaySlate\aiClient.js:73` — `globalThis.SaySlateAIClient = { generate }` |
| EV-026 | `tests/verify.mjs` discovers and executes every `tests/*.test.mjs` file before running static repository assertions. | `C:\SaySlate\tests\verify.mjs:1-18` |
| EV-027 | SaySlate has no `package.json`; its current JavaScript and tests run without an installed package dependency graph. | `C:\SaySlate` repository root inspection on 2026-09-22; `package.json` absent; EV-026 |
| EV-028 | SaySlate has no repository-local `AGENTS.md`, `CLAUDE.md`, `.agents`, or `.codex` instruction source. | Recursive `C:\SaySlate` repository inspection on 2026-09-22 |
| EV-029 | The full-page renderer already owns a connection-icon settings panel with key/model inputs, configured status, error region, and the shared toast mechanism; it currently rehydrates the stored Gemini key into the input. | `C:\SaySlate\app.html:48-122,363-367`; `C:\SaySlate\app.js:32-56,118-119,232-236,281-286,332-361` |
| EV-030 | SaySlate keeps validation records under `docs/review`, maintains current capability text in `README.md`, and records pending work in `[Unreleased]` within `CHANGELOG.md`; `ROADMAP.md` also exists as a project summary surface. | `C:\SaySlate\docs\review\`; `C:\SaySlate\README.md`; `C:\SaySlate\CHANGELOG.md:15`; `C:\SaySlate\ROADMAP.md` |
| EV-031 | Focused tests load a classic global script by reading its source and running it in a `node:vm` context with injected browser globals, then read the exposed `globalThis` module. | `C:\SaySlate\tests\ai-client.test.mjs:1-21` — `vm.createContext(context); vm.runInContext(source, context); return context.SaySlateAIClient;` |
| EV-032 | A local Playwright installation (`playwright` 1.61.1) with downloaded Chromium builds exists outside the SaySlate repository and can launch Chromium with an unpacked extension loaded. | `C:\dustin-thomason\scripts\browser\package.json` — `"playwright": "^1.49.0"`; installed version 1.61.1 in `C:\dustin-thomason\scripts\browser\node_modules`; Chromium builds under `%LOCALAPPDATA%\ms-playwright` on 2026-09-22 |
| EV-033 | Anthropic API-key requests authenticate with `x-api-key` plus `anthropic-version: 2023-06-01`. `Authorization: Bearer` is the OAuth-token path and requires `anthropic-beta: oauth-2025-04-20`, so EV-021's Bearer wording does not apply to API keys. Structured output is `output_config: { format: { type: "json_schema", schema } }`. `max_tokens` is required, and about 16000 is the documented non-streaming default. `temperature`, `top_p`, and `top_k` return HTTP 400 on current Claude models. A response can end with `stop_reason` `refusal` or `max_tokens`. `GET /v1/models` paginates with `has_more`, `last_id`, and `after_id`. | Claude API reference bundled with the `claude-api` skill (Claude Code 2.1.280), read 2026-09-22: `curl/examples.md` (x-api-key and anthropic-version headers on every example); `SKILL.md` Authentication, Thinking & Effort table (Sampling column: Removed - 400), Common Pitfalls (`max_tokens`, `output_config.format`); `shared/model-migration.md` (`output_config.format` json_schema); `shared/managed-agents-api-reference.md` (Models pagination `after_id` / `has_more`) |

`SaySlate/...` pointers above are relative to
`C:\SaySlate`.

## Scope Boundary

| Repository or path | Access | Basis |
| --- | --- | --- |
| `C:\dustin-thomason\docs\SaySlate\tickets\sayslate-ai-provider-tailscale\` | Writable by the document author/orchestrator under the one-writer rules | REQ-013 |
| `C:\SaySlate` | Writable implementation repository through isolated ticket branches/worktrees | EV-016 |
| `C:\SaySlate-worktrees\` | Writable; one isolated worktree per ticket, created by the implementation agent | EV-016 |
| `C:\dustin-thomason\scripts\browser\` | Read-only verification tool; run, never modified | EV-032 |
| `C:\Users\dktho\OneDrive\PDProjects\Browser Extensions\SaySlate` | Excluded from active source and evidence gathering | Dustin Thomason, 2026-09-22 clarification; the user may delete it after validation |
| `C:\Argus` | Read-only reference | REQ-008 |
| `C:\dustin-thomason\docs\SaySlate\SAYSLATE-AI-PROVIDER-TAILSCALE-INTEGRATION-TODO.md` | Read-only comparison artifact | User requested a rewrite for comparison, not deletion |
| `C:\dustin-thomason\docs\SaySlate\WHISPER-SERVICE-INTEGRATION-TODO.md` | Read-only precedent | Existing SaySlate handoff evidence |
| Any `dnu\` folder | Excluded | `agentic-handoff` rule |

## Readiness

| Prerequisite | Status | Evidence or blocker |
| --- | --- | --- |
| Canonical SaySlate repository and remote access | Met | EV-016; `C:\SaySlate` and `origin/main` were aligned at `af9a2f3a8cbad88c22edc094767b5cdd31f1a24e` when the handoff was authored |
| Node test runtime | Met | Node `v24.11.1` observed in `C:\SaySlate` on 2026-09-22; EV-015 and EV-026 define the gate |
| Loaded-extension browser tooling | Met | EV-032; Chrome and Edge executables also found at their standard local installation paths on 2026-09-22 |
| Live private Tailscale/LM Studio acceptance environment | Unmet | The private endpoint does not exist yet (Dustin Thomason, 2026-09-22); when it does, the user supplies the endpoint, model, and token directly in the loaded extension, and secrets stay out of planning artifacts |
