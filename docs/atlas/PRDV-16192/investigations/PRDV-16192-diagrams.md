# Diagrams — atlas/PRDV-16192

> Companion to [PRDV-16192-investigation.md](./PRDV-16192-investigation.md). Each diagram states what question it answers.

## Current vs target

What this shows: where a `PERMISSIONS_UPDATED` event loses information on its way to the grid, which lane owns each step, and which steps must stay frozen. Lanes are owners; red is the defect, amber is what changes, grey is frozen.

```mermaid
flowchart TB
  subgraph CAL["Callisto (emitter) - frozen unless OV-1 says otherwise"]
    A["PermissionsMatrixService.computeDiff<br/>one entry per changed resource key"]
    B["PermissionsToAuditEventAssembler<br/>resourceName = roleName<br/>resourcePath = resourceKey<br/>oldState.path / newState.path = actions joined"]
  end

  subgraph PIPE["SQS + Mongo (transport and store) - frozen"]
    C["SQS audit queue"]
    D["SqsAuditEventListener<br/>raw JSON parse then save"]
    E[("auditevents collection<br/>N resources per document<br/>resourcePath IS stored")]
  end

  subgraph EUR["Europa (read) - the change lands here"]
    F["toItemProjection line 55<br/>auditEventResources index 0 only"]
    G["toItemProjection lines 58-62<br/>nullish chain so empty string wins"]
    H["projection + DTO + responder<br/>no resourcePath field exposed"]
  end

  subgraph ATL["Atlas (render) - contract follows Europa"]
    I["SearchAuditEventItem<br/>no resourcePath property"]
    J["auditEventColumns path<br/>raw passthrough no format"]
    K["Audit grid row"]
  end

  A --> B --> C --> D --> E --> F --> G --> H --> I --> J --> K

  L["TARGET<br/>represent every resource<br/>expose the resource key<br/>distinguish cleared from absent"]
  F -.replace.-> L
  G -.replace.-> L
  L -.-> H

  M["FROZEN - must not move<br/>LOGIN and LOGOUT null states<br/>PROCEEDING newState.value with no path<br/>single-resource FILE rows"]
  M -.constrains.-> L

  classDef defect fill:#7f1d1d,stroke:#ef4444,color:#fff
  classDef change fill:#78350f,stroke:#f59e0b,color:#fff
  classDef frozen fill:#374151,stroke:#9ca3af,color:#fff
  class F,G defect
  class H,I,J,L change
  class A,B,C,D,E,M frozen
```

Reading it: nothing is wrong before the Europa lane. The document in Mongo is complete — it carries every changed resource key in `resourcePath`. Both red nodes discard information that is already present, which is why the fix is retroactive.

## Flows

### 1. What a two-key save actually renders today

What this shows: the exact loss for the ticket's own example — transcript track gains `update`, video track is cleared — and why the blank cell also costs you the key.

```mermaid
flowchart TB
  S["One save changes 2 resource keys"] --> EV["1 event with 2 resources"]

  EV --> R0["resource index 0 - TRANSCRIPT<br/>resourcePath = SUBMISSION_PROCEEDING_FILES_TRANSCRIPT<br/>oldState.path = read<br/>newState.path = read, update"]
  EV --> R1["resource index 1 - VIDEO<br/>resourcePath = SUBMISSION_PROCEEDING_FILES_VIDEO<br/>oldState.path = read, update<br/>newState.path = empty string"]

  R0 --> P["toItemProjection takes index 0 only"]
  R1 --> X["DISCARDED - never reaches the grid"]

  P --> Q{"newState.path is not null or undefined"}
  Q -->|"true - read, update"| ROW["Grid row<br/>Resource = role name<br/>Path = read, update"]

  ROW --> OUT["Auditor sees one row.<br/>No resource key. No old state.<br/>No sign the video track was cleared at all."]

  classDef lost fill:#7f1d1d,stroke:#ef4444,color:#fff
  class X,OUT lost
```

### 2. Why the empty string is worse than a blank cell

What this shows: the `??` chain when the *first* resource is the cleared one — the case that produces the ticket's item 3. The chain is a fallback ladder, and `''` is a rung, not a miss.

```mermaid
flowchart LR
  N["newState.path = empty string"] --> C1{"nullish?"}
  C1 -->|"no - empty string is a value"| WIN["path = empty string"]
  C1 -.->|"would have continued"| C2["oldState.path = read, update"]
  C2 -.-> C3["resourcePath = the resource key"]
  WIN --> CELL["Blank cell.<br/>Both fallbacks unreachable,<br/>including the one holding the key."]

  classDef lost fill:#7f1d1d,stroke:#ef4444,color:#fff
  classDef skipped fill:#374151,stroke:#9ca3af,color:#fff
  class WIN,CELL lost
  class C2,C3 skipped
```

## Sequences

### 1. Fire-and-forget dispatch — the audit can vanish while the save succeeds

What this exposes: the permission change is persisted *before* the audit event is dispatched, and the dispatch is not awaited by the request. A queue failure logs to console and the user sees a successful save with no audit trail — a silent gap in an audit log, which is the one place silence is unacceptable.

```mermaid
sequenceDiagram
    participant U as Admin in Atlas
    participant S as PermissionsMatrixService
    participant DB as Postgres
    participant Q as SQS
    U->>S: PUT permissions matrix
    S->>DB: getCurrentAllowedCells (snapshot)
    S->>S: computeDiff
    S->>DB: replaceRolePermissions (delete then insert)
    S--)Q: dispatch PERMISSIONS_UPDATED (not awaited)
    S-->>U: 200 OK
    Note over Q: if the queue rejects, the catch<br/>logs to console and nothing else
    Note over U: user sees success<br/>audit log has no record
```

### 2. Two concurrent saves on the same role — the second event's "old" state is wrong

What this exposes: the diff baseline is snapshotted before the replace, and nothing serialises two saves against the same role. If B snapshots before A commits, B's event reports an `oldActions` that never existed at the moment B ran — the audit trail becomes internally inconsistent even though the final permission state is correct.

```mermaid
sequenceDiagram
    participant A as Admin A
    participant B as Admin B
    participant S as PermissionsMatrixService
    participant DB as Postgres
    A->>S: save role 19 (grant update)
    B->>S: save role 19 (grant delete)
    S->>DB: A snapshot - current = read
    S->>DB: B snapshot - current = read
    S->>DB: A replace - now read, update
    S--)S: A event says read to read, update
    S->>DB: B replace - now read, delete
    S--)S: B event says read to read, delete
    Note over S: B never saw A's update.<br/>The trail reads as if update was<br/>never granted, only silently dropped.
```

Both sequences are pre-existing behaviour, not introduced by this ticket, and both are recorded in [future-development concerns](../PRDV-16192-future-development-concerns.md) rather than folded into scope.
