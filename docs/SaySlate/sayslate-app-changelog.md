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

### 2026-09-24T20:14:00Z — Per-pass reasoning merged: a reasoning switch for each pass

- **Direction:** Dustin confirmed the handoff and asked for a separate worktree while SAYSTAT-01 was
  in flight, with the merge held until SAYSTAT-01 completed.
- **Problem → requirement → solution:** Custom (LM Studio) passes always sent
  `reasoning_effort: "none"`. The user wants reasoning off for the grammar pass and optionally on for
  the coherence pass (REQ-001–003). So each pass now has its own switch, and the Custom request
  carries that pass's setting.
- **Shipped** (SaySlate `main`, all `--no-ff` and pushed):
  - `a168833` SAYREASON-01: `generate` takes `reasoning`. Custom sends `"medium"` when it is on and
    `"none"` when it is off. OpenAI, Gemini, and Claude requests are unchanged, and the schema-free
    retry still sends no reasoning field.
  - `d990884` SAYREASON-02: "Reasoning on/off" switches for the first and second pass in the AI
    prompts panel, both off by default and stored in `sayslate-grammar-config` with no schema bump.
    Every full-page and Floating Slate pass sends its saved setting. `CHANGELOG.md` and `README.md`
    are updated.
  - `753a5b1` SAYREASON-02A: removed two `if (…)` listener guards that SAYREASON-02 added only because
    a test fixture it could not change lacked the new ids.
- **Review:** SAYREASON-01 passed on review 1. SAYREASON-02 took two rounds:
  - F1: two full-page scenarios still passed with their pass click removed. Fixed in `542fa4a`, and
    the same probes now fail as they should.
  - F2: the ticket file had not been updated in place.
  - F3: the listener guards, routed to SAYREASON-02A.

  Details are in the handoff's audit records.
- **Verification:** `node tests/verify.mjs`, `node --check` on every changed file, and
  `git diff --check` pass on each branch and on merged `main` `753a5b1`. Probes on scratch copies
  confirmed the new tests fail when the wiring is removed. Loaded-extension screenshots show both
  switches in light and dark themes, and a switch turned on is still on after a reload.
- **Docs:** the "Reasoning (thinking)" section of the endpoint doc now describes the switches
  (`a256f91`).
- **Left open:**
  - The live LM Studio check: one pass with its switch off and one with it on, recording
    `reasoning_tokens`.
  - Two lines of the endpoint doc outside the "Reasoning (thinking)" section still say SaySlate
    always sends `"none"`: the "AI pass" row in "Values SaySlate uses" and the V5 verification
    row.

### 2026-09-24T19:32:00Z — SAYSTAT-01 merged: full-page badge shows AI pass stages

- **Pre-dispatch:** the orchestrator's code check found two overlaps that the ticket as written
  would have misreported:
  - A discard during the first pass, or Ctrl+Alt+X during either pass, would show "Ready" while the
    pass was still running (EV-025).
  - Ctrl+Alt+D starts dictation during a pass although the start button is disabled then (EV-026).
    A finished pass would then replace "Listening", and stopping dictation would show "Ready"
    mid-pass.

  Both were resolved from sources as LD-006 and LD-007, and the ticket was revised before dispatch
  (`e71d540`).
- **Shipped:** SaySlate `main` `0e1b26b` (`--no-ff`, pushed). The full-page badge reads "Phase 1" or
  "Phase 2" while a pass request runs, then "Phase N ready" or "Phase N failed". It returns to
  "Ready" after a discard, a clear, or Finish. It uses Floating Slate's colors in both themes.
  Files: `app.js`, `app.css`, `tests/app-dictation-integration.test.mjs`, `CHANGELOG.md`.
- **Review:** two rounds. Two findings were fixed in `88284c6`: F1, a CSS comment that misstated
  the dark-theme cascade, and F2, a test that clicked a disabled button. Details are in the
  handoff's SAYSTAT-01 audit record.
- **Verification:** `node tests/verify.mjs`, `node --check` on both changed files, and
  `git diff --check` pass on the branch and on merged `main`. Loaded-extension screenshots show all
  four states in both themes.
- **Left open:** Ctrl+Alt+D and Ctrl+Alt+X still act during a pass while their buttons are
  disabled. The badge now reports that correctly, but dictation during a first pass can add text
  the pass doesn't see. Blocking the shortcuts would change dictation behavior, so it needs a
  separate decision.

### 2026-09-24T18:10:00Z — Per-pass reasoning handoff drafted

