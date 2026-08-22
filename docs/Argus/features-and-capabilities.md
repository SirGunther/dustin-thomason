# Argus Feature and Capability Catalog

This catalog describes the Argus POC as it exists on 2026-08-19. It distinguishes visible simulation from executable architecture so the prototype is not mistaken for a production implementation.

## Status legend

- **UI POC:** implemented in browser HTML/CSS/JavaScript; behavior is locally simulated.
- **Architecture proof:** executed through isolated Node processes and covered by automated tests.
- **Specified:** behavior or boundary is documented but not yet connected end to end.
- **Deferred:** intentionally reserved for a later implementation slice.

## Primary window

| Surface or control | Status | Current behavior | Implementation reference |
| --- | --- | --- | --- |
| ARGUS / Active Assistant identity | UI POC | Establishes a compact desktop-assistant identity in the upper-left header. | `index.html`, `styles.css` |
| Session identity button | UI POC | Shows the current session and opens the session-details drawer. | `#sessionDetailsButton` |
| Session state indicator | UI integrated | Renders the `ui.session-status` projection for stopped, recording, and finalized states. | `#sessionStateDot`, `renderSession()` |
| Session time | UI integrated | Displays elapsed time from the session projection while the bridge demonstration is recording. | `#elapsedTime`, `ui.session-status` |
| Record | UI integrated | Sends a governed session command to the lifecycle boundary; the browser changes only after the accepted status projection. | `#recordButton`, `ui.command` |
| Stop | UI integrated | Sends a governed stop command without finalizing; the active session projection remains resumable. | `#stopButton`, `ui.command` |
| Close session | UI POC | Opens a deliberate finalization confirmation instead of immediately ending the session. | `#closeSessionButton`, `openCloseModal()` |
| Two-pane workspace | UI POC | Places Raw Transcript and Logged Items side by side at desktop widths. | `.workspace` |
| Narrow-window fallback | UI POC | Stacks panes vertically below 840 px and simplifies selected header/footer content. | CSS media queries |
| Playback controls | Deferred by requirement | No playback control is included. | Initial UI requirements |

## Raw Transcript pane

