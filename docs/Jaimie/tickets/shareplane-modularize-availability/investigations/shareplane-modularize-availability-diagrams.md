# Diagrams — Jaimie/shareplane-modularize-availability

> Companion to [shareplane-modularize-availability-investigation.md](./shareplane-modularize-availability-investigation.md). Each diagram states the question it answers.

## Current vs target

Shows what the refactor changes (monolith → modules + a NEW data-layer seam) and what stays frozen (URL-building output must be byte-identical).

```mermaid
flowchart TB
  subgraph CUR["Current — one file (SharePoint Lookup.html)"]
    C1["inline style + markup + script<br/>(URL building + UI + wiring, all mixed)"]
    C2["NO network layer<br/>(links built blind)"]
  end
  subgraph TGT["Target — modular"]
    T1["index.html + styles.css"]
    T2["url-builder.js<br/>FROZEN output (byte-identical)"]
    T3["sharepoint.js<br/>NEW data layer: authenticated _api read + parse"]
    T4["app.js / ui.js<br/>rendering + wiring + availability badges"]
    T5["config.js<br/>TENANT / SITES / FILTER_FIELD"]
  end
  C1 --> T1
  C1 --> T2
  C1 --> T4
  C2 -. becomes .-> T3
  T5 --> T2
  T5 --> T3
  T3 --> T4
```

## Flows

Shows where an availability check travels and the delivery-context gate that decides whether it is possible at all.

```mermaid
flowchart LR
  U["User types Title"] --> UI["ui: request availability"]
  UI --> SP["sharepoint.js: fetch _api $filter"]
  SP --> GATE{"execution context?"}
  GATE -->|"same-origin SP page"| OK1["cookie sent, response readable"]
  GATE -->|"extension host_permissions + credentials include"| OK2["cookie sent, page CORS bypassed"]
  GATE -->|"local file:// script fetch"| BLOCK["CORS blocked — cannot read (F4)"]
  OK1 --> P["parse count -> badge"]
  OK2 --> P
  BLOCK --> DEG["degrade: open _api URL in a tab (raw payload)"]
```

## Sequences

Exposes the bulk-availability throttle/threshold edge — why one-query-per-title is wrong for the OJB lists.

```mermaid
sequenceDiagram
    participant UI as UI (bulk paste, N titles)
    participant DL as sharepoint.js
    participant SP as SharePoint _api
    UI->>DL: check availability for N titles
    alt naive (one call per title)
        loop N times
            DL->>SP: GET items filter Title eq value
            SP-->>DL: 200 or 429 (throttle at ~300/60s)
        end
    else batched (recommended)
        DL->>SP: GET items filter Title eq a or Title eq b ... (bounded, $top)
        SP-->>DL: 200 (or 5000-threshold warning)
    end
    DL-->>UI: per-title availability (or visible degrade at limit)
```
