# SaySlate ↔ WhisperService Integration Work Breakdown

Status: planning artifact; no SaySlate production changes are authorized by this document.

This document divides the WhisperService integration into independently assignable build blocks. Each `WSI-*` section can be copied into a ticket and given to one agent. The blocks deliberately separate file ownership so the first and third waves can be worked in parallel with minimal merge conflict risk.

## Integration outcome

SaySlate will keep its current browser speech-recognition option and add a user-selectable **Local Whisper** dictation option backed by the manually started WhisperService at `http://127.0.0.1:8178`.

The selected provider and local settings will persist. SaySlate will visibly report whether Local Whisper is selected and whether the service is available. If Local Whisper is selected but unavailable, authentication fails, or streaming fails, SaySlate must stop with an explicit error; it must not silently switch to browser dictation.

This work changes dictation intake only. It does not replace SaySlate's current AI processing, prompts, pass order, output behavior, or interface design.

## Source of truth

- SaySlate repository: `C:\Users\dktho\OneDrive\PDProjects\Browser Extensions\SaySlate`
- WhisperService repository: `C:\WhisperService`
- WhisperService runtime address: `http://127.0.0.1:8178`
- Protocol version: `1.0.0`
- Service contracts:
  - `C:\WhisperService\contracts\openapi.yaml`
  - `C:\WhisperService\contracts\schemas\*.json` (health, session-create, control, events, error, config)
  - `C:\WhisperService\clients\browser.mjs`
- Existing SaySlate dictation paths:
  - Full page: `app.js` → `speechEngine.js`
  - Floating window: `floating.js` → `floatingSpeechClient.js` → `background.js` → `offscreenSpeech.js` → `speechEngine.js`

The WhisperService browser client is an ESM reference implementation. SaySlate currently loads classic scripts, so agents should adapt its contract and behavior to SaySlate's script model rather than directly adding an incompatible script tag.

## Non-negotiable integration rules

Every ticket inherits these rules:

- Preserve the current Browser Dictation path and make it the default for existing users.
- Add Local Whisper as an explicit choice; do not make availability trigger automatic provider switching.
- Preserve the existing visual language. Add only the top-level dictation selector, its compact menu/settings surface, and a clear availability state.
- Do not delete, rewrite, clear, or reorder any existing prompt, AI pass, transcript-to-pass transition, output transformation, copy action, insertion action, or ChatGPT submission behavior.
- `Finish` must wait for the selected speech provider to settle its final transcript before AI processing or downstream submission starts.
- `Clear`, Escape, window close, provider change during an idle state, and other cancellation paths must erase the active local session without emitting a transcript.
- Create a fresh WhisperService session for every dictation run. Never reuse a service session or utterance state across dictation runs.
- Use English-only, PCM16 little-endian, 16 kHz, mono audio.
- Use a default partial-preview cadence of 2,000 ms and allow values from 1,500–3,000 ms.
- Treat partial events as replaceable previews keyed by `utteranceId` and increasing `revision`. Only final events are committed transcript text.
- Keep the WhisperService bearer token out of source code, logs, error text, WebSocket URLs, and extension messages. Store it only through the explicit user configuration flow. Only the background service worker reads the saved token from extension storage: it performs authenticated health checks and session creation there, then hands the offscreen document only the resulting short-lived session descriptor (ticket + stream URL) so the offscreen document — which owns microphone capture and the streaming WebSocket — never needs the token itself (offscreen documents only receive the `chrome.runtime` extension API).
- Never log audio bytes or transcript text as integration diagnostics.
- Use only the ticketed WebSocket URL returned by `POST /v1/sessions`; do not add the bearer token to that URL.
- No LM Studio integration, AI-provider change, prompt change, automatic WhisperService launch, model management, or WhisperService implementation belongs in these tickets.

## Recommended delivery order

```text
WSI-01 ┐
WSI-02 ├──> WSI-04 ──┬──> WSI-05 ┐
WSI-03 ┘              └──> WSI-06 ├──> WSI-07
```

