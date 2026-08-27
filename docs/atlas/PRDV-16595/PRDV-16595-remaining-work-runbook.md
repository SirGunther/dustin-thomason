# PRDV-16595 remaining work — runbook

Source: Derrick Dieso sync-up, captured in [PRDV-16595-derrick-sync-up.md](./PRDV-16595-derrick-sync-up.md). Companion to [PRDV-16595-pathfinder-update-runbook.md](./PRDV-16595-pathfinder-update-runbook.md).

Three overrides remain in Callisto. Each masks real findings, and each has a different route out.

| Override | Masks | Route |
| --- | --- | --- |
| `@planetdepos/pathfinder-observability-pkg` | 6 high | Publish Pathfinder `0.2.14` — [separate runbook](./PRDV-16595-pathfinder-update-runbook.md) |
| `tar` | **1 critical** + 4 high | Upgrade `sqlite3` to `6.x` — breaking, needs real app testing |
| `@nestjs/swagger` → `js-yaml` | 2 high | Uptick `@nestjs/swagger`, see if it resolves |

---

## The method Derrick described, for any override

This is the general loop. It applies to all three.

1. **Delete the override lines** from `package.json`.
2. **Uptick the parent package** to its latest published npm version — *"see what the most up-to-date version of dependency cruiser is published on npm, and then uptick that."*
3. **Delete `node_modules` and `package-lock.json`.** Not optional:
   > *"delete my node packages or or my node modules delete my package lock and then run npm install"*
4. `npm install`, then `npm audit`.
5. **If it still complains, put the override back and move on.** — *"we keep the sucker in place, right, and we move on to the next one."* The upstream maintainers may simply not have fixed it yet.

**Go one at a time.** Binary search works, but:
> *"It helps especially learning it to go one by one to just see, you know, okay, like I confirm dependency cruiser is happy. Now let me try this... package and so on."*

Derrick confirmed the five already removed were done correctly — *"it sounds like you did exactly... what was needed."*

---

## 1. `tar` — the critical, and the riskiest change

**Chain:** `sqlite3 5.1.7` → `node-gyp` → `make-fetch-happen` → `http-proxy-agent` → `@tootallnate/once` (critical).

**Derrick's direction:** try it.
> *"So if you update SQLite three, and then you update tar. Does that fix the issues? ... cool. So I would say go ahead and try that."*

### The part that must not be skipped

`sqlite3` 5.x → 6.x is a **major**. Derrick was explicit that a script through DBeaver is *not* sufficient verification:

> *"definitely testing it as the application runs is the move... we're updating SQLite three within Calisto, which is just the package that Calisto is using to communicate with [the database]. So it's not actually changing anything at the database level. It's changing like the drivers or... the different mechanisms with which Calisto communicates with the database, **which fully could break**. Like updating this, it might cause unforeseen issues with like how our databases are registered."*

### Required verification

Run both apps and exercise real flows:

- Start **Callisto** and **Atlas**
- **Upload a file**
- **Create a proceeding**
- **Modify some records**

> *"make those updates, then actually run Calisto, run Atlas, and see if you can upload a file, create a proceeding, modify some stuff."*

### Steps

```bash
cd ~/callisto-back-end
# package.json: sqlite3 ^5.1.7 -> ^6.x (latest published)
# remove the "tar" override
rm -rf node_modules
rm package-lock.json
npm install
npm audit
```

Then run the app checks above before considering it done. If the app breaks, the override goes back and the finding is recorded as accepted risk with an owner.

---

## 2. `@nestjs/swagger` → `js-yaml` — probably the easy one

Callisto pins `js-yaml ^5.2.3` under `@nestjs/swagger` because the version swagger resolves on its own sits in the vulnerable `4.0.0 – 4.3.0` range.

Derrick's read: *"Swagger isn't that big a deal... I can try it out and see what happens."*

```bash
cd ~/callisto-back-end
# package.json: uptick @nestjs/swagger ^11.2.3 -> latest published
# remove the "@nestjs/swagger" override block
rm -rf node_modules
rm package-lock.json
npm install
npm audit
```

If a newer `@nestjs/swagger` resolves a patched `js-yaml`, the override goes. If not, it stays and you move on.

**Check the Swagger docs still render** after the bump — it is the package that generates them.

---

## 3. `@planetdepos/pathfinder-observability-pkg` — 6 high

Covered fully in the [Pathfinder runbook](./PRDV-16595-pathfinder-update-runbook.md). Summary: publish `0.2.14`, uptick Callisto to it, delete the override.

**Do this one first if you want the biggest single reduction** — six of the nine masked highs.

---

## Suggested order

| # | Task | Why this position |
| --- | --- | --- |
| 1 | `@nestjs/swagger` | Cheapest, lowest risk, quick confidence |
| 2 | Pathfinder `0.2.14` | Biggest reduction; has an external dependency (PR + publish) so start the clock early |
| 3 | `sqlite3` → `tar` | Highest risk, needs manual app testing — do it when you can give it attention |

---

## Definition of done

Callisto's `overrides` block contains **only** what genuinely cannot be fixed upstream, and `npm audit --audit-level=high` exits `0` **without suppression doing the work**.

Any override that survives should be recorded as an accepted risk with a reason and an owner — not left silently in place. That is Larry's point: *"you can get away with override, but at some point we got to kind of stop, you know, kind of nip it."*

---

## Cadence — why this keeps coming back

> *"that's why we have these tasks as a monthly thing because... you can imagine this is one month of changes. Imagine like three months. Imagine trying to do this with like three months of breaking shit... It's kind of like getting your engine checked. Do it [on a] regular cadence before everything starts breaking."*

---

## Separate topic captured from the same conversation — PR review protocol

Not PRDV-16595 work; recorded here so it is not lost.

- **Take the oldest open PR that is ready.** Old PRs accumulate merge conflicts as `main` moves — Derrick had one sit two weeks and had to keep resolving conflicts.
- **Check the PR channel first**, before the repos. Emoji markers show what is claimed (👀) or approved (✅).
- **The author posts every repo a ticket touches** — you should not have to hunt for them.
- **Review all of a ticket's PRs together.** *"don't approve Callisto before approving Atlas. Like do it at the same time."* Merging one without the other breaks the other environment.
- **Cherry-picking away from very large PRs is fine** if you cannot confidently QA them — *"no judgment."*
