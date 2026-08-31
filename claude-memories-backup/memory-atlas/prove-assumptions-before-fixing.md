---
name: prove-assumptions-before-fixing
description: "Before committing to a fix plan, prove the root cause with falsifiable checks; right-size the solution; solve the class of problem, not just the instance."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 1ed3b51d-1b8c-4db4-991c-e1b07be10842
---

Before finalizing a fix plan, prove what you think you know: state falsifiable hypotheses about the root cause and confirm/refute each with read-only evidence — including negative/leak checks that the problem isn't caused by, or leaking into, somewhere else. Capture the investigation in a doc for the user to review before planning.

**Why:** the user asked to "prove what you think you know about the problem," wants solutions "no simpler than it needs to be, and no more complex than it needs to be," and to confirm the fix "solves the actual class of problem, not just this instance," follows best practices / fits the architecture and philosophy, and scales.

**How to apply:** run a verification pass (often parallel read-only subagents across FE + BE) before locking the plan; write it to `dustin-thomason/docs/<system>/<ticket>/`. Bound the fix to the proven scope; centralize the corrected rule once (mirror the backend's single source of truth) so future instances are correct by construction; explicitly answer class/architecture/scale. Example (PRDV-16047): proved the withdraw resource-key drift + enumerated exactly the withdraw entry points before planning. See [[preserve-intentional-ux-in-defect-fixes]], [[spec-review-gate-larry-adams]].
