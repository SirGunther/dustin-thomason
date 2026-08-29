# Markdown Kit Package Extraction — Spec

## Metadata

- **Status:** draft / ready for implementation planning
- **Date:** 2026-08-27
- **Ticket:** markdown-kit-package-extraction
- **Domain:** WorkLists (owner) · Cairn (companion consumer)
- **Spec:** `c:\dustin-thomason\docs\WorkLists\tickets\markdown-kit-package-extraction\specs\markdown-kit-package-extraction-spec.md`
- **Changelog:** `c:\dustin-thomason\docs\WorkLists\worklists-app-changelog.md`

## Package identified

The package that exists in two places is the **markdown authoring surface** — four UMD files authored in WorkLists and copied verbatim into Cairn:

| WorkLists original (authored)  | Cairn copy                    | md5 (both, verified 2026-08-27)    |
| ------------------------------ | ----------------------------- | ---------------------------------- |
| `public/markdownRenderer.js`   | `vendor/markdown-renderer.js` | `3ef87f42c004b2f50e01dc67acb53fab` |
| `public/markdownEditor.js`     | `vendor/markdown-editor.js`   | `55fbc26a666e0d3ad01a9c8b3e7247d3` |
| `public/markdownAuthoring.js`  | `vendor/markdown-authoring.js`| `2aa710a6ed2a6ce0f8e748f9b5d2312e` |
| `public/editSession.js`        | `vendor/edit-session.js`      | `82ac6782d99562c6d612ba76df0d565e` |

All four pairs are **byte-identical today**. There is no drift to reconcile — this is a consolidation, not a merge. Cairn holds the pairing in `tools/check-vendor-parity.mjs` (the `PAIRS` map), enforced as gate 6 of `tools/verify.mjs`.

## Problem → Requirement → Solution

### Problem

WorkLists has no package boundary. The four markdown files sit loose in `public/` beside twenty-four unrelated application scripts, are wired by `<script>` tag ordering in `public/index.html`, and publish themselves onto `window` as ambient globals (`MarkdownRenderer`, `MarkdownEditor`, `MarkdownAuthoring`, `EditSession`). Nothing declares what is public, what is internal, or what the unit is.

Cairn did not copy these files by preference. It copied them because **there was nothing to depend on** — no package, no entry point, no version, no resolvable name. Vendoring was the only mechanism available, and Cairn's own source says so: adapting the files would end the byte-parity that makes drift visible, so the copies are deliberately frozen.

The consequence is that Cairn's `check-vendor-parity.mjs` — a genuinely well-built gate — exists to manage a defect that lives in WorkLists. It resolves the originals through a hard-coded absolute machine path:

```js
const WORKLISTS = "c:/Users/dktho/OneDrive/SCRIPTS ALL SYSTEMS/To Do List/WorkLists/public";
```

On any machine or checkout where that path does not resolve, the gate reports `UNVERIFIABLE` and exits non-zero. Cairn's own comment names this correctly as a recorded limit rather than a fix. Three of the four copies (`markdown-editor.js`, `markdown-authoring.js`, `edit-session.js`) have no importer anywhere in Cairn's source — they are held under parity enforcement purely as staged material.

The duplication is the symptom. The missing package boundary in WorkLists is the defect.

### Requirement

These conditions must hold, independent of how they are achieved:

1. **One authored copy.** Exactly one editable copy of each markdown file exists across all repositories. No second copy is authored, staged, or maintained.
2. **Declared interface.** The unit declares a name, a version, and an explicit public surface. What is importable is stated, not discovered by reading `<script>` tags.
3. **Resolution, not reproduction.** A second consumer obtains the code by resolving the one copy through a declared dependency. Obtaining it by copying is not a supported path.
4. **Same artifact both sides.** WorkLists loads the package through the same declared interface an external consumer uses, so the app and the consumer exercise one artifact — not an original and a mirror that happen to agree.
5. **No behavior change.** Card rendering, note rendering, the markdown editor toolbar, list-continuation authoring, and edit-session blur/save semantics behave exactly as they do today. This change is structural.
6. **Recurrence is visible.** Re-introducing a second copy fails a gate rather than passing quietly.

### Solution

