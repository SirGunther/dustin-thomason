# Argus App Changelog

## Purpose

This is the canonical development record for the Argus Active Voice Assistant POC and its evolution into a product implementation. It captures user-visible changes, architectural boundaries, verification evidence, plans, superseded attempts, and the definitive current state.

## Scope

Personal-project changelog for the Argus browser UI proof, executable Node architecture proof, contract and wiring governance, session/storage work, desktop integration, and related product decisions.

## Session log (newest first)

### 2026-08-12T18:49:37Z — Argus

- **Summary:** Accepted and documented the polyglot/container-capable runtime direction in a root-level architectural strategy. The artifact distinguishes the language-neutral contract boundary from the current Node-only launcher, defines trusted Node/native/container provider shapes, preserves default-deny inbound/outbound authority, establishes container and transport constraints, and sets measurable proof criteria before Argus may claim executable polyglot support.
- **Plan used:** Verify current manifest/orchestrator limitations; create one prominent future-agent reference; link it from the root README and component guide; add explicit roadmap work under supervision and permissions/packaging; record the accepted direction without claiming implementation.
- **Files/Areas:** `POLYGLOT-RUNTIME-STRATEGY.md`; `README.md`; `Architecture/ComponentAuthoring.md`; `TODO.md`; canonical `product-and-layout-decisions.md` and this changelog.
- **User-visible impact:** No application behavior changed. Contributors now have an explicit invariant that component language and packaging may vary while contracts, declared wires, control paths, permissions, failure semantics, and replacement evidence remain mandatory.
- **Tests run:**

| Gate | Command | Scope | Result | Exception / risk |
| --- | --- | --- | --- | --- |
| documentation links | PowerShell Markdown-link resolver over the staged root strategy, README, and component guide | New navigation and relative references | pass — all links resolve | Directional manifest examples are intentionally non-executable |
| full regression | `npm.cmd test` | Existing contract governance, compatibility, isolated services, wiring, failure/completion, and replacement behavior | pass — 29 tests, 0 failures | No polyglot launcher behavior exists yet, so no cross-runtime test can honestly run |
- **Tests added/updated:** None; this session documents and schedules architectural direction without changing executable behavior.
- **Regression impact:** The current service-manifest schema remains Node-only and the orchestrator still launches `process.execPath`. Roadmap additions are unchecked deliberately. Existing contract governance and graph behavior are unchanged.
- **API docs:** Not relevant — no HTTP/Swagger surface; the artifact governs process/runtime boundaries.
- **Conflicts / exceptions:** Polyglot support is not marked implemented. The required claim remains: “polyglot-ready by contract direction, Node-only by executable launcher” until native and OCI conformance proofs pass.
- **Tooling gates:** Documentation validation and the existing full Node test suite are the applicable gates; no runtime code, dependency, generated contract reference, or browser UI changed.

### 2026-08-12T18:38:51Z — Argus

- **Summary:** Completed Architecture Phase 1 — Contract Governance. The catalog now governs semantic compatibility, plane identity, ownership, schema, payload limits, and message-specific history for all seven contracts. Replaced the proof-only schema subset with Ajv at the runtime boundary, added generated contract documentation and drift checks, retained/replayed 1.0.0 fixtures through current 1.1.0 consumers, and standardized the canonical `service.failure` outcome.
- **Plan used:** Implement all eight Phase 1 checkboxes as executable policy; retain isolated-service and interchangeable-extractor behavior; add happy/failure/edge/compatibility coverage; publish only after the contract checker, generated-doc check, demos, audit, and full regression suite passed.
- **Files/Areas:** `Architecture/ContractGovernance.md`; `contracts/catalog.json`, envelope/failure schemas, `baselines/`, `history/`, and generated reference; `runtime/contract-governance.mjs`, `contract-registry.mjs`, `orchestrator.mjs`; all five service producers; governance scripts; compatibility fixtures/tests; `package.json`, lockfile, README, and TODO.
- **User-visible impact:** The browser interface is unchanged. Architecture contributors now have enforceable rules for contract evolution and a generated readable inventory. Messages with incompatible versions, wrong planes, invalid schemas, or oversized payloads are rejected before routing; failures expose stable safe codes/categories rather than free-form types.
- **Tests run:**

| Gate | Command | Scope | Result | Exception / risk |
| --- | --- | --- | --- | --- |
| governance integrity | `npm.cmd run contracts:check` | Catalog metadata, histories, schemas, baseline evolution, and plane/version rules for seven messages | pass | — |
| generated-doc drift | `npm.cmd run contracts:docs:check` | Generated human-readable contract reference | pass — current | — |
| full regression | `npm.cmd test` | Contract governance, 1.0 fixture replay through 1.1 consumers, payload limits, canonical failures, isolated services, wiring, planes, completion, and extractor replacement | pass — 29 tests, 0 failures | — |
| concise graph | `npm.cmd run demo` | Current 1.1 concise extractor graph | pass — stored domain result and explicit workflow completion | — |
| alternate graph | `npm.cmd run demo:alternate` | Current 1.1 passthrough extractor graph | pass — stored domain result and explicit workflow completion | — |
| dependency audit | `npm.cmd audit --audit-level=high` | Lockfile dependency tree after adding Ajv | pass — 0 vulnerabilities | Requires registry access |

