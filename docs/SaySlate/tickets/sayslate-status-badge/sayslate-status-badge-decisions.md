# SaySlate Status Badge — Decisions

Requirements: [sayslate-status-badge-requirements.md](./sayslate-status-badge-requirements.md)

| ID | Decision | Why | Serves | Source | Supersedes or rejects |
| --- | --- | --- | --- | --- | --- |
| LD-001 | The work is delivered as the `agentic-handoff` document set in `docs/SaySlate/tickets/sayslate-status-badge/`. | The user named the skill and the SaySlate documents area. | — | [Original ticket](./sayslate-status-badge-original-ticket.md), message 2 | — |
| LD-002 | **Superseded by LD-003.** The full-page badge reads `Pass 1` while the first AI pass runs and `Pass 2` while the second runs. | These are the words the user named. Today the full page keeps its previous label during both passes (EV-004). | REQ-001, REQ-002 | [Original ticket](./sayslate-status-badge-original-ticket.md), message 1 | Leaving the full-page badge unchanged while a pass runs |
| LD-003 | The full-page badge reads `Phase 1` while the first AI pass runs and `Phase 2` while the second runs. These are the labels Floating Slate already uses (EV-010). | The user wants the full page to match what Floating Slate shows in the browser. | REQ-001, REQ-003 | Dustin Thomason, 2026-09-24 clarification (REQ-003) | LD-002's "Pass" wording |
| LD-004 | Floating Slate's badge wording and behavior stay unchanged. SAYSTAT-02 is withdrawn before dispatch. | Floating Slate is the reference the full page is being made consistent with. | REQ-003 | Dustin Thomason, 2026-09-24: "we want to keep it with phase one and phase two because that is how the extension inside the browser works" | Open decision 1's recommendation to change Floating Slate's labels to "Pass" |
| LD-005 | The full-page badge follows Floating Slate's pass states, with the same labels (EV-010, EV-012, EV-013). See the four states below the table. | The full page matches Floating Slate's labels, states, and colors. The one timing difference keeps the full page from reporting a stage that is not running, which REQ-001 requires; Floating Slate's badge does report one in that case (EV-011). | REQ-001, REQ-003 | Dustin Thomason, 2026-09-24: "it should be consistent with what the standalone browser extension would do" … "change the wording to whatever it is over there"; the label timing: [Original ticket](./sayslate-status-badge-original-ticket.md), message 1, "displays the current status of the process" | — |
| LD-006 | Discarding the processed result, or clearing everything, sets the badge to "Ready" only when no pass request is in flight and dictation is not running. A discard or clear while a pass request is in flight leaves "Phase N" showing. | The discard button and Ctrl+Alt+X both reach the discard while a pass runs (EV-025). REQ-001 requires the running stage on the badge for as long as the pass runs, so "Ready" there would report a pass as finished while it is still running. | REQ-001 | REQ-001; LD-005 state 4; resolved from sources, open decision 3 | Narrows LD-005 state 4 |
| LD-007 | When dictation and a pass overlap (EV-026), the dictation state owns the badge while dictation runs: a pass that succeeds or fails during dictation does not replace "Listening". When dictation stops while a pass request is still in flight, the badge shows that pass's `processing` / "Phase N" instead of "Ready". | The badge reports the current activity ([origin](./sayslate-status-badge-original-ticket.md), message 1, "displays the current status of the process"). While dictating, that is "Listening" (EV-003), which LD-005 already keeps over discard and clear. Once dictation stops, the running pass is the current activity, and "Ready" would report a stage that is still running, against REQ-001. | REQ-001 | REQ-001; EV-003; LD-005 state 4's "Listening" rule; resolved from sources, open decision 4 | Narrows LD-005 states 1–3 |

LD-005's four states:

1. **Running:** `processing` / "Phase N", set when the provider request starts. A pass that stops because no provider is chosen leaves the badge as it was (EV-005). This is the one timing difference from Floating Slate.
2. **Success:** `complete` / "Phase N ready".
3. **Failure:** `error` / "Phase N failed".
4. **Discard or clear:** `idle` / "Ready" when the processed result is discarded or everything is cleared, including at the end of Finish. While dictation is running, "Listening" stays (EV-003, EV-007).

The new `processing` and `complete` styles cover light and dark themes, using Floating Slate's hues: `#5b7fa3` for processing and the accent color for complete.

## Open Decision Checklist

- [x] 1. Is Floating Slate's badge part of this work, changing "Phase 1" / "Phase 2" to "Pass 1" / "Pass 2"? — Resolved as LD-004
- [x] 2. On the full page, what does the badge show after a pass succeeds or fails, how is each state styled, and when does it return to "Ready"? — Resolved as LD-005
- [x] 3. What does the full-page badge show when the result is discarded, or everything is cleared, while a pass request is in flight? — Resolved from sources as LD-006
- [x] 4. What does the full-page badge show when dictation starts or stops while a pass request is in flight? — Resolved from sources as LD-007

## Open Decision Register

### 1. Floating Slate's badge wording