Extract the four files into a local package, `@worklists/markdown-kit`, living at `WorkLists/packages/markdown-kit/`, owned by WorkLists. Serve it to the browser from a dedicated Express static mount, load it in `index.html` through that mount, and have Cairn consume it as a `file:` dependency — exactly the arrangement Cairn already uses for `@cairn/dantalion` (`"@cairn/dantalion": "file:../Dantalion"`). npm links a `file:` directory dependency rather than copying it, so Cairn's `node_modules` entry resolves to the one authored copy. Cairn's `vendor/` directory and its parity gate are then deleted, because there is no longer a second copy for them to police.

**The file contents do not change.** The four files keep their UMD wrappers byte-for-byte. That wrapper is the compatibility contract — it is what lets the same file serve four different consumption modes (browser `<script>`, Node `require`, ESM side-effect `import`, worker `importScripts`). Converting to ESM would break all four. Move, do not rewrite.

## Locked decisions

- **Owner:** WorkLists. The package lives inside the WorkLists repository.
- **Package name:** `@worklists/markdown-kit`. Overridable — one-line change, no structural impact.
- **File contents:** byte-identical to the current `public/` originals. Verified by hash in acceptance. Any content change is out of scope for this ticket.
- **Module format:** UMD preserved. No ESM conversion, no bundler, no build step.
- **Filenames:** kebab-case inside the package (`markdown-renderer.js`), matching Cairn's vendor naming and Dantalion's convention. Contents unchanged; only the name and location move.
- **Browser URL:** `/markdown-kit/<file>.js`, from an Express static mount on the package's `src/` directory. `src/` does not appear in the URL.
- **Load order:** `markdown-renderer.js` must load before `markdown-editor.js` (`markdownEditor.js:27-30` resolves `MarkdownRenderer` from the global scope), and both before `todolist2.js`.
- **Cairn history:** `Architecture/Phase*Evidence.md` and `Architecture/briefs/*` reference `vendor/markdown-renderer.js` as historical record. **Leave them unchanged** — they accurately describe what was true when written. Only executable references migrate.
- **Scope of the Cairn work:** included and required. Moving the WorkLists originals breaks `check-vendor-parity.mjs` by construction — it would report `UNVERIFIABLE` and fail `npm run verify` on the next run. The two sides ship together.

## 1. Folder hierarchy

New and modified paths in **WorkLists**:

```text
WorkLists/
  packages/
    markdown-kit/
      package.json                    # NEW - name, version, exports map, files
      README.md                       # NEW - interface, consumption, one-copy rule
      index.js                        # NEW - ESM entry, side-effect imports + namespace re-export
      src/
        markdown-renderer.js          # MOVED from public/markdownRenderer.js (bytes unchanged)
        markdown-authoring.js         # MOVED from public/markdownAuthoring.js (bytes unchanged)
        edit-session.js               # MOVED from public/editSession.js (bytes unchanged)
        markdown-editor.js            # MOVED from public/markdownEditor.js (bytes unchanged)
  public/
    index.html                        # script srcs -> /markdown-kit/*, load order preserved
    markdownRenderer.js               # DELETED
    markdownEditor.js                 # DELETED
    markdownAuthoring.js              # DELETED
    editSession.js                    # DELETED
  server.js                           # add static mount for the package src/
  package.json                        # add @worklists/markdown-kit as a file: dependency
  tests/
    markdown-renderer.test.js         # update require path + index.html load-order assertion
    markdown-editor.test.js           # update require path
    markdown-authoring.test.js        # update require path
    edit-session.test.js              # update require path
    markdown-kit-package.test.js      # NEW - boundary, hash parity, no-duplicate guard
```

Modified paths in **Cairn** (companion):

```text
Cairn/
  package.json                        # add @worklists/markdown-kit file: dep; drop vendor:check script
  vendor/                             # DELETED (all four files)
  tools/
    check-vendor-parity.mjs           # DELETED - superseded by dependency resolution
    verify.mjs                        # remove gate 6 (vendor:check); add package-resolution gate
    serve.mjs                         # serve the package for probe/worker URLs
  components/
    markdown-renderer/index.js        # import "../../vendor/..." -> "@worklists/markdown-kit/renderer"
    document-owner/index.js:24        # same
  Architecture/probes/
    worker-render.js:2                # importScripts("/vendor/...") -> importScripts("/markdown-kit/...")
    probe.mjs:16                      # vendor/ path special-case -> package path
```

Ticket artifacts:

```text
c:\dustin-thomason\docs\WorkLists\tickets\markdown-kit-package-extraction\
  specs\
    markdown-kit-package-extraction-spec.md
```

