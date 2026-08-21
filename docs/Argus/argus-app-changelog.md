# Argus App Changelog

## Purpose

This is the canonical development record for the Argus Active Voice Assistant POC and its evolution into a product implementation. It captures user-visible changes, architectural boundaries, verification evidence, plans, superseded attempts, and the definitive current state.

## Scope

Personal-project changelog for the Argus browser UI proof, executable Node architecture proof, contract and wiring governance, session/storage work, desktop integration, and related product decisions.

## Session log (newest first)

### 2026-08-21 — Argus

- **Summary:** Corrected the shared Phase 7 browser startup path discovered during hands-on validation. Registered the missing `includeTimestamps` element, added a named required-element guard and permanent selector-drift regression, corrected logged-item copy command mapping, exposed explicit bridge connection state in the existing footer status treatment, and clarified session Stop versus terminal `Ctrl+C`.
- **Browser evidence:** A transient Playwright 1.62.1 run against installed Google Chrome passed 1/1 in 11.7 seconds with zero page errors. It exercised bootstrap/SSE, Record and deterministic live projections, transcript/logged-item edits, exact provenance, selection, timestamp-aware copy through a fake capability, Stop preservation, Resume, Close, top-positioned toasts, and bridge disconnect feedback. Playwright was not added as a dependency.
- **Verification:** Focused UI tests passed 7/7; the expanded `demo:ui:smoke` passed 24 bootstrap projections plus lifecycle/edit/copy flow; the complete regression passed 114/114; contract governance remained valid for 53 messages; generated contract documentation remained current.
- **Validation status:** The corrective implementation checklist is complete except for user revalidation. D1–D5 and the user's notes remain unchanged; Phase 8 remains paused until that hands-on revalidation is recorded.
- **Scope:** Focused Phase 7 correction only. No microphone/STT/model, desktop shell, Playwright dependency, Phase 8 permissions, or architecture redesign was added.

### 2026-08-21 — Argus

- **Summary:** Created the version-specific Phase 7 browser POC [user validation review](../../../Users/dktho/OneDrive/PDProjects/Argus/docs/review/v0.1.0-phase-7-browser-poc-validation-review.md) for Argus v0.1.0.
- **Validation status:** Empty-state layout and visual clarity passed. Hands-on review then found no observable Record, transcript/logged-item, editing/copy, or session-command response, so D2–D5 failed and D1 remains pending clarification. The linked review now contains the corrective checklist; Phase 8 should wait for revalidation.
- **Implementation impact:** Documentation only. No application behavior, contract, wiring, package, or test result changed.

### 2026-08-19 — Argus

- **Summary:** Implemented Phase 7 UI Boundary as one cohesive batch. Added six governed browser-facing contracts, a loopback-only Node HTTP/SSE bridge, projection validation, closed UI command validation, owner-routed optimistic transcript/logged-item edits, deterministic clipboard/folder capability adapters, UI-owned selection/scroll state, exact source-range rendering, and independent degraded states.
- **User-visible impact:** The existing HTML look and feel remains recognizable, but rows now arrive from explicit bridge projection events. Provisional transcript rows are read-only, finalized edits are owner-accepted before becoming authoritative, copy/open-folder controls report capability outcomes, and service/capability status is visible per boundary.
- **Files/areas:** `ui/bridge.mjs`, `ui/bridge-contracts.mjs`, `ui/command-router.mjs`, `ui/demo-state.mjs`, `ui/platform-capabilities.mjs`, `ui/ui-state.mjs`, `app.js`, `index.html`, `styles.css`, six UI contract schemas/history/fixtures, generated contract reference, Phase 7 evidence, ADR-016, TODO, pending decisions, README, and canonical capability records.
- **Verification:** `node --test tests/ui-boundary.test.mjs` passed 6/6; `npm.cmd run demo:ui:smoke` passed with 24 validated bootstrap projections; `npm.cmd test` passed 113/113; `npm.cmd run contracts:check` passed for 53 governed messages; `npm.cmd run contracts:docs:check` reported current generated documentation.
- **Intentional limits:** The bridge is local and deterministic. No Electron, Tauri, remote hosting, authentication, framework, database, real microphone/STT/model integration, broad permissions, or observability was added. `APP-001` and `UI-001` remain unresolved.

### 2026-08-19 — Argus

- **Summary:** Implemented Phase 6 Sessions and Storage as one complete batch. Added governed versioned Record/Stop/Resume/Close and folder-locator contracts, a root-scoped replaceable filesystem storage boundary, durable active transcript/logged-item snapshots, append-only NDJSON histories, idempotent close evidence, bounded active revision caching, and deterministic crash recovery before and after every close-finalization phase.
- **Plan used:** Preserve default-deny ownership, at-least-once replay, stable session/revision identities, ephemeral raw audio, and the existing Phase 4–5 message boundaries. Use Node built-ins only for the POC and keep JSON/NDJSON behind service/storage owners so an embedded database remains a later replacement option.
- **Files/Areas:** Session metadata and lifecycle contracts/history/fixtures/catalog 1.8.0/generated reference; `runtime/session-storage.mjs`; `runtime/session-lifecycle.mjs`; session lifecycle controller; session-folder locator; durable-capable transcript/logged-item owners; Phase 6 and completed Phase 4E tests; ADR-015; Phase 6 evidence; TODO/pending decisions; and canonical capability/index records.
- **User-visible impact:** Browser UI remains unchanged. The executable architecture now has a governed local session lifecycle and storage proof; browser/desktop folder opening and UI integration remain separate boundaries.
- **Tests run:**

| Gate | Command | Scope | Result | Exception / risk |
| --- | --- | --- | --- | --- |
| focused Phase 6 | `node --test tests/phase6-session-storage.test.mjs` | Contracts, lifecycle, Stop preservation, Close idempotency, locator, every recovery phase, bounded cache, and restart | pass — 6 tests, 0 failures | Local temporary directories only. |
| completed Phase 4E proof | `node --test tests/phase4e-behavior-recovery.test.mjs` | Long-monologue bounded active state/queues/latency, durable history, eviction/reload, replay, and Stop/Resume-compatible ownership | pass — 3 tests, 0 failures | Deterministic fixtures; no production thresholds claimed. |
| full regression | `npm.cmd test` | All repository tests | pass — 107 tests, 0 failures | — |
| contract governance | `npm.cmd run contracts:check` | Catalog 1.8.0, 47 governed messages, artifacts, schemas, histories, fixtures, owners, and limits | pass | — |
| generated reference | `npm.cmd run contracts:docs:check` | Generated contract documentation drift | pass after regeneration | — |

