# OtterCopy App Changelog

## Purpose
This changelog tracks development and changes within the OtterCopy browser extension.

## Scope
Personal project changelog for extension behavior, prompt workflow changes, notification integrations, and verification notes.

## Session log

### 2026-06-30T15:09:58Z — OtterCopy
- **Summary:** Migrated standard-refine prompts to a code-versioned, sync-backed library.
- **Files/Areas:** `promptStore.js` (core refactor), `background.js`, `popup.js`, `prompts/custom/index.json` (new), `prompts/custom/handoff.md` (moved from `prompts/handoff.md`), `prompts/_archive/refinement-objective-preamble.md` (new); deleted `prompts/refinement.md` and `prompts/handoff.md`.
- **User-visible impact:** The prompt list now seeds four code-versioned built-ins from packaged files — Refinement, Summary, Variables, Handoff — identical on every install (was: a single `Refinement` built-in plus browser-cache-only user prompts). Edits and the active selection persist in `chrome.storage.sync`, so they travel across signed-in browsers/machines instead of being siloed in one browser's `chrome.storage.local`. Reset restores the packaged file content. Handoff is now a selectable prompt and the same file (`prompts/custom/handoff.md`) still drives the extended-handoff pipeline. The `# Objective:` preamble from the retired top-level refinement prompt is parked, unused, under `prompts/_archive/`.
- **Storage model:** `promptStore.js` no longer stores one `ottercopyPrompts` array in `storage.local`. Built-in content is hydrated from packaged files (never synced); `chrome.storage.sync` holds only lightweight per-prompt items — `ottercopy:activePromptId`, `ottercopy:override:<id>` (edited built-ins), `ottercopy:custom:<id>` (user prompts) — one item each to respect `QUOTA_BYTES_PER_ITEM`. A one-shot `ottercopy:migratedV2` migration folds the legacy local array into the new keys (built-in edits → overrides only when they differ from the packaged file; user prompts → custom keys; active selection preserved). Public store API unchanged.
- **Tests run:**

| Gate | Command | Scope | Result | Exception / risk |
| ---- | ------- | ----- | ------ | ---------------- |
| syntax | `node --check promptStore.js` | prompt store refactor | pass | — |
| syntax | `node --check background.js` | handoff path repoint + regression surface | pass | — |
| syntax | `node --check popup.js` | prompt UI meta label | pass | — |
| syntax | `node --check content.js` | content script regression surface | pass | — |
| manifest | `node -e "JSON.parse(fs.readFileSync('manifest.json'))"` | extension manifest | pass | — |
| data | `node -e "JSON.parse(.../index.json)"` (4 entries) | library index | pass | — |
| behavior | mocked Node-VM harness for `promptStore.js` (5 scenarios, 24 assertions) | seed, edit+reset, custom CRUD, quota guard, legacy migration | pass | — |

- **Tests added/updated:** No persistent automated tests added; this repo has no `package.json`/test harness (consistent with prior sessions). Verification used `node --check`, JSON parse, and a temporary mocked Node-VM harness (run, then left only in the session scratchpad outside the repo). Residual risk: live Chrome `chrome.storage.sync` propagation across a second signed-in profile, and the one-shot legacy migration against real cached `ottercopyPrompts` data, should be confirmed in a loaded extension.
- **Regression impact:** Standard `ai-refine` and `extended-refine` still read the active prompt via the unchanged `getPrompts`/`getActivePrompt` API (background.js call sites untouched). The extended-handoff pipeline still sources its governing prompt from a file (`governingPromptSource:"file"`), now `prompts/custom/handoff.md`; handoff prompt text was moved verbatim. Semantic-block, personas, extended section directives, model orchestration, polling, cancellation, and notifications are unchanged.
- **API docs:** Not relevant: browser extension only; no HTTP API contract or Swagger/OpenAPI surface. Internal change is the prompt-storage layer and one packaged-file path constant.
- **Tooling gates:** No package-level lint/test/audit gates apply because the repo has no `package.json`; direct syntax, manifest, JSON, and mocked-behavior checks were run with Node.

### 2026-06-26T05:30:02Z — OtterCopy
- **Summary:** Added popup terminal-status announcement for watched refinement jobs.
- **Files/Areas:** `popup.js`
- **User-visible impact:** If the popup remains open after starting Refine, Extended refinement, or Engineering handoff, the main status now updates when the watched latest-result run leaves `running`: completed runs say the refinement is ready and point to `Copy latest result`; failed and cancelled runs surface their terminal state.
- **Tests run:**

| Gate | Command | Scope | Result | Exception / risk |
| ---- | ------- | ----- | ------ | ---------------- |
| syntax | `node --check popup.js` | popup script | pass | — |
| syntax | `node --check background.js` | background service worker regression surface | pass | — |
| syntax | `node --check content.js` | content script regression surface | pass | — |
| manifest | `node -e "JSON.parse(require('fs').readFileSync('manifest.json','utf8')); console.log('manifest ok')"` | extension manifest | pass | — |

- **Tests added/updated:** No persistent automated tests added; this repo has no package/test harness. Residual risk: the live popup polling transition should be verified in Chrome with a real refinement run.
- **Regression impact:** Latest-result polling still stops on terminal states. Manual `Copy latest result` suppresses the ready announcement so it does not overwrite `Latest result copied.` Exact transcript copy and background job execution are unchanged.
- **API docs:** Not relevant: browser extension only; no HTTP API contract or Swagger/OpenAPI surface exists. This changes popup presentation only.
- **Tooling gates:** No package-level lint/test/audit gates apply because the repo has no `package.json`; direct syntax and manifest checks were run with Node.

