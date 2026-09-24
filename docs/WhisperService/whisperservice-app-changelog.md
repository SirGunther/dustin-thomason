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

- **Working:** WhisperService v1 on `main` (`9677c12`), serving `base.en` on `127.0.0.1:8178`.
- **Open:**
  - Model upgrade handoff: confirm the delivery order, commit the set, then dispatch WMODEL-01 with
    the live service stopped.
  - After WMODEL-02 merges, the user switches the live installation to `small.en` and compares it
    with `base.en`.
