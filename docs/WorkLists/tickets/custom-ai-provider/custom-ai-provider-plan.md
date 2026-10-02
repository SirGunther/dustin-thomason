# Custom AI provider (self-hosted, OpenAI-compatible) — plan

| Field | Value |
| --- | --- |
| Project | WorkLists |
| Asked | 2026-09-28, by the owner: "the wiring that exists in C:\SaySlate … needs to be wired in so that I can make these calls locally via tailscale instead of off the shelf solutions like google" |
| Reference implementation | SaySlate (`C:\SaySlate`): `openAICompatibleClient.js`, `aiProviderClient.js`, `aiProviderRegistry.js`, `aiProviderConnectionTest.js`, and their tests |
| Host record | [`docs/tailscale/sayslate-lmstudio-endpoint.md`](../../../tailscale/sayslate-lmstudio-endpoint.md): LM Studio behind Tailscale Serve, Bearer token required, model `google/gemma-4-12b-qat` |
| Branch | `fix/custom-ai-provider`, worktree `C:\WorkLists-worktrees\custom-ai-provider`, cut from `local-fixes` `1b4cda0`; merges into `local-fixes` |
| Status | **Implementation dispatched** |

**This repo is public.** Real tailnet hostnames and tokens never go in it. Everywhere here the host is written
`<device>.<tailnet>.ts.net`; the tests use `lmstudio.example-tailnet.ts.net`.

## Problem → Requirement → Solution

**Problem.** Every AI action in WorkLists goes to a hosted model: the three live models are all Google.
The owner runs LM Studio on their own machine behind Tailscale, and SaySlate already calls it correctly. WorkLists
has an `openai-compatible` adapter, but it cannot reach that host:

1. `baseUrl` is used as the full POST URL; nothing appends `/chat/completions`. The UI placeholder
   (`https://api.example.com/v1`) suggests the opposite, so entering the SaySlate value POSTs to `…/v1` itself.
   A blank `baseUrl` falls back to `https://api.openai.com/v1/chat/completions`
   (`modelProviderClient.js:95-101`).
2. A key is mandatory at three points, and `Authorization: Bearer` is sent unconditionally
   (`modelProviderClient.js:150-154`, `:206-209`; `gemmaNormalize.js:1205-1219`, `:1071-1073`, `:1133-1135`).
3. **Leak.** A new model defaults `apiKeyEnvVar` to `GEMINI_API_KEY` (UI `todolist2.js:21013`, DAL
   `dal.js:171`, `:1588-1590`). `resolveModelApiKey` reads that variable for any adapter, which sends the owner's
   Google key to the custom host.
4. A POST or PATCH without `adapter` keeps `google-genai` (`dal.js:1576-1578`).
5. Timeouts: there is one global 45 s `Promise.race`, and the fetch is never aborted. A 12B model with
   thinking on takes about 12 s per call, and one AI action makes up to three calls.
6. Errors are generic: an unreachable host, a wrong path, and a rejected token all read as "AI could not process that request".
7. There is no test-connection route or button, and no test covers the `openai-compatible` HTTP path
   (the `app.locals.gemmaGenerateContent` stub bypasses it).

**Requirement.**

- The owner can add a **Custom (OpenAI-compatible)** model in Settings › APIs with three fields:
  - an endpoint, the base URL ending in `/v1`, the same value SaySlate uses;
  - an optional API key, which is write-only and kept when the field is left blank;
  - a model id.
- They can **Test connection** before or after saving, then save, activate, and have every AI action go to that host.
- A request to the custom host carries only its own key, never another provider's.
- Calls to a slow self-hosted model are given enough time, are aborted when they run out, and fail with a message that names what went wrong:
  - the host could not be reached;
  - the token was rejected;
  - the model or path was not found.
- Google models behave exactly as before.

**Solution.** Port SaySlate's OpenAI-compatible transport into the server-side provider client. Add a
`custom` provider value, a test-connection route with a button, and tests against a real local fake
OpenAI server. The browser-extension parts of SaySlate (host permissions, `chrome.storage`) do not apply.
The server makes the call, so the only requirement on the host is that the WorkLists machine is on the tailnet.

## Decisions (made from the code and the SaySlate evidence; recorded so they can be revisited)

