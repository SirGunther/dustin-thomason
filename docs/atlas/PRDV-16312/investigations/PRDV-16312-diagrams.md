# Diagrams — atlas/PRDV-16312

Companion to [PRDV-16312-investigation.md](./PRDV-16312-investigation.md) §5 and §9. Baseline `71ce3cbf` (callisto `main`).

## Current vs target

The delta is one injected dependency and one call. Everything dashed is what this ticket adds; everything solid exists today.

```mermaid
flowchart TD
    A["POST /upload-complete<br/>UploadCompleteDeliverableFileAction"] --> B["UploadCompleteDeliverableFileTransactionScript<br/>@Transactional()"]
    B --> C{"pendingDynamicCollectionName<br/>non-empty?"}
    C -->|yes| D["FindOrCreateDynamicCollectionAssembler<br/>returns {id, value}"]
    C -->|no| E["use params.deliverableCollectionId ?? null"]
    D --> F["4 validators<br/>collection/proceeding, type/collection,<br/>duplicate name, file exists"]
    E --> F
    F --> G["CreateDeliverableFileMapper"]
    G --> H["deliverableFileRepository.create(file)"]
    H --> I["COMMIT"]
    I --> J(["today: nothing downstream<br/>client cannot see the file"])

    H -.->|ADD| K["ClientAccessOutboxPort.write<br/>routeKey file.created.v1<br/>payload = 17 fields incl.<br/>deliverableCollectionId + Value"]
    K -.-> I
    I -.-> L["outbox_events row<br/>same transaction"]
    L -.-> M["dispatcher polls + publishes"]
    M -.-> N["RabbitMQ callisto.client-access.*"]
    N -.-> O["Dione: INSERT file row<br/>+ UPSERT dynamic collection<br/>from inline value"]
    O -.-> P(["client sees the file<br/>under track → collection → type"])

    style J fill:#fdd,stroke:#900
    style P fill:#dfd,stroke:#090
    style K stroke-dasharray: 5 5
```

**What the delta is not:** no second event, no new contract, no registry change, and no change to the assembler's return type. `CALLISTO_CLIENT_ACCESS_FILE_CREATED_V1` is already registered and `CLIENT_ACCESS_OUTBOX` is already provided and exported — it simply has no consumer yet.

## Flows

### The removed event, and where the ticket's second emission went

Why the ClickUp text asks for something that cannot be built, and what replaced it.

```mermaid
flowchart LR
    subgraph ASKED["ClickUp text (2026-07-20) — 2 events"]
        A1["file.created.v1<br/>always"]
        A2["collection.created.v1<br/>only if newly created"]
    end

    subgraph DESIGN["Design doc Q15 / Q21 — 1 event"]
        B1["file.created.v1<br/>always, carrying<br/>deliverableCollectionId +<br/>deliverableCollectionValue inline"]
    end

    subgraph BLOCKED["Why A2 cannot be emitted"]
        C1["registry has 7 contracts<br/>COLLECTION_CREATED absent"]
        C2["commit 31c81db4<br/>'Remove collection.created'"]
        C3["writer throws<br/>BadRequestException<br/>on unknown routeKey"]
    end

    A1 --> B1
    A2 -.->|"removed by design"| C2
    C2 --> C1
    C1 --> C3
    A2 -.->|"need satisfied by"| B1
    B1 --> D["Dione UPSERTs the collection<br/>from the inline value"]

    style A2 fill:#fdd,stroke:#900
    style B1 fill:#dfd,stroke:#090
```

### Collection-creation surfaces — three, only one in scope

Protect-the-neighbors set for any change to the assembler.

