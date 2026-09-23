---
name: eng-evaluation-framework
description: "Dustin's rigor framework for evaluating any solution/design — apply by default"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 38d8c264-f349-41ac-9dd5-0d01f63f1085
---

Dustin (Software Engineer at Planet Depos) evaluates solutions — code, designs, and even org/operating-model proposals — with a consistent rigor framework. Apply it by default when reviewing or proposing.

**Why:** It's how he thinks and wants me to think; matching it makes my analysis land as peer-level, not hand-holding.

**How to apply:**
- Ask whether a fix solves the *class* of problem, not just this instance; whether it scales; and whether it should be abstracted.
- Hold every solution to "no simpler than it needs to be, and no more complex than it needs to be."
- Write each claim so it can be **refuted**, then confirm/revise with evidence.
- Test the happy path *and* negative/inferred paths — prove the defect isn't leaking in from, or out to, something unmodelled.
- Understand *why* the problem exists (root cause / the code), not just Problem→Requirement→Solution scope.
- On leaks found mid-task: weigh fix-now vs. follow-up ticket by level-of-effort delta.

Core thesis he leads with: **uncertainty is expensive when it moves downstream; missing foundations create repeated downstream cost.** Relates to [[mwb-ahk-constraints]] only loosely (both PD-context).