| Wave | Tickets | Parallel? | Purpose |
| --- | --- | --- | --- |
| 1 | WSI-01, WSI-02, WSI-03 | Yes | Build the protocol, audio, and configuration/UI foundations. |
| 2 | WSI-04 | No | Join those foundations in the shared offscreen host. |
| 3 | WSI-05, WSI-06 | Yes | Connect full-page and floating experiences independently. |
| 4 | WSI-07 | No | Final permissions, documentation, regression, and acceptance gate. |

This is **seven build tickets across four delivery waves**. WSI-01 through WSI-03 are the first dispatch group.

## Agent handoff rules

Before starting a block, an agent must:

- Read this entire document and the referenced WhisperService contracts.
- Inspect the current versions of every owned file; do not assume line numbers or implementation details from a ticket summary.
- Confirm all dependencies listed for the block are present.
- Restrict production changes to the block's owned files. If another file is genuinely required, stop and report the proposed ownership change before editing it.
- Add focused tests for the behavior introduced by the block and run all existing relevant SaySlate tests.
- Return the exact files changed, tests run, results, remaining risks, and any contract assumption made.

Do not assign two active tickets that own the same production file.

---

## WSI-01 — WhisperService protocol client

**Depends on:** Nothing  
**May run in parallel with:** WSI-02 and WSI-03  
**Exclusive production ownership:** New protocol-client file(s) only, proposed `whisperServiceClient.js`  
**Test ownership:** New focused protocol-client test file(s)

### Goal

Create a dependency-light, classic-script-compatible SaySlate client for the WhisperService 1.0.0 HTTP and WebSocket contracts. This block provides transport and protocol behavior only; it does not capture microphone audio or modify either SaySlate user interface.

### Build checklist

- [ ] Expose a narrow global API suitable for the background/offscreen extension contexts.
- [ ] Implement authenticated `GET /v1/health`.
- [ ] Implement authenticated `POST /v1/sessions` with optional `previewMs`.
- [ ] Connect to the returned 15-second, single-use WebSocket ticket URL.
- [ ] Send binary PCM frames without transformation.
- [ ] Support `flush`, `stop`, and `cancel` control envelopes at protocol version `1.0.0`.
- [ ] Parse `session.ready`, `transcript.partial`, `transcript.final`, `transcript.empty`, `error`, and `session.closed` events.
- [ ] Suppress malformed envelopes, unknown protocol versions, stale partial revisions, and events for the wrong session with explicit client errors.
- [ ] Make connection, stop, and cancellation settlement deterministic and idempotent.
- [ ] Map authentication, origin, capacity, timeout, worker, malformed-response, network, and unavailable failures into stable SaySlate-facing error categories.
- [ ] Redact bearer credentials and transcript/audio data from every error and diagnostic representation.

### Exit gate

- [ ] Unit tests cover health readiness, session creation, ticket use, event parsing, stale revision suppression, stop, cancel, socket close, malformed data, and service-unavailable behavior.
- [ ] Tests prove the bearer token appears only in HTTP authorization headers and never in a WebSocket URL or logged/returned diagnostic.
- [ ] No existing SaySlate production file has been changed.

### Out of scope

Microphone capture, resampling, UI, storage, background routing, and edits to the WhisperService repository.

---

## WSI-02 — Local microphone capture and PCM pipeline

**Depends on:** Nothing  
**May run in parallel with:** WSI-01 and WSI-03  
**Exclusive production ownership:** New audio capture/worklet/conversion file(s) only  
**Test ownership:** New focused PCM/audio test file(s)

### Goal

Build the reusable browser audio component that turns a microphone stream into bounded PCM16 little-endian, 16 kHz, mono frames for WhisperService. It will eventually run in SaySlate's offscreen document.

### Build checklist

