# SaySlate Per-Pass Reasoning — Decisions

Requirements: [sayslate-pass-reasoning-requirements.md](./sayslate-pass-reasoning-requirements.md)

| ID | Decision | Why | Serves | Source | Supersedes or rejects |
| --- | --- | --- | --- | --- | --- |
| LD-001 | The work is delivered as the `agentic-handoff` document set in `docs/SaySlate/tickets/sayslate-pass-reasoning/`. | The user asked for "the same sort of ticket and everything" as the status badge set. | — | [Original ticket](./sayslate-pass-reasoning-original-ticket.md), message 2 | — |
| LD-002 | Each pass's setting is a boolean in `sayslate-grammar-config`: `firstPassReasoning` and `secondPassReasoning`. Only a stored `true` reads as on, so a missing or other value reads as off. Both normalizers carry both fields: `normalizeProcessingConfig` in `app.js` and `normalizeConfig` in `floating.js`. `PROMPT_SCHEMA_VERSION` stays 3, and no migration is added. | Each pass needs its own setting (REQ-001), and both surfaces read this record (EV-013). A normalizer that omits the fields would drop them on the next write (EV-007). A missing field already reads as off, so existing records need no migration (EV-008). Off keeps today's behavior, which the user chose (EV-006). | REQ-001, REQ-003 | Resolved from sources, open decision 2: REQ-001; EV-006, EV-007, EV-008, EV-013 | Amends LD-038(1) of the AI-provider decisions (EV-014): the record also carries these two fields |
| LD-003 | `SaySlateAIProviderClient.generate` accepts an optional boolean `reasoning`, default `false`. The four provider kinds handle it as follows: <ul><li>**Custom:** sends `reasoning_effort: "medium"` when `reasoning` is `true` and `"none"` otherwise, on the structured request only.</li><li>**OpenAI:** still sends no `reasoning_effort`.</li><li>**Gemini and Anthropic:** do not receive `reasoning`, and their request bodies are unchanged.</li><li>**The HTTP 400/422 schema-free retry:** keeps sending only the model and messages (EV-002).</li></ul> The adapter already sends `reasoningEffort` when it is given one, so `openAICompatibleClient.js` does not change. | The user limited the setting to LM Studio (REQ-002) and wants it on every LM Studio request (REQ-003). "medium" is used because every non-`"none"` value turns thinking on and no level is proven to differ ("Treat it as an on/off switch."), so the middle accepted value meets the on/off requirement without claiming that a level matters (EV-005). | REQ-002, REQ-003 | [Original ticket](./sayslate-pass-reasoning-original-ticket.md), message 2 (REQ-002, REQ-003); the value and the retry rule resolved from sources, open decision 1: EV-002, EV-005 | LD-041's fixed `"none"` for Custom profiles, which is now the off value |
| LD-004 | The prompt panel gets two switches built from the existing `.pass-toggle` pattern. <ul><li>**First pass:** the "First-pass prompt" label moves into a `.pass-setting-header` row holding `firstPassReasoningState` and `firstPassReasoningInput` (`role="switch"`, `aria-label="Use reasoning for the first pass"`).</li><li>**Second pass:** its header keeps the Enabled switch and adds `secondPassReasoningState` and `secondPassReasoningInput` (`aria-label="Use reasoning for the second pass"`).</li><li>**State word:** each reads "Reasoning on" or "Reasoning off".</li><li>**Saving:** each saves as soon as it changes, with the toast "First-pass reasoning on" / "…off" (or "Second-pass …"), and also with **Save prompts**. A failed save restores the previous value and shows "The browser could not save the reasoning setting."</li><li>**Second pass off:** the second-pass reasoning switch stays usable and keeps its value.</li><li>**Help lines:** each pass's help line ends with "Reasoning applies only to Custom (LM Studio) connections."</li></ul> | The user asked for a toggle on each prompt, with the second pass's beside its enable switch (REQ-001). Reusing the second-pass switch's markup, save behavior, and failure handling keeps one switch pattern in the panel (EV-009, EV-010, EV-011). Turning the second pass off already keeps its prompt usable, so its reasoning setting follows the same rule (EV-010). The panel states each control's effect in its help line (EV-009), and REQ-002 is the effect to state. | REQ-001, REQ-002 | [Original ticket](./sayslate-pass-reasoning-original-ticket.md), message 2 (REQ-001, REQ-002); layout and behavior resolved from sources, open decision 3: EV-009, EV-010, EV-011 | — |
| LD-005 | Floating Slate uses the saved per-pass settings on both its passes, including Finish and the ChatGPT send, and has no reasoning controls of its own. Each of its `generate` calls passes the matching setting, which its live storage listener keeps current. | "Anything that goes through" (REQ-003) includes Floating Slate, which runs on the settings saved on the full page and has no prompt controls (EV-013). | REQ-003 | [Original ticket](./sayslate-pass-reasoning-original-ticket.md), message 2 (REQ-003); resolved from sources, open decision 4: EV-013 | — |
| LD-006 | The documentation changes with the behavior. <ul><li>**`CHANGELOG.md`:** the `[Unreleased]` line saying Custom profiles always send `"none"` (EV-015) is rewritten to describe the per-pass reasoning switches, off by default.</li><li>**`README.md`:** the second-pass toggle paragraph gains one sentence on the reasoning switches.</li><li>**Endpoint doc:** after the last ticket merges, the orchestrating agent updates the "Reasoning (thinking)" section of the LM Studio endpoint doc to match.</li></ul> | Those three texts would otherwise describe behavior this work changes (EV-015). The changelog records pending changes, and the README holds current capability text (EV-023). | REQ-001, REQ-002 | Resolved from sources: EV-015, EV-023 | — |
| LD-007 | Custom (LM Studio) passes stream, and their timeout measures silence instead of total time. <ul><li>**Dispatcher:** in the `OPENAI_CHAT_COMPLETIONS` case, passes `stream: true` to the adapter for Custom profiles, with reasoning on or off, and nothing for OpenAI profiles.</li><li>**Adapter, `stream` true:** the structured request carries `stream: true`. The abort timer restarts whenever the response headers or a body chunk arrive, so `request_timeout` means `timeoutMs` (still 90 s by default) passed with nothing received. A `text/event-stream` response is read as server-sent events: `choices[0].delta.content` is concatenated, `delta.reasoning_content` is ignored, a `delta.refusal` or an `error` payload is a `provider_error`, an unparseable `data:` line is a `malformed_response`, and the concatenated content goes through the existing canonical `{ text }` validation. A response that is not `text/event-stream` goes through the existing JSON path unchanged.</li><li>**Adapter, `stream` false (OpenAI):** behavior and request body are unchanged.</li><li>**Schema-free retry:** unchanged; its body stays the model and messages only (EV-002).</li></ul> | REQ-004. A total-time budget cannot fit a generation whose length the model chooses, with reasoning on or off (EV-025, EV-029). LM Studio streams this exact request shape and sends a chunk at least every 840 ms while it works (EV-028), so silence separates a working server from a stopped one. Keeping 90 s as the silence limit preserves today's wait for a server that never answers. Streaming only Custom profiles keeps REQ-002's LM Studio-only scope. | REQ-004 | [Original ticket](./sayslate-pass-reasoning-original-ticket.md), message 4; resolved from sources: EV-025, EV-028, EV-029 | Amends LD-003's "OpenAI-compatible adapter does not change" for Custom requests; OpenAI requests stay unchanged |