| Surface or control | Status | Current behavior | Implementation reference |
| --- | --- | --- | --- |
| Entry count | UI POC | Displays the number of transcript rows with singular/plural wording. | `#transcriptCount` |
| Select all / Clear all | UI integrated | Selects or clears every transcript row; selection is UI-owned and survives incoming projections during the page lifetime. Hidden at compact widths. | `.select-all-button[data-kind="transcript"]`; `ui/ui-state.mjs` |
| Copy selected | UI integrated | Routes selected transcript identities through the bridge in source order and reports the owner/capability result in a toast. | `#copyTranscriptSelected`; `copy` command |
| Row selection checkbox | UI integrated | Selects one transcript entry in UI-owned state; it is never part of the authoritative transcript projection. | Row template; `ui/ui-state.mjs` |
| Timestamp | UI POC | Shows the entry's capture time. | Row template `<time>` |
| Editable transcript text | UI integrated | Finalized rows submit governed expected-revision edits; provisional rows stay read-only and rejected/stale results restore the owner projection. | `.editable-text`; `transcript.edit` |
| Individual copy | UI integrated | Sends one row identity through the clipboard capability and posts its accepted/unavailable result. | `.row-copy`; `copy` command |
| Native text selection | UI POC | Browser text selection remains available inside editable row content. | `.editable-text` |
| Independent live scrolling | UI integrated | Follows new transcript only when this pane is already following live content. Scrolling upward preserves the user's position. | `ui/ui-state.mjs`; `#transcriptScroll` |
| Jump to live | UI integrated | Appears when the user leaves the bottom, reports unseen rows, and restores live following. | `#transcriptJump`; `jumpToLive()` |
| Real speech-to-text stream | Deferred | The POC appends deterministic sample content; no microphone, VAD, or STT provider is connected. | `liveSamples`, `addLiveSample()` |
| Edited text supplied to later model calls | Governed boundary | Owner-accepted revisions become the only current projection; no browser-only edit is presented as authoritative. | `ui.command-result`; owner revisions |
| Ephemeral raw audio | Governed for Phase 4B | Audio is released after terminal transcription and is not stored as a recording. A future retry buffer must be a separate bounded capability. | ADR-007; `PENDING-DECISIONS.md` AUD-001 |
| Deterministic fake audio format | Governed for Phase 4B | `audio.chunk` bounds inline PCM16, 16 kHz, mono fixtures and validates format, canonical base64, byte/sample equality, and SHA-256 checksum; this does not select a real microphone SDK. | ADR-007; `audio-chunk.schema.json` |
| Provisional transcript projection | Governed for Phase 4B | `transcript.partial` is a revisioned, replaceable utterance projection that remains read-only and has no extraction/history authority. | ADR-008; `transcript-partial.schema.json` |
| Incremental committed words | Governed for Phase 4B | `transcript.word-committed` carries ordered immutable STT evidence, confidence, source chunk IDs, and optional similar-sounding alternatives. | ADR-008; `transcript-word-committed.schema.json` |
| Contextual word correction | Governed for Phase 4B | Provider or adjacent language processing emits a proposal with exact target/context, alternatives, confidence, basis, and versioned policy/instructions. Only the active owner can accept it; source evidence remains unchanged. | ADR-009; `transcript-word-correction-proposed.schema.json` |
| Context-aware logged-item directive | Governed for Phase 4B | A context window may name the logged-item policy/instruction version and exact lookback, forward, and character bounds while retaining mandatory source-segment provenance. | `transcript.context-window` 1.3.0 |
| Provisional punctuation and structure | Governed for Phase 4B | Provider-native or contextual formatting can update the live projection; punctuation/capitalization become downstream truth only when the active owner finalizes the segment. | ADR-010 |
| Active transcript revisions | Governed for Phase 4B | Finalized active segments retain original STT text and per-word correction provenance; edits require an expected revision. | `transcript.segment-update`; `transcript.segment-stored` |
| Append-only transcript history | Governed for Phase 4B | A separate owner accepts explicit, idempotent appends of finalized segment revisions and returns a stable receipt. | `transcript.history-append`; `transcript.history-appended` |
| Working-document fake pipeline | Architecture proof — Phase 4C | Five isolated components execute fake PCM → changing partials/committed words → contextual correction/formatting → finalized active segment → append-only history. | `wiring/demo.transcript-pipeline.json` |
| Provider-independent word identity | Architecture proof — Phase 4C | Argus derives stable session-scoped word IDs when the provider does not expose usable identifiers. | `fake-stt`; ADR-011 |
| Automatic eligible correction | Architecture proof — Phase 4C | Target/expected text must match and proposal confidence must meet the explicit fake threshold; original STT and proposal ID remain preserved. | `active-transcript-owner`; ADR-011 |
| Focused ambiguity evidence | Architecture proof — Phase 4C | Only unresolved ambiguity or a meaningful below-threshold correction produces `review_flags`; low confidence alone and accepted corrections remain quiet. | `review_flags`; `tests/transcript-components.test.mjs` |
| Revision-complete history | Architecture proof — Phase 4C | Final revision 0 and every optimistic user revision append independently; exact replay is idempotent and conflicting reuse fails. | `permanent-transcript-history`; ADR-012 |
| Ephemeral audio release proof | Architecture proof — Phase 4C | Fake STT validates PCM data, emits no audio bytes, and retains no raw-audio archive; silence creates no phantom transcript output. | `fake-stt`; Phase 4C tests |
| Finalized-only context graph | Architecture proof — Phase 4D | Nine isolated processes wire policy-gated PCM through the transcription lane and active owner to context selection; partial hypotheses have no route to context or history. | `wiring/demo.transcript-context.json` |
| Explicit context policy | Architecture proof — Phase 4D | Pause, source size, deterministic topic sequences, maximum latency, lookback, forward context, and character bounds are versioned session policy rather than code-private constants. | `transcript.context-policy`; ADR-013 |
| Singular source ownership | Architecture proof — Phase 4D | Every source range is contiguous and non-overlapping; bounded lookback/forward segments are separately labeled context and cannot duplicate source ownership. | `transcript.context-window` 1.4; payload invariants |
| Trigger evidence | Architecture proof — Phase 4D | The first satisfied signal closes a range, maximum latency is mandatory, and every simultaneous reason remains visible under stable primary precedence. | `selection`; `triggered_reasons` |
| Transcription scheduler gate | Architecture proof — Phase 4D | Fake PCM traverses an explicit concurrency-one `transcription` workload gate without persisting audio as scheduler input. | `serial-transcription-gate` |
| Dual replacement proof | Architecture proof — Phase 4D | An independent provider-B STT and independent alternate context selector each occupy the same graph position without neighbor or wire changes. | Phase 4D replacement tests |
| Exact PCM redelivery | Architecture proof — Phase 4E | The transcription gate re-handles an exact duplicate and re-emits the currently delivered PCM while its protocol retains only an output fingerprint and its scheduler journal rejects raw audio. | `phase4e-behavior-recovery.test.mjs` |
| Replay-safe transcript owners | Architecture proof — Phase 4E | Fake STT may replay deterministic evidence; active ownership keeps one logical word/revision state; permanent history returns one stable entry receipt per segment revision and rejects conflicting identity reuse. | Phase 4E replay case |
| Stop/Resume-compatible active ownership | Architecture proof — Phase 4E/6 | Stop preserves active temporary state without moving permanent history; Resume continues the same session identity and ordering; late/stale input and writes after Close reject. | `tests/phase6-session-storage.test.mjs`; Phase 4E batch-harness case |
| Long-monologue bounded surfaces | Architecture proof — Phase 4E/6 | Actual long input closes by configured size or maximum latency; authoritative ranges remain contiguous and non-overlapping; related context and graph queues remain bounded; durable history survives active-cache eviction and reload. | `TranscriptBehaviorPhase4EEvidence.md`; `SessionStoragePhase6Evidence.md` |
| Governed session lifecycle | Architecture proof — Phase 6 | Record, Stop, Resume, and Close use versioned commands/outcomes, stable operation identity, explicit state transitions, idempotent replay, and conflicting identity failures. | `session.*` contracts; `runtime/session-lifecycle.mjs` |
| Recoverable Close finalization | Architecture proof — Phase 6 | Close blocks writes, drains admitted work, persists active projections, reconciles append-only history, seals close evidence, and releases evictable cache. Recovery is proven before and after every phase. | `tests/phase6-session-storage.test.mjs` |
| Root-scoped filesystem session storage | Architecture proof — Phase 6 POC | Versioned JSON metadata/current snapshots and append-only NDJSON histories live beneath `ARGUS_SESSION_ROOT`; replacement is atomic and no database or SDK is selected. | `runtime/session-storage.mjs`; ADR-015 |
| Narrow session-folder locator | Architecture proof — Phase 6 | The locator accepts only a governed session identity, validates the resolved root-scoped folder, and returns active/permanent paths without arbitrary path access. | `services/session-folder-locator`; `session.folder-locate` |
| Inline PCM transport evidence | Architecture proof — Phase 4F | Deterministic 100/250/500 ms PCM16 chunks traverse the governed envelope and capacity-32 queue at their representative cadence; base64/envelope expansion, latency, RSS, and explicit oversized rejection are recorded without production thresholds. | `TranscriptTransportPhase4FEvidence.md`; `benchmark:transport` |