- [ ] Acquire a microphone stream through `getUserMedia` using mono-oriented constraints without assuming the device's native sample rate.
- [ ] Downmix input to mono and resample the actual input rate to 16 kHz.
- [ ] Convert normalized samples to signed 16-bit little-endian PCM with correct clipping behavior.
- [ ] Emit bounded binary chunks below the WhisperService 64 KiB WebSocket frame limit.
- [ ] Provide explicit `start`, `stop`, and `cancel` lifecycle methods that tolerate repeated calls.
- [ ] Stop all media tracks, disconnect audio nodes, close/release the audio context, clear queued buffers, and remove callbacks on every exit path.
- [ ] Surface permission denial, missing device, audio-context failure, and invalid sample data as distinct non-secret errors.
- [ ] Keep audio bytes in memory only for the time required to stream them; do not persist recordings.
- [ ] Prefer an AudioWorklet-based capture path compatible with the extension's offscreen document and current manifest policy.

### Exit gate

- [ ] Deterministic tests cover mono conversion, clipping, endianness, multiple source sample rates, chunk bounds, stop, cancellation, and cleanup.
- [ ] A focused browser/manual harness confirms frames are accepted by a locally running WhisperService.
- [ ] No existing SaySlate production file has been changed.

### Out of scope

WhisperService HTTP/WebSocket calls, settings, toolbar UI, transcript handling, and dictation routing.

---

## WSI-03 — Dictation provider configuration and top-level UI

**Depends on:** Nothing  
**May run in parallel with:** WSI-01 and WSI-02  
**Exclusive production ownership:** `app.html`, `app.css`, and new provider-settings/controller file(s)  
**Test ownership:** New focused provider-settings/UI test file(s)

### Goal

Add the minimal SaySlate interface and persisted configuration needed to choose Browser Dictation or Local Whisper and to understand Local Whisper availability. This block defines state and presentation but does not yet start dictation.

### Build checklist

- [ ] Add a compact dictation-provider control to the top toolbar using SaySlate's existing styling, spacing, focus treatment, and theme behavior.
- [ ] Provide exactly two v1 choices: `Browser Dictation` and `Local Whisper`.
- [ ] Keep Browser Dictation as the migration default when no prior choice exists.
- [ ] Persist provider, WhisperService endpoint, bearer token, and preview cadence in `chrome.storage.local` using a versioned settings object.
- [ ] Fix the v1 endpoint to `http://127.0.0.1:8178` in normal UI; do not expose arbitrary remote hosts.
- [ ] Provide a masked token entry/update flow and remove the plaintext value from the input after saving.
- [ ] Provide preview-cadence control constrained to 1,500–3,000 ms with a 2,000 ms default.
- [ ] Define a small global settings API/event contract that WSI-04, WSI-05, and WSI-06 can consume without directly reading DOM controls.
- [ ] Represent Local Whisper states distinctly: checking, available, unavailable, unauthorized/misconfigured, and active.
- [ ] Keep the active provider visually evident while preserving the existing interface hierarchy.
- [ ] Disable provider/configuration mutation while dictation is active; do not interrupt a live session by silently changing configuration.
- [ ] Ensure settings serialization and rendered status never expose the saved token.

### Exit gate

- [ ] Tests cover default migration, load/save, invalid values, cadence bounds, token masking/redaction, provider changes, active-state locking, and each availability state.
- [ ] Existing top-toolbar behavior and keyboard accessibility still work.
- [ ] `app.js`, `floating.js`, `background.js`, and `offscreenSpeech.js` have not been changed.

### Out of scope

Health transport implementation, microphone capture, session streaming, and changes to current transcription behavior.

---

## WSI-04 — Shared offscreen Local Whisper host and routing

**Depends on:** WSI-01, WSI-02, and the persisted settings contract from WSI-03  
**May run in parallel with:** Nothing  
**Exclusive production ownership:** `background.js`, `offscreen.html`, and `offscreenSpeech.js`  
**Test ownership:** `tests/background-routing.test.mjs`, `tests/offscreen-speech.test.mjs`, and new focused integration tests

### Goal

Make the offscreen document the single owner of Local Whisper microphone capture and service communication for both SaySlate surfaces. Preserve the existing browser-recognition path while adding normalized local-provider commands and results.