- **Storage/recovery evidence:** JSON metadata/current projections use atomic temporary-file-and-rename replacement; permanent transcript/logged-item NDJSON entries are fingerprinted and idempotent; Stop preserves active state; Close blocks writes and recovers from both edges of all six finalization phases; sealed sessions do not reopen; evicted revisions reload and accept later revisions.
- **Phase 4E closure:** Complete. The long-monologue proof now demonstrates bounded active revision cache, bounded graph queues, maximum-latency closure, durable transcript/history preservation, and valid revision behavior after eviction/reload.
- **Conflicts / exceptions:** This is replaceable local POC storage, not production-grade/global durability. No database, storage SDK, backup, synchronization, encryption, migration, cloud storage, real microphone/STT, UI integration, Phase 7 work, or broad permission enforcement was added. The globally shared durable AI journal remains explicitly deferred.

### 2026-08-19 — Argus

- **Summary:** Completed Phase 5B.1 boundary hardening without expanding product scope. The model request/result protocol is now governed by versioned `ai.work-request@1.4.0` and `ai.work-completed@1.4.0` shapes with valid/invalid fixtures; sibling-service implementation imports are removed; endpoints are loopback-only HTTP; classification receives explicit transcript context; pending state is bounded and cleaned; purpose is bound to workload; and model configuration is manifest-allowlisted.
- **Plan used:** Correct only the Phase 5B boundaries identified in the focused review. Preserve deterministic fakes, the existing extraction/classification graph positions, concurrency-one priority behavior, and optional classification degradation. Defer the durable globally shared AI journal to integrated application/storage work coordinated with Phase 6.
- **Files/Areas:** Governed AI schemas/catalog history/generated reference/fixtures; shared model protocol; local extractor, model lane, classifier, manifests, Node provider environment filtering, explicit context wire, focused tests, Phase 5B evidence, TODO, pending decisions, README/DOCS, and canonical capability/changelog records. No new message type or dependency was added.
- **User-visible impact:** Browser UI is unchanged. No production provider/model, credentials, durable product storage, durable global AI journal, Phase 6 lifecycle, microphone, or real STT was started.
- **Tests run:**

| Gate | Command | Scope | Result | Exception / risk |
| --- | --- | --- | --- | --- |
| focused Phase 5B.1 | `node --test tests/phase5b-model-adapter.test.mjs` | Protocol fixtures, isolation, loopback config, explicit context, retry/failure, priority, configuration filtering, and pending capacity | pass — 14 tests, 0 failures | — |
| full regression | `npm.cmd test` | All repository tests | pass — 101 tests, 0 failures | — |
| governance integrity | `npm.cmd run contracts:check` | Catalog 1.7.0, 37 governed messages, schemas, histories, fixtures, owners, and limits | pass | — |
| generated-doc drift | `npm.cmd run contracts:docs:check` | Human-readable contract reference | pass — current | — |

- **Conflicts / exceptions:** `MOD-001` remains evidence-needed for a production local server/model. The Phase 5B model lane is graph-local with an in-memory journal; no cross-process global scheduler or durable global journal claim is made. Existing demos and measurement matrices were not rerun in this corrective batch per scope.
### 2026-08-19T16:00:00Z — Argus

- **Summary:** Completed Argus Phase 5B: a provider-neutral, environment-configured local HTTP model adapter now replaces the deterministic logged-item extractor through the existing `logged-item-extraction` scheduler workload. The adapter enforces exact finalized source/context, policy and instruction identity, bounded budgets, strict structured output, stable request identity, explicit retryable failures, and no guessed item on failure. Optional lowest-priority classification produces revision-bound suggestions without mutating active or permanent history.
- **Plan used:** Preserve Phase 5A ownership; add only the missing model request/result boundary and service graph wiring; use built-in HTTP and no provider SDK; retain deterministic fakes; prove replacement, exact retry, timeout/unavailable/malformed/invalid-output handling, and optional classification; stop before Phase 6, UI, production-provider selection, credentials, and durable storage.
- **Files/Areas:** `services/log-extractor-local-http`, `services/serial-ai-model-lane`, `services/logged-item-classification-suggester`, `wiring/demo.logged-item-model.json`, deterministic local endpoint helper, model demo script, focused Phase 5B tests, Phase 5B evidence, repository guidance, canonical feature catalog, and this changelog. No new governed messages were required; catalog 1.7.0 remains at 37 messages.
- **User-visible impact:** Browser UI is unchanged. The executable architecture now proves local model extraction and optional classification contracts while production model/server choice remains unresolved under `MOD-001`.
- **Tests run:**

| Gate | Command | Scope | Result | Exception / risk |
| --- | --- | --- | --- | --- |
| dependency audit | `npm.cmd audit --omit=dev` | Production dependency tree | pass — 0 vulnerabilities | — |
| full regression | `npm.cmd test` | All repository tests | pass — 96 tests, 0 failures | — |
| Phase 5B focus | `node --test tests/phase5b-model-adapter.test.mjs` | Model boundary, scheduler lane, failure/retry, replacement, and optional classification | pass — 9 tests, 0 failures | — |
| affected regression | `node --test tests/phase5a-logged-items.test.mjs tests/identity-ordering.test.mjs tests/contract-governance.test.mjs tests/wiring.test.mjs` | Phase 5A ownership, scheduler/identity, governance, and graph wiring | pass — 34 tests, 0 failures | — |
| governance integrity | `npm.cmd run contracts:check` | Catalog 1.7.0, schemas, histories, fixtures, owners, and limits | pass — 37 governed messages | — |
| generated-doc drift | `npm.cmd run contracts:docs:check` | Human-readable contract reference | pass — current | — |
| existing demos | `npm.cmd run demo`, `demo:alternate`, `demo:context`, `demo:logged-items` | Existing deterministic graphs | pass | Shared runtime/transport code was not changed; transcript/measurement/benchmark gates were not triggered. |
| Phase 5B demo | `npm.cmd run demo:logged-item-model` | Deterministic local HTTP extraction/classification graph | pass | Deterministic endpoint only; no production model selected. |

- **Conflicts / exceptions:** `MOD-001` remains evidence-needed for the local server/model and safe production defaults. The model lane is one shared scheduler process for this graph; the older standalone transcription gate remains a separate Phase 4 adapter graph, so no cross-process global-scheduler claim is made. Phase 6, browser UI integration, provider selection, credentials, packages, durable storage, microphone, and real STT were not started.
### 2026-08-19T15:38:51Z — Argus

