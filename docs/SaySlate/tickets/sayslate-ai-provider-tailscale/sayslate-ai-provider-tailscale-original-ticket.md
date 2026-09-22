# SaySlate AI Provider and Tailscale Integration - Original Ticket

## Capture Metadata

| Field | Value |
| --- | --- |
| Project | SaySlate |
| Ticket slug / ID | `sayslate-ai-provider-tailscale` |
| Captured on | 2026-09-22 |
| Source | User-provided chat request |
| Formatting | Lightly formatted for Markdown; wording preserved |

## Original Request

We are going to do a feature update. We are going to integrate Tailscale to allow us to hit our own endpoint via LM studio. Currently, the other local system [@Argus - Main](thread://019ff2a0-99cb-7031-9820-0f01937d7000) has the ability to use LM studio, so code is there to handle how that integration works, it can be used as a reference for that integration.

Basically, the icon for connection needs to host multiple types of apis, Openai, claude, gemini, all the various keys, model ids, be able to test the connection, etc. And specifically that we want to use a custom secure provider via tailscale to LM studio.

So what I need you to do is create a 'todo' that I will pass along to another agent.

I was told a basic mvp could look like

Extension setting:
  inferenceBaseUrl
  modelId
  apiToken

Service worker:
  runAI()

Transport:
  POST /v1/chat/completions

Authentication:
  Bearer token

Network:
  Tailscale

Output:
  JSON schema whenever possible

But that is quite rough.

Do the research, create the TODO artifact in the Dustin Thomason repo, and create it in the spirit of

C:\Argus\docs\plans\SCRIBE-PIPELINE-INTEGRATION-TODO.md

C:\Argus\docs\plans\ARGUS-ISOLATED-TICKET-HANDOFF.md

C:\Argus\docs\plans\SCRIBE-STATELESS-REQUEST-HARDENING-TODO.md

Basically the most important aspects to make sure that are present are the evidence and the way a resolved and unresolved request works. The Agent will be sending subagents to do the work. So each must edit the doc with the nature of the action for its section, each section must be broken down for high level reasoning vs low reasoning implementation.

However, ignore the pause portion, this is now an all selfcontained orchestration that requires the main model to manage the implementation and oversee the lower tiered models, please ingest all documentation.

SCRIBE-05A — Asynchronous model admission and truthful Scribe progress
C:\Argus\docs\plans\SCRIBE-PIPELINE-INTEGRATION-TODO.md

The following are reminders that you MUST use the following!
C:\dustin-thomason\agents\skills\checklist-in-chat\SKILL.md
C:\dustin-thomason\agents\rules\agent-completion-notification.md

Start with Stage 1.
Let me know when ready Stage 2, for the higher reasoning section of the task so I can switch models.

The checklist was not merely a request, it is mandatory, even if it means you are planning your own actions, these are for visibility.

This is all very important because this is the first time we are using all of these methods combined.
C:\dustin-thomason\agents\skills\checklist-in-chat\SKILL.md

## Explicit Constraints In Original Request

- Research before defining the implementation work.
- Use Argus's LM Studio integration as reference material.
- Account for OpenAI, Claude, Gemini, and a custom Tailscale/LM Studio provider.
- Include keys, model IDs, endpoint configuration, and connection testing.
- Request JSON Schema output whenever possible.
- Separate high-level reasoning from low-reasoning implementation.
- Make the main model responsible for continuous orchestration and lower-tier agents.
- Preserve implementation and review evidence, including resolved and unresolved work.
- Use the checklist-in-chat and completion-notification instructions.

## Context Paths In Original Request

- `C:\Argus\docs\plans\SCRIBE-PIPELINE-INTEGRATION-TODO.md`
- `C:\Argus\docs\plans\ARGUS-ISOLATED-TICKET-HANDOFF.md`
- `C:\Argus\docs\plans\SCRIBE-STATELESS-REQUEST-HARDENING-TODO.md`
- `C:\dustin-thomason\agents\skills\checklist-in-chat\SKILL.md`
- `C:\dustin-thomason\agents\rules\agent-completion-notification.md`
- `thread://019ff2a0-99cb-7031-9820-0f01937d7000`
