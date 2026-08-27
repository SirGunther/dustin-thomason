# Pathfinder update runbook — PRDV-16595

Source: Derrick Dieso sync-up, captured in [PRDV-16595-derrick-sync-up.md](./PRDV-16595-derrick-sync-up.md). Steps below follow his described process; his wording is quoted where it is a rule rather than a preference.

---

## Three things settled up front

**No separate ticket.** Derrick: *"we don't want to open up a new ticket for this because the effort to fix the dependencies in Calisto needs the the effort for the Pathfinder observability package."* Package problems surface *through* the services that use them, so the fix rides the service ticket. This is why PRDV-16595 is a three-pointer — *"that's why this guy's a three-pointer for these kinds of nested things."*

**Developers publish, not DevOps.** *"for our packages that we maintain, we developers actually publish it. So Carl doesn't need to know anything going on there."* No DevOps hand-off, no release-tag coordination for this.

**Why Pathfinder at all.** Multiple services consume it — Callisto and Triton confirmed, possibly Dione and others. *"So it's a problem for us, but it's also a problem for [the] Dione team."* Fixing it once fixes every consumer.

---

## ⚠️ Two corrections to work already done

**1. The existing branch was built the wrong way.** `PRDV-16595-otel-bump` in `pathfinder-observability-pkg` was produced with `npm install --package-lock-only`. Derrick's process requires deleting `package-lock.json` and `node_modules` first:

> *"Make sure to delete the package lock JSON before you do that, because if you update the package JSON, but you don't update the package lock and you do the npm install, things can sometimes get misaligned, and we'll catch that in the quality report here."*

**Redo it per Step 2 below.** The dependency versions chosen are still correct — `auto-instrumentations-node ^0.79.0`, `sdk-node ^0.221.0`, `exporter-trace-otlp-http ^0.221.0`, and the `js-yaml` override floor — and those were verified green (audit 0, build 0, lint 0, tests 0, `propagator-jaeger` resolving to `2.10.0`). It is the lockfile *generation method* that needs correcting, not the versions.

**2. This process requires a PR.** Derrick: *"you'll make a PR, and like any other PR, you'll send it to the PR channel to be reviewed."* The Pathfinder change cannot be published without being merged to `main` first, and it cannot be merged without a PR. This conflicts with the standing "no PRs" instruction — **flagging rather than deciding.** Nothing below gets executed without a go.

---

## The sequence

### Step 1 — Get the repo

```bash
cd ~
gh repo clone planetdepos/pathfinder-observability-pkg
cd pathfinder-observability-pkg
git checkout -b PRDV-16595-otel-bump
```

Access is already confirmed: `push: true`, `triage: true` (`admin: false`, `maintain: false`).

### Step 2 — Edit, then rebuild the lockfile from scratch

Edit `package.json`. Either remove an override outright, or uptick the offending package to its latest published version — *"see what the most up-to-date version of dependency cruiser is published on npm, and then uptick that."*

For Pathfinder specifically, the four changes are:

```
@opentelemetry/auto-instrumentations-node   ^0.77.0   ->  ^0.79.0
@opentelemetry/sdk-node                     ^0.219.0  ->  ^0.221.0
@opentelemetry/exporter-trace-otlp-http     ^0.219.0  ->  ^0.221.0
overrides.js-yaml                           ^4.2.0    ->  ^5.2.3
```

Then — **this ordering is the part that matters**:

```bash
rm -rf node_modules
rm package-lock.json
npm install
npm audit
```

> *"delete my node packages or or my node modules delete my package lock and then run npm install and then after npm install I would run npm audit"*

If a package still reports high severity after upticking, **put the override back and move on** — *"whoever updates Dependency Cruiser... they may or may not have fixed the thing that we are trying to avoid."*

### Step 3 — Bump the package version, then rebuild the lockfile *again*

`0.2.13` → **`0.2.14`**. Minor change, so the patch digit.

> *"you can do your iterations, and then if it's working, delete package lock again, uptick this version, and then npm install."*

So the final pass is:

```bash
# after edits are settled and audit is clean
rm package-lock.json
# bump "version": "0.2.13" -> "0.2.14" in package.json
npm install
```

The version must land in `package.json` **before** the final lockfile is generated, so the two agree. The publish workflow also enforces this — it refuses to republish an existing version and requires the new one to be strictly greater than the registry's latest.

### Step 4 — PR

Push the branch and open a PR. Post it in the PR channel, and say why it exists:

> *"hey, in order to enable work for 16595, I needed to update Pathfinder. Here's a PR for that... It's not closing out this ticket, but it's necessary to get this ticket going because you have to have this updated first."*

Wait for approval, then merge to `main`.

### Step 5 — Create the tag (GitHub Actions)

Tag and publish used to be one workflow; **they are now separate** — *"these used to be combined, but they are now separated."*

1. GitHub → the `pathfinder-observability-pkg` repo → **Actions** tab
2. Select the **semver tag** workflow (`semver-tag-commit.yml`)
3. **Run workflow**, from `main`
4. Enter the version you set in `package.json`: **`0.2.14`**

Use the semver number, **not** a date-style release tag:

> *"you'll create the tag with that number, not like 2024, you know, 2026... whatever 17.1 or whatever."*

### Step 6 — Publish to npm

1. Actions → **Publish to npm (GitHub Packages)** (`pkg-publish-npm.yml`)
2. **Run workflow**
3. `tag` input: **`0.2.14`** — the tag you just created
4. `dry_run`: set **`true`** first. It builds and packs without publishing — a free rehearsal
5. If the dry run succeeds, run it again with `dry_run` **`false`** to publish for real

The workflow checks out the tag, verifies the ref really is a tag, runs `npm ci` and `npm run build`, confirms the version beats the registry's latest, then publishes.

**Publishing is safe.** Existing versions stay available:

> *"it'll publish the version, but all the other published versions are still hosted and available, so Triton in this case will still be able to access [0.2.13] because that'll still be there."*

### Step 7 — Back to Callisto

```bash
cd ~/callisto-back-end
# in package.json: @planetdepos/pathfinder-observability-pkg  ^0.2.13 -> ^0.2.14
rm -rf node_modules
rm package-lock.json
npm install
npm audit
```

Then **delete the `@planetdepos/pathfinder-observability-pkg` override block** from Callisto's `overrides` and re-run the audit. That is the point of the whole exercise — the six high-severity findings resolve at the source rather than being suppressed.

> *"you can then go back to Callisto and in Calisto uptick the version of Pathfinder... then do npm install, and that should resolve these issues."*

---

## Same process for every internal package

> *"that's same process for like receiver package, relay package, any package that we're leveraging in any of these services. It's the same same workflow."*

Relevant because `nova-orbital-back-end` consumes `@planetdepos/orbital-receiver-pkg` and `orbital-relay-pkg`, both of which reach the same vulnerable OpenTelemetry chain through Pathfinder. Publishing `0.2.14` may resolve those too — separate story, noted so it is not rediscovered later.

---

## Open items

| Item | Needs |
| --- | --- |
| The PR conflict | A go — Derrick's process requires a PR; standing instruction is none |
| Rebuild the branch per Step 2 | Nothing; can be done as soon as the above is cleared |
| Publish (Steps 5–6) | An explicit go — outward action on a package multiple services consume |