- **Summary:** Verified the completed Phase 5A proof and authorized the bounded Phase 5B local-model-adapter/classification batch. The focused four-test suite and six-service logged-item graph reran successfully with zero rejections or dead letters.
- **Plan used:** Preserve the Phase 5A ownership graph; prove a provider-neutral environment-configured HTTP adapter against a deterministic local test endpoint; retain the offline fake; route extraction/classification through the existing scheduler priorities; stop before Phase 6 and UI integration.
- **Files/Areas:** `TODO.md` next-slice authorization and canonical Phase 5B plan status. No product code changed.
- **Tests run:** `node --test tests/phase5a-logged-items.test.mjs` passed 4/4; `npm.cmd run demo:logged-items` completed six services with zero rejections and zero dead letters.
- **Conflicts / exceptions:** The specific local model server/model remains unresolved under `MOD-001`; Phase 5B may use a deterministic local HTTP test endpoint but must not silently select a production runtime. Phase 6, UI integration, packaging, real microphone, and real STT remain out of scope.

### 2026-08-19T14:18:00Z — Argus

- **Summary:** Completed Argus Phase 5A: governed logged-item state and ownership. Reconciled the existing partial attempt, repaired deterministic replay identity and exact source provenance, completed separate active/history owners, added user-authoritative update proposals, wired the six-service Phase 5A graph, and added explicit evidence observation.
- **Plan used:** Preserve ADR-014 boundaries; keep concise and passthrough extractors deterministic and interchangeable; derive item identity from governed session/window input; scope emitted message identity to service instances; update retained contract fixtures and generated references; stop before Phase 5B and Phase 6.
- **Files/Areas:** Phase 5A extractors, active owner, permanent-history owner, producer-instance identity, retained fixtures, focused tests, logged-item graph, `Architecture/LoggedItemPipelinePhase5AEvidence.md`, TODO/README/DOCS, generated contract reference, and canonical feature/changelog/index records.
- **User-visible impact:** Browser UI is unchanged. The executable architecture now proves exact logged-item source provenance, stable context replay, identity conflicts, optimistic revisions, append-only revision receipts, separate authority, and explicit proposal acceptance without connecting a model or durable storage.
- **Tests run:**

| Gate | Command | Scope | Result | Exception / risk |
| --- | --- | --- | --- | --- |
| dependency audit | `npm.cmd audit --omit=dev` | Production dependency tree | pass — 0 vulnerabilities | No dependency files changed in this session. |
| full regression | `npm.cmd test` | All prior phases plus Phase 5A | pass — 87 tests, 0 failures | — |
| governance integrity | `npm.cmd run contracts:check` | Catalog 1.7.0, schemas, histories, retained fixtures, owners, and limits for 37 messages | pass | — |
| generated-doc drift | `npm.cmd run contracts:docs:check` | Human-readable contract reference | pass — current | — |
| concise graph | `npm.cmd run demo` | Existing deterministic concise extractor graph | pass | — |
| alternate graph | `npm.cmd run demo:alternate` | Existing deterministic passthrough extractor graph | pass | — |
| context graph | `npm.cmd run demo:context` | Existing finalized-context graph | pass | Shared runtime/transport code was not changed, so separate transcript/measurement/benchmark gates were not triggered. |
| logged-item graph | `npm.cmd run demo:logged-items` | Six-service Phase 5A ownership/evidence graph | pass | Six services ready and drained; zero rejections/dead letters. |

- **Regression repair:** The first final regression exposed an existing graph-instance identity collision after stable item identity was corrected. Producer-scoped output idempotency keys repaired the multi-instance isolation path without changing logical `item_id` or revision identity; the final 87-test run passed.
- **Conflicts / exceptions:** Phase 4E remains 7/8 proven because bounded finalized active history depends on Phase 6 storage/eviction. Phase 5B local model integration, environment model configuration, scheduler extraction wiring, classification, durable storage, session lifecycle, packaging, microphone, real STT, and UI integration were not started.

### 2026-08-18T20:47:56Z — Argus

- **Summary:** Repaired the Phase 4F canonical closeout record and split the authorized Phase 5 logged-item work into two bounded batches. Phase 5A now covers deterministic logged-item state/ownership; Phase 5B covers the configurable local model adapter and optional classification.
- **Plan used:** Keep the next-agent scope small, preserve the unfinished Phase 4E active-history bound for Phase 6, and record the user's model/state/failure defaults before implementation begins.
- **Files/Areas:** Canonical changelog/current state/plans; `TODO.md` Phase 5A/5B checklist; `PENDING-DECISIONS.md`; ADR-014; canonical AD-023.
- **User-visible impact:** None. This is governance and handoff preparation; no application behavior or browser UI changed.
- **Tests run:** Documentation-only change; Phase 4F's focused test and transport benchmark were rerun before this update and passed. No product code changed after the recorded 83-test Phase 4F gate.
- **Conflicts / exceptions:** Phase 4E remains 7/8 proven because bounded finalized active history depends on Phase 6 storage/eviction. Phase 5B, durable storage, packaging, and real microphone/STT work were not started.

### 2026-08-18T19:46:40Z — Argus

- **Summary:** Completed Phase 4F transport measurement and closeout. Added deterministic PCM16/16 kHz/mono 100/250/500 ms transport evidence, bounded-queue/registry measurement, and explicit oversized `audio.chunk` rejection without selecting a production transport or threshold.
- **Files/Areas:** `scripts/benchmark-audio-transport.mjs`; `tests/phase4f-transport.test.mjs`; `Architecture/TranscriptTransportPhase4FEvidence.md`; Phase 4F checklist, decision register, repository docs, and canonical catalog.
- **Tests run:** `npm.cmd audit --omit=dev`, full `npm.cmd test` (83 passing), contract governance/generated-doc checks, four graph demos, runtime scaling measurement, and the transport benchmark all passed.
- **Decisions / limitations:** AUD-003, TRN-001, and TRN-002 remain evidence-needed for real-device/provider/user-session data. TRN-003 remains deferred to Phase 6 storage/eviction. The Phase 4E active-history bound is unchanged. Phase 5 and packaging were not started.

### 2026-08-18T16:11:04Z — Argus

