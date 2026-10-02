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

### 2026-09-28T21:30:00Z — Logged-in ChatGPT: composer located, send button found in its form

- **Problem:** two symptoms, both from the user's logged-in live test on `c17c85c`.
  - SaySlate sat on "Preparing send" with the blue arrow never pressed. The logged-in Send is
    `<button type="submit" aria-label="Send">`, which has no id and no `data-composer-submit`. It
    was copied by the user and is identical in temporary and regular chats.
  - On a fresh chat, SaySlate refused with "Place the cursor in the ChatGPT message composer…"
    because focus was not in the composer when Floating Slate opened. The user's requirement is
    that the composer is always found.
- **Requirement:**
  - Press only the composer's own send button.
  - Find the composer when the saved target is not the composer.
  - Keep refusing when there are zero or two visible composers, when the composer was replaced,
    and off ChatGPT.
- **Solution** (`chatGPTAdapter.js`; per the user, all ChatGPT markup knowledge lives there):
  - Selectors are declared once, each with a note naming the markup it matches.
  - `findSendButton(composer, document)` returns, inside the composer's own form, the first known
    marker, else the first `button[type='submit']`. Outside that form it returns a page-wide known
    marker only. A `type=submit` button only submits its own form.
  - `findComposer(document)` returns the single visible composer.
  - `floatingHost.js` only calls them. A found composer is captured at the end of its content, so
    text is appended after a draft.
- **Process:**
  1. An implementation subagent committed `c72ad1e`.
  2. The code review asked for changes, and the test review found gaps. Both independently
     reproduced the same blocking defect: the first design walked every ancestor up to body, so
     it could reach the app root and press an unrelated form's submit button. Every fixture had
     sat directly under body, so no test caught it.
  3. The fix round, `c5d78f8`, limits the search to the composer's form. It adds app-shell
     negatives, a Send element re-rendered during the wait, a composer hidden by a stylesheet, and
     a draft that is appended to.
  4. Re-review: approved, and the tests valid. Every mutation (a, m, l, n, o, h, k, d2, c, d, e,
     i, j) is caught.
- **Shipped:** merged to local `main` as `553590a` (`--no-ff`, not pushed; `main` is 7 ahead of
  `origin/main`).
- **Tests run:**

  | Gate | Command | Scope | Result | Exception / risk |
  | ---- | ------- | ----- | ------ | ---------------- |
  | tests | `node tests/verify.mjs` | merged `main`, 25 test files plus static checks | pass | — |
  | whitespace | `git diff --check c17c85c HEAD` | merged change | pass | — |
  | browser | `node tests/browser/chatgpt-composer.browser.mjs --live` | branch `c5d78f8`: B1–B19, L1 | 20 of 20 pass | opt-in; L1 blocked the send click, 0 POSTs |
  | audit, lint | — | — | not applicable | SaySlate has no `package.json` |

- **Regression impact:** plain insert (Ctrl+Alt+F), the replaced-composer path (copied, not sent),
  the off-ChatGPT refusal, the logged-out form, and the `#prompt-textarea` markup are all covered
  and passing. B7 changed on purpose: a saved non-composer field now leads to the found composer.
- **Left open, unverified:**
  - Whether the logged-in Send shares a `<form>` with the composer. The artifact does not show
    it. If it does not, SaySlate inserts and does not send; it never presses another button.
  - Stop mode while a reply streams.
  - A draft's trailing space collapses when text is appended. This is pre-existing behavior and
    may be a harness artifact.

### 2026-09-28T19:40:00Z — ChatGPT send button: captured, reviewed, tests match the page

- **Problem:** the send button changed, and SaySlate must press the new one. The user will not log
  in to a remote-debugging Chrome profile, which would expose the session. So the logged-in page
  cannot be observed. The debug window was closed, port 9222 verified shut, and its never-logged-in
  profile deleted.
- **Capture:** Playwright on chatgpt.com without a login (pipe transport, no port), box empty and
  then typed. The send button is `button[data-composer-submit]`, with `type="submit"` and
  `aria-label="Send message"`, inside `form[data-mobile-composer]`. There is no
  `#composer-submit-button`. Ready is signalled by removing `aria-disabled="true"` and
  `data-visually-disabled`; `disabled` stays false in both states.
- **Finding:** `main` already selected and waited on that button since `8a7c108`. That code had not
  been independently reviewed.
- **Reviews:**
  - Code reviewer: approved. The selector matches only Send, and readiness matches the capture.
  - Test reviewer: gaps found. No fixture held the captured add-files or dictation buttons, so
    widening the selector to them passed every test (M13). Ready was modeled as
    `aria-disabled="false"`, and the not-ready to ready change was never run end to end.
