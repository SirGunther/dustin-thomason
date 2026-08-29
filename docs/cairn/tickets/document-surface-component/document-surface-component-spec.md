# Spec: Document Surface as a Reusable Component (Cairn phase)

| Field | Value |
| --- | --- |
| Project | Cairn |
| Slug | `document-surface-component` |
| Phase | 1 of 2. Cairn-only. WorkLists consumption is deferred to phase 2. |
| Live repository | `C:\Users\dktho\OneDrive\PDProjects\Cairn` |
| Canonical record | `C:\dustin-thomason\docs\cairn\cairn-app-changelog.md` |
| Capability catalog | `C:\dustin-thomason\docs\cairn\capabilities.md` |
| Written | 2026-08-27 |
| Status | Ready for implementation |

---

## Product story

As the author of both Cairn and WorkLists, I want the markdown document surface (its rendering,
its editing behavior, and its appearance) to exist as one reusable component with a declared
interface, so that WorkLists can later present a note using exactly the surface Cairn presents a
document with, and so that a change made once to typography or layout reaches both applications.

This phase delivers the component and proves it inside Cairn. Cairn must look and behave
identically before and after.

### Acceptance criteria

1. A document surface module exists with a declared, documented interface, and Cairn draws its
   document view exclusively through that interface.
2. `npm run verify` passes at the same or better gate count than before the change, with no gate
   newly failing.
3. `npm run graph:check` still reports exactly one main-thread component.
4. The rendered document, the source pane, the ribbon, mode switching, caret behavior on edit, and
   task-checkbox commit are unchanged from the user's point of view.
5. The surface accepts a host-supplied document key rather than assuming a filesystem path.
6. The surface's appearance is owned by the module rather than by the host stylesheet, or the
   reason it is not is recorded as a resolved decision with evidence.
7. No module that holds a DOM side effect does so without a written statement of what it may reach.

---

## Summary and scope

| In scope | Out of scope |
| --- | --- |
| A document surface module with a declared interface | Any change to WorkLists |
| Moving document drawing, ribbon, mode switching, gutter, and rich-editor lifecycle behind that interface | Standing up a kernel or graph inside WorkLists |
| Giving `rich-editor` a declared interface document | The attachments / file-pointer feature discussed separately |
| Deciding and implementing how the surface's styles travel with it | Redesigning the appearance of the document surface |
| Making the surface's document identity host-supplied rather than path-based | Replacing `markdown-renderer` with ProseMirror rendering |
| Recording the outcome in the changelog and capability catalog | Changing Cairn's explorer, tabs, dialogs, outline, or status bar |

---

## Problem, requirement, solution

### Problem

The markdown document surface exists twice across two applications, and neither copy is a
component. In Cairn the surface is spread across four places that no interface separates: the
governed message boundary in `components/dom-owner/index.js`, the drawing and interaction code
inside `app.js`, the markup skeleton in `index.html`, and roughly 131 selector occurrences in
`styles.css`. Because no boundary exists, a second host cannot present the same surface, and a
change to appearance must be made twice and kept in agreement by hand.

### Requirement

The document surface must be callable by a host that did not write it. Specifically:

- The host supplies a mount node and a document key. The surface owns everything inside the
  document frame and knows nothing about the host's chrome.
- The surface's inputs and outputs are declared, so a host can be wired to it without reading its
  implementation, and nothing is reachable that was not declared.
- The surface's appearance travels with the surface, so one change reaches every host.
- Cairn's observable behavior is unchanged, and Cairn continues to consume the surface through the
  same governed messages it uses today.

### Solution

Extract the document surface into a declared-interface module under `components/`, consumed by the
existing privileged component. Do not make it a second graph component; the graph forbids that
(see **Resolved decisions**, `D1`). The module owns the document markup, the drawing, the ribbon,
mode switching, the rich editor, and the styles. `dom-owner` keeps sole host-realm privilege and
delegates drawing to the module. `markdown-renderer` is unchanged and continues to supply rendered
HTML as a governed worker component.

---

## Resolved decisions

