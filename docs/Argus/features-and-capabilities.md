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
| Session state indicator | UI POC | Changes appearance for stopped, recording, and finalized states. | `#sessionStateDot`, `updateSessionUI()` |
| Session time | UI POC | Displays elapsed capture time and advances while recording. | `#elapsedTime`, `startTimers()` |
| Record | UI POC | Starts or resumes simulated capture, advances time, and appends sample transcript/logged items. Disabled while recording or after finalization. | `#recordButton`, `beginRecording()` |
| Stop | UI POC | Stops capture without finalizing; current browser state remains resumable. | `#stopButton`, `stopRecording()` |
| Close session | UI POC | Opens a deliberate finalization confirmation instead of immediately ending the session. | `#closeSessionButton`, `openCloseModal()` |
| Two-pane workspace | UI POC | Places Raw Transcript and Logged Items side by side at desktop widths. | `.workspace` |
| Narrow-window fallback | UI POC | Stacks panes vertically below 840 px and simplifies selected header/footer content. | CSS media queries |
| Playback controls | Deferred by requirement | No playback control is included. | Initial UI requirements |

## Raw Transcript pane

| Surface or control | Status | Current behavior | Implementation reference |
| --- | --- | --- | --- |
| Entry count | UI POC | Displays the number of transcript rows with singular/plural wording. | `#transcriptCount` |
| Select all / Clear all | UI POC | Selects or clears every transcript row; selection survives incoming rows and local reloads. Hidden at compact widths. | `.select-all-button[data-kind="transcript"]` |
| Copy selected | UI POC | Copies selected transcript rows in their source order and reports the count in a toast. Disabled with no selection. | `#copyTranscriptSelected`, `batchCopy()` |
| Row selection checkbox | UI POC | Selects one transcript entry and persists that selection. | Row template checkbox |
| Timestamp | UI POC | Shows the entry's capture time. | Row template `<time>` |
| Editable transcript text | UI POC | Supports direct editing, autosaves non-empty input, and restores the previous value if left empty. Ctrl/Cmd+Enter commits by leaving edit mode. | `.editable-text` |
| Individual copy | UI POC | Copies one row, shows a temporary copied state, and posts a notification. | `.row-copy` |
| Native text selection | UI POC | Browser text selection remains available inside editable row content. | `.editable-text` |
| Independent live scrolling | UI POC | Follows new transcript only when this pane is at the bottom. Scrolling upward preserves the user's position. | `paneState.transcript` |
| Jump to live | UI POC | Appears when the user leaves the bottom, reports unseen rows, and restores live following. | `#transcriptJump` |
| Real speech-to-text stream | Deferred | The POC appends deterministic sample content; no microphone, VAD, or STT provider is connected. | `liveSamples`, `addLiveSample()` |
| Edited text supplied to later model calls | Specified | Edits are authoritative in browser state, but no live model is connected yet. | UI requirements; architecture backlog |
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
| Source context range | UI POC | Shows the first/last transcript timestamps considered for the item. Selecting it scrolls to and temporarily highlights matching transcript rows. | `.source-range`, `showSourceContext()` |
| Missing active source handling | UI POC | Reports when the source transcript is outside the currently rendered window. | `showSourceContext()` |
| Editable logged text | UI POC | Supports direct editing and autosave; non-empty user text becomes current browser state. | `.editable-text` |
| Individual copy | UI POC | Copies one item with optional timestamp and posts a toast. | `.row-copy` |
| Simulated extraction delay | UI POC | Adds a concise logged item shortly after each simulated transcript segment. | `addLiveSample()` |
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
| Browser autosave | UI POC | Stores transcript, logged items, edits, selection, session state, elapsed time, and timestamp preference in `localStorage`. |
| Save-state feedback | UI POC | Shows “Saving changes…” and then “All changes saved.” |
| Top-center toast region | UI POC | Stacks transient notifications in header negative space so new live rows remain unobscured. |
| Reduced-motion support | UI POC | Respects the operating system/browser reduced-motion preference. |
| Durable filesystem persistence | Architecture proof — Phase 6 POC / UI integration deferred | The architecture POC persists session metadata, active transcript/logged-item snapshots, append-only permanent histories, and close evidence through the root-scoped filesystem boundary. The browser UI is not wired to it. |

## Session details and finalization

