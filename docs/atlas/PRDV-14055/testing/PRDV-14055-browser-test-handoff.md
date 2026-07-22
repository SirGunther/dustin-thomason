# PRDV-14055 — Browser test handoff (for Codex)

> **Purpose:** execute the *runtime* validation that unit tests can't prove — that the Upload Manager count **visibly counts up**, that failures show a toast + error row, and that an **offline mid-batch** interruption resolves instead of hanging. Companion to [PRDV-14055-test-plan.md](./PRDV-14055-test-plan.md) (unit coverage already green: 47 tests). Record results back into that plan's Results log.
> **Branch under test:** `atlas-front-end` @ `PRDV-14055` (working tree; changes not yet committed).
> **Guardrails:** follow `browser-loop-guardrails` the whole time — observe truth, don't guess selectors; **escalate after ~3 non-converging attempts** with a structured account instead of continuing to tune.

---

## What we're validating (maps to spec ACs)

| ID | Acceptance criterion | Runtime check |
| --- | --- | --- |
| BT-1 | Count is completed+in-progress and **counts up** (AC 1–2) | "Uploading N of M" — N rises toward M as files transfer/finish, never drops; ends N === M just before the success title |
| BT-2 | Second number stays the batch total (AC 2) | M constant = number of files dropped |
| BT-3 | Failed upload marked failed + **toast** (AC 4) | A failing file shows the error row (ErrorUploadItem) and a `"<file> failed to upload"` toast |
| BT-4 | Failed file stays counted, no drop-back (AC 3) | On a mid-batch failure the number does not decrease |
| BT-5 | **Offline mid-upload resolves, no hang** (AC 5) | Cut network during a 20×10MB batch → in-flight files marked failed, count still reaches M, batch resolves to "completed with errors"/failed title, toasts fire, dialog does **not** sit on "Uploading N of M" |
| BT-6 | 0-byte file (AC 3–4) | A 0-byte file errors, is counted, shows error row + toast |
| BT-7 | Neighbors unchanged (AC 6) | Progress bar fills normally; closing mid-batch still shows the cancel-confirm dialog; success/countdown title unchanged on the happy path |

---

## Prerequisites — YOU prepare these before handing to Codex

Codex cannot create accounts, grant permissions, or log in for you. Have these ready:

1. **A running app pointed at a real backend.** From `atlas-front-end`, pick a hosted env so uploads actually reach the backend/S3:
   ```powershell
   npm run dev:tst    # or dev:sb / dev:dev — your call
   ```
   Note the URL the dev server prints (Quasar default is `http://localhost:9000`). Full-local instead: see `docs/atlas/local/full-stack-local-setup.md` + `callisto-local-quickstart.md`.
