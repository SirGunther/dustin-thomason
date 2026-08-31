---
name: avoid-metaphors-write-literally
description: "Write literally in chat and artifacts; metaphors like \"stale\", \"hygiene\", \"dead weight\" confuse rather than clarify"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 1af6eb80-6e04-4899-8156-90c4356ec67e
  modified: 2026-08-31T21:27:37.776Z
---

Do not use metaphor or idiom to convey technical meaning. Say the literal thing.

Flagged directly by the user after a run where "hygiene", "stale", "dead weight",
"load-bearing", "version floor", and "drift" all appeared within a few turns, and
also landed in the ticket changelog. Each one prompted a clarifying question
("you mean the system is sick?", "like a piece of bread?"), so each cost a round
trip instead of saving one.

**Why:** a metaphor asks the reader to decode an analogy before they get the fact.
When the reader is scanning a changelog or a status report, that decoding step is
pure cost, and a wrong decode is worse than no sentence at all. Domain idioms feel
precise to write and read as vague to receive.

**How to apply:** state the mechanism instead of the figure.

| Do not write | Write |
| --- | --- |
| stale override / stale floor | pinned version now below the patched version |
| stale lockfile | lockfile holding older resolutions than the ranges allow |
| dead weight / not earning its place | no longer changes any resolved version |
| load-bearing | removing it reintroduces findings |
| hygiene | reducing the number of hand-maintained overrides |
| drift | the pinned value stops matching current advisories |

This applies to written artifacts (changelogs, PR bodies, specs) as much as to
chat, since those are the durable record other developers read. Applies alongside
the style constraints in [[claude-rewrites-style]] if that memory exists.
