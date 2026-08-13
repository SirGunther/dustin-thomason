# Diagrams — atlas/PRDV-16313

> Companion to [PRDV-16313-investigation.md](./PRDV-16313-investigation.md). Each diagram states what question it answers.

## Current vs target

**What this shows:** where the emission lands, why it cannot land where the spec says, and what stays frozen. The frozen lane is the whole argument — three HTTP surfaces share one transaction script, so the emit has to sit *above* it in a module that is allowed to depend downward.

```mermaid
flowchart TB
  classDef current fill:#ffe3e3,stroke:#c92a2a,color:#3b0a0a
  classDef delta   fill:#d0ebff,stroke:#1c7ed6,color:#0b2545
  classDef shared  fill:#f1f3f5,stroke:#868e96,color:#212529
  classDef ok      fill:#d3f9d8,stroke:#2f9e44,color:#102015

  subgraph SG_ROUTES["HTTP surfaces - three routes, one shared script"]
    direction TB
    R_A["A. PATCH granting-client-access/file/:fileId<br/>deliverable-validated - has AuthUser - audits<br/>THE TARGET"]
    R_BC["B. PATCH proceedings/file/:fileId - submission-validated<br/>C. PATCH ajsf/file/:fileId - NO validator, NO user, NO audit<br/>concern C1"]
  end

  subgraph SG_GCA["granting-client-access - where the change lands"]
    direction TB
    SVC_C["CURRENT DeliverableRenameService<br/>validator - aggregator - audit dispatch<br/>plain provider, NO transaction"]
    SVC_T["TARGET DeliverableRenameService<br/>captures the validator's returned context for proceedingId<br/>delegates to the assembler - audit still last and OUTSIDE"]
    ASM_T["TARGET RenameDeliverableFileAssembler<br/>provider wraps it in createTransactionalProxy<br/>skips the no-op, then writes the outbox row"]
    CONV_T["TARGET FileRenamedToOutboxDataConverter<br/>returns CallistoClientAccessFileRenamedV1Data explicitly<br/>so a payload mismatch is a compile error"]
    VAL["ProceedingFileMustBeDeliverableValidator<br/>already 403s non-deliverables since PRDV-15776<br/>AC3 is met structurally - so no new tag check"]
    PORT["CLIENT_ACCESS_OUTBOX port and writer<br/>shipped by PRDV-16293 - routekey already allow-listed"]
  end

  subgraph SG_FROZEN["proceedings and proceeding-job-submission - FROZEN, zero files touched"]
    direction TB
    TS["RenameProceedingFileTS<br/>shared by A, B and C - has no AuthUser<br/>a granting-client-access port here would be a module cycle<br/>and transaction-scripts-no-aggregators blocks the alternative"]
    NOOP["Early return when the recomputed name equals the current one<br/>NO UPDATE is issued - the emitter must not fire here"]
    REPO["ProceedingFileRepository.updateFileName<br/>writes file_name and updated_at only<br/>never modified_user_identity"]
  end

  subgraph SG_DB["Postgres"]
    direction TB
    DB_FILES["files row - name changed"]
    DB_OUT["outbox_events row - NEW<br/>same transaction as the UPDATE"]
  end

  OUT_STALE["CURRENT outcome - Dione keeps the old name<br/>silently and permanently"]
  OUT_OK["TARGET outcome - relay publishes, Dione updates<br/>client sees the current name"]

  R_A --> SVC_C --> TS --> REPO --> DB_FILES --> OUT_STALE
  R_A --> SVC_T --> ASM_T --> TS
  R_BC --> TS
  VAL -. runs first, so everything after is a deliverable .-> SVC_T
  CONV_T -. builds the payload .-> ASM_T
  PORT -. injected by Symbol .-> ASM_T
  TS -. no-op branch - assembler skips on fileName equals previousFileName .-> NOOP
  ASM_T --> DB_OUT --> OUT_OK

  class SVC_C,OUT_STALE current
  class SVC_T,ASM_T,CONV_T,DB_OUT delta
  class R_A,R_BC,VAL,PORT,TS,NOOP,REPO,DB_FILES shared
  class OUT_OK ok

  style SG_ROUTES  fill:#e7f0ff,stroke:#3867d6,color:#10203f
  style SG_GCA     fill:#e8f7ed,stroke:#2f9e44,color:#102015
  style SG_FROZEN  fill:#f1f3f5,stroke:#868e96,color:#212529
  style SG_DB      fill:#fff4d6,stroke:#c98a00,color:#2d2200
```