## Logged Items pane

| Surface or control | Status | Current behavior | Implementation reference |
| --- | --- | --- | --- |
| Neutral Logged Items label | UI POC | Presents extracted statements without asserting task/note/idea/observation classifications. | `#derivedTitle`; ADR-001 |
| Item count | UI POC | Displays the number of logged items. | `#derivedCount` |
| Select all / Clear all | UI POC | Selects or clears every logged item. Hidden at compact widths. | `.select-all-button[data-kind="derived"]` |
| Copy selected | UI POC | Copies selected logged items in display order and reports the count. | `#copyDerivedSelected`, `batchCopy()` |
| Row selection checkbox | UI POC | Selects one logged item and persists the selection. | Row template checkbox |
| Logged time | UI POC | Shows when the logged item was produced. | Row template `<time>` |
| Source context range | UI integrated | Displays exact first/last transcript segment IDs and timestamps. Selecting it scrolls to and temporarily highlights the ID-bounded transcript rows. | `.source-range`; `showSourceContext()` |
| Missing active source handling | UI integrated | Invalid/missing source provenance is visibly degraded and never inferred in the browser. | `ui.logged-item-row.source` |
| Editable logged text | UI integrated | Submits non-empty text through the logged-item owner with an expected revision; stale/rejected results do not overwrite newer state. | `.editable-text`; `logged-item.edit` |
| Individual copy | UI integrated | Routes one item through the bridge clipboard capability with optional timestamp and posts a result toast. | `.row-copy`; `copy` command |
| Simulated extraction delay | Architecture proof / UI integrated | The bridge emits a deterministic provisional transcript event followed by finalized transcript and logged-item projections while recording. | `ui/bridge.mjs`; SSE projections |
| Stable segment-ID provenance | Architecture proof | Deterministic Phase 5A extraction retains the exact first/last finalized segment IDs, source timestamps, context-window ID, generator identity, and revision identity through active state and history append. | `Architecture/LoggedItemPipelinePhase5AEvidence.md` |
| Governed active logged-item owner | Architecture proof | One in-memory owner alone mutates active logged-item text, applies user-authoritative optimistic revisions, replays duplicates, and rejects stale commands or conflicting item identity. | `services/active-logged-item-owner`, `logged-item.stored`, `logged-item.update` |
| Separate append-only logged-item history | Architecture proof | A second in-memory owner accepts each exact revision idempotently and emits a stable append acknowledgement; it has no update port. | `services/permanent-logged-item-history`, `logged-item.history-append` |
| User-authoritative update proposals | Architecture proof | Model-like updates are recorded as proposals and cannot replace active text until an explicit user acceptance; rejection produces no active revision. | `logged-item.update-proposed`, `logged-item.proposal-resolve` |
| Deterministic logged-item pipeline | Architecture proof | Finalized context windows flow through either deterministic extractor to active state, permanent history, and an explicit evidence observer in a default-deny six-service graph. | `wiring/demo.logged-item-pipeline.json` |
| Model-backed extraction | Architecture proof / production runtime deferred | A governed provider-neutral local HTTP adapter sends exact finalized context through `logged-item-extraction` on the graph's concurrency-one model lane; deterministic concise/passthrough fakes remain available. Strict versioned request/result shapes, loopback-only endpoint validation, bounded pending state, and a deterministic loopback endpoint prove behavior, but no production model/server is selected. | `services/log-extractor-local-http`; `services/serial-ai-model-lane`; `contracts/ai-work-request.schema.json`; `contracts/ai-work-completed.schema.json`; `Architecture/LoggedItemModelPhase5BEvidence.md`; MOD-001 |
| Automatic classification | Architecture proof / UI deferred | Classification is a separate optional suggestion, bound to the stored item revision and evidence segment IDs, receives the exact finalized transcript context through an explicit wire, runs through lowest-priority `classification-enrichment`, and cannot block or mutate primary text. It is not a live-list identity and has no current badge. | `services/logged-item-classification-suggester`; `classification.suggestion` |
| LLM revision of an existing item | Deferred | Current simulation appends items; it does not revise an existing item. Future proposals must not silently overwrite user edits. | Architecture backlog |
| Delete row | Deferred / undecided | No transcript or logged-item delete button currently exists. Deletion semantics, provenance impact, and recovery need an explicit decision. | No current control |

