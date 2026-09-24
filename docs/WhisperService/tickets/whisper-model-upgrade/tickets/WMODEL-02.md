# WMODEL-02 — Setup installs the chosen model

**Handoff:** [whisper-model-upgrade-handoff.md](../whisper-model-upgrade-handoff.md)
**Serves:** REQ-001, REQ-002
**Depends on:** WMODEL-01
**May run in parallel with:** Nothing
**Branch slug:** `wmodel-02-setup-model-choice`
**Exclusive production ownership:** `scripts/setup.mjs`, `src/constants.mjs` (removing the `MODEL_FILE` and `MODEL_SHA256` exports only), `tests/setup.test.mjs` (new), `README.md`, `THIRD_PARTY_NOTICES.md`
**Must not change:** `src/config.mjs`, `src/cli.mjs`, `src/service.mjs`, `src/worker-client.mjs`, `scripts/smoke.mjs`, `native/`, `clients/`, `contracts/`, `package.json`, `package-lock.json`, `.github/`, setup's source-checkout and build steps, and `%LOCALAPPDATA%\WhisperService\`

## Goal

`npm run setup -- --model <id>` downloads and verifies the named catalog model. Without `--model`, setup provisions whichever model the configuration selects, and it never changes the selection (LD-006). `small.en` can therefore be installed alone and kept alone. The README and third-party notices describe both models and how to switch between them (LD-009). This ticket must not change how a model is selected (WMODEL-01), add a remove command, or change the source or build steps.

## Build checklist

- [x] In `scripts/setup.mjs`, parse `--model <id>`. An unknown id or a missing value exits non-zero, listing the `MODELS` ids (LD-006). — `parseModelArg` (`scripts/setup.mjs:85-93`), guard uses it and sets `process.exitCode = 1` on rejection (`scripts/setup.mjs:136-148`)
- [x] Resolve the model to provision: the `--model` id if given, otherwise `modelIdForConfig` of the configuration that `initializeUserFiles` leaves in place. A new installation's configuration selects `base.en`. An invalid configuration is an error, never a silent default (LD-004, LD-006). — `resolveModelId` (`scripts/setup.mjs:95-99`)
- [x] Change `provisionModel` to take the model id and use that entry's file (inside `paths.models`), hash, and URL. Change the success message to `<file> identity verified.` (LD-006). — `provisionModel(paths, modelId)` (`scripts/setup.mjs:62-83`); message at `scripts/setup.mjs:127`
- [x] Guard the module-level `setup(…)` call the way `src/cli.mjs` guards `main`, and export the argument-parsing and model-resolving functions so they can be tested (LD-006). — `scripts/setup.mjs:136-148`; `parseModelArg`/`resolveModelId` exported at `scripts/setup.mjs:85`/`:95`
- [x] Remove `MODEL_FILE` and `MODEL_SHA256` from `src/constants.mjs`, since nothing imports them any longer (LD-003). — `src/constants.mjs:1-23` (no legacy exports); `git grep -n -E "MODEL_SHA256|MODEL_FILE"` returns no matches
- [x] Add `tests/setup.test.mjs`:
  - [x] `--model small.en` resolves to `small.en`. — `tests/setup.test.mjs:9-16` ("parseModelArg resolves a known id…"), `:18-26` ("resolveModelId prefers an explicit id…")
  - [x] An unknown id and a missing value are rejected. — `tests/setup.test.mjs:14-15`
  - [x] With no flag, a configuration selecting `small.en` resolves to `small.en`, and a new temporary home resolves to `base.en`. — `tests/setup.test.mjs:28-36` (new home → `base.en`), `:38-49` (selected → `small.en`)
  - [x] Resolving leaves `config.json` byte-identical. — `tests/setup.test.mjs:23-24`, `:46-48` (`assert.deepEqual` on raw file bytes)
- [x] Update `README.md` (LD-009):
  - [x] Rewrite `:3`, `:26`, `:28`, and `:107` for two models. — `README.md:3`, `:19-32`, `:124` (post-edit line numbers; original targets rewritten)
  - [x] Add a "Change the model" subsection: `npm run setup -- --model small.en --skip-build`, `npm run configure -- model small.en`, and a restart. Going back is `npm run configure -- model base.en` and a restart. To keep only one model, delete the other file from `%LOCALAPPDATA%\WhisperService\models`. — `README.md:30-46`
- [x] Add a `small.en` section to `THIRD_PARTY_NOTICES.md` matching the `base.en` section at `:18-24`, with EV-010's file, URL, and hash (LD-009). — `THIRD_PARTY_NOTICES.md:26-32`

## Exit gate

