# Implement Prompt Injection for Note Refinement - Original Ticket

## Capture Metadata

| Field | Value |
| --- | --- |
| Project | WorkLists |
| Ticket slug / ID | prompt-injection-note-refinement |
| Captured on | 2026-07-31 |
| Source | User-provided request |
| Formatting | Lightly formatted for Markdown; original headings and wording retained |

## Original Request

# Implement Prompt Injection for Note Refinement

### Problem

Currently, there is inconsistent or accidental behavior regarding prompt injection within the notes pane. Users lack a structured way to trigger further actions or sub-note creation without impacting the primary parent card's content or state.

### Requirement

Develop a feature that allows prompt injection directly at the card level. This must facilitate:

- Creation of sub-notes from the top-level card.
- Creation of sub-notes from existing sub-notes.
- Contextual awareness to include the entire thread (parent card + all sub-notes) or specific segments for refinement.

### Solution

Introduce a designated 'Prompt Injection' field or interface within the notes pane. By separating the logic, users gain the flexibility to perform iterative refinements, generate new content, or trigger automated workflows based on the established context without polluting the primary card data.

**Estimation:** 5 Sprint Points.

# Floating Context Window Implementation Vision

## Core Objective

Develop a transient, floating context window that assists in prompt injection for cards and notes without obscuring actionable text. The window remains adjacent to the active field.

## Functional Requirements

- **Transient Nature:** Prompt injections are not saved; once the action is completed and the user moves on, the context is cleared.
- **Undo Mechanism:** If an AI response is unsatisfactory, an "Undo" action restores the original prompt text to the injection window, allowing for refinement rather than discarding work.
- **Input Methods:** Support for manual entry (standard line breaks via `Enter`), voice-to-text, and `Ctrl+Shift+Enter` for automatic submission.
- **Persistence:** Maintain parity with existing card/note functionality.
- **Access:** Accessible via an ellipse menu or keyboard shortcut.

## Key Bindings

- **Activation Shortcut:** Proposed `Ctrl+Shift+Plus` (to avoid standard `Print` command conflicts) or `Ctrl+Shift+Quote`.
- **Workflow:** When triggered during edit mode, the system saves the current state and opens the transient window with the cursor ready for input.

## Explicit Constraints In Original Request

- Prompt injection must not pollute primary card data.
- The injection surface is transient and adjacent to the active field.
- Undo restores the original injection prompt.
- `Enter` inserts line breaks; `Ctrl+Shift+Enter` submits.
- Support voice-to-text.
- Provide ellipsis-menu or keyboard-shortcut access.

## Context Paths In Original Request

- `C:\\dustin-thomason\\agents`
- `C:\\dustin-thomason\\agents\\skills\\investigation\\SKILL.md`
- `C:\\dustin-thomason\\agents\\docs\\problem-check.md`
- `C:\\dustin-thomason\\agents\\docs\\investigation-question-coverage.md`
- `C:\\dustin-thomason\\agents\\docs\\investigation-software-gaps.md`
- `C:\\dustin-thomason\\agents\\docs\\investigation-report.md`
- `C:\\dustin-thomason\\.claude\\skills\\grill-me\\SKILL.md`
- `C:\\dustin-thomason\\agents\\rules\\spec-writing.md`

## Downstream Artifacts

- Investigation: `investigations/prompt-injection-note-refinement-investigation.md`
- Spec: `specs/prompt-injection-note-refinement-spec.md`
- Q and A ledger: `qa/prompt-injection-note-refinement-qa-ledger.md`