2. **An Ops Atlas user with upload (RAL) permission** on that env, and a **target Callisto page that has the upload surface** — a Job Proceeding / Job Submission / Case Detail page you can drag files onto. Have the exact URL ready. (Without RAL permission the upload button is disabled — see PRDV-14855.)
3. **A logged-in Chrome on the CDP port** (Playwright attaches to this — a fresh Playwright browser is logged out and won't see the app). Run the launch command in the next section and **log in once** in that window.
4. **Test fixtures generated** (command below) — a normal batch, a 0-byte file, and twenty ~10 MB files.
5. Confirm the file types you use are **supported extensions** for the upload surface; the fixtures below use `.pdf`. If the backend rejects zero-filled content for a *successful*-path file, drop in a few real sample files for the happy-path runs (BT-1/BT-2); the failure/0-byte/offline runs don't need valid content.

---

## PowerShell commands

### 1. Generate test fixtures

```powershell
$dir = "$env:TEMP\prdv-14055-fixtures"
New-Item -ItemType Directory -Force $dir | Out-Null

# 0-byte file (BT-6)
if (-not (Test-Path "$dir\zero-byte.pdf")) { New-Item -ItemType File "$dir\zero-byte.pdf" | Out-Null }

# Small happy-path batch (BT-1/BT-2) — 6 x ~1MB
1..6 | ForEach-Object { fsutil file createnew "$dir\happy-$_.pdf" 1048576 | Out-Null }

# Offline batch (BT-5) — 20 x 10MB (large enough to still be uploading when you cut the network)
1..20 | ForEach-Object { fsutil file createnew "$dir\big-$_.pdf" 10485760 | Out-Null }

Write-Host "Fixtures in $dir"
```

### 2. Launch the authenticated Chrome for Playwright to attach to

```powershell
Start-Process chrome.exe -ArgumentList `
  '--remote-debugging-port=9222', `
  '--user-data-dir=C:\temp\prdv-14055-cdp-profile', `
  'http://localhost:9000'   # <- use the URL your dev server printed
# Then log in as the Ops user in that window (once; the dedicated profile keeps the session).
```

### 3. Drive the offline scenario with Playwright (attaches over CDP)

Save as `scripts/browser/prdv-14055-offline.mjs` (Playwright is already installed under `scripts/browser/`), fill the two selectors by observing the page, then run it. It uploads the 20-file batch, cuts the network mid-upload, and reports the title text over time so you can confirm it resolves instead of hanging.

```powershell
node scripts/browser/prdv-14055-offline.mjs --cdp http://localhost:9222 --fixtures "$env:TEMP\prdv-14055-fixtures"
```

```js
// prdv-14055-offline.mjs  (scaffold — set UPLOAD_INPUT and TITLE selectors from the live page)
import { chromium } from 'playwright';
import fs from 'node:fs';
import path from 'node:path';

const cdp = process.argv[process.argv.indexOf('--cdp') + 1];
const fixtures = process.argv[process.argv.indexOf('--fixtures') + 1];
const UPLOAD_INPUT = 'input[type=file]';        // <- confirm on the page
const TITLE = '.text-h6';                        // <- the "Uploading N of M" element

const browser = await chromium.connectOverCDP(cdp);
const ctx = browser.contexts()[0];
const page = ctx.pages()[0] ?? (await ctx.newPage());

const files = fs.readdirSync(fixtures).filter(f => f.startsWith('big-')).map(f => path.join(fixtures, f));
await page.setInputFiles(UPLOAD_INPUT, files);   // or use the drag-drop surface the page exposes

// let a few files start, then cut the network mid-upload
await page.waitForTimeout(1500);
await ctx.setOffline(true);
console.log('NETWORK OFFLINE at', new Date().toISOString());

// sample the title until it resolves (or time out)
for (let i = 0; i < 30; i++) {
  const t = await page.locator(TITLE).first().innerText().catch(() => '(gone)');
  console.log(i, t);
  if (/uploaded successfully|completed with errors|failed/i.test(t)) { console.log('RESOLVED'); break; }
  await page.waitForTimeout(1000);
}
await ctx.setOffline(false);
await browser.close();
```

If `ctx.setOffline` doesn't take over CDP in your setup, fall back to a raw CDP session: `Network.emulateNetworkConditions({ offline: true, latency: 0, downloadThroughput: 0, uploadThroughput: 0 })`.

---

## Scenarios to run (steps → expected)

1. **Happy path (BT-1/BT-2/BT-7).** Drop the 6 `happy-*.pdf`. Watch the title: N should climb (e.g. 2→3→…→6), M stays 6, the bar fills, then it switches to "All files uploaded successfully" with the countdown. Capture screenshots at ~3 points showing N rising.
2. **0-byte (BT-6).** Drop `zero-byte.pdf` alone. Expect: it errors → error row + `"zero-byte.pdf failed to upload"` toast; the batch reaches a terminal title (doesn't hang).
3. **Mixed (BT-3/BT-4).** Drop a few `happy-*.pdf` plus `zero-byte.pdf`. Expect: the good ones complete, the bad one shows error row + toast, N never drops, title ends "completed with errors".
4. **Offline mid-batch (BT-5).** Run the Playwright script above with the 20 `big-*.pdf`. Expect from the logged title samples: after offline, the in-flight files fail, N still climbs to 20, and the title **resolves** to a terminal state within a few seconds — it must **not** stay on "Uploading N of M". Note whether failure toasts stack (should be deduped via `multiple: false`).
5. **Neighbor — cancel dialog (BT-7).** Start a batch, click the manager's close/X mid-upload → the "Are you sure?" cancel-confirm dialog must still appear.

---

## Evidence to capture

- Screenshots: count rising (happy path), error row + toast (0-byte/mixed), and the **final resolved title** for the offline run.
- The offline script's stdout (the title-over-time samples showing it resolved).
- Write each scenario's result into [PRDV-14055-test-plan.md](./PRDV-14055-test-plan.md) **Results log** with date + observed outcome; mark any failure with repro details.

## Definition of done

Every BT-1…BT-7 observed and recorded; the offline run demonstrably resolves (no hang); any deviation is logged in the test plan with a screenshot and repro. If a scenario can't be run (env/permission/data), record it **blocked** with the reason — don't silently skip.
