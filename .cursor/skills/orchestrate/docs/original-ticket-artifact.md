# Original Ticket Artifact

Use this instruction when a request needs a stable source-of-truth artifact before investigation, Q and A, spec writing, or implementation planning begins.

The purpose of `original-ticket.md` is to establish one fact:

> This is the original ticket/request as it was provided.

It is not an investigation, not a spec, not a decision log, and not a place to infer missing requirements.

## How to reference it

Use any of these phrases:

- `@original-ticket-artifact`
- "Generate the original ticket artifact."
- "Create the original-ticket.md first."
- "Capture the original ticket as source of truth."
- "Establish the original ticket fact before investigation."

When invoked, create or update the canonical `original-ticket.md` artifact before generating investigation, Q and A, spec, or implementation-plan artifacts.

## Output location

Default path:

```text
docs/<Project>/tickets/<ticket-slug>/original-ticket.md
```

Sibling artifacts should live under the same ticket folder when created later:

```text
docs/<Project>/tickets/<ticket-slug>/investigations/<ticket-slug>-investigation.md
docs/<Project>/tickets/<ticket-slug>/specs/<ticket-slug>-spec.md
```

Example:

```text
docs/WorkLists/tickets/prompt-injection-note-refinement/original-ticket.md
```

## Core rules

- Preserve the original request as the baseline fact.
- Keep the user's wording intact wherever practical.
- Record only minimal provenance metadata.
- Do not add investigation findings.
- Do not add agent recommendations.
- Do not add later Q and A decisions.
- Do not rewrite the ticket to match later clarifications.
- If later clarifications conflict with the original request, preserve the original here and record the clarification in the Q and A ledger or spec.

## Required contents

An `original-ticket.md` artifact should contain only:

1. Title.
2. Capture metadata.
3. Original request.
4. Explicit constraints present in the original request.
5. Context paths or links present in the original request.

**Nothing else.** This artifact is the request and only the request, and it is immutable once captured — no later phase appends to it. Paths to the files a ticket produces belong in the ledger's **Artifacts** column, never here. A Downstream Artifacts section used to live in the template below; it duplicated the ledger and blurred this boundary, so it was removed.

## Artifact template

```markdown
# <Ticket Title> - Original Ticket

## Capture Metadata

| Field | Value |
| --- | --- |
| Project |  |
| Ticket slug / ID |  |
| Captured on | YYYY-MM-DD |
| Source | User-provided request / backlog item / chat prompt / external ticket |
| Formatting | Verbatim / lightly formatted for Markdown |

## Original Request

<Preserve the original request text here. Keep headings, bullets, estimates, and phase instructions intact.>

## Explicit Constraints In Original Request

- 

## Context Paths In Original Request

- 
```

## What belongs here

- The initial problem statement.
- The initial requirement statement.
- The initial proposed solution, if one was provided.
- Initial estimate or phase structure, if provided.
- Original constraints such as "do not change code yet" or "do not pull broad modules."
- Original links and file paths provided as context.

## What does not belong here

- Investigation findings.
- Open questions.
- Answered grill-me questions.
- Later locked decisions.
- Implementation recommendations.
- Test plans.
- Acceptance criteria unless they were part of the original request text.

## Definition of done

This artifact is done when a future agent can open it and know exactly what was originally asked, where it came from, and when it was captured.
