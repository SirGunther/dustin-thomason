#!/usr/bin/env node
// Cascade provenance - the "who won" answer, not just "what" (spec 3.1).
//
// For a target element, reports, per CSS property: which rule's declaration won, and which
// declarations it struck through (overrode) - the exact data behind the DevTools Styles pane,
// served via CDP CSS.getMatchedStylesForNode rather than inferred from getComputedStyle.
//
// Usage:
//   node css-provenance.mjs --url <url> --selector "<css>" [--property <name>] [--headed]
//   node css-provenance.mjs --cdp http://localhost:9222 --selector "<css>" [--url <url>]
//
// --cdp attaches to an already-running Chrome (launched with --remote-debugging-port); otherwise
// a headless Chromium is launched for --url. Output is JSON on stdout.

import { chromium } from 'playwright';

function parseArgs(argv) {
  const args = {};
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--headed') { args.headed = true; continue; }
    if (a.startsWith('--')) { args[a.slice(2)] = argv[++i]; }
  }
  return args;
}
function fail(msg) { console.error(`css-provenance: ${msg}`); process.exit(2); }

function sourceOf(rule, sheets) {
  if (!rule || !rule.styleSheetId) {
    return rule && rule.origin && rule.origin !== 'regular' ? `<${rule.origin}>` : null;
  }
  const h = sheets.get(rule.styleSheetId);
  const url = (h && (h.sourceURL || h.title)) || `<stylesheet ${rule.styleSheetId}>`;
  const startLine =
    (rule.style && rule.style.range && rule.style.range.startLine) ??
    (rule.selectorList && rule.selectorList.selectors && rule.selectorList.selectors[0] &&
      rule.selectorList.selectors[0].range && rule.selectorList.selectors[0].range.startLine);
  return startLine != null ? `${url}:${startLine + 1}` : url;
}

// Build per-property cascade winners from the matched-styles payload. Layers are ordered by
// ascending priority (matched rules low->high as CDP returns them, then inline highest); a later
// normal declaration overrides an earlier one, and any !important outranks every normal.
function buildProvenance(matched, sheets, onlyProp) {
  const layers = [];
  for (const m of matched.matchedCSSRules ?? []) {
    const rule = m.rule || {};
    const selector = (rule.selectorList?.selectors ?? []).map((s) => s.text).join(', ');
    layers.push({ kind: 'rule', selector, origin: rule.origin, source: sourceOf(rule, sheets), style: rule.style });
  }
  if (matched.inlineStyle) {
    layers.push({ kind: 'inline', selector: 'element.style', origin: 'inline', source: null, style: matched.inlineStyle });
  }

  const byProp = new Map();
  const seen = new Set(); // CDP can list a declaration twice per rule; collapse exact repeats.
  layers.forEach((layer, layerIdx) => {
    for (const d of layer.style?.cssProperties ?? []) {
      if (!d.name || d.disabled) continue;
      if (d.value == null || d.value === '') continue;
      const name = d.name.toLowerCase();
      if (onlyProp && name !== onlyProp.toLowerCase()) continue;
      // CDP may fold "!important" into the value string; normalize so it isn't doubled.
      const important = !!d.important || /!important\s*$/i.test(d.value);
      const value = String(d.value).replace(/\s*!important\s*$/i, '');
      const key = `${layerIdx}|${name}|${value}|${important}`;
      if (seen.has(key)) continue;
      seen.add(key);
      if (!byProp.has(name)) byProp.set(name, []);
      byProp.get(name).push({
        value,
        important,
        rank: (important ? 1e6 : 0) + layerIdx,
        by: layer.selector,
        kind: layer.kind,
        source: layer.source,
      });
    }
  });

  const fmt = (d) => ({ value: d.value + (d.important ? ' !important' : ''), by: d.by, kind: d.kind, source: d.source });
  const properties = [];
  for (const [property, decls] of byProp) {
    const ranked = [...decls].sort((a, b) => b.rank - a.rank);
    properties.push({ property, winner: fmt(ranked[0]), struckThrough: ranked.slice(1).map(fmt) });
  }
  properties.sort((a, b) => a.property.localeCompare(b.property));
  return properties;
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  if (!args.selector) fail('--selector is required');

  let browser;
  let page;
  let owns = false;
  if (args.cdp) {
    browser = await chromium.connectOverCDP(args.cdp);
    const ctx = browser.contexts()[0] ?? (await browser.newContext());
    page = ctx.pages()[0] ?? (await ctx.newPage());
    if (args.url) await page.goto(args.url, { waitUntil: 'load' });
  } else {
    if (!args.url) fail('--url is required unless --cdp is given');
    browser = await chromium.launch({ headless: !args.headed });
    owns = true;
    page = await browser.newPage();
    await page.goto(args.url, { waitUntil: 'load' });
  }

  const cdp = await page.context().newCDPSession(page);
  const sheets = new Map();
  cdp.on('CSS.styleSheetAdded', (e) => sheets.set(e.header.styleSheetId, e.header));
  await cdp.send('DOM.enable');
  await cdp.send('CSS.enable');

  const { root } = await cdp.send('DOM.getDocument', { depth: -1 });
  const { nodeId } = await cdp.send('DOM.querySelector', { nodeId: root.nodeId, selector: args.selector });
  if (!nodeId) { if (owns) await browser.close(); fail(`selector not found: ${args.selector}`); }

  const matched = await cdp.send('CSS.getMatchedStylesForNode', { nodeId });
  const report = {
    selector: args.selector,
    url: args.url ?? null,
    properties: buildProvenance(matched, sheets, args.property),
  };
  console.log(JSON.stringify(report, null, 2));

  if (owns) await browser.close();
}

main().catch((e) => { console.error(e); process.exit(1); });
