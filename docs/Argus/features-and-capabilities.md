# Argus Feature and Capability Catalog

This catalog describes the Argus POC as it exists on 2026-08-12. It distinguishes visible simulation from executable architecture so the prototype is not mistaken for a production implementation.

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
| Stable segment-ID provenance | Architecture proof / specified | Contracts carry provenance boundaries; the browser currently demonstrates ranges with timestamps. Durable archived lookup remains pending. | `context-window.schema.json`, `logged-item-draft.schema.json` |
| Model-backed extraction | Deferred | Two deterministic extractors prove replaceability; no LLM adapter is connected. | `services/log-extractor-*` |
| Automatic classification | Contracted / not model-wired | Classification is a separate optional suggestion, bound to the item revision, and is the lowest-priority workload in the global AI lane. It is not a live-list identity and has no current badge. | ADR-004; `classification.suggestion` |
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
| Durable filesystem persistence | Deferred | Browser storage is only a POC stand-in; active and permanent session stores are not implemented. |

## Session details and finalization

| Surface or control | Status | Current behavior |
| --- | --- | --- |
| Session-details drawer | UI POC | Shows session ID, state, created time, duration, entry counts, proposed storage path, and proposed session files. |
| Drawer close button | UI POC | Closes the drawer; the scrim and Escape key also close it. |
| Storage path control | UI POC | Copies the proposed session path and confirms it with a toast. |
| Session data preview | UI POC | Illustrates active transcript, active logged items, permanent history, and metadata artifacts. Names are illustrative, not an implemented disk contract. |
| Open session folder (footer and drawer) | UI POC / deferred integration | Demonstrates the interaction and explains that a desktop build will call the operating-system shell. No folder is opened in the browser. |
| Finalization summary | UI POC | Shows transcript/logged-item counts and warns that finalization prevents resume. |
| Keep session open | UI POC | Cancels finalization; the scrim and Escape key do the same. |
| Finalize & close | UI POC | Marks local state finalized, stops timers, persists, disables capture controls, and posts a confirmation. |
| Transactional finalization | Deferred | Temporary-to-permanent file movement, idempotency, and crash recovery remain to be implemented and tested. |

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
| Automated proof suite | Architecture proof | 78 tests cover all prior phases plus Phase 4D graph policy gating, four independent/coincident triggers, source/context ownership, scheduler routing, dual replacements, and partial isolation. |
| Contract compatibility policy | Architecture proof | Semver-based backward-compatible minor policy accepts retained 1.0.0 messages under current 1.1.0 consumers and rejects unknown newer minors or different majors. |
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
| Global AI execution lane | Architecture proof | A bounded JSON-lines journal supports concurrency one, non-preemptive completion, transcription/correction/extraction/enrichment priority, FIFO per workload, explicit overflow, retries, restart recovery, and completed-result replay. |

## Contract and service inventory

- Domain contracts: `audio.chunk`; `transcript.partial`, `transcript.word-committed`, `transcript.word-correction-proposed`, `transcript.utterance-boundary`, `transcript.correction-request`, `transcript.correction-resolved`, `transcript.segment`, `transcript.segment-update`, `transcript.segment-stored`, `transcript.history-append`, `transcript.history-appended`, and `transcript.context-window`; `logged-item.draft`, `logged-item.stored`, `logged-item.update`, `classification.suggestion`, and `classification.suggestion-accepted`.
- Control contracts: `transcript.context-policy`, `lifecycle.start`, `lifecycle.health-check`, `service.health`, `lifecycle.drain`, `service.drained`, `operation.completed`, `operation.rejected`, `service.failure`, `service.exited`, `dead-letter.message`, `workflow.completed`, `ai.work-request`, and `ai.work-completed`.
- Executable services: prior components plus a context-policy source, serial transcription gate, alternate STT, alternate context selector, and finite-graph evidence observer.
- Demo graphs: concise-extractor, passthrough-extractor, Phase 4C working-document, and Phase 4D finalized-context variants.
- Runtime: Node 22+ orchestration host, trusted provider registry with Node active, bounded queues, explicit supervisor policy, and Ajv as the single maintained validation dependency.

## Known boundaries before a product build

- The HTML POC and Node architecture proof are not wired together.
- No microphone, audio capture, VAD, STT provider, LLM provider, or model credentials are present.
- No package, SDK, real provider, production threshold, storage engine, or desktop host has been selected for Phase 4; each deferred choice has an evidence trigger in `PENDING-DECISIONS.md`.
- No durable session filesystem, archive, crash recovery, or operating-system folder integration is present.
- The revision and stale-result contracts are proven against an in-memory owner; durable domain storage, merge proposals, and delete behavior are not present.
- Native/container providers, transport line-size bounds, cross-runtime memory accounting, production thresholds, and a production security sandbox are not present.
- At-least-once replay identity and scheduler restart idempotency are proven. Durable logged-item/session owners must persist equivalent idempotency and revision state before production recovery.
- No optional classification review UI has been designed.
- The session path and files shown in the drawer are illustrative.
- The current browser implementation uses the internal word `derived` in some IDs/storage names; the user-facing product term is `Logged Item`.

The prioritized engineering backlog remains in the live repository's `TODO.md`. Phases 4A through 4D are complete; broader behavioral and recovery proofs are next in Phase 4E. Unresolved technology and product selections are governed by `PENDING-DECISIONS.md`.
