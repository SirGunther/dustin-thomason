# WhisperService Model Upgrade — Decisions

Requirements: [whisper-model-upgrade-requirements.md](./whisper-model-upgrade-requirements.md)

| ID | Decision | Why | Serves | Source | Supersedes or rejects |
| --- | --- | --- | --- | --- | --- |
| LD-001 | The work is delivered as the `agentic-handoff` document set in `docs/WhisperService/tickets/whisper-model-upgrade/`, with a WhisperService project changelog at `docs/WhisperService/whisperservice-app-changelog.md`. | The user asked for the same handoff process and for this work to be kept separate from the app. | — | [Original ticket](./whisper-model-upgrade-original-ticket.md): "Same handoff process" … "abstract it from whatever's going on with the actual app" | — |
| LD-002 | The whole service runs one active model at a time. There is no per-session or per-client choice, and SaySlate does not change. | The user reduced the feature to upgrading the model "in general", done in WhisperService. SaySlate already works with any model name (EV-013). | REQ-002, REQ-003 | [Original ticket](./whisper-model-upgrade-original-ticket.md): "Let's make it easier. What if I just want to upgrade the Whisper model in general?" | A model picker in SaySlate, and per-session model selection |
| LD-003 | The service knows exactly two models: `base.en` and `small.en`. <ul><li>**`constants.mjs`** exports `DEFAULT_MODEL_ID = 'base.en'` and a frozen `MODELS` map. Each entry is a frozen `{ file, sha256, url }`, with EV-010's file names, hashes, and `https://huggingface.co/ggerganov/whisper.cpp/resolve/main/<file>` URLs.</li><li>**Legacy constants:** `MODEL_FILE` and `MODEL_SHA256` stay exported as the `base.en` entry's values until WMODEL-02, because `scripts/setup.mjs` imports `MODEL_SHA256` (EV-008).</li></ul> | The user named "small". The service is English-only (EV-003, EV-006), so the English-only `.en` files apply. Pinned hashes keep the existing identity check (EV-005). | REQ-001, REQ-002 | [Original ticket](./whisper-model-upgrade-original-ticket.md) ("the small one"); the `.en` variant and the entry shape resolved from sources, open decision 2: EV-003, EV-005, EV-006, EV-008, EV-010 | The single pinned model (EV-001) |
| LD-004 | The selected model is recorded in the existing `runtime.modelPath` and `runtime.modelSha256` fields, so there is no new configuration field, no migration, and no schema change. <ul><li>**`modelIdForConfig(config)`:** `config.mjs` exports it. It returns the `MODELS` id whose `sha256` equals `runtime.modelSha256` (ignoring case) and whose `file` equals the file name of `runtime.modelPath`. Otherwise it throws `ServiceError('INVALID_CONFIGURATION', …)`.</li><li>**`validateConfig`:** calls `modelIdForConfig` instead of comparing against `MODEL_SHA256`.</li><li>**`servicePaths()`:** adds `models` (the `<home>\models` folder), and `model` stays the default model's path.</li></ul> | The live configuration (EV-011) stays valid as it is. The schema already allows any hash (EV-009). The worker already verifies whichever hash is configured (EV-005). | REQ-002 | Resolved from sources, open decision 3: EV-002, EV-003, EV-005, EV-009, EV-011 | EV-003's single-hash check |
| LD-005 | `configure model <id>` selects the model. <ul><li>**`selectModel(config, modelId, paths, catalog = MODELS)`:** `config.mjs` exports it as an async function.<ul><li>It rejects an unknown id with a message listing the valid ids.</li><li>It requires `<paths.models>\<file>` to exist with a matching SHA-256, using the `sha256` helper that `worker-client.mjs` now exports.</li><li>It returns a copy of the configuration with `runtime.modelPath` and `runtime.modelSha256` set.</li><li>Every failure is `INVALID_CONFIGURATION`, and a missing or mismatched file names `npm run setup -- --model <id>`.</li></ul></li><li>**`cli.mjs`:** calls it, then `saveConfig`, and prints "Model set to `<id>`. Restart WhisperService to load it." `usage` lists `configure model <base.en\|small.en>`.</li></ul> | This follows the existing `configure` pattern of validating and then saving (EV-004). A missing or wrong file would otherwise pass configuration and fail only when the service starts (EV-005). The service reads its configuration once, at startup (EV-004). Exporting the existing helper avoids a second hashing mechanism (EV-005). | REQ-002 | Resolved from sources, open decision 4: EV-004, EV-005 | — |
| LD-006 | `npm run setup -- --model <id>` downloads and verifies that model into the models folder. <ul><li>**Without `--model`:** setup provisions the model the existing configuration selects (`modelIdForConfig`), which is `base.en` on a new installation.</li><li>**Selection:** setup never changes which model is selected.</li><li>**Output:** its success message names the file it provisioned.</li><li>**Imports:** its module-level run is guarded the way `cli.mjs`'s is, so tests can import it.</li></ul> | `small.en` can then be installed alone, and a later setup does not bring back `base.en` (REQ-002). Selection stays one explicit command (LD-005). | REQ-001, REQ-002 | Resolved from sources, open decision 4: REQ-002, EV-008 | EV-008's hard-coded download and message |
| LD-007 | `base.en` stays the default for new installations and for the live configuration. Switching to `small.en` is the user's own live step after the tickets merge. | The user says the base model is doing well enough today. | REQ-002 | [Original ticket](./whisper-model-upgrade-original-ticket.md): "The base one seems to be doing okay" | — |
| LD-008 | Health's fallback model name becomes the file name of `runtime.modelPath` instead of the hard-coded base name. The health response keeps its shape. | Health would otherwise report the base model while `small.en` runs, and SaySlate accepts any non-empty name (EV-007, EV-013). | REQ-001, REQ-003 | Resolved from sources: EV-007, EV-013 | EV-007's hard-coded fallback |
| LD-009 | `README.md` states that the model can be chosen between `base.en` and `small.en`, adding the switch, switch-back, and keep-only-one steps. `THIRD_PARTY_NOTICES.md` adds a `small.en` section like the `base.en` one. | Both documents would otherwise say `base.en` is the only model (EV-014). | REQ-002 | Resolved from sources: EV-014 | README's "alternate model" exclusion (EV-014), for the model only |

