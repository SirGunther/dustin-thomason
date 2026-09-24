# WMODEL-01 — Model catalog and `configure model`

**Handoff:** [whisper-model-upgrade-handoff.md](../whisper-model-upgrade-handoff.md)
**Serves:** REQ-001, REQ-002, REQ-003
**Depends on:** Nothing
**May run in parallel with:** Nothing
**Branch slug:** `wmodel-01-model-catalog`
**Exclusive production ownership:** `src/constants.mjs`, `src/config.mjs`, `src/cli.mjs`, `src/service.mjs`, `src/worker-client.mjs` (adding `export` to the existing `sha256` function only), `tests/config.test.mjs`, `tests/service.test.mjs`, `tests/cli.test.mjs` (new)
**Must not change:** `scripts/` (including `setup.mjs` and `smoke.mjs`), `native/`, `clients/`, `contracts/`, every other `src/` file, `package.json`, `package-lock.json`, `.github/`, `README.md`, `THIRD_PARTY_NOTICES.md`, the configuration file's shape, the health and session protocol, the default model, and `%LOCALAPPDATA%\WhisperService\`

## Goal

WhisperService knows two pinned models, `base.en` and `small.en` (LD-003). A configuration that selects either one is valid (LD-004). `node src/cli.mjs configure model <id>` switches to a model only when its file is installed and verified (LD-005). Health reports the file name of the selected model (LD-008). An existing `base.en` configuration keeps working unchanged (LD-007). This ticket must not download models, change setup, change SaySlate, or add per-session model choice (LD-002).

## Build checklist

- [x] In `src/constants.mjs`, add `DEFAULT_MODEL_ID` and the frozen `MODELS` map with EV-010's file names, hashes, and URLs. Redefine `MODEL_FILE` and `MODEL_SHA256` from `MODELS[DEFAULT_MODEL_ID]` so `scripts/setup.mjs` keeps working (LD-003).
- [x] In `src/worker-client.mjs`, add `export` to the existing `sha256` function and change nothing else (LD-005).
- [x] In `src/config.mjs` (LD-004, LD-005):
  - [x] Add `models` to `servicePaths()`, and build `model` from the default entry.
  - [x] Build `defaultConfig`'s `runtime.modelPath` and `runtime.modelSha256` from the default entry.
  - [x] Add `modelIdForConfig`, and use it in `validateConfig` in place of the single-hash comparison at `config.mjs:109`.
  - [x] Add `selectModel`.