## Selection, copying, saving, and notifications

| Capability | Status | Current behavior |
| --- | --- | --- |
| Ordered batch copy | UI POC | Preserves current row order and separates copied entries with newlines. |
| Copy timestamps toggle | UI POC | Includes or omits `[time]` for both individual and batch copies; preference persists locally. |
| Clipboard fallback | UI POC | Falls back to an off-screen textarea if the modern Clipboard API is unavailable. |
| Browser autosave | Removed by Phase 7 boundary | The browser does not persist authoritative transcript, logged-item, or session data. Owner acceptance/rejection is shown through the bridge result. |
| Save-state feedback | UI integrated | Shows waiting-for-owner and owner-accepted/rejected feedback without claiming durable browser storage. |
| Top-center toast region | UI POC | Stacks transient notifications in header negative space so new live rows remain unobscured. |
| Reduced-motion support | UI POC | Respects the operating system/browser reduced-motion preference. |
| Durable filesystem persistence | Architecture proof — Phase 6 POC / storage capability unavailable in browser demo | The architecture POC persists session metadata, active transcript/logged-item snapshots, append-only permanent histories, and close evidence through the root-scoped filesystem boundary. The browser receives only an independent storage/session availability projection. |

## Session details and finalization

| Surface or control | Status | Current behavior |
| --- | --- | --- |
| Session-details drawer | UI POC | Shows session ID, state, created time, duration, entry counts, proposed storage path, and proposed session files. |
| Drawer close button | UI POC | Closes the drawer; the scrim and Escape key also close it. |
| Storage path control | UI integrated / host-dependent | Sends only the session identity to the authorized folder resolver and clipboard capability; arbitrary paths are not accepted. |
| Session data preview | UI integrated | Shows capability-neutral owner boundaries; the browser does not display or read storage file paths. |
| Open session folder (footer and drawer) | UI integrated / host-dependent | Sends only session identity to the folder capability and visibly reports unavailable behavior when no authorized host adapter exists. |
| Finalization summary | UI POC | Shows transcript/logged-item counts and warns that finalization prevents resume. |
| Keep session open | UI POC | Cancels finalization; the scrim and Escape key do the same. |
| Finalize & close | UI integrated | Sends a governed close command; controls disable only after the accepted closed session projection. |
| Transactional finalization | Architecture proof — Phase 6 POC / desktop integration deferred | The service boundary proves atomic snapshots, idempotent append history, persisted close phases, final close evidence, and restart recovery. It does not claim production transactions or global durability. |

## Executable architecture proof

