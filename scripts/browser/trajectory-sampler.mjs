#!/usr/bin/env node
// Trajectory sampling - the fix for "what happened in between" (spec 3.2-3.3).
//
// Performs a REAL stepped drag (press -> move through intermediate points -> release; it does not
// shortcut by setting a width), and at each checkpoint captures getBoundingClientRect for many
// elements - the target, its contents, and neighbors - as numeric geometry. Includes the boundary
// (fully dragged) checkpoint and an optional trigger action (e.g. click-out) afterward. Flags any
// tracked element that jumps size/position by more than a threshold between adjacent steps, which
// catches a class of bug no one wrote a specific test for by flagging physical impossibility.
//
// Usage:
//   node trajectory-sampler.mjs --config <config.json>
//   node trajectory-sampler.mjs --url <url> --handle "<sel>" --dx -200 --dy 0 --steps 10 \
//        --watch ".panel,.panel .content,.neighbor" --threshold 50 [--trigger-click "<sel>"] [--headed]
//
// Output is JSON on stdout: { steps: [{label, rects}], discontinuities: [...] }. Exit code is 1
// if any discontinuity is flagged, 0 otherwise.

import { readFileSync } from 'node:fs';
import { chromium } from 'playwright';

function parseArgs(argv) {
  const a = {};
  for (let i = 0; i < argv.length; i++) {
    const k = argv[i];
    if (k === '--headed') { a.headed = true; continue; }
    if (k.startsWith('--')) a[k.slice(2)] = argv[++i];
  }
  return a;
}
function fail(msg) { console.error(`trajectory-sampler: ${msg}`); process.exit(2); }

function loadConfig(args) {
  let cfg = {};
  if (args.config) cfg = JSON.parse(readFileSync(args.config, 'utf8'));
  if (args.url) cfg.url = args.url;
  if (args.handle) cfg.handle = args.handle;
  if (args.dx != null || args.dy != null) cfg.delta = { dx: Number(args.dx ?? cfg.delta?.dx ?? 0), dy: Number(args.dy ?? cfg.delta?.dy ?? 0) };
  if (args.steps) cfg.steps = Number(args.steps);
  if (args.watch) cfg.watch = args.watch.split(',').map((s) => s.trim()).filter(Boolean);
  if (args.threshold) cfg.threshold = Number(args.threshold);
  if (args['trigger-click']) cfg.trigger = { action: 'click', selector: args['trigger-click'] };
  if (args.headed) cfg.headed = true;
  cfg.steps = cfg.steps || 10;
  cfg.threshold = cfg.threshold ?? 50;
  cfg.delta = cfg.delta || { dx: 0, dy: 0 };
  if (!cfg.url) fail('url is required (--url or config.url)');
  if (!cfg.handle) fail('handle selector is required (--handle or config.handle)');
  if (!cfg.watch || !cfg.watch.length) fail('watch selectors are required (--watch or config.watch)');
  return cfg;
}

async function measure(page, selectors) {
  return page.evaluate((sels) => {
    const out = {};
    for (const sel of sels) {
      const el = document.querySelector(sel);
      if (!el) { out[sel] = null; continue; }
      const r = el.getBoundingClientRect();
      const cs = getComputedStyle(el);
      const visible = cs.display !== 'none' && cs.visibility !== 'hidden' && Number(cs.opacity) !== 0;
      out[sel] = { x: +r.x.toFixed(2), y: +r.y.toFixed(2), width: +r.width.toFixed(2), height: +r.height.toFixed(2), visible };
    }
    return out;
  }, selectors);
}

function findDiscontinuities(steps, watch, threshold) {
  const flags = [];
  for (const sel of watch) {
    for (let i = 1; i < steps.length; i++) {
      const a = steps[i - 1].rects[sel];
      const b = steps[i].rects[sel];
      const present = (v) => v && v.visible;
      if (present(a) !== present(b)) {
        flags.push({ selector: sel, from: steps[i - 1].label, to: steps[i].label, dim: 'visibility', fromValue: present(a), toValue: present(b) });
        continue;
      }
      if (!a || !b) continue;
      for (const dim of ['x', 'y', 'width', 'height']) {
        const delta = Math.abs(b[dim] - a[dim]);
        if (delta > threshold) {
          flags.push({ selector: sel, from: steps[i - 1].label, to: steps[i].label, dim, fromValue: a[dim], toValue: b[dim], delta: +delta.toFixed(2), threshold });
        }
      }
    }
  }
  return flags;
}

async function main() {
  const cfg = loadConfig(parseArgs(process.argv.slice(2)));
  const browser = await chromium.launch({ headless: !cfg.headed });
  const page = await browser.newPage();
  await page.goto(cfg.url, { waitUntil: 'load' });

  const steps = [];
  steps.push({ label: 'rest', rects: await measure(page, cfg.watch) });

  const box = await page.locator(cfg.handle).first().boundingBox();
  if (!box) { await browser.close(); fail(`handle not found or not visible: ${cfg.handle}`); }
  const cx = box.x + box.width / 2;
  const cy = box.y + box.height / 2;

  await page.mouse.move(cx, cy);
  await page.mouse.down();
  const n = cfg.steps;
  for (let i = 1; i <= n; i++) {
    const tx = cx + (cfg.delta.dx * i) / n;
    const ty = cy + (cfg.delta.dy * i) / n;
    await page.mouse.move(tx, ty, { steps: 1 });
    steps.push({ label: `drag ${i}/${n}`, rects: await measure(page, cfg.watch) });
  }
  await page.mouse.up();
  steps.push({ label: 'release', rects: await measure(page, cfg.watch) });

  if (cfg.trigger && cfg.trigger.selector) {
    if ((cfg.trigger.action ?? 'click') === 'click') await page.click(cfg.trigger.selector);
    steps.push({ label: `after-trigger (${cfg.trigger.action ?? 'click'} ${cfg.trigger.selector})`, rects: await measure(page, cfg.watch) });
  }

  const discontinuities = findDiscontinuities(steps, cfg.watch, cfg.threshold);
  console.log(JSON.stringify({ url: cfg.url, handle: cfg.handle, threshold: cfg.threshold, steps, discontinuities }, null, 2));

  await browser.close();
  process.exit(discontinuities.length ? 1 : 0);
}

main().catch((e) => { console.error(e); process.exit(1); });