- **Scope:** feature two, a reasoning on/off switch for each pass that affects only Custom
  (LM Studio) requests.
- **Written:** the `agentic-handoff` set in
  [`tickets/sayslate-pass-reasoning/`](tickets/sayslate-pass-reasoning/):
  - requirements: REQ-001–003 and EV-001–024;
  - decisions: LD-001–006, with four open questions all resolved from sources;
  - the handoff, SAYREASON-01 (dispatcher `reasoning` input) and SAYREASON-02 (switches, storage,
    both surfaces, docs).
- **Key values:**
  - "On" sends `reasoning_effort: "medium"` and "off" sends `"none"`. The levels aren't proven to
    differ.
  - Both switches are off by default, and the second-pass switch stays usable when that pass is off.
  - Floating Slate uses the saved settings without controls of its own.
- **Not done:**
  - The delivery order awaits confirmation, and the set isn't committed.
  - SAYREASON-02 also waits for the status badge's SAYSTAT-01 to merge (both change `app.js` and
    `CHANGELOG.md`).

### 2026-09-24T17:20:00Z — Status badge handoff: full page matches Floating Slate

- **Direction:** keep Floating Slate's "Phase 1" / "Phase 2" wording and make the full page match
  it (REQ-003, superseding REQ-002's "Pass" wording).
- **Recorded:**
  - LD-003: the full page uses "Phase 1" / "Phase 2".
  - LD-004: Floating Slate is unchanged, and SAYSTAT-02 is withdrawn.
  - LD-005: the full page follows Floating Slate's ready/failed/Ready states and colors.
  - Open decisions 1–2 are resolved.
- **Result:** SAYSTAT-01 is now the only ticket.
- **Deliberate difference:** the full page sets "Phase N" only when the provider request starts, so
  it never shows a stage that isn't running.
- **Left as is:** Floating Slate's stuck label with no provider chosen (EV-011).

### 2026-09-24T16:50:00Z — Status badge handoff drafted

- **Scope:** the fourth of four proposed SaySlate features, a status badge that shows the running
  stage ("Pass 1", "Pass 2") instead of only "Ready". The other three (Whisper model selection, a
  reasoning option, a reconcile pass) were sized in chat only.
- **Written:** the `agentic-handoff` set in
  [`tickets/sayslate-status-badge/`](tickets/sayslate-status-badge/): original ticket,
  requirements (REQ-001–002, EV-001–024), decisions (LD-001–002 and open decisions 1–2), handoff,
  SAYSTAT-01 (full page) and SAYSTAT-02 (Floating Slate).
- **Found:** Floating Slate sets its pass label before resolving the provider profile, so with no
  provider chosen the badge keeps showing a pass that never started (EV-011). SAYSTAT-02 fixes it
  if open decision 1 resolves yes.
- **Not done:** open decisions 1–2 and the delivery order await confirmation; the set is not
  committed; no ticket has been dispatched and no SaySlate code changed.

### 2026-09-24T01:10:00Z — Reasoning override confirmed on the LM Studio host

- **Confirmed:** after the SaySlate update (`2bafd4e`), the LM Studio host's log for a SaySlate pass
  showed `reasoning_tokens: 0`. That host's saved Enable Thinking setting is on, so this proves
  `reasoning_effort: "none"` overrides a saved "on", which the earlier local probes couldn't show.
- **Recorded in:** the setup doc's V5 row and reasoning section, EV-035, and SaySlate's
  `CHANGELOG.md`.
- **Pushed:** SaySlate `main` and dustin-thomason `main`.

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
- **Confirmed:** no reasoning pass on the LM Studio host (`reasoning_tokens: 0`, 2026-09-23). That
  is now the behavior with a pass's reasoning switch off, which is the default.
- **Open:**
  - Per-pass reasoning (`tickets/sayslate-pass-reasoning/`, merged `753a5b1`): reload the extension
    and run one Custom pass with its reasoning switch off and one with it on; record each run's
    `reasoning_tokens` in the SAYREASON-02 audit.
  - Write the SAYAI-06 validation review; the README and ROADMAP updates wait for it (LD-029).
  - A successful Gemini generation on this build; OpenAI and Claude profiles run live.
- **Someday:** self-host the Tailscale coordination server (Headscale) and a relay on spare
  hardware, removing the dependency on Tailscale's service.
- **Side effect:** LM Studio token auth is server-wide, so Argus's local LM Studio provider gets 401
  on that host until Argus supports tokens, or auth is turned off.
