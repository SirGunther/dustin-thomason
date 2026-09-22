# SaySlate AI Provider and Tailscale Integration — Decisions

Requirements: [sayslate-ai-provider-tailscale-requirements.md](./sayslate-ai-provider-tailscale-requirements.md)

| ID | Decision | Why | Serves | Source | Supersedes or rejects |
| --- | --- | --- | --- | --- | --- |
| LD-001 | The connection control must support OpenAI, Anthropic Claude, Gemini, and a custom provider. | These are the provider families explicitly requested. | REQ-001, REQ-002, REQ-004 | [Original ticket](./sayslate-ai-provider-tailscale-original-ticket.md), paragraph 2 | Gemini-only configuration as the final feature |
| LD-002 | The first custom-provider target is LM Studio reached over Tailscale. | This is the explicit private-endpoint use case. | REQ-005, REQ-006 | [Original ticket](./sayslate-ai-provider-tailscale-original-ticket.md), paragraphs 1–2 | Public exposure as the primary path |
| LD-003 | Requests use JSON Schema output whenever the selected provider/model supports it. | The user explicitly requested schema output where possible rather than as an unconditional provider assumption. | REQ-007 | [Original ticket](./sayslate-ai-provider-tailscale-original-ticket.md), rough MVP | Unconditional JSON Schema support |
| LD-004 | Argus is read-only reference material for provider and LM Studio integration. | The user named its working integration as the reference implementation. | REQ-008 | [Original ticket](./sayslate-ai-provider-tailscale-original-ticket.md), paragraph 1 | Making SaySlate depend on Argus runtime code |
| LD-005 | Provider configurations must persist independently rather than one save replacing another provider. | The user explicitly identified provider replacement as unexpected behavior. | REQ-002, REQ-003 | Dustin Thomason, 2026-09-22 clarification | A single destructive active-provider record |
| LD-006 | One high-reasoning orchestrator owns architecture and oversight; low-reasoning agents receive bounded implementation tickets. | The workflow is intended to prevent low-tier agents from improvising architecture. | REQ-009 | [Original ticket](./sayslate-ai-provider-tailscale-original-ticket.md), orchestration paragraphs | Tierless unbounded implementation |
| LD-007 | Subagent completion is not an orchestration pause point. | The user explicitly rejected the earlier pause behavior. | REQ-010 | [Original ticket](./sayslate-ai-provider-tailscale-original-ticket.md), “ignore the pause portion” | Pausing after every subagent return |
| LD-008 | Checklists remain visible in chat, while durable implementation and review evidence lives in the artifact set. | The checklist is mandatory for visibility; evidence must survive chat. | REQ-011 | [Original ticket](./sayslate-ai-provider-tailscale-original-ticket.md); Dustin Thomason, 2026-09-22 clarification | Evidence only in chat |
| LD-009 | Every substantive completion or blocker sends the standard completion notification. | The user explicitly required the notification rule. | REQ-012 | [Original ticket](./sayslate-ai-provider-tailscale-original-ticket.md) | Silent completion |
| LD-010 | The work uses the `agentic-handoff` multi-file set nested under one ticket folder. | The user is testing this structure in place of the monolithic TODO. | REQ-013 | Dustin Thomason, 2026-09-22 clarification invoking `agentic-handoff` | The single-file TODO as the active orchestration contract |
| LD-011 | Objectives and findings use `State`, `Value`, `Evidence`, and `Depends on`. | The user identified the PRDV-16936 compact record as the correct reporting format. | REQ-014 | Dustin Thomason, 2026-09-22 clarification citing `PRDV-16936-CASE-DETAIL-PROTOTYPE-TODO.md` | Generic narrative evidence ledgers |
| LD-012 | Production-path evidence is required; a passing test alone does not establish correctness. | Tests must represent the real work failure point, not substitute for it. | REQ-015 | Dustin Thomason, 2026-09-22 clarification | Test-only correctness claims |
| LD-013 | `SirGunther/SaySlate` is the canonical implementation repository and `C:\SaySlate` is its local working location; the original PDProjects folder is preserved read-only. | The user explicitly selected the GitHub repository and requested a C-drive worktree beside Argus and WhisperService. | Process decision (`Serves: —`) | Dustin Thomason, 2026-09-22 clarification; commit `af9a2f3a8cbad88c22edc094767b5cdd31f1a24e` | Treating the original OneDrive folder as the writable implementation location |
| LD-014 | Provider profiles, including endpoints, model IDs, and API keys, persist in `chrome.storage.local` within the installed browser profile; switching providers preserves every configured profile. The data is not synced between installations, and no native credential host is introduced. | The user wants configuration to survive provider switching in one extension installation without adding a separate credential system. | REQ-002, REQ-003 | Dustin Thomason, 2026-09-22 clarification | Session-only re-entry, synchronized credentials, a native credential host, and a single destructive active-provider record |
| LD-015 | Gemini keeps the existing native Gemini adapter. It moves to an OpenAI-compatible transport only if a demonstrated incompatibility makes that necessary. | The current adapter works, so changing it without a real failure would add risk without user value. | REQ-001, REQ-007 | Dustin Thomason, 2026-09-22 clarification: “if it ain't broke, don't fix it” | Replacing the working Gemini adapter merely to unify transports |

## Numbered Open Decision Register

Numbers are permanent chat references. Resolved entries remain here for posterity, point to their
locked decision, and are never removed, migrated, reused, reordered, or renumbered. New questions
receive the next integer. Unresolved decisions must not be delegated to a low-reasoning
implementation agent.

### 1. Provider-profile persistence
**State:** Resolved
**Value:** Resolved as LD-014.
**Evidence:** Dustin Thomason, 2026-09-22 clarification.
**Depends on:** —

### 2. Gemini transport
**State:** Resolved
**Value:** Resolved as LD-015.
**Evidence:** Dustin Thomason, 2026-09-22 clarification; EV-005.
**Depends on:** —

### 3. Long-running inference ownership
**State:** Unresolved
**Value:** How should an inference request survive real LM Studio responses longer than Chrome's documented service-worker fetch-response lifetime?
**Evidence:** EV-006 and EV-011 establish the current worker boundary and the documented lifetime risk; no production mechanism has been confirmed.
**Depends on:** Inference boundary and live acceptance ticket.

### 4. Custom-origin permissions
**State:** Unresolved
**Value:** Should custom HTTPS origins be granted at install time or requested individually as optional host permissions when a user configures a provider?
**Evidence:** EV-001 and EV-012 establish the fixed current allow-list and Chrome's cross-origin permission requirement.
**Depends on:** Manifest and provider-settings UX ticket.

### 5. Connection-test semantics
**State:** Unresolved
**Value:** What exact checks establish reachability, authentication, model usability, and structured-output compatibility for each provider family?
**Evidence:** REQ-004 requires a useful result; a model-list response alone does not prove inference behavior.
**Depends on:** Connection-test ticket and acceptance criteria.

### 6. Delivery order
**State:** Unresolved
**Value:** What ticket order and wave structure should the orchestrator enforce after the material architecture decisions are resolved?
**Evidence:** The prior monolithic artifact called its ticket list provisional; no replacement order has been confirmed.
**Depends on:** Ticket files and handoff.

### 7. Canonical repository and local base
**State:** Resolved
**Value:** Resolved as LD-013.
**Evidence:** EV-016; Dustin Thomason, 2026-09-22 clarification.
**Depends on:** —
