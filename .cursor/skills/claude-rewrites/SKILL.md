---
name: claude-rewrites
description: Rewrite dense, fragmented, overly technical, or semantically compressed responses into coherent explanations that can be understood in one pass without reconstructing the reasoning. Preserve the substance, evidence, and conclusions while restoring the connective reasoning between them. Use when the user says a response is hard to follow, confusing, too compressed, too technical, reads like notes, lacks coherence, needs a clearer TL;DR, or asks to "make this easier to understand," "explain this normally," "rewrite this coherently," or similar.
---


Rewrite your answer for someone who understands the two applications but has not followed your investigation.

I want a TL;DR, but do not semantically compress the explanation. Use normal conversational prose and complete thoughts. The reader should not have to infer why one fact leads to another.

Explain the idea in this order:

1. What I am proposing.
2. What you discovered about the systems today.
3. How that changes or validates my proposal.
4. What work would actually be required.
5. Your overall recommendation.

Focus on the architectural idea rather than narrating your investigation. Leave out implementation trivia unless it materially changes the feasibility, scope, or direction.

Use 3–5 short paragraphs rather than a dense list. Aim for roughly 150–250 words. Avoid shorthand such as “consume first, extract second,” “reverse the flow,” “the engine is the package,” or similar compressed phrases unless you immediately explain what they mean in plain English.

Most importantly, preserve the reasoning between statements. I should be able to read the response once, from top to bottom, and understand the proposal, the current state, and the recommended path without reconstructing the argument myself.
