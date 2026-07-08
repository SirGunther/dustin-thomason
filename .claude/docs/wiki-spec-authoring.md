# Wiki spec authoring (Callisto / Atlas)

Canonical conventions for PRDV epic/story specs and dev notes in the team **Obsidian wiki** (`systems/` tree). Technical spec sections 1–8 live in [spec-writing](../.cursor/rules/spec-writing.mdc); this doc covers naming, frontmatter, vault wiring, and dev notes.

Guided workflow: [write-spec](../.cursor/skills/write-spec/SKILL.md) skill. Ticket memory stays in `docs/<system>/PRDV-XXXXX-changelog.md`.

---

## File naming and folder conventions

### File naming

Spec filenames **must be prefixed with their PRDV ticket number**, followed by a dash and a short kebab-case description. All parts lowercase kebab-case — no spaces, camelCase, or underscores:

```
{PRDV-#####}-{short-kebab-description}.md
```

Examples:

- `PRDV-14699-display-client-deliverables.md`
- `PRDV-15738-story-2-set-track-and-collection-on-drag-and-drop-upload.md`

Apply the prefix at the file level; folder names do not need the ticket prefix.

### Folder structure

Each epic gets its own folder, named in kebab-case after the epic. Story specs for that epic live directly inside:

```
systems/
  {platform}/
    {feature-folder}/
      epics/
        {epic-kebab-name}/
          {PRDV-#####}-{story-description}.md
          {PRDV-#####}-{story-description}.md
```

Story files are never placed at the top level alongside epic folders.

---

## Spec frontmatter (required on every spec)

Every spec — epic or story — opens with YAML frontmatter:

```yaml
---
ticket: PRDV-#####
tags: [system-name, feature-area]
author: Firstname Lastname
created: YYYY-MM-DD
modified: YYYY-MM-DD
modified_by: Firstname Lastname   # omit if file has never been modified
---
```

Rules:

- `tags` — lowercase kebab-case array for Obsidian graph filtering. Always include the platform (`neptune`, `nova`, `saturn`) and at least one feature tag.
- `author` — person who first wrote the spec.
- `created` — date first committed.
- `modified` — updated every edit; must match the actual edit date.
- `modified_by` — who made the most recent change. Omit on brand-new specs; required after first edit.
- When modifying a spec, update `modified` and `modified_by` — do not change `author`.

Dev notes use the same frontmatter. Include platform + feature tags + `dev-note`.

---

## Obsidian vault integration

Specs and dev notes are not done until wired into the graph — not only readable as standalone markdown.

### Checklist — every new or updated spec

1. **Frontmatter `tags`** — platform + at least one feature tag (e.g. `file-navigator`, `media-duration`, `pdf`).
2. **Index entry** — wiki-link line in `systems/README.md` under the correct platform section (create a subsection if needed).
3. **Wiki-links for internal vault paths** — `[[neptune/.../PRDV-#####-name]]` (no `.md` extension) for specs, dev notes, runbooks, patterns, companion tickets. Full URLs for ClickUp and external docs only.
4. **Cross-link companions** — parent epic, prerequisites, dev notes, follow-on tickets link to each other with wiki-links when practical.
5. **Dev note** — `{PRDV-#####}-dev-note.md` when estimation is needed; `dev-note` tag; spec ↔ dev note wiki-links; index in `systems/README.md`.

Do **not** add Obsidian plugins, change `.obsidian/` config, or create folder READMEs unless the team explicitly requests them.

### Tag examples

```yaml
# Story spec
tags: [neptune, media-duration, files, file-navigator]

# Dev note
tags: [neptune, media-duration, files, file-navigator, dev-note]
```

### Wiki-link examples

```markdown
**ClickUp:** [PRDV-9756](https://app.clickup.com/t/43227262/PRDV-9756)
**Dev note:** [[neptune/media-duration/PRDV-9756-dev-note]]
**Companion:** [[neptune/pdf-page-count/PRDV-9933-view-page-count-of-pdf-files]]
See [[runbooks/operations-critical-file-list]] for supported file types.
```

### Index entry example (`systems/README.md`)

```markdown
#### File length metadata (Atlas File Navigator)

- [[neptune/pdf-page-count/PRDV-9933-view-page-count-of-pdf-files]] — PDF page count
- [[neptune/media-duration/PRDV-9756-view-duration-of-media-files]] — Media duration
- [[neptune/media-duration/PRDV-9756-dev-note]] — Dev note (estimation)
```

---

## Dev note (estimation artifact)

Companion doc named `{PRDV-#####}-dev-note.md`. High-level only — enough for refinement, not a duplicate of the full spec.

Link to the full spec with a wiki-link. Add the dev note to `systems/README.md` when used for estimation.

### What we're building

One or two sentences. What the story delivers and where complexity lives.

### Dependencies

Epics or stories that must merge first.

### Backend

- **New endpoints** — method + route
- **New tables** — table name + one-line purpose
- **Modified tables** — table name + columns added/changed
- **New migrations** — count + DDL vs seed
- **New DTOs / projections** — request/response shape names
- **Registries / wiring** — anything that needs registration

### Frontend

- **New API call** — method + route
- **New components / composables** — name + one-line purpose
- **Modified components** — name + what changes
- **New specs** — count + scope

### Complexity flags

Short bullets on the riskiest or most uncertain pieces.

### Estimate

**Small / Medium / Large (X–Y points).** One sentence justifying it.

---

## Author checklist (before marking a spec complete)

- [ ] Frontmatter: `ticket`, `tags`, `author`, `created`, `modified` (+ `modified_by` if edited)
- [ ] All applicable [spec-writing](../.cursor/rules/spec-writing.mdc) sections filled or N/A with reason
- [ ] Problem → Requirement → Solution narrative (per [problem-requirement-solution](../.cursor/rules/problem-requirement-solution.mdc))
- [ ] Wiki-links to companion tickets, dev note, and runbooks (not relative paths)
- [ ] Entry added to `systems/README.md`
- [ ] Dev note created and indexed when the story needs estimation
- [ ] Changelog **Plans** row updated in `docs/<system>/PRDV-XXXXX-changelog.md` when ticket is active
