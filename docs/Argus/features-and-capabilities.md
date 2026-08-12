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
| Automatic classification | Deferred by decision | Classification is a separate, optional idle-time suggestion; it is not a live-list identity and has no current badge. | ADR-004 |
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
| Visible runtime participants | Architecture proof | `@session-controller`, `@supervisor`, `@result-collector`, and `@run-controller` occupy declared graph positions. |
| Finite intrinsic kernel authority | Architecture proof | Kernel is limited to hosting, streams, raw process lifecycle, shutdown mechanics, and validation. It has no implicit domain authority. |
| Explicit startup, failure, result, and completion paths | Architecture proof | Removing the corresponding wire makes the capability invalid or unavailable. |
| Transcript-to-logged-item vertical slice | Architecture proof | Fake transcript source → context-window selector → extractor → in-memory store. |
| Replaceable extractor | Architecture proof | Concise and passthrough implementations share one manifest/contract position and both complete the graph. |
| Structured trace output | Architecture proof | Service traces use standard error; domain/control messages use standard output. |
| Contract-valid failure outcome | Architecture proof | Invalid service input is converted into an explicit `service.failure` message routed to the supervisor. |
| Automated proof suite | Architecture proof | 29 tests cover governance, compatibility replay, schema validation, payload limits, canonical failures, service isolation, wiring invariants, plane separation, completion, and replaceability. |
| Contract compatibility policy | Architecture proof | Semver-based backward-compatible minor policy accepts retained 1.0.0 messages under current 1.1.0 consumers and rejects unknown newer minors or different majors. |
| Plane-breaking governance | Architecture proof | Catalog evolution checks reject a domain/control move unless the contract major version increases. |
| Contract ownership and history | Architecture proof | Every message declares an accountable owner and append-only message-specific changelog. |
| Maintained JSON Schema validation | Architecture proof | A single Ajv instance compiles schemas once when the graph registry loads and validates envelopes, payloads, manifests, and graphs at the runtime boundary. |
| Payload limits | Architecture proof | Every message has an explicit UTF-8 JSON payload limit; oversized messages are rejected before routing. |
| Generated contract reference | Architecture proof | Catalog/schema metadata generates `contracts/generated/contract-reference.md`; a drift check fails when it is stale. |
| Canonical failure outcome | Architecture proof | `service.failure` carries stable code/category, safe message, explicit retryability, and optional structured details over a declared control wire. |

## Contract and service inventory

- Domain contracts: `transcript.segment`, `transcript.context-window`, `logged-item.draft`, `logged-item.stored`.
- Control contracts: `lifecycle.start`, `service.failure`, `workflow.completed`.
- Executable services: fake transcript source, context-window selector, concise extractor, passthrough extractor, and in-memory logged-item store (four occupy any one demo graph).
- Demo graphs: concise-extractor and passthrough-extractor variants.
- Runtime: Node 22+ orchestrator and contract registry with Ajv as the single maintained validation dependency.

## Known boundaries before a product build

- The HTML POC and Node architecture proof are not wired together.
- No microphone, audio capture, VAD, STT provider, LLM provider, or model credentials are present.
- No durable session filesystem, archive, crash recovery, or operating-system folder integration is present.
- No user-edit revision contract, stale-result rejection, merge proposal, or delete behavior is present.
- No backpressure, health/readiness, restart policy, retry policy, dead-letter path, transport line-size bound, or production security sandbox is present.
- No optional classification review UI has been designed.
- The session path and files shown in the drawer are illustrative.
- The current browser implementation uses the internal word `derived` in some IDs/storage names; the user-facing product term is `Logged Item`.

The prioritized engineering backlog remains in the live repository's `TODO.md`. Contract governance is complete; runtime supervision is the next architecture phase. Session state and temporary transcript persistence remain the next recommended product vertical after the governance/runtime foundation.
