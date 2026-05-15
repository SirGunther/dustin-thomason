# Commit & push workflow (routing doc)

Operational instructions—including **`npm audit --audit-level=high`**, **`npm run lint`** before **`git commit`**, repo-specific ESLint quirks, the **`git`** sequence, and pasted **SHA** etiquette—live in the Cursor workspace rule:

**[`/.cursor/rules/git-commit-workflow.mdc`](../.cursor/rules/git-commit-workflow.mdc)**

## Why stay in `.cursor/`?

Cursor loads **`alwaysApply`** rules from **`.cursor/rules/`**. Moving the authoritative file exclusively into **`.github/`** drops that automation unless you rebuild wiring elsewhere—so **`git-commit-workflow.mdc` stays canonical here**, and **this Markdown file only helps people browsing **`.github/**` on GitHub or in the IDE.