Read without the prose: the frozen lane is shared by three routes and holds no user identity, so the emit moves up into the module that owns the port; the deliverable guarantee already exists so no new check is added; and the new outbox row commits with the name change rather than after it.

## Flows

**1. Where each of the five payload fields comes from.** This is the diagram that explains why the validator's return value changed — `proceedingId` exists nowhere else at the emit site without a third query.

```mermaid
flowchart LR
  classDef current fill:#ffe3e3,stroke:#c92a2a,color:#3b0a0a
  classDef delta   fill:#d0ebff,stroke:#1c7ed6,color:#0b2545
  classDef shared  fill:#f1f3f5,stroke:#868e96,color:#212529
  classDef ok      fill:#d3f9d8,stroke:#2f9e44,color:#102015

  subgraph SG_SRC["Where the value originates"]
    direction TB
    S_PARAM["Route param fileId"]
    S_USER["AuthUser from VerifiedUserDecorator<br/>identity is OPTIONAL - sub always present"]
    S_VAL["Validator's loaded context - CHANGED<br/>fetchProceedingFileForRename already ran<br/>and its result was previously discarded"]
    S_PROJ["RenameProceedingFileProjection<br/>bucket, filePath, fileName, previousFileName"]
    S_CLOCK["One new Date at the emit site<br/>serves renamedAt AND rowUpdatedAt"]
  end

  subgraph SG_PAY["CallistoClientAccessFileRenamedV1Data - five non-nullable fields"]
    direction TB
    P1["fileId"]
    P2["proceedingId"]
    P3["fileName - the NEW name"]
    P4["renamedUserIdentity"]
    P5["renamedAt - ISO 8601"]
  end

  ID["Outbox PK - uuidv5 over<br/>runnerName, aggregateType File, aggregateId, rowUpdatedAt ms, eventType<br/>NOT a payload field"]

  S_PARAM --> P1
  S_VAL --> P2
  S_PROJ --> P3
  S_USER -- "identity?.userId ?? sub" --> P4
  S_CLOCK --> P5
  S_CLOCK --> ID
  S_PARAM -. aggregateId is String of fileId .-> ID

  class S_VAL,S_CLOCK delta
  class S_PARAM,S_USER,S_PROJ,ID shared
  class P1,P2,P3,P4,P5 ok
```

The two blue nodes are the entire data-plumbing delta. Everything else was already in scope at the emit site.

**2. The emission decision — three ways to not emit.** Answers "when exactly does nothing get written, and why is each case correct?"

```mermaid
flowchart TB
  classDef current fill:#ffe3e3,stroke:#c92a2a,color:#3b0a0a
  classDef delta   fill:#d0ebff,stroke:#1c7ed6,color:#0b2545
  classDef shared  fill:#f1f3f5,stroke:#868e96,color:#212529
  classDef ok      fill:#d3f9d8,stroke:#2f9e44,color:#102015

  START["PATCH granting-client-access/file/:fileId"]
  Q_FOUND{"File found and attached to a proceeding?"}
  Q_DELIV{"isDeliverable?"}
  Q_CHANGED{"Recomputed name differs from the current one?"}
  Q_WRITE{"Outbox write succeeds?"}

  N_404["404 - no emit<br/>nothing was written"]
  N_403["403 - no emit<br/>THIS IS AC3 - the guard already existed"]
  N_NOOP["200 with message - NO emit<br/>the script issued no UPDATE, so there is no rename to announce"]
  N_ROLL["500 - transaction ROLLS BACK<br/>filename unchanged, caller retries cleanly<br/>this is why the transaction matters"]
  EMIT["One outbox row committed with the UPDATE"]

  START --> Q_FOUND
  Q_FOUND -- no --> N_404
  Q_FOUND -- yes --> Q_DELIV
  Q_DELIV -- no --> N_403
  Q_DELIV -- yes --> Q_CHANGED
  Q_CHANGED -- no --> N_NOOP
  Q_CHANGED -- yes --> Q_WRITE
  Q_WRITE -- no --> N_ROLL
  Q_WRITE -- yes --> EMIT

  class N_404,N_403,N_NOOP shared
  class N_ROLL,Q_WRITE delta
  class START,Q_FOUND,Q_DELIV,Q_CHANGED shared
  class EMIT ok
```

