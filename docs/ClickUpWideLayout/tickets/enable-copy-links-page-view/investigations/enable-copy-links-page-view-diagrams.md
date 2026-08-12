# Diagrams — ClickUpWideLayout/enable-copy-links-page-view

> Companion to [enable-copy-links-page-view-investigation.md](./enable-copy-links-page-view-investigation.md). Each diagram states what question it answers.

## Current vs target

What changes in metadata ownership while the popup controls, formatters, clipboard path, and ClickUp DOM remain stable?

```mermaid
flowchart LR
  subgraph Current["Current"]
    C1["Existing popup buttons"] --> C2["Popup reads ID and title"]
    C2 --> C3["Content API resolves URL"]
    C3 --> C4{"Displayed ID found in URL or anchor"}
    C4 -->|"yes"| C5["Existing formatter and clipboard"]
    C4 -->|"no"| C6["Missing task link"]
  end

  subgraph Target["Target"]
    T1["Existing popup buttons unchanged"] --> T2["Content API reads active task metadata"]
    T2 --> T3{"Rendered task context"}
    T3 -->|"full page"| T4["Use current task route"]
    T3 -->|"pane"| T5["Use existing anchor and DOM lookup"]
    T3 -->|"unknown"| T6["Fail safely"]
    T4 --> T7["Existing formatter and clipboard unchanged"]
    T5 --> T7
  end

  classDef changed fill:#fff3bf,stroke:#b08900,color:#111;
  classDef frozen fill:#e7f5ff,stroke:#1c7ed6,color:#111;
  classDef failure fill:#ffe3e3,stroke:#c92a2a,color:#111;
  class C2,C3,C4,T2,T3,T4,T5 changed;
  class C1,C5,T1,T7 frozen;
  class C6,T6 failure;
```

## Flows

How does one metadata request select the correct URL without adding UI or a backend?

```mermaid
flowchart TD
  A["Popup copy click"] --> B["Ensure content API"]
  B --> C["getTaskMeta retries bounded ID and title lookup"]
  C --> D{"Metadata found"}
  D -->|"no"| E["Existing error feedback and no clipboard write"]
  D -->|"yes"| F{"Context"}
  F -->|"full page with task route"| G["Current window URL"]
  F -->|"pane"| H["Matching anchor or nearby DOM URL"]
  F -->|"unknown"| I["Null URL or safe failure"]
  G --> J["Return ID title URL context"]
  H --> J
  J --> K{"Selected existing format"}
  K -->|"plain"| L["ID title and URL"]
  K -->|"Markdown"| M["Heading link"]
  L --> N["Existing clipboard and toast"]
  M --> N
```

## Sequences

Which timing edge case prevents a copy click from reading task metadata before ClickUp finishes rendering?

```mermaid
sequenceDiagram
  participant U as User
  participant P as Popup
  participant A as Content API
  participant D as ClickUp DOM
  participant C as Clipboard
  U->>P: Choose existing copy action
  P->>A: getTaskMeta
  loop Bounded retry window
    A->>D: Read ID title and rendered context
    D-->>A: Metadata or not ready
  end
  alt Metadata ready
    A-->>P: ID title URL and context
    P->>C: Write unchanged payload
    C-->>P: Success or rejection
    P-->>U: Existing success or failure toast
  else Metadata unavailable
    A-->>P: null
    P-->>U: Existing task-details error
  end
```