### Build checklist

- [ ] Load the WSI-01 and WSI-02 classic scripts in `offscreen.html` in dependency-safe order.
- [ ] Extend background routing so both the full page and floating window can target a shared offscreen speech host without receiving or forwarding the saved bearer token.
- [ ] Have the background service worker read the saved provider configuration from `chrome.storage.local`, call WSI-01's `createSessionDescriptor()` there, and pass only the resulting session descriptor to the offscreen host; the offscreen host calls WSI-01's token-free `connectSession()` and never reads the bearer token from storage itself.
- [ ] Add a health-check command used by the UI availability indicator, with bounded timeout and stable errors.
- [ ] For every Local Whisper `start`, create one fresh service session and one fresh microphone capture pipeline.
- [ ] Do not carry session IDs, utterance IDs, revisions, partial text, audio, or client instances into the next dictation run.
- [ ] Normalize local partial/final/empty events into a provider-neutral internal result shape consumable by both existing SaySlate surfaces.
- [ ] Replace a partial only when its revision is newer for the same utterance; never append repeated partial snapshots as final text.
- [ ] Commit each final utterance once, including automatic ten-second rollover finals, and continue the live dictation session when the service does.
- [ ] Make `stop` send the service stop control, cease capture, and settle only after final/empty and closed outcomes or a bounded explicit failure.
- [ ] Make `cancel` cease capture, send cancellation/delete as appropriate, clear all in-memory session state, and emit no transcript.
- [ ] Cancel and clean up on disconnect, offscreen teardown, provider error, malformed service data, or extension shutdown.
- [ ] Preserve existing Web Speech behavior and current floating-message routing for Browser Dictation.
- [ ] Never fall back from Local Whisper to Browser Dictation after Local Whisper has been selected.

### Exit gate

- [ ] Tests cover target routing, health states, local start/result/stop/cancel, stale partials, rollover finals, empty speech, service errors, disconnect, duplicate commands, and cleanup.
- [ ] Tests prove two sequential dictation runs receive new WhisperService session IDs and share no partial/final state.
- [ ] Tests prove concurrent/overlapping start attempts are rejected or serialized without leaking audio or results between targets.
- [ ] Existing Browser Dictation offscreen tests remain green.

### Out of scope

Full-page transcript rendering, floating-window transcript rendering, AI pass behavior, manifest release changes, and WhisperService changes.

---

## WSI-05 — Full-page dictation integration

**Depends on:** WSI-03 and WSI-04  
**May run in parallel with:** WSI-06  
**Exclusive production ownership:** `app.js`  
**Test ownership:** New full-page dictation integration test(s), plus directly affected existing app tests

### Goal

Connect the full SaySlate page to the selected dictation provider while preserving all existing transcript, prompt, AI-processing, copy, and reset behavior.

### Build checklist

- [ ] Keep the current direct `SaySlateSpeech` path unchanged when Browser Dictation is selected.
- [ ] Route Local Whisper start/stop/cancel and normalized result messages through the WSI-04 background/offscreen path.
- [ ] Feed normalized local interim and final text into the same visible transcript composition rules used today.
- [ ] Reflect active/checking/error state through the WSI-03 provider UI contract without duplicating provider settings logic.
- [ ] Make `Finish` await the definitive local stop settlement before invoking the first AI pass.
- [ ] Preserve both existing AI passes, their exact stored/default prompts, their order, and all current error recovery behavior.
- [ ] Preserve transcript content when service stop or transcription fails and present a useful explicit error.
- [ ] Make Clear, reset, page teardown, and any existing cancellation path cancel and erase the local service session.
- [ ] Prevent late partial/final events from a closed or superseded dictation run from changing the UI.
- [ ] Do not alter copy/output actions beyond waiting for settled final transcription where required.

### Exit gate

