# Blueprint: Unified File Management Layer for Personal Kanban

> **Status:** Concept / Future Feature
> **Author:** (you)
> **Last updated:** 2026-07-09
> **Context:** Turning the existing self-built Kanban board into a central filing system that points to files stored across multiple cloud providers, rather than storing everything in one place (e.g. a GitHub repo).

---

## 1. Problem Statement

Work artifacts are currently scattered across disparate systems: OneNote, GitHub, OneDrive, Box, transcripts, screenshots, docs, and links. Consolidating *everything* into a single GitHub repo is tempting but breaks down because Git is not designed for large binary/media storage.

**Goal:** One central place to *discover and organize* everything, without forcing all the *actual files* to physically live in one system.

---

## 2. Core Concept

Use the existing Kanban board as a **metadata + pointer layer**, not a storage layer. Files stay where they belong; the Kanban holds lightweight references to them.

```
Kanban Board (central hub + filing system)
    |
    +-- Card: "Project X Docs"
    |     +-- Pointer -> Box:/Project-X/design.pdf
    |     +-- Pointer -> OneDrive:/Screenshots/flow-diagram.png
    |     +-- Pointer -> GitHub:/repo/architecture.md
    |
    +-- Card: "Meeting Notes - Q3"
          +-- Pointer -> Box:/Notes/transcript.txt
          +-- Pointer -> OneDrive:/Meetings/2026-07-09.docx
```

### Why this works
- Kanban stays lightweight (just metadata/pointers).
- Files live where they belong (Box, OneDrive, GitHub).
- Single discovery point (the Kanban board).
- No repo bloat; Git performance and version control stay intact.
- Not locked into a single provider.

---

## 3. Why NOT "everything in one GitHub repo"

Reference limits that drove this decision:

| Constraint | Limit |
|---|---|
| Individual file hard limit | 100 MB (rejected above this) |
| Individual file soft warning | 50 MB |
| Repo soft recommendation | < 1 GB |
| Repo warning / slowdown threshold | ~5 GB+ |
| Practical pain (clone/push/status lag) | 10 GB+ |

Screenshots and media add up fast; storing them in Git bloats the repo and undermines the value of version control. Text/Markdown belongs in the repo; binaries and media belong in cloud storage.

**Division of responsibility:**
- **GitHub repo** = code + Markdown docs + index files + links
- **Cloud storage (Box / OneDrive)** = actual files (screenshots, media, large docs)
- **Kanban** = central filing system + task tracking + pointers tying it together

---

## 4. Design Decisions To Resolve

### 4.1 Pointer format
Decide on a consistent scheme for references. Options:
- **Provider-scheme URI:** `box://project-x/design.pdf`, `onedrive://Screenshots/flow.png`
- **Full URLs:** `https://app.box.com/f/abc123`
- **Structured metadata (recommended for extensibility):**

```json
{
  "provider": "box",
  "path": "/Project-X/design.pdf",
  "url": "https://app.box.com/f/abc123",
  "size_bytes": 2048576,
  "last_modified": "2026-07-01T14:22:00Z",
  "linked_card": "project-x-docs"
}
```

### 4.2 Where metadata lives
- In the Kanban card itself (custom fields / attributes)
- In a JSON/CSV index file inside the GitHub repo
- In the card description (simplest, least structured)

### 4.3 Integration depth
Progressive levels — pick a starting point, grow later:
1. **Simple links** — click a pointer, it opens the file in the provider. (MVP)
2. **API-enriched** — fetch previews, file size, last-modified from the provider.
3. **Bi-directional sync** — file changes reflect back into the Kanban state.

### 4.4 Provider abstraction
Design a provider-agnostic interface so Box/OneDrive/GitHub/local are all just "storage backends." Avoid coupling the core system to any single provider's API. This makes swapping or adding providers later cheap.

```
StorageProvider (interface)
    - resolve(pointer) -> file metadata
    - open(pointer) -> URL / stream
    - list(path) -> entries
        |
        +-- BoxProvider
        +-- OneDriveProvider
        +-- GitHubProvider
        +-- LocalProvider
```

---

## 5. Suggested Recommended Architecture (target state)

- **GitHub repo:** code, code-related docs, architecture decisions, Markdown notes, the pointer index.
- **GitHub Issues/Discussions (optional):** active work threads, if not fully covered by the Kanban.
- **Cloud storage (Box / OneDrive):** actual binary files — screenshots, media, large PDFs/docs. OneDrive continues to serve as the cross-device sync mechanism.
- **Kanban board:** central hub — task tracking + filing system + pointers to everything above.

---

## 6. Open Questions

- How much effort to invest in cloud provider API integration vs. starting with simple links?
- Should the metadata index be the source of truth, or the Kanban board?
- How to handle a file that moves or is renamed in the provider (broken-pointer detection)?
- Do you want offline discoverability (index cached locally) or is online-only acceptable?
- Versioning of *pointers* — do you care about history of what was linked where?

---

## 7. Suggested Phasing

1. **Phase 1 (MVP):** Add a "linked files" field to Kanban cards accepting full URLs. Manual entry. No API.
2. **Phase 2:** Define the structured pointer format + a JSON index in the repo.
3. **Phase 3:** Build the `StorageProvider` abstraction; implement one provider (start with whichever you use most — likely OneDrive or Box).
4. **Phase 4:** API enrichment — previews, sizes, last-modified, broken-link detection.
5. **Phase 5 (optional):** Bi-directional sync.

---

*This document is a living blueprint. Update as decisions are made.*