- **Summary:** Completed the smallest defensible Architecture Phase 4E behavioral/recovery slice. Seven of eight checklist claims now have direct evidence: existing Phase 4C/4D cases were mapped and strengthened, exact audio redelivery now crosses the transcription gate without caching PCM, replay remains idempotent through fake STT/active state/permanent history, and a same-process intake pause/resume preserves session, ordering, revision, and provenance state. The long-monologue proof covers size/latency closure, contiguous ranges, bounded context, and bounded queues, but the active owner's in-memory finalized-session history remains unbounded; that checkbox stays open rather than starting Phase 6 storage.
- **Plan used:** Reuse direct assertions for the first five claims; add only the missing post-edit provenance check; make the transcription gate re-handle duplicates while retaining only an output fingerprint; add deterministic long/replay/pause-resume cases; leave any guarantee requiring durable active-history eviction explicit and unchecked; update canonical memory after the full staged gates passed.
- **Files/Areas:** Service protocol idempotent output fingerprints; serial transcription gate duplicate handling and raw-audio journal guard; interactive process-test batches; `tests/phase4e-behavior-recovery.test.mjs`; Phase 4C assertion strengthening; Phase 4E evidence artifact; TODO, README, DOCS, pending decision TRN-003; canonical capability, decision, changelog, and index artifacts.
- **User-visible impact:** Browser UI is unchanged. The executable architecture now demonstrates exact-redelivery replay and Stop/Resume-compatible active ownership without adding lifecycle commands, raw-audio history, production persistence, or a real provider.
- **Tests run:**

| Gate | Command | Scope | Result | Exception / risk |
| --- | --- | --- | --- | --- |
| dependency audit | `npm.cmd audit --omit=dev` | Installed production dependency tree | pass — 0 vulnerabilities | Initial sandboxed audit could not reach the registry or write the npm cache log; the approved registry-backed rerun passed. |
| full regression and Phase 4E proof | `npm.cmd test` | All prior phases plus three new long/replay/pause-resume cases and strengthened Phase 4C assertions | pass — 81 tests, 0 failures | — |
| governance integrity | `npm.cmd run contracts:check` | Catalog 1.6.0, schemas, fixtures, owners, histories, and limits for 32 messages | pass | No contract change. |
| generated-doc drift | `npm.cmd run contracts:docs:check` | Human-readable contract reference | pass — current | — |
| concise graph | `npm.cmd run demo` | Existing concise extractor graph | pass | — |
| alternate graph | `npm.cmd run demo:alternate` | Existing passthrough extractor graph | pass | — |
| transcript graph | `npm.cmd run demo:transcript` | Phase 4C five-process working-document graph | pass | — |
| context graph | `npm.cmd run demo:context` | Phase 4D nine-process finalized-context graph | pass | — |
| scaling evidence | `npm.cmd run measure:runtime` | Existing 4/8/12 service-process measurement | pass — JSON metrics produced | POC evidence only; Phase 4F transport benchmark was not started. |
| documentation links | `powershell.exe -NoProfile -ExecutionPolicy Bypass -File 'C:\Users\dktho\OneDrive\SCRIPTS ALL SYSTEMS\To Do List\WorkLists\argus-phase4e-stage\validate-markdown-links.ps1' -Live` | Promoted Phase 4E evidence, TODO, README, DOCS, pending decisions, and four canonical records | pass — 9 documents, 8 local links | The default script policy blocked the first staged invocation, and the first live invocation used an incorrect relative script path; the final read-only live-tree command passed. No HTTP links were involved. |
- **Tests added/updated:** Added three Phase 4E cases. They prove actual long-fixture closure by configured size and maximum latency, bounded graph queue depth, four contiguous/non-overlapping synthetic source ranges with bounded related context, exact PCM redelivery through the gate/STT/active/history chain, unique logical word/revision/history identity, terminal conflict reuse, and a paused/resumed same-process active owner with late/stale rejection. The Phase 4C fake-STT case now asserts domain-event interleaving, and the edit case asserts unchanged word provenance after revision 1.
- **Regression impact:** All 78 Phase 4D tests remain green. The suite grows to 81. The service protocol now stores an output fingerprint separately from optional retained outputs, allowing `retainOutputs: false` operations to re-handle duplicates without retaining raw PCM. Catalog 1.6.0, all 32 contracts, fixtures, generated reference, packages, lockfile, browser UI, graphs, and immutable comparison baseline remain unchanged.
- **API docs:** No HTTP/OpenAPI surface and no process-contract schema/catalog change; the generated contract reference remains current.
- **Conflicts / exceptions:** Phase 4E is not fully complete. Its long-monologue active-state checkbox remains open because the active owner retains finalized segments in memory for later edits and no Phase 6 storage/eviction boundary is authorized. This session does not claim crash recovery, process-restart durability, production thresholds, or lifecycle orchestration.
- **Tooling gates:** All defined package, contract, graph, measurement, dependency, and local-link gates pass. Phase 4F and later phases were not started.

### 2026-08-13T02:15:00Z — Argus

- **Summary:** Completed Architecture Phase 4D — explicit transcript-to-context wiring and context selection. Added a governed session context policy, policy-gated audio startup, a highest-priority serial transcription gate, finalized-only context selection, singular authoritative source ownership, bounded lookback/forward context, deterministic topic signals, and alternate STT/selector replacement proofs.
- **Plan used:** Record the accepted defaults; evolve context contracts additively; configure selection through an explicit control component; route fake PCM through the proven scheduler; connect only finalized segments; test each trigger independently and together; prove source/context invariants and both substitutions; update canonical memory after all gates.
- **Files/Areas:** Catalog 1.6.0 and `transcript.context-policy`; `transcript.context-window` 1.4; graph run configuration propagation; context payload invariants; context policy source, transcription gate, alternate STT, alternate selector, evidence observer; `wiring/demo.transcript-context.json`; six Phase 4D tests; ADR-013; Phase 4D evidence; TODO/pending/readme/docs and canonical artifacts.
- **User-visible impact:** Browser UI is unchanged. The executable architecture can now reproducibly turn the finalized working-document transcript into an exact policy-bearing context window, never a partial projection.
- **Tests run:** Full regression 78/78; governance valid for 32 messages; generated reference current; concise, passthrough, Phase 4C transcript, and Phase 4D context graphs pass; 4/8/12 scaling evidence passes; dependency audit reports 0 vulnerabilities; local Markdown links pass.
- **Tests added/updated:** Six Phase 4D cases prove nine-process policy-gated wiring, pause/size/topic/latency independently and simultaneously, non-overlapping source with bounded related context, transcription workload/concurrency evidence, STT and selector replacements, and default-deny partial exclusion.
- **Regression impact:** All 72 Phase 4C tests remain green. Catalog grows from 31 to 32 messages. Existing 1.0 context fixtures and prior graphs remain compatible. No package, UI, microphone, real STT/model, storage engine, or immutable baseline change.
- **Conflicts / exceptions:** Test policy thresholds are not production values. Forward context deliberately delays emission until the configured number of finalized future segments exists; drain flushes an incomplete candidate. Durable selector recovery and long-monologue bounds remain Phase 4E.

