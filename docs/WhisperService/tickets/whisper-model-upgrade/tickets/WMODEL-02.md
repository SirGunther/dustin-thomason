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

- [ ] In `scripts/setup.mjs`, parse `--model <id>`. An unknown id or a missing value exits non-zero, listing the `MODELS` ids (LD-006).
- [ ] Resolve the model to provision: the `--model` id if given, otherwise `modelIdForConfig` of the configuration that `initializeUserFiles` leaves in place. A new installation's configuration selects `base.en`. An invalid configuration is an error, never a silent default (LD-004, LD-006).
- [ ] Change `provisionModel` to take the model id and use that entry's file (inside `paths.models`), hash, and URL. Change the success message to `<file> identity verified.` (LD-006).
- [ ] Guard the module-level `setup(…)` call the way `src/cli.mjs` guards `main`, and export the argument-parsing and model-resolving functions so they can be tested (LD-006).
- [ ] Remove `MODEL_FILE` and `MODEL_SHA256` from `src/constants.mjs`, since nothing imports them any longer (LD-003).
- [ ] Add `tests/setup.test.mjs`:
  - [ ] `--model small.en` resolves to `small.en`.
  - [ ] An unknown id and a missing value are rejected.
  - [ ] With no flag, a configuration selecting `small.en` resolves to `small.en`, and a new temporary home resolves to `base.en`.
  - [ ] Resolving leaves `config.json` byte-identical.
- [ ] Update `README.md` (LD-009):
  - [ ] Rewrite `:3`, `:26`, `:28`, and `:107` for two models.
  - [ ] Add a "Change the model" subsection: `npm run setup -- --model small.en --skip-build`, `npm run configure -- model small.en`, and a restart. Going back is `npm run configure -- model base.en` and a restart. To keep only one model, delete the other file from `%LOCALAPPDATA%\WhisperService\models`.
- [ ] Add a `small.en` section to `THIRD_PARTY_NOTICES.md` matching the `base.en` section at `:18-24`, with EV-010's file, URL, and hash (LD-009).

## Exit gate

- [ ] `npm ci`, then `npm audit --audit-level=high`, reports no high or critical vulnerability.
- [ ] `npm test` passes every test with `127.0.0.1:8178` free (handoff dispatch rule 5).
- [ ] `node --check` passes for every changed `.mjs` file.
- [ ] `git diff --check` reports nothing.
- [ ] `git grep -n -E "MODEL_SHA256|MODEL_FILE"` returns no matches.
- [ ] Real run in a fresh scratch home (handoff dispatch rule 6):
  - [ ] `node scripts/setup.mjs --model small.en --skip-build` prints `ggml-small.en.bin identity verified.`, and the downloaded file hashes to EV-010's value.
  - [ ] `configure show` still selects `base.en`.
  - [ ] Running the same command again downloads nothing: the file's modification time is unchanged.
  - [ ] After the live `whisper-worker.exe` is copied in, `node src/cli.mjs configure model small.en` succeeds.
  - [ ] `node scripts/setup.mjs --skip-build`, with no flag, downloads nothing and does not create `ggml-base.en.bin`.
  - [ ] `npm run smoke` prints `"ok":true` with `"modelInitializations":1`.
- [ ] `%LOCALAPPDATA%\WhisperService\config.json` has the same SHA-256 before and after the run.
- [ ] `git diff --stat <starting commit>..HEAD` lists only the owned files.

## Out of scope

- Model selection, configuration validation, and health: WMODEL-01.
- Switching the live installation to `small.en`: the user's post-merge step (handoff dispatch rule 6).

## Objectives

Complete every objective below in place, using the handoff's Compact Audit Trail Output Rule. Resolved requires implemented code, direct evidence, and focused verification; intent or partial implementation is Unresolved.

### Setup provisions the named or selected model
**State:**
**Value:**
**Evidence:**
**Depends on:**

### Setup never changes the selection
**State:**
**Value:**
**Evidence:**
**Depends on:**

### Legacy single-model constants removed
**State:**
**Value:**
**Evidence:**
**Depends on:**

### Documentation describes both models
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
