# Prompt Injection for Note Refinement - Q and A Ledger

## Purpose

This ledger preserves Phase 3 decisions and corrections that govern the prompt-injection specification. It is downstream of `../original-ticket.md`; the original ticket remains unchanged as the baseline fact.

## Locked Decisions

| ID | Locked decision | Source | Supersedes or rejects | Spec destination |
| --- | --- | --- | --- | --- |
| LD-001 | Prompt Injection is a new, distinct feature. It is not the existing automatic note-refinement flow. | User clarification | Reuses of the existing refine feature as the product concept | Problem, terminology, UI behavior |
| LD-002 | A submission changes only the current selected target: the current card text or current selected note. It must not modify any other card or note. | User clarification; correction | Full-thread or multi-note mutation interpretations | Target and mutation boundaries |
| LD-003 | Existing note refinement remains unchanged. Prompt Injection has its own entry point in the notes-pane ellipsis menu. | User clarification; original ticket | Replacing or relabeling the existing refine action | UI entry points and protected neighbors |
| LD-004 | The injection instruction is transient. It is not persisted as card or note content. | Original ticket; user clarification | Persisted prompt-field designs | Client state and persistence boundary |
| LD-005 | When invoked during edit mode, save the current note state first, then open the focused transient injection window. | Original ticket | Opening over unsaved note state | Invocation flow |
| LD-006 | `Enter` inserts a line break. `Ctrl/Cmd+Shift+Enter` submits once the injection window has focus. Voice-to-text is supported in that window. | Original ticket; user clarification | Using the submit chord as activation or treating Enter as submit | Keyboard and voice behavior |
| LD-007 | Undo restores the prior saved note text and reopens the injection window with the original instruction text, so the user can revise and resubmit. | Original ticket; user clarification | Undo that only restores note text or discards the injection text | Undo state and acceptance criteria |
| LD-008 | The model request is composed from the current note text plus the transient injection text through a dedicated concatenation helper. The raw current note text remains the stale-write guard and undo source. | User clarification | Treating injection text as durable note data or source text replacement | AI payload and server composition |
| LD-009 | No other notes are included as context or changed by this feature. The prompt-injection scope is the current note only. | User clarification | Parent-card, sibling-note, and full-thread context paths | Context boundary and non-goals |
| LD-010 | `Ctrl/Cmd+Shift+Quote` opens Prompt Injection. The notes-pane ellipsis-menu action remains the visible access path. | User approval | `Ctrl/Cmd+Shift+Plus` activation option | Keyboard behavior and UI entry points |

## Rejected Paths

| ID | Rejected path | Reason / source |
| --- | --- | --- |
| RP-001 | Treat Prompt Injection as automatic note refinement. | User: it is a new feature, not auto refine. |
| RP-002 | Touch the parent card, sibling notes, or the full note thread. | User: this introduces unnecessary complexity and was never required for the clarified feature. |
| RP-003 | Use the existing refine action as the entry point. | User: the feature is accessed through the ellipsis menu. |
| RP-004 | Persist the prompt text in note or card data. | Original ticket: prompt injections are transient. |

## Open Variables

| ID | Variable | Current evidence | Next action |
| --- | --- | --- |
| None | None | All material behavior is established by the original ticket, current system behavior, and locked decisions. | Proceed to spec. |

## Traceability Check

- Existing note refine behavior remains a protected neighbor.
- The spec must state that Prompt Injection only targets the current selected note.
- The spec must include transient-window, undo restoration, voice, multiline, ellipsis-menu, and shortcut acceptance criteria.
- No rejected path may return as an implementation alternative without an explicit user reopening it.