### 2026-06-26T05:21:31Z — OtterCopy
- **Summary:** Removed background clipboard auto-copy and fixed manual latest-result copy fallback.
- **Files/Areas:** `background.js`, `popup.js`, `manifest.json`
- **User-visible impact:** `Refine and copy` now completes by saving the refined artifact and sending the notification; it does not attempt to write to the clipboard after the user leaves the page. `Copy latest result` now catches popup async clipboard failures and falls back to a focused textarea copy path.
- **Tests run:**

| Gate | Command | Scope | Result | Exception / risk |
| ---- | ------- | ----- | ------ | ---------------- |
| syntax | `node --check background.js` | background service worker | pass | — |
| syntax | `node --check popup.js` | popup script | pass | — |
| syntax | `node --check content.js` | content script regression surface | pass | — |
| manifest | `node -e "JSON.parse(require('fs').readFileSync('manifest.json','utf8')); console.log('manifest ok')"` | extension manifest | pass | — |

- **Tests added/updated:** No persistent automated tests added; this repo has no package/test harness. Residual risk: manual copy should still be verified in a loaded Chrome extension popup because clipboard permission behavior can vary by browser focus state.
- **Regression impact:** Standard Refine no longer depends on clipboard success to mark the job completed. Exact transcript copy remains content-script based. Extended refinement/handoff continue to save and notify without auto-copy. `Copy latest result` and debug-log copy share the hardened popup copy fallback.
- **API docs:** Not relevant: browser extension only; no HTTP API contract or Swagger/OpenAPI surface exists. Internal `refineTranscript` still starts a background job; terminal success now means saved, not copied.
- **Tooling gates:** No package-level lint/test/audit gates apply because the repo has no `package.json`; direct syntax and manifest checks were run with Node.

### 2026-06-26T05:01:35Z — OtterCopy
- **Summary:** Moved standard Refine copy completion into the background clipboard flow.
- **Files/Areas:** `background.js`, `popup.js`, `manifest.json`, `offscreen.html`, `offscreen.js`
- **User-visible impact:** `Refine and copy` now starts a background refinement job and releases the popup immediately. When the job completes, the service worker writes the refined text through an offscreen extension clipboard page, saves the output as the latest result, sends the existing Power Automate success/failure notification, and only uses the page toast when the original tab is still reachable.
- **Tests run:**

| Gate | Command | Scope | Result | Exception / risk |
| ---- | ------- | ----- | ------ | ---------------- |
| syntax | `node --check background.js` | background service worker | pass | — |
| syntax | `node --check popup.js` | popup script | pass | — |
| syntax | `node --check content.js` | content script regression surface | pass | — |
| syntax | `node --check offscreen.js` | offscreen clipboard writer | pass | — |
| manifest | `node -e "JSON.parse(require('fs').readFileSync('manifest.json','utf8')); console.log('manifest ok')"` | extension manifest | pass | — |

- **Tests added/updated:** No persistent automated tests added; this repo has no package/test harness. Residual risk: live Chrome offscreen clipboard permission behavior should be checked with the loaded extension against a real Otter transcript.
- **Regression impact:** Exact transcript copy remains content-script based. `Copy latest result` and debug-log copy still use popup clipboard writes. Extended refinement/handoff background storage, polling, cancellation, and notification behavior remain on the existing extended path; standard Refine now shares the same latest-result/notification lifecycle and adds an offscreen clipboard completion step.
- **API docs:** Not relevant: browser extension only; no HTTP API contract or Swagger/OpenAPI surface exists. Internal Chrome message behavior for `refineTranscript` now starts a background job instead of returning refined text synchronously.
- **Tooling gates:** No package-level lint/test/audit gates apply because the repo has no `package.json`; direct syntax and manifest checks were run with Node.

### 2026-06-24T16:58:14Z — OtterCopy
- **Summary:** Added a session-only prompt override toggle for the existing Direction input and made single-pass AI refinement save as the latest copyable result.
- **Files/Areas:** `popup.html`, `popup.css`, `popup.js`, `background.js`
- **User-visible impact:** The popup now has `Use direction as the only prompt` under the Direction box. When checked and Direction has text, Refine and copy, Extended refine and copy, and Engineering handoff use that text as the governing prompt instead of the active/file prompt. The text is not also injected as steering guidance, avoiding duplicate prompt pressure. Single-pass Refine and copy now updates `Copy latest result` with the generated output.
- **Tests run:**

| Gate | Command | Scope | Result | Exception / risk |
| ---- | ------- | ----- | ------ | ---------------- |
| syntax | `node --check popup.js` | popup script | pass | — |
| syntax | `node --check background.js` | background service worker | pass | — |

- **Tests added/updated:** No persistent automated tests added; this repo has no package/test harness. Residual risk: live Chrome popup/provider behavior should be checked with an installed extension run against a real Otter transcript.
- **Regression impact:** Override is gated by a new unchecked checkbox plus non-empty Direction text; unchecked runs keep the existing active/file prompt and direction-steering behavior. Exact transcript copy, transcript extraction, prompt storage, provider adapters, cancellation, and extended saved-result polling remain unchanged.
- **API docs:** Not relevant: browser extension only; no HTTP API contract or Swagger/OpenAPI surface exists. Internal Chrome message payloads gained optional `useDirectionAsPrompt` metadata only.
- **Tooling gates:** No package-level lint/test/audit gates apply because the repo has no `package.json`; 