### 2026-08-13T01:15:00Z — Argus

- **Summary:** Completed Architecture Phase 4C — independently runnable transcript components and the working-document proof. Added deterministic PCM audio, fake STT with evolving partials/immutable words/utterance boundaries, contextual correction/formatting, the sole active transcript owner, and append-only permanent history. The proof visibly resolves `are you ready` to `Argus, you ready?` while retaining original STT, stable Argus-owned word IDs, alternatives, proposal identity, formatting provenance, revision 0, and the history receipt.
- **Plan used:** Formalize the user's Microsoft-style live behavior and focused-highlighting preference; add only the missing request/boundary/result contracts; implement five isolated services; authorize their relationships in a new default-deny graph; prove happy path, invalid/corrupt/silence, replay/order, automatic-versus-review policy, revisions/history, lifecycle/recovery, and AI priority; update canonical memory only after gates pass.
- **Files/Areas:** Three new governed transcript contracts/histories/fixtures; additive segment/review and AI-work contract evolution; service protocol versioned-output support; five component directories; `wiring/demo.transcript-pipeline.json`; Phase 4C component tests and evidence artifact; ADR-011/012; AI-lane docs; README/DOCS/TODO/pending decisions; canonical feature/decision/changelog/index artifacts.
- **User-visible impact:** The browser POC is unchanged, but the executable architecture now produces the intended live-transcript semantics. A future UI can update one provisional row, settle correction/punctuation in place, convert it to an editable segment, and show subtle review affordances only for unresolved meaningful ambiguity.
- **Tests run:**

| Gate | Command | Scope | Result | Exception / risk |
| --- | --- | --- | --- | --- |
| full regression and Phase 4C proof | `npm.cmd test` | All prior phases plus 11 new component/graph cases for valid/invalid/corrupt PCM, long/silence fixtures, evolving partials, immutable words, replay/gap/late, correction/review, edits/history, lifecycle/recovery, default-deny wiring, and AI order | pass — 72 tests, 0 failures | — |
| governance integrity | `npm.cmd run contracts:check` | Catalog 1.5.0, exact fixtures, schemas, owners, histories, limits for 31 messages | pass | — |
| generated-doc drift | `npm.cmd run contracts:docs:check` | Human-readable contract reference | pass — current | — |
| three executable graphs | existing concise and passthrough commands plus `npm.cmd run demo:transcript` | Both extractor replacements and five-process transcript working-document proof | pass | First transcript run exposed missing observer wires for finalized/active projections; explicit result-collector wires were added and the rerun passed. |
| scaling evidence | `npm.cmd run measure:runtime` | Existing 4/8/12 service-process scaling proof | pass — JSON metrics produced | POC evidence only; Phase 4F will benchmark PCM transport separately. |
| dependency audit | `npm.cmd audit --omit=dev` | Production dependency tree | pass — 0 vulnerabilities | No package or lockfile change. |
- **Tests added/updated:** Added 11 Phase 4C cases and updated the future-version sentinel. Tests prove actual bounded PCM chunks; deterministic long/silence/correction fixtures; no emitted raw-audio bytes; corrupt/checksum, contradictory chunk-ID reuse, gap, late, and replay behavior; correction component isolation; 0.90 automatic acceptance versus focused review flags; optimistic edit/stale rejection; revision-complete append history; graph completion and no partial leakage; state restart fail-closed; health/drain conformance; and transcription → correction/formatting → extraction → classification scheduling.
- **Regression impact:** All 61 Phase 4B tests remain green. Governed messages grow from 28 to 31; catalog advances to 1.5.0. AI work, stored/history segment projections, and finalized segments advance additively while retained fixtures replay. The runtime protocol can emit the catalog version required by additive outputs. Existing browser code, packages, existing graphs, and immutable baseline are unchanged.
- **API docs:** No HTTP/OpenAPI surface. Generated process-contract reference is current.
- **Conflicts / exceptions:** Components are deterministic/in-memory. The fake 0.90 correction threshold is not a production claim. Exact review styling, real provider behavior, durable recovery/storage, context-trigger wiring, and transport benchmarks remain governed future work.
- **Tooling gates:** Applicable regression, governance, generated-reference, graph, measurement, and audit gates pass.

### 2026-08-13T00:40:00Z — Argus

- **Summary:** Completed Architecture Phase 4B — transcript contracts and ownership. Added governed bounded audio, replaceable partial, immutable committed-word, contextual-correction proposal, active-segment update/state, and append-only permanent-history contracts. Formalized that similar-sounding alternatives remain evidence, contextual AI uses an exact bounded range plus versioned policy/instructions, only the active transcript owner accepts corrections, punctuation remains provisional until segment finalization, and logged-item context windows carry explicit versioned generation/context parameters.
- **Plan used:** Translate the user's correction/punctuation/UI expectations into provider-neutral ownership first; evolve the catalog compatibly; add strict cross-field audio validation where JSON Schema cannot express decoded-byte relationships; preserve original STT and correction provenance through active revisions/history; prove valid and invalid boundaries; update canonical project memory only after regression passed.
- **Files/Areas:** Contract catalog 1.4.0; eight new schemas, histories, and retained fixtures; additive `transcript.segment` 1.3.0 provenance/finalization fields; audio semantic-invariant validation; Phase 4B contract tests; generated contract reference; operation outcome map; transcript ownership evidence, ADR-009/010, pending-decision register, README/DOCS/TODO, and canonical decision/capability/changelog artifacts.
- **User-visible impact:** The browser UI is unchanged. The implementation contract now supports the intended Microsoft-style read-only updating line, provider or adjacent contextual correction, visible similar-word candidates in a future UI, finalized punctuation, optimistic transcript edits, and append-only evidence without granting AI silent mutation authority.
- **Tests run:**

