# Argus Product and Layout Decisions

This is the canonical decision register for visible product behavior and layout. Detailed payload examples and runtime rules remain beside the implementation in `Architecture\DesignDecisions.md` and `Architecture\RuntimeKernelAndPlanes.md`.

Statuses are **Accepted**, **Proposed**, **Open**, or **Superseded**. A later decision must explicitly supersede an earlier one; prior rationale remains part of the record.

## Decision register

| ID | Status | Decision | Reason and consequence |
| --- | --- | --- | --- |
| PD-001 | Accepted | The live primary output is a neutral **Logged Item**. | Extraction should capture useful meaning without making an uncertain category look authoritative or enlarging every row. |
| PD-002 | Accepted | Every logged item exposes the exact transcript source range considered. | A concise item must remain auditable and recoverable in context; persistent contracts use stable segment IDs while the UI displays timestamps. |
| PD-003 | Accepted in principle | Extraction is chunk-driven and off the word-by-word transcription path. | Coherent windows reduce noise, cost, and unstable output. Pause, size, topic, and maximum-latency thresholds still need measurement. |
| PD-004 | Proposed | Classification is a separate optional idle-time suggestion. | A category can use the exact source range plus bounded surrounding context without delaying capture. Suggestions may not silently mutate logged items. |
| PD-005 | Accepted for POC | Toasts occupy top-center negative space. | Notifications remain visible without covering the newest transcript or logged items at the bottom of either pane. |
| PD-006 | Accepted | Desktop layout uses two equal, independently scrolling panes. | Transcript and extracted meaning can be compared continuously while preserving separate live-follow state. |
| PD-007 | Accepted | Rows are compact horizontal records with selection, time/provenance, editable text, and copy action. | High information density supports long live sessions while keeping all actions associated with one row. |
| PD-008 | Accepted | Stop and Close Session are different operations. | Stop preserves resumable working state; Close is an explicit, irreversible finalization boundary. |
| PD-009 | Accepted | Finalization requires a confirmation modal with record counts. | A destructive lifecycle transition should be deliberate and show what is being finalized. |
| PD-010 | Accepted | Session metadata and storage are disclosed in a side drawer. | Operational detail is available on demand without consuming the primary live workspace. |
| PD-011 | Accepted | Copy behavior is available per row and per selected batch, with one global timestamp preference. | Fast extraction from the session is a primary workflow; a shared preference keeps output predictable. |
| PD-012 | Accepted | Autosave is the normal path; there is no routine Save button. | Live capture should not require manual persistence steps. Save status remains visible. |
| PD-013 | Accepted | Scrolling upward pauses live following only for that pane; Jump to live restores it. | Reading earlier material must not be disrupted, and activity in one pane must not seize the other pane's scroll position. |
| PD-014 | Accepted for POC | Narrow layouts stack the two panes and reduce secondary chrome. | The POC remains inspectable below desktop width without redesigning the core information hierarchy. |
| PD-015 | Accepted | Playback controls are absent. | Playback was explicitly outside the initial interface requirement. |
| PD-016 | Open | Row deletion and recovery semantics. | The current POC supports editing but not deleting. The product must decide soft delete versus permanent removal and preserve transcript/log provenance. |
| PD-017 | Open | Where classification suggestions are reviewed and what acceptance affects. | No badge belongs in the primary list until edit/review, export, filtering, and automation behavior are understood. |
| PD-018 | Accepted for architecture POC | Browser folder actions remain honest simulations until a desktop shell owns OS integration. | HTML alone cannot safely prove the packaged filesystem capability. |
| AD-001 | Accepted and implemented | Domain and control messages use separate explicit, default-deny planes. | Startup, supervision, result collection, and completion remain visible architecture instead of hidden orchestrator behavior. |
| AD-002 | Accepted and implemented | Runtime mechanics have a finite documented authority boundary. | The kernel may host and validate processes/messages but may not invent, interpret, or bypass domain behavior. |
| AD-003 | Accepted and implemented | Components are replaceable only through versioned contracts and compatible declared ports. | A drop-in claim is demonstrated by substituting extractors in the same graph position and rerunning the same tests. |
| AD-004 | Accepted direction; proof pending | Argus is polyglot and container-capable by architectural intent; Node remains the baseline orchestrator but not a required component language. | Trusted runtime providers must preserve contracts, explicit wires, supervision, state/side-effect declarations, permissions, and shared conformance tests. Current executable truth remains Node-only until a native and container replacement proof passes. |

## Superseded directions retained for context

| Former direction | Replaced by | Why it changed |
| --- | --- | --- |
| Show task, note, observation, or idea as the primary identity of every extracted row. | PD-001 and PD-004 | It merged extraction with classification, overstated model certainty, and added visual weight. |
| Place toast notifications near the incoming list content. | PD-005 | A growing stack could obscure the live working area; the header has more suitable negative space. |
| Let the orchestrator implicitly own startup, failures, terminal results, or completion. | AD-001 and AD-002 | Hidden operational authority violated the architecture's explicit wiring and replaceability goals. |

## Visual hierarchy

The current layout intentionally reads in this order:

1. **Session identity and capture state** in the header.
2. **Raw evidence** in the left pane.
3. **Succinct logged meaning plus provenance** in the right pane.
4. **Persistence and export status** in the footer.
5. **Detailed session/storage information** in an on-demand drawer.
6. **Irreversible finalization** in a focused modal.

The dark, compact presentation is optimized for a long-running desktop companion: muted structural chrome, bright state/accent colors, monospaced timestamps, complete-row hover/selection/edit states, and motion limited by the user's reduced-motion preference.

## Decision update rule

When product testing changes a direction:

1. Add a new row with a new ID.
2. Mark the old row **Superseded** rather than deleting it.
3. State the evidence or user problem that caused the change.
4. Update the capability catalog and the live code-adjacent ADR when contracts or runtime behavior are affected.
5. Record the implementation and verification in the newest changelog entry.
