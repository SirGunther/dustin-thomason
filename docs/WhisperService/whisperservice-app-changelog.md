# WhisperService App Changelog

## Purpose

This is the canonical development record for WhisperService work run from dustin-thomason: what
changed, why, how it was verified, and what is still open.

## Scope

Personal-project changelog for WhisperService (`C:\WhisperService`, `SirGunther/WhisperService`),
the local Whisper transcription server SaySlate's Local Whisper provider uses, and its planning
artifacts under `docs/WhisperService/`. SaySlate's own record is
[`../SaySlate/sayslate-app-changelog.md`](../SaySlate/sayslate-app-changelog.md).

## Session log (newest first)

### 2026-09-24T22:05:00Z — Model upgrade handoff delivered (WMODEL-01, WMODEL-02 merged)

- **Problem → requirement:** the service could only run `base.en`; it has to run `small.en` too, and
  switch between them in either direction with either one installed alone, inside WhisperService
  only (REQ-001–003).
- **WMODEL-01** (merged `bcc5049`): a frozen `MODELS` catalog (`base.en`, `small.en`) in
  `src/constants.mjs`; `modelIdForConfig` validates the configured file-and-hash pair against the
  catalog; `configure model <id>` switches only to an installed, hash-verified file and prompts a
  restart; health falls back to the configured model's file name. No configuration-schema change;
  the live `base.en` configuration stays valid.
- **WMODEL-02** (merged `04d87d0`): `npm run setup -- --model <id>` downloads and verifies the named
  model; with no flag, setup provisions the selected model and never changes the selection. The
  legacy `MODEL_FILE`/`MODEL_SHA256` constants are removed, and the README ("Change the model") and
  third-party notices cover both models. Review 1 finding F1 (the new README subsection had absorbed
  the origin and token setup) was fixed in `f9fe7db` before the merge.
- **Real runs (implementation agents, scratch homes):** the worker loaded `ggml-small.en.bin`
  through `serve`'s configuration path and smoke passed with one model load. Two-session smoke on
  this CPU (i9-9900K): about 128 s on `small.en` against about 123 s on `base.en`. The live
  `config.json` hash is unchanged.
- **Tests run (final state, `main` `04d87d0`, port 8178 free):**

  | Gate | Command | Scope | Result | Exception / risk |
  | --- | --- | --- | --- | --- |
  | audit | `npm audit --audit-level=high` | WhisperService (ticket worktrees) | pass, 0 vulnerabilities | — |
  | tests | `npm test` | WhisperService `main` after each merge | pass, 30/30 | — |
  | syntax | `node --check` on changed `.mjs` files | both tickets | pass | — |
  | whitespace | `git diff --check` | both ticket ranges | pass | — |
  | CI | `.github/workflows/ci.yml` (`npm ci`, audit, test, native build) | `origin/main` `bcc5049` and `04d87d0` | success on both | — |

- **Tests added/updated:** `tests/cli.test.mjs` and `tests/setup.test.mjs` (new);
  `tests/config.test.mjs` and `tests/service.test.mjs` (extended). The orchestrator's mutation
  probes (8 across both tickets) each failed a test.
- **Regression impact:** checked against SaySlate's contract. Health keeps its shape and `model`
  stays a non-empty string (EV-013), the session protocol is unchanged, and SaySlate is untouched.
- **API docs:** not relevant. `contracts/` (health and config schemas, OpenAPI) is unchanged; the
  config schema already allowed any pinned hash (EV-009).
- **Audits:** [handoff audit records](tickets/whisper-model-upgrade/whisper-model-upgrade-handoff.md#audit-records).

### 2026-09-24T21:20:00Z — Model upgrade handoff confirmed and committed

- **Confirmed:** Dustin Thomason handed the orchestrating agent the
  [handoff](tickets/whisper-model-upgrade/whisper-model-upgrade-handoff.md) to run and notify on
  completion; recorded on its `Confirmed:` line.
- **Committed:** the complete document set, as the dispatch base for WMODEL-01.
- **Live service:** stopped by the user, freeing `127.0.0.1:8178` for the gates.

### 2026-09-24T18:40:00Z — Model upgrade handoff drafted

- **Scope:** make the model switchable between `base.en` (the current one) and `small.en`, server-wide
  and inside WhisperService only. This narrows the proposed SaySlate "Whisper model selection"
  feature; SaySlate needs no change.
- **Written:** the `agentic-handoff` set in
  [`tickets/whisper-model-upgrade/`](tickets/whisper-model-upgrade/):
  - requirements: REQ-001–003 and EV-001–022;
  - decisions: LD-001–009, with four open questions all resolved from sources;
  - the handoff, WMODEL-01 (model catalog, configuration, `configure model`, health name) and
    WMODEL-02 (setup `--model`, docs).
- **Found:**
  - `small.en` is 487,614,201 bytes, with SHA-256 `c6138d6d…41e5d` taken from its Hugging Face
    pointer.
  - The live service (pid 9444) holds `127.0.0.1:8178`, so `npm test` shows 17 passing and 1
    `EADDRINUSE` failure until it is stopped. Every gate needs it stopped.
- **Not done:** the delivery order awaits confirmation, the set isn't committed, and no
  WhisperService code has changed.

## Current state

- **Working:** WhisperService on `main` (`04d87d0`) with a switchable model: `base.en` (default)
  or `small.en`, via `npm run setup -- --model <id>` and `npm run configure -- model <id>`, then a
  restart. The live installation still selects `base.en`, and only `ggml-base.en.bin` is installed.
- **Open:**
  - The user's live trial: install and select `small.en`, start the service, dictate through
    SaySlate's Local Whisper, and compare it with `base.en`. To go back, run
    `npm run configure -- model base.en` and restart. Record the verdict in the WMODEL-02 audit's
    post-merge validation line.