## 2. Package interface

`packages/markdown-kit/package.json`:

```json
{
  "name": "@worklists/markdown-kit",
  "version": "1.0.0",
  "private": true,
  "description": "Markdown rendering, editing, authoring, and edit-session primitives authored by WorkLists. One authored copy - consumers depend on it, they do not copy it.",
  "main": "index.js",
  "exports": {
    ".": "./index.js",
    "./renderer": "./src/markdown-renderer.js",
    "./editor": "./src/markdown-editor.js",
    "./authoring": "./src/markdown-authoring.js",
    "./edit-session": "./src/edit-session.js",
    "./package.json": "./package.json"
  },
  "files": ["index.js", "src", "README.md"]
}
```

The `exports` map is the declared public surface required by Requirement 2. Subpaths not listed are unreachable, so a future consumer cannot quietly deep-link one internal file.

Modules and their exported members (unchanged from today):

| Subpath         | Global set (browser) | Exported members                                                                                                             | Depends on                     | Touches DOM                          |
| --------------- | -------------------- | ---------------------------------------------------------------------------------------------------------------------------- | ------------------------------ | ------------------------------------ |
| `./renderer`    | `MarkdownRenderer`   | `escapeHtml`, `linkifyText`, `normalizeLinkHref`, `renderInlineMarkdown`, `renderTaskMarkdown`, `updateTaskCheckboxMarkdown`   | none                           | no                                   |
| `./authoring`   | `MarkdownAuthoring`  | `getLineRange`, `getListItemParts`, `getNextMarker`, `handleListBackspace`, `handleListEnter`, `handleMarkdownTextareaKeydown` | none                           | no                                   |
| `./edit-session`| `EditSession`        | `createEditSessionManager`, `normalizeTaskId`, `shouldSaveOnBlur`, `suppressBlurSave`                                          | none                           | reads passed-in textarea only        |
| `./editor`      | `MarkdownEditor`     | `TOOLBAR_ITEMS`, `createEditorController`, `htmlToMarkdown`, `insertSyntax`, `populateToolbar`, `renderMarkdownForVisual`, `renderMarkdownSafe`, `visualFormatAction` | `MarkdownRenderer` (ambient global) | yes — `createElement`, `execCommand`, Font Awesome classes |

`index.js` performs the four side-effect imports in dependency order and re-exports the namespaces for ESM and Node consumers. It is the only new executable file in the package.

### Known internal coupling (carried forward, not fixed here)

`markdown-editor.js` resolves its renderer dependency through ambient global lookup (`markdownEditor.js:27-30`), falling back to `null`. Under the package this still works — `index.js` and the `<script>` order both guarantee the renderer is present first. Converting that lookup to an explicit injected dependency is a **separate ticket**; doing it here would change file bytes and forfeit the hash-parity acceptance proof that makes this change safe.

## 3. Server wiring

`server.js` gains one static mount, placed alongside the existing `public/` mount:

```js
app.use("/markdown-kit", express.static(path.join(__dirname, "packages", "markdown-kit", "src")));
```

`public/index.html` script tags change location only; relative order is preserved:

| Line (current) | From                  | To                                  |
| -------------- | --------------------- | ----------------------------------- |
| 352            | `editSession.js`      | `/markdown-kit/edit-session.js`     |
| 361            | `markdownRenderer.js` | `/markdown-kit/markdown-renderer.js`|
| 362            | `markdownAuthoring.js`| `/markdown-kit/markdown-authoring.js`|
| 364            | `markdownEditor.js`   | `/markdown-kit/markdown-editor.js`  |

`WorkLists/package.json` adds:

```json
"@worklists/markdown-kit": "file:./packages/markdown-kit"
```

This makes the app's own Node tests resolve the package by name rather than by relative path, satisfying Requirement 4 — the app and Cairn reach the code the same way.

## 4. Cairn consumption

`Cairn/package.json`:

```json
"dependencies": {
  "@cairn/dantalion": "file:../Dantalion",
  "@worklists/markdown-kit": "file:../../SCRIPTS ALL SYSTEMS/To Do List/WorkLists/packages/markdown-kit"
}
```

npm links (does not copy) a `file:` directory dependency, so `node_modules/@worklists/markdown-kit` resolves to the single authored copy. There is no second copy left to drift, which is why `check-vendor-parity.mjs` is deleted rather than retargeted.

Source changes:

- `components/markdown-renderer/index.js` — `import "../../vendor/markdown-renderer.js"` becomes `import "@worklists/markdown-kit/renderer"`. The file remains UMD, so the side-effect import still sets `globalThis.MarkdownRenderer`; the surrounding comment explaining why it is UMD stays accurate and should be updated only to name the package instead of `vendor/`.
- `components/document-owner/index.js:24` — same substitution.
- `Architecture/probes/worker-render.js:2` — `importScripts("/vendor/markdown-renderer.js")` becomes `importScripts("/markdown-kit/markdown-renderer.js")`, with `tools/serve.mjs` mounting the package `src/` at that URL.
- `Architecture/probes/probe.mjs:16` — the `rel.startsWith("vendor/")` base-path special case is retargeted to the package location.

### Residual risk: the relative path

The `file:` specifier crosses two OneDrive subtrees and contains spaces. It is **relative and declared**, which is strictly better than today's hard-coded absolute string in a script, but it still assumes Cairn and WorkLists share a common parent. If that assumption breaks, the failure is a loud `npm install` resolution error rather than a silent stale copy — an acceptable trade, and the reason this is recorded as a risk rather than treated as solved.

## 5–8. Entities, migrations, DTOs, projections

**N/A — no persistence involved.** This ticket moves four browser-side UMD files and changes static-asset wiring. No entity, table, column, migration, DTO, or projection is created, modified, or read. Surfaces checked and confirmed unchanged: `dal.js` (no reference to any of the four modules), `data/` schema files, and `WorkBoardDB.backup.json` shape.

## HTTP surface

**Static-asset routing only; no API contract change.** One new static mount (`/markdown-kit/*`) is added; four previously-served `public/*.js` URLs are removed. Surfaces checked and confirmed unchanged: every path in `openapi.js`, all request/response schemas, and all status codes. `openapi.js` describes the JSON API and does not document static asset URLs, so it requires no edit. This was verified by inspection rather than inferred from the change being "internal".

## Spec tests

### Happy path

- Each of the four modules loads from `/markdown-kit/<name>.js` and sets its expected global.
- `tests/markdown-renderer.test.js`, `markdown-editor.test.js`, `markdown-authoring.test.js`, and `edit-session.test.js` pass **with assertions unchanged** — only their `require` paths move to `@worklists/markdown-kit/<subpath>`. An assertion that had to change to stay green would mean behavior moved, which this ticket forbids.
- `tests/browser-notes-smoke.js` passes: notes render markdown, the editor toolbar populates, list continuation works on Enter, and blur-save fires.

### Move-not-rewrite proof (the core assertion of this ticket)

`tests/markdown-kit-package.test.js` asserts each packaged file hashes to the recorded pre-move value:

| Packaged file               | Expected md5                       |
| --------------------------- | ---------------------------------- |
| `src/markdown-renderer.js`  | `3ef87f42c004b2f50e01dc67acb53fab` |
| `src/markdown-editor.js`    | `55fbc26a666e0d3ad01a9c8b3e7247d3` |
| `src/markdown-authoring.js` | `2aa710a6ed2a6ce0f8e748f9b5d2312e` |
| `src/edit-session.js`       | `82ac6782d99562c6d612ba76df0d565e` |

Implementation should also record sha256 for each file at move time and assert on that; the md5 values above are the ones actually measured on 2026-08-27 and are the baseline this spec commits to. This test is what converts "we only moved it" from a claim into a check.

### Failure paths

- A packaged file missing from the mount returns 404 and produces a visible script error. Note: `markdownEditor.js`'s `getMarkdownRenderer()` returns `null` on absence rather than throwing, so a missing renderer degrades quietly today. That behavior is **pre-existing and unchanged**; it is recorded here as a known gap, not introduced by this ticket.
- Cairn's `npm install` fails loudly if the `file:` path does not resolve. Assert the failure is a resolution error, not a silent skip.

### Edge cases

- **Load order.** `tests/markdown-renderer.test.js:212-213` currently asserts `index.html` contains `markdownRenderer.js` before `todolist2.js`. Retarget it to the new URLs and extend it to assert `markdown-renderer.js` precedes `markdown-editor.js`, which is the ordering the ambient global dependency actually requires.
- **Node vs browser.** The UMD `module.exports` branch is exercised by the Node suites; the `root.X = factory()` branch by the browser smoke test. Both must remain covered.