| ID | Decision | Why, with evidence |
| --- | --- | --- |
| `D1` | The document surface is **not** a graph component. It is a declared-interface module consumed by `dom-owner`. | `runtime/graph-prepare.mjs` fails the graph when more than one main-thread component exists: "At most one component may run in the host realm." The document surface must touch the DOM, so it must be main-thread, and `dom-owner` already holds that slot. The rule's rationale is `Architecture/FeasibilityReview.md` section 2, "The DOM is one privileged component that cannot be decomposed." Adding a second main-thread component would fail `npm run graph:check`. |
| `D2` | `rich-editor` stays a library and does not become a graph component. | It constructs a ProseMirror `EditorView`, which requires the DOM. `graph-prepare.mjs` rejects a worker component declaring a `dom` side effect, and `D1` forbids a second main-thread component. A library with a declared interface is the only shape available to it. |
| `D3` | `markdown-renderer` is left alone. | Its manifest already declares `state: "none"` and `side_effects: []`, with ports accepting `document.render-request` and emitting `document.rendered`. It is already the portable unit the abstraction wants, and it is live in the graph with wires in both directions. |
| `D4` | The document key is host-supplied and opaque to the surface. | The surface currently keys sessions by filesystem path. WorkLists notes are keyed by `noteId` and have no path. Making the key opaque now costs little and avoids a second refactor in phase 2. |
| `D5` | Cairn's appearance is the target appearance. No visual redesign in this phase. | Acceptance criterion 4 requires the surface to be visually unchanged, which makes the extraction independently verifiable. A redesign would make a regression indistinguishable from an intended change. |

---

## Open questions

| ID | Question | Why it is open | How to close it |
| --- | --- | --- | --- |
| `Q1` | How do the surface's styles travel with the module? | Three candidates: a stylesheet file the host links, a constructed stylesheet the module adopts via `adoptedStyleSheets`, or leaving styles to each host. The third defeats acceptance criterion 6. | Write a probe under `Architecture/probes/` that adopts a constructed stylesheet under the served CSP and reports whether the rules apply. `tools/serve.mjs` sets `style-src 'self'` and its comments state that CSSOM property writes are unaffected, but constructed stylesheets are a different mechanism and must be measured rather than assumed. |
| `Q2` | Does the ribbon belong to the surface or to the host? | The stated framing is that the toolbar is the visible difference between reading a note and editing one, which suggests the surface owns it and the host toggles it. Cairn currently owns `#mdRibbon` in host markup. | Decide during implementation. Default to the surface owning it, with the host asking for it to be shown or hidden. |
| `Q3` | Does the surface own the source pane and gutter, or only the rendered view? | Cairn shows preview, split, and source modes. WorkLists may only ever need the rendered view plus editing. | Default to the surface owning all three so Cairn is unchanged, and let phase 2 decide whether a host may request a reduced mode set. |

---

## 1. Folder hierarchy

New and changed paths under `C:\Users\dktho\OneDrive\PDProjects\Cairn`:

```
components/
  document-surface/                 NEW
    index.js                        the module and its declared interface
    INTERFACE.md                    what a host may call, and what it may not reach
    surface.css                     the styles moved out of styles.css (pending Q1)
    markup.js                       the document frame the surface builds into its mount
    modes.js                        preview / split / source switching
    ribbon.js                       formatting toolbar construction and dispatch
  dom-owner/
    index.js                        CHANGED: delegates drawing to document-surface
  rich-editor/
    index.js                        CHANGED: document key becomes opaque (D4)
    INTERFACE.md                    NEW: declared interface for the editor library
app.js                              CHANGED: document-view code removed, host frame retained
index.html                          CHANGED: document frame markup removed from host markup
styles.css                          CHANGED: document-surface selectors removed
Architecture/probes/
  surface-style-adoption.html       NEW: the Q1 probe
tests/
  document-surface-browser.mjs      NEW: the surface driven through its interface alone
```

## 2. New modules and their interfaces

| Module | Export | Responsibility |
| --- | --- | --- |
| `components/document-surface/index.js` | `createDocumentSurface({ mount, onIntent, capabilities })` | Builds the document frame into `mount`, draws projections, hosts the editor, emits intents. Owns nothing outside `mount`. |
| same | `surface.present(key, projection)` | Draw or update the document identified by `key`. |
| same | `surface.setMode(mode)` | One of `preview`, `split`, `source`. |
| same | `surface.setEditable(editable)` | Controls whether the ribbon and editing are available. |
| same | `surface.isDirty(key)`, `surface.markdown(key)`, `surface.accept(key, revision, markdown)` | Draft state, mirroring the existing rich-editor contract. |
| same | `surface.close(key)`, `surface.destroy()` | Session and lifetime management. |
| `components/document-surface/INTERFACE.md` | document | The declared boundary: every call a host may make, every intent it may receive, and an explicit statement that the surface never reads the filesystem, never holds authoritative text, and never touches DOM outside its mount. |

