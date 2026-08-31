---
name: keep-ticket-artifacts-in-repo
description: Never publish ticket work to a web-hosted artifact; ticket deliverables belong as files in the dustin-thomason repo alongside the other ticket artifacts.
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 85cc1756-80de-422c-83c6-1edead1419a0
  modified: 2026-08-18T21:25:00.663Z
---

Do not publish ticket-related work (decision reviews, status boards, investigation summaries) as a web-hosted Artifact, even though artifacts are private by default. Ticket deliverables belong in `dustin-thomason/docs/<system>/PRDV-XXXXX/` as markdown, next to the other artifacts for that ticket. Ask first if a visual review page seems genuinely useful.

**Why:** the user objected directly — "This artifact should not be on the internet. It really belongs in the Dustin Thomason repository with the other artifacts related to the ticket." The `orchestrate` skill's own **Repo boundary** rule already says every orchestration artifact lives in `dustin-thomason` regardless of where the code lives; publishing to claude.ai violated a rule that was already loaded. Being default-private did not make it acceptable — the objection is to hosting the work outside the repo at all.

**How to apply:**
- Build the deliverable as a markdown file in the ticket folder. If content would duplicate an existing artifact (e.g. a decision ledger that already exists), enrich that file rather than creating a second source of truth.
- The Artifact tool has **no delete action** (publish / list / comments / reply / resolve only). If something is published by mistake, say so plainly and tell the user to remove it from the artifact page's share menu or `claude.ai/code/artifacts` — do not imply it can be retracted from this side.
- This is about *ticket* work. It does not forbid artifacts categorically if the user asks for one.

See [[spec-review-gate-larry-adams]].
