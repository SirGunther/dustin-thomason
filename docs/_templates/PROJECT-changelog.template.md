# {{PROJECT}} App — General Changelog

## Purpose

Running changelog for {{PROJECT}}. _One line on what the project is._

---

## Record integrity

_What is confirmed, by what evidence, and what is unrecoverable. State the gaps rather than
letting a reader assume the record is complete._

- Every entry below was written in the session it describes; none is reconstructed after the fact.
- Verification claims name the command that produced them. Where a check could not be run, the
  entry says so and names the residual risk rather than recording `N/A`.

---

## Scope

- **App:** `{{PROJECT}}`
- **Primary workspace:** `{{REPO_PATH}}`
- **Log location:** `{{DOCS_PATH}}\{{SLUG}}-app-changelog.md`

---

## Current state

**Phase:** _where the project is now._

- _What is true today. Do not contradict this without saying why._

**Next:** _the next boundary, and what decides it._

---

## Plans

| Date | Plan | Status | Approach |
| --- | --- | --- | --- |
| {{DATE}} | _path or in-session label_ | `active` | _one line_ |

---

## Session log

_Newest first. Add one entry per working session or merge-worthy update._

### {{DATE}}T00:00:00Z — _short title_

- **Summary:** _what happened._
- **Problem:** _the underlying need, not a restatement of the task title._
- **Requirement:** _what must be true to resolve it, stated independently of the solution._
- **Solution:** _the change, and how it traces back to the requirement._
- **Files/areas:** _paths touched._
- **User-visible impact:** _what a user would notice, or plainly "none"._
- **Tests run:** _exact command, scope, result. Never "tests passed."_
- **Tests added/updated:** _what was added, or the named blocker plus the residual risk and
  the smallest follow-up that would unlock coverage._
- **Regression impact:** _the boundary that isolates the change, or the neighbours checked.
  "Isolated" alone is not sufficient — name what makes it isolated._
- **API docs:** _updated, or not relevant with the checked surface named._
- **Tooling gates:** _each gate, or why it does not apply. Name the gate and the reason._
- **Conflicts / exceptions:** _anything skipped, blocked, or overridden, with the residual risk._