### 2026-06-15T21:12:00Z — OtterCopy
- **Summary:** Added an optional "Direction" steering input that is injected into every agent across the refinement, extended refinement, and engineering handoff pipelines.
- **Files/Areas:** `popup.html`, `popup.css`, `popup.js`, `background.js`
- **User-visible impact:** The popup now shows an optional "Direction (optional)" textarea above the action buttons. When the user types steering text and runs Refine and copy, Extended refine and copy, or Engineering handoff, that text is threaded through the background job and injected as a labeled, guard-railed block into every model call: the semantic-block preflight, each primary/secondary persona pass, final synthesis, objective insertion, and the single-pass refine prompt. The injected block instructs agents to use the direction to focus/prioritize topics when a transcript spans multiple subjects, while still grounding all claims in the transcript and preferring the transcript on conflict. Empty direction preserves prior behavior exactly. The direction is recorded on the saved result and the extended debug log (provided flag, character count, preview) for inspection. Direction is captured per run from the popup and is not persisted across popup sessions.
- **Tests run:** `node --check background.js` and `node --check popup.js` — syntax checks passed. Mocked Node VM run of `runExtendedRefinementJob(...)` with fake Chrome/fetch/model clients — verified a direction marker reached all 17 model calls in the no-repair refinement path (1 semantic block + 14 persona + 1 final synthesis + 1 objective insertion) and that the steering label is absent from all calls on an empty-direction run.
- **Tests added/updated:** No persistent automated tests added; this repo still has no package/test harness. The verification harness was a temporary Node VM script, run then removed. Residual risk: live provider steering quality (how strongly models honor the direction without fabricating support) should be checked with a real multi-topic Otter transcript.
- **Regression impact:** Direction defaults to empty and the injected block is omitted when empty, so single-pass refine, extended refine, and handoff outputs are unchanged for runs without direction (verified: no steering label leaks into empty-direction calls). Copy exact transcript, transcript extraction, model/prompt orchestration, saved-result polling, cancellation, repair calls, and provider adapters remain unchanged.
- **API docs:** Not relevant: browser extension only; no HTTP API contract or Swagger/OpenAPI surface exists in this repo. The internal Chrome message payloads gained an optional `direction` field on the refine/extended/handoff actions; no external contract.
- **Tooling gates:** No package-level lint/test/audit gates apply because the repo has no `package.json`; direct syntax checks and a mocked orchestration check were run with Node.

### 2026-06-08T03:00:52Z — OtterCopy
- **Summary:** Migrated the legacy in-repo OtterCopy changelog into this canonical dustin-thomason changelog.
- **Files/Areas:** `docs/OtterCopy/OtterCopy-app-changelog.md`; `OtterCopy/docs/ottercopy/ottercopy-changelog.md`
- **User-visible impact:** Documentation history now lives in the canonical personal-project changelog location used by AGENTS guidance, while preserving the previously separate in-repo session history.
- **Legacy source metadata preserved:** Title `# OtterCopy Changelog`; Purpose `Track implementation sessions for the OtterCopy browser extension.`; Scope `Personal project changelog for extension behavior, prompt workflow changes, and verification notes.`
- **Tests run:** PowerShell merge verification counted all 16 legacy session entries and both pre-existing canonical session entries before writing; post-merge verification confirmed every legacy session heading is present in this file.
- **Tests added/updated:** Not relevant: documentation migration only.
- **Regression impact:** Documentation-only migration; extension runtime behavior and shipped files remain unchanged by this entry.
- **API docs:** Not relevant: changelog-only documentation migration; no browser extension HTTP API contract exists.
- **Tooling gates:** No package-level lint/test/audit gates apply to this documentation-only migration.

### 2026-06-08T02:52:47Z — OtterCopy
- **Summary:** Added Power Automate watch notifications for extended job terminal states.
- **Files/Areas:** `background.js`; `manifest.json`
- **User-visible impact:** Extended refinement and engineering handoff now send a best-effort JSON notification when they complete successfully or fail. The payload contains only `status` and `message`, with failure messages carrying the reason. Notification delivery failures are logged in the service worker console and do not alter the saved job outcome.
- **Tests run:** `node --check background.js` — syntax check passed; `node -e "JSON.parse(require('fs').readFileSync('manifest.json','utf8')); console.log('manifest ok')"` — manifest JSON parsed successfully; inline Node VM mocked `runExtendedRefinementJob(...)` — verified success payload `{ status: "success", message: "Extended refinement completed successfully." }`, failure payload `{ status: "fail", message: "Engineering handoff failed: Provider timed out." }`, and `application/json` content type.
- **Tests added/updated:** No persistent automated tests added; this repo still has no package/test harness. Residual risk: live Power Automate delivery should be validated from the loaded extension with the real endpoint.
- **Regression impact:** Isolated to extended refinement/handoff terminal status handling in `background.js` plus the required Power Platform host permission in `manifest.json`; transcript extraction, model orchestration, saved-result polling, cancellation, copy-only behavior, and provider adapters remain unchanged.
- **API docs:** Not relevant: browser extension only; no HTTP API contract or Swagger/OpenAPI surface exists in this repo.
- **Tooling gates:** No package-level lint/test/audit gates found because the repo has no `package.json`; direct syntax, manifest, and mocked status-notification checks were run.

### 2026-06-08T01:46:42Z — OtterCopy

Summary: Added first-pass transcript semantic block generation.

Files / areas:
- `background.js`
- `docs/ottercopy/ottercopy-changelog.md`

User-visible impact:
- AI refinement now generates a compact semantic block from the transcript before downstream model synthesis.
- The semantic block uses the configured final-pass model slot, then is appended to the downstream active-model prompt for single-pass refinement.
- Extended refinement and engineering handoff now start with a `semantic-block` call on the final-pass model, then append that generated block to persona, repair, final synthesis, and Objective insertion prompts.
- Extended debug logs now record the semantic-block model, generated block summary, and updated expected call plan.

Tests run:
- `node --check background.js` — syntax check passed.
- `node --check promptStore.js` — syntax check passed.
- `node --check popup.js` — syntax check passed.
- `node --check content.js` — syntax check passed.
- `node --check modelProviderClient.js` — syntax check passed.
- Inline Node VM mocked `runExtendedRefinement(...)` — verified 17 no-repair calls for extended refinement, first call type `semantic-block`, first call uses the final-pass model, downstream persona/final/objective prompts include the block, debug metadata records the semantic-block model and call plan, and single-pass prompt formatting appends the block.