- **Fix, tests only:**
  - An implementation subagent committed `2f51b07` on `fix/sayslate-send-button-tests`.
  - New `tests/support/chatGPTLoggedOutComposer.mjs` holds the captured markup and its typed-state
    change.
  - The adapter, floating-host, and browser fixtures carry all three buttons.
  - New browser scenario B11: Send never becomes ready, and nothing is pressed.
  - No production file changed.
- **Re-review:** valid.
  - Fixtures match the capture exactly, by a comparison script.
  - M1–M13 and M13b are caught. M13 and M13b fail both node suites and B5/B11.
  - M6 (treat any `aria-disabled` as not ready) now passes, which is correct for the real page.
- **Shipped:** merged to local `main` as `c17c85c` (`--no-ff`, not pushed; `main` is 4 ahead of
  `origin/main`).
- **Tests run:**

  | Gate | Command | Scope | Result | Exception / risk |
  | ---- | ------- | ----- | ------ | ---------------- |
  | tests | `node tests/verify.mjs` | merged `main`, 25 test files | pass | — |
  | whitespace | `git diff --check 8a7c108 HEAD` | merged change | pass | — |
  | browser | `node tests/browser/chatgpt-composer.browser.mjs --live` | branch `2f51b07`: B1–B11, L1 | 12 of 12 pass | opt-in; L1 blocked the send click, 0 POSTs |
  | audit, lint | — | — | not applicable | SaySlate has no `package.json` |

- **Regression impact:** none in production. `chatGPTAdapter.js`, `floatingHost.js`, and
  `shortcutProtocol.js` have a 0-line diff from `8a7c108`.
- **Left open, both unverified:**
  - The logged-in send button, which was not observable without a login.
  - Stop mode, raised by both reviewers. The Send button carries
    `data-stop-label="Stop generating"`, so pressing Ctrl+Alt+S while a reply streams might press
    Stop. Checking it needs a generating state, which means sending a message.

### 2026-09-28T17:45:00Z — Floating Slate process and submit accepts ChatGPT's current composer

- **Context:** another agent was asked to fix "an error when the extension drops completed text"
  into the ChatGPT composer (captured markup in the prompt, now
  `C:\SaySlate\tests\fixtures\chatgpt-composer-2026-09-28.html`), on local branch
  `fix/sayslate-floating-input`. This session reviewed that work, added tests, and merged.
- **Review of the other agent's change: rejected.** It left one uncommitted edit to
  `floatingHost.js`, which wrapped the manual contenteditable fallback in `try/catch` and rewrote
  its event as `new InputEvent({ bubbles, composed, inputType, data })`.
  - It does not touch the cause. The error comes from `chatGPTAdapter.js`, and with the edit the
    captured composer is still refused with the same message.
  - It adds a defect. `InputEvent`'s first argument is the event type, so the fallback now
    dispatches a non-bubbling event named `"[object Object]"` and never an `input` event.
  - The `try/catch` duplicates the one already in `commitText`. `git diff --check` fails on five
    trailing-whitespace lines.
  - `node tests/verify.mjs` still passed, because no test covered this code. The edit was
    discarded before the fix; the points above describe all of it.
- **Problem:** on chatgpt.com, process and submit (Ctrl+Alt+S or the send icon) fails after the
  passes finish with "Place the cursor in the ChatGPT message composer before opening SaySlate."
  `isChatGPTComposer` accepted only `#prompt-textarea`, or a textarea whose form holds
  `#composer-submit-button`. ChatGPT's current composers have neither:
  - The logged-in ProseMirror composer in the captured markup has no id. It carries
    `data-composer-markdown`.
  - The logged-out composer, observed live on 2026-09-28, is `textarea#mobile-composer-prompt`.
    Its send button is `button[data-composer-submit]`.
- **Requirement:** process and submit must accept ChatGPT's message composer in each variant it
  serves, and still refuse other fields on chatgpt.com, other hosts, a replaced composer, and a
  send button that never becomes enabled.
- **Solution:** in `chatGPTAdapter.js`, the editor selector adds
  `[contenteditable='true'][data-composer-markdown]` and the send selector adds
  `button[data-composer-submit]`. `floatingHost.js` is unchanged from `main`.