- [x] In `src/cli.mjs`, add the `configure model <id>` branch (`selectModel`, then `saveConfig`, then LD-005's message), and add the line to `usage` (LD-005).
- [x] In `src/service.mjs`, change health's fallback at `service.mjs:73` to the file name of `this.config.runtime.modelPath` (LD-008).
- [x] Extend `tests/config.test.mjs`:
  - [x] `validateConfig` accepts the default configuration and a configuration selecting `small.en`.
  - [x] It rejects the `small.en` hash with the `base.en` file name, and it rejects an unknown hash.
  - [x] `modelIdForConfig` returns `base.en` and `small.en` for their configurations.
  - [x] `selectModel`, given a test catalog and a temporary file whose hash it lists, returns the updated configuration and leaves the input unchanged.
  - [x] It rejects a missing file with a message naming `npm run setup -- --model`, a hash mismatch, and an unknown id with a message listing the valid ids.
- [x] Add `tests/cli.test.mjs`, calling `main` with `WHISPER_SERVICE_HOME` set to a temporary home created by `initializeUserFiles(…, { secureCredentials: false })`:
  - [x] `configure model small.en` with no model file rejects, and `config.json` is byte-identical afterwards.
  - [x] `configure model tiny.en` rejects and lists the valid ids.
  - [x] `configure model` with no id prints usage, including the new line, and sets exit code 2.
- [x] Extend `tests/service.test.mjs`: with worker metadata lacking `model` and a configuration selecting `small.en`, `/v1/health` reports `ggml-small.en.bin`.

## Exit gate

- [x] `npm ci`, then `npm audit --audit-level=high`, reports no high or critical vulnerability.
- [x] `npm test` passes every test with `127.0.0.1:8178` free (handoff dispatch rule 5).
- [x] `node --check` passes for every changed `.mjs` file.
- [x] `git diff --check` reports nothing.
- [x] Real run in a scratch home (handoff dispatch rule 6):
  - [x] `ggml-small.en.bin`, downloaded from its EV-010 URL, hashes to EV-010's value.
  - [x] `node src/cli.mjs configure model small.en` succeeds, and `configure show` then lists the `small.en` path and hash.
  - [x] `npm run smoke` prints `"ok":true` with `"modelInitializations":1`.
  - [x] `configure model base.en` refuses while no base file is present, and `small.en` stays selected.
  - [x] After the live `ggml-base.en.bin` is copied in, `configure model base.en` succeeds and `npm run smoke` again prints `"ok":true`.
  - [x] The wall-clock time of each smoke run is reported.
- [x] `%LOCALAPPDATA%\WhisperService\config.json` has the same SHA-256 before and after the run.
- [x] `git diff --stat <starting commit>..HEAD` lists only the owned files.

## Out of scope

- Setup downloading a chosen model, removing the legacy constants, and the README and notices: WMODEL-02.
- Switching the live installation to `small.en`: the user's post-merge step (handoff dispatch rule 6).

## Objectives

Complete every objective below in place, using the handoff's Compact Audit Trail Output Rule. Resolved requires implemented code, direct evidence, and focused verification; intent or partial implementation is Unresolved.

### Two pinned models in the catalog
**State:** Resolved
**Value:** `constants.mjs` exports a frozen `DEFAULT_MODEL_ID` and `MODELS` map holding `base.en` and `small.en`, each with EV-010's file, sha256, and `resolve/main/` URL; `MODEL_FILE`/`MODEL_SHA256` are redefined from `MODELS[DEFAULT_MODEL_ID]` so `scripts/setup.mjs` keeps importing them unchanged.
**Evidence:** `src/constants.mjs:8-23`; small.en's downloaded file hashed to `c6138d6d58ecc8322097e0f987c32f1be8bb0a18532a3f88f734d1bbf9c41e5d` (487,614,201 bytes) via `sha256sum`, matching EV-010.

### Configuration accepts either model
**State:** Resolved
**Value:** `servicePaths()` adds `models`; `defaultConfig` builds `runtime.modelPath`/`modelSha256` from the default entry; `modelIdForConfig` resolves a config to its catalog id by matching both file name and hash, and `validateConfig` calls it in place of the old single-hash comparison.
**Evidence:** `src/config.mjs:10-27` (`servicePaths`), `:29-55` (`defaultConfig`), `:114` (`validateConfig` call), `:118-128` (`modelIdForConfig`); `tests/config.test.mjs` — "validateConfig accepts the default model and small.en, and modelIdForConfig resolves both", "validateConfig rejects a mismatched file/hash pair and an unknown hash".

### `configure model` switches only to a verified file
**State:** Resolved
**Value:** `selectModel(config, modelId, paths, catalog)` rejects an unknown id (listing valid ids), rejects a missing or hash-mismatched file (naming `npm run setup -- --model <id>`), and otherwise returns a copy of the config with the new `runtime.modelPath`/`modelSha256`; `cli.mjs`'s `configure model <id>` calls it, then `saveConfig`, then prints "Model set to `<id>`. Restart WhisperService to load it."; `usage` lists the command.
**Evidence:** `src/config.mjs:130-143` (`selectModel`), `src/cli.mjs:52-57` (branch), `:19` (usage line); `tests/config.test.mjs` — "selectModel returns an updated configuration…", "selectModel rejects a missing file, a hash mismatch, and an unknown id"; `tests/cli.test.mjs` — all three tests; real scratch-home run: `configure model small.en` succeeded only after the verified file existed, `configure model base.en` refused while no base file was present and left `small.en` selected, then succeeded once the live `ggml-base.en.bin` was copied in.

### Health names the running model
**State:** Resolved
**Value:** `/v1/health`'s `model` fallback is now the file name of `this.config.runtime.modelPath` (via `node:path` `basename`) instead of the hard-coded `ggml-base.en.bin`.
**Evidence:** `src/service.mjs:74`; `tests/service.test.mjs` — "health falls back to the selected model file name when worker metadata omits it" (asserts `ggml-small.en.bin`).

### Real service runs `small.en`
**State:** Resolved
**Value:** In a scratch home outside the worktree and `%LOCALAPPDATA%`, the real worker loaded the downloaded, hash-verified `ggml-small.en.bin` through `serve`'s configuration path and `npm run smoke` printed `{"ok":true,"sessions":2,"modelInitializations":1,...}`; the worker's own `ready` event reported `"model":"ggml-small.en.bin"`.
**Evidence:** scratch-home smoke output, 2026-09-24T21:13:37–21:13:47Z; `"ok":true,"modelInitializations":1`; wall-clock 127,914 ms. A second smoke run after switching back to `base.en` also printed `"ok":true,"modelInitializations":1`, wall-clock 122,662 ms.

### Scope and architecture compliance
**State:** Resolved
**Value:** Only the ticket's owned files changed; `scripts/`, `native/`, `clients/`, `contracts/`, `package.json`/`package-lock.json`, `.github/`, `README.md`, `THIRD_PARTY_NOTICES.md`, the config schema shape, the health/session protocol, the default model (`base.en`), and `%LOCALAPPDATA%\WhisperService\` were untouched; no remote operation beyond pushing the ticket branch.
**Evidence:** `git diff --stat 9677c12e2bfcfe3d11689c324f90281ea2b99a1e..HEAD` lists exactly `src/cli.mjs`, `src/config.mjs`, `src/constants.mjs`, `src/service.mjs`, `src/worker-client.mjs`, `tests/cli.test.mjs`, `tests/config.test.mjs`, `tests/service.test.mjs`; `%LOCALAPPDATA%\WhisperService\config.json` SHA-256 `65DF91E9...AFEE392` identical before and after the scratch-home run; `git status --short --branch` clean and equal to `origin/agent/wmodel-01-model-catalog`.

### Implementation completeness
**State:** Resolved
**Value:** Every build-checklist and exit-gate item is checked with direct evidence; `npm ci` + `npm audit --audit-level=high` reported 0 vulnerabilities, `npm test` passed 26/26 with port 8178 free, `node --check` passed on every changed `.mjs` file, and `git diff --check` reported nothing.
**Evidence:** commit `06adb8d85953b481a71c902f181b0842a934a35a` on `agent/wmodel-01-model-catalog`, pushed to `origin`; `npm test` → `pass 26, fail 0`.
