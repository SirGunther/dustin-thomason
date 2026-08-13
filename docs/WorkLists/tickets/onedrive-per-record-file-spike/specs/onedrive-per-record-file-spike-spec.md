# W7 — OneDrive per-record file spike — Spec

| Field | Value |
| --- | --- |
| Project | WorkLists |
| Ticket slug | `onedrive-per-record-file-spike` |
| Body of work | W7 of [`003-agent-workflow-sync-work-breakdown.md`](../../../features/agent-workflow-sync/003-agent-workflow-sync-work-breakdown.md) |
| Governing decisions | [`001`](../../../features/agent-workflow-sync/001-agent-workflow-sync-decisions.md) → record-level data access (D0, the per-record-storage option) and the additive-only constraint |
| Serves job story | [04 — Nothing I typed disappears](../../agent-workflow-sync/stories/agent-workflow-sync-job-story-04-nothing-i-typed-disappears.md), storage half |
| Depends on | none |
| Deliverable | **A written finding, not code** |
| Date | 2026-08-12 |

## Read this first — where this sits in the sequence

Per-record storage (W10) is **deferred behind two predecessors**, not blocked. It needs `GET /data` to stop reading the whole database, and that replacement waits until the adjacent scoped-read path has proven itself in real use — *eventually, not immediately*. Order: prove record-level access → migrate the board's read → then reconsider storage.

So this spike **does not by itself advance anything**, and that is fine. Its value:

1. It produces the numbers that make the storage decision an evidence call rather than a caution call, whenever that decision comes up.
2. If the answer is a clear **no-go**, per-record files are off the table for good — worth knowing, because it means section-scoped writes are the permanent destination for the deferred write-amplification fix rather than a way station.
3. It is a few hours and produces numbers instead of speculation.

**Run it early, expect nothing from it immediately.** Do not sequence any body of work behind it.

## Problem → Requirement → Solution

**Problem.** D0's per-record option assumes ~2,731 small files can live in the OneDrive-synced `data/` tree. That assumption is untested, and there is direct evidence that file-lock contention already happens today: `atomicWrite` retries `EBUSY` / `EPERM` / `ENOENT` five times with a one-second delay (`dal.js:556`). That retry loop was written for a reason.

**Requirement.** A go / no-go answer with measured numbers, covering steady-state write behavior, sync latency, and cross-machine behavior — enough that the decision is made on evidence rather than caution.

**Solution.** A throwaway harness that writes and rewrites a per-record file set inside the real synced tree, instrumented for the failure modes that matter, run on both machines the host-scoped data files imply.

## What the existing evidence already tells us

Stated so the spike measures what is genuinely unknown rather than re-confirming what is known.

| Known | Source | Implication |
| --- | --- | --- |
| Lock contention on rename happens today | `atomicWrite`'s 5-retry loop on `EBUSY`/`EPERM`/`ENOENT` | The failure mode is real, not hypothetical |
| Temp files are already written outside the synced tree | `TEMP_DIR` = `os.tmpdir()/worklists-atomic-writes` | Temp churn does not hit OneDrive. Only the final rename target does |
| The data tree is inside OneDrive | `DATA_DIR` = `<repo>/data`, repo is under `OneDrive\SCRIPTS ALL SYSTEMS` | Every write is a synced write |
| The host-scoped files are **inert** | `data/todos-OfficeComputer1.json` and `data/boards-PDLP-D362HS3.json` are referenced by nothing — absent from `SECTIONS`, and no `os.hostname()` call exists in the app | There is no code-level multi-machine mechanism. Whether cross-machine measurements matter depends on whether *you* work from two machines — open decision 8 |
| Per-record writes touch *less* per operation | One small file vs. 12 large ones | The direction may be favorable in steady state; the risk is file count, not per-write cost |

**The genuinely open question is narrow:** does a directory of ~2,731 small files in a synced tree cause materially worse lock contention, sync latency, or cross-machine divergence than 12 large files?

## Method

### Setup

Run entirely in a **throwaway sibling directory** inside the synced tree — never against `data/`:

```text
WorkLists/
  data-spike/            gitignored, deleted after the spike
    todos/               2,731 generated files, one per real card, realistic sizes
```

Generate the file set from a copy of the real `todos.json` so record sizes match production rather than being uniformly tiny. **Read the real file; never write to it.**

### Measurements

| # | Measurement | How | Recorded |
| --- | --- | --- | --- |
| 1 | Initial sync of 2,731 new files | Create the set, watch OneDrive to completion | Wall-clock to fully synced; CPU/disk observations |
| 2 | Single-record write latency, steady state | Rewrite one file 100 times with the real `atomicWrite` | p50 / p95 / max; retry count per write |
| 3 | Retry frequency vs. baseline | Same 100 writes against a 12-file layout in the same tree | `EBUSY`/`EPERM`/`ENOENT` counts, both layouts |
| 4 | Burst write | Rewrite 40 files back-to-back, mimicking a phase batch | Total time; retries; any write that exhausted its 5 retries |
| 5 | Full-set read | Read all 2,731 files, parse each | Wall-clock vs. parsing one 925 KB file |
| 6 | Cross-machine convergence | Write on machine A, observe on machine B | Time to appear; any conflict copies created |
| 7 | Concurrent-machine collision | Write the same record on both machines within the sync window | Does OneDrive create a `-MachineName` conflict copy? Which content wins? |
| 8 | Antivirus interaction | Note whether on-access scanning correlates with retries | Qualitative |