## Open Decision Checklist

- [x] 1. Swap `base` for `small`, or make the model switchable? — Resolved from the origin as LD-002 and LD-004 (REQ-002)
- [x] 2. Which `small` file: `small` or `small.en`? — Resolved from sources as LD-003
- [x] 3. Where is the selected model recorded? — Resolved from sources as LD-004
- [x] 4. How does the user install and select a model? — Resolved from sources as LD-005 and LD-006

## Open Decision Register

### 1. Swap or switch

**State:** Resolved
**Value:** Resolved as LD-002 and LD-004.
**Investigation:** The origin treats small as a trial ("might be a little bit better") and leaves both installation outcomes open ("Maybe I'll just have that one installed, or maybe not"). A plain swap of the pinned constants (EV-001, EV-003, EV-008) would make going back to base a code change.
**Why user input is required:** Not required. REQ-002 records the user's own words, and only a switchable model satisfies both outcomes.
**Recommendation:** Keep both models available, and make selection one command.
**Evidence:** EV-001, EV-003, EV-008
**Depends on:** —

### 2. Which small model

**State:** Resolved
**Value:** Resolved as LD-003.
**Investigation:** Configuration validation and the native worker both force English (EV-003, EV-006). The English-only files exist with pinned hashes (EV-010).
**Why user input is required:** Not required. The service can only transcribe English, so the English-only file applies.
**Recommendation:** `small.en`.
**Evidence:** EV-003, EV-006, EV-010
**Depends on:** —

### 3. Where the choice is recorded

**State:** Resolved
**Value:** Resolved as LD-004.
**Investigation:** The configuration already records the model path and hash (EV-002), and the live installation uses them (EV-011). The worker verifies whatever is configured (EV-005), and the published schema already allows any hash (EV-009).
**Why user input is required:** Not required. The existing fields hold the choice without a migration.
**Recommendation:** Reuse `runtime.modelPath` and `runtime.modelSha256`, and validate them against the catalog.
**Evidence:** EV-002, EV-005, EV-009, EV-011
**Depends on:** —

### 4. Installing and selecting

**State:** Resolved
**Value:** Resolved as LD-005 and LD-006.
**Investigation:** Setup downloads and verifies one hard-coded model (EV-008). Each `configure` command validates its input and saves (EV-004). The worker refuses a missing or mismatched model only at startup (EV-005).
**Why user input is required:** Not required. The existing setup and configure commands each already own one of these two steps.
**Recommendation:** Setup downloads the model named by `--model`, or the selected one. `configure model` switches only to an installed, verified file, and the user then restarts.
**Evidence:** EV-004, EV-005, EV-008
**Depends on:** —
