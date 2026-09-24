# WhisperService Model Upgrade — Requirements

Origin: [Original ticket](./whisper-model-upgrade-original-ticket.md)

## Requirements

| ID | Condition that must be true | Source |
| --- | --- | --- |
| REQ-001 | WhisperService can transcribe with the Whisper `small` model in place of `base`. | [Original ticket](./whisper-model-upgrade-original-ticket.md): "What if I just want to upgrade the Whisper model in general? The base one seems to be doing okay, but I wonder if the small one might be a little bit better." |
| REQ-002 | The user can switch the service between `base` and `small`, in either direction, without changing code. Either model can be the only one installed. | [Original ticket](./whisper-model-upgrade-original-ticket.md): "I wonder if the small one might be a little bit better. Maybe I'll just have that one installed, or maybe not." |
| REQ-003 | The change is made in WhisperService alone, and SaySlate keeps working with it unchanged. | [Original ticket](./whisper-model-upgrade-original-ticket.md): "Maybe I need to go to the Whisper service and update that specifically … we can totally abstract it from whatever's going on with the actual app" |

## Evidence

| ID | Fact about what exists | Direct pointer |
| --- | --- | --- |
| EV-001 | The service pins one model as two constants: its file name and its SHA-256. | `C:\WhisperService\src\constants.mjs:8-9` — `export const MODEL_FILE = 'ggml-base.en.bin';` / `export const MODEL_SHA256 = 'a03779c86df3323075f5e796cb2ce5029f00ec8869eee3fdfb897afe36c6d002';` |
| EV-002 | The model path is `<home>\models\<MODEL_FILE>`. A new configuration records that path and the pinned hash in `runtime`. | `C:\WhisperService\src\config.mjs:23` — `model: join(root, 'models', MODEL_FILE)`; `config.mjs:46-51` — `runtime: {` … `modelPath: paths.model,` / `modelSha256: MODEL_SHA256,` |
| EV-003 | Configuration validation accepts only English and only the one pinned hash. | `C:\WhisperService\src\config.mjs:88` — `config.language !== 'en'`; `config.mjs:109` — `config.runtime?.modelSha256?.toLowerCase() !== MODEL_SHA256` |
| EV-004 | `serve` reads the configuration once at startup and hands `runtime.modelPath` and `runtime.modelSha256` to the one worker. The `configure` commands each validate their input, then call `saveConfig`. | `C:\WhisperService\src\cli.mjs:76-84` — `const config = await loadConfig(paths);` … `modelPath: config.runtime.modelPath,` / `modelSha256: config.runtime.modelSha256,`; `cli.mjs:9-21` (`usage`); `cli.mjs:43-50` (`configure preview`) |
| EV-005 | Before it spawns the worker, the worker client checks that the configured model file exists and matches the configured hash, then passes it as `--model`. Its hashing helper is not exported. | `C:\WhisperService\src\worker-client.mjs:28` — `this.args = command ? args : ['--model', modelPath];`; `worker-client.mjs:37-45` — `const actual = await sha256(this.modelPath);` … `'The model SHA-256 does not match the pinned identity.'`; `worker-client.mjs:9-13` — `async function sha256(path) {` |
| EV-006 | The native worker loads whichever file `--model` names, reports that file's name when ready, runs on the CPU with at most 8 threads, and forces English. | `C:\WhisperService\native\whisper-worker.cpp:149` — `context_parameters.use_gpu = false;`; `whisper-worker.cpp:156` — `"{\"protocolVersion\":\"1.0.0\",\"model\":\"" + json_escape(basename(model_path))`; `whisper-worker.cpp:185-186` — `std::min(8, …hardware_concurrency()…)` / `parameters.language = "en";` |
| EV-007 | Health reports the worker's model name, but falls back to a hard-coded base file name. The health contract types `model` as a string. | `C:\WhisperService\src\service.mjs:73` — `model: this.worker.metadata?.model \|\| 'ggml-base.en.bin',`; `C:\WhisperService\contracts\schemas\health.schema.json:12` — `"model": { "type": "string" },` |
| EV-008 | Setup has the base model's URL and success message hard-coded, and it verifies against the one pinned hash. It always checks out the whisper.cpp source unless `--config-only` is given. It runs as soon as the module loads. | `C:\WhisperService\scripts\setup.mjs:14` — `const MODEL_URL = 'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.en.bin';`; `setup.mjs:63-82` (`provisionModel`, `MODEL_SHA256`); `setup.mjs:104-109` — `if (configOnly) return paths;` / `await provisionSource(paths);` … `console.log('ggml-base.en.bin identity verified.');`; `setup.mjs:118-119` — `const args = new Set(process.argv.slice(2));` / `setup({ configOnly: …` |
| EV-009 | The published configuration schema accepts any 64-character hex hash, so it needs no change to allow another pinned model. | `C:\WhisperService\contracts\schemas\config.schema.json:40` — `"modelSha256": { "type": "string", "pattern": "^[a-fA-F0-9]{64}$" },` |
| EV-010 | The Hugging Face pointers identify the two models. `ggml-base.en.bin` matches the pinned hash and the installed file's size. `ggml-small.en.bin` has SHA-256 `c6138d6d58ecc8322097e0f987c32f1be8bb0a18532a3f88f734d1bbf9c41e5d` and is 487,614,201 bytes. Both download from the same `resolve/main/` path. | `https://huggingface.co/ggerganov/whisper.cpp/raw/main/ggml-base.en.bin` → `oid sha256:a03779c86df3323075f5e796cb2ce5029f00ec8869eee3fdfb897afe36c6d002`, `size 147964211`; `https://huggingface.co/ggerganov/whisper.cpp/raw/main/ggml-small.en.bin` → `oid sha256:c6138d6d58ecc8322097e0f987c32f1be8bb0a18532a3f88f734d1bbf9c41e5d`, `size 487614201`; fetched 2026-09-24 |
| EV-011 | The live installation selects `base.en`. Its models folder holds only `ggml-base.en.bin` (147,964,211 bytes), and the built worker is present. | `%LOCALAPPDATA%\WhisperService\config.json` `runtime` — `"modelPath": "C:\\Users\\dktho\\AppData\\Local\\WhisperService\\models\\ggml-base.en.bin"`, `"modelSha256": "a03779c86df3323075f5e796cb2ce5029f00ec8869eee3fdfb897afe36c6d002"`; `%LOCALAPPDATA%\WhisperService\models\` and `runtime\whisper-worker.exe` listings, 2026-09-24 |
| EV-012 | The live service runs from the `C:\WhisperService` checkout and holds `127.0.0.1:8178`. The service test and the smoke test both bind that fixed address, so with the live service running `npm test` shows 17 passing tests and 1 failure (`EADDRINUSE`). | `127.0.0.1:8178` listener pid 9444 `node  src/cli.mjs serve`, 2026-09-24; `C:\WhisperService\src\service.mjs:43` — `this.http.listen({ host: HOST, port: PORT });`; `C:\WhisperService\tests\service.test.mjs:20-21`; `npm test` on 2026-09-24: `pass 17`, `fail 1`, `Cannot bind 127.0.0.1:8178: listen EADDRINUSE` |
| EV-013 | SaySlate requires only that health's `model` be a non-empty string, and it never sends a model in a session request. | `C:\SaySlate\whisperServiceClient.js:126-127` — `typeof body.model === "string" &&` / `body.model.length > 0 &&`; `whisperServiceClient.js:560` — `{ version: PROTOCOL_VERSION, previewMs }` |
| EV-014 | The README and third-party notices describe `base.en` as the only model. | `C:\WhisperService\README.md:3` — "owns one CPU-only English `base.en` model"; `README.md:26` (setup downloads `ggml-base.en.bin` and verifies its SHA-256); `README.md:28` (setup flags); `README.md:107` — "GPU tuning, alternate model/language"; `C:\WhisperService\THIRD_PARTY_NOTICES.md:18-24` ("ggml `base.en` model") |
| EV-015 | The smoke test uses whatever home `WHISPER_SERVICE_HOME` names. It runs two real sessions, requires exactly one model initialization, and reports no timing. It creates its WAV fixture if missing, and `*.wav`, `*.bin`, and `config.json` are gitignored. | `C:\WhisperService\scripts\smoke.mjs:54-67` — `const paths = servicePaths();` … `if (modelInitializations !== 1)` … `console.log(JSON.stringify({ ok: true, sessions: 2, …`; `C:\WhisperService\src\config.mjs:10` (`WHISPER_SERVICE_HOME`); `C:\WhisperService\.gitignore` |
| EV-016 | This machine has an Intel i9-9900K (8 cores, 16 threads) and 31.9 GB of RAM. Its GTX 1080 Ti is unused, because the build is CPU-only (EV-006). | `Win32_Processor`, `Win32_ComputerSystem`, and `Win32_VideoController` queries, 2026-09-24 |

## Implementation conventions

| ID | Fact about what exists | Direct pointer |
| --- | --- | --- |
| EV-017 | The package is ES modules (`"type": "module"`, `.mjs` files) on Node 22 or later, with exactly two runtime dependencies. | `C:\WhisperService\package.json` — `"type": "module"`, `"node": ">=22"`, `"busboy": "1.6.0"`, `"ws": "8.21.3"`; local `node --version` → `v24.11.1` |
| EV-018 | `npm test` runs `node --test --test-reporter=spec` over the `tests/*.test.mjs` files, which use `node:test` and `node:assert/strict`. The tests build configurations with `testConfig` in temporary homes set through `WHISPER_SERVICE_HOME`. | `C:\WhisperService\package.json` `scripts.test`; `C:\WhisperService\tests\helpers.mjs:5-9` (`testConfig`); `tests/helpers.mjs:11-17` (`FakeWorker`, `metadata.model`); `tests/config.test.mjs:35-37` (`mkdtemp` + `servicePaths({ WHISPER_SERVICE_HOME: root })`) |
| EV-019 | CI's gates are `npm ci`, `npm audit --audit-level=high`, `npm test`, and a native build with no model download. There is no lint script. The baseline audit reports 0 vulnerabilities. | `C:\WhisperService\.github\workflows\ci.yml`; `npm audit --audit-level=high` → `found 0 vulnerabilities`, 2026-09-24 |
| EV-020 | Dependencies are locked by `package-lock.json`, and there are no dev dependencies. A fresh worktree has no `node_modules` until `npm ci` runs. | `C:\WhisperService\package-lock.json`; `.gitignore` — `node_modules/` |
| EV-021 | WhisperService has no repository-local `AGENTS.md`, `CLAUDE.md`, `.agents`, or `.codex` instruction source. `.vscode/` is untracked. | `find` over `C:\WhisperService` excluding `node_modules`, 2026-09-24; `git status --short --branch` → `?? .vscode/` |
| EV-022 | `main` equals `origin/main` at a single commit, and the remote is `SirGunther/WhisperService`. | `git rev-parse HEAD` → `9677c12e2bfcfe3d11689c324f90281ea2b99a1e`; `git remote -v` → `https://github.com/SirGunther/WhisperService.git` |

## Scope boundary

| Repo or path | Access |
| --- | --- |
| `C:\WhisperService\src\constants.mjs`, `src\config.mjs`, `src\cli.mjs`, `src\service.mjs`, `src\worker-client.mjs` (exporting the existing `sha256` only), `scripts\setup.mjs`, `tests\config.test.mjs`, `tests\service.test.mjs`, new `tests\cli.test.mjs` and `tests\setup.test.mjs`, `README.md`, `THIRD_PARTY_NOTICES.md` | Writable |
| Every other path in `C:\WhisperService`, including `native\`, `clients\`, `contracts\`, `scripts\smoke.mjs`, `package.json`, `package-lock.json`, `.github\`, and `.vscode\` | Read-only |
| `%LOCALAPPDATA%\WhisperService\` (the live installation) | Read-only for every agent. Copying files out of it is allowed. Only the user changes it, in the live step after merge. |
| `C:\SaySlate` | Read-only; not touched (REQ-003) |
| `C:\dustin-thomason\docs\WhisperService\` | Writable by the author and orchestrating agent. Each ticket's checkboxes and objectives are writable by its assigned implementation agent. |
| Every other path in `C:\dustin-thomason` | Read-only |

The work does not include:
- a model picker in SaySlate, per-session models, or models beyond `base.en` and `small.en`;
- a GPU build or language support beyond English;
- the reasoning and reconcile features.

Source: [Original ticket](./whisper-model-upgrade-original-ticket.md): "Let's make it easier. What if I just want to upgrade the Whisper model in general?"

## Readiness

| Prerequisite | Status | Evidence |
| --- | --- | --- |
| `C:\WhisperService` on `main`, equal to `origin/main`, with only `.vscode/` untracked | Met | EV-022; `git status --short --branch`, 2026-09-24 |
| Live WhisperService stopped, freeing `127.0.0.1:8178`, while each ticket's gates and the review gates run | Unmet | EV-012: pid 9444 is listening, 2026-09-24. The user stops it before each dispatch and restarts it afterwards. |
| Network access to `huggingface.co` for the 488 MB `small.en` download | Met | EV-010 |
| Node 22 or later and a working `npm ci` | Met | EV-017, EV-020 |
| A built `whisper-worker.exe` to copy into scratch homes, so no CMake build is needed | Met | EV-011 |
| Worktree root `C:\WhisperService-worktrees` | Unmet | Does not exist yet. The orchestrating agent creates it at first dispatch. |
| Push access to `origin` (`SirGunther/WhisperService`) | Met | EV-022; `main` is pushed and equal to `origin/main` |
