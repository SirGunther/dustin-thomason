# SaySlate Status Badge — Requirements

Origin: [Original ticket](./sayslate-status-badge-original-ticket.md)

## Requirements

| ID | Condition that must be true | Source |
| --- | --- | --- |
| REQ-001 | While SaySlate runs a processing stage, the top status badge shows which stage is running rather than only "Ready", so the user can see that the system is working. | [Original ticket](./sayslate-status-badge-original-ticket.md), message 1: "it's not just a 'ready' but it displays the current status of the process" … "so you know that the system is working" |
| REQ-002 | **Superseded by REQ-003.** Stage labels use simple words in the form "Pass 1" and "Pass 2". | [Original ticket](./sayslate-status-badge-original-ticket.md), message 1: "keeping words simple like 'Pass 1' or 'Pass 2' etc." |
| REQ-003 | The full-page badge uses the same stage labels and states that Floating Slate's badge already shows ("Phase 1", "Phase 2", …). Floating Slate's wording stays as it is. | Dustin Thomason, 2026-09-24 clarification: "we want to keep it with phase one and phase two because that is how the extension inside the browser works" … "it should be consistent with what the standalone browser extension would do" … "change the wording to whatever it is over there" |

## Evidence

| ID | Fact about what exists | Direct pointer |
| --- | --- | --- |
| EV-001 | The full-page top bar holds the status badge, which starts in the `idle` state reading "Ready". | `C:\SaySlate\app.html:28-31` — `<div id="statusPill" class="status-pill" data-state="idle">` … `<span id="statusText">Ready</span>` |
| EV-002 | The full page changes the badge through one function that sets the state attribute and the label. | `C:\SaySlate\app.js:110-113` — `function setStatus(state, label) {` / `statusPill.dataset.state = state;` / `statusText.textContent = label;` |
| EV-003 | When dictation starts the badge reads "Listening"; when it stops, the badge returns to "Ready" unless it is in the `error` state. | `C:\SaySlate\app.js:913-917` — `setStatus("listening", "Listening");` … `} else if (statusPill.dataset.state !== "error") {` / `setStatus("idle", "Ready");` |
| EV-004 | Neither full-page AI pass changes the badge; only the button labels change while a pass runs. Every `setStatus` call in `app.js` is a dictation state, at lines 914, 916, 961, 967, 974, 984, 1002, 1109, 1139, 1167, and 1193. | `C:\SaySlate\app.js:719-731` — `firstPassLabel.textContent = running ? "Running first pass…" : "Run first pass";`, `secondPassLabel.textContent = running ? "Running second pass…" : "Run second pass";`; `runFirstPass` at `app.js:740-783` and `runSecondPass` at `app.js:785-834` contain no `setStatus` call |
| EV-005 | Each full-page pass resolves the provider profile before it sends a request, and returns early without a request when no profile is active. | `C:\SaySlate\app.js:758-763` and `app.js:810-815` — `const profile = await resolveActiveProfile();` / `if (!profile) {` … `return false;` |
| EV-006 | The full-page Finish workflow stops dictation, runs pass 1, runs pass 2 when enabled, copies the result, and clears everything. | `C:\SaySlate\app.js:1282-1320` — `await stopDictationAndWait();` … `runFirstPass({ scroll: false, announce: false })` … `if (processingConfig.secondPassEnabled) {` … `copyResultTranscript({ announce: false })` … `clearTranscript({ announce: false });` / `showToast("Finished · Final result copied · Everything cleared");` |
| EV-007 | Clearing and discarding on the full page do not reset the badge, except through `setListeningUI(false)` when dictation was active. The discard button stays enabled while dictating. | `C:\SaySlate\app.js:1260-1280` (`clearTranscript`; `setListeningUI(false)` at 1263 and 1269 only); `app.js:702-709` (`discardResultTranscript`, no status call); `app.js:686` — `discardResultButton.disabled = secondPassRunning \|\| finishWorkflowRunning;` |
| EV-008 | The full-page stylesheet styles only the `listening`, `retrying`, and `error` badge states, in light and dark themes. There is no `processing` or `complete` rule. | `C:\SaySlate\app.css:655-686` (light); `C:\SaySlate\app.css:1193-1196,1207-1219` (dark: `html[data-theme="dark"] .status-pill`, `.status-dot`, `[data-state="listening"]`, `[data-state="error"]`) |
| EV-009 | Floating Slate's badge sits in the overlay header and starts reading "Ready". | `C:\SaySlate\floating.html:24` — `<span id="status" class="status" data-state="idle"><i></i><span id="statusText">Ready</span></span>` |
| EV-010 | Floating Slate labels its pass stages "Phase", while its own notices for the same passes say "pass". | `C:\SaySlate\floating.js:243,261,264` — `setStatus("processing", "Phase 1")`, `setStatus("complete", "Phase 1 ready")`, `setStatus("error", "Phase 1 failed")`; `floating.js:282,300,303` — the same for "Phase 2"; `floating.js:244,283` — `showNotice("Running first pass…")`, `showNotice("Running second pass…")` |
| EV-011 | Floating Slate sets the pass label before it resolves the provider profile. With no active profile it returns without changing the badge again, so the badge keeps the pass label although no request is running. | `C:\SaySlate\floating.js:243-252` (first pass) and `floating.js:282-291` (second pass) — `setStatus("processing", "Phase 1");` … `const profile = await resolveActiveProfile();` / `if (!profile) {` … `return false;` |
| EV-012 | Clearing Floating Slate returns its badge to "Ready". | `C:\SaySlate\floating.js:339` — `setStatus("idle", "Ready");` inside `clearTranscript` |
| EV-013 | Floating Slate styles the `processing` and `complete` states: processing uses `#5b7fa3`, complete uses the accent color. | `C:\SaySlate\floating.css:80-85` — `.status[data-state="processing"] { border-color: #aebfd0; background: color-mix(in srgb, #5b7fa3 12%, transparent); color: #5b7fa3; }` … `.status[data-state="complete"] { border-color: var(--accent); background: var(--accent-pale); color: var(--accent); }` |
| EV-014 | The static verification requires the literal labels "Phase 1" and "Phase 2" in `floating.js`. | `C:\SaySlate\tests\verify.mjs:286-288` — `for (const phase of ["Phase 1", "Phase 2", "Inserting", "Retrying"]) {` |
| EV-015 | The README describes Floating Slate's indicator by stage, not by label text; the roadmap lists stage indicators as complete. | `C:\SaySlate\README.md:63` — "Its status indicator shows listening, retrying, first-pass, second-pass, and insertion progress."; `C:\SaySlate\ROADMAP.md:31` — "- [x] Stage indicators for listening, retrying, both processing passes, and insertion" |
| EV-025 | On the full page, the discard button stays enabled while the first pass runs. The Ctrl+Alt+X shortcut clears everything, which includes discarding the result, while either pass runs: the Clear button is disabled during passes, but the shortcut handler checks only the Finish workflow. | `C:\SaySlate\app.js:686` — `discardResultButton.disabled = secondPassRunning \|\| finishWorkflowRunning;`; `app.js:881` — `clearButton.disabled = … \|\| firstPassRunning \|\| secondPassRunning;`; `app.js:1344-1353` — `if (finishWorkflowRunning) {` … `clearTranscript();`; `app.js:1275` — `discardResultTranscript({ announce: false });` inside `clearTranscript` |
| EV-026 | The Ctrl+Alt+D shortcut starts dictation while a full-page pass runs from its button or shortcut, although the start button is disabled then. Starting dictation sets "Listening" and stopping it sets "Ready" through `setListeningUI`, so dictation and a pass request can overlap. | `C:\SaySlate\app.js:878` — `startButton.disabled = finishWorkflowRunning \|\| firstPassRunning \|\| secondPassRunning;`; `app.js:1344-1349` — `if (finishWorkflowRunning) {` … `toggleDictation();`; `app.js:980-1005` (`startDictation`, no pass check); `app.js:904-917` (`setListeningUI`); `C:\SaySlate\README.md:11` — "**Ctrl + Alt + D** — start dictating" |

