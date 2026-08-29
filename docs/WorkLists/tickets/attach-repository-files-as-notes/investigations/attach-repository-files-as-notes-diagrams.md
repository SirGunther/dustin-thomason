# Diagrams — WorkLists/attach-repository-files-as-notes

Companion to [the investigation report](./attach-repository-files-as-notes-investigation.md) §5 and §7. Baseline commit `06b78be`.

Every diagram below shows the **recommended** design (server-resolved root). If open variable 1 resolves the other way, diagrams 2–4 change materially and this file is superseded rather than edited.

---

## 1. Current vs. target — where a note's content comes from

The whole ticket is this one difference.

```mermaid
flowchart LR
  subgraph CUR["Current — one source, unbranched"]
    C1["data/event-notes.json<br/>{noteId, eventId, text}"] --> C2["GET /api/notes"]
    C2 --> C3["createNoteItem<br/>dataset.rawText = note.text"]
    C3 --> C4["Dantalion surface"]
    C4 -->|save| C5["saveNoteInlineEditor"]
    C5 --> C6["PUT /api/notes/:id<br/>writes note.text"]
    C6 --> C1
  end

  subgraph TGT["Target — the same path, with one branch"]
    T1["data/event-notes.json<br/>{noteId, eventId, text, source?}"] --> T2["GET /api/notes"]
    T2 --> T3{"note.source<br/>present?"}
    T3 -->|no| T4["dataset.rawText = note.text<br/><i>unchanged behaviour</i>"]
    T3 -->|yes| T5["GET /api/files/read<br/>→ file bytes + mtime"]
    T5 --> T4
    T4 --> T6["Dantalion surface"]
    T6 -->|save| T7{"note.source<br/>present?"}
    T7 -->|no| T8["PUT /api/notes/:id"]
    T7 -->|yes| T9["PUT /api/files/write<br/>+ expected mtime"]
    T8 --> T1
    T9 --> T10[("the file on disk")]
    T5 -.reads.-> T10
  end
```

**What to read from it:** the two diamonds are the entire change on the note path. Everything else — the surface, the fetch, the record — is untouched. A note without a `source` traverses exactly the path it traverses today, which is what makes the change additive and what makes "protect the neighbours" (report §7) checkable rather than hopeful.

---

## 2. The authority boundary — target only

```mermaid
flowchart TB
  B["Browser<br/>public/todolist2.js"] -->|"/api/files/*<br/>repo-relative path only"| S["Express<br/>server.js"]
  S --> G{"containment check"}
  G -->|"resolve against root"| G1["reject: .. / absolute / UNC / backslash / empty segment"]
  G -->|"fs.realpath"| G2["reject: symlink resolving outside the root"]
  G -->|"bounds"| G3["reject: over size / depth / count limit"]
  G -->|"passes all three"| OK[("file under the repository root")]

  R["repository root<br/><i>server-stored setting</i>"] -.defines.-> G
  D[("DATA_DIR<br/>the app's own data")] -.must not nest with.-> R

  X["anything outside the root"] -.->|"unreachable by construction"| G

  style G fill:#2d4a5a,stroke:#7fb3d5,color:#fff
  style X stroke-dasharray: 4 4
```

**What to read from it:** there is exactly **one** chokepoint, and it does three independent jobs. The third (`realpath`) is the one Cairn never needed — a `FileSystemDirectoryHandle` cannot be traversed upward at all, whereas a Node path can be walked out of via a symlink. That asymmetry is why the path rules port but the security model does not port unchanged.

---

## 3. Attach flow — from the ellipsis to a rendered note

