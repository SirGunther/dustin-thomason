# SaySlate Per-Pass Reasoning - Original Ticket

## Capture Metadata

| Field | Value |
| --- | --- |
| Project | SaySlate |
| Ticket slug / ID | `sayslate-pass-reasoning` |
| Captured on | 2026-09-24 |
| Source | User-provided chat request, two messages. Message 1 is the paragraph that introduced this feature within a four-feature SaySlate request; the rest of that request is not captured here. Message 2 asks for this feature's ticket set. |
| Formatting | Verbatim |

## Original Request

### Message 1 (excerpt)

We would then also want to introduce two other pieces. One of them would be the ability to select 'use reasoning' when actually doing the output. The second would be a third piece, which would be more of a defined part of the process rather than a toggle or a choice like the others. This is actually where I think the reasoning would be used, though I haven't decided on which specific step for certain just yet.

### Message 2

Okay, so I want you to give me the same sort of ticket and everything for number two: the use of reasoning. There are a couple of things to just throw it out there. This is only going to apply to the LM Studio because it's something that we have the ability to throw to the payload, so that removes the ambiguity there with other models. Then, just throw it on all of them. Anything that goes through. 

I was thinking almost like a toggle switch for each step. Say you want the first pass to not use reasoning because, in my instances, the first pass is really just for grammatical fixes, and the second pass is intentionally for enhancing the coherence of the actual dialogue. I think that's where I'm trying to head with this. It may not even need a third pass, or what I guess I put in number three as we talked about, because it's a reconciled pass. I mean, I need that if I use a reasoning sort of step, because all these other ones that I've used previously were not reasoning models. They were strictly single pass. 

So, I think maybe what I'm looking for is the ability, almost like a toggle, that I could then turn on in both passes. Well, I say both passes the writing behavior, that icon. I just want to have a toggle for the first pass prompt to turn reasoning on and off, and then for the second pass prompt, you either turn it on and enabled, and then you can also turn on reasoning if you'd like. 

I think that's what I'm trying to say, and I think that simplifies it because it would only apply to the LM Studio and models that have reasoning capabilities, which is pretty much going to be anything that I choose to begin with. Then you just turn it on and off because if it doesn't apply, if you ever threw a model in there, you'd just be able to toggle it on and off. I think that simplifies it. Maybe make the artifacts. That sounds easy enough.

## Explicit Constraints In Original Request

- "the same sort of ticket and everything for number two: the use of reasoning"
- "This is only going to apply to the LM Studio"
- "just throw it on all of them. Anything that goes through."
- "a toggle for the first pass prompt to turn reasoning on and off, and then for the second pass prompt, you either turn it on and enabled, and then you can also turn on reasoning if you'd like"
- "the writing behavior, that icon"

## Context Paths In Original Request

- None
