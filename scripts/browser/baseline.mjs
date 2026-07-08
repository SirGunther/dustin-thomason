#!/usr/bin/env node
// Regression baselines - turn "should still work" into executable assertions (spec 3.4, 4).
//
// Per component, stores a baseline: geometry (rects) + visibility for a set of selectors, plus a
// threshold screenshot. `compare` re-captures and asserts against it, so a later agent is TOLD it
// broke something instead of believing it didn't. Geometry is sub-pixel exact (position/size);
// the screenshot is diffed with a pixel tolerance (anti-aliasing/hinting cause ~1px shimmer that
// is not a real regression).
//
// Usage:
//   node baseline.mjs capture --url <url> --selectors "a,b,c" --dir <baselineDir> [--clip <sel>] [--headed]
//   node baseline.mjs compare --url <url> --selectors "a,b,c" --dir <baselineDir> [--clip <sel>] [--max-diff-pixels 100]
//
// Convention for <baselineDir>: docs/<project>/baselines/<component>/  (baseline.json + baseline.png).
// `compare` exits 1 on any geometry/visibility change or pixel diff over tolerance, 0 otherwise.

import { mkdirSync, existsSync, readFileSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { chromium } from 'playwright';
import { PNG } from 'pngjs';
import pixelmatch from 'pixelmatch';

function parseArgs(argv) {
  const a = { _: [] };
  for (let i = 0; i < argv.length; i++) {
    const k = argv[i];
    if (k === '--headed') { a.headed = true; continue; }
    if (k.startsWith('--')) { a[k.slice(2)] = argv[++i]; } else { a._.push(k); }
  }
  return a;
}
function fail(msg) { console.error(`baseline: ${msg}`); process.exit(2); }

async function captureGeometry(page, selectors) {
  return page.evaluate((sels) => {
    const out = {};
    for (const sel of sels) {
      const el = document.querySelector(sel);
      if (!el) { out[sel] = { present: false }; continue; }
      const r = el.getBoundingClientRect();
      const cs = getComputedStyle(el);
      out[sel] = {
        present: true,
        visible: cs.display !== 'none' && cs.visibility !== 'hidden' && Number(cs.opacity) !== 0,
        x: +r.x.toFixed(2), y: +r.y.toFixed(2), width: +r.width.toFixed(2), height: +r.height.toFixed(2),
      };
    }
    return out;
  }, selectors);
}

async function screenshot(page, clip) {
  const target = clip ? page.locator(clip).first() : page;
  return target.screenshot();
}

function diffGeometry(base, curr, selectors) {
  const changes = [];
  for (const sel of selectors) {
    const a = base[sel];
    const b = curr[sel];
    if (!a) { changes.push({ selector: sel, note: 'not in baseline' }); continue; }
    if (a.present !== b.present) { changes.push({ selector: sel, dim: 'present', from: a.present, to: b.present }); continue; }
    if (!a.present) continue;
    if (a.visible !== b.visible) changes.push({ selector: sel, dim: 'visible', from: a.visible, to: b.visible });
    for (const dim of ['x', 'y', 'width', 'height']) {
      if (a[dim] !== b[dim]) changes.push({ selector: sel, dim, from: a[dim], to: b[dim], delta: +(b[dim] - a[dim]).toFixed(2) });
    }
  }
  return changes;
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const mode = args._[0];
  if (mode !== 'capture' && mode !== 'compare') fail('first arg must be "capture" or "compare"');
  if (!args.url) fail('--url is required');
  if (!args.dir) fail('--dir is required');
  if (!args.selectors) fail('--selectors is required');
  const selectors = args.selectors.split(',').map((s) => s.trim()).filter(Boolean);
  const maxDiffPixels = Number(args['max-diff-pixels'] ?? 100);
  const jsonPath = join(args.dir, 'baseline.json');
  const pngPath = join(args.dir, 'baseline.png');

  const browser = await chromium.launch({ headless: !args.headed });
  const page = await browser.newPage();
  await page.goto(args.url, { waitUntil: 'load' });

  const geometry = await captureGeometry(page, selectors);
  const shot = await screenshot(page, args.clip);

  if (mode === 'capture') {
    mkdirSync(args.dir, { recursive: true });
    writeFileSync(jsonPath, JSON.stringify({ url: args.url, clip: args.clip ?? null, selectors, geometry }, null, 2) + '\n');
    writeFileSync(pngPath, shot);
    console.log(`Captured baseline for ${selectors.length} selector(s) -> ${args.dir}`);
    await browser.close();
    return;
  }

  // compare
  if (!existsSync(jsonPath)) { await browser.close(); fail(`no baseline at ${jsonPath} - run capture first`); }
  const base = JSON.parse(readFileSync(jsonPath, 'utf8'));
  const geoChanges = diffGeometry(base.geometry, geometry, selectors);

  let pixelDiff = null;
  const report = { url: args.url, geometryChanges: geoChanges };
  if (existsSync(pngPath)) {
    const baseImg = PNG.sync.read(readFileSync(pngPath));
    const currImg = PNG.sync.read(shot);
    if (baseImg.width !== currImg.width || baseImg.height !== currImg.height) {
      report.screenshot = { changed: true, reason: `size changed ${baseImg.width}x${baseImg.height} -> ${currImg.width}x${currImg.height}` };
      pixelDiff = Infinity;
    } else {
      const diff = new PNG({ width: baseImg.width, height: baseImg.height });
      pixelDiff = pixelmatch(baseImg.data, currImg.data, diff.data, baseImg.width, baseImg.height, { threshold: 0.1 });
      report.screenshot = { pixelDiff, maxDiffPixels, over: pixelDiff > maxDiffPixels };
      if (pixelDiff > maxDiffPixels) writeFileSync(join(args.dir, 'diff.png'), PNG.sync.write(diff));
    }
  }

  console.log(JSON.stringify(report, null, 2));
  await browser.close();
  const failed = geoChanges.length > 0 || (pixelDiff != null && pixelDiff > maxDiffPixels);
  process.exit(failed ? 1 : 0);
}

main().catch((e) => { console.error(e); process.exit(1); });