| Capability | Status | Evidence |
| --- | --- | --- |
| One process per service | Architecture proof | Runtime spawns service executables without importing their implementation modules. |
| Typed message envelope and payload contracts | Architecture proof | JSON schemas plus runtime contract registry. |
| Default-deny wiring | Architecture proof | A message moves only through a declared compatible wire. Invalid producer/consumer declarations are rejected before launch. |
| Explicit domain and control planes | Architecture proof | Plane is part of contract identity, ports, wires, envelopes, and validation. |
| Visible runtime participants | Architecture proof | `@session-controller`, `@supervisor`, `@runtime-provider`, `@dead-letter-collector`, `@result-collector`, and `@run-controller` occupy declared graph positions. |
| Finite intrinsic kernel authority | Architecture proof | Kernel is limited to hosting, streams, raw process lifecycle, shutdown mechanics, and validation. It has no implicit domain authority. |
| Explicit startup, failure, result, and completion paths | Architecture proof | Removing the corresponding wire makes the capability invalid or unavailable. |
| Transcript-to-logged-item vertical slice | Architecture proof | Fake transcript source → context-window selector → extractor → in-memory store. |
| Replaceable extractor | Architecture proof | Concise and passthrough implementations share one manifest/contract position and both complete the graph. |
| Structured trace output | Architecture proof | Service traces use standard error; domain/control messages use standard output. |
| Contract-valid failure outcome | Architecture proof | Invalid service input is converted into an explicit `service.failure` message routed to the supervisor. |
| Automated proof suite | Architecture proof | 114 tests pass in the final full gate; focused Phase 7 coverage adds projections, command routing, capability fakes, bridge startup, required-element selector alignment, provenance, and UI-owned state to the earlier lifecycle/storage/recovery suites. |
| Contract compatibility policy | Architecture proof | Semver-based backward-compatible minor policy governs catalog 1.8.0 with 53 messages, accepts retained 1.0.0 messages where compatible, and rejects unknown newer minors or different majors. |
| Plane-breaking governance | Architecture proof | Catalog evolution checks reject a domain/control move unless the contract major version increases. |
| Contract ownership and history | Architecture proof | Every message declares an accountable owner and append-only message-specific changelog. |
| Maintained JSON Schema validation | Architecture proof | A single Ajv instance compiles schemas once when the graph registry loads and validates envelopes, payloads, manifests, and graphs at the runtime boundary. |
| Payload limits | Architecture proof | Every message has an explicit UTF-8 JSON payload limit; oversized messages are rejected before routing. |
| Generated contract reference | Architecture proof | Catalog/schema metadata generates `contracts/generated/contract-reference.md`; a drift check fails when it is stale. |
| Canonical failure outcome | Architecture proof | `service.failure` carries stable code/category, safe message, explicit retryability, and optional structured details over a declared control wire. |
| Runtime-neutral provider boundary | Architecture proof | Manifests discriminate Node/native/container without arbitrary shell commands. Only the Node provider is installed; unsupported providers fail closed before launch. |
| Readiness gate | Architecture proof | Every service receives a wired health probe and must return `service.health` within the default 5 s deadline before session start. |
| Explicit work completion | Architecture proof | A provider stream write is not treated as completed work; every accepted operation terminates with `operation.completed`, `operation.rejected`, or `service.failure`. |
| Operation timeout | Architecture proof | The default 2 s deadline is graph-controlled and timeout is emitted as a canonical retryable failure from `@runtime-provider` to `@supervisor`. |
| Bounded queues and backpressure | Architecture proof | Every per-wire queue is bounded, depth is traced, and the POC fails observably on overflow. |
| Opt-in wire retry | Architecture proof | Retry is disabled unless the exact wire declares attempts, delay, and an explicit dead-letter destination. |
| Dead-letter routing | Architecture proof | Retry exhaustion routes the original message and failure evidence to `@dead-letter-collector` before required-component fail-fast. |
| Bounded restart and recovery ownership | Architecture proof | Restart is off by default. Stateless restart is bounded; a state-owning service cannot restart until a recovery owner is declared. |
| Required versus optional components | Architecture proof | Required services fail after recovery exhaustion. Degraded behavior exists only for services explicitly marked optional. |
| Graceful drain | Architecture proof | Services acknowledge `lifecycle.drain`; the kernel waits the default 2 s deadline before forcing an uncooperative process to stop. |
| Provider exit facts | Architecture proof | Raw process exit is converted into a wired `service.exited` fact; the supervisor applies declared recovery policy. |
| Supervision measurement | Architecture proof | `npm run measure:runtime` reports startup, health-reported RSS, throughput, queue depth, and operation latency for 4, 8, and 12 service processes as POC evidence. |
| At-least-once identity | Architecture proof | Schema 1.2+ requires UUID-v4 message IDs, stable logical idempotency keys, and canonical SHA-256 semantic fingerprints. Exact replays are accepted; identity reuse with different content is fatal. |
| Graph-instance producer namespace | Architecture proof | The trusted Node provider injects each graph service-instance ID. The kernel rejects a mismatched producer, preventing same-implementation instances from colliding. |
| Serialized idempotent consumers | Architecture proof | Service input handlers run sequentially. Stateless duplicates replay cached outputs; state owners re-evaluate safely and cannot mutate twice. |
| Per-session transcript ordering | Architecture proof | Contiguous sequence is enforced independently per session. Gaps are retryable; late messages are explicit nonfatal rejections. |
| Optimistic logged-item revision | Architecture proof | `logged-item.update` applies only when `expected_revision` matches; duplicate updates do not increment twice and stale edits are rejected. |
| Stale AI-result protection | Architecture proof | A classification suggestion names the item revision analyzed and is rejected after a user edit advances authoritative state. |
| Explicit nonfatal rejection | Architecture proof | `operation.rejected` is wired to the supervisor, clears pending work, appears in metrics/results, and does not falsely fail a required service. |
| Serial AI execution lane | Architecture proof | The generic scheduler supports concurrency one, non-preemptive completion, transcription/correction/extraction/enrichment priority, FIFO per workload, explicit overflow, retries, restart recovery, and completed-result replay. The Phase 5B model graph uses one in-memory-journal lane for extraction and classification; separate graph processes are not claimed to share a global scheduler, and durable global journaling remains deferred. |
| Session/storage boundary | Architecture proof | Declared lifecycle/storage owners use the root-scoped JSON/NDJSON boundary; other services receive no ambient filesystem authority and communicate through governed messages. Close recovery and bounded active-history reload are executable proofs, not production durability claims. |

