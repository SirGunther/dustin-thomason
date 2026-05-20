# Start a new branch

Do this when you pick up a ticket.

**Map of all workflows:** [workflow-index.md](../../docs/workflow-index.md)

**Ticket memory:** Create or open the changelog in `dustin-thomason` before deep work — see [ticket-changelog-workflow.md](../../docs/ticket-changelog-workflow.md).

## 1. Go to the right repo

`atlas-front-end`, `callisto-back-end`, `europa-back-end`, or `triton-back-end` — whichever owns the work.

## 2. Update main and create the branch

Replace `PRDV-15263` with your ticket number. **The branch name is only the ticket number.**

```bash
git checkout main
git pull origin main
git checkout -b PRDV-15263
```

If that branch already exists on your machine:

```bash
git checkout PRDV-15263
```

## 3. Confirm you're on it

```bash
git branch --show-current
```

Should print `PRDV-15263` (your ticket).

## 4. Create the ticket changelog (first pass)

In **`dustin-thomason`** (this personal repo), not the app repo:

```powershell
cd C:\Users\dustin.thomason\dustin-thomason
.\scripts\new-ticket-changelog.ps1 -Ticket PRDV-15263 -System atlas -Title "Your one-line title"
```

(`<system>` = `atlas`, `callisto`, `europa`, `triton`, or `other` — use `-Repo` when `other`.)

Optional: `-RequirementsFile .\paste-from-clickup.txt` to fill **Requirements (verbatim)** from a file.

Then paste or verify **Requirements (verbatim)** from ClickUp — do not paraphrase the first time.

Agents: [ticket-changelog.mdc](../rules/ticket-changelog.mdc). Playbook: [ticket-changelog-workflow.md](../../docs/ticket-changelog-workflow.md).

## 5. Work, then commit

When you have changes ready:

```bash
git status
git add <files you changed>
git commit -m "PRDV-15263: Short description of what you did"
git push -u origin PRDV-15263
```

Commit message format: **`PRDV-12345: What you changed`** (imperative, short).

## 6. Open the PR

Use your repo’s PR template. Title: **`PRDV-15263: Same short description`**. Pull description bullets from the ticket changelog ([ticket-changelog-workflow.md](../../docs/ticket-changelog-workflow.md)).

---

That’s the starting point. For PR body text, screenshots, and commit hash in the description, use [pull-request-workflow.md](./pull-request-workflow.md) when you’re ready to open the PR—not before.