```mermaid
flowchart TD
    S1["upload-complete TS :41"] --> A["FindOrCreateDynamicCollectionAssembler"]
    S2["recategorize TS :46"] --> A
    S3["approve-v2 service :59"] --> T["FindOrCreateDynamicCollectionTS :23<br/>(thin passthrough — TS→TS is forbidden,<br/>service→TS is not)"]
    T --> A
    A --> R["deliverableCollectionRepository.saveDynamic<br/>(exactly one caller)"]

    S1 -.->|"PRDV-16312 — this ticket"| E1["file.created.v1"]
    S2 -.->|"PRDV-16314"| E2["file.recategorized.v1"]
    S3 -.->|"PRDV-16311"| E3["file.approved.v1"]

    style S1 fill:#dfd,stroke:#090
    style E1 fill:#dfd,stroke:#090
```

Completeness is closed by construction: `saveDynamic` has exactly one caller (the assembler), and the assembler has exactly three. Each of the other two carries the same inline collection fields under its own sibling ticket, so the class is covered — not by this ticket.

## Sequences

### Concurrent uploads of the same new collection name (the race)

This is the timing edge case where a created-vs-found conditional would have gone wrong — and the reason the inline design removes the hazard rather than handling it.

```mermaid
sequenceDiagram
    participant U1 as Upload A
    participant U2 as Upload B
    participant AS as Assembler
    participant DB as Postgres
    participant OB as outbox_events

    par two uploads, same collection name
        U1->>AS: apply({proceedingId, trackTypeId, value: "Volume III"})
        U2->>AS: apply({proceedingId, trackTypeId, value: "Volume III"})
    end

    AS->>DB: findDynamicByNameCaseInsensitive (A)
    DB-->>AS: null
    AS->>DB: findDynamicByNameCaseInsensitive (B)
    DB-->>AS: null

    AS->>DB: saveDynamic (A)
    DB-->>AS: row id=42 — CREATED
    AS->>DB: saveDynamic (B)
    DB-->>AS: 23505 unique_violation
    AS->>DB: re-select case-insensitively (B)
    DB-->>AS: winner id=42 — FOUND

    Note over AS: both branches return {id: 42, value: "Volume III"}<br/>only the created flag differs — and it is discarded

    AS-->>U1: {id: 42, value}
    AS-->>U2: {id: 42, value}
    U1->>OB: file.created.v1 (fileA, collectionId 42, value "Volume III")
    U2->>OB: file.created.v1 (fileB, collectionId 42, value "Volume III")

    Note over OB: exactly 2 events, 1 collection.<br/>Under the removed 2-event design this is<br/>where a duplicate or missing collection.created<br/>would have come from.
```

**Why this matters to the acceptance criteria.** Story 02 criterion 2 — *"does not make that grouping show up twice for the client"* — is satisfied here by Dione **upserting** on `deliverableCollectionId`, so two events naming collection 42 converge on one row. No ordering guarantee is needed (design Q18).

### Atomicity — a rejected upload must emit nothing

Proves story 01 criterion 5 and report §9's first negative path.

```mermaid
sequenceDiagram
    participant A as Action
    participant TS as TS @Transactional()
    participant V as Validators
    participant DB as Postgres
    participant OB as outbox_events

    A->>TS: apply(params)
    TS->>DB: BEGIN
    TS->>V: duplicate filename? type matches collection?
    V-->>TS: throw BadRequestException
    TS->>DB: ROLLBACK
    Note over DB,OB: no file row AND no outbox row —<br/>the outbox write is inside the same transaction<br/>(design Diagram 6), so it cannot escape
    TS-->>A: 400
```

Note the ordering that makes this hold: the emission is placed **after** `deliverableFileRepository.create(file)`, so a validator throw never reaches it, and a persist failure rolls back both writes together.

## N/A

- **Entity-relationship diagram** — N/A. No schema change: no new table, column, or migration. The existing `deliverable_collections`, `files`, and `file_attachments` shapes are read as-is, and `outbox_events` was created by PRDV-16293.
- **State-machine diagram** — N/A. No status field or lifecycle transition is introduced; `file.created` is a one-shot fact, not a state change.
- **Front-end interaction diagram** — N/A. Backend-only ticket; no Atlas surface changes, and the upload UI is untouched.
