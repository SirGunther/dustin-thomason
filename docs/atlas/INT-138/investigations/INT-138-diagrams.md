# Diagrams — atlas/INT-138

> Companion to [INT-138-investigation.md](./INT-138-investigation.md). Each diagram states the question it answers. **Render check:** no Mermaid renderer is installed on this machine, so these were hand-checked against the gotchas in `agents/docs/current-vs-target-diagram.md` (no colons in edge labels, quoted node labels, no raw angle brackets, `<br/>` breaks, and no pipes inside labels) rather than machine-rendered. Re-check in a Mermaid preview before quoting a diagram in a spec or PR.

## Current vs target

**Question:** for each path that writes a file's categorization, what reaches the Europa audit log today, what reaches it after this ticket, and which parts do not change?

Target nodes for A and B/C depend on D1. The diagram shows the recommended D1 (A, B/C and D emit; E, F and G unchanged). The literal is shown as `CATEGORIZED` pending D2.

```mermaid
flowchart LR
  classDef current fill:#ffe3e3,stroke:#c92a2a,color:#3b0a0a
  classDef delta   fill:#d0ebff,stroke:#1c7ed6,color:#0b2545
  classDef shared  fill:#f1f3f5,stroke:#868e96,color:#212529
  classDef ok      fill:#d3f9d8,stroke:#2f9e44,color:#102015

  subgraph SG_CALLISTO["callisto-back-end - write paths and audit emit"]
    direction TB
    BE_A["A upload-complete - 1 file"]
    BE_BC["B/C approve v1 and v2 - many files"]
    BE_D["D recategorize - many files"]
    BE_EFG["E unapprove / F transcript summary / G legacy approve"]
    BE_A_CUR["CURRENT: CREATED only<br/>state has path, bucket, fileName<br/>no type, no collection"]
    BE_BC_CUR["CURRENT: APPROVED per file<br/>no type, no collection"]
    BE_D_CUR["CURRENT: no audit at all<br/>Dione outbox row only"]
    BE_NEW["TARGET: new CATEGORIZED event per file<br/>after the TS returns<br/>newState.path = Filepath / Deliverable Type / Collection or N/A<br/>oldState = prior categorization"]
    BE_EFG_KEEP["UNCHANGED: UNAPPROVED / none / APPROVED"]
  end

  subgraph SG_EUROPA["europa-back-end - UNCHANGED"]
    direction TB
    EU_STORE["SQS listener saves raw JSON<br/>type is a free string - no enum"]
    EU_READ["search-paginated<br/>exact-match type filter<br/>path = newState.path first<br/>shows resource 0 only"]
  end

  subgraph SG_ATLAS["atlas-front-end - Europa audit page"]
    direction TB
    FE_CUR["CURRENT: eventTypes list has no categorize literal<br/>path shown as one line for non-permission types"]
    FE_NEW["TARGET: literal added to eventTypes plus chip colour<br/>path split into bold-labelled lines for the new type"]
    FE_OK["Ops filters Event Type and sees one row per file<br/>who, when, file, type, collection"]
  end

  BE_A --> BE_A_CUR --> EU_STORE
  BE_BC --> BE_BC_CUR --> EU_STORE
  BE_D --> BE_D_CUR
  BE_A --> BE_NEW
  BE_BC --> BE_NEW
  BE_D --> BE_NEW
  BE_NEW --> EU_STORE
  BE_EFG --> BE_EFG_KEEP --> EU_STORE
  EU_STORE --> EU_READ
  EU_READ --> FE_CUR
  EU_READ --> FE_NEW --> FE_OK

  class BE_A_CUR,BE_BC_CUR,BE_D_CUR,FE_CUR current
  class BE_NEW,FE_NEW delta
  class BE_A,BE_BC,BE_D,BE_EFG,BE_EFG_KEEP,EU_STORE,EU_READ shared
  class FE_OK ok

  style SG_CALLISTO fill:#e8f7ed,stroke:#2f9e44,color:#102015
  style SG_EUROPA   fill:#f1f3f5,stroke:#868e96,color:#212529
  style SG_ATLAS    fill:#e7f0ff,stroke:#3867d6,color:#10203f
```

Reading it:
- The only red node with nothing downstream is **D**, the recategorize path that is silent today.
- Europa sits in a grey lane on both chains.
- Existing events (the red `CURRENT` nodes for A and B/C) keep flowing unchanged. The new event is added alongside them, not in place of them.

## Flows

**Question:** why does Europa need no change? How does one Categorize value travel from Callisto to the rendered cell?

```mermaid
flowchart TB
  classDef delta   fill:#d0ebff,stroke:#1c7ed6,color:#0b2545
  classDef shared  fill:#f1f3f5,stroke:#868e96,color:#212529
  classDef ok      fill:#d3f9d8,stroke:#2f9e44,color:#102015

  C1["Callisto converter builds one FILE resource<br/>newState.path = Filepath / Deliverable Type / Collection<br/>joined with space-pipe-space, label then colon-space"]
  C2["SQS message - raw JSON"]
  E1["Europa saves as-is<br/>oldState and newState are free-form objects"]
  E2["Europa projection<br/>not PERMISSIONS_UPDATED, so path = newState.path"]
  E3["Response item path - the same string, unmodified"]
  A1["Atlas path cell<br/>type matches the extended condition"]
  A2["Split on space-pipe-space, bold the text before colon-space<br/>colons inside a value are preserved"]
  A3["Three lines - Filepath / Deliverable Type / Collection"]

  C1 --> C2 --> E1 --> E2 --> E3 --> A1 --> A2 --> A3

  class C1,A1,A2 delta
  class C2,E1,E2,E3 shared
  class A3 ok
```

Safe separators: dynamic collection names reject both `|` and `:` (`validate-dynamic-collection-name.validator.ts:7`), and the seeded deliverable type names contain no pipe. The Planet Suite seed is still to be checked (coverage frontier).

## Sequences

**Question:** in what order do commit, audit dispatch and failure happen on recategorize? This shows why dispatching after the TS returns means a rollback can't produce an audit, and where a lost audit goes unnoticed.

```mermaid
sequenceDiagram
    participant U as Atlas user
    participant S as RecategorizeDeliverableFilesService
    participant T as RecategorizeDeliverableFilesTS (transactional)
    participant DB as Postgres file_attachments
    participant AG as ProceedingFileAuditAggregator
    participant Q as SQS audit queue
    participant EU as Europa listener and Mongo
    participant OPS as Ops on Europa page

    U->>S: PATCH recategorize-deliverable-files (N files)
    S->>T: apply(assembledData)
    T->>DB: setTrackCollectionAndType per unique attachment
    T->>DB: Dione outbox rows (GCA flag on only)
    T-->>S: processed files (commit done)
    Note over S,T: validation error or rollback - service never reaches dispatch, no audit
    loop once per processed file (TARGET)
        S->>AG: dispatchFileAuditCategorizedEvent
        AG->>Q: send one event with one FILE resource
        Q-->>AG: ok, or failure logged and false returned
    end
    Note over AG,Q: send failure is logged only, the request still succeeds (concern C2)
    S-->>U: 200 with processedFileIds (unchanged)
    Q->>EU: message consumed and saved as-is
    OPS->>EU: search-paginated with type set to the new literal
    EU-->>OPS: one row per file with the three-part path
```

Edge case this exposes: nothing re-sends a failed audit. Europa gets no record, and the user's request still succeeds. The existing CREATED, APPROVED and UNAPPROVED audits share this behavior, so it is accepted as-is and recorded as concern C2.