## Open Decision Checklist

- [x] 1. What does SaySlate send to LM Studio when a pass has reasoning on, and what does the schema-free retry send? — Resolved from sources as LD-003
- [x] 2. Where is each pass's reasoning setting stored, and what is its default? — Resolved from sources as LD-002
- [x] 3. What do the switches look like, how do they save, and does the second-pass switch lock when the second pass is off? — Resolved from sources as LD-004
- [x] 4. Does Floating Slate get its own reasoning switches? — Resolved from sources as LD-005

## Open Decision Register

### 1. The value sent when reasoning is on

**State:** Resolved
**Value:** Resolved as LD-003.
**Investigation:**
- **Dispatcher:** it fixes `"none"` for Custom profiles today (EV-001).
- **Adapter:** it sends whatever effort it is given, on the structured request only, and its retry sends only the model and messages (EV-002).
- **LM Studio:** the request field overrides the saved setting, every non-`"none"` value turns thinking on, and no level is proven to differ (EV-005, `docs/tailscale/sayslate-lmstudio-endpoint.md:95-101`).
- **Other providers:** OpenAI rejects the field on non-reasoning models (EV-006).

**Why user input is required:** Not required. The user asked for on/off (REQ-001), and EV-005 shows every "on" value behaves the same.
**Recommendation:** Send `"medium"` when on and `"none"` when off, for Custom profiles only, and leave the retry body unchanged.
**Evidence:** EV-001, EV-002, EV-005, EV-006
**Depends on:** —

### 2. Storage and default

**State:** Resolved
**Value:** Resolved as LD-002.
**Investigation:**
- **Storage and normalizers:** both surfaces read `sayslate-grammar-config`, and each normalizer drops fields it does not name (EV-007, EV-013).
- **Migration:** it runs only below schema version 3 and touches only prompt text (EV-008).
- **Current behavior:** Custom profiles send `"none"`, which the user chose on 2026-09-23 (EV-006).
- **Record contents:** the record's contents were limited to prompt fields and `secondPassEnabled` (EV-014).

**Why user input is required:** Not required. The record, its readers, and today's behavior determine the storage location and the default.
**Recommendation:** Two booleans in the existing record, defaulting to off, with no schema bump or migration.
**Evidence:** EV-006, EV-007, EV-008, EV-013, EV-014
**Depends on:** —

### 3. Switch layout and behavior

**State:** Resolved
**Value:** Resolved as LD-004.
**Investigation:**
- **Existing switch:** the panel's one switch is the second pass's `.pass-toggle` in a `.pass-setting-header` row (EV-009, `app.html:187-193`). It saves on change and on **Save prompts**, shows a state word and a toast, and restores on a failed save (EV-010, `app.js:645-664`).
- **Second pass off:** turning the second pass off keeps its prompt editable (EV-010).
- **Help lines:** each help line states its controls' effect (EV-009, `app.html:185,201`).
- **Styles:** they already exist for the pattern (EV-011).

**Why user input is required:** Not required. REQ-001 places the switches, and the panel's existing switch sets how they look and save.
**Recommendation:** Reuse the second-pass switch pattern for both reasoning switches, keep the second-pass reasoning switch usable when that pass is off, and state the LM Studio limit in each help line.
**Evidence:** EV-009, EV-010, EV-011
**Depends on:** —

### 4. Floating Slate controls

**State:** Resolved
**Value:** Resolved as LD-005.
**Investigation:** Floating Slate reads the saved record, reloads it on storage changes, and calls the same dispatcher for both passes. It has no prompt controls and uses the settings saved on the full page (EV-013, `floating.js:44-60,253-256,292-295,449-454`; `README.md:65`).
**Why user input is required:** Not required. REQ-003 covers every request, and the overlay's existing settings model answers where the control lives.
**Recommendation:** Floating Slate applies the saved settings and adds no controls.
**Evidence:** EV-013
**Depends on:** —