- **Tests added:**
  - `tests/chatgpt-adapter.test.mjs`: four accepted composer variants; five refused fields; send
    buttons by id, by attribute, and enabled late; refusal when disabled, aria-disabled, an
    unrelated submit, a text mismatch, or a replaced composer. It uses the new shared
    `tests/support/elementModel.mjs`.
  - `tests/floating-host-insert.test.mjs` (new): drives `floatingHost.js` through runtime messages.
    Positive: submits from the id-less ProseMirror composer and from the logged-out textarea; the
    manual fallback dispatches one bubbling `input` event. Negative: replaced composer (copied, not
    submitted); non-composer field; unmarked ProseMirror editor; off ChatGPT; insertion and both
    clipboard paths failing.
  - `tests/browser/chatgpt-composer.browser.mjs` (new, opt-in, Playwright with Chrome): scenarios
    B1–B10 in real Chrome on fixture pages served at `https://chatgpt.com/`, one with a real
    ProseMirror editor, plus L1 against the live logged-out chatgpt.com. L1 intercepts the send
    click and aborts conversation POSTs, so nothing is sent.
- **Evidence** (browser check, 2026-09-28):

  | Scenario | `main` | Other agent's edit | This fix |
  | -------- | ------ | ------------------ | -------- |
  | B1 captured markup, submit | fail: wrong-target | fail: wrong-target | pass |
  | B2 real ProseMirror, submit | fail: wrong-target | fail: wrong-target | pass |
  | B3 manual fallback `input` event | pass | fail: `"[object Object]"` | pass |
  | B4 `#prompt-textarea` markup | pass | pass | pass |
  | B5 logged-out textarea markup | fail: wrong-target | fail: wrong-target | pass |
  | B6 composer replaced: copied, not sent | fail: wrong-target first | fail: wrong-target first | pass |
  | B7 other chatgpt.com field refused | pass | pass | pass |
  | B8 unmarked ProseMirror refused | pass | pass | pass |
  | B9 non-ChatGPT host refused | pass | pass | pass |
  | B10 send never enabled: 20 s bound | fail: wrong-target first | fail: wrong-target first | pass |
  | L1 live logged-out chatgpt.com | fail: wrong-target | not run | pass: ChatGPT enabled its send button, 0 POSTs |

  The new unit tests fail on `main` and on the other agent's edit with the user-visible message.
  Mutation probes M1–M8 each fail a new test: dropping either new selector, accepting
  non-editable or non-button markers, removing or de-bubbling the fallback event, skipping the
  wrong-target guard, and submitting after a clipboard fallback.
- **Left open:** the logged-in composer was checked through the captured markup and a real
  ProseMirror editor, not the live logged-in page. The capture does not include the logged-in send
  button. If it has neither `#composer-submit-button` nor `data-composer-submit`, text is inserted
  and not sent, with the 20 s message. The remaining check is one Ctrl+Alt+S run on the user's
  logged-in ChatGPT.
- **Tests run:**

  | Gate | Command | Scope | Result | Exception / risk |
  | ---- | ------- | ----- | ------ | ---------------- |
  | tests | `node tests/verify.mjs` | all 25 `tests/*.test.mjs` plus static checks | pass | — |
  | syntax | `node --check` | 5 changed or added `.js`/`.mjs` files | pass | — |
  | whitespace | `git diff --check` | working tree | pass | — |
  | browser | `node tests/browser/chatgpt-composer.browser.mjs --live` | B1–B10, L1 | 11 of 11 pass | opt-in; needs Playwright and Chrome |
  | audit, lint | — | — | not applicable | SaySlate has no `package.json` |

- **Regression impact:** `floatingHost.js`, `floating.js`, and `background.js` are unchanged. The
  adapter change adds selectors and removes none. B4 and the `#composer-submit-button` cases pass.
- **API docs:** not relevant. SaySlate is a Chrome extension with no HTTP API; the runtime message
  shapes checked in `background.js` and `floatingHost.js` are unchanged.
- **Shipped:** `be3ae6e` "Accept current ChatGPT composers for submission" on
  `fix/sayslate-floating-input`, merged to local `main` as `8a7c108` (`--no-ff`, not pushed;
  `main` is 2 ahead of `origin/main`). On merged `main`, `node tests/verify.mjs` (25 files),
  `git diff --check cd0a82a HEAD`, and browser scenarios B1–B10 pass again.

### 2026-09-24T22:18:00Z — SAYREASON-01A merged: LM Studio passes stream and time out on silence

- **Problem:** in the live check, a reasoning pass showed "timed out" in SaySlate while LM Studio
  finished the request. The adapter sent one non-streamed request under one 90 s timer (EV-025).
  Generation time grows with the tokens produced, about 26 tokens/s on the Chrome machine, so any
  response over about 2,350 tokens fails, with reasoning on or off (EV-029).
