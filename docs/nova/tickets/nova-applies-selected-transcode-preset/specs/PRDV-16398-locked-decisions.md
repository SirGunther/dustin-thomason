# Locked decisions — nova/nova-applies-selected-transcode-preset

Source of open variables: [PRDV-16398-investigation.md](../investigations/PRDV-16398-investigation.md) §10.

> **Note on this file's history.** An earlier version of this file recorded six decisions as "agent default" that the agent had made unilaterally. That was wrong — those were Dustin's calls. Dustin pulled it back on 2026-07-28 and set a standing rule: **no changes or decisions without explicit approval.** The file below records only what Dustin actually ruled.

## The governing decision

**LD-000 — Follow Larry's spec as written unless the investigation surfaced a genuine reason not to.**

> Ruled by Dustin, 2026-07-28: *"if there's no harm in doing it, then do it… if he thinks it should be built, then just do it… Unless there's a genuine reason to not follow the path of the spec."*

This settles every structural question at once and takes them off the table. Larry's spec at `larry-adams/systems/nebula/video-transcode/PRDV-16398-nova-applies-selected-transcode-preset.md` is the implementation shape: `TRANSCODE_PRESETS` const, `resolveTranscodePreset` returning `{ presetValue, buildArgs, isFallback }`, the `presets/` subfolder, `standard-depo.preset.ts` + `vid-mix.preset.ts`, `ffmpeg.template.ts` deleted, `VideoJob.template` → `transcodeValue`, and the spec-test layout in its §"Spec tests".

The point of the investigation was to check for **drift** — whether the spec matched the code — not to relitigate style. It matched. So it gets built as specified.

## Decisions ruled by Dustin

| ID | Decision | Ruled | Where it lands |
| --- | --- | --- | --- |
| LD-001 | **Ignore the HandBrake-drift check.** `template1` has not changed; migrate it verbatim and change nothing about Standard's output. Supersedes the ticket's developer note ("fix in the same PR if it drifts", original-ticket line 64) and Larry's spec line 223. | Dustin, 2026-07-28 — *"Nothing's changed… It just needs to be migrated correctly… paste the file."* | `standard-depo.preset.ts` — verbatim copy. AC 2 = byte-identical parity. |
| LD-002 | **Fix the local harness that seeds `videoTranscodeValue: "template1"`.** Not treated as a decision — it is part of doing the job correctly. | Dustin, 2026-07-28 | `scripts/run-local-transcode.sh`, `docs/local-docker-transcode.md` |
| LD-003 | **Video Mix arg values come from the HandBrake preset, supplied by Dustin.** Not inferred (`source-truth`). Drop location agreed: `src/video-conversion/domain/steps/transcode-step/presets/vid-mix.preset.ts`. | Dustin, 2026-07-28 | `vid-mix.preset.ts` — file created, values pending |
| LD-004 | **Implement now, then test locally.** Everything except `vid-mix.preset.ts`'s values proceeds; local Docker E2E follows. | Dustin, 2026-07-28 | Test plan HP-6 / HP-7 |
| LD-005 | **Standing rule: the agent makes no changes or decisions without Dustin's explicit approval.** | Dustin, 2026-07-28 | Applies to every phase from here |

## Carried by the ticket itself (not agent choices)

- Key on `videoTranscodeValue`, not `videoTranscodeId` — ticket developer note; independently confirmed by migration `1754574059506` (report §8, A4).
- Unknown/empty → fall back to Standard with a `warn` carrying `requestedValue` and `appliedPreset` — ticket AC 4.
- `nova-back-end` only; no Callisto, docking-protocol, or infrastructure change — ticket "Fix scope"; verified by trace (report §3, criterion 6).
- Registry keys exactly `['Standard', 'Video Mix']`, enforced by a CI test — ticket AC 5.

## Deferred, with the risk recorded

- **The applied preset is not reported downstream.** Nova's completed event forwards the *requested* value, so a fallback is invisible outside Nova's logs. Out of scope per the ticket's no-contract-change constraint. Risk recorded in [PRDV-16398-future-development-concerns.md](../PRDV-16398-future-development-concerns.md) Concern 1 — that entry is the record, and it names the options for whoever owns the contract.
- **Whether the AJSF upload path is a second producer** that bypasses Callisto's two-value gate. Does not gate this ticket — the fallback ships either way. Concern 3.

## Still open

- Nothing blocking implementation.
- `vid-mix.preset.ts`'s arg values — awaiting the HandBrake preset from Dustin (LD-003).
