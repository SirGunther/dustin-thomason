# SaySlate App Changelog

## Purpose

This is the canonical development record for SaySlate work run from dustin-thomason: what changed,
why, how it was verified, and what is still open. SaySlate's own release history stays in
`C:\SaySlate\CHANGELOG.md`; this file records the sessions behind it.

## Scope

Personal-project changelog for the SaySlate Chrome extension (`C:\SaySlate`, `SirGunther/SaySlate`)
and its planning artifacts under `docs/SaySlate/`. The private LM Studio endpoint it uses is
documented in [`docs/tailscale/sayslate-lmstudio-endpoint.md`](../tailscale/sayslate-lmstudio-endpoint.md).

## Session log (newest first)

### 2026-09-24T00:59:00Z — AI providers live over Tailscale; Gemini error detail; LM Studio reasoning off

- **Starting point:** the orchestrated handoff in
  [`tickets/sayslate-ai-provider-tailscale/`](tickets/sayslate-ai-provider-tailscale/) merged SAYAI-01
  through SAYAI-05 to SaySlate `main` (merge `0e22974`). SAYAI-06, live acceptance, was deferred until
  a private endpoint existed (LD-032).
- **Gemini stopped working after a refresh.** Google had disabled the Gemini key because it was
  published in this public repo (`docs/Temp/scratchpad.md`, first pushed in `a9135eb`). The key was
  rotated. Generation then failed with only "The provider request failed."
- **Cause:** Google answered HTTP 503, "This model is currently experiencing high demand", for
  `gemini-3.1-flash-lite`, and the new code hid Google's reason. The request itself was valid:
  Google accepted the body and the key.
- **Fix:** Gemini failures now carry the HTTP status and Google's own message, bounded to 200
  characters with the key redacted, and both surfaces show it (SaySlate `cf4bc5d`; LD-039).
- **Reverted:** a 5xx retry added in the same commit, on an unconfirmed "overload" assumption. In
  real use it left the pass hanging, so it was removed and only the message detail kept (SaySlate
  `0998f48`; LD-040).
- **LM Studio over Tailscale:** the endpoint was set up on the LM Studio host (Serve, token auth,
  loopback only, Funnel off). Tailscale was installed on the Chrome machine, and from there
  SaySlate's Test Connection and a first pass both succeeded (V7).
- **Reasoning:** the LM Studio host's saved Enable Thinking setting is on, and a SaySlate pass spent
  321 of 354 tokens reasoning (~12 s). Local probes showed LM Studio honors `reasoning_effort` per
  request: `"none"` turns thinking off, and every other value turns it on (EV-035). SaySlate now sends
  `reasoning_effort: "none"` for Custom profiles only; OpenAI, Gemini, and Claude profiles are
  unchanged (SaySlate `2bafd4e`; LD-041).
- **Verification:** `node tests/verify.mjs`, syntax checks, and `git diff --check` pass on each
  SaySlate commit. The real client code was also run against the local LM Studio: structured
  `{text}` returned and validated, and with the new field, 0 reasoning tokens in 1.9 s.
- **Files:** SaySlate `aiClient.js`, `app.js`, `floating.js`, `aiProviderClient.js`,
  `openAICompatibleClient.js`, `CHANGELOG.md`, and tests. dustin-thomason: the ticket's decisions
  (LD-039–LD-041) and requirements (EV-035), `docs/tailscale/`, and this file.
- **Not done:**
  - SaySlate `main` is not pushed.
  - `"none"` overriding a saved "on" is not yet confirmed on the LM Studio host (re-run V5 there).
  - The SAYAI-06 validation review is not written.
  - No successful Gemini generation on this build has been observed yet.
  - OpenAI and Claude profiles have not been run live.

## Current state

- **Working:** SaySlate provider profiles on local `main`, and the Custom LM Studio path over
  Tailscale end to end.
- **Open:**
  - Confirm `reasoning_tokens: 0` on the LM Studio host.
  - Write the SAYAI-06 validation review; the README and ROADMAP updates wait for it (LD-029).
  - Push SaySlate `main`.
- **Side effect:** LM Studio token auth is server-wide, so Argus's local LM Studio provider gets 401
  on that host until Argus supports tokens, or auth is turned off.
