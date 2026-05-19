# Pull request workflow (reference)

Personal playbook for opening branches, commits, and PRs with consistent ticketing and evidence. Use this in PlanetDepos repos (and similar) where tickets follow the `PRDV-*` pattern.

## Where this fits (doc vs Cursor rule)

| Approach | What it is | When to use |
| -------- | ---------- | ----------- |
| **This file** (`.cursor/docs/pull-request-workflow.md`) | Reference; copy/paste templates | Bookmark it; `@`-mention it in Cursor when you want this followed; paste into PRs or channels |
| **Cursor Rules** (`.cursor/rules/*.mdc`) | Always-on or path-scoped AI hints | Use for repo-specific conventions (e.g. “never commit `.env`”) inside a **code** project—not required for this personal folder |

**Starting a branch?** Use [new-branch-get-started.md](./new-branch-get-started.md) first. Use **this file** when you open the PR.

---

## Branch and PR framing

- Create work on a **new branch** and push a **PR** (do not merge straight to `main` without review unless policy says otherwise).
- **Branch name:** `<TICKET_NUMBER>` (example: `PRDV-15263`).
- **Session rule:** Only create the branch **once per session**. If the branch for this ticket already exists locally from earlier in the same session, reuse it (`git checkout <TICKET_NUMBER>`) instead of creating again.

---

## Commit message format

```
<TICKET_NUMBER>: <Short imperative description>

<Optional longer body explaining what and why>
```

Examples:

- `PRDV-15263: Turn off Swagger for Callisto outside local`
- Body: bullet points or paragraphs for reviewers—what changed, why, any risks or follow-ups.

---

## PR template

The shared template (when present in the target repo) lives at:

`.github/pull_request_template.md`

Fill it out consistently:

| Field | Guidance |
| ----- | -------- |
| **Title** | `<TICKET_NUMBER>: <Short description>` |
| **Clickup** | Full ClickUp URL for the task |
| **Description** | What changed and why (bullets welcome). Include a **fenced code block with the tip commit hash** (see **Commit hash** below). |
| **Test Evidence** | See **Testing & verification** below—prefer screenshots; call out automated tests only when they matter |
| **Checklist** | All boxes checked before requesting review |

### Commit hash

After you push, capture the revision reviewers should look at (usually **latest commit on the PR branch**). The same habit applies when you land work on **`main`** via [git-commit-workflow.mdc](../rules/git-commit-workflow.mdc): agents and tooling should leave you a **copy-pasteable** hash, not only a narrative “pushed successfully.”

**PowerShell (preferred on Windows):** copy to the clipboard **and** echo to the terminal so you can paste again from chat output if needed:

```powershell
git rev-parse HEAD | Set-Clipboard
git rev-parse HEAD
```

**Bash / sh:**

```bash
git rev-parse HEAD
```

**Cursor agents (after `git push`):** run **`git rev-parse HEAD`**, then reply with **one fenced markdown block containing only the forty-character hash** (no branch name, no `commit` prefix)—same shape as the PR body example below.

In the PR body (often under **Description** or its own short heading), include the hash in a **markdown fenced code block** so it stays easy to copy:

````markdown
### Commit

```
abc123def4567890abcd0123456789abcdef01234567
```
````

Use the same pattern in **Slack / Teams** PR announcements when you paste the hash for quick reference.

---

## Steps (happy path)

1. **`git status` / `git diff`** — Confirm only intended files are staged or modified.
2. **`git log`** — Match recent commit message style in that repo.
3. **`git checkout -b <TICKET_NUMBER>`** — Skip if the branch already exists **in this session**; then `git checkout <TICKET_NUMBER>`.
4. **`git add <only relevant files>`** — Do **not** add unrelated changes.
5. **`git commit`** — Ticket-prefixed subject line; optional body.
6. **`git push -u origin <TICKET_NUMBER>`**
7. **Commit hash** — **`git rev-parse HEAD | Set-Clipboard`** (pwsh) or **`git rev-parse HEAD`**; paste the hash into the PR body (see **Commit hash** above).
8. **`gh pr create`** — Use the repo PR template; **`--base main`** unless the team uses a different default branch. Include the **commit hash** in a fenced code block in the PR body (see **Commit hash** above).

### CLI example (`gh`)

Adapt flags to whatever `gh pr create` prompts your repo for (template bodies often work best pasted from this doc):

```bash
gh pr create --base main --title "PRDV-15263: Short description" --body-file pr-body.md
```

---

## Do not commit

- `.env` files or environment files with secrets  
- Secrets, tokens, private keys  
- Unrelated **`package-lock.json`** / lockfile churn (unless this PR *is* the dependency change)

---

## PR description reference example

Use this structure in the GitHub PR body (adjust headings if the template differs):

### [Clickup - PRDV-15262 - [BE] Turn off Swagger for Triton in higher environments](https://app.clickup.com/t/43227262/PRDV-15262)

### Description

- Gate Swagger setup behind `ENV_NAME === 'local'` in `configure-swagger.ts` so API docs are only exposed during local development.
- Mirrors the Callisto implementation (PRDV-15263): env check lives solely in the swagger bootstrap module, not `main.ts`.
- Swagger UI (`/triton/swagger`) and JSON endpoint (`/triton/swagger-json`) are now only registered when `ENV_NAME` is `local`. All other environments (`dev`, `tst`, `sb`, `prod`, `undefined`) return nothing.

### Commit

```
a1b2c3d4e5f678901234567890abcd1234567890
```

### Testing and Verification

https://atlas-sb.planetdepos.com/triton/swagger  
https://atlas-dev.planetdepos.com/triton/swagger

<img width="1133" height="493" alt="image" src="https://github.com/user-attachments/assets/a1f590c7-8b19-48be-9103-f67ce9551a27" />

### Checklist

- [x] Description provided  
- [x] Clickup link  
- [x] Evidence provided  

---

## Testing & verification (expectations)

- **Default expectation:** You will **build/run** the change and capture **screenshots** as primary evidence. That is the normal bar for “Testing and Verification.”
- **Automated tests:** Only spell out commands/output when specific tests are relevant to the change; otherwise you usually **do not** need long test logs.
- **Section headers:** Keep **### Testing and Verification** (or whatever the template uses) **even when the body is minimal**—for example a short note plus screenshots, or a sentence like “Verified locally; see screenshots below.”
- **Agents / drafts:** If a PR is drafted before you have run the app, leave the section present with a placeholder you replace after verification (do not skip the heading).

---

## Channel comment (Slack / Teams / etc.)

Paste and fill in the blanks:

````
PR for **PRDV-15263 - [BE] Turn off Swagger for Callisto in higher environments**
https://app.clickup.com/t/43227262/PRDV-15263
https://github.com/planetdepos/callisto-back-end/pull/312
```
a1b2c3d4e5f678901234567890abcd1234567890
```
````

Swap ticket title, ClickUp URL, GitHub PR URL, and commit hash per task. The inner triple-backtick block is the **commit hash code block** (easy to copy in Slack/Teams).