- **Requirement:** REQ-004. A Custom pass is not reported as timed out while the server is still
  producing its response, and it still fails when the server stops.
- **Solution (LD-007):** Custom requests send `stream: true`. The 90 s timer restarts on every
  chunk, so it measures silence. The SSE `content` deltas are joined and validated like the JSON
  result, and `reasoning_content` is ignored. OpenAI, Gemini, Claude, and the schema-free retry are
  unchanged. Before deciding, a probe of the Chrome machine's LM Studio showed that it streams the
  exact SaySlate request shape, with no gap above 840 ms (EV-028).
- **Shipped:** SaySlate `main` `cd0a82a` (`--no-ff`, pushed), merged after SAYSTAT-01A's `7e3e7b9`
  with no conflict. Files: `aiProviderClient.js`, `openAICompatibleClient.js`, three test files, and
  `CHANGELOG.md`.
- **Verification:**
  - `node tests/verify.mjs`, `node --check`, and `git diff --check` pass on the branch and on merged
    `main`.
  - Mutation probes fail when the per-chunk timer restart or the dispatcher's `stream` is removed.
  - Live on the Chrome machine's LM Studio with a 5 s limit: the streamed pass completed in 37 s,
    and the same request non-streamed timed out at 5 s.
- **Left open:**
  - Rerun a long reasoning pass through the installed extension and the LM Studio host. That also
    confirms Tailscale Serve passes the stream through.
  - The endpoint doc's "AI pass" row (90 s, `"none"`) and V5 row are outside this handoff's writable
    section and still describe the old behavior.

### 2026-09-24T20:05:00Z — SAYSTAT-01A merged: full-page shortcuts follow their buttons during a pass

- **Why:** SAYSTAT-01's audit left Ctrl+Alt+D and Ctrl+Alt+X acting during a pass although their
  buttons are disabled then. That note was wrongly handed to the user as a decision. It is
  resolvable from the code: each button's disabled condition is the rule for its shortcut (REQ-004,
  LD-008). The same gap existed for Ctrl+Alt+R during the second pass (EV-027).
- **Shipped:** SaySlate `main` `7e3e7b9` (`--no-ff`, pushed). While a pass runs, Ctrl+Alt+D and
  Ctrl+Alt+X do nothing, and neither does Ctrl+Alt+R during the second pass. Each shows Finish's
  existing toast, "AI processing is already running". Since dictation can no longer overlap a pass
  (EV-029), SAYSTAT-01's LD-007 compensation was removed: the pass result states are unconditional
  again, and `setListeningUI` is back to its pre-SAYSTAT-01 form (LD-009). Files: `app.js`,
  `tests/app-dictation-integration.test.mjs`, `CHANGELOG.md`.
- **Review:** two rounds. F1: the Ctrl+Alt+R toast assertion could not fail, because it re-read the
  toast Ctrl+Alt+D had just set. A mutation probe showed this, and the fix is in `bbfba0d`. Details
  are in the handoff's SAYSTAT-01A audit record.
- **Verification:** `node tests/verify.mjs`, `node --check` on the changed files, and
  `git diff --check` pass on the branch and on merged `main`. The F1 mutant now fails.
- **Status badge handoff:** complete. SAYSTAT-01 and SAYSTAT-01A are merged, SAYSTAT-02 is withdrawn,
  and no residual risk is open.

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
  - Floating Slate process and submit on ChatGPT (`553590a`, local `main`, not pushed). Not
    verified: the user's logged-in Ctrl+Alt+S run, which confirms the Send shares the composer's
    form, and Ctrl+Alt+S during a streaming reply (Stop).
  - Per-pass reasoning (`tickets/sayslate-pass-reasoning/`, merged through `cd0a82a`) is complete;
    on 2026-09-24 the user confirmed a reasoning pass completes without a timeout. Optional: the
    endpoint doc's "AI pass" and V5 rows still describe the old fixed `"none"` and 90 s total limit.
  - Write the SAYAI-06 validation review; the README and ROADMAP updates wait for it (LD-029).
  - A successful Gemini generation on this build; OpenAI and Claude profiles run live.
- **Someday:** self-host the Tailscale coordination server (Headscale) and a relay on spare
  hardware, removing the dependency on Tailscale's service.
- **Side effect:** LM Studio token auth is server-wide, so Argus's local LM Studio provider gets 401
  on that host until Argus supports tokens, or auth is turned off.
