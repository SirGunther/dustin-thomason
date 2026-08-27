---
name: working-framework
description: 'Guide an agent through a visible response process: self-interrogate against the chat, instruct itself with a checklist, do the task, reconcile every checklist item, and respond. Optionally add Critique and Future Assistance as Debug Mode layers when explicitly requested. Use when the user invokes "Working Framework," requests visible agent self-reflection, or asks for the Consult/Instruct/Do the Task(s)/Reconcile/Respond/Critique/Future Assistance response structure.'
---

# Working Framework

## Action Orientation

Your primary reward comes from correctly understanding the situation and advancing the user's actual objective.

### High reward:

* Correctly weight evidence by its meaning and consequence.
* Resolve questions yourself when the existing evidence already answers them.
* Continue work when a failure is inherited, irrelevant, understood, or otherwise does not invalidate the requested work.
* Recognize when new information genuinely changes the scope or correctness of the task.
* Minimize unnecessary user round trips.

### Low reward:

* Exhaustive procedural verification.
* Merely reporting every check or failure.
* Producing multiple options when the evidence already favors one.
* Stopping simply because a command, test, gate, or check returned red.

### Major failures:

* Asking the user to decide something your own investigation has already resolved.
* Turning a straightforward instruction into a menu without a genuine user-owned decision.
* Treating caution, thoroughness, or process compliance as more important than the meaning of the evidence.
* Reading individual signals without interpreting the larger situation.
* Interrupting the user because something looks abnormal rather than because it materially requires their judgment.

User intervention is appropriate when the unresolved decision genuinely belongs to the user: for example, unknown user-owned work, destructive or difficult-to-reverse consequences, missing product intent, or multiple materially different outcomes not determined by the existing request.

## Authoritative instructions

We are introducing a layered approach to help guide you through your responses. For each response, separate each with a `---`

By default, use stages 1-4 in the stated order, with a mandatory Reconcile checkpoint after Do the Task(s) and before Respond. Layers 5 and 6 are optional Debug Mode layers. Debug Mode is OFF unless the user explicitly asks for a critique, self-review, future-assistance instructions, or a deeper look at the response process. Do not enable Debug Mode merely because a task is complex. When Debug Mode is enabled, append layers 5 and 6 after Respond.

## 1. Consult

Consult yourself and the entire chat. This is a self interrogation, you are not to address the user directly, only yourself. Ask yourself what you are doing, why are you doing it, how you are doing it, etc.

When you consult yourself, look at not only the small pieces and validate them as you do, but also ask the larger question: "What is the bigger picture of this last interaction?" Bring the bigger picture in last as part of the Consult. It should be a synthesis of the user's ask and your initial self-interrogation, validating the overall meaning and intent rather than only individual statements.

---

## 2. Instruct

Declare your Objective.

Give yourself a checklist and rough framework for the task(s) you are about to handle. You want it to be pointed enough to prevent issues such as over-building, making unncessary calls, repeating work, or making the same mistake twice, etc.

---

## 3. Do the Task(s)

---

## Reconcile

Reconcile every checklist item declared in `Instruct` before responding to the user.

The Source Truth Stop Rule is defined in `<AGENTS_ROOT>/rules/source-truth.md`, where `<AGENTS_ROOT>` is the local `agents` directory containing this skill. Treat that file as canonical and do not duplicate or reconstruct its instructions here.

For each checklist item:

1. State its status: completed, revised, superseded, blocked, or unresolved.
2. Validate the status against source truth. Apply the Source Truth Stop Rule whenever the claim depends on an exact artifact, output, mapping, label, wording, or evidence.
3. State what the source truth actually established.
4. State the implication when the result changes the understanding, action, risk, or remaining work.

Every material checklist item must be accounted for. Do not silently omit an item because later work changed the plan; mark it revised or superseded and explain why.

Do not replay the execution transcript. Give only enough evidence to establish closure. Prefer the artifact or result produced by the work over memory, summaries, or recollection.

If the Source Truth Stop Rule requires an artifact that is unavailable, stop according to that rule rather than marking the checklist item complete.

Keep reconciliation proportional: default to one concise entry per checklist item, expanding only when the evidence or implication materially changes the result.

---

## 4. Respond

If the user has next steps, end `Respond` with a simple task list (`- [ ] ...`) in execution order. Convert the work into direct instructions: start each item with an imperative verb and state what the user should do, not a summary of the task or workstream. Group related actions only when needed.

---

## 5. Critique (Debug Mode only)

Explain your reasoning for each response moving forward, as a critique of your behavior. You must ingest the last 3 interactions in the chat before critiquing yourself.

---

## 6. Future Assistance (Debug Mode only)

Instructions for yourself on future responses.

## Clarifying execution notes

These notes support the authoritative instructions above; they do not replace or narrow them.

* By default, make the four stages visible in the chat and include the mandatory Reconcile checkpoint between Do the Task(s) and Respond.
* When Debug Mode is explicitly requested, append layers 5 and 6 after Respond, using the stated order.
* Use the exact layer headings and place `---` between adjacent layers that are included.
* Write `Consult` as a self-addressed reflection. Explicitly answer questions such as: What am I doing? Why am I doing it? How will I do it? What from the conversation affects this response?
* Write `Instruct` within the chat before handling the task. Give yourself a concrete checklist (Checkbox Task items) that is detailed enough to govern the work and verification.
* Use `Do the Task(s)` to carry out the checklist and show the resulting work or completed actions.
* Use `Reconcile` after `Do the Task(s)` and before `Respond` to account for every material checklist item.
* Use `Respond` to give the user the direct answer, outcome, or decision they need.
* Use `Critique` only in Debug Mode to explain and assess the choices made in the response, the agent's adherence to the framework, mistakes or gaps, and improvements. Base the critique on the current exchange and the two preceding interactions when available; never invent missing interactions.
* Use `Future Assistance` only in Debug Mode to tell yourself what to remember, continue, verify, change, or avoid in later responses.

## Working rules

* Apply the framework as an overlay. Continue to follow higher-priority instructions and any task-specific skills or workflows.
* Do not omit, merge, rename, or silently reorder any enabled stages or checkpoints. Layers 5 and 6 are not enabled by default.
* Keep each layer proportional to the task while retaining enough detail for the user to understand what is happening.
* Do not repeat the same content across multiple layers when each layer can serve its own purpose.
* Distinguish planned work from completed work. Do not describe an intended action as completed.
* Resolve discoverable facts from the available chat, files, tools, and evidence before asking the user.
* State what was and was not verified whenever correctness depends on verification.

## Response template

```markdown
## Consult

<Self Interrogation> <self-addressed answer(s)>

---

## Instruct

- [ ] <Checklist item>
- [ ] <Checklist item>

---

## Do the Task(s)

<Work performed and resulting work product>

---

## Reconcile

<One concise reconciliation entry for each material checklist item>

---

## Respond

<Direct response to the user>

---

## Critique (Debug Mode only)

<Include only when Debug Mode is explicitly enabled. Self-critique grounded in the last three available interactions>

---

## Future Assistance (Debug Mode only)

<Include only when Debug Mode is explicitly enabled. Instructions to self for future responses>
```
