# Ticket changelog workflow

Personal, ticket-scoped memory that travels with you across repos, sessions, and agents. One file per ticket keeps context out of chat history so you do not re-explain requirements every time you commit or open a PR.

**Authoritative location:** `docs/` in this repo (`dustin-thomason`). Cursor references live under `.cursor/docs/` and `.cursor/rules/` but point here.

---

## When to use this

| Moment | Doc to follow | Changelog action |
| ------ | ------------- | ---------------- |
| Pick up a ticket, create branch | [new-branch-get-started.md](../.cursor/docs/new-branch-get-started.md) | **Create** changelog (first pass — see below) |
| Work in Cursor / another agent | — | **Append** session notes as you go (optional but cheap insurance) |
| Commit or push (any PlanetDepos repo) | [git-commit-workflow.mdc](../.cursor/rules/git-commit-workflow.mdc) | **Update** changelog before `git commit` (required for agents) |
| Open PR | [pull-request-workflow.md](../.cursor/docs/pull-request-workflow.md) | **Mine** changelog for Description / learnings |

---

## File layout

```
docs/
  ticket-changelog-workflow.md          ← this file
  _templates/
    TICKET-changelog.template.md       ← copy when starting a ticket
  <system>/                            ← atlas | callisto | europa | triton | other
    PRDV-12345-changelog.md
```

- **`<system>`** — short name for where the code lives (`atlas`, `callisto`, `europa`, `triton`, or `other` for cross-cutting / personal-only work).
- **Filename** — `PRDV-12345-changelog.md` (ticket number + `-changelog`).

Example: [atlas/PRDV-12264-changelog.md](./atlas/PRDV-12264-changelog.md).

---

## First pass (branch / new ticket)

Do this **once** when you start the ticket (step 4 in [new-branch-get-started.md](../.cursor/docs/new-branch-get-started.md)), or the **first time** an agent touches commit workflow for that ticket.

### Scaffold script (preferred)

From repo root:

```powershell
.\scripts\new-ticket-changelog.ps1 -Ticket PRDV-12345 -System atlas -Title "One-line title"
```

| Parameter | Purpose |
| --------- | ------- |
| `-Ticket` | `PRDV-12345` (required) |
| `-System` | `atlas` \| `callisto` \| `europa` \| `triton` \| `other` (required) |
| `-Title` | H1 subtitle (optional) |
| `-Repo` | Overrides default repo for the system (required when `-System other`) |
| `-RequirementsFile` | Path to text file → pasted into **Requirements (verbatim)** as blockquote lines |
| `-Force` | Overwrite existing changelog (use sparingly) |

Default repos: `atlas` → `atlas-front-end`, `callisto` → `callisto-back-end`, `europa` → `europa-back-end`, `triton` → `triton-back-end`.

Manual fallback: copy `docs/_templates/TICKET-changelog.template.md` → `docs/<system>/PRDV-XXXXX-changelog.md`.

### After scaffold

1. Paste or verify **Requirements (verbatim)** — **do not paraphrase** on first capture.
2. Add **Context** only if the user supplied constraints (env, related PRs, specs in `larry-adams`, etc.).

Agents always load [.cursor/rules/ticket-changelog.mdc](../.cursor/rules/ticket-changelog.mdc). Treat the changelog as the source of truth for "what we agreed the ticket means."

---

## Before every commit (agents)

When [git-commit-workflow.mdc](../.cursor/rules/git-commit-workflow.mdc) runs (user asks to commit/push, or agent lands code):

1. **Resolve ticket** — from branch name (`PRDV-12345`), commit subject, or user message.
2. **Locate changelog** — `docs/<system>/PRDV-12345-changelog.md`. If missing, run **First pass** using whatever ticket text is in the current conversation.
3. **Append a Session log entry** (newest at top under `## Session log`):
   - **Date** (YYYY-MM-DD)
   - **Repos touched** (e.g. `atlas-front-end`)
   - **Summary** — what changed this conversation (files/areas, behavior)
   - **Commits** (optional) — short subject or SHA after commit
4. If the attempt failed or taught something durable, add or extend **Attempt history** / **Key technical learnings**.
5. Refresh **Current state** so the next agent knows what is done vs pending.
6. Then run pre-flight (audit/lint/test) and git steps per git-commit-workflow.

**Gate:** Do not `git commit` without a session log entry that covers work from **this** conversation (unless the user explicitly waives changelog for a trivial doc-only tweak in `dustin-thomason` only).

---

## Session log entry shape

```markdown
### 2026-05-20 — atlas-front-end

- **Summary:** Added `useTextTruncation`; wired ProceedingFileTableDataRow tooltip when ellipsis active.
- **Files:** `useTextTruncation.ts`, `ProceedingFileTableDataRow.vue`, …
- **Commits:** `PRDV-12264: Add truncation composable` (pending)
- **Notes:** Parent tables still need `table-layout: fixed` — see Current state.
```

Keep entries short; link to attempt history for long debugging threads.

---

## Pull requests

When drafting a PR ([pull-request-workflow.md](../.cursor/docs/pull-request-workflow.md)):

- **Description** — pull bullets from **Requirements**, **Current state**, and the latest **Session log** entry.
- **What not to do** — do not paste the entire changelog into GitHub; summarize and link to this repo path if reviewers need depth.

---

## Tips for humans

- `@` mention `docs/ticket-changelog-workflow.md` or the ticket file when starting a new agent thread.
- One changelog per ticket, even if you touch multiple repos — use **Session log** to note which repo each slice landed in.
- For long tickets, keep **Attempt history** so you do not retry dead ends across sessions.