- [x] `npm ci`, then `npm audit --audit-level=high`, reports no high or critical vulnerability. — `npm ci` (3 packages), `npm audit --audit-level=high` → "found 0 vulnerabilities"
- [x] `npm test` passes every test with `127.0.0.1:8178` free (handoff dispatch rule 5). — `Get-NetTCPConnection -LocalPort 8178 -State Listen` returned nothing (free); `npm test` → 30 pass, 0 fail
- [x] `node --check` passes for every changed `.mjs` file. — `node --check` on `scripts/setup.mjs`, `src/constants.mjs`, `tests/setup.test.mjs`, all OK
- [x] `git diff --check` reports nothing. — exit 0, no output
- [x] `git grep -n -E "MODEL_SHA256|MODEL_FILE"` returns no matches. — no output
- [x] Real run in a fresh scratch home (handoff dispatch rule 6):
  - [x] `node scripts/setup.mjs --model small.en --skip-build` prints `ggml-small.en.bin identity verified.`, and the downloaded file hashes to EV-010's value. — printed exactly; `Get-FileHash` → `C6138D6D58ECC8322097E0F987C32F1BE8BB0A18532A3F88F734D1BBF9C41E5D`
  - [x] `configure show` still selects `base.en`. — `runtime.modelPath` ends `ggml-base.en.bin`, `modelSha256` = the `base.en` hash
  - [x] Running the same command again downloads nothing: the file's modification time is unchanged. — `LastWriteTimeUtc` `09/24/2026 21:27:29` before and after rerun
  - [x] After the live `whisper-worker.exe` is copied in, `node src/cli.mjs configure model small.en` succeeds. — printed "Model set to small.en. Restart WhisperService to load it."
  - [x] `node scripts/setup.mjs --skip-build`, with no flag, downloads nothing and does not create `ggml-base.en.bin`. — models folder listing after the run holds only `ggml-small.en.bin`; `Test-Path …ggml-base.en.bin` → `False`
  - [x] `npm run smoke` prints `"ok":true` with `"modelInitializations":1`. — `{"ok":true,"sessions":2,"modelInitializations":1,"firstCharacters":44,"secondCharacters":44}`; worker.ready logged `"model":"ggml-small.en.bin"`
- [x] `%LOCALAPPDATA%\WhisperService\config.json` has the same SHA-256 before and after the run. — `65DF91E95DBBA1E0C4273830B20ED56C1130857D0406E0DDB3FCA7729AFEE392`, matching the value already on record in the WMODEL-01 audit; this ticket only ever reads from `%LOCALAPPDATA%\WhisperService` (one `Copy-Item` of `runtime\whisper-worker.exe` as source)
- [x] `git diff --stat <starting commit>..HEAD` lists only the owned files. — `git diff --stat bcc5049e..2a763b80` lists exactly `README.md`, `THIRD_PARTY_NOTICES.md`, `scripts/setup.mjs`, `src/constants.mjs`, `tests/setup.test.mjs`

## Out of scope

- Model selection, configuration validation, and health: WMODEL-01.
- Switching the live installation to `small.en`: the user's post-merge step (handoff dispatch rule 6).

## Objectives

Complete every objective below in place, using the handoff's Compact Audit Trail Output Rule. Resolved requires implemented code, direct evidence, and focused verification; intent or partial implementation is Unresolved.

### Setup provisions the named or selected model
**State:** Resolved
**Value:** `npm run setup -- --model <id>` downloads and verifies that catalog model; with no `--model`, setup provisions the model the current configuration selects.
**Evidence:** `scripts/setup.mjs:62-99` (`provisionModel`, `parseModelArg`, `resolveModelId`), `scripts/setup.mjs:118-134` (`setup`); `tests/setup.test.mjs`; scratch-home run — `ggml-small.en.bin identity verified.` printed, file hashes to `c6138d6d…9c41e5d` (EV-010); real worker's `worker.ready` reported `"model":"ggml-small.en.bin"` and smoke printed `"modelInitializations":1`

### Setup never changes the selection
**State:** Resolved
**Value:** Setup only reads the configuration through `resolveModelId`/`modelIdForConfig`; it never calls `selectModel` or `saveConfig`.
**Evidence:** `scripts/setup.mjs:95-99` (no config write); scratch-home run — `configure show` still selected `base.en` after `setup --model small.en --skip-build`; `resolveModelId` tests assert `config.json` byte-identical before/after (`tests/setup.test.mjs:23-24`, `:46-48`)

### Legacy single-model constants removed
**State:** Resolved
**Value:** `MODEL_FILE` and `MODEL_SHA256` no longer exist; nothing imports them.
**Evidence:** `src/constants.mjs:1-23`; `git grep -n -E "MODEL_SHA256|MODEL_FILE"` → no matches

### Documentation describes both models
**State:** Resolved
**Value:** README describes the model as `base.en` or `small.en` with a "Change the model" subsection, and third-party notices carry a matching `small.en` section.
**Evidence:** `README.md:3`, `:19-32` (Setup + Change the model), `:124` (exclusions); `THIRD_PARTY_NOTICES.md:26-32`

### Scope and architecture compliance
**State:** Resolved
**Value:** Only the ticket's exclusive files changed; `config.mjs`, `cli.mjs`, `service.mjs`, `worker-client.mjs`, the source-checkout/build steps, and `%LOCALAPPDATA%\WhisperService` were not written to.
**Evidence:** `git diff --stat bcc5049e..2a763b80` lists exactly `README.md`, `THIRD_PARTY_NOTICES.md`, `scripts/setup.mjs`, `src/constants.mjs`, `tests/setup.test.mjs`; `%LOCALAPPDATA%\WhisperService\config.json` SHA-256 `65DF91E9…AFEE392` unchanged from the WMODEL-01 audit record

### Implementation completeness
**State:** Resolved
**Value:** Every build-checklist and exit-gate item is checked with direct evidence; no departures from the requirements' evidence were needed.
**Evidence:** Build checklist and exit gate above; final commit `2a763b80db9239b77d3e41e56794c0e85c1c037f` on `agent/wmodel-02-setup-model-choice`, pushed to `origin/agent/wmodel-02-setup-model-choice`

### F1 — "Change the model" subsection absorbs the origin and token setup
**State:**
**Value:**
**Evidence:**
**Depends on:**