Tests added/updated:
- No persistent automated tests added; this repo still has no package/test harness. Residual risk: live provider output quality for the semantic block should be checked with a real noisy Otter transcript.

Regression impact:
- Single-pass AI refinement intentionally gains one high-performance semantic-block call before the active-model call.
- Extended refinement intentionally changes the no-repair call plan from 16 calls to 17 calls by adding the first semantic-block call.
- Engineering handoff receives the same semantic-block preflight and downstream prompt injection.
- Copy-only behavior, transcript extraction, saved-result polling, cancellation, and provider adapters remain otherwise unchanged.

API docs:
- Not relevant: browser extension only; no HTTP API contract or Swagger/OpenAPI surface exists in this repo.

Tooling gates:
- No package-level lint/test/audit gates found because the repo has no `package.json`; direct syntax checks and a mocked orchestration check were run with Node.

### 2026-06-04T18:17:06Z — OtterCopy

Summary: Moved Objective generation to a separate post-final insertion pass.

Files / areas:
- `background.js`
- `prompts/extended/08-final-pass.md`
- `promptStore.js`
- `docs/ottercopy/ottercopy-changelog.md`

User-visible impact:
- Final synthesis is Objective-agnostic again and produces the normal refined artifact.
- A separate `objective-insertion` model call now runs after final synthesis using the base/active model, generates only the `### Objective` block, and code inserts that block between the H1 and the first section without letting the model rewrite the note.
- Debug logs now show the additional `objective-insertion` call and the expected call plan includes it.
- Built-in prompt storage self-heals if the browser cached the short-lived bad `### Objective` instruction in the main refinement prompt.

Tests run:
- `node --check background.js` — syntax check passed.
- `node --check promptStore.js` — syntax check passed.
- `node --check popup.js` — syntax check passed.
- `node --check content.js` — syntax check passed.
- `node --check modelProviderClient.js` — syntax check passed.
- `node -e "JSON.parse(require('fs').readFileSync('manifest.json','utf8')); console.log('manifest ok')"` — manifest JSON parsed successfully.
- Mocked `runExtendedRefinement(...)` — verified final synthesis prompt no longer includes Objective instructions, the separate objective-only call runs after final synthesis, and the generated block is inserted after the H1.
- Mocked `promptStore.getPrompts()` with a cached built-in prompt containing `### Objective` — verified the cached Objective instruction is removed by refreshing from the packaged prompt.

Tests added/updated:
- No persistent automated tests added; this repo still has no package/test harness. Residual risk: objective quality should be checked with a real transcript, especially that the objective-only model does not overreach.

Regression impact:
- Extended output shape intentionally changes via deterministic insertion after final synthesis.
- Final synthesis, saved-result behavior, cancellation, polling, and debug logging remain otherwise unchanged.

API docs:
- Not relevant: browser extension only; no HTTP API contract or Swagger/OpenAPI surface exists in this repo.

Tooling gates:
- No package-level lint/test/audit gates found because the repo has no `package.json`; direct syntax, manifest, mocked pipeline, and prompt-store checks were run.

### 2026-06-04T17:52:07Z — OtterCopy

Summary: Corrected Objective prompt scope to final-pass only.

Files / areas:
- `prompts/refinement.md`
- `docs/ottercopy/ottercopy-changelog.md`

User-visible impact:
- Removed the Objective instruction from the main governing refinement prompt because it changed the weighting and nature of intermediate/single-pass responses.
- Objective remains only in the extended final-pass instruction path through `prompts/extended/08-final-pass.md` and runtime final synthesis rules in `background.js`.
- This restores the main prompt to the original Problem → Requirement → Solution framing while preserving final reconciler-only Objective injection.

Tests run:
- `node --check background.js` — syntax check passed.
- `node --check popup.js` — syntax check passed.
- `node --check content.js` — syntax check passed.
- `node --check modelProviderClient.js` — syntax check passed.
- `Select-String -Path prompts\refinement.md -Pattern "Objective"` — verified no Objective instruction remains in the main prompt.
- `Select-String` checks verified Objective remains present in `prompts/extended/08-final-pass.md` and runtime final synthesis instructions in `background.js`.

Tests added/updated:
- No persistent automated tests added; this repo still has no package/test harness. Residual risk: output quality should be revalidated with a real extended run.

Regression impact:
- Isolated to prompt-scope correction; execution flow, saved-result behavior, cancellation, polling, and debug logging remain unchanged.

API docs:
- Not relevant: browser extension only; no HTTP API contract or Swagger/OpenAPI surface exists in this repo.

Tooling gates:
- No package-level lint/test/audit gates found because the repo has no `package.json`; direct syntax and prompt-presence checks were run.

### 2026-06-04T17:12:47Z — OtterCopy

Summary: Added final-pass Objective section requirement.

Files / areas:
- `prompts/refinement.md`
- `prompts/extended/08-final-pass.md`
- `background.js`
- `docs/ottercopy/ottercopy-changelog.md`

User-visible impact:
- Extended final synthesis now instructs the reconciler to place an `### Objective` section immediately after the top-level Markdown header.
- The Objective is derived from the complete reconciled context, including Problem, Requirement, Solution, risks, open questions, and action items.
- The Objective is constrained to a concise outcome statement rather than implementation steps.
- The packaged governing prompt now documents the same output shape for future prompt resets and single-pass prompt use.

Tests run:
- `node --check background.js` — syntax check passed.
- `node --check popup.js` — syntax check passed.
- `node --check content.js` — syntax check passed.
- `node --check modelProviderClient.js` — syntax check passed.
- Mocked `runExtendedRefinement(...)` final prompt capture — verified the runtime final request includes the Objective order, derivation, and concision rules.