| Surface or control | Status | Current behavior |
| --- | --- | --- |
| Session-details drawer | UI POC | Shows session ID, state, created time, duration, entry counts, proposed storage path, and proposed session files. |
| Drawer close button | UI POC | Closes the drawer; the scrim and Escape key also close it. |
| Storage path control | UI POC | Copies the proposed session path and confirms it with a toast. |
| Session data preview | UI POC | Shows the Phase 6 artifact names as a UI preview; the browser is not directly authorized to read them. |
| Open session folder (footer and drawer) | UI POC / deferred integration | Demonstrates the interaction and explains that a desktop build will call the operating-system shell. No folder is opened in the browser. |
| Finalization summary | UI POC | Shows transcript/logged-item counts and warns that finalization prevents resume. |
| Keep session open | UI POC | Cancels finalization; the scrim and Escape key do the same. |
| Finalize & close | UI POC | Marks local state finalized, stops timers, persists, disables capture controls, and posts a confirmation. |
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
| Automated proof suite | Architecture proof | 107 tests pass in the final full gate; focused Phase 6 and Phase 4E suites cover lifecycle, storage, recovery, locator authority, eviction/reload, bounded queues, and long-monologue closure. |
| Contract compatibility policy | Architecture proof | Semver-based backward-compatible minor policy governs catalog 1.8.0, accepts retained 1.0.0 messages where compatible, and rejects unknown newer minors or different majors. |
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

## Contract and service inventory

- Domain contracts: `audio.chunk`; `transcript.partial`, `transcript.word-committed`, `transcript.word-correction-proposed`, `transcript.utterance-boundary`, `transcript.correction-request`, `transcript.correction-resolved`, `transcript.segment`, `transcript.segment-update`, `transcript.segment-stored`, `transcript.history-append`, `transcript.history-appended`, and `transcript.context-window`; `logged-item.draft`, `logged-item.stored`, `logged-item.update`, `logged-item.history-append`, `logged-item.history-appended`, `logged-item.update-proposed`, `logged-item.proposal-resolve`, `logged-item.proposal-resolved`, `classification.suggestion`, and `classification.suggestion-accepted`.
- Control contracts: `transcript.context-policy`, `lifecycle.start`, `lifecycle.health-check`, `service.health`, `lifecycle.drain`, `service.drained`, `operation.completed`, `operation.rejected`, `service.failure`, `service.exited`, `dead-letter.message`, `workflow.completed`, `ai.work-request`, `ai.work-completed`, and the Phase 6 `session.record`, `session.recorded`, `session.stop`, `session.stopped`, `session.resume`, `session.resumed`, `session.close`, `session.closed`, `session.folder-locate`, and `session.folder-located` messages.
- Executable services: prior components plus a context-policy source, serial transcription gate, alternate STT, alternate context selector, dedicated durable-capable active/history transcript and logged-item owners, the Phase 6 session lifecycle controller and folder locator, the Phase 5B serial model lane/local HTTP extractor/classifier, and finite-graph evidence observers.
- Demo graphs: concise-extractor, passthrough-extractor, Phase 4C working-document, Phase 4D finalized-context, Phase 5A logged-item ownership, and Phase 5B local-model variants.
- Runtime: Node 22+ orchestration host, trusted provider registry with Node active, bounded queues, explicit supervisor policy, and Ajv as the single maintained validation dependency.

## Known boundaries before a product build

- The HTML POC and Node architecture proof are not wired together.
- No microphone, audio capture, VAD, STT provider, production LLM provider/model, or model credentials are present. Phase 5B.1 uses only a deterministic loopback HTTP endpoint, and the model variables are allowlisted only to the components that require them.
- No package, SDK, real provider, production threshold, storage engine, or desktop host has been selected for Phase 4; each deferred choice has an evidence trigger in `PENDING-DECISIONS.md`.
- The Phase 6 session filesystem, archive, close recovery, and folder locator are implemented as a local replaceable POC boundary; browser/desktop folder opening and UI integration remain separate work.
- Finalized active transcript revisions are evicted from a bounded in-memory cache after durable acceptance and resolve through permanent history. This proves the POC bound without claiming production memory accounting.
- The revision, stale-result, logged-item proposal, lifecycle, and storage contracts are proven; delete behavior, backup, synchronization, encryption, migrations, and production durability are not present.
- Native/container providers, production transport selection/line-size bounds, cross-runtime memory accounting, production thresholds, and a production security sandbox are not present.
- At-least-once replay identity and generic scheduler restart idempotency are proven. The Phase 5B graph's AI journal is in memory; a durable globally shared AI journal and durable logged-item/session owners must be coordinated with integrated application/storage work before production recovery.
- No optional classification review UI has been designed.
- The session path and files shown in the drawer are illustrative.
- The current browser implementation uses the internal word `derived` in some IDs/storage names; the user-facing product term is `Logged Item`.

The prioritized engineering backlog remains in the live repository's `TODO.md`. Phases 4A through 4F and Phase 5A/5B.1 are complete for review; Phase 4E still has only the active-history bound left open. Phase 6 and later phases have not started. Unresolved technology and product selections are governed by `PENDING-DECISIONS.md`.
