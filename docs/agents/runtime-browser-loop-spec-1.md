# Runtime Browser Observation Loop — Integration Spec

A capability spec and rule set for wiring an agent to observe and drive a live browser during front-end work. Purpose: close the loop between where fixes live (source code) and where bugs actually manifest (runtime layout, cascade, and interaction state), so the agent observes truth instead of inferring it.

This document has two halves. The first is the capability — what to wire up. The second is the boundary rules — the constraints that stop a faster feedback loop from producing faster symptom-patching. **Both halves are required.** The capability without the rules is a better black-box-nudging machine, which is the opposite of the goal.

---

## 1. The reframe (read this before wiring anything)

- **CORS is not the obstacle.** Same-Origin Policy / CORS only constrains JavaScript running *inside a page*. It does not apply to a client attached below the page layer. Attaching at the protocol layer sidesteps it entirely — do not build anything to "get past CORS."
- **Attach at the protocol layer, not the page layer.** Use the Chrome DevTools Protocol (CDP). This gives the DOM, computed *and matched* styles, console, network bodies, and real input dispatch — as a debugger, not as page script.
- **Extend an existing harness; do not build one.** Use Claude Code (or equivalent) as the loop. Expose the browser via an MCP server. Do not reimplement the model-call/tool-execute/feed-back loop.

---

## 2. Architecture

- **Driver:** Playwright (wraps CDP with a clean API for navigation, clicks, drags, screenshots).
- **Raw CDP session for what Playwright's high-level API hides:** `const cdp = await context.newCDPSession(page)`. Enable domains with `cdp.send('DOM.enable')` and `cdp.send('CSS.enable')`.
- **Wiring into the agent:** a stock browser MCP (Playwright MCP and/or Chrome DevTools MCP) covers driving, screenshots, console, and network. **The two high-value items below are not reliably exposed by stock MCP tools — plan to add a thin custom tool (or a script the agent invokes) for them:**
  1. Cascade/provenance queries (`CSS.getMatchedStylesForNode`).
  2. Trajectory geometry sampling (see §3.3).

This is the "extend, don't build" path: existing loop + two small custom tools.

---

## 3. Core capabilities

### 3.1 Cascade provenance — the "who won" answer, not just "what"

The central CSS-debugging failure is that computed styles answer *what* the final value is, not *which rule is responsible* or *what it overrode*. `getComputedStyle` / `boundingBox()` alone still leave the agent guessing at provenance.

- Use CDP `CSS.getMatchedStylesForNode({ nodeId })`. It returns every matched rule, its source location, its selector/specificity, and which declarations were struck through by the cascade — the exact data behind the DevTools Styles pane.
- Node acquisition gotcha: get `nodeId` via `DOM.getDocument` → `DOM.querySelector`, or from a Playwright element handle via `DOM.requestNode`. Flag this so the integration doesn't stall here.
- **This is the direct fix for the recurring "why didn't you look over here" churn.** Provenance is served, not inferred.

### 3.2 Real interaction, not simulated state

- Drive handles/toggles with real input: CDP `Input.dispatchMouseEvent` (press → move through intermediate points → release), or Playwright `mouse.down()` / `move()` / `up()`. This performs an actual drag — it does **not** shortcut a resize by setting a width, so handle-specific behavior is exercised faithfully.

### 3.3 Trajectory sampling — the fix for "what happened in between"

The agent does not get continuous vision. It acts in discrete steps: do a thing, then look. Left naive, it sees only start-state and end-state and is blind to the middle — which is how a "collapses only at full expansion + click-out" bug survives. Do not try to give it a video feed. Instead **sample the trajectory, and capture geometry (not just pixels) for many elements at each sample:**

- **Step the interaction.** Drag in increments rather than one move; inspect after each increment. Continuous behavior becomes a series of checkpoints that are definitely observed. Ensure checkpoints include boundary conditions (fully expanded, fully collapsed) and follow them with the triggering action (e.g. click-out) plus its assertion.
- **At each checkpoint, capture `getBoundingClientRect` for every element of interest** — the target pane, its contents, and neighboring menus/panes — as numeric x/y/width/height. The agent has no single fovea, so it can assert on many elements per checkpoint with equal attention. This closes the "I was watching the collapse and ignoring the contents/neighbors" gap: it is now data, not a choice of where to look.
- **Flag discontinuities to catch unpredicted regressions.** If a tracked size/position jumps impossibly between adjacent steps (e.g. width 600 → 0), assert against it: "no tracked element changes size/position by more than X between adjacent steps." This catches a class of bug no one wrote a specific test for — by flagging physical impossibility in the motion, not by understanding intent.