- [ ] Tests cover both providers, local partial replacement, multiple final utterances, stop-before-processing ordering, cancel, late events, empty results, and explicit offline/auth failures.
- [ ] Regression tests prove prompts and pass ordering are byte-for-byte/behaviorally unchanged.
- [ ] Manual comparison confirms Browser Dictation behaves as before.
- [ ] No floating-window production file has been changed.

### Out of scope

Floating-window integration, new AI behavior, prompt editing, visual redesign, and manifest/release documentation.

---

## WSI-06 — Floating-window dictation integration

**Depends on:** WSI-03 and WSI-04  
**May run in parallel with:** WSI-05  
**Exclusive production ownership:** `floating.js` and `floatingSpeechClient.js`  
**Test ownership:** `tests/floating-speech-client.test.mjs` and new floating integration test(s)

### Goal

Connect the floating SaySlate experience to the selected dictation provider while keeping its insertion and ChatGPT submission workflows identical after transcription settles.

### Build checklist

- [ ] Extend the floating speech client with provider-neutral start/stop/cancel/status/result handling.
- [ ] Use the persisted provider choice; do not introduce a second conflicting provider setting in the floating window.
- [ ] Display normalized Local Whisper partial and final results using the floating window's existing transcript behavior.
- [ ] Make Finish wait for definitive local stop settlement before insertion, AI processing, or ChatGPT submission.
- [ ] Make Escape, Clear, host close, window teardown, and all current cancellation paths cancel and erase the local service session.
- [ ] Reject late events from a prior/superseded session.
- [ ] Preserve all existing shortcut routing, target-field insertion, ChatGPT adapter behavior, and user-visible error recovery.
- [ ] Show Local Whisper unavailable/authentication/stream failures explicitly and never fall back silently.

### Exit gate

- [ ] Tests cover both providers, local partial/final behavior, finish settlement, cancellation paths, late events, offline/auth errors, and host disconnect.
- [ ] Existing shortcut, insertion, and ChatGPT adapter tests remain green.
- [ ] Manual comparison confirms Browser Dictation behaves as before.
- [ ] `app.js` has not been changed.

### Out of scope

Full-page integration, provider settings design, prompt/AI changes, and manifest/release documentation.

---

## WSI-07 — Security, manifest, documentation, and acceptance gate

**Depends on:** WSI-05 and WSI-06  
**May run in parallel with:** Nothing  
**Exclusive production ownership:** `manifest.json`, `README.md`, `CHANGELOG.md`, optional `ROADMAP.md` status edits, `tests/verify.mjs`, and final cross-cutting test fixtures  
**Test ownership:** Final regression and end-to-end acceptance coverage

### Goal

Finish the integration with the least-privilege extension permission, operator instructions, complete regression verification, and a real-service acceptance pass. This is the only block authorized to make release/version documentation changes.

### Build checklist

- [ ] Add only the required loopback host permission: `http://127.0.0.1:8178/*`.
- [ ] Confirm no wildcard, LAN, public HTTP, or unrelated host access was added.
- [ ] Document manual WhisperService startup and the fact that SaySlate never starts it.
- [ ] Document token retrieval, entry/rotation, storage expectations, and redaction behavior without including a real token.
- [ ] Document discovery of the installed extension ID and exact service-origin registration: `chrome-extension://<extension-id>`.
- [ ] Document that WhisperService must be restarted after its allowed-origin configuration changes.
- [ ] Document provider selection, status meanings, preview-cadence range, and explicit no-fallback behavior.
- [ ] Add troubleshooting for offline service, invalid token, forbidden origin, microphone permission, capacity, and worker failure.
- [ ] Update the project verification runner so every new focused test participates in the standard local test command/process.
- [ ] Perform a secret/log review covering source, extension messages, error output, URLs, and tests.
- [ ] Update release/version records using SaySlate's existing convention only after acceptance passes.

### Automated acceptance

- [ ] All existing SaySlate tests pass.
- [ ] All WSI-focused tests pass through the standard verification runner.
- [ ] Static verification confirms the manifest grants only the expected loopback origin.
- [ ] Regression coverage proves prompt content, pass count/order, copy/insertion behavior, and ChatGPT adapter behavior are unchanged.
- [ ] Isolation coverage proves one dictation run cannot accept results belonging to a previous run.

