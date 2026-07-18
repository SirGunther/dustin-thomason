# Q and A to Spec Traceability

Use this workflow when a requirements conversation, grill-me pass, investigation review, or user correction needs to become durable spec content. Its job is to prevent settled answers from being re-asked, diluted, or lost between conversation and implementation.

This document is a process guardrail. It does not replace `agents/skills/grill-me/SKILL.md`, `agents/docs/investigation-report.md`, or `agents/rules/spec-writing.md`. Load it alongside those documents when the task moves from questions into a spec or implementation plan.

## How to reference it

Use any of these phrases:

- `@qa-to-spec-traceability`
- "Use Q and A to Spec Traceability for this ticket."
- "Run the locked-decision ledger before the spec."
- "Audit the spec against the Q and A ledger."
- "Do not ask again; reconcile against Q and A traceability."

When invoked, the agent must create or update a locked-decision ledger before continuing the spec or implementation plan.

## When to use it

Use this workflow when:

- A user answers design questions that affect behavior, scope, UI, contracts, state, tests, or rollout.
- A user corrects the agent's interpretation of requirements.
- A grill-me session produces decisions that must feed a spec.
- A Phase 3 probe/spec pass follows a Phase 1 investigation report.
- A spec seems to contain open questions that may already be answered in the ticket, investigation, changelog, or conversation.

Do not use this workflow to invent new requirements. It preserves and reconciles requirements that already exist.

## Core rule

Every user answer that changes, narrows, rejects, or locks behavior becomes a locked decision before the next question, spec update, or implementation plan proceeds.

A locked decision is no longer an open design option. If later source material conflicts with it, the latest explicit user correction wins unless the user reopens the decision.

## Required workflow

1. Gather only relevant sources.
   - Original ticket or request.
   - Investigation report or canonical project artifact.
   - Changelog entries that directly affect the feature.
   - Current Q and A transcript or user corrections.
   - Spec-writing rule when a spec is being created.

2. Build the current answer ledger.
   - Record the decision in direct, implementation-shaped language.
   - Cite the source: original ticket, investigation artifact, changelog, or user clarification.
   - Mark whether it supersedes an earlier assumption.
   - Name where the decision must appear in the spec.

3. Reconcile before asking.
   - Search the ticket, investigation, changelog, existing artifact, and ledger first.
   - If the answer exists, cite it instead of asking.
   - If the user says the answer was already discussed, stop the question path and reconcile immediately.

4. Ask only material unresolved questions.
   - Ask one question at a time.
   - Do not ask about behavior already locked by the ticket or ledger.
   - Do not ask preference questions when the implementation path is implied by the requirement and existing system behavior.

5. Commit each answer immediately.
   - Add the answer to the ledger in the artifact being produced.
   - If the answer rejects a prior path, record the rejected path so it does not return later as an option.
   - If the answer narrows scope, record what is out of scope.

6. Transfer decisions into the spec.
   - Add a section named `Locked Decisions From Q and A` near the top of the spec.
   - Map implementation requirements and acceptance criteria back to the locked decisions.
   - Keep open variables separate from locked decisions.

7. Audit before finalizing.
   - No locked decision may remain as `TBD`, `open`, or `needs confirmation`.
   - No rejected path may reappear as a recommended option.
   - Every acceptance criterion must trace to the ticket, investigation, changelog, or locked-decision ledger.
   - The Problem, Requirement, and Solution sections must reflect the locked decisions.

## Locked-decision ledger template

| ID | Locked decision | Source | Supersedes or rejects | Spec destination |
| --- | --- | --- | --- | --- |
| LD-001 |  |  |  |  |

## Spec section template

```markdown
## Locked Decisions From Q and A

| Decision | Source | Implementation consequence |
| --- | --- | --- |
|  |  |  |
```

## Question gate template

Use this gate before asking a question during grill-me or spec writing:

```markdown
### Question Gate

- Proposed question:
- Existing answer check:
- Current behavior evidence:
- Recommendation:
- Ask only if still unresolved:
```

If `Existing answer check` finds an answer, do not ask the question. Cite the answer and update the ledger.

## Correction handling

When the user says a question was already answered:

1. Stop asking that question.
2. Pull the original ticket, current artifact, or conversation context that answers it.
3. Cite the answer back briefly.
4. Add or update the locked-decision ledger.
5. Continue from the reconciled decision.

When the user says "no" or rejects a path, record the rejection as a locked decision. Do not bring the rejected path back as an option unless the user explicitly reopens it.

## Definition of done

This workflow is done when:

- The ledger exists in the generated artifact or spec.
- Each locked decision has a source and implementation consequence.
- The spec has a `Locked Decisions From Q and A` section.
- Acceptance criteria and test scenarios reflect the locked decisions.
- Open questions contain only genuinely unresolved variables.
- The agent can proceed without re-asking answered questions.