Tests added/updated:
- No persistent automated tests added; this repo still has no package/test harness. Residual risk: final artifact quality should be validated with a real transcript output.

Regression impact:
- Isolated to prompt/output-shape instructions; model call sequencing, saved-result behavior, cancellation, and debug logging remain unchanged.

API docs:
- Not relevant: browser extension only; no HTTP API contract or Swagger/OpenAPI surface exists in this repo.

Tooling gates:
- No package-level lint/test/audit gates found because the repo has no `package.json`; direct syntax and mocked prompt-capture checks were run with Node.

### 2026-06-03T15:07:00Z — OtterCopy
- **Summary:** Initial commit and push of the OtterCopy project to the main branch.
- **Files/Areas:** All files in the OtterCopy directory.
- **User-visible impact:** N/A (initial commit)
- **Tests run:** N/A - no test harness configured.

### 2026-06-02T19:14:15Z — OtterCopy

Summary: Added popup polling for saved extended-refinement result status.

Files / areas:
- `popup.js`
- `docs/ottercopy/ottercopy-changelog.md`

User-visible impact:
- When the popup is open during an extended refinement, the latest-result summary now refreshes every 2.5 seconds while the saved result status is `running`.
- If the popup is reopened while a run is still active, the initial summary refresh detects `running` and starts polling automatically.
- Polling stops once the result is completed, failed, cancelled, unavailable, or missing.

Tests run:
- `node --check popup.js` — syntax check passed.
- `node --check background.js` — syntax check passed.
- Static lookup verified polling starts after extended start and when `renderLatestResultSummary(...)` sees `running`, and stops on non-running states.

Tests added/updated:
- No persistent automated tests added; this repo still has no package/test harness. Residual risk: live popup refresh cadence should be validated in Chrome during a real extended run.

Regression impact:
- Isolated to popup status refresh behavior; refinement execution and storage behavior remain unchanged.

API docs:
- Not relevant: browser extension only; no HTTP API contract or Swagger/OpenAPI surface exists in this repo.

Tooling gates:
- No package-level lint/test/audit gates found because the repo has no `package.json`; direct syntax checks were run with Node.

### 2026-06-02T19:10:09Z — OtterCopy

Summary: Fixed stop flow so cancellation cannot get stuck in a pending state.

Files / areas:
- `background.js`
- `popup.js`
- `popup.css`
- `docs/ottercopy/ottercopy-changelog.md`

User-visible impact:
- `Stop refinement` now marks the latest run `cancelled` immediately instead of leaving it in `cancel_requested`.
- A new extended refinement can be started right after stopping, even if an old provider call is still unwinding.
- Late completion/failure updates from the cancelled run cannot overwrite the terminal cancelled state or the next run.
- Popup now reports `Refinement stopped.`

Tests run:
- `node --check background.js` — syntax check passed.
- `node --check popup.js` — syntax check passed.
- `node --check content.js` — syntax check passed.
- `node --check modelProviderClient.js` — syntax check passed.
- `node -e "JSON.parse(require('fs').readFileSync('manifest.json','utf8')); console.log('manifest ok')"` — manifest JSON parsed successfully.
- Mocked stuck-state reproduction — verified stop immediately saved `cancelled`, a second run started successfully before the old provider call returned, and the old run did not overwrite the latest run.
- Mocked short transcript extraction returning `Transcript` — verified the minimum-character guard still failed before model calls.

Tests added/updated:
- No persistent automated tests added; this repo still has no package/test harness. Residual risk: live provider calls still cannot be forcibly aborted mid-request without adding abort-signal support to provider clients.

Regression impact:
- Isolated to extended refinement cancellation state handling.
- Copy-only and single-pass refinement paths remain unchanged.

API docs:
- Not relevant: browser extension only; no HTTP API contract or Swagger/OpenAPI surface exists in this repo.

Tooling gates:
- No package-level lint/test/audit gates found because the repo has no `package.json`; direct syntax, manifest, and mocked behavior checks were run with Node.

### 2026-06-02T19:06:35Z — OtterCopy

Summary: Added wrong-screen transcript preflight and stop support for extended refinement.

Files / areas:
- `background.js`
- `popup.html`
- `popup.js`
- `popup.css`
- `docs/ottercopy/ottercopy-changelog.md`

User-visible impact:
- Extended refinement now rejects extracted transcript text shorter than 100 characters before any model calls, preventing accidental runs on pages that only expose labels such as `Transcript`.
- Popup now includes `Stop refinement`.
- Stop requests mark the latest run as `cancel_requested`, then the pipeline stops before the next model call or after the current in-flight provider call returns.
- Cancelled runs save as `cancelled` instead of `failed`.
- Starting a second extended refinement is blocked while a run is `running` or `cancel_requested`.

Tests run:
- `node --check background.js` — syntax check passed.
- `node --check popup.js` — syntax check passed.
- `node --check content.js` — syntax check passed.
- `node --check modelProviderClient.js` — syntax check passed.
- `node -e "JSON.parse(require('fs').readFileSync('manifest.json','utf8')); console.log('manifest ok')"` — manifest JSON parsed successfully.
- Mocked short transcript extraction returning `Transcript` — verified run failed with the minimum-character message and made zero model calls.
- Mocked stop request after the first model response — verified latest result saved as `cancelled` and only one model call was made.
- Mocked normal extended run — verified latest result saved as `completed` with 15 model calls in the no-repair path.

Tests added/updated:
- No persistent automated tests added; this repo still has no package/test harness. Residual risk: live cancellation cannot abort a provider request already in flight unless provider/client abort support is added later.

Regression impact:
- Copy-only and single-pass refinement paths remain unchanged.
- Extended refinement gains preflight validation and cooperative cancellation.