### Anti-recurrence (Requirement 6)

- `tests/markdown-kit-package.test.js` fails if any of `markdownRenderer.js`, `markdownEditor.js`, `markdownAuthoring.js`, or `editSession.js` reappears in `public/`.
- The same test fails if a packaged file's content is duplicated anywhere else in the WorkLists tree outside `packages/markdown-kit/`.
- Cairn's `tools/verify.mjs` replaces the deleted `vendor:check` gate with a resolution gate: `@worklists/markdown-kit` resolves, **and** no `vendor/` directory exists. A reappearing `vendor/` fails the build. This preserves the intent of the gate Cairn built — recurrence produces a failure, not a quiet pass — while removing the copy it was policing.
- `packages/markdown-kit/README.md` states the one-copy rule explicitly, so the next consumer reads the constraint before choosing how to obtain the code.

### Regression impact

Not isolated — this touches shared infrastructure in two repositories, so regression coverage is required rather than waived. Affected surfaces and their guards:

| Surface                                                                                              | Risk                             | Guard                                    |
| ---------------------------------------------------------------------------------------------------- | -------------------------------- | ---------------------------------------- |
| `public/todolist2.js` (8 `MarkdownRenderer` refs: `:694`, `:753`, `:763`, `:10662`, `:10704`, `:15369`)| global unset if load order breaks| load-order assertion + browser smoke     |
| `public/index.html` script graph                                                                      | wrong URL, 404                   | happy-path load test                     |
| Cairn `components/markdown-renderer`                                                                  | import path break                | Cairn `test:standalone`, `test:kernel`   |
| Cairn `components/document-owner`                                                                     | import path break                | Cairn `test:file-operations`             |
| Cairn probes / worker                                                                                 | `importScripts` URL break        | Cairn probe run                          |
| Cairn `tools/verify.mjs`                                                                              | gate 6 removed                   | full `npm run verify` green end to end   |

## Cross-cutting

- **Precedent:** `@cairn/dantalion` — "the reusable browser document surface extracted from Cairn… Cairn consumes the local published package through its `file:` dependency during this phase." This ticket applies the same pattern in the opposite direction, with WorkLists as the extracting owner.
- **Tooling gates:** WorkLists — `npm run lint` (`prettier --check .`) must cover the new `packages/` tree; confirm `.prettierignore` does not exclude it. `npm test` (`node --test "tests/*.test.js"`) must stay green. `npm audit --audit-level=high` applies. Cairn — full `npm run verify` must pass with the gate list changed.
- **Changelog:** append a session entry to `docs/WorkLists/worklists-app-changelog.md` before commit. The changelog currently has no entry mentioning Cairn, Dantalion, or the vendored copies — this ticket is the first record of that relationship and should say so.
- **Complexity:** Medium. The move itself is mechanical and hash-verifiable; the cost sits in the Cairn migration and in retiring a verification gate without losing what it guaranteed.
- **Estimate band:** Medium — one focused session per repository, sequenced WorkLists first.

## Sequencing

The two repositories must land in order, because the WorkLists move breaks Cairn's gate the moment it happens.

1. Create the package, move the four files, verify hashes match the recorded baseline.
2. Wire the WorkLists server mount, `index.html`, and `package.json`; retarget the four test suites; add `markdown-kit-package.test.js`. Full WorkLists suite green.
3. Cairn: add the `file:` dependency, retarget the two component imports and the probe URLs, delete `vendor/` and `check-vendor-parity.mjs`, replace gate 6 with the resolution gate. Full `npm run verify` green.
4. Commit each repository separately with its own session log entry.

Do not delete Cairn's `vendor/` before step 3 wires the replacement — between steps 2 and 3 Cairn is knowingly red, and that window should be closed in one sitting.

## Open questions

| #   | Question                                                                                                       | Owner | Default if unanswered                                            |
| --- | -------------------------------------------------------------------------------------------------------------- | ----- | ---------------------------------------------------------------- |
| 1   | Package name — `@worklists/markdown-kit`?                                                                       | user  | proceed with `@worklists/markdown-kit`                            |
| 2   | Should the package instead live at `PDProjects/` beside Dantalion, making WorkLists and Cairn peer consumers?    | user  | no — "implement it properly within the app" locks WorkLists owner |
| 3   | Add a Dantalion-style `INTERFACE.md` per module, or is the `exports` map plus README sufficient?                 | user  | README + `exports` map only                                       |
