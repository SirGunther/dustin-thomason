# Cursor docs (playbooks)

**Unsure what to `@`?** → [workflow-index.md](../../docs/workflow-index.md) (or type `@workflow-index`).

| Task | `@` this file |
| ---- | ------------- |
| New agent on a ticket (optional) | [session-start.md](./session-start.md) |
| New branch / ticket | [new-branch-get-started.md](./new-branch-get-started.md) |
| Open PR | [pull-request-workflow.md](./pull-request-workflow.md) |
| Wiring audit | run `scripts/validate-workflows.ps1` |

Ticket changelogs live in **`docs/<system>/PRDV-XXXXX-changelog.md`**; personal projects use **`docs/<project>/*-changelog*`**. Not under `.cursor/docs/`.

**Personal rules load automatically** when `dustin-thomason` is in the workspace — including while you edit Callisto/Atlas. Agents **resolve and read** the canonical changelog at **task start** for substantive work ([ticket-changelog.mdc](../rules/ticket-changelog.mdc)). Say *“write a spec”* or *“commit”*; do **not** copy rules into app repos. Router: `personal-methodology.mdc`.

**`@` the changelog** on a new agent thread is **optional** but helpful when several tickets or repos are open.

**Multi-root:** [workflow-index.md](../../docs/workflow-index.md#multi-root-workspace-callisto--dustin-thomason)
