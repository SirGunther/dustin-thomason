# PRDV-16192 — PR draft

> **UNFILLED SHELL.** Staged at Phase 2 to get the head start; the body is written at **Phase 5**, after the change is implemented and verified. Scope can still move in Phases 3–4, so do not fill this early. Content is assembled from [`testing/PRDV-16192-testing-implementation.md`](./testing/PRDV-16192-testing-implementation.md) (scenario-first) and the [test plan](./testing/PRDV-16192-test-plan.md) results log — never copied into source comments.

**Repo(s):** _TBD at Phase 4 — likely `europa-back-end` (primary) and `atlas-front-end`; `callisto-back-end` only if OV-1 puts work on the emit side. One PR per repo._

## Title

_(Phase 5 — `PRDV-16192: <five to seven descriptive words>`)_

### Clickup

https://app.clickup.com/t/43227262/PRDV-16192

### Description:

_(Phase 5 — Problem → Requirement → Solution. Lead with the reclassification: the ticket reads as three display defects; the cause is one read-path mismatch. Reference the [Why doc](./PRDV-16192-why-these-changes.md) categorized change breakdown.)_

### Test Evidence

_(Phase 5 — per-scenario, from the testing-implementation doc: the real situations stress-tested, why each matters, and any change hung off the scenario that forced it. Plus the gate table: exact command + scope + result.)_

### Checklist

- [ ] Description provided
- [ ] Clickup link
- [ ] Evidence provided.

### Commit hash

_(Phase 5 — `git rev-parse HEAD`, in a fenced block containing only the forty-character hash.)_

---

## Reviewer notes to assemble at Phase 5

- [ ] Lead with the reclassification — reviewers will expect a Callisto change and the fix is in Europa.
- [ ] State the retroactivity property explicitly: historical entries are repaired with no migration, because `resourcePath` was already stored.
- [ ] Name the neighbours proven unchanged (`LOGIN`/`LOGOUT`, `PROCEEDING`, single-resource `FILE`) — absence of change verified against a concrete surface.
- [ ] Say whether `MERGED` was fixed or deliberately left (OV-5), never leave it ambiguous.
- [ ] Link the future-development concerns doc for the items consciously left out of scope.
- [ ] **No reviewer requested** — per the git-commit-workflow rule, open with no reviewers set.
