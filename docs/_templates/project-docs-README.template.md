# {{PROJECT}} Documentation

This directory is the canonical project record for {{PROJECT}}. It preserves what the
project can do, what was decided and why, and what was verified in each development
session.

_One-line description of {{PROJECT}}._

## Start here

| Artifact | Purpose | Update rule |
| --- | --- | --- |
| [{{PROJECT}} app changelog]({{SLUG}}-app-changelog.md) | Newest-first development record, verification evidence, current state, plans, and superseded attempts | Update after every implementation session |
| [Capability catalog](capabilities.md) | Inventory of every visible control and behavior, each marked `Working`, `UI POC`, `Specified`, or `Deferred` | Update whenever a control, behavior, or its status changes |
| [Roadmap](<{{REPO_PATH}}\ROADMAP.md>) | Feature scope, status, and the **Decisions resolved** register | Add to `Completed` when work lands; add a `Decisions resolved` row whenever direction is settled |
| [Pending decisions](<{{REPO_PATH}}\DECISIONS-PENDING.md>) | Queue of deferred choices, each with a safe default and a concrete decision trigger | Add before an unresolved choice enters implementation; resolve when its trigger is reached |

## Artifact ownership

- **Canonical project memory:** this directory, `{{DOCS_PATH}}`.
- **Live implementation:** `{{REPO_PATH}}`.
- **Code-adjacent documents:** the live repository's `ROADMAP.md` and `DECISIONS-PENDING.md`.
  These stay beside the code because they govern and gate implementation —
  `DECISIONS-PENDING.md` in particular exists so implementation cannot bypass a deferred
  choice.
- **Repository pointer:** the live repository's `DOCS.md` directs future contributors back here.
- **Immutable comparison baseline:** _created by `new-poc-snapshot.ps1` when the POC phase
  ends. Record the path here once it exists._

This separation avoids maintaining two competing changelogs. Scope, gates, and open choices
stay inspectable beside the code; development history, capability inventory, and decision
memory are authoritative here.

## Maintenance rules

1. Prepend a UTC-dated entry to the changelog after every implementation session.
2. Record the exact verification command, its scope, and its result. Never write "tests passed."
3. Refresh **Current state** whenever behavior or the next implementation boundary changes.
4. Update the capability catalog when a control, behavior, status, or limitation changes.
   A control moving from `UI POC` to `Working` is a status change and must be recorded.
5. Record decisions explicitly. Never silently rewrite a prior decision; mark it superseded
   and link its replacement.
6. Record failed attempts **as failures.** A retired approach stays recorded as retired
   rather than being quietly dropped or rewritten as a success.
7. Track every deferred library, adapter, storage choice, or threshold in
   `DECISIONS-PENDING.md` with a safe default and a concrete decision trigger.
8. Once a snapshot exists, keep it immutable so later builds can be compared with the
   established baseline.

## Status vocabulary

Used consistently across all artifacts in this directory.

| Term | Meaning |
| --- | --- |
| `Working` | Implemented and verified against a real check |
| `UI POC` | Implemented, but behavior is simulated, in-memory, or stubbed |
| `Specified` | Documented or styled, but not connected end to end |
| `Deferred` | Deliberately reserved for a later slice |
| `Blocked` | Attempted, prevented by a named dependency |
| `Pending` | Ready to evaluate, not yet evaluated |
| `N/A` | Does not apply, no action required |

`Blocked` and `N/A` are not interchangeable. `N/A` means the trigger was absent; `Blocked`
means the trigger was present and the action did not complete.
