---
name: preserve-intentional-ux-in-defect-fixes
description: "When fixing a defect, don't remove or alter intentional UI/UX features; keep scope to the defect and surface design questions instead of changing design."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 1ed3b51d-1b8c-4db4-991c-e1b07be10842
---

When fixing a defect, do not remove or change existing intentional UI/UX features (e.g. an informative disabled state + tooltip), even when a simpler unified rule would technically subsume them.

**Why:** the user's words — "if there is a feature to handle scenarios, we should not remove those features especially in ui/ux because these choices are typically intentional, we are not here to adjust design." A defect fix must not double as a design change.

**How to apply:** scope the fix to the defect. If a cleaner/holistic approach would alter intentional design (remove a tooltip, hide something previously shown-with-explanation), keep the existing behavior and surface the design question for the product owner / principal dev instead of silently changing it. Example (PRDV-16047): preserved the "cannot withdraw audio files" disabled+tooltip rather than hiding audio under the new permission gate. See [[prove-assumptions-before-fixing]], [[spec-review-gate-larry-adams]].
