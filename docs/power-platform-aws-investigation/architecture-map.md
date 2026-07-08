# Architecture Map

Status: Draft  
Prepared: 2026-07-06

These diagrams are text-first maps for planning. They should be validated against Power Platform, SharePoint, gateway, and AWS console state before use as final architecture.

## ADB Current Problem

```mermaid
flowchart LR
    User[Scheduler opens ADB PowerApp]
    App[ADB PowerApp]
    DirectQuery[Login-triggered direct RB9 query]
    RB9[(OMTI RB9)]

    User --> App --> DirectQuery --> RB9
    DirectQuery -. high frequency .-> Timeout[60-second timeout / provider block risk]
```

Problem: ADB was tightly coupled to RB9 and could trigger expensive source queries during user interaction.

## ADB Near-Term Recovery

```mermaid
flowchart LR
    RB9[(OMTI RB9)]
    PBI[Power BI semantic model]
    PA[Power Automate query flow]
    App[ADB PowerApp]
    Override[(SharePoint override list)]
    User[Scheduler]

    RB9 -->|scheduled low-frequency refresh| PBI
    PBI --> PA --> App
    User -->|manual scheduling change| App
    App --> Override
    Override -->|higher precedence than semantic model| App
```

Key design rule: semantic model data is the base state; SharePoint overrides are immediate and win in the UI until reconciled.

## OJB Current Problem

```mermaid
flowchart LR
    Flows[OJB Power Automate flows]
    RB9[(OMTI RB9)]
    Working[(Operations Job Boards list)]
    Archive[(Operations Job Boards Archive)]
    Backlog[Backlog since 2026-05-21]

    Flows -->|full historical catch-up risk| RB9
    Backlog -. drives huge query window .-> Flows
    Flows --> Working
    Working --> Archive
```

Problem: reconnecting all flows without controlling the high-water mark can force a massive catch-up query and create a timeout loop.

## OJB Staged Recovery

```mermaid
flowchart TD
    Prod[Production OJB]
    Clone[Cloned pre-prod SharePoint lists and flows]
    Gateway[New gateway hostname / staged connection target]
    HWM[Approved high-water mark timestamp]
    CDC[CDC query: changed IDs]
    Batch[Batch updates: 15 to 20 items]
    RB9[(OMTI RB9)]
    Working[(OJB working list)]
    Archive[(OJB archive list)]
    Monitor[Gateway, flow, and DB monitoring]
    Backfill[Separate historical backfill plan]

    Prod --> Clone
    Clone --> Gateway
    HWM --> CDC
    Gateway --> CDC --> RB9
    CDC --> Batch --> Working
    Working --> Archive
    Monitor --> Gateway
    HWM -. skipped period .-> Backfill
```

Key design rule: restore forward-looking delta polling first; handle the May 21 through restoration-date gap as a separate backfill.

## Lagrange/AWS Fallback Candidate

```mermaid
flowchart LR
    PowerPlatform[Power Apps / Power Automate]
    Gateway[Power Platform gateway or controlled connector host]
    Network[Approved secure route]
    Proxy[Proxy / NLB / PrivateLink endpoint service]
    Postgres[(Lagrange PostgreSQL / Aurora)]
    Views[Read-optimized views/tables]

    PowerPlatform --> Gateway --> Network --> Proxy --> Postgres --> Views
```

Key design rule: no direct public inbound database exposure. The exact route remains a PoC decision.

## Lagrange TLS Decision Point

```mermaid
flowchart TD
    Client[Power Platform PostgreSQL connector]
    Encrypt[Encrypt Connection enabled]
    DNS[Server name used by connector]
    Cert[Certificate presented on route]
    Trust[RDS CA or proxy CA trusted]
    Pass{Certificate identity valid?}
    Success[Connection accepted]
    Fail[Connection rejected or insecure workaround]

    Client --> Encrypt --> DNS --> Cert --> Trust --> Pass
    Pass -->|yes| Success
    Pass -->|no| Fail
```

Open decision: determine whether the connector can validate the certificate identity across the selected gateway/proxy/NLB path without weakening security.

## Dependency Inventory Template

| Area | Item | Current lead | Needs confirmation |
| --- | --- | --- | --- |
| ADB source | Power BI semantic model matching `VQM jobs` and `VQM jobs tests` | Internal note | Owner, workspace, refresh schedule, fields |
| ADB override | SharePoint temporary ADB statuses/override list | Local WorkLists lead | Schema, retention rule, permissions |
| OJB lists | Operations Job Boards and Operations Job Boards Archive | Local WorkLists lead | URLs, item counts, indexed fields, views |
| OJB flows | RB Dispatcher, cleanup, and reconciliation flows | Local WorkLists lead | Trigger cadence, queries, connection refs, retry policy |
| Gateway | New hostname / staged cutover route | Internal note | Version, admins, data sources, network tests |
| Lagrange | PostgreSQL views/tables in TST | Internal note | PR status, schema, least-privilege role |
| Security | Credential rotation and connection sharing | Internal note | Actual shared users, secret locations, rotation status |