## Implementation conventions

| ID | Fact about what exists | Direct pointer |
| --- | --- | --- |
| EV-016 | Renderer code is classic scripts wrapped in an immediately invoked function, loaded by ordered `<script>` tags; there are no ES-module imports. | `C:\SaySlate\app.js:1` and `C:\SaySlate\floating.js:1` — `(() => {`; `C:\SaySlate\app.html:408-420`; `C:\SaySlate\floating.html:64-75` |
| EV-017 | `node tests/verify.mjs` is the one standard verification command. It runs every `tests/*.test.mjs` file, then runs static checks, including a required-file list that names every test file. | `C:\SaySlate\tests\verify.mjs:9-22` — "This file is the project's one standard verification command"; `tests/verify.mjs:83-139` (`const requiredFiles = [` … `"tests/floating-dictation-integration.test.mjs",`) |
| EV-018 | The full-page integration test loads the real provider modules and then the real `app.js` into a `node:vm` context with a fake DOM. The fake DOM exposes `statusPill` and `statusText` with `dataset` and `textContent`. A `responder` controls what each AI call returns. | `C:\SaySlate\tests\app-dictation-integration.test.mjs:20-35` (`ELEMENT_IDS` including `"statusPill", "statusText"`); `:37-82` (`createElement` with `dataset: {}` and `textContent: ""`); `:209-219` (`createFakeAiClient(responder)`); `:226-287` (`buildContext`); `:638-678` (existing scenario: both passes through Finish) |
| EV-019 | The Floating Slate integration test runs the real `floating.js` with a registered `status`/`statusText` element and pass buttons. Its fake AI adapter returns a fixed string. | `C:\SaySlate\tests\floating-dictation-integration.test.mjs:70-89` (`register("status")`, `register("statusText")`, `register("firstPassButton")`, `register("secondPassButton")`); `:239-244` — `async generateStructured({ userPrompt }) {` … `return "PROCESSED TEXT";` |
| EV-020 | The baseline passes: `node tests/verify.mjs` exits 0 on `668a10fee66d513615a19972778b19019770fbc5`, under Node v24.11.1. | Run on 2026-09-24 in `C:\SaySlate`; `node --version` → `v24.11.1` |
| EV-021 | SaySlate has no `package.json`, so no dependency graph or install step. | `find` over `C:\SaySlate` excluding `.git`, 2026-09-24: no `package.json` |
| EV-022 | SaySlate has no repository-local `AGENTS.md`, `CLAUDE.md`, `.agents`, or `.codex` instruction source. | `find` and root listing of `C:\SaySlate`, 2026-09-24 |
| EV-023 | `CHANGELOG.md` records verified changes, and pending work goes under `[Unreleased]`. | `C:\SaySlate\CHANGELOG.md:3` — "This file records verified SaySlate changes."; `CHANGELOG.md:15` — `## [Unreleased]` |
| EV-024 | Playwright 1.61.1 is installed outside the SaySlate repository and has been used to launch Chromium with an unpacked SaySlate worktree loaded. | `C:\dustin-thomason\scripts\browser\node_modules\playwright\package.json` — `"version": "1.61.1"`; prior use recorded in `../sayslate-ai-provider-tailscale/sayslate-ai-provider-tailscale-handoff.md`, dispatch rule 6 |