- **Tests added/updated:** Added `tests/contract-governance.test.mjs` plus one 1.0.0 fixture per message. Coverage includes governance completeness, compatible/forward/major versions, plane-breaking enforcement, schema keywords, namespaced extensions, multibyte payload sizing, fixture replay through current isolated consumers, and safe canonical failure shape. Updated the existing supervisor integration assertion for the stable error code.
- **Regression impact:** Existing default-deny wiring and service isolation remain unchanged. Both extractor implementations still occupy the same graph position and complete. Envelope versions are now semver strings (`1.1.0`), so pre-governance integer-version messages are intentionally rejected; governed backward compatibility begins with retained 1.0.0 fixtures.
- **API docs:** Not relevant — checked repository surfaces; Argus exposes NDJSON process contracts, not HTTP routes or Swagger/OpenAPI. Generated process-contract documentation is current.
- **Conflicts / exceptions:** The first PowerShell invocation of `npm` was blocked by local execution policy (`npm.ps1`); the Windows `npm.cmd` entrypoint ran the same scripts successfully. An initial 27/28 run exposed the expected old error-type assertion, which was updated to the canonical stable code; final suite is fully green. Transport line-size bounding remains a Phase 2 supervision concern; Phase 1 enforces the required payload limit after JSON parsing and before routing.
- **Tooling gates:** Package scripts now include tests, governance integrity, documentation generation, and drift detection. No lint or typecheck script exists. Audit, all defined contract gates, both demos, and the full test suite passed.

### 2026-08-12T18:13:09Z — Argus

- **Summary:** Established `C:\dustin-thomason\docs\Argus` as the canonical project-memory location and created an indexed documentation set: this changelog, a comprehensive capability/control inventory, and a product/layout decision register. Added a short `DOCS.md` pointer to the live Argus repository so contributors reach the canonical record without creating a duplicate changelog.
- **Plan used:** Inspect the agents changelog rules and existing personal-project examples; inventory the live UI, architecture, contracts, services, wiring, tests, backlog, and immutable POC archive; create canonical documents; verify links and rerun the architecture suite; record the evidence here.
- **Files/Areas:** `C:\dustin-thomason\docs\Argus\README.md`, `argus-app-changelog.md`, `features-and-capabilities.md`, `product-and-layout-decisions.md`; `C:\Users\dktho\OneDrive\PDProjects\Argus\DOCS.md`.
- **User-visible impact:** The working application is unchanged. Future development now has one discoverable source for what Argus currently does, what every visible control means, which features are simulated or deferred, why layout/product decisions exist, and how each session was verified.
- **Tests run:**

| Gate | Command | Scope | Result | Exception / risk |
| --- | --- | --- | --- | --- |
| documentation links | PowerShell local Markdown-link resolver over `.argus-docs-stage\*.md` | Relative links across the four canonical documents | pass — all relative links resolve | Absolute artifact paths were separately confirmed to exist; future paths cannot be predicted |
| architecture regression | `node --test tests/service-contract.test.mjs tests/wiring.test.mjs tests/integration.test.mjs` | Contracts, isolated services, two-plane wiring, failure/completion routing, and extractor replaceability | pass — 20 tests, 0 failures | Browser visuals were not changed; no additional visual regression pass was required |
- **Tests added/updated:** None; this session changes documentation only.
- **Regression impact:** No runtime, contract, schema, service, wiring, UI, or archived POC files were changed. The live repository receives only a documentation pointer.
- **API docs:** Not applicable; Argus has no HTTP/OpenAPI surface in the current proof.
- **Conflicts / exceptions:** Code-adjacent architecture and schema specifications remain in the implementation repository because they define executable behavior. Canonical development memory and product documentation live in `C:\dustin-thomason\docs\Argus`; the repository pointer prevents competing authoritative copies.
- **Tooling gates:** `package.json` defines only the test and two demo scripts; no repository lint, typecheck, audit, or documentation-generator gates exist. The dependency-free test command above is the applicable regression gate. No HTTP API exists, so Swagger/OpenAPI drift verification is not applicable.

## Current state

Argus has two complementary POC layers:

1. A zero-build browser UI demonstrates the desktop interaction model: capture states, raw transcript and neutral logged-item panes, edits/autosave, selection and copying, independent live scrolling, explicit source ranges, top-center notifications, session details, and deliberate finalization. Audio, speech recognition, model calls, filesystem persistence, and OS folder integration are simulated or deferred.
2. A Node 22+ architecture proof executes four isolated service processes in an explicit graph. Versioned contracts, default-deny domain/control wires, visible runtime pseudo-components, deterministic extractor replacement, structured traces, explicit failure routing, and explicit workflow completion are covered by 29 automated tests. Ajv is the single maintained runtime dependency and compiles the JSON Schemas at the routing boundary.

