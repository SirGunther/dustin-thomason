# PRDV-16595 — Callisto remediation state (the pattern already exists)

**Run:** 2026-08-25T14:05Z · `callisto-back-end` @ `main` `56eead71`, clean tree.
**Parent epic:** PRDV-16423 · **Sequenced:** 1st of 3 · **Points:** 3

## Headline

Callisto **already satisfies both acceptance criteria.** `npm audit` at the gate level reports **0 high, 0 critical**. The `overrides` block pasted into the ticket body is not a proposal — it is the block already committed to `callisto-back-end/package.json` on `main`, verbatim, character for character.

The consequence is that this story is not remediation work. It is **ratification**: confirming the block holds, and establishing it as the canonical pattern the other two stories consume. That is why it is sequenced first, and why it carries 3 points despite zero outstanding vulnerabilities.

## The block, and what each entry buys

```json
"overrides": {
  "@planetdepos/pathfinder-observability-pkg": {
    "@nestjs/common": "$@nestjs/common",
    "@opentelemetry/sdk-node": "^0.221.0",
    "@opentelemetry/auto-instrumentations-node": "^0.79.0",
    "@opentelemetry/propagator-jaeger": "^2.10.0"
  },
  "dependency-cruiser":    { "picomatch": "^4.0.4" },
  "@angular-devkit/core":  { "picomatch": "^4.0.4" },
  "fdir":                  { "picomatch": "^4.0.4" },
  "minimatch@10":          { "brace-expansion": "^5.0.9" },
  "@nestjs/swagger":       { "js-yaml": "^5.2.3" },
  "tar":    ">=7.5.7",
  "multer": "^2.2.0"
}
```

Every pinned version was verified to exist on the public registry: `js-yaml@5.2.3`, `@opentelemetry/auto-instrumentations-node@0.79.0`, `@opentelemetry/sdk-node@0.221.0`, `@opentelemetry/propagator-jaeger@2.10.0`, `picomatch@4.0.4`, `brace-expansion@5.0.9`, `tar@7.5.7`, `multer@2.2.0`. Nothing in the block is aspirational.

Two properties of the block are worth naming, because they are the reusable part:

**It uses scoped overrides, not flat ones.** `{"@nestjs/swagger": {"js-yaml": "^5.2.3"}}` forces the version only where that parent resolves it, leaving every other `js-yaml` consumer alone. A flat `{"js-yaml": "^5.2.3"}` forces it tree-wide. The other three repos in the epic use flat overrides, which is the more brittle form.

**It crosses a major version where necessary.** `js-yaml` is pinned to `^5.2.3` — the 5.x line, latest `5.4.0`. The 4.x line is vulnerable through `4.3.0`, so staying inside `^4.x` means tracking a moving floor with no margin. Callisto's team went to the next major instead and it deploys.

## Provenance — this was built incrementally, under other tickets

Callisto's block was not written for PRDV-16595. `git log -S` on `package.json` shows it accumulating across at least six unrelated tickets:

| Commit | Ticket |
| --- | --- |
| `95636c44` | PRDV-14641: Update to pathfinder package |
| `14c2f3ad` | PRDV-14641: Fix audit |
| `a8761489` | **PRDV-14699: Resolve npm audit via OpenTelemetry overrides** |
| `0338a2ab` | PRDV-16288: reduce weight of queries 1 |
| `f75dd4e0` | **PRDV-15850: Fixed high level vulnerabilities** |
| `997c45da` | PRDV-15850: Fixed npm vulnerability |
| `954f4adb` | PRDV-16391: npm audit fix |
| `45f5116e` | PRDV-16081: npm audit fix |

So the Callisto remediation was paid for in pieces by whoever happened to be blocked at the time. PRDV-16595 is the first ticket to look at the result deliberately.

## The finding that reframes the whole epic

All four repos in PRDV-16423 already maintain an `overrides` block. Callisto's is complete. The other three are **partial or stale copies of the same effort** — and each repo's audit failures correspond exactly to what its block is missing.

| Override | `callisto` (0 high) | `nova-back-end` (2 high) | `nova-orbital` (9 high) | `europa` (7 high) |
| --- | --- | --- | --- | --- |
| `brace-expansion` | `minimatch@10` → `^5.0.9` ✅ | `^5.0.8` flat — **stale, flagged** | absent — **flagged** | absent — **flagged** |
| `js-yaml` | `@nestjs/swagger` → `^5.2.3` ✅ | `^4.2.0` flat — **stale, flagged** | `^4.2.0` — **stale, flagged** | absent — **flagged** |
| OTel chain | scoped under pathfinder ✅ | `propagator-jaeger ^2.9.0` + `core ^2.8.0` — current, **not flagged** | absent — **6 findings** | n/a |
| `multer` | `^2.2.0` ✅ | n/a | `^2.2.0` — current, **not flagged** | absent — **flagged** |
| `picomatch` | 3 scoped ✅ | absent | absent | 3 scoped — **not flagged** |
| `tar` | `>=7.5.7` ✅ | absent | absent | `>=7.5.7` — **not flagged** |
| `fast-uri` | not needed | not needed | absent — **flagged** | absent — **flagged** |

