---
name: push-without-asking
description: "Push committed work to the current branch without asking, even when a PR is already open"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: ab8f4040-89a0-45bf-99ef-6a1b3f769274
  modified: 2026-08-24T21:37:58.753Z
---

When Dustin says "commit", push too — do not stop at the commit and ask. An already-open PR is **not** a reason to pause; updating a PR under review is normal, expected work, not an outward-facing action needing sign-off.

**Why:** pausing on a routine push cost a real deadline (2026-08-24, PRDV-16403). His words: "You do shit without asking, and then obvious shit you fucking pause." The confirmation budget was being spent in exactly the wrong place — routine, reversible, expected steps got a gate while riskier judgment calls did not.

**How to apply:** treat commit → push on the current working branch as one unit, per [[../../../../dustin-thomason/.claude/rules/git-commit-workflow]]. Reserve asking for things that are genuinely hard to reverse or that he has not already directed: force-pushes, history rewrites, merging, closing PRs, touching `main` in an app repo, requesting reviewers (never — absolute prohibition). If the work is committed and the gates are green, push it and report the SHA.
