# Development / Testing Prerequisites

Run through this checklist **before** starting any Atlas local work. Full startup commands: [`full-stack-local-setup.md`](./full-stack-local-setup.md). Demoing the PRDV-15619 refresh button specifically? Use [`refresh-proceedings-demo.md`](./refresh-proceedings-demo.md).

---

## Pre-flight checklist

- [ ] **Start Docker Desktop**
- [ ] **Start the Postgres container** — `docker start callisto-postgres`
- [ ] **Start the RabbitMQ container** — `docker start callisto-rabbitmq`
- [ ] **Open DBeaver** and confirm the `callisto` connection is live
- [ ] **Get fresh AWS credentials** from [Planet Portal](https://planetportal.awsapps.com/start/#/?tab=accounts) → Neptune SB *(expire every 1–4h)*
- [ ] **Export your GitHub PAT** in the shell you'll run `npm ci` from:
  ```powershell
  $env:GITHUB_TOKEN = "<your-pat>"   # PowerShell
  ```
  ```bash
  export GITHUB_TOKEN=<your-pat>     # Git Bash
  ```
  PAT must have `read:packages` **and** be SSO-authorized for the PlanetDepos org.

> First time? Containers don't exist yet? → Follow **Step 0** in `full-stack-local-setup.md`.

---

## AI Agent Execution Requirements

When an AI agent performs development, testing, debugging, setup, or configuration work, it must document **every operation it runs** in enough detail that a developer could manually reproduce the same process later.

The agent should provide a clear step-by-step record of:

- **Commands executed** — the exact command line, the working directory, and the shell (PowerShell vs Git Bash matters on this Windows setup).
- **Files created, edited, moved, or deleted** — full paths and the purpose of the change.
- **Configuration values added or changed** — including which file (`.env`, `.env.local`, `.npmrc`, `quasar.config.ts`).
- **Environment variables used or required** — e.g. `NODE_ENV=local`, `GITHUB_TOKEN`, AWS session vars.
- **Docker containers** started, stopped, rebuilt, or inspected.
- **Database connections opened, queries run, or schema/data changes made** — including which DB/schema, and any backups taken before destructive edits.
- **Package installs, dependency changes, or repository access requirements** — including registry/auth requirements.
- **Git operations performed** — branches, commits, pulls, merges, rebases, and token-authenticated package installs.
- **Cloud resources, permissions, roles, subscriptions/tenants, or credentials used** — for this stack, AWS account/role (Neptune SB), Cognito, S3/SQS.
- **Any errors encountered and the exact remediation steps taken.**

Temporary diagnostics (e.g. `console.log`) added during investigation must be **reverted before completion**, and the changelog must note they were added and removed (no diff should remain).

---

## Manual Reproduction Requirement

For every completed task, the agent must include a **"Manual Reproduction Steps"** section (see the PRDV changelogs in `docs/atlas/` for the established format). That section must explain:

1. **The starting state or assumptions** — what is expected to already be running/installed.
2. **The exact sequence of operations performed** — copy-pasteable commands/queries in order.
3. **Any prerequisite services that must already be running** — Docker, backends, browser login.
4. **Any credentials, tokens, permissions, or access requirements.**
5. **Any expected outputs or success indicators** — exact strings/status codes to look for.
6. **Any common failure points or troubleshooting notes.**
7. **Any cleanup steps needed after the operation** — especially restoring spoofed DB state or dropping backup tables.

---

## Useful Prompt to Give the AI Agent

When asking the agent to perform work, include this instruction:

> "While completing this task, keep a full operational log of everything you do. At the end, provide manual reproduction steps detailed enough for a developer to repeat the process without using the AI agent. Include commands, file changes, environment assumptions, required permissions, services started, errors encountered, and troubleshooting notes."

---

## Notes

- Complete this checklist **before** beginning Atlas testing/development to avoid environment setup failures, package-install issues, and permission blockers.
- The deliverable is twofold: the working software **and** documentation good enough to audit, repeat, and debug the work by hand.
- When a task spoofs permissions or seeds/edits local data, treat the local DB as disposable but reversible: back up the affected table first and record the restore command in the changelog's cleanup step.