API docs:
- Not relevant: browser extension only; no HTTP API contract or Swagger/OpenAPI surface exists in this repo.

Tooling gates:
- No package-level lint/test/audit gates found because the repo has no `package.json`; direct syntax, manifest, and mocked behavior checks were run with Node.

### 2026-06-02T18:56:45Z — OtterCopy

Summary: Added saved latest-result retrieval for extended refinement.

Files / areas:
- `background.js`
- `popup.html`
- `popup.js`
- `popup.css`
- `docs/ottercopy/ottercopy-changelog.md`

User-visible impact:
- Extended refinement now starts as a background-style job and no longer immediately copies the final output or closes the popup.
- The latest extended run is saved in `chrome.storage.local` with `running`, `completed`, or `failed` status.
- Popup now includes `Copy latest result`, allowing the user to reopen the extension later and copy the saved final artifact.
- The saved result includes run metadata, model summaries, prompt summary, transcript character count, completion/error state, final text, and linked debug run id.
- Existing single-pass refinement still copies immediately.
- Existing debug-log copying remains available.

Tests run:
- `node --check background.js` — syntax check passed.
- `node --check popup.js` — syntax check passed.
- `node --check content.js` — syntax check passed.
- `node --check modelProviderClient.js` — syntax check passed.
- `node -e "JSON.parse(require('fs').readFileSync('manifest.json','utf8')); console.log('manifest ok')"` — manifest JSON parsed successfully.
- Mocked `startExtendedRefinementJob(...)` — verified start returns while latest result is `running`, completion updates latest result to `completed`, final text is saved, debug run id is linked, and 15 model calls were made in the no-repair path.

Tests added/updated:
- No persistent automated tests added; this repo still has no package/test harness. Residual risk: Chrome MV3 service-worker lifetime should be validated in a live browser run while the popup is closed or focus is elsewhere.

Regression impact:
- Copy-only and single-pass refinement paths remain unchanged.
- Extended refinement behavior intentionally changed from immediate clipboard copy to saved-result retrieval.

API docs:
- Not relevant: browser extension only; no HTTP API contract or Swagger/OpenAPI surface exists in this repo.

Tooling gates:
- No package-level lint/test/audit gates found because the repo has no `package.json`; direct syntax, manifest, and mocked saved-result checks were run with Node.

### 2026-06-02T18:33:18Z — OtterCopy

Summary: Compacted extended debug logs to remove repeated prompt context.

Files / areas:
- `background.js`
- `docs/ottercopy/ottercopy-changelog.md`

User-visible impact:
- `Copy latest debug log` now produces a less repetitive log.
- Full per-call request prompt bodies are omitted by default.
- Each call keeps request hash, character count, preview, unique call parts, and references into a shared `promptLibrary`.
- Repeated context such as the governing prompt, persona matrix, transcript, and directives is stored or referenced once by hash instead of repeated in every call.
- Responses, normalized responses, repair metadata, timings, call counts, and errors remain inspectable.

Tests run:
- `node --check background.js` — syntax check passed.
- `node --check popup.js` — syntax check passed.
- `node -e "JSON.parse(require('fs').readFileSync('manifest.json','utf8')); console.log('manifest ok')"` — manifest JSON parsed successfully.
- Mocked `runExtendedRefinement(...)` — verified per-call request bodies are empty by default, calls include refs/previews/hashes, the persona matrix is stored once in `promptLibrary`, and responses remain visible.

Tests added/updated:
- No persistent automated tests added; this repo still has no package/test harness. Residual risk: log size can still be large on long transcripts because responses and normalized outputs remain intentionally visible.

Regression impact:
- Isolated to debug-log serialization; model call contents and refinement behavior remain unchanged.

API docs:
- Not relevant: browser extension only; no HTTP API contract or Swagger/OpenAPI surface exists in this repo.

Tooling gates:
- No package-level lint/test/audit gates found because the repo has no `package.json`; direct syntax, manifest, and mocked debug-log checks were run with Node.

### 2026-06-02T18:20:12Z — OtterCopy

Summary: Added a copyable debug log for extended refinement model calls.

Files / areas:
- `background.js`
- `popup.html`
- `popup.js`
- `popup.css`
- `manifest.json`
- `docs/ottercopy/ottercopy-changelog.md`

User-visible impact:
- Popup now includes `Copy latest debug log`.
- After an extended refinement run, the latest debug log can be copied as formatted JSON for inspection.
- The log records each extended model call, including persona calls, format-repair calls, final synthesis, model metadata, timestamps, durations, request prompt contents, raw response text, normalized response text, errors, total call count, and rate-limit settings.
- API keys are not logged, and secret-like fields in raw provider payloads are redacted.
- Added `unlimitedStorage` permission so large transcript/prompt debug logs can be retained in `chrome.storage.local`.

Tests run:
- `node --check background.js` — syntax check passed.
- `node --check popup.js` — syntax check passed.
- `node --check content.js` — syntax check passed.
- `node --check modelProviderClient.js` — syntax check passed.
- `node -e "JSON.parse(require('fs').readFileSync('manifest.json','utf8')); console.log('manifest ok')"` — manifest JSON parsed successfully.
- Mocked `runExtendedRefinement(...)` with one unstructured persona response — verified the stored debug log recorded 16 calls, request/response text, repair-call metadata, final synthesis metadata, and redacted secret-like raw response fields.

Tests added/updated:
- No persistent automated tests added; this repo still has no package/test harness. Residual risk: live provider raw payload shapes may contain additional fields that should be redacted if discovered.

Regression impact:
- Copy-only and single-pass refinement behavior remain unchanged.
- Extended refinement now performs the same work while additionally storing the latest run log locally.

API docs:
- Not relevant: browser extension only; no HTTP API contract or Swagger/OpenAPI surface exists in this repo.