**State:** Resolved
**Value:** Resolved as LD-004 (with LD-003 for the full-page wording).
**Investigation:** Floating Slate's badge is in the overlay header and reads "Ready" at rest (EV-009, `C:\SaySlate\floating.html:24`). It already shows each pass, as "Phase 1" / "Phase 2", while its own notices for those passes say "Running first pass…" (EV-010, `floating.js:243-303`). It sets the pass label before resolving the provider profile, so with no provider chosen it keeps showing a pass that never started (EV-011, `floating.js:243-252,282-291`). `tests/verify.mjs:286` requires the literal "Phase 1" and "Phase 2" (EV-014). The README describes the indicator by stage, not label text, so it stays accurate either way (EV-015).
**Why user input is required:** The origin asks for "the top badge that handles 'ready'", in the singular, and both surfaces have one (EV-001, EV-009). On Floating Slate the need is already met except for the wording. Changing existing user-visible wording on a surface the request may not have meant is a product choice, and the origin does not say which badge it meant.
**Recommendation:** Include it. Change the six labels to "Pass 1" / "Pass 2" / "Pass N ready" / "Pass N failed", and set the pass label only once the provider request starts. This gives one vocabulary across both surfaces, matching the word Floating Slate's own notices already use. It also stops the badge from reporting a pass that is not running. The cost is one sequential ticket touching `floating.js`, its integration test, and one static-check line.
**Evidence:** EV-009, EV-010, EV-011, EV-014, EV-015; Dustin Thomason, 2026-09-24 answer (REQ-003)
**Depends on:** —

### 2. Full-page badge after each pass

**State:** Resolved
**Value:** Resolved as LD-005.
**Investigation:**
- **Badge updates today:** the full page updates its badge only through `setStatus` (EV-002, `C:\SaySlate\app.js:110-113`), and only for dictation (EV-003, EV-004).
- **Passes:** each pass resolves the provider profile before sending (EV-005). Finish runs the passes and then clears everything (EV-006).
- **Clearing and discarding:** neither resets the badge, and discard stays enabled while dictating (EV-007, `app.js:686,702-709,1260-1280`).
- **Styles:** the stylesheet has no `processing` or `complete` badge style in either theme (EV-008, `app.css:655-686,1193-1219`).
- **Floating Slate's existing pattern:** `processing` while a pass runs, then `complete` "… ready" or `error` "… failed", and `idle` "Ready" on clear (EV-010, EV-012). It has processing and complete styles (EV-013, `floating.css:80-85`).

**Why user input is required:** The origin fixes the wording while a pass runs (LD-002) and says nothing about afterwards. No source settles these user-visible behaviors:
- whether a finished pass stays on the badge;
- whether a failure shows there;
- when it goes back to "Ready";
- which colors the new states use.

**Recommendation:** Use Floating Slate's existing pattern, with "Pass" as the word:
- `processing` / "Pass N" from the moment the provider request starts. A pass that stops because no provider is chosen leaves the badge as it was (EV-005).
- `complete` / "Pass N ready" when the pass returns a result.
- `error` / "Pass N failed" when it fails.
- `idle` / "Ready" when the processed result is discarded or everything is cleared, including at the end of Finish. While dictation is running, "Listening" stays (EV-003, EV-007).
- Full-page `processing` and `complete` badge styles in light and dark themes, using Floating Slate's hues: `#5b7fa3` for processing and the accent color for complete (EV-013).

Users already see this sequence in Floating Slate, so the full page adds no new words or colors. The cost is that "Pass 2 ready" stays on the badge until the next action rather than reverting to "Ready" by itself.
**Evidence:** EV-003, EV-005, EV-007, EV-008, EV-010, EV-012, EV-013; Dustin Thomason, 2026-09-24 answer (REQ-003)
**Depends on:** —

### 3. Full-page badge when the result is discarded or cleared during a pass

**State:** Resolved
**Value:** Resolved from sources as LD-006.
**Investigation:** Recorded by the orchestrating agent before SAYSTAT-01's dispatch. The discard button is enabled while the first pass runs, and Ctrl+Alt+X reaches `clearTranscript`, which discards the result, while either pass runs (EV-025, `C:\SaySlate\app.js:686,881,1275,1344-1353`). SAYSTAT-01's discard rule as first written reset the badge to "Ready" whenever dictation was not running, so a discard during a pass would show "Ready" while that pass's request was still in flight.
**Why user input is required:** Not required. REQ-001 fixes the badge while a pass runs, so the only rule consistent with it is to leave "Phase N" showing.
**Recommendation:** —
**Evidence:** EV-025; REQ-001
**Depends on:** —

### 4. Full-page badge when dictation overlaps a pass

**State:** Resolved
**Value:** Resolved from sources as LD-007.
**Investigation:** Recorded by the orchestrating agent before SAYSTAT-01's dispatch. Ctrl+Alt+D starts dictation while a pass runs, although the start button is disabled then (EV-026, `C:\SaySlate\app.js:878,980-1005,1344-1349`). As first written, SAYSTAT-01 would let a pass that settles during dictation replace "Listening" with "Phase N ready" or "Phase N failed". A dictation stop during a pass would also show "Ready" while that pass's request was in flight (`app.js:913-917`).
**Why user input is required:** Not required. REQ-001 and EV-003 each fix the badge for one of the two activities, and LD-005 already gives "Listening" precedence over the other badge states. Together they settle both overlap orders. Whether Ctrl+Alt+D should be blocked during a pass, as the start button is, changes dictation behavior. That is outside this handoff and is not decided here.
**Recommendation:** —
**Evidence:** EV-003, EV-026; REQ-001; LD-005
**Depends on:** —