Without the transaction, the `Q_WRITE = no` branch would instead be "200, name changed, no event, forever" — the exact defect this ticket exists to remove, reintroduced by the fix.

## Sequences

**1. The double-submit interleaving — why a duplicate event id is a silent overwrite.** The edge case worth drawing, because the failure only exists in the interleaving and produces no error anywhere.

```mermaid
sequenceDiagram
    participant U as Ops user (double-click / LB retry)
    participant A as Assembler (txn 1)
    participant B as Assembler (txn 2)
    participant W as ClientAccessOutboxWriter
    participant D as Postgres outbox_events
    participant R as Relay (polls PENDING)

    U->>A: rename to "final.pdf"
    U->>B: rename to "final.pdf" again, same ms
    A->>W: write with rowUpdatedAt = T
    W->>W: uuidv5(runner, File, 123, T, file.renamed.v1) = ID
    W->>D: save(id = ID) - row absent, so INSERT
    D-->>A: row ID status PENDING
    Note over B: second request sees the name already equals the target
    B->>B: no-op branch - NO UPDATE, NO emit
    Note over D,R: so no collision in the common retry case
    R->>D: claim PENDING, publish once

    Note over A,D: The collision needs two GENUINE renames in the same ms
    U->>A: rename to "v2.pdf" at T
    U->>B: rename to "v3.pdf" also at T
    B->>W: write with rowUpdatedAt = T
    W->>W: same aggregate, same ms, same eventType - SAME ID
    W->>D: save(id = ID) - row PRESENT, so UPDATE
    D-->>B: no error, no log - data overwritten, status reset to PENDING
    R->>D: publishes ONE event carrying "v3.pdf"
```

Two things this diagram is doing. First, it shows the **retry** case is handled by the no-op guard, not by the id — which is why `rowUpdatedAt` is doing far less work here than it appears to. Second, it shows the genuine collision degrades to *one event carrying the correct final name* rather than a lost correction, and that this holds **only because the payload is a state snapshot with no `previousFileName`**. A future `v2` adding that field makes the overwrite lossy. Recorded as concern C7; the underlying `save()` behaviour is report assumption A3, confirmed directionally and still owing a real-Postgres demonstration.

**2. Atomicity — the failure window the spec did not mention.** Answers "what actually differs between emitting inside and outside the transaction?"

```mermaid
sequenceDiagram
    participant S as DeliverableRenameService
    participant P as TransactionalProxy
    participant T as RenameProceedingFileTS
    participant O as Outbox writer
    participant Q as Audit SQS

    Note over S,Q: WITHOUT a transaction - what the spec's design would produce
    S->>T: rename
    T-->>S: UPDATE autocommits
    S->>O: write outbox row
    O--xS: fails
    Note over S,Q: name changed, no event, no error recorded.<br/>Q5 forbids the reconciler that would repair it.<br/>Client is stale permanently.

    Note over S,Q: WITH the transaction - the design
    S->>P: assembler.apply
    P->>P: open boundary (re-entrant, joins if one exists)
    P->>T: rename - repositories auto-enlist via TransactionContext
    P->>O: write outbox row - enlists via TYPEORM_OUTBOX_REPOSITORY_RESOLVER
    O--xP: fails
    P-->>S: ROLLBACK - filename unchanged, 500 to caller
    Note over S,Q: nothing diverged. A retry is clean.

    S->>Q: audit dispatch - deliberately AFTER commit, OUTSIDE the boundary
    Note over Q: SQS is not rollbackable. Pulling it inside would hold a DB<br/>transaction across a network hop AND newly let an SQS outage<br/>roll back renames - a regression on a path this ticket must not change.
```

The audit dispatch's position is the non-obvious half: the correct answer is *not* "put everything in the transaction."

## Kinds deliberately skipped

- **A separate before/after pair for the current-vs-target picture** — N/A by convention: one figure, shared lanes, two chains.
- **A concurrency sequence for two different files renamed at once** — N/A: the deterministic id includes `aggregateId`, so different files cannot collide, and there is no shared mutable state between them.
- **A relay/dispatcher publication sequence** — N/A: RabbitMQ is descoped epic-wide and the producer's obligation ends at the `outbox_events` row. The relay appears in the collision diagram only far enough to establish that the overwrite happens before publication.
