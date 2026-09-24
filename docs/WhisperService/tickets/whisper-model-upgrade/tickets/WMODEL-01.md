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

- [ ] In `src/constants.mjs`, add `DEFAULT_MODEL_ID` and the frozen `MODELS` map with EV-010's file names, hashes, and URLs. Redefine `MODEL_FILE` and `MODEL_SHA256` from `MODELS[DEFAULT_MODEL_ID]` so `scripts/setup.mjs` keeps working (LD-003).
- [ ] In `src/worker-client.mjs`, add `export` to the existing `sha256` function and change nothing else (LD-005).
- [ ] In `src/config.mjs` (LD-004, LD-005):
  - [ ] Add `models` to `servicePaths()`, and build `model` from the default entry.
  - [ ] Build `defaultConfig`'s `runtime.modelPath` and `runtime.modelSha256` from the default entry.
  - [ ] Add `modelIdForConfig`, and use it in `validateConfig` in place of the single-hash comparison at `config.mjs:109`.
  - [ ] Add `selectModel`.
- [ ] In `src/cli.mjs`, add the `configure model <id>` branch (`selectModel`, then `saveConfig`, then LD-005's message), and add the line to `usage` (LD-005).
- [ ] In `src/service.mjs`, change health's fallback at `service.mjs:73` to the file name of `this.config.runtime.modelPath` (LD-008).
- [ ] Extend `tests/config.test.mjs`:
  - [ ] `validateConfig` accepts the default configuration and a configuration selecting `small.en`.
  - [ ] It rejects the `small.en` hash with the `base.en` file name, and it rejects an unknown hash.
  - [ ] `modelIdForConfig` returns `base.en` and `small.en` for their configurations.
  - [ ] `selectModel`, given a test catalog and a temporary file whose hash it lists, returns the updated configuration and leaves the input unchanged.
  - [ ] It rejects a missing file with a message naming `npm run setup -- --model`, a hash mismatch, and an unknown id with a message listing the valid ids.
- [ ] Add `tests/cli.test.mjs`, calling `main` with `WHISPER_SERVICE_HOME` set to a temporary home created by `initializeUserFiles(…, { secureCredentials: false })`:
  - [ ] `configure model small.en` with no model file rejects, and `config.json` is byte-identical afterwards.
  - [ ] `configure model tiny.en` rejects and lists the valid ids.
  - [ ] `configure model` with no id prints usage, including the new line, and sets exit code 2.
- [ ] Extend `tests/service.test.mjs`: with worker metadata lacking `model` and a configuration selecting `small.en`, `/v1/health` reports `ggml-small.en.bin`.

## Exit gate

- [ ] `npm ci`, then `npm audit --audit-level=high`, reports no high or critical vulnerability.
- [ ] `npm test` passes every test with `127.0.0.1:8178` free (handoff dispatch rule 5).
- [ ] `node --check` passes for every changed `.mjs` file.
- [ ] `git diff --check` reports nothing.
- [ ] Real run in a scratch home (handoff dispatch rule 6):
  - [ ] `ggml-small.en.bin`, downloaded from its EV-010 URL, hashes to EV-010's value.
  - [ ] `node src/cli.mjs configure model small.en` succeeds, and `configure show` then lists the `small.en` path and hash.
  - [ ] `npm run smoke` prints `"ok":true` with `"modelInitializations":1`.
  - [ ] `configure model base.en` refuses while no base file is present, and `small.en` stays selected.
  - [ ] After the live `ggml-base.en.bin` is copied in, `configure model base.en` succeeds and `npm run smoke` again prints `"ok":true`.
  - [ ] The wall-clock time of each smoke run is reported.
- [ ] `%LOCALAPPDATA%\WhisperService\config.json` has the same SHA-256 before and after the run.
- [ ] `git diff --stat <starting commit>..HEAD` lists only the owned files.

## Out of scope

- Setup downloading a chosen model, removing the legacy constants, and the README and notices: WMODEL-02.
- Switching the live installation to `small.en`: the user's post-merge step (handoff dispatch rule 6).

## Objectives

Complete every objective below in place, using the handoff's Compact Audit Trail Output Rule. Resolved requires implemented code, direct evidence, and focused verification; intent or partial implementation is Unresolved.

### Two pinned models in the catalog
**State:**
**Value:**
**Evidence:**
**Depends on:**

### Configuration accepts either model
**State:**
**Value:**
**Evidence:**
**Depends on:**

### `configure model` switches only to a verified file
**State:**
**Value:**
**Evidence:**
**Depends on:**

### Health names the running model
**State:**
**Value:**
**Evidence:**
**Depends on:**

### Real service runs `small.en`
**State:**
**Value:**
**Evidence:**
**Depends on:**

### Scope and architecture compliance
**State:**
**Value:**
**Evidence:**
**Depends on:**

### Implementation completeness
**State:**
**Value:**
**Evidence:**
**Depends on:**
