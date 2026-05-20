---
name: workflow-housekeeping
description: Audit dustin-thomason workflow docs, rules, and index for drift, duplicates, and missing entries. Use when user asks to housekeeping workflows, sync workflow-index, validate personal Cursor setup, or after adding a new playbook or rule.
---

# Workflow housekeeping

Run in **`dustin-thomason`** only.

## Steps

1. Run **`.\scripts\validate-workflows.ps1`** from repo root. Capture all warnings/errors.

2. Inventory and compare to [docs/workflow-index.md](../../docs/workflow-index.md):
   - `.cursor/rules/*.mdc` — note `alwaysApply` and `globs`
   - `.cursor/docs/*.md` — playbooks (exclude README)
   - `docs/ticket-changelog-workflow.md`, `docs/_templates/`, `scripts/new-ticket-changelog.ps1`
   - Flag ticket changelogs under `.cursor/docs/` (should not exist)

3. Fix drift:
   - Update **workflow-index** tables
   - Fix broken relative links in index and README
   - Remove duplicate stubs; keep `.github/` as one-line pointers only

4. Report to user:
   - What was out of date
   - What you changed
   - Anything they must decide manually (e.g. new workflow type with no playbook yet)

Do not modify app-repo workspaces (atlas-front-end, callisto-back-end, etc.) unless the user explicitly asks.
