# PRDV-16423 — Baseline vulnerability audit (clean-slate sweep)

**Run:** 2026-08-25T05:40Z · all four repos on `main`, fetched + fast-forwarded, working trees clean.
**Method:** `npm audit --json` (full tree, dev included) at repo root, then `npm audit fix --package-lock-only` to measure what a non-breaking fix resolves. **All lockfile changes were reverted** — repos are back at pristine `main`.

## The gate we have to satisfy

The deploy blocker is not ECR image scanning. It is a plain npm audit step inside the shared reusable workflow:

- `planetdepos/actions/.github/workflows/node-service-ci.yml@main` (Managed by DevOps, version `2026-04-02.1`)
- Step **Audit**: `npm audit --audit-level=high`
- Runs after `npm install` (not `npm ci`), Node 24, **dev dependencies included**

Each repo's `node-build-auto-ecr.yml` calls that workflow, and `build-and-push` (the ECR push) is gated on it via `needs: [setup, build]`. A non-zero audit exit fails the build before any image is published — which matches the ticket's "preventing deployment to AWS through the standard process".

**Consequence for scoping:** dev-only vulnerabilities count. `--omit=dev` numbers are not the target.

## Baseline by repo

| Repo | HEAD | High | Crit | Mod | Low | `npm audit fix` (no `--force`) result |
| --- | --- | --- | --- | --- | --- | --- |
| `nova-back-end` | `e5f071a` | 2 | 0 | 0 | 0 | **→ 0 total.** Lockfile only, `package.json` untouched |
| `europa-back-end` | `34da474` | 7 | 0 | 5 | 2 | **→ 0 total.** Lockfile only, `package.json` untouched |
| `callisto-back-end` | `56eead71` | **0** | **0** | 2 | 5 | Already passes the gate. Residual low/mod needs `--force` |
| `nova-orbital-back-end` | `5326247` | 9 | 0 | 2 | 1 | **Could not run** — npm E401 against GitHub Packages |

## nova-back-end — 2 high, both trivial

| Package | Direct | Advisory |
| --- | --- | --- |
| `brace-expansion` 4.0.0–5.0.8 | no | GHSA-rgw5-rvv9-x895 — DoS via unbounded intermediate arrays |
| `js-yaml` 4.0.0–4.3.0 | no | GHSA-5p4m-2wfm-xmqj — quadratic CPU in `!!omap` resolution |

Both transitive, both semver-compatible. `npm audit fix` clears the repo to 0 with a 93-insert / 36-delete lockfile diff and no manifest change.

## europa-back-end — 7 high, all resolve in range

| Package | Direct | Notes |
| --- | --- | --- |
| `axios` 1.0.0–1.17.0 | **yes** | Large advisory cluster — ReDoS via cookie-name injection, proxy-auth credential leak on HTTP→HTTPS redirect, prototype-pollution MITM gadget in `config.proxy`, NO_PROXY bypass |
| `@nestjs/platform-express` ≤11.1.27 | **yes** | Vulnerable only via its `multer` dependency |
| `multer` 1.0.0–2.1.1 | no | GHSA-72gw-mp4g-v24j — DoS via deeply nested field names |
| `form-data` 4.0.0–4.0.5 | no | GHSA-hmw2-7cc7-3qxx — CRLF injection via unescaped multipart field names |
| `fast-uri` 3.0.0–3.1.4 | no | Three host-confusion advisories — backslash authority delimiter, IDN canonicalization |
| `brace-expansion` | no | Same cluster as Nova, plus the `<=1.1.17` and `2.0.0–2.1.3` branches |
| `js-yaml` | no | Merge-key + `!!omap` quadratic CPU; reaches `@nestjs/swagger` |

Despite `axios` and `@nestjs/platform-express` being **direct** dependencies, every fix lands inside the existing `package.json` ranges — `npm audit fix` took the repo to **0 total** with a lockfile-only diff (381 insertions / 235 deletions, ~1005 packages re-resolved).

The wide diff is the risk here, not the fix strategy: `axios` and the Nest platform layer sit on hot paths (HTTP clients, multipart upload handling), so this one needs the full test suite and a sandbox deploy, not just a green audit.

## callisto-back-end — already clean at the gate level