### Real-runtime acceptance

- [ ] With WhisperService stopped, Local Whisper shows unavailable and starting dictation fails explicitly without browser fallback.
- [ ] With WhisperService running and valid configuration, health reports available.
- [ ] An invalid token produces a distinct authentication/misconfiguration state without exposing the token.
- [ ] An unregistered extension origin produces a distinct forbidden-origin state with actionable instructions.
- [ ] Full-page Local Whisper produces useful partial text, a correct final transcript, and starts AI processing only after final settlement.
- [ ] Floating Local Whisper produces useful partial text, a correct final transcript, and performs insertion/submission only after final settlement.
- [ ] Stop finalizes immediately; Clear/Escape/close cancel without adding transcript text.
- [ ] Starting a second dictation after the first proves no prior words, partials, or context appear.
- [ ] Changing the preview cadence within its supported range takes effect on the next session.
- [ ] Browser Dictation remains fully functional in both SaySlate surfaces.
- [ ] Reloading SaySlate retains the selected provider and configuration while keeping the token masked.
- [ ] No transcript text, audio data, bearer token, or ticket appears in logs.

### Out of scope

New feature development, UI redesign, WhisperService code changes, automated service launch, LM Studio, and public distribution work.

---

## WSI-08 — Post-build regression coverage and routing hardening

**Depends on:** WSI-07  
**May run in parallel with:** Nothing  
**Exclusive production ownership:** None unless a regression test exposes a defect in an existing WSI implementation  
**Test ownership:** `tests/background-routing.test.mjs`, `tests/offscreen-speech.test.mjs`, and focused integration fixtures

### Goal

Add the deferred regression coverage for Local Whisper host behavior after the complete feature path is built, without expanding the feature or changing established SaySlate behavior.

### Build checklist

- [ ] Prove Stop waits for microphone/worklet flush completion before sending the WhisperService stop control, so the final PCM remainder cannot be clipped.
- [ ] Prove duplicate `transcript.final` and `transcript.empty` events for the same utterance ID are committed at most once and later partials remain suppressed.
- [ ] Prove background routing always uses the fixed `http://127.0.0.1:8178` endpoint even if persisted storage contains another endpoint.
- [ ] Prove health-check storage failures return a bounded, stable unavailable response instead of leaving the message channel unsettled.
- [ ] Re-run sequential-session, overlapping-start, cancellation, disconnect, malformed-event, rollover, and Browser Dictation regression coverage after the focused cases are added.
- [ ] Add every new test to the standard SaySlate verification command/process.

### Exit gate

- [ ] All focused WSI-08 regression tests pass.
- [ ] All existing SaySlate and WSI tests remain green.
- [ ] No new permissions, provider fallback, prompt changes, UI changes, or WhisperService changes were introduced.

### Out of scope

New product behavior, UI redesign, prompt or AI-pass changes, additional providers, WhisperService changes, and release feature work.

---

## Integration-wide definition of complete

The integration is complete only when all eight ticket exit gates pass and the following remain true:

- SaySlate offers Browser Dictation and Local Whisper without changing its established look and workflow.
- The last selected provider and supported Local Whisper configuration survive reloads.
- The interface accurately distinguishes selected, active, available, unavailable, and authentication/origin error states.
- Local Whisper failures are explicit and never cause silent provider fallback.
- Each dictation run creates and destroys an isolated WhisperService session.
- Both SaySlate surfaces settle final speech before starting any downstream action.
- Existing prompts, multi-pass processing, output handling, insertion behavior, and Browser Dictation behavior remain intact.
- Credentials and dictated content do not leak through source, logs, URLs, extension messages, or diagnostics.

## Next dispatch

Create and assign WSI-01, WSI-02, and WSI-03 as the first three tickets. Do not dispatch WSI-04 until their public APIs and storage schema have been reviewed together for compatibility.