| Gate | Command | Scope | Result | Exception / risk |
| --- | --- | --- | --- | --- |
| full regression and Phase 4B boundary proof | `npm.cmd test` | All prior architecture behavior plus eight new fixtures, audio corruption/bounds, partial authority exclusion, correction/logging context and prompt provenance, active/history evidence, and compatibility | pass — 61 tests, 0 failures | First run found an obsolete future-version sentinel after `transcript.segment` advanced to 1.3.0; corrected to test 1.4.0 and reran green. |
| governance integrity | `npm.cmd run contracts:check` | Catalog evolution, exact fixture inventory, schemas, owners, histories, limits, and fixtures for 28 messages | pass | — |
| generated-doc drift | `npm.cmd run contracts:docs:check` | Human-readable reference for catalog 1.4.0 | pass — current | — |
| concise and alternate graphs | `node runtime/orchestrator.mjs wiring/demo.concise.json`; `node runtime/orchestrator.mjs wiring/demo.passthrough.json` | Existing replaceable extractor graphs under the evolved catalog | pass | Phase 4C transcript component graph is not implemented yet. |
| scaling evidence | `npm.cmd run measure:runtime` | Existing 4/8/12-process proof after catalog/registry evolution | pass — JSON metrics produced | Values remain POC evidence, not production thresholds. |
| dependency audit | `npm.cmd audit --omit=dev` | Installed production dependency tree | pass — 0 vulnerabilities | Isolated staging lacked registry/cache-log access; the approved live-workspace rerun passed. |
- **Tests added/updated:** Added seven Phase 4B tests. They validate all new compatibility fixtures; PCM format/base64/byte/sample/checksum bounds; absence of durable authority in partial projections; acoustic alternatives and versioned contextual-prompt provenance; original STT/word/formatting evidence through active and history payloads; backward-compatible 1.0 segment/context replay; and bounded versioned logged-item generation directives.
- **Regression impact:** All 54 Phase 3 tests remain green. Governed messages grow from 20 to 28. `transcript.segment` advances additively from 1.2.0 to 1.3.0 and changes accountable owner from capture to active state; retained 1.0.0 fixtures continue to replay. Existing services, graphs, packages, browser code, and immutable POC baseline are unchanged.
- **API docs:** No HTTP/OpenAPI surface. Generated process-contract reference is current.
- **Conflicts / exceptions:** No real microphone, STT, language-model, storage, or UI integration was added. Whether provider-native correction/punctuation is sufficient remains evidence-driven as STT-003; fake components are Phase 4C. No package change was needed.
- **Tooling gates:** Applicable regression, governance, generated-reference, and both existing graph gates pass.

### 2026-08-12T23:07:50Z — Argus

- **Summary:** Formalized the Phase 4 transcript-pipeline plan after accepting ephemeral audio, PCM16/16 kHz/mono fake input, read-only partial hypotheses, incremental confident-word commitment, finalized editable segments, and finalized-only downstream/history flow. Expanded the Phase 4 backlog into contracts/ownership, component, wiring, behavioral/recovery, transport-evidence, and exit-gate sections. Added a central pending-decision register with safe defaults and evidence triggers for future packages, SDKs, providers, thresholds, storage, transport, native/container, credentials, observability, corpus, and desktop-host choices.
- **Plan used:** Turn the user-approved defaults into explicit architecture decisions; decompose Phase 4 into checkable implementation/proof steps; make deferred choices discoverable before they can become accidental dependencies; synchronize code-adjacent and canonical project memory; verify documentation only because no runtime behavior changed.
- **Files/Areas:** `TODO.md`; new root `PENDING-DECISIONS.md`; `Architecture/DesignDecisions.md`; repository `README.md` and `DOCS.md`; canonical documentation index, changelog, feature/capability catalog, and product/architecture decision register.
- **User-visible impact:** No application behavior changed. Future implementers now have an ordered Phase 4 execution plan and one place to see which technology decisions are open, which safe default applies, what evidence is required, and when work must pause for a choice.
- **Tests run:**

| Gate | Command | Scope | Result | Exception / risk |
| --- | --- | --- | --- | --- |
| Markdown reference/link audit | PowerShell resolver plus `rg` cross-reference checks over the staged repository and canonical artifacts | New pending-decision links, Phase 4 checklist references, ADR references, canonical index, current state, plan, features, and decision IDs | pass | Runtime tests not triggered: documentation/planning only; no runtime, schema, contract catalog, service, wiring, dependency, or UI file changed |
- **Regression impact:** Documentation-only and isolated from executable behavior. Checked `runtime/`, `contracts/`, `services/`, `wiring/`, `tests/`, `package.json`, browser HTML/CSS/JS, and the immutable POC baseline; none are changed by this session.
- **API docs:** No HTTP/OpenAPI surface and no process-contract schema/catalog change; generated contract reference is intentionally unchanged.
- **Conflicts / exceptions:** No new package was installed because Phase 4 can begin with Node built-ins, Ajv, deterministic PCM fixtures, and fake components. Real microphone/STT/model/storage/transport choices remain explicitly deferred until their evidence trigger is reached.
- **Tooling gates:** The repository defines runtime/contract gates, but this session changes planning and decision Markdown only. The applicable final gate is the documented link/reference audit.

### 2026-08-12T21:40:00Z — Argus

- **Summary:** Completed Architecture Phase 3 — Identity, Duplication, Ordering, and the global AI execution lane. Argus now explicitly uses at-least-once delivery with UUID-v4 message IDs, stable idempotency keys, canonical semantic fingerprints, graph-wide and service-local conflict detection, serialized idempotent consumers, per-session transcript ordering, optimistic logged-item revisions, stale AI-result rejection, and a durably journaled bounded AI scheduler. The one model lane is non-preemptive and concurrency-one; pending work is transcription first, logged-item extraction second, and classification enrichment last, with FIFO inside each workload.
- **Plan used:** Capture the accepted policy in executable contracts; implement identity and ordering primitives; make the first state owner duplicate-safe and revision-aware; prove stale classification rejection; build the persistent scheduler/recovery boundary; wire nonfatal rejection to the supervisor; run concurrency, restart, scaling, compatibility, governance, graph, and audit gates; promote only after the isolated stage passed.
- **Files/Areas:** `runtime/message-identity.mjs`, `ordered-stream.mjs`, `serial-ai-scheduler.mjs`, service protocol/provider/orchestrator; transcript selector and logged-item store; catalog/envelope plus six new contracts, histories, fixtures, and generated reference; both demo graphs; `tests/identity-ordering.test.mjs` and integration/wiring/governance tests; `Architecture/IdentityOrderingAndAiLane.md`, ADRs, component guidance, README, DOCS, and TODO.
- **User-visible impact:** The browser UI is unchanged. Architecture messages are now auditable and replay-safe; transcript gaps, late inputs, stale edits, and stale classification suggestions have explicit outcomes. Optional classification is formally the lowest-priority AI workload and cannot silently mutate an item or displace queued transcription.
- **Tests run:**