| # | Decision | Why |
| --- | --- | --- |
| D1 | `baseUrl` is the **API base**. The client appends `/chat/completions` and `/models`. A stored value already ending in `/chat/completions` is used as-is for the POST (and stripped of that suffix to find `/models`) | Matches SaySlate and the owner's value. The backward-compat branch covers existing records and the `api.test.js` fixture (`https://api.example.com/v1/chat/completions`) |
| D2 | Save normalizes the endpoint: trim, parse as a URL, `http:` or `https:` only, no userinfo, query or hash, strip one trailing slash. **`/v1` is never added** | SaySlate normalization, but http is allowed: the call is server-side, so a LAN or loopback LM Studio is legitimate. Tailscale encrypts the transport either way |
| D3 | `custom` requires an endpoint (400 on save); it never falls back to `api.openai.com` | A blank custom endpoint sending prompts to OpenAI is the worst failure |
| D4 | Key is **optional for `custom`**; no key means no `Authorization` header. Other providers keep today's key rule | SaySlate's rule; LM Studio can run without auth |
| D5 | `GEMINI_API_KEY` never reaches a non-Google model. A new non-Google model defaults `apiKeyEnvVar` to `""` in both the UI and the DAL | Closes the leak in Problem 3 |
| D6 | The adapter is derived from the provider when a POST or PATCH omits it | Closes Problem 4 |
| D7 | Custom requests send `reasoning_effort: "none"` unless the model's Options JSON sets it. On HTTP 400/422 they retry once with `{model, messages}` only | LM Studio honours only `reasoning_effort`; `"none"` took a pass from about 12 s to about 2 s (endpoint record). The retry covers servers that reject the field (SaySlate behaviour) |
| D8 | No `response_format` and no streaming | WorkLists prompts define their own JSON shapes, and `parseGemmaJson` already unwraps fences. Streaming exists in SaySlate for a browser silence timer, which a server-side call does not need |
| D9 | `<think>…</think>` blocks are stripped from the content, and `reasoning_content` is ignored | Hardening SaySlate lacks: llama.cpp or vLLM without a reasoning parser would inline thinking and break JSON parsing |
| D10 | Custom calls get a 90 s response timeout (or the global setting, if larger), and the fetch is aborted when it fires. Google is unchanged | SaySlate's 90 s budget. An aborted fetch stops the model from spending time on an answer nobody waits for |
| D11 | Test connection is `POST /api/models/test-connection`. It is openai-compatible only: `GET {base}/models`, 15 s, success means the exact model id is in `data[].id`. It returns the list of ids on a miss, never writes storage, and uses a saved model's stored key when the key field is blank | SaySlate's probe. Returning the ids turns "wrong model id" into a one-glance fix |
| D12 | Error messages name the endpoint's origin and never include the key or the raw body | Problem 6. Wording stays model-agnostic ("AI"), per `ai-label-dynamic` |

## Out of scope

- Google test-connection.
- Streaming.
- A per-model timeout field.
- Redacting keys placed in Headers JSON (a pre-existing gap: `headers` still reaches the browser).
- The uncommitted provider edits in the main checkout (key-precedence fix, model-name error wording). They conflict with
  `local-fixes` and are the owner's work in progress.

## Amendments after review

- **D11 (amended):** test-connection may reuse a stored secret (a key, or the saved model's own env var) only when the form's provider, adapter and normalized endpoint all equal the saved record's. It never reuses a key saved on a `google-genai` record, and never reads an env var named only in the form. The route answers 403 to a cross-origin browser `Origin`.
- **D5 (extended):** a provider change clears both `apiKey` and `apiKeyEnvVar` unless the same request supplies new ones.
- **Scope, set by the owner on 2026-09-28:** "wire it in like SaySlate, nothing more." The fix round covers only the three key-leak defects this branch introduced. The review's other findings are dropped:
  - the shared deadline across retries and stages;
  - the 502 wording;
  - the "internal" retry regex;
  - the pre-existing Google override;
  - the query-string URL;
  - the adapter alias;
  - the stale-result guard;
  - the test timing and OpenAPI text.

  The owner's service has no speed problem. The wait-time finding was hypothetical: a host that hangs or errors.

## Progress log

- 2026-09-28: Implementation `42f80ad`: 80 new tests, 2161/2161, browser 15/15. A real-browser run against a fake LM Studio passed. The real host, tested without a token, answered `authentication_failed` (HTTP 401), which proves the URL and reachability. **An independent review found a blocker:** test-connection reused a saved key for any host the request named. Reproduced cases:
  - a Google key sent to `api.openai.com` or to a typed host;
  - any env var sent as a Bearer token;
  - an env key carried across a provider change;
  - the "internal" retry regex matching the origin;
  - a fresh 90 s budget per retry, so one job could hold the queue for about 450 s;
  - a vague message for "Serve up, LM Studio down" (502).

  The trial merge into `local-fixes` (2161/2161, 15/15) was aborted, and the branch was sent back with all 12 findings.

- 2026-09-28: SaySlate and WorkLists provider paths mapped by two read-only explorers. The Tailscale host is
  reachable from this machine: `GET /v1/models` without a token returns 401 from LM Studio, as the host record
  says it should. Worktree created and implementation dispatched.
