# Browser-loop setup (dustin-thomason)

Task-oriented setup for the runtime browser-observation loop: wiring an agent to observe and drive a live browser during front-end work, so it observes truth (runtime layout, cascade, interaction state) instead of inferring it.

- **Boundary rules (mandatory, load first):** [browser-loop-guardrails.mdc](../rules/browser-loop-guardrails.mdc)
- **Authoritative spec:** [runtime-browser-loop-spec-1.md](../../docs/agents/runtime-browser-loop-spec-1.md)

## When to use

Diagnosing or verifying front-end layout, CSS cascade, or interaction (drag/resize/toggle) at runtime — especially "works at the start and end but breaks in between" bugs, cascade conflicts ("which rule won?"), and flush-to-edge / off-by-N geometry.

## One-time setup

Register a stock browser MCP at **user scope** so it is available in every project:

```
claude mcp add --scope user playwright -- npx @playwright/mcp@latest
npx playwright install chromium
```

(Cursor / other harnesses: add the same server to their MCP config. Chrome DevTools MCP is an alternative for driving + console + network.)

## Tools

| Capability | Tool | Status |
| ---------- | ---- | ------ |
| Navigate, click, drag, type; screenshot; console; network bodies | Stock browser MCP (Playwright MCP / Chrome DevTools MCP) | Available now |
| Cascade provenance — which rule won and what it struck through (`CSS.getMatchedStylesForNode`) | `scripts/browser/css-provenance.mjs` | Planned (Phase 5) |
| Stepped-drag trajectory sampler — per-step `getBoundingClientRect` for many elements + discontinuity flagging | `scripts/browser/trajectory-sampler.mjs` | Planned (Phase 5) |
| Per-component baseline capture/compare (geometry + visibility + threshold screenshot) | `scripts/browser/baseline.mjs` | Planned (Phase 5) |

The two provenance/trajectory items are **not** reliably exposed by stock MCP tools; they are thin custom scripts the agent invokes via the shell. Until Phase 5 lands them, use stock MCP driving/observation plus the method below.

## Method (from the spec)

- **Provenance over guessing.** Use matched styles to get *who won* and *what it overrode*, not just the final computed value.
- **Real interaction, not simulated state.** Dispatch real press -> move-through-intermediate-points -> release. Do not shortcut a resize by setting a width; that skips handle-specific behavior.
- **Sample the trajectory.** Step the interaction in increments; at each checkpoint capture geometry for the target *and* its contents *and* neighbors. Include boundary conditions (fully expanded/collapsed) and follow them with the triggering action (e.g. click-out) plus its assertion. Flag any tracked element that jumps size/position impossibly between adjacent steps.
- **Right tool for the assertion.** Geometry (`getBoundingClientRect`, computed styles) is sub-pixel exact and stable — use it for numeric position/size/spacing checks. Screenshot diffing is noisy — use it for holistic visual regression, always with a pixel tolerance.

## Baselines

Per component, store a baseline and assert future changes against it:

```
docs/<project>/baselines/<component>/
  baseline.json   # geometry (rects) + visibility
  baseline.png    # threshold screenshot
```

Keep the narrative changelog as context, but the baseline is what *tells* a later agent it broke something instead of letting it believe it did not. Note replication conditions (viewport, timing, external state) precisely — clean for deterministic layout/CSS bugs, flakier otherwise.

## Guardrails (always in effect)

The six boundary rules in [browser-loop-guardrails.mdc](../rules/browser-loop-guardrails.mdc) apply the entire time: no specificity band-aids, explain magic constants, keep independent constants independent, a green check is necessary-not-sufficient, fix the rule not the symptom, and **escalate after ~3 non-converging attempts** with a structured account instead of continuing to tune.

## Handoff checklist (spec section 7)

- [ ] Claude Code (or equivalent) as the loop; no custom harness.
- [ ] Playwright driving + raw `newCDPSession` for hidden domains (DOM/CSS).
- [ ] Stock browser MCP for drive / screenshot / console / network.
- [ ] Thin custom tool: `CSS.getMatchedStylesForNode` cascade/provenance query.
- [ ] Thin custom tool: stepped-drag trajectory sampler capturing multi-element `getBoundingClientRect` + discontinuity flagging.
- [ ] Baseline store per component (geometry + visibility + threshold screenshot).
- [ ] Boundary rules loaded as enforced agent rules **before** the loop is used.
