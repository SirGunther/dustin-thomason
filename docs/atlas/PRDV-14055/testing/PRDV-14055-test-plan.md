# Test plan — atlas/PRDV-14055 (single reference)

> **This is the one testing reference to hand to Codex.** It consolidates the automated coverage (done) and the manual/browser execution (to run) after the approved Callisto-only spec ([PRDV-14055-upload-manager-count-up.md](../specs/PRDV-14055-upload-manager-count-up.md)). Superseded standalone handoff moved to `dnu/`.
> **Branch under test:** `atlas-front-end` @ `PRDV-14055` (working tree; not yet committed). **Guardrails:** follow `browser-loop-guardrails` for the browser work — observe truth, don't guess selectors; escalate after ~3 non-converging attempts.
> **Status:** Automated coverage complete + green (43 tests). **Manual/browser runtime validation is the remaining work** — Part B below.

## Scope and surfaces

- **In scope (Callisto only):** the Upload Manager first number counts **up** (completed + in-progress) to the total; a failed upload (chunk failure, upload-complete failure incl. 0-byte, network loss) is marked terminal on the queue item, is **counted**, shows an error row + a **toast**, and lets the batch **resolve** instead of hanging.
- **Surfaces:** `uploadManagerStore.ts`, `UploadManager.vue`, `UploadManagerTitle.vue`, `useUploadItem.ts` (all under `src/callisto/`).
- **Must stay unchanged (neighbors):** `activeUploadsCount`, `hasActiveUploads` (close-confirm / beforeunload), `totalProgress` (bar math), `allUploadsComplete` logic, and the title success/error/failed branches.
- **Not in scope:** Triton (separate follow-up); automatic retry/resume/offline-detection (interruption fails gracefully, it does not retry).

---

# Part A — Automated coverage (DONE, green)

Unit/component suites, run serially. All passing — 43 across the three core suites below (32 store + 8 title + 3 upload-item); the 2026-07-21 log row shows 47 because that run also included the neighboring `ErrorUploadItem` suite.

| Ref | Behavior | Suite |
| --- | --- | --- |
| A-1 | Count computed: empty → 0; queued-at-0% not counted; in-progress + completed rises (monotonic); all-complete === `uploadQueue.length`; errored/cancelled-at-0% counted | `src/callisto/stores/__specs__/uploadManagerStore.spec.ts` |
| A-2 | Neighbors unchanged: `activeUploadsCount` / `hasActiveUploads` / `totalProgress` assertions still pass | `uploadManagerStore.spec.ts` |
| A-3 | Title renders the up-count in `active` with `total` = queue length; success/error/failed branches unchanged | `src/callisto/components/FileUploadWrapper/UploadManager/__specs__/UploadManagerTitle.spec.ts` |
| A-4 | Failure handling: chunk failure and upload-complete failure (incl. 0-byte / 0-part) set queue-visible `error`, fire a file-named failure toast (`multiple: false`), and permit terminal batch resolution; success sets `isComplete` with no `error`/toast | `src/callisto/components/FileUploadWrapper/UploadManager/UploadItem/composables/__specs__/useUploadItem.spec.ts` |

**Gates:** `audit` — blocked by 93 pre-existing dependency vulns (no deps changed by this ticket); `lint` — pass; `tests` — see the command in the Results log. Automated results are recorded below and do **not** need re-running unless code changes.

---

# Part B — Manual / browser execution (Codex to run)

The runtime behavior unit tests can't prove: the count **visibly** rising, the failure toast/error row in the real UI, and the **offline mid-batch** interruption resolving instead of hanging.

## B.0 — Prerequisites YOU (the human) prepare first

Codex cannot create accounts, grant permissions, or log in. Have ready:

1. **App running against a real backend.** From `atlas-front-end`: `npm run dev:tst` (or `dev:sb` / `dev:dev`). Note the URL it prints (Quasar default `http://localhost:9000`). Full-local option: `docs/atlas/local/full-stack-local-setup.md` + `callisto-local-quickstart.md`.
2. **An Ops user with upload (RAL) permission** and the **URL of a page with the upload surface** (Job Proceeding / Job Submission / Case Detail). Without RAL the upload control is disabled (PRDV-14855).
3. **Logged-in Chrome on the CDP port** (Playwright attaches to this — a fresh Playwright browser is logged out). Launch (B.1 #2) and **log in once** in that window.
4. **Test fixtures generated** (B.1 #1).
5. Confirm the file types are **supported extensions** (fixtures use `.pdf`); if the backend rejects zero-filled content on the *happy* path, use a few real sample files for B-1/B-2 (the failure/0-byte/offline runs don't need valid content).

## B.1 — PowerShell commands

**1. Generate fixtures**
```powershell
$dir = "$env:TEMP\prdv-14055-fixtures"
New-Item -ItemType Directory -Force $dir | Out-Null
if (-not (Test-Path "$dir\zero-byte.pdf")) { New-Item -ItemType File "$dir\zero-byte.pdf" | Out-Null }   # 0-byte (B-6)
1..6  | ForEach-Object { fsutil file createnew "$dir\happy-$_.pdf" 1048576  | Out-Null }                   # happy batch (B-1/B-2)
1..20 | ForEach-Object { fsutil file createnew "$dir\big-$_.pdf"   10485760 | Out-Null }                   # offline batch (B-5)
Write-Host "Fixtures in $dir"
```

**2. Launch authenticated Chrome for Playwright to attach to**
```powershell
Start-Process chrome.exe -ArgumentList `
  '--remote-debugging-port=9222', `
  '--user-data-dir=C:\temp\prdv-14055-cdp-profile', `
  'http://localhost:9000'   # use the URL your dev server printed; then log in as the Ops user once
```

**3. Drive the offline scenario with Playwright (attaches over CDP)** — save as `scripts/browser/prdv-14055-offline.mjs`, set the two selectors from the live page, then:
```powershell
node scripts/browser/prdv-14055-offline.mjs --cdp http://localhost:9222 --fixtures "$env:TEMP\prdv-14055-fixtures"
```
```js
// prdv-14055-offline.mjs  (scaffold — set UPLOAD_INPUT and TITLE from the live page)
import { chromium } from 'playwright';
import fs from 'node:fs';
import path from 'node:path';
const cdp = process.argv[process.argv.indexOf('--cdp') + 1];
const fixtures = process.argv[process.argv.indexOf('--fixtures') + 1];
const UPLOAD_INPUT = 'input[type=file]';   // <- confirm on the page
const TITLE = '.text-h6';                   // <- the "Uploading N of M" element
const browser = await chromium.connectOverCDP(cdp);
const ctx = browser.contexts()[0];
const page = ctx.pages()[0] ?? (await ctx.newPage());
const files = fs.readdirSync(fixtures).filter(f => f.startsWith('big-')).map(f => path.join(fixtures, f));
await page.setInputFiles(UPLOAD_INPUT, files);
await page.waitForTimeout(1500);
await ctx.setOffline(true);                 // fallback: raw CDP Network.emulateNetworkConditions({offline:true,...})
console.log('NETWORK OFFLINE at', new Date().toISOString());
for (let i = 0; i < 30; i++) {
  const t = await page.locator(TITLE).first().innerText().catch(() => '(gone)');
  console.log(i, t);
  if (/uploaded successfully|completed with errors|failed/i.test(t)) { console.log('RESOLVED'); break; }
  await page.waitForTimeout(1000);
}
await ctx.setOffline(false);
await browser.close();
```

## B.2 — Scenarios (steps → expected)

| Ref | AC | Steps | Expected |
| --- | --- | --- | --- |
| B-1 | 1,2 | Drop the 6 `happy-*.pdf` | "Uploading N of M": N climbs (2→…→6), M stays 6, bar fills, then "All files uploaded successfully" + countdown. Capture 3 screenshots showing N rising. |
| B-2 | 2 | (during B-1) | Second number M is constant = file count. |
| B-3 | 4 | Drop `zero-byte.pdf` alone | It errors → error row (ErrorUploadItem) + `"zero-byte.pdf failed to upload"` toast; batch reaches a terminal title (no hang). |
| B-4 | 3 | Drop a few `happy-*.pdf` + `zero-byte.pdf` | Good ones complete, bad one shows error row + toast, N never drops, title ends "completed with errors". |
| B-5 | 5 | Run the B.1 #3 script with the 20 `big-*.pdf` | After offline: in-flight files fail, N still climbs to 20, title **resolves** to a terminal state within a few seconds — must **not** stay on "Uploading N of M". Note whether failure toasts dedupe (`multiple: false`). |
| B-6 | 3,4 | (covered by B-3) | 0-byte counted + error row + toast. |
| B-7 | 6 | Start a batch, click the manager's close/X mid-upload | The "Are you sure?" cancel-confirm dialog still appears (neighbor unchanged). |

## B.3 — Evidence to capture

Screenshots: count rising (B-1), error row + toast (B-3/B-4), and the **final resolved title** for the offline run (B-5); plus the offline script's stdout (title-over-time samples). Record each into the Results log below; mark any failure with repro details, or **blocked + reason** if a scenario can't run (env/permission/data).

---

## Results log

| Date | Gate/Scenario | Command | Scope | Result | Exception / risk |
| --- | --- | --- | --- | --- | --- |
| 2026-07-21 | audit | `npm audit --audit-level=high` | `atlas-front-end` dependency tree | blocked: 93 existing vulns (90 high) | No fix available for affected paths; ticket changes no dependencies. |
| 2026-07-21 | lint | `npm run lint` | full `atlas-front-end` lint scope | pass | — |
| 2026-07-21 | tests (A-1..A-4) | `npx vitest run --maxWorkers 1 src/callisto/stores/__specs__/uploadManagerStore.spec.ts src/callisto/components/FileUploadWrapper/UploadManager/__specs__ src/callisto/components/FileUploadWrapper/UploadManager/UploadItem/composables/__specs__/useUploadItem.spec.ts` | store, title, error row, upload-item failure | pass: 4 files, 47 tests | Browser runtime (Part B) still pending. |
| 2026-07-22 | lint | `npm run lint` | full `atlas-front-end` lint scope | pass | Toast-dedup follow-up. |
| 2026-07-22 | tests (A-4) | `npx vitest run --maxWorkers 1 src/callisto/components/FileUploadWrapper/UploadManager/UploadItem/composables/__specs__/useUploadItem.spec.ts` | upload-item terminal failure notifications | pass: 1 file, 3 tests | File-named toast with `multiple: false`. |
| _pending_ | B-1 count rises | manual (browser) | happy 6-file batch | | |
| _pending_ | B-3 0-byte fails visibly | manual (browser) | zero-byte.pdf | | |
| _pending_ | B-4 mixed no-drop | manual (browser) | happy + zero-byte | | |
| _pending_ | B-5 offline resolves | `node scripts/browser/prdv-14055-offline.mjs …` | 20×10MB, network cut | | |
| _pending_ | B-7 cancel dialog | manual (browser) | close mid-batch | | |

## Definition of done

Part A green (done). Every Part B scenario (B-1…B-7) observed and recorded with evidence; the offline run demonstrably resolves (no hang); any scenario not run is logged **blocked + reason**, not silently skipped.
