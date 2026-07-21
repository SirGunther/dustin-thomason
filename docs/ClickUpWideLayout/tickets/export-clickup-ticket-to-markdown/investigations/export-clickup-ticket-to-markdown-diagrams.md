# Diagrams - ClickUpWideLayout/export-clickup-ticket-to-markdown

> Companion to [export-clickup-ticket-to-markdown-investigation.md](./export-clickup-ticket-to-markdown-investigation.md). Each diagram states what question it answers.

## Current vs target

What changes in the extension when export is added, and what stays frozen.

```mermaid
flowchart LR
    subgraph User["User"]
        U1["Open ClickUp task"]
        U2["Open extension popup"]
    end

    subgraph Popup["popup.html and popup.js"]
        C1["Existing copy buttons"]
        T1["New export button"]
        T2["Task data collector"]
        T3["Markdown formatter"]
        T4["Blob download"]
    end

    subgraph Page["ClickUp page"]
        P1["Visible task DOM"]
        P2["Task link helper"]
    end

    subgraph Frozen["Unchanged neighbors"]
        F1["Layout toggle"]
        F2["Copy ID title"]
        F3["Copy Markdown link"]
    end

    U1 --> U2
    U2 --> C1
    C1 --> F2
    C1 --> F3
    U2 --> T1
    T1 --> T2
    T2 --> P1
    T2 --> P2
    T2 --> T3
    T3 --> T4
    U2 --> F1
```

## Flows

How the target export flow chooses DOM-first capture and API fallback.

```mermaid
flowchart TD
    A["Popup export clicked"] --> B["Inject collector into active tab"]
    B --> C["Read title id url description metadata"]
    C --> D{"Required fields found"}
    D -->|yes| E["Format original-ticket Markdown"]
    E --> F["Download ticket-id original-ticket md"]
    D -->|no| G["Show visible failure"]
    G --> H["Record missing selector or field"]
    H --> I{"Need API for missing fields"}
    I -->|not yet| J["Keep v1 DOM-first"]
    I -->|yes later| K["Design token or OAuth flow"]
```

## Sequences

Happy path timing for one export request.

```mermaid
sequenceDiagram
    participant User
    participant Popup
    participant ClickUpPage
    participant Browser

    User->>Popup: click export
    Popup->>Popup: show loading state
    Popup->>ClickUpPage: execute collector
    ClickUpPage-->>Popup: task fields and markdown source
    Popup->>Popup: format markdown and sanitize filename
    Popup->>Browser: start Blob download
    Popup-->>User: show success feedback
```