```mermaid
sequenceDiagram
  actor U as User
  participant M as Card ellipsis<br/>(extraActions seam)
  participant P as Picker
  participant S as Server
  participant N as Notes API
  participant L as Notes list

  U->>M: open ellipsis
  alt no root configured
    M-->>U: item absent / disabled, reason stated
  else root configured
    M-->>U: "Attach document"
    U->>M: choose it
    M->>S: GET /api/files/list
    S-->>M: Markdown files under the root
    M->>P: show them
    U->>P: pick notes/spec.md
    P->>N: POST /api/notes {eventId, source}
    alt already attached to this card
      N-->>U: refused, told plainly, no second row
    else new
      N-->>L: note record with a source
      L->>S: GET /api/files/read
      alt file present
        S-->>L: bytes + mtime
        L-->>U: renders through the same surface as every other note
      else file missing
        S-->>L: not-found
        L-->>U: says it cannot be found — not a blank
      end
    end
  end
```

**What to read from it:** the only genuinely new interaction is the picker. The refusal branches are the story-02 criteria that are easiest to leave out and hardest to notice missing — an already-attached duplicate, and a file that has since moved.

---

## 4. Save with the concurrency precondition

```mermaid
sequenceDiagram
  participant E as Surface (editor)
  participant C as Client
  participant S as Server
  participant F as File on disk

  Note over C: mtime captured at read time
  E->>C: save
  C->>S: PUT /api/files/write {path, text, expectedMtime}
  S->>F: stat
  alt mtime matches
    S->>F: write
    F-->>S: new mtime
    S-->>C: 200 + new mtime
    C-->>E: accept(key, revision, markdown)
  else mtime differs
    S-->>C: 409 + current mtime
    C-->>E: told before overwriting — draft retained
  else unwritable
    S-->>C: named reason (read-only / gone / permission)
    C-->>E: reason shown — draft retained
  end
```

**What to read from it:** this is not a new pattern. `PATCH /api/notes/:noteId` already does exactly this shape with `expectedLastModified` → `409` (`server.js:2896-2920`), and `tests/note-checklist-patch.test.js` already exercises it. The file version substitutes mtime for `lastModified` and changes nothing else — which is the reason to mirror it rather than invent one.

---

## 5. Cairn's permission process vs. the recommended one

Side by side, because the difference is the report's reframe (§1) and it is easier to see than to read.

```mermaid
flowchart TB
  subgraph CA["Cairn — no server exists"]
    CA1["user gesture"] --> CA2["showDirectoryPicker()<br/><i>main thread only</i>"]
    CA2 --> CA3["kernel grant → worker<br/><i>local ref dropped same statement</i>"]
    CA3 --> CA4[("IndexedDB<br/>localStorage absent in a worker")]
    CA4 -->|"on reload"| CA5["queryPermission()"]
    CA5 -->|"not granted"| CA6["vault.permission-required<br/>→ needs a new gesture"]
    CA5 -->|granted| CA7["read the folder"]
  end

  subgraph WL["WorkLists — a server already has the authority"]
    WL1["Settings tab"] --> WL2["absolute path, validated"]
    WL2 --> WL3[("server-stored setting")]
    WL3 -->|"every request"| WL4["resolve + realpath containment"]
    WL4 --> WL5["read / write the file"]
  end
```

**What to read from it:** the left column's four middle boxes all exist to hold an OS grant somewhere a browser tab can keep it. The right column has no equivalent because the authority never left the machine. What *is* common — one root, granted once, everything under it reachable, nothing outside it, failures named from a closed vocabulary — is the part worth porting, and it ports intact.

---

## 6. Kinds not drawn

- **State machine — N/A.** Nothing here has states beyond present/absent; a diagram would restate diagram 1.
- **ER / schema diagram — N/A.** One optional field on one existing record. Report §7 states it in a sentence, which is shorter and no less clear.
- **Deployment / infrastructure — N/A.** Single local process; nothing deploys.
- **Race-condition timing diagram — deliberately deferred.** The one real race (two places editing the same file) is covered by diagram 4's `409` branch. A timing diagram becomes worth drawing only if open variable 9 (live refresh while the file changes on disk) resolves to yes, which would add a genuine watcher-versus-editor interleaving.