Tooling gates:
- No package-level lint/test/audit gates found because the repo has no `package.json`; direct syntax, manifest, and mocked debug-log checks were run with Node.

### 2026-06-02T16:55:13Z — OtterCopy

Summary: Added recovery for unstructured persona responses that omit the required top-level labels.

Files / areas:
- `background.js`
- `docs/ottercopy/ottercopy-changelog.md`

User-visible impact:
- Extended refinement no longer fails immediately when a persona pass returns useful content without `SECTION_OUTPUT` and `CLAIM_LEDGER`.
- The pipeline now attempts a strict format-repair call for that persona response; if repair also fails, it wraps the original content in a conservative structured result and flags that final synthesis must verify claims against the transcript.
- Persona prompts now explicitly require `SECTION_OUTPUT:` as the first non-whitespace response text.

Tests run:
- `node --check background.js` — syntax check passed.
- Mocked `runExtendedRefinement(...)` with the first persona returning plain Markdown — verified a repair call ran and the pipeline reached final synthesis.
- Mocked `runExtendedRefinement(...)` with both original and repair responses unstructured — verified the conservative wrapper fallback completed the pipeline.

Tests added/updated:
- No persistent automated tests added; this repo still has no package/test harness. Residual risk: provider-specific formatting behavior remains model-dependent in live runs.

Regression impact:
- Isolated to extended persona result normalization/repair in `background.js`; copy-only and single-pass refinement paths remain unchanged.

API docs:
- Not relevant: browser extension only; no HTTP API contract or Swagger/OpenAPI surface exists in this repo.

Tooling gates:
- No package-level lint/test/audit gates found because the repo has no `package.json`; syntax and mocked pipeline checks were run directly with Node.

### 2026-06-02T16:50:03Z — OtterCopy

Summary: Tuned final synthesis discipline after reviewing a real extended-refine output and critique.

Files / areas:
- `background.js`
- `prompts/extended/08-final-pass.md`
- `docs/ottercopy/ottercopy-changelog.md`

User-visible impact:
- Extended refinement should keep the implementation-ticket usefulness of the paired pipeline while reducing over-certainty in the final artifact.
- The final pass now explicitly downgrades inferred implementation choices, avoids turning unconfirmed details into hard requirements or action items, preserves material downstream-effect questions, and treats request flags such as `isDeliverable` as routing/intent signals unless the transcript proves they are authorization boundaries.

Tests run:
- `node --check background.js` — syntax check passed.
- Mocked `runExtendedRefinement(...)` with final prompt capture — verified the final synthesis prompt includes the new over-certainty, open-question preservation, and `isDeliverable` boundary rules.

Tests added/updated:
- No persistent automated tests added; this repo still has no package/test harness. Residual risk: final artifact quality remains model-dependent and needs another real Otter transcript run.

Regression impact:
- Isolated to final synthesis prompting; persona pass order, copy-only mode, and single-pass refinement behavior remain unchanged.

API docs:
- Not relevant: browser extension only; no HTTP API contract or Swagger/OpenAPI surface exists in this repo.

Tooling gates:
- No package-level lint/test/audit gates found because the repo has no `package.json`; syntax and mocked prompt-capture checks were run directly with Node.

### 2026-06-02T16:34:42Z — OtterCopy

Summary: Made extended persona claim-ledger handling resilient to omitted empty buckets.

Files / areas:
- `background.js`
- `docs/ottercopy/ottercopy-changelog.md`

User-visible impact:
- Extended refinement no longer fails when a persona response includes `SECTION_OUTPUT` and `CLAIM_LEDGER` but omits otherwise empty claim labels such as `Weak Inference` or `Speculative`; missing buckets are normalized to `None identified.`

Tests run:
- `node --check background.js` — syntax check passed.
- Mocked `runExtendedRefinement(...)` with the Requirement secondary persona omitting `Weak Inference` and `Speculative` — verified the pipeline completed all 15 calls.

Tests added/updated:
- No persistent automated tests added; this repo still has no package/test harness. Residual risk: real provider responses may vary in other ways. Smallest follow-up: add a reusable mocked-provider harness if this repo gets a test setup.

Regression impact:
- Isolated to persona response normalization in `background.js`; missing required top-level response sections still fail clearly.

API docs:
- Not relevant: browser extension only; no HTTP API contract or Swagger/OpenAPI surface exists in this repo.

Tooling gates:
- No package-level lint/test/audit gates found because the repo has no `package.json`; syntax and mocked pipeline checks were run directly with Node.

### 2026-06-02T16:26:28Z — OtterCopy

Summary: Tuned the extended refinement call pacing and verified malformed persona responses fail clearly.

Files / areas:
- `background.js`
- `docs/ottercopy/ottercopy-changelog.md`

User-visible impact:
- Extended refinement now spaces lightweight persona calls by default to respect the approximate 15-calls-per-minute budget.
- If a lightweight persona returns an incomplete claim ledger, the popup receives a clear section/persona failure message.

Tests run:
- `node --check background.js` — syntax check passed.
- Mocked `runExtendedRefinement(...)` with fake timers — verified 15 calls total: 14 persona passes in expected order plus 1 final synthesis call.
- Mocked malformed persona response — verified failure message names `Header and Problem`, `User Impact Analyst`, and the missing claim labels.

Tests added/updated:
- No persistent automated tests added; this repo still has no package/test harness. Residual risk: real Chrome extension behavior and provider timing are not covered by automated tests. Smallest follow-up: add a reusable mocked-provider harness if this repo gets a test setup.

Regression impact:
- Isolated to extended refinement pacing and persona response validation in `background.js`; copy-only and single-pass refinement paths remain untouched.

API docs:
- Not relevant: browser extension only; no HTTP API contract or Swagger/OpenAPI surface exists in this repo.