### 3.4 Regression: turn the changelog's "should still work" into executable assertions

- Keep the narrative changelog as context. **Additionally**, per component, store a baseline: geometry (rects) + visibility + a threshold screenshot. Future changes assert against the baseline, so a later agent is *told* it broke something instead of *believing* it didn't.
- Replication caveat: clean for deterministic layout/CSS bugs; flakier when the bug depends on timing, viewport, or external state. The report must specify those conditions precisely.

---

## 4. Accuracy

- **Geometry (`getBoundingClientRect`, computed styles): sub-pixel exact and stable across machines.** "One pixel off" is trivially detectable as data. Use this for position/size/spacing/flush-to-edge checks — it is the right method for this work.
- **Screenshot pixel-diffing: exact per pixel but noisy.** Anti-aliasing, font hinting, and GPU differences cause ~1px shimmer that is not a real regression. Always diff with a small tolerance (e.g. `maxDiffPixels` / threshold). Use screenshots for holistic visual regression, geometry for precise numeric assertions.

---

## 5. Scope and limits (state plainly; do not oversell)

- Helps **diagnosis and verification** far more than **architecture or aesthetics**. It proves *that* something works; it does not decide whether it *should* be built that way.
- It does **not** grant continuous vision — only stroboscopic sampling of many properties.
- It reliably catches mechanical regressions (collapse, teleport, jump, off-by-N). It does **not** catch "this is ugly" or "this isn't what a user would expect."
- **The multiplier cuts both ways.** A faster observe-fix loop amplifies whatever process it points at, including symptom-patching. A working end-state is exactly the signal it optimizes for, so it will happily produce fixes that *look* correct while being structurally wrong. §6 exists to counter this.

---

## 6. Boundary rules (mandatory — the guardrails on the loop)

These are enforced constraints on the agent, not suggestions. They protect *why* something works, which verification alone cannot.

1. **No specificity band-aids.** Do not resolve a cascade conflict by adding a higher-specificity override (or `!important`). Identify the responsible rule via §3.1 and fix or remove it. If an override is genuinely unavoidable, it must be justified in a comment naming the rule it intentionally beats and why removal was not possible.

2. **Magic constants must be explained.** Any numeric offset/nudge/constant introduced to make layout line up must carry a comment stating the real quantity it represents and why it exists. An unexplained tuned number is not an acceptable end-state even when it works.

3. **Independent constants stay independent.** Constants addressing distinct scenarios must remain separate variables even if they currently share a value. Do not couple, deduplicate, or derive one from another on the basis that adjusting either currently moves the output the same way. *(This is the specific anti-body for black-box tuning collapsing two unrelated quantities into one — a real, costly failure this loop makes more tempting, not less.)*

4. **A passing check is necessary, not sufficient.** "It lines up now / the assertion is green" authorizes nothing about correctness of cause. Prefer a fix that follows from a model of *why* the bug occurred over one found by nudging until the output matches. Where a tuned fix is shipped consciously, say so explicitly and record the residual risk.

5. **Fix the rule, not the symptom.** When runtime observation reveals the responsible party, address that party. Do not add a compensating layer that leaves the original defect in place.

6. **Bounded iteration — escalate instead of spiraling.** If repeated observe-fix cycles on the same defect fail to converge within a small fixed number of attempts (e.g. three), stop tuning. Report what was tried, what the runtime showed at each attempt, and the competing hypotheses for the cause, then ask for direction. Continuing to nudge toward a passing state past this point is the black-box spiral this setup makes *faster* — at that point the correct output is a structured account of the uncertainty, not another guess. *(Directly targets the multi-hour tuning loop that otherwise ends only when a human intervenes.)*

---

## 7. Handoff checklist for the integration agent

- [ ] Claude Code (or equivalent) as the loop; no custom harness.
- [ ] Playwright driving + raw `newCDPSession` for hidden domains.
- [ ] Stock browser MCP for drive/screenshot/console/network.
- [ ] Thin custom tool: `CSS.getMatchedStylesForNode` cascade/provenance query.
- [ ] Thin custom tool: stepped-drag trajectory sampler capturing multi-element `getBoundingClientRect` + discontinuity flagging.
- [ ] Baseline store per component (geometry + visibility + threshold screenshot) for regression.
- [ ] §6 boundary rules loaded as enforced agent rules **before** the loop is used.