## Phase 7 UI boundary

| Surface or capability | Status | Current behavior | Implementation reference |
| --- | --- | --- | --- |
| Browser projection boundary | Architecture proof / UI integrated | The HTML POC receives only validated session, transcript, logged-item, command-result, and service-status projections from a loopback-only Node bridge. Required singleton selectors are guarded at startup, and the footer reports the bridge as connecting, available, or unavailable. | `ui/bridge.mjs`; `app.js`; `tests/ui-dom-bindings.test.mjs`; `Architecture/UiBoundaryPhase7Evidence.md` |
| Transcript event bridge | UI integrated | Provisional rows are read-only; finalized rows carry stable segment/revision identity and become editable only through the transcript owner command boundary. | `ui.transcript-row`; `app.js` |
| Logged-item event bridge | UI integrated | Logged-item text and revisions come from explicit projections. Optional classification is a suggestion and does not block editing. | `ui.logged-item-row`; `app.js` |
| Exact source provenance | UI integrated | Each logged item displays stable first/last segment IDs and exact timestamps; the browser highlights by IDs and visibly degrades missing provenance. | `ui.logged-item-row.source`; `showSourceContext()` |
| Optimistic owner edits | Architecture proof / UI integrated | Transcript and logged-item edits carry expected revisions. Accepted owner projections replace the row; stale, validation, provisional, and unavailable results remain visible. | `ui.command`; `ui.command-result`; `ui/command-router.mjs` |
| Copy capability | UI integrated / host-dependent | Individual and ordered batch copy preserve the timestamp preference and route through a replaceable clipboard adapter. The adapter reports host unavailability explicitly. | `platform-capabilities.mjs`; `copy` command |
| Open-folder capability | UI integrated / host-dependent | The browser sends only a session identity. The authorized capability resolves the folder; no arbitrary browser path is accepted. | `platform-capabilities.mjs`; `open-folder` command |
| UI-owned selection and scrolling | UI integrated | Row selection, select-all, independent pane following, unseen counts, jump-to-live, timestamp preference, and toasts stay in browser state. | `ui/ui-state.mjs`; `app.js` |
| Individual degraded states | UI integrated | Transcript, logged-item pipeline, storage/session, clipboard, folder opening, and optional classification display independent availability states. Classification failure does not disable editing. | `ui.service-status`; `#serviceStatusList` |

The Phase 7 demo starts with `npm.cmd run demo:ui` and opens at `http://127.0.0.1:4173`. `npm.cmd run demo:ui:smoke` validates deterministic startup and lifecycle/edit/copy command flow. Corrective revalidation D1–D4 passed. The newly observed active-editor position movement is a deferred Phase 7A bug. The browser/Node bridge is accepted as the POC host; `APP-001` now governs only a future desktop/product host, while `UI-001` and the optional-classification toggle decision `UI-002` remain deferred.