Zero high, zero critical. The remaining 7 findings are 5 low + 2 moderate, all from `aws-sdk` → bundled `uuid`. npm's only offer is `npm audit fix --force`, which installs **`aws-sdk@1.18.0`** — a downgrade-shaped major far more disruptive than the finding warrants.

`--audit-level=high` does not fail on these, so Callisto is **not currently blocking deployment**. The ticket's "1-Callisto (3)" almost certainly counts child stories, not vulnerabilities — worth confirming against the ClickUp subtasks before assuming Callisto work exists.

## nova-orbital-back-end — the only real engineering

Nine high findings, collapsing into two groups.

**Group 1 — routine transitives (3), same class as Nova/Europa:** `brace-expansion`, `fast-uri`, `js-yaml`. All `fixAvailable: true`.

**Group 2 — one root cause wearing six hats:**

```
@planetdepos/orbital-receiver-pkg  1.1.3   (direct)
@planetdepos/orbital-relay-pkg     1.0.2   (direct)
        └── @planetdepos/pathfinder-observability-pkg ^0.2.13  (direct)
                └── @opentelemetry/sdk-node  <=0.219.0
                        └── @opentelemetry/propagator-jaeger  <2.9.0
                                └── GHSA-45rx-2jwx-cxfr — DoS via unhandled
                                    exception on a malformed Jaeger header
```

npm reports `fixAvailable: false` for all six, which reads as "blocked on upstream". It is not:

- `@opentelemetry/propagator-jaeger@2.9.0` and `2.10.0` are published and patched.
- `@opentelemetry/sdk-node@0.221.0` (latest) already depends on `propagator-jaeger@2.10.0`.
- The repo **already uses `overrides`** for exactly this purpose — `package.json` carries `{"js-yaml":"^4.2.0","multer":"^2.2.0"}`.

So the remedy is an in-house pattern already established in this file, not a cross-team upstream ask. Two options, in preference order:

1. Bump `@planetdepos/pathfinder-observability-pkg` if a release exists that pulls `sdk-node >= 0.220` — cleanest; keeps the internal package authoritative.
2. Add an `overrides` entry pinning `@opentelemetry/sdk-node` (or `propagator-jaeger` directly) — matches existing precedent, but hides the internal package's stale floor rather than fixing it.

**Option 1 could not be evaluated.** See the blocker below.

## Blocker — local GitHub Packages auth is dead

Every `@planetdepos`-scoped resolution fails locally, so `npm audit fix` and `npm view` are both unusable on `nova-orbital-back-end`:

| Token source | Result |
| --- | --- |
| `~/.npmrc` `_authToken` | **401** — "unauthenticated: User cannot be authenticated with the token provided" (expired or revoked) |
| `gh auth token` | **403** — "The token provided does not match expected scopes" (missing `read:packages`) |

The repo's `.npmrc` reads `//npm.pkg.github.com/:_authToken=${GITHUB_TOKEN}`, and that repo-level line wins over the user-level token, so an unset `GITHUB_TOKEN` resolves to empty regardless of what `~/.npmrc` holds.

**Unblock:** mint a GitHub PAT with `read:packages`, then either refresh `~/.npmrc` or export it as `GITHUB_TOKEN`. Until then no dependency work on `nova-orbital-back-end` is possible locally. CI is unaffected — it injects `secrets.GITHUB_TOKEN`.

## Scope question to settle before estimating

The ticket names three systems — Nova, Callisto, Europa — but **Nova is two repos**: `nova-back-end` (`nova-video-transcoder`) and `nova-orbital-back-end`. That distinction decides the size of this ticket, because the trivial repo and the only non-trivial repo are both "Nova":

- If Nova means `nova-back-end` only → this ticket is two lockfile commits and Callisto is already done.
- If Nova includes `nova-orbital-back-end` → there is one genuine piece of engineering, on the OTel/observability chain.

The ClickUp subtasks ("2-Nova (2)", "1-Callisto (3)", "3-Europa (2)") should name their repos. Confirm there before pointing.

## Standing caveat

The advisory database moves. A repo that exits 0 today can fail the same unchanged gate next week — `brace-expansion` and `js-yaml` in this sweep are both *repeat* advisories against ranges that were already patched once. Whatever ships here should be framed as clearing the current backlog, not as making the gate permanently green. A scheduled audit, or Renovate/Dependabot on these four repos, is the durable answer and is worth raising as a follow-up story on the epic.
