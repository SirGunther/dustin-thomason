# Session start (optional)

Rules in `.cursor/rules/` (and generated **`AGENTS.md`**) already load automatically. Agents **must** resolve and read the canonical changelog **once at the start of each new substantive task** — see [ticket-changelog.mdc](../rules/ticket-changelog.mdc) (**Task start — changelog alignment**). You do **not** have to `@` the file for that to happen.

Copy-paste below only when you want to **point** the agent at a specific ticket or scaffold a missing log.

**Existing changelog:**

```text
Working on PRDV-XXXXX. Ticket log: @docs/atlas/PRDV-XXXXX-changelog
(read Plans + Attempt history before proposing a new approach)
```

Replace `atlas` and the filename for your system/ticket.

**No changelog yet:**

```text
Working on PRDV-XXXXX (atlas). Scaffold changelog and capture requirements verbatim.
```

**Personal project** (Countdowns, WorkLists, …):

```text
Working on Countdowns. Project log: @docs/countdowns/countdowns-app-changelog.mdc
```
