# Development / Testing Prerequisites

Complete this checklist **before** beginning any Atlas-related testing or development work. It exists to prevent the recurring class of failures we keep hitting: environment setup gaps, package-install (token) issues, missing Postgres extensions, and credential/permission blockers.

The goal is not just to get work done, but to leave behind enough documentation that the work can be **understood, audited, repeated, and debugged manually** — without an AI agent.

> Related docs: the end-to-end runbook is [`full-stack-local-setup.md`](./full-stack-local-setup.md); per-service runbooks are [`callisto-local.mdc`](./callisto-local.mdc), [`triton-local.mdc`](./triton-local.mdc), [`europa-local.mdc`](./europa-local.mdc). This file is the pre-flight gate that sits in front of all of them.

---

## Atlas Testing Setup

Before testing with Atlas, ensure the following prerequisites are complete:

- [ ] **Start the required Docker containers.** `callisto-postgres` (Postgres) and `callisto-rabbitmq` (RabbitMQ). Verify with `docker ps`. If they don't exist yet, follow Step 0 of `full-stack-local-setup.md`.
- [ ] **Start your database client (DBeaver).** Connections for the `callisto` and `triton` databases (both on the same `callisto-postgres` container, port `5432`).
- [ ] **Confirm the database is running and accessible.** `docker exec callisto-postgres psql -U postgres -d callisto -c "SELECT 1;"` returns a row. The `callisto` schema is seeded (roles, resource_keys, permissions).
- [ ] **Confirm required Postgres extensions exist.** `uuid-ossp` and `pgcrypto` in the `callisto` DB's `public` schema — the `notifications` migrations call `uuid_generate_v4()` on startup and the app crashes without them. See `full-stack-local-setup.md` → Step 0 / Common issues.
- [ ] **Verify cloud credentials are configured.** This stack runs on **AWS** (Neptune SB), not Azure: Callisto verifies Cognito tokens and Triton uses S3/SQS. Pull fresh session creds from [Planet Portal](https://planetportal.awsapps.com/start/#/?tab=accounts) — they expire every 1-4 hours. (If a task additionally involves Azure/Foundry tooling, configure those separately; they are not part of the Atlas local stack.)
- [ ] **Confirm all required GitHub tokens are available.** A PAT is needed for `npm ci` to install `@planetdepos/*` packages from GitHub Packages.
- [ ] **Check that the GitHub token is not expired.** An expired PAT 401s exactly like a missing one.
- [ ] **Confirm the token has access to install packages from the private/org repositories.** It must have `read:packages` **and** be SSO-authorized for the PlanetDepos org. Export it in the **same shell** before installing (`$env:GITHUB_TOKEN` in PowerShell / `export GITHUB_TOKEN` in Git Bash), because `.npmrc` resolves `_authToken=${GITHUB_TOKEN}` from the shell env, not from `.env.local`.

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
