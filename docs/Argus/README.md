# Argus Documentation

This directory is the canonical project record for Argus. It preserves what the project can do, why its product and layout decisions were made, how the architecture has evolved, and what was verified in each development session.

## Start here

| Artifact | Purpose | Update rule |
| --- | --- | --- |
| [Argus app changelog](argus-app-changelog.md) | Newest-first development record, verification evidence, current state, plans, and superseded attempts | Update after every implementation session |
| [Feature and capability catalog](features-and-capabilities.md) | Complete inventory of visible controls, behaviors, architecture proof capabilities, limitations, and future work | Update whenever a capability or control changes |
| [Product and layout decisions](product-and-layout-decisions.md) | Decision register for product behavior and interface layout, including rationale and status | Add or supersede a decision whenever direction changes |

## Artifact ownership

- **Canonical project memory:** this directory, `C:\dustin-thomason\docs\Argus`.
- **Live implementation:** `C:\Users\dktho\OneDrive\PDProjects\Argus`.
- **Code-adjacent technical specifications:** the live repository's `Architecture`, `contracts`, `services`, `runtime`, `wiring`, and `tests` directories. These remain beside the code because they define or verify executable boundaries.
- **Immutable comparison baseline:** `C:\Users\dktho\OneDrive\PDProjects\Argus-POC-v1-2026-08-12`, its ZIP archive, and the ZIP's SHA-256 sidecar.
- **Repository pointer:** the live repository's `DOCS.md` directs future contributors back to this canonical location.

This separation avoids maintaining two competing changelogs. Implementation-bound schemas and architecture rules stay inspectable beside the code; development history, feature inventory, and decision memory are authoritative here.

## Maintenance rules

1. Prepend a UTC-dated entry to the changelog after every implementation session.
2. Record exact verification commands, their scope, and their result.
3. Refresh **Current state** whenever behavior, architecture, or the next implementation boundary changes.
4. Update the capability catalog when a button, state, service, contract, limitation, or deferred feature changes.
5. Record decisions explicitly. Never silently rewrite a prior decision; mark it superseded and link its replacement.
6. Keep the POC v1 snapshot immutable so later builds can be compared with the established baseline.

