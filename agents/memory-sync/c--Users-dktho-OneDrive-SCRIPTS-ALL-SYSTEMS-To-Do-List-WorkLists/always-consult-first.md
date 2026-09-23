---
name: always-consult-first
description: "Open every response with the working-framework Consult section (self-interrogation ending in \"The Bigger Picture\") before anything else"
metadata:
  node_type: memory
  type: feedback
  originSessionId: b4b5ca6b-9d4b-407c-b7f9-fd2c755dfe44
  modified: 2026-09-22T20:19:51.954Z
---

Start every response with a `## Consult` section per stage 1 of the working-framework skill (`C:\dustin-thomason\agents\skills\working-framework\SKILL.md`): self-addressed interrogation of what/why/how, ending with an explicit "The Bigger Picture" synthesis. Only stage 1 is required unless the user directs otherwise. It overrides other rules, including direct-responses' answer-in-first-sentence.

**Why:** Stated 2026-09-22 after I redesigned a doc's section layout when the user had only asked me to lay the sections out ("I need to determine what to include" — the inclusion call was theirs). User: "ALways consult first, it guarantees you have reasoned about the request and the tasks upcoming." Scoped as "for now, unless otherwise directed."

**How to apply:** Use Consult to pin the explicit instructions in the request (words like "first", "for now", "I need to determine") and what the user has reserved for themselves, before acting. If the user narrows or lifts this directive, update or delete this memory. Related: [[verify-question-premise-against-own-output]], [[agents-mental-model]].