Tooling gates:
- No package-level lint/test/audit gates found because the repo has no `package.json`; syntax and mocked pipeline checks were run directly with Node.

### 2026-06-02T16:24:37Z — OtterCopy

Summary: Validated and hardened the paired extended refinement pipeline.

Files / areas:
- `background.js`
- `docs/ottercopy/ottercopy-changelog.md`

User-visible impact:
- Extended refinement now fails with a clear section/persona error if a lightweight persona response omits `SECTION_OUTPUT`, `CLAIM_LEDGER`, or any required claim label.

Tests run:
- `node --check background.js` — syntax check passed.
- Mocked `runExtendedRefinement(...)` in a Node VM with fake Chrome/fetch/model clients — verified 15 calls total: 14 persona passes in expected order plus 1 final synthesis call.

Tests added/updated:
- No persistent automated tests added; this repo still has no package/test harness. Residual risk: browser-extension runtime behavior with real Chrome APIs and provider responses remains manually verified only. Smallest follow-up: add a reusable mocked-provider harness if this repo gets a test setup.

Regression impact:
- Isolated to extended refinement validation in `background.js`; copy-only mode and single-pass refinement control flow remain untouched.

API docs:
- Not relevant: browser extension only; no HTTP API contract or Swagger/OpenAPI surface exists in this repo.

Tooling gates:
- No package-level lint/test/audit gates found because the repo has no `package.json`; syntax and mocked pipeline checks were run directly with Node.

### 2026-06-02T16:22:13Z — OtterCopy

Summary: Reworked extended transcript refinement into a deterministic paired-perspective pipeline.

Files / areas:
- `background.js`

User-visible impact:
- Copy-only mode remains unchanged.
- Single-pass refinement remains unchanged.
- Extended refinement now runs each section through a primary and secondary persona pass, requires `SECTION_OUTPUT` plus `CLAIM_LEDGER`, and sends the collected persona outputs and claim ledgers to the final synthesis model.

Tests run:
- `node --check background.js` — syntax check passed.

Tests added/updated:
- No automated tests added; this repo currently has no package/test harness. Residual risk: full browser-extension runtime behavior and provider call sequencing are not covered by automated tests. Smallest follow-up: add a lightweight mocked-provider harness for `background.js` extended refinement helpers.

Regression impact:
- Isolated to extended refinement in `background.js`; popup actions, transcript extraction, model storage, prompt storage, and single-pass formatting surfaces were checked and left unchanged.

API docs:
- Not relevant: browser extension only; no HTTP API contract or Swagger/OpenAPI surface exists in this repo.

Tooling gates:
- No package-level lint/test/audit gates found because the repo has no `package.json`; syntax check was run for the touched JavaScript file.

## Current state
Standard-refine prompts are a code-versioned library. `prompts/custom/index.json` enumerates four packaged built-ins (Refinement, Summary, Variables, Handoff); `promptStore.js` seeds their content from the packaged `.md` files on load and stores only user state in `chrome.storage.sync` — active selection (`ottercopy:activePromptId`), edited-built-in overrides (`ottercopy:override:<id>`), and user-created prompts (`ottercopy:custom:<id>`), one sync item each. Reset deletes an override to restore packaged content; built-ins cannot be deleted; oversized prompts are rejected against the per-item sync quota. A one-shot `ottercopy:migratedV2` migration imports the legacy `chrome.storage.local` `ottercopyPrompts` array. The handoff prompt lives at `prompts/custom/handoff.md` and serves both the selectable Handoff prompt and the extended-handoff pipeline's file-sourced governing prompt. The retired top-level `prompts/refinement.md` `# Objective:` preamble is parked, unused, in `prompts/_archive/`.

Extended refinement uses a final-pass-model semantic-block preflight, then a seven-section paired persona pipeline with claim-ledger discipline before the final synthesis and Objective insertion passes. The same semantic block is appended to downstream prompts for single-pass refinement, extended refinement, and engineering handoff.

An optional user "Direction" textarea in the popup lets the user steer a run. When provided, the direction is injected as a labeled, guard-railed steering block into every model call (semantic block, each persona pass, final synthesis, objective insertion, and the single-pass refine prompt) so the agents can be nudged toward the intended topic when a transcript spans multiple subjects, without treating the direction as new transcript facts. Empty direction preserves prior behavior; the direction is captured per run and not persisted across popup sessions.

The Direction input also supports a session-only override toggle: when enabled with text present, that text replaces the active/file governing prompt for single-pass refinement, extended refinement, and engineering handoff. Single-pass AI refinement now starts as a background job, saves its output as the latest result, and sends a best-effort Power Automate notification on terminal success/failure without attempting automatic clipboard writes; `Copy latest result` remains the manual copy path.

Extended refinement and engineering handoff run as background jobs, save their latest result/debug state, and send best-effort Power Automate notifications on success or failure using a `{ status, message }` payload.

Legacy in-repo changelog content from C:\Users\dustin.thomason\OneDrive\PDProjects\Browser Extensions\OtterCopy\docs\ottercopy\ottercopy-changelog.md was migrated into this canonical file on 2026-06-08T03:00:52Z without removing historical session text.

## Plans
- [2026-06-30] Migrate autocopy prompts to a code-versioned, sync-backed library (index.json seed + per-key sync overrides; promote handoff; archive Objective preamble). Plan: `C:\Users\dktho\.claude\plans\dustin-thomason-agents-md-do-not-pull-refactored-snowglobe.md`. Status: implemented.
- [2026-06-15] Optional Direction steering input injected into all pipeline agents. Status: implemented.
- [2026-06-08] Migrate legacy in-repo changelog into canonical dustin-thomason OtterCopy changelog. Status: implemented.
- [2026-06-08] Power Automate success/failure notifications for extended jobs. Status: implemented.
- [2026-06-03] initial commit and push to main. Status: implemented.











