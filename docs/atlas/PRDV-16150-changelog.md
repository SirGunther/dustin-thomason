# PRDV-16150 — NPM Vulnerabilities in Atlas

## Ticket

- **ClickUp:** [PRDV-16150](https://app.clickup.com/t/43227262/PRDV-16150)
- **Repo:** `atlas-front-end`
- **Branch:** `PRDV-16150`
- **PR:** _(link when opened)_

---

## Requirements (verbatim)

> PRDV-16150 - NPM Vulnerabilities in Atlas
>
> Recurring NPM package maintenance
>
> Check the following repos for
> - moderate to severe vulnerabilities
> - overrides that can be removed due to package updates
> - general updates "npm audit fix"
>
> Address NPM Package vulnerabilities in:
> - Atlas Front End

---

## Context

- Recurring dependency-maintenance ticket. Resolved by a plain `npm audit fix` — no `package.json` override additions or removals were required.
- Only `package-lock.json` changed; no source or `package.json` changes.

---

## Plans

| Added | Plan (path or link) | Status | One-line approach |
| ----- | ------------------- | ------ | ----------------- |
| 2026-06-30 | in-session | `implemented` | Run `npm audit fix`, verify 0 vulnerabilities, ship the lockfile bump on its own branch. |

---

## Session log

_Newest first._

### 2026-06-30T19:30:00Z — atlas-front-end

- **Summary:** Resolved the recurring NPM vulnerability ticket via `npm audit fix`. The fix bumped vulnerable transitive deps in `package-lock.json` (notably `dompurify` 3.4.0→3.4.11, `form-data` 4.0.5→4.0.6, `js-yaml` 4.1.1→4.3.0, `vite` 7.3.3→7.3.6), plus bundled `npm` 11.14.0→11.18.0 and `@vitest/*` 3.2.4→3.2.6 dev tooling. No `package.json` override changes were needed. Branched from `main` so the PR carries only the lockfile change (isolated from the unrelated PRDV-15619 work-in-progress where the fix was originally generated).
- **Files/areas:** `package-lock.json` only.
- **Intended commit message:** `PRDV-16150: Resolve npm vulnerabilities via audit fix`

| Gate | Command | Scope | Result | Exception / risk |
| ---- | ------- | ----- | ------ | ---------------- |
| audit | `npm audit` | atlas-front-end | pass | 0 vulnerabilities. |
| lint | `npm run lint` | atlas-front-end | pass | `eslint . --max-warnings 0`, clean. |
| tests | `npx vitest run --maxWorkers 1` | full unit suite | pass | 98 files, 853 passed / 4 skipped. |

- **Tests added/updated:** not relevant — dependency-only change (lockfile); no behavior or logic changed, so no unit under test was added or modified.
- **Regression impact:** isolated to `package-lock.json`; `package.json` (declared deps + overrides) unchanged, so resolved app-facing dependency ranges are unchanged. Full lint + unit suite green confirms no behavioral regression from the patched transitive versions.
- **API docs:** not relevant — front-end dependency maintenance; no HTTP contract or API surface in this repo.
- **Conflicts / exceptions:** none.

---

## Current state (as of 2026-06-30)

- `npm audit fix` applied; `npm audit` reports **0 vulnerabilities**.
- Change isolated to `package-lock.json` on branch `PRDV-16150` (cut from `main`).
- audit + lint + full unit suite all green; ready for PR.