Read the table either direction and it holds. Where a repo has a current override, that package is absent from its audit. Where the override is stale or missing, the package is flagged. Nova-back-end's OTel overrides are current, and nova-back-end reports **zero** OTel findings while nova-orbital reports six — same internal `pathfinder-observability-pkg` dependency, opposite outcome, explained entirely by whether the override is present.

**The epic is not four independent dependency problems. It is one overrides block, developed in Callisto, never propagated — plus floor drift where it was partially copied.**

## What this story should actually deliver

1. **Confirm the AC.** `npm audit --audit-level=high` exits 0 on `main`. Done — verified this session.
2. **Ratify the block** as Callisto's remediation and record the *technique* for the epic — scope overrides narrowly, cross a major version when the floor has no margin. Per the measurement below, do **not** publish the block itself as a drop-in for the other repos; it does not port.
3. **Record the accepted residual.** Callisto still carries 5 low + 2 moderate, all `aws-sdk` → bundled `uuid`. npm's only offer is `--force` installing `aws-sdk@1.18.0`, a downgrade-shaped major. Out of AC scope (`high`/`critical` only) and not gate-blocking. Accept and document; do not fix.
4. **Name the maintenance defect.** A hand-maintained floor silently drifts back inside new advisory ranges — nova-back-end's `brace-expansion: ^5.0.8` against a patched `5.0.9` is the live example, and its `js-yaml: ^4.2.0` is the second. This block will need re-verification every time the advisory DB moves. That is a follow-up story on the epic (Renovate/Dependabot), not work for PRDV-16595.

## Measured: the block does NOT port. Tested, 2026-08-25T14:20Z

The obvious inference from the matrix above — "propagate Callisto's block to the other repos" — was tested on `europa-back-end` and **is wrong**. Both runs were lockfile-only and reverted; Europa has no `@planetdepos` dependencies, so the GitHub Packages auth gap did not interfere.

| Approach on Europa | 7 high becomes | `package.json` |
| --- | --- | --- |
| Port Callisto's applicable entries (`minimatch@10`→`brace-expansion`, `@nestjs/swagger`→`js-yaml`, `multer`) | **5 high** | modified |
| Plain `npm audit fix` | **0** | untouched |

**Why porting underperforms — and it is the same property that makes Callisto's block good.** Callisto uses *scoped* overrides, which pin a version only under a named parent. That precision is a statement about **one repo's dependency tree shape**, and Europa's shape differs:

- `brace-expansion` stayed flagged despite `minimatch@10` → `^5.0.9`, because Europa reaches it through `@eslint/config-array`, `@eslint/eslintrc`, `@jest/reporters`, `eslint`, and root — not through `minimatch@10`.
- `js-yaml` stayed flagged despite `@nestjs/swagger` → `^5.2.3`, because Europa also reaches it via `@istanbuljs/load-nyc-config` and root, outside the scoped parent.
- Only `multer` cleared, which also cleared `@nestjs/platform-express` (its finding was purely via multer).
- `axios`, `form-data` and `fast-uri` have no entry in Callisto's block at all — 3 of Europa's 7 were never addressable this way.

**A scoped override is not a portable artifact.** It is tuned to the tree it was written against. The transferable thing is the *technique* (scope narrowly, cross a major when the floor has no margin), not the JSON.

### Corrected per-repo direction

| Repo | Remedy | Verified? |
| --- | --- | --- |
| `callisto-back-end` | none — already at 0 high | ✅ measured |
| `nova-back-end` | plain `npm audit fix`, lockfile-only | ✅ measured → 0 |
| `europa-back-end` | plain `npm audit fix`, lockfile-only. **Do not port the block** | ✅ measured → 0 |
| `nova-orbital-back-end` | override needed — `audit fix` cannot help (its 6 OTel findings are `fixAvailable: false`) | ❌ **not verified — auth blocked** |

Nova-orbital is the one place Callisto's block is a genuine candidate, and for a specific reason: it declares the **identical** parent, `@planetdepos/pathfinder-observability-pkg@^0.2.13`, same as Callisto. Same parent, same version range, same child chain — the one case where the tree shape matches and a scoped override should transfer. That is reasoning, not a measurement: it **could not be tested**, because every `@planetdepos` resolution fails locally (`~/.npmrc` token 401, `gh` token missing `read:packages`). Treat it as the leading candidate to verify first, not as a confirmed fix.

## Correction to the epic-level triage

The PRDV-16423 baseline artifact recommended deriving nova-orbital's OTel fix from scratch and raising its `js-yaml` floor to `^4.3.1`. The `^4.3.1` advice is superseded — Callisto's proven pin is `^5.2.3` on the 5.x line (latest `5.4.0`), and a 4.x floor tracks a range vulnerable through `4.3.0` with no margin. The from-scratch derivation is *partly* superseded: Callisto's scoped pathfinder entry is the candidate to try first, but per the measurement above a ported block is not automatically a working block, and nova-orbital's remains unverified.