| Gate | Command | Scope | Result | Exception / risk |
| --- | --- | --- | --- | --- |
| full regression and Phase 3 concurrency | `npm.cmd test` | Governance, compatibility, isolation, supervision, identity conflicts/tamper, duplicate/late/gap handling, revisions/stale results, scheduler capacity/priority/FIFO/concurrency/restart, multi-instance identity, and wiring | pass — 54 tests, 0 failures | — |
| governance integrity | `npm.cmd run contracts:check` | Catalog evolution, schemas, owners, histories, limits, and fixtures for 20 messages | pass | — |
| generated-doc drift | `npm.cmd run contracts:docs:check` | Human-readable contract reference | pass — current | — |
| concise and alternate graphs | `node runtime/orchestrator.mjs wiring/demo.concise.json`; `node runtime/orchestrator.mjs wiring/demo.passthrough.json` | Both replaceable extractors through identity-aware readiness, work, result, completion, drain, and exit | pass | — |
| scaling evidence | `npm.cmd run measure:runtime` | 1/2/3 parallel pipelines: 4/8/12 service processes and per-instance producer namespaces | pass — JSON metrics produced | Values are POC evidence, not production thresholds |
| dependency audit | `npm.cmd audit --omit=dev` | Installed production dependency tree | pass — 0 vulnerabilities | Initial sandbox registry/cache access was restricted; approved rerun passed |
- **Tests added/updated:** Added or updated 12 Phase 3 cases, including the explicit rejection-wiring invariant. Proofs cover current envelope identity, exact replay, fatal ID/key conflicts, fingerprint tamper, independent session sequence, duplicate/gap/late selector behavior, optimistic update idempotency, stale classification rejection, single-lane priority/FIFO, non-preemption, bounded no-drop admission, slow-journal admission order, unfinished recovery, completed-result replay after restart, and same-implementation multi-instance producer isolation.
- **Regression impact:** All 42 Phase 2 tests remain green. Catalog messages grow from 14 to 20 and current emitters move to envelope 1.2.0; retained 1.0.0 fixtures still replay. Demo control wires grow from 29 to 31 because rejection is explicit. The final measurement gate exposed a same-implementation producer collision, resolved by injecting the graph service-instance ID through the trusted provider and rejecting mismatched producer claims.
- **API docs:** No HTTP/OpenAPI surface. Generated process-contract reference is current.
- **Conflicts / exceptions:** The logged-item proof owner is still in memory; Phase 6 durable domain storage must persist equivalent idempotency/revision state. The scheduler boundary and journal are implemented and proven, but real model adapters are not yet wired. Classification review UI remains open. Native/OCI providers remain unimplemented.
- **Tooling gates:** All defined package gates, both demos, 4/8/12-process measurement, and the production dependency audit pass.

### 2026-08-12T20:45:00Z — Argus

- **Summary:** Completed Architecture Phase 2 — Runtime Supervision. The graph now governs runtime kind, required/optional status, readiness, operation completion, drain, bounded queues, timeouts, opt-in retries, dead letters, and bounded restart/recovery. Launching is behind a trusted runtime-provider boundary with Node as the sole active provider; native and container declarations fail closed until providers exist. Required components fail fast only after declared recovery is exhausted.
- **Plan used:** Implement the user-accepted defaults as contracts and schema rules first; adapt all isolated services; move Node spawning behind a provider registry; exercise fault/recovery behavior; collect POC scaling evidence; reconcile code-adjacent and canonical documentation; publish only after all gates pass.
- **Files/Areas:** `runtime/` provider, queue, service protocol, and supervisor orchestration; `contracts/` schemas/catalog/history/fixtures/generated reference; all service manifests and implementations; demo wiring graphs; supervision fixtures/tests; measurement script; runtime architecture/evidence and polyglot strategy; README, TODO, and canonical feature/decision/changelog artifacts.
- **User-visible impact:** The browser UI is unchanged. Architecture runs now wait for all required services to become ready, track actual work completion, drain explicitly, report process exits to the wired supervisor, and return POC metrics. Failure/recovery behavior is visible and graph-controlled instead of launcher-private.
- **Tests run:**

| Gate | Command | Scope | Result | Exception / risk |
| --- | --- | --- | --- | --- |
| full regression and supervision | `npm.cmd test` | Governance, compatibility, isolation, wiring, replacement, readiness, timeout, retry/dead-letter, restart, optional degradation, queue overflow, undeclared output, and drain deadline | pass — 42 tests, 0 failures | — |
| governance integrity | `npm.cmd run contracts:check` | Catalog evolution, schemas, owners, histories, limits, and artifact validation for 14 messages | pass | — |
| generated-doc drift | `npm.cmd run contracts:docs:check` | Human-readable contract reference | pass — current | — |
| concise and alternate graphs | `npm.cmd run demo`; `npm.cmd run demo:alternate` | Both extractor replacements through readiness, work receipts, result, completion, drain, and exit paths | pass | — |
| scaling evidence | `npm.cmd run measure:runtime` | 1/2/3 parallel pipelines: 4/8/12 service processes | pass — JSON metrics produced | Values are POC evidence, not production thresholds |
| dependency audit | `npm.cmd audit --omit=dev` | Installed production dependency tree | pass — 0 vulnerabilities | Initial sandbox request could not reach registry; approved network rerun passed |
- **Tests added/updated:** Added 13 Phase 2 supervision cases and fault fixtures. The suite proves fail-closed unsupported providers, readiness failure, operation timeout without implicit retry, exact-wire retry, dead-letter exhaustion, stateless restart with unfinished-input replay, restart exhaustion, explicitly optional degradation, stateful recovery-owner validation, bounded queue overflow, undeclared output failure, drain deadline, and resource evidence.
- **Regression impact:** Both existing extractor implementations remain interchangeable and all 29 pre-Phase-2 assertions remain green after being updated to distinguish domain outputs from explicit operation receipts. The catalog grows from 7 to 14 governed messages. Manifests move from `runtime.command` to discriminated `runtime.kind`.
- **API docs:** No HTTP/OpenAPI surface. Generated process-contract reference is current.
- **Conflicts / exceptions:** This is not an executable polyglot claim. Only the Node provider is installed. NDJSON remains the transport, overflow policy is fail, optional degradation has policy support but no optional demo service, and replay can duplicate work until Phase 3 idempotency/ordering rules are implemented.
- **Tooling gates:** All defined package gates, both demos, scaling evidence, and the production dependency audit pass.

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
2. A Node 22+ architecture proof executes replaceable extraction graphs, a five-service working-document graph, a nine-service finalized-context graph, a six-service Phase 5A logged-item ownership graph, and an eight-service Phase 5B local-model/classification graph. Thirty-seven governed messages, default-deny domain/control wires, supervision/recovery, identity/order/revision guarantees, the four-level serial AI lane, policy-driven context selection, dual STT/selector replacement, replay across transcript owners, same-process intake pause/resume, deterministic logged-item ownership, exact model context/budget enforcement, retry behavior, explicit classification context, governed model protocol fixtures, and revision-bound optional classification are covered by 101 automated tests. Ajv is the single maintained runtime dependency.

