# Argus Documentation

This directory is the canonical project record for Argus. It preserves what the project can do, why its product and layout decisions were made, how the architecture has evolved, and what was verified in each development session.

## Start here

| Artifact | Purpose | Update rule |
| --- | --- | --- |
| [Argus app changelog](argus-app-changelog.md) | Newest-first development record, verification evidence, current state, plans, and superseded attempts | Update after every implementation session |
| [Feature and capability catalog](features-and-capabilities.md) | Complete inventory of visible controls, behaviors, architecture proof capabilities, limitations, and future work | Update whenever a capability or control changes |
| [Product and layout decisions](product-and-layout-decisions.md) | Decision register for product behavior and interface layout, including rationale and status | Add or supersede a decision whenever direction changes |
| [Pending decisions](<../../../Users/dktho/OneDrive/PDProjects/Argus/PENDING-DECISIONS.md>) | Central queue and evidence triggers for unresolved packages, SDKs, providers, transport, storage, thresholds, and platform choices | Add before an unresolved choice enters implementation; resolve when its trigger is reached |
| [Phase 4B transcript contracts and ownership](<../../../Users/dktho/OneDrive/PDProjects/Argus/Architecture/TranscriptContractsAndOwnership.md>) | Governed live-hypothesis, correction, finalization, revision, and history ownership model | Update when a Phase 4 transcript boundary or owner changes |
| [Phase 4C executable transcript evidence](<../../../Users/dktho/OneDrive/PDProjects/Argus/Architecture/TranscriptPipelinePhase4CEvidence.md>) | Independent fake components, working-document correction proof, revision history, and executable evidence | Update when Phase 4C behavior or evidence changes |
| [Phase 4D context-selection evidence](<../../../Users/dktho/OneDrive/PDProjects/Argus/Architecture/TranscriptContextPhase4DEvidence.md>) | Policy-driven triggers, singular source ownership, transcription scheduling, partial isolation, and dual replacement proof | Update when Phase 4D behavior or evidence changes |
| [Phase 4E behavior/recovery evidence](<../../../Users/dktho/OneDrive/PDProjects/Argus/Architecture/TranscriptBehaviorPhase4EEvidence.md>) | Existing behavior mapping, long-monologue bounded surfaces, replay semantics, Stop/Resume-compatible ownership, and the remaining active-history limitation | Update when a Phase 4E claim or limitation changes |
| [Phase 4F transport evidence](<../../../Users/dktho/OneDrive/PDProjects/Argus/Architecture/TranscriptTransportPhase4FEvidence.md>) | Deterministic inline-base64 PCM transport matrix, queue/latency/RSS evidence, and the oversized rejection proof | Update when POC transport evidence changes |
| [Phase 5A logged-item evidence](<../../../Users/dktho/OneDrive/PDProjects/Argus/Architecture/LoggedItemPipelinePhase5AEvidence.md>) | Deterministic logged-item identity, active/history ownership, user-authoritative proposals, replay/conflict/revision proof, and evidence observation | Update when Phase 5A behavior changes |
| [Phase 5B local-model evidence](<../../../Users/dktho/OneDrive/PDProjects/Argus/Architecture/LoggedItemModelPhase5BEvidence.md>) | Provider-neutral local HTTP extraction, shared model lane, strict bounded outputs, explicit failure/retry, and optional revision-bound classification | Update when Phase 5B behavior changes |
| [Phase 6 session/storage evidence](<../../../Users/dktho/OneDrive/PDProjects/Argus/Architecture/SessionStoragePhase6Evidence.md>) | Governed Record/Stop/Resume/Close lifecycle, root-scoped filesystem storage, close recovery, folder locator, and bounded active-history proof | Update when session lifecycle or storage evidence changes |
| [Phase 7 UI boundary evidence](<../../../Users/dktho/OneDrive/PDProjects/Argus/Architecture/UiBoundaryPhase7Evidence.md>) | Versioned browser projections, loopback bridge, owner-routed edits, capability adapters, UI-owned state, provenance, and degraded behavior | Update when browser-boundary behavior or evidence changes |
| [Phase 7 user validation review](<../../../Users/dktho/OneDrive/PDProjects/Argus/docs/review/v0.1.0-phase-7-browser-poc-validation-review.md>) | User-owned D1–D6 validation status, corrective implementation checklist, notes, and revalidation evidence | Update only from observed user or executable evidence; preserve user-entered notes |

## Artifact ownership

- **Canonical project memory:** this directory, `C:\dustin-thomason\docs\Argus`.
- **Live implementation:** `C:\Users\dktho\OneDrive\PDProjects\Argus`.
- **Code-adjacent technical specifications:** the live repository's `Architecture`, `contracts`, `services`, `runtime`, `wiring`, and `tests` directories. These remain beside the code because they define or verify executable boundaries.
- **Immutable comparison baseline:** `C:\Users\dktho\OneDrive\PDProjects\Argus-POC-v1-2026-08-12`, its ZIP archive, and the ZIP's SHA-256 sidecar.
- **Repository pointer:** the live repository's `DOCS.md` directs future contributors back to this canonical location.
- **Pending-decision authority:** the live repository's root `PENDING-DECISIONS.md`; it stays beside the executable backlog so implementation cannot bypass a deferred choice.

This separation avoids maintaining two competing changelogs. Implementation-bound schemas and architecture rules stay inspectable beside the code; development history, feature inventory, and decision memory are authoritative here.

## Maintenance rules

1. Prepend a UTC-dated entry to the changelog after every implementation session.
2. Record exact verification commands, their scope, and their result.
3. Refresh **Current state** whenever behavior, architecture, or the next implementation boundary changes.
4. Update the capability catalog when a button, state, service, contract, limitation, or deferred feature changes.
5. Record decisions explicitly. Never silently rewrite a prior decision; mark it superseded and link its replacement.
6. Keep the POC v1 snapshot immutable so later builds can be compared with the established baseline.
7. Track every deferred package, SDK, provider, transport, storage, threshold, or platform selection in `PENDING-DECISIONS.md` with a safe default and a concrete decision trigger.
