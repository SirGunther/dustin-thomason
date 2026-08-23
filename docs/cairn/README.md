# Cairn Documentation

This directory is the canonical project record for Cairn. It preserves what the project can
do, what was decided and why, and what was verified in each development session.

Cairn is a markdown vault UI — a folder of notes that reads like OneNote and behaves like
VS Code — intended for eventual integration into WorkLists.

Phase 0 closed 2026-08-22 with the manual directory-picker result; Phases 1 through 6 —
contract governance, supervision, identity/ordering/revisions, the vault read boundary,
document state ownership, and the write path — landed the same day. **No file anyone chose has
been written**; two gesture-driven probes are pending a manual run. The original UI POC remains a direct-open, zero-build artifact;
the worker graph and its browser probes require a served origin. The graph has **seven**
independently valuable DOM-free components plus the privileged DOM owner, with evidence in the
`PDProjects/Cairn/Architecture/Phase*Evidence.md` series.

## Start here

| Artifact | Purpose | Update rule |
| --- | --- | --- |
| [Cairn app changelog](cairn-app-changelog.md) | Newest-first development record, verification evidence, current state, plans, and superseded attempts | Update after every implementation session |
| [Capability catalog](capabilities.md) | Inventory of every visible control and behavior, each marked `UI POC`, `Working`, `Specified`, or `Deferred` | Update whenever a control, behavior, or its status changes |
| [Roadmap](<../../../Users/dktho/OneDrive/PDProjects/Cairn/ROADMAP.md>) | Feature scope, status, and the **Decisions resolved** register | Add to `Completed` when work lands; add a `Decisions resolved` row whenever direction is settled |
| [Pending decisions](<../../../Users/dktho/OneDrive/PDProjects/Cairn/DECISIONS-PENDING.md>) | Queue of deferred choices, each with a safe default and a concrete decision trigger | Add before an unresolved choice enters implementation; resolve when its trigger is reached |
| [POC v1 snapshot notes](<../../../Users/dktho/OneDrive/PDProjects/Cairn/docs/poc-v1-snapshot-notes.md>) | The narrative rendered into the frozen baseline's `SNAPSHOT.md`: what it proves, what it does not, and what was left open | Static for v1 — write a new file for the next snapshot rather than editing this one |
| [SaySlate design baseline](<../../../Users/dktho/OneDrive/PDProjects/Cairn/docs/investigations/sayslate-design-baseline.md>) | Research artifact: what the SaySlate changelog establishes about the target design, with citations | Static — supersede with a new investigation rather than editing |

## Artifact ownership

- **Canonical project memory:** this directory, `C:\dustin-thomason\docs\cairn`.
- **Live implementation:** `C:\Users\dktho\OneDrive\PDProjects\Cairn`.
- **Code-adjacent documents:** the live repository's `ROADMAP.md` and `DECISIONS-PENDING.md`.
  These stay beside the code because they govern and gate implementation — `DECISIONS-PENDING.md`
  in particular exists so implementation cannot bypass a deferred choice.
- **Repository pointer:** the live repository's `DOCS.md` directs future contributors back here.
- **Immutable comparison baseline:** `C:\Users\dktho\OneDrive\PDProjects\Cairn-POC-v1-2026-08-20`,
  its ZIP archive, and the ZIP's SHA-256 sidecar. Created 2026-08-20 by
  `scripts/new-poc-snapshot.ps1`; 28 of 28 files verify with `sha256sum -c`. This is the
  boundary the POC phase ended at — architecture work continues in the live repository.

This separation avoids maintaining two competing changelogs. Scope, gates, and open choices
stay inspectable beside the code; development history, capability inventory, and decision
memory are authoritative here.

## Maintenance rules

1. Prepend a UTC-dated entry to the changelog after every implementation session.
2. Record the exact verification command, its scope, and its result. Never write "tests passed."
3. Refresh **Current state** whenever behavior or the next implementation boundary changes.
4. Update the capability catalog when a control, behavior, status, or limitation changes.
   A control moving from `UI POC` to `Working` is a status change and must be recorded.
5. Record decisions explicitly. Never silently rewrite a prior decision; mark it superseded and
   link its replacement.
6. Record failed attempts **as failures.** A retired approach stays recorded as retired rather
   than being quietly dropped or rewritten as a success.
7. Track every deferred library, adapter, storage choice, or threshold in `DECISIONS-PENDING.md`
   with a safe default and a concrete decision trigger.
8. Once the POC v1 snapshot exists, keep it immutable so later builds can be compared with the
   established baseline.

## Status vocabulary

Used consistently across all artifacts in this directory.

| Term | Meaning |
| --- | --- |
| `Working` | Implemented and verified against a real check |
| `UI POC` | Implemented in the browser, but behavior is simulated or in-memory only |
| `Specified` | Documented or styled, but not connected end to end |
| `Deferred` | Deliberately reserved for a later slice |
| `Blocked` | Attempted, prevented by a named dependency |
| `Pending` | Ready to evaluate, not yet evaluated |
| `N/A` | Does not apply, no action required |

`Blocked` and `N/A` are not interchangeable. `N/A` means the trigger was absent; `Blocked`
means the trigger was present and the action did not complete.