## Phase 8 permissions and packaging

| Surface or capability | Status | Current behavior | Implementation reference |
| --- | --- | --- | --- |
| Default-deny component authority | Architecture proof | Every manifest declares a required `permissions` block across filesystem, microphone, clipboard, network, model credentials, child processes, worker threads, native add-ons, and WASI. An omitted class, an omitted scope list, and an explicit `false` all normalize to no authority. 16 of 23 shipped components hold none. | `contracts/service-manifest.schema.json`; `runtime/permission-policy.mjs` |
| Host-neutral filesystem scopes | Architecture proof | Filesystem authority is declared as the named scope `session-root`, never a host path, so a manifest cannot express traversal and a future container host can map the same scope onto a mount unchanged. Requires the matching environment allowlist entry. | `runtime/permission-policy.mjs` |
| Node-runtime-enforced restrictions | Architecture proof | Declarations become real `node --permission` flags. Live probes observe `ERR_ACCESS_DENIED` for undeclared writes, reads outside every grant, child processes, and worker threads, and observe a granted session-root scope working while every other capability stays refused. | `runtime/providers/node-process-provider.mjs`; `tests/fixtures/permission-probe*` |
| Declared heap ceiling | Architecture proof | `resources.max_heap_mb` is applied through `--max-old-space-size`; the probe observes the reduced V8 limit. `memory_mb` and `cpu_limit` are refused outside a container runtime. | `runtime/permission-policy.mjs` |
| Environment and credential containment | Architecture proof | The provider rebuilds the child environment from the declared allowlist, dropping every undeclared `ARGUS_` variable and every credential-shaped inherited variable. A manifest may not allowlist a credential-bearing key without a `model_credentials` grant, and that grant is itself refused while `SEC-001` is open. | `buildNodeEnvironment`; `tests/phase8-permissions-packaging.test.mjs` |
| Outbound network | Architecture proof / **adapter-enforced only** | The installed Node build ships no network permission flag, verified directly. Loopback-only http is enforced at the model configuration boundary and by refusing `ARGUS_MODEL_ENDPOINT` without the declared scope. A component that bypassed the adapter and used `node:net` would not be stopped by this host. | `services/serial-ai-model-lane/model-config.mjs`; `ENFORCEMENT_MATRIX` |
| Fail-closed runtime providers | Architecture proof | `native` and `container` manifests fail graph preparation with `RUNTIME_PROVIDER_UNAVAILABLE` before any process launches. Selecting or installing a runtime grants no connectivity or permission by itself. | `runtime/runtime-providers.mjs` |
| Refusal of unsupportable capabilities | Architecture proof | Microphone, component clipboard, model credentials, component listeners, and container-only resource limits are refused at declaration time rather than accepted and simulated. | `assertPermissionPolicy` |
| Deterministic inspectable packages | Architecture proof | `npm run package:graph` writes one artifact per graph recording the graph, contract catalog and every schema/changelog, each manifest with fully expanded authority and declared files, the shared component libraries, and an integrity block with a package digest. `npm run package:graph:verify` re-derives and compares. | `runtime/package-inventory.mjs`; `scripts/package-graph.mjs` |
| Package refusals | Architecture proof | Path escape, undeclared component files, secrets, and integrity drift are refused with explicit codes. The undeclared-file rule forced three components to declare their helper modules through `runtime.includes`. | `PACKAGE_PATH_ESCAPE`; `UNDECLARED_PACKAGE_FILE`; `PACKAGED_SECRET_DETECTED`; `PACKAGE_INTEGRITY_VIOLATION` |

The intended enforcement matrix separates Node-runtime-enforced, adapter/configuration-restricted, and deferred claims. The executable matrix still needs the terminology-only correction recorded in the live `TODO.md`: outbound configuration is restricted, but this Node host does not contain direct sockets. Full evidence is in `Architecture/PermissionsPackagingPhase8Evidence.md`; ADR-018 records the decision. Native and OCI proofs remain evidence-triggered under `NAT-001` and `CNT-001` because no compiler and no container engine is installed.

## Contract and service inventory