Intents emitted through `onIntent(kind, payload)` map onto messages `dom-owner` already emits, so
no new governed message types are required:

| Intent | Existing message `dom-owner` emits |
| --- | --- |
| `toggle-task` | `document.toggle-task` |
| `replace-text` | `document.replace-text` |
| `save` | `document.save` |
| `request-source` | `document.source-request` |

## 3. Manifests and contracts

- `components/document-surface/` gets **no** `component.json`, per `D1`. Its boundary is declared
  in `INTERFACE.md` and enforced by the test in section 7.
- `components/rich-editor/` gets **no** `component.json`, per `D2`, and gains `INTERFACE.md`.
- `components/dom-owner/component.json` is **unchanged**. Its declared ports already cover every
  message the surface's intents map onto, so the governed contract does not move.
- `contracts/catalog.json` is **unchanged**. No new message types are introduced. Confirm with
  `npm run contracts:check` and `npm run contracts:docs:check`.

## 4. Graph wiring

`graphs/read-render.json` is **unchanged**. The component count stays at nine and the wire count
stays at 135. `npm run graph:check` must still report exactly one main-thread component, which is
the primary structural guard on this change.

## 5. Markup boundary

The document frame is already contiguous in `index.html` and moves as a block into the surface:

| Element | Disposition |
| --- | --- |
| `#mdRibbon`, `#mdRibbonActions` | Moves to the surface (pending `Q2`) |
| `#docBody` | Moves to the surface |
| `#previewPane`, `#preview` | Moves to the surface |
| `#sourcePane`, `#gutter`, `#source` | Moves to the surface (pending `Q3`) |
| `#emptyState` | Moves to the surface |
| Everything else (`#sidebar`, `#tree`, `#tabStrip`, `#breadcrumb`, `#outline`, status bar, dialogs, `#paletteLayer`) | Stays in the host |

The host is left with a single mount node where `#docBody` used to sit.

**Known consequence to plan for:** `app.js` and `tests/shell-browser.mjs` reach document elements
by `document.getElementById`. Those references must move to surface-owned lookups or to the
surface's interface. This is the mechanical cost recorded against `EMB-001` in
`DECISIONS-PENDING.md`, and this change reduces it for the document region.

## 6. Styles

Move the document-surface selectors out of `styles.css` into
`components/document-surface/surface.css`. Measured footprint in the current `styles.css`
(2226 lines total), by selector occurrence:

| Selector family | Occurrences |
| --- | --- |
| `.md-body` | 71 |
| `.markdown-*` | 17 |
| `.ProseMirror` | 13 |
| `.md-ribbon` | 11 |
| `.doc-body` | 9 |
| `.pm-*` | 4 |
| `.empty-state` | 4 |
| `.doc-pane` | 1 |
| `.gutter` | 1 |

Delivery mechanism is `Q1`. Whichever is chosen, the acceptance test is that changing a font
declaration in `surface.css` changes Cairn's rendered document with no edit to `styles.css`.

## 7. Tests

| Test | Purpose |
| --- | --- |
| `tests/document-surface-browser.mjs` NEW | Drive the surface through its interface only, with no host present: present a projection, switch modes, toggle a task, edit and read back markdown, confirm no DOM is written outside the mount. |
| `tests/shell-browser.mjs` CHANGED | Update element lookups that moved behind the surface. Must still pass at its current count. |
| `tests/rich-editor-browser.mjs` CHANGED | Update for the opaque document key (`D4`). Must still pass at its current count. |
| `tests/component-standalone.mjs` | Unchanged. Must still pass; it proves the governed components still run through their own ports. |
| `Architecture/probes/surface-style-adoption.html` NEW | Closes `Q1`. Needs a browser and a hand. |

## 8. Verification gates

Run in this order and record the exact command, scope, and result:

| Gate | Command | Expectation |
| --- | --- | --- |
| graph | `npm run graph:check` | Accepted. Exactly one main-thread component. |
| contracts | `npm run contracts:check` | Catalog unchanged at `1.12.0`, 41 message types. |
| contract docs | `npm run contracts:docs:check` | No drift. |
| artifacts | `npm run artifacts:check` | No drift. Graph unchanged. |
| vendor | `npm run vendor:check` | Unchanged. See the note below. |
| node tests | `npm test` | No regression in count. |
| standalone | `npm run test:standalone` | 33 checks still pass. |
| shell | `npm run test:shell` | Passes after element-lookup updates. |
| surface | `node tests/document-surface-browser.mjs` | New. All checks pass. |
| rich editor | `npm run test:rich-editor` | 7 checks still pass. |
| format | `npm run format:check` | Clean. |
| everything | `npm run verify` | 16 of 16 gates, plus the new surface gate once wired in. |

**Vendor note:** `tools/check-vendor-parity.mjs` currently gates three files that nothing in Cairn
imports (`markdown-editor.js`, `markdown-authoring.js`, `edit-session.js`); only
`markdown-renderer.js` is imported. This is outside the scope of this spec, but if the
implementing agent touches `vendor/`, record whether those three are a deliberate fallback or
should be removed from `PAIRS`, rather than leaving the gate asserting a coupling that no longer
exists.

## Sections not applicable

| Section | Why |
| --- | --- |
| New entities, modified entities | Cairn has no database or ORM. Documents are files on disk. |
| Migrations, migration classes | Same. |
| DTOs, projections as HTTP contracts | Cairn exposes no HTTP API. `tools/serve.mjs` serves static files under a CSP and defines no routes. |
| Authorization, guards, roles | Single-user local application, no auth surface. |
| API docs / Swagger | No HTTP surface to document. Checked `tools/serve.mjs`: it serves files by path and defines no endpoints. |

---

## Risks

| Risk | Mitigation |
| --- | --- |
| Caret behavior regresses. The block-diffing in `drawProjection` exists because four earlier attempts to restore a caret after replacing nodes each fixed one case and broke another; that history is written into the file's comments. | Move `drawProjection` intact. Do not reimplement it. Assert caret survival in the new surface test. |
| The task-checkbox commit path breaks. It rewrites exactly one source line without re-serializing, and Cairn has a standing decision against whole-document round-tripping. | `splice-lines.mjs` and `apply-delta.mjs` stay with `dom-owner`. The surface emits an intent; it does not compute the edit. |
| Element-id coupling is larger than expected once `app.js` is opened. | Do the markup move first and let the failures in `test:shell` enumerate the coupling before writing the interface. |
| Style extraction changes appearance subtly through cascade order. | Compare rendered output before and after against the same document. Do not resolve any cascade conflict with a higher-specificity override or `!important`; find the responsible rule. |

---

## Implementation sequence

1. Run `npm run verify` on the untouched tree and record the baseline gate counts. Every later
   claim of "no regression" is measured against this.
2. Close `Q1` with the style-adoption probe before moving any CSS.
3. Move the document frame markup out of `index.html` into `components/document-surface/markup.js`,
   leaving a single mount node. Let `npm run test:shell` fail and use its failures to enumerate the
   element coupling.
4. Create `createDocumentSurface` and move drawing, mode switching, ribbon, gutter, and rich-editor
   lifecycle behind it. Move `drawProjection` without rewriting it.
5. Change the document key to be host-supplied and opaque (`D4`). Update `test:rich-editor`.
6. Move the styles into `surface.css` using the mechanism `Q1` settled on.
7. Write `INTERFACE.md` for both `document-surface` and `rich-editor`, stating what a host may call
   and what it may never reach.
8. Write `tests/document-surface-browser.mjs` and wire it into `tools/verify.mjs`.
9. Run every gate in section 8. Report the exact command, scope, and result for each.
10. Prepend a UTC-dated entry to `cairn-app-changelog.md` and update `capabilities.md`, which
    currently records inline editing against `rich-editor/` and will need to record the surface.

---

## Phase 2 preview (not in scope)

For context only, so the implementing agent does not design against it by accident. WorkLists
consumption needs: the kernel, component host, and contract catalog stood up in WorkLists; a graph
declaring which components are wired; a loading path for an ES module bundle in an application
that currently loads plain script globals; and reconnecting the notes pane's voice-to-text, AI
refine, and collapse behavior to the surface. None of that belongs in this phase.
