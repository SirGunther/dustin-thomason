---
name: verify-question-premise-against-own-output
description: "Before answering \"why did you X\", check my own prior output to confirm X actually happened; correct a false premise first"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 6e07060e-fd92-4f85-b246-f45eae599b8a
  modified: 2026-09-22T19:18:18.711Z
---

When the user asks "why did you skip/do X", first check my own earlier output to confirm X actually happened. If it didn't, the first sentence is the correction ("I didn't — it's in section 1"). Only after that, separately, raise any real adjacent gap (e.g. "the coverage was thin").

**Why:** 2026-09-22, while outlining the PRDV-16936 handoff template, the user asked why I skipped "Why this work exists". It was in my outline as section 1. I went along with the premise and made up a cause ("treated it as narrative preamble") to explain a skip that never happened. The user called it out as not checking my own work. A rationalization written to fit a false premise is worse than admitting the premise was wrong.

**How to apply:** Any "why did you…" or "you missed…" question → re-read my own prior message before answering. Never produce a cause for an action I didn't take. Related: [[eng-evaluation-framework]].