## Scope boundary

| Repo or path | Access |
| --- | --- |
| `C:\SaySlate\app.js`, `app.css`, `tests\app-dictation-integration.test.mjs`, `CHANGELOG.md` (`[Unreleased]` only) | Writable |
| Every other path in `C:\SaySlate`, including `floating.js`, `floating.css`, `floating.html`, `app.html`, `tests\floating-dictation-integration.test.mjs`, `tests\verify.mjs`, `README.md`, `ROADMAP.md`, and the provider and speech modules | Read-only. Floating Slate stays as it is per REQ-003. |
| `C:\WhisperService` | Read-only; not touched |
| `C:\dustin-thomason\docs\SaySlate\tickets\sayslate-status-badge\` | Writable by the author and orchestrating agent. Each ticket's checkboxes and objectives are writable by its assigned implementation agent. |
| Every other path in `C:\dustin-thomason`, including `docs\SaySlate\tickets\sayslate-ai-provider-tailscale\` | Read-only |

The other three SaySlate features in the same request (Whisper model selection, a reasoning option, a reconcile pass) are outside this work: [Original ticket](./sayslate-status-badge-original-ticket.md), message 2, "addresses number 4".

## Readiness

| Prerequisite | Status | Evidence |
| --- | --- | --- |
| `C:\SaySlate` on `main`, clean, equal to `origin/main` | Met | `git status --short --branch` → `## main...origin/main`; `git rev-parse HEAD origin/main` → `668a10fee66d513615a19972778b19019770fbc5` for both, 2026-09-24 |
| Worktree root `C:\SaySlate-worktrees` exists; no `saystat-*` branch or worktree | Met | `git worktree list` and `git branch -a`, 2026-09-24: only `sayai-01` through `sayai-05` exist |
| Push access to `origin` (`SirGunther/SaySlate`) | Met | `remotes/origin/agent/sayai-01-provider-profiles` through `sayai-05` were pushed from this machine |
| Node for gates | Met | EV-020 |
| Baseline gate green | Met | EV-020 |
| Loaded-extension check tooling | Met | EV-024 |