- Domain contracts: `audio.chunk`; `transcript.partial`, `transcript.word-committed`, `transcript.word-correction-proposed`, `transcript.utterance-boundary`, `transcript.correction-request`, `transcript.correction-resolved`, `transcript.segment`, `transcript.segment-update`, `transcript.segment-stored`, `transcript.history-append`, `transcript.history-appended`, and `transcript.context-window`; `logged-item.draft`, `logged-item.stored`, `logged-item.update`, `logged-item.history-append`, `logged-item.history-appended`, `logged-item.update-proposed`, `logged-item.proposal-resolve`, `logged-item.proposal-resolved`, `classification.suggestion`, and `classification.suggestion-accepted`; Phase 7 `ui.session-status`, `ui.transcript-row`, and `ui.logged-item-row`.
- Control contracts: `transcript.context-policy`, `lifecycle.start`, `lifecycle.health-check`, `service.health`, `lifecycle.drain`, `service.drained`, `operation.completed`, `operation.rejected`, `service.failure`, `service.exited`, `dead-letter.message`, `workflow.completed`, `ai.work-request`, `ai.work-completed`, and the Phase 6 `session.record`, `session.recorded`, `session.stop`, `session.stopped`, `session.resume`, `session.resumed`, `session.close`, `session.closed`, `session.folder-locate`, and `session.folder-located` messages; Phase 7 `ui.command`, `ui.command-result`, and `ui.service-status`.
- Executable services: prior components plus a context-policy source, serial transcription gate, alternate STT, alternate context selector, dedicated durable-capable active/history transcript and logged-item owners, the Phase 6 session lifecycle controller and folder locator, the Phase 5B serial model lane/local HTTP extractor/classifier, and finite-graph evidence observers.
- Demo graphs: concise-extractor, passthrough-extractor, Phase 4C working-document, Phase 4D finalized-context, Phase 5A logged-item ownership, and Phase 5B local-model variants.
- Runtime: Node 22+ orchestration host, trusted provider registry with Node active and `native`/`container` failing closed, per-component default-deny permissions enforced through the Node permission model, bounded queues, explicit supervisor policy, and Ajv as the single maintained validation dependency.
- Packaging: one deterministic inspectable artifact per graph under `runtime-output/package/`, recording manifests, contracts, component files, versions, and per-file integrity hashes.

## Known boundaries before a product build

- The HTML POC and Node architecture proof are not wired together.
- No microphone, audio capture, VAD, STT provider, production LLM provider/model, or model credentials are present. Phase 5B.1 uses only a deterministic loopback HTTP endpoint, and the model variables are allowlisted only to the components that require them.
- No package, SDK, real provider, production threshold, storage engine, or future desktop/product host has been selected for Phase 4; the browser/Node POC host is accepted and every remaining choice has an evidence trigger in `PENDING-DECISIONS.md`.
- The Phase 6 session filesystem, archive, close recovery, and folder locator are implemented as a local replaceable POC boundary; Phase 7 consumes only a storage/session availability projection and routes folder actions by session identity through a capability adapter.
- Finalized active transcript revisions are evicted from a bounded in-memory cache after durable acceptance and resolve through permanent history. This proves the POC bound without claiming production memory accounting.
- The revision, stale-result, logged-item proposal, lifecycle, and storage contracts are proven; delete behavior, backup, synchronization, encryption, migrations, and production durability are not present.
- Native/container providers, production transport selection/line-size bounds, cross-runtime memory accounting, and production thresholds are not present. The Phase 8 permission boundary is a real but partial sandbox: filesystem, child-process, worker, add-on, WASI, and heap restrictions are Node-runtime-enforced. Outbound endpoint configuration is adapter-restricted, but direct sockets are not contained because the installed Node build has no network permission flag.
- At-least-once replay identity and generic scheduler restart idempotency are proven. The Phase 5B graph's AI journal is in memory; a durable globally shared AI journal and durable logged-item/session owners must be coordinated with integrated application/storage work before production recovery.
- Optional classification remains a suggestion and its final review UI remains unresolved under `UI-001`.
- The browser drawer shows capability-neutral owner labels; it does not read or expose session file paths.
- The current browser implementation uses the internal word `derived` in some IDs/storage names; the user-facing product term is `Logged Item`.

The prioritized engineering backlog remains in the live repository's `TODO.md`. Phases 4A through 4F, Phase 5A/5B.1, Phase 6, and Phase 7 corrective revalidation are complete. Phase 8 behavior and packaging pass, with one terminology-only enforcement-matrix correction open before closeout; the Phase 7A editor-position bug is explicitly deferred. Actual native/OCI provider proofs remain evidence-triggered because their toolchains are not installed and must not be installed without authorization. Phase 9 observability has not started. Unresolved technology and product selections, including `APP-001`, `UI-001`, `UI-002`, `SEC-001`, `NAT-001`, and `CNT-001`, are governed by `PENDING-DECISIONS.md`.