**Measurement 7 is the decisive one.** OneDrive's conflict resolution for a same-file collision produces a duplicate file, which in a per-record layout means a phantom record the DAL would either ignore or load as a second card. That is a data-integrity failure mode with no equivalent in the 12-file layout — where the same collision damages one section file, visibly.

### Baseline comparison

Every measurement runs against **both** layouts in the same tree, same session. An absolute number for the per-record layout proves nothing without the 12-file number beside it — the existing layout already has retries, so the question is relative, not absolute.

## Go / no-go criteria

Stated in advance so the result is not interpreted to fit a preference.

| Criterion | Go | No-go |
| --- | --- | --- |
| Retry rate, steady-state single write | No worse than the 12-file baseline | Materially worse |
| Any write exhausting 5 retries | Zero across all runs | One or more |
| Burst of 40 writes | Completes with no exhausted retries | Any exhaustion |
| Full-set read | Within a small multiple of the single-file parse | Order-of-magnitude worse |
| **Cross-machine conflict copies** | **None produced** | **Any produced** |
| Initial sync | Completes without manual intervention | Requires intervention or stalls |

**Any single no-go closes per-record storage for good.** Deliberately asymmetric: the current layout works, so the bar for replacing it is that the replacement is not worse in any dimension that risks data.

## Deliverable

`docs/WorkLists/features/agent-workflow-sync/005-per-record-storage-spike-result.md`, containing:

1. **Verdict** — go or no-go, in the first line.
2. **The numbers** — every measurement above, both layouts, with the machine and OneDrive client version.
3. **What would change the verdict** — e.g. moving `data/` outside the synced tree, which is a different decision with its own cost.
4. **Recommendation for the deferred write-amplification fix** — if no-go, section-scoped writes are the permanent destination rather than a way station, and that should be said plainly so the deferral has an endpoint.

## Additive-only compliance

| Guarantee | How |
| --- | --- |
| No production code changes | The harness is a standalone script deleted afterward |
| No production data touched | Writes only into `data-spike/`; reads `data/todos.json` |
| No dependency added | Uses `node:fs`, `node:os`, and the existing `atomicWrite` logic, copied rather than imported so `dal.js` need not be modified for instrumentation |
| Nothing left behind | `data-spike/` removed; `.gitignore` entry removed |

**Copy `atomicWrite` rather than importing it.** Importing would tempt instrumenting the real function, which means editing `dal.js` for a throwaway measurement. A copy that is verified line-identical at the start of the spike is safer.

## Spec tests

N/A — this body of work produces a measurement, not behavior. Recorded explicitly rather than omitted: **tests not relevant — no shipped behavior.** The harness's own correctness is established by running it against the 12-file baseline first and confirming it reproduces the retry counts the real app already exhibits.

## Cross-cutting

- **Risk:** Low to the app, since nothing production is touched. The real risk is spending effort on a question whose answer cannot be acted on under the current constraint — mitigated by keeping it small and by the second value listed at the top (a no-go permanently closes R3).
- **Rollback:** Delete `data-spike/` and the harness.
- **Delivery order:** Any time. Blocks nothing.
- **API docs:** N/A — no HTTP surface.
- **Tooling gates:** `npm run lint` applies if the harness lands in the repo; prefer keeping it in the scratchpad so it does not.

## Open questions

1. **Is moving `data/` outside OneDrive on the table?** It would eliminate the entire question — no sync, no conflict copies, no `EBUSY` — at the cost of losing the cross-machine sync the host-scoped files suggest is being relied on. If the answer is yes, this spike is less interesting than a spec for that move.
2. **What are the host-scoped files actually for?** — **Half resolved by tracing.** `todos-OfficeComputer1.json` and `boards-PDLP-D362HS3.json` are referenced by **nothing** in the codebase: they are absent from `SECTIONS`, `sectionPath` only ever builds `data/<section>.json`, and there is no `os.hostname()` call anywhere in the app. They are inert files — manual copies or leftovers, not an active sync mechanism.

   **What this changes:** there is no code-level multi-machine mechanism, so measurements 6 and 7 are testing whether *the user* moves between machines, not whether the app does. Still worth measuring — OneDrive will happily sync the same tree to two machines regardless of whether the app knows — but the premise is weaker than assumed when this spike was scoped. **Remaining question for the user:** do you actually run WorkLists on more than one machine against this same synced folder? If not, drop measurements 6 and 7 and the spike shrinks by more than half.
