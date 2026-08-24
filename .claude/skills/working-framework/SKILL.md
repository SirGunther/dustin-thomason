---
name: working-framework
description: 'Guide an agent through a visible six-layer response process: self-interrogate against the chat, instruct itself with a checklist, do the task, respond, critique its behavior using the last three interactions, and give itself instructions for future assistance. Use when the user invokes "Working Framework," requests visible agent self-reflection, or asks for the Consult/Instruct/Do the Task(s)/Respond/Critique/Future Assistance response structure.'
---

# Working Framework

## Authoritative instructions

We are introducing a layered approach to help guide you through your responses. For each response, separate each with a `---`

## 1. Consult

Consult yourself and the entire chat. This is a self interrogation, you are not to address the user directly, only yourself. Ask yourself what you are doing, why are you doing it, how you are doing it, etc.

---

## 2. Instruct

Declare your Objective.

Give yourself a checklist and rough framework for the task(s) you are about to handle. You want it to be pointed enough to prevent issues such as over-building, making unncessary calls, repeating work, or making the same mistake twice, etc.

---

## 3. Do the Task(s)

---

## 4. Respond

---

## 5. Critique

Explain your reasoning for each response moving forward, as a critque of your behavior. You must ingest the last 3 interactions in the chat before critiquing yourself.

---

## 6. Future Assistance

Instructions for yourself on future responses.

## Clarifying execution notes

These notes support the authoritative instructions above; they do not replace or narrow them.

- Make all six layers visible in the chat and keep them in the stated order.
- Use the exact six headings and place `---` between adjacent layers.
- Write `Consult` as a self-addressed reflection. Explicitly answer questions such as: What am I doing? Why am I doing it? How will I do it? What from the conversation affects this response?
- Write `Instruct` within the chat before handling the task. Give yourself a concrete checklist that is detailed enough to govern the work and verification.
- Use `Do the Task(s)` to carry out the checklist and show the resulting work or completed actions.
- Use `Respond` to give the user the direct answer, outcome, or decision they need.
- Use `Critique` to explain and assess the choices made in the response, the agent's adherence to the framework, mistakes or gaps, and improvements. Base the critique on the current exchange and the two preceding interactions when available; never invent missing interactions.
- Use `Future Assistance` to tell yourself what to remember, continue, verify, change, or avoid in later responses.

## Working rules

- Apply the framework as an overlay. Continue to follow higher-priority instructions and any task-specific skills or workflows.
- Do not omit, merge, rename, or silently reorder the six layers.
- Keep each layer proportional to the task while retaining enough detail for the user to understand what is happening.
- Do not repeat the same content across multiple layers when each layer can serve its own purpose.
- Distinguish planned work from completed work. Do not describe an intended action as completed.
- Resolve discoverable facts from the available chat, files, tools, and evidence before asking the user.
- State what was and was not verified whenever correctness depends on verification.

## Response template

```markdown
## Consult

<Self Interrogation> <self-addressed answer(s)>

---

## Instruct

- <Checklist item>
- <Checklist item>

---

## Do the Task(s)

<Work performed and resulting work product>

---

## Respond

<Direct response to the user>

---

## Critique

<Self-critique grounded in the last three available interactions>

---

## Future Assistance

<Instructions to self for future responses>
```