The initial architectural ambiguity around hidden startup, supervision, result, and completion authority has been resolved: these capabilities occupy typed control/domain wires, while the runtime kernel retains only a finite documented set of process-hosting and validation mechanics.

The live workspace is `C:\Users\dktho\OneDrive\PDProjects\Argus`. The immutable comparison baseline is `Argus-POC-v1-2026-08-12` beside the live workspace, with a ZIP and SHA-256 sidecar. Canonical project memory is this `C:\dustin-thomason\docs\Argus` directory.

Contract Governance Phase 1, Runtime Supervision Phase 2, Identity/Ordering Phase 3, Transcript Pipeline Phases 4A through 4F, and Phase 5A are complete for review; Phase 5B.1 is implemented for review with a deterministic loopback endpoint and no production provider selection. Phase 4E has direct evidence for seven of eight claims; its active-history bound remains explicitly deferred because the in-memory active owner retains finalized segments for later revision and the required persistence/eviction boundary belongs to Phase 6. Phase 5A uses deterministic extraction, separate in-memory active/history owners, exact provenance, revision identity, and user-authoritative proposals. Phase 5B.1 adds strict versioned model request/result boundaries, bounded strict outputs and pending state, explicit retryable failure, loopback-only transport, scoped configuration, explicit classification context, and optional revision-bound classification. The final corrective gate passes with 101 full-regression tests and 14 focused tests. Catalog 1.7.0 governs 37 messages; retained older fixtures prove compatible replay and generated documentation is enforced.

Raw audio will be ephemeral after transcription. Partial hypotheses are visible but read-only; confident words commit as immutable evidence. Provider/acoustic alternatives and adjacent contextual correction are governed proposals with exact context and versioned instructions, and only the active owner can accept them. Punctuation remains provisional until finalization; only finalized segments become editable or enter extraction/history. No real microphone, STT, model, storage, transport, or desktop SDK has been selected. `PENDING-DECISIONS.md` is the central queue for those choices and their evidence triggers.

Polyglot/container-capable execution is an accepted architectural invariant. The trusted provider boundary and discriminated manifests are implemented, but Node is the sole active provider; future native/OCI providers must preserve the same contracts, wires, lifecycle/supervision, permissions, and shared replacement evidence. `POLYGLOT-RUNTIME-STRATEGY.md` remains governing.

## Plans

- [2026-08-12] Establish canonical Argus changelog, feature catalog, decision register, docs index, and repository pointer. Status: implemented.
- [2026-08-12] Preserve the completed POC as an immutable folder, ZIP, and SHA-256 comparison baseline. Status: implemented.
- [2026-08-12] Make domain/control planes, runtime pseudo-components, and kernel authority explicit in the executable proof. Status: implemented.
- [2026-08-11] Separate neutral logged-item extraction from optional classification and expose transcript provenance. Status: implemented in UI/architecture direction and Phase 5B architecture proof; production model-backed enrichment remains deferred.
- [2026-08-11] Build the first Active Assistant look-and-feel prototype in plain HTML/CSS/JavaScript. Status: implemented.
- [2026-08-12] Contract governance: semantic compatibility, plane-breaking enforcement, ownership/history, compatibility replay, Ajv boundary validation, generated documentation, payload limits, and canonical failure outcomes. Status: implemented.
- [2026-08-12] Runtime supervision: readiness, operation receipts/timeouts, drain deadline, bounded queues, exact-wire retry/dead-letter, restart/recovery, exit facts, and measurements. Status: implemented for POC.
- [2026-08-12] Polyglot runtime strategy: trusted launcher-provider boundary, default-deny container capabilities, shared cross-runtime conformance, and proof criteria. Status: provider boundary implemented; native/OCI providers and conformance remain pending.
- Identity, idempotency, duplication, per-session ordering, optimistic revisions, stale-result rejection, and serial AI scheduling. Status: implemented for POC.
- Phase 4 transcript pipeline plan (`TODO.md` Phase 4A-4F): ephemeral PCM fake audio, partial/committed/correction contracts, active/permanent owners, context triggers, recovery proofs, and transport benchmark. Status: Phase 4F complete; Phase 4E is 7/8 proven with the active-history bound intentionally deferred to Phase 6.
- Phase 5A logged-item state/ownership proof. Status: implemented for review; deterministic components, exact source provenance, separate in-memory active/history owners, revisions, replay, conflict behavior, proposals, and evidence observation only.
- Phase 5B local model adapter and optional classification. Status: authorized next; environment-configured provider-neutral HTTP boundary, deterministic local test endpoint, retained fake, explicit retryable failure, and non-blocking lowest-priority classification. A specific local server/model remains unresolved under `MOD-001`.
- Central pending technology/product decision register (`PENDING-DECISIONS.md`). Status: active governance artifact; resolve entries only when their evidence trigger is reached.
- Context-window → logged-item integration. Status: Phase 5A deterministic ownership proof is complete for review; the local model endpoint remains Phase 5B, real audio/STT remains separately deferred, and durable persistence remains Phase 6.

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
| 2026-08-12 | Runtime supervision proof | Added runtime-neutral provider boundary, readiness, operation outcomes, drain, queue bounds, timeout, retry/dead-letter, restart/recovery, and scaling evidence. |
