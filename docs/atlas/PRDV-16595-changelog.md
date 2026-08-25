# PRDV-16595 — 1-Callisto remediate high/critical security vulnerabilities

## Ticket

- **ClickUp:** [PRDV-16595](https://app.clickup.com/t/43227262/PRDV-16595) — Technical Story, 3 points, Owning Team NASA, status IN PROGRESS (ClickUp internal id `86ak0c9p7`)
- **Parent epic:** [PRDV-16423](https://app.clickup.com/t/43227262/PRDV-16423) — sequenced **1st of 3** (`1-Callisto`, `2-Nova`, `3-Europa`)
- **Repo:** `callisto-back-end`
- **Branch:** _(none — no code change required, see Current state)_
- **PR:** _(none)_
- **WorkLists card:** `todo-1787666748649-710ac783`

---

## Requirements (verbatim)

Captured verbatim in `docs/atlas/PRDV-16595/PRDV-16595-original-ticket.md` (ClickUp browser capture, 2026-08-25). Reproduced unchanged:

> #### See Epic for Value Proposition
>
> #### **Acceptance Criteria**
>
> - No high- or critical-severity security vulnerabilities remain for Callisto
> - All three systems can be deployed to AWS through the standard deployment process without security-related exceptions.

The ticket body then carries an `overrides` JSON block. **That block is Callisto's current `package.json` state, not a proposal** — see Current state.

---

## Context

- **The gate** (established under PRDV-16423): `npm audit --audit-level=high` in the DevOps-managed reusable workflow `planetdepos/actions/.github/workflows/node-service-ci.yml@main`, run after `npm install` on the full tree. Dev dependencies count. The ECR push job depends on it.
- **URL discrepancy in the kickoff message.** The card title supplied by the user read `... - PRDV-16595` but the pasted link pointed at `/t/43227262/PRDV-16423` (the epic). The original-ticket artifact is authoritative and gives `https://app.clickup.com/t/43227262/PRDV-16595`; the card was written with that. This is the exact title-vs-link hazard `worklists-card-sync` warns about, resolved from the source artifact rather than by guessing.
- **AC line 2 is epic-scoped**, not Callisto-scoped ("All three systems can be deployed"). Callisto alone cannot satisfy it; it closes when all three child stories close.

---

## Plans

| Added | Plan (path or link) | Status | One-line approach |
| ----- | ------------------- | ------ | ----------------- |
| 2026-08-25 | `docs/atlas/PRDV-16595/PRDV-16595-callisto-remediation-state.md` | `active` | Establish that Callisto is already remediated, ratify its `overrides` block as the epic's canonical pattern, document the accepted `aws-sdk` residual. |
| 2026-08-25 | `docs/atlas/PRDV-16423/PRDV-16423-baseline-audit.md` (epic) | `superseded in part` | Epic triage. Its nova-orbital recommendation (derive the OTel override, raise `js-yaml` to `^4.3.1`) is superseded — Callisto's block already solves it, scoped, at `js-yaml ^5.2.3`. |

---

## Current state

**Callisto already satisfies AC line 1.** `npm audit` on `main` @ `56eead71` reports **0 high, 0 critical**. No code change is required in `callisto-back-end`.

The `overrides` block in the ticket body is Callisto's committed `package.json` state, verbatim. Every version it pins was verified to exist on the public registry. It was not authored for this ticket — `git log -S` shows it accumulating across PRDV-14641, PRDV-14699, PRDV-15850, PRDV-16081, PRDV-16288 and PRDV-16391, paid for piecemeal by whoever was blocked at the time.

**This story is ratification, not remediation** — which is why it is sequenced first and still worth 3 points. Its deliverable is the pattern the other two stories consume.

**The epic-reframing finding.** All four repos already carry `overrides` blocks, and each repo's audit failures correspond exactly to what its block is missing or has let go stale. Callisto's is complete; nova-back-end's is partially stale (`brace-expansion ^5.0.8` vs patched `5.0.9`; `js-yaml ^4.2.0` inside a range vulnerable through `4.3.0`); nova-orbital has no OTel entries at all and takes six findings for it; europa lacks js-yaml/brace-expansion/multer/fast-uri entries and is flagged for precisely those. The correspondence holds in both directions — nova-back-end's OTel overrides *are* current and it reports zero OTel findings against the same internal `pathfinder-observability-pkg` dependency that gives nova-orbital six.

So PRDV-16423 is one overrides block developed in Callisto and never propagated, plus floor drift where it was partially copied. Stories 2 and 3 should **port Callisto's block**, not re-derive fixes.

**Accepted residual:** 5 low + 2 moderate, all `aws-sdk` → bundled `uuid`. npm offers only `--force` installing `aws-sdk@1.18.0` (downgrade-shaped major). Outside AC scope, not gate-blocking. Accept and document.

**Open, and genuinely yours:** whether "ratify the pattern" is worth 3 points now that no Callisto code changes, and whether the propagation work is re-pointed onto stories 2 and 3. Recommendation in the epic changelog.

---

## Attempt history

_None — no implementation attempted or required._

---

## Session log

### 2026-08-25T14:10:00Z — callisto-back-end (read-only analysis) + WorkLists card scaffold

**Summary.** Narrowed from the PRDV-16423 epic to its first sequenced child story. Established that Callisto is already remediated and identified why the epic's other three repos are not. No production code touched, no branch created, no commit made.

**What the ticket body turned out to be.** The `overrides` JSON in the ClickUp description read initially as a proposed remediation. Compared it field-by-field against `callisto-back-end/package.json` on `main`: it is the committed block, verbatim. Verified every pinned version resolves on the public registry (`js-yaml@5.2.3`, `auto-instrumentations-node@0.79.0`, `sdk-node@0.221.0`, `propagator-jaeger@2.10.0`, `picomatch@4.0.4`, `brace-expansion@5.0.9`, `tar@7.5.7`, `multer@2.2.0`) — nothing aspirational in it.

**Provenance traced.** `git log -S'pathfinder-observability-pkg'` and `-S'propagator-jaeger'` on `package.json`, plus `log -L` over the overrides range, attribute the block to six prior tickets (PRDV-14641, PRDV-14699, PRDV-15850, PRDV-16081, PRDV-16288, PRDV-16391). Notably `a8761489 PRDV-14699: Resolve npm audit via OpenTelemetry overrides` and `f75dd4e0 PRDV-15850: Fixed high level vulnerabilities`.

**Cross-repo comparison — the finding.** Dumped `overrides` from all four epic repos and mapped them against the PRDV-16423 audit results. Every flagged package corresponds to a missing or stale override; every current override corresponds to an absent finding. Recorded as a matrix in the artifact.

**Two corrections to my own PRDV-16423 triage**, both material to stories 2 and 3:
- I reported `js-yaml`'s patched release as `4.3.1` after filtering only the 4.x line. A 5.x line exists (latest `5.4.0`), and Callisto deliberately pins `^5.2.3`. The 5.x jump is the proven answer, not a 4.x floor bump.
- I recommended designing nova-orbital's OTel override from scratch. Unnecessary — Callisto's scoped block already covers that exact chain and is deployed.

**Files/areas:** `docs/atlas/PRDV-16595-changelog.md` (new), `docs/atlas/PRDV-16595/PRDV-16595-callisto-remediation-state.md` (new). No app-repo files changed; `callisto-back-end` verified clean at `main` `56eead71`.

**WorkLists card `todo-1787666748649-710ac783`:**
- Card arrived as a bare template (body was the single line `# Ticket Template`, no workflow headings, so `currentStep` would have 400'd). Wrote the title + workflow scaffold first, then set fields on a fresh precondition — two exchanges, each re-read immediately before its write.
- Ticket-id guard: the supplied title carried PRDV-16595 while the supplied link pointed at the epic PRDV-16423. Resolved from the original-ticket artifact (authoritative), which gives the PRDV-16595 URL; card written with that. No ambiguity about which ticket the card is for — the template was blank, so there was no competing id to confuse.
- Marked **1 row**: Preliminary → "Generated ticket for the work to be done" (evidence: `PRDV-16595-original-ticket.md` on disk).
- **Left unmarked, everything else.** Deploy & PR → Pre-Push → "Run `npm audit`": audits were run and are clean, but that row belongs to pre-push of implemented work. Investigation → "Investigation Report": the state artifact is analysis, not that report.
- Set `currentStep` and `nextUp`; left `waitingOn` empty (nothing blocks this story — the GitHub Packages PAT gap from the epic session affects nova-orbital only). Status left `Unrefined`: no Investigation Report emitted, so the `In Progress` transition does not apply. `workAhead` left untouched — user's field.

#### Shipping checklist

- **Tests run** — not relevant: read-only analysis. No production code, config, or test file modified in `callisto-back-end`; `git status --porcelain` empty at `main` `56eead71`. The `npm audit` runs this session were measurements for the ticket, not commit gates.
- **Tests added/updated** — not relevant: no behavior changed.
- **Regression impact** — isolated: the only writes were to `dustin-thomason/docs/` and the WorkLists card. `callisto-back-end` verified untouched.
- **API docs** — not relevant: no HTTP surface read or modified. No route, DTO, or decorator touched.
- **Tooling gates** — not applicable: `dustin-thomason` has no root `package.json`, so audit/lint/test gates do not exist for the changed files (docs only).
- **Conflicts / exceptions** — none. The card's ticket-id guard resolved cleanly from the source artifact rather than by inference; recorded above.
