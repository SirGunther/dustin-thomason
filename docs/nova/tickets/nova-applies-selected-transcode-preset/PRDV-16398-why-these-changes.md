# Why these changes — nova/nova-applies-selected-transcode-preset

> The living "Why" of this ticket. Created Phase 1, updated every phase, finalized at close. High-level — scenarios live in the testing-implementation doc; point-in-time classification lives in the investigation report.
>
> **Ticket:** [PRDV-16398](https://app.clickup.com/t/43227262/PRDV-16398) · **Report:** `investigations/PRDV-16398-investigation.md`

## Problem class (the core — what are we actually solving?)

**A contract vocabulary mismatch across a service boundary.** Callisto and Nova both shipped their half of the video-transcode-selection feature, and both halves work — but they never agreed on what the `videoTranscodeValue` field *means*. Callisto sends a **human display label** (`"Video Mix"`, `"Standard"`); Nova was built expecting an **ffmpeg template identifier** (`"template1"`). Nova's consumer received a string it could not recognise as a template name, and the code degenerated to hardcoding the only template it had.

This is **not** the class the ticket assumed. The ticket says the Nova consumer half "was never built." A consumer *was* built — the value is read, named, carried into the domain object, and asserted in tests. It just consumed a different vocabulary than the producer emits. See report §1.

## The code at the root (what/where is the problem)

Two symbols, and the gap between them:

- **`VideoJobAssembler.apply`** — `nova-back-end/src/video-conversion/domain/services/video-conversion-service/video-job.assembler.ts:66` — reads `payload.videoTranscodeValue` into `VideoJob.template`. The name `template` *is* the mismatch, in miniature: it labels a display string as a template identifier.
- **`TranscodeStep.apply`** — `nova-back-end/src/video-conversion/domain/steps/transcode-step/transcode.step.ts:16-25` — takes only `(localInputPath, localOutputPath)`. There is no parameter through which a preset could arrive, and line 25 calls `template1(...)` unconditionally.

The value is carried the whole way and then dropped at the last step. Full trace: report §5.

## The problems we're solving

1. **Wiring gap** — the selection Nova already receives never reaches the step that would act on it. Provable and fixable today.
2. **Capability gap** — Nova has exactly one preset (`template1`) and has never had a second. Blocked on an external artifact (the HandBrake Video Mix preset), not on code.
3. **Vocabulary gap** — Nova's own docs, fixtures, runner script, and domain field name all encode the *wrong* meaning for this field. Unaddressed, this survives the fix and makes local verification lie.
4. **Detection gap** — three separate layers of the test suite could each have caught this and none could fail. See report §5.

These are distinct, with different fixes and different blockers; the ticket merges 1 and 2 into a single "root cause" sentence.

## Why-log (append per phase; label each entry)

### Phase 1 — 2026-07-28 — [COURSE CHANGE]

**Obvious from the start:**

- Nova hardcodes `template1`; `TranscodeStep.apply` has no preset parameter. Larry's spec said so and the code confirms it exactly.
- Keying on the display label rather than `videoTranscodeId` is right, and provably so — migration `1754574059506` renumbered every id, so the id is not a stable contract.

**Not obvious — what changed after looking:**

- **The class flipped.** Reading the ticket, this looked like "producer shipped, consumer didn't." Then Nova's own artifacts turned up spelling the field's value as `"template1"` in five separate places — the domain field name, `scripts/run-local-transcode.sh:116`, `docs/local-docker-transcode.md:148` and `:299`, `__specs__/video-job.assembler.spec.ts:49`, and both root payload fixtures. A consumer that carries the value, names it, and asserts it in tests is *built*. It's built against the wrong vocabulary. That reframing is what makes problems 3 and 4 above visible at all — under the assumed class they don't exist.
- **The practical consequence is a trap.** After the resolver lands, Nova's *own documented local test value* `"template1"` becomes an unknown → falls back to Standard. Every local verification run would exercise the fallback path while appearing to pass. The vocabulary convergence isn't tidiness; it's what keeps the verification honest.
- **The detection gap is three layers, not one.** `transcode.step.spec.ts:25` computes its expected args by calling `template1` itself — tautological, structurally incapable of catching a wrong preset. `video-conversion.service.spec.ts:203-208` asserts `expect.any(Array)`. `video-job.assembler.spec.ts` proves the value *arrives* and never that it is *used*, with fixture data that hid the real labels. This is what designs the red→green regression test.
- **The completed outbox event has a blind spot.** It forwards `sourcePayload` verbatim, so it reports the value that was *requested*, never the preset that was *applied*. If Nova falls back, nothing downstream can tell. Not covered by Larry's spec; logged as a future-development concern rather than expanded into a contract change.
- **The acceptance criteria contradict themselves.** AC 2 demands "output matches today's `template1` behaviour (no regression)"; the developer note says fix Standard in the same PR if it drifted from HandBrake. Both cannot hold. Needs a ruling.

**Assumptions logged:** A1–A10 in report §8, all resolved by evidence during Phase 1 — including the Phase 0 flag about a docking-protocol version skew, which turned out to be a **stale local `node_modules` only** (`package-lock.json` pins 1.0.5). No fact was carried into the open-variable list.

**Noise / discarded:**

- The docking-protocol version skew — real observation, closed as a local-environment artifact, not a defect. Discarded from scope.
- `omitUpdatedAuditFields` destructuring `updatedBy`, a field name that no longer exists in contract 1.0.5 — a genuine oddity, but harmless (untyped `Record` passthrough) and unrelated to preset selection. Noted in the coverage-ledger frontier, not pursued.
- Adding a stable `presetKey` to the wire contract. Better long-term design, but it spans three repos with a deploy-ordering constraint, and it does **not** remove the value-keyed path (replayed historical messages have no `presetKey`). Value-keying is a strict subset of that work, so it is not a detour. Rejected for this ticket, recorded in report §6.

## Changes made — categorized (filled as implementation locks; subject to update)

_Pending Phase 5. Anticipated shape from the confirmed class: 1 requested change (apply the selected preset) · 1 capability gap (a second preset exists at all) · 1 workflow change (converge the local-harness vocabulary) · 1 bug fix or more in the test surface (the tautological assertions). Counted and given Before / After / Why once implemented._

## Why it shipped together

_Pending Phase 5 — will tie the bundle to the acceptance criteria._

## Scope

`nova-back-end` only, as the ticket constrains. No Callisto, docking-protocol, or infrastructure change. The investigation confirmed that constraint is correct rather than assumed it: the value already arrives intact, so nothing upstream needs to move.

## Net

_Pending close._

## Verified

_Pending Phase 5. Note from Phase 1: mocked unit tests cannot prove the encode actually differs — only the local Docker harness (`scripts/run-local-transcode.sh`) plus `ffprobe` on the downloaded output can. The test plan carries both._