The initial architectural ambiguity around hidden startup, supervision, result, and completion authority has been resolved: these capabilities occupy typed control/domain wires, while the runtime kernel retains only a finite documented set of process-hosting and validation mechanics.

The live workspace is `C:\Users\dktho\OneDrive\PDProjects\Argus`. The immutable comparison baseline is `Argus-POC-v1-2026-08-12` beside the live workspace, with a ZIP and SHA-256 sidecar. Canonical project memory is this `C:\dustin-thomason\docs\Argus` directory.

Contract Governance Phase 1 is complete: current contracts are version 1.1.0, every message has an owner/history/limit, 1.0.0 fixtures prove backward-compatible replay, plane moves require a major version, and categorized failures plus generated documentation are enforced. Phase 2 in the architecture backlog is runtime supervision. The first recommended product vertical after the governance/runtime foundation remains session state plus temporary transcript persistence because it exercises ownership, Stop/Resume, idempotency, and crash recovery without requiring audio hardware or a model provider.

Polyglot/container-capable execution is now an accepted architectural invariant. The current executable launcher remains Node-only; future Node/native/OCI providers must preserve explicit contracts, wires, lifecycle/supervision, permissions, and shared replacement evidence. `POLYGLOT-RUNTIME-STRATEGY.md` is the governing code-adjacent direction artifact.

## Plans

- [2026-08-12] Establish canonical Argus changelog, feature catalog, decision register, docs index, and repository pointer. Status: implemented.
- [2026-08-12] Preserve the completed POC as an immutable folder, ZIP, and SHA-256 comparison baseline. Status: implemented.
- [2026-08-12] Make domain/control planes, runtime pseudo-components, and kernel authority explicit in the executable proof. Status: implemented.
- [2026-08-11] Separate neutral logged-item extraction from optional classification and expose transcript provenance. Status: implemented in UI/architecture direction; model-backed enrichment remains deferred.
- [2026-08-11] Build the first Active Assistant look-and-feel prototype in plain HTML/CSS/JavaScript. Status: implemented.
- [2026-08-12] Contract governance: semantic compatibility, plane-breaking enforcement, ownership/history, compatibility replay, Ajv boundary validation, generated documentation, payload limits, and canonical failure outcomes. Status: implemented.
- Runtime supervision. Status: next architecture phase.
- [2026-08-12] Polyglot runtime strategy: trusted launcher-provider boundary, default-deny container capabilities, shared cross-runtime conformance, and proof criteria. Status: direction accepted; implementation scheduled across runtime supervision and permissions/packaging.
- Session state and temporary transcript persistence. Status: recommended implementation slice after governance.
- Real audio → transcription → context-window → logged-item integration. Status: deferred until supporting contracts and persistence are proven.

## Attempt history

| Date | Approach | Outcome | Learning retained |
| --- | --- | --- | --- |
| 2026-08-11 | Treat task/note/observation/idea as the primary identity of each extracted row. | Superseded. | Extraction and classification are different responsibilities; classification must remain an optional, reviewable suggestion. |
| 2026-08-11 | Place notifications adjacent to growing live content. | Superseded. | Top-center header negative space preserves both panes' live working area. |
| 2026-08-12 | Allow the process host to implicitly control startup, failures, terminal results, and completion. | Superseded by the explicit two-plane proof. | Operational coordination is part of the architecture and must be visible, typed, wired, and removable. |
| 2026-08-12 | Represent the session-folder action in browser-only HTML. | Retained as an honest interaction simulation. | The OS operation belongs to a future narrowly authorized desktop capability service. |

## Historical milestones

These date-level milestones reconstruct the work completed before this canonical changelog was established; exact UTC session timestamps were not retroactively invented.

| Date | Milestone | Result |
| --- | --- | --- |
| 2026-08-11 | Initial UI POC | Desktop-style two-pane interface with recording states, live sample data, editing, autosave, selection, copying, scrolling, session drawer, and finalization modal. |
| 2026-08-11 | Logged-item/provenance revision | Removed authoritative live classification, added source context ranges and transcript reveal, and moved toasts to top-center negative space. |
| 2026-08-12 | Executable atomic-architecture proof | Added contracts, manifests, isolated services, graph wiring, runtime, deterministic replacement, and automated contract/wiring/integration coverage. |
| 2026-08-12 | Explicit control-plane resolution | Made lifecycle, supervision, result collection, and completion visible graph participants; documented the finite runtime kernel authority. |
| 2026-08-12 | POC v1 preservation | Created an immutable comparison folder, ZIP, and SHA-256 sidecar without changing the live project. |
